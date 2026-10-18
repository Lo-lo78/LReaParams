#include "lrp/FxNavigator.h"
#include "lrp/ReaEqVirtual.h"
#include <algorithm>
#include <cctype>
#include <climits>
#include <cmath>
#include <cstring>
#include <cwchar>
#include <stdexcept>
#include <sstream>
#include <limits>
#include <windows.h>

namespace lrp {
namespace {
bool guidSame(const GUID* a,const GUID& b) { return a && std::memcmp(a,&b,sizeof(GUID))==0; }
std::string originalName(MediaTrack* track,MediaItem_Take* take,int fx,int id) {
    if(id==compareParamIndex)return "Compare";
    if(id<0)return {};
    char buffer[4096]{};
    const bool ok=take?TakeFX_GetParamName(take,fx,id,buffer,sizeof(buffer))
                      :TrackFX_GetParamName(track,fx,id,buffer,sizeof(buffer));
    return ok?buffer:"";
}
std::string keyName(const Key& k) {
    switch(k.vk) {
        case VK_UP:return "up";case VK_DOWN:return "down";
        case VK_LEFT:return "left";case VK_RIGHT:return "right";
        case VK_PRIOR:case VK_HOME:return "up";
        case VK_NEXT:case VK_END:return "down";
        default:return "";
    }
}
bool opposite(const std::string& a,const std::string& b) {
    return (a=="up"&&b=="down")||(a=="down"&&b=="up")||
           (a=="left"&&b=="right")||(a=="right"&&b=="left");
}
}

// Store new native -10..+10 values without corrupting the Lua's 18-entry
// param_step_scales_v1. Both live in [Extra] of the same .fx plugin profile.
// Lua v3/v2/old numeric profiles are consulted only when no native override
// exists. Raw REAPER names guard against parameter indices changing.
namespace {
constexpr const char* nativeParamStepsKey = "lrp_param_step_scales_v1";
constexpr const char* legacyParamStepsKey = "param_step_scales_v1";
constexpr double luaStepMultipliers[] = {
    0.0001,0.0002,0.0005,0.002,0.01,0.02,0.05,0.10,0.25,0.50,
    1.00,2.00,5.00,10.0,20.0,50.0,100.0,500.0
};
bool stepRow(const std::string& line,int& id,std::string& name,std::string& token) {
    const auto first=line.find('\t');
    if(first==std::string::npos)return false;
    const auto second=line.find('\t',first+1);
    if(second==std::string::npos)return false;
    try {
        size_t end=0;
        const long candidate=std::stol(line.substr(0,first),&end,10);
        if(end!=first || candidate<std::numeric_limits<int>::min() || candidate>std::numeric_limits<int>::max())return false;
        id=static_cast<int>(candidate);
        name=line.substr(first+1,second-first-1);
        token=line.substr(second+1);
        return true;
    }catch(...) {return false;}
}
bool parseStepNumber(const std::string& token,int& result) {
    try {size_t consumed=0;const auto n=std::stoi(token,&consumed,10);
        if(consumed!=token.size())return false;result=n;return true;
    }catch(...) {return false;}
}
int legacyStep(const std::string& token) {
    auto version=std::string{};
    auto number=token;
    const auto sep=token.find(':');
    if(sep!=std::string::npos) {version=token.substr(0,sep);number=token.substr(sep+1);}
    int index=0;if(!parseStepNumber(number,index))return 0;
    if(version=="v3") {}
    else if(version=="v2")index+=2;
    else if(version.empty())index+=3;
    else return 0;
    if(index<1 || index>18)return 0;
    // The C++ navigator already uses Step -10..+10 as powers of two.
    // Choose the nearest magnitude, never replace existing legacy bytes.
    const auto factor=luaStepMultipliers[index-1];
    return std::clamp(static_cast<int>(std::lround(std::log2(factor))),-10,10);
}
}
std::string FxNavigator::stepParameterName(int param) const {
    if(param==compareParamIndex)return "Compare";
    if(eqVirtualValid(param))return eqVirtualName(param);
    if(dynamicsVirtualValid(param))return dynamicsVirtualName(param);
    if(param<0 || param>=count_)return {};
    // Alias changes must not invalidate saved Step identities.
    return originalName(track_,take_,fx_,param);
}
void FxNavigator::loadParameterSteps() {
    parameterSteps_.clear(); parameterStepsDirty_=false;
    stepActiveParameter_=INT_MIN;
    const auto text=fxOrder_.extraValue(nativeParamStepsKey);
    for(const auto& line:split(text,'\n')) {
        int id=0,step=0;std::string name,raw;
        if(!stepRow(line,id,name,raw) || !parseStepNumber(raw,step) || step< -10 || step>10)continue;
        parameterSteps_[id]={name,step};
    }
}
int FxNavigator::savedStepForParameter(int param) const {
    const auto wanted=stepParameterName(param);
    if(wanted.empty())return 0;
    const auto byId=parameterSteps_.find(param);
    if(byId!=parameterSteps_.end() && (byId->second.first.empty() || byId->second.first==wanted))
        return byId->second.second;
    // If plugin version shifted indices, only recover an unambiguous name.
    int found=0,matchCount=0;
    for(const auto& row:parameterSteps_)
        if(!row.second.first.empty() && row.second.first==wanted) {
            found=row.second.second;++matchCount;
        }
    if(matchCount==1)return found;
    if(matchCount>1)return 0;
    const auto legacy=fxOrder_.extraValue(legacyParamStepsKey);
    int legacyIndex=0,legacyValue=0,legacyMatches=0;
    for(const auto& line:split(legacy,'\n')) {
        int id=0;std::string name,token;
        if(!stepRow(line,id,name,token))continue;
        const int v=legacyStep(token);
        if(id==param && (name.empty() || name==wanted))return v;
        if(!name.empty() && name==wanted){legacyIndex=id;legacyValue=v;++legacyMatches;}
    }
    (void)legacyIndex;
    return legacyMatches==1?legacyValue:0;
}
void FxNavigator::syncParameterStep() {
    if(!active_ || count_<=0 || browserIndex_<0)return;
    if(stepActiveParameter_==parameter_)return;
    if(parameterStepsDirty_)flushParameterSteps();
    stepScale_=savedStepForParameter(parameter_);
    stepActiveParameter_=parameter_;
}
void FxNavigator::markParameterStepChanged() {
    if(!active_ || count_<=0 || browserIndex_<0 || !persistentPositionWriter_)return;
    if(stepActiveParameter_!=parameter_)syncParameterStep();
    if(stepActiveParameter_!=parameter_)return;
    const auto name=stepParameterName(parameter_);
    if(name.empty())return;
    parameterSteps_[parameter_]={name,std::clamp(stepScale_,-10,10)};
    parameterStepsDirty_=true;
}
void FxNavigator::stageParameterSteps() {
    std::string data;
    for(const auto& row:parameterSteps_) {
        if(!data.empty())data+='\n';
        // Names originate in host label fields; keep each record on one line.
        std::string name=row.second.first;
        for(char& c:name)if(c=='\t'||c=='\r'||c=='\n')c=' ';
        data+=std::to_string(row.first)+"\t"+name+"\t"+std::to_string(row.second.second);
    }
    fxOrder_.setExtraValue(nativeParamStepsKey,data);
}
bool FxNavigator::flushParameterSteps() noexcept {
    if(!parameterStepsDirty_ || !persistentPositionWriter_)return true;
    try {
        stageParameterSteps();
        if(!fxOrder_.save())return false;
        parameterStepsDirty_=false;
        return true;
    }catch(const std::exception&) {
        OutputDebugStringW(L"LReaParams: could not persist per-parameter Step; profile untouched.\n");
        return false;
    }
}
std::string FxNavigator::displayName() const {
    auto label=fxOrder_.label(parameter_);
    return label.empty()?parameterName_:label;
}
void FxNavigator::loadFxOrder() {
    flushParameterSteps();
    // Raw REAPER name corresponds to Lua get_fx_raw_label(), not its stripped
    // display name or a per-instance GUID.
    const std::string name=entries_.at(static_cast<size_t>(browserIndex_)).name;
    std::vector<int> nativeOrder;
    if(isReaEq() && eqBandCount()>0)
        nativeOrder=reaeq::pluginOrder(eqBandCount(),count_,compareParamIndex);
    else if(isReaComp() || isReaGate()) nativeOrder=dynamicsPluginOrder();
    fxOrder_.load(resourceRoot_,name,count_,[this](int id) {
        return id==compareParamIndex?std::string("Compare"):
            eqVirtualValid(id)?eqVirtualName(id):
            dynamicsVirtualValid(id)?dynamicsVirtualName(id):
            (id>=0 && id<count_?([this,id]{auto alias=dynamicsAlias(id);return alias.empty()?originalName(track_,take_,fx_,id):alias;}()):std::string());
    },nativeOrder);
    loadParameterSteps();
    groupSlot_=0;groupEditAll_=false;searchMode_=false;editF7_=false;
    f7FilterActive_=false;f7FullView_.clear();f7FilterPositions_.clear();f7FilterQuery_.clear();
    slotMode_=fxOrder_.groupSlotMode?0:1;
    visible_=fxOrder_.visibleOrder();
    int preference=-1;
    if(auto* memory=contextMemory())for(const auto& pos:memory->positions)
        if(guidSame(&pos.fxGuid,fxGuid_)) {preference=pos.viewPosition;f7Selected_=pos.f7Selected;fxOrder_.custom=pos.customView && fxOrder_.storedCustomOrder();break;}
    rebuildView(parameter_,preference);
    snapshotDefaultsIfMissing();
    resetMidiContext();
}
void FxNavigator::rebuildView(int preferParam,int preferPosition) {
    if(groupSlot_ && !groupEditAll_) {
        visible_=fxOrder_.groups[groupSlot_];
        visible_.erase(std::remove(visible_.begin(),visible_.end(),compareParamIndex),visible_.end());
    } else visible_=fxOrder_.visibleOrder();
    if(visible_.empty()) {
        // Even when all parameters are hidden, retain a valid host param for
        // real-time FX validation and let the edit UI announce an empty view.
        viewPos_=0;return;
    }
    int next=-1;
    if(preferPosition>=0 && preferPosition<static_cast<int>(visible_.size()) &&
       visible_[static_cast<size_t>(preferPosition)]==preferParam)next=preferPosition;
    if(next<0)for(size_t i=0;i<visible_.size();++i)
        if(visible_[i]==preferParam){next=static_cast<int>(i);break;}
    if(next<0)next=0;
    viewPos_=next;parameter_=visible_[static_cast<size_t>(next)];
    parameterName_=parameterName();
}
int FxNavigator::f7OriginalPosition(int filteredPos) const {
    if(f7FilterActive_ && filteredPos>=0 && filteredPos<static_cast<int>(f7FilterPositions_.size()))
        return f7FilterPositions_[static_cast<size_t>(filteredPos)];
    return filteredPos;
}
void FxNavigator::clearF7Filter() {
    if(!f7FilterActive_)return;
    const int original=f7OriginalPosition(viewPos_);
    visible_=f7FullView_;
    viewPos_=std::clamp(original,0,std::max(0,static_cast<int>(visible_.size())-1));
    if(!visible_.empty()){
        parameter_=visible_[static_cast<size_t>(viewPos_)];
        parameterName_=parameterName();
    }
    f7FilterActive_=false;f7FullView_.clear();f7FilterPositions_.clear();f7FilterQuery_.clear();
    f7SnakePath_.clear();f7SnakeDirections_.clear();
}
void FxNavigator::applyF7Filter(const std::string& query, bool speak) {
    // This is a shared filtered GRID, not a one-result jump. It works both
    // outside F7 and in F7, where selections refer to unfiltered occurrences.
    clearF7Filter();
    if(query.empty()){if(speak)speech_("Search cleared. "+currentParameterSpeech());return;}
    f7FullView_=visible_;
    f7FilterPositions_.clear();
    for(int i=0;i<static_cast<int>(f7FullView_.size());++i){
        const std::string label=fxOrder_.label(f7FullView_[static_cast<size_t>(i)]);
        if(matchesSearch(label,query))f7FilterPositions_.push_back(i);
    }
    f7FilterQuery_=query;
    if(f7FilterPositions_.empty()){
        f7FullView_.clear();f7FilterQuery_.clear();
        if(speak)speech_(editF7_?"No results. Selection kept":"No results");return;
    }
    visible_.clear();
    for(int i:f7FilterPositions_)visible_.push_back(f7FullView_[static_cast<size_t>(i)]);
    f7FilterActive_=true;viewPos_=0;parameter_=visible_.front();parameterName_=parameterName();
    if(speak)speech_("Search results. "+std::to_string(visible_.size())+" results. "+
            (editF7_?std::to_string(f7Selected_.size())+" selected. ":std::string())+currentParameterSpeech());
}
FxNavigator::EditHistory FxNavigator::captureHistory() const {
    return {fxOrder_.order,fxOrder_.aliases,fxOrder_.hidden,fxOrder_.groups,fxOrder_.groupNames};
}
void FxNavigator::restoreHistory(const EditHistory& v){
    clearF7Filter();
    fxOrder_.order=v.order;fxOrder_.aliases=v.aliases;fxOrder_.hidden=v.hidden;
    fxOrder_.groups=v.groups;fxOrder_.groupNames=v.groupNames;
    saveStructure();f7Selected_.clear();rebuildView(parameter_);
}
void FxNavigator::saveUndo(){
    if(!editF7_)return;
    if(undoStack_.size()>=64)undoStack_.erase(undoStack_.begin());
    undoStack_.push_back(captureHistory());redoStack_.clear();
}
void FxNavigator::f7Undo(bool redo){
    auto& source=redo?redoStack_:undoStack_;
    auto& target=redo?undoStack_:redoStack_;
    if(source.empty()){speech_(redo?"Nothing to redo":"Nothing to undo");return;}
    target.push_back(captureHistory());
    const auto state=source.back();source.pop_back();
    restoreHistory(state);speech_(redo?"Redo. "+currentParameterSpeech():"Undo. "+currentParameterSpeech());
}
void FxNavigator::positionChanged(int position,bool speakIt) {
    if(position<0||position>=static_cast<int>(visible_.size())||position==viewPos_)return;
    if(editF7_) {f7SnakePath_.clear();f7SnakeDirections_.clear();}
    viewPos_=position;parameter_=visible_[static_cast<size_t>(position)];
    parameterName_=parameterName();
    rememberPosition();
    if(speakIt)announce();
}
void FxNavigator::saveStructure() {
    if(parameterStepsDirty_)stageParameterSteps();
    if(!fxOrder_.save())throw std::runtime_error("FX profile save failed");
    parameterStepsDirty_=false;
    rememberPosition();
}
void FxNavigator::enterF7() {
    // F7 is the deliberate creation boundary. Ctrl+L never invents a custom
    // profile. Editing always shows Custom Order, never Plugin Order.
    if(!groupSlot_ && !fxOrder_.storedCustomOrder()) {
        if(!fxOrder_.createCustomOrder()) {speech_("Cannot create Custom Order");return;}
    } else if(!groupSlot_ && !fxOrder_.custom) {
        fxOrder_.custom=true;saveStructure();
    }
    if(!groupSlot_)rebuildView(parameter_);
    undoStack_.clear();redoStack_.clear();
    f7ReturnParam_=parameter_;f7ReturnPos_=viewPos_;f7ReturnGroup_=groupSlot_;
    clearF7Filter();
    editF7_=true;valueMode_=false;groupEditAll_=false;
    f7SnakePath_.clear();f7SnakeDirections_.clear();f7BaseSelection_=f7Selected_;
    speech_(std::string(groupSlot_?"Edit: "+groupLabel(groupSlot_):"Edit: Custom Order")+
        ". "+std::to_string(f7Selected_.size())+" selected. "+
        viewPositionSpeech()+". "+editorParameterSpeech());
}
void FxNavigator::exitF7() {
    clearF7Filter();
    editF7_=false;valueMode_=false;groupEditAll_=false;
    f7SnakePath_.clear();f7SnakeDirections_.clear();
    groupSlot_=f7ReturnGroup_;
    rebuildView(f7ReturnParam_,f7ReturnPos_);
    rememberPosition();
    speech_((groupSlot_?groupLabel(groupSlot_)+". ":fxOrder_.custom?"Custom order. ":"Plugin order. ")+currentParameterSpeech());
}
void FxNavigator::selectF7(bool shift,int target,const std::string& direction,bool sweep) {
    if(visible_.empty())return;
    target=std::clamp(target,0,static_cast<int>(visible_.size())-1);
    if(!shift) {
        f7SnakePath_.clear();f7SnakeDirections_.clear();
        positionChanged(target);
        return;
    }
    // A blocked selection command (including Shift+Page and Shift+Home/End)
    // is silent, as in the Lua editor. No phantom anchor is created at edges.
    if(target==viewPos_)return;

    // The first ordinary Shift+arrow paints the current cell, without
    // moving, exactly like group_edit_shift_step_to_pos in the Lua.
    // Page/Home/End are deliberately different: they paint *every* cell
    // from the current position through the inclusive destination.
    if(f7SnakePath_.empty()) {
        f7BaseSelection_=f7Selected_;
        f7SnakeUnselect_=f7Selected_.count(f7OriginalPosition(viewPos_))!=0;
        f7SnakePath_.push_back(viewPos_);
        f7SnakeDirections_.push_back(direction);
        if(!sweep) {
            f7Selected_=f7BaseSelection_;
            const int pos=f7OriginalPosition(viewPos_);
            if(f7SnakeUnselect_)f7Selected_.erase(pos);
            else f7Selected_.insert(pos);
            rememberPosition();
            speech_("Selected "+std::to_string(f7Selected_.size())+". "+editorParameterSpeech());
            return;
        }
    }

    // Sweep through every intermediate row, rather than jumping straight
    // to the landing position. This is essential for Shift+PageUp/Down and
    // Shift+Home/End: a 15-item jump must paint all 16 touched cells.
    // Ordinary horizontal arrows still move one column at a time.
    const int start=viewPos_;
    const int distance=sweep?std::abs(target-start):1;
    const int stride=sweep?(target>start?1:-1):target-start;
    for(int i=0;i<distance;++i) {
        const int next=sweep?viewPos_+stride:target;
        if(next<0||next>=static_cast<int>(visible_.size())||next==viewPos_)break;
        if(f7SnakePath_.size()>1 &&
           f7SnakePath_[f7SnakePath_.size()-2]==next &&
           opposite(f7SnakeDirections_.back(),direction)) {
            // Reverse over the snake's tail: retract the last painted cell.
            f7SnakePath_.pop_back();f7SnakeDirections_.pop_back();
        } else {
            // Turn a corner or extend the snake: the new cell joins the path.
            f7SnakePath_.push_back(next);f7SnakeDirections_.push_back(direction);
        }
        viewPos_=next;
    }
    parameter_=visible_[static_cast<size_t>(viewPos_)];
    parameterName_=parameterName();
    f7Selected_=f7BaseSelection_;
    for(int pos:f7SnakePath_) {
        const int original=f7OriginalPosition(pos); // preserve duplicate occurrences
        if(f7SnakeUnselect_)f7Selected_.erase(original);
        else f7Selected_.insert(original);
    }
    rememberPosition();
    speech_("Selected "+std::to_string(f7Selected_.size())+". "+editorParameterSpeech());
}

void FxNavigator::selectF7ToGlobalEdge(bool toEnd) {
    // In F7, Ctrl+Shift+Home/End selects the range from the CURRENT cell
    // to the beginning/end of the entire visible grid. Ctrl+Home/End alone
    // only navigates; Ctrl+A still selects everything.
    if(visible_.empty())return;
    const int target=toEnd?static_cast<int>(visible_.size())-1:0;
    if(target==viewPos_)return; // repeated movement at either edge is silent
    const int origin=viewPos_;
    const int first=std::min(origin,target);
    const int last=std::max(origin,target);

    // Replace the selection *inside this grid* so nothing behind the origin
    // remains selected. In a filtered grid, protect selections of elements
    // that are temporarily not visible; they belong to another search pass.
    for(int pos=0;pos<static_cast<int>(visible_.size());++pos)
        f7Selected_.erase(f7OriginalPosition(pos));
    for(int pos=first;pos<=last;++pos)
        f7Selected_.insert(f7OriginalPosition(pos));

    // A new contiguous range becomes a stable selection; a subsequent
    // Shift+arrow starts a fresh snake instead of extending an old path.
    f7SnakePath_.clear();f7SnakeDirections_.clear();
    f7BaseSelection_=f7Selected_;f7SnakeUnselect_=false;
    viewPos_=target;
    parameter_=visible_[static_cast<size_t>(viewPos_)];
    parameterName_=parameterName();
    rememberPosition();
    speech_(std::to_string(f7Selected_.size())+" selected. "+editorParameterSpeech());
}

void FxNavigator::doCopy(bool cut) {
    if(!editF7_)return;
    clip_.clear();
    const auto& source=f7FilterActive_?f7FullView_:visible_;
    for(int p:f7Selected_)if(p>=0&&p<static_cast<int>(source.size()))clip_.push_back(source[static_cast<size_t>(p)]);
    if(clip_.empty()&&!source.empty())clip_.push_back(source[static_cast<size_t>(f7OriginalPosition(viewPos_))]);
    clipCut_=cut;clipPlugin_=entries_[browserIndex_].name;
    clipFxGuid_=fxGuid_;clipSourceGroup_=groupSlot_;clipPositions_.clear();
    const auto& sourceList=groupSlot_?fxOrder_.groups.at(groupSlot_):fxOrder_.order;
    // F7 positions are in the VISIBLE view. The Custom list can also contain
    // hidden parameters, so map selected OCCURRENCES to true list positions.
    int visibleIndex=0;
    for(int sourceIndex=0;sourceIndex<static_cast<int>(sourceList.size());++sourceIndex) {
        const int id=sourceList[static_cast<size_t>(sourceIndex)];
        if(!groupSlot_ && fxOrder_.hidden.count(id))continue;
        if((f7Selected_.empty() && visibleIndex==f7OriginalPosition(viewPos_))||
           f7Selected_.count(visibleIndex))clipPositions_.insert(sourceIndex);
        ++visibleIndex;
    }
    speech_(std::string(cut?"Cut ":"Copied ")+std::to_string(clip_.size())+" parameters");
}
void FxNavigator::doPaste() {
    if(!editF7_||clip_.empty()){speech_("Clipboard empty");return;}
    if(clipPlugin_!=entries_[browserIndex_].name){speech_("Clipboard belongs to another FX");return;}
    if(groupEditAll_){speech_("Return to group before paste");return;}
    if(clipCut_ && (!guidSame(&clipFxGuid_,fxGuid_) || clipSourceGroup_!=groupSlot_)) {
        speech_("Cut belongs to its original FX and group");return;
    }
    clearF7Filter();
    std::vector<int>* list=groupSlot_?&fxOrder_.groups[groupSlot_]:&fxOrder_.order;
    if(!groupSlot_&&!fxOrder_.custom){speech_("Plugin order. Read only");return;}
    // Map visible insertion point back into raw Custom order; hidden entries
    // must never shift or cause the cut of a different occurrence.
    int targetPos=static_cast<int>(list->size());
    if(!list->empty()) {
        if(groupSlot_)targetPos=std::clamp(viewPos_,0,static_cast<int>(list->size())-1);
        else {
            int visibleIndex=0;
            for(int rawIndex=0;rawIndex<static_cast<int>(list->size());++rawIndex) {
                if(fxOrder_.hidden.count((*list)[static_cast<size_t>(rawIndex)]))continue;
                if(visibleIndex==viewPos_) {targetPos=rawIndex;break;}
                ++visibleIndex;
            }
        }
    }
    // Cut stores RAW occurrence positions at Ctrl+X, not the cursor position
    // after moving to the insertion target.
    if(clipCut_ && clipPositions_.count(targetPos)) {
        speech_("Move to another position before paste");return;
    }
    std::vector<int> reduced;
    int insertionIndex=targetPos;
    for(int i=0;i<static_cast<int>(list->size());++i) {
        if(clipCut_ && clipPositions_.count(i)) {
            if(i<targetPos)--insertionIndex;
        } else reduced.push_back((*list)[static_cast<size_t>(i)]);
    }
    insertionIndex=std::clamp(insertionIndex,0,static_cast<int>(reduced.size()));
    reduced.insert(reduced.begin()+insertionIndex,clip_.begin(),clip_.end());
    saveUndo();
    list->swap(reduced);
    if(!groupSlot_)fxOrder_.normalize();
    const size_t inserted=clip_.size();
    saveStructure();
    const int old=clip_.front();
    f7Selected_.clear();f7SnakePath_.clear();f7SnakeDirections_.clear();
    rebuildView(old,insertionIndex);
    if(clipCut_) {clip_.clear();clipPositions_.clear();}
    speech_(std::string(clipCut_?"Moved ":"Pasted ")+std::to_string(inserted)+
            " parameters. "+currentParameterSpeech());
}
void FxNavigator::hideSelected() {
    if(!editF7_)return;
    const int actualPos=f7OriginalPosition(viewPos_);
    clearF7Filter();
    saveUndo();
    if(groupSlot_&&!groupEditAll_) {
        auto& rows=fxOrder_.groups[groupSlot_];
        if(rows.empty())return;
        std::set<int> toRemove=f7Selected_;
        if(toRemove.empty())toRemove.insert(actualPos);
        for(auto it=toRemove.rbegin();it!=toRemove.rend();++it)
            if(*it>=0&&*it<static_cast<int>(rows.size()))rows.erase(rows.begin()+*it);
        saveStructure();f7Selected_.clear();rebuildView(parameter_);
        speech_("Removed from group");return;
    }
    if(groupEditAll_){speech_("Return to group before remove");return;}
    if(!fxOrder_.custom){speech_("Plugin order. Read only");return;}
    int newlyHidden=0;
    std::set<int> toHide=f7Selected_;
    if(toHide.empty())toHide.insert(actualPos);
    for(int pos:toHide)if(pos>=0&&pos<static_cast<int>(visible_.size()))
        if(fxOrder_.hidden.insert(visible_[static_cast<size_t>(pos)]).second)++newlyHidden;
    if(newlyHidden==0){speech_("No new parameters hidden");return;}
    saveStructure();f7Selected_.clear();f7SnakePath_.clear();f7SnakeDirections_.clear();
    rebuildView(parameter_);
    speech_("Hidden "+std::to_string(newlyHidden)+" parameters"+
            (visible_.empty()?". No visible parameters":". "+currentParameterSpeech()));
}
void FxNavigator::saveGroup(int slot) {
    if(!editF7_) {speech_("Press F7 to select group parameters");return;}
    std::vector<int> saved;
    const auto& reference=f7FilterActive_?f7FullView_:visible_;
    for(int pos:f7Selected_)if(pos>=0&&pos<static_cast<int>(reference.size()))
        saved.push_back(reference[static_cast<size_t>(pos)]);
    if(saved.empty()){speech_("No selected parameters");return;}
    if(fxOrder_.groups.count(slot)&&!fxOrder_.groups[slot].empty()) {
        speech_("Slot occupied. Group "+std::to_string(slot));return;
    }
    saveUndo();
    fxOrder_.groups[slot]=std::move(saved);
    saveStructure();
    speech_("Saved Group "+std::to_string(slot)+". "+std::to_string(fxOrder_.groups[slot].size())+" parameters");
}
std::string FxNavigator::groupLabel(int slot) const {
    std::string label="Group "+std::to_string(slot);
    auto it=fxOrder_.groupNames.find(slot);
    if(it!=fxOrder_.groupNames.end() && !it->second.empty())label+=". "+it->second;
    return label;
}
void FxNavigator::openGroup(int slot) {
    const auto it=fxOrder_.groups.find(slot);
    // The same Ctrl+Fn closes this group and restores the EXACT source view:
    // Plugin/Custom Order, F7 edit state, selection and optional search filter.
    // A different Ctrl+Fn changes groups without replacing that source view.
    if(groupSlot_==slot) {
        const bool haveOrigin=groupReturnActive_;
        // Keep the CURRENT editing mode: F7 may have been entered or exited
        // after loading the group. An editor outside any group is Custom Order.
        const bool wasEditing=editF7_;
        const bool wasCustom=wasEditing || groupReturnCustom_;
        const int oldParam=groupReturnParam_;
        const int oldPos=groupReturnPosition_;
        const auto oldSelection=groupReturnSelection_;
        const auto oldFilter=groupReturnFilter_;
        if(wasEditing && !fxOrder_.storedCustomOrder() && !fxOrder_.createCustomOrder()) {
            speech_("Cannot create Custom Order");return;
        }
        groupReturnActive_=false;
        clearF7Filter();
        groupSlot_=0;groupEditAll_=false;valueMode_=false;
        f7SnakePath_.clear();f7SnakeDirections_.clear();
        if(haveOrigin) {
            fxOrder_.custom=wasCustom;
            editF7_=wasEditing;
            f7Selected_=oldSelection;
            rebuildView(oldParam,oldPos);
            if(!oldFilter.empty()) {
                applyF7Filter(oldFilter,false);
                // Restore the precise occurrence in the filtered grid too,
                // not only the unfiltered parameter ID (copies can repeat).
                const auto match=std::find(f7FilterPositions_.begin(),
                                           f7FilterPositions_.end(),oldPos);
                if(match!=f7FilterPositions_.end()) {
                    viewPos_=static_cast<int>(match-f7FilterPositions_.begin());
                    parameter_=visible_[static_cast<size_t>(viewPos_)];
                    parameterName_=parameterName();
                }
            }
        } else {
            editF7_=false;
            rebuildView(parameter_);
        }
        rememberPosition();
        speech_(std::string(editF7_?"Edit: ":"")+
                (fxOrder_.custom?"Custom Order":"Plugin Order")+
                (f7FilterActive_?". Search results":"")+". "+
                (editF7_?editorParameterSpeech():currentParameterSpeech()));
        return;
    }
    if(it==fxOrder_.groups.end()||it->second.empty()){
        speech_("Group "+std::to_string(slot)+" empty");return;
    }
    if(!groupSlot_) {
        // Capture ONCE, before entering the first group; do not overwrite it
        // while switching Group 1 -> Group 2 -> Group 3.
        groupReturnActive_=true;
        groupReturnCustom_=fxOrder_.custom;
        groupReturnEdit_=editF7_;
        groupReturnParam_=parameter_;
        groupReturnPosition_=f7FilterActive_?f7OriginalPosition(viewPos_):viewPos_;
        groupReturnFilter_=f7FilterActive_?f7FilterQuery_:std::string();
        groupReturnSelection_=f7Selected_;
    }
    clearF7Filter();
    groupSlot_=slot;groupEditAll_=false;valueMode_=false;
    // Preserve F7 while changing groups. The group list is independent of
    // Plugin/Custom Order and is never redirected to Plugin Order here.
    f7Selected_.clear();f7SnakePath_.clear();f7SnakeDirections_.clear();
    rebuildView(parameter_);
    rememberPosition();
    speech_(std::string(editF7_?"Edit: ":"")+groupLabel(slot)+". "+
            (editF7_?editorParameterSpeech():currentParameterSpeech()));
}

namespace {
std::string fromWide(const std::wstring& w) {
    if(w.empty())return {};
    int bytes=WideCharToMultiByte(CP_UTF8,0,w.data(),static_cast<int>(w.size()),nullptr,0,nullptr,nullptr);
    if(bytes<=0)return {};
    std::string out(static_cast<size_t>(bytes),'\0');
    WideCharToMultiByte(CP_UTF8,0,w.data(),static_cast<int>(w.size()),out.data(),bytes,nullptr,nullptr);
    return out;
}
std::wstring clipboardWide() {
    if(!OpenClipboard(nullptr))return {};
    std::wstring out;
    if(HANDLE data=GetClipboardData(CF_UNICODETEXT)) {
        if(auto* p=static_cast<const wchar_t*>(GlobalLock(data))) {
            out.assign(p,p+std::min<size_t>(wcsnlen_s(p,8192),8192));
            GlobalUnlock(data);
        }
    }
    CloseClipboard();return out;
}
void copyWide(const std::wstring& value) {
    if(!OpenClipboard(nullptr))return;
    EmptyClipboard();
    const auto size=(value.size()+1)*sizeof(wchar_t);
    HGLOBAL data=GlobalAlloc(GMEM_MOVEABLE,size);
    if(data){
        if(auto* p=GlobalLock(data)) {
            std::memcpy(p,value.c_str(),size);
            GlobalUnlock(data);
            if(SetClipboardData(CF_UNICODETEXT,data))data=nullptr;
        }
        if(data)GlobalFree(data);
    }
    CloseClipboard();
}
}
void FxNavigator::handleTextEdit(const Key& k) {
    if(k.vk==VK_ESCAPE){textEdit_=false;textBuffer_.clear();textWide_.clear();speech_("Rename cancelled");return;}
    if(k.vk==VK_RETURN) {
        // In native Windows EDIT mode, textBuffer_ is supplied by the focus
        // owner. The old simulated text remains a fallback without TitleProxy.
        // Native EDIT has already provided textBuffer_ through the owner.
        while(!textBuffer_.empty()&&(textBuffer_.back()==' '||textBuffer_.back()=='\t'))textBuffer_.pop_back();
        saveUndo();
        if(textEditParam_!=-1) {
            const auto original=parameterName_;
            if(textBuffer_.empty()||textBuffer_==original)fxOrder_.aliases.erase(textEditParam_);
            else fxOrder_.aliases[textEditParam_]=textBuffer_;
        } else if(groupSlot_) fxOrder_.groupNames[groupSlot_]=textBuffer_;
        textEdit_=false;saveStructure();speech_("Name saved. "+(textEditParam_==-1?groupLabel(groupSlot_):displayName()));return;
    }
    if(k.ctrl&&!k.alt&&k.vk=='A') {textFresh_=true;speech_("All selected");return;}
    if(k.ctrl&&!k.alt&&k.vk=='C') {copyWide(textWide_);speech_("Name copied");return;}
    if(k.ctrl&&!k.alt&&k.vk=='X') {copyWide(textWide_);textWide_.clear();textCursor_=0;textFresh_=false;}
    else if(k.ctrl&&!k.alt&&k.vk=='V') {
        const auto data=clipboardWide();
        if(textFresh_){textWide_.clear();textCursor_=0;textFresh_=false;}
        for(wchar_t c:data)if(c>=32&&textWide_.size()<240)textWide_.insert(textWide_.begin()+static_cast<ptrdiff_t>(textCursor_++),c);
    }
    else if(k.vk==VK_LEFT){if(textCursor_)--textCursor_;textFresh_=false;}
    else if(k.vk==VK_RIGHT){if(textCursor_<textWide_.size())++textCursor_;textFresh_=false;}
    else if(k.vk==VK_HOME){textCursor_=0;textFresh_=false;}
    else if(k.vk==VK_END){textCursor_=textWide_.size();textFresh_=false;}
    else if(k.vk==VK_BACK){
        if(textFresh_){textWide_.clear();textCursor_=0;textFresh_=false;}
        else if(textCursor_){textWide_.erase(--textCursor_,1);}
    }
    else if(k.vk==VK_DELETE){
        if(textFresh_){textWide_.clear();textCursor_=0;textFresh_=false;}
        else if(textCursor_<textWide_.size())textWide_.erase(textCursor_,1);
    }
    else if(!k.ctrl||k.alt){
        BYTE state[256]{};GetKeyboardState(state);
        state[k.vk]=0x80;
        if(k.shift)state[VK_SHIFT]=0x80;
        if(k.ctrl)state[VK_CONTROL]=0x80;
        if(k.alt)state[VK_MENU]=0x80;
        wchar_t buffer[8]{};
        const auto layout=GetKeyboardLayout(0);
        const int n=ToUnicodeEx(k.vk,MapVirtualKeyExW(k.vk,MAPVK_VK_TO_VSC,layout),state,
                               buffer,8,0,layout);
        if(n>0){
            if(textFresh_){textWide_.clear();textCursor_=0;textFresh_=false;}
            for(int i=0;i<n&&textWide_.size()<240;++i)if(buffer[i]>=32)
                textWide_.insert(textWide_.begin()+static_cast<ptrdiff_t>(textCursor_++),buffer[i]);
        }
    }
    textBuffer_=fromWide(textWide_);
    speech_("Edit name. "+(textBuffer_.empty()?"Empty":textBuffer_));
}
bool FxNavigator::handleF7(const Key& k) {
    if(!editF7_)return false;
    if(k.ctrl&&!k.alt&&!k.shift&&(k.vk=='Z'||k.vk=='Y')){
        if(!k.repeat)f7Undo(k.vk=='Y');return true;
    }
    if(k.ctrl&&!k.alt&&!k.shift&&(k.vk=='C'||k.vk=='X')){doCopy(k.vk=='X');return true;}
    if(k.ctrl&&!k.alt&&!k.shift&&k.vk=='V'){doPaste();return true;}
    if(k.ctrl&&!k.alt&&!k.shift&&k.vk=='A') {
        f7Selected_.clear();
        for(int i=0;i<static_cast<int>(visible_.size());++i)f7Selected_.insert(f7OriginalPosition(i));
        f7SnakePath_.clear();f7SnakeDirections_.clear();rememberPosition();
        speech_("Selected all. "+std::to_string(f7Selected_.size())+" selected");return true;
    }
    if(k.ctrl&&!k.alt&&!k.shift&&k.vk==VK_DELETE){hideSelected();return true;}
    // Recovery until the Lua F8 hidden-parameter manager is migrated.
    if(k.ctrl&&k.shift&&!k.alt&&k.vk==VK_DELETE) {
        if(!fxOrder_.custom){speech_("Plugin order. Read only");return true;}
        const auto count=fxOrder_.hidden.size();
        if(!count){speech_("No hidden parameters");return true;}
        clearF7Filter();saveUndo();
        fxOrder_.hidden.clear();saveStructure();f7Selected_.clear();
        rebuildView(parameter_);
        speech_("Restored "+std::to_string(count)+" hidden parameters");return true;
    }
    if(!k.ctrl&&!k.alt&&!k.shift&&k.vk==VK_DELETE){
        f7Selected_.clear();f7SnakePath_.clear();f7SnakeDirections_.clear();
        rememberPosition();speech_("Unselected all. 0 selected");return true;
    }
    if(k.shift&&!k.ctrl&&!k.alt&&k.vk==VK_SPACE){
        const int selected=f7OriginalPosition(viewPos_);
        if(f7Selected_.count(selected))f7Selected_.erase(selected);else f7Selected_.insert(selected);
        f7SnakePath_.clear();f7SnakeDirections_.clear();rememberPosition();
        speech_(std::string(f7Selected_.count(f7OriginalPosition(viewPos_))?"Selected ":"Unselected ")+currentParameterSpeech());return true;
    }
    if(!k.ctrl&&!k.shift&&!k.alt&&k.vk==VK_TAB){
        speech_((groupSlot_?"Edit: "+groupLabel(groupSlot_):"Edit: Custom Order")+". "+
                std::to_string(f7Selected_.size())+" selected. "+viewPositionSpeech()+
                (f7FilterActive_?". Filter "+f7FilterQuery_:""));return true;
    }
    if(k.ctrl&&!k.shift&&!k.alt&&k.vk==VK_RETURN){
        if(slotMode_==0 && !groupSlot_) {speech_("Open a group to rename");return true;}
        textEdit_=true;textEditParam_=(slotMode_==0)?-1:parameter_;
        textBuffer_=(textEditParam_==-1)?fxOrder_.groupNames[groupSlot_]:displayName();
        const int needed=MultiByteToWideChar(CP_UTF8,0,textBuffer_.c_str(),-1,nullptr,0);
        textWide_.assign(static_cast<size_t>(std::max(0,needed)),L'\0');
        if(needed>0) {MultiByteToWideChar(CP_UTF8,0,textBuffer_.c_str(),-1,textWide_.data(),needed);textWide_.pop_back();}
        textCursor_=textWide_.size();textFresh_=true;
        speech_(std::string(textEditParam_==-1?"Edit group name. ":"Edit param name. ")+textBuffer_);
        return true;
    }
    if(k.alt&&k.shift&&!k.ctrl&&
       (k.vk==VK_UP||k.vk==VK_DOWN||k.vk==VK_LEFT||k.vk==VK_RIGHT)) {
        // Alt+Shift+arrows follow grid geometry among selected parameters,
        // keeping plain Alt+arrows available for the existing Step/Value keys.
        // Up/Down stay in their column; Left/Right choose the next column
        // with a selected cell, preferring the same row in that column.
        if(f7Selected_.empty()){speech_("0 selected");return true;}
        const int height=std::max(1,columns_);
        const int currentColumn=viewPos_/height, currentRow=viewPos_%height;
        int best=-1;
        int bestPrimary=INT_MAX, bestSecondary=INT_MAX;
        for(int original:f7Selected_) {
            int pos=original;
            if(f7FilterActive_) {
                const auto found=std::find(f7FilterPositions_.begin(),f7FilterPositions_.end(),original);
                if(found==f7FilterPositions_.end())continue;
                pos=static_cast<int>(found-f7FilterPositions_.begin());
            }
            if(pos<0 || pos>=static_cast<int>(visible_.size()) || pos==viewPos_)continue;
            const int col=pos/height, row=pos%height;
            int primary=0,secondary=0;
            if(k.vk==VK_UP || k.vk==VK_DOWN) {
                if(col!=currentColumn)continue;
                primary=k.vk==VK_UP?currentRow-row:row-currentRow;
                if(primary<=0)continue;
            } else {
                primary=k.vk==VK_LEFT?currentColumn-col:col-currentColumn;
                if(primary<=0)continue;
                secondary=std::abs(row-currentRow);
            }
            if(primary<bestPrimary || (primary==bestPrimary && secondary<bestSecondary)) {
                best=pos;bestPrimary=primary;bestSecondary=secondary;
            }
        }
        if(best>=0)positionChanged(best);
        // A boundary with no next selected parameter is silent.
        return true;
    }
    if(k.ctrl&&k.shift&&!k.alt&&(k.vk==VK_HOME||k.vk==VK_END)) {
        // Only Ctrl+Shift selects an interval to the global grid edge.
        // Ctrl+Home/End without Shift falls through to normal navigation.
        selectF7ToGlobalEdge(k.vk==VK_END);return true;
    }
    if(k.shift&&!k.ctrl&&!k.alt &&
       (k.vk==VK_UP||k.vk==VK_DOWN||k.vk==VK_LEFT||k.vk==VK_RIGHT||
        k.vk==VK_PRIOR||k.vk==VK_NEXT||k.vk==VK_HOME||k.vk==VK_END)) {
        if(visible_.empty())return true;
        const int start=(viewPos_/columns_)*columns_;
        const int end=std::min(static_cast<int>(visible_.size())-1,start+columns_-1);
        int target=viewPos_;
        if(k.vk==VK_UP)target=std::max(start,viewPos_-1);
        else if(k.vk==VK_DOWN)target=std::min(end,viewPos_+1);
        else if(k.vk==VK_LEFT)target=std::max(0,viewPos_-columns_);
        else if(k.vk==VK_RIGHT)target=std::min(static_cast<int>(visible_.size())-1,viewPos_+columns_);
        else if(k.vk==VK_PRIOR)target=std::max(start,viewPos_-5);
        else if(k.vk==VK_NEXT)target=std::min(end,viewPos_+5);
        else if(k.vk==VK_HOME)target=start;
        else if(k.vk==VK_END)target=end;
        const bool sweep=k.vk==VK_PRIOR||k.vk==VK_NEXT||k.vk==VK_HOME||k.vk==VK_END;
        const std::string direction=sweep?(target<viewPos_?"up":"down"):keyName(k);
        selectF7(true,target,direction,sweep);return true;
    }
    return false;
}
}
