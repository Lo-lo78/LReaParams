"""Static source contract checks only; no CMake, compiler, or binaries."""
from pathlib import Path
root=Path(__file__).resolve().parents[1]
ext=(root/'src/Extension.cpp').read_text()
fx=(root/'src/FxNavigator.cpp').read_text()
mem=(root/'src/FxNavigatorMemories.cpp').read_text()
order=(root/'src/FxOrder.cpp').read_text()
cmake=(root/'CMakeLists.txt').read_text()
assert '{"LREAPARAMSFXMEMORIES", "LReaParams: FX Memories", L"FX Memories"}' in ext
assert 'navigator_.openFxMemories(true)' in ext and 'launchNavigator(&navigator_)' in ext
assert 'LReaParams: FX Memories (future)' not in ext
assert 'FxNavigatorMemories.cpp' in cmake
assert 'if (memoryManager_) return memoryReview()' in fx
for key in ('"Memory positions"','"Groups"','"Hidden parameters"','"MIDI CC"',
            '"Custom order"','"Copied parameters"','"Default values"'):
    assert key in mem,key
for op in ('fxOrder_.deleteCustomOrder()','fxOrder_.hidden.erase(entry.param)',
           'fxOrder_.groups.erase(entry.slot)','fxOrder_.paramSlots.erase(entry.slot)',
           'fxOrder_.order.erase(fxOrder_.order.begin()+entry.rawPos)'):
    assert op in mem,op
assert 'if(!standalone && !editF7_)' in mem
assert 'memories' not in str(root/'src/FxNavigatorMemories.cpp')
assert 'group_slot_name_v1::slot::' in order
assert 'defaultRegenerate_=true' in mem and 'saveDefaultRows({})' in mem
print('TEST18 static contracts PASS. Runtime tests NOT RUN.')
