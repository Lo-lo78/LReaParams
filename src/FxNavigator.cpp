#include "lrp/FxNavigator.h"
#include <algorithm>
#include <cmath>
#include <cstring>
#include <cctype>
#include <stdexcept>

namespace lrp {
namespace {
bool same(const GUID* a, const GUID& b) { return a && std::memcmp(a, &b, sizeof(GUID)) == 0; }
}
bool FxNavigator::begin() {
    end();
    int trackIndex = 0, itemIndex = -1, takeIndex = -1, flags = 0;
    // Focused FX first. A stale "still open" result is refused; touched FX is an explicit fallback.
    bool focused = GetTouchedOrFocusedFX(1, &trackIndex, &itemIndex, &takeIndex, &fx_, &flags) && !(flags & 1);
    int touchedParam = 0;
    if (!focused && !GetTouchedOrFocusedFX(0, &trackIndex, &itemIndex, &takeIndex, &fx_, &touchedParam)) {
        speech_("No focused or touched FX. Open an FX or touch a parameter first."); return false;
    }
    project_ = EnumProjects(-1, nullptr, 0);
    track_ = trackIndex < 0 ? GetMasterTrack(project_) : GetTrack(project_, trackIndex);
    if (!track_ || !ValidatePtr2(project_, track_, "MediaTrack*")) return false;
    take_ = nullptr;
    if (itemIndex >= 0) {
        auto* item = GetTrackMediaItem(track_, itemIndex);
        if (!item || !ValidatePtr2(project_, item, "MediaItem*")) return false;
        take_ = GetTake(item, takeIndex);
        if (!take_ || !ValidatePtr2(project_, take_, "MediaItem_Take*")) return false;
    }
    const auto* tg = GetTrackGUID(track_);
    const auto* fg = take_ ? TakeFX_GetFXGUID(take_, fx_) : TrackFX_GetFXGUID(track_, fx_);
    if (!tg || !fg) return false;
    trackGuid_ = *tg; fxGuid_ = *fg;
    count_ = count();
    if (count_ <= 0) { speech_("No FX parameters"); return false; }
    parameter_ = focused ? 0 : std::clamp(touchedParam, 0, count_ - 1);
    parameterName_ = parameterName();
    valueMode_ = false; searchMode_ = false; search_.clear(); stepScale_ = 0; columns_ = 10; active_ = true;
    hadUi_ = take_ ? TakeFX_GetOpen(take_, fx_) : TrackFX_GetOpen(track_, fx_);
    char name[2048]{};
    if (take_) TakeFX_GetFXName(take_, fx_, name, sizeof(name)); else TrackFX_GetFXName(track_, fx_, name, sizeof(name));
    speech_(std::string("FX Params. Phase zero. ") + name);
    announce(); return true;
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
    int tr = 0, item = -1, tk = -1, fx = -1, state = 0;
    if (!GetTouchedOrFocusedFX(1, &tr, &item, &tk, &fx, &state) || (state & 1)) return true;
    auto* track = tr < 0 ? GetMasterTrack(project_) : GetTrack(project_, tr);
    if (track != track_ || fx != fx_) return false;
    if (item < 0) return take_ == nullptr;
    auto* media = GetTrackMediaItem(track, item);
    return media && GetTake(media, tk) == take_;
}
HWND FxNavigator::floatingWindow() const {
    return valid() ? (take_ ? TakeFX_GetFloatingWindow(take_, fx_) : TrackFX_GetFloatingWindow(track_, fx_)) : nullptr;
}
bool FxNavigator::uiStillOpen() const {
    if (!valid()) return false;
    return !hadUi_ || (take_ ? TakeFX_GetOpen(take_, fx_) : TrackFX_GetOpen(track_, fx_));
}
bool FxNavigator::accepts(const Key& k) const noexcept {
    if (!active_) return false;
    if (k.ctrl && !k.alt && !k.shift && k.vk == 'F') return true;
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
void FxNavigator::announce() {
    if (!valid()) throw std::runtime_error("FX context changed");
    char text[4096]{};
    const bool ok = take_ ? TakeFX_GetFormattedParamValue(take_, fx_, parameter_, text, sizeof(text)) : TrackFX_GetFormattedParamValue(track_, fx_, parameter_, text, sizeof(text));
    const double v = take_ ? TakeFX_GetParamNormalized(take_, fx_, parameter_) : TrackFX_GetParamNormalized(track_, fx_, parameter_);
    speech_(parameterName_ + ", " + (ok && text[0] ? std::string(text) : std::to_string(v)));
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
    if (k.ctrl && k.vk == 'F') {
        if (!k.repeat) { searchMode_ = !searchMode_; search_.clear(); speech_(searchMode_ ? "Find parameter. Type letters or digits, Up or Down next match, Enter accept, Escape cancel." : "Find cancelled"); }
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
    if (k.vk == VK_ESCAPE) { if (valueMode_) { valueMode_ = false; speech_("Grid"); } else end(); return; }
    if (k.vk == VK_RETURN) { if (k.repeat) return; valueMode_ = !valueMode_; speech_(valueMode_ ? "Value" : "Grid"); return; }
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
