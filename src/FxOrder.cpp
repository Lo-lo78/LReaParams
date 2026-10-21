#include "lrp/FxOrder.h"
#include "lrp/ReaEqVirtual.h"
#include "lrp/DynamicsSpecial.h"
#include "lrp/Storage.h"
#include <algorithm>
#include <cctype>
#include <cstdio>
#include <iomanip>
#include <sstream>
#include <cmath>
#include <cstring>
#include <locale>
#include <limits>
#include <windows.h>

namespace lrp {
namespace {
std::string trim(std::string s) {
    const auto a=s.find_first_not_of(" \r\n\t");
    if(a==std::string::npos) return {};
    return s.substr(a,s.find_last_not_of(" \r\n\t")-a+1);
}
std::string unescape(const std::string& input) {
    std::string r;
    for(size_t i=0;i<input.size();++i) {
        if(input[i]=='\\' && i+1<input.size()) {
            char c=input[++i]; r+=(c=='n'?'\n':c=='r'?'\r':c);
        } else r+=input[i];
    }
    return r;
}
std::string escape(const std::string& input) {
    std::string r;
    for(char c:input) {
        if(c=='\\') r+="\\\\";
        else if(c=='\n') r+="\\n";
        else if(c=='\r') r+="\\r";
        else r+=c;
    }
    return r;
}
std::string oneLine(std::string s) {
    for(char& c:s) if(c=='\r'||c=='\n'||c=='\t') c=' ';
    return trim(std::move(s));
}
std::string filename(std::string name) {
    // Mirrors Lua sanitize_plugin_filename, preserving UTF-8.
    name=oneLine(std::move(name));
    std::string r;
    bool pendingSpace=false;
    for(unsigned char c:name) {
        if(c==' '||c=='\t') { pendingSpace=true;continue; }
        if(pendingSpace && !r.empty()) r+=' ';
        pendingSpace=false;
        if(c==':' || c=='/' || c=='\\' || c=='*' || c=='?' || c=='"' || c=='<' || c=='>' || c=='|') r+=" - ";
        else if(c>=32) r+=static_cast<char>(c);
    }
    std::string compact;
    bool space=false;
    for(char c:r) { if(c==' ') { if(!space && !compact.empty()) compact+=' '; space=true; } else { compact+=c; space=false; } }
    compact=trim(compact);
    // The Lua normalizes separators as " - ".
    std::string cleaned;
    for(size_t i=0;i<compact.size();++i) {
        if(compact[i]=='-') {
            while(!cleaned.empty()&&cleaned.back()==' ') cleaned.pop_back();
            if(!cleaned.empty()) cleaned+=' ';
            cleaned+='-'; cleaned+=' ';
            while(i+1<compact.size()&&compact[i+1]==' ') ++i;
        } else cleaned+=compact[i];
    }
    cleaned=trim(cleaned);
    while(!cleaned.empty()&&cleaned.front()=='.') cleaned.erase(cleaned.begin());
    while(!cleaned.empty()&&cleaned.back()=='.') cleaned.pop_back();
    if(cleaned.empty()) cleaned="Unknown FX";
    if(cleaned.size()>160) cleaned=trim(cleaned.substr(0,160));
    return cleaned+".fx";
}
bool parseIndex(const std::string& line,int& id,std::string& name,std::string& alias) {
    auto fields=split(line,'\t');
    if(fields.size()<2) return false;
    try {
        size_t end=0; long val=std::stol(trim(fields[0]),&end,10);
        if(end!=trim(fields[0]).size()||val<-2147483648LL||val>2147483647) return false;
        id=static_cast<int>(val);
    } catch (...) { return false; }
    name=fields[1]; alias=fields.size()>2?fields[2]:"";
    return true;
}
std::string lineFor(int id,const std::string& name,const std::string& alias={}) {
    return std::to_string(id)+"\t"+oneLine(name)+(alias.empty()?"":"\t"+oneLine(alias));
}
// Edit a single profile field/section while preserving every unrelated Lua
// record byte-for-byte. The serializer validates the complete updated profile.
std::string patchProfile(const std::string& input,const std::string& view,
                         const std::vector<std::string>& orderLines,
                         const std::map<std::string,std::string>& extras,
                         const std::map<int,std::vector<int>>& groups,
                         const std::map<int,int>& params, const std::vector<std::string>& defaults, bool groupMode,
                         const std::function<std::string(int)>& name) {
    const auto original=parseLegacy(input);
    const auto unsupported=[&](const std::string& row) {
        int id=0;std::string label,alias;
        return parseIndex(row,id,label,alias) && name(id).empty();
    };
    const auto rawLines=split(input,'\n');
    std::vector<std::string> out;
    std::string section;
    bool customEmitted=false, extraEmitted=false, groupsEmitted=false, paramsEmitted=false;
    bool foundView=false,foundSlotMode=false,defaultsEmitted=false;
    auto emitDefaults=[&] { if(defaultsEmitted)return; defaultsEmitted=true;
        out.push_back("[DefaultValues]"); for(const auto& line:defaults)out.push_back(line); };
    auto emitOrder=[&] { if(customEmitted) return; customEmitted=true; out.push_back("[CustomOrder]");
        for(const auto& s:orderLines) out.push_back(s); };
    auto emitExtra=[&] { if(extraEmitted)return;extraEmitted=true;out.push_back("[Extra]");
        for(const auto& pair:extras)out.push_back(pair.first+"="+escape(pair.second)); };
    auto emitGroups=[&] { if(groupsEmitted)return;groupsEmitted=true;out.push_back("[GroupSlots]");
        for(const auto& pair:groups) {
            std::string joined;
            for(int i:pair.second) { if(!joined.empty()) joined+='\n'; joined+=lineFor(i,name(i)); }
            const auto old=original.sections.find("GroupSlots");
            if(old!=original.sections.end())for(const auto& row:old->second) {
                const auto eq=row.find('=');if(eq==std::string::npos||row.substr(0,eq)!=std::to_string(pair.first))continue;
                for(const auto& ref:split(unescape(row.substr(eq+1)),'\n'))if(unsupported(ref)) {if(!joined.empty())joined+='\n';joined+=ref;}
            }
            out.push_back(std::to_string(pair.first)+"="+escape(joined));
        }
        const auto old=original.sections.find("GroupSlots");
        if(old!=original.sections.end())for(const auto& row:old->second) {
            const auto eq=row.find('=');if(eq==std::string::npos)continue;
            int slot=0;try {slot=std::stoi(row.substr(0,eq));}catch(...) {continue;}
            if(groups.count(slot))continue;
            bool allOpaque=true;const auto refs=split(unescape(row.substr(eq+1)),'\n');
            for(const auto& ref:refs)if(!ref.empty()&&!unsupported(ref))allOpaque=false;
            if(allOpaque)out.push_back(row);
        }
    };
    auto emitParams=[&] { if(paramsEmitted)return;paramsEmitted=true;out.push_back("[ParamSlots]");
        for(const auto& pair:params)out.push_back(std::to_string(pair.first)+"="+lineFor(pair.second,name(pair.second)));
        const auto old=original.sections.find("ParamSlots");
        if(old!=original.sections.end())for(const auto& row:old->second) {
            const auto eq=row.find('=');if(eq==std::string::npos)continue;
            int slot=0;try {slot=std::stoi(row.substr(0,eq));}catch(...) {continue;}
            if(!params.count(slot)&&unsupported(unescape(row.substr(eq+1))))out.push_back(row);
        }
    };
    for(auto line:rawLines) {
        if(!line.empty()&&line.back()=='\r')line.pop_back();
        if(!line.empty()&&line.front()=='['&&line.back()==']') {
            if(section=="CustomOrder")emitOrder();
            else if(section=="Extra")emitExtra();
            else if(section=="GroupSlots")emitGroups();
            else if(section=="ParamSlots")emitParams();
            else if(section=="DefaultValues")emitDefaults();
            section=line.substr(1,line.size()-2);
            if(section!="CustomOrder"&&section!="Extra"&&section!="GroupSlots"&&section!="ParamSlots"&&section!="DefaultValues")out.push_back(line);
            continue;
        }
        if(section=="CustomOrder"||section=="Extra"||section=="GroupSlots"||section=="ParamSlots"||section=="DefaultValues") {
            const auto start=line.find_first_not_of(" \t");
            if(start!=std::string::npos && (line[start]=='#'||line[start]==';'))out.push_back(line);
            continue;
        }
        if(line.rfind("CustomOrderView=",0)==0) {out.push_back("CustomOrderView="+view);foundView=true;}
        else if(line.rfind("SlotAccessMode=",0)==0) {out.push_back(std::string("SlotAccessMode=")+(groupMode?"group":"param"));foundSlotMode=true;}
        else out.push_back(line);
    }
    if(section=="CustomOrder")emitOrder();
    if(section=="Extra")emitExtra();
    if(section=="GroupSlots")emitGroups();
    if(section=="ParamSlots")emitParams();
    if(section=="DefaultValues")emitDefaults();
    if(!customEmitted)emitOrder();
    if(!groupsEmitted)emitGroups();
    if(!paramsEmitted)emitParams();
    if(!extraEmitted)emitExtra();
    if(!defaultsEmitted)emitDefaults();
    if(!foundView)out.insert(out.begin(),"CustomOrderView="+view);
    if(!foundSlotMode)out.insert(out.begin(),std::string("SlotAccessMode=")+(groupMode?"group":"param"));
    std::string result;
    for(const auto& line:out) { result+=line;result+='\n'; }
    return result;
}
}
void FxOrder::reset() noexcept {
    custom=false;groupSlotMode=false;order.clear();aliases.clear();hidden.clear();groups.clear();groupNames.clear();paramSlots.clear();ccLinks.clear();
    file_.clear();resource_.clear();rawName_.clear();loadedDigest_.clear();paramName_={};count_=0;defaultOrder_.clear();validVirtual_.clear();profile_={};loaded_=existed_=false;customCreated_=false;
}
void FxOrder::normalize() {
    std::vector<int> kept;
    std::set<int> included;
    for(int id:order)if(id!=compareParamIndex && permitted(id)){kept.push_back(id);included.insert(id);}
    for(int id:defaultOrder_)if(id!=compareParamIndex && !included.count(id))kept.push_back(id);
    order.swap(kept);
    for(auto it=hidden.begin();it!=hidden.end();)if(!permitted(*it))it=hidden.erase(it);else ++it;
    for(auto it=aliases.begin();it!=aliases.end();)if(!permitted(it->first))it=aliases.erase(it);else ++it;
}
std::vector<int> FxOrder::visibleOrder() const {
    std::vector<int> visible;
    const auto& source=custom?order:defaultOrder_;
    for(int id:source)if(id!=compareParamIndex && (!custom||!hidden.count(id)))visible.push_back(id);
    return visible;
}
std::string FxOrder::label(int id) const {
    if(custom) { const auto it=aliases.find(id);if(it!=aliases.end()&&!it->second.empty())return it->second; }
    return paramName_?paramName_(id):"";
}
bool FxOrder::hasRealModifications() const {
    if(!aliases.empty()||!hidden.empty())return true;
    const auto& expected=defaultOrder_;
    if(order!=expected)return true;
    return false;
}
void FxOrder::load(const std::filesystem::path& resource,const std::string& rawName,
                   int paramCount,std::function<std::string(int)> paramName,
                   const std::vector<int>& nativeOrder) {
    reset();resource_=resource;rawName_=rawName;paramName_=std::move(paramName);
    count_=std::max(0,paramCount);
    if(nativeOrder.empty()){
        for(int i=0;i<count_;++i)defaultOrder_.push_back(i);
        // Compare is now an F8 action, never a virtual parameter.
    }else {
        std::set<int> unique;
        for(int id:nativeOrder)if(unique.insert(id).second &&
            (id!=compareParamIndex && ((id>=0 && id<count_) || (id==-200000 || id==-210000 || (id<0 && id>=-100127)))))
            defaultOrder_.push_back(id);
    }
    for(int id:defaultOrder_)if(id<0 && id!=compareParamIndex)validVirtual_.insert(id);
    order=defaultOrder_;
    if(resource_.empty()||rawName_.empty())return;
    const auto folder=resource_/L"LReaParams"/L"Plugins";
    file_=folder/std::filesystem::u8path(filename(rawName));
    // Original importer may retain older file spellings or subfolders.
    // ProfileRaw, not a coincidental filename, is the identity check.
    if(!std::filesystem::exists(file_) && std::filesystem::exists(folder)) {
        for(auto it=std::filesystem::recursive_directory_iterator(folder,
            std::filesystem::directory_options::skip_permission_denied);
            it!=std::filesystem::recursive_directory_iterator();++it) {
            if(it->is_symlink()) {if(it->is_directory())it.disable_recursion_pending();continue;}
            if(!it->is_regular_file()||it->path().extension()!=L".fx")continue;
            try {
                auto candidate=parseNative(readFile(it->path()));
                if(candidate.kind==ProfileKind::fx&&candidate.headers["PluginRaw"]==rawName) {file_=it->path();break;}
            } catch(...) {}
        }
    }
    if(std::filesystem::exists(file_)) {
        if(std::filesystem::is_symlink(file_))throw ProfileError("Symlink FX profile refused");
        const auto currentBytes=readFile(file_);
        loadedDigest_=sha256(currentBytes);
        profile_=parseNative(currentBytes);
        if(profile_.kind!=ProfileKind::fx||profile_.headers.at("PluginRaw")!=rawName)
            throw ProfileError("Profile identity mismatch: refusing unrelated FX profile");
        existed_=true;
    } else {
        std::string payload="Version=3\nPluginRaw="+escape(rawName)+"\nLastParam=\nLastEntry=\nLastArea=\nSlotAccessMode=param\nCustomOrderView=plugin\nQuickGroup=\n\n[CustomOrder]\n\n[DefaultValues]\n\n[ParamSlots]\n\n[GroupSlots]\n\n[Extra]\n";
        profile_=parseLegacy(payload);
    }
    loaded_=true;
    custom=profile_.headers.at("CustomOrderView")=="custom";
    customCreated_=custom || !profile_.sections["CustomOrder"].empty();
    groupSlotMode=profile_.headers.at("SlotAccessMode")=="group";
    for(const auto& row:profile_.sections["CustomOrder"]) {
        int id=0;std::string name,alias;
        if(!parseIndex(row,id,name,alias))continue;
        if(permitted(id)) {order.push_back(id);if(!alias.empty())aliases[id]=alias;}
        else if(!name.empty()) {
            for(int i=0;i<count_;++i) if(paramName_(i)==name) {order.push_back(i);if(!alias.empty())aliases[i]=alias;break;}
        }
    }
    if(!profile_.sections["CustomOrder"].empty()) {
        order.erase(order.begin(),order.begin()+static_cast<std::ptrdiff_t>(defaultOrder_.size()));
    }
    for(const auto& row:profile_.sections["Extra"]) {
        const auto pos=row.find('=');if(pos==std::string::npos)continue;
        const auto key=row.substr(0,pos), value=unescape(row.substr(pos+1));
        if(key=="hidden_params_v1") for(const auto& line:split(value,'\n')) {
            int id=0;std::string name,alias;
            if(parseIndex(line,id,name,alias)&&(permitted(id)))hidden.insert(id);
        }
        const std::string ccPrefix="cc_link_v1::param::";
        if(key.rfind(ccPrefix,0)==0) {
            try {int param=std::stoi(key.substr(ccPrefix.size()));
                if((permitted(param)) && !value.empty())ccLinks[param]=value;
            } catch(...) {}
        }
        const std::string prefix="group_slot_name_v1::slot::";
        if(key.rfind(prefix,0)==0) {
            try{int slot=std::stoi(key.substr(prefix.size()));if(slot>=1&&slot<=12)groupNames[slot]=value;}catch(...){}
        }
    }
    for(const auto& row:profile_.sections["ParamSlots"]) {
        auto p=row.find('=');if(p==std::string::npos)continue;
        int slot=0;try{slot=std::stoi(row.substr(0,p));}catch(...){continue;}
        if(slot<1||slot>12)continue;
        int id=0;std::string name,alias;
        if(parseIndex(unescape(row.substr(p+1)),id,name,alias)&&(permitted(id)))paramSlots[slot]=id;
    }
    for(const auto& row:profile_.sections["GroupSlots"]) {
        auto p=row.find('=');if(p==std::string::npos)continue;
        int slot=0;try {slot=std::stoi(row.substr(0,p));}catch(...){continue;}
        if(slot<1||slot>12)continue;
        for(auto& line:split(unescape(row.substr(p+1)),'\n')) {
            int id=0;std::string name,alias;
            if(parseIndex(line,id,name,alias)&&(permitted(id)))groups[slot].push_back(id);
        }
    }
    // Lua Plugin Order interleaves virtual Enabled/Type before the physical
    // controls of each ReaEQ band. Existing pre-0.0.43 Custom Orders do not
    // contain those virtual IDs; append-at-end would put them after Global
    // Gain. Merge by band WITHOUT writing the profile until the user edits.
    if(std::find(defaultOrder_.begin(),defaultOrder_.end(),reaeq::enabled(0))!=defaultOrder_.end()) {
        int bands=0;
        while(bands<64 &&
              std::find(defaultOrder_.begin(),defaultOrder_.end(),reaeq::enabled(bands))!=defaultOrder_.end())
            ++bands;
        order=reaeq::mergeLegacyCustomOrder(order,bands,count_,compareParamIndex);
    }
    // Older profiles predate the detector summary. Put just that missing virtual
    // control after the last detector filter, ahead of Filter Preview, without
    // rearranging user-authored physical order or saving until an actual edit.
    for(const int id:{-200000,-210000})if(validVirtual_.count(id) &&
         std::find(order.begin(),order.end(),id)==order.end()) {
        auto at=std::find_if(order.begin(),order.end(),[&](int physical){
            return physical>=0 && physical<count_ &&
                (dynamics::normalize(paramName_(physical))=="filter preview");
        });
        // Namespace qualification is intentional: `normalize` is also a
        // FxOrder member method.
        if(at!=order.end())order.insert(at,id);
    }
    normalize();
    // Older Lua profiles may contain a custom order without an explicit view flag.
    if(hasRealModifications())customCreated_=true;
}
namespace {
constexpr const char* lastNavigationKey = "lrp_last_navigation_v1";
}
std::string FxOrder::lastParameterRecord() const {
    const auto it = profile_.headers.find("LastParam");
    return loaded_ && it != profile_.headers.end() ? it->second : std::string();
}
std::optional<FxOrder::LastView> FxOrder::lastView() const {
    if (!loaded_) return std::nullopt;
    const auto record = extraValue(lastNavigationKey);
    const auto comma = record.find(',');
    if (comma == std::string::npos || record.find(',', comma + 1) != std::string::npos)
        return std::nullopt;
    try {
        const auto numeric = [](const std::string& text, int high) -> int {
            if (text.empty() || !std::all_of(text.begin(), text.end(), [](unsigned char c) {
                    return std::isdigit(c) != 0;
                })) return -1;
            std::size_t count = 0;
            const auto n = std::stoll(text, &count, 10);
            return count == text.size() && n <= high ? static_cast<int>(n) : -1;
        };
        const int slot = numeric(record.substr(0, comma), 12);
        const int position = numeric(record.substr(comma + 1), std::numeric_limits<int>::max());
        if (slot < 0 || position < 0) return std::nullopt;
        return LastView{slot, position};
    } catch (const std::exception&) {return std::nullopt;}
}

bool FxOrder::persistLastParameter(int parameter, const std::string& parameterName,
                                   int groupSlot, int viewPosition,
                                   const std::string& contextGrids) {
    if (!loaded_ || resource_.empty() || file_.empty() || parameterName.empty()) return false;
    if (groupSlot < 0 || groupSlot > 12 || viewPosition < 0) return false;
    // This is a navigation-only write. Preserve every user-authored CustomOrder,
    // GroupSlots, MIDI association, defaults and unrecognized field bytewise.
    const std::string newRecord = std::to_string(parameter) + "\t" + oneLine(parameterName);
    const LastView newView{groupSlot, viewPosition};
    const auto oldView = lastView();
    if (lastParameterRecord() == newRecord && oldView &&
        oldView->groupSlot == newView.groupSlot &&
        oldView->viewPosition == newView.viewPosition &&
        (contextGrids.empty() || extraValue("lrp_context_grids_v1") == contextGrids) &&
        existed_) return true;
    std::string payload = profile_.payload;
    const std::string prefix = "LastParam=";
    std::size_t begin = 0;
    bool found = false;
    while (begin < payload.size()) {
        const std::size_t newline = payload.find('\n', begin);
        const std::size_t end = newline == std::string::npos ? payload.size() : newline;
        if (payload.compare(begin, prefix.size(), prefix) == 0) {
            const bool crlf = end > begin && payload[end - 1] == '\r';
            payload.replace(begin, end - begin, prefix + newRecord + (crlf ? "\r" : ""));
            found = true;
            break;
        }
        if (newline == std::string::npos) break;
        begin = newline + 1;
    }
    if (!found) throw ProfileError("FX profile has no LastParam field");

    // The optional v1 entry belongs in [Extra], keeping legacy LastParam
    // readable by Lua and avoiding new required headers in Version=3.
    const std::string locationLine = std::string(lastNavigationKey) + "=" +
        std::to_string(groupSlot) + "," + std::to_string(viewPosition);
    bool inExtra = false, wroteLocation = false, hasExtra = false;
    std::size_t extraInsertAt = std::string::npos;
    std::string extraNewline = "\n";
    for (std::size_t at = 0; at < payload.size();) {
        const auto newline = payload.find('\n', at);
        const auto end = newline == std::string::npos ? payload.size() : newline;
        const auto logicalEnd = end > at && payload[end - 1] == '\r' ? end - 1 : end;
        if (payload.compare(at, logicalEnd - at, "[Extra]") == 0) {
            inExtra = true;
            hasExtra = true;
            extraInsertAt = newline == std::string::npos ? end : newline + 1;
            extraNewline = logicalEnd < end ? "\r\n" : "\n";
        } else if (inExtra && logicalEnd > at && payload[at] == '[' &&
                   payload[logicalEnd - 1] == ']') {
            break;
        } else if (inExtra && payload.compare(at, std::strlen(lastNavigationKey), lastNavigationKey) == 0 &&
                   at + std::strlen(lastNavigationKey) < logicalEnd &&
                   payload[at + std::strlen(lastNavigationKey)] == '=') {
            payload.replace(at, logicalEnd - at, locationLine);
            wroteLocation = true;
            break;
        }
        if (newline == std::string::npos) break;
        at = newline + 1;
    }
    if (!wroteLocation) {
        if (hasExtra) {
            // [Extra] at EOF with no newline is valid: terminate the header.
            if (extraInsertAt == payload.size() && !payload.empty() && payload.back() != '\n') {
                payload += extraNewline;
                extraInsertAt += extraNewline.size();
            }
            payload.insert(extraInsertAt, locationLine + extraNewline);
        } else {
            // A legacy .fx may have no [Extra]. Add only that optional
            // section, using its existing LF/CRLF line endings.
            const std::string newline = payload.find("\r\n") == std::string::npos ? "\n" : "\r\n";
            if (!payload.empty() && payload.back() != '\n') payload += newline;
            payload += "[Extra]" + newline + locationLine + newline;
        }
    }
    // Independent Plugin/Custom/12 Group cursors are one optional [Extra]
    // record. Patch just this record: do not serialize/normalize the user's
    // Custom Order, group membership, or MIDI data for navigation alone.
    if (!contextGrids.empty()) {
        const std::string key = "lrp_context_grids_v1=";
        const std::string line = key + contextGrids;
        bool inSection = false, replaced = false;
        std::size_t insertAt = std::string::npos;
        for (std::size_t at = 0; at < payload.size();) {
            const auto newline = payload.find('\n', at);
            const auto end = newline == std::string::npos ? payload.size() : newline;
            const auto logical = end > at && payload[end - 1] == '\r' ? end - 1 : end;
            if (payload.compare(at, logical - at, "[Extra]") == 0) {
                inSection = true;
                insertAt = newline == std::string::npos ? end : newline + 1;
            } else if (inSection && logical > at && payload[at] == '[' && payload[logical - 1] == ']') {
                break;
            } else if (inSection && payload.compare(at, key.size(), key) == 0) {
                payload.replace(at, logical - at, line);
                replaced = true;
                break;
            }
            if (newline == std::string::npos) break;
            at = newline + 1;
        }
        if (!replaced) {
            if (insertAt == std::string::npos)
                throw ProfileError("Cannot find FX Extra section for view cursors");
            const std::string newline = payload.find("\r\n") == std::string::npos ? "\n" : "\r\n";
            payload.insert(insertAt, line + newline);
        }
    }
    // Full parser and native envelope checks before touching the original.
    auto checked = parseLegacy(payload);
    if (checked.kind != ProfileKind::fx || checked.headers.at("PluginRaw") != rawName_)
        throw ProfileError("FX profile identity changed");
    const auto bytes = serializeNative(checked);
    std::filesystem::create_directories(file_.parent_path());
    if (existed_) {
        if (!std::filesystem::exists(file_) || std::filesystem::is_symlink(file_))
            throw ProfileError("FX profile replaced externally");
        const auto original = readFile(file_);
        if (sha256(original) != loadedDigest_)
            throw ProfileError("FX profile changed externally; position not overwritten");
        if (original == bytes) {profile_ = std::move(checked); return true;}
        const auto backupRoot = resource_ / L"LReaParams" / L"Backups" / L"ProfileEdits";
        std::filesystem::create_directories(backupRoot);
        if (!writeNewVerified(backupRoot / std::filesystem::u8path(sha256(original) + ".fx"), original))
            throw ProfileError("Cannot back up FX profile");
    } else if (std::filesystem::exists(file_)) {
        throw ProfileError("FX profile appeared externally");
    }
    auto temporary = file_;
    temporary += L".tmp-" + std::to_wstring(GetCurrentProcessId());
    if (std::filesystem::exists(temporary)) throw ProfileError("Stale FX profile temp file");
    if (!writeNewVerified(temporary, bytes)) throw ProfileError("Cannot stage FX position");
    if (parseNative(readFile(temporary)).payload != payload)
        throw ProfileError("Position profile verification failed");
    if (!MoveFileExW(temporary.c_str(), file_.c_str(), MOVEFILE_REPLACE_EXISTING | MOVEFILE_WRITE_THROUGH))
        throw ProfileError("Cannot commit FX position; backup preserved");
    if (readFile(file_) != bytes) throw ProfileError("FX position readback mismatch");
    profile_ = std::move(checked);
    existed_ = true;
    loadedDigest_ = sha256(bytes);
    return true;
}

bool FxOrder::save() {
    if(!loaded_ || resource_.empty())return false;
    normalize();
    const bool stored=storedCustomOrder();
    const std::string view=(custom && stored)?"custom":"plugin";
    std::vector<std::string> orderLines;
    if(stored)for(int id:order)orderLines.push_back(lineFor(id,paramName_(id),aliases.count(id)?aliases[id]:""));
    for(const auto& row:profile_.sections["CustomOrder"]) {
        int id=0;std::string label,alias;
        if(parseIndex(row,id,label,alias) && (!permitted(id)))orderLines.push_back(row);
    }
    std::map<std::string,std::string> extra;
    for(const auto& row:profile_.sections["Extra"]) {
        const auto p=row.find('=');if(p==std::string::npos)continue;
        extra[row.substr(0,p)]=unescape(row.substr(p+1));
    }
    for(auto it=extra.begin();it!=extra.end();) {
        if(it->first.rfind("cc_link_v1::param::",0)==0) {
            bool managed=false;try {const int id=std::stoi(it->first.substr(std::string("cc_link_v1::param::").size()));managed=permitted(id);}catch(...) {}
            if(managed)it=extra.erase(it);else ++it;
        }else ++it;
    }
    for(const auto& link:ccLinks)extra["cc_link_v1::param::"+std::to_string(link.first)]=link.second;
    std::string hiddenLines;
    for(int id:hidden) {if(!hiddenLines.empty())hiddenLines+='\n';hiddenLines+=lineFor(id,paramName_(id));}
    const auto oldHidden=extra.find("hidden_params_v1");
    if(oldHidden!=extra.end())for(const auto& row:split(oldHidden->second,'\n')) {
        int id=0;std::string label,alias;
        if(parseIndex(row,id,label,alias)&&!permitted(id)) {if(!hiddenLines.empty())hiddenLines+='\n';hiddenLines+=row;}
    }
    if(hiddenLines.empty())extra.erase("hidden_params_v1");else extra["hidden_params_v1"]=hiddenLines;
    for(int slot=1;slot<=12;++slot)extra.erase("group_slot_name_v1::slot::"+std::to_string(slot));
    for(const auto& pair:groupNames)extra["group_slot_name_v1::slot::"+std::to_string(pair.first)]=pair.second;
    std::string payload=patchProfile(profile_.payload,view,orderLines,extra,groups,paramSlots,profile_.sections["DefaultValues"],groupSlotMode,paramName_);
    Profile checked=parseLegacy(payload);
    const auto bytes=serializeNative(checked);
    std::filesystem::create_directories(file_.parent_path());
    // Never overwrite another writer's edits made after this navigator loaded.
    if(existed_) {
        if(!std::filesystem::exists(file_) || std::filesystem::is_symlink(file_))
            throw ProfileError("FX profile replaced externally");
        const auto current=readFile(file_);
        if(sha256(current)!=loadedDigest_)throw ProfileError("FX profile changed externally; not overwritten");
        if(current==bytes) {profile_=std::move(checked);return true;}
    } else if(std::filesystem::exists(file_))throw ProfileError("FX profile appeared externally");
    const auto backupRoot=resource_/L"LReaParams"/L"Backups"/L"ProfileEdits";
    if(existed_) {
        const auto original=readFile(file_);
        std::filesystem::create_directories(backupRoot);
        const auto backup=backupRoot/std::filesystem::u8path(sha256(original)+".fx");
        if(!writeNewVerified(backup,original))throw ProfileError("Could not back up FX profile");
    }
    auto temporary=file_;temporary+=L".tmp-"+std::to_wstring(GetCurrentProcessId());
    // Controlled in-process single-writer path; any existing temp prevents writing.
    if(std::filesystem::exists(temporary))throw ProfileError("Stale FX profile temp file");
    if(!writeNewVerified(temporary,bytes))throw ProfileError("Cannot write FX profile temp");
    if(parseNative(readFile(temporary)).payload!=payload)throw ProfileError("FX profile verification failed");
    if(!MoveFileExW(temporary.c_str(),file_.c_str(),MOVEFILE_REPLACE_EXISTING|MOVEFILE_WRITE_THROUGH))
        throw ProfileError("Cannot replace FX profile; backup preserved");
    if(readFile(file_)!=bytes)throw ProfileError("FX profile readback mismatch");
    profile_=std::move(checked);existed_=true;loadedDigest_=sha256(bytes);
    return true;
}
}

