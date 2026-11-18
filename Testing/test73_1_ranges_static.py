"""TEST73.1: targeted contracts, source-only. MSVC/REAPER/NVDA still required."""
from pathlib import Path
root=Path(__file__).resolve().parents[1]
fx=(root/'src/FxNavigator.cpp').read_text()
adv=(root/'src/FxNavigatorAdvanced.cpp').read_text()
track=(root/'src/TrackNavigator.cpp').read_text()
extra=(root/'src/TrackNavigatorExtra.cpp').read_text()
store=(root/'src/TrackMemory.cpp').read_text()
profile=(root/'src/Profile.cpp').read_text()
memfx=(root/'src/FxNavigatorMemories.cpp').read_text()
memtr=(root/'src/TrackNavigatorMemories.cpp').read_text()
midi=(root/'src/TrackNavigatorMidi.cpp').read_text()
dialog=(root/'src/RangeDialog.cpp').read_text()
header=(root/'include/lrp/ParameterRanges.h').read_text()
assert "(k.vk == 'R' || k.vk == 'C' || k.vk == 'F')" in fx
assert "(k.vk == 'R' || k.vk == 'C' || k.vk == 'F')" in track
assert 'parameterRangeFor(parameter_).clamp(value)' in fx
assert 'parameterRangeFor(id).clamp(' in fx
assert 'value = clampParameterValue(e,value);' in track
assert 'fixedCc_ ||' in adv and 'fixedCc_ ||' in extra
assert 'floatingCcSessionRange() = editable;' in adv
assert 'floatingCcSessionRange() = range;' in extra
assert 'ParameterRange range{0.0, 127.0}' in header and 'return floatingCcSession().range;' in header
assert 'ccPickupTarget' in midi and 'scaleCcFraction' in midi and 'scaleCcFraction' in adv
assert 'setParameterRange' in store and 'setCcRange' in store
assert 'LReaParams.ParameterRanges' in profile and 'LReaParams.CcRanges' in profile
assert 'Volume Ranges' not in memtr and 'Ctrl+Shift+I' not in track
assert '"Parameter Ranges"' in memfx and '"Parameter Ranges"' in memtr
assert 'Range ' in memfx and 'Range ' in memtr
assert 'WM_INITDIALOG' in dialog and 'IDOK' in dialog and 'IDCANCEL' in dialog
assert 'WS_TABSTOP' in dialog and 'SetFocus(state->minimumEdit)' in dialog
assert 'src/RangeDialog.cpp' in (root/'CMakeLists.txt').read_text()
assert 'parameter_ranges_tests' in (root/'CMakeLists.txt').read_text()
print('TEST73.1 static contracts PASS (Windows and NVDA runtime unverified)')
