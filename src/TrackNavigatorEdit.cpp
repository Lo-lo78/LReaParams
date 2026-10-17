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

// SWS's paste action may insert tracks at the start of the project, even
// though the F1 cursor has temporarily selected an anchor.  Move only GUIDs
// that did not exist before paste. Do not guess by selection or track count:
// selections may include existing tracks and SWS can change the TCP selection.
void TrackNavigator::trackClipboard(TrackClipboardAction action) {
    if (page_ != Page::tracks || !track_) return;
    // Lua's SWS/S&M actions preserve routing (including internal sends).
    // Never substitute REAPER's ordinary clipboard commands.
    const char* named = action == TrackClipboardAction::cut ? "_S&M_CUTSNDRCV1" :
        action == TrackClipboardAction::copy ? "_S&M_COPYSNDRCV1" : "_S&M_PASTSNDRCV1";
    if (!NamedCommandLookup || !Main_OnCommand) {
        speech_("SWS command API unavailable"); return;
    }
    const int command = NamedCommandLookup(named);
    if (command <= 0) {
        speech_("SWS/S&M not installed. Tracks with routing were not changed"); return;
    }
    if (action == TrackClipboardAction::paste && !ReorderSelectedTracks) {
        speech_("Paste at cursor unavailable: REAPER track reordering API missing"); return;
    }
    if (action == TrackClipboardAction::paste && !filterQuery_.empty()) {
        speech_("Clear the track filter before pasting"); return;
    }
    const int oldRow = row_;
    const GUID currentGuid = rows_[row_].guid; // value, never a stale track pointer
    const int beforeCount = CountTracks(project_);
    std::vector<GUID> existing;
    if (action == TrackClipboardAction::paste) {
        existing.reserve(static_cast<size_t>(beforeCount));
        for (int i = 0; i < beforeCount; ++i) {
            if (auto* tr = GetTrack(project_, i))
                if (const GUID* id = GetTrackGUID(tr)) existing.push_back(*id);
        }
        // SWS uses the *physical* TCP selection for its insertion anchor.
        // Setting it is useful, but the explicit reposition below is the
        // guarantee that the resulting tracks follow the *logical* F1 cursor.
        for (int i = 0; i < beforeCount; ++i)
            if (auto* tr = GetTrack(project_, i)) SetTrackSelected(tr, tr == track_);
    } else if (CountSelectedTracks(project_) == 0) {
        SetTrackSelected(track_, true);
    }
    refreshTrackSelection();
    Main_OnCommand(command, 0);

    GUID focusGuid = currentGuid;
    bool pasted = false;
    bool placedAtCursor = true;
    if (action == TrackClipboardAction::paste) {
        std::vector<GUID> added;
        const int afterCount = CountTracks(project_);
        int anchorIndex = -1;
        for (int i = 0; i < afterCount; ++i) {
            auto* tr = GetTrack(project_, i);
            const GUID* id = tr ? GetTrackGUID(tr) : nullptr;
            if (!id) continue;
            if (equalGuid(*id, currentGuid)) anchorIndex = i;
            const bool wasHere = std::any_of(existing.begin(), existing.end(),
                [id](const GUID& g) { return equalGuid(g, *id); });
            if (!wasHere) added.push_back(*id);
        }
        if (!added.empty()) {
            pasted = true;
            focusGuid = added.front();
            if (anchorIndex < 0) {
                placedAtCursor = false;
            } else {
                // Check actual project order. Even if SWS already pasted
                // after the anchor, never reorder just to create an undo step.
                bool alreadyAfter = anchorIndex + static_cast<int>(added.size()) < afterCount;
                for (int j = 0; j < static_cast<int>(added.size()) && alreadyAfter; ++j) {
                    auto* tr = GetTrack(project_, anchorIndex + j + 1);
                    const GUID* g = tr ? GetTrackGUID(tr) : nullptr;
                    alreadyAfter = g && equalGuid(*g, added[static_cast<size_t>(j)]);
                }
                if (!alreadyAfter) {
                    // Select precisely the newly pasted block, preserving its
                    // internal routing.  REAPER moves selected tracks in order.
                    for (int i = 0; i < afterCount; ++i) {
                        auto* tr = GetTrack(project_, i);
                        const GUID* g = tr ? GetTrackGUID(tr) : nullptr;
                        const bool newTrack = g && std::any_of(added.begin(), added.end(),
                            [g](const GUID& id) { return equalGuid(id, *g); });
                        if (tr) SetTrackSelected(tr, newTrack);
                    }
                    refreshTrackSelection();
                    Undo_BeginBlock2(project_);
                    // The SDK index points to the track *before which* the
                    // selected tracks will be placed: anchor + 1 means after.
                    placedAtCursor = ReorderSelectedTracks(anchorIndex + 1, 0);
                    Undo_EndBlock2(project_, "LReaParams: Place pasted tracks after F1 cursor", UNDO_STATE_TRACKCFG);
                }
            }
        } else placedAtCursor = false; // nothing pasted: do not claim success
    }
    clearPhysicalSelection();
    refreshAfterTrackEdit(action == TrackClipboardAction::cut ? nullptr : &focusGuid, oldRow);
    if (!active_) return;
    if (action == TrackClipboardAction::paste && !pasted) {
        speech_("No new tracks pasted. Check SWS clipboard"); return;
    }
    if (action == TrackClipboardAction::paste && !placedAtCursor) {
        speech_("Tracks pasted, but placement after the current track could not be confirmed. " +
            folderAwareTrackLabel()); return;
    }
    const char* name = action == TrackClipboardAction::copy ? "Copied tracks with routing" :
        action == TrackClipboardAction::cut ? "Cut tracks with routing" : "Pasted tracks with routing";
    if (action == TrackClipboardAction::cut && beforeCount == CountTracks(project_))
        speech_("Cut tracks with routing. Track count unchanged. Verify SWS result");
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
