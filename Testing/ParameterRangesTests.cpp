#include "lrp/ParameterRanges.h"
#include <cassert>
#include <cmath>
#include <iostream>
using namespace lrp;
static bool near(double a, double b) { return std::abs(a-b) < 1e-11; }
int main() {
    ParameterRange r{};
    assert(parseParameterRange("30,110",r,0,127,true));
    assert(near(r.minimum,30) && near(r.maximum,110));
    assert(near(scaleCcFraction(0,r),30.0/127.0));
    assert(near(scaleCcFraction(127,r),110.0/127.0));
    assert(near(scaleCcFraction(64,r),(30.0+80.0*64.0/127.0)/127.0));
    assert(near(ccPickupTarget(110.0/127.0,r),1));
    assert(near(ccPickupTarget(30.0/127.0,r),0));
    assert(!parseParameterRange("110,30",r,0,127,true));
    assert(!parseParameterRange("-1,127",r,0,127,true));
    assert(!parseParameterRange("31.5,110",r,0,127,true));
    assert(!parseParameterRange("0,0",r,0,127,true));
    assert(!parseParameterRange("NaN,100",r,0,127));
    assert(parseParameterRange("-60,0",r,-150,48));
    assert(near(r.clamp(-90),-60) && near(r.clamp(12),0));
    floatingCcSessionRange() = {15,99};
    assert(floatingCcSessionRange().minimum == 15 && floatingCcSessionRange().maximum == 99);
    std::cout << "ParameterRanges unit tests PASS\n";
}
