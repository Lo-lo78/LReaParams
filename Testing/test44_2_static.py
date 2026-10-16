"""0.0.44.2: source-only contracts for ReaComp/ReaGate SignIn host scale.
No compilation is performed.
"""
from pathlib import Path
from version_contract import version_at_least
root=Path(__file__).resolve().parents[1]
assert version_at_least(root,(0,0,44,2))
header=(root/'include/lrp/DynamicsSpecial.h').read_text()
cpp=(root/'src/FxNavigatorDynamics.cpp').read_text()
controls=(root/'Testing/ControlTests.cpp').read_text()
assert 'detectorHostSteps=1084.0' in header
for code in ('1024','1025','1026','1027','999','1000','0,', '2,'):
    assert code in header
for phrase in ('detectorHostIndex(', 'GetParamNormalized(',
               'detectorHostFraction(wanted)', 'writeNormalized(fraction)',
               'after.index==desired', 'OutputDebugStringA(diagnostic)'):
    assert phrase in cpp
assert 'wanted>=minimum && wanted<=maximum' in cpp
assert 'if(after.index!=desired)' in cpp
assert 'state.index' in cpp
assert 'detectorHostFraction(raw)' in controls
print('0.0.44.2 source detector normalization and readback contracts PASS')
