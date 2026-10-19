"""LReaParams TEST57 - F6 Track MIDI contracts, source and synthetic boundary model only.

No native compilation and no device/REAPER/NVDA execution.
"""
from pathlib import Path
root = Path(__file__).resolve().parents[1]
def read(file): return (root / file).read_text(encoding="utf-8")
cpp = read("src/TrackNavigatorTrackMidi.cpp")
nav = read("src/TrackNavigator.cpp")
h = read("include/lrp/TrackNavigator.h")
f4 = read("src/TrackNavigatorFxTcp.cpp")
f4grid = read("src/TrackNavigatorFxTcpList.cpp")
f5 = read("src/TrackNavigatorPinAudio.cpp")
api = read("include/lrp/ReaperApi.h")
cmake = read("CMakeLists.txt")
workflow = read(".github/workflows/build-windows.yml")
lua = read("Docs/LuaManifest.csv")
assert "VERSION 0.0.57" in cmake and "src/TrackNavigatorTrackMidi.cpp" in cmake
assert "REAPERAPI_WANT_GetMIDIOutputName" in api
assert "trackMidi" in h and "trackMidiRow_" in h
assert "Page::trackMidi" in nav
assert "trackMidiReview(false)" in nav and "Track MIDI" in nav
assert "page_ != Page::trackMidi" in nav  # explicit exemption from F2/F3 invalidation
assert 'savedPage == "F6"' in nav and 'memory_.position("F6.TrackGUID") == rowGuid()' in nav
assert "enterTrackMidi()" in f4 and "enterTrackMidi()" in f4grid and "enterTrackMidi()" in f5
assert "closeFxTcpParameterGrid(false)" in f4grid
assert "leavePinAudio(false)" in f5
assert "selectPage(Page::fxTcp)" in cpp
assert "selectPage(Page::sends)" in cpp and "selectPage(Page::receives)" in cpp
assert '"No sends or receives"' in cpp
assert '"Select an FX in F4 first"' in cpp
assert '"F6.Row"' in cpp and '"F6.TrackGUID"' in cpp and '"LastPage", "F6"' in cpp
for label in ("MIDI hardware output", "MIDI hardware channel", "MIDI input channel map", "MIDI control channel", "MIDI routing"):
    assert label in cpp
for name in ("I_MIDIHWOUT", "I_MIDI_INPUT_CHANMAP", "I_MIDI_CTL_CHAN"):
    assert name in cpp
assert "GetMIDIOutputName(device, name, sizeof(name))" in cpp
assert "TrackList_AdjustWindows(false)" in cpp and "UpdateArrange()" in cpp
assert "Undo_BeginBlock2" in cpp and "Undo_EndBlock2" in cpp
assert "readMidiInfo(track_, parm) != value" in cpp
assert "std::clamp(current + delta, -1, 31)" in cpp
assert "std::clamp(current + delta, 0, 16)" in cpp
assert "std::clamp(current + delta, 0, 17)" in cpp
assert "coarse ? 4 : 1" in cpp and "coarse ? -4 : -1" in cpp
assert "VK_HOME" in cpp and "VK_END" in cpp and "VK_PRIOR" in cpp and "VK_NEXT" in cpp
assert "trackMidiRow_ == 4" in cpp
assert "openTrackMemories(false)" in cpp and "k.ctrl && k.shift" in cpp
assert "SetTrackStateChunk" not in cpp and "TrackFX_GetPinMappings" not in cpp
assert "TEST57 F6" in workflow
assert "Speak Track Params - TrackTake Navigator.lua" in lua
# Synthetic MIDI encoding and edge cases, following the user's Lua.
for dev in (0,1,15,31):
    for ch in (0,1,8,16):
        encoded=(dev<<5)|ch
        assert encoded>=0
        assert ((encoded>>5)&31)==dev
        assert (encoded&31)==ch
assert (0 << 5 | 0) == 0
assert (31 << 5 | 16) == 1008
for pos in range(18):
    raw=-1 if pos==0 else 16 if pos==17 else pos-1
    text='None' if raw<0 else 'All channels' if raw==16 else str(raw+1)
    assert (raw<0 and text=='None') or (raw==16 and text=='All channels') or (0<=raw<=15 and text==str(raw+1))
for pos in range(17):
    raw=-1 if pos==0 else pos
    assert raw==-1 or 1<=raw<=16
print("TEST57 F6 track MIDI source/API/keyboard/memory/boundary model PASS")
