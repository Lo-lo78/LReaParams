#include "lrp/ParameterStepSizing.h"
#include <cassert>
#include <cmath>
#include <iostream>

int main() {
    using lrp::parameter_step::amount;
    auto near = [](double x, double y) { return std::abs(x-y) < 1e-12; };
    assert(near(amount(false,0,0,false,0), 0.001));
    assert(near(amount(false,0,0,true,0), 0.01));
    // Regression: a host's 'large' can be 1/16th of its normal step.
    assert(near(amount(true,0.04,0.0025,false,0), 0.04));
    assert(near(amount(true,0.04,0.0025,true,0), 0.4));
    assert(near(amount(true,0.04,0.0025,true,2), 1.6));
    assert(near(amount(true,0.04,0.0025,false,2), 0.16));
    assert(near(amount(true,0.04,0.0025,true,-4), 0.025));
    assert(near(amount(true,0.04,0.0025,false,-4), 0.0025));
    // A correctly reported larger step remains authoritative.
    assert(near(amount(true,0.01,0.05,true,0), 0.05));
    assert(near(amount(true,0.01,0.05,false,0), 0.01));
    // Same steps: choose a useful coarse step.
    assert(near(amount(true,0.03,0.03,true,0), 0.3));
    assert(near(amount(true,0.5,0.2,true,0), 1.0));
    // Missing or invalid host step sizes keep safe legacy fallbacks.
    assert(near(amount(true,0.0,0.0,true,0),0.01));
    assert(near(amount(true,NAN,-1,true,0),0.01));
    assert(near(amount(true,2,2,false,0),0.001));
    assert(near(amount(true,2,2,true,0),0.01));
    std::cout << "TEST64.3 calibrated Page/arrow steps PASS\n";
}
