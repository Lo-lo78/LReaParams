// LReaParams 0.0.45: system-clipboard values and Lua-compatible full-FX
// snapshots.  Only physical REAPER parameter indices enter this format.
#include "lrp/FxNavigator.h"
#include <algorithm>
#include <cerrno>
#include <cmath>
#include <cstdlib>
#include <cstring>
#include <iomanip>
#include <limits>
#include <locale>
#include <sstream>
#include <string>
#include <vector>
#include <windows.h>

namespace lrp {
namespace {
constexpr const char* kFull = "FXPARAM_SNAPSHOT_V1"; // exact Lua 6.3A marker
constexpr const char* kSingle = "FXPARAM_VALUE_V1";
constexpr size_t kClipboardLimit = 8u * 1024u * 1024u;
constexpr int kMaxParams = 100000;

// String fields follow fx_snapshot_escape()/unescape() in the original Lua.
std::string escapeField(const std::string& text) {
    std::string result;
    for (char c : text) {
        switch(c) {
            case '\\': result += "\\\\"; break;
            case '\t': result += "\\t"; break;
            case '\r': result += "\\r"; break;
            case '\n': result += "\\n"; break;
            default: result += c; break;
        }
    }
    return result;
}
std::string unescapeField(const std::string& value) {
    std::string result;
    for(size_t i=0;i<value.size();++i) {
        if(value[i]=='\\' && i+1<value.size()) {
            const char next=value[i+1];
            if(next=='t'||next=='r'||next=='n'||next=='\\') {
                result+=(next=='t'?'\t':next=='r'?'\r':next=='n'?'\n':'\\');
                ++i;continue;
            }
        }
        result+=value[i];
    }
    return result;
}
std::string numeric(double value) {
    std::ostringstream out;
    out.imbue(std::locale::classic());out<<std::setprecision(17)<<value;
    return out.str();
}
bool parseInt(const std::string& source,int& value) {
    if(source.empty())return false;
    char* end=nullptr;errno=0;
    const long v=std::strtol(source.c_str(),&end,10);
    if(errno || end!=source.c_str()+source.size() || v<0 || v>kMaxParams)return false;
    value=static_cast<int>(v);return true;
}
bool parseValue(const std::string& source,double& value) {
    if(source.empty())return false;
    char* end=nullptr;errno=0;
    const double v=std::strtod(source.c_str(),&end);
    if(errno || end!=source.c_str()+source.size() || !std::isfinite(v) || v<0 || v>1)return false;
    value=v;return true;
}
std::vector<std::string> lines(const std::string& text) {
    std::vector<std::string> result;
    std::istringstream in(text);std::string line;
    while(std::getline(in,line)) {
        if(!line.empty()&&line.back()=='\r')line.pop_back();
        if(!line.empty())result.push_back(std::move(line));
    }
    return result;
}
std::wstring toWide(const std::string& utf8) {
    if(utf8.empty())return {};
    const int size=MultiByteToWideChar(CP_UTF8,MB_ERR_INVALID_CHARS,utf8.data(),static_cast<int>(utf8.size()),nullptr,0);
    if(size<=0)return {};
    std::wstring wide(static_cast<size_t>(size),L'\0');
    if(MultiByteToWideChar(CP_UTF8,MB_ERR_INVALID_CHARS,utf8.data(),static_cast<int>(utf8.size()),&wide[0],size)!=size)return {};
    return wide;
}
std::string toUtf8(const wchar_t* wide,int count) {
    if(!wide||count<=0)return {};
    const int size=WideCharToMultiByte(CP_UTF8,WC_ERR_INVALID_CHARS,wide,count,nullptr,0,nullptr,nullptr);
    if(size<=0)return {};
    std::string utf8(static_cast<size_t>(size),'\0');
    if(WideCharToMultiByte(CP_UTF8,WC_ERR_INVALID_CHARS,wide,count,&utf8[0],size,nullptr,nullptr)!=size)return {};
    return utf8;
}
bool clipboardWrite(const std::string& utf8) {
    if(utf8.empty()||utf8.size()>kClipboardLimit)return false;
    const auto wide=toWide(utf8);
    if(wide.empty()||wide.size()>kClipboardLimit / sizeof(wchar_t))return false;
    if(!OpenClipboard(nullptr))return false;
    bool success=false;
    if(EmptyClipboard()) {
        HGLOBAL allocated=GlobalAlloc(GMEM_MOVEABLE,(wide.size()+1)*sizeof(wchar_t));
        if(allocated) {
            if(void* bytes=GlobalLock(allocated)) {
                std::memcpy(bytes,wide.c_str(),(wide.size()+1)*sizeof(wchar_t));
                GlobalUnlock(allocated);
                if(SetClipboardData(CF_UNICODETEXT,allocated)) {
                    success=true;allocated=nullptr; // clipboard now owns allocation
                }
            }
            if(allocated)GlobalFree(allocated);
        }
    }
    CloseClipboard();return success;
}
bool clipboardRead(std::string& text) {
    text.clear();if(!OpenClipboard(nullptr))return false;
    bool result=false;
    if(HANDLE data=GetClipboardData(CF_UNICODETEXT)) {
        if(const wchar_t* wide=static_cast<const wchar_t*>(GlobalLock(data))) {
            const SIZE_T bytes=GlobalSize(data);
            const size_t capacity=static_cast<size_t>(bytes / sizeof(wchar_t));
            // Bounded NUL scan: a malformed clipboard block cannot force a
            // read outside allocated memory or allocate unbounded strings.
            if(capacity>0 && capacity<=kClipboardLimit / sizeof(wchar_t)) {
                size_t len=0;while(len<capacity && wide[len]!=L'\0')++len;
                if(len<capacity && len<=static_cast<size_t>(std::numeric_limits<int>::max())) {
                    text=toUtf8(wide,static_cast<int>(len));result=!text.empty();
                }
            }
            GlobalUnlock(data);
        }
    }
    CloseClipboard();return result;
}
struct Snapshot {
    std::string plugin;
    std::vector<std::string> names;
    std::vector<double> values;
};
bool decodeSnapshot(const std::string& text,Snapshot& snap) {
    const auto rows=lines(text);
    if(rows.size()<3 || rows[0]!=kFull)return false;
    if(rows[1].compare(0,10,"PluginRaw\t")!=0 || rows[2].compare(0,11,"ParamCount\t")!=0)return false;
    snap.plugin=unescapeField(rows[1].substr(10));
    int count=0;
    if(snap.plugin.empty()||!parseInt(rows[2].substr(11),count)||count<1)return false;
    if(rows.size()!=static_cast<size_t>(count)+3)return false;
    snap.names.resize(static_cast<size_t>(count));snap.values.resize(static_cast<size_t>(count));
    std::vector<bool> seen(static_cast<size_t>(count),false);
    for(size_t line=3;line<rows.size();++line) {
        const auto& row=rows[line];if(row.compare(0,2,"P\t")!=0)return false;
        const auto first=row.find('\t',2);if(first==std::string::npos)return false;
        const auto second=row.find('\t',first+1);if(second==std::string::npos)return false;
        int id=0;double value=0;
        if(!parseInt(row.substr(2,first-2),id) || id>=count || seen[static_cast<size_t>(id)] ||
           !parseValue(row.substr(first+1,second-first-1),value))return false;
        seen[static_cast<size_t>(id)]=true;
        snap.values[static_cast<size_t>(id)]=value;
        snap.names[static_cast<size_t>(id)]=unescapeField(row.substr(second+1));
    }
    return std::all_of(seen.begin(),seen.end(),[](bool v){return v;});
}
} // namespace

void FxNavigator::copyParameterValue() {
    if(!valid()||parameter_<0||parameter_>=count_) {speech_("No physical parameter to copy");return;}
    const double value=take_?TakeFX_GetParamNormalized(take_,fx_,parameter_):TrackFX_GetParamNormalized(track_,fx_,parameter_);
    if(!std::isfinite(value)||value<0||value>1){speech_("Cannot read parameter value");return;}
    // Standalone parameter value can be pasted into a different physical
    // parameter: normalized 0..1. Never copy an alias as parameter identity.
    const std::string message=std::string(kSingle)+"\nNorm\t"+numeric(value)+"\n";
    speech_(clipboardWrite(message)?"Value copied":"Clipboard unavailable");
}
void FxNavigator::copyFxSnapshot() {
    if(!valid()||count_<1||count_>kMaxParams ||browserIndex_<0||
       browserIndex_>=static_cast<int>(entries_.size())) {
        speech_("No plugin parameters to snapshot");return;
    }
    const int now=take_?TakeFX_GetNumParams(take_,fx_):TrackFX_GetNumParams(track_,fx_);
    if(now!=count_){speech_("FX parameters changed. Snapshot cancelled");return;}
    const std::string plugin=entries_[static_cast<size_t>(browserIndex_)].name;
    if(plugin.empty()){speech_("Unknown plugin. Snapshot cancelled");return;}
    std::string output=std::string(kFull)+"\nPluginRaw\t"+escapeField(plugin)+
        "\nParamCount\t"+std::to_string(count_)+"\n";
    for(int i=0;i<count_;++i) {
        char name[4096]{};
        const bool named=take_?TakeFX_GetParamName(take_,fx_,i,name,sizeof(name)):
                               TrackFX_GetParamName(track_,fx_,i,name,sizeof(name));
        const double value=take_?TakeFX_GetParamNormalized(take_,fx_,i):TrackFX_GetParamNormalized(track_,fx_,i);
        if(!named||!std::isfinite(value)||value<0||value>1){speech_("FX snapshot cancelled");return;}
        output+="P\t"+std::to_string(i)+"\t"+numeric(value)+"\t"+escapeField(name)+"\n";
        if(output.size()>kClipboardLimit){speech_("FX snapshot too large");return;}
    }
    if(!clipboardWrite(output)){speech_("Clipboard unavailable");return;}
    speech_("FX snapshot copied. "+fxDisplayName()+". "+std::to_string(count_)+" parameters");
}
void FxNavigator::pasteFxClipboard() {
    if(!valid()){speech_("FX context changed");return;}
    std::string text;
    if(!clipboardRead(text)) {speech_("Clipboard empty or unavailable");return;}
    const auto rows=lines(text);
    if(rows.empty())return;
    if(rows[0]==kSingle) {
        if(rows.size()!=2 || rows[1].compare(0,5,"Norm\t")!=0){speech_("Invalid value clipboard");return;}
        double normalized=0;
        if(!parseValue(rows[1].substr(5),normalized)){speech_("Invalid value clipboard");return;}
        if(parameter_<0||parameter_>=count_){speech_("No physical destination parameter");return;}
        // Reuse the existing setter (Undo, detector discretization, readback,
        // REAPER EndParamEdit, error reporting and spoken value).
        setValue(normalized);
        pickup_.erase(parameter_);
        return;
    }
    if(rows[0]!=kFull)return; // foreign text is not an FX snapshot
    Snapshot snap;
    if(!decodeSnapshot(text,snap)){speech_("Invalid FX snapshot");return;}
    if(browserIndex_<0 || browserIndex_>=static_cast<int>(entries_.size()) ||
       snap.plugin!=entries_[static_cast<size_t>(browserIndex_)].name) {
        speech_("Snapshot plugin does not match");return;
    }
    const int now=take_?TakeFX_GetNumParams(take_,fx_):TrackFX_GetNumParams(track_,fx_);
    if(now!=count_ || static_cast<int>(snap.values.size())!=now){speech_("Snapshot parameter count does not match");return;}
    for(int i=0;i<count_;++i) {
        char name[4096]{};
        const bool ok=take_?TakeFX_GetParamName(take_,fx_,i,name,sizeof(name)):
                            TrackFX_GetParamName(track_,fx_,i,name,sizeof(name));
        if(!ok||snap.names[static_cast<size_t>(i)]!=name){
            speech_("Snapshot parameters do not match at parameter "+std::to_string(i+1));return;
        }
    }
    // Validate and capture the complete original state before ANY write.
    std::vector<double> old(static_cast<size_t>(count_));
    for(int i=0;i<count_;++i) {
        const double v=take_?TakeFX_GetParamNormalized(take_,fx_,i):TrackFX_GetParamNormalized(track_,fx_,i);
        if(!std::isfinite(v)||v<0||v>1){speech_("Snapshot paste cancelled");return;}
        old[static_cast<size_t>(i)]=v;
    }
    const int flags=take_?UNDO_STATE_ITEMS:UNDO_STATE_FX;
    Undo_BeginBlock2(project_);
    int written=0;
    for(int i=0;i<count_;++i) {
        const bool ok=take_?TakeFX_SetParamNormalized(take_,fx_,i,snap.values[static_cast<size_t>(i)]):
                            TrackFX_SetParamNormalized(track_,fx_,i,snap.values[static_cast<size_t>(i)]);
        if(!ok)break;
        ++written;
        if(take_)TakeFX_EndParamEdit(take_,fx_,i);else TrackFX_EndParamEdit(track_,fx_,i);
    }
    if(written!=count_) {
        // Undo-aware best-effort rollback. Never announce successful paste
        // after a partial failure; REAPER Undo remains the final fallback.
        // The failed setter may have written before reporting false (some
        // REAPER FX do that). Include its index in the rollback attempt.
        for(int i=std::min(written,count_-1);i>=0;--i) {
            if(take_){TakeFX_SetParamNormalized(take_,fx_,i,old[static_cast<size_t>(i)]);TakeFX_EndParamEdit(take_,fx_,i);}
            else {TrackFX_SetParamNormalized(track_,fx_,i,old[static_cast<size_t>(i)]);TrackFX_EndParamEdit(track_,fx_,i);}
        }
    }
    Undo_EndBlock2(project_,"LReaParams: paste FX parameter snapshot",flags);
    if(written!=count_){speech_("FX snapshot paste incomplete. Use REAPER Undo");return;}
    pickup_.clear();
    speech_("FX snapshot pasted. "+fxDisplayName()+". "+std::to_string(count_)+" parameters");
}
} // namespace lrp
