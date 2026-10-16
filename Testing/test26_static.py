"""TEST26 static regression checks; intentionally NO native C++ compilation."""
from pathlib import Path
root=Path(__file__).resolve().parents[1]
h=(root/'include/lrp/FxNavigator.h').read_text()
fx=(root/'src/FxNavigator.cpp').read_text()
order=(root/'src/FxNavigatorOrder.cpp').read_text()
router=(root/'src/InputRouter.cpp').read_text()
proxy=(root/'src/TitleProxy.cpp').read_text()
assert 'VERSION 0.0.' in (root/'CMakeLists.txt').read_text()
assert 'groupReturnEdit_' in h and 'groupReturnCustom_' in h
assert 'groupReturnFilter_' in h and 'groupReturnSelection_' in h
assert 'groupReturnActive_=true;' in order and 'groupReturnActive_=false;' in order
assert 'fxOrder_.custom=wasCustom;' in order and 'editF7_=wasEditing;' in order
assert 'groupReturnSelection_=f7Selected_;' in order
assert 'if(groupSlot_==slot)' in order and 'if(!groupSlot_)' in order
assert 'k.vk<=VK_F12' in fx and 'k.vk <= VK_F12' in fx
assert 'vk == VK_F12 && !(GetKeyState(VK_CONTROL)' in router
assert 'wp == VK_F12' in proxy and 'GetKeyState(VK_CONTROL)' in proxy
assert 'if(!editF7_)return;' not in order.split('void FxNavigator::applyF7Filter',1)[1].split('FxNavigator::EditHistory',1)[0]
assert 'applyF7Filter(query);' in fx
assert 'else if(f7FilterActive_){' in fx and 'clearF7Filter();' in fx
assert 'f7FilterActive_?". Search results"' in fx
assert 'if(k.alt&&k.shift&&!k.ctrl&&' in order
assert 'const int currentColumn=viewPos_/height, currentRow=viewPos_%height;' in order
assert 'if(col!=currentColumn)continue;' in order
assert 'secondary=std::abs(row-currentRow);' in order
assert 'f7FilterPositions_.begin()' in order
# Example semantics, not an execution of the native search matcher:
import re
def lookup(name,query):
    if not (len(query)>=2 and query.startswith('"') and query.endswith('"')):
        return query.lower() in name.lower()
    have=re.findall(r'\w+',name.lower()); want=re.findall(r'\w+',query[1:-1].lower())
    return bool(want) and any(all((have[start+i].startswith(w) if len(want)>1 and i==len(want)-1 else have[start+i]==w)
           for i,w in enumerate(want)) for start in range(len(have)-len(want)+1))
assert lookup('Slot 1 Filter','"slot 1 fil"')
assert not lookup('Slot 10 Filter','"slot 1 fil"')
assert not lookup('Slot 19 LFO1','"slot 1 lfo1"')
assert lookup('Kick','"kick"') and not lookup('Kickoff','"kick"')
assert lookup('Kickoff','kick')
print('TEST26 source and example semantics PASS; native build and NVDA testing pending')
