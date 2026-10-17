#include "lrp/TrackNavigator.h"
#include <algorithm>
#include <cmath>
#include <cstring>
#include <cwctype>
#include <string>
#include <vector>

namespace lrp {
namespace {
std::wstring utf8Wide(const std::string& value) {
    if (value.empty()) return {};
    const int len = MultiByteToWideChar(CP_UTF8, MB_ERR_INVALID_CHARS,
        value.data(), static_cast<int>(value.size()), nullptr, 0);
    if (len <= 0) return {};
    std::wstring result(static_cast<size_t>(len), L'\0');
    if (!MultiByteToWideChar(CP_UTF8, MB_ERR_INVALID_CHARS, value.data(),
        static_cast<int>(value.size()), result.data(), len)) return {};
    return result;
}
// Matches the Lua's clean_one_line and case-insensitive literal substring.
// Unicode text is converted through Windows UTF-8; case folding follows
// Windows locale (not merely ASCII lowercasing on UTF-8 bytes).
std::wstring normalized(const std::string& value) {
    const auto wide = utf8Wide(value);
    std::wstring clean;
    clean.reserve(wide.size());
    bool spacing = false;
    for (wchar_t c : wide) {
        if (std::iswspace(static_cast<wint_t>(c))) {
            if (!clean.empty()) spacing = true;
        } else {
            if (spacing) clean.push_back(L' ');
            spacing = false;
            clean.push_back(c);
        }
    }
    if (!clean.empty()) CharLowerBuffW(clean.data(), static_cast<DWORD>(clean.size()));
    return clean;
}
bool matches(const std::string& haystack, const std::string& query) {
    const auto sought = normalized(query);
    if (sought.empty()) return true;
    return normalized(haystack).find(sought) != std::wstring::npos;
}
std::string trackLabel(MediaTrack* track) {
    if (!track) return {};
    char name[2048]{};
    GetTrackName(track, name, sizeof(name));
    std::string result = name[0] ? name : "Track " + std::to_string(
        static_cast<int>(GetMediaTrackInfo_Value(track, "IP_TRACKNUMBER")));
    if (GetMediaTrackInfo_Value(track, "I_FOLDERDEPTH") > 0.5)
        result += GetMediaTrackInfo_Value(track, "I_FOLDERCOMPACT") >= 1.0 ?
            " closed folder" : " open folder";
    return result;
}
std::string simplifyFilter(const std::string& text) {
    std::string result;
    result.reserve(std::min<size_t>(text.size(), 240));
    bool whitespace = false;
    for (char c : text) {
        if (c == '\n' || c == '\t' || c == '\r' || c == ' ') {
            if (!result.empty()) whitespace = true;
            continue;
        }
        if (whitespace) result.push_back(' ');
        whitespace = false;
        result.push_back(c);
    }
    return result;
}
} // namespace

bool TrackNavigator::trackMatchesFilter(MediaTrack* track) const {
    return filterQuery_.empty() || matches(trackLabel(track), filterQuery_);
}

bool TrackNavigator::routeMatchesFilter(MediaTrack* owner, int category, int index) const {
    if (filterQuery_.empty()) return true;
    if (!owner || index < 0 || index >= GetTrackNumSends(owner, category)) return false;
    MediaTrack* peer = nullptr;
    if (GetSetTrackSendInfo) {
        peer = static_cast<MediaTrack*>(GetSetTrackSendInfo(owner, category, index,
            category == 0 ? "P_DESTTRACK" : "P_SRCTRACK", nullptr));
        if (peer && !ValidatePtr2(project_, peer, "MediaTrack*")) peer = nullptr;
    }
    const char* direction = category == 0 ? "Send" : "Receive";
    std::string searchable = std::string(direction) + " " + std::to_string(index + 1) +
        " " + (category == 0 ? "Send to " : "Receive from ") + trackLabel(peer);
    // As in the Lua, search also includes displayed routing fields/values,
    // without conflating two different sends to the same track.
    for (const char* field : {"D_VOL", "D_PAN", "B_MUTE", "I_SRCCHAN", "I_DSTCHAN",
                               "I_SENDMODE", "I_MIDIFLAGS"}) {
        const double value = GetTrackSendInfo_Value(owner, category, index, field);
        searchable += " "; searchable += field;
        searchable += " "; searchable += std::to_string(value);
    }
    searchable += " Volume Pan Mute Audio source mode Audio source Audio destination"
                  " Send type MIDI source MIDI destination MIDI source bus MIDI destination bus"
                  " MIDI follows fader MIDI merge";
    return matches(searchable, filterQuery_);
}

int TrackNavigator::matchingRoutingCount(MediaTrack* owner, int category) const {
    if (!owner) return 0;
    const int count = std::clamp(GetTrackNumSends(owner, category), 0, 512);
    if (filterQuery_.empty()) return count;
    int matchesCount = 0;
    for (int index = 0; index < count; ++index)
        if (routeMatchesFilter(owner, category, index)) ++matchesCount;
    return matchesCount;
}

std::string TrackNavigator::filterSuffix() const {
    if (filterQuery_.empty()) return {};
    const int count = page_ == Page::tracks ? static_cast<int>(rows_.size()) :
        static_cast<int>(entries_.size()) / detailHeight;
    return ". Filter " + filterQuery_ + ". " + std::to_string(count) + " results";
}

void TrackNavigator::toggleFilter() {
    if (!active_) return;
    if (!filterQuery_.empty()) { clearFilter(); return; }
    if (pendingRouting_ != RoutingKind::none) {
        speech_("Finish or cancel Add send or receive before filtering"); return;
    }
    if (!nativeFilterAvailable_) {
        speech_("Enable the LReaParams native keyboard window to edit a filter"); return;
    }
    valueMode_ = false;
    filterEditing_ = true;
    filterBuffer_.clear();
    speech_(nativeTextLabel() + ". Type text and press Enter; Escape cancels.");
}

void TrackNavigator::cancelFilter() {
    filterEditing_ = false;
    filterBuffer_.clear();
    speech_("Search cleared. " + parameterValueSpeech());
}

bool TrackNavigator::rebuildForFilter(bool keepCurrentTrack) {
    if (rows_.empty()) return false;
    const GUID target = rows_[static_cast<size_t>(row_)].guid;
    const int oldRow = row_;
    const int oldRawIndex = page_ != Page::tracks && current() ? current()->index : -1;
    const auto previousRows = rows_;
    const auto previousEntries = entries_;
    if (page_ == Page::tracks) rebuildVisibleRows();
    if (rows_.empty()) { rows_ = previousRows; return false; }
    row_ = std::clamp(oldRow, 0, static_cast<int>(rows_.size()) - 1);
    if (keepCurrentTrack) {
        for (int i = 0; i < static_cast<int>(rows_.size()); ++i)
            if (std::memcmp(&rows_[static_cast<size_t>(i)].guid, &target, sizeof(GUID)) == 0) {
                row_ = i; break;
            }
    }
    track_ = rows_[static_cast<size_t>(row_)].track;
    buildEntries();
    if (entries_.empty()) {
        rows_ = previousRows;
        entries_ = previousEntries;
        row_ = oldRow;
        track_ = rows_[static_cast<size_t>(row_)].track;
        return false;
    }
    detailIndex_ = 0;
    if (page_ != Page::tracks && oldRawIndex >= 0)
        for (int i = 0, n = static_cast<int>(entries_.size()) / detailHeight; i < n; ++i)
            if (entries_[static_cast<size_t>(i * detailHeight)].index == oldRawIndex) {
                detailIndex_ = i; break;
            }
    stepScale_ = memory_.step(parameterKey());
    resetSelectionStroke();
    syncCursorToReaper();
    rememberPosition();
    return true;
}

void TrackNavigator::clearFilter() {
    filterQuery_.clear();
    filterEditing_ = false;
    filterBuffer_.clear();
    rebuildForFilter(true);
    speech_("Search cleared. " + parameterValueSpeech());
}

void TrackNavigator::applyFilter() {
    const std::string candidate = simplifyFilter(filterBuffer_);
    if (candidate.empty()) { clearFilter(); return; }
    // Probe BEFORE mutating active state or existing REAPER folder openness.
    // Empty result keeps the EDIT and its caret available for correction.
    const std::string previous = filterQuery_;
    filterQuery_ = candidate;
    bool found = false;
    if (page_ == Page::tracks) {
        for (int i = 0, n = CountTracks(project_); i < n; ++i) {
            auto* tr = GetTrack(project_, i);
            if (tr && GetMediaTrackInfo_Value(tr, "B_SHOWINTCP") > 0.5 &&
                trackMatchesFilter(tr)) { found = true; break; }
        }
    } else found = matchingRoutingCount(track_, page_ == Page::sends ? 0 : -1) > 0;
    if (!found) {
        filterQuery_ = previous;
        speech_("No results for " + candidate + ". Edit the filter or press Escape");
        return;
    }
    // The Lua reveals parent folders for matching tracks. Do this once, on
    // confirmed F1 queries, never during incremental typing.
    if (page_ == Page::tracks) {
        std::vector<MediaTrack*> parents;
        bool opened = false;
        for (int i = 0, n = CountTracks(project_); i < n; ++i) {
            MediaTrack* tr = GetTrack(project_, i);
            if (!tr) continue;
            if (trackMatchesFilter(tr) && GetMediaTrackInfo_Value(tr, "B_SHOWINTCP") > 0.5) {
                for (MediaTrack* parent : parents) {
                    if (GetMediaTrackInfo_Value(parent, "I_FOLDERCOMPACT") >= 1.0 &&
                        SetMediaTrackInfo_Value(parent, "I_FOLDERCOMPACT", 0.0)) opened = true;
                }
            }
            const int delta = static_cast<int>(std::lround(GetMediaTrackInfo_Value(tr, "I_FOLDERDEPTH")));
            if (delta > 0) for (int j = 0; j < delta; ++j) parents.push_back(tr);
            else if (delta < 0) for (int j = 0; j < -delta && !parents.empty(); ++j) parents.pop_back();
        }
        if (opened) { TrackList_AdjustWindows(false); UpdateArrange(); }
    }
    filterEditing_ = false;
    filterBuffer_.clear();
    if (!rebuildForFilter(true)) {
        // Defensive rollback: retain the original grid and its live cursor.
        filterQuery_ = previous;
        speech_("No matching visible results. Filter unchanged");
        return;
    }
    speech_("Filter " + filterQuery_ + ". " +
        std::to_string(page_ == Page::tracks ? rows_.size() : entries_.size() / detailHeight) +
        " results. " + currentParameterSpeech());
}
} // namespace lrp
