"""TEST54 contracts: source-only, plus independent pure logical examples.
No native C++ or REAPER compilation/execution is performed.
"""
from pathlib import Path
from version_contract import version_at_least
r=Path(__file__).resolve().parents[1]
assert version_at_least(r,(0,0,54))
nav=(r/'src/TrackNavigator.cpp').read_text()
midi=(r/'src/TrackNavigatorMidi.cpp').read_text()
extra=(r/'src/TrackNavigatorExtra.cpp').read_text()
mem=(r/'src/TrackMemory.cpp').read_text()
h=(r/'include/lrp/TrackNavigator.h').read_text()
ext=(r/'src/Extension.cpp').read_text()
cmake=(r/'CMakeLists.txt').read_text()
assert 'src/TrackNavigatorMidi.cpp' in cmake and 'src/TrackNavigatorExtra.cpp' in cmake
assert 'trackNavigator_.tickMidi()' in ext
assert 'filterEditing_ || numericEditing_' in h and 'numericEditing_' in nav
assert 'k.vk == \'E\'' in nav and 'beginNumericEdit' in nav
assert 'jumpToLinkedRouting()' in nav and 'detailPeerOccurrence' in nav
assert 'GetSetTrackSendInfo(track_, sourceCat, selected.index' in extra
assert 'P_DESTTRACK' in extra and 'P_SRCTRACK' in extra
assert 'corresponding = i' in extra and '++seen == ordinal' in extra
assert 'numericEditing_ = false;' in extra and 'put(*e, raw);' in extra
assert 'MIDI_GetRecentInputEvent(i, bytes' in midi
assert 'pending.rbegin()' not in midi and 'items.rbegin()' in midi
assert 'decodeCc(' in midi and 'midiSequence_' in midi
assert 'pickup.allows(value, norm(before))' in midi
assert 'pendingMidiSpeech_' in midi and 'GetTickCount64()' in midi
assert 'memory_.setFixedCcLink(row.first, "")' in midi
assert 'memory_.setFixedCcLink(learnIdentity_, link)' in midi
assert 'continue; // learn event must never modify the target' in midi
assert 'if (filterEditing_ || numericEditing_)' in midi
assert 'if (section != sectionFor(page_' in midi
assert 'midiPickup_.clear()' in nav
assert 'memory_.fixedCcSpeech(speechTarget)' in midi and 'memory_.fixedCcSpeech(identity)' in midi
assert 'std::string TrackMemory::ccLink(' in mem
assert 'std::map<std::string, std::string> TrackMemory::ccLinks(' in mem
assert 'patchLine(std::move(payload)' in mem
assert 'sha256(current) != digest_' in mem and 'Backups' in mem
assert 'LREAPARAMS_PROFILE_V1' in (r/'src/Profile.cpp').read_text()
# Synthetic route symmetry: duplicate routing ordinal is relative to SAME peer.
sends=['Bass','Drums','Bass','Bass','Keys']
receives=['Bass','Bass','Bass']
assert sum(v=='Bass' for v in sends[:4])==3
assert [i for i,v in enumerate(receives) if v=='Bass'][2]==2
# Pickup model: first unmatched controller cannot jump an existing value.
assert abs(0/127-0.7)>1/127
assert (0/127<0.7 and 100/127>=0.7)
print('TEST54 MIDI CC, Lua .tp compatibility, numeric input and linked routing source contracts PASS (no build)')
