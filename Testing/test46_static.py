"""Source-only contract verification for 0.0.46. No C++, CMake or native build."""
from pathlib import Path
from version_contract import version_at_least
r=Path(__file__).resolve().parents[1]
assert version_at_least(r, (0, 0, 46))
h=(r/'include/lrp/FxNavigator.h').read_text(encoding='utf-8')
source=(r/'src/FxNavigator.cpp').read_text(encoding='utf-8')
contexts=(r/'src/FxNavigatorContexts.cpp').read_text(encoding='utf-8')
api=(r/'include/lrp/ReaperApi.h').read_text(encoding='utf-8')
ext=(r/'src/Extension.cpp').read_text(encoding='utf-8')
cm=(r/'CMakeLists.txt').read_text(encoding='utf-8')
workflow=(r/'.github/workflows/build-windows.yml').read_text(encoding='utf-8')
lua=(r/'Legacy/Speak FX Params - TrackTake Navigator.lua').read_text(encoding='utf-8')
for marker in ['function handle_fx_browser_key(char)', 'function switch_item_context_by_direction(direction)',
               'function switch_take_context_to_current_track_fx()', 'function open_current_context_fx_chain()']:
    assert marker in lua, marker
for marker in ['switchToContext(', 'switchItem(', 'returnToTrackFx(', 'browserKey(', 'enterFxBrowser(',
               'browserSelect(', 'browserMoveFx(', 'browserCycleByInitial(']:
    assert marker in h and marker in contexts, marker
assert 'browserCursor_' in h and 'fxBrowserMode_' in h
assert 'if (fxBrowserMode_) speech_(browserSpeech());' in source
assert 'if (fxBrowserMode_) return browserSpeech();' in source
assert "k.vk==VK_F10" in source and "k.vk=='W'" in source
assert 'k.vk==VK_PRIOR||k.vk==VK_NEXT' in source
assert 'k.vk==VK_LEFT||k.vk==VK_RIGHT' in source
assert 'browserMoveFx(' in contexts and 'TrackFX_CopyToTrack(' in contexts and 'TakeFX_CopyToTake(' in contexts
assert '((src ^ target) & 0x1000000) != 0' in contexts
assert 'Undo_BeginBlock2(project_)' in contexts and 'Undo_EndBlock2(project_' in contexts
assert 'GetMediaItemTake_Item(' in contexts and 'GetActiveTake(' in contexts
assert 'guidEquals(' in contexts and 'newActive' in contexts
assert '*this = std::move(backup);' in contexts
assert 'nativeFxWindowRequest_ = NativeFxWindow::chain;' in contexts
assert 'nativeFxWindowRequest_ = NativeFxWindow::addFx;' in contexts
assert 'const auto request = navigator_.consumeNativeFxWindowRequest();' in ext
assert 'exitNavigation(false);' in ext
for name in ('TrackFX_Show','TakeFX_Show','TrackFX_CopyToTrack','TakeFX_CopyToTake',
             'SetMediaItemSelected','GetMediaItemTake_Item','GetMediaItemInfo_Value'):
    assert '#define REAPERAPI_WANT_'+name in api
assert 'src/FxNavigatorContexts.cpp' in cm
assert 'python Testing/test46_static.py' in workflow
assert 'Parameter Library' not in (r/'src/Extension.cpp').read_text()
print('TEST46 context navigation and browser contracts PASS (source only).')
