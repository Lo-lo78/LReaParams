#pragma once

#include <algorithm>
#include <cmath>

namespace lrp::parameter_step {

// Step sizes come from the host FX. Some plugins report a "large" increment
// smaller than their normal increment (or zero). Page keys must never become
// finer than the arrows for the *same* user's Step -10..+10 setting.
// This helper is shared by Standard Value and Keyboard, without changing F7 bulk edit.
inline double amount(bool hostHasSteps, double normal, double large,
                     bool page, int userStepScale) noexcept {
    auto valid = [](double v) { return std::isfinite(v) && v > 0.0 && v <= 1.0; };
    const double arrow = hostHasSteps && valid(normal) ? normal : 0.001;
    // Respect a genuine larger host step. If it is missing, equal or smaller,
    // derive a coarse jump from the arrow's step (10x, capped to the range).
    const double pageStep = hostHasSteps && valid(large) && large > arrow
        ? large : std::min(1.0, arrow * 10.0);
    return (page ? pageStep : arrow) *
        std::pow(2.0, std::clamp(userStepScale, -10, 10));
}

} // namespace lrp::parameter_step
