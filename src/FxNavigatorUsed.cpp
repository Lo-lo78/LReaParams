#include "lrp/FxNavigator.h"
#include <algorithm>
#include <string>

namespace lrp {
namespace {
// Stable binary GUID encoding: the instance identity is scoped to the project
// by SetProjExtState. Replacing/reordering FX cannot attach the list to a slot.
std::string usedKey(const GUID& guid) {
    constexpr char hex[]="0123456789ABCDEF";
    const auto* bytes=reinterpret_cast<const unsigned char*>(&guid);
    std::string key="FX_";
    for(std::size_t i=0;i<sizeof(GUID);++i) {
        key.push_back(hex[bytes[i]>>4]);key.push_back(hex[bytes[i]&15]);
    }
    return key;
}
constexpr const char* section="LReaParams.UsedParameters.v1";
}
void FxNavigator::loadUsedState() {
    usedActive_=false;
    usedOrigin_={};
    usedState_={};usedState_.count=count_;
    if(!project_ || !count_ || !GetProjExtState)return;
    const auto key=usedKey(fxGuid_);
    // A bounded read: never accept corrupt or unexpectedly huge RPP metadata.
    std::string data(700001,'\0');
    if(GetProjExtState(project_,section,key.c_str(),data.data(),static_cast<int>(data.size()))<=0)return;
    const auto nul=std::find(data.begin(),data.end(),'\0');
    if(nul==data.end())return;
    data.resize(static_cast<std::size_t>(nul-data.begin()));
    used::State loaded;
    if(used::decode(data,count_,loaded))usedState_=std::move(loaded);
}
void FxNavigator::saveUsedState() {
    if(!active_ || !project_ || !SetProjExtState || !contextUnchanged() || count_<=0)return;
    if(usedActive_ && !visible_.empty() && viewPos_>=0 && viewPos_<static_cast<int>(visible_.size()))
        usedState_.selected=visible_[static_cast<std::size_t>(viewPos_)];
    if(usedActive_) usedState_.columns=std::clamp(columns_,1,400);
    const auto key=usedKey(fxGuid_);
    const auto payload=used::encode(usedState_);
    SetProjExtState(project_,section,key.c_str(),payload.c_str());
}
void FxNavigator::markUsedParameter(int id) {
    // The physical parameter ID is used, never the order occurrence. Virtual
    // action buttons, patch loads, automation and MIDI input are not recorded.
    if(!active_ || id<0 || id>=count_ || !contextUnchanged())return;
    if(!used::add(usedState_,id))return;
    if(usedActive_ && !f7FilterActive_) {
        visible_.push_back(id);
        if(visible_.size()==1) {
            viewPos_=0;parameter_=id;parameterName_=parameterName();
            syncParameterStep();
        }
    }
    saveUsedState();
}
void FxNavigator::removeUsedParameter() {
    if(!usedActive_ || visible_.empty() || viewPos_<0 ||
       viewPos_>=static_cast<int>(visible_.size()))return;
    const int id=visible_[static_cast<std::size_t>(viewPos_)];
    if(!used::erase(usedState_,id))return;
    if(f7FilterActive_) {
        const auto query=f7FilterQuery_;
        f7FilterActive_=false;f7FullView_.clear();f7FilterPositions_.clear();f7FilterQuery_.clear();
        visible_=usedState_.ids;
        if(!query.empty() && !visible_.empty())applyF7Filter(query,false);
    } else visible_.erase(visible_.begin()+viewPos_);
    if(!visible_.empty()) {
        viewPos_=std::min(viewPos_,static_cast<int>(visible_.size())-1);
        parameter_=visible_[static_cast<std::size_t>(viewPos_)];
        parameterName_=parameterName();syncParameterStep();
    } else {
        viewPos_=0;usedState_.selected=-1;
    }
    saveUsedState();
    speech_("Removed from Used. "+std::to_string(visible_.size())+" parameters remaining"+
            (visible_.empty()?std::string():". "+currentParameterSpeech()));
}
void FxNavigator::leaveUsedView(bool speak) {
    if(!usedActive_)return;
    saveUsedState();
    usedActive_=false;
    visible_=std::move(usedOrigin_.visible);
    parameter_=usedOrigin_.parameter;viewPos_=usedOrigin_.position;
    columns_=usedOrigin_.columns;valueMode_=usedOrigin_.value;
    f7FilterActive_=usedOrigin_.filterActive;
    f7FullView_=std::move(usedOrigin_.filterFull);
    f7FilterPositions_=std::move(usedOrigin_.filterPositions);
    f7FilterQuery_=std::move(usedOrigin_.filterQuery);
    usedOrigin_={};
    parameterName_=parameterName();syncParameterStep();
    rememberPosition();
    if(speak) {
        const std::string origin=groupSlot_?groupLabel(groupSlot_):
            (fxOrder_.custom?"Custom Order":"Plugin Order");
        speech_(origin+". "+(visible_.empty()?"Empty":currentParameterSpeech()));
    }
}
void FxNavigator::toggleUsedView() {
    if(usedActive_) {leaveUsedView(true);return;}
    // Entering Used never changes an original 14-context cursor or saved theme.
    rememberPosition();
    usedOrigin_.visible=visible_;
    usedOrigin_.parameter=parameter_;usedOrigin_.position=viewPos_;
    usedOrigin_.columns=columns_;usedOrigin_.value=valueMode_;
    usedOrigin_.filterActive=f7FilterActive_;
    usedOrigin_.filterFull=f7FullView_;
    usedOrigin_.filterPositions=f7FilterPositions_;
    usedOrigin_.filterQuery=f7FilterQuery_;
    f7FilterActive_=false;f7FullView_.clear();f7FilterPositions_.clear();f7FilterQuery_.clear();
    usedActive_=true;valueMode_=false;
    visible_=usedState_.ids; columns_=usedState_.columns;
    const auto found=std::find(visible_.begin(),visible_.end(),usedState_.selected);
    viewPos_=found!=visible_.end()?static_cast<int>(found-visible_.begin()):0;
    if(!visible_.empty()) {
        parameter_=visible_[static_cast<std::size_t>(viewPos_)];
        parameterName_=parameterName();syncParameterStep();
    }
    speech_("Used. "+std::to_string(visible_.size())+" parameters"+
            (visible_.empty()?std::string(". Empty") : ". "+currentParameterSpeech()));
}
}
