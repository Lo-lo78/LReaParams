"""TEST29: source-level checks and reference range model, no C++ compilation."""
from pathlib import Path
root=Path(__file__).resolve().parents[1]
fx=(root/'src/FxNavigatorOrder.cpp').read_text(encoding='utf-8')
outer=(root/'src/FxNavigator.cpp').read_text(encoding='utf-8')
h=(root/'include/lrp/FxNavigator.h').read_text(encoding='utf-8')
assert 'VERSION 0.0.31' in (root/'CMakeLists.txt').read_text()
assert 'void selectF7ToGlobalEdge(bool toEnd);' in h
assert 'void FxNavigator::selectF7ToGlobalEdge(bool toEnd)' in fx
assert 'const int target=toEnd?static_cast<int>(visible_.size())-1:0;' in fx
assert 'if(target==viewPos_)return;' in fx
assert 'const int origin=viewPos_;' in fx
assert 'const int first=std::min(origin,target);' in fx
assert 'const int last=std::max(origin,target);' in fx
assert 'f7Selected_.erase(f7OriginalPosition(pos));' in fx
assert 'f7Selected_.insert(f7OriginalPosition(pos));' in fx
assert 'selectF7ToGlobalEdge(k.vk==VK_END);return true;' in fx
assert 'if(k.ctrl&&k.shift&&!k.alt&&(k.vk==VK_HOME||k.vk==VK_END))' in fx
assert 'if (editF7_ && handleF7(k)) return;' in outer
assert 'if (k.ctrl && !k.shift && !k.alt && k.vk==VK_HOME){navigate(-viewPos_);return;}' in outer
assert 'if (k.ctrl && !k.shift && !k.alt && k.vk==VK_END){navigate(static_cast<int>(visible_.size())-1-viewPos_);return;}' in outer
assert "k.vk=='A'" in fx # select-all still provided through Ctrl+A

def replace_current_view_selection(previous, currently_visible, origin, target):
    if origin==target:return previous.copy()
    result=previous-set(currently_visible)
    lo,hi=sorted((origin,target))
    result.update(currently_visible[lo:hi+1])
    return result
all_params=list(range(40))
assert replace_current_view_selection({2,5},all_params,14,0)==set(range(15))
assert replace_current_view_selection({1,2},all_params,14,39)==set(range(14,40))
assert replace_current_view_selection(set(),all_params,0,0)==set()
# Previous selections outside active search are retained; within search,
# every occurrence behind the start is cleared.
assert replace_current_view_selection({2,9,38},[2,9,14,20],2,3)=={14,20,38}
print('TEST29 range selection model (TEST30 corrected shortcut) PASS; native test pending')
