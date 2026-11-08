#!/usr/bin/env python3
"""TEST67.1: virtual Used state must remain separate from historical profile views."""
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]
fx=(ROOT/'src/FxNavigator.cpp').read_text(encoding='utf-8')
used=(ROOT/'src/FxNavigatorUsed.cpp').read_text(encoding='utf-8')
order=(ROOT/'src/FxNavigatorOrder.cpp').read_text(encoding='utf-8')
header=(ROOT/'include/lrp/UsedParameters.h').read_text(encoding='utf-8')
audit=(ROOT/'Tools/audit.py').read_text(encoding='utf-8')
cm=(ROOT/'CMakeLists.txt').read_text(encoding='utf-8')
for label,condition in [
 ('Ctrl+Shift+L toggle', "k.ctrl && k.shift && !k.alt && !k.altGr && k.vk=='L'" in fx and 'toggleUsedView();' in fx),
 ('Ctrl+Delete only Used', 'if (usedActive_ && !searchMode_ && k.ctrl && !k.shift' in fx and 'removeUsedParameter();' in fx),
 ('collect only direct writes', 'markUsedParameter(parameter_)' in fx),
 ('per-FX project state', 'LReaParams.UsedParameters.v1' in used and 'usedKey(fxGuid_)' in used and 'SetProjExtState(' in used),
 ('restore original context', 'usedOrigin_.visible=visible_' in used and 'visible_=std::move(usedOrigin_.visible)' in used),
 ('own theme', 'usedState_.keyboard=!usedState_.keyboard' in order),
 ('existing 14 contexts protected', 'if (usedActive_) return;' in order and 'std::array<ViewCursor, 14>' in (ROOT/'include/lrp/FxNavigator.h').read_text()),
 ('nondestructive removal', 'used::erase(usedState_,id)' in used and 'removed from used' in used.lower()),
 ('first-touch unique logic', 'state.ids.push_back(id)' in header and 'std::find(state.ids.begin(), state.ids.end(), id)' in header),
 ('portable test built by CI', 'Testing/UsedParametersTests.cpp' in cm and 'add_test(NAME used_parameters' in cm),
 ('no global persistence', 'SetExtState(' not in used and 'SetProjExtState' in audit),
 ('leave before FX Memories', 'if (usedActive_) leaveUsedView(false);\n            openFxMemories(false);' in fx),
]:
 if not condition: raise AssertionError(label)
print('TEST67.1 Used virtual view: PASS')
