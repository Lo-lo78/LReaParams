#include "lrp/TrackNavigator.h"
#include <algorithm>
#include <array>
#include <cmath>
#include <iomanip>
#include <sstream>

namespace lrp {
namespace {
constexpr int kHardwareCategory = 1;
constexpr int kRows = 11;
constexpr std::array<const char*, kRows> kFields = {{
    "Hardware output", "Volume", "Pan", "Mute", "Phase invert", "Mono",
    "Audio source mode", "Audio source", "Hardware destination", "Send type", "Pan law"
}};
constexpr std::array<double, 4> kPanLaw = {{-1.0, 0.5, 0.7079457843841379, 1.0}};
std::string number(double v, int decimals=1) {
    std::ostringstream s; s << std::fixed << std::setprecision(decimals) << v;
    return s.str();
}
double db(double v) { return v <= 0 ? -150.0 : 20 * std::log10(v); }
double amp(double d) { return d <= -150.0 ? 0.0 : std::pow(10.0, d / 20); }
int panLawIndex(double v) {
    if (v < 0) return 0;
    int best = 1;
    for (int i=2; i<4; ++i)
        if (std::abs(kPanLaw[i]-v) < std::abs(kPanLaw[best]-v)) best=i;
    return best;
}
int nextSendMode(int mode, int direction) {
    // 2 is a legacy REAPER value. Do not silently normalize it on read.
    constexpr std::array<int,4> modes = {{0,1,2,3}};
    const auto it = std::find(modes.begin(), modes.end(), mode);
    const int index = it == modes.end() ? 0 : static_cast<int>(it-modes.begin());
    return modes[std::clamp(index+direction, 0, 3)];
}
std::string pairText(int raw, bool source) {
    if (source && raw < 0) return "None";
    const int offset = raw & 1023;
    if (!source && offset >= 512) {
        return "ReaRoute " + std::to_string(offset - 511) + ((raw & 1024) ? " mono" : "");
    }
    std::string s = "Channels " + std::to_string(offset+1) + "/" + std::to_string(offset+2);
    if (source) {
        const int mode = raw >> 10;
        if (mode == 1) s += " mono";
        else if (mode > 1) s += " " + std::to_string(mode*2) + " channels";
    } else if (raw & 1024) s += " mono";
    return s;
}
} // namespace

std::vector<int> TrackNavigator::hardwareOutputIndexes() const {
    std::vector<int> indexes;
    if (!track_ || !project_ || !ValidatePtr2(project_, track_, "MediaTrack*") ||
        !GetTrackNumSends || !GetTrackSendInfo_Value) return indexes;
    const int total = std::clamp(GetTrackNumSends(track_, kHardwareCategory), 0, 512);
    for (int i=0; i<total; ++i) {
        // Physical hardware output destination indices are below the ReaRoute base.
        const int raw = static_cast<int>(GetTrackSendInfo_Value(track_, kHardwareCategory, i, "I_DSTCHAN"));
        if ((raw & 1023) < 512) indexes.push_back(i);
    }
    return indexes;
}
int TrackNavigator::hardwareOutputCount() const {
    return static_cast<int>(hardwareOutputIndexes().size());
}

std::string TrackNavigator::hardwareOutputReview(bool context) const {
    const int count = hardwareOutputCount();
    if (count <= 0) return "No hardware outputs";
    const int column = std::clamp(hardwareOutputColumn_, 0, count-1);
    const int field = std::clamp(hardwareOutputRow_, 0, kRows-1);
    const int idx = hardwareOutputIndexes()[static_cast<size_t>(column)];
    const auto get = [this,idx](const char* key) { return GetTrackSendInfo_Value(track_, kHardwareCategory, idx, key); };
    const int source = static_cast<int>(get("I_SRCCHAN"));
    const int dest = static_cast<int>(get("I_DSTCHAN"));
    std::string value;
    switch (field) {
        case 0: value = "to " + pairText(dest, false); break;
        case 1: { const double level = get("D_VOL"); value = level <= 0 ? "minus infinity dB" : number(db(level)) + " dB"; break; }
        case 2: { const double pan = get("D_PAN"); value = std::abs(pan) < 0.00001 ? "center" :
            number(std::abs(pan)*100, 0) + (pan < 0 ? " percent left" : " percent right"); break; }
        case 3: value = get("B_MUTE") >= 0.5 ? "On" : "Off"; break;
        case 4: value = get("B_PHASE") >= 0.5 ? "On" : "Off"; break;
        case 5: value = get("B_MONO") >= 0.5 ? "On" : "Off"; break;
        case 6: { const int mode = source < 0 ? -1 : std::clamp(source >> 10, 0, 8);
            value = mode < 0 ? "None" : mode == 0 ? "Stereo" : mode == 1 ? "Mono" :
                std::to_string(mode*2) + " channels"; break; }
        case 7: value = pairText(source, true); break;
        case 8: value = pairText(dest, false); break;
        case 9: { const int m=static_cast<int>(get("I_SENDMODE"));
            value = m == 0 ? "Post fader" : m == 1 ? "Pre FX" : m == 2 ? "Post FX deprecated" :
                m == 3 ? "Post FX" : "Mode " + std::to_string(m); break; }
        case 10: { const double law = get("D_PANLAW");
            value = law < 0 ? "Project default" : law <= 0 ? "minus infinity dB" : number(db(law)) + " dB"; break; }
    }
    std::string message = std::string(kFields[field]) + ", " + value;
    if (context) message = trackName() + ". Hardware output " + std::to_string(column+1) +
        " of " + std::to_string(count) + ". " + message +
        ". Row " + std::to_string(field+1) + " of " + std::to_string(kRows);
    else if (field == 0) message = "Hardware output " + std::to_string(column+1) + ", " + value;
    return message;
}

void TrackNavigator::rememberHardwareOutputPosition() {
    if (page_ != Page::hardwareOutputs) return;
    memory_.setPosition("LastPage", "F7");
    memory_.setPosition("F7.TrackGUID", rowGuid());
    memory_.setPosition("F7.Row", std::to_string(hardwareOutputRow_));
    memory_.setPosition("F7.Column", std::to_string(hardwareOutputColumn_));
}

bool TrackNavigator::enterHardwareOutputs() {
    if (!active_ || !project_ || !track_ || !ValidatePtr2(project_, track_, "MediaTrack*") ||
        !GetTrackNumSends || !GetTrackSendInfo_Value || !SetTrackSendInfo_Value || !RemoveTrackSend) {
        speech_("Hardware output API unavailable"); return false;
    }
    const int count = hardwareOutputCount();
    if (!count) { speech_(trackName() + ". No hardware outputs"); return false; }
    if (page_ == Page::hardwareOutputs) { speech_(hardwareOutputReview(true)); return true; }
    rememberPosition();
    page_ = Page::hardwareOutputs;
    valueMode_ = false;
    resetSelectionStroke();
    hardwareOutputRow_ = hardwareOutputColumn_ = 0;
    if (memory_.position("F7.TrackGUID") == rowGuid()) {
        try { hardwareOutputRow_ = std::clamp(std::stoi(memory_.position("F7.Row")), 0, kRows-1); } catch (...) {}
        try { hardwareOutputColumn_ = std::clamp(std::stoi(memory_.position("F7.Column")), 0, count-1); } catch (...) {}
    }
    rememberHardwareOutputPosition();
    announceTitle();
    return true;
}

void TrackNavigator::hardwareOutputMove(int column, int row) {
    const int count = hardwareOutputCount();
    if (!count) { speech_("No hardware outputs"); return; }
    const int c = std::clamp(column, 0, count-1), r = std::clamp(row, 0, kRows-1);
    if (c == hardwareOutputColumn_ && r == hardwareOutputRow_) return; // silent borders
    const bool newColumn = c != hardwareOutputColumn_;
    hardwareOutputColumn_ = c; hardwareOutputRow_ = r;
    hardwareOutputEdge_.clear();
    rememberHardwareOutputPosition();
    speech_(hardwareOutputReview(newColumn));
}

void TrackNavigator::hardwareOutputAdjust(int direction, bool coarse, int edge) {
    const int count = hardwareOutputCount();
    if (count <= 0) { speech_("No hardware outputs"); return; }
    const int col = std::clamp(hardwareOutputColumn_, 0, count-1);
    const int row = hardwareOutputRow_;
    if (row == 0) { speech_("Hardware output header. Read only"); return; }
    const int idx = hardwareOutputIndexes()[static_cast<size_t>(col)];
    const auto get = [this,idx](const char* key) { return GetTrackSendInfo_Value(track_, 1, idx, key); };
    const double oldLevel = get("D_VOL");
    const double oldPan = get("D_PAN");
    const int source = static_cast<int>(get("I_SRCCHAN"));
    const int dest = static_cast<int>(get("I_DSTCHAN"));
    const int mode = static_cast<int>(get("I_SENDMODE"));
    const double oldLaw = get("D_PANLAW");
    const char* parm = nullptr;
    double value = 0, previous = 0;
    int sourceChannelsNeeded = 0;
    const int step = direction >= 0 ? (coarse ? 4 : 1) : (coarse ? -4 : -1);
    switch (row) {
        case 1: {
            parm = "D_VOL"; previous = oldLevel;
            const auto range = memory_.volumeRange("Sends");
            const double current = oldLevel <= 0 ? -150.0 : db(oldLevel);
            const double d = edge < 0 ? range.first : edge > 0 ? range.second :
                std::clamp(current + (coarse ? 3.0 : 0.5) * direction, range.first, range.second);
            value = amp(d); break;
        }
        case 2: parm = "D_PAN"; previous = oldPan; value = edge < 0 ? -1 : edge > 0 ? 1 :
            std::clamp(oldPan + direction*(coarse ? 0.1 : 0.01), -1.0, 1.0); break;
        case 3: case 4: case 5: {
            parm = row == 3 ? "B_MUTE" : row == 4 ? "B_PHASE" : "B_MONO";
            previous = get(parm);
            value = edge < 0 ? 0 : edge > 0 ? 1 : direction > 0 ? 1 : 0;
            break;
        }
        case 6: {
            parm = "I_SRCCHAN"; previous = source;
            if (source < 0) { speech_("Audio source disabled. Change Audio source first"); return; }
            const int oldMode = std::clamp(source >> 10, 0, 8);
            const int newMode = edge < 0 ? 0 : edge > 0 ? 8 : std::clamp(oldMode + step, 0, 8);
            value = (source & 1023) | (newMode << 10);
            // A multichannel source must fit the existing track, without silently resizing it.
            const int width = newMode == 0 ? 2 : newMode == 1 ? 1 : newMode * 2;
            sourceChannelsNeeded = (source & 1023) + width;
            if (sourceChannelsNeeded > 128) { speech_("Audio source exceeds 128 channels"); return; }
            break;
        }
        case 7: {
            parm = "I_SRCCHAN"; previous = source;
            const int oldPair = source < 0 ? -1 : (source & 1023) / 2;
            const int next = edge < 0 ? -1 : edge > 0 ? 63 : std::clamp(oldPair + step, -1, 63);
            const int retained = source >= 0 ? source & ~1023 : 0;
            value = next < 0 ? -1 : (retained | (next*2));
            const int smode = (retained >> 10);
            const int width = smode == 0 ? 2 : smode == 1 ? 1 : smode*2;
            sourceChannelsNeeded = next >= 0 ? next*2 + width : 0;
            if (sourceChannelsNeeded > 128) { speech_("Audio source exceeds 128 channels"); return; }
            break;
        }
        case 8: {
            parm = "I_DSTCHAN"; previous = dest;
            const int oldPair = ((dest & 1023) >= 512) ? 0 : (dest & 1023)/2;
            const int next = edge < 0 ? 0 : edge > 0 ? 63 : std::clamp(oldPair + step, 0, 63);
            // Preserve mono; switch ReaRoute to a physical hardware destination ONLY when user edits it.
            value = (dest & 1024) | (next * 2); break;
        }
        case 9: {
            parm = "I_SENDMODE"; previous = mode;
            const int oldIndex = std::clamp(mode, 0, 3);
            value = edge < 0 ? 0 : edge > 0 ? 3 : nextSendMode(oldIndex, step); break;
        }
        case 10: {
            parm = "D_PANLAW"; previous = oldLaw;
            const int current = panLawIndex(oldLaw);
            const int next = edge < 0 ? 0 : edge > 0 ? 3 : std::clamp(current+step, 0, 3);
            value = kPanLaw[next]; break;
        }
        default: return;
    }
    if (std::abs(previous-value) < 0.00000000001) return; // unchanged: quiet, no Undo
    // Lua send_ensure_audio_source_channels widens the source track before routing.
    // Keep the same behavior, never exceeding 128, and restore on failed send write.
    const int oldTrackChannels = GetMediaTrackInfo_Value ?
        std::clamp(static_cast<int>(GetMediaTrackInfo_Value(track_, "I_NCHAN")), 2, 128) : 2;
    const int evenChannels = std::min(128, (sourceChannelsNeeded + 1) & ~1);
    const bool mustExpand = sourceChannelsNeeded > oldTrackChannels;
    if (mustExpand && (!GetMediaTrackInfo_Value || !SetMediaTrackInfo_Value)) {
        speech_("REAPER track channel API unavailable"); return;
    }
    if (Undo_BeginBlock2) Undo_BeginBlock2(project_);
    bool expanded = false;
    if (mustExpand) {
        expanded = SetMediaTrackInfo_Value(track_, "I_NCHAN", evenChannels);
        if (!expanded) {
            if (Undo_EndBlock2) Undo_EndBlock2(project_, "LReaParams: hardware source channel expansion refused", UNDO_STATE_TRACKCFG);
            speech_("Could not expand track channels"); return;
        }
    }
    const bool ok = SetTrackSendInfo_Value(track_, kHardwareCategory, idx, parm, value);
    const bool readBack = ok && std::abs(GetTrackSendInfo_Value(track_, kHardwareCategory, idx, parm)-value) <= 0.000001;
    if (!readBack && expanded) SetMediaTrackInfo_Value(track_, "I_NCHAN", oldTrackChannels);
    if (Undo_EndBlock2) Undo_EndBlock2(project_,
        (std::string("LReaParams: hardware output ") + kFields[row]).c_str(), UNDO_STATE_TRACKCFG);
    if (!readBack) {
        speech_(std::string(kFields[row]) + " could not be changed"); return;
    }
    hardwareOutputEdge_.clear();
    if (TrackList_AdjustWindows) TrackList_AdjustWindows(false);
    if (UpdateArrange) UpdateArrange();
    speech_(hardwareOutputReview(false));
}

void TrackNavigator::deleteHardwareOutput() {
    if (!RemoveTrackSend || hardwareOutputCount() == 0) { speech_("No hardware outputs"); return; }
    const int oldCount = hardwareOutputCount();
    const int logical = std::clamp(hardwareOutputColumn_, 0, oldCount-1);
    const int target = hardwareOutputIndexes()[static_cast<size_t>(logical)];
    if (Undo_BeginBlock2) Undo_BeginBlock2(project_);
    const bool removed = RemoveTrackSend(track_, kHardwareCategory, target);
    if (Undo_EndBlock2) Undo_EndBlock2(project_, "LReaParams: delete hardware output", UNDO_STATE_TRACKCFG);
    if (!removed) { speech_("Hardware output delete failed"); return; }
    if (TrackList_AdjustWindows) TrackList_AdjustWindows(false);
    if (UpdateArrange) UpdateArrange();
    const int count = hardwareOutputCount();
    hardwareOutputColumn_ = count ? std::clamp(logical, 0, count-1) : 0;
    rememberHardwareOutputPosition();
    // When empty, return to F1 so stale hardware indexes cannot be reused.
    if (!count) {
        selectPage(Page::tracks);
        speech_("Deleted. No hardware outputs");
    } else speech_("Deleted hardware output. " + hardwareOutputReview(true));
}

void TrackNavigator::handleHardwareOutputsKey(const Key& k) {
    if (k.ctrl && k.shift && !k.alt && k.vk == 'M') { if (!k.repeat) openTrackMemories(false); return; }
    if (k.repeat && (k.vk == VK_RETURN || k.vk == VK_DELETE)) return;
    if (!k.ctrl && !k.alt && !k.shift) {
        switch (k.vk) {
            case VK_F1: selectPage(Page::tracks); return;
            case VK_F2: selectPage(Page::sends); return;
            case VK_F3: selectPage(Page::receives); return;
            case VK_F4: selectPage(Page::fxTcp); return;
            case VK_F5: speech_("Select an FX in F4 first"); return;
            case VK_F6: enterTrackMidi(); return;
            case VK_F7: case VK_TAB: speech_(hardwareOutputReview(true)); return;
            case VK_F8: if (!k.repeat) enterReaRoute(); return;
            case VK_ESCAPE: if (valueMode_) { valueMode_ = false; speech_("Grid, " + hardwareOutputReview(false)); }
                else selectPage(Page::tracks); return;
            case VK_DELETE: deleteHardwareOutput(); return;
            case VK_UP: if (valueMode_) hardwareOutputAdjust(1); else hardwareOutputMove(hardwareOutputColumn_, hardwareOutputRow_-1); return;
            case VK_DOWN: if (valueMode_) hardwareOutputAdjust(-1); else hardwareOutputMove(hardwareOutputColumn_, hardwareOutputRow_+1); return;
            case VK_PRIOR: if (valueMode_) hardwareOutputAdjust(1,true); else hardwareOutputMove(hardwareOutputColumn_, hardwareOutputRow_-5); return;
            case VK_NEXT: if (valueMode_) hardwareOutputAdjust(-1,true); else hardwareOutputMove(hardwareOutputColumn_, hardwareOutputRow_+5); return;
            case VK_LEFT: hardwareOutputMove(hardwareOutputColumn_-1, hardwareOutputRow_); return;
            case VK_RIGHT: hardwareOutputMove(hardwareOutputColumn_+1, hardwareOutputRow_); return;
            case VK_HOME: hardwareOutputMove(hardwareOutputColumn_, 0); return;
            case VK_END: hardwareOutputMove(hardwareOutputColumn_, kRows-1); return;
            case VK_RETURN:
                if (hardwareOutputCount() == 0) { speech_("No hardware outputs"); return; }
                if (hardwareOutputRow_ == 3 || hardwareOutputRow_ == 4 || hardwareOutputRow_ == 5)
                    hardwareOutputAdjust(GetTrackSendInfo_Value(track_, 1,
                        hardwareOutputIndexes()[static_cast<size_t>(std::clamp(hardwareOutputColumn_, 0, hardwareOutputCount()-1))],
                        hardwareOutputRow_ == 3 ? "B_MUTE" : hardwareOutputRow_ == 4 ? "B_PHASE" : "B_MONO") >= 0.5 ? -1 : 1);
                else if (hardwareOutputRow_ == 0) speech_(hardwareOutputReview(true));
                else { valueMode_ = !valueMode_; speech_(std::string(valueMode_ ? "Value, " : "Grid, ") + hardwareOutputReview(false)); }
                return;
            case VK_SPACE: {
                const int play = GetPlayState ? GetPlayState() : 0;
                if ((play & 2) && OnPlayButton) OnPlayButton();
                else if (Main_OnCommand) Main_OnCommand(40044, 0);
                return;
            }
            default: return;
        }
    }
    if (k.alt && !k.ctrl && !k.shift) {
        switch (k.vk) {
            case VK_UP: hardwareOutputAdjust(1); return;
            case VK_DOWN: hardwareOutputAdjust(-1); return;
            case VK_PRIOR: hardwareOutputAdjust(1, true); return;
            case VK_NEXT: hardwareOutputAdjust(-1, true); return;
            case VK_HOME: hardwareOutputAdjust(1, false, 1); return;
            case VK_END: hardwareOutputAdjust(-1, false, -1); return;
            default: return;
        }
    }
    if (k.ctrl && !k.alt && !k.shift) {
        if (k.vk == VK_HOME) { hardwareOutputMove(0, hardwareOutputRow_); return; }
        if (k.vk == VK_END) { hardwareOutputMove(hardwareOutputCount()-1, hardwareOutputRow_); return; }
        if (k.vk == VK_TAB || k.vk == 'Q') return; // handled by the top-level router
        if (k.vk == VK_SPACE && Main_OnCommand) { Main_OnCommand(40073, 0); return; }
    }
}
} // namespace lrp
