#pragma once
// ReaComp / ReaGate accessibility adapter. Pure C++17; no audio processing.
// Lua source: Legacy/Speak FX Params - TrackTake Navigator.lua sections 3.1A2/3.1A3.
#include <algorithm>
#include <array>
#include <cctype>
#include <cmath>
#include <cstdlib>
#include <iomanip>
#include <initializer_list>
#include <locale>
#include <sstream>
#include <string>
#include <utility>
#include <vector>

namespace lrp::dynamics {
enum class Kind { none, comp, gate };
constexpr int compRange=-200000, gateRange=-210000;
inline int virtualId(Kind kind) {return kind==Kind::comp?compRange:kind==Kind::gate?gateRange:0;}
inline std::string normalize(std::string value) {
    std::string result;bool whitespace=false;
    for(unsigned char c:value) {
        if(c=='\r'||c=='\n'||c=='\t'||c==' '){whitespace=true;continue;}
        if(whitespace && !result.empty())result+=' ';
        whitespace=false;result+=static_cast<char>(std::tolower(c));
    }
    return result;
}
inline bool oneOf(const std::string& key,std::initializer_list<const char*> names) {
    for(const char* value:names)if(key==value)return true;
    return false;
}
inline bool detectorInput(const std::string& key) {return oneOf(key,{"signin","sign in"});}
inline bool toggle(Kind kind,const std::string& key) {
    if(kind==Kind::comp)return oneOf(key,{"filter preview","auto make up gain","auto makeup gain","auto release"});
    if(kind==Kind::gate)return oneOf(key,{"filter preview","preview filter","invert gate","invert","send midi on open/close","send midi on open close","send midi","audition input","audin","aud in"});
    return false;
}
inline std::string alias(Kind kind,const std::string& key) {
    if(kind==Kind::none)return {};
    if(oneOf(key,{"hipass","hi pass","highpass","high pass"}))return "Detector Highpass";
    if(oneOf(key,{"lowpass","low pass"}))return "Detector Lowpass";
    if(detectorInput(key))return "Detector input";
    if(oneOf(key,{"filter preview","preview filter"}))return "Filter Preview";
    if(key=="dry")return "Dry mix";
    if(key=="wet")return "Wet mix";
    if(kind==Kind::comp) {
        static const std::pair<const char*,const char*> comp[] = {
            {"pre-comp","Lookahead"},{"precomp","Lookahead"},{"pre comp","Lookahead"},
            {"auto make up gain","Auto Make Up Gain"},{"auto makeup gain","Auto Make Up Gain"},
            {"auto release","Auto Release"},{"rms size","RMS size"},
            {"resvd","Reserved"},{"audin","Audition input"},{"aud in","Audition input"},
            {"legacy attack/knee options","Legacy attack knee options"},
            {"deprecated broken anti-alias","Deprecated anti-alias compatibility"},
            {"multichannel mode","Multichannel mode"},{"metering index","Metering display mode"}
        };
        for(const auto& item:comp)if(key==item.first)return item.second;
    } else if(kind==Kind::gate) {
        static const std::pair<const char*,const char*> gate[] = {
            {"pre-open","Lookahead"},{"preopen","Lookahead"},{"pre open","Lookahead"},
            {"hysteresis","Hysteresis"},{"attack","Attack"},{"hold","Hold"},
            {"release","Release"},{"threshold","Threshold"},
            {"invert gate","Invert gate"},{"invert","Invert gate"},
            {"send midi on open/close","Send MIDI on open close"},
            {"send midi on open close","Send MIDI on open close"},
            {"send midi","Send MIDI"},{"midi note","MIDI note"},
            {"midi note on open","MIDI note"},{"midi note on close","MIDI note off"},
            {"midi channel","MIDI channel"},{"midi chan","MIDI channel"},
            {"midi velocity","MIDI velocity"},{"midi vel","MIDI velocity"},
            {"audin","Audition input"},{"aud in","Audition input"},
            {"audition input","Audition input"}
        };
        for(const auto& item:gate)if(key==item.first)return item.second;
    }
    return {};
}
struct DetectorChoice {int raw;const char* label;};
inline constexpr std::array<DetectorChoice,8> detectorChoices{{
    {0,"Main inputs"},{2,"Auxiliary inputs"},
    {1024,"Main input left"},{1025,"Main input right"},
    {1026,"Auxiliary input left"},{1027,"Auxiliary input right"},
    {999,"Feedback pre-fader"},{1000,"Output feedback deprecated"}
}};
inline int detectorIndex(double raw) {
    const int value=static_cast<int>(std::floor(raw+0.5));
    for(int i=0;i<static_cast<int>(detectorChoices.size());++i)
        if(value==detectorChoices[static_cast<size_t>(i)].raw)return i;
    return 0;
}
inline double detectorFraction(double raw) {return detectorIndex(raw)/7.0;}
inline int detectorRawFromFraction(double value) {
    const int index=std::clamp(static_cast<int>(std::floor(std::clamp(value,0.0,1.0)*7+0.5)),0,7);
    return detectorChoices[static_cast<size_t>(index)].raw;
}
inline std::string detectorLabel(double raw) {return detectorChoices[static_cast<size_t>(detectorIndex(raw))].label;}
inline bool firstNumber(const std::string& source,double& value) {
    for(size_t i=0;i<source.size();++i) {
        const char c=source[i];
        if(!std::isdigit(static_cast<unsigned char>(c)) && c!='-' && c!='+' && c!='.')continue;
        const char* start=source.c_str()+i;
        char* end=nullptr;const double parsed=std::strtod(start,&end);
        if(end!=start && std::isfinite(parsed)){value=parsed;return true;}
    }
    return false;
}
inline std::string plain(double value,int decimals) {
    std::ostringstream text;text.imbue(std::locale::classic());text<<std::fixed<<std::setprecision(decimals)<<value;
    std::string result=text.str();
    while(result.find('.')!=std::string::npos && result.back()=='0')result.pop_back();
    if(!result.empty()&&result.back()=='.')result.pop_back();
    return result;
}
inline std::string rms(const std::string& formatted) {
    double value=0;if(!firstNumber(formatted,value))return formatted;
    if(std::abs(value)<0.0005)return "0 ms, peak detector";
    return plain(value,3)+" ms";
}
inline std::string hz(double value) {return plain(value,1)+" Hz";}
inline std::string filterRange(double hp,double lp) {
    const bool high=hp>0.5, low=lp<19999.5;
    if(!high&&!low)return "Full range";
    if(high&&low)return hz(hp)+" to "+hz(lp);
    return high?"Above "+hz(hp):"Below "+hz(lp);
}
inline std::vector<int> pluginOrder(Kind kind,const std::vector<std::string>& raw,int compareId) {
    std::vector<int> out;std::vector<bool> used(raw.size(),false);
    const auto add=[&](std::initializer_list<const char*> names) {
        for(size_t i=0;i<raw.size();++i)if(!used[i] && oneOf(normalize(raw[i]),names)) {
            out.push_back(static_cast<int>(i));used[i]=true;break;
        }
    };
    add({"threshold"});
    if(kind==Kind::comp){add({"ratio"});add({"attack"});add({"release"});add({"pre-comp","precomp","pre comp"});add({"rms size"});add({"knee"});}
    if(kind==Kind::gate){add({"attack"});add({"hold"});add({"release"});add({"hysteresis"});add({"pre-open","preopen","pre open"});add({"rms size","rms"});}
    add({"signin","sign in"});add({"hipass","hi pass","highpass","high pass"});add({"lowpass","low pass"});
    out.push_back(virtualId(kind));
    add({"filter preview","preview filter"});add({"dry"});add({"wet"});
    if(kind==Kind::comp){add({"auto make up gain","auto makeup gain"});add({"auto release"});}
    if(kind==Kind::gate){
        add({"invert gate","invert"});add({"send midi on open/close","send midi on open close","send midi"});
        add({"midi note","midi note on open","midi note on close"});add({"midi channel","midi chan"});add({"midi velocity","midi vel"});
        add({"audition input","audin","aud in"});
    }
    for(size_t i=0;i<raw.size();++i)if(!used[i])out.push_back(static_cast<int>(i));
    // Like the Lua, include the FX Compare virtual control before the tail wrappers.
    const int before=std::min<int>(3,static_cast<int>(out.size()));
    out.insert(out.end()-before,compareId);
    return out;
}
} // namespace lrp::dynamics
