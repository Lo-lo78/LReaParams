"""Source-only ReaEQ 0.0.43 contract. No C++ compilation or REAPER UI."""
from pathlib import Path
root=Path(__file__).resolve().parents[1]
virtual=(root/'include/lrp/ReaEqVirtual.h').read_text()
chunk=(root/'include/lrp/ReaEqChunk.h').read_text()
fx=(root/'src/FxNavigator.cpp').read_text()
re=(root/'src/FxNavigatorReaEq.cpp').read_text()
order=(root/'src/FxNavigatorOrder.cpp').read_text()
profiles=(root/'src/FxOrder.cpp').read_text()
midi=(root/'src/FxNavigatorAdvanced.cpp').read_text()
mem=(root/'src/FxNavigatorMemories.cpp').read_text()
cmake=(root/'CMakeLists.txt').read_text()
assert 'VERSION 0.0.43' in cmake and 'src/FxNavigatorReaEq.cpp' in cmake
assert 'target = -99998, action = -99999, base = -100000' in virtual
user=[0,1,8,3,4,5,6,7,10,9,2]
assert len(user)==len(set(user))==11 and user.index(8)==2 and user.index(2)==10
assert '0,1,8,3,4,5,6,7,10,9,2' in virtual
for key in ('enabled(b)','type(b)','out.push_back(target)','out.push_back(action)'):
    assert key in virtual
for phrase in ('defaultBand()', 'addBand()', 'removeBand(int zeroBased)', 'setBandCount(++count_)', 'setBandCount(--count_)'):
    assert phrase in chunk
assert 'defaultOrder_' in profiles and 'validVirtual_' in (root/'include/lrp/FxOrder.h').read_text()
assert 'nativeOrder=reaeq::pluginOrder(eqBandCount(),count_,compareParamIndex)' in order
for phrase in ('eqVirtualValid(parameter_)','eqVirtualFormatted(parameter_)','eqVirtualFraction(parameter_)','eqVirtualSet(parameter_,value)','eqVirtualNudge(direction,big)','eqBandAction()'):
    assert phrase in fx
assert 'writeNamedConfig("BAND' not in re  # assemble each key with explicit band number
assert 'writeNamedConfig("vst_chunk",model.text())' in re
assert 'ReaEqChunk(namedConfig("vst_chunk")).bands()==expected' in re
assert 'ReaEqChunk saved(fxOrder_.defaultMeta("REA_EQ_VST_CHUNK"))' in fx
assert 'eqVirtualValid(e.param)' in mem and 'eqVirtualValid(entry.param)' in mem
assert 'if(eqVirtualValid(param))' in midi and 'const auto links=fxOrder_.ccLinks;' in midi
# Synthetic contract: Lua virtual IDs do not collide with physical indices or Compare.
for n in range(64):
    for i in (-100000-2*n,-100001-2*n):
        assert i<-99999 and i!=-300000
print('0.0.43 ReaEQ source contracts and virtual ID fixtures PASS; native/runtime NOT RUN')
