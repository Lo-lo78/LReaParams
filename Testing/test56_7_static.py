"""TEST56.7 F4 headerless grid and uniform FX shortcuts, source only."""
from pathlib import Path
r=Path(__file__).resolve().parents[1]
t=(r/'src/TrackNavigatorFxTcp.cpp').read_text()
n=(r/'src/TrackNavigator.cpp').read_text()
l=(r/'src/TrackNavigatorFxTcpList.cpp').read_text()
f=(r/'src/FxNavigator.cpp').read_text()
b=(r/'src/FxNavigatorContexts.cpp').read_text()
h=(r/'include/lrp/FxNavigator.h').read_text()
assert 'if (fxTcpHeight() > 1 && fxTcpRow_ == 0) fxTcpRow_ = 1;' in t
assert 'std::clamp(fxTcpRow_ + delta, fxTcpHeight() > 1 ? 1 : 0' in t
assert 'if (!count) return; // Empty FX remains accessible through Alt+Enter.' in t
assert 'if (!k.repeat) { rebuildFxTcp(true); openFxTcpParameterGrid(false); }' in t
assert 'if (currentFxTcpParameter()) {' in t
assert 'No TCP parameters. Press Alt+Enter to add' in t
assert 'std::wstring(L" - ") + wideUtf8(currentFxTcpColumn()' in n
assert 'k.vk == VK_PRIOR || k.vk == VK_NEXT' in t
assert 'moveFxTcpFx(k.vk == VK_PRIOR ? -1 : 1)' in t
assert 'k.vk == VK_PRIOR || k.vk == VK_NEXT' in f
assert 'browserMoveFx(k.vk == VK_PRIOR ? -1 : 1)' in f
assert '(!editF7_ && (k.vk == VK_PRIOR || k.vk == VK_NEXT))' in f
assert 'browserMoveFx(k.vk == VK_PRIOR ? -1 : 1)' in b
assert 'browserSwitchTrack(k.vk==VK_UP?-1:1)' in b
assert 'void FxNavigator::browserSwitchTrack(int direction)' in b
assert 'void browserSwitchTrack(int direction)' in h
assert 'fxBrowserMode_ = true;' in b
assert 'TrackFX_GetFXGUID(candidate, fx)' in b
assert 'if (!target) return; // Silent boundary.' in b
assert 'fxTcpRow_ = count > 0 ? std::clamp(oldVisibleRow, 1, count) : 0;' in l
assert 'if (fxBrowserMode_ && nparams <= 0)' in b
assert 'if (k.alt && k.shift && !k.ctrl && (k.vk == VK_UP || k.vk == VK_DOWN))' not in t
assert 'if (k.vk==VK_UP||k.vk==VK_DOWN) {browserMoveFx' not in b
assert 'openFxTcpParameterGrid(true)' not in t
print('TEST56.7 source-only contracts PASS; C++ and REAPER not executed')
