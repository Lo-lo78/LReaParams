"""TEST73.2: preserve both FX/Track navigator and keyboard focus on range close."""
from pathlib import Path
import re
root = Path(__file__).resolve().parents[1]
dialog = (root / "src/RangeDialog.cpp").read_text(encoding="utf-8")
header = (root / "include/lrp/RangeDialog.h").read_text(encoding="utf-8")
extension = (root / "src/Extension.cpp").read_text(encoding="utf-8")
fx = (root / "src/FxNavigatorAdvanced.cpp").read_text(encoding="utf-8")
track = (root / "src/TrackNavigatorExtra.cpp").read_text(encoding="utf-8")
assert 'rangeDialogModalActive() noexcept' in header
assert 'thread_local unsigned rangeDialogDepth = 0;' in dialog
assert '++rangeDialogDepth;' in dialog and '--rangeDialogDepth;' in dialog
assert dialog.index('++rangeDialogDepth;') < dialog.index('DialogBoxIndirectParamW(GetModuleHandleW(nullptr), dlg,')
assert dialog.index('DialogBoxIndirectParamW(GetModuleHandleW(nullptr), dlg,') < dialog.index('SetForegroundWindow(owner);')
assert dialog.index('SetForegroundWindow(owner);') < dialog.index('--rangeDialogDepth;')
assert 'SetFocus(priorFocus);' in dialog
assert 'if (rangeDialogModalActive()) return;' in extension
assert extension.index('if (rangeDialogModalActive()) return;') < extension.index('if (titleProxyActive_ && !titleProxy_.active())')
assert 'editParameterRange(GetForegroundWindow(),' in fx
assert 'editParameterRange(GetForegroundWindow(),' in track
assert 'if (ok != IDOK || !state.accepted) return false;' in dialog
assert 'value=state.result;return true;' in dialog
print('TEST73.2 PASS: modal range dialog preserves navigator and restores focus on OK/Cancel')
