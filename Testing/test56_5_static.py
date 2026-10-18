"""Source-only TEST56.5 contracts. Never compiles local C++ or runs REAPER."""
from pathlib import Path
p=Path(__file__).resolve().parents[1]
router=(p/'src/InputRouter.cpp').read_text()
track=(p/'src/TrackNavigator.cpp').read_text()
f4=(p/'src/TrackNavigatorFxTcp.cpp').read_text()
auto=(p/'src/TrackNavigatorAutomation.cpp').read_text()
h=(p/'include/lrp/TrackNavigator.h').read_text()
listfile=(p/'src/TrackNavigatorFxTcpList.cpp').read_text()
workflow=(p/'.github/workflows/build-windows.yml').read_text()
# Alt+Home/End must be captured BEFORE REAPER's accelerator translation.
assert 'const bool altEdge' in router
assert 'message.wParam == VK_HOME || message.wParam == VK_END' in router
assert 'consumed = self->route(message, true);' in router
assert 'self->navigator_->accepts(Key{' in router
assert 'Alt+Home/End ALWAYS changes the value' in f4
assert 'if (!k.ctrl && !k.shift && k.alt &&' in f4  # TEST56.6: value endpoints in Grid AND Value
assert 'writeFxTcpValue(k.vk == VK_HOME ? 1.0 : 0.0)' in f4
# Editing must never act on the wrong FX or delete the FX header.
assert 'fxTcpSelectedIdentityValid() const' in f4
assert 'std::memcmp(live, &column->guid, sizeof(GUID)) == 0' in f4
assert 'if (fxTcpRow_ == 0) return;' in f4
assert 'setFxTcpParameterVisible(fx, param, false)' in f4
assert 'case VK_DELETE: return true;' in track
assert 'Undo_EndBlock2(project_' in f4
assert 'TrackFX_CopyToTrack(track_, from, track_, to, true)' in f4
assert 'std::memcmp(&fxTcpColumns_' in f4
assert 'Delta Solo unavailable for this FX' in f4 and 'name != "delta" && name != "delta solo"' in f4
assert 'TrackFX_SetEnabled(track_, fx, !before)' in f4
# FX envelope is selected by instance GUID and REAL parameter index.
assert 'void TrackNavigator::toggleFxTcpAutomation()' in auto
assert 'GetFXEnvelope(track_, fx, index, !before)' in auto
assert 'setShown(env, !before)' in auto
assert 'fxTcpAutomationActive()' in f4
assert 'if (k.ctrl && k.shift && !k.alt && k.vk == \'A\')' in f4
assert 'if (k.ctrl && k.shift && k.alt && !k.altGr && k.vk == \'A\')' in f4
for symbol in ['toggleFxTcpBypass', 'toggleFxTcpDeltaSolo','moveFxTcpFx',
               'removeCurrentFxTcpControl','toggleFxTcpAutomation']:
    assert symbol in h and symbol in f4+auto
# Preserve shared memories & names-only TCP selection and TEST56.4 search.
for marker in ['fxTcpMainFilter_', 'fxTcpGridFilter_', 'fxTcpVisibleColumns_']:
    assert marker in h
assert 'bool TrackNavigator::setFxTcpParameterVisible' in listfile
assert 'test56_5_static.py' in workflow
print('TEST56.5 source contracts PASS; native build, keyboard and REAPER/NVDA NOT RUN')
