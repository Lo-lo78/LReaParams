// LReaParams 0.0.46: contextual Track/Take navigation and Lua-style FX browser.
// The browser has an independent cursor: moving in it never changes parameters
// until Enter is pressed. All REAPER API calls execute on the main thread.
#include "lrp/FxNavigator.h"
#include <algorithm>
#include <cctype>
#include <cstring>
#include <cstdlib>
#include <cwctype>
#include <utility>

namespace lrp {
namespace {
bool guidEquals(const GUID* a, const GUID& b) {
    return a && std::memcmp(a, &b, sizeof(GUID)) == 0;
}
// Same display-prefix list as the Lua's strip_fx_prefix(). Keep the raw
// host name intact in the FX identity/profile: stripping is only for speech
// and cyclic searching in the browser.
std::string browserDisplayName(std::string name) {
    if (name.rfind("Monitor: ", 0) == 0) name.erase(0, 9);
    for (const char* prefix : {"JS:", "VST:", "VSTi:", "VST2:", "VST2i:",
                               "VST3:", "VST3i:", "CLAP:", "CLAPi:",
                               "AU:", "AUi:", "DX:", "DXi:"}) {
        const std::string p(prefix);
        if (name.rfind(p, 0) == 0) {
            name.erase(0, p.size());
            while (!name.empty() && name.front() == ' ') name.erase(name.begin());
            break;
        }
    }
    return name;
}
}

bool FxNavigator::switchToContext(MediaTrack* destination, MediaItem_Take* destinationTake,
                                 const std::string& what) {
    if (!destination || !ValidatePtr2(project_, destination, "MediaTrack*") ||
        (destinationTake && (!ValidatePtr2(project_, destinationTake, "MediaItem_Take*") ||
                             GetMediaItemTake_Track(destinationTake) != destination))) {
        speech_("FX context unavailable"); return false;
    }
    if (destination == track_ && destinationTake == take_) return true;
    const GUID* guid = GetTrackGUID(destination);
    if (!guid) { speech_("FX context unavailable"); return false; }

    // Validate at least one eligible FX BEFORE changing the active navigator.
    const int count = destinationTake ? TakeFX_GetCount(destinationTake) : TrackFX_GetCount(destination);
    const int monitor = !destinationTake && destination == GetMasterTrack(project_) ?
        TrackFX_GetRecCount(destination) : 0;
    bool found = false;
    for (int i = 0; i < count + monitor; ++i) {
        const int id = i < count ? i : 0x1000000 + (i - count);
        const GUID* candidate = destinationTake ? TakeFX_GetFXGUID(destinationTake, id) :
            TrackFX_GetFXGUID(destination, id);
        const int parameters = destinationTake ? TakeFX_GetNumParams(destinationTake, id) :
            TrackFX_GetNumParams(destination, id);
        if (candidate && parameters > 0) { found = true; break; }
    }
    if (!found) { speech_(destinationTake ? "No take FX parameters" : "Track has no FX parameters"); return false; }

    rememberPosition();
    flushParameterSteps();
    flushPersistentPosition();
    // Preserve the complete original navigation state for failed transitions.
    // No undo point or external REAPER selection is changed on failure.
    FxNavigator backup(*this);
    track_ = destination;
    take_ = destinationTake;
    trackGuid_ = *guid;
    // Avoid recording the OLD FX under the NEW track/take identity.
    count_ = 0; browserIndex_ = -1;
    bool switched = false;
    if (rebuildEntries()) {
        int preferred = 0;
        if (const auto* memory = contextMemory(); memory && memory->hasLastFx) {
            const int old = rememberedFxIndex(*memory);
            if (old >= 0) preferred = old;
        }
        if (selectFx(preferred)) switched = true;
        for (int i = 0; !switched && i < static_cast<int>(entries_.size()); ++i)
            if (i != preferred && selectFx(i)) switched = true;
    }
    if (!switched) {
        *this = std::move(backup);
        speech_("FX context switch failed");
        return false;
    }
    if (destinationTake) {
        MediaItem* item = GetMediaItemTake_Item(destinationTake);
        if (item) {
            SetOnlyTrackSelected(destination);
            SetMediaItemSelected(item, true);
        }
    } else SetOnlyTrackSelected(destination);
    UpdateArrange();
    browserCursor_ = browserIndex_;
    browserScopeMonitor_ = !take_ && track_ == GetMasterTrack(project_) && (fx_ & 0x1000000);
    if (fxBrowserMode_) speech_(what + ". " + browserSpeech());
    else speech_(what + ". " + fxContextAnnouncement());
    return true;
}

void FxNavigator::switchItem(int direction) {
    if (!track_ || !direction || track_ == GetMasterTrack(project_)) return;
    const int total = GetTrackNumMediaItems(track_);
    int start = direction > 0 ? -1 : total;
    if (take_) {
        MediaItem* current = GetMediaItemTake_Item(take_);
        for (int i = 0; i < total; ++i)
            if (GetTrackMediaItem(track_, i) == current) { start = i; break; }
    } else {
        // As in the Lua: a selected item with Take FX gets priority when
        // leaving Track FX; otherwise search relative to the selected item.
        for (int i = 0; i < total; ++i) {
            MediaItem* item = GetTrackMediaItem(track_, i);
            if (item && GetMediaItemInfo_Value(item, "B_UISEL") > 0.5) {
                MediaItem_Take* tk = GetActiveTake(item);
                if (tk && TakeFX_GetCount(tk) > 0) {
                    switchToContext(track_, tk, "Take FX"); return;
                }
                start = i; break;
            }
        }
    }
    for (int i = start + direction; i >= 0 && i < total; i += direction) {
        MediaItem* item = GetTrackMediaItem(track_, i);
        MediaItem_Take* tk = item ? GetActiveTake(item) : nullptr;
        if (tk && TakeFX_GetCount(tk) > 0) {
            switchToContext(track_, tk, "Take FX"); return;
        }
    }
    speech_(take_ ? (direction < 0 ? "No previous item with FX" : "No next item with FX") :
            "No item with FX");
}

void FxNavigator::returnToTrackFx() {
    if (take_) switchToContext(track_, nullptr, "Track FX");
    // Ctrl+W from Track FX is deliberately a quiet no-op, as in Lua.
}

void FxNavigator::openCurrentFxChain() {
    if (!valid()) return;
    rememberPosition(); flushPersistentPosition();
    // Extension releases the off-screen keyboard/focus owner BEFORE showing
    // the native chain, otherwise hideAndRestore can steal focus again.
    nativeFxWindowRequest_ = NativeFxWindow::chain;
}
void FxNavigator::openNativeFxBrowser() {
    if (!active_) return;
    rememberPosition(); flushPersistentPosition();
    nativeFxWindowRequest_ = NativeFxWindow::addFx;
}

bool FxNavigator::browserEntryInScope(int entryIndex) const {
    if (entryIndex < 0 || entryIndex >= static_cast<int>(entries_.size())) return false;
    if (take_ || track_ != GetMasterTrack(project_)) return true;
    return ((entries_[static_cast<size_t>(entryIndex)].index & 0x1000000) != 0) == browserScopeMonitor_;
}
int FxNavigator::browserVisibleIndex() const {
    const int candidate = std::clamp(browserCursor_, 0, std::max(0, static_cast<int>(entries_.size())-1));
    if (browserEntryInScope(candidate)) return candidate;
    // Guard against an external chain modification or stale browser cursor.
    // Never jump to the other Master/Monitor chain as a fallback.
    for (int i=0; i<static_cast<int>(entries_.size()); ++i)
        if (browserEntryInScope(i)) return i;
    return -1;
}
std::string FxNavigator::browserSpeech() const {
    if (entries_.empty()) return "No FX";
    const int index = browserVisibleIndex();
    if (index < 0) return track_ == GetMasterTrack(project_) && !take_ ?
        (browserScopeMonitor_ ? "Monitor FX. No FX" : "Master FX. No FX") : "No FX in this chain";
    const auto& entry = entries_[static_cast<size_t>(index)];
    const bool monitor = !take_ && track_ == GetMasterTrack(project_) && browserScopeMonitor_;
    const std::string label = browserDisplayName(entry.name);
    const bool offline = take_ ? TakeFX_GetOffline(take_, entry.index) :
                                 TrackFX_GetOffline(track_, entry.index);
    const bool bypassed = !offline && (take_ ? !TakeFX_GetEnabled(take_, entry.index) :
                                   !TrackFX_GetEnabled(track_, entry.index));
    std::string text = (monitor ? "Monitor FX. " : track_==GetMasterTrack(project_) ? "Master FX. " : "");
    if (offline) text += "Offline. ";
    else if (bypassed) text += "Bypassed. ";
    if (!offline) {
        int delta = -1;
        if (deltaParameter(track_, take_, entry.index, delta) &&
            (take_ ? TakeFX_GetParamNormalized(take_, entry.index, delta) :
                     TrackFX_GetParamNormalized(track_, entry.index, delta)) > 0.5)
            text += "Delta Solo. ";
    }
    text += label;
    int ordinal = 0, total = 0;
    for (int i = 0; i < static_cast<int>(entries_.size()); ++i) {
        if (browserEntryInScope(i)) {
            ++total;
            if (i <= index) ++ordinal;
        }
    }
    return text + ". " + std::to_string(ordinal) + " of " + std::to_string(total);
}
void FxNavigator::enterFxBrowser() {
    if (!active_ || entries_.empty()) return;
    onlineReturnPending_ = false; // F10 is an explicit request to browse.
    rememberPosition(); flushPersistentPosition();
    clearF7Filter(); editF7_ = false;
    fxBrowserMode_ = true;
    browserScopeMonitor_ = !take_ && track_ == GetMasterTrack(project_) && (fx_ & 0x1000000);
    browserCursor_ = browserIndex_;
    browserMasterCursor_ = browserMonitorCursor_ = -1;
    if (track_ == GetMasterTrack(project_) && !take_) {
        if (browserScopeMonitor_) browserMonitorCursor_ = browserCursor_;
        else browserMasterCursor_ = browserCursor_;
    }
    valueMode_ = false;
    speech_("FX Browser. " + browserSpeech());
}
void FxNavigator::browserMove(int amount) {
    if (!amount || entries_.empty()) return;
    const int old = browserVisibleIndex();
    if (old < 0) return;
    // One-column Track/Take browser; Master and Monitor are two distinct
    // columns that never wrap into each other vertically.
    int next = old;
    for (int i = std::abs(amount); i > 0; --i) {
        const int step = amount > 0 ? 1 : -1;
        if (!browserEntryInScope(next + step)) break;
        next += step;
    }
    if (next != old) {onlineReturnPending_ = false; browserCursor_ = next; speech_(browserSpeech());}
}
void FxNavigator::browserSwitchColumn(int direction) {
    // Master and Monitor are separate vertical lists, linked only by the
    // horizontal arrows (right: Master -> Monitor; left: Monitor -> Master).
    if (take_ || track_ != GetMasterTrack(project_) || direction == 0) return;
    const bool targetMonitor = direction > 0;
    if (browserScopeMonitor_ == targetMonitor) return; // quiet at outer edge
    onlineReturnPending_ = false;
    const int current = browserVisibleIndex();
    int& fromCursor = browserScopeMonitor_ ? browserMonitorCursor_ : browserMasterCursor_;
    if (current >= 0) fromCursor = current;
    browserScopeMonitor_ = targetMonitor;
    const int remembered = targetMonitor ? browserMonitorCursor_ : browserMasterCursor_;
    if (browserEntryInScope(remembered)) {
        browserCursor_ = remembered;
    } else {
        // A missing/empty column is still reachable and announces its scope.
        // No effect from the other chain may be selected as a fallback.
        for (int i = 0; i < static_cast<int>(entries_.size()); ++i) {
            if (browserEntryInScope(i)) { browserCursor_ = i; break; }
        }
    }
    speech_(browserSpeech());
}
void FxNavigator::browserSelect() {
    if (entries_.empty() || !active_) return;
    onlineReturnPending_ = false;
    const int index = browserVisibleIndex();
    if (index < 0) return;
    // After an offline/online transition the plugin may have re-created its
    // parameter list. Rebind even if this is the same FX as before.
    if ((index != browserIndex_ || count_ == 0) && !selectFx(index)) {
        speech_("No navigable FX parameters"); return;
    }
    fxBrowserMode_ = false;
    speech_(fxContextAnnouncement());
}
void FxNavigator::browserCycleByInitial(wchar_t character, bool backwards) {
    if (entries_.empty()) return;
    const int origin = browserVisibleIndex();
    if (origin < 0) return;
    const int direction = backwards ? -1 : 1;
    for (int i = 1; i <= static_cast<int>(entries_.size()); ++i) {
        const int j = (origin + direction*i + static_cast<int>(entries_.size()) * (i+1)) % static_cast<int>(entries_.size());
        if (!browserEntryInScope(j)) continue;
        const std::string label = browserDisplayName(entries_[static_cast<size_t>(j)].name);
        if (!label.empty() && std::towlower(static_cast<unsigned char>(label[0])) == std::towlower(character)) {
            onlineReturnPending_ = false; browserCursor_ = j; speech_(browserSpeech()); return;
        }
    }
}
void FxNavigator::browserSwitchTrack(int direction) {
    if (!fxBrowserMode_ || !direction || !track_ ||
        track_ == GetMasterTrack(project_)) return;
    const int total = CountTracks(project_);
    const int ordinal = static_cast<int>(GetMediaTrackInfo_Value(track_, "IP_TRACKNUMBER")) - 1;
    if (ordinal < 0 || ordinal >= total) return;
    MediaTrack* target = nullptr;
    for (int index = ordinal + direction; index >= 0 && index < total; index += direction) {
        MediaTrack* candidate = GetTrack(project_, index);
        if (!candidate || !ValidatePtr2(project_, candidate, "MediaTrack*") ||
            !GetTrackGUID(candidate)) continue;
        // Unlike the parameter grid, the browser must also reach offline FX.
        const int fxCount = TrackFX_GetCount(candidate);
        for (int fx = 0; fx < fxCount; ++fx)
            if (TrackFX_GetFXGUID(candidate, fx)) { target = candidate; break; }
        if (target) break;
    }
    if (!target) return; // Silent boundary.
    onlineReturnPending_ = false;
    const GUID* id = GetTrackGUID(target);
    if (!id) return;
    // Do not save the old FX under the new track GUID. On failure, put every
    // cursor and profile association back exactly as before.
    rememberPosition(); flushParameterSteps(); flushPersistentPosition();
    FxNavigator backup(*this);
    track_ = target; take_ = nullptr; trackGuid_ = *id;
    browserIndex_ = -1; count_ = 0;
    if (!rebuildEntries()) { *this = std::move(backup); return; }
    int preferred = 0;
    if (const auto* previous = contextMemory(); previous && previous->hasLastFx) {
        const int remembered = rememberedFxIndex(*previous);
        if (remembered >= 0) preferred = remembered;
    }
    preferred = std::clamp(preferred, 0, static_cast<int>(entries_.size()) - 1);
    if (TrackFX_GetNumParams(track_, entries_[static_cast<size_t>(preferred)].index) > 0) {
        if (!selectFx(preferred)) { *this = std::move(backup); return; }
    } else {
        const auto& selected = entries_[static_cast<size_t>(preferred)];
        fx_ = selected.index; fxGuid_ = selected.guid;
        parameter_ = 0; parameterName_.clear(); count_ = 0;
    }
    fxBrowserMode_ = true;
    browserScopeMonitor_ = false;
    browserCursor_ = preferred;
    browserMasterCursor_ = browserMonitorCursor_ = -1;
    SetOnlyTrackSelected(target);
    UpdateArrange();
    char label[2048]{};
    GetTrackName(target, label, sizeof(label));
    speech_(std::string(label[0] ? label : "Track") + ". " + browserSpeech());
}

void FxNavigator::browserMoveFx(int direction) {
    if (!direction || entries_.empty()) return;
    onlineReturnPending_ = false;
    const int srcIndex = fxBrowserMode_ ? browserVisibleIndex() : browserIndex_;
    if (srcIndex < 0 || srcIndex >= static_cast<int>(entries_.size())) return;
    const GUID* current = take_ ? TakeFX_GetFXGUID(take_, entries_[static_cast<size_t>(srcIndex)].index) :
                                  TrackFX_GetFXGUID(track_, entries_[static_cast<size_t>(srcIndex)].index);
    if (!guidEquals(current, entries_[static_cast<size_t>(srcIndex)].guid)) {
        speech_("FX list changed. Reopen FX Params"); return;
    }
    const int targetIndex = srcIndex + direction;
    if (!browserEntryInScope(targetIndex)) return;
    const int src = entries_[static_cast<size_t>(srcIndex)].index;
    const int target = entries_[static_cast<size_t>(targetIndex)].index;
    if (((src ^ target) & 0x1000000) != 0) return; // no Master↔Monitor crossing
    const GUID movingGuid = entries_[static_cast<size_t>(srcIndex)].guid;
    rememberPosition(); flushPersistentPosition();
    const GUID activeGuid = fxGuid_;
    Undo_BeginBlock2(project_);
    if (take_) TakeFX_CopyToTake(take_, src, take_, target, true);
    else TrackFX_CopyToTrack(track_, src, track_, target, true);
    Undo_EndBlock2(project_, "LReaParams: reorder FX", take_ ? UNDO_STATE_ITEMS : UNDO_STATE_FX);
    if (!rebuildEntries()) {end();return;}
    int newActive = -1, newCursor = -1;
    for (int i=0;i<static_cast<int>(entries_.size());++i) {
        if (guidEquals(&entries_[static_cast<size_t>(i)].guid, activeGuid)) newActive=i;
        if (guidEquals(&entries_[static_cast<size_t>(i)].guid, movingGuid)) newCursor=i;
    }
    if (newActive>=0 && newCursor>=0) {
        // The host may have shifted the active FX to another numeric slot.
        // Rebind by GUID; never use an old slot against a different plugin.
        count_=0;browserIndex_=-1;
        const FxEntry& active = entries_[static_cast<size_t>(newActive)];
        const int nparams = take_ ? TakeFX_GetNumParams(take_, active.index) :
                                    TrackFX_GetNumParams(track_, active.index);
        if (fxBrowserMode_ && nparams <= 0) {
            // Offline FX can be physically reordered without parameters.
            fx_ = active.index; fxGuid_ = active.guid;
            browserIndex_ = newActive;
            parameter_ = 0; parameterName_.clear();
        } else if (!selectFx(newActive)) {end();return;}
        browserCursor_=newCursor;
        speech_("FX moved. " + (fxBrowserMode_ ? browserSpeech() : fxContextAnnouncement()));
        return;
    }
    // REAPER replaced the instance rather than moving it. Do not guess.
    end();
}
bool FxNavigator::enterOnlineParameters(int entryIndex) {
    // selectFx() is the same tested path used when reopening FX Params:
    // it re-reads the new parameter count, reloads the .fx group and restores
    // the per-instance GUID position (or the persisted LastParam fallback).
    if (!selectFx(entryIndex)) return false;
    onlineReturnPending_ = false;
    fxBrowserMode_ = false;
    browserCursor_ = browserIndex_;
    speech_("Online. " + fxContextAnnouncement());
    return true;
}

bool FxNavigator::pollOnlineParameters() {
    if (!onlineReturnPending_) return false;
    if (!active_ || !fxBrowserMode_ || !track_) {
        onlineReturnPending_ = false;
        return false;
    }
    const int selected = browserVisibleIndex();
    if (selected < 0 || selected >= static_cast<int>(entries_.size()) ||
        !guidEquals(&entries_[static_cast<size_t>(selected)].guid, onlineReturnGuid_)) {
        // The user chose another FX/chain: never redirect their navigation.
        onlineReturnPending_ = false;
        return false;
    }
    const auto& entry = entries_[static_cast<size_t>(selected)];
    const GUID* actual = take_ ? TakeFX_GetFXGUID(take_, entry.index) :
                                 TrackFX_GetFXGUID(track_, entry.index);
    if (!guidEquals(actual, onlineReturnGuid_) ||
        (take_ ? TakeFX_GetOffline(take_, entry.index) : TrackFX_GetOffline(track_, entry.index))) {
        onlineReturnPending_ = false;
        return false;
    }
    const ULONGLONG now = GetTickCount64();
    if (now >= onlineReturnUntil_) {
        // The FX is online but may genuinely have no parameters. Leave the
        // browser usable, including Enter and Ctrl+Alt+B, without a busy wait.
        onlineReturnPending_ = false;
        return false;
    }
    if (now < onlineReturnNextCheck_) return false;
    onlineReturnNextCheck_ = now + 250;
    const int params = take_ ? TakeFX_GetNumParams(take_, entry.index) :
                               TrackFX_GetNumParams(track_, entry.index);
    return params > 0 && enterOnlineParameters(selected);
}

void FxNavigator::toggleOffline() {
    if (!active_ || !track_ || (fxBrowserMode_ && entries_.empty())) return;
    const int selected = fxBrowserMode_ ? browserVisibleIndex() : browserIndex_;
    if (selected < 0 || selected >= static_cast<int>(entries_.size()) ||
        (fxBrowserMode_ && !browserEntryInScope(selected))) return;
    const FxEntry entry = entries_[static_cast<size_t>(selected)];
    const GUID* actual = take_ ? TakeFX_GetFXGUID(take_, entry.index) :
                                 TrackFX_GetFXGUID(track_, entry.index);
    if (!guidEquals(actual, entry.guid)) {
        speech_("FX list changed. Reopen FX Params");return;
    }
    onlineReturnPending_ = false;
    const bool wasOffline = take_ ? TakeFX_GetOffline(take_, entry.index) :
                                    TrackFX_GetOffline(track_, entry.index);
    // Preserve the current group, occurrence and parameter BEFORE REAPER
    // unloads an FX's parameter list. Both Track FX and Take FX use this path.
    if (!fxBrowserMode_ && !wasOffline) {
        rememberPosition();flushPersistentPosition();
    }
    if (take_) TakeFX_SetOffline(take_, entry.index, !wasOffline);
    else TrackFX_SetOffline(track_, entry.index, !wasOffline);
    const bool nowOffline = take_ ? TakeFX_GetOffline(take_, entry.index) :
                                    TrackFX_GetOffline(track_, entry.index);
    if (nowOffline == wasOffline) {
        speech_("Offline not changed");return;
    }
    // Some plugin names change when unloaded/reloaded. Rebuild entries and
    // rebind by FX GUID, never by a potentially stale numeric slot.
    if (!rebuildEntries()) {speech_("FX list unavailable");end();return;}
    int newCursor = -1;
    for (int i=0;i<static_cast<int>(entries_.size());++i)
        if (guidEquals(&entries_[static_cast<size_t>(i)].guid, entry.guid)) {
            newCursor = i;break;
        }
    if (newCursor < 0) {speech_("FX list changed. Reopen FX Params");end();return;}
    browserCursor_ = newCursor;
    if (guidEquals(&entry.guid, fxGuid_)) {
        // Discard the old parameter binding, never reuse a stale index/count.
        count_ = 0;
    }
    if (nowOffline) {
        browserScopeMonitor_ = !take_ && track_ == GetMasterTrack(project_) &&
                              (entry.index & 0x1000000);
        // Offline FX may expose zero parameters, but the browser must stay
        // navigable so the same shortcut can switch the plugin online.
        clearF7Filter();editF7_=false;fxBrowserMode_=true;valueMode_=false;
        speech_("Offline. " + browserSpeech());
        return;
    }
    // REAPER has switched it back online: restore the parameter GRID right
    // away, including its group and exact saved position. No Enter, Esc or
    // second invocation of FX Params should be needed.
    if (enterOnlineParameters(newCursor)) return;
    if (!active_) return; // selectFx() can abort on a replaced FX GUID.
    // Some instruments populate their parameters a little after SetOffline.
    // Keep Ctrl+Alt+B/F10/Enter operational and retry unobtrusively on the
    // existing REAPER main-thread timer until ready or navigation changes.
    fxBrowserMode_ = true;
    onlineReturnPending_ = true;
    onlineReturnGuid_ = entry.guid;
    onlineReturnNextCheck_ = GetTickCount64() + 250;
    onlineReturnUntil_ = GetTickCount64() + 90000;
    speech_("Online. Loading parameters. " + browserSpeech());
}
void FxNavigator::browserKey(const Key& k) {
    if (k.vk==VK_SPACE && !k.shift && !k.alt) {
        if(!k.repeat) Main_OnCommand(k.ctrl ? 40073 : 40044, 0);
        return;
    }
    if (k.repeat && (k.vk==VK_RETURN || k.vk=='B' || k.vk=='D' || k.vk==VK_ESCAPE))return;
    if (k.ctrl && k.alt && !k.shift && !k.altGr && k.vk=='B') {
        toggleOffline();return;
    }
    if (k.ctrl && !k.shift && !k.alt) {
        // Ctrl+PageUp/Down physically moves the selected FX inside its chain.
        if (k.vk == VK_PRIOR || k.vk == VK_NEXT) {
            if (!k.repeat) browserMoveFx(k.vk == VK_PRIOR ? -1 : 1);
            return;
        }
        // Ctrl+Up/Down can also navigate inside the opened chain, just like
        // the parameter grid. It must not jump between Master and Monitor FX.
        if (k.vk==VK_UP||k.vk==VK_DOWN) {browserMove(k.vk==VK_UP?-1:1);return;}
        if (k.vk==VK_HOME||k.vk==VK_END) {browserMove(k.vk==VK_HOME?-100000:100000);return;}
        if (k.vk=='D') {toggleDeltaSolo();return;}
        if (k.vk=='B') {
            const int selected = browserVisibleIndex();
            if (selected < 0 || !browserEntryInScope(selected)) return;
            if (selected != browserIndex_ && !selectFx(selected))return;
            toggleBypass();speech_(browserSpeech());return;
        }
        if (k.vk=='W') {returnToTrackFx();return;}
        if (k.vk==VK_LEFT || k.vk==VK_RIGHT) {switchItem(k.vk==VK_LEFT?-1:1);return;}
    }
    if (k.alt && k.shift && !k.ctrl && k.vk=='F') {openNativeFxBrowser();return;}
    if (k.ctrl && k.shift && !k.alt) {
        if (k.vk=='F') {openCurrentFxChain();return;}
        if (k.vk==VK_UP||k.vk==VK_DOWN) {if (!k.repeat) browserSwitchTrack(k.vk==VK_UP?-1:1);return;}
        if (k.vk=='D') {clearProjectDeltaSolo();return;}
    }
    if (k.vk==VK_ESCAPE) {end();return;}
    if (!k.ctrl && !k.alt) {
        if (k.vk==VK_RETURN) {browserSelect();return;}
        if (k.vk==VK_TAB) {speech_(browserSpeech());return;}
        if (k.vk==VK_UP||k.vk==VK_DOWN) {browserMove(k.vk==VK_UP?-1:1);return;}
        if (k.vk==VK_PRIOR||k.vk==VK_NEXT) {browserMove(k.vk==VK_PRIOR?-5:5);return;}
        if (k.vk==VK_HOME||k.vk==VK_END) {browserMove(k.vk==VK_HOME?-100000:100000);return;}
        // Horizontal arrows change Master/Monitor columns, never the FX
        // selection in the parameter grid. Vertical navigation stays scoped.
        if (!k.shift && (k.vk==VK_LEFT||k.vk==VK_RIGHT)) {
            browserSwitchColumn(k.vk==VK_LEFT?-1:1);return;
        }
        if (k.character) browserCycleByInitial(k.character, k.shift);
    } else if (k.altGr && k.character) browserCycleByInitial(k.character, k.shift);
}
} // namespace lrp
