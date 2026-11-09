#include "lrp/TempoMapEngine.h"
#include <cassert>
#include <iostream>
#include <random>
#include <cmath>

static std::vector<float> makeSong(int scenario) {
    constexpr int sr=lrp::tempo::sampleRate;
    std::vector<float> pcm(sr*90);
    double time=1.35;
    while(time<88.5) {
        const int start=int(time*sr);
        for(int i=0;i<500 && start+i<int(pcm.size());++i)
            pcm[start+i]+=(i%7<3?1.f:-1.f)*std::exp(-i/100.f);
        const double bpm = scenario==0?128.152 :
                           scenario==1?110.0+0.5*time : (time<45.0?90.0:130.0);
        time+=60/bpm;
    }
    return pcm;
}
static lrp::tempo_map::Analysis run(const std::vector<float>& pcm) {
    lrp::tempo_map::Stream engine;
    // Stream using irregular buffer lengths to verify chunk independence.
    for(std::size_t p=0;p<pcm.size();) {
        std::size_t n=std::min<std::size_t>(p%1000+103,pcm.size()-p);
        engine.feed(pcm.data()+p,n);
        p+=n;
    }
    const auto e=engine.envelope();
    return lrp::tempo_map::analyze(e,lrp::tempo_map::initialTempo(e));
}
int main(){
    auto constant=run(makeSong(0));
    std::cout<<"128.152 -> "<<constant.bpm<<" beats="<<constant.beats.size()<<"\n";
    std::cout<<"first beat at "<<constant.beats.front()<<"\n";
    assert(constant.valid && !constant.varying && std::abs(constant.bpm-128.152)<0.05);
    auto ramp=run(makeSong(1));
    std::cout<<"ramp markers="<<ramp.points.size()<<"\n";
    assert(ramp.valid && ramp.varying && ramp.points.size()>10 &&
           ramp.points.front().bpm < ramp.points.back().bpm);
    auto change=run(makeSong(2));
    std::cout<<"jump markers="<<change.points.size()<<"\n";
    assert(change.valid && change.varying && change.points.size()>5);
    assert(change.points.front().bpm < 110 && change.points.back().bpm >120);
    auto silence=run(std::vector<float>(lrp::tempo::sampleRate*20,0));
    assert(!silence.valid);
    std::mt19937 rng(123);
    std::normal_distribution<float> dist(0,0.12f);
    std::vector<float> noise(lrp::tempo::sampleRate*20);
    for(auto& v:noise) v=dist(rng);
    auto random=run(noise);
    std::cout<<"random accepted="<<random.valid<<"\n";
    assert(!random.valid);
}
