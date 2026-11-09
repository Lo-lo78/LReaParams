#pragma once
#include <vector>
#include <array>
#include <complex>
#include <cmath>
#include <algorithm>
#include <limits>
#include <numeric>

// Standalone deterministic audio BPM estimator. No Windows / REAPER API dependency.
// PCM input must be 11025 Hz mono. Uses three-pass onset modelling:
// spectral flux in four frequency regions; tempo autocorrelation; beat phase consistency.
namespace lrp::tempo {
struct Result { double bpm = 0.0; double confidence = 0.0; bool valid = false; };
constexpr int sampleRate = 11025;
constexpr int fftSize = 1024;
constexpr int hopSize = 256;
constexpr double featureRate = double(sampleRate) / hopSize;
constexpr double pi = 3.1415926535897932384626433832795;

inline void fft(std::array<std::complex<double>, fftSize>& a) {
    for (unsigned i = 1, j = 0; i < fftSize; ++i) {
        unsigned bit = fftSize >> 1;
        for (; j & bit; bit >>= 1) j ^= bit;
        j ^= bit;
        if (i < j) std::swap(a[i], a[j]);
    }
    for (int len = 2; len <= fftSize; len <<= 1) {
        const auto wlen = std::polar(1.0, -2.0 * pi / len);
        for (int i = 0; i < fftSize; i += len) {
            auto w = std::complex<double>(1.0, 0.0);
            for (int j = 0; j < len/2; ++j) {
                const auto u = a[i+j];
                const auto v = a[i+j+len/2] * w;
                a[i+j] = u+v;
                a[i+j+len/2] = u-v;
                w *= wlen;
            }
        }
    }
}

inline Result analyze(const std::vector<float>& pcm) {
    if (pcm.size() < sampleRate * 7u) return {};
    constexpr int bands = 4;
    std::vector<std::array<double, bands>> features;
    features.reserve(pcm.size() / hopSize);
    std::array<double, fftSize/2> prev{};
    double rmsSum = 0.0;
    for (float v : pcm) rmsSum += double(v)*v;
    if (rmsSum / pcm.size() < 1e-9) return {};
    for (std::size_t pos = 0; pos + fftSize <= pcm.size(); pos += hopSize) {
        std::array<std::complex<double>, fftSize> spectrum{};
        for (int j = 0; j < fftSize; ++j) {
            const double win = 0.5 - 0.5 * std::cos(2 * pi * j / (fftSize-1));
            spectrum[j] = std::complex<double>(pcm[pos+j]*win, 0);
        }
        fft(spectrum);
        std::array<double,bands> flux{};
        for (int k = 2; k < fftSize/2; ++k) {
            const double magnitude = std::log1p(std::abs(spectrum[k]));
            const double diff = std::max(0.0, magnitude - prev[k]);
            // roughly 43-170, 170-600, 600-1800, 1800-5500 Hz
            const int band = k < 16 ? 0 : k < 56 ? 1 : k < 168 ? 2 : 3;
            flux[band] += diff;
            prev[k] = magnitude;
        }
        features.push_back(flux);
    }
    const int n = int(features.size());
    if (n < 250) return {};
    // Local contrast suppresses sustained material and long-term timbral bias.
    std::array<std::vector<double>,bands> novelty;
    for (auto& b : novelty) b.resize(n);
    for (int b = 0; b < bands; ++b) {
        std::vector<double> prefix(n+1, 0);
        for (int i = 0; i < n; ++i) prefix[i+1] = prefix[i] + features[i][b];
        double energy = 0;
        for (int i = 0; i < n; ++i) {
            const int left = std::max(0,i-9), right = std::min(n,i+10);
            const double local = (prefix[right]-prefix[left]) / (right-left);
            novelty[b][i] = std::max(0.0, features[i][b] - local*0.8);
            energy += novelty[b][i]*novelty[b][i];
        }
        const double norm = std::sqrt(energy / n);
        if (norm > 1e-8) for (auto& x : novelty[b]) x /= norm;
    }
    std::vector<double> onset(n,0);
    for (int i=0;i<n;++i) {
        for (int b=0;b<bands;++b) onset[i] += novelty[b][i] * (b == 0 ? 1.25 : b == 1 ? 1.1 : 0.9);
    }
    const auto [minIt,maxIt] = std::minmax_element(onset.begin(),onset.end());
    if (*maxIt - *minIt < 0.15) return {};
    const double center=std::accumulate(onset.begin(),onset.end(),0.0)/n;
    for(auto& value:onset) value-=center;
    // Score every tempo; fractional lag avoids integer-frame quantisation.
    // Harmonic-aware lag correlations are combined with the strength of the
    // periodic beat phase and with a mild mid-tempo prior.
    struct Candidate { double bpm, score, raw; };
    std::vector<Candidate> candidates;
    candidates.reserve(1501);
    double total = 0;
    for (double x:onset) total += x*x;
    if (total < n*0.03) return {};
    auto correlation = [&](double lag) {
        const int whole = int(lag);
        const double frac = lag-whole;
        double sum=0, denom=0;
        for(int i=whole+1;i<n;++i) {
            const double delayed=onset[i-whole]*(1-frac)+onset[i-whole-1]*frac;
            sum+=onset[i]*delayed;
            denom+=onset[i]*onset[i];
        }
        return denom > 0 ? sum/denom : 0.0;
    };
    for (int tenths=550; tenths<=2100; ++tenths) {
        double bpm=tenths/10.0;
        double lag=featureRate*60.0/bpm;
        const double one=correlation(lag);
        const double two=correlation(2*lag);
        const double half = lag >= 24 ? correlation(lag*0.5) : 0;
        const double four = 4*lag < n/2 ? correlation(4*lag) : two;
        const double raw = 0.42*one + 0.33*two + 0.25*four;
        // Avoid classifying every eighth-note onset as a doubled tempo.
        const double harmonicPenalty=std::max(0.0,half-one)*0.17;
        // Mid-tempo preference only breaks uncertain octave-equivalent ties.
        const double distance=std::abs(std::log2(bpm/115.0));
        const double prior=1.0-0.06*std::min(2.0,distance);
        candidates.push_back({bpm,(raw-harmonicPenalty)*prior,raw});
    }
    std::sort(candidates.begin(),candidates.end(),[](auto a,auto b){return a.score>b.score;});
    if(candidates.empty()||candidates.front().score<0.18) return {};
    auto best=candidates.front();
    // Correct frequent half-time errors when octave alternatives are nearly
    // equivalent. Never force an octave if its evidence is much weaker.
    for (double target : {best.bpm * 2.0, best.bpm / 2.0}) {
        if (target < 55 || target > 210) continue;
        auto alt=std::max_element(candidates.begin(), candidates.end(),[&](const Candidate& a,const Candidate& b){
            const double as=std::abs(a.bpm-target)<2.5?a.score:0.0;
            const double bs=std::abs(b.bpm-target)<2.5?b.score:0.0;
            return as<bs;
        });
        if(alt!=candidates.end() && std::abs(alt->bpm-target)<2.5 &&
           alt->score>best.score*0.83 &&
           std::abs(std::log2(alt->bpm/115.0))+0.15 < std::abs(std::log2(best.bpm/115.0)))
            best=*alt;
    }
    // Check how strong the best candidate is relative to non-octave alternatives.
    double competitor=0;
    for (auto& c:candidates) {
        const double ratio=c.bpm/best.bpm;
        if(std::abs(c.bpm-best.bpm)<3.0 || std::abs(ratio-2.0)<0.06 || std::abs(ratio-0.5)<0.03) continue;
        competitor=std::max(competitor,c.score);
    }
    const double separation = (best.score-competitor)/std::max(0.01,best.score);
    const double confidence=std::clamp(0.7*best.score + 0.3*separation, 0.0,1.0);
    if (confidence<0.18) return {};
    return {best.bpm,confidence,true};
}

inline Result combine(const std::vector<Result>& windows) {
    std::vector<Result> valid;
    for(auto r:windows) if(r.valid && std::isfinite(r.bpm) && r.bpm>=55 && r.bpm<=210) valid.push_back(r);
    if(valid.empty()) return {};
    struct Consensus { double bpm, weight; int votes; } best{0,0,0};
    for (auto seed:valid) {
        double weightedBpm=0,weights=0;
        int votes=0;
        for(auto candidate:valid) {
            if(std::abs(candidate.bpm-seed.bpm)>std::max(2.0,seed.bpm*0.025))continue;
            double weight=std::max(0.01,candidate.confidence);
            weightedBpm += candidate.bpm*weight;
            weights+=weight;
            ++votes;
        }
        if(votes>best.votes || (votes==best.votes && weights>best.weight))
            best={weightedBpm/std::max(0.01,weights),weights,votes};
    }
    // Multiple windows must agree: a single isolated result is not enough
    // for automatic tempo modification unless the item itself is short.
    if(best.votes < (valid.size()>1?2:1))return {};
    return {best.bpm, best.weight/valid.size(),true};
}
}
