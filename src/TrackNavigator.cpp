#include "lrp/TrackNavigator.h"
#include <algorithm>
#include <cmath>
#include <cstring>
#include <stdexcept>
#include <sstream>
#include <iomanip>

namespace lrp {
namespace {
constexpr double minDb = -150.0, maxDb = 48.0;
double db(double amplitude) { return amplitude <= 0 ? minDb : 20.0 * std::log10(amplitude); }
double amp(double decibels) { return decibels <= minDb ? 0.0 : std::pow(10.0, decibels / 20.0); }
std::string num(double v, int places=1) {
    std::ostringstream o; o << std::fixed << std::setprecision(places) << v; return o.str();
}
}
bool TrackNavigator::begin() {
    end(); entries_.clear();
    project_ = EnumProjects(-1, nullptr, 0);
    track_ = GetSelectedTrack2(project_, 0, true);
    if (!track_ || !ValidatePtr2(project_, track_, "MediaTrack*")) {
        speech_("Track Params: select a track first"); return false;
    }
    const GUID* g = GetTrackGUID(track_); if (!g) return false;
    guid_ = *g;
    entries_ = {
        {"Volume", "D_VOL", 99, -1, Entry::volume},
        {"Pan", "D_PAN", 99, -1, Entry::pan},
        {"Width", "D_WIDTH", 99, -1, Entry::width},
        {"Mute", "B_MUTE", 99, -1, Entry::flag},
        {"Solo", "I_SOLO", 99, -1, Entry::solo},
        {"Record arm", "I_RECARM", 99, -1, Entry::flag},
        {"Phase invert", "B_PHASE", 99, -1, Entry::flag},
        {"FX enabled", "I_FXEN", 99, -1, Entry::flag}
    };
    sends_ = std::clamp(GetTrackNumSends(track_, 0), 0, 512);
    receives_ = std::clamp(GetTrackNumSends(track_, -1), 0, 512);
    for (int category : {0, -1}) {
        const int count = category == 0 ? sends_ : receives_;
        for (int i = 0; i < count; ++i) {
            const std::string prefix = std::string(category == 0 ? "Send " : "Receive ") + std::to_string(i + 1) + " ";
            entries_.push_back({prefix + "volume", "D_VOL", category, i, Entry::volume});
            entries_.push_back({prefix + "pan", "D_PAN", category, i, Entry::pan});
            entries_.push_back({prefix + "mute", "B_MUTE", category, i, Entry::flag});
        }
    }
    parameter_ = 0; active_ = true; valueMode_ = false;
    char name[2048]{}; GetTrackName(track_, name, sizeof(name));
    speech_(std::string("Track Params. Native basic controls. ") + name);
    announce(); return true;
}
bool TrackNavigator::contextUnchanged() const {
    if (!active_ || EnumProjects(-1, nullptr, 0) != project_ || !ValidatePtr2(project_, track_, "MediaTrack*")) return false;
    const auto* g = GetTrackGUID(track_);
    if (!g || std::memcmp(g, &guid_, sizeof(GUID)) != 0) return false;
    if (GetSelectedTrack2(project_, 0, true) != track_) return false;
    return GetTrackNumSends(track_, 0) == sends_ && GetTrackNumSends(track_, -1) == receives_;
}
bool TrackNavigator::accepts(const Key& k) const noexcept {
    if (!active_ || k.ctrl || k.shift) return false;
    if (k.alt) return k.vk == VK_UP || k.vk == VK_DOWN || k.vk == VK_PRIOR || k.vk == VK_NEXT;
    switch (k.vk) {
        case VK_ESCAPE: case VK_RETURN: case VK_TAB: case VK_UP: case VK_DOWN:
        case VK_LEFT: case VK_RIGHT: case VK_HOME: case VK_END:
        case VK_PRIOR: case VK_NEXT: return true;
        default: return false;
    }
}
double TrackNavigator::get(const Entry& e) const {
    return e.index < 0 ? GetMediaTrackInfo_Value(track_, e.parm.c_str()) :
        GetTrackSendInfo_Value(track_, e.category, e.index, e.parm.c_str());
}
void TrackNavigator::put(const Entry& e, double value) {
    if (!contextUnchanged() || !std::isfinite(value)) throw std::runtime_error("Track context changed");
    const double before = get(e); if (before == value) return;
    struct UndoScope {
        ReaProject* project;
        explicit UndoScope(ReaProject* p) : project(p) { Undo_BeginBlock2(p); }
        ~UndoScope() { Undo_EndBlock2(project, "LReaParams: track control", UNDO_STATE_TRACKCFG); }
    } undo(project_);
    const bool ok = e.index < 0 ? SetMediaTrackInfo_Value(track_, e.parm.c_str(), value) :
        SetTrackSendInfo_Value(track_, e.category, e.index, e.parm.c_str(), value);
    if (!ok) throw std::runtime_error("REAPER refused track change");
    announce();
}
std::string TrackNavigator::valueText(const Entry& e, double value) {
    if (e.type == Entry::flag) return value > 0.5 ? "on" : "off";
    if (e.type == Entry::solo) return value >= 0.5 ? "solo " + std::to_string(static_cast<int>(value)) : "off";
    if (e.type == Entry::volume) return value <= 0 ? "minus infinity dB" : num(db(value)) + " dB";
    if (e.type == Entry::pan) return std::abs(value) < 0.00001 ? "center" : num(std::abs(value) * 100.0, 0) + (value < 0 ? " percent left" : " percent right");
    return num(value * 100.0, 0) + " percent";
}
void TrackNavigator::announce() {
    if (!contextUnchanged()) throw std::runtime_error("Track context changed");
    const auto& e = entries_.at(static_cast<std::size_t>(parameter_));
    speech_(e.title + ", " + valueText(e, get(e)));
}
void TrackNavigator::move(int delta) {
    const int next = std::clamp(parameter_ + delta, 0, static_cast<int>(entries_.size()) - 1);
    if (next != parameter_) { parameter_ = next; announce(); }
}
void TrackNavigator::nudge(int direction, bool coarse) {
    const auto& e = entries_.at(static_cast<std::size_t>(parameter_));
    const double old = get(e);
    double next = old;
    switch (e.type) {
        case Entry::volume: next = amp(std::clamp(db(old) + (coarse ? 3.0 : 0.5) * direction, minDb, maxDb)); break;
        case Entry::pan: case Entry::width: next = std::clamp(old + direction * (coarse ? 0.1 : 0.01), -1.0, 1.0); break;
        case Entry::flag: case Entry::solo: next = direction > 0 ? 1 : 0; break;
    }
    put(e, next);
}
void TrackNavigator::handle(const Key& k) {
    if (!contextUnchanged()) throw std::runtime_error("Track context changed");
    if (k.vk == VK_ESCAPE) {
        if (valueMode_) { valueMode_ = false; speech_("Track grid"); }
        else end();
        return;
    }
    if (k.vk == VK_RETURN) {
        if (!k.repeat) { valueMode_ = !valueMode_; speech_(valueMode_ ? "Track value" : "Track grid"); }
        return;
    }
    if (k.vk == VK_TAB) { announce(); return; }
    if (k.alt || valueMode_) {
        if (k.vk == VK_UP || k.vk == VK_DOWN || k.vk == VK_PRIOR || k.vk == VK_NEXT)
            nudge(k.vk == VK_UP || k.vk == VK_PRIOR ? 1 : -1, k.vk == VK_PRIOR || k.vk == VK_NEXT);
        else if (valueMode_ && (k.vk == VK_HOME || k.vk == VK_END)) {
            const auto& e = entries_.at(static_cast<std::size_t>(parameter_));
            const double value = k.vk == VK_HOME ? (e.type == Entry::pan || e.type == Entry::width ? -1.0 : 0.0) : 1.0;
            put(e, value);
        }
        return;
    }
    if (k.vk == VK_HOME) { parameter_ = 0; announce(); }
    else if (k.vk == VK_END) { parameter_ = static_cast<int>(entries_.size()) - 1; announce(); }
    else if (k.vk == VK_PRIOR) move(-columnHeight_);
    else if (k.vk == VK_NEXT) move(columnHeight_);
    else if (k.vk == VK_UP) move(-1);
    else if (k.vk == VK_DOWN) move(1);
    else if (k.vk == VK_LEFT) move(-columnHeight_);
    else if (k.vk == VK_RIGHT) move(columnHeight_);
}
}
