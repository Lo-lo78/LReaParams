"""TEST30 — corrected F7 shortcut separation (static only, no build)."""
from pathlib import Path
r=Path(__file__).resolve().parents[1]
f7=(r/'src/FxNavigatorOrder.cpp').read_text(encoding='utf-8')
nav=(r/'src/FxNavigator.cpp').read_text(encoding='utf-8')
assert 'VERSION 0.0.31' in (r/'CMakeLists.txt').read_text()
assert 'if(k.ctrl&&k.shift&&!k.alt&&(k.vk==VK_HOME||k.vk==VK_END))' in f7
assert 'selectF7ToGlobalEdge(k.vk==VK_END);return true;' in f7
assert 'if(k.ctrl&&!k.alt&&(k.vk==VK_HOME||k.vk==VK_END))' not in f7
assert 'if (editF7_ && handleF7(k)) return;' in nav
assert 'if (k.ctrl && !k.shift && !k.alt && k.vk==VK_HOME){navigate(-viewPos_);return;}' in nav
assert 'if (k.ctrl && !k.shift && !k.alt && k.vk==VK_END){navigate(static_cast<int>(visible_.size())-1-viewPos_);return;}' in nav
assert 'if (k.ctrl && k.shift && !k.alt) return k.vk==VK_HOME||k.vk==VK_END||k.vk==VK_DELETE;' in nav
# The range implementation still uses the original current position to
# select only the interval up to the chosen edge, not the whole grid.
assert 'const int origin=viewPos_;' in f7
assert 'const int first=std::min(origin,target);' in f7
assert 'const int last=std::max(origin,target);' in f7
assert 'for(int pos=first;pos<=last;++pos)' in f7
assert 'if(target==viewPos_)return;' in f7
print('TEST30 shortcut routing PASS (static checks only; native REAPER test pending)')
