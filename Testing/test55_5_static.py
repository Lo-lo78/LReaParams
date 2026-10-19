"""TEST55.5 unified memory shortcut contracts; source-only, no native compilation."""
from pathlib import Path
r = Path(__file__).resolve().parents[1]
fx = (r/'src/FxNavigator.cpp').read_text()
fxmem = (r/'src/FxNavigatorMemories.cpp').read_text()
track = (r/'src/TrackNavigator.cpp').read_text()
tmem = (r/'src/TrackNavigatorMemories.cpp').read_text()
actions = (r/'src/Extension.cpp').read_text()
# Interception + action must both exist, and AltGr must not act as Ctrl+Alt.
assert fx.count("k.vk == 'M'") >= 3
assert 'k.ctrl && k.shift && !k.alt && !k.altGr' in fx
assert 'openFxMemories(false)' in fx
assert "k.vk=='M'" in fxmem and 'memoryExit()' in fxmem
assert "k.vk == 'M'" in track and 'openTrackMemories(false)' in track
assert "k.vk == 'M'" in tmem and 'memoryExit()' in tmem
# F8 no longer drives FX memory transitions; Alt+F8 no longer drives Track memory transitions.
assert 'k.vk == VK_F8' in fx and 'f8Press()' in fx
assert 'VK_F8' not in fxmem
# TEST61 moves Track ReaRoute to F7; Ctrl+Shift+M remains the memory shortcut.
assert 'k.vk == VK_F7' in track and 'enterReaRoute()' in track
assert 'openTrackMemories(true)' not in track
assert 'VK_F8' not in tmem
assert 'openFxMemories(true)' in actions and 'openTrackMemories(true)' in actions
assert 'LReaParams: FX Memories' in actions and 'LReaParams: Track Memories' in actions
assert 'Parameter Library' not in (r/'CMakeLists.txt').read_text()
print('TEST55.5 unified Ctrl+Shift+M shortcuts PASS (source only)')
