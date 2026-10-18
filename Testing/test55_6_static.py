"""TEST55.6 A/B compare contracts, source-only. No local C++ compilation."""
from pathlib import Path
r=Path(__file__).resolve().parents[1]
fx=(r/'src/FxNavigator.cpp').read_text()
adv=(r/'src/FxNavigatorAdvanced.cpp').read_text()
order=(r/'src/FxOrder.cpp').read_text()
mem=(r/'src/FxNavigatorMemories.cpp').read_text()
app=(r/'src/Extension.cpp').read_text()
assert 'if (!k.repeat) f8Press();' in fx
assert 'if (pendingF8At_) resolveF8();' in fx
assert 'navigator_.pollCompare();' in app
assert 'GetDoubleClickTime()' in adv
assert 'updateOriginal(); // Double F8 never briefly applies the other sound.' in adv
assert 'void FxNavigator::initializeCompare()' in adv
assert 'state.original = captureCompare();' in adv
assert 'state.edited = state.original;' in adv
assert 'if (!applyCompare(state.original)) return false;' in adv
assert 'if (!applyCompare(state.edited)) return false;' in adv
assert 'speech_("Original updated")' in adv
assert 'speech_("Original")' in adv and 'speech_("Compare")' in adv
assert 'initializeCompare(); // Capture only; never apply Original when entering an FX.' in fx
assert 'compareStates_.clear()' not in fx
assert 'id!=compareParamIndex && permitted(id)' in order
assert 'id!=compareParamIndex && !included.count(id)' in order
assert 'if (pair.second == compareParamIndex) continue;' in mem
assert 'if (pair.first == compareParamIndex) continue;' in mem
assert 'refreshAfterStructure(parameter_)' in adv
assert 'oldSnapDoNotExist' not in adv
print('TEST55.6 Compare F8 double/solo, non-destructive entry, profile isolation PASS')
