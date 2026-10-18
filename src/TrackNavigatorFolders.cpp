#include "lrp/TrackNavigator.h"
#include <algorithm>
#include <cmath>
#include <cstring>

namespace lrp {
namespace {
int folderDepth(MediaTrack* track) {
    // REAPER's I_FOLDERDEPTH: +1 opens, 0 is ordinary, -N closes N
    // folders AFTER this track. A track can terminate multiple folders.
    return static_cast<int>(std::lround(GetMediaTrackInfo_Value(track, "I_FOLDERDEPTH")));
}
std::string nameOf(MediaTrack* track) {
    char buf[2048]{};
    if (track && GetTrackName(track, buf, sizeof(buf)) && buf[0]) return buf;
    const double num = track ? GetMediaTrackInfo_Value(track, "IP_TRACKNUMBER") : 0;
    return "Track " + std::to_string(static_cast<int>(num));
}
}

void TrackNavigator::rebuildVisibleRows() {
    rows_.clear();
    int nesting = 0;
    int hiddenLevel = -1;
    for (int i = 0, n = CountTracks(project_); i < n; ++i) {
        MediaTrack* tr = GetTrack(project_, i);
        if (!tr) continue;
        const int depth = folderDepth(tr);
        const bool hidden = hiddenLevel >= 0 && nesting > hiddenLevel;
        if (!hidden && GetMediaTrackInfo_Value(tr, "B_SHOWINTCP") > 0.5 &&
            (page_ != Page::tracks || trackMatchesFilter(tr))) {
            if (const GUID* guid = GetTrackGUID(tr)) rows_.push_back({tr, *guid, i});
        }
        // Do not let a child collapsed folder override the outer fold.
        if (!hidden && hiddenLevel < 0 && depth > 0 &&
            GetMediaTrackInfo_Value(tr, "I_FOLDERCOMPACT") >= 2.0)
            hiddenLevel = nesting;
        nesting = std::max(0, nesting + depth);
        if (hiddenLevel >= 0 && nesting <= hiddenLevel) hiddenLevel = -1;
    }
}

std::vector<MediaTrack*> TrackNavigator::endingFolders(MediaTrack* target) const {
    std::vector<MediaTrack*> result;
    if (!target || !project_) return result;
    std::vector<MediaTrack*> stack;
    for (int i = 0, n = CountTracks(project_); i < n; ++i) {
        MediaTrack* tr = GetTrack(project_, i);
        if (!tr) continue;
        const int delta = folderDepth(tr);
        if (tr == target) {
            if (delta < 0) {
                for (int j = 0; j < -delta && !stack.empty(); ++j) {
                    result.push_back(stack.back()); // inner -> outer
                    stack.pop_back();
                }
            }
            break;
        }
        if (delta > 0) {
            for (int j = 0; j < delta; ++j) stack.push_back(tr);
        } else if (delta < 0) {
            for (int j = 0; j < -delta && !stack.empty(); ++j) stack.pop_back();
        }
    }
    return result;
}

std::string TrackNavigator::folderAwareTrackLabel() const {
    if (!track_) return "No track";
    std::string label;
    if (folderDepth(track_) > 0) {
        const bool closed = GetMediaTrackInfo_Value(track_, "I_FOLDERCOMPACT") >= 1.0;
        label = std::string(closed ? "closed folder " : "open folder ") + trackName();
    } else label = trackName();
    for (MediaTrack* folder : endingFolders(track_))
        label += ", end folder " + nameOf(folder);
    return label;
}

void TrackNavigator::toggleCurrentFolder() {
    if (page_ != Page::tracks || !track_) return;
    if (!filterQuery_.empty()) {
        speech_("Clear filter before collapsing folders"); return;
    }
    MediaTrack* target = nullptr;
    if (folderDepth(track_) > 0) {
        target = track_;
        lastEndFolderTrackIndex_ = -1;
        nextEndFolderIndex_ = 0;
    } else {
        const auto endings = endingFolders(track_);
        if (endings.empty()) { speech_("Not a folder or end folder"); return; }
        const int index = rows_[row_].projectIndex;
        if (lastEndFolderTrackIndex_ != index) {
            lastEndFolderTrackIndex_ = index;
            nextEndFolderIndex_ = 0;
        }
        target = endings[nextEndFolderIndex_ % endings.size()];
        ++nextEndFolderIndex_;
    }
    if (!target || !ValidatePtr2(project_, target, "MediaTrack*")) {
        speech_("Folder no longer available"); return;
    }
    const bool closed = GetMediaTrackInfo_Value(target, "I_FOLDERCOMPACT") >= 1.0;
    const GUID* guid = GetTrackGUID(target);
    if (!guid) { speech_("Folder GUID unavailable"); return; }
    const GUID destination = *guid;
    Undo_BeginBlock2(project_);
    const bool ok = SetMediaTrackInfo_Value(target, "I_FOLDERCOMPACT", closed ? 0.0 : 2.0);
    Undo_EndBlock2(project_, "LReaParams: toggle track folder", UNDO_STATE_TRACKCFG);
    if (!ok) { speech_("Folder change failed"); return; }
    TrackList_AdjustWindows(false);
    UpdateArrange();
    // Collapse may remove the current last-track row from the visible list.
    // Reanchor at the target folder and preserve the F1 parameter column.
    rebuildVisibleRows();
    for (int i = 0; i < static_cast<int>(rows_.size()); ++i) {
        if (std::memcmp(&rows_[i].guid, &destination, sizeof(GUID)) == 0) {
            row_ = i;
            track_ = rows_[i].track;
            break;
        }
    }
    valueMode_ = false;
    resetSelectionStroke();
    syncCursorToReaper();
    rememberPosition();
    announceTrack();
}

void TrackNavigator::deleteCurrentRouting() {
    if (page_ == Page::tracks || !track_) return;
    const Entry* e = current();
    if (!e || e->index < 0) { speech_("No send or receive"); return; }
    const bool receive = e->category == -1;
    const int oldColumn = detailIndex_;
    const int oldParameter = parameter_;
    MediaTrack* source = track_;
    int realIndex = e->index;
    const std::string peerName = detailPeerName(e->category, e->index);
    if (receive) {
        source = routingEndpoint(*e, true);
        if (!source) { speech_("Receive source not found"); return; }
        // Every receive refers to a real send on its source. Reconstruct the
        // ordinal among duplicate sends from this source, just as Lua does.
        int occurrence = 0;
        for (int i = 0; i <= e->index; ++i) {
            Entry prior = *e;
            prior.index = i;
            if (routingEndpoint(prior, true) == source) ++occurrence;
        }
        realIndex = -1;
        for (int i = 0, n = GetTrackNumSends(source, 0); i < n; ++i) {
            auto* peer = static_cast<MediaTrack*>(GetSetTrackSendInfo(source, 0, i, "P_DESTTRACK", nullptr));
            if (peer == track_ && --occurrence == 0) { realIndex = i; break; }
        }
        if (realIndex < 0) { speech_("Receive send instance not found"); return; }
    }
    if (!source || !ValidatePtr2(project_, source, "MediaTrack*") || !RemoveTrackSend) {
        speech_("Delete send not available"); return;
    }
    Undo_BeginBlock2(project_);
    const bool ok = RemoveTrackSend(source, 0, realIndex);
    Undo_EndBlock2(project_, receive ? "LReaParams: remove receive" :
        "LReaParams: remove send", UNDO_STATE_TRACKCFG);
    if (!ok) { speech_("Delete routing failed"); return; }
    // Invalidate guards even if a subsequent edit recreates the same number
    // and destination order of sends (otherwise ordinals could be reused).
    memory_.invalidateSendGuardsForSource(trackGuidText(source));
    memory_.flush();
    TrackList_AdjustWindows(false);
    UpdateArrange();
    // Rebuild before the next context check, or the old send counts would
    // deliberately invalidate Track Params after a successful deletion.
    buildEntries();
    const int count = static_cast<int>(entries_.size()) / detailHeight;
    if (count == 0) {
        // The last visible routing column may have been filtered out while
        // other sends remain.  Clear the filter before returning to F1.
        filterQuery_.clear();
        page_ = Page::tracks;
        detailIndex_ = 0;
        parameter_ = receive ? 7 : 6;
        buildEntries();
        valueMode_ = false;
        rememberPosition();
        speech_(std::string("Deleted ") + (receive ? "receive from " : "send to ") + peerName +
            (receive ? ". No receives" : ". No sends"));
        return;
    }
    detailIndex_ = std::clamp(oldColumn, 0, count - 1);
    parameter_ = std::clamp(oldParameter, 0, detailHeight - 1);
    valueMode_ = false;
    stepScale_ = memory_.step(parameterKey());
    rememberPosition();
    speech_(std::string("Deleted ") + (receive ? "receive from " : "send to ") + peerName +
        ". " + currentParameterSpeech());
}
} // namespace lrp
