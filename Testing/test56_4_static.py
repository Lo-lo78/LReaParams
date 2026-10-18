"""TEST56.4 source-only contracts; native C++ and NVDA require GitHub Actions/REAPER."""
from pathlib import Path
root=Path(__file__).resolve().parents[1]
h=(root/'include/lrp/TrackNavigator.h').read_text(encoding='utf-8')
core=(root/'src/TrackNavigatorFxTcp.cpp').read_text(encoding='utf-8')
grid=(root/'src/TrackNavigatorFxTcpList.cpp').read_text(encoding='utf-8')
track=(root/'src/TrackNavigator.cpp').read_text(encoding='utf-8')
workflow=(root/'.github/workflows/build-windows.yml').read_text(encoding='utf-8')
# Modify values without redundant names, while normal grid review remains detailed.
assert 'speech_(fxTcpValueSpeech());' in core
assert 'std::string TrackNavigator::fxTcpValueSpeech() const' in core
assert 'speech_(fxTcpReview(false)); // FX Params: changes' not in core
# Full Ctrl+F with native EDIT, scoped to F4 vs selection, honors quoted mode.
for t in ('fxTcpMainFilter_', 'fxTcpGridFilter_', 'toggleFxTcpFilter()',
          'applyFxTcpFilter()', 'clearFxTcpFilter()', 'filterEditing_'):
    assert t in h or t in core
assert 'fxTcpMatchesSearch' in core and 'lastPrefix' in core
assert 'k.vk == \'F\'' in grid and 'k.vk == \'F\'' in core
assert 'if (page_ == Page::fxTcp && filterEditing_)' in h
assert 'Filter FX parameter grid' in h
assert 'Search cleared. ' in core
# Main F4 Alt+Home / End, without changing its FX column.
assert 'k.vk == VK_HOME || k.vk == VK_END' in core
assert 'if (height > 1) moveFxTcpRow(' in core
# Alt+Enter visible grid: columns per FX, rows start at the FX header,
# vertical speech must never prepend FX name.
for token in ('fxTcpVisibleColumns_', 'moveFxTcpVisibleColumn',
              'moveFxTcpVisibleRow', 'syncFxTcpVisibleSelection',
              'if (!details) return entry.parameterName;',
              'case VK_LEFT: moveFxTcpVisibleColumn(-1)',
              'case VK_RIGHT: moveFxTcpVisibleColumn(1)'):
    assert token in grid or token in h, token
assert 'if (fxTcpListVisibleOnly_ && fxTcpListRow_ == 0) return;' in grid
assert 'rebuildFxTcpVisibleColumns(fxTcpColumn_, param->index)' in grid
assert 'Visible TCP parameters - Remove' in track
assert 'fxTcpParameterVisible(fxIndex, paramIndex) == visible' in grid
assert 'TrackFX_GetFXGUID(track_, e.fxIndex)' in grid
# No regressions to Step/Undo or single .tp structure.
assert 'memory_.step(fxTcpStepKey())' in core
assert 'Undo_BeginBlock2(project_)' in core and 'Undo_EndBlock2(project_' in core
assert 'test56_4_static.py' in workflow
print('TEST56.4 source contracts PASS; native compilation and REAPER/NVDA NOT RUN')
