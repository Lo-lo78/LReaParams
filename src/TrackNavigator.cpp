#include "lrp/TrackNavigator.h"
#include <algorithm>
#include <cmath>
#include <cstring>
#include <iomanip>
#include <cstdio>
#include <sstream>
#include <stdexcept>

namespace lrp {
namespace {
constexpr double minDb = -150.0, maxDb = 48.0;
double db(double amplitude) { return amplitude <= 0 ? minDb : 20.0 * std::log10(amplitude); }
double amp(double decibels) { return decibels <= minDb ? 0.0 : std::pow(10.0, decibels / 20.0); }
std::string num(double v, int places = 1) {
    std::ostringstream o; o << std::fixed << std::setprecision(places) << v; return o.str();
}
// REAPER track names use UTF-8; convert them for the native NVDA window title.
std::wstring wideUtf8(const std::string& text) {
    if (text.empty()) return {};
    const int length = MultiByteToWideChar(CP_UTF8, 0, text.c_str(), -1, nullptr, 0);
    if (length <= 0) return {};
    std::wstring converted(static_cast<size_t>(length), L'\0');
    if (!MultiByteToWideChar(CP_UTF8, 0, text.c_str(), -1, converted.data(), length)) return {};
    converted.resize(static_cast<size_t>(length - 1));
    return converted;
}
}

// TEST49: preserve preferences even on an external REAPER action that closes
// navigation. All IO errors are reported without escaping a noexcept callback.
void TrackNavigator::end() noexcept {
    if (active_) {
        try { rememberPosition(); memory_.flush(); }
        catch (...) {
            OutputDebugStringW(L"LReaParams: Track Params memory could not be saved.\n");
            try { speech_("Track Params: memory not saved. Check Track CC Map.tp"); } catch (...) {}
        }
    }
    active_ = false; valueMode_ = false; rows_.clear(); entries_.clear();
}

bool TrackNavigator::begin() {
    end();
    project_ = EnumProjects(-1, nullptr, 0);
    if (!project_) { speech_("Track Params: no project"); return false; }
    trackCount_ = CountTracks(project_);
    initialSelection_ = GetSelectedTrack2(project_, 0, true);
    int nesting = 0;
    int hiddenLevel = -1;
    for (int i = 0; i < trackCount_; ++i) {
        auto* track = GetTrack(project_, i);
        if (!track) continue;
        const int depth = static_cast<int>(GetMediaTrackInfo_Value(track, "I_FOLDERDEPTH"));
        const bool underCollapsedFolder = hiddenLevel >= 0 && nesting > hiddenLevel;
        const bool visible = GetMediaTrackInfo_Value(track, "B_SHOWINTCP") > 0.5;
        if (visible && !underCollapsedFolder) {
            if (const GUID* guid = GetTrackGUID(track)) rows_.push_back({track, *guid, i});
        }
        if (!underCollapsedFolder && GetMediaTrackInfo_Value(track, "I_FOLDERCOMPACT") >= 2.0 && depth > 0)
            hiddenLevel = nesting;
        nesting = std::max(0, nesting + depth);
        if (hiddenLevel >= 0 && nesting <= hiddenLevel) hiddenLevel = -1;
    }
    if (rows_.empty()) { speech_("Track Params: no visible tracks"); return false; }
    memory_.load(resource_);
    row_ = 0;
    for (int i = 0; i < static_cast<int>(rows_.size()); ++i) {
        if (rows_[i].track == initialSelection_) { row_ = i; break; }
    }
    track_ = rows_[row_].track;
    parameter_ = detailIndex_ = 0;
    page_ = Page::tracks;
    valueMode_ = false;
    stepScale_ = 0;
    // Opening a different selected track must never unexpectedly jump to a
    // previously remembered track.  The current selection remains authoritative.
    restorePosition();
    active_ = true;
    return true;
}

bool TrackNavigator::contextUnchanged() const {
    if (!active_ || EnumProjects(-1, nullptr, 0) != project_ || CountTracks(project_) != trackCount_ ||
        row_ < 0 || row_ >= static_cast<int>(rows_.size())) return false;
    // An externally changed selection ends the session; moving between our
    // logical rows never changes REAPER's actual selected track.
    if (GetSelectedTrack2(project_, 0, true) != initialSelection_) return false;
    const auto& row = rows_[row_];
    if (GetTrack(project_, row.projectIndex) != row.track ||
        !ValidatePtr2(project_, row.track, "MediaTrack*")) return false;
    const auto* guid = GetTrackGUID(row.track);
    if (!guid || std::memcmp(guid, &row.guid, sizeof(GUID)) != 0 || track_ != row.track) return false;
    if (page_ != Page::tracks &&
        (GetTrackNumSends(track_, 0) != sends_ || GetTrackNumSends(track_, -1) != receives_)) return false;
    return true;
}

bool TrackNavigator::accepts(const Key& k) const noexcept {
    if (!active_ || (k.shift && !(k.ctrl && !k.alt && k.vk == 'T'))) return false;
    if (k.ctrl) return !k.alt && (k.vk == VK_HOME || k.vk == VK_END || k.vk == 'R' ||
                         k.vk == 'T' || k.vk == VK_BACK);
    if (k.alt) return k.vk == VK_UP || k.vk == VK_DOWN || k.vk == VK_PRIOR || k.vk == VK_NEXT || k.vk == VK_HOME || k.vk == VK_END || k.vk == VK_LEFT || k.vk == VK_RIGHT;
    switch (k.vk) {
        case VK_ESCAPE: case VK_RETURN:
        case VK_LEFT: case VK_RIGHT: case VK_UP: case VK_DOWN:
        case VK_HOME: case VK_END: case VK_PRIOR: case VK_NEXT:
        case VK_F1: case VK_F2: case VK_F3: return true;
        default: return false;
    }
}
void TrackNavigator::buildEntries() {
    entries_.clear();
    if (page_ == Page::tracks) {
        entries_ = {
            {"Volume", "D_VOL", 99, -1, Entry::volume},
            {"Pan", "D_PAN", 99, -1, Entry::pan},
            {"Width", "D_WIDTH", 99, -1, Entry::width},
            {"Mute", "B_MUTE", 99, -1, Entry::flag},
            {"Solo", "I_SOLO", 99, -1, Entry::solo},
            {"Phase invert", "B_PHASE", 99, -1, Entry::flag},
            {"Send count", "", 99, -1, Entry::sendCount},
            {"Receive count", "", 99, -1, Entry::receiveCount},
            {"FX count", "", 99, -1, Entry::fxCount}
        };
        return;
    }
    sends_ = std::clamp(GetTrackNumSends(track_, 0), 0, 512);
    receives_ = std::clamp(GetTrackNumSends(track_, -1), 0, 512);
    const int cat = page_ == Page::sends ? 0 : -1;
    const int count = cat == 0 ? sends_ : receives_;
    for (int i = 0; i < count; ++i) {
        // Exactly 14 vertically ordered fields per send/receive as in the Lua.
        entries_.push_back({cat == 0 ? "Send" : "Receive", "", cat, i, Entry::header});
        entries_.push_back({"Volume", "D_VOL", cat, i, Entry::volume});
        entries_.push_back({"Pan", "D_PAN", cat, i, Entry::pan});
        entries_.push_back({"Mute", "B_MUTE", cat, i, Entry::flag});
        entries_.push_back({"Audio source mode", "I_SRCCHAN", cat, i, Entry::audioSourceMode});
        entries_.push_back({"Audio source", "I_SRCCHAN", cat, i, Entry::audioSource});
        entries_.push_back({"Audio destination", "I_DSTCHAN", cat, i, Entry::audioDestination});
        entries_.push_back({"Send type", "I_SENDMODE", cat, i, Entry::sendType});
        entries_.push_back({"MIDI source", "I_MIDIFLAGS", cat, i, Entry::midiSource});
        entries_.push_back({"MIDI destination", "I_MIDIFLAGS", cat, i, Entry::midiDestination});
        entries_.push_back({"MIDI source bus", "I_MIDIFLAGS", cat, i, Entry::midiSourceBus});
        entries_.push_back({"MIDI destination bus", "I_MIDIFLAGS", cat, i, Entry::midiDestinationBus});
        entries_.push_back({"MIDI follows fader", "I_MIDIFLAGS", cat, i, Entry::midiFollowsFader});
        entries_.push_back({"MIDI merge", "I_MIDIFLAGS", cat, i, Entry::midiMerge});
    }
}
std::string TrackNavigator::pageKey() const {
    return page_ == Page::tracks ? "F1" : page_ == Page::sends ? "F2" : "F3";
}
std::string TrackNavigator::rowGuid() const {
    if (row_ < 0 || row_ >= static_cast<int>(rows_.size())) return {};
    const GUID& g = rows_[row_].guid;
    char text[64]{};
    std::snprintf(text, sizeof(text), "{%08lX-%04hX-%04hX-%02hhX%02hhX-%02hhX%02hhX%02hhX%02hhX%02hhX%02hhX}",
        static_cast<unsigned long>(g.Data1), static_cast<unsigned short>(g.Data2),
        static_cast<unsigned short>(g.Data3), g.Data4[0], g.Data4[1], g.Data4[2], g.Data4[3],
        g.Data4[4], g.Data4[5], g.Data4[6], g.Data4[7]);
    return text;
}
std::string TrackNavigator::parameterKey() const {
    const auto* e = current();
    if (!e) return {};
    const char* key = nullptr;
    switch (e->type) {
        case Entry::volume: key = "Volume"; break;
        case Entry::pan: key = "Pan"; break;
        case Entry::width: key = "Width"; break;
        case Entry::flag: key = e->parm == "B_PHASE" ? "PhaseInvert" : "Mute"; break;
        case Entry::solo: key = "Solo"; break;
        case Entry::sendCount: key = "SendCount"; break;
        case Entry::receiveCount: key = "ReceiveCount"; break;
        case Entry::fxCount: key = "FXCount"; break;
        case Entry::header: key = "Header"; break;
        case Entry::audioSourceMode: key = "AudioSourceMode"; break;
        case Entry::audioSource: key = "AudioSource"; break;
        case Entry::audioDestination: key = "AudioDestination"; break;
        case Entry::sendType: key = "SendType"; break;
        case Entry::midiSource: key = "MidiSource"; break;
        case Entry::midiDestination: key = "MidiDestination"; break;
        case Entry::midiSourceBus: key = "MidiSourceBus"; break;
        case Entry::midiDestinationBus: key = "MidiDestinationBus"; break;
        case Entry::midiFollowsFader: key = "MidiFollowsFader"; break;
        case Entry::midiMerge: key = "MidiMerge"; break;
    }
    return std::string(page_ == Page::tracks ? "Track." : page_ == Page::sends ? "Sends." : "Receives.") + key;
}
void TrackNavigator::rememberPosition() {
    if (rows_.empty() || !current()) return;
    const auto section = pageKey();
    memory_.setPosition("LastPage", section);
    memory_.setPosition(section + ".Parameter", parameterKey());
    memory_.setPosition(section + ".TrackGUID", rowGuid());
    if (page_ != Page::tracks) memory_.setPosition(section + ".Column", std::to_string(detailIndex_));
}
void TrackNavigator::restorePosition() {
    const auto savedPage = memory_.position("LastPage");
    if (savedPage == "F2" && GetTrackNumSends(track_, 0) > 0) page_ = Page::sends;
    else if (savedPage == "F3" && GetTrackNumSends(track_, -1) > 0) page_ = Page::receives;
    else page_ = Page::tracks;
    buildEntries();
    parameter_ = detailIndex_ = 0;
    const auto savedParameter = memory_.position(pageKey() + ".Parameter");
    const int limit = page_ == Page::tracks ? static_cast<int>(entries_.size()) : detailHeight;
    bool found = false;
    for (int i = 0; i < limit; ++i) {
        parameter_ = i;
        if (parameterKey() == savedParameter) { found = true; break; }
    }
    if (!found) parameter_ = 0;
    if (page_ != Page::tracks && memory_.position(pageKey() + ".TrackGUID") == rowGuid()) {
        try { const auto raw = memory_.position(pageKey() + ".Column");
            if (!raw.empty()) {
                std::size_t n = 0; const int index = std::stoi(raw, &n);
                if (n == raw.size()) detailIndex_ = std::clamp(index, 0, static_cast<int>(entries_.size()) / detailHeight - 1);
            }
        } catch (...) { detailIndex_ = 0; }
    }
    stepScale_ = memory_.step(parameterKey());
}
bool TrackNavigator::ccSpeechSupported() const {
    const auto* e = current();
    if (!e) return false;
    if (page_ == Page::tracks)
        return e->type == Entry::volume || e->type == Entry::pan || e->type == Entry::width ||
            e->type == Entry::flag || e->type == Entry::solo;
    return e->type == Entry::volume || e->type == Entry::pan || e->type == Entry::flag;
}

bool TrackNavigator::selectPage(Page page) {
    if (page == page_) return true; // Repeated page key is silent
    if (page == Page::sends && GetTrackNumSends(track_, 0) <= 0) { speech_("No sends"); return false; }
    if (page == Page::receives && GetTrackNumSends(track_, -1) <= 0) { speech_("No receives"); return false; }
    rememberPosition();
    page_ = page;
    parameter_ = detailIndex_ = 0;
    valueMode_ = false;
    buildEntries();
    // Restore this page's last parameter. Keep send-column memory only for
    // the same track GUID, not for unrelated newly selected tracks.
    const auto savedParameter = memory_.position(pageKey() + ".Parameter");
    const int limit = page_ == Page::tracks ? static_cast<int>(entries_.size()) : detailHeight;
    bool found = false;
    for (int i = 0; i < limit; ++i) {
        parameter_ = i;
        if (parameterKey() == savedParameter) { found = true; break; }
    }
    if (!found) parameter_ = 0;
    if (page_ != Page::tracks && memory_.position(pageKey() + ".TrackGUID") == rowGuid()) {
        try { const auto raw = memory_.position(pageKey() + ".Column");
            if (!raw.empty()) {
                std::size_t n = 0; const int index = std::stoi(raw, &n);
                if (n == raw.size()) detailIndex_ = std::clamp(index, 0, static_cast<int>(entries_.size()) / detailHeight - 1);
            }
        } catch (...) { detailIndex_ = 0; }
    }
    stepScale_ = memory_.step(parameterKey());
    rememberPosition();
    announceTitle();
    return true;
}
std::string TrackNavigator::trackName() const {
    char name[2048]{};
    if (track_ && GetTrackName(track_, name, sizeof(name)) && name[0]) return name;
    return "Track " + std::to_string(rows_.at(static_cast<size_t>(row_)).projectIndex + 1);
}
std::string TrackNavigator::detailPeerName(int category, int index) const {
    char name[2048]{};
    if (category == 0) {
        // GetTrackSendName indexes the hardware outputs before the sends.
        const int sendOffset = GetTrackNumSends(track_, 1);
        if (GetTrackSendName(track_, index + sendOffset, name, sizeof(name)) && name[0]) return name;
    } else if (category == -1) {
        if (GetTrackReceiveName(track_, index, name, sizeof(name)) && name[0]) return name;
    }
    return "Unknown track";
}
const TrackNavigator::Entry* TrackNavigator::current() const {
    const int index = page_ == Page::tracks ? parameter_ : detailIndex_ * detailHeight + parameter_;
    if (index < 0 || index >= static_cast<int>(entries_.size())) return nullptr;
    return &entries_[static_cast<size_t>(index)];
}
double TrackNavigator::get(const Entry& e) const {
    if (e.type == Entry::sendCount) return GetTrackNumSends(track_, 0);
    if (e.type == Entry::receiveCount) return GetTrackNumSends(track_, -1);
    if (e.type == Entry::fxCount) return TrackFX_GetCount(track_);
    if (e.type == Entry::header) return 0.0;
    const double value = e.index < 0 ? GetMediaTrackInfo_Value(track_, e.parm.c_str()) :
        GetTrackSendInfo_Value(track_, e.category, e.index, e.parm.c_str());
    if (e.type == Entry::audioSourceMode || e.type == Entry::audioSource ||
        e.type == Entry::audioDestination || e.type == Entry::sendType ||
        e.type == Entry::midiSource || e.type == Entry::midiDestination ||
        e.type == Entry::midiSourceBus || e.type == Entry::midiDestinationBus ||
        e.type == Entry::midiFollowsFader || e.type == Entry::midiMerge) {
        const int bits = static_cast<int>(value);
        switch (e.type) {
            case Entry::audioSourceMode: return bits < 0 ? -1 : (bits >> 10) & 255;
            case Entry::audioSource: return bits < 0 ? -1 : (bits & 1023) / 2;
            case Entry::audioDestination: return bits & 1023;
            case Entry::midiSource: return bits & 31;
            case Entry::midiDestination: return (bits >> 5) & 31;
            case Entry::midiSourceBus: return (bits >> 14) & 255;
            case Entry::midiDestinationBus: return (bits >> 22) & 255;
            case Entry::midiFollowsFader: return (bits & 1024) ? 1 : 0;
            case Entry::midiMerge: return (bits & 31) == 31 ? 0 : 1;
            default: break;
        }
    }
    return value;
}
void TrackNavigator::put(const Entry& e, double value) {
    if (!contextUnchanged() || !std::isfinite(value)) throw std::runtime_error("Track context changed");
    if (e.type == Entry::header || e.type == Entry::sendCount ||
        e.type == Entry::receiveCount || e.type == Entry::fxCount || e.type == Entry::midiMerge) {
        speech_("Read only"); return;
    }
    if (get(e) == value) return; // silent boundary: no change
    std::string parm = e.parm;
    double raw = value;
    // Preserve unrelated MIDI bits (other bus/channel/fader settings).
    if (e.type == Entry::midiSource || e.type == Entry::midiDestination ||
        e.type == Entry::midiSourceBus || e.type == Entry::midiDestinationBus ||
        e.type == Entry::midiFollowsFader) {
        int bits = static_cast<int>(GetTrackSendInfo_Value(track_, e.category, e.index, "I_MIDIFLAGS"));
        const int n = static_cast<int>(value);
        if (e.type == Entry::midiSource) bits = (bits & ~31) | (n & 31);
        else if (e.type == Entry::midiDestination) bits = (bits & ~(31 << 5)) | ((n & 31) << 5);
        else if (e.type == Entry::midiSourceBus) bits = (bits & ~(255 << 14)) | ((n & 255) << 14);
        else if (e.type == Entry::midiDestinationBus) bits = (bits & ~(255 << 22)) | ((n & 255) << 22);
        else bits = value >= 0.5 ? bits | 1024 : bits & ~1024;
        raw = static_cast<double>(bits);
    } else if (e.type == Entry::audioSourceMode) {
        const int old = static_cast<int>(GetTrackSendInfo_Value(track_, e.category, e.index, "I_SRCCHAN"));
        if (old < 0) { speech_("Audio source disabled. Change Audio source first."); return; }
        raw = static_cast<double>((old & 1023) | (static_cast<int>(value) << 10));
    } else if (e.type == Entry::audioSource || e.type == Entry::audioDestination) {
        // Editing pair indices needs channel-count validation like the Lua;
        // leave this advanced change disabled until that API migration is done.
        speech_("Audio routing edit not yet migrated"); return;
    }
    struct UndoScope {
        ReaProject* project;
        explicit UndoScope(ReaProject* p) : project(p) { Undo_BeginBlock2(p); }
        ~UndoScope() { Undo_EndBlock2(project, "LReaParams: track or routing control", UNDO_STATE_TRACKCFG); }
    } undo(project_);
    const bool ok = e.index < 0 ? SetMediaTrackInfo_Value(track_, parm.c_str(), raw) :
        SetTrackSendInfo_Value(track_, e.category, e.index, parm.c_str(), raw);
    if (!ok) throw std::runtime_error("REAPER refused track change");
    if (memory_.valueSpeech(parameterKey())) speech_(valueText(e, get(e)));
}
std::string TrackNavigator::valueText(const Entry& e, double value) const {
    if (e.type == Entry::header) return (e.category == 0 ? "to " : "from ") + detailPeerName(e.category, e.index);
    if (e.type == Entry::sendCount || e.type == Entry::receiveCount || e.type == Entry::fxCount)
        return std::to_string(static_cast<int>(value));
    if (e.type == Entry::flag || e.type == Entry::midiFollowsFader || e.type == Entry::midiMerge)
        return value > 0.5 ? "on" : "off";
    if (e.type == Entry::solo) return value >= 0.5 ? "on" : "off";
    if (e.type == Entry::volume) return value <= 0 ? "minus infinity dB" : num(db(value)) + " dB";
    if (e.type == Entry::pan) return std::abs(value) < 0.00001 ? "center" :
        num(std::abs(value) * 100.0, 0) + (value < 0 ? " percent left" : " percent right");
    if (e.type == Entry::width) return num(value * 100.0, 0) + " percent";
    if (e.type == Entry::audioSourceMode) {
        if (value < 0) return "None";
        if (value == 0) return "Stereo";
        if (value == 1) return "Mono";
        return std::to_string(static_cast<int>(value * 2)) + " channels";
    }
    if (e.type == Entry::audioSource) return value < 0 ? "None" : "Channels " +
        std::to_string(static_cast<int>(value) * 2 + 1) + "/" + std::to_string(static_cast<int>(value) * 2 + 2);
    if (e.type == Entry::audioDestination) return "channel " + std::to_string(static_cast<int>(value) + 1);
    if (e.type == Entry::sendType) {
        switch (static_cast<int>(value)) {
            case 0: return "Post fader";
            case 1: return "Pre FX";
            case 2: case 3: return "Post FX";
            case 8: return "Pre receive";
            default: return "Mode " + std::to_string(static_cast<int>(value));
        }
    }
    if (e.type == Entry::midiSource) {
        if (value == 31) return "None";
        if (value == 0) return "All";
        return "Channel " + std::to_string(static_cast<int>(value));
    }
    if (e.type == Entry::midiDestination) {
        if (value == 0) return "Original";
        return "Channel " + std::to_string(static_cast<int>(value));
    }
    if (e.type == Entry::midiSourceBus || e.type == Entry::midiDestinationBus) {
        if (value == 0) return "All buses";
        return "Bus " + std::to_string(static_cast<int>(value));
    }
    return num(value);
}
std::string TrackNavigator::currentParameterSpeech() const {
    if (!contextUnchanged()) throw std::runtime_error("Track context changed");
    const auto* e = current();
    if (!e) return trackName() + (page_ == Page::sends ? ", no sends" : page_ == Page::receives ? ", no receives" : ", no parameters");
    if (page_ == Page::tracks) return trackName() + ", " + e->title + ", " + valueText(*e, get(*e));
    const char* label = page_ == Page::sends ? "Send " : "Receive ";
    return trackName() + ", " + label + std::to_string(e->index + 1) +
        (page_ == Page::sends ? " to " : " from ") + detailPeerName(e->category, e->index) +
        ", " + e->title + ", " + valueText(*e, get(*e));
}
std::string TrackNavigator::reviewLine() const {
    if (!active_) return "";
    // NVDA+Up in Grid reviews only the parameter and value, like FX Params.
    // Track/page names remain available via NVDA+T. Moving between tracks
    // continues to announce the track name; Ctrl+R still reviews context.
    if (!valueMode_) return parameterValueSpeech();
    const auto* e = current();
    return e ? "Value, " + e->title + ", " + valueText(*e, get(*e)) : parameterValueSpeech();
}
bool TrackNavigator::nativeValueSlider() const {
    if (!active_ || !valueMode_) return false;
    const auto* e = current();
    return e && (e->type == Entry::volume || e->type == Entry::pan || e->type == Entry::width);
}
double TrackNavigator::valueFraction() const {
    const auto* e = current();
    if (!e || !nativeValueSlider()) return 0.0;
    const double value = get(*e);
    if (e->type == Entry::volume) return std::clamp((db(value) - minDb) / (maxDb - minDb), 0.0, 1.0);
    return std::clamp((value + 1.0) / 2.0, 0.0, 1.0);
}
std::string TrackNavigator::sliderLabel() const {
    const auto* e = current();
    return e ? e->title : "";
}
// Grid movement within the same track announces only the focused control.
// The full track/parameter/value context stays available for NVDA+Up,
// Ctrl+R and changes of track row.
std::string TrackNavigator::parameterValueSpeech() const {
    if (!contextUnchanged()) throw std::runtime_error("Track context changed");
    const auto* e = current();
    if (!e) return page_ == Page::sends ? "No sends" :
                   page_ == Page::receives ? "No receives" : "No parameters";
    return e->title + ", " + valueText(*e, get(*e));
}
void TrackNavigator::announce() { speech_(parameterValueSpeech()); }
void TrackNavigator::announceTrack() { speech_(currentParameterSpeech()); }
void TrackNavigator::announceTitle() {
    if (!active_) return;
    const std::string pageSuffix = page_ == Page::tracks ? "" :
                                   page_ == Page::sends ? " - Sends" : " - Receives";
    speech_("Track Params - " + trackName() + pageSuffix +
            (valueMode_ ? " - Value. " : ". ") + currentParameterSpeech());
}
std::wstring TrackNavigator::windowTitle() const {
    if (!active_) return L"Track Params";
    const wchar_t* pageSuffix = page_ == Page::tracks ? L"" :
                                page_ == Page::sends ? L" - Sends" : L" - Receives";
    return std::wstring(L"Track Params - ") + wideUtf8(trackName()) + pageSuffix +
           (valueMode_ ? L" - Value" : L"");
}
void TrackNavigator::moveTrack(int delta) {
    if (page_ != Page::tracks) return;
    const int next = std::clamp(row_ + delta, 0, static_cast<int>(rows_.size()) - 1);
    if (next != row_) { row_ = next; track_ = rows_[row_].track; rememberPosition(); announceTrack(); }
}
void TrackNavigator::moveParameter(int delta) {
    if (entries_.empty()) return;
    const int limit = page_ == Page::tracks ? 8 : detailHeight - 1;
    const int next = std::clamp(parameter_ + delta, 0, limit);
    if (next != parameter_) { parameter_ = next; stepScale_ = memory_.step(parameterKey()); rememberPosition(); announce(); }
}
void TrackNavigator::moveDetailColumn(int delta) {
    if (page_ == Page::tracks || entries_.empty()) return;
    const int count = static_cast<int>(entries_.size()) / detailHeight;
    const int next = std::clamp(detailIndex_ + delta, 0, count - 1);
    if (next != detailIndex_) { detailIndex_ = next; rememberPosition(); announce(); }
}
void TrackNavigator::toggle(const Entry& e) {
    if (e.type != Entry::flag && e.type != Entry::solo && e.type != Entry::midiFollowsFader) return;
    put(e, get(e) >= 0.5 ? 0.0 : 1.0);
}
void TrackNavigator::nudge(int direction, bool coarse) {
    const auto* e = current();
    if (!e) return;
    const double old = get(*e);
    const double factor = std::pow(2.0, memory_.step(parameterKey()));
    double next = old;
    switch (e->type) {
        case Entry::volume: next = amp(std::clamp(db(old) + (coarse ? 3.0 : 0.5) * factor * direction, minDb, maxDb)); break;
        case Entry::pan: case Entry::width: next = std::clamp(old + direction * (coarse ? 0.1 : 0.01) * factor, -1.0, 1.0); break;
        case Entry::flag: case Entry::solo: case Entry::midiFollowsFader: next = direction > 0 ? 1.0 : 0.0; break;
        case Entry::audioSourceMode: next = std::clamp(old + direction, 0.0, 8.0); break;
        case Entry::sendType: {
            // Defined REAPER modes: post-fader, pre-FX, post-FX, pre-receive.
            const int modes[] = {0, 1, 3, 8};
            int i = 0;
            while (i < 3 && modes[i] < static_cast<int>(old)) ++i;
            next = modes[std::clamp(i + direction, 0, 3)]; break;
        }
        case Entry::midiSource: {
            // All, 1..16, None (31).
            const int oldIndex = old == 31 ? 17 : std::clamp(static_cast<int>(old), 0, 16);
            const int idx = std::clamp(oldIndex + direction, 0, 17);
            next = idx == 17 ? 31 : idx; break;
        }
        case Entry::midiDestination: next = std::clamp(old + direction, 0.0, 16.0); break;
        case Entry::midiSourceBus: case Entry::midiDestinationBus:
            next = std::clamp(old + direction * (coarse ? 8.0 : 1.0), 0.0, 255.0); break;
        default: speech_("Read only or not yet migrated"); return;
    }
    put(*e, next);
}
void TrackNavigator::handle(const Key& k) {
    if (!contextUnchanged()) throw std::runtime_error("Track context changed");
    if (k.ctrl && !k.alt && !k.shift && k.vk == 'R') {
        if (!k.repeat) speech_(currentParameterSpeech() + ". Step " +
            std::to_string(memory_.step(parameterKey())) +
            (memory_.valueSpeech(parameterKey()) ? ". Value speech on" : ". Value speech off") +
            (ccSpeechSupported() ? (memory_.ccSpeech(page_ == Page::tracks ? "Track" : page_ == Page::sends ? "Sends" : "Receives",
                parameterKey().substr(parameterKey().find('.') + 1)) ? ". MIDI speech on" : ". MIDI speech off") : ""));
        return;
    }
    if (k.ctrl && !k.alt && k.vk == 'T') {
        if (k.repeat || !current()) return;
        if (k.shift) {
            const auto id = parameterKey();
            const bool on = !memory_.valueSpeech(id);
            memory_.setValueSpeech(id, on); memory_.flush();
            speech_(on ? "Value speech on" : "Value speech off");
        } else {
            if (!ccSpeechSupported()) { speech_("MIDI speech not available for this field"); return; }
            const auto id = parameterKey();
            const auto page = page_ == Page::tracks ? "Track" : page_ == Page::sends ? "Sends" : "Receives";
            const auto bare = id.substr(id.find('.') + 1);
            const bool on = !memory_.ccSpeech(page, bare);
            memory_.setCcSpeech(page, bare, on); memory_.flush();
            speech_(std::string(on ? "MIDI speech on" : "MIDI speech off") + ". MIDI control will arrive in a later test");
        }
        return;
    }
    if (k.ctrl && !k.alt && !k.shift && k.vk == VK_BACK) {
        if (k.repeat || !current()) return;
        memory_.setStep(parameterKey(), 0); stepScale_ = 0; memory_.flush();
        speech_("Step 0"); return;
    }
    if (k.vk == VK_ESCAPE) {
        if (valueMode_) { valueMode_ = false; announceTitle(); }
        else if (page_ != Page::tracks) selectPage(Page::tracks);
        else end();
        return;
    }
    if (k.vk == VK_F1) { selectPage(Page::tracks); return; }
    if (k.vk == VK_F2) { selectPage(Page::sends); return; }
    if (k.vk == VK_F3) { selectPage(Page::receives); return; }
    if (k.vk == VK_RETURN) {
        if (k.repeat) return;
        const auto* e = current();
        // On/Off controls change directly: no Value window, no extra Enter.
        if (e && (e->type == Entry::flag || e->type == Entry::solo || e->type == Entry::midiFollowsFader)) {
            toggle(*e); return;
        }
        if (page_ == Page::tracks && e) {
            if (e->type == Entry::sendCount) { selectPage(Page::sends); return; }
            if (e->type == Entry::receiveCount) { selectPage(Page::receives); return; }
            if (e->type == Entry::fxCount) { speech_("Track FX page not yet migrated. Use FX Params."); return; }
        }
        // Detail headers and other read-only entries do not open an empty Value mode.
        if (!e || e->type == Entry::header || e->type == Entry::audioSource ||
            e->type == Entry::audioDestination || e->type == Entry::midiMerge) {
            announce(); return;
        }
        valueMode_ = !valueMode_;
        if (valueMode_) speech_(reviewLine());
        else announceTitle();
        return;
    }
    if (k.ctrl && k.vk == VK_HOME) {
        if (page_ == Page::tracks) moveTrack(-row_);
        else moveDetailColumn(-detailIndex_);
        return;
    }
    if (k.ctrl && k.vk == VK_END) {
        if (page_ == Page::tracks) moveTrack(static_cast<int>(rows_.size()) - 1 - row_);
        else moveDetailColumn(static_cast<int>(entries_.size()) / detailHeight - 1 - detailIndex_);
        return;
    }
    if (k.alt || valueMode_) {
        if (k.vk == VK_LEFT || k.vk == VK_RIGHT) {
            const int next = std::clamp(stepScale_ + (k.vk == VK_LEFT ? -1 : 1), -10, 10);
            if (next != stepScale_) {
                stepScale_ = next;
                memory_.setStep(parameterKey(), stepScale_);
                memory_.flush();
                speech_("Step " + std::to_string(stepScale_));
            }
        }
        else if (k.vk == VK_UP || k.vk == VK_DOWN || k.vk == VK_PRIOR || k.vk == VK_NEXT)
            nudge(k.vk == VK_UP || k.vk == VK_PRIOR ? 1 : -1, k.vk == VK_PRIOR || k.vk == VK_NEXT);
        else if (k.vk == VK_HOME || k.vk == VK_END) {
            const auto* e = current();
            if (!e) return;
            const bool high = k.vk == VK_HOME; // Lua: Home maximum, End minimum
            switch (e->type) {
                case Entry::volume: put(*e, high ? amp(maxDb) : 0.0); break;
                case Entry::pan: case Entry::width: put(*e, high ? 1.0 : -1.0); break;
                case Entry::flag: case Entry::solo: case Entry::midiFollowsFader: put(*e, high ? 1.0 : 0.0); break;
                case Entry::audioSourceMode: put(*e, high ? 8.0 : 0.0); break;
                case Entry::sendType: put(*e, high ? 8.0 : 0.0); break;
                case Entry::midiSource: put(*e, high ? 31.0 : 0.0); break;
                case Entry::midiDestination: put(*e, high ? 16.0 : 0.0); break;
                case Entry::midiSourceBus: case Entry::midiDestinationBus: put(*e, high ? 255.0 : 0.0); break;
                default: break; // read-only/unfinished fields remain silent
            }
        }
        return;
    }
    if (k.vk == VK_HOME) { moveParameter(-parameter_); return; }
    if (k.vk == VK_END) { moveParameter((page_ == Page::tracks ? 8 : detailHeight - 1) - parameter_); return; }
    // F1: left/right = parameters, up/down = tracks.
    // F2/F3: left/right = SEND/RECEIVE COLUMNS, up/down = 14 vertical fields.
    if (k.vk == VK_LEFT) { if (page_ == Page::tracks) moveParameter(-1); else moveDetailColumn(-1); return; }
    if (k.vk == VK_RIGHT) { if (page_ == Page::tracks) moveParameter(1); else moveDetailColumn(1); return; }
    if (k.vk == VK_UP) { if (page_ == Page::tracks) moveTrack(-1); else moveParameter(-1); return; }
    if (k.vk == VK_DOWN) { if (page_ == Page::tracks) moveTrack(1); else moveParameter(1); return; }
    if (k.vk == VK_PRIOR) { if (page_ == Page::tracks) moveTrack(-5); else moveParameter(-5); return; }
    if (k.vk == VK_NEXT) { if (page_ == Page::tracks) moveTrack(5); else moveParameter(5); return; }
}
} // namespace lrp
