"""0.0.44.1: source-only regression: FX position and sparse detector values.
Never runs native code or a compiler.
"""
from pathlib import Path
from version_contract import version_at_least
r=Path(__file__).resolve().parents[1]
assert version_at_least(r,(0,0,44,1))
fx=(r/'src/FxNavigator.cpp').read_text()
dy=(r/'src/FxNavigatorDynamics.cpp').read_text()
h=(r/'include/lrp/DynamicsSpecial.h').read_text()
assert 'saved.parameterName==raw' in fx
assert 'const auto alias=dynamicsAlias(index)' in fx
assert 'saved.parameterName==alias' in fx
assert 'rememberPosition();' in fx
for marker in ('1024','1025','1026','1027','999','1000'):
    assert marker in h
assert 'TrackFX_SetParam(track_,fx_,param,wanted)' in dy
assert 'TrackFX_SetParamNormalized(track_,fx_,param,fraction)' in dy
assert 'TakeFX_SetParamNormalized(take_,fx_,param,fraction)' in dy
assert 'wanted>=minimum && wanted<=maximum' in dy
assert 'after.index==desired' in dy
assert 'OutputDebugStringA(diagnostic)' in dy
assert 'Detector input unchanged' in dy
print('0.0.44.1 FX session-memory aliases and detector source contracts PASS')
