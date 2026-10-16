#include "lrp/FxNavigator.h"
#include "lrp/ReaEqChunk.h"
#include "lrp/ReaEqVirtual.h"
#include "lrp/Storage.h"
#include <algorithm>
#include <cmath>
#include <cstdlib>
#include <cstring>
#include <iomanip>
#include <locale>
#include <sstream>

namespace lrp {
namespace {
int recentSequence() {
    char data[1024]{};int size=sizeof(data),ts=0,dev=0,loop=0;double pos=0;
    return MIDI_GetRecentInputEvent(0,data,&size,&ts,&dev,&pos,&loop);
}
bool parseLink(const std::string& text,int& channel,int& cc) {
    const auto fields=split(text,'\t');if(fields.size()!=2)return false;
    try {size_t a=0,b=0;channel=std::stoi(fields[0],&a);cc=std::stoi(fields[1],&b);
        return a==fields[0].size() && b==fields[1].size() && channel>=1 && channel<=16 && cc>=0 && cc<=127;
    } catch(...) {return false;}
}
// Only top-level envelope properties are modified. Automation-item state and
// point data remain untouched, including nested source chunks.
std::string envelopeProperty(std::string chunk,const std::string& key,bool enabled) {
    auto lines=split(chunk,'\n');int depth=0;bool found=false;
    for(auto& line:lines) {
        if(depth==1 && line.rfind(key+" ",0)==0) {
            const auto suffix=line.find(' ',key.size()+1);
            line=key+(enabled?" 1":" 0")+(suffix==std::string::npos?"":line.substr(suffix));found=true;
        }
        if(!line.empty()&&line[0]=='<')++depth;
        else if(line==">")--depth;
    }
    if(!found)return {};
    std::string result;for(const auto& line:lines){if(!result.empty())result+='\n';result+=line;}return result;
}
bool chunkActive(const std::string& chunk) {
    int depth=0;for(const auto& line:split(chunk,'\n')) {
        if(depth==1 && line.rfind("ACT ",0)==0)return line.size()>4&&line[4]=='1';
        if(!line.empty()&&line[0]=='<')++depth;else if(line==">")--depth;
    }return false;
}
}
void FxNavigator::prepareBackgroundMidi() {
    // MIDI copies are not UI navigation: never overwrite LastParam on shutdown.
    persistentPositionWriter_ = false;
    // FxOrder is copied with the navigator, but its label callback captured
    // the foreground navigator at load time. Repair that capture to prevent
    // speaking/saving CC links against the wrong FX after reopening the UI.
    fxOrder_.rebindParamName([this](int id) -> std::string {
        if (id == compareParamIndex) return "Compare";
        if(eqVirtualValid(id))return eqVirtualName(id);
        if(dynamicsVirtualValid(id))return dynamicsVirtualName(id);
        if (id < 0 || id >= count_) return {};
        char name[4096]{};
        const bool ok = take_ ? TakeFX_GetParamName(take_, fx_, id, name, sizeof(name)) :
                                TrackFX_GetParamName(track_, fx_, id, name, sizeof(name));
        if(!ok)return {};
        const auto alias=dynamicsAlias(id);return alias.empty()?std::string(name):alias;
    });
    // A MIDI-only context must never operate a text editor, memory manager,
    // numeric editor or keyboard navigator after Ctrl+Q releases the focus.
    recentMode_ = false;
    numericEdit_ = false;
    textEdit_ = false;
    searchMode_ = false;
    memoryManager_ = false;
    defaultConfirm_ = false;
    defaultRegenerate_ = false;
    valueMode_ = false;
    editF7_ = false;
    midiPendingSpeech_.clear();
    // Keep the MIDI sequence, pickup, learn and floating mappings unchanged:
    // the next CC must not jump or capture a stale event after losing focus.
}
bool FxNavigator::sameMidiFx(const FxNavigator& other) const noexcept {
    return active_ && other.active_ && project_ == other.project_ &&
           take_ == other.take_ && track_ == other.track_ && fx_ == other.fx_ &&
           std::memcmp(&fxGuid_, &other.fxGuid_, sizeof(GUID)) == 0;
}
void FxNavigator::resetMidiContext() {
    learnCc_=false;learnParam_=-1;pickup_.clear();midiSpoken_.clear();
    floatingParam_=-1;numericEdit_=false;midiPendingSpeech_.clear();
    fixedCc_=fxOrder_.extraValue("cc_runtime_fixed_map_enabled_v1")=="1";
    midiSequence_=recentSequence();
}
// Same persisted MIDI association read by FX Memories/F8. Speech lookup
// is read-only and must not depend on the active Fixed CC runtime flag.
std::string FxNavigator::currentParameterCcSpeech() const {
    // As in the Lua's ordinary parameter label, Floating CC temporarily
    // takes precedence over stored fixed assignments.
    if (floatingCc_ || floatingWaiting_) return {};

    const auto link = fxOrder_.ccLinks.find(parameter_);
    if (link != fxOrder_.ccLinks.end()) {
        int channel = 0, number = 0;
        if (parseLink(link->second, channel, number))
            return "CC channel " + std::to_string(channel) + " CC " + std::to_string(number);
    }

    // Lua fallback: also recognize a native REAPER MIDI Learn connection
    // when there is no valid internal link. It is a two-byte binary value:
    // B0..BF (channel) followed by the CC number, not a text/hex string.
    // Use an actual byte buffer: std::string(c_str()) would lose CC 0.
    if (parameter_ < 0 || parameter_ >= count_ || !valid()) return {};
    const std::string key = "param." + std::to_string(parameter_) + ".learn.midi1";
    char raw[16]{};
    const bool ok = take_ ?
        TakeFX_GetNamedConfigParm(take_, fx_, key.c_str(), raw, sizeof(raw)) :
        TrackFX_GetNamedConfigParm(track_, fx_, key.c_str(), raw, sizeof(raw));
    if (!ok) return {};
    const auto status = static_cast<unsigned char>(raw[0]);
    const auto number = static_cast<unsigned char>(raw[1]);
    if ((status & 0xF0u) != 0xB0u || number > 127) return {};
    return "CC channel " + std::to_string((status & 0x0Fu) + 1) +
           " CC " + std::to_string(number);
}
void FxNavigator::queueCcSpeech(int param,const std::string& formatted) {
    if(formatted.empty() || fxOrder_.extraValue("cc_param_speech_v1::"+std::to_string(param))!="1")return;
    if(midiSpoken_[param]==formatted)return;
    midiSpoken_[param]=formatted;
    std::string value=formatted;
    // Lua omits a redundant plus sign from positive values.
    if(!value.empty()&&value[0]=='+')value.erase(value.begin());
    midiPendingSpeech_=param==parameter_?value:fxOrder_.label(param)+", "+value;
}
void FxNavigator::clearNativeLearn(int param) {
    if(param<0 || param>=count_)return;
    for(const char* field:{"midi1","midi2","osc"}) {
        const std::string name="param."+std::to_string(param)+".learn."+field;
        if(take_)TakeFX_SetNamedConfigParm(take_,fx_,name.c_str(),"");
        else TrackFX_SetNamedConfigParm(track_,fx_,name.c_str(),"");
    }
}
void FxNavigator::applyMidi(int param,int value) {
    if(eqVirtualValid(param)){
        if(param==reaeq::action){
            const bool high=value>=64;
            if(high && !eqActionMidiHigh_)eqBandAction();
            eqActionMidiHigh_=high;
            return;
        }
        auto& state=pickup_[param];
        if(!state.allows(value,eqVirtualFraction(param)))return;
        // Discrete virtuals use the same 0..127 learn mapping as Lua.
        const double target=value/127.0;
        if(eqVirtualSet(param,target)){
            state.applied(eqVirtualFraction(param));
            queueCcSpeech(param,eqVirtualFormatted(param));
        }
        return;
    }
    if(param==compareParamIndex) {
        auto& state=pickup_[param];const double current=compareFormatted()=="Original"?0:1;
        if(state.allows(value,current) && setCompare(value/127.0)) {
            state.applied(compareFormatted()=="Original"?0:1);
            queueCcSpeech(param,compareFormatted());
        }
        return;
    }
    if(param<0||param>=count_||!valid())return;
    if(dynamicsDetectorInput(param)) {
        auto& pickup=pickup_[param];
        if(!pickup.allows(value,dynamicsFraction(param)))return;
        if(dynamicsSetDetectorAt(param,value/127.0)) {
            pickup.applied(dynamicsFraction(param));
            queueCcSpeech(param,dynamicsRealFormatted(param,""));
        }
        return;
    }
    if(eqBandParam(param,1)) {
        auto& state=pickup_[param];if(!state.allows(value,eqGainNorm(param)))return;
        if(writeEqGain(param,value/127.0)) {
            state.applied(eqGainNorm(param));
            queueCcSpeech(param,std::to_string(-150+186.1*eqGainNorm(param))+" dB");
        }return;
    }
    const double current=take_?TakeFX_GetParamNormalized(take_,fx_,param):TrackFX_GetParamNormalized(track_,fx_,param);
    auto& state=pickup_[param];
    if(!state.allows(value,current))return;
    double norm=value/127.0;
    double step=0,small=0,large=0;bool toggle=false;
    const bool known=take_?TakeFX_GetParameterStepSizes(take_,fx_,param,&step,&small,&large,&toggle):
                           TrackFX_GetParameterStepSizes(track_,fx_,param,&step,&small,&large,&toggle);
    if(known && toggle)norm=norm<0.5?0:1;
    else if(known && std::isfinite(step) && step>0 && step<=1)norm=std::clamp(std::round(norm/step)*step,0.0,1.0);
    const bool ok=take_?TakeFX_SetParamNormalized(take_,fx_,param,norm):TrackFX_SetParamNormalized(track_,fx_,param,norm);
    if(!ok)return;
    if(take_)TakeFX_EndParamEdit(take_,fx_,param);else TrackFX_EndParamEdit(track_,fx_,param);
    state.applied(take_?TakeFX_GetParamNormalized(take_,fx_,param):TrackFX_GetParamNormalized(track_,fx_,param));
    char text[4096]{};
    const bool formatted=take_?TakeFX_GetFormattedParamValue(take_,fx_,param,text,sizeof(text)):
                               TrackFX_GetFormattedParamValue(track_,fx_,param,text,sizeof(text));
    if(formatted)queueCcSpeech(param,text);
}
void FxNavigator::pollMidi() {
    if(!active_||!contextUnchanged()||memoryManager_||recentMode_||numericEdit_||textEdit_||searchMode_) {
        // Drain while protected editors own focus; never replay stale events.
        midiSequence_=recentSequence();return;
    }
    if(!learnCc_ && !fixedCc_ && !floatingCc_ && !floatingWaiting_)return;
    // Read a bounded chronological batch on REAPER's main-thread timer. Latch
    // index zero once. No audio hook, global scan, wait, or disk write per CC.
    struct Event {int seq;std::optional<MidiCc> cc;};
    std::vector<Event> pending;int latest=midiSequence_;
    for(int index=0;index<256;++index) {
        char data[1024]{};int size=sizeof(data),ts=0,dev=0,loop=0;double pos=0;
        const int seq=MIDI_GetRecentInputEvent(index,data,&size,&ts,&dev,&pos,&loop);
        if(index==0)latest=seq;
        if(!seq || seq==midiSequence_)break;
        pending.push_back({seq,decodeCc(reinterpret_cast<const unsigned char*>(data),std::min(size,static_cast<int>(sizeof(data))))});
    }
    if(latest)midiSequence_=latest;
    for(auto it=pending.rbegin();it!=pending.rend();++it) {
        if(!it->cc)continue;
        const auto cc=*it->cc;
        if(learnCc_) {
            if((learnParam_<0 && learnParam_!=compareParamIndex && !eqVirtualValid(learnParam_))||learnParam_>=count_){learnCc_=false;return;}
            // Lua reassigns a duplicated controller to the newly learned param.
            for(auto link=fxOrder_.ccLinks.begin();link!=fxOrder_.ccLinks.end();) {
                int ch=0,num=0;
                if(link->first!=learnParam_ && parseLink(link->second,ch,num) && ch==cc.channel && num==cc.number) {
                    clearNativeLearn(link->first);link=fxOrder_.ccLinks.erase(link);
                }else ++link;
            }
            fxOrder_.ccLinks[learnParam_]=std::to_string(cc.channel)+"\t"+std::to_string(cc.number);
            clearNativeLearn(learnParam_);learnCc_=false;fixedCc_=true;
            fxOrder_.setExtraValue("cc_runtime_fixed_map_enabled_v1","1");
            saveStructure();pickup_.clear();
            speech_("CC learned. Channel "+std::to_string(cc.channel)+" CC "+std::to_string(cc.number));
            // Capturing never jumps the value. Pickup starts on the next event.
            continue;
        }
        if(floatingWaiting_ && !fixedCc_) {
            floatingChannel_=cc.channel;floatingNumber_=cc.number;
            floatingWaiting_=false;floatingCc_=true;floatingParam_=-1;
            speech_("Floating CC. Channel "+std::to_string(cc.channel)+" CC "+std::to_string(cc.number));continue;
        }
        if(fixedCc_) {
            // A virtual ReaEQ Band Action may rebuild FxOrder in applyMidi.
            // Snapshot the links first; never iterate a map being replaced.
            const auto links=fxOrder_.ccLinks;
            for(const auto& link:links) {
                int ch=0,num=0;if(parseLink(link.second,ch,num)&&ch==cc.channel&&num==cc.number)applyMidi(link.first,cc.value);
            }
        }else if(floatingCc_ && cc.channel==floatingChannel_ && cc.number==floatingNumber_) {
            if(floatingParam_!=parameter_) {pickup_.clear();floatingParam_=parameter_;}
            applyMidi(parameter_,cc.value);
        }
    }
    // Coalesce MIDI speech, preserving only the most recent changed label.
    if(!midiPendingSpeech_.empty() && GetTickCount64()-midiSpeechTime_>=180) {
        speech_(midiPendingSpeech_);midiPendingSpeech_.clear();midiSpeechTime_=GetTickCount64();
    }
}
bool FxNavigator::acceptsAdvanced(const Key& k) const noexcept {
    if(learnCc_)return k.vk==VK_ESCAPE||k.vk==VK_DELETE||k.vk==VK_TAB||k.vk==VK_RETURN||(k.ctrl&&k.alt&&k.vk=='C');
    if(k.vk=='C')return (k.ctrl && (k.alt!=k.shift))||(!k.ctrl&&k.shift&&!k.alt);
    if(k.ctrl && !k.alt && !k.shift && (k.vk=='T'||k.vk=='E'))return true;
    if(k.ctrl && k.shift && !k.alt && k.vk=='R')return true;
    if(k.ctrl && k.shift && k.vk=='A')return true;
    return k.alt && !k.ctrl && !k.shift && k.vk>=VK_F1 && k.vk<=VK_F4;
}
bool FxNavigator::handleAdvanced(const Key& k) {
    if(numericEdit_) {
        if(k.vk==VK_ESCAPE||(k.ctrl&&k.vk=='E')){numericEdit_=false;speech_("Value edit cancelled");}
        else if(k.vk==VK_RETURN && !k.repeat)numericCommit();
        return true;
    }
    if(!acceptsAdvanced(k))return false;
    if(k.repeat)return true;
    if(learnCc_) {
        if(k.vk==VK_ESCAPE || (k.ctrl&&k.alt&&k.vk=='C')){learnCc_=false;speech_("CC learn disarmed");}
        else if(k.vk==VK_DELETE){clearNativeLearn(learnParam_);fxOrder_.deleteCcLink(learnParam_);pickup_.clear();learnCc_=false;speech_("CC removed");}
        else if(k.vk==VK_TAB)speech_("CC learn. Move a MIDI control. Delete removes mapping");
        return true;
    }
    if(k.vk=='C') {
        midiSequence_=recentSequence();pickup_.clear();midiPendingSpeech_.clear();
        if(k.ctrl && k.alt) {
            floatingCc_=floatingWaiting_=false;learnCc_=true;learnParam_=parameter_;
            speech_("CC learn. "+displayName()+". Move a MIDI control");
        }else if(k.ctrl && k.shift) {
            if(floatingCc_||floatingWaiting_) {floatingCc_=floatingWaiting_=false;fixedCc_=fxOrder_.extraValue("cc_runtime_fixed_map_enabled_v1")=="1";speech_("Floating CC off. Normal CC mappings");}
            else {fixedCc_=false;floatingWaiting_=true;speech_("Floating CC. Move a MIDI control");}
        }else {
            fixedCc_=!fixedCc_;floatingCc_=floatingWaiting_=false;
            fxOrder_.setExtraValue("cc_runtime_fixed_map_enabled_v1",fixedCc_?"1":"0");saveStructure();
            speech_(fixedCc_?"Fixed CC on":"Fixed CC off");
        }
        return true;
    }
    if(k.vk=='T') {
        if(parameter_!=compareParamIndex && !eqVirtualValid(parameter_) &&
           (parameter_<0 || parameter_>=count_)) {speech_("CC speech not available");return true;}
        const auto key="cc_param_speech_v1::"+std::to_string(parameter_);
        const bool on=fxOrder_.extraValue(key)!="1";
        fxOrder_.setExtraValue(key,on?"1":"");saveStructure();
        midiSpoken_.erase(parameter_);midiPendingSpeech_.clear();
        speech_(std::string(on?"CC speech on. ":"CC speech off. ")+displayName());return true;
    }
    if(k.vk=='E'){numericBegin();return true;}
    if(k.vk=='R'){announce();return true;} // full review preserved separately
    if(k.vk=='A'){toggleEnvelope(k.alt);return true;}
    if(k.vk==VK_F1||k.vk==VK_F2){navigatePreset(k.vk==VK_F1?-1:1);return true;}
    if(k.vk==VK_F3||k.vk==VK_F4){navigateEnvelope(k.vk==VK_F3?-1:1);return true;}
    return false;
}
void FxNavigator::navigatePreset(int direction) {
    Undo_BeginBlock2(project_);
    const bool ok=take_?TakeFX_NavigatePresets(take_,fx_,direction):TrackFX_NavigatePresets(track_,fx_,direction);
    Undo_EndBlock2(project_,"LReaParams: FX preset",take_?UNDO_STATE_ITEMS:UNDO_STATE_FX);
    pickup_.clear();midiSpoken_.clear();midiSequence_=recentSequence();
    if(!ok){speech_("Preset navigation unavailable");return;}
    const int n=count();
    if(n!=count_) {
        count_=n;if(n<=0){end();return;}
        if(!eqVirtualValid(parameter_) && !dynamicsVirtualValid(parameter_) && parameter_!=compareParamIndex)
            parameter_=std::clamp(parameter_,0,n-1);
        loadFxOrder();
    }
    parameterName_=parameterName();
    char text[4096]{};
    const bool named=take_?TakeFX_GetPreset(take_,fx_,text,sizeof(text)):TrackFX_GetPreset(track_,fx_,text,sizeof(text));
    speech_(named&&text[0]?std::string("Preset. ")+text:"Preset changed");
}
double FxNavigator::rawValue(int param) const {
    double lo=0,hi=1;
    return take_?TakeFX_GetParam(take_,fx_,param,&lo,&hi):TrackFX_GetParam(track_,fx_,param,&lo,&hi);
}
bool FxNavigator::setRawValue(int param,double value) {
    double lo=0,hi=1;
    if(take_)TakeFX_GetParam(take_,fx_,param,&lo,&hi);else TrackFX_GetParam(track_,fx_,param,&lo,&hi);
    if(!std::isfinite(value)||!std::isfinite(lo)||!std::isfinite(hi)||value<lo||value>hi)return false;
    Undo_BeginBlock2(project_);
    const bool ok=take_?TakeFX_SetParam(take_,fx_,param,value):TrackFX_SetParam(track_,fx_,param,value);
    if(take_)TakeFX_EndParamEdit(take_,fx_,param);else TrackFX_EndParamEdit(track_,fx_,param);
    Undo_EndBlock2(project_,"LReaParams: numeric FX value",take_?UNDO_STATE_ITEMS:UNDO_STATE_FX);
    pickup_.erase(param);return ok;
}
bool FxNavigator::numericFormat(double norm,double& value,std::string& unit) const {
    char buffer[4096]{};
    const bool ok=take_?TakeFX_FormatParamValueNormalized(take_,fx_,parameter_,norm,buffer,sizeof(buffer)):
                        TrackFX_FormatParamValueNormalized(track_,fx_,parameter_,norm,buffer,sizeof(buffer));
    if(!ok)return false;
    std::istringstream text(buffer);text.imbue(std::locale::classic());
    if(!(text>>value)||!std::isfinite(value))return false;
    std::getline(text,unit);return true;
}
void FxNavigator::numericBegin() {
    if(dynamicsDetectorInput(parameter_)){speech_("Use Value for detector input");return;}
    if(parameter_<0||parameter_>=count_){speech_("Numeric edit unavailable");return;}
    numericFormatted_=false;numericUnit_.clear();
    double current=rawValue(parameter_);
    if(eqBandParam(parameter_,0)||eqBandParam(parameter_,1)||eqBandParam(parameter_,2)) {
        ReaEqChunk chunk(namedConfig("vst_chunk"));current=chunk.value(parameter_/3,parameter_%3);
        if(parameter_%3==1) {current=current<=0?-150:20*std::log10(current);numericUnit_="dB";}
        else numericUnit_=parameter_%3==0?"Hz":"Bandwidth";
        numericFormatted_=true;
    }else {
        double first=0,last=0;std::string u,v;
        if(numericFormat(0,first,u)&&numericFormat(1,last,v)&&u==v&&first!=last) {
            bool monotonic=true;double previous=first;
            for(int i=1;i<=64;++i) {
                double value=0;std::string unit;
                if(!numericFormat(i/64.0,value,unit)||unit!=u||(last>first?value<previous:value>previous)){monotonic=false;break;}
                previous=value;
            }
            const double norm=take_?TakeFX_GetParamNormalized(take_,fx_,parameter_):TrackFX_GetParamNormalized(track_,fx_,parameter_);
            if(monotonic && numericFormat(norm,current,v)){numericFormatted_=true;numericUnit_=u;}
        }
    }
    std::ostringstream text;text.imbue(std::locale::classic());text<<std::setprecision(12)<<current;
    numericBuffer_=text.str();numericEdit_=true;
    speech_(numericFormatted_?"Parameter value. "+numericUnit_:"Parameter value. Host raw units");
}
void FxNavigator::numericCommit() {
    std::istringstream text(numericBuffer_);text.imbue(std::locale::classic());double value=0;
    if(!(text>>value) || !(text>>std::ws).eof() || !std::isfinite(value)) {speech_("Invalid number");return;}
    bool ok=false;
    if(numericFormatted_ && (eqBandParam(parameter_,0)||eqBandParam(parameter_,1)||eqBandParam(parameter_,2))) {
        const int type=parameter_%3;
        const double lo=type==0?20:type==1?-150:0.01;
        const double hi=type==0?24000:type==1?36.1:4;
        if(value<lo||value>hi){speech_("Outside parameter range");return;}
        ReaEqChunk chunk(namedConfig("vst_chunk"));
        chunk.value(parameter_/3,type,type==1?(value<=-149.5?0:std::min(64.0,std::pow(10.0,value/20))):value);
        Undo_BeginBlock2(project_);ok=writeNamedConfig("vst_chunk",chunk.text());
        Undo_EndBlock2(project_,"LReaParams: ReaEQ numeric value",take_?UNDO_STATE_ITEMS:UNDO_STATE_FX);
    }else if(numericFormatted_) {
        double first=0,last=0;std::string unit;
        if(!numericFormat(0,first,unit)||!numericFormat(1,last,unit)||value<std::min(first,last)||value>std::max(first,last)) {
            speech_("Outside parameter range");return;
        }
        double left=0,right=1;
        for(int i=0;i<48;++i) {
            double mid=(left+right)*0.5,shown=0;
            if(!numericFormat(mid,shown,unit)){speech_("Formatter unavailable");return;}
            if((last>first)==(shown<value))left=mid;else right=mid;
        }
        const double norm=(left+right)*0.5;
        Undo_BeginBlock2(project_);
        ok=take_?TakeFX_SetParamNormalized(take_,fx_,parameter_,norm):TrackFX_SetParamNormalized(track_,fx_,parameter_,norm);
        if(take_)TakeFX_EndParamEdit(take_,fx_,parameter_);else TrackFX_EndParamEdit(track_,fx_,parameter_);
        Undo_EndBlock2(project_,"LReaParams: formatted numeric value",take_?UNDO_STATE_ITEMS:UNDO_STATE_FX);
    }else ok=setRawValue(parameter_,value);
    if(!ok){speech_("Value unavailable or outside host range");return;}
    numericEdit_=false;pickup_.erase(parameter_);speech_(formattedValue());
}
TrackEnvelope* FxNavigator::envelope(int param,bool create) const {
    if(param<0||param>=count_)return nullptr;
    return take_?TakeFX_GetEnvelope(take_,fx_,param,create):GetFXEnvelope(track_,fx_,param,create);
}
bool FxNavigator::envelopeActive(int param) const {
    auto env=envelope(param,false);if(!env)return false;
    // Announcements now query this on ordinary Grid navigation. Reuse the
    // scratch buffer on REAPER's UI thread instead of allocating 4 MiB for
    // every parameter movement or NVDA review. The read never creates or
    // changes an envelope.
    thread_local std::vector<char> buffer(4*1024*1024);
    return GetEnvelopeStateChunk(env,buffer.data(),static_cast<int>(buffer.size()),false) && chunkActive(buffer.data());
}
bool FxNavigator::setEnvelope(int param,bool active) {
    auto env=envelope(param,active);if(!env)return !active;
    std::vector<char> buffer(4*1024*1024);
    if(!GetEnvelopeStateChunk(env,buffer.data(),static_cast<int>(buffer.size()),false))return false;
    const auto act=envelopeProperty(buffer.data(),"ACT",active);
    const auto vis=envelopeProperty(act,"VIS",active);
    return !act.empty()&&!vis.empty()&&SetEnvelopeStateChunk(env,vis.c_str(),true);
}
void FxNavigator::toggleEnvelope(bool all) {
    const bool target=!all && !envelopeActive(parameter_);
    Undo_BeginBlock2(project_);int changed=0,failed=0;
    if(all) {
        for(int i=0;i<count_;++i)if(envelope(i,false)) {if(setEnvelope(i,false))++changed;else ++failed;}
    }else {if(setEnvelope(parameter_,target))++changed;else ++failed;}
    Undo_EndBlock2(project_,"LReaParams: FX automation",take_?UNDO_STATE_ITEMS:UNDO_STATE_TRACKCFG);
    TrackList_AdjustWindows(false);UpdateArrange();
    if(failed)speech_("Automation update failed for "+std::to_string(failed)+" parameters");
    else if(all)speech_("Cleared "+std::to_string(changed)+" FX envelopes");
    else speech_(target?"Auto. "+displayName():"Auto off. "+displayName());
}
void FxNavigator::navigateEnvelope(int direction) {
    std::vector<int> matches;
    for(int pos=0;pos<static_cast<int>(visible_.size());++pos)
        if(envelopeActive(visible_[static_cast<size_t>(pos)]))matches.push_back(pos);
    if(matches.empty()){speech_("No automated parameters");return;}
    int target=direction>0?matches.front():matches.back();
    if(direction>0) {for(int pos:matches)if(pos>viewPos_){target=pos;break;}}
    else {for(auto it=matches.rbegin();it!=matches.rend();++it)if(*it<viewPos_){target=*it;break;}}
    if(target!=viewPos_)positionChanged(target);
}
}