namespace lrp {
bool FxOrder::storedCustomOrder() const noexcept {
    return customCreated_ || hasRealModifications();
}
bool FxOrder::createCustomOrder() {
    if(storedCustomOrder()) { custom=true; return true; }
    custom=true;
    customCreated_=true;
    if(!save()) { custom=false;customCreated_=false;return false; }
    return true;
}
bool FxOrder::hasDefaultValues() const noexcept {
    const auto it=profile_.sections.find("DefaultValues");
    return it!=profile_.sections.end() && !it->second.empty();
}
int FxOrder::defaultValueCount() const noexcept {
    const auto it=profile_.sections.find("DefaultValues");
    if(it==profile_.sections.end())return 0;
    int records=0, bands=-1, parameters=0;
    for(const auto& line:it->second) {
        const auto parts=split(line,'\t');
        if(parts.size()>=3 && parts[0]=="META") {
            try {
                if(parts[1]=="REA_EQ_BAND_COUNT")bands=std::stoi(parts[2]);
                else if(parts[1]=="REA_EQ_PARAM_COUNT")parameters=std::stoi(parts[2]);
            } catch(...) {}
        } else ++records;
    }
    if(records==0 && bands>=0)return std::max(1,bands*5+std::max(0,parameters-bands*3));
    return records;
}
std::map<int,double> FxOrder::defaultValues() const {
    std::map<int,double> values;
    const auto it=profile_.sections.find("DefaultValues");
    if(it==profile_.sections.end())return values;
    for(const auto& row:it->second){
        const auto parts=split(row,'\t');
        if(parts.size()!=3)continue;
        try {
            size_t offset=0;const auto id=std::stoi(parts[0],&offset);
            if(offset!=parts[0].size()||id<0||id>=count_)continue;
            offset=0;const double norm=std::stod(parts[2],&offset);
            if(offset!=parts[2].size()||!std::isfinite(norm)||norm<0||norm>1)continue;
            // The writer normalizes control labels to a single line. Match
            // that same representation here, not the host's raw whitespace.
            if(oneLine(paramName_(id))!=parts[1])continue;
            values[id]=norm;
        } catch(...) {}
    }
    return values;
}
std::map<int,double> FxOrder::defaultValuesByIndex() const {
    std::map<int,double> values;
    const auto it=profile_.sections.find("DefaultValues");
    if(it==profile_.sections.end() || count_<=0)return {};
    std::multiset<std::string> savedNames, currentNames;
    bool namesChanged=false;
    for(const auto& row:it->second) {
        const auto parts=split(row,'\t');
        // Structural ReaEQ defaults and incomplete/unsupported legacy rows
        // cannot be safely restored using physical parameter indices.
        if(parts.size()!=3 || parts[0]=="META")return {};
        try {
            size_t end=0;
            const int id=std::stoi(parts[0],&end,10);
            if(end!=parts[0].size() || id<0 || id>=count_ || values.count(id))return {};
            end=0;
            const double value=std::stod(parts[2],&end);
            if(end!=parts[2].size() || !std::isfinite(value) || value<0 || value>1)return {};
            values.emplace(id,value);
            const auto current=oneLine(paramName_(id));
            const auto stored=oneLine(parts[1]);
            namesChanged |= stored!=current;
            savedNames.insert(stored);
            currentNames.insert(current);
        }catch(const std::exception&) {return {};}
    }
    if(values.size()!=static_cast<size_t>(count_))return {};
    // If all labels are still present but attached to other IDs, the synth
    // reordered its parameters. Do not silently apply the old audio values.
    if(namesChanged && savedNames==currentNames)return {};
    return values;
}
bool FxOrder::hasStructuralDefault() const noexcept {
    auto it=profile_.sections.find("DefaultValues");
    if(it==profile_.sections.end())return false;
    for(const auto& line:it->second)if(line.rfind("META\t",0)==0)return true;
    return false;
}
bool FxOrder::saveDefaultValues(const std::map<int,double>& values) {
    if(!loaded_)return false;
    std::vector<std::string> rows;
    for(const auto& [id,value]:values){
        if(id<0||id>=count_||!std::isfinite(value)||value<0||value>1)continue;
        std::ostringstream stream;stream.imbue(std::locale::classic());
        stream<<std::setprecision(17)<<value;
        rows.push_back(lineFor(id,paramName_(id))+"\t"+stream.str());
    }
    profile_.sections["DefaultValues"]=std::move(rows);
    return save();
}
bool FxOrder::deleteCcLink(int param) {
    if(!ccLinks.erase(param))return false;
    return save();
}
void FxOrder::deleteCustomOrder() {
    order.clear();for(int id=0;id<count_;++id)order.push_back(id);
    aliases.clear();hidden.clear();custom=false;customCreated_=false;
    if(!save())throw ProfileError("Cannot save deleted Custom Order");
}
}

