#pragma once
#include <algorithm>
#include <cmath>
#include <optional>

namespace lrp {
// Pure state machine: no REAPER, Windows, files or audio-thread callbacks.
struct MidiCc { int channel{}, number{}, value{}; };
inline std::optional<MidiCc> decodeCc(const unsigned char* data, int size) {
    if(size<3 || (data[0]&0xf0)!=0xb0 || data[1]>127 || data[2]>127)return {};
    return MidiCc{(data[0]&15)+1,data[1],data[2]};
}
struct Pickup {
    bool initialized=false, waiting=true;
    double target=0, previous=-1, lastApplied=0;
    int accepted=-1, candidate=-1, repeats=0;
    void reset() { *this=Pickup{}; }
    bool allows(int midi, double current) {
        const double v=midi/127.0;
        if(!initialized || (!waiting && std::abs(current-lastApplied)>0.0005)) {
            initialized=true;waiting=true;target=current;previous=-1;
            accepted=candidate=-1;repeats=0;
        }
        const double old=previous;previous=v;
        if(waiting) {
            if(std::abs(v-target)>1.0/127.0 &&
               !(old>=0 && ((old<target && v>=target)||(old>target && v<=target))))return false;
            waiting=false;
        }
        // Lua anti-jitter: jumps >=3 pass; +/-1 needs 3 repeats, +/-2 needs 2.
        if(accepted<0) {accepted=midi;return true;}
        int diff=std::abs(midi-accepted);
        if(diff==0){candidate=-1;repeats=0;return false;}
        if(diff>=3){accepted=midi;candidate=-1;repeats=0;return true;}
        if(candidate==midi)++repeats;else {candidate=midi;repeats=1;}
        if(repeats<(diff<=1?3:2))return false;
        accepted=midi;candidate=-1;repeats=0;return true;
    }
    void applied(double value) {lastApplied=value;}
};
}
