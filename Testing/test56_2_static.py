"""TEST56.2: source-only contracts for the FX TCP parameter selection grid.
No native binaries or REAPER project are used here. GitHub Actions builds the C++.
"""
from pathlib import Path
root = Path(__file__).resolve().parents[1]
header = (root / 'include/lrp/TrackNavigator.h').read_text(encoding='utf-8')
nav = (root / 'src/TrackNavigator.cpp').read_text(encoding='utf-8')
fx = (root / 'src/TrackNavigatorFxTcp.cpp').read_text(encoding='utf-8')
grid = (root / 'src/TrackNavigatorFxTcpList.cpp').read_text(encoding='utf-8')
cmake = (root / 'CMakeLists.txt').read_text(encoding='utf-8')
workflow = (root / '.github/workflows/build-windows.yml').read_text(encoding='utf-8')
for token in (
    'fxTcpListOpen_', 'fxTcpListGridHeight_', 'fxTcpListVisibleOnly_',
    'fxTcpListFxGuid_', 'fxTcpParameterGridReview', 'commitFxTcpParameterGrid',
    'setFxTcpParameterVisible', 'rebuildFxTcpParameterGrid',
):
    assert token in header
assert 'src/TrackNavigatorFxTcpList.cpp' in cmake
assert 'if (fxTcpListOpen_) { handleFxTcpParameterGridKey(k); return; }' in fx
assert 'if (fxTcpListOpen_) return fxTcpParameterGridReview(includeContext);' in fx
assert 'if (!k.repeat) { rebuildFxTcp(true); openFxTcpParameterGrid(false); }' in fx
assert 'if (currentFxTcpParameter()) {' in fx
assert 'openFxTcpParameterGrid(true)' not in fx  # TEST56.6 removes the Alt+Enter visible-only mode
assert 'if (fxTcpListOpen_) {' in nav and 'k.vk == VK_RETURN' in nav
assert 'case VK_F1: case VK_F2: case VK_F6:' in nav
assert 'std::clamp(fxTcpListGridHeight_ + (k.vk == VK_F1 ? -1 : 1), 1, 200)' in grid
assert 'const int start = (fxTcpListPosition_ / height) * height;' in grid
assert 'case VK_LEFT: if (next - height >= 0)' in grid
assert 'case VK_RIGHT: if (next + height < size)' in grid
assert 'if (next != fxTcpListPosition_)' in grid  # silent borders
assert 'if (!details) return e.parameterName;' in grid  # normal navigation: names ONLY
assert 'e.visible ? ", visible in TCP" : ", not in TCP"' in grid  # Tab detail
assert 'commitFxTcpParameterGrid(k.ctrl)' in grid
assert 'keepOpen ? !e.visible : true' in grid
assert 'fxTcpListVisibleOnly_ ? false :' in grid
assert 'TrackFX_GetNumParams(track_, fx)' in grid
assert 'TrackFX_GetFXGUID(track_, e.fxIndex)' in grid
assert 'std::memcmp(currentGuid, &e.fxGuid, sizeof(GUID)) != 0' in grid
assert 'CountTCPFXParms(project_, track_)' in grid
assert 'GetTCPFXParm(project_, track_, i, &fx, &param)' in grid
assert 'TrackFX_SetNamedConfigParm' in grid
assert 'GetTrackStateChunk' in grid and 'SetTrackStateChunk' in grid
assert 'matched != 1' in grid and 'fxid < 0' in grid
assert 'Do not reserialize an unknown extended format' in grid
assert 'fxTcpParameterVisible(fxIndex, paramIndex) == visible' in grid
assert 'SetTrackStateChunk(track_, oldChunk.c_str(), false)' in grid
assert 'Undo_BeginBlock2(project_)' in grid and 'Undo_EndBlock2(project_' in grid
assert 'test56_2_static.py' in workflow
assert 'Parameter Library.cpp' not in cmake
print('TEST56.2 names-only TCP grid source contracts PASS; native build/runtime not run')
