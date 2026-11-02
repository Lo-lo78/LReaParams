"""TEST62.5 FX/Track memories: Shift+Space, Ctrl+A, selected-first speech,
batch Delete. This verifies source structure and deletion-index model only;
compile + REAPER/NVDA interaction require Windows CI/manual testing.
"""
from pathlib import Path
root=Path(__file__).resolve().parents[1]
fx=(root/'src/FxNavigatorMemories.cpp').read_text(encoding='utf-8')
track=(root/'src/TrackNavigatorMemories.cpp').read_text(encoding='utf-8')
fh=(root/'include/lrp/FxNavigator.h').read_text(encoding='utf-8')
th=(root/'include/lrp/TrackNavigator.h').read_text(encoding='utf-8')
fn=(root/'src/FxNavigator.cpp').read_text(encoding='utf-8')
tn=(root/'src/TrackNavigator.cpp').read_text(encoding='utf-8')
for name,src,head,nav,ncols in [('FX',fx,fh,fn,8),('Track',track,th,tn,5)]:
    assert f'std::array<std::set<int>,{ncols}> memorySelected_' in head,name
    assert 'if(k.ctrl' in src or 'if (k.ctrl' in src
    assert "k.vk=='A'" in src or "k.vk == 'A'" in src
    assert 'k.vk==VK_SPACE' in src or 'k.vk == VK_SPACE' in src
    assert 'selected.erase(memoryRow_' in src,name
    assert 'selected.insert(memoryRow_' in src,name
    assert 'Selected. ' in src,name
    assert 'Not selected. ' in src,name
    assert 'selected.clear()' in src,name
    assert ('memorySelected_' in nav if name=='Track' else 'if (memoryManager_)' in nav),name
    assert 'memoryDelete()' in src,name
    assert 'std::vector<MemoryEntry> entries;' in src if name=='FX' else 'std::vector<MemoryItem> items;' in src
    assert 'for(auto& selection:memorySelected_)selection.clear();' in src
assert 'const std::string selected=memorySelected_' in fx
assert 'std::reverse(entries.begin(),entries.end());' in fx
for src in (fx,track):
    assert 'int focusRow=memoryRow_;' in src
    assert 'if(indexes.count(focusRow))' in src
    assert 'while(next>=0 && indexes.count(next))--next;' in src
assert 'group.erase(group.begin()+entry.rawPos);' in fx
assert 'fxOrder_.order.erase(fxOrder_.order.begin()+entry.rawPos);' in fx
assert 'if(targetColumn==6)' in fx and 'defaultConfirm_=true' in fx
assert 'fxOrder_.hidden.erase(entry.param);structureChanged=true;' in fx
assert 'if(indexes.empty())indexes.insert(memoryRow_);' in fx
assert 'if(indexes.empty())indexes.insert(memoryRow_);' in track
assert 'std::vector<MemoryItem> items;' in track
assert 'memory_.flush();' in track
assert '(memorySelected_[static_cast<size_t>(col)].count(memoryRow_) ? "Selected. " : "")' in tn
assert 'k.vk==VK_HOME||k.vk==VK_END||k.vk==\'A\'' in fn
assert 'k.vk == VK_HOME || k.vk == VK_END || k.vk == \'A\'' in tn

# Simulate deleting multiple copies from a single logical row list. The
# selected raw positions must be processed high-to-low to prevent index drift.
def remove_rows(rows,positions):
    out=list(rows)
    for pos in sorted(positions,reverse=True):out.pop(pos)
    return out
assert remove_rows([10,20,10,20,30],{1,3})==[10,10,30]
assert remove_rows([10,10,10,20],{1,2})==[10,20]
assert remove_rows([10,20,30],{0,1,2})==[]
# Single Delete without explicit selection acts on just the current row.
assert remove_rows([10,20,30],{1})==[10,30]
# Stable focus: if focused row survives, adjust its position by earlier
# deletions; otherwise advance to the next surviving row (or prior at end).
def focus_after(size,current,selected):
    anchor=current
    if anchor in selected:
        right=next((i for i in range(anchor+1,size) if i not in selected),None)
        anchor=right if right is not None else next((i for i in range(anchor-1,-1,-1) if i not in selected),-1)
    return max(0,anchor-sum(i<anchor for i in selected))
assert focus_after(5,3,{0,1})==1
assert focus_after(5,2,{1,2})==1
assert focus_after(5,4,{4})==3
assert focus_after(1,0,{0})==0
# Selection is column-local and must not delete from another category.
cols={0:[10,20],1:[30,40,50]}
sel={0:{0},1:{1,2}}
cols[1]=remove_rows(cols[1],sel[1]); assert cols=={0:[10,20],1:[30]}
print('TEST62.5 PASS: FX+Track per-column selection, speech, batch delete, duplicates and default confirmation (static)')
