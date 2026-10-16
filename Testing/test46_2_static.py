"""0.0.46.2 source-only contracts for FX Browser Delta/Offline (NO native build)."""
from pathlib import Path
from version_contract import version_at_least
r=Path(__file__).resolve().parents[1]
assert version_at_least(r,(0,0,46,2))
api=(r/'include/lrp/ReaperApi.h').read_text(encoding='utf-8')
fx=(r/'src/FxNavigator.cpp').read_text(encoding='utf-8')
browser=(r/'src/FxNavigatorContexts.cpp').read_text(encoding='utf-8')
h=(r/'include/lrp/FxNavigator.h').read_text(encoding='utf-8')
lua=(r/'Legacy/Speak FX Params - TrackTake Navigator.lua').read_text(encoding='utf-8')
assert 'function toggle_current_fx_offline()' in lua
assert 'KEY_CTRL_ALT_B' in lua
for api_name in ('TrackFX_GetOffline','TakeFX_GetOffline','TrackFX_SetOffline','TakeFX_SetOffline'):
    assert '#define REAPERAPI_WANT_'+api_name in api
assert 'void toggleOffline();' in h
assert 'void FxNavigator::toggleOffline()' in browser
assert "if (k.ctrl && k.alt && !k.shift && !k.altGr && k.vk=='B')" in browser
assert "if (k.ctrl && k.alt && !k.shift && !k.altGr && k.vk=='B')" in fx
assert 'const int selected = fxBrowserMode_ ? browserVisibleIndex() : browserIndex_;' in browser
assert 'guidEquals(actual, entry.guid)' in browser
assert 'nowOffline == wasOffline' in browser
assert 'if (guidEquals(&entry.guid, fxGuid_))' in browser
assert 'browserCursor_ = newCursor;' in browser
assert 'if (fxBrowserMode_) return true;' in fx  # offline browser remains valid
assert 'int offlineCursor = -1;' in fx and 'fxBrowserMode_ = true;' in fx
assert 'if (fxBrowserMode_) return true;' in fx[fx.index('bool FxNavigator::uiStillOpen()'):]
assert "if (k.vk=='D') {toggleDeltaSolo();return;}" in browser
assert "if (k.vk=='D') {clearProjectDeltaSolo();return;}" in browser
# The target is now resolved through a chain-scoped browser cursor to prevent
# Master/Monitor effects from being modified across chains.
assert 'const int targetIndex = fxBrowserMode_ ? browserVisibleIndex() : browserIndex_;' in fx
assert 'const int target = fxBrowserMode_ ? entries_[static_cast<size_t>(targetIndex)].index : fx_;' in fx
assert '(fxBrowserMode_ && !browserEntryInScope(targetIndex))' in fx
assert 'deltaParameter(track_, take_, entry.index, delta)' in browser
assert 'GetParamNormalized(take_, entry.index, delta)' in browser
assert "if (k.vk=='D') {\n            const int selected = browserVisibleIndex();" not in browser
assert 'Parameter Library' not in (r/'src/Extension.cpp').read_text(encoding='utf-8')
print('TEST46.2 browser Delta/Offline source contracts PASS')
