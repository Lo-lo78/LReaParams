#include "lrp/UsedParameters.h"
#include <cassert>
#include <string>
int main() {
    lrp::used::State s; s.count=128;
    assert(lrp::used::add(s,74));
    assert(lrp::used::add(s,11));
    assert(!lrp::used::add(s,74));
    assert(!lrp::used::add(s,128));
    assert(s.ids.size()==2 && s.ids[0]==74 && s.ids[1]==11);
    s.columns=17;s.keyboard=true;s.selected=11;
    lrp::used::State restored;
    assert(lrp::used::decode(lrp::used::encode(s),128,restored));
    assert(restored.ids==s.ids && restored.columns==17 && restored.keyboard && restored.selected==11);
    assert(!lrp::used::decode(lrp::used::encode(s),129,restored)); // Changed plugin layout.
    assert(!lrp::used::decode("U1;128;17;1;11;74,74",128,restored));
    assert(!lrp::used::decode("U1;128;17;1;11;74,1200",128,restored));
    assert(!lrp::used::decode("U1;128;401;1;11;74",128,restored));
    assert(!lrp::used::decode("U1;128;17;1;11;74,",128,restored));
    assert(lrp::used::erase(s,74));
    assert(!lrp::used::erase(s,74));
    assert(lrp::used::add(s,74)); // Removed parameter rejoins at the end.
    assert(s.ids.size()==2 && s.ids[0]==11 && s.ids[1]==74);
    const std::string serialized=lrp::used::encode(s);
    assert(lrp::used::decode(serialized,128,restored));
    return 0;
}
