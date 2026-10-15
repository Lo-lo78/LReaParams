#include "lrp/FxNavigator.h"
#include <algorithm>
#include <cctype>
#include <cmath>
#include <cstring>
#include <cwchar>
#include <stdexcept>
#include <windows.h>

namespace lrp {
namespace {
bool guidSame(const GUID* a,const GUID& b) { return a && std::memcmp(a,&b,sizeof(GUID))==0; }
std::string originalName(MediaTrack* track,MediaItem_Take* take,int fx,int id) {
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
        default:return "page";
    }
}
bool opposite(const std::string& a,const std::string& b) {
    return (a=="up"&&b=="down")||(a=="down"&&b=="up")||
           (a=="left"&&b=="right")||(a=="right"&&b=="left");
}
}
std::string FxNavigator::displayName() const {
    auto label=fxOrder_.label(parameter_);
    return label.empty()?parameterName_:label;
}
void FxNavigator::loadFxOrder() {
    // Raw REAPER name corresponds to Lua get_fx_raw_label(), not its stripped
    // display name or a per-instance GUID.
    const std::string name=entries_.at(static_cast<size_t>(browserIndex_)).name;
    fxOrder_.load(resourceRoot_,name,count_,[this](int id) {
        return originalName(track_,take_,fx_,id);
    });
    groupSlot_=0;groupEditAll_=false;editF7_=false;searchMode_=false;
    slotMode_=fxOrder_.groupSlotMode?0:1;
    visible_=fxOrder_.visibleOrder();
    int preference=-1;
    if(auto* memory=contextMemory())for(const auto& pos:memory->positions)
        if(guidSame(&pos.fxGuid,fxGuid_)) {preference=pos.viewPosition;f7Selected_=pos.f7Selected;fxOrder_.custom=pos.customView;break;}
    rebuildView(parameter_,preference);
}
void FxNavigator::rebuildView(int preferParam,int preferPosition) {
    if(groupSlot_ && !groupEditAll_) {
        visible_=fxOrder_.groups[groupSlot_];
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
void FxNavigator::positionChanged(int position,bool speakIt) {
    if(position<0||position>=static_cast<int>(visible_.size())||position==viewPos_)return;
    if(editF7_) {f7SnakePath_.clear();f7SnakeDirections_.clear();}
    viewPos_=position;parameter_=visible_[static_cast<size_t>(position)];
    parameterName_=parameterName();
    rememberPosition();
    if(speakIt)announce();
}
void FxNavigator::saveStructure() {
    if(!fxOrder_.save())throw std::runtime_error("FX profile save failed");
    rememberPosition();
}
void FxNavigator::enterF7() {
    if(!fxOrder_.custom && !groupSlot_) {speech_("F7 not available in Plugin order");return;}
    f7ReturnParam_=parameter_;f7ReturnPos_=viewPos_;f7ReturnGroup_=groupSlot_;
    editF7_=true;valueMode_=false;groupEditAll_=false;
    f7SnakePath_.clear();f7SnakeDirections_.clear();f7BaseSelection_=f7Selected_;
    speech_(std::string(groupSlot_?"Edit Group "+std::to_string(groupSlot_):"Edit Custom order")+
        ". "+std::to_string(f7Selected_.size())+" selected. "+currentParameterSpeech());
}
void FxNavigator::exitF7() {
    editF7_=false;valueMode_=false;groupEditAll_=false;
    f7SnakePath_.clear();f7SnakeDirections_.clear();
    groupSlot_=f7ReturnGroup_;
    rebuildView(f7ReturnParam_,f7ReturnPos_);
    rememberPosition();
    speech_((groupSlot_?"Group. ":fxOrder_.custom?"Custom order. ":"Plugin order. ")+currentParameterSpeech());
}
void FxNavigator::selectF7(bool shift,int target,const std::string& direction) {
    if(visible_.empty())return;
    target=std::clamp(target,0,static_cast<int>(visible_.size())-1);
    if(!shift) {
        f7SnakePath_.clear();f7SnakeDirections_.clear();
        positionChanged(target);
        return;
    }
    // Lua's serpent: first Shift chooses the current cell without moving.
    // Reversing the previous direction removes the path tail.
    if(f7SnakePath_.empty()) {
        f7BaseSelection_=f7Selected_;
        f7SnakePath_.push_back(viewPos_);
        f7SnakeDirections_.push_back(direction);
    } else if(f7SnakePath_.back()==viewPos_ &&
              opposite(f7SnakeDirections_.back(),direction)) {
        f7SnakePath_.pop_back();f7SnakeDirections_.pop_back();
        if(!f7SnakePath_.empty()) {
            viewPos_=f7SnakePath_.back();parameter_=visible_[static_cast<size_t>(viewPos_)];
            parameterName_=parameterName();
        }
    } else if(target!=viewPos_) {
        viewPos_=target;parameter_=visible_[static_cast<size_t>(viewPos_)];
        parameterName_=parameterName();
        f7SnakePath_.push_back(viewPos_);f7SnakeDirections_.push_back(direction);
    }
    f7Selected_=f7BaseSelection_;
    for(int p:f7SnakePath_)f7Selected_.insert(p);
    rememberPosition();
    speech_("Selected "+std::to_string(f7Selected_.size())+". "+currentParameterSpeech());
}
void FxNavigator::doCopy(bool cut) {
    if(!editF7_)return;
    clip_.clear();
    const auto& source=(groupSlot_&&!groupEditAll_)?fxOrder_.groups[groupSlot_]:visible_;
    for(int p:f7Selected_)if(p>=0&&p<static_cast<int>(source.size()))clip_.push_back(source[static_cast<size_t>(p)]);
    if(clip_.empty()&&!source.empty())clip_.push_back(source[static_cast<size_t>(viewPos_)]);
    clipCut_=cut;clipPlugin_=entries_[browserIndex_].name;
    clipFxGuid_=fxGuid_;clipSourceGroup_=groupSlot_;clipPositions_.clear();
    const auto& sourceList=groupSlot_?fxOrder_.groups.at(groupSlot_):fxOrder_.order;
    // F7 positions are in the VISIBLE view. The Custom list can also contain
    // hidden parameters, so map selected OCCURRENCES to true list positions.
    int visibleIndex=0;
    for(int sourceIndex=0;sourceIndex<static_cast<int>(sourceList.size());++sourceIndex) {
        const int id=sourceList[static_cast<size_t>(sourceIndex)];
        if(!groupSlot_ && fxOrder_.hidden.count(id))continue;
        if((f7Selected_.empty() && visibleIndex==viewPos_)||
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
    if(groupSlot_&&!groupEditAll_) {
        auto& rows=fxOrder_.groups[groupSlot_];
        if(rows.empty())return;
        std::set<int> toRemove=f7Selected_;
        if(toRemove.empty())toRemove.insert(viewPos_);
        for(auto it=toRemove.rbegin();it!=toRemove.rend();++it)
            if(*it>=0&&*it<static_cast<int>(rows.size()))rows.erase(rows.begin()+*it);
        saveStructure();f7Selected_.clear();rebuildView(parameter_);
        speech_("Removed from group");return;
    }
    if(groupEditAll_){speech_("Return to group before remove");return;}
    if(!fxOrder_.custom){speech_("Plugin order. Read only");return;}
    int newlyHidden=0;
    std::set<int> toHide=f7Selected_;
    if(toHide.empty())toHide.insert(viewPos_);
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
    for(int pos:f7Selected_)if(pos>=0&&pos<static_cast<int>(visible_.size()))
        saved.push_back(visible_[static_cast<size_t>(pos)]);
    if(saved.empty()){speech_("No selected parameters");return;}
    if(fxOrder_.groups.count(slot)&&!fxOrder_.groups[slot].empty()) {
        speech_("Slot occupied. Group "+std::to_string(slot));return;
    }
    fxOrder_.groups[slot]=std::move(saved);
    saveStructure();
    speech_("Saved Group "+std::to_string(slot)+". "+std::to_string(fxOrder_.groups[slot].size())+" parameters");
}
void FxNavigator::openGroup(int slot) {
    const auto it=fxOrder_.groups.find(slot);
    if(it==fxOrder_.groups.end()||it->second.empty()){speech_("Group "+std::to_string(slot)+" empty");return;}
    if(editF7_&&groupSlot_==slot){
        groupEditAll_=!groupEditAll_;
        rebuildView(parameter_);f7Selected_.clear();
        speech_(groupEditAll_?"All parameters in Group edit":"Group parameters in edit");return;
    }
    const bool wasEditing=editF7_;
    if(wasEditing) {editF7_=false;f7Selected_.clear();}
    groupSlot_=slot;groupEditAll_=false;rebuildView(parameter_);
    if(wasEditing)enterF7();
    else speech_("Group "+std::to_string(slot)+". "+currentParameterSpeech());
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
        textBuffer_=fromWide(textWide_);
        while(!textBuffer_.empty()&&(textBuffer_.back()==' '||textBuffer_.back()=='\t'))textBuffer_.pop_back();
        if(textEditParam_>=0) {
            const auto original=parameterName_;
            if(textBuffer_.empty()||textBuffer_==original)fxOrder_.aliases.erase(textEditParam_);
            else fxOrder_.aliases[textEditParam_]=textBuffer_;
        } else if(groupSlot_) fxOrder_.groupNames[groupSlot_]=textBuffer_;
        textEdit_=false;saveStructure();speech_("Name saved. "+displayName());return;
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
    if(k.ctrl&&!k.alt&&!k.shift&&(k.vk=='C'||k.vk=='X')){doCopy(k.vk=='X');return true;}
    if(k.ctrl&&!k.alt&&!k.shift&&k.vk=='V'){doPaste();return true;}
    if(k.ctrl&&!k.alt&&!k.shift&&k.vk=='A') {
        f7Selected_.clear();
        for(int i=0;i<static_cast<int>(visible_.size());++i)f7Selected_.insert(i);
        f7SnakePath_.clear();f7SnakeDirections_.clear();rememberPosition();
        speech_("Selected all. "+std::to_string(f7Selected_.size())+" selected");return true;
    }
    if(k.ctrl&&!k.alt&&!k.shift&&k.vk==VK_DELETE){hideSelected();return true;}
    // Recovery until the Lua F8 hidden-parameter manager is migrated.
    if(k.ctrl&&k.shift&&!k.alt&&k.vk==VK_DELETE) {
        if(!fxOrder_.custom){speech_("Plugin order. Read only");return true;}
        const auto count=fxOrder_.hidden.size();
        if(!count){speech_("No hidden parameters");return true;}
        fxOrder_.hidden.clear();saveStructure();f7Selected_.clear();
        rebuildView(parameter_);
        speech_("Restored "+std::to_string(count)+" hidden parameters");return true;
    }
    if(!k.ctrl&&!k.alt&&!k.shift&&k.vk==VK_DELETE){
        f7Selected_.clear();f7SnakePath_.clear();f7SnakeDirections_.clear();
        rememberPosition();speech_("Unselected all. 0 selected");return true;
    }
    if(k.shift&&!k.ctrl&&!k.alt&&k.vk==VK_SPACE){
        if(f7Selected_.count(viewPos_))f7Selected_.erase(viewPos_);else f7Selected_.insert(viewPos_);
        f7SnakePath_.clear();f7SnakeDirections_.clear();rememberPosition();
        speech_(std::string(f7Selected_.count(viewPos_)?"Selected ":"Unselected ")+currentParameterSpeech());return true;
    }
    if(!k.ctrl&&!k.shift&&!k.alt&&k.vk==VK_TAB){
        speech_(std::to_string(f7Selected_.size())+" selected");return true;
    }
    if(k.ctrl&&!k.shift&&!k.alt&&k.vk==VK_RETURN){
        textEdit_=true;textEditParam_=groupSlot_?-1:parameter_;
        textBuffer_=groupSlot_?fxOrder_.groupNames[groupSlot_]:displayName();
        const int needed=MultiByteToWideChar(CP_UTF8,0,textBuffer_.c_str(),-1,nullptr,0);
        textWide_.assign(static_cast<size_t>(std::max(0,needed)),L'\0');
        if(needed>0) {MultiByteToWideChar(CP_UTF8,0,textBuffer_.c_str(),-1,textWide_.data(),needed);textWide_.pop_back();}
        textCursor_=textWide_.size();textFresh_=true;
        speech_(std::string(groupSlot_?"Edit group name. ":"Edit param name. ")+textBuffer_);
        return true;
    }
    if(k.ctrl&&k.alt&&!k.shift&&(k.vk==VK_UP||k.vk==VK_DOWN||k.vk==VK_LEFT||k.vk==VK_RIGHT)) {
        if(f7Selected_.empty()){speech_("0 selected");return true;}
        int delta=(k.vk==VK_UP?-1:k.vk==VK_DOWN?1:k.vk==VK_LEFT?-columns_:columns_);
        auto it=delta>0?f7Selected_.upper_bound(viewPos_):f7Selected_.lower_bound(viewPos_);
        if(delta<0){if(it!=f7Selected_.begin())--it;else return true;}
        if(it!=f7Selected_.end())positionChanged(*it);
        return true;
    }
    if(k.ctrl&&k.shift&&!k.alt&&(k.vk==VK_HOME||k.vk==VK_END)) {
        f7Selected_.clear();for(int i=0;i<static_cast<int>(visible_.size());++i)f7Selected_.insert(i);
        f7SnakePath_.clear();f7SnakeDirections_.clear();rememberPosition();
        speech_("Selected all. "+std::to_string(f7Selected_.size())+" selected");return true;
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
        else if(k.vk==VK_HOME)target=end;
        else if(k.vk==VK_END)target=start;
        selectF7(true,target,keyName(k));return true;
    }
    return false;
}
}
