#pragma once
// TEST67.1: Pure collection logic. Project-specific storage is in FxNavigatorUsed.cpp;
// the existing Lua-compatible .fx schema is never changed.
#include <algorithm>
#include <charconv>
#include <string>
#include <string_view>
#include <vector>
#include <utility>
#include <system_error>

namespace lrp::used {
struct State {
    int count = 0;              // The parameter layout that was saved.
    int columns = 10;           // Independent fifteenth grid.
    bool keyboard = false;      // Independent fifteenth theme.
    bool resume = false;        // Per-FX last view, saved separately in the project.
    int selected = -1;          // Physical parameter ID, not an occurrence.
    std::vector<int> ids;       // First-actual-edit order, no duplicates.
};
inline bool add(State& state, int id) {
    if (id < 0 || id >= state.count ||
        std::find(state.ids.begin(), state.ids.end(), id) != state.ids.end()) return false;
    state.ids.push_back(id);
    return true;
}
inline bool erase(State& state, int id) {
    const auto it = std::find(state.ids.begin(), state.ids.end(), id);
    if (it == state.ids.end()) return false;
    state.ids.erase(it);
    return true;
}
inline std::string encode(const State& state) {
    std::string out="U1;"+std::to_string(state.count)+";"+
                    std::to_string(state.columns)+";"+
                    (state.keyboard?"1":"0")+";"+std::to_string(state.selected)+";";
    for (std::size_t i=0; i<state.ids.size(); ++i) {
        if (i) out += ',';
        out += std::to_string(state.ids[i]);
    }
    return out;
}
inline bool integer(std::string_view data, int& output) {
    if (data.empty() || data.size() > 11) return false;
    const auto result=std::from_chars(data.data(),data.data()+data.size(),output);
    return result.ec==std::errc{} && result.ptr==data.data()+data.size();
}
inline bool decode(std::string_view data, int expectedCount, State& result) {
    if (expectedCount<=0 || expectedCount>100000 || data.size()>700000 ||
        data.compare(0,3,"U1;")!=0) return false;
    State candidate; candidate.count=expectedCount;
    std::size_t begin=3;
    int header[4]{};
    for(int i=0;i<4;++i) {
        const auto end=data.find(';',begin);
        if(end==std::string_view::npos || !integer(data.substr(begin,end-begin),header[i]))return false;
        begin=end+1;
    }
    if(header[0]!=expectedCount || header[1]<1 || header[1]>400 ||
       (header[2]!=0 && header[2]!=1) || header[3]<-1 || header[3]>=expectedCount)return false;
    candidate.columns=header[1];candidate.keyboard=header[2]==1;candidate.selected=header[3];
    auto ids=data.substr(begin);
    while(!ids.empty()) {
        const auto end=ids.find(',');
        int id=0;
        if(!integer(ids.substr(0,end),id) || !add(candidate,id))return false;
        if (end==std::string_view::npos) break;
        ids.remove_prefix(end+1);
        if(ids.empty())return false;
    }
    result=std::move(candidate);
    return true;
}
}
