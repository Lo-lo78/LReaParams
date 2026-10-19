"""TEST59 F8 ReaRoute: source contract plus reversible encoding checks.
This script does not execute MSVC, CMake or REAPER.
"""
# TEST61 relocates the same native feature; verify its full replacement contract
# rather than requiring the old F5 source file and obsolete page numbering.
from pathlib import Path as _LegacyPath
import runpy as _runpy
if 'VERSION 0.0.61' in (_LegacyPath(__file__).resolve().parents[1] / 'CMakeLists.txt').read_text():
    _runpy.run_path(str(_LegacyPath(__file__).with_name('test61_pin_connector_migration_static.py')))
    raise SystemExit(0)

from pathlib import Path
from version_contract import version_at_least

root = Path(__file__).resolve().parents[1]
def read(name): return (root/name).read_text(encoding='utf-8')
cpp = read('src/TrackNavigatorReaRoute.cpp')
nav = read('src/TrackNavigator.cpp')
hardware = read('src/TrackNavigatorHardwareOutputs.cpp')
header = read('include/lrp/TrackNavigator.h')
workflow = read('.github/workflows/build-windows.yml')
legacy = read('Legacy/Speak Track Params - TrackTake Navigator.lua')
assert version_at_least(root, (0,0,59))
assert 'src/TrackNavigatorReaRoute.cpp' in read('CMakeLists.txt')
assert 'python Testing/test59_f8_static.py' in workflow
for name in ('reaRoute','enterReaRoute','handleReaRouteKey','reaRouteOutputIndexes','rememberReaRoutePosition'):
    assert name in header and name in nav+cpp
assert 'savedPage == "F8"' in nav and 'F8.TrackGUID' in cpp and 'F8.Row' in cpp and 'F8.Column' in cpp
assert 'Page::reaRoute' in nav and 'VK_F8' in nav
for file in ('src/TrackNavigatorFxTcp.cpp','src/TrackNavigatorFxTcpList.cpp',
             'src/TrackNavigatorTrackMidi.cpp','src/TrackNavigatorPinAudio.cpp',
             'src/TrackNavigatorHardwareOutputs.cpp'):
    assert 'enterReaRoute();' in read(file), file
assert 'kBase = 512' in cpp and 'kMaxChannels = 16' in cpp
assert 'kRows = 11' in cpp and 'GetTrackNumSends(track_, kCategory)' in cpp
assert '"I_RECINPUT"' in cpp and '"I_NCHAN"' in cpp
assert 'type == 2 ? 1024 : type == 3 ? 2048 : 0' in cpp
assert 'std::clamp(start, 1, maxStart)' in cpp
for label in ('ReaRoute input','Input enabled','Input type','Input channel or pair','Input start',
              'Input width','Track channels','Input raw value','Input note','Output side', 'ReaRoute note',
              'ReaRoute output', 'ReaRoute output count','Add ReaRoute output','Output hint',
              'Volume','Pan','Mute','Phase invert','Mono','Audio source mode','Audio source',
              'ReaRoute destination','Send type','Pan law'):
    assert '"'+label+'"' in cpp, label
assert 'GetTrackSendInfo_Value(track_, kCategory, i, "I_DSTCHAN")' in cpp
assert 'if (isRearouteDestination(raw)) output.push_back(i)' in cpp
assert 'CreateTrackSend(track_,nullptr)' in cpp
assert 'SetTrackSendInfo_Value(track_,kCategory,idx,"I_DSTCHAN",static_cast<double>(kBase))' in cpp
assert 'RemoveTrackSend(track_,kCategory,idx); // rollback' in cpp
assert 'RemoveTrackSend(track_,kCategory,index)' in cpp
assert 'Undo_BeginBlock2' in cpp and 'Undo_EndBlock2' in cpp
assert 'reaRouteReview(true)' in cpp and 'reaRouteReview(false)' in cpp
assert 'hardwareOutputIndexes()' in hardware
assert 'if ((raw & 1023) < 512) indexes.push_back(i)' in hardware
assert 'hardwareOutputIndexes()[static_cast<size_t>(col)]' in hardware
assert 'hardwareOutputIndexes()[static_cast<size_t>(logical)]' in hardware
assert 'savedPage == "F7" && hardwareOutputCount() > 0' in nav
assert 'rearoute_input_type_index' in legacy and 'rearoute_add_output_block_to_grid' in legacy
assert 'build_rearoute_grid' in legacy
for t in range(1,4):
    for start in range(1,17 if t!=2 else 16):
        raw=512+start-1 + (1024 if t==2 else 2048 if t==3 else 0)
        assert 512 <= (raw&1023)<528
        assert ((raw&1023)-512+1)==start
        assert ((raw&2048)!=0)==(t==3)
        assert ((raw&1024)!=0)==(t==2)
for start in range(1,17):
    for mono in (False,True):
        if start==16 and not mono: continue
        raw=512+start-1+(1024 if mono else 0)
        assert (raw&1023)==512+start-1
        assert bool(raw&1024)==mono
        assert not ((raw&1023)<512)
assert 'SetTrackStateChunk' not in cpp and 'TrackFX_GetPinMappings' not in cpp
print('PASS TEST59 F8 input/outputs 11-row bridge, REAPER encoding, F7 physical isolation, memory, undo (static)')
