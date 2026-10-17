"""TEST54.4: source contracts for physical REAPER track synchronization.
No compilation or simulation of REAPER APIs is performed.
"""
from pathlib import Path
from version_contract import version_at_least
r = Path(__file__).resolve().parents[1]
assert version_at_least(r, (0, 0, 54, 4))
track = (r/'src/TrackNavigator.cpp').read_text()
fxh = (r/'include/lrp/FxNavigator.h').read_text()
th = (r/'include/lrp/TrackNavigator.h').read_text()
ext = (r/'src/Extension.cpp').read_text()
linked = (r/'src/TrackNavigatorExtra.cpp').read_text()
folders = (r/'src/TrackNavigatorFolders.cpp').read_text()
filtered = (r/'src/TrackNavigatorFilter.cpp').read_text()
assert 'MediaTrack* cursorTrack() const noexcept { return active_ ? track_ : nullptr; }' in fxh
assert 'void setNextStartTrack(MediaTrack* track) noexcept { nextStartTrack_ = track; }' in th
assert 'MediaTrack* explicitTrack = nextStartTrack_;' in track
assert 'nextStartTrack_ = nullptr;' in track
assert 'initialSelection_ = explicitTrack;' in track
assert 'if (explicitTrack) syncCursorToReaper();' in track
assert 'void TrackNavigator::syncCursorToReaper()' in track
assert 'SetOnlyTrackSelected(track_);' in track
assert 'if (pendingRouting_ != RoutingKind::none) return;' in track
assert 'refreshTrackSelection();' in track
assert 'if (next != row_) {' in track and 'syncCursorToReaper();' in track[track.index('void TrackNavigator::moveTrack'):track.index('void TrackNavigator::moveParameter')]
assert 'syncCursorToReaper();' in track[track.index('void TrackNavigator::switchDetailTrack'):track.index('void TrackNavigator::toggle(')]
assert 'syncCursorToReaper();' in track[track.index('void TrackNavigator::moveToFolder'):track.index('void TrackNavigator::moveTrack')]
assert 'syncCursorToReaper();' in linked and 'syncCursorToReaper();' in folders and 'syncCursorToReaper();' in filtered
assert 'MediaTrack* preferred = wasTrack ? trackNavigator_.cursorTrack() : navigator_.cursorTrack();' in ext
assert 'else trackNavigator_.setNextStartTrack(preferred);' in ext
assert 'if (wasTrack) navigator_.setNextStartTrack(preferred);' in ext
assert 'SetOnlyTrackSelected(fxTrack);' in ext
assert 'desired == &navigator_ && !navigator_.isMemoryManager()' in ext
# Do not destroy F1 multiselect when the user explicitly extends a selection.
a = track[track.index('void TrackNavigator::extendTrackSelection('):track.index('void TrackNavigator::moveToFolder')]
assert 'applyRangeSelection(' in a and 'syncCursorToReaper()' not in a
assert 'void TrackNavigator::refreshTrackSelection()' in track
print('TEST54.4 FX/Track/TCP synchronized cursor contracts PASS (source only)')
