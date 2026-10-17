"""TEST54.3: numeric editing speech and contextual empty FX handling.
Only inspect sources; GitHub Actions performs the MSVC compilation.
"""
from pathlib import Path
from version_contract import version_at_least
root = Path(__file__).resolve().parents[1]
assert version_at_least(root, (0, 0, 54, 3))
edit = (root / 'src/TrackNavigatorExtra.cpp').read_text()
fx = (root / 'src/FxNavigator.cpp').read_text()
ext = (root / 'src/Extension.cpp').read_text()
assert 'numericEditing_ = false;' in edit
assert 'suppressPutSpeech_ = true;' in edit and 'put(*e, raw)' in edit
assert 'speech_("Set. " + parameterValueSpeech())' not in edit
assert 'speech_("Set. " + ' not in edit
# REAPER FX context must honor the specified track/take, never silently
# borrow effects from a different selected track or take.
assert 'speech_("No track FX"); return false;' in fx
assert 'speech_("No take FX"); return false;' in fx
assert 'GetCursorContext2(true) == 1' in fx
assert 'GetDlgCtrlID(GetFocus()) != 1076' in fx
assert 'TrackFX_GetRecCount(master)' in fx
assert 'GetSelectedTrack(project_, 0)' in fx
assert 'GetSelectedMediaItem(project_, i)' in fx
# Ctrl+Tab with an empty track FX chain stays in Track Params without
# closing and reopening its owned focus window or saying anything twice.
pos = ext.index('MediaTrack* preferred = wasTrack ? trackNavigator_.cursorTrack() : navigator_.cursorTrack();')
shortcircuit = ext.index('if (TrackFX_GetCount(preferred) <= 0 && !monitorFx)', pos)
exit_nav = ext.index('exitNavigation(false);', pos)
assert pos < shortcircuit < exit_nav
assert 'speak("No track FX"); return;' in ext[pos:exit_nav]
assert 'navigator_.setNextStartTrack(preferred)' in ext[exit_nav:]
assert 'TrackFX_GetRecCount(preferred) > 0' in ext[pos:exit_nav]
assert 'if (target->begin())' in ext[exit_nav:]
# No changes to the persisted track CC profile implementation.
assert (root/'src/TrackMemory.cpp').is_file()
print('TEST54.3 numeric speech and empty track/take FX context contracts PASS')
