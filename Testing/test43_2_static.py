"""ReaEQ 0.0.43.2 false-negative band-property report; source-only checks."""
from pathlib import Path
root=Path(__file__).resolve().parents[1]
virtual=(root/'include/lrp/ReaEqVirtual.h').read_text()
update=(root/'src/FxNavigatorReaEq.cpp').read_text()
test=(root/'Testing/ControlTests.cpp').read_text()
cmake=(root/'CMakeLists.txt').read_text()
workflow=(root/'.github/workflows/build-windows.yml').read_text()
assert 'VERSION 0.0.43.3' in cmake
assert 'bandWriteAcceptedOrVerified(' in virtual
assert 'std::from_chars(first,last,actual)' in virtual
assert 'const bool accepted=writeNamedConfig(key,std::to_string(raw));' in update
assert 'const std::string observed=namedConfig(key);' in update
assert 'bandWriteAcceptedOrVerified(accepted,observed,raw)' in update
assert 'verified.enabled(band)==raw' in update and 'verified.rawType(band)==raw' in update
assert 'else speech_("ReaEQ band update failed")' in update
assert update.index('const bool accepted=writeNamedConfig')<update.index('const std::string observed=namedConfig')<update.index('if(ok){pickup_.erase(id);rememberPosition();}')
assert 'bandWriteAcceptedOrVerified(false,"1",1)' in test
assert '!reaeq::bandWriteAcceptedOrVerified(true,"0",1)' in test
assert '!reaeq::bandWriteAcceptedOrVerified(false,"0",1)' in test
assert 'Testing/test43_2_static.py' in workflow
print('0.0.43.2 ReaEQ band readback/false-negative source checks PASS; native/REAPER NOT RUN')
