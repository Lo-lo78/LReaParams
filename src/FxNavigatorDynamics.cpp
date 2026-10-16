#include "lrp/FxNavigator.h"
#include "lrp/DynamicsSpecial.h"
#include <algorithm>
#include <cmath>
#include <initializer_list>
#include <string>
#include <vector>

namespace lrp {
namespace {
std::string rawName(MediaTrack* track,MediaItem_Take* take,int fx,int id) {
    if(id<0)return {};
    char text[4096]{};
    const bool ok=take?TakeFX_GetParamName(take,fx,id,text,sizeof(text)):
        TrackFX_GetParamName(track,fx,id,text,sizeof(text));
    return ok?std::string(text):std::string();
}
dynamics::Kind detect(const std::string& name) {
    const auto normalized=dynamics::normalize(name);
    if(normalized.find("reacomp")!=std::string::npos)return dynamics::Kind::comp;
    if(normalized.find("reagate")!=std::string::npos)return dynamics::Kind::gate;
    return dynamics::Kind::none;
}
}
bool FxNavigator::isReaComp() const {
    return browserIndex_>=0 && browserIndex_<static_cast<int>(entries_.size()) &&
           detect(entries_[static_cast<size_t>(browserIndex_)].name)==dynamics::Kind::comp;
}
bool FxNavigator::isReaGate() const {
    return browserIndex_>=0 && browserIndex_<static_cast<int>(entries_.size()) &&
           detect(entries_[static_cast<size_t>(browserIndex_)].name)==dynamics::Kind::gate;
}
bool FxNavigator::dynamicsVirtualValid(int id) const {
    return (id==dynamics::compRange && isReaComp()) || (id==dynamics::gateRange && isReaGate());
}
std::string FxNavigator::dynamicsVirtualName(int id) const {
    return dynamicsVirtualValid(id)?"Detector filter range":std::string();
}
std::string FxNavigator::dynamicsAlias(int id) const {
    if(id<0 || id>=count_)return {};
    const auto kind=isReaComp()?dynamics::Kind::comp:isReaGate()?dynamics::Kind::gate:dynamics::Kind::none;
    return dynamics::alias(kind,dynamics::normalize(rawName(track_,take_,fx_,id)));
}
bool FxNavigator::dynamicsDetectorInput(int id) const {
    return id>=0 && id<count_ && (isReaComp()||isReaGate()) &&
        dynamics::detectorInput(dynamics::normalize(rawName(track_,take_,fx_,id)));
}
bool FxNavigator::dynamicsToggle(int id) const {
    if(id<0 || id>=count_)return false;
    const auto kind=isReaComp()?dynamics::Kind::comp:isReaGate()?dynamics::Kind::gate:dynamics::Kind::none;
    return dynamics::toggle(kind,dynamics::normalize(rawName(track_,take_,fx_,id)));
}
bool FxNavigator::dynamicsRms(int id) const {
    return isReaComp() && id>=0 && id<count_ &&
        dynamics::normalize(rawName(track_,take_,fx_,id))=="rms size";
}
std::string FxNavigator::dynamicsRealFormatted(int id,const std::string& formatted) const {
    if(dynamicsDetectorInput(id)) {
        const double raw=take_?TakeFX_GetParam(take_,fx_,id,nullptr,nullptr):
            TrackFX_GetParam(track_,fx_,id,nullptr,nullptr);
        return dynamics::detectorLabel(raw);
    }
    if(dynamicsToggle(id)) {
        const double raw=take_?TakeFX_GetParam(take_,fx_,id,nullptr,nullptr):
            TrackFX_GetParam(track_,fx_,id,nullptr,nullptr);
        return raw>=0.5?"On":"Off";
    }
    if(dynamicsRms(id))return dynamics::rms(formatted);
    return formatted;
}
std::vector<int> FxNavigator::dynamicsPluginOrder() const {
    const auto kind=isReaComp()?dynamics::Kind::comp:isReaGate()?dynamics::Kind::gate:dynamics::Kind::none;
    if(kind==dynamics::Kind::none)return {};
    std::vector<std::string> names;names.reserve(static_cast<size_t>(count_));
    for(int i=0;i<count_;++i)names.push_back(rawName(track_,take_,fx_,i));
    return dynamics::pluginOrder(kind,names,compareParamIndex);
}
std::string FxNavigator::dynamicsVirtualFormatted(int id) const {
    if(!dynamicsVirtualValid(id))return {};
    int high=-1,low=-1;
    for(int i=0;i<count_;++i){
        const std::string name=dynamics::normalize(rawName(track_,take_,fx_,i));
        if(dynamics::oneOf(name,{"hipass","hi pass","highpass","high pass"}))high=i;
        if(dynamics::oneOf(name,{"lowpass","low pass"}))low=i;
    }
    const auto rangeValue=[this](int index,double fallback) {
        if(index<0)return fallback;
        char formatted[512]{};
        const bool ok=take_?TakeFX_GetFormattedParamValue(take_,fx_,index,formatted,sizeof(formatted)):
            TrackFX_GetFormattedParamValue(track_,fx_,index,formatted,sizeof(formatted));
        double hz=0;
        if(ok && dynamics::firstNumber(formatted,hz))return hz;
        return take_?TakeFX_GetParam(take_,fx_,index,nullptr,nullptr):
            TrackFX_GetParam(track_,fx_,index,nullptr,nullptr);
    };
    return dynamics::filterRange(rangeValue(high,0),rangeValue(low,20000));
}
double FxNavigator::dynamicsFraction(int id) const {
    if(!dynamicsDetectorInput(id))return 0;
    return dynamics::detectorFraction(take_?TakeFX_GetParam(take_,fx_,id,nullptr,nullptr):
        TrackFX_GetParam(track_,fx_,id,nullptr,nullptr));
}
bool FxNavigator::dynamicsSetDetector(double normalized) {
    return dynamicsSetDetectorAt(parameter_,normalized);
}
bool FxNavigator::dynamicsSetDetectorAt(int param,double normalized) {
    if(!dynamicsDetectorInput(param) || !contextUnchanged() || !std::isfinite(normalized))return false;
    const int wanted=dynamics::detectorRawFromFraction(normalized);
    const double actual=take_?TakeFX_GetParam(take_,fx_,param,nullptr,nullptr):
        TrackFX_GetParam(track_,fx_,param,nullptr,nullptr);
    if(static_cast<int>(std::lround(actual))==wanted)return false;
    Undo_BeginBlock2(project_);
    const bool accepted=take_?TakeFX_SetParam(take_,fx_,param,wanted):
        TrackFX_SetParam(track_,fx_,param,wanted);
    if(take_)TakeFX_EndParamEdit(take_,fx_,param);
    else TrackFX_EndParamEdit(track_,fx_,param);
    Undo_EndBlock2(project_,"LReaParams: detector input",take_?UNDO_STATE_ITEMS:UNDO_STATE_FX);
    const double readback=take_?TakeFX_GetParam(take_,fx_,param,nullptr,nullptr):
        TrackFX_GetParam(track_,fx_,param,nullptr,nullptr);
    // REAPER plugins can report false even if the value is already applied.
    if(!accepted && std::abs(readback-wanted)>0.5)return false;
    return std::abs(readback-wanted)<=0.5;
}
void FxNavigator::dynamicsNudgeDetector(int direction,bool big) {
    if(!direction || !dynamicsDetectorInput(parameter_))return;
    const double raw=take_?TakeFX_GetParam(take_,fx_,parameter_,nullptr,nullptr):
        TrackFX_GetParam(track_,fx_,parameter_,nullptr,nullptr);
    const int index=dynamics::detectorIndex(raw);
    // Matches Lua's discrete step handling: Alt+arrows use one choice,
    // coarse Page Up/Down uses a larger jump without invalid raw values.
    const int amount=big?std::clamp(static_cast<int>(std::lround(std::pow(2.0,std::max(0,stepScale_)))),1,7):1;
    const int next=std::clamp(index+(direction>0?amount:-amount),0,7);
    if(next==index)return; // quiet at grid/value boundaries
    if(dynamicsSetDetector(next/7.0))speech_(dynamics::detectorChoices[static_cast<size_t>(next)].label);
}
} // namespace lrp
