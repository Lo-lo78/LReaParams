"""0.0.43.4: Ctrl+Space calls REAPER's native 40073 directly (source-only)."""
from pathlib import Path
root=Path(__file__).resolve().parents[1]
fx=(root/'src/FxNavigator.cpp').read_text()
test=fx[fx.index('void FxNavigator::handle('):]
space=test[test.index('if (k.vk == VK_SPACE && !k.shift && !k.alt'):test.index('if (memoryManager_)')]
ctrl=space[space.index('if (k.ctrl) {'):space.index('} else {',space.index('if (k.ctrl) {'))]
plain=space[space.index('} else {',space.index('if (k.ctrl) {')):]
assert 'Main_OnCommand(40073, 0)' in ctrl
for wrong in ('OnPlayButton()', 'OnPauseButton()', 'Main_OnCommand(40044, 0)'):
    assert wrong not in ctrl, f'Ctrl+Space must not use {wrong}'
assert 'Main_OnCommand(40044, 0)' in plain
assert '(playState & 2) && OnPlayButton' in plain
assert 'if (!k.repeat)' in space
assert '!textEdit_ && !searchMode_ && !numericEdit_' in space
assert 'k.vk == VK_SPACE && !k.shift && !k.alt' in fx[:fx.index('void FxNavigator::handle(')]
assert 'if(k.shift&&!k.ctrl&&!k.alt&&k.vk==VK_SPACE)' in (root/'src/FxNavigatorOrder.cpp').read_text()
assert 'return 0;' in (root/'src/TitleProxy.cpp').read_text()
assert 'Testing/test43_4_static.py' in (root/'.github/workflows/build-windows.yml').read_text()
assert 'VERSION 0.0.43.4' in (root/'CMakeLists.txt').read_text()
print('0.0.43.4 native Play/Pause dispatch PASS; C++/REAPER/NVDA NOT RUN')
