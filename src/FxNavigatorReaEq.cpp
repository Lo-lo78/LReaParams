#include "lrp/FxNavigator.h"
#include "lrp/ReaEqChunk.h"
#include "lrp/ReaEqVirtual.h"
#include <algorithm>
#include <cmath>
#include <cstdlib>
#include <string>

namespace lrp {
int FxNavigator::eqBandCount() const {
    if(!isReaEq() || !track_)return 0;
    try {return ReaEqChunk(namedConfig("vst_chunk")).bands();}catch(...) {return 0;}
}
bool FxNavigator::eqVirtualValid(int id) const {
    return id<0 && isReaEq() && eqBandCount()>0 && reaeq::valid(id,eqBandCount());
}
std::string FxNavigator::eqVirtualName(int id) const {
    if(id==reaeq::target)return "ReaEQ Target Band";
    if(id==reaeq::action)return eqTargetBand_==0?"Add Band":"Remove Band "+std::to_string(eqTargetBand_);
    const int band=reaeq::band(id);
    if(band<0)return {};
    return "Band "+std::to_string(band+1)+(reaeq::enabledId(id)?" Enabled":" Type");
}
std::string FxNavigator::eqVirtualFormatted(int id) const {
    if(id==reaeq::target)return eqTargetBand_<=0?"Add band":"Band "+std::to_string(std::min(eqTargetBand_,eqBandCount()));
    if(id==reaeq::action)return "Ready";
    const int band=reaeq::band(id);
    if(band<0 || band>=eqBandCount())return "Unavailable";
    const std::string raw=namedConfig((reaeq::enabledId(id)?"BANDENABLED":"BANDTYPE")+std::to_string(band));
    if(raw.empty())return "Unavailable";
    char* end=nullptr;const long value=std::strtol(raw.c_str(),&end,10);
    if(end==raw.c_str())return "Unavailable";
    if(reaeq::enabledId(id))return value?"On":"Off";
    return reaeq::names()[static_cast<size_t>(reaeq::userFromRaw(static_cast<int>(value)))];
}
double FxNavigator::eqVirtualFraction(int id) const {
    if(id==reaeq::action)return 0.0;
    if(id==reaeq::target)return eqBandCount()>0?std::clamp(eqTargetBand_,0,eqBandCount())/static_cast<double>(eqBandCount()):0;
    const int band=reaeq::band(id);
    if(band<0 || band>=eqBandCount())return 0;
    const std::string raw=namedConfig((reaeq::enabledId(id)?"BANDENABLED":"BANDTYPE")+std::to_string(band));
    char* end=nullptr;const long value=std::strtol(raw.c_str(),&end,10);
    if(end==raw.c_str())return 0;
    return reaeq::enabledId(id)?(value?1.0:0.0):reaeq::userFromRaw(static_cast<int>(value))/10.0;
}
bool FxNavigator::eqVirtualSet(int id,double normalized) {
    if(!eqVirtualValid(id)||!std::isfinite(normalized))return false;
    normalized=std::clamp(normalized,0.0,1.0);
    if(id==reaeq::target){eqTargetBand_=std::clamp(static_cast<int>(std::lround(normalized*eqBandCount())),0,eqBandCount());return true;}
    if(id==reaeq::action){if(normalized>=0.5)eqBandAction();return false;}
    const int band=reaeq::band(id);
    const int user=reaeq::enabledId(id)?(normalized>=0.5?1:0):
        std::clamp(static_cast<int>(std::lround(normalized*10)),0,10);
    const int raw=reaeq::typeId(id)?reaeq::rawFromUser(user):user;
    const auto key=std::string(reaeq::enabledId(id)?"BANDENABLED":"BANDTYPE")+std::to_string(band);
    const std::string old=namedConfig(key);
    if(old.empty()){speech_("ReaEQ band property unavailable");return false;}
    if(old==std::to_string(raw))return false;
    Undo_BeginBlock2(project_);
    const bool ok=writeNamedConfig(key,std::to_string(raw));
    Undo_EndBlock2(project_,"LReaParams: ReaEQ band property",take_?UNDO_STATE_ITEMS:UNDO_STATE_FX);
    if(ok){pickup_.erase(id);rememberPosition();}
    else speech_("ReaEQ band update failed");
    return ok;
}
void FxNavigator::eqVirtualNudge(int direction,bool big) {
    if(!eqVirtualValid(parameter_) || !direction)return;
    if(parameter_==reaeq::action){speech_("Press Enter to activate band action");return;}
    if(reaeq::enabledId(parameter_)){setValue(direction>0?1.0:0.0);return;}
    const int maximum=parameter_==reaeq::target?eqBandCount():10;
    if(maximum<=0)return;
    const int current=static_cast<int>(std::lround(eqVirtualFraction(parameter_)*maximum));
    const int amount=big?std::clamp(static_cast<int>(std::lround(std::pow(2.0,std::clamp(stepScale_,0,5)))),1,10):1;
    const int next=std::clamp(current+(direction>0?amount:-amount),0,maximum);
    if(next==current)return;
    setValue(next/static_cast<double>(maximum));
}
void FxNavigator::eqBandAction() {
    if(!eqVirtualValid(reaeq::action)){speech_("ReaEQ unavailable");return;}
    std::string previous=namedConfig("vst_chunk");
    try {
        ReaEqChunk model(previous);
        const int before=model.bands();
        eqTargetBand_=std::clamp(eqTargetBand_,0,before);
        const int wanted=eqTargetBand_;
        if(wanted==0)model.addBand();
        else model.removeBand(wanted-1);
        const int expected=model.bands();
        Undo_BeginBlock2(project_);
        bool ok=writeNamedConfig("vst_chunk",model.text());
        if(ok && count()>0){
            // Lua: refresh ReaEQ's dynamic parameter list without changing the value.
            const double current=take_?TakeFX_GetParamNormalized(take_,fx_,0):TrackFX_GetParamNormalized(track_,fx_,0);
            if(take_)TakeFX_SetParamNormalized(take_,fx_,0,current);
            else TrackFX_SetParamNormalized(track_,fx_,0,current);
        }
        if(ok){try {ok=ReaEqChunk(namedConfig("vst_chunk")).bands()==expected;}catch(...) {ok=false;}}
        if(!ok && !previous.empty())writeNamedConfig("vst_chunk",previous);
        Undo_EndBlock2(project_,"LReaParams: ReaEQ add/remove band",take_?UNDO_STATE_ITEMS:UNDO_STATE_FX);
        if(!ok){speech_("ReaEQ band action failed. No verified change");return;}
        eqTargetBand_=wanted==0?expected:std::min(wanted,expected);
        // Structural changes invalidate Compare and MIDI pickup references.
        auto& compare=compareState();compare.armed=false;compare.original={};compare.edited={};
        // Invalidate old per-parameter navigation/CC pickup after a structural change.
        const int preserved=reaeq::action;
        refreshAfterStructure(preserved);
        speech_(wanted==0?"Band added. "+std::to_string(expected)+" bands":
            "Band "+std::to_string(wanted)+" removed. "+std::to_string(expected)+" bands");
    }catch(const std::exception&){speech_("ReaEQ band action unavailable. No changes");}
}
} // namespace lrp
