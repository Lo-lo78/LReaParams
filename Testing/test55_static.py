"""TEST55: static contracts only. GitHub Actions runs the actual C++ build and unit tests."""
from pathlib import Path
from version_contract import version_at_least
r=Path(__file__).resolve().parents[1]
assert version_at_least(r, (0,0,55))
nav=(r/'src/TrackNavigator.cpp').read_text()
manager=(r/'src/TrackNavigatorMemories.cpp').read_text()
mem=(r/'src/TrackMemory.cpp').read_text()
prof=(r/'src/Profile.cpp').read_text()
core=(r/'src/Extension.cpp').read_text()
head=(r/'include/lrp/TrackNavigator.h').read_text()
unit=(r/'Testing/ProfileTests.cpp').read_text()
cmake=(r/'CMakeLists.txt').read_text()
assert 'src/TrackNavigatorMemories.cpp' in cmake
assert 'case trackMemories:' in core and 'trackNavigator_.openTrackMemories(true)' in core
assert 'trackNavigator_.isMemoryManager()' in core
assert 'k.vk == VK_F8' in nav and 'openTrackMemories(false)' in nav
assert 'void TrackNavigator::handleMemory' in manager
assert 'void TrackNavigator::memoryDelete' in manager
assert 'void TrackNavigator::saveTrackSlot' in manager
assert 'void TrackNavigator::recallTrackSlot' in manager
assert 'memory_.setCcLink' in manager and 'memory_.flush()' in manager
assert 'std::clamp(memoryColumn_' in manager and 'memoryRow_' in manager
assert 'memory_.setTrackSlot(slot, guid)' in manager and 'syncCursorToReaper();' in manager
assert 'trackGuidText(' in manager and 'findSavedTrack' in manager
assert 'LReaParams.TrackPositions' in mem and 'LReaParams.TrackPositions' in prof
assert 'volumeRange(const std::string& page)' in mem and 'LReaParams.VolumeRanges' in prof
assert 'rangeEditing_' in nav and 'beginVolumeRangeEdit()' in nav
assert 'memoryManager_ || !contextUnchanged()' in (r/'src/TrackNavigatorMidi.cpp').read_text()
assert 'TrackMemory afterDeletion;' in unit and 'tm.setVolumeRange("Track", -60.0, 12.0)' in unit
assert 'LReaParams: Track Memories' in core
assert 'Parameter Library' not in cmake
print('TEST55 source checks PASS (native build and REAPER/NVDA tests not run)')
