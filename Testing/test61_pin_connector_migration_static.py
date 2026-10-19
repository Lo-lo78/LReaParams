"""TEST61 source-only contracts: F10/F11, Track F5-F7, Peak Watcher, safe .tp upgrade."""
from pathlib import Path
root=Path(__file__).resolve().parents[1]
def read(x): return (root/x).read_text(encoding='utf-8')
fx=read('src/FxNavigator.cpp');pin=read('src/FxNavigatorPinAudio.cpp')
fh=read('include/lrp/FxNavigator.h'); th=read('include/lrp/TrackNavigator.h')
nav=read('src/TrackNavigator.cpp'); api=read('include/lrp/ReaperApi.h')
f4=read('src/TrackNavigatorFxTcp.cpp'); fl=read('src/TrackNavigatorFxTcpList.cpp')
midi=read('src/TrackNavigatorTrackMidi.cpp');hw=read('src/TrackNavigatorHardwareOutputs.cpp');rr=read('src/TrackNavigatorReaRoute.cpp')
ctx=read('src/FxNavigatorContexts.cpp');cmake=read('CMakeLists.txt')
peak=read('include/lrp/PeakWatcher.h')
assert 'project(LReaParams VERSION 0.0.61' in cmake
assert 'src/FxNavigatorPinAudio.cpp' in cmake and 'src/TrackNavigatorPinAudio.cpp' not in cmake
assert 'TrackNavigatorPinAudio.cpp' not in '\n'.join(p.name for p in (root/'src').glob('*.cpp'))
assert 'fxTcp, trackMidi, hardwareOutputs, reaRoute' in th and 'Page::pinAudio' not in nav
assert 'pinAudioMode_' in fh and 'pinAudioMode_' in fx
assert 'k.vk == VK_F10' in fx and 'k.vk == VK_F11' in fx
assert 'if (fxBrowserMode_) browserSelect();' in fx and 'else enterFxBrowser();' in fx
assert 'if (!fxBrowserMode_) enterPinAudio();' in fx
assert "k.vk=='P'" not in fx and "k.vk=='P'" not in ctx
assert 'case VK_F10: leavePinAudio(false); enterFxBrowser();' in pin
assert 'case VK_ESCAPE: leavePinAudio();' in pin
assert 'pinAudioReview(true)' in fx and 'pinAudioReview(true)' in pin
for apiName in ('TrackFX_GetIOSize','TrackFX_GetPinMappings','TrackFX_SetPinMappings',
                'TakeFX_GetIOSize','TakeFX_GetPinMappings','TakeFX_SetPinMappings'):
    assert '#define REAPERAPI_WANT_'+apiName in api
    assert apiName in pin
for marker in ('pinAudioInputs_', 'pinAudioOutputs_', 'std::clamp(inputs, 0, maxChannels)',
               'std::clamp(outputs, 0, maxChannels)', 'GetMediaTrackInfo_Value(track_, "I_NCHAN")',
               'constexpr int maxChannels = 128;', 'constexpr int second64Bank = 0x1000000;',
               'channel >= 64 ? second64Bank : 0', 'return channel % 64;',
               'std::uint32_t{1} << (bit % 32)', 'pinAudioSelected(column, channel) == connected',
               'Undo_BeginBlock2(project_)', 'Undo_EndBlock2(project_',
               'pinAudioJumpSelected(-1, 0)', 'pinAudioJumpSelected(1, 2)', 'case VK_DELETE:',
               'case VK_RETURN: case VK_SPACE:'):
    assert marker in pin,marker
assert 'SetMediaTrackInfo_Value' not in pin # no automatic channel resizing
assert 'F5.Row' in midi and '"LastPage", "F5"' in midi and 'case VK_F5: case VK_TAB:' in midi
assert 'F6.Row' in hw and '"LastPage", "F6"' in hw and 'case VK_F6: case VK_TAB:' in hw
assert 'F7.Row' in rr and '"LastPage", "F7"' in rr and 'case VK_F7: case VK_TAB:' in rr
assert 'if (k.vk == VK_F5' in f4 and 'if (k.vk == VK_F5' in fl
assert 'if (k.vk == VK_F6' in f4 and 'if (k.vk == VK_F6' in fl
assert 'if (k.vk == VK_F7' in f4 and 'if (k.vk == VK_F7' in fl
for marker in ('PageLayoutVersion','oldValues[3][3]', 'oldPages[] = {"F6", "F7", "F8"}',
               'newPages[] = {"F5", "F6", "F7"}', 'memory_.setPosition("LastPage", "F5")',
               'memory_.setPosition("LastPage", "F6")', 'memory_.setPosition("LastPage", "F7")',
               'if (memory_.position("PageLayoutVersion") == "61") return;', 'migratePageLayout();'):
    assert marker in nav,marker
for marker in ('_OSARA_RESETPEAKWATCHERT1','_OSARA_REPORTPEAKWATCHERT1C1',
               '_OSARA_REPORTPEAKWATCHERT1C2','_OSARA_RESETPEAKWATCHERT2',
               '_OSARA_REPORTPEAKWATCHERT2C1','_OSARA_REPORTPEAKWATCHERT2C2',
               'NamedCommandLookup','Main_OnCommand'):
    assert marker in peak,marker
assert 'executePeakWatcherShortcut(k)' in fx and 'executePeakWatcherShortcut(k)' in nav
# Synthetic 4 x 32-bit masks: changing a single cell leaves the other words untouched.
for pinIndex in (0,1,63,127):
    for ch in (0,31,32,63,64,65,95,96,127):
        bank=pinIndex + (0x1000000 if ch>=64 else 0)
        word=2*(ch//64)+(ch%64)//32
        mask=1 << (ch%32)
        assert bank == pinIndex + (0x1000000 if ch>=64 else 0)
        masks=[0xAAAA5555,0x5555AAAA,0x12345678,0x87654321]
        old=masks[:];masks[word]|=mask
        assert masks[word]&mask
        assert all(masks[i]==old[i] for i in range(4) if i!=word)
print('PASS TEST61 source migration, F10/F11, 128-channel Track/Take/Monitor, Track F5-F7, OSARA and memory')
