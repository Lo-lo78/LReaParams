"""0.0.44 ReaComp/ReaGate source-only contracts. No native compilation."""
from version_contract import version_at_least
from pathlib import Path
root=Path(__file__).resolve().parents[1]
h=(root/'include/lrp/DynamicsSpecial.h').read_text()
d=(root/'src/FxNavigatorDynamics.cpp').read_text()
fx=(root/'src/FxNavigator.cpp').read_text()
order=(root/'src/FxNavigatorOrder.cpp').read_text()
profiles=(root/'src/FxOrder.cpp').read_text()
mem=(root/'src/FxNavigatorMemories.cpp').read_text()
cmake=(root/'CMakeLists.txt').read_text()
assert version_at_least(root, (0, 0, 44)) and 'src/FxNavigatorDynamics.cpp' in cmake
for piece in ('compRange=-200000','gateRange=-210000','"Main inputs"','"Auxiliary inputs"',
              '"Feedback pre-fader"','"Output feedback deprecated"','"Filter Preview"','"Hysteresis"','"Auto Make Up Gain"','"Invert gate"',
              '"0 ms, peak detector"','"Full range"','"Above "','"Below "'):
    assert piece in h,piece
for piece in ('TakeFX_SetParam(take_,fx_,param,wanted)',
              'TrackFX_SetParam(track_,fx_,param,wanted)',
              'dynamics::detectorRawFromFraction(normalized)',
              'dynamics::filterRange(rangeValue(high,0),rangeValue(low,20000))',
              'dynamics::pluginOrder(kind,names,compareParamIndex)',
              'dynamicsSetDetectorAt(int param,double normalized)'):
    assert piece in d,piece
for piece in ('dynamicsVirtualValid(parameter_)','dynamicsDetectorInput(parameter_)',
              'dynamicsNudgeDetector(direction,big)','dynamicsRealFormatted(parameter_',
              'speech_(currentParameterSpeech());return; // read-only summary'):
    assert piece in fx,piece
assert 'nativeOrder=dynamicsPluginOrder()' in order
assert 'id==-200000 || id==-210000' in profiles
assert 'dynamicsVirtualValid(entry.param)' in mem
assert 'dynamicsVirtualValid(id)' in (root/'src/FxNavigatorAdvanced.cpp').read_text()
assert 'src/TrackNavigator.cpp' in cmake
print('0.0.44 ReaComp/ReaGate source-only contracts PASS. Native tests NOT executed.')
