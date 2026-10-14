#include "lrp/FxNavigator.h"
#include <algorithm>
#include <cmath>
#include <cstring>
#include <cctype>
#include <utility>
#include <stdexcept>

namespace lrp {
namespace {
bool same(const GUID* a, const GUID& b) { return a && std::memcmp(a, &b, sizeof(GUID)) == 0; }
}
// Startup context follows the original Lua's track/item selection rather than
// requiring GetTouchedOrFocusedFX, which is often empty when FX Params is invoked.
bool FxNavigator::begin() {
    end();
    project_ = EnumProjects(-1, nullptr, 0);
    if (!project_) { speech_("No REAPER project"); return false; }
    track_ = nullptr; take_ = nullptr;
    MediaTrack* master = GetMasterTrack(project_);
    const bool masterSelected = master && GetMediaTrackInfo_Value(master, "I_SELECTED") > 0.5;
    // An already visible FX chain wins over cursor context (as in the Lua).
    if (masterSelected && (TrackFX_GetChainVisible(master) >= 0 || TrackFX_GetRecChainVisible(master) >= 0)) {
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
            if (!take_) { speech_("No take FX on selected item"); return false; }
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
            if (!track_) { speech_("No take FX on selected item"); return false; }
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
        speech_("Select a track with FX or an item with take FX"); return false;
    }
    const auto* trackGuid = GetTrackGUID(track_);
    if (!trackGuid) return false;
    trackGuid_ = *trackGuid;

    const int regularCount = take_ ? TakeFX_GetCount(take_) : TrackFX_GetCount(track_);
    const int monitorCount = !take_ && track_ == master ? TrackFX_GetRecCount(track_) : 0;
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
    if (entries_.empty()) { speech_("No FX on selected track or take"); return false; }

    // Put the browser cursor on REAPER's visible-chain selection when possible.
    int visible = -1;
    if (take_) visible = TakeFX_GetChainVisible(take_);
    else {
        if (track_ == master && TrackFX_GetRecChainVisible(track_) >= 0)
            visible = 0x1000000 + TrackFX_GetRecChainVisible(track_);
        else visible = TrackFX_GetChainVisible(track_);
    }
    for (size_t i = 0; i < entries_.size(); ++i)
        if (entries_[i].index == visible) { browserIndex_ = static_cast<int>(i); break; }

    active_ = true;
    browserMode_ = entries_.size() > 1;
    searchMode_ = false; search_.clear();
    valueMode_ = false; stepScale_ = 0; columns_ = 10;
    if (browserMode_) return true;
    if (!selectFx(0)) { end(); return false; }
    return true;
}
void FxNavigator::browserAnnounce() {
    if (entries_.empty()) return;
    speech_(std::to_string(browserIndex_ + 1) + " of " + std::to_string(entries_.size()) + ", " + entries_[browserIndex_].name);
}
void FxNavigator::browserMove(int delta) {
    const int index = std::clamp(browserIndex_ + delta, 0, static_cast<int>(entries_.size()) - 1);
    if (index != browserIndex_) { browserIndex_ = index; browserAnnounce(); }
}
bool FxNavigator::selectFx(int index) {
    if (index < 0 || index >= static_cast<int>(entries_.size())) return false;
    const auto& candidate = entries_[index];
    const GUID* guid = take_ ? TakeFX_GetFXGUID(take_, candidate.index) : TrackFX_GetFXGUID(track_, candidate.index);
    if (!same(guid, candidate.guid)) { speech_("FX list changed. Reopen FX Params"); end(); return false; }
    const int num = take_ ? TakeFX_GetNumParams(take_, candidate.index) : TrackFX_GetNumParams(track_, candidate.index);
    if (num <= 0) { speech_("This FX has no parameters. Choose another FX."); return false; }
    fx_ = candidate.index; fxGuid_ = candidate.guid;
    count_ = num; parameter_ = 0;
    parameterName_ = parameterName();
    hadUi_ = take_ ? TakeFX_GetOpen(take_, fx_) : TrackFX_GetOpen(track_, fx_);
    browserMode_ = false;
    valueMode_ = false; searchMode_ = false; search_.clear();
    return true;
}
int FxNavigator::count() const { return take_ ? TakeFX_GetNumParams(take_, fx_) : TrackFX_GetNumParams(track_, fx_); }
std::string FxNavigator::parameterName() const {
    char name[4096]{};
    bool ok = take_ ? TakeFX_GetParamName(take_, fx_, parameter_, name, sizeof(name)) : TrackFX_GetParamName(track_, fx_, parameter_, name, sizeof(name));
    return ok ? name : "";
}
bool FxNavigator::valid() const {
    if (!active_ || EnumProjects(-1, nullptr, 0) != project_ || !ValidatePtr2(project_, track_, "MediaTrack*")) return false;
    if (!same(GetTrackGUID(track_), trackGuid_)) return false;
    if (take_ && (!ValidatePtr2(project_, take_, "MediaItem_Take*") || GetMediaItemTake_Track(take_) != track_)) return false;
    if (browserMode_) return true;
    const auto* g = take_ ? TakeFX_GetFXGUID(take_, fx_) : TrackFX_GetFXGUID(track_, fx_);
    if (!same(g, fxGuid_)) return false;
    if (count() != count_ || parameter_ < 0 || parameter_ >= count_) return false;
    return parameterName() == parameterName_;
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
    return valid() && !browserMode_ ? (take_ ? TakeFX_GetFloatingWindow(take_, fx_) : TrackFX_GetFloatingWindow(track_, fx_)) : nullptr;
}
bool FxNavigator::uiStillOpen() const {
    if (!valid()) return false;
    return browserMode_ || !hadUi_ || (take_ ? TakeFX_GetOpen(take_, fx_) : TrackFX_GetOpen(track_, fx_));
}
bool FxNavigator::accepts(const Key& k) const noexcept {
    if (!active_) return false;
    // Restore TEST3's F1/F2 grid height controls. F12 remains OSARA's.
    if (browserMode_) {
        if (k.alt || k.ctrl || k.shift) return false;
        return k.vk == VK_ESCAPE || k.vk == VK_RETURN || k.vk == VK_TAB ||
            k.vk == VK_UP || k.vk == VK_DOWN || k.vk == VK_LEFT || k.vk == VK_RIGHT ||
            k.vk == VK_HOME || k.vk == VK_END || k.vk == VK_PRIOR || k.vk == VK_NEXT ||
            (k.vk >= 'A' && k.vk <= 'Z');
    }
    if (k.alt && !k.ctrl && !k.shift && k.vk == 'B') return entries_.size() > 1;
    if (k.ctrl && !k.alt && !k.shift && k.vk == 'F') return true;
    if (k.ctrl && !k.alt && !k.shift && (k.vk == VK_HOME || k.vk == VK_END)) return true;
    if (searchMode_) {
        if (k.alt || k.ctrl) return false;
        return k.vk == VK_ESCAPE || k.vk == VK_RETURN || k.vk == VK_BACK ||
            k.vk == VK_UP || k.vk == VK_DOWN || (k.vk >= 'A' && k.vk <= 'Z') ||
            (k.vk >= '0' && k.vk <= '9') || k.vk == VK_SPACE;
    }
    if (k.ctrl || k.shift) return false;
    if (k.alt) return k.vk == VK_UP || k.vk == VK_DOWN || k.vk == VK_PRIOR || k.vk == VK_NEXT || k.vk == VK_LEFT || k.vk == VK_RIGHT;
    return k.vk == VK_ESCAPE || k.vk == VK_RETURN || k.vk == VK_TAB || k.vk == VK_LEFT || k.vk == VK_RIGHT ||
        k.vk == VK_UP || k.vk == VK_DOWN || k.vk == VK_F1 || k.vk == VK_F2 ||
        k.vk == VK_HOME || k.vk == VK_END || k.vk == VK_PRIOR || k.vk == VK_NEXT;
}
std::string FxNavigator::currentParameterSpeech() const {
    if (!valid()) throw std::runtime_error("FX context changed");
    char text[4096]{};
    const bool ok = take_ ? TakeFX_GetFormattedParamValue(take_, fx_, parameter_, text, sizeof(text)) : TrackFX_GetFormattedParamValue(track_, fx_, parameter_, text, sizeof(text));
    const double v = take_ ? TakeFX_GetParamNormalized(take_, fx_, parameter_) : TrackFX_GetParamNormalized(track_, fx_, parameter_);
    return parameterName_ + ", " + (ok && text[0] ? std::string(text) : std::to_string(v));
}
void FxNavigator::announce() {
    speech_(currentParameterSpeech());
}
void FxNavigator::announceTitle() {
    if (!active_) return;
    if (browserMode_) {
        speech_("LReaParams - FX Params - FX browser. " +
                std::to_string(browserIndex_ + 1) + " of " + std::to_string(entries_.size()) +
                ", " + entries_[browserIndex_].name);
    } else {
        speech_("LReaParams - FX Params - " +
                std::string(valueMode_ ? "Value" : "Grid") + ". " +
                entries_[browserIndex_].name + ". " + currentParameterSpeech());
    }
}
std::wstring FxNavigator::windowTitle() const {
    if (!active_) return L"LReaParams - FX Params";
    if (browserMode_) return L"LReaParams - FX Params - FX Browser";
    if (searchMode_) return L"LReaParams - FX Params - Find Parameter";
    return valueMode_ ? L"LReaParams - FX Params - Value" : L"LReaParams - FX Params - Grid";
}
std::string FxNavigator::reviewLine() const {
    if (!active_) return "";
    if (browserMode_) {
        if (entries_.empty()) return "No FX";
        return "FX " + std::to_string(browserIndex_ + 1) + " of " +
            std::to_string(entries_.size()) + ", " + entries_[browserIndex_].name;
    }
    // The line remains about the actual parameter even while its search mode
    // or the parameter Value mode is active.
    return entries_[browserIndex_].name + ", " + currentParameterSpeech();
}
void FxNavigator::navigate(int delta) {
    const int next = std::clamp(parameter_ + delta, 0, count_ - 1);
    if (next == parameter_) return;
    parameter_ = next; parameterName_ = parameterName(); announce();
}
void FxNavigator::setValue(double value) {
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
    announce();
}
void FxNavigator::nudge(int direction, bool big) {
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
}
void FxNavigator::findMatching(bool forward) {
    if (search_.empty()) { speech_("Search is empty"); return; }
    const std::string needle = lowerAscii(search_);
    for (int offset = 1; offset <= count_; ++offset) {
        const int index = (parameter_ + (forward ? offset : -offset) + count_ * 2) % count_;
        char name[4096]{};
        const bool ok = take_ ? TakeFX_GetParamName(take_, fx_, index, name, sizeof(name)) :
            TrackFX_GetParamName(track_, fx_, index, name, sizeof(name));
        if (ok && lowerAscii(name).find(needle) != std::string::npos) {
            parameter_ = index; parameterName_ = name;
            speech_("Match " + std::to_string(parameter_ + 1) + ", " + parameterName_);
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
    if (browserMode_) {
        if (k.vk == VK_ESCAPE) { end(); return; }
        if (k.vk == VK_RETURN) {
            if (!k.repeat && selectFx(browserIndex_)) {
                speech_("LReaParams - FX Params - Grid. " +
                        entries_[browserIndex_].name + ". " + currentParameterSpeech());
            }
            return;
        }
        if (k.vk == VK_TAB) { browserAnnounce(); return; }
        if (k.vk == VK_HOME) { browserIndex_ = 0; browserAnnounce(); return; }
        if (k.vk == VK_END) { browserIndex_ = static_cast<int>(entries_.size()) - 1; browserAnnounce(); return; }
        if (k.vk == VK_DOWN || k.vk == VK_RIGHT) { browserMove(1); return; }
        if (k.vk == VK_UP || k.vk == VK_LEFT) { browserMove(-1); return; }
        if (k.vk == VK_NEXT) { browserMove(10); return; }
        if (k.vk == VK_PRIOR) { browserMove(-10); return; }
        if (k.vk >= 'A' && k.vk <= 'Z') {
            for (int offset = 1; offset <= static_cast<int>(entries_.size()); ++offset) {
                int index = (browserIndex_ + offset) % static_cast<int>(entries_.size());
                std::string name = entries_[index].name;
                const auto colon = name.find(": ");
                if (colon != std::string::npos) name.erase(0, colon + 2);
                while (name.size() && name.front() == ' ') name.erase(name.begin());
                // Strip common FX type prefixes (VST3i:, VST:, JS:).
                const auto typeEnd = name.find(':');
                if (typeEnd != std::string::npos && typeEnd < 6) name.erase(0, typeEnd + 1);
                while (name.size() && name.front() == ' ') name.erase(name.begin());
                if (name.size() && std::toupper(static_cast<unsigned char>(name.front())) == static_cast<int>(k.vk)) {
                    browserIndex_ = index; browserAnnounce(); break;
                }
            }
        }
        return;
    }
    if (k.alt && k.vk == 'B' && entries_.size() > 1) {
        browserMode_ = true; valueMode_ = false; searchMode_ = false;
        speech_("LReaParams - FX Params - FX browser. " +
                std::to_string(browserIndex_ + 1) + " of " + std::to_string(entries_.size()) +
                ", " + entries_[browserIndex_].name); return;
    }
    if (k.ctrl && k.vk == 'F') {
        if (!k.repeat) { searchMode_ = !searchMode_; search_.clear(); speech_(searchMode_ ? "LReaParams - FX Params - Find parameter. Type letters or digits, Up or Down next match, Enter accept, Escape cancel." : "Find cancelled"); }
        return;
    }
    if (searchMode_) {
        if (k.vk == VK_ESCAPE) { searchMode_ = false; search_.clear(); speech_("Find cancelled"); }
        else if (k.vk == VK_RETURN) { searchMode_ = false; search_.clear(); announce(); }
        else if (k.vk == VK_UP || k.vk == VK_DOWN) findMatching(k.vk == VK_DOWN);
        else if (k.vk == VK_BACK) { if (!search_.empty()) search_.pop_back(); searchPreview(); }
        else if (search_.size() < 64) {
            if (k.vk >= 'A' && k.vk <= 'Z') search_.push_back(static_cast<char>(k.vk));
            else if (k.vk >= '0' && k.vk <= '9') search_.push_back(static_cast<char>(k.vk));
            else if (k.vk == VK_SPACE) search_.push_back(' ');
            searchPreview();
        }
        return;
    }
    if (k.ctrl && !k.alt && !k.shift && k.vk == VK_HOME) { navigate(-parameter_); return; }
    if (k.ctrl && !k.alt && !k.shift && k.vk == VK_END) { navigate(count_ - parameter_ - 1); return; }
    if (k.vk == VK_ESCAPE) { if (valueMode_) { valueMode_ = false; speech_("LReaParams - FX Params - Grid"); } else end(); return; }
    if (k.vk == VK_RETURN) { if (k.repeat) return; valueMode_ = !valueMode_; speech_(valueMode_ ? "LReaParams - FX Params - Value" : "LReaParams - FX Params - Grid"); return; }
    if (k.vk == VK_TAB) { announce(); return; }
    if (!valueMode_ && k.vk == VK_HOME) { navigate(-parameter_); return; }
    if (!valueMode_ && k.vk == VK_END) { navigate(count_ - parameter_ - 1); return; }
    if (!valueMode_ && k.vk == VK_PRIOR) { navigate(-columns_); return; }
    if (!valueMode_ && k.vk == VK_NEXT) { navigate(columns_); return; }
    if (k.vk == VK_F1 || k.vk == VK_F2) {
        columns_ = std::clamp(columns_ + (k.vk == VK_F1 ? -1 : 1), 1, 200);
        speech_("Grid " + std::to_string(columns_)); return;
    }
    if (k.alt || valueMode_) {
        if (k.vk == VK_LEFT || k.vk == VK_RIGHT) {
            stepScale_ = std::clamp(stepScale_ + (k.vk == VK_LEFT ? -1 : 1), -6, 6);
            speech_("Test step scale " + std::to_string(stepScale_));
        } else if (k.vk == VK_HOME) setValue(0);
        else if (k.vk == VK_END) setValue(1);
        else nudge(k.vk == VK_UP || k.vk == VK_PRIOR ? 1 : -1, k.vk == VK_PRIOR || k.vk == VK_NEXT);
        return;
    }
    // Lua grid_size is the height of a column, not a row width.
    const int start = (parameter_ / columns_) * columns_;
    const int end = std::min(count_ - 1, start + columns_ - 1);
    if (k.vk == VK_LEFT && start >= columns_) navigate(-columns_);
    else if (k.vk == VK_RIGHT && start + columns_ < count_) navigate(columns_);
    else if (k.vk == VK_UP && parameter_ > start) navigate(-1);
    else if (k.vk == VK_DOWN && parameter_ < end) navigate(1);
}
}
