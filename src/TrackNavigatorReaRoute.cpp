#include "lrp/TrackNavigator.h"
#include <algorithm>
#include <array>
#include <cmath>
#include <iomanip>
#include <sstream>

namespace lrp {
namespace {
constexpr int kCategory = 1;
constexpr int kBase = 512;
constexpr int kMaxChannels = 16;
constexpr int kRows = 11;
constexpr std::array<const char*, kRows> kInputFields = {{
    "ReaRoute input", "Input enabled", "Input type", "Input channel or pair",
    "Input start", "Input width", "Track channels", "Input raw value",
    "Input note", "Output side", "ReaRoute note"
}};
constexpr std::array<const char*, kRows> kControlFields = {{
    "ReaRoute output", "ReaRoute output count", "Add ReaRoute output", "Output hint",
    "Output volume", "Output pan", "Output mute", "Output phase",
    "Output mono", "Output source", "Output destination"
}};
constexpr std::array<const char*, kRows> kOutputFields = {{
    "ReaRoute output", "Volume", "Pan", "Mute", "Phase invert", "Mono",
    "Audio source mode", "Audio source", "ReaRoute destination", "Send type", "Pan law"
}};
constexpr std::array<double, 4> kPanLaws = {{-1.0, 0.5, 0.7079457843841379, 1.0}};
int roundInt(double v) { return static_cast<int>(std::lround(v)); }
std::string format(double value, int decimals = 1) {
    std::ostringstream os; os << std::fixed << std::setprecision(decimals) << value; return os.str();
}
double inDb(double v) { return v <= 0 ? -150.0 : 20.0 * std::log10(v); }
double fromDb(double d) { return d <= -150.0 ? 0.0 : std::pow(10.0, d / 20.0); }
bool isRearouteDestination(int raw) {
    const int offset = raw & 1023;
    return offset >= kBase && offset < kBase + kMaxChannels;
}
int recType(int raw) {
    if (raw < 0 || !isRearouteDestination(raw)) return 0;
    if (raw & 2048) return 3;
    if (raw & 1024) return 2;
    return 1;
}
int recStart(int raw) { return isRearouteDestination(raw) ? (raw & 1023) - kBase + 1 : 1; }
int encodeRec(int type, int start) {
    if (type <= 0) return -1;
    const int maxStart = type == 2 ? kMaxChannels - 1 : kMaxChannels;
    return kBase + std::clamp(start, 1, maxStart) - 1 +
        (type == 2 ? 1024 : type == 3 ? 2048 : 0);
}
std::string recChannel(int raw) {
    const int type = recType(raw), start = recStart(raw);
    if (!type) return "Disabled";
    if (type == 1) return "ReaRoute " + std::to_string(start);
    // Mirrors the Lua presentation for multichannel input.
    return "ReaRoute " + std::to_string(start) + "/" + std::to_string(start+1);
}
std::string destChannel(int raw) {
    const int start = (raw & 1023) - kBase + 1;
    return "ReaRoute " + std::to_string(start) +
        ((raw & 1024) ? " mono" : "/" + std::to_string(start+1));
}
std::string srcChannel(int raw) {
    if (raw < 0) return "None";
    const int start = (raw & 1023) + 1;
    const int mode = raw >> 10;
    std::string text = "Channels " + std::to_string(start) + "/" + std::to_string(start+1);
    if (mode == 1) text += " mono";
    else if (mode > 1) text += " " + std::to_string(mode*2) + " channels";
    return text;
}
int panLawIndex(double value) {
    if (value < 0) return 0;
    int result=1;
    for (int i=2; i<4; ++i)
        if (std::abs(value-kPanLaws[i]) < std::abs(value-kPanLaws[result])) result=i;
    return result;
}
} // namespace

std::vector<int> TrackNavigator::reaRouteOutputIndexes() const {
    std::vector<int> output;
    if (!project_ || !track_ || !GetTrackNumSends || !GetTrackSendInfo_Value ||
        !ValidatePtr2(project_, track_, "MediaTrack*")) return output;
    const int total = std::clamp(GetTrackNumSends(track_, kCategory), 0, 512);
    for (int i=0; i<total; ++i) {
        const int raw = roundInt(GetTrackSendInfo_Value(track_, kCategory, i, "I_DSTCHAN"));
        if (isRearouteDestination(raw)) output.push_back(i);
    }
    return output;
}

std::string TrackNavigator::reaRouteReview(bool context) const {
    if (!track_ || !GetMediaTrackInfo_Value || !GetTrackSendInfo_Value) return "ReaRoute unavailable";
    const auto outputs = reaRouteOutputIndexes();
    const int col = std::clamp(reaRouteColumn_, 0, static_cast<int>(outputs.size())+1);
    const int row = std::clamp(reaRouteRow_, 0, kRows-1);
    std::string label, value;
    if (col == 0) {
        label = kInputFields[row];
        const int raw = roundInt(GetMediaTrackInfo_Value(track_, "I_RECINPUT"));
        const int type = recType(raw);
        switch (row) {
            case 0: case 3: value = recChannel(raw); break;
            case 1: value = type ? "Enabled" : "Disabled"; break;
            case 2: value = type == 0 ? "Disabled" : type == 1 ? "Mono" :
                type == 2 ? "Stereo" : "Multichannel"; break;
            case 4: value = type ? "ReaRoute " + std::to_string(recStart(raw)) : "Disabled"; break;
            case 5: value = type == 0 ? "Disabled" : type == 1 ? "1 channel" :
                type == 2 ? "2 channels" :
                std::to_string(std::clamp(roundInt(GetMediaTrackInfo_Value(track_, "I_NCHAN")),2,128)) + " track channels"; break;
            case 6: value = std::to_string(std::clamp(roundInt(GetMediaTrackInfo_Value(track_, "I_NCHAN")),2,128)); break;
            case 7: value = std::to_string(raw); break;
            case 8: value = "Track input only"; break;
            case 9: value = "Next column"; break;
            case 10: value = "Input and output bridge"; break;
        }
    } else if (col == 1) {
        label = kControlFields[row];
        const int count = static_cast<int>(outputs.size());
        switch (row) {
            case 0: value = std::to_string(count) + (count == 1 ? " output" : " outputs"); break;
            case 1: value = std::to_string(count); break;
            case 2: value = "Enter"; break;
            case 3: value = count ? "Output columns follow" : "No output yet"; break;
            default: value = count ? "Use output column" : "No output"; break;
        }
    } else {
        const int idx = outputs[static_cast<size_t>(col-2)];
        const auto get = [this,idx](const char* key) {return GetTrackSendInfo_Value(track_,kCategory,idx,key);};
        label = kOutputFields[row];
        const int src = roundInt(get("I_SRCCHAN"));
        const int dst = roundInt(get("I_DSTCHAN"));
        switch (row) {
            case 0: case 8: value = destChannel(dst); if (row == 0) value = "to " + value; break;
            case 1: { const double x=get("D_VOL"); value = x <= 0 ? "minus infinity dB" : format(inDb(x)) + " dB"; break; }
            case 2: { const double x=get("D_PAN"); value = std::abs(x) < 0.00001 ? "center" :
                format(std::abs(x)*100,0) + (x < 0 ? " percent left" : " percent right"); break; }
            case 3: value = get("B_MUTE") >= 0.5 ? "On" : "Off"; break;
            case 4: value = get("B_PHASE") >= 0.5 ? "On" : "Off"; break;
            case 5: value = get("B_MONO") >= 0.5 ? "On" : "Off"; break;
            case 6: { const int m=src < 0 ? -1 : std::clamp(src >> 10, 0, 8);
                value = m < 0 ? "None" : m == 0 ? "Stereo" : m == 1 ? "Mono" :
                    std::to_string(m*2) + " channels"; break; }
            case 7: value = srcChannel(src); break;
            case 9: { const int m=roundInt(get("I_SENDMODE"));
                value = m == 0 ? "Post fader" : m == 1 ? "Pre FX" :
                    m == 2 ? "Post FX deprecated" : m == 3 ? "Post FX" : "Mode " + std::to_string(m); break; }
            case 10: { const double law=get("D_PANLAW");
                value = law < 0 ? "Project default" : law <= 0 ? "minus infinity dB" : format(inDb(law)) + " dB"; break; }
        }
    }
    std::string message = label + ", " + value;
    if (context) {
        const std::string columnName = col == 0 ? "Input" : col == 1 ? "Output controls" :
            "Output " + std::to_string(col-1);
        message = trackName() + ". ReaRoute. " + columnName + ". " + message +
            ". Column " + std::to_string(col+1) + " of " + std::to_string(outputs.size()+2) +
            ". Row " + std::to_string(row+1) + " of " + std::to_string(kRows);
    } else if (row == 0 && col >= 2)
        message = "ReaRoute output " + std::to_string(col-1) + ", " + value;
    return message;
}

void TrackNavigator::rememberReaRoutePosition() {
    if (page_ != Page::reaRoute) return;
    memory_.setPosition("LastPage", "F8");
    memory_.setPosition("F8.TrackGUID", rowGuid());
    memory_.setPosition("F8.Row", std::to_string(reaRouteRow_));
    memory_.setPosition("F8.Column", std::to_string(reaRouteColumn_));
}

bool TrackNavigator::enterReaRoute() {
    if (!active_ || !project_ || !track_ || !ValidatePtr2(project_,track_,"MediaTrack*") ||
        !GetMediaTrackInfo_Value || !SetMediaTrackInfo_Value || !GetTrackNumSends ||
        !GetTrackSendInfo_Value || !SetTrackSendInfo_Value || !CreateTrackSend || !RemoveTrackSend) {
        speech_("ReaRoute API unavailable"); return false;
    }
    if (page_ == Page::reaRoute) { speech_(reaRouteReview(true)); return true; }
    rememberPosition();
    page_ = Page::reaRoute;
    resetSelectionStroke();
    valueMode_ = false;
    reaRouteColumn_ = reaRouteRow_ = 0;
    if (memory_.position("F8.TrackGUID") == rowGuid()) {
        try { reaRouteRow_ = std::clamp(std::stoi(memory_.position("F8.Row")),0,kRows-1); } catch (...) {}
        try { reaRouteColumn_ = std::clamp(std::stoi(memory_.position("F8.Column")),
            0, static_cast<int>(reaRouteOutputIndexes().size())+1); } catch (...) {}
    }
    rememberReaRoutePosition();
    announceTitle();
    return true;
}

void TrackNavigator::reaRouteMove(int column, int row) {
    const int c = std::clamp(column, 0, static_cast<int>(reaRouteOutputIndexes().size())+1);
    const int r = std::clamp(row, 0, kRows-1);
    if (c == reaRouteColumn_ && r == reaRouteRow_) return; // quiet borders
    const bool newColumn = c != reaRouteColumn_;
    reaRouteColumn_ = c;
    reaRouteRow_ = r;
    rememberReaRoutePosition();
    speech_(reaRouteReview(newColumn));
}

void TrackNavigator::reaRouteAdjust(int direction, bool coarse, int edge) {
    if (!project_ || !track_ || !ValidatePtr2(project_,track_,"MediaTrack*")) return;
    const int step = direction < 0 ? (coarse ? -4 : -1) : (coarse ? 4 : 1);
    const int row = reaRouteRow_;
    if (reaRouteColumn_ == 0) {
        const int oldRaw = roundInt(GetMediaTrackInfo_Value(track_,"I_RECINPUT"));
        const int type = recType(oldRaw), start = recStart(oldRaw);
        const char* parm = "I_RECINPUT";
        int newRaw = oldRaw;
        if (row == 1) {
            // Already disabled from a different physical/MIDI input: do not clear it.
            if (!type && ((edge == 0 && direction < 0) || edge < 0)) return;
            newRaw = encodeRec(edge < 0 ? 0 : edge > 0 ? (type ? type : 2) :
                direction > 0 ? (type ? type : 2) : 0, start);
        }
        else if (row == 2) newRaw = encodeRec(edge < 0 ? 0 : edge > 0 ? 3 :
            std::clamp(type+step,0,3),start);
        else if (row == 3 || row == 4) {
            const int activeType = type ? type : 2;
            const int maxStart = activeType == 2 ? 15 : 16;
            newRaw = encodeRec(activeType, edge < 0 ? 1 : edge > 0 ? maxStart :
                std::clamp(start+step,1,maxStart));
        } else if (row == 6) {
            parm = "I_NCHAN";
            const int oldChannels = std::clamp(roundInt(GetMediaTrackInfo_Value(track_,parm)),2,128);
            const int nextChannels = edge < 0 ? 2 : edge > 0 ? 128 :
                std::clamp(oldChannels+step*2,2,128);
            newRaw = nextChannels + (nextChannels & 1);
        } else { speech_(reaRouteReview(false) + ". Read only"); return; }
        const int previous = row == 6 ? roundInt(GetMediaTrackInfo_Value(track_, parm)) : oldRaw;
        if (row == 6 && newRaw < previous) return; // Lua track_ensure_channel_count only expands
        if (newRaw == previous) return;
        if (Undo_BeginBlock2) Undo_BeginBlock2(project_);
        const bool ok = SetMediaTrackInfo_Value(track_,parm,static_cast<double>(newRaw));
        const bool verify = ok && roundInt(GetMediaTrackInfo_Value(track_,parm)) == newRaw;
        if (Undo_EndBlock2) Undo_EndBlock2(project_, "LReaParams: ReaRoute track input", UNDO_STATE_TRACKCFG);
        if (!verify) { speech_("ReaRoute input change failed"); return; }
        if (TrackList_AdjustWindows) TrackList_AdjustWindows(false);
        if (UpdateArrange) UpdateArrange();
        speech_(reaRouteReview(false));
        return;
    }
    if (reaRouteColumn_ == 1) { speech_(reaRouteReview(false) + ". Read only"); return; }
    const auto outputs = reaRouteOutputIndexes();
    if (reaRouteColumn_-2 >= static_cast<int>(outputs.size())) { speech_("No ReaRoute output"); return; }
    const int idx = outputs[static_cast<size_t>(reaRouteColumn_-2)];
    const auto get = [this,idx](const char* key){return GetTrackSendInfo_Value(track_,kCategory,idx,key);};
    const int oldSource = roundInt(get("I_SRCCHAN"));
    const int oldDest = roundInt(get("I_DSTCHAN"));
    const double oldLaw = get("D_PANLAW");
    double previous = 0, value = 0;
    const char* parm = nullptr;
    int neededChannels = 0;
    switch (row) {
        case 1: {
            parm = "D_VOL"; previous = get(parm);
            const auto range = memory_.volumeRange("Sends");
            const double current = inDb(previous);
            value = fromDb(edge < 0 ? range.first : edge > 0 ? range.second :
                std::clamp(current + direction*(coarse ? 3.0 : 0.5),range.first,range.second));
            break;
        }
        case 2: parm = "D_PAN"; previous = get(parm);
            value = edge < 0 ? -1 : edge > 0 ? 1 :
                std::clamp(previous + direction*(coarse ? 0.1 : 0.01),-1.0,1.0); break;
        case 3: case 4: case 5: {
            parm = row == 3 ? "B_MUTE" : row == 4 ? "B_PHASE" : "B_MONO";
            previous = get(parm); value = edge < 0 ? 0 : edge > 0 ? 1 : direction > 0 ? 1 : 0;
            break;
        }
        case 6: {
            parm = "I_SRCCHAN"; previous = oldSource;
            if (oldSource < 0) { speech_("Audio source disabled. Change Audio source first"); return; }
            const int newMode = edge < 0 ? 0 : edge > 0 ? 8 : std::clamp((oldSource >> 10)+step,0,8);
            value = (oldSource & 1023) | (newMode << 10);
            neededChannels = (oldSource & 1023) + (newMode == 0 ? 2 : newMode == 1 ? 1 : newMode*2);
            break;
        }
        case 7: {
            parm = "I_SRCCHAN"; previous = oldSource;
            const int pair = oldSource < 0 ? -1 : (oldSource & 1023)/2;
            const int next = edge < 0 ? -1 : edge > 0 ? 63 : std::clamp(pair+step,-1,63);
            const int retained = oldSource < 0 ? 0 : oldSource & ~1023;
            value = next < 0 ? -1 : (retained | (next*2));
            const int smode = retained >> 10;
            neededChannels = next < 0 ? 0 : next*2 + (smode == 0 ? 2 : smode == 1 ? 1 : smode*2);
            break;
        }
        case 8: {
            parm = "I_DSTCHAN"; previous = oldDest;
            // Never allow F8 to convert a ReaRoute output into physical hardware.
            const int current = (oldDest & 1023) - kBase + 1;
            const int maxStart = (oldDest & 1024) ? 16 : 15;
            const int next = edge < 0 ? 1 : edge > 0 ? maxStart : std::clamp(current+step,1,maxStart);
            value = kBase + next-1 + (oldDest & 1024);
            break;
        }
        case 9: { parm = "I_SENDMODE"; previous = get(parm);
            value = edge < 0 ? 0 : edge > 0 ? 3 : std::clamp(roundInt(previous)+step,0,3); break; }
        case 10: { parm = "D_PANLAW"; previous = oldLaw;
            value = kPanLaws[edge < 0 ? 0 : edge > 0 ? 3 :
                std::clamp(panLawIndex(previous)+step,0,3)]; break; }
        default: speech_(reaRouteReview(false) + ". Read only"); return;
    }
    if (neededChannels > 128) { speech_("Audio source exceeds 128 track channels"); return; }
    if (std::abs(previous - value) < 0.000000001) return;
    const int oldCount = std::clamp(roundInt(GetMediaTrackInfo_Value(track_,"I_NCHAN")),2,128);
    const bool expand = neededChannels > oldCount;
    if (Undo_BeginBlock2) Undo_BeginBlock2(project_);
    bool expanded = !expand;
    if (expand) expanded = SetMediaTrackInfo_Value(track_,"I_NCHAN",(neededChannels+1)&~1);
    const bool ok = expanded && SetTrackSendInfo_Value(track_,kCategory,idx,parm,value);
    const bool verify = ok && std::abs(GetTrackSendInfo_Value(track_,kCategory,idx,parm)-value) <= 0.000001;
    if (!verify && expand && expanded) SetMediaTrackInfo_Value(track_,"I_NCHAN",oldCount);
    if (Undo_EndBlock2) Undo_EndBlock2(project_, "LReaParams: ReaRoute output parameter", UNDO_STATE_TRACKCFG);
    if (!verify) { speech_("ReaRoute output change failed"); return; }
    if (TrackList_AdjustWindows) TrackList_AdjustWindows(false);
    if (UpdateArrange) UpdateArrange();
    speech_(reaRouteReview(false));
}

void TrackNavigator::reaRouteAddOutput() {
    if (!project_ || !track_ || !ValidatePtr2(project_,track_,"MediaTrack*") ||
        !CreateTrackSend || !SetTrackSendInfo_Value || !RemoveTrackSend) return;
    if (Undo_BeginBlock2) Undo_BeginBlock2(project_);
    const int idx = CreateTrackSend(track_,nullptr);
    bool ok = idx >= 0;
    if (ok) {
        ok = SetTrackSendInfo_Value(track_,kCategory,idx,"I_DSTCHAN",static_cast<double>(kBase));
        ok = ok && roundInt(GetTrackSendInfo_Value(track_,kCategory,idx,"I_DSTCHAN")) == kBase;
        if (!ok) RemoveTrackSend(track_,kCategory,idx); // rollback physical output on error
    }
    if (Undo_EndBlock2) Undo_EndBlock2(project_, "LReaParams: add ReaRoute output", UNDO_STATE_TRACKCFG);
    if (!ok) { speech_("Could not create ReaRoute output"); return; }
    const auto outputs = reaRouteOutputIndexes();
    const auto pos = std::find(outputs.begin(),outputs.end(),idx);
    if (pos != outputs.end()) { reaRouteColumn_ = 2 + static_cast<int>(pos-outputs.begin()); reaRouteRow_ = 0; }
    rememberReaRoutePosition();
    if (TrackList_AdjustWindows) TrackList_AdjustWindows(false);
    if (UpdateArrange) UpdateArrange();
    speech_("Added ReaRoute output. " + reaRouteReview(true));
}

void TrackNavigator::reaRouteDelete() {
    const auto outputs = reaRouteOutputIndexes();
    if (reaRouteColumn_ < 2 || reaRouteColumn_-2 >= static_cast<int>(outputs.size())) {
        speech_("No ReaRoute output"); return;
    }
    const int index = outputs[static_cast<size_t>(reaRouteColumn_-2)];
    if (!isRearouteDestination(roundInt(GetTrackSendInfo_Value(track_,kCategory,index,"I_DSTCHAN")))) {
        speech_("Output is no longer ReaRoute"); return;
    }
    if (Undo_BeginBlock2) Undo_BeginBlock2(project_);
    const bool ok = RemoveTrackSend(track_,kCategory,index);
    if (Undo_EndBlock2) Undo_EndBlock2(project_, "LReaParams: delete ReaRoute output", UNDO_STATE_TRACKCFG);
    if (!ok) { speech_("ReaRoute output delete failed"); return; }
    reaRouteColumn_ = std::clamp(reaRouteColumn_,0,static_cast<int>(reaRouteOutputIndexes().size())+1);
    rememberReaRoutePosition();
    if (TrackList_AdjustWindows) TrackList_AdjustWindows(false);
    if (UpdateArrange) UpdateArrange();
    speech_("Deleted ReaRoute output. " + reaRouteReview(true));
}

void TrackNavigator::reaRouteEnter() {
    if (reaRouteColumn_ == 1 && reaRouteRow_ == 2) { reaRouteAddOutput(); return; }
    if (reaRouteColumn_ == 0) {
        if (reaRouteRow_ == 1) {
            const int raw = roundInt(GetMediaTrackInfo_Value(track_,"I_RECINPUT"));
            reaRouteAdjust(recType(raw) ? -1 : 1); return;
        }
        if (reaRouteRow_ == 8) { speech_("ReaRoute input belongs to the current track input. It does not change record arm or monitoring"); return; }
        if (reaRouteRow_ == 9) { speech_("ReaRoute outputs are in the next column"); return; }
    }
    if (reaRouteColumn_ >= 2 && reaRouteRow_ >= 3 && reaRouteRow_ <= 5) {
        const auto outputs = reaRouteOutputIndexes();
        if (reaRouteColumn_-2 < static_cast<int>(outputs.size())) {
            const int idx = outputs[static_cast<size_t>(reaRouteColumn_-2)];
            const char* key = reaRouteRow_ == 3 ? "B_MUTE" : reaRouteRow_ == 4 ? "B_PHASE" : "B_MONO";
            reaRouteAdjust(GetTrackSendInfo_Value(track_,kCategory,idx,key) >= 0.5 ? -1 : 1);
        }
        return;
    }
    if ((reaRouteColumn_ == 0 && (reaRouteRow_ == 2 || reaRouteRow_ == 3 || reaRouteRow_ == 4 || reaRouteRow_ == 6)) ||
        (reaRouteColumn_ >= 2 && reaRouteRow_ != 0)) {
        valueMode_ = !valueMode_;
        speech_(std::string(valueMode_ ? "Value, " : "Grid, ") + reaRouteReview(false));
        return;
    }
    speech_(reaRouteReview(true));
}

void TrackNavigator::handleReaRouteKey(const Key& k) {
    if (k.ctrl && k.shift && !k.alt && k.vk == 'M') { if (!k.repeat) openTrackMemories(false); return; }
    if (k.repeat && (k.vk == VK_RETURN || k.vk == VK_DELETE)) return;
    if (!k.ctrl && !k.shift && !k.alt) {
        switch (k.vk) {
            case VK_F1: selectPage(Page::tracks); return;
            case VK_F2: selectPage(Page::sends); return;
            case VK_F3: selectPage(Page::receives); return;
            case VK_F4: selectPage(Page::fxTcp); return;
            case VK_F5: speech_("Select an FX in F4 first"); return;
            case VK_F6: enterTrackMidi(); return;
            case VK_F7: enterHardwareOutputs(); return;
            case VK_F8: case VK_TAB: speech_(reaRouteReview(true)); return;
            case VK_OEM_5: speech_(reaRouteReview(false)); return;
            case VK_ESCAPE: if (valueMode_) { valueMode_ = false; speech_("Grid, " + reaRouteReview(false)); }
                else selectPage(Page::tracks); return;
            case VK_DELETE: reaRouteDelete(); return;
            case VK_UP: if (valueMode_) reaRouteAdjust(1); else reaRouteMove(reaRouteColumn_,reaRouteRow_-1); return;
            case VK_DOWN: if (valueMode_) reaRouteAdjust(-1); else reaRouteMove(reaRouteColumn_,reaRouteRow_+1); return;
            case VK_PRIOR: if (valueMode_) reaRouteAdjust(1,true); else reaRouteMove(reaRouteColumn_,reaRouteRow_-5); return;
            case VK_NEXT: if (valueMode_) reaRouteAdjust(-1,true); else reaRouteMove(reaRouteColumn_,reaRouteRow_+5); return;
            case VK_LEFT: reaRouteMove(reaRouteColumn_-1,reaRouteRow_); return;
            case VK_RIGHT: reaRouteMove(reaRouteColumn_+1,reaRouteRow_); return;
            case VK_HOME: reaRouteMove(reaRouteColumn_,0); return;
            case VK_END: reaRouteMove(reaRouteColumn_,kRows-1); return;
            case VK_RETURN: reaRouteEnter(); return;
            case VK_SPACE: {
                const int state=GetPlayState ? GetPlayState() : 0;
                if ((state & 2) && OnPlayButton) OnPlayButton();
                else if (Main_OnCommand) Main_OnCommand(40044,0);
                return;
            }
            default: return;
        }
    }
    if (k.alt && !k.ctrl && !k.shift) {
        switch (k.vk) {
            case VK_UP: reaRouteAdjust(1); return;
            case VK_DOWN: reaRouteAdjust(-1); return;
            case VK_PRIOR: reaRouteAdjust(1,true); return;
            case VK_NEXT: reaRouteAdjust(-1,true); return;
            case VK_HOME: reaRouteAdjust(1,false,1); return;
            case VK_END: reaRouteAdjust(-1,false,-1); return;
            default: return;
        }
    }
    if (k.ctrl && !k.alt && !k.shift) {
        if (k.vk == VK_HOME) { reaRouteMove(0,reaRouteRow_); return; }
        if (k.vk == VK_END) { reaRouteMove(static_cast<int>(reaRouteOutputIndexes().size())+1,reaRouteRow_); return; }
        if (k.vk == VK_TAB || k.vk == 'Q') return; // global router
        if (k.vk == VK_SPACE && Main_OnCommand) { Main_OnCommand(40073,0); return; }
    }
}
} // namespace lrp
