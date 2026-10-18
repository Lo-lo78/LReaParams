"""TEST55.3 source-only checks; Windows C++ build is performed by GitHub Actions."""
from pathlib import Path
r=Path(__file__).resolve().parents[1]
nav=(r/'src/TrackNavigator.cpp').read_text()
midi=(r/'src/TrackNavigatorMidi.cpp').read_text()
manager=(r/'src/TrackNavigatorMemories.cpp').read_text()
mem=(r/'src/TrackMemory.cpp').read_text()
profile=(r/'src/Profile.cpp').read_text()
unit=(r/'Testing/ProfileTests.cpp').read_text()
assert 'bool TrackNavigator::midiFixedIdentity' in midi
assert 'Track|' in midi and 'Sends|' in midi
assert 'detailPeerOccurrence(entry->category, entry->index)' in midi
assert 'void TrackNavigator::applyFixedMidi' in midi
assert 'findSavedTrack(target.source)' in midi and 'findSavedTrack(target.destination)' in midi
assert 'GetSetTrackSendInfo(source, 0, i, "P_DESTTRACK"' in midi
assert 'SetTrackSendInfo_Value(source, 0, sendIndex, parm, next)' in midi
assert 'SetMediaTrackInfo_Value(source, parm, next)' in midi
assert 'midiPickup_[identity]' in midi
assert 'memory_.fixedCcLinks()' in midi and 'memory_.setFixedCcLink(learnIdentity_, link)' in midi
assert 'memory_.ccLinks(group)' not in midi
assert 'const std::string link = memory_.fixedCcLink(identity);' in nav
assert 'memory_.setFixedCcLink(item.key.substr(2), "")' in manager
assert 'Legacy inactive,' in manager
assert 'LReaParams.FixedCCByTarget' in mem and 'LReaParams.FixedCCByTarget' in profile
assert 'two tracks or duplicate sends' in unit
assert 'Project-scoped Fixed CC identities did not persist' in unit
assert 'Deleting one Fixed CC erased a different track' in unit
assert 'TrackMemory::fixedCcLinks() const' in mem
assert 'return !fixedCcLinks().empty()' in mem
print('TEST55.3 GUID-specific Fixed CC and Floating cursor separation: static PASS')
