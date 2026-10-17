#include "lrp/TrackNavigator.h"
#include <cstddef>
#include <cstring>
#include <string>
#include <vector>

namespace lrp {
namespace {
bool sameGuid(const GUID& a, const GUID& b) noexcept {
    return std::memcmp(&a, &b, sizeof(GUID)) == 0;
}
const char* kindName(bool receives) noexcept { return receives ? "Add receive" : "Add send"; }
}

// The Lua collects ALL REAPER-selected tracks, including tracks hidden from
// its visible F1 grid, then sorts them in project order. Neither the current
// logical F1 row nor REAPER's selected-track anchor is assumed to be a route.
std::vector<GUID> TrackNavigator::selectedTrackGuids() const {
    std::vector<GUID> guids;
    if (!project_) return guids;
    const int count = CountTracks(project_);
    guids.reserve(static_cast<std::size_t>(CountSelectedTracks(project_)));
    for (int i = 0; i < count; ++i) {
        MediaTrack* tr = GetTrack(project_, i);
        if (!tr || !IsTrackSelected(tr)) continue;
        if (const GUID* guid = GetTrackGUID(tr)) guids.push_back(*guid);
    }
    return guids;
}

// Resolve only live tracks in the current project, by GUID. A project edit
// may remove or reorder a track after the first routing keypress; storing
// MediaTrack* and dereferencing it later would risk dangling pointers.
MediaTrack* TrackNavigator::trackByGuid(const GUID& guid) const {
    if (!project_) return nullptr;
    for (int i = 0, n = CountTracks(project_); i < n; ++i) {
        MediaTrack* tr = GetTrack(project_, i);
        if (!tr || !ValidatePtr2(project_, tr, "MediaTrack*")) continue;
        const GUID* current = GetTrackGUID(tr);
        if (current && sameGuid(*current, guid)) return tr;
    }
    return nullptr;
}

void TrackNavigator::resetPendingRouting() noexcept {
    pendingRouting_ = RoutingKind::none;
    pendingTrackGuids_.clear();
}

std::string TrackNavigator::pendingRoutingStatus() const {
    if (pendingRouting_ == RoutingKind::none) return {};
    const bool receive = pendingRouting_ == RoutingKind::receive;
    return std::string(kindName(receive)) + " pending. " +
        std::to_string(pendingTrackGuids_.size()) + (receive ?
        " destination tracks stored. Select source tracks, then press Ctrl Shift R." :
        " source tracks stored. Select destination tracks, then press Ctrl Shift S.");
}

void TrackNavigator::startTrackRouting(RoutingKind kind) {
    const bool receive = kind == RoutingKind::receive;
    const auto tracks = selectedTrackGuids();
    if (tracks.empty()) {
        speech_(receive ? "No destination tracks selected" : "No source tracks selected");
        return;
    }
    resetPendingRouting();
    pendingRouting_ = kind;
    pendingTrackGuids_ = tracks;
    resetSelectionStroke();
    // Exactly like the Lua, clear selection after storing the first stage so
    // the next selection refers only to the other side of the routing.
    for (int i = 0, n = CountTracks(project_); i < n; ++i) {
        if (MediaTrack* tr = GetTrack(project_, i)) SetTrackSelected(tr, false);
    }
    refreshTrackSelection(); // also re-baselines contextUnchanged()
    speech_(std::string(kindName(receive)) + ". " +
        std::to_string(pendingTrackGuids_.size()) + (receive ?
        " destination tracks stored. Select source tracks, then press Ctrl Shift R." :
        " source tracks stored. Select destination tracks, then press Ctrl Shift S."));
}

void TrackNavigator::completeTrackRouting() {
    if (pendingRouting_ == RoutingKind::none) return;
    const auto selectedNow = selectedTrackGuids();
    const bool receive = pendingRouting_ == RoutingKind::receive;
    if (selectedNow.empty()) {
        speech_(receive ? "No source tracks selected" : "No destination tracks selected");
        return; // do not discard the first stage, or create anything
    }
    // A receive of D from S is created via CreateTrackSend(S, D): the REAPER
    // API has no separate CreateTrackReceive call.
    const auto& sourceGuids = receive ? selectedNow : pendingTrackGuids_;
    const auto& destinationGuids = receive ? pendingTrackGuids_ : selectedNow;
    // Resolve just once before creating routes.  The API only adds routing
    // connections, not tracks, so these live pointers remain valid for the
    // duration of this UI-thread operation.  This avoids a project scan for
    // every element of the cross product in large multitrack projects.
    std::vector<MediaTrack*> sources, destinations;
    sources.reserve(sourceGuids.size());
    destinations.reserve(destinationGuids.size());
    for (const GUID& g : sourceGuids) sources.push_back(trackByGuid(g));
    for (const GUID& g : destinationGuids) destinations.push_back(trackByGuid(g));
    int added = 0, skipped = 0, failed = 0;
    bool undoStarted = false;
    for (std::size_t s = 0; s < sources.size(); ++s) {
        for (std::size_t d = 0; d < destinations.size(); ++d) {
            MediaTrack* source = sources[s];
            MediaTrack* destination = destinations[d];
            if (!source || !destination) { ++failed; continue; }
            if (sameGuid(sourceGuids[s], destinationGuids[d])) { ++skipped; continue; }
            if (!undoStarted) { Undo_BeginBlock2(project_); undoStarted = true; }
            if (CreateTrackSend(source, destination) >= 0) ++added;
            else ++failed;
        }
    }
    if (undoStarted) {
        Undo_EndBlock2(project_, receive ? "LReaParams: Add receives" :
            "LReaParams: Add sends", UNDO_STATE_TRACKCFG);
    }
    resetPendingRouting();
    resetSelectionStroke();
    if (added) { TrackList_AdjustWindows(false); UpdateArrange(); }
    // Keep the second-stage selection and the F1 cursor as in the Lua.
    refreshTrackSelection();
    std::string result = "Added " + std::to_string(added) + (receive ? " receives." : " sends.");
    if (skipped) result += " " + std::to_string(skipped) + " skipped.";
    if (failed) result += " " + std::to_string(failed) + " failed.";
    speech_(result);
}

void TrackNavigator::cancelTrackRouting() {
    if (pendingRouting_ == RoutingKind::none) return;
    const bool receive = pendingRouting_ == RoutingKind::receive;
    resetPendingRouting();
    speech_(std::string(kindName(receive)) + " cancelled");
}

void TrackNavigator::addTrackRouting(RoutingKind kind) {
    if (page_ != Page::tracks) { speech_("Only in Tracks"); return; }
    if (pendingRouting_ == RoutingKind::none) { startTrackRouting(kind); return; }
    if (pendingRouting_ != kind) {
        speech_(pendingRouting_ == RoutingKind::receive ?
            "Finish or cancel Add receive first" : "Finish or cancel Add send first");
        return;
    }
    completeTrackRouting();
}
} // namespace lrp
