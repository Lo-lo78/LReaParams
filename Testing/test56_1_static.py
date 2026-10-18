"""TEST56.1 F4 TCP-only grid source contracts; no C++ execution or build."""
from pathlib import Path
root = Path(__file__).resolve().parents[1]
api = (root / 'include/lrp/ReaperApi.h').read_text(encoding='utf-8')
header = (root / 'include/lrp/TrackNavigator.h').read_text(encoding='utf-8')
nav = (root / 'src/TrackNavigator.cpp').read_text(encoding='utf-8')
fx = (root / 'src/TrackNavigatorFxTcp.cpp').read_text(encoding='utf-8')
cmake = (root / 'CMakeLists.txt').read_text(encoding='utf-8')
workflow = (root / '.github/workflows/build-windows.yml').read_text(encoding='utf-8')
assert '#define REAPERAPI_WANT_CountTCPFXParms' in api
assert '#define REAPERAPI_WANT_GetTCPFXParm' in api
assert 'enum class Page { tracks, sends, receives, fxTcp }' in header
assert 'src/TrackNavigatorFxTcp.cpp' in cmake
assert 'CountTCPFXParms(project_, track_)' in fx
assert 'GetTCPFXParm(project_, track_, i, &fx, &param)' in fx
assert 'column.fxIndex = fx' in fx and 'fxTcpColumns_.push_back' in fx
assert 'TrackFX_GetParamName' in fx and 'TrackFX_GetFormattedParamValue' in fx
assert 'if (next == fxTcpRow_) return;' in fx and 'if (next == fxTcpColumn_) return;' in fx
assert 'fxTcpRow_ = std::clamp(fxTcpRow_, fxTcpHeight() > 1 ? 1 : 0, fxTcpHeight() - 1)' in fx
assert 'memory_.setPosition("F4.FxGUID"' in fx
assert 'syncCursorToReaper();' in fx
assert 'selectPage(Page::fxTcp)' in nav
assert 'page_ == Page::fxTcp' in nav
assert 'if (page_ == Page::fxTcp) return nullptr;' in nav
assert 'entries_.clear(); // F4 owns separate FX TCP value targets' in fx
assert 'if (page_ == Page::fxTcp) return fxTcpReview(false);' in nav
assert 'if (page_ == Page::fxTcp) { handleFxTcpKey(k); return; }' in nav
assert 'if (k.ctrl && k.shift && !k.alt && k.vk == \'M\') return true;' in nav
assert 'case VK_F1: case VK_F2: case VK_F3: case VK_F4:' in nav
assert 'project(LReaParams VERSION 0.0.56' in cmake
assert 'python Testing/test56_1_static.py' in workflow
# TEST56.3 advances F4 to editing; navigation must still be built from TCP API.
assert 'writeFxTcpValue' in fx
assert 'SetTrackStateChunk' not in fx
print('TEST56.1 FX TCP navigation static contracts PASS; runtime not tested')
