#pragma once
#include "lrp/TempoDetector.h"
#include <vector>
#include <array>
#include <cmath>
#include <algorithm>
#include <numeric>
#include <cstddef>

// Experimental tempo-following detector. Streaming spectral-flux front-end,
// deterministic beat-phase tracker, and conservative tempo-map segmentation.
// All timestamps here are relative to the item start; this file is portable.
namespace lrp::tempo_map {
struct Point { double seconds=0.0, bpm=0.0; };
struct Analysis {
    std::vector<double> beats;
    std::vector<Point> points;
    double bpm=0.0, confidence=0.0;
    bool valid=false, varying=false;
};
class Stream {
    std::vector<float> pending_;
    std::size_t consumed_=0;
    std::array<double,tempo::fftSize/2> previous_{};
    std::vector<std::array<double,4>> flux_;
    double rms_=0.0;
    std::size_t samples_=0;
public:
    void feed(const float* data, std::size_t count) {
        for(std::size_t i=0;i<count;++i) rms_+=double(data[i])*data[i];
        samples_+=count;
        pending_.insert(pending_.end(),data,data+count);
        while(consumed_+tempo::fftSize<=pending_.size()) {
            std::array<std::complex<double>,tempo::fftSize> spectrum{};
            for(int j=0;j<tempo::fftSize;++j) {
                const double w=0.5-0.5*std::cos(2*tempo::pi*j/(tempo::fftSize-1));
                spectrum[j]={pending_[consumed_+j]*w,0};
            }
            tempo::fft(spectrum);
            std::array<double,4> f{};
            for(int k=2;k<tempo::fftSize/2;++k) {
                double magnitude=std::log1p(std::abs(spectrum[k]));
                double delta=std::max(0.0,magnitude-previous_[k]);
                int band=k<16?0:k<56?1:k<168?2:3;
                f[band]+=delta;
                previous_[k]=magnitude;
            }
            flux_.push_back(f);
            consumed_+=tempo::hopSize;
        }
        if(consumed_>16384) {
            pending_.erase(pending_.begin(),pending_.begin()+consumed_);
            consumed_=0;
        }
    }
    bool silent() const {return samples_<tempo::sampleRate*7u || rms_/std::max(std::size_t(1),samples_)<1e-9;}
    std::vector<double> envelope() const {
        if(silent() || flux_.size()<150) return {};
        int n=int(flux_.size());
        std::vector<double> onset(n,0.0);
        for(int b=0;b<4;++b) {
            std::vector<double> prefix(n+1,0);
            for(int i=0;i<n;++i) prefix[i+1]=prefix[i]+flux_[i][b];
            double energy=0;
            std::vector<double> local(n);
            for(int i=0;i<n;++i) {
                int lo=std::max(0,i-9),hi=std::min(n,i+10);
                double baseline=(prefix[hi]-prefix[lo])/(hi-lo);
                local[i]=std::max(0.0,flux_[i][b]-0.8*baseline);
                energy+=local[i]*local[i];
            }
            double norm=std::sqrt(energy/std::max(1,n));
            if(norm>1e-8) for(int i=0;i<n;++i) onset[i]+=local[i]*(b==0?1.25:b==1?1.1:0.9)/norm;
        }
        double max=*std::max_element(onset.begin(),onset.end());
        if(max<0.3) return {};
        return onset;
    }
};
inline double sample(const std::vector<double>& x,double t) {
    double p=t*tempo::featureRate;
    int i=int(std::floor(p));
    if(i<0 || i+1>=int(x.size())) return 0;
    double f=p-i;
    return x[i]*(1-f)+x[i+1]*f;
}
inline double robustMedian(std::vector<double> x) {
    if(x.empty())return 0;
    auto m=x.begin()+x.size()/2;
    std::nth_element(x.begin(),m,x.end());
    return *m;
}
inline double localTempo(const std::vector<double>& x,double t0,double t1,double preferred=0) {
    const int lo=std::max(1,int(t0*tempo::featureRate));
    const int hi=std::min(int(x.size())-1,int(t1*tempo::featureRate));
    if(hi-lo < 6*tempo::featureRate)return 0;
    double mean=0,total=0;
    for(int i=lo;i<hi;++i)mean+=x[i];
    mean/=(hi-lo);
    for(int i=lo;i<hi;++i){double v=x[i]-mean;total+=v*v;}
    if(total < (hi-lo)*0.002)return 0;
    double bestScore=0,bpm=0;
    for(int tick=550;tick<=2100;tick+=2) {
        const double b=tick/10.0, lag=tempo::featureRate*60/b;
        double s=0,den=0;
        for(int mult:{1,2,4}) {
            int n=int(std::round(lag*mult));
            if(n>=hi-lo-1)continue;
            double correlation=0,norm=0;
            for(int i=lo+n;i<hi;++i) {
                const double a=x[i]-mean,prev=x[i-n]-mean;
                correlation+=a*prev;norm+=a*a;
            }
            if(norm>1e-8){const double w=mult==1?0.4:mult==2?0.35:0.25;s+=w*correlation/norm;den+=w;}
        }
        if(den==0)continue;
        s/=den;
        if(preferred>0) {
            // Prior breaks octave ambiguity only; never masks confident evidence.
            double octave=std::abs(std::log2(b/preferred));
            s*=1.0-0.045*std::min(2.0,octave);
        }
        if(s>bestScore){bestScore=s;bpm=b;}
    }
    return bestScore>0.11?bpm:0;
}
inline double initialTempo(const std::vector<double>& env) {
    const double duration=env.size()/tempo::featureRate;
    // Prefer the first rhythmic section; do not let a later section with a
    // different tempo rewrite the starting tempo.
    double best=0;
    for(double t:{0.0,8.0,16.0}) {
        if(t+9>duration)continue;
        double b=localTempo(env,t,t+14,0);
        if(b>0){best=b;break;}
    }
    return best;
}
inline Analysis analyze(const std::vector<double>& input,double seedBpm) {
    Analysis out;
    if(input.size()<250||!std::isfinite(seedBpm)||seedBpm<45||seedBpm>240)return out;
    const double dt=1.0/tempo::featureRate;
    const double duration=input.size()*dt;
    const double max=*std::max_element(input.begin(),input.end());
    if(max<=0) return out;
    // Compress large isolated transient energy; suppress very quiet onsets.
    std::vector<double> strength(input.size());
    double sum=0,energy=0;
    for(std::size_t i=0;i<input.size();++i) {
        strength[i]=std::sqrt(std::max(0.0,input[i])/max);
        if(strength[i]<0.12)strength[i]=0;
        sum+=strength[i]; energy+=strength[i]*strength[i];
    }
    if(energy<input.size()*0.004)return out;
    double avg=sum/input.size();
    double variance=energy/input.size()-avg*avg;
    if(variance<0.002)return out;
    // Initial period/phase: maximize a beat-period comb over the entire audio.
    // The fundamental may be silent on some beats; we never demand an onset at every beat.
    double bestScore=-1e100,period=60/seedBpm,phase=0;
    const double startPeriod=60/seedBpm;
    // Local evidence allows the phase-locked tracker to follow accelerando,
    // ritardando, and transitions without assuming a constant song tempo.
    std::vector<double> hints;
    for(double center=0;center<duration+2;center+=2) {
        double a=std::max(0.0,center-6.0),b=std::min(duration,center+6.0);
        double local=localTempo(strength,a,b,seedBpm);
        hints.push_back(local>0?local:seedBpm);
    }
    for(int d=-20;d<=20;++d) {
        const double p=startPeriod*(1.0+d*0.0005);
        for(int ph=0;ph<44;++ph) {
            const double offset=p*ph/44.0;
            double score=0,weights=0;
            for(double t=offset;t<std::min(duration,9.0);t+=p){
                double v=std::max({sample(strength,t-0.012),sample(strength,t),sample(strength,t+0.012)});
                score+=v;weights+=1;
            }
            if(weights>8 && score/weights>bestScore) {
                bestScore=score/weights;period=p;phase=offset;
            }
        }
    }
    if(bestScore<0.11)return out;
    // Place the first grid beat near meaningful audio; retain the true phase.
    double firstActive=0;
    for(std::size_t i=0;i<input.size();++i) if(strength[i]>0.32) { firstActive=i*dt; break; }
    double first=phase+std::max(0.0,std::floor((firstActive-phase)/period))*period;
    while(first < firstActive-0.25*period) first+=period;
    if(first<0)first+=period;
    double time=first,stablePeriod=period;
    int supported=0,considered=0;
    std::vector<double> localIntervals;
    // Predict -> observe -> update, with inertia. Bounding the search to
    // 28% of a beat avoids locking onto intervening eighth-note attacks.
    for(int count=0;count<200000 && time<duration-0.06;++count) {
        // Sudden changes are allowed only when supported by a full local window.
        // Slowly varying hints are followed with a gentle phase-locked loop.
        const int hintIndex=std::clamp(int(time/2),0,int(hints.size())-1);
        const double hintedPeriod=60.0/hints[hintIndex];
        double relative=std::abs(hintedPeriod/stablePeriod-1.0);
        if(relative>0.10)
            stablePeriod=stablePeriod*0.28+hintedPeriod*0.72;
        else
            stablePeriod=stablePeriod*0.83+hintedPeriod*0.17;
        const double expected=time;
        double selected=expected,best=-1e100,observed=0;
        const double radius=std::min(0.28*stablePeriod,0.19);
        for(double t=std::max(0.0,expected-radius);t<=std::min(duration-0.02,expected+radius);t+=dt*0.50) {
            const double v=sample(strength,t);
            const double dist=(t-expected)/std::max(0.01,radius);
            const double metric=v-0.25*dist*dist;
            if(metric>best){best=metric;selected=t;observed=v;}
        }
        const bool trusted=observed>=std::max(0.22,avg*1.35) && best>0.16;
        ++considered;
        if(trusted) ++supported;
        if(trusted) time=expected*0.35+selected*0.65;
        if(!out.beats.empty()) {
            double interval=time-out.beats.back();
            if(interval<stablePeriod*0.55||interval>stablePeriod*1.55)return {};
            if(trusted) {
                stablePeriod=std::clamp(0.78*stablePeriod+0.22*interval,
                    period*0.55,period*1.8);
                localIntervals.push_back(interval);
            }
        }
        out.beats.push_back(time);
        time+=stablePeriod;
    }
    if(out.beats.size()<12||considered==0||double(supported)/considered<0.28)return {};
    // Robust local tempos evaluated over several beats reduce transient jitter.
    constexpr int block=4;
    std::vector<double> tempi;
    for(std::size_t i=0;i+block<out.beats.size();i+=block) {
        const double span=out.beats[i+block]-out.beats[i];
        const double bpm=60.0*block/span;
        if(span<=0||bpm<45||bpm>240)return {};
        tempi.push_back(bpm);
        out.points.push_back({out.beats[i],bpm});
    }
    if(tempi.size()<3)return {};
    const double median=robustMedian(tempi);
    // Stable-time refinements: fit a straight line across all tracked beats
    // rather than rounding 0.1-BPM autocorrelation to whole BPM.
    const double n=double(out.beats.size());
    double sx=(n-1)*n*0.5, sy=0,sxx=(n-1)*n*(2*n-1)/6, sxy=0;
    for(std::size_t i=0;i<out.beats.size();++i){sy+=out.beats[i];sxy+=i*out.beats[i];}
    double slope=(n*sxy-sx*sy)/(n*sxx-sx*sx);
    double precise=60/slope;
    if(!std::isfinite(precise)||precise<45||precise>240)return {};
    // Suppress low-confidence wild jumps; smooth over neighbouring 4-beat blocks.
    std::vector<double> cleaned=tempi;
    for(std::size_t i=0;i<tempi.size();++i) {
        double prior=i>0?tempi[i-1]:tempi[i];
        double next=i+1<tempi.size()?tempi[i+1]:tempi[i];
        cleaned[i]=robustMedian({prior,tempi[i],next});
    }
    double dev=0;
    for(double t:cleaned)dev+=std::abs(t-median);
    dev/=cleaned.size();
    out.varying=dev>0.32;
    out.bpm=out.varying?median:precise;
    out.confidence=double(supported)/considered;
    if(!out.varying) {
        out.points={{out.beats.front(),out.bpm}};
    } else {
        // Preserve real tempo changes but avoid a marker per transient.
        for(std::size_t i=0;i<out.points.size();++i)out.points[i].bpm=cleaned[i];
        std::vector<Point> sparse;
        for(auto point:out.points) {
            if(sparse.empty()||std::abs(point.bpm-sparse.back().bpm)>0.2||point.seconds-sparse.back().seconds>12)
                sparse.push_back(point);
        }
        out.points=std::move(sparse);
    }
    // FFT novelty is timestamped at the beginning of its analysis window;
    // compensate the expected detector latency before writing project seconds.
    constexpr double onsetOffset=tempo::fftSize*0.65/tempo::sampleRate;
    for(double& beat:out.beats)beat+=onsetOffset;
    for(auto& marker:out.points)marker.seconds+=onsetOffset;
    out.valid=true;
    return out;
}
} // namespace lrp::tempo_map
