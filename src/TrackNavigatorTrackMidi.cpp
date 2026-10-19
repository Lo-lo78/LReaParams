#include "lrp/TrackNavigator.h"
#include <algorithm>
#include <cmath>
#include <string>

namespace lrp {
namespace {
constexpr int kMidiFields = 5;
constexpr const char* kMidiLabels[kMidiFields] = {
    "MIDI hardware output", "MIDI hardware channel", "MIDI input channel map",
    "MIDI control channel", "MIDI routing"
};
// REAPER stores a MIDI hardware device in bits 5..9, MIDI channel in 0..4.
// -1 disables the output. Always preserve the existing channel while choosing
// another device (or vice versa), just as the original Track Params Lua does.
struct HardwareMidiOut { int device = -1, channel = 0, raw = -1; };
int readMidiInfo(MediaTrack* track, const char* key) {
    if (!track || !GetMediaTrackInfo_Value) return -1;
    const double value = GetMediaTrackInfo_Value(track, key);
    if (!std::isfinite(value)) return -1;
    return static_cast<int>(std::lround(value));
}
HardwareMidiOut readMidiHardware(MediaTrack* track) {
    HardwareMidiOut out;
    out.raw = readMidiInfo(track, "I_MIDIHWOUT");
    if (out.raw >= 0) {
        out.channel = std::clamp(out.raw & 31, 0, 16);
        out.device = std::clamp((out.raw >> 5) & 31, 0, 31);
    }
    return out;
}
int midiHardwareValue(int device, int channel) {
    return (std::clamp(device, 0, 31) << 5) | std::clamp(channel, 0, 16);
}
std::string outputName(int device) {
    std::string label = "Device " + std::to_string(device + 1);
    char name[1024]{};
    if (GetMIDIOutputName && GetMIDIOutputName(device, name, sizeof(name)) && name[0]) {
        // MIDI device aliases are UTF-8 and can be spoken via OSARA.
        label += " "; label += name;
    }
    return label;
}
std::string midiValue(MediaTrack* track, int row) {
    if (row == 0 || row == 1) {
        const auto hw = readMidiHardware(track);
        if (hw.raw < 0) return row == 0 ? "Disabled" : "Output disabled";
        if (row == 0) return outputName(hw.device);
        return hw.channel == 0 ? "All" : std::to_string(hw.channel);
    }
    if (row == 2) {
        const int value = readMidiInfo(track, "I_MIDI_INPUT_CHANMAP");
        return value < 0 ? "Source channel" : std::to_string(std::clamp(value, 1, 16));
    }
    if (row == 3) {
        const int value = readMidiInfo(track, "I_MIDI_CTL_CHAN");
        return value < 0 ? "None" : value >= 16 ? "All channels" : std::to_string(value + 1);
    }
    return "Sends and receives use F2 and F3";
}
} // namespace

std::string TrackNavigator::trackMidiReview(bool context) const {
    const int row = std::clamp(trackMidiRow_, 0, kMidiFields - 1);
    std::string line = std::string(kMidiLabels[row]) + ", " + midiValue(track_, row);
    if (context) line = trackName() + ". Track MIDI. " + line +
        ". " + std::to_string(row + 1) + " of " + std::to_string(kMidiFields);
    return line;
}

void TrackNavigator::rememberTrackMidiPosition() {
    if (page_ != Page::trackMidi) return;
    memory_.setPosition("LastPage", "F6");
    memory_.setPosition("F6.TrackGUID", rowGuid());
    memory_.setPosition("F6.Row", std::to_string(trackMidiRow_));
}

bool TrackNavigator::enterTrackMidi() {
    if (!active_ || !project_ || !track_ ||
        !ValidatePtr2(project_, track_, "MediaTrack*") ||
        !GetMediaTrackInfo_Value || !SetMediaTrackInfo_Value) {
        speech_("REAPER track MIDI API unavailable");
        return false;
    }
    if (page_ == Page::trackMidi) {
        speech_(trackMidiReview(true));
        return true;
    }
    // F4 stores its own FX GUID/parameter cursor, independent of F6.
    rememberPosition();
    page_ = Page::trackMidi;
    valueMode_ = false;
    resetSelectionStroke();
    trackMidiEdge_.clear();
    trackMidiRow_ = 0;
    if (memory_.position("F6.TrackGUID") == rowGuid()) {
        try { trackMidiRow_ = std::clamp(std::stoi(memory_.position("F6.Row")), 0, 4); }
        catch (...) { trackMidiRow_ = 0; }
    }
    rememberTrackMidiPosition();
    announceTitle();
    return true;
}

void TrackNavigator::trackMidiMove(int row) {
    const int next = std::clamp(row, 0, kMidiFields - 1);
    if (next == trackMidiRow_) return; // Silent navigation edges.
    trackMidiRow_ = next;
    trackMidiEdge_.clear();
    rememberTrackMidiPosition();
    speech_(trackMidiReview(false));
}

void TrackNavigator::trackMidiAdjust(int direction, bool coarse, int edge) {
    if (!track_ || !project_ || !ValidatePtr2(project_, track_, "MediaTrack*")) {
        speech_("Track no longer available"); return;
    }
    if (trackMidiRow_ == 4) {
        speech_("MIDI routing is read only. Press Enter for Sends or Receives");
        return;
    }
    const int delta = direction >= 0 ? (coarse ? 4 : 1) : (coarse ? -4 : -1);
    const auto hw = readMidiHardware(track_);
    const int input = readMidiInfo(track_, "I_MIDI_INPUT_CHANMAP");
    const int control = readMidiInfo(track_, "I_MIDI_CTL_CHAN");
    int current = 0, next = 0, value = -1;
    const char* parm = nullptr;
    switch (trackMidiRow_) {
        case 0: {
            parm = "I_MIDIHWOUT";
            current = hw.raw < 0 ? -1 : hw.device;
            next = edge < 0 ? -1 : edge > 0 ? 31 : std::clamp(current + delta, -1, 31);
            value = next < 0 ? -1 : midiHardwareValue(next, hw.channel);
            break;
        }
        case 1: {
            if (hw.raw < 0) {
                speech_("Enable MIDI hardware output first"); return;
            }
            parm = "I_MIDIHWOUT";
            current = hw.channel;
            next = edge < 0 ? 0 : edge > 0 ? 16 : std::clamp(current + delta, 0, 16);
            value = midiHardwareValue(hw.device, next);
            break;
        }
        case 2: {
            parm = "I_MIDI_INPUT_CHANMAP";
            current = input < 0 ? 0 : std::clamp(input, 1, 16);
            next = edge < 0 ? 0 : edge > 0 ? 16 : std::clamp(current + delta, 0, 16);
            value = next == 0 ? -1 : next;
            break;
        }
        case 3: {
            parm = "I_MIDI_CTL_CHAN";
            current = control < 0 ? 0 : std::clamp(control + 1, 1, 17);
            next = edge < 0 ? 0 : edge > 0 ? 17 : std::clamp(current + delta, 0, 17);
            value = next == 0 ? -1 : next == 17 ? 16 : next - 1;
            break;
        }
        default: return;
    }
    if (next == current) {
        const std::string token = std::to_string(trackMidiRow_) + ":" + std::to_string(current);
        trackMidiEdge_ = token; // silent value bounds, as in the Lua

        return;
    }
    trackMidiEdge_.clear();
    // Avoid inventing hardware port names, modifying channel settings on an
    // inactive device or creating an undo point when the value is unchanged.
    if (Undo_BeginBlock2) Undo_BeginBlock2(project_);
    const bool written = SetMediaTrackInfo_Value(track_, parm, static_cast<double>(value));
    if (Undo_EndBlock2) Undo_EndBlock2(project_,
        (std::string("LReaParams: Track MIDI ") + kMidiLabels[trackMidiRow_]).c_str(), -1);
    // Only report success after REAPER confirms the actual value.
    if (!written || readMidiInfo(track_, parm) != value) {
        speech_(std::string(kMidiLabels[trackMidiRow_]) + " could not be changed");
        return;
    }
    if (TrackList_AdjustWindows) TrackList_AdjustWindows(false);
    if (UpdateArrange) UpdateArrange();
    speech_(trackMidiReview(false));
}

void TrackNavigator::handleTrackMidiKey(const Key& k) {
    if (k.ctrl && k.shift && !k.alt && k.vk == 'M') {
        if (!k.repeat) openTrackMemories(false);
        return;
    }
    if (k.repeat && (k.vk == VK_RETURN || (k.alt && k.vk == VK_HOME) ||
                     (k.alt && k.vk == VK_END))) return;
    if (!k.ctrl && !k.shift && !k.alt) {
        switch (k.vk) {
            case VK_OEM_5: speech_(trackMidiReview(false)); return; // Lua backslash repeats the current value
            case VK_F1: selectPage(Page::tracks); return;
            case VK_F2: selectPage(Page::sends); return;
            case VK_F3: selectPage(Page::receives); return;
            case VK_F4: selectPage(Page::fxTcp); return;
            case VK_F5: speech_("Select an FX in F4 first"); return;
            case VK_F6: case VK_TAB: speech_(trackMidiReview(true)); return;
            case VK_F7: if (!k.repeat) enterHardwareOutputs(); return;
            case VK_F8: if (!k.repeat) enterReaRoute(); return;
            case VK_ESCAPE: end(); return;
            case VK_UP: trackMidiMove(trackMidiRow_ - 1); return;
            case VK_DOWN: trackMidiMove(trackMidiRow_ + 1); return;
            case VK_PRIOR: trackMidiMove(trackMidiRow_ - 5); return;
            case VK_NEXT: trackMidiMove(trackMidiRow_ + 5); return;
            case VK_HOME: trackMidiMove(0); return;
            case VK_END: trackMidiMove(kMidiFields - 1); return;
            case VK_RETURN:
                if (trackMidiRow_ == 4) {
                    if (GetTrackNumSends(track_, 0) > 0) selectPage(Page::sends);
                    else if (GetTrackNumSends(track_, -1) > 0) selectPage(Page::receives);
                    else speech_("No sends or receives");
                } else trackMidiAdjust(1);
                return;
            case VK_SPACE: {
                const int state = GetPlayState ? GetPlayState() : 0;
                if ((state & 2) && OnPlayButton) OnPlayButton();
                else if (Main_OnCommand) Main_OnCommand(40044, 0);
                return;
            }
            default: return;
        }
    }
    if (!k.ctrl && !k.shift && k.alt) {
        switch (k.vk) {
            case VK_UP: trackMidiAdjust(1); return;
            case VK_DOWN: trackMidiAdjust(-1); return;
            case VK_PRIOR: trackMidiAdjust(1, true); return;
            case VK_NEXT: trackMidiAdjust(-1, true); return;
            case VK_HOME: trackMidiAdjust(1, false, 1); return;
            case VK_END: trackMidiAdjust(-1, false, -1); return;
            default: return;
        }
    }
    if (k.ctrl && !k.shift && !k.alt) {
        switch (k.vk) {
            case VK_HOME: trackMidiMove(0); return;
            case VK_END: trackMidiMove(kMidiFields - 1); return;
            case VK_SPACE: if (Main_OnCommand) Main_OnCommand(40073, 0); return;
            // The extension owns Ctrl+Tab/Ctrl+Q; do not swallow their state.
            case VK_TAB: case 'Q': return;
            default: return;
        }
    }
}
} // namespace lrp
