"""0.0.45 — Lua-compatible FX clipboard and transactional defaults. Source-only.

The Windows clipboard, MSVC compilation, REAPER and NVDA require the user's
GitHub Actions / live host. This is NOT a runtime behavior test.
"""
from pathlib import Path
from version_contract import version_at_least
root=Path(__file__).resolve().parents[1]
assert version_at_least(root,(0,0,45))
fx=(root/'src/FxNavigator.cpp').read_text()
cb=(root/'src/FxNavigatorClipboard.cpp').read_text()
head=(root/'include/lrp/FxNavigator.h').read_text()
cm=(root/'CMakeLists.txt').read_text()
workflow=(root/'.github/workflows/build-windows.yml').read_text()
legacy=(root/'Legacy/Speak FX Params - TrackTake Navigator.lua').read_text()
assert 'FX_PARAM_SNAPSHOT_MAGIC = "FXPARAM_SNAPSHOT_V1"' in legacy
assert 'FXPARAM_SNAPSHOT_V1' in cb and 'FXPARAM_VALUE_V1' in cb
assert 'PluginRaw\\t' in cb and 'ParamCount\\t' in cb and 'P\\t' in cb
assert 'OpenClipboard(nullptr)' in cb and 'CF_UNICODETEXT' in cb
assert 'SetClipboardData(CF_UNICODETEXT' in cb and 'GetClipboardData(CF_UNICODETEXT)' in cb
assert 'decodeSnapshot(' in cb and 'snap.plugin!=' in cb
assert 'snap.names[static_cast<size_t>(i)]!=name' in cb
assert 'snap.values.size())!=now' in cb
assert 'std::vector<double> old(' in cb and 'Undo_BeginBlock2(project_)' in cb
assert 'Undo_EndBlock2(project_' in cb and 'FX snapshot paste incomplete' in cb
assert 'if(parameter_<0||parameter_>=count_)' in cb
assert 'if (!editF7_' in fx and 'copyParameterValue()' in fx and 'pasteFxClipboard()' in fx
assert 'copyFxSnapshot()' in fx and "k.vk=='C'" in fx
assert 'if (editF7_ && handleF7(k)) return;' in fx
assert 'bool FxNavigator::resetAllToDefault(' in fx
assert 'Default parameter identities changed. No changes' in fx
assert 'std::vector<double> previous(static_cast<size_t>(count_))' in fx
assert 'for(int i=std::min(restored,count_-1);i>=0;--i)' in fx
assert 'src/FxNavigatorClipboard.cpp' in cm
for name in ('copyParameterValue','copyFxSnapshot','pasteFxClipboard'):
    assert 'void '+name+'();' in head
assert 'python Testing/test45_static.py' in workflow
# Lua fixture cross-reference: the current snapshot format is reusable in a
# migrated project, not a newly invented PluginRaw schema.
assert 'function fx_snapshot_validate_for_current_fx' in legacy
assert 'function fx_snapshot_apply' in legacy
assert 'function fx_snapshot_system_clipboard_set' in legacy
print('TEST45 FX clipboard/default safety contracts PASS (source only).')
