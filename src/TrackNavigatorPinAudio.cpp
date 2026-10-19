#include "lrp/TrackNavigator.h"
#include <algorithm>
#include <cstdint>
#include <cstring>

namespace lrp {
namespace {
// REAPER's pin mapping API uses two 32-bit words for channels 1-64.
// The second independent 64-bit bank (channels 65-128) is accessed by
// adding 0x1000000 to the pin index. Do not shift by 64 or combine
// banks into a single 64-bit mask: read/modify/write only the target bank.
constexpr int kMaxAudioTrackChannels = 128;
constexpr int kSecond64PinBank = 0x1000000;
int pinIndexForChannel(int pin, int channel) {
    return pin + (channel >= 64 ? kSecond64PinBank : 0);
}
int channelWithinPinBank(int channel) {
    return channel % 64;
}
std::string pinName(int pin) {
    if (pin == 0) return "left";
    if (pin == 1) return "right";
    return "pin " + std::to_string(pin + 1);
}
}

int TrackNavigator::pinAudioResolvedFx() const {
    if (!active_ || !project_ || !track_ ||
        !ValidatePtr2(project_, track_, "MediaTrack*") ||
        !TrackFX_GetCount || !TrackFX_GetFXGUID) return -1;
    const int n = std::clamp(TrackFX_GetCount(track_), 0, 1024);
    for (int i = 0; i < n; ++i) {
        const GUID* id = TrackFX_GetFXGUID(track_, i);
        if (id && std::memcmp(id, &pinAudioGuid_, sizeof(GUID)) == 0) return i;
    }
    return -1;
}

bool TrackNavigator::enterPinAudio() {
    if (page_ != Page::fxTcp || fxTcpListOpen_ || !track_) return false;
    if (!TrackFX_GetIOSize || !TrackFX_GetPinMappings || !TrackFX_SetPinMappings ||
        !TrackFX_GetFXGUID) {
        speech_("REAPER audio pin mapping API unavailable");
        return false;
    }
    const FxTcpColumn* fx = currentFxTcpColumn();
    if (!fx || fx->fxIndex < 0 || fx->fxIndex >= TrackFX_GetCount(track_)) {
        speech_("Select an FX in F4 first");
        return false;
    }
    const GUID* currentGuid = TrackFX_GetFXGUID(track_, fx->fxIndex);
    if (!currentGuid || std::memcmp(currentGuid, &fx->guid, sizeof(GUID)) != 0) {
        speech_("FX identity changed. Reopen F4");
        return false;
    }
    int inputPins = 0, outputPins = 0;
    TrackFX_GetIOSize(track_, fx->fxIndex, &inputPins, &outputPins);
    if (inputPins <= 0 && outputPins <= 0) {
        speech_("No audio pins");
        return false;
    }
    // Pin count is independent of the track's channel count. Bound both
    // against REAPER's 128-channel audio matrix, without changing I_NCHAN.
    pinAudioInputs_ = std::clamp(inputPins, 0, kMaxAudioTrackChannels);
    pinAudioOutputs_ = std::clamp(outputPins, 0, kMaxAudioTrackChannels);
    const double channels = GetMediaTrackInfo_Value ?
        GetMediaTrackInfo_Value(track_, "I_NCHAN") : 2.0;
    pinAudioChannels_ = std::clamp(static_cast<int>(channels), 2, kMaxAudioTrackChannels);
    pinAudioColumn_ = pinAudioChannel_ = 0;
    pinAudioGuid_ = *currentGuid;
    rememberFxTcpPosition();
    page_ = Page::pinAudio;
    valueMode_ = false;
    speech_("Audio pin connector. " + trackName() + ". " +
        fx->name + ". " + pinAudioReview(false));
    return true;
}

void TrackNavigator::leavePinAudio(bool speak) {
    if (page_ != Page::pinAudio) return;
    const int fx = pinAudioResolvedFx();
    page_ = Page::fxTcp;
    // preserve the exact F4 FX/parameter when possible even if FX moved.
    rebuildFxTcp(true);
    if (fx >= 0) {
        for (int i = 0; i < static_cast<int>(fxTcpColumns_.size()); ++i) {
            if (std::memcmp(&fxTcpColumns_[static_cast<size_t>(i)].guid,
                    &pinAudioGuid_, sizeof(GUID)) == 0) {
                fxTcpColumn_ = i;
                break;
            }
        }
    }
    if (speak) speech_(fx >= 0 ? "FX parameters. " + fxTcpReview(false) :
        "FX no longer available. " + fxTcpReview(false));
}

bool TrackNavigator::pinAudioSelected(int column, int channel) const {
    const int fx = pinAudioResolvedFx();
    if (fx < 0 || !TrackFX_GetPinMappings || column < 0 ||
        column >= pinAudioColumnCount() || channel < 0 || channel >= pinAudioChannels_) return false;
    const bool output = column >= pinAudioInputs_;
    const int pin = output ? column - pinAudioInputs_ : column;
    const int bankPin = pinIndexForChannel(pin, channel);
    const int bit = channelWithinPinBank(channel);
    int high = 0;
    const std::uint32_t lowBits = static_cast<std::uint32_t>(
        TrackFX_GetPinMappings(track_, fx, output ? 1 : 0, bankPin, &high));
    const std::uint32_t highBits = static_cast<std::uint32_t>(high);
    return bit < 32 ? ((lowBits & (std::uint32_t{1} << bit)) != 0) :
        ((highBits & (std::uint32_t{1} << (bit - 32))) != 0);
}

std::string TrackNavigator::pinAudioReview(bool context) const {
    const int fx = pinAudioResolvedFx();
    if (fx < 0) return "FX no longer available";
    const bool output = pinAudioColumn_ >= pinAudioInputs_;
    const int pin = output ? pinAudioColumn_ - pinAudioInputs_ : pinAudioColumn_;
    const int channel = pinAudioChannel_ + 1;
    std::string message = pinAudioSelected(pinAudioColumn_, pinAudioChannel_) ? "Selected. " : "";
    message += output ? "Output " : "Input ";
    message += std::to_string(pin + 1) + " " + pinName(pin);
    message += output ? ". Sends to track channel " : ". Receives from track channel ";
    message += std::to_string(channel);
    if (context) {
        char fxName[1024]{};
        if (TrackFX_GetFXName) TrackFX_GetFXName(track_, fx, fxName, sizeof(fxName));
        message = trackName() + ". FX " + std::to_string(fx + 1) + " " +
            (fxName[0] ? fxName : "FX") + ". " + message +
            ". Column " + std::to_string(pinAudioColumn_ + 1) + " of " +
            std::to_string(pinAudioColumnCount()) + ", channel " +
            std::to_string(channel) + " of " + std::to_string(pinAudioChannels_);
    }
    return message;
}

bool TrackNavigator::pinAudioSet(int column, int channel, bool selected) {
    const int fx = pinAudioResolvedFx();
    if (fx < 0 || !TrackFX_GetPinMappings || !TrackFX_SetPinMappings ||
        column < 0 || column >= pinAudioColumnCount() || channel < 0 ||
        channel >= pinAudioChannels_) return false;
    const bool output = column >= pinAudioInputs_;
    const int pin = output ? column - pinAudioInputs_ : column;
    const int bankPin = pinIndexForChannel(pin, channel);
    const int bit = channelWithinPinBank(channel);
    int high = 0;
    std::uint32_t lowBits = static_cast<std::uint32_t>(
        TrackFX_GetPinMappings(track_, fx, output ? 1 : 0, bankPin, &high));
    std::uint32_t highBits = static_cast<std::uint32_t>(high);
    const std::uint32_t mask = std::uint32_t{1} << (bit % 32);
    std::uint32_t& bits = bit < 32 ? lowBits : highBits;
    if (selected) bits |= mask;
    else bits &= ~mask;
    if (Undo_BeginBlock2) Undo_BeginBlock2(project_);
    const bool ok = TrackFX_SetPinMappings(track_, fx, output ? 1 : 0, bankPin,
        static_cast<int>(lowBits), static_cast<int>(highBits));
    if (Undo_EndBlock2) Undo_EndBlock2(project_,
        selected ? "LReaParams: connect audio FX pin" : "LReaParams: disconnect audio FX pin", -1);
    if (ok && UpdateArrange) UpdateArrange();
    return ok && pinAudioSelected(column, channel) == selected;
}

void TrackNavigator::pinAudioMove(int column, int channel) {
    const int nextCol = std::clamp(column, 0, pinAudioColumnCount() - 1);
    const int nextCh = std::clamp(channel, 0, pinAudioChannels_ - 1);
    if (nextCol == pinAudioColumn_ && nextCh == pinAudioChannel_) return;
    pinAudioColumn_ = nextCol;
    pinAudioChannel_ = nextCh;
    speech_(pinAudioReview(false));
}

void TrackNavigator::pinAudioJumpSelected(int direction, int axis) {
    // axis 0: within one pin column; 1: across pin columns at current channel;
    // axis 2: linear global search. No wrapping and silent boundaries.
    const int count = pinAudioColumnCount() * pinAudioChannels_;
    const int current = pinAudioColumn_ * pinAudioChannels_ + pinAudioChannel_;
    for (int offset = direction; offset * direction > 0; offset += direction) {
        const int index = current + (axis == 0 ? offset : axis == 1 ? offset * pinAudioChannels_ : offset);
        if (index < 0 || index >= count) break;
        const int c = index / pinAudioChannels_, r = index % pinAudioChannels_;
        if (axis == 0 && c != pinAudioColumn_) break;
        if (axis == 1 && r != pinAudioChannel_) break;
        if (pinAudioSelected(c, r)) { pinAudioMove(c, r); return; }
    }
    speech_("No selected connection in that direction");
}

void TrackNavigator::handlePinAudioKey(const Key& k) {
    if (pinAudioResolvedFx() < 0) { leavePinAudio(); return; }
    if (k.repeat && (k.vk == VK_RETURN || k.vk == VK_DELETE)) return;
    if (!k.ctrl && !k.shift && !k.alt) {
        switch (k.vk) {
            case VK_F5: case VK_TAB: speech_(pinAudioReview(true)); return;
            case VK_F6: leavePinAudio(false); enterTrackMidi(); return;
            case VK_F7: if (hardwareOutputCount() > 0) {
                leavePinAudio(false); enterHardwareOutputs();
            } else speech_("No hardware outputs"); return;
            case VK_F8: if (!k.repeat) { leavePinAudio(false); enterReaRoute(); } return;
            case VK_F4: case VK_ESCAPE: leavePinAudio(); return;
            case VK_F1: leavePinAudio(); selectPage(Page::tracks); return;
            case VK_F2: leavePinAudio(); selectPage(Page::sends); return;
            case VK_F3: leavePinAudio(); selectPage(Page::receives); return;
            case VK_RETURN: case VK_SPACE: {
                const bool connect = !pinAudioSelected(pinAudioColumn_, pinAudioChannel_);
                speech_(pinAudioSet(pinAudioColumn_, pinAudioChannel_, connect) ?
                    (connect ? "Connected. " : "Disconnected. ") + pinAudioReview(false) :
                    "Could not change pin connection");
                return;
            }
            case VK_DELETE:
                speech_(pinAudioSelected(pinAudioColumn_, pinAudioChannel_) ?
                    (pinAudioSet(pinAudioColumn_, pinAudioChannel_, false) ?
                    "Disconnected. " + pinAudioReview(false) : "Could not disconnect") : "Not connected");
                return;
            case VK_UP: pinAudioMove(pinAudioColumn_, pinAudioChannel_ - 1); return;
            case VK_DOWN: pinAudioMove(pinAudioColumn_, pinAudioChannel_ + 1); return;
            case VK_LEFT: pinAudioMove(pinAudioColumn_ - 1, pinAudioChannel_); return;
            case VK_RIGHT: pinAudioMove(pinAudioColumn_ + 1, pinAudioChannel_); return;
            case VK_HOME: pinAudioMove(pinAudioColumn_, 0); return;
            case VK_END: pinAudioMove(pinAudioColumn_, pinAudioChannels_ - 1); return;
            case VK_PRIOR: pinAudioMove(pinAudioColumn_, pinAudioChannel_ - 5); return;
            case VK_NEXT: pinAudioMove(pinAudioColumn_, pinAudioChannel_ + 5); return;
            default: return;
        }
    }
    if (k.ctrl && !k.alt && !k.shift) {
        switch (k.vk) {
            case VK_HOME: pinAudioMove(0, 0); return;
            case VK_END: pinAudioMove(pinAudioColumnCount() - 1, pinAudioChannels_ - 1); return;
            case VK_UP: pinAudioJumpSelected(-1, 0); return;
            case VK_DOWN: pinAudioJumpSelected(1, 0); return;
            case VK_LEFT: pinAudioJumpSelected(-1, 1); return;
            case VK_RIGHT: pinAudioJumpSelected(1, 1); return;
            case 'Q': return; // Ctrl+Q handled centrally, if applicable.
            case VK_SPACE: if (Main_OnCommand) Main_OnCommand(40073, 0); return;
            default: return;
        }
    }
    if (k.ctrl && k.alt && !k.shift) {
        switch (k.vk) {
            case VK_UP: case VK_LEFT: pinAudioJumpSelected(-1, 2); return;
            case VK_DOWN: case VK_RIGHT: pinAudioJumpSelected(1, 2); return;
            default: return;
        }
    }
}
} // namespace lrp
