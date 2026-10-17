"""0.0.43.3: FX transport shortcut contracts. Source-only; no native build."""
from version_contract import version_at_least
from pathlib import Path
root=Path(__file__).resolve().parents[1]
fx=(root/'src/FxNavigator.cpp').read_text()
api=(root/'include/lrp/ReaperApi.h').read_text()
router=(root/'src/InputRouter.cpp').read_text()
proxy=(root/'src/TitleProxy.cpp').read_text()
f7=(root/'src/FxNavigatorOrder.cpp').read_text()
track=(root/'src/TrackNavigator.cpp').read_text()
cmake=(root/'CMakeLists.txt').read_text()
workflow=(root/'.github/workflows/build-windows.yml').read_text()
lua=(root/'Legacy/Speak FX Params - TrackTake Navigator.lua').read_text()
assert version_at_least(root, (0, 0, 43, 3))
for name in ('GetPlayState','OnPlayButton','OnPauseButton'):
    assert '#define REAPERAPI_WANT_'+name in api
assert 'CMD_PLAY_STOP  = 40044' in lua and 'CMD_PLAY_PAUSE = 40073' in lua
assert 'k.vk == VK_SPACE && !k.shift && !k.alt' in fx
assert fx.count('k.vk == VK_SPACE && !k.shift && !k.alt') == 2  # accepts/handle
assert 'if (!k.repeat) {' in fx[fx.index('void FxNavigator::handle('):fx.index('if (memoryManager_)',fx.index('void FxNavigator::handle('))]
assert 'const int playState = GetPlayState ? GetPlayState() : 0;' in fx
assert 'if (k.ctrl) {' in fx  # keep the two transport gestures distinct
assert '(playState & 2) && OnPlayButton' in fx
assert 'Main_OnCommand(40044, 0)' in fx and 'Main_OnCommand(40073, 0)' in fx
assert '!textEdit_ && !searchMode_ && !numericEdit_' in fx
# Ordinary F7 Shift+Space must continue to select/deselect.
assert 'k.shift&&!k.ctrl&&!k.alt&&k.vk==VK_SPACE' in f7
# The native Win32 EDIT remains the authoritative text/space handler.
assert 'TitleProxy::nativeEditProc' in proxy and 'CallWindowProcW(self->originalNativeEditProc_' in proxy
# Both routes dispatch only accepted shortcuts, and REAPER must not get a second Space.
assert 'if (!navigator_->accepts(key)) return true;' in router
assert 'queue_[tail_] = key;' in router
# TEST54.1: Track Params now shares FX transport semantics.
assert 'if ((state & 2) && OnPlayButton)' in track and 'Main_OnCommand(40073, 0)' in track
assert 'k.vk == VK_SPACE && !k.shift && !k.alt' in track
assert 'Testing/test43_3_static.py' in workflow
print('0.0.43.3 FX transport/static focus contracts PASS; C++/REAPER/NVDA NOT RUN')
