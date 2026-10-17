#include "lrp/TrackNavigator.h"
#include <algorithm>
#include <cmath>
#include <cstring>
#include <string>
#include <unordered_set>
#include <vector>

namespace lrp {
namespace {
bool equalGuid(const GUID& a, const GUID& b) noexcept {
    return std::memcmp(&a, &b, sizeof(GUID)) == 0;
}
int folderDelta(MediaTrack* tr) {
    return static_cast<int>(std::lround(GetMediaTrackInfo_Value(tr, "I_FOLDERDEPTH")));
}
// The final child can close multiple nested folders. We must include that
// child, not stop on the first negative I_FOLDERDEPTH.
int folderLast(ReaProject* project, int first, int count) {
    MediaTrack* root = GetTrack(project, first);
    if (!root || folderDelta(root) <= 0) return first;
    int level = folderDelta(root);
    for (int i = first + 1; i < count; ++i) {
        if (MediaTrack* tr = GetTrack(project, i)) level += folderDelta(tr);
        if (level <= 0) return i;
    }
    return count - 1;
}
}

void TrackNavigator::clearPhysicalSelection() {
    for (int i = 0, n = CountTracks(project_); i < n; ++i)
        if (auto* tr = GetTrack(project_, i)) SetTrackSelected(tr, false);
    resetSelectionStroke();
    refreshTrackSelection(); // Own selection change must not close our navigator.
}

void TrackNavigator::refreshAfterTrackEdit(const GUID* desired, int fallback) {
    // Do NOT dereference any old MediaTrack* after SWS cut/paste. Rebuild from
    // the project's actual list, then restore only GUID/row/parameter state.
    trackCount_ = CountTracks(project_);
    rebuildVisibleRows();
    if (rows_.empty()) {
        // end() saves preferences without dereferencing the removed track.
        end();
        speech_("No visible tracks");
        return;
    }
    int next = std::clamp(fallback, 0, static_cast<int>(rows_.size()) - 1);
    if (desired) {
        for (int i = 0; i < static_cast<int>(rows_.size()); ++i) {
            if (equalGuid(rows_[i].guid, *desired)) { next = i; break; }
        }
    }
    row_ = next;
    track_ = rows_[row_].track;
    page_ = Page::tracks;
    valueMode_ = false;
    parameter_ = std::clamp(parameter_, 0, 8);
    detailIndex_ = 0;
    sends_ = GetTrackNumSends(track_, 0);
    receives_ = GetTrackNumSends(track_, -1);
    buildEntries();
    stepScale_ = memory_.step(parameterKey());
    resetSelectionStroke();
    refreshTrackSelection();
    rememberPosition();
}

void TrackNavigator::trackClipboard(TrackClipboardAction action) {
    if (page_ != Page::tracks || !track_) return;
    // Lua's SWS/S&M commands preserve routing. Plain REAPER copy/paste is NOT
    // a safe fallback because it may discard inter-track sends and receives.
    const char* named = action == TrackClipboardAction::cut ? "_S&M_CUTSNDRCV1" :
        action == TrackClipboardAction::copy ? "_S&M_COPYSNDRCV1" : "_S&M_PASTSNDRCV1";
    if (!NamedCommandLookup || !Main_OnCommand) {
        speech_("SWS command API unavailable"); return;
    }
    const int command = NamedCommandLookup(named);
    if (command <= 0) {
        speech_("SWS/S&M not installed. Tracks with routing were not changed"); return;
    }
    const int oldRow = row_;
    const GUID currentGuid = rows_[row_].guid;
    if (action == TrackClipboardAction::paste) {
        // The invisible F1 cursor is not the physical TCP selection. The Lua
        // selects exactly the anchor before invoking SWS's paste command.
        for (int i = 0, n = CountTracks(project_); i < n; ++i)
            if (auto* tr = GetTrack(project_, i)) SetTrackSelected(tr, tr == track_);
    } else if (CountSelectedTracks(project_) == 0) {
        SetTrackSelected(track_, true); // Lua: current cursor if none selected
    }
    refreshTrackSelection();
    const int beforeCount = CountTracks(project_);
    Main_OnCommand(command, 0); // One SWS undoable action, as in the Lua.
    GUID focusGuid = currentGuid;
    if (action == TrackClipboardAction::paste) {
        // SWS normally selects pasted tracks; use the earliest in project
        // order before clearing the physical selection again.
        for (int i = 0, n = CountTracks(project_); i < n; ++i) {
            auto* tr = GetTrack(project_, i);
            if (tr && IsTrackSelected(tr)) {
                if (const GUID* id = GetTrackGUID(tr)) focusGuid = *id;
                break;
            }
        }
    }
    // Never preserve a raw GUID pointer across the SWS edit: copies above
    // are values. The old track may have been destroyed by Cut.
    clearPhysicalSelection();
    refreshAfterTrackEdit(action == TrackClipboardAction::cut ? nullptr : &focusGuid, oldRow);
    if (!active_) return;
    const char* name = action == TrackClipboardAction::copy ? "Copied tracks with routing" :
        action == TrackClipboardAction::cut ? "Cut tracks with routing" : "Pasted tracks with routing";
    if (action != TrackClipboardAction::copy && beforeCount == CountTracks(project_))
        speech_(std::string(name) + ". Track count unchanged. Verify SWS result");
    else speech_(std::string(name) + ". " + folderAwareTrackLabel());
}

void TrackNavigator::moveSelectedTracks(int direction) {
    if (!filterQuery_.empty()) {
        speech_("Clear filter before physically moving tracks"); return;
    }
    if (page_ != Page::tracks || !track_ || !ReorderSelectedTracks || !direction) {
        if (!ReorderSelectedTracks) speech_("Move tracks not available");
        return;
    }
    const int count = CountTracks(project_);
    if (count <= 1) return;
    std::vector<GUID> originallySelected = selectedTrackGuids();
    if (originallySelected.empty()) {
        // Same as Lua: move the logical cursor track if no TCP selection.
        originallySelected.push_back(rows_[row_].guid);
        SetTrackSelected(track_, true);
        refreshTrackSelection();
    }
    // A selected folder represents its *whole* contiguous child block.
    // Selected children within that block must not be separate move roots.
    std::vector<bool> expanded(static_cast<size_t>(count), false);
    int first = count, last = -1;
    for (int i = 0; i < count; ++i) {
        auto* tr = GetTrack(project_, i);
        if (!tr || !IsTrackSelected(tr) || expanded[static_cast<size_t>(i)]) continue;
        const int end = folderLast(project_, i, count);
        for (int j = i; j <= end; ++j) expanded[static_cast<size_t>(j)] = true;
        first = std::min(first, i);
        last = std::max(last, end);
    }
    if (last < 0) { speech_("No selected tracks"); return; }
    if ((direction < 0 && first == 0) || (direction > 0 && last == count - 1)) {
        speech_(direction < 0 ? "Top of tracks" : "End of tracks"); return;
    }
    const int before = direction < 0 ? first - 1 : std::min(count, last + 2);
    const GUID cursorGuid = rows_[row_].guid;
    const int oldRow = row_;
    // Temporarily select all children of selected folders (only while REAPER
    // executes ReorderSelectedTracks). Preserve original logical selection.
    for (int i = 0; i < count; ++i)
        if (auto* tr = GetTrack(project_, i)) SetTrackSelected(tr, expanded[static_cast<size_t>(i)]);
    refreshTrackSelection();
    Undo_BeginBlock2(project_);
    const bool ok = ReorderSelectedTracks(before, 0);
    Undo_EndBlock2(project_, "LReaParams: Move selected tracks", UNDO_STATE_TRACKCFG);
    // Resolve GUIDs only after moving; even if REAPER internally reallocates
    // track objects, we do not retain pointers from before the edit.
    for (int i = 0, n = CountTracks(project_); i < n; ++i) {
        auto* tr = GetTrack(project_, i);
        if (!tr) continue;
        const GUID* g = GetTrackGUID(tr);
        bool logical = false;
        if (g) for (const GUID& original : originallySelected)
            if (equalGuid(*g, original)) { logical = true; break; }
        SetTrackSelected(tr, logical);
    }
    refreshAfterTrackEdit(&cursorGuid, oldRow);
    if (!active_) return;
    speech_(ok ? std::string(direction < 0 ? "Moved up. " : "Moved down. ") +
        folderAwareTrackLabel() : "Unable to move selected tracks");
}
} // namespace lrp
