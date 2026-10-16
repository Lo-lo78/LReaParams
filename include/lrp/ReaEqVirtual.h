#pragma once
#include <algorithm>
#include <array>
#include <string>
#include <vector>
namespace lrp::reaeq {
// Lua FX Params IDs: preserve these verbatim in existing .fx profiles.
constexpr int target = -99998, action = -99999, base = -100000;
constexpr int enabled(int band) { return base-2*band; }
constexpr int type(int band) { return base-2*band-1; }
constexpr bool actionId(int id) {return id==target || id==action;}
constexpr int band(int id) {return id<=base && id>base-128?(base-id)/2:-1;}
constexpr bool enabledId(int id){return band(id)>=0 && ((base-id)%2)==0;}
constexpr bool typeId(int id){return band(id)>=0 && ((base-id)%2)==1;}
constexpr bool valid(int id,int bands){return (actionId(id) || (band(id)>=0 && band(id)<bands));}
inline const std::array<int,11>& rawTypes(){static const std::array<int,11> list{0,1,8,3,4,5,6,7,10,9,2};return list;}
inline const std::array<const char*,11>& names(){static const std::array<const char*,11> list{
    "Low shelf","High shelf","Band","Low pass","High pass","All pass","Notch","Band pass",
    "Parallel band pass","Band alt","Band alt 2"};return list;}
inline int userFromRaw(int raw){auto const& list=rawTypes();for(int i=0;i<11;++i)if(list[i]==raw)return i;return 2;}
inline int rawFromUser(int user){return rawTypes()[static_cast<size_t>(std::clamp(user,0,10))];}
inline std::vector<int> pluginOrder(int bands,int physicalCount,int compareId){
    std::vector<int> out;
    bands=std::clamp(bands,0,64);
    for(int b=0;b<bands;++b){out.push_back(enabled(b));out.push_back(type(b));
        for(int k=0;k<3;++k)if(b*3+k<physicalCount)out.push_back(b*3+k);}
    out.push_back(target);out.push_back(action);
    for(int i=bands*3;i<physicalCount;++i)out.push_back(i);
    out.insert(out.end()-std::min<int>(3,static_cast<int>(out.size())),compareId);
    return out;
}
} // namespace lrp::reaeq
