#include "lrp/TempoDetector.h"
#include <iostream>
#include <cassert>
#include <random>
#include <cmath>

static std::vector<float> pulse(double bpm, int seconds, bool sparse=false) {
    std::vector<float> a(lrp::tempo::sampleRate*seconds,0);
    double beat = 60.0/bpm;
    for(int i=0;i<int(seconds/beat);++i) {
        if(sparse && i%4==2)continue;
        int start=int(i*beat*lrp::tempo::sampleRate);
        for(int j=0;j<300 && start+j<int(a.size());++j) {
            double envelope=std::exp(-j/75.0);
            double v=std::sin(2*lrp::tempo::pi*(i%4==0?65:240)*j/lrp::tempo::sampleRate);
            a[start+j]+=float(v*envelope);
        }
    }
    return a;
}
int main(){
    for (double bpm:{90.,120.,150.}) {
        auto r=lrp::tempo::analyze(pulse(bpm,20));
        std::cout<<bpm<<" => "<<r.bpm<<" confidence="<<r.confidence<<" valid="<<r.valid<<'\n';
        assert(r.valid && std::abs(r.bpm-bpm)<3.0);
    }
    for (double bpm : {100.,128.}) {
        auto audio=pulse(bpm,28);
        // Add eighth-note high-frequency hats, syncopation and deterministic noise.
        for (int i=0; i<int(28*2*bpm/60.0); ++i) {
            const int t=int(i*60.0/(bpm*2.0)*lrp::tempo::sampleRate);
            for(int j=0;j<95 && t+j<int(audio.size());++j)
                audio[t+j]+=float(0.17*std::sin(j*1.8)*std::exp(-j/18.));
        }
        auto r=lrp::tempo::analyze(audio);
        std::cout<<"drum "<<bpm<<" => "<<r.bpm<<" confidence="<<r.confidence<<" valid="<<r.valid<<'\n';
        assert(r.valid && std::abs(r.bpm-bpm)<3.0);
    }
    std::mt19937 rng(12345);
    std::normal_distribution<float> noise(0.f,0.1f);
    std::vector<float> randomAudio(lrp::tempo::sampleRate*20);
    for(auto& value:randomAudio)value=noise(rng);
    auto noiseResult=lrp::tempo::analyze(randomAudio);
    std::cout<<"noise => "<<noiseResult.bpm<<" confidence="<<noiseResult.confidence<<" valid="<<noiseResult.valid<<'\n';
    assert(!noiseResult.valid);
    auto silence=lrp::tempo::analyze(std::vector<float>(lrp::tempo::sampleRate*12,0));
    assert(!silence.valid);
    auto consensus=lrp::tempo::combine({{120,0.8,true},{119.5,0.7,true},{95,0.9,true}});
    assert(consensus.valid && std::abs(consensus.bpm-120)<1);
}
