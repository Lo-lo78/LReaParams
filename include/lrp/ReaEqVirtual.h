#pragma once
#include <algorithm>
#include <cstddef>
#include <array>
#include <string>
#include <charconv>
#include <system_error>
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
// Some host ReaEQ named-property setters can report false even after a
// successful change. A matching numeric readback is equally authoritative.
// Keep real failures observable: false + no matching readback means failure.
inline bool bandWriteAcceptedOrVerified(bool hostAccepted,const std::string& observed,int requested) {
    // A readable, contradictory value takes precedence over the setter bool;
    // the caller can still verify the underlying chunk independently.
    if(observed.empty())return hostAccepted;
    int actual=0;
    const auto* first=observed.data();
    const auto* last=first+observed.size();
    const auto result=std::from_chars(first,last,actual);
    return result.ec==std::errc{} && result.ptr==last && actual==requested;
}
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
// ReaEQ virtual controls were introduced after many Lua/.fx Custom Orders
// already existed. FxOrder::normalize() normally appends newly discovered
// parameters, which would put ALL Band Enabled/Type controls after Global Gain.
// Reconcile only newly introduced controls, leaving existing, deliberately
// positioned virtual entries and the physical order (including copies) intact.
inline std::vector<int> mergeLegacyCustomOrder(const std::vector<int>& stored,
                                               int bands, int physicalCount, int compareId) {
    bands=std::clamp(bands,0,64);
    if(bands==0)return stored;

    std::vector<int> generatedTail;
    for(int b=0;b<bands;++b){generatedTail.push_back(enabled(b));generatedTail.push_back(type(b));}
    generatedTail.push_back(target);generatedTail.push_back(action);

    // Repair the specific suffix written by the 0.0.43 normalization path,
    // even if an .fx profile was saved with that order. Other explicit Custom
    // Order placements must not be silently rearranged.
    const bool generatedSuffix=stored.size()>=generatedTail.size() &&
        std::equal(generatedTail.begin(),generatedTail.end(),
                   stored.end()-static_cast<std::ptrdiff_t>(generatedTail.size()));
    std::vector<int> merged(stored.begin(),generatedSuffix?
        stored.end()-static_cast<std::ptrdiff_t>(generatedTail.size()):stored.end());
    auto contains=[&](int id){return std::find(merged.begin(),merged.end(),id)!=merged.end();};

    for(int b=0;b<bands;++b) {
        const int enabledId=enabled(b), typeId=type(b);
        const bool hasEnabled=contains(enabledId), hasType=contains(typeId);
        if(hasEnabled && hasType)continue;
        if(hasEnabled) {
            auto at=std::find(merged.begin(),merged.end(),enabledId);
            merged.insert(at+1,typeId);
        } else if(hasType) {
            auto at=std::find(merged.begin(),merged.end(),typeId);
            merged.insert(at,enabledId);
        } else {
            // Find the first physical control OF THIS BAND in the original
            // custom sequence, not necessarily its frequency control. A user
            // may have reordered frequency, gain and bandwidth deliberately.
            auto at=std::find_if(merged.begin(),merged.end(),[b](int id){
                return id>=b*3 && id<b*3+3;
            });
            if(at==merged.end()) {
                // In unusual sparse old profiles place it before the first
                // global control; FxOrder::normalize then fills missing reals.
                at=std::find_if(merged.begin(),merged.end(),[&](int id){
                    return id>=bands*3 && id<physicalCount;
                });
            }
            at=merged.insert(at,enabledId);
            merged.insert(at+1,typeId);
        }
    }

    // Band management belongs between the last band and global ReaEQ controls.
    // Preserve explicitly positioned Target/Action if they are already present.
    if(!contains(target) || !contains(action)) {
        auto globals=std::find_if(merged.begin(),merged.end(),[&](int id){
            return id>=bands*3 && id<physicalCount;
        });
        // Lua inserts Compare just before the trailing wrapper controls.
        // If that is the position directly preceding Global Gain, place band
        // management BEFORE Compare, too, as in reaeq_build_default_param_indices.
        const auto compare=std::find(merged.begin(),merged.end(),compareId);
        if(globals!=merged.end() && compare!=merged.end() && compare+1==globals)
            globals=compare;
        if(globals==merged.end()) {
            // If this profile lacks globals, use the position after the last
            // physical band parameter (rather than placing actions at the end
            // after wrapper parameters or Compare).
            for(auto it=merged.begin();it!=merged.end();++it)
                if(*it>=0 && *it<bands*3)globals=it+1;
        }
        if(!contains(target))globals=merged.insert(globals,target)+1;
        if(!contains(action))merged.insert(globals,action);
    }
    return merged;
}
} // namespace lrp::reaeq