namespace lrp {
const FxNavigator::CompareState* FxNavigator::findCompareState() const {
    for(const auto& state:compareStates_)if(state.project==project_ && state.take==take_ &&
        std::memcmp(&state.track,&trackGuid_,sizeof(GUID))==0 && std::memcmp(&state.guid,&fxGuid_,sizeof(GUID))==0)return &state;
    return nullptr;
}
FxNavigator::CompareState& FxNavigator::compareState() {
    if(const auto* state=findCompareState())return *const_cast<CompareState*>(state);
    CompareState state;state.guid=fxGuid_;state.project=project_;state.track=trackGuid_;state.take=take_;
    compareStates_.push_back(std::move(state));return compareStates_.back();
}
FxNavigator::CompareSnapshot FxNavigator::captureCompare() const {
    CompareSnapshot snapshot;
    for(int i=0;i<count_;++i) {
        char name[4096]{};
        if(take_)TakeFX_GetParamName(take_,fx_,i,name,sizeof(name));else TrackFX_GetParamName(track_,fx_,i,name,sizeof(name));
        snapshot.names.push_back(name);
        snapshot.values.push_back(take_?TakeFX_GetParamNormalized(take_,fx_,i):TrackFX_GetParamNormalized(track_,fx_,i));
    }
    if(isReaEq())snapshot.eqChunk=namedConfig("vst_chunk");
    return snapshot;
}
bool FxNavigator::applyCompare(const CompareSnapshot& snapshot) {
    if(!snapshot.eqChunk.empty()) {
        try {ReaEqChunk checked(snapshot.eqChunk);(void)checked;}catch(...) {speech_("Compare ReaEQ chunk invalid");return false;}
        Undo_BeginBlock2(project_);
        bool ok=writeNamedConfig("vst_chunk",snapshot.eqChunk);
        if(ok) {
            const int n=count();
            for(int tail=0;tail<3 && n>=3 && snapshot.values.size()>=3;++tail) {
                const double value=snapshot.values[snapshot.values.size()-3+tail];
                ok=(take_?TakeFX_SetParamNormalized(take_,fx_,n-3+tail,value):TrackFX_SetParamNormalized(track_,fx_,n-3+tail,value))&&ok;
            }
            refreshAfterStructure(compareParamIndex);
        }
        Undo_EndBlock2(project_,"LReaParams: ReaEQ Compare",take_?UNDO_STATE_ITEMS:UNDO_STATE_FX);
        return ok;
    }
    if(snapshot.values.size()!=static_cast<size_t>(count_)) {speech_("Compare layout changed. No changes");return false;}
    // Validate the whole identity list before the first write.
    for(int i=0;i<count_;++i) {
        char name[4096]{};
        if(take_)TakeFX_GetParamName(take_,fx_,i,name,sizeof(name));else TrackFX_GetParamName(track_,fx_,i,name,sizeof(name));
        if(snapshot.names[static_cast<size_t>(i)]!=name){speech_("Compare parameter identity changed. No changes");return false;}
    }
    Undo_BeginBlock2(project_);bool ok=true;
    for(int i=0;i<count_;++i) {
        const double v=snapshot.values[static_cast<size_t>(i)];
        ok=(take_?TakeFX_SetParamNormalized(take_,fx_,i,v):TrackFX_SetParamNormalized(track_,fx_,i,v))&&ok;
        if(take_)TakeFX_EndParamEdit(take_,fx_,i);else TrackFX_EndParamEdit(track_,fx_,i);
    }
    Undo_EndBlock2(project_,"LReaParams: Compare",take_?UNDO_STATE_ITEMS:UNDO_STATE_FX);
    pickup_.clear();if(!ok)speech_("Compare restore incomplete. Use REAPER Undo");return ok;
}
bool FxNavigator::setCompare(double value) {
    if(!valid()||!std::isfinite(value))return false;
    auto& state=compareState();
    if(!state.armed) {state.original=captureCompare();state.edited={};state.armed=true;state.originalActive=false;return true;}
    const bool original=value<0.5;if(original==state.originalActive)return false;
    if(original){auto edited=captureCompare();if(!applyCompare(state.original))return false;state.edited=std::move(edited);}
    else if(!applyCompare(state.edited))return false;
    state.originalActive=original;return true;
}
std::string FxNavigator::compareFormatted() const {
    const auto* state=findCompareState();return !state||!state->armed?"Not armed":state->originalActive?"Original":"Edited";
}
}

