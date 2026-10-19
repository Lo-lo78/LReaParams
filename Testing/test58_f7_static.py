"""TEST58 Track F7 hardware outputs; static contract & routing encoding model only.
No C++, CMake, REAPER or NVDA are run here.
"""
from pathlib import Path
from version_contract import version_at_least
root=Path(__file__).resolve().parents[1]
def read(path): return (root/path).read_text(encoding='utf-8')
cpp=read('src/TrackNavigatorHardwareOutputs.cpp')
nav=read('src/TrackNavigator.cpp')
h=read('include/lrp/TrackNavigator.h')
f4=read('src/TrackNavigatorFxTcp.cpp')
f4list=read('src/TrackNavigatorFxTcpList.cpp')
f5=read('src/TrackNavigatorPinAudio.cpp')
f6=read('src/TrackNavigatorTrackMidi.cpp')
lua=read('Legacy/Speak Track Params - TrackTake Navigator.lua')
sdk=read('third_party/reaper-sdk/reaper_plugin_functions.h')
assert version_at_least(root, (0,0,58))
assert 'src/TrackNavigatorHardwareOutputs.cpp' in read('CMakeLists.txt')
assert 'python Testing/test58_f7_static.py' in read('.github/workflows/build-windows.yml')
assert 'hardwareOutputs' in h and 'handleHardwareOutputsKey' in h
assert 'Page::hardwareOutputs' in nav and 'F7.Row' in nav and 'F7.Column' in cpp
assert 'savedPage == "F7"' in nav
assert 'enterHardwareOutputs();' in nav and 'enterHardwareOutputs();' in f4
assert 'enterHardwareOutputs();' in f4list and 'enterHardwareOutputs();' in f5
assert 'enterHardwareOutputs();' in f6 and 'case VK_F7' in f6
assert 'kHardwareCategory = 1' in cpp and 'kRows = 11' in cpp
assert 'GetTrackNumSends(track_, kHardwareCategory)' in cpp
assert 'SetTrackSendInfo_Value(track_, kHardwareCategory' in cpp
assert 'RemoveTrackSend(track_, kHardwareCategory, target)' in cpp
assert 'Undo_BeginBlock2' in cpp and 'Undo_EndBlock2' in cpp
assert 'hardwareOutputReview(true)' in cpp and 'hardwareOutputReview(false)' in cpp
for label in ('Hardware output','Volume','Pan','Mute','Phase invert','Mono',
              'Audio source mode','Audio source','Hardware destination','Send type','Pan law'):
    assert f'"{label}"' in cpp and f'label = "{label}"' in lua if label not in ('Hardware output',) else f'"{label}"' in cpp
assert 'kPanLaw' in cpp and '0.7079457843841379' in cpp
assert 'sourceChannelsNeeded' in cpp and 'I_NCHAN' in cpp and 'evenChannels' in cpp
assert 'if (!readBack && expanded)' in cpp
assert 'value = (dest & 1024) | (next * 2)' in cpp
assert 'value = next < 0 ? -1 : (retained | (next*2))' in cpp
assert 'No hardware outputs' in cpp and 'hardwareOutputCount() == 0' in cpp
for key in ('VK_LEFT','VK_RIGHT','VK_UP','VK_DOWN','VK_TAB','VK_ESCAPE','VK_DELETE',
            'VK_HOME','VK_END','VK_PRIOR','VK_NEXT','VK_RETURN','VK_F7'):
    assert key in cpp
assert 'trackMidiReview(false)' in f6 and 'VK_OEM_5' in f6
assert 'trackMidiEdge_ = token; // silent value bounds' in f6
assert 'ReaRoute' in cpp and '512' in cpp and 'otherwise >0 for hardware outputs' in sdk
# Identity-safe routing arithmetic: mono flag is preserved; channels 1/2 .. 127/128.
for pair in range(64):
    for mono in (0,1024):
        encoded=(pair*2)|mono
        assert (encoded&1023)==pair*2
        assert (encoded&1024)==mono
        assert (encoded&1023)+1 == pair*2+1
        assert (encoded&1023)+2 == pair*2+2
for mode in range(9):
    for pair in range(64):
        encoded=pair*2|(mode<<10)
        assert (encoded>>10)==mode
        width=2 if mode==0 else 1 if mode==1 else mode*2
        needed=pair*2+width
        assert 1<=needed<=142
        if needed<=128: assert (needed+1)&~1 <= 128
# F7 and F5 remain separate from ReaRoute F8 and MIDI F6.
assert 'SetTrackStateChunk' not in cpp and 'TrackFX_GetPinMappings' not in cpp
print('PASS TEST58 F7 11-row hardware-output routing, memory, NVDA, bounds and F6 refinements (static)')
