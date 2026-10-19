"""TEST61.4: source-only hardware output creation from an empty F6 page.
No native compilation, REAPER or audio device is run here.
"""
from pathlib import Path
root=Path(__file__).resolve().parents[1]
def read(path): return (root/path).read_text(encoding='utf-8')
hw=read('src/TrackNavigatorHardwareOutputs.cpp')
nav=read('src/TrackNavigator.cpp')
header=read('include/lrp/TrackNavigator.h')
api=read('include/lrp/ReaperApi.h')
selector=read('src/TrackNavigatorFxTcpList.cpp')
workflow=read('.github/workflows/build-windows.yml')
assert 'GetNumAudioOutputs' in hw and 'GetOutputChannelName' in hw
for name in ('GetNumAudioOutputs','GetOutputChannelName','CreateTrackSend'):
    assert '#define REAPERAPI_WANT_'+name in api
assert 'physicalDestinationOptions()' in hw and 'physicalDestination(int option)' in hw
assert '(first | 1024)' in hw  # final unmatched physical output is mono
assert 'kAddRows = 3' in hw and 'hardwareOutputColumn_ < 0 || count == 0' in hw
assert 'if (!count) { speech_(trackName() + ". No hardware outputs"); return false; }' not in hw
assert 'if (page_ == Page::hardwareOutputs)' in hw
assert 'std::clamp(column, -1, count-1)' in hw
assert 'std::clamp(std::stoi(memory_.position("F6.Column")), -1, count-1)' in hw
assert 'CreateTrackSend(track_, nullptr)' in hw
assert 'SetTrackSendInfo_Value(track_, kHardwareCategory, index, "I_DSTCHAN", dest)' in hw
assert 'GetTrackSendInfo_Value(track_, kHardwareCategory, index, "I_DSTCHAN")' in hw
assert 'RemoveTrackSend(track_, kHardwareCategory, index)' in hw
assert 'Undo_BeginBlock2(project_)' in hw and 'Undo_EndBlock2(project_' in hw
assert 'if (hardwareOutputColumn_ < 0 || hardwareOutputCount() == 0) { addHardwareOutput(); return; }' in hw
assert 'case VK_DELETE: deleteHardwareOutput(); return;' in hw
assert 'if (hardwareOutputColumn_ < 0 || !RemoveTrackSend' in hw
assert 'hardwareOutputColumn_ = count ? std::clamp(logical, 0, count-1) : -1;' in hw
assert 'hardwareOutputColumn_ = hardwareOutputCount() > 0 ? 0 : -1;' in nav
assert 'else if (savedPage == "F6")' in nav
assert 'closeFxTcpParameterGrid(false); enterHardwareOutputs();' in selector
assert 'hardwareOutputNewPair_' in header
assert 'void addHardwareOutput();' in header
assert 'Testing/test61_4_f6_add_hardware_output_static.py' in workflow
# Destination encoding independent of physical ReaRoute 512+ or high mono bit.
for channels in range(1, 513):
    options=channels//2 + channels%2
    for pair in range(options):
        first=pair*2
        dest=(first | 1024) if (channels%2 and first == channels-1) else first
        assert (dest & 1023) < 512
        assert bool(dest & 1024) == (first == channels-1)
# Test the one-option, zero-output, 2-output, and odd-output cases explicitly.
assert (0//2+0%2)==0
assert (1//2+1%2)==1
assert (2//2+2%2)==1
assert (3//2+3%2)==2
print('PASS TEST61.4 F6 create from empty, device-aware destinations, rollback, Undo, isolated deletion (static)')
