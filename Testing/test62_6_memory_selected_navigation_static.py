"""TEST62.6: FX/Track memory Alt+Shift selected-only navigation.
Source-contract test plus reference behavior simulation; actual keyboard routing
is exercised via Windows GitHub Actions compilation and REAPER manual testing.
"""
from pathlib import Path
from bisect import bisect_left, bisect_right
r=Path(__file__).resolve().parents[1]
fx=(r/'src/FxNavigatorMemories.cpp').read_text()
track=(r/'src/TrackNavigatorMemories.cpp').read_text()
fn=(r/'src/FxNavigator.cpp').read_text()
tn=(r/'src/TrackNavigator.cpp').read_text()
for name,source,route,col in [('FX',fx,fn,'memoryCol_'),('Track',track,tn,'memoryColumn_')]:
    assert 'k.alt && k.shift && !k.ctrl' in source, name
    assert 'k.alt && k.shift && !k.ctrl' in route, name
    for key in ('VK_LEFT','VK_RIGHT','VK_UP','VK_DOWN'):
        assert key in source and key in route,name
    assert f'memorySelected_[static_cast<size_t>({col})]' in source,name
    assert 'selected.upper_bound(memoryRow_)' in source,name
    assert 'selected.lower_bound(memoryRow_)' in source,name
    assert 'memoryRow_=*next;speakMemory();' in source,name
    assert 'memoryRow_=*previous;speakMemory();' in source,name
    assert 'if(k.vk==VK_LEFT || k.vk==VK_RIGHT)return;' in source if name=='FX' else 'if(k.vk == VK_LEFT || k.vk == VK_RIGHT)return;' in source
    assert 'speech_("0 selected")' in source,name
    assert 'if(selected.empty())' in source,name
    assert 'memorySelectColumn(-1)' in fx  # normal left/right still active
    assert 'memoryAdjustStep(' in track # normal Alt+left/right still active

# Contract of the selection-relative movement, including a sparse column.
def nav(selected,position,direction):
    a=sorted(selected)
    if direction=='down':
        i=bisect_right(a,position)
        return a[i] if i<len(a) else position
    i=bisect_left(a,position)
    return a[i-1] if i else position
sel={1,4,8}
assert nav(sel,0,'down')==1
assert nav(sel,1,'down')==4
assert nav(sel,3,'down')==4
assert nav(sel,4,'up')==1
assert nav(sel,8,'down')==8 # quiet boundary
assert nav(sel,1,'up')==1
assert nav(sel,7,'up')==4
assert nav({2},0,'down')==2
assert nav({2},2,'down')==2
assert nav(set(),3,'up')==3
print('TEST62.6 PASS: FX/Track selected-only vertical shortcuts and inert horizontal gestures')
