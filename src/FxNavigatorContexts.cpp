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

int FxNavigator::browserVisibleIndex() const {
    return std::clamp(browserCursor_, 0, std::max(0, static_cast<int>(entries_.size()) - 1));
}
std::string FxNavigator::browserSpeech() const {
    if (entries_.empty()) return "No FX";
    const int index = browserVisibleIndex();
    const auto& entry = entries_[static_cast<size_t>(index)];
    const bool monitor = (entry.index & 0x1000000) != 0;
    const std::string label = browserDisplayName(entry.name);
    const bool offline = take_ ? TakeFX_GetOffline(take_, entry.index) :
                                 TrackFX_GetOffline(track_, entry.index);
    const bool bypassed = !offline && (take_ ? !TakeFX_GetEnabled(take_, entry.index) :
                                   !TrackFX_GetEnabled(track_, entry.index));
    std::string text = (monitor ? "Monitor FX. " : track_==GetMasterTrack(project_) ? "Master FX. " : "");
    if (offline) text += "Offline. ";
    else if (bypassed) text += "Bypassed. ";
    text += label;
    int ordinal = 0, total = 0;
    for (int i = 0; i < static_cast<int>(entries_.size()); ++i) {
        if (((entries_[static_cast<size_t>(i)].index & 0x1000000) != 0) == monitor) {
            ++total;
            if (i <= index) ++ordinal;
        }
    }
    return text + ". " + std::to_string(ordinal) + " of " + std::to_string(total);
}
void FxNavigator::enterFxBrowser() {
    if (!active_ || entries_.empty()) return;
    rememberPosition(); flushPersistentPosition();
    clearF7Filter(); editF7_ = false;
    fxBrowserMode_ = true;
    browserCursor_ = browserIndex_;
    valueMode_ = false;
    speech_("FX Browser. " + browserSpeech());
}
void FxNavigator::browserMove(int amount) {
    if (!amount || entries_.empty()) return;
    const int old = browserVisibleIndex();
    const int category = entries_[static_cast<size_t>(old)].index & 0x1000000;
    // One-column Track/Take browser; Master and Monitor are two distinct
    // columns that never wrap into each other vertically.
    int next = old;
    for (int i = std::abs(amount); i > 0; --i) {
        const int step = amount > 0 ? 1 : -1;
        if (next + step < 0 || next + step >= static_cast<int>(entries_.size()) ||
            (entries_[static_cast<size_t>(next + step)].index & 0x1000000) != category) break;
        next += step;
    }
    if (next != old) {browserCursor_ = next; speech_(browserSpeech());}
}
void FxNavigator::browserSelect() {
    if (entries_.empty() || !active_) return;
    const int index = browserVisibleIndex();
    if (index != browserIndex_ && !selectFx(index)) {
        speech_("No navigable FX parameters"); return;
    }
    fxBrowserMode_ = false;
    speech_(fxContextAnnouncement());
}
void FxNavigator::browserCycleByInitial(wchar_t character, bool backwards) {
    if (entries_.empty()) return;
    const int origin = browserVisibleIndex();
    const bool master = track_ == GetMasterTrack(project_);
    const bool monitor = (entries_[static_cast<size_t>(origin)].index & 0x1000000) != 0;
    const int direction = backwards ? -1 : 1;
    for (int i = 1; i <= static_cast<int>(entries_.size()); ++i) {
        const int j = (origin + direction*i + static_cast<int>(entries_.size()) * (i+1)) % static_cast<int>(entries_.size());
        if (master && ((entries_[static_cast<size_t>(j)].index & 0x1000000) != 0) != monitor) continue;
        const std::string label = browserDisplayName(entries_[static_cast<size_t>(j)].name);
        if (!label.empty() && std::towlower(static_cast<unsigned char>(label[0])) == std::towlower(character)) {
            browserCursor_ = j; speech_(browserSpeech()); return;
        }
    }
}
void FxNavigator::browserMoveFx(int direction) {
    if (!direction || entries_.empty()) return;
    const int srcIndex = browserVisibleIndex();
    const int targetIndex = srcIndex + direction;
    if (targetIndex < 0 || targetIndex >= static_cast<int>(entries_.size())) return;
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
        if (!selectFx(newActive)) {end();return;}
        browserCursor_=newCursor;
        speech_("FX moved. " + browserSpeech());
        return;
    }
    // REAPER replaced the instance rather than moving it. Do not guess.
    end();
}
void FxNavigator::browserKey(const Key& k) {
    if (k.vk==VK_SPACE && !k.shift && !k.alt) {
        if(!k.repeat) Main_OnCommand(k.ctrl ? 40073 : 40044, 0);
        return;
    }
    if (k.repeat && (k.vk==VK_RETURN || k.vk=='P' || k.vk=='B' || k.vk==VK_ESCAPE))return;
    if (k.ctrl && !k.shift && !k.alt) {
        if (k.vk=='P') {browserSelect();return;}
        if (k.vk==VK_HOME||k.vk==VK_END) {browserMove(k.vk==VK_HOME?-100000:100000);return;}
        if (k.vk=='B') {
            const int selected = browserVisibleIndex();
            if (selected != browserIndex_ && !selectFx(selected))return;
            toggleBypass();speech_(browserSpeech());return;
        }
        if (k.vk=='W') {returnToTrackFx();return;}
        if (k.vk==VK_LEFT || k.vk==VK_RIGHT) {switchItem(k.vk==VK_LEFT?-1:1);return;}
    }
    if (k.alt && k.shift && !k.ctrl && k.vk=='F') {openNativeFxBrowser();return;}
    if (k.ctrl && k.shift && !k.alt) {
        if (k.vk=='F') {openCurrentFxChain();return;}
        if (k.vk==VK_UP||k.vk==VK_DOWN) {browserMoveFx(k.vk==VK_UP?-1:1);return;}
        if (k.vk=='D') {
            const int selected = browserVisibleIndex();
            if (selected != browserIndex_ && !selectFx(selected))return;
            toggleDeltaSolo();return;
        }
    }
    if (k.vk==VK_ESCAPE) {end();return;}
    if (!k.ctrl && !k.alt) {
        if (k.vk==VK_RETURN) {browserSelect();return;}
        if (k.vk==VK_TAB) {speech_(browserSpeech());return;}
        if (k.vk==VK_UP||k.vk==VK_DOWN) {browserMove(k.vk==VK_UP?-1:1);return;}
        if (k.vk==VK_PRIOR||k.vk==VK_NEXT) {browserMove(k.vk==VK_PRIOR?-5:5);return;}
        if (k.vk==VK_HOME||k.vk==VK_END) {browserMove(k.vk==VK_HOME?-100000:100000);return;}
        if ((k.vk==VK_LEFT||k.vk==VK_RIGHT) && track_==GetMasterTrack(project_)) {
            const bool wantMonitor = k.vk==VK_RIGHT;
            const int selected = browserVisibleIndex();
            if (((entries_[static_cast<size_t>(selected)].index & 0x1000000) != 0) == wantMonitor)return;
            int oldOrdinal=0;
            for (int i=0;i<=selected;++i)
                if (((entries_[static_cast<size_t>(i)].index & 0x1000000) != 0) != wantMonitor) ++oldOrdinal;
            std::vector<int> column;
            for (int i=0;i<static_cast<int>(entries_.size());++i)
                if (((entries_[static_cast<size_t>(i)].index & 0x1000000) != 0) == wantMonitor) column.push_back(i);
            if (!column.empty()) {
                browserCursor_ = column[static_cast<size_t>(std::clamp(oldOrdinal-1, 0, static_cast<int>(column.size())-1))];
                speech_(browserSpeech());
            }
            return;
        }
        if (k.character) browserCycleByInitial(k.character, k.shift);
    } else if (k.altGr && k.character) browserCycleByInitial(k.character, k.shift);
}
} // namespace lrp
