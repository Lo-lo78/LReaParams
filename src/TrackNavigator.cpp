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
    if (active_ && !backgroundMode_) {
        try { rememberPosition(); memory_.flush(); }
        catch (...) {
            OutputDebugStringW(L"LReaParams: Track Params memory could not be saved.\n");
            try { speech_("Track Params: project memory not saved. Check the project .tp"); } catch (...) {}
        }
    }
    memoryManager_ = memoryStandalone_ = false; memoryItems_.clear();
    active_ = false; valueMode_ = false; filterEditing_ = false; numericEditing_ = false;
    rangeEditing_ = false; resetMidiState();
    backgroundMode_ = false; clearAutomationConfirm_ = false; clearAutomationYes_ = false;
    filterBuffer_.clear(); filterQuery_.clear(); resetSelectionStroke(); resetPendingRouting(); rows_.clear(); entries_.clear();
}

bool TrackNavigator::begin() {
    // Consume the FX owner's real track BEFORE clearing our navigation state.
    MediaTrack* explicitTrack = nextStartTrack_;
    nextStartTrack_ = nullptr;
    end();
    project_ = EnumProjects(-1, nullptr, 0);
    if (!project_) { speech_("Track Params: no project"); return false; }
    trackCount_ = CountTracks(project_);
    initialSelection_ = GetSelectedTrack2(project_, 0, true);
    rebuildVisibleRows();
    if (rows_.empty()) { speech_("Track Params: no visible tracks"); return false; }
    if (explicitTrack) {
        if (!ValidatePtr2(project_, explicitTrack, "MediaTrack*")) {
            speech_("Track no longer available"); return false;
        }
        const auto entry = std::find_if(rows_.begin(), rows_.end(),
            [explicitTrack](const TrackRow& row) { return row.track == explicitTrack; });
        if (entry == rows_.end()) {
            speech_("Track is hidden in the TCP"); return false;
        }
        // No stale row or previous F1 cursor may override the FX context.
        initialSelection_ = explicitTrack;
    }
    char projectFilename[4096]{};
    EnumProjects(-1, projectFilename, static_cast<int>(sizeof(projectFilename)));
    memory_.load(resource_, projectFilename);
    // Persisted Fixed CC is re-enabled on every entry, never silently lost.
    fixedCc_ = memory_.fixedEnabled();
    row_ = 0;
    for (int i = 0; i < static_cast<int>(rows_.size()); ++i) {
        if (rows_[i].track == initialSelection_) { row_ = i; break; }
    }
    track_ = rows_[row_].track;
    parameter_ = detailIndex_ = 0;
    page_ = Page::tracks;
    valueMode_ = false;
    resetSelectionStroke();
    resetPendingRouting();
    lastEndFolderTrackIndex_ = -1;
    nextEndFolderIndex_ = 0;
    stepScale_ = 0;
    // Opening a different selected track must never unexpectedly jump to a
    // previously remembered track.  The current selection remains authoritative.
    restorePosition();
    midiSequence_ = 0; // populated by pollMidi before consuming subsequent controller input
    active_ = true;
    // Synchronize an explicitly transferred FX track only after the navigator
    // has initialized successfully. Normal entry preserves F1 multi-selection.
    if (explicitTrack) syncCursorToReaper();
    return true;
}

