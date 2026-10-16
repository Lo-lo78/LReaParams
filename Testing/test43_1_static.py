"""0.0.43.1 ReaEQ order regression checks; source-only, no native build."""
from pathlib import Path
root=Path(__file__).resolve().parents[1]
virtual=(root/'include/lrp/ReaEqVirtual.h').read_text()
order=(root/'src/FxOrder.cpp').read_text()
fxnav=(root/'src/FxNavigatorOrder.cpp').read_text()
test=(root/'Testing/ControlTests.cpp').read_text()
lua=(root/'Legacy/Speak FX Params - TrackTake Navigator.lua').read_text()
assert 'function reaeq_build_default_param_indices()' in lua
assert 'out[#out + 1] = reaeq_make_virtual_index(b, "enabled")' in lua
assert 'out[#out + 1] = reaeq_make_virtual_index(b, "type")' in lua
assert 'inline std::vector<int> mergeLegacyCustomOrder(' in virtual
assert 'order=reaeq::mergeLegacyCustomOrder(order,bands,count_,compareParamIndex)' in order
assert 'nativeOrder=reaeq::pluginOrder(eqBandCount(),count_,compareParamIndex)' in fxnav
assert 'generatedSuffix' in virtual and 'at=merged.insert(at,enabledId)' in virtual
assert 'merged.insert(at+1,typeId)' in virtual
assert 'virtual controls must be adjacent' in test
assert 'mergeLegacyCustomOrder(oldAppended,2,9,compareParamIndex)==expected' in test
assert 'mergeLegacyCustomOrder(deliberate,2,9,compareParamIndex)==deliberate' in test
# Model expected for 2 bands + one global + two wrapper params.
expected=[-100000,-100001,0,1,2,-100002,-100003,3,4,5,-99998,-99999,6,7,8]
assert len(expected)==15 and expected.index(-100000)<expected.index(1)
assert expected.index(-100002)<expected.index(4)
assert expected.index(-99999)<expected.index(6)
print('0.0.43.1 ReaEQ legacy Custom Order insertion contracts PASS; C++/REAPER NOT RUN')
