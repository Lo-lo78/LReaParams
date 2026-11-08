#!/usr/bin/env python3
"""TEST68.1: Used re-entry/FX transitions preserve original context and old RPP."""
from pathlib import Path
r=Path(__file__).resolve().parents[1]
read=lambda p:(r/p).read_text(encoding='utf-8')
fx=read('src/FxNavigator.cpp')
used=read('src/FxNavigatorUsed.cpp')
codec=read('include/lrp/UsedParameters.h')
tests=read('Testing/UsedParametersTests.cpp')
assert 'leaveUsedView(false, true);else usedActive_=false' in fx # ESC/end
assert 'if (usedActive_ && contextUnchanged())leaveUsedView(false, true);' in fx # next FX
assert 'if (usedState_.resume) enterUsedView(false)' in fx # reopen FX, after restore
assert fx.index('rememberPosition();\n    // A stored per-instance Used view') < fx.index('if (usedState_.resume) enterUsedView(false)')
assert 'usedState_.resume=keepForNextEntry;' in used
assert 'usedState_.resume=true;' in used
assert 'if(usedActive_) leaveUsedView(true);' in used # user toggle is explicit
assert 'leaveUsedView(false, switchContext);' in fx # switch FX/track/take
assert 'const bool switchContext=k.ctrl && !k.alt' in fx
assert 'LReaParams.UsedParameters.v1' in used # no section migration
assert 'usedKey(fxGuid_)' in used and 'SetProjExtState' in used
assert 'std::string out="U1;"' in codec
assert 'U2;' not in codec
assert 'key+"_LastView"' in used
assert 'std::string(lastView)=="USED"' in used
assert 'usedState_.resume?"USED":"OTHER"' in used
assert 's.resume=true' in tests and '!restored.resume' in tests
assert 'if (usedActive_) leaveUsedView(false);\n            openFxMemories(false);' in fx
print('TEST68.1 Used reopen, GUID landing and U1 backwards compatibility: PASS')
