"""Source-only checks for F5 audio pin routing. Never compiles anything."""
# TEST61 relocates the same native feature; verify its full replacement contract
# rather than requiring the old F5 source file and obsolete page numbering.
from pathlib import Path as _LegacyPath
import runpy as _runpy
if 'VERSION 0.0.61' in (_LegacyPath(__file__).resolve().parents[1] / 'CMakeLists.txt').read_text():
    _runpy.run_path(str(_LegacyPath(__file__).with_name('test61_pin_connector_migration_static.py')))
    raise SystemExit(0)

from pathlib import Path
root = Path(__file__).resolve().parents[1]
header = (root / 'include/lrp/TrackNavigator.h').read_text(encoding='utf-8')
main = (root / 'src/TrackNavigator.cpp').read_text(encoding='utf-8')
fx = (root / 'src/TrackNavigatorFxTcp.cpp').read_text(encoding='utf-8')
pin = (root / 'src/TrackNavigatorPinAudio.cpp').read_text(encoding='utf-8')
api = (root / 'include/lrp/ReaperApi.h').read_text(encoding='utf-8')
cm = (root / 'CMakeLists.txt').read_text(encoding='utf-8')
checks = {
    'separate F5 page': 'fxTcp, pinAudio' in header,
    'REAPER pin mapping getters': 'REAPERAPI_WANT_TrackFX_GetPinMappings' in api and 'REAPERAPI_WANT_TrackFX_GetIOSize' in api,
    'REAPER pin mapping writer': 'REAPERAPI_WANT_TrackFX_SetPinMappings' in api,
    'F5 opens from F4': 'enterPinAudio();' in fx and 'VK_F5' in fx,
    'F5 accepted by keyboard router': 'case VK_F4: case VK_F5: case VK_F6:' in main,
    'F5 handler before F1 F2 F3': 'if (page_ == Page::pinAudio) { handlePinAudioKey(k); return; }' in main,
    'FX GUID identity resolution': 'pinAudioResolvedFx() const' in pin and 'TrackFX_GetFXGUID' in pin,
    'banked 128 channel two-mask mapping': 'channelWithinPinBank(channel)' in pin and 'bit < 32' in pin and '(bit - 32)' in pin and 'kSecond64PinBank' in pin,
    'readback verification after write': 'pinAudioSelected(column, channel) == selected' in pin,
    'direct pin-cell editing with Enter': 'case VK_RETURN: case VK_SPACE:' in pin and 'pinAudioSet(pinAudioColumn_, pinAudioChannel_, connect)' in pin,
    'active pin navigators': 'pinAudioJumpSelected' in pin,
    'escape returns to F4': 'case VK_F4: case VK_ESCAPE: leavePinAudio(); return;' in pin,
    'F5 builds only in GitHub Actions': 'src/TrackNavigatorPinAudio.cpp' in cm,
    'F4 persisted cursor preserved': 'rememberFxTcpPosition();' in pin and 'rebuildFxTcp(true);' in pin,
    'no separate F5 profile': 'pinAudio' not in (root / 'src/TrackMemory.cpp').read_text(encoding='utf-8'),
}
for label, ok in checks.items():
    print(('PASS' if ok else 'FAIL') + ': ' + label)
assert all(checks.values()), 'F5 static contract violation'
