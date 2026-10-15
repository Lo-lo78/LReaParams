#include "lrp/FxOrder.h"
#include "lrp/Storage.h"
#include <algorithm>
#include <cctype>
#include <cstdio>
#include <iomanip>
#include <sstream>
#include <cmath>
#include <locale>
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
        if(end!=trim(fields[0]).size()||val<0||val>2147483647) return false;
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
            out.push_back(std::to_string(pair.first)+"="+escape(joined));
        }
    };
    auto emitParams=[&] { if(paramsEmitted)return;paramsEmitted=true;out.push_back("[ParamSlots]");
        for(const auto& pair:params)out.push_back(std::to_string(pair.first)+"="+lineFor(pair.second,name(pair.second))); };
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
        if(section=="CustomOrder"||section=="Extra"||section=="GroupSlots"||section=="ParamSlots"||section=="DefaultValues")continue;
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
    file_.clear();resource_.clear();rawName_.clear();loadedDigest_.clear();paramName_={};count_=0;profile_={};loaded_=existed_=false;
}
void FxOrder::normalize() {
    std::vector<int> kept;
    std::vector<bool> included(static_cast<size_t>(std::max(count_,0)),false);
    for(int i:order) if(i>=0&&i<count_) {kept.push_back(i);included[static_cast<size_t>(i)]=true;}
    for(int i=0;i<count_;++i)if(!included[static_cast<size_t>(i)])kept.push_back(i);
    order.swap(kept);
    for(auto it=hidden.begin();it!=hidden.end();)if(*it<0||*it>=count_)it=hidden.erase(it);else ++it;
    for(auto it=aliases.begin();it!=aliases.end();)if(it->first<0||it->first>=count_)it=aliases.erase(it);else ++it;
}
std::vector<int> FxOrder::visibleOrder() const {
    std::vector<int> visible;
    if(custom)for(int id:order) { if(!hidden.count(id))visible.push_back(id); }
    else for(int i=0;i<count_;++i)visible.push_back(i);
    return visible;
}
std::string FxOrder::label(int id) const {
    if(custom) { const auto it=aliases.find(id);if(it!=aliases.end()&&!it->second.empty())return it->second; }
    return paramName_?paramName_(id):"";
}
bool FxOrder::hasRealModifications() const {
    if(!aliases.empty()||!hidden.empty())return true;
    if(order.size()!=static_cast<size_t>(count_))return true;
    for(int i=0;i<count_;++i)if(order[static_cast<size_t>(i)]!=i)return true;
    return false;
}
void FxOrder::load(const std::filesystem::path& resource,const std::string& rawName,
                   int paramCount,std::function<std::string(int)> paramName) {
    reset();resource_=resource;rawName_=rawName;paramName_=std::move(paramName);
    count_=std::max(0,paramCount);
    for(int i=0;i<count_;++i)order.push_back(i);
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
    groupSlotMode=profile_.headers.at("SlotAccessMode")=="group";
    for(const auto& row:profile_.sections["CustomOrder"]) {
        int id=0;std::string name,alias;
        if(!parseIndex(row,id,name,alias))continue;
        if(id>=0&&id<count_) {order.push_back(id);if(!alias.empty())aliases[id]=alias;}
        else if(!name.empty()) {
            for(int i=0;i<count_;++i) if(paramName_(i)==name) {order.push_back(i);if(!alias.empty())aliases[i]=alias;break;}
        }
    }
    if(!profile_.sections["CustomOrder"].empty()) {
        order.erase(order.begin(),order.begin()+count_);
    }
    for(const auto& row:profile_.sections["Extra"]) {
        const auto pos=row.find('=');if(pos==std::string::npos)continue;
        const auto key=row.substr(0,pos), value=unescape(row.substr(pos+1));
        if(key=="hidden_params_v1") for(const auto& line:split(value,'\n')) {
            int id=0;std::string name,alias;
            if(parseIndex(line,id,name,alias)&&id>=0&&id<count_)hidden.insert(id);
        }
        const std::string ccPrefix="cc_link_v1::param::";
        if(key.rfind(ccPrefix,0)==0) {
            try {int param=std::stoi(key.substr(ccPrefix.size()));
                if(param>=0 && param<count_ && !value.empty())ccLinks[param]=value;
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
        if(parseIndex(unescape(row.substr(p+1)),id,name,alias)&&id>=0&&id<count_)paramSlots[slot]=id;
    }
    for(const auto& row:profile_.sections["GroupSlots"]) {
        auto p=row.find('=');if(p==std::string::npos)continue;
        int slot=0;try {slot=std::stoi(row.substr(0,p));}catch(...){continue;}
        if(slot<1||slot>12)continue;
        for(auto& line:split(unescape(row.substr(p+1)),'\n')) {
            int id=0;std::string name,alias;
            if(parseIndex(line,id,name,alias)&&id>=0&&id<count_)groups[slot].push_back(id);
        }
    }
    normalize();
}
bool FxOrder::save() {
    if(!loaded_ || resource_.empty())return false;
    normalize();
    const bool modified=hasRealModifications();
    const std::string view=(custom && modified)?"custom":"plugin";
    std::vector<std::string> orderLines;
    if(modified)for(int id:order)orderLines.push_back(lineFor(id,paramName_(id),aliases.count(id)?aliases[id]:""));
    std::map<std::string,std::string> extra;
    for(const auto& row:profile_.sections["Extra"]) {
        const auto p=row.find('=');if(p==std::string::npos)continue;
        extra[row.substr(0,p)]=unescape(row.substr(p+1));
    }
    for(int param=0;param<count_;++param) {
        const auto key="cc_link_v1::param::"+std::to_string(param);
        auto it=ccLinks.find(param);
        if(it==ccLinks.end())extra.erase(key);
        else extra[key]=it->second;
    }
    std::string hiddenLines;
    for(int id:hidden) {if(!hiddenLines.empty())hiddenLines+='\n';hiddenLines+=lineFor(id,paramName_(id));}
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
    return hasRealModifications();
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
            values[id]=norm;
        } catch(...) {}
    }
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
    aliases.clear();hidden.clear();custom=false;
    if(!save())throw ProfileError("Cannot save deleted Custom Order");
}
}
