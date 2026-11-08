"""TEST66.2: source-only, independent FX Grid/Step resets; no REAPER execution."""
from pathlib import Path
r=Path(__file__).resolve().parents[1]
nav=(r/'src/FxNavigator.cpp').read_text(encoding='utf-8')
views=(r/'src/FxNavigatorOrder.cpp').read_text(encoding='utf-8')
header=(r/'include/lrp/FxNavigator.h').read_text(encoding='utf-8')
ext=(r/'src/Extension.cpp').read_text(encoding='utf-8')
assert 'void FxNavigator::resetGridAndStep()' not in nav
step=nav.split('void FxNavigator::resetCurrentStep() {',1)[1].split('void FxNavigator::resetCurrentGrid()',1)[0]
assert 'stepScale_ = 0;' in step and 'markParameterStepChanged();' in step
assert 'columns_ =' not in step and 'rememberPosition();' in step
grid=nav.split('void FxNavigator::resetCurrentGrid() {',1)[1].split('void FxNavigator::beginGridNumericEdit()',1)[0]
assert 'columns_ = 10;' in grid and 'stepScale_' not in grid
assert 'rememberPosition();' in grid and 'lastControl_ = LastControl::grid;' in grid
assert 'if (k.ctrl && k.shift) {' in nav and 'resetAllToDefault();' in nav
assert 'else if (k.ctrl) resetCurrentStep();' in nav and 'else resetCurrentToDefault();' in nav
assert 'if (k.vk == VK_BACK && !k.alt && !k.altGr)' in nav
assert 'const bool gridResetKey = k.vk == VK_BACK && !k.ctrl && k.shift &&' in nav
assert 'if (!(k.vk == VK_BACK && k.ctrl && k.shift && !k.alt && !k.altGr))' in nav
assert 'if (k.ctrl && k.shift) {\n            pendingGridResetAt_ = 0;\n            resetAllToDefault();' in nav
assert 'else if (k.ctrl) resetCurrentStep();\n        else resetCurrentToDefault();' in nav
assert 'if (k.ctrl && k.shift && k.alt && !k.altGr)' not in nav
assert 'pendingGridResetAt_ = now ? now : 1;' in nav
assert 'now - pendingGridResetAt_ <= GetDoubleClickTime()' in nav
assert 'if (k.repeat) return;' in nav and 'beginGridNumericEdit();' in nav
assert 'void FxNavigator::pollGridReset()' in nav
assert 'navigator_.pollGridReset();' in ext
assert 'gridNumericEdit_' in header and 'Grid size, 1 to 400' in header
assert 'gridNumericEdit_ ? gridNumericBuffer_' in header
assert 'gridNumericEdit_ ? L" - Grid Size"' in nav
assert 'commitGridNumericEdit()' in nav and 'width < 1 || width > 400' in nav
assert 'std::clamp(columns_, 1, 400)' in views and 'width <= 400' in views
assert 'n <= 400' in views and 'std::clamp(saved.gridHeight, 1, 400)' in nav
assert 'std::clamp(columns_+(k.vk==VK_F1?-1:1),1,400)' in nav
assert 'lrp_context_grids_v1' in views and 'lrp_param_step_scales_v1' in views
assert 'TEST66.2 FX Backspace routing and numeric grid' in (r/'.github/workflows/build-windows.yml').read_text()
assert 'project(LReaParams VERSION 0.0.67' in (r/'CMakeLists.txt').read_text()
assert 'LReaParams 0.0.67 - Native REAPER extension' in ext
print('TEST66.2 independent Grid/Step reset and numeric edit static contracts PASS; Windows runtime NOT tested')