bool TrackNavigator::contextUnchanged() const {
    // A parked Ctrl+Q context must survive ordinary TCP selection changes.
    // All fixed targets are resolved again by GUID on every MIDI event.
    if (backgroundMode_) return active_ && project_ &&
        EnumProjects(-1, nullptr, 0) == project_ &&
        track_ && ValidatePtr2(project_, track_, "MediaTrack*");
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
    if (!active_ || k.altGr) return false;
    // While asking for confirmation, no navigation key may reach the TCP.
    if (clearAutomationConfirm_) return true;
    if (memoryManager_) {
        if (k.ctrl && k.shift && !k.alt && k.vk == 'M') return true;
        if (k.shift) return false;
        if (k.ctrl) return !k.alt && (k.vk == VK_HOME || k.vk == VK_END);
        if (k.alt) return k.vk == VK_LEFT || k.vk == VK_RIGHT;
        switch (k.vk) {
            case VK_ESCAPE: case VK_TAB: case VK_RETURN: case VK_DELETE:
            case VK_UP: case VK_DOWN: case VK_LEFT: case VK_RIGHT:
            case VK_HOME: case VK_END: case VK_PRIOR: case VK_NEXT: return true;
            default: return false;
        }
    }
    if (filterEditing_ || numericEditing_) {
        // The standard EDIT handles actual typing, selection and clipboard.
        // Only accept navigation-ending keys; other keys must never reach
        // REAPER's Main section while the text field has focus.
        return k.vk == VK_RETURN || k.vk == VK_ESCAPE ||
            (k.ctrl && !k.alt && !k.shift && k.vk == 'F');
    }
    if (k.ctrl && k.shift && !k.alt && k.vk == 'M') return true;
    if (page_ == Page::tracks && !k.alt && k.ctrl &&
        k.vk >= VK_F1 && k.vk <= VK_F12) return true;
    const bool f1 = page_ == Page::tracks;
    // Ctrl+R and Ctrl+Shift+V are intentionally free.  Tab provides info,
    // Enter toggles Grid/Value, and Ctrl+Alt+Up/Down moves among folders.
    // Never swallow unknown shortcuts from REAPER, and do not leak selection
    // gestures to the TCP while this owned keyboard window is active.
    if (k.ctrl && !k.alt && !k.shift && (k.vk == VK_TAB || k.vk == 'Q')) return true;
    if (k.ctrl && k.shift && k.alt && !k.altGr && k.vk == 'A') return true;
    if (k.ctrl && k.alt) return !k.shift && (k.vk == 'C' || (f1 && (k.vk == VK_UP || k.vk == VK_DOWN)));
    if (k.alt && k.shift) return f1 && !k.ctrl && (k.vk == VK_UP || k.vk == VK_DOWN);
    if (k.ctrl && k.shift) return !k.alt && (k.vk == 'C' || k.vk == 'T' ||
        (k.vk == 'S' || k.vk == 'R' || k.vk == 'A' || k.vk == 'I') || (f1 && k.vk == VK_DELETE) ||
        (f1 && (k.vk == VK_SPACE || k.vk == VK_UP || k.vk == VK_DOWN)));
    if (k.shift) return !k.alt && !k.ctrl && (k.vk == 'C' || (f1 &&
        (k.vk == VK_SPACE || k.vk == VK_UP || k.vk == VK_DOWN ||
         k.vk == VK_PRIOR || k.vk == VK_NEXT)));
    if (k.ctrl) return !k.alt && (k.vk == 'E' || k.vk == 'F' || k.vk == VK_HOME || k.vk == VK_END ||
        k.vk == 'T' || k.vk == VK_BACK || k.vk == VK_DELETE || k.vk == VK_SPACE || (!f1 && (k.vk == VK_UP || k.vk == VK_DOWN)) || (f1 && (k.vk == VK_RETURN || k.vk == 'A' || k.vk == 'C' ||
            k.vk == 'X' || k.vk == 'V' || k.vk == VK_DELETE)));
    if (k.alt) return k.vk == VK_UP || k.vk == VK_DOWN || k.vk == VK_PRIOR ||
        k.vk == VK_NEXT || k.vk == VK_HOME || k.vk == VK_END ||
        k.vk == VK_LEFT || k.vk == VK_RIGHT;
    switch (k.vk) {
        case VK_ESCAPE: case VK_RETURN: case VK_TAB: case VK_SPACE:
        case VK_LEFT: case VK_RIGHT: case VK_UP: case VK_DOWN:
        case VK_HOME: case VK_END: case VK_PRIOR: case VK_NEXT:
        case VK_F1: case VK_F2: case VK_F3: return true;
        case VK_DELETE: return true; // F1 deselect; F2/F3 remove current routing
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
        if (!routeMatchesFilter(track_, cat, i)) continue;
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
    if (page_ != Page::tracks) {
        const auto* e = current();
        memory_.setPosition(section + ".Column", std::to_string(e ? e->index : detailIndex_));
    }
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
                if (n == raw.size()) {
                    const int count = static_cast<int>(entries_.size()) / detailHeight;
                    for (int col = 0; col < count; ++col) {
                        if (entries_[static_cast<size_t>(col * detailHeight)].index == index) {
                            detailIndex_ = col; break;
                        }
                    }
                }
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
    if (page == Page::tracks && !filterQuery_.empty()) {
        bool found = false;
        for (int i = 0; i < CountTracks(project_); ++i) {
            MediaTrack* candidate = GetTrack(project_, i);
            if (candidate && GetMediaTrackInfo_Value(candidate, "B_SHOWINTCP") > 0.5 &&
                trackMatchesFilter(candidate)) { found = true; break; }
        }
        if (!found) { speech_("No matching tracks. Clear filter with Ctrl F"); return false; }
    }
    if (page == Page::sends && GetTrackNumSends(track_, 0) <= 0) { speech_("No sends"); return false; }
    if (page == Page::receives && GetTrackNumSends(track_, -1) <= 0) { speech_("No receives"); return false; }
    if (page != Page::tracks && matchingRoutingCount(track_, page == Page::sends ? 0 : -1) == 0) {
        speech_(page == Page::sends ? "No matching sends" : "No matching receives"); return false;
    }
    rememberPosition();
    resetSelectionStroke();
    const GUID guid = rows_[static_cast<size_t>(row_)].guid;
    page_ = page;
    rebuildVisibleRows();
    // A filter applies to F1 track rows, while F2/F3 search each routing
    // column.  Reanchor by GUID, never a stale index into a filtered list.
    row_ = 0;
    for (int i = 0; i < static_cast<int>(rows_.size()); ++i)
        if (std::memcmp(&rows_[static_cast<size_t>(i)].guid, &guid, sizeof(GUID)) == 0) { row_ = i; break; }
    track_ = rows_[static_cast<size_t>(row_)].track;
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
                if (n == raw.size()) {
                    const int count = static_cast<int>(entries_.size()) / detailHeight;
                    for (int col = 0; col < count; ++col) {
                        if (entries_[static_cast<size_t>(col * detailHeight)].index == index) {
                            detailIndex_ = col; break;
                        }
                    }
                }
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
    if (!GetSetTrackSendInfo) return "Unknown track";
    const char* field = category == 0 ? "P_DESTTRACK" : "P_SRCTRACK";
    auto* peer = static_cast<MediaTrack*>(
        GetSetTrackSendInfo(track_, category, index, field, nullptr));
    if (!peer || !ValidatePtr2(project_, peer, "MediaTrack*")) return "Unknown track";
    char name[2048]{};
    if (GetTrackName(peer, name, sizeof(name)) && name[0]) return name;
    const int number = static_cast<int>(GetMediaTrackInfo_Value(peer, "IP_TRACKNUMBER"));
    return number > 0 ? "Track " + std::to_string(number) : "Master track";
}
// Index is the true REAPER send/receive index, not a filtered column.
// Number only the 2nd, 3rd, ... connection to the *same* peer.  A different
// peer inserted between two Bass sends does not affect the Bass ordinal.
int TrackNavigator::detailPeerOccurrence(int category, int index) const {
    if (!GetSetTrackSendInfo || index < 0) return 1;
    const char* field = category == 0 ? "P_DESTTRACK" : "P_SRCTRACK";
    auto* target = static_cast<MediaTrack*>(
        GetSetTrackSendInfo(track_, category, index, field, nullptr));
    if (!target || !ValidatePtr2(project_, target, "MediaTrack*")) return 1;
    int ordinal = 0;
    for (int i = 0; i <= index; ++i) {
        auto* other = static_cast<MediaTrack*>(
            GetSetTrackSendInfo(track_, category, i, field, nullptr));
        if (other == target) ++ordinal;
    }
    return std::max(1, ordinal);
}
const TrackNavigator::Entry* TrackNavigator::current() const {
    const int index = page_ == Page::tracks ? parameter_ : detailIndex_ * detailHeight + parameter_;
    if (index < 0 || index >= static_cast<int>(entries_.size())) return nullptr;
    return &entries_[static_cast<size_t>(index)];
}
MediaTrack* TrackNavigator::routingEndpoint(const Entry& e, bool source) const {
    if (e.category == 0 && source) return track_;
    if (e.category == -1 && !source) return track_;
    if (!GetSetTrackSendInfo) return nullptr;
    const char* parm = source ? "P_SRCTRACK" : "P_DESTTRACK";
    auto* peer = static_cast<MediaTrack*>(GetSetTrackSendInfo(track_, e.category, e.index, parm, nullptr));
    return peer && ValidatePtr2(project_, peer, "MediaTrack*") ? peer : nullptr;
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
            case Entry::audioSourceMode: return bits < 0 ? 0 : std::clamp(bits >> 10, 0, 8);
            case Entry::audioSource: return bits < 0 ? -1 : (bits & 1023) / 2;
            case Entry::audioDestination: return (bits & 1023) / 2;
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
    if (e.type == Entry::volume) {
        // The project's Ctrl+Shift+I range is authoritative for every write
        // path, not just arrow nudges and Home/End: MIDI, numeric edits and
        // Value must never circumvent the configured limits.
        const auto range = memory_.volumeRange(page_ == Page::tracks ? "Track" :
            page_ == Page::sends ? "Sends" : "Receives");
        value = amp(std::clamp(db(value), range.first, range.second));
    }
    if (get(e) == value) return; // silent boundary: no change
    std::string parm = e.parm;
    double raw = value;
    MediaTrack* channelTrack = nullptr;
    int previousChannelCount = 0;
    int requiredChannels = 0;
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
    } else if (e.type == Entry::audioSourceMode || e.type == Entry::audioSource ||
               e.type == Entry::audioDestination) {
        // REAPER uses -1 for disabled audio, a ten-bit channel offset and
        // independent mode bits.  Never write a displayed pair number as a
        // raw I_SRCCHAN/I_DSTCHAN value. Keep mode/mono flags intact.
        const bool source = e.type != Entry::audioDestination;
        const char* field = source ? "I_SRCCHAN" : "I_DSTCHAN";
        const int old = static_cast<int>(GetTrackSendInfo_Value(track_, e.category, e.index, field));
        int bits = old;
        if (e.type == Entry::audioSourceMode) {
            if (old < 0) { speech_("Audio source disabled. Change Audio source first."); return; }
            bits = (old & 1023) | (std::clamp(static_cast<int>(value), 0, 8) << 10);
        } else if (e.type == Entry::audioSource) {
            // Pair -1 is the real REAPER None state; otherwise 1/2..127/128.
            const int pair = std::clamp(static_cast<int>(value), -1, 63);
            bits = pair < 0 ? -1 : ((pair * 2) | ((old < 0 ? 0 : old) & ~1023));
        } else {
            const int pair = std::clamp(static_cast<int>(value), 0, 63);
            bits = (pair * 2) | (old & ~1023); // preserve destination mono
        }
        raw = static_cast<double>(bits);
        if (bits >= 0) {
            const int width = source ? ((bits >> 10) == 1 ? 1 :
                (bits >> 10) == 0 ? 2 : (bits >> 10) * 2) :
                ((bits & 1024) ? 1 : 2);
            requiredChannels = (bits & 1023) + width;
            if (requiredChannels > 128) {
                speech_("Routing exceeds REAPER's 128 track channels"); return;
            }
            // F2: source = current track, dest = peer. F3 reverses this.
            // Never expand an unrelated track based on an unverified pointer.
            channelTrack = routingEndpoint(e, source);
            if (!channelTrack) { speech_("Routing peer unavailable"); return; }
            previousChannelCount = std::clamp(
                static_cast<int>(GetMediaTrackInfo_Value(channelTrack, "I_NCHAN")), 2, 128);
            if (requiredChannels % 2) ++requiredChannels;
        }
    }
    struct UndoScope {
        ReaProject* project;
        explicit UndoScope(ReaProject* p) : project(p) { Undo_BeginBlock2(p); }
        ~UndoScope() { Undo_EndBlock2(project, "LReaParams: track or routing control", UNDO_STATE_TRACKCFG); }
    } undo(project_);
    bool widened = false;
    if (channelTrack && requiredChannels > previousChannelCount) {
        if (!SetMediaTrackInfo_Value(channelTrack, "I_NCHAN", requiredChannels))
            throw std::runtime_error("REAPER refused channel expansion");
        widened = true;
    }
    const bool ok = e.index < 0 ? SetMediaTrackInfo_Value(track_, parm.c_str(), raw) :
        SetTrackSendInfo_Value(track_, e.category, e.index, parm.c_str(), raw);
    if (!ok) {
        if (widened) SetMediaTrackInfo_Value(channelTrack, "I_NCHAN", previousChannelCount);
        throw std::runtime_error("REAPER refused track change");
    }
    TrackList_AdjustWindows(false);
    UpdateArrange();
    if (!suppressPutSpeech_ && memory_.valueSpeech(parameterKey())) speech_(valueText(e, get(e)));
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
        if (static_cast<int>(GetTrackSendInfo_Value(track_, e.category, e.index, "I_SRCCHAN")) < 0)
            return "None";
        if (value == 0) return "Stereo";
        if (value == 1) return "Mono";
        return std::to_string(static_cast<int>(value * 2)) + " channels";
    }
    if (e.type == Entry::audioSource || e.type == Entry::audioDestination) {
        if (value < 0) return "None";
        const int pair = static_cast<int>(value);
        std::string text = "Channels " + std::to_string(pair * 2 + 1) + "/" + std::to_string(pair * 2 + 2);
        if (e.type == Entry::audioSource) {
            const int bits = static_cast<int>(GetTrackSendInfo_Value(track_, e.category, e.index, "I_SRCCHAN"));
            const int mode = bits >> 10;
            if (mode == 1) text += " mono";
            else if (mode > 1) text += " " + std::to_string(mode * 2) + " channels";
        } else {
            const int bits = static_cast<int>(GetTrackSendInfo_Value(track_, e.category, e.index, "I_DSTCHAN"));
            if (bits & 1024) text += " mono";
        }
        return text;
    }
    if (e.type == Entry::sendType) {
        switch (static_cast<int>(value)) {
            case 0: return "Post fader";
            case 1: return "Pre FX";
            case 2: return "Post FX deprecated";
            case 3: return "Post FX";
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
        if (value == 1) return "Normal bus";
        return "Bus " + std::to_string(static_cast<int>(value));
    }
    return num(value);
}
std::string TrackNavigator::ccParameterSuffix() const {
    std::string section, key;
    if (!midiTarget(section, key)) return {};
    std::string identity;
    if (!midiFixedIdentity(identity)) return {};
    const std::string link = memory_.fixedCcLink(identity);
    const auto separator = link.find(',');
    if (separator == std::string::npos) return {};
    try {
        std::size_t lengthCh = 0, lengthCc = 0;
        const int channel = std::stoi(link.substr(0, separator), &lengthCh);
        const auto second = link.substr(separator + 1);
        const int number = std::stoi(second, &lengthCc);
        if (lengthCh == separator && lengthCc == second.size() &&
            channel >= 1 && channel <= 16 && number >= 0 && number <= 127)
            return ". CC channel " + std::to_string(channel) + " CC " + std::to_string(number);
    } catch (...) {}
    return {};
}
std::string TrackNavigator::statusSuffix() const {
    // FX Params contract: CC before Auto, even when fixed CC is disabled.
    return ccParameterSuffix() + (currentEnvelopeActive() ? ". Auto" : "");
}
std::string TrackNavigator::currentParameterSpeech() const {
    if (!contextUnchanged()) throw std::runtime_error("Track context changed");
    const auto* e = current();
    if (!e) return trackName() + (page_ == Page::sends ? ", no sends" : page_ == Page::receives ? ", no receives" : ", no parameters");
    const std::string suffix = statusSuffix();
    if (page_ == Page::tracks) {
        const std::string selected = IsTrackSelected(track_) ? "Selected. " : "";
        // The folder-aware label contains open/closed and all ending folders.
        // Its suffix is critical when one track closes nested folders.
        return selected + folderAwareTrackLabel() + ", " + e->title + ", " + valueText(*e, get(*e)) + suffix;
    }
    // Tab/page review always gives complete context; directional navigation
    // follows separate vertical and horizontal announcement rules.
    const int occurrence = detailPeerOccurrence(e->category, e->index);
    std::string label = detailPeerName(e->category, e->index);
    label += page_ == Page::sends ? ", Send" : ", Receive";
    if (occurrence > 1) label += " " + std::to_string(occurrence);
    if (e->type == Entry::header) return label;
    return label + ", " + e->title + ", " + valueText(*e, get(*e)) + suffix;
}
// F2/F3 LEFT/RIGHT only: name a new peer, then avoid repeating the same
// track on further sends/receives to that peer. Duplicate numbering follows
// actual REAPER routing indices, even under a filtered column view.
std::string TrackNavigator::detailColumnSpeech(int previousColumn) const {
    if (!contextUnchanged()) throw std::runtime_error("Track context changed");
    const auto* e = current();
    if (!e) return parameterValueSpeech();
    if (page_ == Page::tracks) return parameterValueSpeech();
    const int occurrence = detailPeerOccurrence(e->category, e->index);
    const std::string direction = page_ == Page::sends ? "Send" : "Receive";
    std::string prefix;
    bool samePeer = false;
    if (previousColumn >= 0 && previousColumn != detailIndex_ && GetSetTrackSendInfo) {
        const int offset = previousColumn * detailHeight;
        if (offset >= 0 && offset < static_cast<int>(entries_.size())) {
            const auto& previous = entries_[static_cast<size_t>(offset)];
            const char* field = e->category == 0 ? "P_DESTTRACK" : "P_SRCTRACK";
            auto* peer = static_cast<MediaTrack*>(
                GetSetTrackSendInfo(track_, e->category, e->index, field, nullptr));
            auto* oldPeer = static_cast<MediaTrack*>(
                GetSetTrackSendInfo(track_, previous.category, previous.index, field, nullptr));
            samePeer = peer && peer == oldPeer && ValidatePtr2(project_, peer, "MediaTrack*");
        }
    }
    // Always announce the first link by peer name; a different peer must be
    // named even if its ordinal is already 2, 3, ... in the full routing list.
    if (!samePeer || occurrence == 1) prefix = detailPeerName(e->category, e->index) + ", ";
    prefix += direction;
    if (occurrence > 1) prefix += " " + std::to_string(occurrence);
    if (e->type == Entry::header) return prefix;
    return prefix + ", " + e->title + ", " + valueText(*e, get(*e)) + statusSuffix();
}
std::string TrackNavigator::reviewLine() const {
    if (!active_) return "";
    if (clearAutomationConfirm_)
        return std::string("Disable all automation on current track, including send envelopes and FX? ") +
            (clearAutomationYes_ ? "Yes selected" : "No selected") +
            ". Left and Right select; Enter confirms the selected answer. Y confirms, N or Escape cancels.";
    if (memoryManager_) {
        if (memoryItems_.empty()) return "Track Memories. No memories";
        const auto& item = memoryItems_[static_cast<size_t>(memoryRow_)];
        const int col = std::clamp(memoryColumn_, 0, 4);
        static constexpr const char* labels[] = {"MIDI CC", "Parameter Steps", "Parameter Speech",
            "Track Positions", "Volume Ranges"};
        return std::string(labels[col]) + ". " + item.label;
    }
    // NVDA+Up in Grid reviews only the parameter and value, like FX Params.
    // Track/page names remain available via NVDA+T. Moving between tracks
    // announces the track name; Tab provides the full context.
    if (filterEditing_) return nativeTextLabel() + ", " + filterBuffer_;
    if (numericEditing_) return (rangeEditing_ ? "Volume range, " : "Parameter value, ") + numericBuffer_;
    if (!valueMode_) return parameterValueSpeech();
    const auto* e = current();
    return e ? "Value, " + e->title + ", " + valueText(*e, get(*e)) : parameterValueSpeech();
}
bool TrackNavigator::nativeValueSlider() const {
    if (!active_ || !valueMode_ || clearAutomationConfirm_) return false;
    const auto* e = current();
    return e && (e->type == Entry::volume || e->type == Entry::pan || e->type == Entry::width);
}
double TrackNavigator::valueFraction() const {
    const auto* e = current();
    if (!e || !nativeValueSlider()) return 0.0;
    const double value = get(*e);
    if (e->type == Entry::volume) {
        const auto range = memory_.volumeRange(page_ == Page::tracks ? "Track" :
            page_ == Page::sends ? "Sends" : "Receives");
        return std::clamp((db(value) - range.first) / (range.second - range.first), 0.0, 1.0);
    }
    return std::clamp((value + 1.0) / 2.0, 0.0, 1.0);
}
std::string TrackNavigator::sliderLabel() const {
    const auto* e = current();
    return e ? e->title : "";
}
// Grid movement within the same track announces only the focused control.
// The full track/parameter/value context stays available with Tab
// and when moving to a different track row.
std::string TrackNavigator::parameterValueSpeech() const {
    if (!contextUnchanged()) throw std::runtime_error("Track context changed");
    const auto* e = current();
    if (!e) return page_ == Page::sends ? "No sends" :
                   page_ == Page::receives ? "No receives" : "No parameters";
    // Vertical navigation (and NVDA+Up) never repeats the connected track,
    // send number or receive number. Header fields have no numeric value.
    if (e->type == Entry::header) return e->title;
    return e->title + ", " + valueText(*e, get(*e)) + statusSuffix();
}
void TrackNavigator::announce() { speech_(parameterValueSpeech()); }
void TrackNavigator::announceTrack() { speech_(currentParameterSpeech()); }
void TrackNavigator::announceTitle() {
    if (!active_) return;
    if (memoryManager_) { speakMemory("Track Memories"); return; }
    const std::string pageSuffix = page_ == Page::tracks ? "" :
                                   page_ == Page::sends ? " - Sends" : " - Receives";
    speech_("Track Params - " + trackName() + pageSuffix +
            (valueMode_ ? " - Value. " : ". ") + currentParameterSpeech());
}
std::wstring TrackNavigator::windowTitle() const {
    if (!active_) return L"Track Params";
    if (memoryManager_) {
        static constexpr const wchar_t* titles[] = {L"MIDI CC", L"Parameter Steps", L"Parameter Speech", L"Track Positions", L"Volume Ranges"};
        return std::wstring(L"Track Memories - ") + titles[static_cast<size_t>(std::clamp(memoryColumn_, 0, 4))];
    }
    const wchar_t* pageSuffix = page_ == Page::tracks ? L"" :
                                page_ == Page::sends ? L" - Sends" : L" - Receives";
    return std::wstring(L"Track Params - ") + wideUtf8(trackName()) + pageSuffix +
           (numericEditing_ ? L" - Numeric edit" : filterEditing_ ? L" - Filter" : !filterQuery_.empty() ? L" - Filter active" : L"") +
           (valueMode_ ? L" - Value" : L"");
}
// F1 selection follows Lua's visible-track row model, keeping the parameter
// column fixed. A selection gesture is the only case allowed to change the
// REAPER selected-track anchor without invalidating our own context guard.
void TrackNavigator::resetSelectionStroke() {
    selectionStroke_ = false;
    selectionAnchorRow_ = 0;
    selectionBase_.clear();
}
void TrackNavigator::captureBaseSelection() {
    selectionBase_.clear();
    for (int i = 0, n = CountTracks(project_); i < n; ++i) {
        MediaTrack* tr = GetTrack(project_, i);
        if (tr && IsTrackSelected(tr)) selectionBase_.insert(tr);
    }
}
void TrackNavigator::refreshTrackSelection() {
    TrackList_AdjustWindows(false);
    UpdateArrange();
    // Rebaseline only after our own explicit selection command. Unsolicited
    // external selection changes still terminate the navigator safely.
    initialSelection_ = GetSelectedTrack2(project_, 0, true);
}
void TrackNavigator::syncCursorToReaper() {
    if (!project_ || !track_ || !ValidatePtr2(project_, track_, "MediaTrack*")) return;
    // During two-pass Add Send/Receive the Lua deliberately clears selection
    // after storing the sources/destinations. Do not implicitly reselect a
    // track while the user is picking the opposite side of the routing.
    if (pendingRouting_ != RoutingKind::none) return;
    // A normal cursor move is an actual TCP track move, not merely a spoken
    // pointer. Collapse any older selection; Shift-selection gestures use
    // applyRangeSelection instead and remain fully multi-track capable.
    if (CountSelectedTracks(project_) != 1 || !IsTrackSelected(track_))
        SetOnlyTrackSelected(track_);
    refreshTrackSelection();
}
void TrackNavigator::announceSelection() const {
    if (page_ != Page::tracks) return;
    speech_(std::to_string(CountSelectedTracks(project_)) + " Selected. " + currentParameterSpeech());
}
void TrackNavigator::applyRangeSelection(int first, int last) {
    if (rows_.empty()) return;
    first = std::clamp(first, 0, static_cast<int>(rows_.size()) - 1);
    last = std::clamp(last, 0, static_cast<int>(rows_.size()) - 1);
    std::unordered_set<MediaTrack*> wanted = selectionBase_;
    if (first > last) std::swap(first, last);
    for (int i = first; i <= last; ++i) wanted.insert(rows_[i].track);
    for (int i = 0, n = CountTracks(project_); i < n; ++i) {
        MediaTrack* tr = GetTrack(project_, i);
        if (tr) SetTrackSelected(tr, wanted.count(tr) != 0);
    }
    refreshTrackSelection();
}
void TrackNavigator::selectVisibleTracks() {
    resetSelectionStroke();
    for (const auto& row : rows_) SetTrackSelected(row.track, true);
    refreshTrackSelection();
    announceSelection();
}
void TrackNavigator::toggleCursorTrackSelection(bool deselectOnly) {
    resetSelectionStroke();
    const bool wasSelected = IsTrackSelected(track_);
    if (deselectOnly && !wasSelected) {
        speech_(std::to_string(CountSelectedTracks(project_)) + " Selected. " + trackName() + ". Not selected");
        return;
    }
    SetTrackSelected(track_, deselectOnly ? false : !wasSelected);
    refreshTrackSelection();
    speech_(std::to_string(CountSelectedTracks(project_)) + " Selected. " + trackName() +
        (deselectOnly || wasSelected ? ". Deselected" : ". Selected"));
}
void TrackNavigator::clearTrackSelection() {
    resetSelectionStroke();
    for (int i = 0, n = CountTracks(project_); i < n; ++i) {
        if (MediaTrack* tr = GetTrack(project_, i)) SetTrackSelected(tr, false);
    }
    refreshTrackSelection();
    speech_("0 Selected");
}
void TrackNavigator::extendTrackSelection(int direction, bool page) {
    if (!selectionStroke_) {
        selectionStroke_ = true;
        selectionAnchorRow_ = row_;
        captureBaseSelection();
        // Original Lua: first Shift+arrow selects the anchor, next one moves.
        applyRangeSelection(row_, row_);
        announceSelection();
        return;
    }
    const int jump = page ? 5 : 1;
    const int next = std::clamp(row_ + direction * jump, 0, static_cast<int>(rows_.size()) - 1);
    if (next == row_) return;
    applyRangeSelection(selectionAnchorRow_, next);
    row_ = next;
    track_ = rows_[row_].track;
    rememberPosition();
    announceSelection();
}
void TrackNavigator::extendTrackSelectionToEdge(int direction) {
    resetSelectionStroke();
    captureBaseSelection();
    const int next = direction < 0 ? 0 : static_cast<int>(rows_.size()) - 1;
    applyRangeSelection(row_, next);
    row_ = next;
    track_ = rows_[row_].track;
    rememberPosition();
    announceSelection();
}
void TrackNavigator::moveToFolder(int direction) {
    resetSelectionStroke();
    for (int i = row_ + direction; i >= 0 && i < static_cast<int>(rows_.size()); i += direction) {
        if (GetMediaTrackInfo_Value(rows_[i].track, "I_FOLDERDEPTH") > 0.5) {
            row_ = i;
            track_ = rows_[row_].track;
            syncCursorToReaper();
            rememberPosition();
            announceTrack();
            return;
        }
    }
    // Silent boundary, same as ordinary F1 movement.
}
void TrackNavigator::moveTrack(int delta) {
    if (page_ != Page::tracks) return;
    resetSelectionStroke();
    const int next = std::clamp(row_ + delta, 0, static_cast<int>(rows_.size()) - 1);
    if (next != row_) {
        row_ = next; track_ = rows_[row_].track;
        syncCursorToReaper();
        midiPickup_.clear(); rememberPosition(); announceTrack();
    }
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
    if (next != detailIndex_) {
        const int previousColumn = detailIndex_;
        detailIndex_ = next;
        midiPickup_.clear();
        rememberPosition();
        speech_(detailColumnSpeech(previousColumn));
    }
}
void TrackNavigator::switchDetailTrack(int direction) {
    if (page_ == Page::tracks || rows_.empty()) return;
    const int category = page_ == Page::sends ? 0 : -1;
    for (int candidate = row_ + direction;
         candidate >= 0 && candidate < static_cast<int>(rows_.size());
         candidate += direction) {
        MediaTrack* nextTrack = rows_[candidate].track;
        if (!nextTrack || matchingRoutingCount(nextTrack, category) <= 0) continue;
        rememberPosition();
        row_ = candidate;
        track_ = nextTrack;
        syncCursorToReaper();
        detailIndex_ = 0;
        midiPickup_.clear();
        buildEntries();
        parameter_ = std::clamp(parameter_, 0, detailHeight - 1);
        stepScale_ = memory_.step(parameterKey());
        valueMode_ = false;
        resetSelectionStroke();
        rememberPosition();
        announceTrack();
        return;
    }
    // Silent boundary, in line with the original vertical navigator.
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
        case Entry::volume: {
            const auto range = memory_.volumeRange(page_ == Page::tracks ? "Track" :
                page_ == Page::sends ? "Sends" : "Receives");
            next = amp(std::clamp(db(old) + (coarse ? 3.0 : 0.5) * factor * direction, range.first, range.second));
            break;
        }
        case Entry::pan: case Entry::width: next = std::clamp(old + direction * (coarse ? 0.1 : 0.01) * factor, -1.0, 1.0); break;
        case Entry::flag: case Entry::solo: case Entry::midiFollowsFader: next = direction > 0 ? 1.0 : 0.0; break;
        case Entry::audioSourceMode: next = std::clamp(old + direction, 0.0, 8.0); break;
        case Entry::audioSource: next = std::clamp(old + direction, -1.0, 63.0); break;
        case Entry::audioDestination: next = std::clamp(old + direction, 0.0, 63.0); break;
        case Entry::sendType: next = std::clamp(old + direction, 0.0, 3.0); break;
        case Entry::midiSource: {
            // All, 1..16, None (31).
            const int oldIndex = old == 31 ? 17 : std::clamp(static_cast<int>(old), 0, 16);
            const int idx = std::clamp(oldIndex + direction, 0, 17);
            next = idx == 17 ? 31 : idx; break;
        }
        case Entry::midiDestination: next = std::clamp(old + direction, 0.0, 16.0); break;
        case Entry::midiSourceBus: case Entry::midiDestinationBus:
            // Match the original Lua's 0=All, 1=Normal, 2..16 bus stepping.
            next = std::clamp(old + direction * (coarse ? 8.0 : 1.0), 0.0, 16.0); break;
        default: speech_("Read only or not yet migrated"); return;
    }
    put(*e, next);
}
void TrackNavigator::handle(const Key& k) {
    if (!contextUnchanged()) throw std::runtime_error("Track context changed");
    // This confirmation temporarily owns the navigator's review line. Handle
    // it BEFORE Tab, transport or the memory shortcuts so NVDA can review the
    // question and arrow keys never move the underlying parameter.
    if (clearAutomationConfirm_) {
        if (k.repeat) return;
        if (k.ctrl || k.alt) return;
        if (k.vk == VK_LEFT || k.vk == VK_RIGHT) {
            const bool yes = k.vk == VK_LEFT;
            if (yes != clearAutomationYes_) {
                clearAutomationYes_ = yes;
                speech_(yes ? "Yes" : "No");
            }
        } else if (k.vk == VK_TAB) {
            speech_(reviewLine());
        } else if (k.vk == 'Y' || (k.vk == VK_RETURN && clearAutomationYes_)) {
            clearAutomationConfirm_ = false;
            clearAutomationYes_ = false;
            clearTrackAutomations();
        } else if (k.vk == 'N' || k.vk == VK_ESCAPE || k.vk == VK_RETURN) {
            clearAutomationConfirm_ = false;
            clearAutomationYes_ = false;
            speech_("Automation clear cancelled");
        }
        return;
    }
    if (memoryManager_) { handleMemory(k); return; }
    if (k.ctrl && k.shift && !k.alt && k.vk == 'M') {
        if (!k.repeat) openTrackMemories(false);
        return;
    }
    if (page_ == Page::tracks && k.ctrl && !k.alt &&
        k.vk >= VK_F1 && k.vk <= VK_F12) {
        if (!k.repeat) {
            const int slot = static_cast<int>(k.vk - VK_F1) + 1;
            if (k.shift) saveTrackSlot(slot);
            else recallTrackSlot(slot);
        }
        return;
    }
    if (!k.ctrl && !k.alt && !k.shift && k.vk == VK_TAB) {
        if (!k.repeat && pendingRouting_ != RoutingKind::none) {
            speech_(pendingRoutingStatus());
            return;
        }
        if (!k.repeat && current()) {
            const std::string id = parameterKey();
            const std::string page = page_ == Page::tracks ? "Track" : page_ == Page::sends ? "Sends" : "Receives";
            const auto dot = id.find('.');
            const std::string bare = dot == std::string::npos ? id : id.substr(dot + 1);
            std::string info = currentParameterSpeech();
            if (const Entry* entry = current(); entry && entry->type == Entry::volume) {
                const auto limits = memory_.volumeRange(page);
                info += ". Volume range " + num(limits.first) + " to " +
                    num(limits.second) + " dB";
            }
            info += ". Step " + std::to_string(memory_.step(id)) +
                (memory_.valueSpeech(id) ? ". Value speech on" : ". Value speech off");
            if (ccSpeechSupported()) {
                std::string target;
                const bool speak = midiFixedIdentity(target) && memory_.fixedCcSpeech(target);
                info += speak ? ". MIDI speech on" : ". MIDI speech off";
            }
            if (page_ == Page::tracks) info += ". " + std::to_string(CountSelectedTracks(project_)) + " tracks selected";
            info += filterSuffix();
            speech_(info);
        }
        return;
    }
    // Shared extension transport: Space Play/Stop, Ctrl+Space Play/Pause.
    // Leave text editors and Shift+Space selection untouched. REAPER/OSARA
    // own transport speech, as in FX Params.
    if (k.vk == VK_SPACE && !k.shift && !k.alt && !filterEditing_ && !numericEditing_) {
        if (!k.repeat) {
            if (k.ctrl) { if (Main_OnCommand) Main_OnCommand(40073, 0); }
            else {
                const int state = GetPlayState ? GetPlayState() : 0;
                if ((state & 2) && OnPlayButton) OnPlayButton();
                else if (Main_OnCommand) Main_OnCommand(40044, 0);
            }
        }
        return;
    }
    if (numericEditing_) {
        if (k.vk == VK_RETURN) commitNumericEdit();
        else if (k.vk == VK_ESCAPE) {
            numericEditing_ = rangeEditing_ = false;
            speech_("Edit cancelled. " + parameterValueSpeech());
        }
        return;
    }
    if (k.ctrl && k.shift && k.alt && !k.altGr && k.vk == 'A') {
        if (!k.repeat) {
            clearAutomationYes_ = false;
            clearAutomationConfirm_ = true;
            speech_("Disable all automation on current track, including send envelopes and FX? No selected. Left and Right choose Yes or No. Enter accepts, Y confirms, N or Escape cancels");
        }
        return;
    }
    if ((k.ctrl && k.alt && !k.shift && k.vk == 'C') ||
        (!k.ctrl && !k.alt && k.shift && k.vk == 'C') ||
        (k.ctrl && !k.alt && k.shift && k.vk == 'C') ||
        (k.ctrl && !k.alt && !k.shift && k.vk == VK_DELETE)) {
        if (!k.repeat) midiShortcut(k);
        return;
    }
    if (k.vk == VK_ESCAPE && learnCc_) { learnCc_ = false; learnSection_.clear(); learnKey_.clear(); learnIdentity_.clear(); speech_("CC learn cancelled"); return; }
    if (k.ctrl && k.shift && !k.alt && k.vk == 'I') {
        if (!k.repeat) beginVolumeRangeEdit();
        return;
    }
    if (k.ctrl && !k.shift && !k.alt && k.vk == 'E') {
        if (!k.repeat) beginNumericEdit();
        return;
    }
    // Ctrl+F works in all F1/F2/F3 pages, with a real NVDA-accessible EDIT.
    // In the field, Windows owns printable keys, selection and clipboard;
    // this function receives only Enter, Escape and Ctrl+F.
    if (filterEditing_) {
        if (k.repeat) return;
        if (k.vk == VK_RETURN) applyFilter();
        else if (k.vk == VK_ESCAPE || (k.ctrl && !k.alt && !k.shift && k.vk == 'F'))
            cancelFilter();
        return;
    }
    if (k.ctrl && !k.alt && !k.shift && k.vk == 'F') {
        if (!k.repeat) toggleFilter();
        return;
    }
    // Two-pass Lua routing: S = sources first, R = destinations first.
    // These combinations are recognized on every page, but permitted only in F1.
    if (k.ctrl && k.shift && !k.alt && (k.vk == 'S' || k.vk == 'R')) {
        if (!k.repeat) addTrackRouting(k.vk == 'S' ? RoutingKind::send : RoutingKind::receive);
        return;
    }
    if (page_ != Page::tracks && k.ctrl && !k.alt && !k.shift &&
        (k.vk == VK_UP || k.vk == VK_DOWN)) {
        switchDetailTrack(k.vk == VK_UP ? -1 : 1);
        return;
    }
    // Lua F1: SWS/S&M clipboard with routing and folder-aware physical moves.
    // Consume only our F1 gestures, and never fall back to REAPER's plain paste.
    if (page_ == Page::tracks && !k.repeat && !k.alt && !k.shift && k.ctrl &&
        (k.vk == 'C' || k.vk == 'X' || k.vk == 'V')) {
        trackClipboard(k.vk == 'C' ? TrackClipboardAction::copy :
            k.vk == 'X' ? TrackClipboardAction::cut : TrackClipboardAction::paste);
        return;
    }
    if (page_ == Page::tracks && !k.repeat && k.alt && k.shift && !k.ctrl &&
        (k.vk == VK_UP || k.vk == VK_DOWN)) {
        moveSelectedTracks(k.vk == VK_UP ? -1 : 1);
        return;
    }
    if (k.ctrl && k.shift && !k.alt && k.vk == 'A') {
        if (!k.repeat) toggleCurrentAutomation();
        return;
    }
    // In F1, REAPER track selection is independent of the invisible cursor.
    if (page_ == Page::tracks) {
        if (k.ctrl && k.alt && !k.shift && (k.vk == VK_UP || k.vk == VK_DOWN)) {
            moveToFolder(k.vk == VK_UP ? -1 : 1); return;
        }
        if (k.ctrl && k.shift && !k.alt && (k.vk == VK_UP || k.vk == VK_DOWN)) {
            if (!k.repeat) extendTrackSelectionToEdge(k.vk == VK_UP ? -1 : 1);
            return;
        }
        if (k.ctrl && k.shift && !k.alt && k.vk == VK_SPACE) {
            if (!k.repeat) toggleCursorTrackSelection(false);
            return;
        }
        if (k.shift && !k.ctrl && !k.alt) {
            if (k.vk == VK_SPACE) { if (!k.repeat) toggleCursorTrackSelection(false); return; }
            if (k.vk == VK_UP || k.vk == VK_DOWN || k.vk == VK_PRIOR || k.vk == VK_NEXT) {
                extendTrackSelection(k.vk == VK_UP || k.vk == VK_PRIOR ? -1 : 1,
                    k.vk == VK_PRIOR || k.vk == VK_NEXT);
                return;
            }
        }
        if (k.ctrl && !k.alt && !k.shift && k.vk == 'A') { if (!k.repeat) selectVisibleTracks(); return; }
        if (k.ctrl && k.shift && !k.alt && k.vk == VK_DELETE) { if (!k.repeat) clearTrackSelection(); return; }
        if (!k.ctrl && !k.alt && !k.shift && k.vk == VK_DELETE) { if (!k.repeat) toggleCursorTrackSelection(true); return; }
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
            std::string target;
            if (!midiFixedIdentity(target)) { speech_("MIDI speech target unavailable"); return; }
            const bool on = !memory_.fixedCcSpeech(target);
            memory_.setFixedCcSpeech(target, on); memory_.flush();
            speech_(on ? "MIDI speech on" : "MIDI speech off");
        }
        return;
    }
    if (k.ctrl && !k.alt && !k.shift && k.vk == VK_BACK) {
        if (k.repeat || !current()) return;
        memory_.setStep(parameterKey(), 0); stepScale_ = 0; memory_.flush();
        speech_("Step 0"); return;
    }
    // Ctrl+Enter toggles the folder without stealing plain Enter from Value.
    // On an end-folder row it targets the innermost closing folder, then
    // cycles across any outer folders closed by the same row.
    if (page_ == Page::tracks && k.ctrl && !k.alt && !k.shift && k.vk == VK_RETURN) {
        if (!k.repeat) toggleCurrentFolder();
        return;
    }
    // Lua: unmodified Delete removes the current F2/F3 routing instance.
    if (page_ != Page::tracks && !k.ctrl && !k.alt && !k.shift && k.vk == VK_DELETE) {
        if (!k.repeat) deleteCurrentRouting();
        return;
    }
    if (k.vk == VK_ESCAPE) {
        if (pendingRouting_ != RoutingKind::none) { cancelTrackRouting(); return; }
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
        if (e && e->type == Entry::midiMerge) {
            speech_("MIDI merge " + valueText(*e, get(*e)) +
                ". Routing status: set MIDI source to None for off, or All / a channel for on.");
            return;
        }
        if (e && e->type == Entry::header && page_ != Page::tracks) {
            jumpToLinkedRouting(); return;
        }
        if (!e) { announce(); return; }
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
                case Entry::volume: {
                    const auto range = memory_.volumeRange(page_ == Page::tracks ? "Track" :
                        page_ == Page::sends ? "Sends" : "Receives");
                    put(*e, amp(high ? range.second : range.first)); break;
                }
                case Entry::pan: case Entry::width: put(*e, high ? 1.0 : -1.0); break;
                case Entry::flag: case Entry::solo: case Entry::midiFollowsFader: put(*e, high ? 1.0 : 0.0); break;
                case Entry::audioSourceMode: put(*e, high ? 8.0 : 0.0); break;
                case Entry::audioSource: put(*e, high ? 63.0 : -1.0); break;
                case Entry::audioDestination: put(*e, high ? 63.0 : 0.0); break;
                case Entry::sendType: put(*e, high ? 3.0 : 0.0); break;
                case Entry::midiSource: put(*e, high ? 31.0 : 0.0); break;
                case Entry::midiDestination: put(*e, high ? 16.0 : 0.0); break;
                case Entry::midiSourceBus: case Entry::midiDestinationBus: put(*e, high ? 16.0 : 0.0); break;
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