namespace lrp {
std::string FxOrder::extraValue(const std::string& key) const {
    const auto it=profile_.sections.find("Extra");if(it==profile_.sections.end())return {};
    for(const auto& row:it->second)if(row.rfind(key+"=",0)==0)return unescape(row.substr(key.size()+1));
    return {};
}
void FxOrder::setExtraValue(const std::string& key,const std::string& value) {
    auto& rows=profile_.sections["Extra"];
    rows.erase(std::remove_if(rows.begin(),rows.end(),[&](const std::string& row){return row.rfind(key+"=",0)==0;}),rows.end());
    if(!value.empty())rows.push_back(key+"="+escape(value));
}
bool FxOrder::regenerateDefaults(const std::map<int,double>& values) {
    if(hasStructuralDefault())return false;
    return saveDefaultValues(values);
}
}

namespace lrp {
std::vector<std::string> FxOrder::defaultRows() const {
    const auto it=profile_.sections.find("DefaultValues");return it==profile_.sections.end()?std::vector<std::string>{}:it->second;
}
bool FxOrder::saveDefaultRows(const std::vector<std::string>& rows) {profile_.sections["DefaultValues"]=rows;return save();}
std::string FxOrder::defaultMeta(const std::string& key) const {
    const std::string prefix="META\t"+key+"\t";
    for(const auto& row:defaultRows())if(row.rfind(prefix,0)==0)return row.substr(prefix.size());return {};
}
}
