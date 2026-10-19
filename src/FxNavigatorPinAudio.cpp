#include "lrp/FxNavigator.h"
#include <algorithm>
#include <cstdint>

namespace lrp {
namespace {
constexpr int maxChannels = 128;
constexpr int second64Bank = 0x1000000;
int bankedPin(int pin, int channel) { return pin + (channel >= 64 ? second64Bank : 0); }
int channelBit(int channel) { return channel % 64; }
std::string pinLabel(int pin) {
    if (pin == 0) return "left";
    if (pin == 1) return "right";
    return "pin " + std::to_string(pin + 1);
}
}

bool FxNavigator::enterPinAudio() {
    if (!active_ || !valid() || !track_) { speech_("FX no longer available"); return false; }
    if (!TrackFX_GetIOSize || !TrackFX_GetPinMappings || !TrackFX_SetPinMappings ||
        (take_ && (!TakeFX_GetIOSize || !TakeFX_GetPinMappings || !TakeFX_SetPinMappings))) {
        speech_("REAPER audio pin API unavailable"); return false;
    }
    int inputs = 0, outputs = 0;
    if (take_) TakeFX_GetIOSize(take_, fx_, &inputs, &outputs);
    else TrackFX_GetIOSize(track_, fx_, &inputs, &outputs);
    if (inputs <= 0 && outputs <= 0) { speech_("No audio pins"); return false; }
    pinAudioInputs_ = std::clamp(inputs, 0, maxChannels);
    pinAudioOutputs_ = std::clamp(outputs, 0, maxChannels);
    const int count = GetMediaTrackInfo_Value ?
        static_cast<int>(GetMediaTrackInfo_Value(track_, "I_NCHAN")) : 2;
    pinAudioChannels_ = std::clamp(count, 2, maxChannels);
    // No navigation changes, parameter changes or file writes on entry.
    pinAudioColumn_ = 0;
    pinAudioChannel_ = 0;
    pinAudioMode_ = true;
    speech_("Audio Pin Connector. " + fxDisplayName() + ". " + pinAudioReview(true));
    return true;
}

void FxNavigator::leavePinAudio(bool announceReturn) {
    if (!pinAudioMode_) return;
    pinAudioMode_ = false;
    if (announceReturn) speech_("FX parameters. " + currentParameterSpeech());
}

bool FxNavigator::pinAudioSelected(int column, int channel) const {
    if (!valid() || !pinAudioMode_ || !track_ || column < 0 ||
        column >= pinAudioColumnCount() || channel < 0 || channel >= pinAudioChannels_) return false;
    const bool output = column >= pinAudioInputs_;
    const int pin = output ? column - pinAudioInputs_ : column;
    const int index = bankedPin(pin, channel);
    int high = 0;
    const std::uint32_t lowBits = static_cast<std::uint32_t>(take_ ?
        TakeFX_GetPinMappings(take_, fx_, output ? 1 : 0, index, &high) :
        TrackFX_GetPinMappings(track_, fx_, output ? 1 : 0, index, &high));
    const int bit = channelBit(channel);
    const std::uint32_t word = bit < 32 ? lowBits : static_cast<std::uint32_t>(high);
    return (word & (std::uint32_t{1} << (bit % 32))) != 0;
}

std::string FxNavigator::pinAudioReview(bool context) const {
    if (!valid()) return "FX no longer available";
    if (pinAudioColumnCount() <= 0) return "No audio pins";
    const bool output = pinAudioColumn_ >= pinAudioInputs_;
    const int pin = output ? pinAudioColumn_ - pinAudioInputs_ : pinAudioColumn_;
    std::string message = pinAudioSelected(pinAudioColumn_, pinAudioChannel_) ? "Attive. " : "";
    message += output ? "Output " : "Input ";
    message += std::to_string(pin + 1) + " " + pinLabel(pin);
    message += output ? ". Sends to track channel " : ". Receives from track channel ";
    message += std::to_string(pinAudioChannel_ + 1);
    if (context) {
        message = contextName() + ". " + fxDisplayName() + ". " + message +
            ". Pin " + std::to_string(pinAudioColumn_ + 1) + " of " +
            std::to_string(pinAudioColumnCount()) + ", channel " +
            std::to_string(pinAudioChannel_ + 1) + " of " +
            std::to_string(pinAudioChannels_);
    }
    return message;
}

bool FxNavigator::pinAudioSet(int column, int channel, bool connected) {
    if (!valid() || !pinAudioMode_ || !TrackFX_GetPinMappings || !TrackFX_SetPinMappings ||
        (take_ && (!TakeFX_GetPinMappings || !TakeFX_SetPinMappings)) ||
        column < 0 || column >= pinAudioColumnCount() || channel < 0 || channel >= pinAudioChannels_) return false;
    const bool output = column >= pinAudioInputs_;
    const int pin = output ? column - pinAudioInputs_ : column;
    const int index = bankedPin(pin, channel);
    const int bit = channelBit(channel);
    int high = 0;
    std::uint32_t lowBits = static_cast<std::uint32_t>(take_ ?
        TakeFX_GetPinMappings(take_, fx_, output ? 1 : 0, index, &high) :
        TrackFX_GetPinMappings(track_, fx_, output ? 1 : 0, index, &high));
    std::uint32_t highBits = static_cast<std::uint32_t>(high);
    std::uint32_t& word = bit < 32 ? lowBits : highBits;
    const std::uint32_t mask = std::uint32_t{1} << (bit % 32);
    if (connected) word |= mask; else word &= ~mask;
    if (Undo_BeginBlock2) Undo_BeginBlock2(project_);
    const bool written = take_ ? TakeFX_SetPinMappings(take_, fx_, output ? 1 : 0, index,
        static_cast<int>(lowBits), static_cast<int>(highBits)) :
        TrackFX_SetPinMappings(track_, fx_, output ? 1 : 0, index,
        static_cast<int>(lowBits), static_cast<int>(highBits));
    if (Undo_EndBlock2) Undo_EndBlock2(project_,
        connected ? "LReaParams: connect audio FX pin" : "LReaParams: disconnect audio FX pin", -1);
    if (written && UpdateArrange) UpdateArrange();
    return written && pinAudioSelected(column, channel) == connected;
}

void FxNavigator::pinAudioMove(int column, int channel) {
    if (pinAudioColumnCount() <= 0) return;
    const int c = std::clamp(column, 0, pinAudioColumnCount() - 1);
    const int r = std::clamp(channel, 0, pinAudioChannels_ - 1);
    if (c == pinAudioColumn_ && r == pinAudioChannel_) return;
    pinAudioColumn_ = c;
    pinAudioChannel_ = r;
    speech_(pinAudioReview(false));
}

void FxNavigator::pinAudioJumpSelected(int direction, int axis) {
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

void FxNavigator::handlePinAudio(const Key& k) {
    if (k.repeat && (k.vk == VK_RETURN || k.vk == VK_SPACE || k.vk == VK_DELETE)) return;
    if (!k.ctrl && !k.alt && !k.shift) {
        switch (k.vk) {
            case VK_F11: case VK_TAB: speech_(pinAudioReview(true)); return;
            case VK_F10: leavePinAudio(false); enterFxBrowser(); return;
            case VK_ESCAPE: leavePinAudio(); return;
            case VK_RETURN: case VK_SPACE: {
                const bool connect = !pinAudioSelected(pinAudioColumn_, pinAudioChannel_);
                speech_(pinAudioSet(pinAudioColumn_, pinAudioChannel_, connect) ?
                    pinAudioReview(false) : "Could not change pin connection"); return;
            }
            case VK_DELETE:
                if (!pinAudioSelected(pinAudioColumn_, pinAudioChannel_)) { speech_(pinAudioReview(false)); return; }
                speech_(pinAudioSet(pinAudioColumn_, pinAudioChannel_, false) ?
                    pinAudioReview(false) : "Could not disconnect"); return;
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
            case VK_END: pinAudioMove(pinAudioColumnCount()-1, pinAudioChannels_-1); return;
            case VK_UP: pinAudioJumpSelected(-1, 0); return;
            case VK_DOWN: pinAudioJumpSelected(1, 0); return;
            case VK_LEFT: pinAudioJumpSelected(-1, 1); return;
            case VK_RIGHT: pinAudioJumpSelected(1, 1); return;
            default: return;
        }
    }
    if (k.ctrl && k.alt && !k.shift && !k.altGr) {
        switch (k.vk) {
            case VK_UP: case VK_LEFT: pinAudioJumpSelected(-1, 2); return;
            case VK_DOWN: case VK_RIGHT: pinAudioJumpSelected(1, 2); return;
            default: return;
        }
    }
}
} // namespace lrp
