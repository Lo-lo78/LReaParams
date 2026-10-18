"""TEST56.10.1: F5 direct pin mapping only; no source compilation."""
from pathlib import Path
root = Path(__file__).resolve().parents[1]
src = (root / "src/TrackNavigatorPinAudio.cpp").read_text(encoding="utf-8")
header = (root / "include/lrp/TrackNavigator.h").read_text(encoding="utf-8")
nav = (root / "src/TrackNavigator.cpp").read_text(encoding="utf-8")
# No stale Ctrl+S bindings, origin memory, or announcements.
for needle in ("pinAudioConnectFromOrigin", "pinAudioOriginPending_", "pinAudioOriginOutput_", "pinAudioOrigin_", "case 'S':", 'Origin selected'):
    assert needle not in src + header + nav, f"Obsolete F5 origin state: {needle}"
# The already-supported direct cell editing and its safety gates remain.
for needle in ("case VK_RETURN: case VK_SPACE:", "case VK_DELETE:", "pinAudioSet(pinAudioColumn_, pinAudioChannel_, connect)", "TrackFX_SetPinMappings", "pinAudioResolvedFx()", "Undo_BeginBlock2", "pinAudioSelected(column, channel) == selected"):
    assert needle in src, f"Required F5 pin operation missing: {needle}"
print("PASS: TEST56.10.1 removes Ctrl+S two-step routing and preserves direct F5 pin controls")