namespace lrp {
bool FxNavigator::isReaEq() const {
    if(browserIndex_<0||browserIndex_>=static_cast<int>(entries_.size()))return false;
    auto name=entries_[static_cast<size_t>(browserIndex_)].name;
    for(char& c:name)if(c>='A'&&c<='Z')c=static_cast<char>(c-'A'+'a');
    return name.find("reaeq")!=std::string::npos;
}
std::string FxNavigator::namedConfig(const std::string& key) const {
    // Virtual ReaEQ parameters are read during every Grid/Value movement.
    // Reuse the 4 MiB SDK scratch space instead of allocating it on each read.
    thread_local std::vector<char> chunkBuffer(4*1024*1024);
    std::array<char,4096> smallBuffer{};
    char* buffer=key=="vst_chunk"?chunkBuffer.data():smallBuffer.data();
    const int capacity=key=="vst_chunk"?static_cast<int>(chunkBuffer.size()):static_cast<int>(smallBuffer.size());
    buffer[0]='\0';
    const bool ok=take_?TakeFX_GetNamedConfigParm(take_,fx_,key.c_str(),buffer,capacity):
                         TrackFX_GetNamedConfigParm(track_,fx_,key.c_str(),buffer,capacity);
    return ok?std::string(buffer):std::string();
}
bool FxNavigator::writeNamedConfig(const std::string& key,const std::string& value) {
    return take_?TakeFX_SetNamedConfigParm(take_,fx_,key.c_str(),value.c_str()):
                 TrackFX_SetNamedConfigParm(track_,fx_,key.c_str(),value.c_str());
}
bool FxNavigator::captureReaEqDefault() {
    if(!isReaEq())return false;
    const auto chunk=namedConfig("vst_chunk");int bands=0;
    try {bands=ReaEqChunk(chunk).bands();}catch(...) {return false;}
    std::vector<std::string> rows={"META\tREA_EQ_DEFAULT_MODE\tCHUNK_ONLY",
        "META\tREA_EQ_BAND_COUNT\t"+std::to_string(bands),"META\tREA_EQ_PARAM_COUNT\t"+std::to_string(count_),
        "META\tREA_EQ_VST_CHUNK\t"+chunk};
    for(int tail=0;tail<3 && count_>=3;++tail) {
        const int param=count_-3+tail;char name[4096]{};
        if(take_)TakeFX_GetParamName(take_,fx_,param,name,sizeof(name));else TrackFX_GetParamName(track_,fx_,param,name,sizeof(name));
        std::ostringstream value;value.imbue(std::locale::classic());value<<std::setprecision(17)<<
            (take_?TakeFX_GetParamNormalized(take_,fx_,param):TrackFX_GetParamNormalized(track_,fx_,param));
        rows.push_back("META\tREA_EQ_WRAPPER_TAIL_"+std::to_string(tail+1)+"_NAME\t"+name);
        rows.push_back("META\tREA_EQ_WRAPPER_TAIL_"+std::to_string(tail+1)+"_NORM\t"+value.str());
    }
    return fxOrder_.saveDefaultRows(rows);
}
void FxNavigator::refreshAfterStructure(int preferred) {
    count_=count();if(count_<=0){end();return;}
    parameter_=(preferred==compareParamIndex || eqVirtualValid(preferred))?
        preferred:std::clamp(preferred,0,count_-1);
    clearF7Filter();groupSlot_=0;editF7_=false;
    loadFxOrder();parameterName_=parameterName();pickup_.clear();rememberPosition();
}
bool FxNavigator::restoreReaEqDefault() {
    if(!isReaEq()){speech_("Structural snapshot belongs to ReaEQ. No changes");return false;}
    const auto chunk=fxOrder_.defaultMeta("REA_EQ_VST_CHUNK");
    try {ReaEqChunk checked(chunk);(void)checked;}catch(...) {speech_("Unsupported ReaEQ default chunk. No changes");return false;}
    std::array<std::string,3> tails;
    for(int tail=0;tail<3;++tail)tails[tail]=fxOrder_.defaultMeta("REA_EQ_WRAPPER_TAIL_"+std::to_string(tail+1)+"_NORM");
    const int preferred=parameter_;
    const auto previous=namedConfig("vst_chunk");
    Undo_BeginBlock2(project_);bool ok=writeNamedConfig("vst_chunk",chunk);
    if(ok) {
        try {ok=ReaEqChunk(namedConfig("vst_chunk")).bands()==ReaEqChunk(chunk).bands();}catch(...) {ok=false;}
    }
    if(!ok) {if(!previous.empty())writeNamedConfig("vst_chunk",previous);}
    else {
        const int n=count();
        for(int tail=0;tail<3 && n>=3;++tail)if(!tails[tail].empty()) {
            try {
                double value=std::stod(tails[tail]);
                if(std::isfinite(value)&&value>=0&&value<=1)
                    ok=(take_?TakeFX_SetParamNormalized(take_,fx_,n-3+tail,value):TrackFX_SetParamNormalized(track_,fx_,n-3+tail,value))&&ok;
                else ok=false;
            }catch(...) {ok=false;}
        }
    }
    Undo_EndBlock2(project_,"LReaParams: structural ReaEQ default",take_?UNDO_STATE_ITEMS:UNDO_STATE_FX);
    if(count()!=count_)refreshAfterStructure(preferred);else {rebuildView(preferred);parameterName_=parameterName();}
    pickup_.clear();
    if(!ok)speech_("ReaEQ restore failed or incomplete. Check REAPER Undo");return ok;
}
bool FxNavigator::eqBandParam(int param,int type) const {
    if(take_||!isReaEq()||param<0 || param%3!=type || param>=count_-3)return false;
    // Named property confirms the band's identity without decoding the chunk
    // for every MIDI event or relying on unstable GetEQParam band numbering.
    return !namedConfig("BANDTYPE"+std::to_string(param/3)).empty();
}
double FxNavigator::eqGainNorm(int param) const {
    const ReaEqChunk chunk(namedConfig("vst_chunk"));const double gain=chunk.value(param/3,1);
    const double db=gain<=0?-150:20*std::log10(gain);
    return std::clamp((db+150)/186.1,0.0,1.0);
}
bool FxNavigator::writeEqGain(int param,double norm) {
    if(!eqBandParam(param,1)||!std::isfinite(norm))return false;
    ReaEqChunk chunk(namedConfig("vst_chunk"));norm=std::clamp(norm,0.0,1.0);
    const double db=-150+186.1*norm;const double raw=db<=-149.5?0:std::min(64.0,std::pow(10.0,db/20));
    chunk.value(param/3,1,raw);return writeNamedConfig("vst_chunk",chunk.text());
}
}

