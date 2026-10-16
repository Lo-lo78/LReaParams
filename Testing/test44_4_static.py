"""0.0.44.4 Lua LastParam persistence (source-only, no local C++ build)."""
from pathlib import Path
from version_contract import version_at_least
root=Path(__file__).resolve().parents[1]
assert version_at_least(root,(0,0,44,4))
lua=(root/'Legacy/Speak FX Params - TrackTake Navigator.lua').read_text(errors='replace')
h=(root/'include/lrp/FxNavigator.h').read_text()
f=(root/'src/FxNavigator.cpp').read_text()
o=(root/'src/FxOrder.cpp').read_text()
a=(root/'src/FxNavigatorAdvanced.cpp').read_text()
t=(root/'Testing/ProfileTests.cpp').read_text()
assert 'plugin_txt_make_kv("LastParam"' in lua
assert 'save_current_param_position()' in lua
assert 'restore_last_param_position()' in lua
assert 'lastParameterRecord' in o and 'persistLastParameter' in o
assert 'LastParam=' in o and 'parseLegacy(payload)' in o
assert 'loadedDigest_' in o and 'sha256(original)' in o
assert 'MoveFileExW' in o and 'writeNewVerified' in o
assert 'std::string FxOrder::lastParameterRecord() const' in o
assert 'FxNavigator::restorePersistedParameter()' in f
assert 'FxNavigator::flushPersistentPosition() noexcept' in f
assert 'void FxNavigator::end() noexcept' in f
assert 'persistentPositionWriter_' in h
assert 'persistentPositionWriter_ = false' in a
assert 'restorePersistedParameter();' in f and 'flushPersistentPosition();' in f
assert 'Session memory is deliberately authoritative' in f
router=(root/'src/InputRouter.cpp').read_text()
assert 'VK_0' not in router, 'VK_0 is not a Windows virtual-key constant'
assert "vk < '0'" in router, 'Use defined VK value for digit zero'
assert 'LastParam update changed an unrelated profile byte' in t
assert 'LastParam not restored after restart' in t
assert 'Stale LastParam save overwrote an external change' in t
print('0.0.44.4 persistent FX parameter memory contract PASS. No compilation.')
