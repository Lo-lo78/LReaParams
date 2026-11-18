#pragma once
#include <algorithm>
#include <cmath>
#include <iomanip>
#include <limits>
#include <sstream>
#include <string>
#include <utility>

namespace lrp {
struct ParameterRange {
    double minimum{}, maximum{};
    double clamp(double value) const noexcept { return std::clamp(value, minimum, maximum); }
};
inline std::string rangeText(const ParameterRange& r) {
    std::ostringstream out;
    out << std::setprecision(12) << r.minimum << ',' << r.maximum;
    return out.str();
}
inline bool parseParameterRange(const std::string& text, ParameterRange& r,
                               double allowedMin, double allowedMax, bool integers = false) {
    const auto comma = text.find(',');
    if (comma == std::string::npos || text.find(',', comma + 1) != std::string::npos) return false;
    const auto left = text.substr(0, comma), right = text.substr(comma + 1);
    try {
        std::size_t a = 0, b = 0;
        const double low = std::stod(left, &a), high = std::stod(right, &b);
        if (a != left.size() || b != right.size() || !std::isfinite(low) || !std::isfinite(high) ||
            low < allowedMin || high > allowedMax || low >= high ||
            (integers && (std::trunc(low) != low || std::trunc(high) != high))) return false;
        r = {low, high};
        return true;
    } catch (...) { return false; }
}
// Convert the full physical 0..127 controller sweep to a configurable range,
// without affecting channel/CC-number identity or MIDI data persisted on disk.
inline double scaleCcFraction(int value, const ParameterRange& cc) noexcept {
    const double raw = std::clamp(value, 0, 127) / 127.0;
    return std::clamp((cc.minimum + (cc.maximum - cc.minimum) * raw) / 127.0, 0.0, 1.0);
}
// Shared by FX Params and Track Params for the lifetime of this REAPER DLL.
// No project, preset, profile, or memory-file persistence is permitted.
// Switching navigator must not forget the learned channel/controller or range.
struct FloatingCcSession {
    int channel = -1;
    int number = -1;
    bool enabled = false;
    ParameterRange range{0.0, 127.0};
    bool active() const noexcept {
        return enabled && channel >= 1 && channel <= 16 && number >= 0 && number <= 127;
    }
    void assign(int channelIn, int numberIn) noexcept {
        channel = channelIn;
        number = numberIn;
        enabled = true;
    }
};
inline FloatingCcSession& floatingCcSession() {
    static FloatingCcSession session;
    return session;
}
inline ParameterRange& floatingCcSessionRange() {
    return floatingCcSession().range;
}
inline double ccPickupTarget(double current, const ParameterRange& cc) {
    const double width = cc.maximum - cc.minimum;
    return width <= 0 ? current : std::clamp((current * 127.0 - cc.minimum) / width, 0.0, 1.0);
}
} // namespace lrp