namespace lrp {
void FxNavigator::loadSearchHistory() {
    if(!searchHistory_.empty())return;
    const auto path=resourceRoot_/L"LReaParams"/L"Settings"/L"recent_searches.txt";
    std::string text;
    try {if(std::filesystem::exists(path))text=readFile(path);}catch(...) {}
    if(text.empty()) {const char* old=GetExtState("OSARA_FX_Params_Param_Browse","recent_searches_v1");if(old)text=old;}
    for(auto line:split(text,'\n')) {
        if(!line.empty()&&line.back()=='\r')line.pop_back();
        if(!line.empty() && line.size()<=4096 && searchHistory_.size()<20)searchHistory_.push_back(line);
    }
}
void FxNavigator::saveSearchHistory() {
    std::string text;for(const auto& line:searchHistory_){text+=line;text+='\n';}
    const auto path=resourceRoot_/L"LReaParams"/L"Settings"/L"recent_searches.txt";
    auto temp=path;temp+=L".tmp-"+std::to_wstring(GetCurrentProcessId());
    try {
        if(!writeNewVerified(temp,text) || !MoveFileExW(temp.c_str(),path.c_str(),MOVEFILE_REPLACE_EXISTING|MOVEFILE_WRITE_THROUGH))
            speech_("Search history not saved");
    }catch(...) {speech_("Search history not saved");}
}
void FxNavigator::handleRecent(const Key& k) {
    if(k.vk==VK_ESCAPE||(k.ctrl&&k.vk=='R')) {recentMode_=false;announce();return;}
    if(searchHistory_.empty()){recentMode_=false;speech_("No recent searches");return;}
    const int size=static_cast<int>(searchHistory_.size());
    if(k.vk==VK_RETURN) {
        const auto query=searchHistory_[static_cast<size_t>(historyIndex_)];recentMode_=false;applyF7Filter(query);return;
    }
    if(k.vk==VK_DELETE && !k.repeat) {
        searchHistory_.erase(searchHistory_.begin()+historyIndex_);saveSearchHistory();
        if(searchHistory_.empty()){recentMode_=false;speech_("No recent searches");return;}
        historyIndex_=std::min(historyIndex_,static_cast<int>(searchHistory_.size())-1);
        speech_("Deleted. "+searchHistory_[static_cast<size_t>(historyIndex_)]);return;
    }
    const int start=historyIndex_/columns_*columns_,end=std::min(size-1,start+columns_-1);
    int next=historyIndex_;
    if(k.vk==VK_UP)next=std::max(start,next-1);
    else if(k.vk==VK_DOWN)next=std::min(end,next+1);
    else if(k.vk==VK_LEFT && next-columns_>=0)next-=columns_;
    else if(k.vk==VK_RIGHT && start+columns_<size)next=std::min(size-1,next+columns_);
    else if(k.vk==VK_PRIOR)next=std::max(0,next-5);
    else if(k.vk==VK_NEXT)next=std::min(size-1,next+5);
    // Lua Recent deliberately uses Home=end and End=start (unlike FX grid).
    else if(k.vk==VK_HOME)next=k.ctrl?size-1:end;
    else if(k.vk==VK_END)next=k.ctrl?0:start;
    if(next!=historyIndex_ || k.vk==VK_TAB) {
        historyIndex_=next;speech_("Recent searches. "+std::to_string(next+1)+" of "+std::to_string(size)+". "+searchHistory_[static_cast<size_t>(next)]);
    }
}
}
