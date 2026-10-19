#include "lrp/FxNavigator.h"
#include "lrp/ReaEqChunk.h"
#include "lrp/ReaEqVirtual.h"
#include <algorithm>
#include <cmath>
#include <cstring>
#include <cctype>
#include <utility>
#include <stdexcept>

namespace lrp {
namespace {
bool same(const GUID* a, const GUID& b) { return a && std::memcmp(a, &b, sizeof(GUID)) == 0; }
bool anyNormalTrackFx(ReaProject* project) {
    if (!project) return false;
    if (auto* master = GetMasterTrack(project); master &&
        (TrackFX_GetCount(master) > 0 || TrackFX_GetRecCount(master) > 0)) return true;
    for (int i = 0; i < CountTracks(project); ++i) {
        if (auto* track = GetTrack(project, i); track && TrackFX_GetCount(track) > 0) return true;
    }
    return false;
}
}
void FxNavigator::flushPersistentPosition() noexcept {
    if (!persistentPositionWriter_ || !active_ || !track_ || !count_ ||
        browserIndex_ < 0 || browserIndex_ >= static_cast<int>(entries_.size()) ||
        parameterName_.empty()) return;
    try {
        if (!fxOrder_.persistLastParameter(parameter_, parameterName_))
            OutputDebugStringW(L"LReaParams: FX position was not saved.\n");
    } catch (const std::exception&) {
        // Navigation/REAPER shutdown must never fail due to a read-only or
        // externally modified profile. Preserve that external file untouched.
        OutputDebugStringW(L"LReaParams: could not persist FX position.\n");
    }
}
void FxNavigator::end() noexcept {
    if (active_) {
        flushParameterSteps();
        // end() is noexcept: even allocation failure in the session snapshot
        // must not crash REAPER while it closes.
        try {rememberPosition();} catch (...) {}
        flushPersistentPosition();
    }
    pendingF8At_ = 0;
    clearAutomationConfirm_ = false;
    clearAutomationYes_ = false;
    // Keep per-instance Original/Compare snapshots across navigator exits and
    // Ctrl+Tab. Original is captured only on first entry to the FX; a double
    // F8 is the sole user command which updates that reference.
    active_ = false; fxBrowserMode_ = false; browserScopeMonitor_ = false; browserCursor_ = 0; browserMasterCursor_ = browserMonitorCursor_ = -1;
    recentMode_ = false; numericEdit_ = false; learnCc_ = false;
    floatingCc_ = false; floatingWaiting_ = false; pickup_.clear();
    valueMode_ = false; searchMode_ = false; editF7_ = false;
    textEdit_ = false; memoryManager_ = false; defaultConfirm_ = false;
    defaultRegenerate_ = false; memoryStandalone_ = false;
    groupSlot_ = 0; groupReturnActive_ = false;
    f7FilterActive_ = false; f7FullView_.clear(); f7FilterPositions_.clear();
    f7FilterQuery_.clear(); search_.clear(); entries_.clear(); count_ = 0;
}
void FxNavigator::restorePersistedParameter() {
    // Session memory is deliberately authoritative while REAPER remains open:
    // per-FX GUID positions beat the shared, Lua-compatible plugin LastParam.
    if (const auto* state = contextMemory())
        for (const auto& position : state->positions)
            if (same(&position.fxGuid, fxGuid_)) return;
    const std::string saved = fxOrder_.lastParameterRecord();
    const auto tab = saved.find('\t');
    if (tab == std::string::npos || tab == 0) return;
    int savedIndex = 0;
    try {
        const std::string numeric = saved.substr(0, tab);
        std::size_t parsed = 0;
        const long value = std::stol(numeric, &parsed, 10);
        if (parsed != numeric.size() || value < -2147483647L || value > 2147483647L) return;
        savedIndex = static_cast<int>(value);
    } catch (...) {return;}
    const std::string savedName = saved.substr(tab + 1);
    auto validIndex = [&](int id) {
        return id == compareParamIndex || eqVirtualValid(id) || dynamicsVirtualValid(id) || (id >= 0 && id < count_);
    };
    if (!validIndex(savedIndex)) return;
    auto nameFor = [&](int id) {
        const int previous = parameter_;
        parameter_ = id;
        const std::string result = parameterName();
        parameter_ = previous;
        return result;
    };
    // Match the Lua: restore by name first when an FX update changes indices,
    // then by numeric index. Preserve the exact virtual ID if still valid.
    int target = savedIndex;
    if (!savedName.empty() && nameFor(target) != savedName) {
        bool found = false;
        for (int id : fxOrder_.visibleOrder()) {
            if (validIndex(id) && nameFor(id) == savedName) {
                target = id; found = true; break;
            }
        }
        if (!found && !validIndex(target)) return;
    }
    rebuildView(target);
}
// Startup context follows the original Lua's track/item selection rather than
// requiring GetTouchedOrFocusedFX, which is often empty when FX Params is invoked.
bool FxNavigator::begin() {
    MediaTrack* explicitTrack = nextStartTrack_;
    nextStartTrack_ = nullptr;
    end();
    nativeFxWindowRequest_ = NativeFxWindow::none;
    project_ = EnumProjects(-1, nullptr, 0);
    if (!project_) { speech_("No REAPER project"); return false; }
    // Retain A/B snapshots for other OPEN project tabs, but discard snapshots
    // belonging to closed projects. Never dereference saved project pointers.
    // No state is applied to an FX when reopening this navigator.
    compareStates_.erase(std::remove_if(compareStates_.begin(), compareStates_.end(),
        [](const CompareState& state) {
            for (int index = 0; ; ++index) {
                ReaProject* openProject = EnumProjects(index, nullptr, 0);
                if (!openProject) return true;
                if (openProject == state.project) return false;
            }
        }), compareStates_.end());
    track_ = nullptr; take_ = nullptr;
    if (explicitTrack && ValidatePtr2(project_, explicitTrack, "MediaTrack*"))
        track_ = explicitTrack;
    // A specifically requested track is never replaced with another track
    // just because its FX chain is empty (Ctrl+Tab from Track Params).
    if (track_ && TrackFX_GetCount(track_) <= 0 &&
        !(track_ == GetMasterTrack(project_) && TrackFX_GetRecCount(track_) > 0)) {
        speech_("No track FX"); return false;
    }
    // When invoked from a native FX Chain list, its focused FX determines
    // whether we entered Master FX or Monitor FX. A simultaneously visible
    // Monitor window must not override an explicitly focused Master FX.
    int focusedFxInChain = -1;
    // Follow OSARA's GetTouchedOrFocusedFX logic when REAPER's FX list owns
    // focus. The visible chain might belong to a track not currently selected.
    // Never use the last-touched FX here: that might be from another track.
    if (!track_ && GetDlgCtrlID(GetFocus()) == 1076) {
        int tr = -1, item = -1, takeIdx = -1, fx = -1, state = 0;
        if (GetTouchedOrFocusedFX(1, &tr, &item, &takeIdx, &fx, &state) && !(state & 1)) {
            MediaTrack* owner = tr == -1 ? GetMasterTrack(project_) : GetTrack(project_, tr);
            if (owner && ValidatePtr2(project_, owner, "MediaTrack*")) {
                if (item >= 0 && takeIdx >= 0) {
                    MediaItem* mediaItem = GetTrackMediaItem(owner, item);
                    MediaItem_Take* wantedTake = mediaItem ? GetTake(mediaItem, takeIdx) : nullptr;
                    if (wantedTake && TakeFX_GetCount(wantedTake) > 0) {
                        track_ = owner; take_ = wantedTake; focusedFxInChain = fx;
                    }
                } else if (TrackFX_GetCount(owner) > 0 ||
                           (owner == GetMasterTrack(project_) && TrackFX_GetRecCount(owner) > 0)) {
                    track_ = owner; focusedFxInChain = fx;
                }
            }
        }
    }
    MediaTrack* master = GetMasterTrack(project_);
    const bool masterSelected = master && GetMediaTrackInfo_Value(master, "I_SELECTED") > 0.5;
    // With an explicit track/item selection, never fall back to an unrelated
    // open FX chain. The focused native FX list above is the one exception:
    // its own highlighted FX is an explicit host selection.
    if (!track_ && GetDlgCtrlID(GetFocus()) != 1076) {
        const int itemCount = CountSelectedMediaItems(project_);
        const bool itemContext = GetCursorContext2(true) == 1 && itemCount > 0;
        if (itemContext) {
            bool hasTakeFx = false;
            for (int i = 0; i < itemCount; ++i) {
                MediaItem* item = GetSelectedMediaItem(project_, i);
                MediaItem_Take* take = item ? GetActiveTake(item) : nullptr;
                if (take && TakeFX_GetCount(take) > 0) {hasTakeFx = true; break;}
            }
            if (!hasTakeFx) {speech_("No take FX"); return false;}
        } else if (masterSelected) {
            if (TrackFX_GetCount(master) <= 0 && TrackFX_GetRecCount(master) <= 0) {
                speech_("No track FX"); return false;
            }
        } else if (CountSelectedTracks(project_) > 0) {
            MediaTrack* selected = GetSelectedTrack(project_, 0);
            if (selected && TrackFX_GetCount(selected) <= 0) {
                speech_("No track FX"); return false;
            }
        } else if (itemCount > 0) {
            bool hasTakeFx = false;
            for (int i = 0; i < itemCount; ++i) {
                MediaItem* item = GetSelectedMediaItem(project_, i);
                MediaItem_Take* take = item ? GetActiveTake(item) : nullptr;
                if (take && TakeFX_GetCount(take) > 0) {hasTakeFx = true; break;}
            }
            if (!hasTakeFx) {speech_("No take FX"); return false;}
        }
    }
    // An already visible FX chain wins over cursor context (as in the Lua).
    if (!track_ && masterSelected && (TrackFX_GetChainVisible(master) >= 0 || TrackFX_GetRecChainVisible(master) >= 0)) {
        track_ = master;
    }
    if (!track_) {
        const int selectedCount = CountSelectedTracks(project_);
        for (int i = 0; i < selectedCount; ++i) {
            auto* candidate = GetSelectedTrack(project_, i);
            if (candidate && TrackFX_GetChainVisible(candidate) >= 0) { track_ = candidate; break; }
        }
    }
    if (!track_ && CountSelectedMediaItems(project_) > 0) {
        for (int i = 0; i < CountSelectedMediaItems(project_); ++i) {
            auto* item = GetSelectedMediaItem(project_, i);
            if (!item) continue;
            auto* candidate = GetActiveTake(item);
            if (candidate && TakeFX_GetChainVisible(candidate) >= 0) {
                take_ = candidate; track_ = GetMediaItemTrack(item); break;
            }
        }
    }
    if (!track_) {
        if (masterSelected) {
            track_ = master;
        } else if (GetCursorContext2(true) == 1 && CountSelectedMediaItems(project_) > 0) {
            // Deliberate item context: do not silently edit track FX instead.
            for (int i = 0; i < CountSelectedMediaItems(project_); ++i) {
                auto* item = GetSelectedMediaItem(project_, i);
                auto* candidate = item ? GetActiveTake(item) : nullptr;
                if (candidate && TakeFX_GetCount(candidate) > 0) {
                    take_ = candidate; track_ = GetMediaItemTrack(item); break;
                }
            }
            if (!take_) { speech_("No take FX"); return false; }
        } else if (CountSelectedTracks(project_) > 0) {
            track_ = GetSelectedTrack(project_, 0);
        } else if (CountSelectedMediaItems(project_) > 0) {
            for (int i = 0; i < CountSelectedMediaItems(project_); ++i) {
                auto* item = GetSelectedMediaItem(project_, i);
                auto* candidate = item ? GetActiveTake(item) : nullptr;
                if (candidate && TakeFX_GetCount(candidate) > 0) {
                    take_ = candidate; track_ = GetMediaItemTrack(item); break;
                }
            }
            if (!track_) { speech_("No take FX"); return false; }
        } else {
            // Lua's last-resort behavior when no track or item is selected.
            auto* last = GetLastTouchedTrack();
            if (last && ValidatePtr2(project_, last, "MediaTrack*") && TrackFX_GetCount(last) > 0) track_ = last;
            if (!track_) for (int i = 0; i < CountTracks(project_); ++i) {
                auto* candidate = GetTrack(project_, i);
                if (candidate && TrackFX_GetCount(candidate) > 0) { track_ = candidate; break; }
            }
        }
    }
    if (!track_ || !ValidatePtr2(project_, track_, "MediaTrack*")) {
        speech_(anyNormalTrackFx(project_) ? "Select a track with FX or an item with take FX" : "No FX in tracks");
        return false;
    }
    const auto* trackGuid = GetTrackGUID(track_);
    if (!trackGuid) return false;
    trackGuid_ = *trackGuid;

    if (!rebuildEntries()) {
        speech_(take_ ? "No take FX" : "No track FX");
        return false;
    }

    // The Lua prefers a deliberately selected FX in an open chain. However,
    // a visible chain often keeps its OLD highlight while Ctrl+Up/Down changes
    // LReaParams's FX. Do not let that stale highlight defeat session memory.
    // If the host highlight changed since our last navigation, respect it.
    const int visible = visibleFxIndex();
    const StoredContext* remembered = contextMemory();
    int preferred = 0;
    bool havePreferred = false;
    // Exact native FX Chain focus wins over an unrelated visible FX window,
    // especially when Master and Monitor FX chains are both visible.
    if (focusedFxInChain >= 0) {
        for (size_t i=0; i<entries_.size(); ++i) {
            if (entries_[i].index == focusedFxInChain) {
                preferred = static_cast<int>(i);
                havePreferred = true;
                break;
            }
        }
    }
    if (!havePreferred && remembered && remembered->hasLastFx) {
        const bool externalSelectionChanged =
            visible >= 0 && visible != remembered->observedVisibleFx;
        if (!externalSelectionChanged) {
            preferred = rememberedFxIndex(*remembered);
            havePreferred = preferred >= 0;
        }
    }
    if (!havePreferred && visible >= 0) {
        for (size_t i = 0; i < entries_.size(); ++i) {
            if (entries_[i].index == visible) {
                preferred = static_cast<int>(i);
                havePreferred = true;
                break;
            }
        }
    }
    if (!havePreferred) preferred = 0;

    active_ = true;
    searchMode_ = false; search_.clear();
    valueMode_ = false; stepScale_ = 0; columns_ = 10;
    // Restore the last navigated FX in this particular track/take context,
    // not an arbitrary global last-touched FX from another track.
    if (selectFx(preferred)) return true;
    for (int i = preferred + 1; i < static_cast<int>(entries_.size()); ++i)
        if (selectFx(i)) return true;
    for (int i = preferred - 1; i >= 0; --i)
        if (selectFx(i)) return true;
    // An all-offline chain must still be accessible after REAPER restarts:
    // leave the user in the FX browser so Ctrl+Alt+B can bring an FX online.
    int offlineCursor = -1;
    for (int i = 0; i < static_cast<int>(entries_.size()); ++i) {
        const int id = entries_[static_cast<size_t>(i)].index;
        if (take_ ? TakeFX_GetOffline(take_, id) : TrackFX_GetOffline(track_, id)) {
            if (i == preferred) {offlineCursor = i;break;}
            if (offlineCursor < 0) offlineCursor = i;
        }
    }
    if (offlineCursor >= 0) {
        browserIndex_ = browserCursor_ = offlineCursor;
        fx_ = entries_[static_cast<size_t>(offlineCursor)].index;
        fxGuid_ = entries_[static_cast<size_t>(offlineCursor)].guid;
        count_ = 0;parameter_ = 0;parameterName_.clear();
        fxBrowserMode_ = true;
        browserScopeMonitor_ = !take_ && track_ == GetMasterTrack(project_) &&
                               (entries_[static_cast<size_t>(offlineCursor)].index & 0x1000000);
        speech_("FX Browser. " + browserSpeech());
        return true;
    }
    speech_("No navigable FX parameters");
    end(); return false;
}
bool FxNavigator::rebuildEntries() {
    entries_.clear();
    const int regularCount = take_ ? TakeFX_GetCount(take_) : TrackFX_GetCount(track_);
    const int monitorCount = !take_ && track_ == GetMasterTrack(project_) ? TrackFX_GetRecCount(track_) : 0;
    for (int i = 0; i < regularCount + monitorCount; ++i) {
        const int fx = i < regularCount ? i : 0x1000000 + (i - regularCount);
        const GUID* guid = take_ ? TakeFX_GetFXGUID(take_, fx) : TrackFX_GetFXGUID(track_, fx);
        if (!guid) continue;
        char name[2048]{};
        if (take_) TakeFX_GetFXName(take_, fx, name, sizeof(name));
        else TrackFX_GetFXName(track_, fx, name, sizeof(name));
        FxEntry entry; entry.index = fx; entry.guid = *guid;
        entry.name = name[0] ? name : ("FX " + std::to_string(i + 1));
        if (fx & 0x1000000) entry.name = "Monitor: " + entry.name;
        entries_.push_back(std::move(entry));
    }
    return !entries_.empty();

}
FxNavigator::StoredContext* FxNavigator::contextMemory() noexcept {
    for (auto& state : sessionMemory_) {
        if (state.project == project_ && state.take == take_ &&
            same(&state.trackGuid, trackGuid_)) return &state;
    }
    return nullptr;
}
const FxNavigator::StoredContext* FxNavigator::contextMemory() const noexcept {
    for (const auto& state : sessionMemory_) {
        if (state.project == project_ && state.take == take_ &&
            same(&state.trackGuid, trackGuid_)) return &state;
    }
    return nullptr;
}
FxNavigator::StoredContext& FxNavigator::ensureContextMemory() {
    if (auto* found = contextMemory()) return *found;
    StoredContext state{};
    state.project = project_;
    state.trackGuid = trackGuid_;
    state.take = take_;
    sessionMemory_.push_back(std::move(state));
    return sessionMemory_.back();
}
int FxNavigator::visibleFxIndex() const {
    if (!track_) return -1;
    if (take_) return TakeFX_GetChainVisible(take_);
    if (track_ == GetMasterTrack(project_)) {
        const int recVisible = TrackFX_GetRecChainVisible(track_);
        if (recVisible >= 0) return 0x1000000 + recVisible;
    }
    return TrackFX_GetChainVisible(track_);
}
int FxNavigator::rememberedFxIndex(const StoredContext& state) const {
    // First match the native per-instance FX GUID: handles duplicate names,
    // reordered chains and master/monitor FX without guessing by position.
    for (size_t i = 0; i < entries_.size(); ++i) {
        if (same(&entries_[i].guid, state.lastFxGuid))
            return static_cast<int>(i);
    }
    // Match Lua's historical fallback: same FX name, same FX area, same
    // occurrence number. A replaced FX gets a new GUID but may be equivalent.
    int occurrence = 0;
    for (size_t i = 0; i < entries_.size(); ++i) {
        const bool monitor = (entries_[i].index & 0x1000000) != 0;
        if (entries_[i].name == state.lastFxName && monitor == state.lastFxMonitor) {
            ++occurrence;
            if (occurrence == state.lastFxOccurrence) return static_cast<int>(i);
        }
    }
    return -1;
}
void FxNavigator::restoreParameterPosition() {
    parameter_ = 0;
    columns_ = 10;
    stepScale_ = 0;
    if (const auto* state = contextMemory()) {
        for (const auto& saved : state->positions) {
            if (!same(&saved.fxGuid, fxGuid_)) continue;
            columns_ = std::clamp(saved.gridHeight, 1, 200);
            stepScale_ = std::clamp(saved.stepScale, -10, 10);
            // Prefer the original parameter index if it still has the same
            // name; otherwise find that name in the updated plugin parameter list.
            auto matches = [&](int index) {
                if(index==compareParamIndex)return saved.parameterName=="Compare";
                if(index<0) {
                    if(eqVirtualValid(index))return saved.parameterName==eqVirtualName(index);
                    if(dynamicsVirtualValid(index))return saved.parameterName==dynamicsVirtualName(index);
                    return false;
                }
                if(index>=count_)return false;
                char raw[4096]{};
                const bool ok=take_?TakeFX_GetParamName(take_,fx_,index,raw,sizeof(raw)):
                                    TrackFX_GetParamName(track_,fx_,index,raw,sizeof(raw));
                if(!ok)return false;
                // The position is stored with an accessible alias, not always
                // the raw REAPER name (Hipass -> Detector Highpass, etc.).
                // Accept both, avoiding a spurious jump to Threshold on reopen.
                if(saved.parameterName==raw)return true;
                const auto alias=dynamicsAlias(index);
                return !alias.empty() && saved.parameterName==alias;
            };
            if (matches(saved.parameter)) { parameter_ = saved.parameter; return; }
            if (!saved.parameterName.empty()) {
                for (int i = 0; i < count_; ++i) {
                    if (matches(i)) { parameter_ = i; return; }
                }
            }
            // If the plugin's parameter layout changed, never restore a stale
            // numeric index that might control an unrelated parameter.
            return;
        }
    }
}
void FxNavigator::rememberPosition() {
    if (!active_ || !track_ || count_ <= 0 || (parameter_ < 0 && parameter_!=compareParamIndex && !eqVirtualValid(parameter_) && !dynamicsVirtualValid(parameter_)) || parameter_ >= count_ ||
        browserIndex_ < 0 || browserIndex_ >= static_cast<int>(entries_.size())) return;
    syncParameterStep();
    auto& state = ensureContextMemory();
    state.hasLastFx = true;
    state.lastFxGuid = fxGuid_;
    state.lastFxName = entries_[browserIndex_].name;
    state.lastFxMonitor = (fx_ & 0x1000000) != 0;
    state.lastFxOccurrence = 0;
    for (int i = 0; i <= browserIndex_; ++i) {
        if (entries_[i].name == state.lastFxName &&
            ((entries_[i].index & 0x1000000) != 0) == state.lastFxMonitor)
            ++state.lastFxOccurrence;
    }
    state.observedVisibleFx = visibleFxIndex();
    for (auto& pos : state.positions) {
        if (same(&pos.fxGuid, fxGuid_)) {
            pos.parameter = parameter_;
            pos.parameterName = parameterName_;
            pos.gridHeight = columns_;
            pos.stepScale = stepScale_;
            pos.viewPosition = viewPos_;
            pos.customView = fxOrder_.custom;
            pos.f7Selected = f7Selected_;
            return;
        }
    }
    StoredFxPosition pos{};
    pos.fxGuid = fxGuid_;
    pos.parameter = parameter_;
    pos.parameterName = parameterName_;
    pos.gridHeight = columns_;
    pos.stepScale = stepScale_;
    pos.viewPosition = viewPos_;
    pos.customView = fxOrder_.custom;
    pos.f7Selected = f7Selected_;
    state.positions.push_back(std::move(pos));
}
void FxNavigator::switchFx(int direction) {
    if (direction == 0) return;
    const bool master = !take_ && track_ == GetMasterTrack(project_);
    const bool fromMonitor = (fx_ & 0x1000000) != 0;
    for (int i = browserIndex_ + direction; i >= 0 && i < static_cast<int>(entries_.size()); i += direction) {
        // Master FX and Monitor FX are different native chains. Ctrl+Up/Down
        // must never cross between them even though entries_ stores both.
        if (master && ((entries_[static_cast<size_t>(i)].index & 0x1000000) != 0) != fromMonitor)
            break;
        const int count = take_ ? TakeFX_GetNumParams(take_, entries_[i].index)
                                : TrackFX_GetNumParams(track_, entries_[i].index);
        if (count <= 0) continue;
        if (!selectFx(i)) return;
        speech_(fxContextAnnouncement());
        return;
    }
    // First/last FX is deliberately silent, like the edges of the grid.
}
void FxNavigator::switchTrack(int direction) {
    if (!track_ || !direction) return;
    if (track_ == GetMasterTrack(project_)) { speech_("Master"); return; }
    const int ordinal = static_cast<int>(GetMediaTrackInfo_Value(track_, "IP_TRACKNUMBER")) - 1;
    const int total = CountTracks(project_);
    if (ordinal < 0 || ordinal >= total) return;
    MediaTrack* target = nullptr;
    bool othersHaveFx = false;
    for (int i = 0; i < total; ++i) {
        auto* candidate = GetTrack(project_, i);
        if (candidate && candidate != track_ && TrackFX_GetCount(candidate) > 0) othersHaveFx = true;
    }
    for (int i = ordinal + direction; i >= 0 && i < total; i += direction) {
        auto* candidate = GetTrack(project_, i);
        if (!candidate || TrackFX_GetCount(candidate) <= 0) continue;
        bool usable = false;
        const int nfx = TrackFX_GetCount(candidate);
        for (int j = 0; j < nfx; ++j) {
            if (TrackFX_GetFXGUID(candidate, j) && TrackFX_GetNumParams(candidate, j) > 0) {
                usable = true; break;
            }
        }
        if (usable) { target = candidate; break; }
    }
    if (!target) {
        speech_(othersHaveFx ? (direction > 0 ? "No next track with FX" : "No previous track with FX")
                             : "No FX on other tracks");
        return;
    }
    const GUID* guid = GetTrackGUID(target);
    if (!guid) { speech_("Track switch failed"); return; }

    // Keep the previous navigator state intact until a usable target FX is found.
    // Session memory is global to this navigator and keyed by project/track GUID.
    rememberPosition();
    flushPersistentPosition();
    auto* previousTrack = track_;
    auto* previousTake = take_;
    const GUID previousGuid = trackGuid_;
    const GUID previousFxGuid = fxGuid_;
    const auto previousEntries = entries_;
    const int previousBrowser = browserIndex_, previousFx = fx_, previousParameter = parameter_;
    const int previousCount = count_, previousColumns = columns_, previousStep = stepScale_;
    const auto previousParameterName = parameterName_;
    const auto previousOrder = fxOrder_;
    const auto previousVisible = visible_;
    const auto previousSelection = f7Selected_;
    const int previousViewPos = viewPos_, previousGroup = groupSlot_;
    const bool previousEditF7 = editF7_;
    const bool previousValueMode = valueMode_, previousHadUi = hadUi_, previousSearchMode = searchMode_;
    const auto previousSearch = search_;
    track_ = target; take_ = nullptr; trackGuid_ = *guid;
    // The old FX must not be saved with the new track identity.
    count_ = 0; browserIndex_ = -1;
    bool changed = false;
    if (rebuildEntries()) {
        int preferred = 0;
        if (const auto* state = contextMemory(); state && state->hasLastFx) {
            const int remembered = rememberedFxIndex(*state);
            if (remembered >= 0) preferred = remembered;
        }
        if (selectFx(preferred)) changed = true;
        if (!changed) for (int i = 0; i < static_cast<int>(entries_.size()); ++i) {
            if (i != preferred && selectFx(i)) { changed = true; break; }
        }
    }
    if (!changed) {
        track_ = previousTrack; take_ = previousTake; trackGuid_ = previousGuid;
        fxGuid_ = previousFxGuid; entries_ = previousEntries;
        browserIndex_ = previousBrowser; fx_ = previousFx; parameter_ = previousParameter;
        count_ = previousCount; columns_ = previousColumns; stepScale_ = previousStep;
        parameterName_ = previousParameterName;
        fxOrder_ = previousOrder; visible_ = previousVisible;
        f7Selected_ = previousSelection; viewPos_ = previousViewPos;
        groupSlot_ = previousGroup; editF7_ = previousEditF7;
        valueMode_ = previousValueMode; hadUi_ = previousHadUi;
        searchMode_ = previousSearchMode; search_ = previousSearch;
        speech_("Track switch failed"); return;
    }
    // Mirror the Lua: select the actual REAPER track only after successful switch.
    SetOnlyTrackSelected(target);
    UpdateArrange();
    browserCursor_ = browserIndex_;
    browserScopeMonitor_ = !take_ && track_ == GetMasterTrack(project_) && (fx_ & 0x1000000);
    if (fxBrowserMode_) speech_(browserSpeech());
    else speech_(fxContextAnnouncement());
}
std::string FxNavigator::contextName() const {
    if (!track_) return "";
    std::string context;
    if (track_ == GetMasterTrack(project_)) context = "Master";
    else {
        char trackName[2048]{};
        if (GetTrackName(track_, trackName, sizeof(trackName)) && trackName[0])
            context = trackName;
        else context = "Track";
    }
    if (take_) context = "Take FX, " + context;
    else if (track_ == GetMasterTrack(project_) && (fx_ & 0x1000000)) context = "Monitor FX";
    return context;
}
std::string FxNavigator::fxDisplayName() const {
    if (browserIndex_ < 0 || browserIndex_ >= static_cast<int>(entries_.size())) return "FX";
    const auto& name=entries_[browserIndex_].name;
    // Keep "Monitor: " in the profile key and session memory for old .fx files;
    // remove it only from speech and the window title.
    const std::string monitorPrefix="Monitor: ";
    std::string visibleName = (fx_ & 0x1000000) && name.rfind(monitorPrefix,0)==0
        ? name.substr(monitorPrefix.size()) : name;
    // REAPER can supply display names ending in a period. Add exactly one
    // sentence separator in FX-switch announcements, not two consecutive dots.
    while (visibleName.size() > 1 &&
           (visibleName.back() == '.' || visibleName.back() == ' ')) visibleName.pop_back();
    return visibleName;
}
bool FxNavigator::isBypassed() const {
    return valid() && !(take_ ? TakeFX_GetEnabled(take_,fx_)
                                 : TrackFX_GetEnabled(track_,fx_));
}
bool FxNavigator::deltaSoloActive() const {
    if (!valid()) return false;
    int delta = -1;
    if (!deltaParameter(track_, take_, fx_, delta)) return false;
    const double value = take_ ? TakeFX_GetParamNormalized(take_, fx_, delta)
                               : TrackFX_GetParamNormalized(track_, fx_, delta);
    return value > 0.5;
}
std::string FxNavigator::statusSummary() const {
    // A disabled state is deliberately omitted: no "Enabled" or "Delta off".
    const bool bypassed = isBypassed();
    const bool delta = deltaSoloActive();
    if (bypassed && delta) return "Bypassed - Delta Solo";
    if (bypassed) return "Bypassed";
    if (delta) return "Delta Solo";
    return {};
}
std::string FxNavigator::fxContextAnnouncement() const {
    // After changing FX, speak context, active states, plugin, parameter/value.
    std::string message = contextName() + ". ";
    if (isBypassed()) message += "Bypassed. ";
    if (deltaSoloActive()) message += "Delta Solo. ";
    return message + fxDisplayName() + ". " + currentParameterSpeech();
}
std::string FxNavigator::fxWindowTitleBase(bool memories) const {
    const std::string name = memories ? "FX Memories" : "FX Params";
    const std::string status = statusSummary();
    // Keep legacy title layout in the normal state, but precede context and FX
    // with active states (matching the exact requested Bypassed/Delta order).
    return name + (status.empty() ? " - " : ". " + status + ". ") +
           contextName() + " - " + fxDisplayName();
}
void FxNavigator::toggleBypass() {
    if (!valid()) return;
    const bool enabled = !isBypassed();
    if (take_) TakeFX_SetEnabled(take_,fx_,!enabled);
    else TrackFX_SetEnabled(track_,fx_,!enabled);
    speech_(enabled ? "Bypassed" : "Enabled");
}
// Only use the host's special *last* wrapper parameter when its label proves
// it is Delta. Never mistake a plugin's ordinary parameter for a wrapper.
bool FxNavigator::deltaParameter(MediaTrack* tr,MediaItem_Take* tk,int fx,int& index) const {
    index=-1;
    if (!tr && !tk) return false;
    const int n=tk?TakeFX_GetNumParams(tk,fx):TrackFX_GetNumParams(tr,fx);
    if(n<=0)return false;
    char label[256]{};
    const bool named=tk?TakeFX_GetParamName(tk,fx,n-1,label,sizeof(label)):
                        TrackFX_GetParamName(tr,fx,n-1,label,sizeof(label));
    if(!named)return false;
    std::string name=label;
    std::transform(name.begin(),name.end(),name.begin(),[](unsigned char c){return static_cast<char>(std::tolower(c));});
    if(name!="delta" && name!="delta solo")return false;
    index=n-1;return true;
}
void FxNavigator::toggleDeltaSolo() {
    // In the browser operate on its highlighted FX, NOT the last FX whose
    // parameter grid was opened. Do not call selectFx(): it changes profiles.
    if (!valid() || (fxBrowserMode_ && entries_.empty())) return;
    const int targetIndex = fxBrowserMode_ ? browserVisibleIndex() : browserIndex_;
    if (targetIndex < 0 || targetIndex >= static_cast<int>(entries_.size()) ||
        (fxBrowserMode_ && !browserEntryInScope(targetIndex))) return;
    const int target = fxBrowserMode_ ? entries_[static_cast<size_t>(targetIndex)].index : fx_;
    int delta=-1;
    if(!deltaParameter(track_,take_,target,delta)) {
        speech_("Delta Solo unavailable for this FX");return;
    }
    const double old=take_?TakeFX_GetParamNormalized(take_,target,delta):TrackFX_GetParamNormalized(track_,target,delta);
    const double next=old>0.5?0.0:1.0;
    const bool ok=take_?TakeFX_SetParamNormalized(take_,target,delta,next):TrackFX_SetParamNormalized(track_,target,delta,next);
    if(!ok){speech_("Delta Solo not changed");return;}
    if(take_)TakeFX_EndParamEdit(take_,target,delta);else TrackFX_EndParamEdit(track_,target,delta);
    speech_(std::string(next>0.5?"Delta Solo on":"Delta Solo off") +
            (fxBrowserMode_?". "+browserSpeech():""));
}
void FxNavigator::clearProjectDeltaSolo() {
    if(!project_)return;
    // Prefer the host command: it covers containers and all FX scopes.
    int clearAction=0;
    KbdSectionInfo* main=SectionFromUniqueID(0);
    if(main && kbd_enumerateActions) for(int i=0;i<25000;++i) {
        const char* name=nullptr;
        int id=kbd_enumerateActions(main,i,&name);
        if(id<=0)break;
        if(name && std::strstr(name,"Clear delta solo for all project FX")) {clearAction=id;break;}
    }
    // Count host wrapper Delta toggles where this version of REAPER exposes
    // them. This allows a truthful brief no-op announcement.
    int active=0,known=0;
    auto inspect=[&](MediaTrack* tr,MediaItem_Take* tk,int fx) {
        int id=-1;
        if(!deltaParameter(tr,tk,fx,id))return;
        ++known;
        if((tk?TakeFX_GetParamNormalized(tk,fx,id):TrackFX_GetParamNormalized(tr,fx,id))>0.5)++active;
    };
    auto scanTrack=[&](MediaTrack* tr) {
        if(!tr)return;
        for(int fx=0;fx<TrackFX_GetCount(tr);++fx)inspect(tr,nullptr,fx);
        for(int fx=0;fx<TrackFX_GetRecCount(tr);++fx)inspect(tr,nullptr,0x1000000+fx);
        for(int itemIndex=0;itemIndex<GetTrackNumMediaItems(tr);++itemIndex) {
            MediaItem* item=GetTrackMediaItem(tr,itemIndex);
            if(!item)continue;
            for(int ti=0;ti<CountTakes(item);++ti) {
                MediaItem_Take* tk=GetTake(item,ti);
                if(tk)for(int fx=0;fx<TakeFX_GetCount(tk);++fx)inspect(tr,tk,fx);
            }
        }
    };
    scanTrack(GetMasterTrack(project_));
    for(int i=0;i<CountTracks(project_);++i)scanTrack(GetTrack(project_,i));
    if(clearAction) {
        // REAPER's native action clears *project* FX, including FX containers,
        // but Monitoring FX are not saved in the project. They belong to the
        // master's separate input/monitoring FX chain (0x1000000 + slot).
        // Keep the native action for its full project scope; then explicitly
        // clear any monitoring Delta wrappers still active after that action.
        Main_OnCommand(clearAction,0);
        int remainingMonitorDelta = 0;
        MediaTrack* master = GetMasterTrack(project_);
        if(master) for(int i=0;i<TrackFX_GetRecCount(master);++i) {
            const int monitorFx = 0x1000000 + i;
            int delta=-1;
            if(!deltaParameter(master,nullptr,monitorFx,delta)) continue;
            if(TrackFX_GetParamNormalized(master,monitorFx,delta)<=0.5) continue;
            // Do not rely only on the API's bool: some wrappers apply the
            // write yet report false. Confirm the *actual* Delta state.
            TrackFX_SetParamNormalized(master,monitorFx,delta,0.0);
            if(TrackFX_GetParamNormalized(master,monitorFx,delta)<=0.5)
                TrackFX_EndParamEdit(master,monitorFx,delta);
            else ++remainingMonitorDelta;
        }
        if(remainingMonitorDelta>0) {
            speech_("Delta Solo not cleared");
            return;
        }
        speech_(known>0 && active==0 ? "No Delta Solo" : "Delta Solo cleared");
        return;
    }
    if(known>0 && active==0) {speech_("No Delta Solo");return;}
    // Local wrapper fallback if the native action is absent or translated.
    int cleared=0;
    auto clearOne=[&](MediaTrack* tr,MediaItem_Take* tk,int fx) {
        int id=-1;if(!deltaParameter(tr,tk,fx,id))return;
        const double old=tk?TakeFX_GetParamNormalized(tk,fx,id):TrackFX_GetParamNormalized(tr,fx,id);
        if(old<=0.5)return;
        const bool ok=tk?TakeFX_SetParamNormalized(tk,fx,id,0):TrackFX_SetParamNormalized(tr,fx,id,0);
        if(ok){++cleared;if(tk)TakeFX_EndParamEdit(tk,fx,id);else TrackFX_EndParamEdit(tr,fx,id);}
    };
    auto clearTrack=[&](MediaTrack* tr) {
        if(!tr)return;
        for(int i=0;i<TrackFX_GetCount(tr);++i)clearOne(tr,nullptr,i);
        for(int i=0;i<TrackFX_GetRecCount(tr);++i)clearOne(tr,nullptr,0x1000000+i);
        for(int i=0;i<GetTrackNumMediaItems(tr);++i) {
            MediaItem* item=GetTrackMediaItem(tr,i);if(!item)continue;
            for(int j=0;j<CountTakes(item);++j){MediaItem_Take* tk=GetTake(item,j);
                if(tk)for(int k=0;k<TakeFX_GetCount(tk);++k)clearOne(tr,tk,k);}
        }
    };
    clearTrack(GetMasterTrack(project_));
    for(int i=0;i<CountTracks(project_);++i)clearTrack(GetTrack(project_,i));
    speech_(cleared?"Delta Solo cleared":"No Delta Solo found");
}
void FxNavigator::runLuaFunctionAction(int command) {
    if(Main_OnCommand) Main_OnCommand(command,0);
}
void FxNavigator::setNativeText(const std::string& content) {
    if(numericEdit_) {numericBuffer_=content;return;}
    if(textEdit_) {textBuffer_=content;return;}
    if(searchMode_)search_=content;
}
void FxNavigator::snapshotDefaultsIfMissing() {
    if(fxOrder_.hasDefaultValues()||!valid()||count_<=0)return;
    // A REAPER ReaEQ has dynamic bands and virtual controls. Its Lua
    // default uses a structural VST chunk. Do not create an unsafe index
    // snapshot pretending to restore the whole state.
    const auto& name=entries_[static_cast<size_t>(browserIndex_)].name;
    if(name.find("ReaEQ")!=std::string::npos || name.find("reaeq")!=std::string::npos){captureReaEqDefault();return;}
    std::map<int,double> values;
    for(int i=0;i<count_;++i) {
        double v=take_?TakeFX_GetParamNormalized(take_,fx_,i):TrackFX_GetParamNormalized(track_,fx_,i);
        if(std::isfinite(v) && v>=0 && v<=1)values[i]=v;
    }
    if(!values.empty()) {
        // A read-only profile directory must not prevent FX navigation.
        // The default is unavailable until a writable profile is present.
        try {fxOrder_.saveDefaultValues(values);}
        catch(const std::exception&) {
            OutputDebugStringW(L"LReaParams: cannot initialize FX default snapshot; continuing navigation.\n");
        }
    }
}
void FxNavigator::resetCurrentToDefault() {
    if(!valid())return;
    if(parameter_==compareParamIndex){auto& state=compareState();state.armed=false;state.original={};state.edited={};speech_("Compare, Not armed");return;}
    if(fxOrder_.hasStructuralDefault() && eqVirtualValid(parameter_)) {
        if(parameter_==reaeq::action || parameter_==reaeq::target){speech_("No default for this action");return;}
        try {
            const ReaEqChunk saved(fxOrder_.defaultMeta("REA_EQ_VST_CHUNK"));
            if(saved.bands()!=eqBandCount()){speech_("Band structure changed. Use full Default reset");return;}
            const int band=reaeq::band(parameter_);
            const double target=reaeq::enabledId(parameter_)?saved.enabled(band):
                reaeq::userFromRaw(saved.rawType(band))/10.0;
            if(eqVirtualSet(parameter_,target))speech_("Reset. "+currentParameterSpeech());
            return;
        }catch(...) {speech_("Structural default invalid. No changes");return;}
    }
    if(fxOrder_.hasStructuralDefault()) {
        if(!isReaEq()){speech_("Structural default unavailable");return;}
        try {
            ReaEqChunk saved(fxOrder_.defaultMeta("REA_EQ_VST_CHUNK")), current(namedConfig("vst_chunk"));
            if(saved.bands()!=current.bands()){speech_("Band structure changed. Use full Default reset");return;}
            if(parameter_>=0 && parameter_<saved.bands()*3) {
                current.value(parameter_/3,parameter_%3,saved.value(parameter_/3,parameter_%3));
                Undo_BeginBlock2(project_);
                const bool ok=writeNamedConfig("vst_chunk",current.text());
                Undo_EndBlock2(project_,"LReaParams: ReaEQ parameter default",take_?UNDO_STATE_ITEMS:UNDO_STATE_FX);
                if(ok)speech_("Reset. "+currentParameterSpeech());else speech_("Reset unavailable");return;
            }
            const int tail=parameter_-(count_-3)+1;
            if(tail>=1&&tail<=3) {
                const auto text=fxOrder_.defaultMeta("REA_EQ_WRAPPER_TAIL_"+std::to_string(tail)+"_NORM");
                if(!text.empty())setValue(std::stod(text));else speech_("No wrapper default");return;
            }
        }catch(const std::exception&) {speech_("Structural default invalid. No changes");return;}
        speech_("No default for this parameter");return;
    }
    auto defaults=fxOrder_.defaultValues();
    // Legacy names may change with a synthesizer preset. Only use ordinal
    // recovery when every physical parameter has been validated together.
    if(defaults.size()!=static_cast<size_t>(count_))defaults=fxOrder_.defaultValuesByIndex();
    const auto it=defaults.find(parameter_);
    if(it==defaults.end()) {speech_("No default for this parameter");return;}
    Undo_BeginBlock2(project_);
    const bool ok=take_?TakeFX_SetParamNormalized(take_,fx_,parameter_,it->second):
                       TrackFX_SetParamNormalized(track_,fx_,parameter_,it->second);
    Undo_EndBlock2(project_,"LReaParams: parameter default",take_?UNDO_STATE_ITEMS:UNDO_STATE_FX);
    if(!ok){speech_("Reset unavailable");return;}
    if(take_)TakeFX_EndParamEdit(take_,fx_,parameter_);else TrackFX_EndParamEdit(track_,fx_,parameter_);
    speech_("Reset. "+currentParameterSpeech());
}
bool FxNavigator::resetAllToDefault(bool announceResult) {
    if(!valid())return false;
    if(fxOrder_.hasStructuralDefault()) {
        const bool ok=restoreReaEqDefault();
        if(ok) {auto& compare=compareState();compare.armed=false;if(announceResult)speech_("Default restored. "+currentParameterSpeech());}
        return ok;
    }
    auto values=fxOrder_.defaultValues();
    const int liveCount=take_?TakeFX_GetNumParams(take_,fx_):TrackFX_GetNumParams(track_,fx_);
    if(!fxOrder_.hasDefaultValues()){speech_("No default snapshot");return false;}
    // A plugin can expose preset-dependent parameter *labels*. The saved
    // .fx is already tied to the plugin identity: on a complete, unchanged
    // physical layout, recover the values using the native parameter IDs.
    // Never accept a partial, duplicate, reordered or changed-count layout.
    if(liveCount!=count_ || fxOrder_.defaultValueCount()!=count_) {
        speech_("Default parameter count changed. No changes");return false;
    }
    if(static_cast<int>(values.size())!=count_)values=fxOrder_.defaultValuesByIndex();
    if(static_cast<int>(values.size())!=count_) {
        speech_("Default parameter identities changed. No changes");return false;
    }
    std::vector<double> previous(static_cast<size_t>(count_));
    for(int i=0;i<count_;++i) {
        const auto it=values.find(i);
        if(it==values.end() || !std::isfinite(it->second) || it->second<0 || it->second>1) {
            speech_("Default parameter identities changed. No changes");return false;
        }
        const double value=take_?TakeFX_GetParamNormalized(take_,fx_,i):TrackFX_GetParamNormalized(track_,fx_,i);
        if(!std::isfinite(value)||value<0||value>1){speech_("Default read failed. No changes");return false;}
        previous[static_cast<size_t>(i)]=value;
    }
    Undo_BeginBlock2(project_);
    int restored=0;
    for(int i=0;i<count_;++i) {
        const double value=values.at(i);
        const bool ok=take_?TakeFX_SetParamNormalized(take_,fx_,i,value):TrackFX_SetParamNormalized(track_,fx_,i,value);
        if(!ok)break;
        ++restored;
        if(take_)TakeFX_EndParamEdit(take_,fx_,i);else TrackFX_EndParamEdit(track_,fx_,i);
    }
    if(restored!=count_) {
        // Best-effort rollback and an Undo step as second line of defense.
        // Include the parameter whose setter may have written and still
        // reported failure (as observed with some REAPER band properties).
        for(int i=std::min(restored,count_-1);i>=0;--i) {
            if(take_) {TakeFX_SetParamNormalized(take_,fx_,i,previous[static_cast<size_t>(i)]);TakeFX_EndParamEdit(take_,fx_,i);}
            else {TrackFX_SetParamNormalized(track_,fx_,i,previous[static_cast<size_t>(i)]);TrackFX_EndParamEdit(track_,fx_,i);}
        }
    }
    Undo_EndBlock2(project_,"LReaParams: restore FX defaults",take_?UNDO_STATE_ITEMS:UNDO_STATE_FX);
    if(restored!=count_){speech_("Default restore incomplete. Use REAPER Undo");return false;}
    auto& compare=compareState();compare.armed=false;pickup_.clear();
    if(announceResult)speech_("Reset "+std::to_string(restored)+" parameters. "+currentParameterSpeech());
    return true;
}
void FxNavigator::resetGridAndStep() {
    columns_=10;stepScale_=0;markParameterStepChanged();speech_("Grid 10. Step 0");
    rememberPosition();
}
void FxNavigator::chooseSlotAccess(int mode) {
    slotMode_ = mode;
    fxOrder_.groupSlotMode = slotMode_==0;
    saveStructure();
    speech_(slotMode_==0?"Groups":"Memory positions");
}
bool FxNavigator::selectFx(int index) {
    // Commit the previous FX position before FxOrder::load rebinds the profile.
    if (active_ && count_ > 0 && browserIndex_ != index) {
        rememberPosition();
        flushParameterSteps();
        flushPersistentPosition();
    }
    if (index < 0 || index >= static_cast<int>(entries_.size())) return false;
    const auto& candidate = entries_[index];
    const GUID* guid = take_ ? TakeFX_GetFXGUID(take_, candidate.index) : TrackFX_GetFXGUID(track_, candidate.index);
    if (!same(guid, candidate.guid)) { speech_("FX list changed. Reopen FX Params"); end(); return false; }
    const int num = take_ ? TakeFX_GetNumParams(take_, candidate.index) : TrackFX_GetNumParams(track_, candidate.index);
    if (num <= 0) return false;
    fx_ = candidate.index; fxGuid_ = candidate.guid;
    browserIndex_ = index; // ReaEQ virtual validation needs the NEW FX identity.
    eqTargetBand_ = 0; eqActionMidiHigh_ = false;
    count_ = num;
    restoreParameterPosition();
    parameterName_ = parameterName();
    hadUi_ = take_ ? TakeFX_GetOpen(take_, fx_) : TrackFX_GetOpen(track_, fx_);
    loadFxOrder();
    restorePersistedParameter();
    parameterName_ = parameterName();
    initializeCompare(); // Capture only; never apply Original when entering an FX.
    resetMidiContext();
    valueMode_ = false; searchMode_ = false; search_.clear();
    rememberPosition();
    return true;
}
int FxNavigator::count() const { return take_ ? TakeFX_GetNumParams(take_, fx_) : TrackFX_GetNumParams(track_, fx_); }
std::string FxNavigator::parameterName() const {
    if(parameter_==compareParamIndex)return "Compare";
    if(eqVirtualValid(parameter_))return eqVirtualName(parameter_);
    if(dynamicsVirtualValid(parameter_))return dynamicsVirtualName(parameter_);
    char name[4096]{};
    bool ok = take_ ? TakeFX_GetParamName(take_, fx_, parameter_, name, sizeof(name)) : TrackFX_GetParamName(track_, fx_, parameter_, name, sizeof(name));
    if(!ok)return {};
    const auto alias=dynamicsAlias(parameter_);return alias.empty()?std::string(name):alias;
}
bool FxNavigator::valid() const {
    if (!active_ || EnumProjects(-1, nullptr, 0) != project_ || !ValidatePtr2(project_, track_, "MediaTrack*")) return false;
    if (!same(GetTrackGUID(track_), trackGuid_)) return false;
    if (take_ && (!ValidatePtr2(project_, take_, "MediaItem_Take*") || GetMediaItemTake_Track(take_) != track_)) return false;
    const auto* g = take_ ? TakeFX_GetFXGUID(take_, fx_) : TrackFX_GetFXGUID(track_, fx_);
    if (!same(g, fxGuid_)) return false;
    // An offline FX can expose zero parameters. Keep its browser keyboard
    // owner alive; GUID/context validation still prevents stale FX access.
    if (fxBrowserMode_) return true;
    if (count() != count_ || (parameter_ < 0 && parameter_!=compareParamIndex && !eqVirtualValid(parameter_) && !dynamicsVirtualValid(parameter_)) || parameter_ >= count_) return false;
    // Action labels depend on Target Band. They may change without the FX
    // identity or the navigator's selected parameter changing.
    return eqVirtualValid(parameter_) || dynamicsVirtualValid(parameter_) || parameterName() == parameterName_;
}
bool FxNavigator::contextUnchanged() const {
    if (!valid()) return false;
    // Compare FX identities, never the last-touched FX. The browser may choose
    // any plugin even while REAPER still reports a different focused plugin.
    const int currentNormal = take_ ? TakeFX_GetCount(take_) : TrackFX_GetCount(track_);
    const int currentMonitor = !take_ && track_ == GetMasterTrack(project_) ? TrackFX_GetRecCount(track_) : 0;
    if (currentNormal + currentMonitor != static_cast<int>(entries_.size())) return false;
    for (const auto& entry : entries_) {
        const GUID* guid = take_ ? TakeFX_GetFXGUID(take_, entry.index) : TrackFX_GetFXGUID(track_, entry.index);
        if (!same(guid, entry.guid)) return false;
    }
    return true;
}
HWND FxNavigator::floatingWindow() const {
    return valid() ? (take_ ? TakeFX_GetFloatingWindow(take_, fx_) : TrackFX_GetFloatingWindow(track_, fx_)) : nullptr;
}
bool FxNavigator::uiStillOpen() const {
    if (!valid()) return false;
    // The native plugin window may close when the FX goes offline; the internal
    // browser intentionally remains open so Ctrl+Alt+B can bring it online.
    if (fxBrowserMode_) return true;
    return !hadUi_ || (take_ ? TakeFX_GetOpen(take_, fx_) : TrackFX_GetOpen(track_, fx_));
}
bool FxNavigator::accepts(const Key& k) const noexcept {
    if (clearAutomationConfirm_) return true;
    if (!active_) return false;
    if (!textEdit_ && !searchMode_ && !numericEdit_ && !recentMode_ &&
        !defaultConfirm_ && isTransportMarkerShortcut(k)) return true;
    // The Lua transport gestures belong to FX Params in Grid, Value, F7 and Memories.
    // Native search/rename/numeric EDIT controls must retain their space key.
    if (fxBrowserMode_) {
        if (k.vk==VK_SPACE && !k.shift && !k.alt) return true; // transport
        if (k.altGr && k.character) return true;
        if (k.ctrl && k.alt && !k.shift && !k.altGr && k.vk=='B') return true; // Lua offline
        if (k.ctrl && !k.alt && !k.shift &&
            (k.vk==VK_PRIOR||k.vk==VK_NEXT||k.vk=='P'||k.vk=='B'||k.vk=='D'||k.vk=='W'||
             k.vk==VK_LEFT||k.vk==VK_RIGHT||k.vk==VK_UP||k.vk==VK_DOWN||
             k.vk==VK_HOME||k.vk==VK_END)) return true;
        if (k.ctrl && k.shift && !k.alt &&
            (k.vk=='D'||k.vk=='F'||k.vk==VK_UP||k.vk==VK_DOWN)) return true;
        if (k.alt && k.shift && !k.ctrl && k.vk=='F') return true;
        if (k.ctrl || k.alt) return false;
        if (k.character) return true;
        return k.vk==VK_ESCAPE||k.vk==VK_RETURN||k.vk==VK_TAB||
               k.vk==VK_UP||k.vk==VK_DOWN||k.vk==VK_LEFT||k.vk==VK_RIGHT||
               k.vk==VK_HOME||k.vk==VK_END||k.vk==VK_PRIOR||k.vk==VK_NEXT;
    }
    // Lua Ctrl+P opens a dedicated FX browser, leaving the parameter selection intact.
    if (k.ctrl && !k.alt && !k.shift && k.vk=='P') return true;
    // Lua context-navigation gestures also work from the parameter grid.
    if (k.ctrl && !k.alt && !k.shift &&
        (k.vk=='W'||k.vk==VK_LEFT||k.vk==VK_RIGHT)) return true;
    if (k.ctrl && k.shift && !k.alt && k.vk=='F') return true; // native FX chain
    if (k.alt && k.shift && !k.ctrl && k.vk=='F') return true; // native FX browser
    if (k.vk == VK_SPACE && !k.shift && !k.alt &&
        !textEdit_ && !searchMode_ && !numericEdit_) return true;
    if (memoryManager_) {
        if (k.ctrl && k.shift && !k.alt && !k.altGr && k.vk == 'M') return true;
        if(defaultConfirm_)return !k.ctrl&&!k.alt&&!k.shift&&(k.vk=='Y'||k.vk=='N'||k.vk==VK_ESCAPE||k.vk==VK_RETURN||k.vk==VK_LEFT||k.vk==VK_RIGHT||k.vk==VK_UP||k.vk==VK_DOWN);
        if(k.vk==VK_F12)return false;
        if(k.ctrl)return !k.alt && !k.shift && (k.vk==VK_HOME||k.vk==VK_END);
        if(k.shift)return false;
        if(k.alt)return k.vk==VK_LEFT||k.vk==VK_RIGHT;
        return k.vk==VK_ESCAPE||k.vk==VK_F7||
               k.vk==VK_TAB||k.vk==VK_RETURN||k.vk==VK_DELETE||
               k.vk==VK_UP||k.vk==VK_DOWN||k.vk==VK_LEFT||k.vk==VK_RIGHT||
               k.vk==VK_HOME||k.vk==VK_END||k.vk==VK_PRIOR||k.vk==VK_NEXT;
    }
    if(recentMode_)return !k.alt && (k.vk==VK_ESCAPE||k.vk==VK_RETURN||k.vk==VK_TAB||k.vk==VK_DELETE||k.vk==VK_UP||k.vk==VK_DOWN||k.vk==VK_LEFT||k.vk==VK_RIGHT||k.vk==VK_HOME||k.vk==VK_END||k.vk==VK_PRIOR||k.vk==VK_NEXT||(k.ctrl&&k.vk=='R'));
    if (numericEdit_) return k.vk==VK_ESCAPE || k.vk==VK_RETURN || (k.ctrl && k.vk=='E');
    if (textEdit_) return true;
    // Context switch is owned by Extension; do not intercept inside text editing.
    if (k.ctrl && !k.shift && !k.alt && k.vk == VK_TAB &&
        !memoryManager_ && !textEdit_ && !searchMode_ && !numericEdit_ &&
        !recentMode_ && !fxBrowserMode_) return true;
    // Ctrl+Q parks MIDI while releasing the native window, input hook and
    // REAPER keyboard focus. Extension owns the transition, not the navigator.
    if (k.ctrl && !k.shift && !k.alt && k.vk == 'Q') return true;
    if (k.ctrl && k.alt && !k.shift && !k.altGr && k.vk == 'B') return true; // offline
    // Windows clipboard: plain Ctrl+C/V outside F7, full FX Ctrl+Alt+Shift+C.
    if (k.ctrl && k.alt && k.shift && !k.altGr && k.vk=='C') return true;
    if (k.ctrl && !k.alt && !k.shift && (k.vk=='C'||k.vk=='V') && !editF7_) return true;
    if (acceptsAdvanced(k) && !searchMode_) return true;
    if (searchMode_ && k.ctrl && (k.vk==VK_UP || k.vk==VK_DOWN))return true;
    if (searchMode_) return k.vk==VK_ESCAPE||k.vk==VK_RETURN||k.vk==VK_BACK||
        k.vk==VK_UP||k.vk==VK_DOWN||k.vk==VK_SPACE||
        (k.vk>='A'&&k.vk<='Z')||(k.vk>='0'&&k.vk<='9')||
        (k.ctrl&&k.vk=='F');
    if ((k.vk==VK_F10||k.vk==VK_F11||k.vk==VK_F12) && k.alt) return false; // OSARA peak watchers
    if (k.vk == VK_F12 && !k.ctrl) return false; // bare F12 is reserved for future LReaParams commands
    if (!k.ctrl && !k.alt && !k.shift && (k.vk==VK_F10)) return false; // unassigned
    if (k.ctrl && !k.alt && k.vk == 'L') return true;
    if (k.vk==VK_BACK && !k.alt) return true;
    if (!k.ctrl && k.alt && !k.shift && (k.vk == 'G' || k.vk == 'M')) return true;
    if (k.ctrl && !k.alt && ((k.vk=='B' && !k.shift)||k.vk=='D')) return true;
    if (!k.ctrl && !k.alt && !k.shift && (k.vk==VK_F3 || k.vk==VK_F5 || k.vk==VK_F6 || k.vk==VK_F9)) return true;
    // F8 is the standalone A/B command, independent of F7 and FX Memories.
    if (k.vk == VK_F8 && !k.ctrl && !k.alt && !k.shift && !k.altGr &&
        !textEdit_ && !numericEdit_ && !searchMode_ && !recentMode_ && !fxBrowserMode_ && !memoryManager_) return true;
    if (k.vk == VK_F7 && !k.ctrl && !k.alt && !k.shift) return true;
    if (k.ctrl && k.shift && !k.alt && !k.altGr && k.vk == 'M' &&
        !textEdit_ && !numericEdit_ && !searchMode_ && !recentMode_ && !fxBrowserMode_) return true;
    if (k.ctrl && !k.alt && k.vk >= VK_F1 && k.vk <= VK_F12) return true;
    // Italian/European keyboard punctuation can require AltGr (Right Alt).
    // Distinguish it from real Ctrl+Alt shortcuts using the physical Right Alt.
    if (k.altGr && k.character) return true;
    if (editF7_) {
        if (k.ctrl && !k.alt && (k.vk=='A'||k.vk=='C'||k.vk=='X'||k.vk=='V'||k.vk=='Z'||k.vk=='Y'||k.vk==VK_DELETE||k.vk==VK_RETURN))return true;
        if (!k.ctrl && k.alt && k.shift) return k.vk==VK_UP||k.vk==VK_DOWN||k.vk==VK_LEFT||k.vk==VK_RIGHT;
        if (k.shift && !k.alt && !k.ctrl) return k.character || k.vk==VK_SPACE||k.vk==VK_UP||k.vk==VK_DOWN||k.vk==VK_LEFT||k.vk==VK_RIGHT||k.vk==VK_HOME||k.vk==VK_END||k.vk==VK_PRIOR||k.vk==VK_NEXT;
        if (k.ctrl && k.shift && !k.alt) return k.vk==VK_HOME||k.vk==VK_END||k.vk==VK_DELETE;
        if (!k.alt && !k.ctrl && !k.shift && (k.vk==VK_DELETE||k.vk==VK_TAB))return true;
    }
    if (k.ctrl && k.shift && !k.alt) return k.vk == VK_UP || k.vk == VK_DOWN;
    // Lua list_cycle_by_initial: printable letters, digits and punctuation
    // are navigation keys in the parameter grid, also in the F7 editor.
    // Do not treat them as search input inside Value, FX Memories or EDIT.
    if (!k.ctrl && !k.alt && k.character) return true;
    if (k.shift) return false;
    if (k.ctrl) {
        if (k.alt) return false;
        return k.vk == VK_HOME || k.vk == VK_END || VK_RETURN == k.vk ||
               k.vk == VK_UP || k.vk == VK_DOWN ||
               (!editF7_ && (k.vk == VK_PRIOR || k.vk == VK_NEXT)) ||
               k.vk == 'F' || k.vk == 'R';
    }
    return k.vk == VK_ESCAPE || k.vk == VK_RETURN || k.vk == VK_F1 || k.vk == VK_F2 ||
           k.vk == VK_HOME || k.vk == VK_END || k.vk == VK_TAB ||
           k.vk == VK_UP || k.vk == VK_DOWN || k.vk == VK_LEFT || k.vk == VK_RIGHT ||
           k.vk == VK_PRIOR || k.vk == VK_NEXT;
}
std::string FxNavigator::formattedValue() const {
    if (!valid()) throw std::runtime_error("FX context changed");
    if(parameter_==compareParamIndex)return compareFormatted();
    if(eqVirtualValid(parameter_))return eqVirtualFormatted(parameter_);
    if(dynamicsVirtualValid(parameter_))return dynamicsVirtualFormatted(parameter_);
    char text[4096]{};
    const bool ok = take_ ? TakeFX_GetFormattedParamValue(take_, fx_, parameter_, text, sizeof(text))
                          : TrackFX_GetFormattedParamValue(track_, fx_, parameter_, text, sizeof(text));
    const double v = take_ ? TakeFX_GetParamNormalized(take_, fx_, parameter_)
                           : TrackFX_GetParamNormalized(track_, fx_, parameter_);
    return dynamicsRealFormatted(parameter_,ok && text[0] ? std::string(text) : std::to_string(v));
}
std::string FxNavigator::currentParameterSpeech() const {
    // Read-only status suffixes used by the Grid, F7, Value and NVDA+Up.
    // The CC association belongs to the parameter, not to its occurrence in
    // the Custom Order or to whether Fixed CC is currently enabled.
    // In this version, CC must precede Auto when both are present.
    std::string spoken = displayName() + ", " + formattedValue();
    const std::string ccSpeech = currentParameterCcSpeech();
    if (!ccSpeech.empty()) spoken += ". " + ccSpeech;
    // Never create an envelope merely to announce its status; virtual
    // parameters have no physical FX envelope.
    if (parameter_ >= 0 && parameter_ < count_ && envelopeActive(parameter_))
        spoken += ". Auto";
    return spoken;
}
std::string FxNavigator::editorParameterSpeech() const {
    // Selection is an OCCURRENCE index, not a parameter ID: duplicate entries
    // in a Custom Order must be announced independently, including filters.
    const bool selected=editF7_ && !visible_.empty() &&
        f7Selected_.count(f7OriginalPosition(viewPos_)) != 0;
    return (selected ? "Selected " : "") + currentParameterSpeech();
}
std::string FxNavigator::viewPositionSpeech() const {
    return std::to_string(visible_.empty()?0:viewPos_+1) + " of " + std::to_string(visible_.size());
}
double FxNavigator::valueFraction() const {
    if(parameter_==compareParamIndex){const auto* state=findCompareState();return state&&state->originalActive?0:1;}
    if(eqVirtualValid(parameter_))return eqVirtualFraction(parameter_);
    if(dynamicsVirtualValid(parameter_))return 0;
    if(dynamicsDetectorInput(parameter_))return dynamicsFraction(parameter_);
    if(eqBandParam(parameter_,1))return eqGainNorm(parameter_);
    if (!valid()) return 0;
    return std::clamp(take_ ? TakeFX_GetParamNormalized(take_, fx_, parameter_)
                            : TrackFX_GetParamNormalized(track_, fx_, parameter_), 0.0, 1.0);
}
std::string FxNavigator::sliderLabel() const { return displayName(); }
void FxNavigator::announce() {
    if(!fxBrowserMode_)syncParameterStep();
    if(fxBrowserMode_) {speech_(browserSpeech());return;}
    if(memoryManager_) {speakMemory();return;}
    speech_(editF7_ ? editorParameterSpeech() : currentParameterSpeech());
}
void FxNavigator::announceTitle() {
    if (!active_) return;
    if(!fxBrowserMode_)syncParameterStep();
    if(fxBrowserMode_){speech_("FX Browser. "+browserSpeech());return;}
    if(memoryManager_){speakMemory("FX Memories");return;}
    speech_(fxWindowTitleBase() + ". " + currentParameterSpeech());
}
namespace {
std::wstring wideUtf8(const std::string& str) {
    if (str.empty()) return {};
    const int size = MultiByteToWideChar(CP_UTF8, 0, str.c_str(), -1, nullptr, 0);
    if (size <= 0) return L"";
    std::wstring out(static_cast<size_t>(size), L'\0');
    if (!MultiByteToWideChar(CP_UTF8, 0, str.c_str(), -1, out.data(), size)) return L"";
    out.resize(static_cast<size_t>(size - 1));
    return out;
}
}
std::wstring FxNavigator::windowTitle() const {
    if (!active_) return L"FX Params";
    if (fxBrowserMode_) {
        std::string browserContext = contextName();
        if (track_ == GetMasterTrack(project_) && !entries_.empty())
            browserContext = browserScopeMonitor_ ? "Monitor FX" : "Master";
        return wideUtf8("FX Browser - " + browserContext);
    }
    if (memoryManager_) return wideUtf8(fxWindowTitleBase(true));
    // Keep Grid out of the title; position Bypassed/Delta BEFORE context/FX.
    return wideUtf8(fxWindowTitleBase()) +
           (textEdit_ ? L" - Rename" : searchMode_ ? L" - Find Parameter" : valueMode_ ? L" - Value" :
            editF7_ ? L" - F7 Edit" : L"");
}
std::string FxNavigator::reviewLine() const {
    // NVDA+Up reads the active confirmation rather than the stale FX parameter.
    if (!active_) return "";
    if (clearAutomationConfirm_)
        return std::string("Disable all automation on current FX? ") +
            (clearAutomationYes_ ? "Yes selected" : "No selected") +
            ". Left and Right select; Enter confirms the selected answer. Y confirms, N or Escape cancels.";
    if (fxBrowserMode_) return browserSpeech();
    if (memoryManager_) return memoryReview();
    if(recentMode_ && historyIndex_>=0 && historyIndex_<static_cast<int>(searchHistory_.size()))return "Recent searches. "+searchHistory_[static_cast<size_t>(historyIndex_)];
    if(numericEdit_)return "Parameter value, "+numericBuffer_;
    if (textEdit_) return "Edit name, " + textBuffer_;
    if (searchMode_) return "Find parameter, " + search_;
    if (editF7_ && !valueMode_)
        return editorParameterSpeech() + ". " + viewPositionSpeech() + ". " +
            std::to_string(f7Selected_.size()) + " selected";
    return valueMode_ ? "Value, " + currentParameterSpeech() : currentParameterSpeech();
}
void FxNavigator::navigate(int delta) {
    if (visible_.empty()) return;
    const int next = std::clamp(viewPos_ + delta, 0, static_cast<int>(visible_.size()) - 1);
    if (next == viewPos_) return;
    positionChanged(next);
}
void FxNavigator::cycleByInitial(wchar_t character) {
    cycleByInitial(character, false);
}
void FxNavigator::cycleByInitial(wchar_t character, bool backwards) {
    if (!character || visible_.empty()) return;
    // Without Shift: next match, wrapping forwards; with Shift: previous
    // match, wrapping backwards. Both use the *displayed* parameter label.
    // Use Windows Unicode case conversion for Italian accents too. No speech
    // or position change if the current grid has no matching initial.
    CharLowerBuffW(&character, 1);
    const int total = static_cast<int>(visible_.size());
    for (int offset = 1; offset <= total; ++offset) {
        const int index = backwards ? (viewPos_ + total - (offset % total)) % total
                                    : (viewPos_ + offset) % total;
        const std::string label = fxOrder_.label(visible_[static_cast<size_t>(index)]);
        if (label.empty()) continue;
        const auto byte0 = static_cast<unsigned char>(label[0]);
        const int utf8Len = byte0 < 0x80 ? 1 : byte0 < 0xc0 ? 0 :
                            byte0 < 0xe0 ? 2 : byte0 < 0xf0 ? 3 : 4;
        if (!utf8Len || label.size() < static_cast<size_t>(utf8Len)) continue;
        wchar_t first[2]{};
        if (MultiByteToWideChar(CP_UTF8, MB_ERR_INVALID_CHARS, label.data(),
                                utf8Len, first, 2) != 1) continue;
        CharLowerBuffW(first, 1);
        if (first[0] == character) {
            // The Lua repeats the current parameter too if it is the only
            // matching initial; announce it rather than leaving NVDA silent.
            if (index == viewPos_) announce();
            else positionChanged(index);
            return;
        }
    }
}
void FxNavigator::setValue(double value) {
    if(parameter_==compareParamIndex){if(setCompare(value))speech_(compareFormatted());return;}
    if(eqVirtualValid(parameter_)){
        if(eqVirtualSet(parameter_,value) && active_)speech_(eqVirtualFormatted(parameter_));
        return;
    }
    if(dynamicsVirtualValid(parameter_))return; // summary is read-only, not a host param
    if(dynamicsDetectorInput(parameter_)) {
        if(!std::isfinite(value))return;
        if(dynamicsSetDetector(value))speech_(dynamicsRealFormatted(parameter_,""));
        else speech_("Detector input unchanged");
        return;
    }
    if(eqBandParam(parameter_,1)) {
        if(!std::isfinite(value))return;value=std::clamp(value,0.0,1.0);
        if(std::abs(value-eqGainNorm(parameter_))<1e-12)return;
        Undo_BeginBlock2(project_);const bool ok=writeEqGain(parameter_,value);
        Undo_EndBlock2(project_,"LReaParams: ReaEQ extended gain",UNDO_STATE_FX);
        if(ok)speech_(formattedValue());else speech_("Gain update failed");return;
    }
    if (!valid()) throw std::runtime_error("FX context changed");
    if (!std::isfinite(value)) return;
    value = std::clamp(value, 0.0, 1.0);
    const double before = take_ ? TakeFX_GetParamNormalized(take_, fx_, parameter_) : TrackFX_GetParamNormalized(track_, fx_, parameter_);
    if (value == before) return;
    struct UndoScope {
        ReaProject* project; int flags;
        explicit UndoScope(ReaProject* p, int f) : project(p), flags(f) { Undo_BeginBlock2(project); }
        ~UndoScope() { Undo_EndBlock2(project, "LReaParams: FX parameter", flags); }
    } undo(project_, take_ ? UNDO_STATE_ITEMS : UNDO_STATE_FX);
    const bool ok = take_ ? TakeFX_SetParamNormalized(take_, fx_, parameter_, value) : TrackFX_SetParamNormalized(track_, fx_, parameter_, value);
    if (take_) TakeFX_EndParamEdit(take_, fx_, parameter_); else TrackFX_EndParamEdit(track_, fx_, parameter_);
    if (!ok) throw std::runtime_error("Host refused parameter value");
    speech_(formattedValue());
}
void FxNavigator::nudge(int direction, bool big) {
    if(eqVirtualValid(parameter_)){eqVirtualNudge(direction,big);return;}
    if(dynamicsVirtualValid(parameter_))return; // no fake setter for filter summary
    if(dynamicsDetectorInput(parameter_)){dynamicsNudgeDetector(direction,big);return;}
    if(parameter_==compareParamIndex) {
        const auto* state=findCompareState();
        if(!state||!state->armed || (direction>0 && state->originalActive) || (direction<0 && !state->originalActive))
            if(setCompare(direction>0?1:0))speech_(compareFormatted());
        return;
    }
    if(eqBandParam(parameter_,1)) {
        double db=-150+186.1*eqGainNorm(parameter_);
        double next=db+(big?10:1)*std::pow(2.0,stepScale_)*direction;
        if(db<=-149.9 && direction>0)next=big?-36:-60;
        setValue((std::clamp(next,-150.0,36.1)+150)/186.1);return;
    }
    double normal = 0, small = 0, large = 0; bool toggle = false;
    const bool known = take_ ? TakeFX_GetParameterStepSizes(take_, fx_, parameter_, &normal, &small, &large, &toggle)
        : TrackFX_GetParameterStepSizes(track_, fx_, parameter_, &normal, &small, &large, &toggle);
    const double old = take_ ? TakeFX_GetParamNormalized(take_, fx_, parameter_) : TrackFX_GetParamNormalized(track_, fx_, parameter_);
    if (known && toggle) { setValue(direction > 0 ? 1 : 0); return; }
    double step = known ? (big ? large : normal) : 0;
    if (!std::isfinite(step) || step <= 0 || step > 1) step = big ? 0.01 : 0.001;
    // Feasibility step control. Full Lua per-plugin/discrete adapters are pending.
    step *= std::pow(2.0, stepScale_);
    setValue(old + direction * step);
}
namespace {
std::string lowerAscii(std::string value) {
    for (char& c : value) c = static_cast<char>(std::tolower(static_cast<unsigned char>(c)));
    return value;
}
bool wordByte(unsigned char c) {
    // Preserve UTF-8 multibyte sequences as word content; ASCII punctuation
    // and whitespace separate words. Comparison remains ASCII-insensitive.
    return std::isalnum(c) || c >= 128;
}
std::vector<std::string> words(const std::string& input) {
    std::vector<std::string> out;
    std::string token;
    for(unsigned char c:input) {
        if(wordByte(c))token.push_back(static_cast<char>(std::tolower(c)));
        else if(!token.empty()) {out.push_back(std::move(token));token.clear();}
    }
    if(!token.empty())out.push_back(std::move(token));
    return out;
}
}
bool FxNavigator::matchesSearch(const std::string& label,const std::string& query) {
    if(query.empty())return false;
    if(query.size()<2 || query.front()!='"' || query.back()!='"')
        return lowerAscii(label).find(lowerAscii(query))!=std::string::npos;
    const auto wanted=words(query.substr(1,query.size()-2));
    const auto available=words(label);
    if(wanted.empty() || wanted.size()>available.size())return false;
    for(size_t start=0;start+wanted.size()<=available.size();++start) {
        bool match=true;
        for(size_t i=0;i<wanted.size();++i) {
            const bool last=i+1==wanted.size();
            // One quoted word means that exact word. In a multiword quoted
            // query the last word can be a prefix ("slot 1 fil").
            if(last && wanted.size()>1) {
                if(available[start+i].compare(0,wanted[i].size(),wanted[i])!=0) {match=false;break;}
            } else if(available[start+i]!=wanted[i]) {match=false;break;}
        }
        if(match)return true;
    }
    return false;
}
void FxNavigator::findMatching(bool forward) {
    if (search_.empty()) { speech_("Search is empty"); return; }
    const int total = static_cast<int>(visible_.size());
    if(total<=0){speech_("No visible parameters");return;}
    for (int offset = 1; offset <= total; ++offset) {
        const int pos = (viewPos_ + (forward ? offset : -offset) + total * 2) % total;
        const int id = visible_[pos];
        if (matchesSearch(fxOrder_.label(id),search_)) {
            positionChanged(pos, false);
            speech_("Match " + std::to_string(pos + 1) + ", " + displayName());
            return;
        }
    }
    speech_("No parameter matching " + search_);
}
void FxNavigator::searchPreview() {
    if (search_.empty()) { speech_("Search empty"); return; }
    findMatching(true);
}
void FxNavigator::handle(const Key& k) {
    if (!contextUnchanged()) throw std::runtime_error("FX context changed");
    if (clearAutomationConfirm_) {
        if (k.repeat) return;
        // The focus stays on the native STATIC (never on the stale Value
        // trackbar). Its WM_GETTEXT now exposes this prompt to NVDA+Up.
        // No is the default: Enter alone must not disable automation.
        if (k.ctrl || k.alt) return;
        if (k.vk == VK_LEFT || k.vk == VK_RIGHT) {
            const bool yes = k.vk == VK_LEFT;
            if (clearAutomationYes_ != yes) {
                clearAutomationYes_ = yes;
                speech_(yes ? "Yes" : "No");
            }
        } else if (k.vk == VK_TAB) {
            speech_(reviewLine());
        } else if (k.vk == 'Y' || (k.vk == VK_RETURN && clearAutomationYes_)) {
            clearAutomationConfirm_ = false;
            clearAutomationYes_ = false;
            toggleEnvelope(true);
        } else if (k.vk == 'N' || k.vk == VK_ESCAPE || k.vk == VK_RETURN) {
            clearAutomationConfirm_ = false;
            clearAutomationYes_ = false;
            speech_("Automation clear cancelled");
        }
        return;
    }
    // Memory management or a filtered search may select a parameter without a position save.
    // Before using its step for a value change, load that parameter's setting.
    if (!fxBrowserMode_) syncParameterStep();
    if (k.vk == VK_F8 && !k.ctrl && !k.alt && !k.shift && !k.altGr &&
        !textEdit_ && !numericEdit_ && !searchMode_ && !recentMode_ && !fxBrowserMode_ && !memoryManager_) {
        if (!k.repeat) f8Press();
        return;
    }
    // A new key finalizes a pending single F8 before changing FX, editing or exiting.
    if (pendingF8At_) resolveF8();
    // TEST60: shared, project-scoped marker/beat/bar navigation.  Never let
    // these keys reach FX browser, parameter editing, or the Main action list.
    if (!textEdit_ && !searchMode_ && !numericEdit_ && !recentMode_ &&
        !defaultConfirm_ && isTransportMarkerShortcut(k)) {
        if (!k.repeat) executeTransportMarkerShortcut(k, project_, markerEdge_, speech_);
        return;
    }
    // Mirror the original Lua transport semantics. Consume key repeats so a
    // held Space cannot alternately start/stop transport multiple times.
    // Shift+Space is intentionally left to the F7 selection controller.
    // No spoken message: REAPER/OSARA own transport announcements.
    if (k.vk == VK_SPACE && !k.shift && !k.alt &&
        !textEdit_ && !searchMode_ && !numericEdit_) {
        if (!k.repeat) {
            if (k.ctrl) {
                // Ctrl+Space must invoke exactly the same native REAPER action
                // as Transport: Play/pause (40073). Calling OnPlayButton on a
                // paused transport may restart at the edit cursor, losing the
                // playback pause position. The REAPER action owns both states.
                if (Main_OnCommand) Main_OnCommand(40073, 0);
            } else {
                // Plain Space: play/stop; from pause resume immediately, as
                // requested by the legacy FX Params Lua transport contract.
                const int playState = GetPlayState ? GetPlayState() : 0;
                if ((playState & 2) && OnPlayButton) OnPlayButton();
                else if (Main_OnCommand) Main_OnCommand(40044, 0);
            }
        }
        return;
    }
    // EDIT, search, numeric fields and F7 own their respective clipboard
    // semantics. Do not steal Ctrl+C/V from Windows or structural editing.
    if (!memoryManager_ && !textEdit_ && !searchMode_ && !numericEdit_) {
        if (k.ctrl && k.alt && k.shift && !k.altGr && k.vk=='C') {
            if(!k.repeat)copyFxSnapshot();return;
        }
        if (!editF7_ && k.ctrl && !k.alt && !k.shift) {
            if (k.vk=='C') {if(!k.repeat)copyParameterValue();return;}
            if (k.vk=='V') {if(!k.repeat)pasteFxClipboard();return;}
        }
    }
    if (fxBrowserMode_) {browserKey(k);return;}
    if (memoryManager_) {memoryNavigate(k);return;}
    if(recentMode_){handleRecent(k);return;}
    if (numericEdit_) {handleAdvanced(k);return;}
    if (textEdit_) { handleTextEdit(k); return; }
    // AltGr generates Ctrl+Alt at the Win32 level, but is a text character
    // on many European keyboards, not an FX Ctrl+Alt command.
    if (k.altGr && k.character) {
        if (!valueMode_ && !searchMode_) {
            if (k.shift) cycleByInitial(k.character, true);
            else cycleByInitial(k.character);
        }
        return;
    }
    // Native REAPER FX Chain and Add FX browser must own keyboard focus.
    if (!searchMode_ && !textEdit_ && !numericEdit_ && !memoryManager_) {
        if (k.ctrl && k.shift && !k.alt && k.vk=='F') {if(!k.repeat)openCurrentFxChain();return;}
        if (k.alt && k.shift && !k.ctrl && k.vk=='F') {if(!k.repeat)openNativeFxBrowser();return;}
        if (k.ctrl && !k.shift && !k.alt && k.vk=='P') {if(!k.repeat)enterFxBrowser();return;}
        if (k.ctrl && !k.shift && !k.alt && k.vk=='W') {if(!k.repeat)returnToTrackFx();return;}
        if (k.ctrl && !k.shift && !k.alt && (k.vk==VK_LEFT||k.vk==VK_RIGHT)) {
            if(!k.repeat)switchItem(k.vk==VK_LEFT?-1:1);return;
        }
    }
    if (!searchMode_ && handleAdvanced(k))return;
    // Same memory shortcut as Track Params; F8 is reserved exclusively for A/B Compare.
    if (k.ctrl && k.shift && !k.alt && !k.altGr && k.vk == 'M' &&
        !searchMode_ && !recentMode_ && !fxBrowserMode_) {
        if (!k.repeat) openFxMemories(false);
        return;
    }
    if (!k.ctrl && k.alt && !k.shift && (k.vk=='G'||k.vk=='M')) {
        chooseSlotAccess(k.vk=='G'?0:1);return;
    }
    if (k.ctrl && k.alt && !k.shift && !k.altGr && k.vk=='B') {
        if(!k.repeat)toggleOffline();return;
    }
    if (k.ctrl && !k.alt && !k.shift && k.vk=='B') {if(!k.repeat)toggleBypass();return;}
    if (k.ctrl && !k.alt && k.vk=='D') {
        if(!k.repeat){if(k.shift)clearProjectDeltaSolo();else toggleDeltaSolo();}
        return;
    }
    if (k.ctrl && !k.shift && !k.alt && !editF7_ &&
        (k.vk == VK_PRIOR || k.vk == VK_NEXT)) {
        if (!k.repeat) browserMoveFx(k.vk == VK_PRIOR ? -1 : 1);
        return;
    }
    if (k.ctrl && !k.alt && k.vk>=VK_F1 && k.vk<=VK_F12) {
        const int slot=static_cast<int>(k.vk-VK_F1)+1;
        if(slotMode_==0){if(k.shift)saveGroup(slot);else openGroup(slot);return;}
        if(k.shift){
            if(fxOrder_.paramSlots.count(slot)) {speech_("Slot occupied. Memory position "+std::to_string(slot));return;}
            fxOrder_.paramSlots[slot]=parameter_;saveStructure();
            speech_("Saved memory position "+std::to_string(slot)+". "+currentParameterSpeech());
        } else {
            auto saved=fxOrder_.paramSlots.find(slot);
            if(saved==fxOrder_.paramSlots.end()){speech_("Memory position "+std::to_string(slot)+" empty");return;}
            const auto located=std::find(visible_.begin(),visible_.end(),saved->second);
            if(located==visible_.end()){speech_("Memory position hidden or not in this group");return;}
            positionChanged(static_cast<int>(std::distance(visible_.begin(),located)));
        }
        return;
    }
    if (k.ctrl && !k.alt && !k.shift && k.vk=='L') {
        if (groupSlot_) {speech_("Group active. Ctrl+L unavailable");return;}
        if (searchMode_) { searchMode_=false;search_.clear();speech_("Find cancelled");return; }
        if (textEdit_) return;
        if (editF7_) {speech_("Exit F7 first");return;}
        if (!fxOrder_.storedCustomOrder()) {speech_("No Custom Order. Press F7");return;}
        clearF7Filter();
        const int old=parameter_;
        fxOrder_.custom=!fxOrder_.custom;
        rebuildView(old);
        saveStructure(); // Persist only the view preference; F7 is the creation boundary.
        // Ctrl+L never creates a previously absent Custom Order.
        speech_(std::string(fxOrder_.custom?"Custom order. ":"Plugin order. ")+currentParameterSpeech());
        return;
    }
    if (k.vk==VK_F7 && !k.ctrl && !k.alt && !k.shift) {
        if(k.repeat)return;
        if(editF7_)exitF7();else enterF7();
        return;
    }
    if (editF7_ && handleF7(k)) return;
    if(k.ctrl && !k.shift && !k.alt && k.vk==VK_RETURN) {
        speech_("Press F7 to rename");return;
    }
    if (k.ctrl && k.shift && !k.alt && (k.vk==VK_UP||k.vk==VK_DOWN)) {
        if(!k.repeat)switchTrack(k.vk==VK_UP?-1:1);
        return;
    }
    if (k.ctrl && !k.alt && !k.shift && k.vk=='R') {
        if(!k.repeat) {
            loadSearchHistory();
            if(searchHistory_.empty())speech_("No recent searches");
            else {recentMode_=true;historyIndex_=0;speech_("Recent searches. "+searchHistory_.front());}
        }return;
    }
    if(k.ctrl && !k.alt && !k.shift && (k.vk==VK_UP||k.vk==VK_DOWN)) {
        if(!k.repeat)switchFx(k.vk==VK_UP?-1:1);return;
    }
    if(k.ctrl && !k.alt && !k.shift && k.vk=='F') {
        if(!k.repeat) {
            loadSearchHistory();historyIndex_=-1;
            searchMode_=true;search_.clear();
            speech_("Find parameter. Type search text; Up or Down finds matches; Enter accepts; Escape cancels.");
        }
        return;
    }
    if(searchMode_) {
        if(k.ctrl && (k.vk==VK_UP||k.vk==VK_DOWN)) {
            if(!searchHistory_.empty()) {
                historyIndex_=std::clamp(historyIndex_+(k.vk==VK_UP?1:-1),0,static_cast<int>(searchHistory_.size())-1);
                search_=searchHistory_[static_cast<size_t>(historyIndex_)];speech_(search_);
            }
        }
        else if(k.vk==VK_ESCAPE){searchMode_=false;search_.clear();speech_("Find cancelled");}
        else if(k.vk==VK_RETURN){
            const std::string query=search_;
            if(!query.empty()) {
                searchHistory_.erase(std::remove(searchHistory_.begin(),searchHistory_.end(),query),searchHistory_.end());
                searchHistory_.insert(searchHistory_.begin(),query);
                if(searchHistory_.size()>20)searchHistory_.pop_back();
                saveSearchHistory();
            }
            historyIndex_=-1;
            searchMode_=false;search_.clear();
            applyF7Filter(query);
        }
        else if(k.vk==VK_UP||k.vk==VK_DOWN)findMatching(k.vk==VK_DOWN);
        else if(k.vk==VK_BACK){if(!search_.empty())search_.pop_back();searchPreview();}
        else if(search_.size()<64) {
            if(k.vk>='A'&&k.vk<='Z')search_+=static_cast<char>(k.vk);
            else if(k.vk>='0'&&k.vk<='9')search_+=static_cast<char>(k.vk);
            else if(k.vk==VK_SPACE)search_+=' ';
            searchPreview();
        }
        return;
    }
    if(k.vk==VK_BACK && !k.alt) {
        if(!k.repeat) {
            if(k.ctrl && k.shift)resetAllToDefault();
            else if(k.ctrl)resetGridAndStep();
            else resetCurrentToDefault();
        }
        return;
    }
    if (k.ctrl && !k.shift && !k.alt && k.vk==VK_HOME){navigate(-viewPos_);return;}
    if (k.ctrl && !k.shift && !k.alt && k.vk==VK_END){navigate(static_cast<int>(visible_.size())-1-viewPos_);return;}
    if (k.vk==VK_ESCAPE){if(valueMode_){valueMode_=false;announceTitle();}
        else if(f7FilterActive_){
            clearF7Filter();
            speech_(std::string(editF7_?"Edit: Search cleared. ":"Search cleared. ")+
                    (editF7_?editorParameterSpeech():currentParameterSpeech()));
        }
        else if(editF7_)exitF7();
        else if(groupSlot_){openGroup(groupSlot_);}else end();return;}
    if(k.vk==VK_RETURN && !k.repeat && !editF7_ && dynamicsVirtualValid(parameter_)) {
        speech_(currentParameterSpeech());return; // read-only summary; no slider
    }
    if(k.vk==VK_RETURN && !k.repeat && !editF7_ && (dynamicsToggle(parameter_) || dynamicsDetectorInput(parameter_))) {
        if(dynamicsToggle(parameter_)) {
            setValue(valueFraction()>=0.5?0.0:1.0);
            return;
        }
        // Discrete detector input can also be adjusted via Value slider.
    }
    if(k.vk==VK_RETURN && !k.repeat && !editF7_ && eqVirtualValid(parameter_)) {
        if(parameter_==reaeq::action){eqBandAction();return;}
        if(reaeq::enabledId(parameter_)){
            setValue(eqVirtualFraction(parameter_)>=0.5?0.0:1.0);return;
        }
    }
    if(k.vk==VK_RETURN){if(k.repeat)return;valueMode_=!valueMode_;
        if (valueMode_) speech_(reviewLine()); else announceTitle(); return;}
    // Tab describes the active parameter ordering; inside F7 it still
    // reports the selection count (handled earlier in handleF7).
    if (!k.ctrl && !k.alt && !k.shift && k.vk==VK_TAB) {
        speech_((groupSlot_ ? groupLabel(groupSlot_) :
                fxOrder_.custom?"Custom Order":"Plugin Order")+
                (f7FilterActive_?". Search results":"")+". "+viewPositionSpeech());return;
    }
    if (!k.ctrl && !k.alt && !k.shift && k.vk==VK_F3) {
        speech_("Grid "+std::to_string(columns_)+". Step "+std::to_string(stepScale_)+
                ". "+(slotMode_==0?"Group slots":"Memory slots"));return;
    }
    if (!k.ctrl && !k.alt && !k.shift && (k.vk==VK_F5||k.vk==VK_F6||k.vk==VK_F9)) {
        if(!k.repeat)runLuaFunctionAction(k.vk==VK_F5?40280:k.vk==VK_F6?40281:40282);
        return;
    }
    // In the grid (including F7 and filtered/group views), typing an initial
    // cycles through the CURRENT visible entries, exactly like the Lua.
    // It is not a multi-character filter: Ctrl+F owns that functionality.
    if (!k.ctrl && !k.alt && k.character) {
        if (!valueMode_) {
            if (k.shift) cycleByInitial(k.character, true);
            else cycleByInitial(k.character);
        }
        return; // Value remains open; characters do not modify its slider.
    }
    if(k.vk==VK_F1||k.vk==VK_F2){
        const int next=std::clamp(columns_+(k.vk==VK_F1?-1:1),1,200);
        if(next!=columns_){columns_=next;lastControl_=LastControl::grid;rememberPosition();speech_("Grid "+std::to_string(columns_));}return;
    }
    if(k.alt||valueMode_) {
        if(k.vk==VK_LEFT||k.vk==VK_RIGHT){
            const int next=std::clamp(stepScale_+(k.vk==VK_LEFT?-1:1),-10,10);
            if(next!=stepScale_){stepScale_=next;lastControl_=LastControl::step;markParameterStepChanged();rememberPosition();speech_("Step "+std::to_string(stepScale_));}
        }else if (k.vk == VK_HOME) setValue(1);
        else if (k.vk == VK_END) setValue(0);
        else if(k.vk==VK_UP||k.vk==VK_DOWN||k.vk==VK_PRIOR||k.vk==VK_NEXT)
            nudge(k.vk==VK_UP||k.vk==VK_PRIOR?1:-1,k.vk==VK_PRIOR||k.vk==VK_NEXT);
        return;
    }
    if(visible_.empty())return;
    const int start=(viewPos_/columns_)*columns_;
    const int end=std::min(static_cast<int>(visible_.size())-1,start+columns_-1);
    if(k.vk==VK_HOME){navigate(start-viewPos_);return;}
    if(k.vk==VK_END){navigate(end-viewPos_);return;}
    if(k.vk==VK_PRIOR||k.vk==VK_NEXT){
        const int target=std::clamp(viewPos_+(k.vk==VK_PRIOR?-5:5),start,end);
        navigate(target-viewPos_);return;
    }
    if(k.vk==VK_LEFT||k.vk==VK_RIGHT){
        const int target=viewPos_+(k.vk==VK_LEFT?-columns_:columns_);
        if(target>=0&&target<static_cast<int>(visible_.size()))navigate(target-viewPos_);
        return;
    }
    if(k.vk==VK_UP&&viewPos_>start)navigate(-1);
    else if(k.vk==VK_DOWN&&viewPos_<end)navigate(1);
}
}
