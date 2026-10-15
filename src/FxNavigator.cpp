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

    // Select the visible FX if any, else start at the first FX.
    browserIndex_ = 0;
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
    searchMode_ = false; search_.clear();
    valueMode_ = false; stepScale_ = 0; columns_ = 10;
    // Select the FX already highlighted in REAPER's visible chain. If it has
    // no parameters, try following FX (then preceding ones). No browser.
    const int preferred = browserIndex_;
    if (selectFx(preferred)) return true;
    for (int i = preferred + 1; i < static_cast<int>(entries_.size()); ++i)
        if (selectFx(i)) return true;
    for (int i = preferred - 1; i >= 0; --i)
        if (selectFx(i)) return true;
    speech_("No navigable FX parameters");
    end(); return false;
}
void FxNavigator::switchFx(int direction) {
    if (direction == 0) return;
    for (int i = browserIndex_ + direction; i >= 0 && i < static_cast<int>(entries_.size()); i += direction) {
        const int count = take_ ? TakeFX_GetNumParams(take_, entries_[i].index)
                                : TrackFX_GetNumParams(track_, entries_[i].index);
        if (count <= 0) continue;
        if (!selectFx(i)) return;
        speech_(entries_[browserIndex_].name + ". " + currentParameterSpeech());
        return;
    }
    // First/last FX is deliberately silent, like the edges of the grid.
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
    return context;
}
bool FxNavigator::selectFx(int index) {
    if (index < 0 || index >= static_cast<int>(entries_.size())) return false;
    const auto& candidate = entries_[index];
    const GUID* guid = take_ ? TakeFX_GetFXGUID(take_, candidate.index) : TrackFX_GetFXGUID(track_, candidate.index);
    if (!same(guid, candidate.guid)) { speech_("FX list changed. Reopen FX Params"); end(); return false; }
    const int num = take_ ? TakeFX_GetNumParams(take_, candidate.index) : TrackFX_GetNumParams(track_, candidate.index);
    if (num <= 0) return false;
    fx_ = candidate.index; fxGuid_ = candidate.guid;
    count_ = num; parameter_ = 0;
    parameterName_ = parameterName();
    hadUi_ = take_ ? TakeFX_GetOpen(take_, fx_) : TrackFX_GetOpen(track_, fx_);
    browserIndex_ = index;
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
    return valid() ? (take_ ? TakeFX_GetFloatingWindow(take_, fx_) : TrackFX_GetFloatingWindow(track_, fx_)) : nullptr;
}
bool FxNavigator::uiStillOpen() const {
    if (!valid()) return false;
    return !hadUi_ || (take_ ? TakeFX_GetOpen(take_, fx_) : TrackFX_GetOpen(track_, fx_));
}
bool FxNavigator::accepts(const Key& k) const noexcept {
    if (!active_ || k.shift) return false;
    if (k.ctrl) {
        if (k.alt) return false;
        return k.vk == VK_HOME || k.vk == VK_END ||
               k.vk == VK_UP || k.vk == VK_DOWN || k.vk == 'F';
    }
    if (searchMode_) {
        if (k.alt) return false;
        return k.vk == VK_ESCAPE || k.vk == VK_RETURN || k.vk == VK_BACK ||
            k.vk == VK_UP || k.vk == VK_DOWN || (k.vk >= 'A' && k.vk <= 'Z') ||
            (k.vk >= '0' && k.vk <= '9') || k.vk == VK_SPACE;
    }
    if (k.alt)
        return k.vk == VK_UP || k.vk == VK_DOWN ||
               k.vk == VK_PRIOR || k.vk == VK_NEXT ||
               k.vk == VK_LEFT || k.vk == VK_RIGHT ||
               k.vk == VK_HOME || k.vk == VK_END;
    // TAB remains unassigned for a future feature, never announces anything.
    return k.vk == VK_ESCAPE || k.vk == VK_RETURN ||
           k.vk == VK_LEFT || k.vk == VK_RIGHT || k.vk == VK_UP ||
           k.vk == VK_DOWN || k.vk == VK_F1 || k.vk == VK_F2 ||
           k.vk == VK_HOME || k.vk == VK_END ||
           k.vk == VK_PRIOR || k.vk == VK_NEXT;
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
    speech_("LReaParams - FX Params - " + entries_[browserIndex_].name +
            ", " + contextName() + ". " + currentParameterSpeech());
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
    if (!active_) return L"LReaParams - FX Params";
    const std::wstring mode = searchMode_ ? L"Find Parameter" : valueMode_ ? L"Value" : L"Grid";
    // NVDA+T: context in the window title; never in the NVDA+Up review line.
    return L"FX Parameters: " + wideUtf8(entries_[browserIndex_].name) +
           L", " + wideUtf8(contextName()) + L" - " + mode;
}
std::string FxNavigator::reviewLine() const {
    // NVDA+Up: ONLY the current parameter and its formatted value.
    return active_ ? currentParameterSpeech() : "";
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
    if (k.ctrl && !k.alt && !k.shift && (k.vk == VK_UP || k.vk == VK_DOWN)) {
        if (!k.repeat) switchFx(k.vk == VK_UP ? -1 : 1);
        return;
    }
    if (k.ctrl && k.vk == 'F') {
        if (!k.repeat) {
            searchMode_ = !searchMode_; search_.clear();
            speech_(searchMode_ ? "Find parameter. Type and use Up or Down; Enter accepts; Escape cancels." : "Find cancelled");
        }
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
    if (k.ctrl && k.vk == VK_HOME) { navigate(-parameter_); return; }
    if (k.ctrl && k.vk == VK_END) { navigate(count_ - 1 - parameter_); return; }
    if (k.vk == VK_ESCAPE) {
        if (valueMode_) { valueMode_ = false; speech_("FX Params - Grid"); }
        else end();
        return;
    }
    if (k.vk == VK_RETURN) {
        if (k.repeat) return;
        valueMode_ = !valueMode_;
        speech_(valueMode_ ? "FX Params - Value" : "FX Params - Grid");
        return;
    }
    if (k.vk == VK_F1 || k.vk == VK_F2) {
        const int next = std::clamp(columns_ + (k.vk == VK_F1 ? -1 : 1), 1, 200);
        if (next != columns_) { columns_ = next; speech_("Grid " + std::to_string(columns_)); }
        return;
    }
    // Alt+Home/End also work in Grid; plain Home/End in Value edit the value.
    if (k.alt || valueMode_) {
        if (k.vk == VK_LEFT || k.vk == VK_RIGHT) {
            const int next = std::clamp(stepScale_ + (k.vk == VK_LEFT ? -1 : 1), -6, 6);
            if (next != stepScale_) { stepScale_ = next; speech_("Step scale " + std::to_string(stepScale_)); }
        } else if (k.vk == VK_HOME) setValue(0);
        else if (k.vk == VK_END) setValue(1);
        else if (k.vk == VK_UP || k.vk == VK_DOWN || k.vk == VK_PRIOR || k.vk == VK_NEXT)
            nudge(k.vk == VK_UP || k.vk == VK_PRIOR ? 1 : -1, k.vk == VK_PRIOR || k.vk == VK_NEXT);
        return;
    }
    // Grid is column-major: each column contains 'columns_' vertical rows.
    const int start = (parameter_ / columns_) * columns_;
    const int end = std::min(count_ - 1, start + columns_ - 1);
    if (k.vk == VK_HOME) { navigate(start - parameter_); return; }
    if (k.vk == VK_END) { navigate(end - parameter_); return; }
    if (k.vk == VK_PRIOR || k.vk == VK_NEXT) {
        // Page Up/Down stays WITHIN the current column, including its short
        // final column; it never spills into the next column.
        const int step = k.vk == VK_PRIOR ? -5 : 5;
        const int target = std::clamp(parameter_ + step, start, end);
        navigate(target - parameter_); return;
    }
    if (k.vk == VK_LEFT || k.vk == VK_RIGHT) {
        const int target = parameter_ + (k.vk == VK_LEFT ? -columns_ : columns_);
        // A missing cell in a short final column is a silent boundary.
        if (target >= 0 && target < count_) navigate(target - parameter_);
        return;
    }
    if (k.vk == VK_UP && parameter_ > start) navigate(-1);
    else if (k.vk == VK_DOWN && parameter_ < end) navigate(1);
}
}
