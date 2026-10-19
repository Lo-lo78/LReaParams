"""TEST60 static wiring and safety checks. No local compilation."""
from pathlib import Path
from version_contract import version_at_least
root=Path(__file__).resolve().parents[1]
read=lambda p:(root/p).read_text(encoding='utf-8')
assert version_at_least(root,(0,0,60))
header=read('include/lrp/TransportMarkers.h')
impl=read('src/TransportMarkers.cpp')
api=read('include/lrp/ReaperApi.h')
cmake=read('CMakeLists.txt')
fx=read('src/FxNavigator.cpp')
track=read('src/TrackNavigator.cpp')
router=read('src/InputRouter.cpp')
assert 'src/TransportMarkers.cpp' in cmake
for symbol in ['EnumProjectMarkers3','CountProjectMarkers','GetCursorPositionEx','TimeMap2_timeToBeats','SetEditCurPos2']:
    assert f'#define REAPERAPI_WANT_{symbol}' in api
    assert symbol in impl
for code in range(41040,41046): assert str(code) in impl
for expected in ['Bar ', ' beat ', 'Last marker','First marker','No markers','not found']:
    assert expected in impl
assert 'std::sort(result.begin()' in impl and '!region' in impl
assert 'm.number == number' in impl
assert 'number - 1' in impl
assert 'if (k.altGr) return false' in impl
for k in ['VK_PRIOR','VK_NEXT',"k.vk == 'I'","k.vk == 'O'", "k.vk == '0'"]:
    assert k in impl
assert 'Project changed' in impl and 'EnumProjects(-1, nullptr, 0) != project' in impl
for src in [fx,track]:
    assert 'isTransportMarkerShortcut(k)' in src
    assert 'executeTransportMarkerShortcut(k, project_, markerEdge_, speech_)' in src
    assert 'if (!k.repeat)' in src
for h in ['include/lrp/FxNavigator.h','include/lrp/TrackNavigator.h']:
    assert 'int markerEdge_ = 0;' in read(h)
assert 'shortcutDown' in router and 'shortcutUp' in router
assert 'self->navigator_->accepts(shortcut)' in router
assert 'self->route(message, true)' in router
assert 'kbd_' not in impl and 'SetProjExtState' not in impl
assert 'Ctrl+Pagina Su/Giù' in read('Docs/TEST60_MARKER_TRANSPORT.md')
workflow=read('.github/workflows/build-windows.yml')
assert 'python Testing/test60_marker_transport_static.py' in workflow
print('PASS TEST60 markers 1..10, prev/next, beat/measure actions, all FX/Track pages, editor protection (static)')
