"""TEST62.4: independent F7 removal/hide shortcuts and stable cursor position.
Only static verification and behavioral model; interactive Windows host test required.
"""
from pathlib import Path
root=Path(__file__).resolve().parents[1]
nav=(root/'src/FxNavigator.cpp').read_text(encoding='utf-8')
order=(root/'src/FxNavigatorOrder.cpp').read_text(encoding='utf-8')
header=(root/'include/lrp/FxNavigator.h').read_text(encoding='utf-8')
mem=(root/'src/FxNavigatorMemories.cpp').read_text(encoding='utf-8')
assert 'void hideSelected(bool globalHide);' in header
assert 'if (group!=fxOrder_.groups.end()) {\n                    groupSlot_=last->groupSlot;' in order
assert 'void FxNavigator::hideSelected(bool globalHide)' in order
assert 'if(k.ctrl&&!k.alt&&!k.shift&&k.vk==VK_DELETE){' in order
assert 'if(k.ctrl&&k.shift&&!k.alt&&k.vk==VK_DELETE){' in order
assert 'else if(!k.repeat)hideSelected(false);' in order
assert 'else if(!k.repeat)hideSelected(true);' in order
assert 'if(usedActive_)speech_("F7 Ctrl+Delete removes from groups, not Used.' in order
assert 'Restore hidden parameters from Custom Order' not in order
assert 'fxOrder_.hidden.clear()' not in order[order.index('bool FxNavigator::handleF7'):]
assert 'Ctrl+Delete removes parameters from a group only.' in order
assert 'if(!globalHide && (!groupSlot_ || groupEditAll_))' in order
assert 'if(globalHide && !groupSlot_ && !fxOrder_.custom)' in order
assert 'fxOrder_.hidden.insert(idsToHide.begin(),idsToHide.end());' in order
assert 'case 2: fxOrder_.hidden.erase(entry.param);structureChanged=true;break;' in mem
# Verify that the C++ method uses the previous VISIBLE position and stable
# occurrence identity, not rebuildView(parameter_) (which jumps to first).
removal=order[order.index('void FxNavigator::hideSelected(bool globalHide)'):order.index('void FxNavigator::saveGroup(int slot)')]
for token in ('f7OriginalPosition(viewPos_)','clearF7Filter();',
              'focusAfterRemoval(visibleToRemove)',
              'visibleToRemove.insert(visibleIndex)',
              'const auto [nextParam,nextPosition]',
              'rebuildView(nextParam,nextPosition);',
              'rows.erase(rows.begin()+*it);',
              'std::distance(removed.begin(),removed.lower_bound(anchor))',
              'f7Selected_.clear();f7SnakePath_.clear();f7SnakeDirections_.clear();'):
    assert token in removal,token
assert 'rebuildView(parameter_);' not in removal
assert 'k.vk==VK_DELETE' in nav and 'k.ctrl && k.shift && !k.alt' in nav

def after_remove(rows, cursor, removed):
    """Cursor algorithm matching the C++ code, using positions not IDs."""
    gone=set(removed)
    assert all(0<=i<len(rows) for i in gone)
    if cursor not in gone:
        anchor=cursor
    else:
        anchor=next((i for i in range(cursor+1,len(rows)) if i not in gone),None)
        if anchor is None:
            anchor=next((i for i in range(cursor-1,-1,-1) if i not in gone),None)
    out=[id for i,id in enumerate(rows) if i not in gone]
    if anchor is None:return out,None
    target=anchor-sum(i<anchor for i in gone)
    assert out[target]==rows[anchor]
    return out,target

# One removal in the middle goes to the following parameter, not first.
assert after_remove([10,20,30,40],1,{1})==([10,30,40],1)
# Last goes to predecessor, and one remaining stays selected.
assert after_remove([10,20,30,40],3,{3})==([10,20,30],2)
assert after_remove([10],0,{0})==([],None)
# Multi-removals: preserve cursor if not removed, even if earlier positions shift.
assert after_remove([10,20,30,40,50],3,{0,1})==([30,40,50],1)
assert after_remove([10,20,30,40,50],2,{1,2,3})==([10,50],1)
assert after_remove([10,20,30,40,50],4,{1,2,4})==([10,40],1)
# Duplicate IDs must preserve the precise occurrence rather than first of same ID.
assert after_remove([10,20,10,20,10],2,{2})==([10,20,20,10],2)
assert after_remove([10,20,10,20,10],3,{1})==([10,10,20,10],2)
# Group with hidden RAW entries: cursor index is in the visible view.
raw=[10,99,20,10,99,30]
hidden={99}
shown=[id for id in raw if id not in hidden]
assert shown==[10,20,10,30]
assert after_remove(shown,1,{1})==([10,10,30],1)
# Global hide drops every visible occurrence of selected ID, including duplicates.
ids_to_hide={20}
assert after_remove([10,20,30,20,40],1,{i for i,id in enumerate([10,20,30,20,40]) if id in ids_to_hide})==([10,30,40],1)
print('TEST62.4 PASS: separate F7 delete shortcuts, cursor successor/predecessor, duplicates and hidden offsets (source only)')
