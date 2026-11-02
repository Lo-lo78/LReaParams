"""TEST62.1 native-source contract + isolated position model (no REAPER runtime).

Does not replace a Windows MSVC build or interactive NVDA tests.
"""
from pathlib import Path
r=Path(__file__).resolve().parents[1]
cpp=(r/'src/FxNavigatorOrder.cpp').read_text(encoding='utf-8')
mem=(r/'src/FxNavigatorMemories.cpp').read_text(encoding='utf-8')
fx=(r/'src/FxOrder.cpp').read_text(encoding='utf-8')
workflow=(r/'.github/workflows/build-windows.yml').read_text(encoding='utf-8')
header=(r/'include/lrp/FxNavigator.h').read_text(encoding='utf-8')
assert 'std::array<std::vector<MemoryEntry>,7>' in header
for s in (
    'Hidden is global to Custom Order and ALL groups',
    'fxOrder_.hidden.count(id)!=0',
    'const auto& sourceList=groupSlot_?fxOrder_.groups.at(groupSlot_):fxOrder_.order;',
    'if(id==compareParamIndex || fxOrder_.hidden.count(id))continue;',
    'if(clipSourceGroup_!=groupSlot_ && (!clipSourceGroup_ || !groupSlot_))',
    'Cut pending.',
    'const bool acrossGroups=clipCut_ && clipSourceGroup_!=groupSlot_;',
    'if(acrossGroups) {',
    'origin->swap(remainder);',
    'saveUndo(); // One Undo captures BOTH groups',
    'if(clipCut_) {clip_.clear();clipPositions_.clear();}',
    'const bool createGroup=groupSlot_ && fxOrder_.groups.find(groupSlot_)==fxOrder_.groups.end();',
    'Restore hidden parameters from Custom Order',
    'return "Group "+(it!=fxOrder_.groupNames.end() && !it->second.empty()',
):assert s in cpp,s
assert 'for(int id:source)if(id!=compareParamIndex && (!custom||!hidden.count(id)))' in fx
assert 'const auto& source=custom?order:defaultOrder_;' in fx
for s in (
    'e.label=fxOrder_.label(id)+". Custom Order. Copy "',
    'for(const auto& group:fxOrder_.groups)',
    'e.slot=group.first;e.param=id;e.rawPos=pos;',
    'e.occurrence=++occurrences[id];',
    '". Occurrence "+std::to_string(e.occurrence)',
    '". Position "+std::to_string(pos+1)',
    '(fxOrder_.hidden.count(id)?". Hidden":std::string())',
    'memoryReturnGroup_=memoryCol_==5?entry.slot:0;',
    'const auto& source=entry.slot>0?fxOrder_.groups.at(entry.slot):fxOrder_.order;',
    'found->second.erase(found->second.begin()+entry.rawPos);',
    'if(memoryCol_==5 && entry.slot>0 && fxOrder_.hidden.count(entry.param))',
    'if(memoryCol_==1)return "Groups. "+entry.label;',
):assert s in mem,s
assert 'python Testing/test62_1_fx_group_memories_static.py' in workflow
# Illustrate that the visible index is NOT the raw index when one or more
# hidden entries (and same-ID copies) intervene.
def visible(rows,hidden):return [v for v in rows if v not in hidden]
def raw_occurrences(rows,hidden,selected):
    v=0;out=[]
    for i,id in enumerate(rows):
        if id in hidden:continue
        if v in selected:out.append(i)
        v+=1
    return out
raw=[2,9,2,7,4,2]; hidden={9,7}
assert visible(raw,hidden)==[2,2,4,2]
assert raw_occurrences(raw,hidden,{1,3})==[2,5]
# Atomic cut: source is left untouched before paste; copied destination
# and reduced source are committed together, preserving hidden entries.
source=[2,9,2,7,4,2]; dest=[5,9,6]; selected=raw_occurrences(source,hidden,{1,3})
clip=[source[i] for i in selected]
assert source==[2,9,2,7,4,2] and clip==[2,2]
new_source=[v for i,v in enumerate(source) if i not in selected]
new_dest=dest[:1]+clip+dest[1:]
assert new_source==[2,9,7,4] and new_dest==[5,2,2,9,6]
assert source==[2,9,2,7,4,2] # original unchanged until successful paste
# One hidden ID is omitted everywhere except Plugin Order.
plugin_order=[2,9,7,4]
assert visible(plugin_order,hidden)==[2,4]
assert plugin_order==[2,9,7,4]
print('TEST62.1 PASS: static contracts and hidden/duplicate position model; host unverified')
