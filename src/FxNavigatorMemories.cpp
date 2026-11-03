#include "lrp/FxNavigator.h"
#include <algorithm>
#include <cmath>
#include <initializer_list>
#include <map>
#include <set>
#include <sstream>
#include <stdexcept>

namespace lrp {
namespace {
constexpr const char* names[] = {"Memory positions", "Groups", "Hidden parameters", "MIDI CC",
                                 "Custom order", "Copied parameters", "Default values", "Parameter Steps"};
}
bool FxNavigator::openFxMemories(bool standalone) {
    if (!active_ || !valid()) return false;
    if(memoryManager_) {memoryExit();return true;}
    // TEST55.5: Ctrl+Shift+M is the independent memory-manager entry point in
    // FX Grid, Value and F7. The dedicated REAPER action uses this same UI.
    // Preserve the exact origin to return correctly after Escape.
    rememberPosition(); // Preserve the ordering being left, even without edits.
    memoryReturnF7_=editF7_;
    memoryReturnF7Filter_=f7FilterQuery_;
    memoryReturnParam_=parameter_;
    memoryReturnPosition_=viewPos_;
    memoryReturnGroup_=groupSlot_;
    memoryStandalone_=standalone;
    valueMode_=false;
    searchMode_=false;
    memoryManager_=true;
    for(auto& selection:memorySelected_)selection.clear();
    rebuildMemoryColumns();
    memoryCol_=0;
    while(memoryCol_<8 && memoryColumns_[static_cast<size_t>(memoryCol_)].empty())++memoryCol_;
    if(memoryCol_==8)memoryCol_=0;
    memoryRow_=0;
    if(!standalone)speakMemory("Parameter Navigator");
    return true;
}
void FxNavigator::rebuildMemoryColumns() {
    for(auto& col:memoryColumns_)col.clear();
    // Columns match the Lua F8 editor's visual and keyboard order, including
    // non-consecutive real Group and Memory slot numbers.
    for(const auto& pair:fxOrder_.paramSlots) {
        if (pair.second == compareParamIndex) continue;
        MemoryEntry e;e.slot=pair.first;e.param=pair.second;
        e.label=(e.param==compareParamIndex || eqVirtualValid(e.param) || dynamicsVirtualValid(e.param) || (e.param>=0&&e.param<count_))?fxOrder_.label(e.param):"Missing parameter";
        memoryColumns_[0].push_back(std::move(e));
    }
    for(const auto& pair:fxOrder_.groups) {
        const int activeCount=static_cast<int>(std::count_if(pair.second.begin(),pair.second.end(),
            [&](int id){return id!=compareParamIndex && !fxOrder_.hidden.count(id);}));
        // An intentionally saved empty group is a real memory, not a missing slot.
        MemoryEntry e;e.slot=pair.first;
        e.label=groupLabel(e.slot)+". "+std::to_string(activeCount)+" visible parameters";
        memoryColumns_[1].push_back(std::move(e));
    }
    for(int id:fxOrder_.hidden)if(eqVirtualValid(id) || dynamicsVirtualValid(id) || (id>=0&&id<count_)){
        MemoryEntry e;e.param=id;e.label=fxOrder_.label(id);
        memoryColumns_[2].push_back(std::move(e));
    }
    // MIDI CC links share the native main-thread runtime and Lua profile keys.
    for(const auto& pair:fxOrder_.ccLinks) {
        if (pair.first == compareParamIndex) continue;
        MemoryEntry e;e.param=pair.first;
        // Lua profiles store "channel\tCC"; announce both field names
        // explicitly rather than presenting an opaque tab-separated pair.
        const auto tab=pair.second.find('\t');
        if(tab!=std::string::npos)
            e.label=fxOrder_.label(pair.first)+". Channel "+pair.second.substr(0,tab)+
                    ". CC "+pair.second.substr(tab+1);
        else
            e.label=fxOrder_.label(pair.first)+". "+pair.second;
        memoryColumns_[3].push_back(std::move(e));
    }
    if(fxOrder_.storedCustomOrder()) {
        const auto count=std::count_if(fxOrder_.order.begin(),fxOrder_.order.end(),
            [](int id){return id!=compareParamIndex;});
        MemoryEntry e;e.label=std::to_string(count)+" parameters";
        memoryColumns_[4].push_back(std::move(e));
    }
    std::map<int,int> counts;
    for(int pos=0;pos<static_cast<int>(fxOrder_.order.size());++pos) {
        const int id=fxOrder_.order[static_cast<size_t>(pos)];
        if (id == compareParamIndex) continue;
        if(++counts[id] > 1) {
            MemoryEntry e;e.param=id;e.rawPos=pos;e.occurrence=counts[id];
            e.label=fxOrder_.label(id)+". Custom Order. Copy "+std::to_string(e.occurrence);
            memoryColumns_[5].push_back(std::move(e));
        }
    }
    // A group's complete list is itself a collection of pasted occurrences.
    // Include the FIRST occurrence too, and identify group + position.
    // Group entries retain their identity even if Hidden makes them temporarily
    // invisible in its grid; they can still be removed here if desired.
    for(const auto& group:fxOrder_.groups) {
        std::map<int,int> occurrences;
        for(int pos=0;pos<static_cast<int>(group.second.size());++pos) {
            const int id=group.second[static_cast<size_t>(pos)];
            if(id==compareParamIndex)continue;
            if(!(eqVirtualValid(id) || dynamicsVirtualValid(id) || (id>=0 && id<count_)))continue;
            MemoryEntry e;e.slot=group.first;e.param=id;e.rawPos=pos;
            e.occurrence=++occurrences[id];
            e.label=fxOrder_.label(id)+". "+groupLabel(group.first)+
                ". Occurrence "+std::to_string(e.occurrence)+
                ". Position "+std::to_string(pos+1)+
                (fxOrder_.hidden.count(id)?". Hidden":std::string());
            memoryColumns_[5].push_back(std::move(e));
        }
    }
    // Only explicit nonzero per-parameter steps are memories, like Track Params.
    // Keep the legacy Lua fallback read-only until the user changes a step.
    std::set<int> stepIds;
    for(const auto& row:parameterSteps_)stepIds.insert(row.first);
    for(const auto& row:fxOrder_.order)if(row!=compareParamIndex)stepIds.insert(row);
    for(const auto& group:fxOrder_.groups)
        for(int id:group.second)if(id!=compareParamIndex)stepIds.insert(id);
    for(int id:stepIds) {
        if(!(eqVirtualValid(id) || dynamicsVirtualValid(id) || (id>=0&&id<count_)))continue;
        const int value=savedStepForParameter(id);
        if(value==0)continue;
        MemoryEntry e;e.param=id;
        e.label=fxOrder_.label(id)+". Step "+std::to_string(value);
        memoryColumns_[7].push_back(std::move(e));
    }
    if(fxOrder_.hasDefaultValues()) {
        MemoryEntry e;e.label=std::to_string(fxOrder_.defaultValueCount())+" parameters";
        memoryColumns_[6].push_back(std::move(e));
    }
}
bool FxNavigator::memoryHasEntries() const {
    for(const auto& column:memoryColumns_)if(!column.empty())return true;
    return false;
}
std::string FxNavigator::memoryColumnName() const {
    return names[static_cast<size_t>(std::clamp(memoryCol_,0,7))];
}
std::string FxNavigator::memoryReview() const {
    if(!memoryManager_)return {};
    if(defaultConfirm_)return defaultYes_?"Clear memories and restore default? Yes":"Clear memories and restore default? No";
    if(!memoryHasEntries())return "Parameter Navigator. No memories";
    const auto& entries=memoryColumns_[static_cast<size_t>(memoryCol_)];
    if(entries.empty())return memoryColumnName()+". Empty";
    const auto& entry=entries[static_cast<size_t>(std::clamp(memoryRow_,0,static_cast<int>(entries.size())-1))];
    const std::string selected=memorySelected_[static_cast<size_t>(memoryCol_)].count(memoryRow_)?"Selected. ":"";
    if(memoryCol_==0)return selected+"Memory positions. "+entry.label;
    if(memoryCol_==1)return selected+"Groups. "+entry.label;
    return selected+memoryColumnName()+". "+entry.label;
}
void FxNavigator::speakMemory(const std::string& prefix) {
    speech_(prefix.empty()?memoryReview():prefix+". "+memoryReview());
}
void FxNavigator::memoryExit(bool announceReturn) {
    if(!memoryManager_)return;
    const bool standalone=memoryStandalone_;
    memoryManager_=false;memoryStandalone_=false;
    for(auto& selection:memorySelected_)selection.clear();
    defaultConfirm_=false;defaultYes_=false;defaultRegenerate_=false;
    editF7_=memoryReturnF7_;
    groupSlot_=memoryReturnGroup_;
    clearF7Filter();
    // F8 Group/Custom selection restores its independent grid unless the
    // memory entry requests an explicit parameter/occurrence jump.
    if (!editF7_ && (memoryReturnGroup_ > 0) &&
        memoryReturnPosition_ < 0)
        restoreViewCursor(memoryReturnParam_, memoryReturnPosition_);
    else rebuildView(memoryReturnParam_,memoryReturnPosition_);
    if(editF7_ && !memoryReturnF7Filter_.empty())applyF7Filter(memoryReturnF7Filter_,false);
    rememberPosition();
    if(standalone) {end();return;}
    if(!announceReturn)return;
    if(editF7_)
        speech_(std::string("Edit ")+(groupSlot_?groupLabel(groupSlot_):"Custom Order")+
                ". "+std::to_string(f7Selected_.size())+" selected. "+
                (visible_.empty()?"Empty":currentParameterSpeech()));
    else if(groupSlot_)speech_(groupLabel(groupSlot_)+". "+
                               (visible_.empty()?"No visible parameters":currentParameterSpeech()));
    else announce();
}
bool FxNavigator::memorySelectColumn(int direction) {
    for(int c=memoryCol_+direction;c>=0&&c<8;c+=direction) {
        if(!memoryColumns_[static_cast<size_t>(c)].empty()) {
            memoryCol_=c;
            memoryRow_=std::clamp(memoryRow_,0,static_cast<int>(memoryColumns_[static_cast<size_t>(c)].size())-1);
            speakMemory();return true;
        }
    }
    return false;
}
void FxNavigator::memoryLoad(bool toEdit) {
    const auto& col=memoryColumns_[static_cast<size_t>(memoryCol_)];
    if(col.empty()){speakMemory();return;}
    const MemoryEntry entry=col[static_cast<size_t>(memoryRow_)];
    // The Lua memory_manager_load_current_for_f7 accepts only positions,
    // groups, MIDI links and Custom Order. Hidden, copied and Default entries
    // are management entries, not valid entry points to the F7 editor.
    if(toEdit && memoryCol_!=0 && memoryCol_!=1 && memoryCol_!=3 && memoryCol_!=4) {
        speech_("No F7 editor for this memory");
        return;
    }
    // A selected memory must never mutate an unrelated FX: navigation is
    // built from the *current* plugin's verified ProfileRaw and FX GUID.
    if(memoryCol_==2 && !toEdit) {
        // Hidden list has no Enter operation. Use Delete to unhide while
        // staying in the manager; this avoids accidental restoration.
        return;
    }
    if(memoryCol_==7) {
        if(toEdit) {speech_("No F7 editor for parameter steps");return;}
        memoryReturnGroup_=0;
        memoryReturnParam_=entry.param;
        memoryReturnPosition_=-1;
        // A step belongs to an FX parameter, not to one group occurrence.
        fxOrder_.custom=false;
    }
    if(memoryCol_==6) {
        if(toEdit) {speech_("Default has no F7 editor. Press Enter to restore");return;}
        if(!defaultConfirm_) {
            // Enter on Default means LOAD the stored sound, not DELETE all
            // other memories. Always return to the normal FX parameter grid.
            if(!resetAllToDefault(false))return;
            memoryReturnF7_=false;
            memoryReturnF7Filter_.clear();
            memoryReturnGroup_=0;
            memoryReturnParam_=parameter_;
            memoryReturnPosition_=-1;
            fxOrder_.custom=false;
            // Also enter the FX grid when invoked via the standalone
            // REAPER "FX Memories" action.
            memoryStandalone_=false;
            memoryExit(false);
            speech_("Default restored. "+currentParameterSpeech());
            return;
        }
        defaultConfirm_=false;
        // Delete on Default retains the explicit Yes/No confirmation and
        // clears the other FX memories only after a successful restore.
        if(!resetAllToDefault(false))return;
        fxOrder_.paramSlots.clear();fxOrder_.groups.clear();fxOrder_.groupNames.clear();fxOrder_.ccLinks.clear();
        fxOrder_.setExtraValue("cc_runtime_fixed_map_enabled_v1","");
        fxOrder_.setExtraValue("temporary_group_v1","");
        fxOrder_.deleteCustomOrder();fixedCc_=false;floatingCc_=floatingWaiting_=false;pickup_.clear();
        memoryReturnF7_=false;
        memoryReturnF7Filter_.clear();
        memoryReturnGroup_=0;
        memoryReturnParam_=parameter_;
        memoryReturnPosition_=-1;
        fxOrder_.custom=false;
        saveStructure();
        memoryStandalone_=false;
        memoryExit(false);
        speech_("Default restored. Plugin Order. "+currentParameterSpeech());
        return;
    }
    if(memoryCol_==3) {
        if(entry.param<0 && entry.param!=compareParamIndex && !eqVirtualValid(entry.param) && !dynamicsVirtualValid(entry.param)){speech_("No parameter");return;}
        // Jump to the physical or Compare parameter without entering learn.
    }
    if(memoryCol_==0 || memoryCol_==2 || memoryCol_==3 || memoryCol_==5) {
        if((entry.param<0 && entry.param!=compareParamIndex && !eqVirtualValid(entry.param) && !dynamicsVirtualValid(entry.param)) || entry.param>=count_){speech_("Missing parameter");return;}
        if(memoryCol_==5 && entry.slot>0 && fxOrder_.hidden.count(entry.param)) {
            speech_("Hidden parameter. Restore it from Hidden parameters first");return;
        }
        if(memoryCol_==2) {
            fxOrder_.hidden.erase(entry.param);
            saveStructure();
            fxOrder_.custom=true;
            if(fxOrder_.hasRealModifications())saveStructure();
            rebuildMemoryColumns();
        }
        if(memoryCol_==5 && entry.slot==0)fxOrder_.custom=true;
        // A position pointing to a hidden Custom Order parameter can still be
        // reached in Plugin Order, which always exposes every native FX param.
        if((memoryCol_==0 || memoryCol_==3) && fxOrder_.hidden.count(entry.param))
            fxOrder_.custom=false;
        // Escape/Enter returns to the FX grid at the requested parameter;
        // duplicates retain the selected raw occurrence, not just the ID.
        memoryReturnGroup_=memoryCol_==5?entry.slot:0;
        memoryReturnParam_=entry.param;
        memoryReturnPosition_=-1;
        if(entry.rawPos>=0) {
            int visiblePosition=0;
            const auto& source=entry.slot>0?fxOrder_.groups.at(entry.slot):fxOrder_.order;
            for(int i=0;i<=entry.rawPos && i<static_cast<int>(source.size());++i)
                if(source[static_cast<size_t>(i)]!=compareParamIndex &&
                   !fxOrder_.hidden.count(source[static_cast<size_t>(i)]))++visiblePosition;
            memoryReturnPosition_=visiblePosition-1;
        }
    } else if(memoryCol_==1) {
        memoryReturnGroup_=entry.slot;
        memoryReturnPosition_=-1;
        const auto& group=fxOrder_.groups.at(entry.slot);
        const auto firstVisible=std::find_if(group.begin(),group.end(),[&](int id){
            return id!=compareParamIndex && !fxOrder_.hidden.count(id);
        });
        memoryReturnParam_=firstVisible!=group.end()?*firstVisible:parameter_;
    } else if(memoryCol_==4) {
        fxOrder_.custom=true;
        saveStructure();
        memoryReturnGroup_=0;
        memoryReturnPosition_=-1;
    }
    const bool standalone=memoryStandalone_;
    // Enter in standalone FX Memories selects the memory and opens FX Params. Escape
    // without selecting returns directly to REAPER (no accidental edit).
    memoryStandalone_=false;
    memoryReturnF7_=false;
    memoryExit(!toEdit);
    if(toEdit) {
        if(!fxOrder_.custom && !groupSlot_)fxOrder_.custom=true;
        rebuildView(parameter_,viewPos_);
        enterF7();
    } else if(standalone) {
        speech_("FX Params. "+(groupSlot_?groupLabel(groupSlot_)+". ":"")+
                (visible_.empty()?"No visible parameters":currentParameterSpeech()));
    }
}
void FxNavigator::memoryDelete() {
    const int targetColumn=memoryCol_;
    const auto& col=memoryColumns_[static_cast<size_t>(targetColumn)];
    if(col.empty()){speakMemory();return;}
    auto indexes=memorySelected_[static_cast<size_t>(targetColumn)];
    if(indexes.empty())indexes.insert(memoryRow_);
    // Remember the logical cursor: retain its row if it survives, otherwise
    // choose the next surviving row, or the previous at the end.
    int focusRow=memoryRow_;
    if(indexes.count(focusRow)) {
        int next=focusRow+1;
        while(next<static_cast<int>(col.size()) && indexes.count(next))++next;
        if(next==static_cast<int>(col.size())) {
            next=focusRow-1;
            while(next>=0 && indexes.count(next))--next;
        }
        focusRow=next;
    }
    if(focusRow>=0)
        focusRow-=static_cast<int>(std::count_if(indexes.begin(),indexes.end(),
            [focusRow](int row){return row<focusRow;}));
    // Only the current column can be deleted. Validate the snapshot BEFORE
    // changing anything; especially important for duplicate group occurrences.
    std::vector<MemoryEntry> entries;
    for(int row:indexes) {
        if(row<0 || row>=static_cast<int>(col.size())) {speech_("Memory selection changed. Select again");return;}
        entries.push_back(col[static_cast<size_t>(row)]);
    }
    if(targetColumn==6) {
        // The default snapshot is intentionally protected by the existing
        // Yes/No confirmation, even when selected with Ctrl+A.
        defaultConfirm_=true;defaultYes_=false;speakMemory();return;
    }
    for(const auto& entry:entries) {
        if(targetColumn==5) {
            if(entry.slot>0) {
                const auto found=fxOrder_.groups.find(entry.slot);
                if(found==fxOrder_.groups.end() || entry.rawPos<0 ||
                    entry.rawPos>=static_cast<int>(found->second.size()) ||
                    found->second[static_cast<size_t>(entry.rawPos)]!=entry.param) {
                    speech_("Memory selection changed. Select again");return;
                }
            } else if(entry.rawPos<0 || entry.rawPos>=static_cast<int>(fxOrder_.order.size()) ||
                      fxOrder_.order[static_cast<size_t>(entry.rawPos)]!=entry.param ||
                      std::count(fxOrder_.order.begin(),fxOrder_.order.end(),entry.param)<=1) {
                speech_("Memory selection changed. Select again");return;
            }
        }
        if(targetColumn==7 && stepParameterName(entry.param).empty()) {
            speech_("Missing parameter. Selection unchanged");return;
        }
    }
    // Descending visible-list position is also descending raw position for
    // each group's occurrences and Custom Order, so no index drifts occur.
    std::reverse(entries.begin(),entries.end());
    int removed=0;
    bool structureChanged=false,stepsChanged=false;
    for(const auto& entry:entries) {
        switch(targetColumn) {
            case 0:
                fxOrder_.paramSlots.erase(entry.slot);structureChanged=true;break;
            case 1:
                fxOrder_.groups.erase(entry.slot);fxOrder_.groupNames.erase(entry.slot);
                if(memoryReturnGroup_==entry.slot) {memoryReturnGroup_=0;memoryReturnPosition_=-1;memoryReturnF7_=false;}
                structureChanged=true;break;
            case 2: fxOrder_.hidden.erase(entry.param);structureChanged=true;break;
            case 3:
                if(!fxOrder_.deleteCcLink(entry.param))continue;
                clearNativeLearn(entry.param);pickup_.erase(entry.param);break;
            case 4:
                fxOrder_.deleteCustomOrder();groupSlot_=0;memoryReturnGroup_=0;
                memoryReturnF7_=false;break;
            case 5:
                if(entry.slot>0) {
                    auto& group=fxOrder_.groups.at(entry.slot);
                    group.erase(group.begin()+entry.rawPos);
                } else {
                    fxOrder_.order.erase(fxOrder_.order.begin()+entry.rawPos);
                }
                structureChanged=true;break;
            case 7:
                parameterSteps_[entry.param]={stepParameterName(entry.param),0};
                parameterStepsDirty_=true;
                if(entry.param==parameter_) {stepScale_=0;stepActiveParameter_=parameter_;}
                stepsChanged=true;break;
            default:continue;
        }
        ++removed;
    }
    if(structureChanged)saveStructure();
    if(stepsChanged && !flushParameterSteps()) {speech_("Parameter steps not saved");return;}
    for(auto& selection:memorySelected_)selection.clear();
    rebuildMemoryColumns();
    // Stay in the same column if it still has entries; otherwise advance to
    // the next occupied one, matching the existing single-Delete behavior.
    if(memoryColumns_[static_cast<size_t>(memoryCol_)].empty()) {
        int first=0;
        while(first<8 && memoryColumns_[static_cast<size_t>(first)].empty())++first;
        memoryCol_=first==8?0:first;
    }
    const auto& newList=memoryColumns_[static_cast<size_t>(memoryCol_)];
    memoryRow_=newList.empty()?0:std::clamp(memoryCol_==targetColumn?focusRow:0,
        0,static_cast<int>(newList.size())-1);
    speech_("Deleted "+std::to_string(removed)+ (removed==1?" memory. ":" memories. ")+
        (memoryHasEntries()?memoryReview():"Parameter Navigator. No memories"));
}
void FxNavigator::memoryTypeAhead(const Key& k) {
    const auto& entries = memoryColumns_[static_cast<size_t>(memoryCol_)];
    if (entries.empty()) return;
    const int next = typeAhead_.find(typeAheadCharacter(k.vk, k.shift, k.character), k.time, k.repeat,
        memoryRow_, static_cast<int>(entries.size()), k.shift,
        [&entries](int i) { return typeAheadWide(entries[static_cast<size_t>(i)].label); });
    if (next >= 0) { memoryRow_ = next; speakMemory(); }
}
void FxNavigator::memoryNavigate(const Key& k) {
    if (k.ctrl && k.shift && !k.alt && !k.altGr && k.vk=='M') {
        if (!k.repeat) {
            defaultConfirm_=false;
            defaultRegenerate_=false;
            memoryExit();
        }
        return;
    }
    if(defaultConfirm_) {
        if(k.repeat)return;
        // A confirmation is modal: ignore modified Y/N and other commands.
        if(k.ctrl || k.alt || k.shift)return;
        if(k.vk==VK_ESCAPE || k.vk=='N'){defaultConfirm_=false;defaultYes_=false;speakMemory("No");return;}
        if(k.vk==VK_LEFT||k.vk==VK_UP){if(defaultYes_){defaultYes_=false;speakMemory();}return;}
        if(k.vk==VK_RIGHT||k.vk==VK_DOWN){if(!defaultYes_){defaultYes_=true;speakMemory();}return;}
        if(k.vk=='Y'||k.vk==VK_RETURN) {
            if(k.vk=='Y'||defaultYes_) {memoryCol_=6;memoryRow_=0;memoryLoad(false);}
            else {defaultConfirm_=false;speakMemory("No");}
        }
        return;
    }
    if(defaultRegenerate_ && !k.repeat && k.vk==VK_RETURN) {
        defaultRegenerate_=false;snapshotDefaultsIfMissing();
        if(!fxOrder_.hasDefaultValues()){defaultRegenerate_=true;speech_("Cannot save default");return;}
        memoryExit();return;
    }
    if(k.repeat && (k.vk==VK_F7||k.vk==VK_RETURN||k.vk==VK_DELETE||
                    (k.shift && k.vk==VK_SPACE)||(k.ctrl && k.vk=='A')))return;
    if(!k.ctrl && !k.alt && typeAheadCharacter(k.vk, k.shift, k.character) >= L'!') {
        memoryTypeAhead(k); return;
    }
    if(k.vk==VK_ESCAPE) {memoryExit();return;}
    if(k.vk==VK_TAB){speakMemory();return;}
    if(k.shift && !k.ctrl && !k.alt && k.vk==VK_SPACE) {
        const auto& col=memoryColumns_[static_cast<size_t>(memoryCol_)];
        if(col.empty()){speakMemory();return;}
        auto& selected=memorySelected_[static_cast<size_t>(memoryCol_)];
        if(!selected.erase(memoryRow_))selected.insert(memoryRow_);
        speech_(std::string(selected.count(memoryRow_)?"Selected. ":"Not selected. ")+
                memoryColumnName()+". "+col[static_cast<size_t>(memoryRow_)].label);
        return;
    }
    if(k.ctrl && !k.shift && !k.alt && k.vk=='A') {
        const auto& col=memoryColumns_[static_cast<size_t>(memoryCol_)];
        if(col.empty()){speakMemory();return;}
        auto& selected=memorySelected_[static_cast<size_t>(memoryCol_)];
        selected.clear();
        for(int i=0;i<static_cast<int>(col.size());++i)selected.insert(i);
        speech_(std::to_string(selected.size())+" memories selected. "+memoryReview());
        return;
    }
    if(k.alt && k.shift && !k.ctrl && !k.altGr &&
       (k.vk==VK_UP || k.vk==VK_DOWN || k.vk==VK_LEFT || k.vk==VK_RIGHT)) {
        // Horizontal Alt+Shift+arrows have no action in either memory manager.
        if(k.vk==VK_LEFT || k.vk==VK_RIGHT)return;
        const auto& selected=memorySelected_[static_cast<size_t>(memoryCol_)];
        if(selected.empty()){speech_("0 selected");return;}
        const auto& col=memoryColumns_[static_cast<size_t>(memoryCol_)];
        if(k.vk==VK_DOWN) {
            const auto next=selected.upper_bound(memoryRow_);
            if(next!=selected.end() && *next>=0 && *next<static_cast<int>(col.size())) {
                memoryRow_=*next;speakMemory();
            }
        } else {
            auto previous=selected.lower_bound(memoryRow_);
            if(previous!=selected.begin()) {
                --previous;
                if(*previous>=0 && *previous<static_cast<int>(col.size())) {
                    memoryRow_=*previous;speakMemory();
                }
            }
        }
        // At the first/last selected row, behave like F7: silent boundary.
        return;
    }
    if(k.vk==VK_F7 && !k.ctrl && !k.alt){memoryLoad(true);return;}
    if(k.alt && !k.ctrl && !k.shift && (k.vk==VK_LEFT || k.vk==VK_RIGHT)) {
        if(memoryCol_==7 && !memoryColumns_[7].empty()) {
            const auto e=memoryColumns_[7][static_cast<size_t>(memoryRow_)];
            const int before=savedStepForParameter(e.param);
            const int next=std::clamp(before+(k.vk==VK_LEFT?-1:1),-10,10);
            if(next==before)return;
            parameterSteps_[e.param]={stepParameterName(e.param),next};
            parameterStepsDirty_=true;
            if(e.param==parameter_) {stepScale_=next;stepActiveParameter_=parameter_;}
            if(!flushParameterSteps()) {speech_("Step memory not saved");return;}
            for(auto& selection:memorySelected_)selection.clear();
            rebuildMemoryColumns();
            if(memoryColumns_[7].empty()) {memoryCol_=7;memoryRow_=0;}
            else memoryRow_=std::clamp(memoryRow_,0,static_cast<int>(memoryColumns_[7].size())-1);
            speakMemory();return;
        }
        const int next=std::clamp(stepScale_+(k.vk==VK_LEFT?-1:1),-10,10);
        if(next!=stepScale_) {stepScale_=next;markParameterStepChanged();rememberPosition();speech_("Step "+std::to_string(stepScale_));}
        return;
    }
    if(k.ctrl && !k.alt && !k.shift && (k.vk==VK_HOME || k.vk==VK_END)) {
        for(int c=k.vk==VK_HOME?0:7;c>=0&&c<8;c+=(k.vk==VK_HOME?1:-1))
            if(!memoryColumns_[static_cast<size_t>(c)].empty()){
                memoryCol_=c;memoryRow_=k.vk==VK_HOME?0:
                    static_cast<int>(memoryColumns_[static_cast<size_t>(c)].size())-1;
                speakMemory();return;
            }
        speakMemory();return;
    }
    if(!k.ctrl&&!k.alt&&!k.shift) {
        if(k.vk==VK_LEFT){memorySelectColumn(-1);return;}
        if(k.vk==VK_RIGHT){memorySelectColumn(1);return;}
        const auto size=static_cast<int>(memoryColumns_[static_cast<size_t>(memoryCol_)].size());
        if(k.vk==VK_UP || k.vk==VK_DOWN || k.vk==VK_PRIOR || k.vk==VK_NEXT || k.vk==VK_HOME || k.vk==VK_END) {
            if(!size){speakMemory();return;}
            int target=memoryRow_;
            if(k.vk==VK_HOME)target=0;
            else if(k.vk==VK_END)target=size-1;
            else if(k.vk==VK_UP)target--;
            else if(k.vk==VK_DOWN)target++;
            else if(k.vk==VK_PRIOR || k.vk==VK_NEXT) {
                // Lua: floor(step_multiplier * 5 + .5), at least 2.
                const int jump=std::clamp(static_cast<int>(5.0*std::pow(2.0,stepScale_)+0.5),2,1000000);
                target+=(k.vk==VK_PRIOR?-jump:jump);
            }
            const int next=std::clamp(target,0,size-1);
            if(next!=memoryRow_ || k.vk==VK_PRIOR || k.vk==VK_NEXT || k.vk==VK_HOME || k.vk==VK_END) {
                memoryRow_=next;speakMemory();
            }
            return;
        }
        if(k.vk==VK_RETURN){memoryLoad(false);return;}
        if(k.vk==VK_DELETE){memoryDelete();return;}
    }
}
} // namespace lrp
