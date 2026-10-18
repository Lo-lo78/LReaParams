"""TEST55.4: FX/Track memory defaults and unified entry points (source-only)."""
from pathlib import Path
r = Path(__file__).resolve().parents[1]
manager = (r/'src/TrackNavigatorMemories.cpp').read_text()
mem = (r/'src/TrackMemory.cpp').read_text()
head = (r/'include/lrp/TrackMemory.h').read_text()
profile = (r/'src/Profile.cpp').read_text()
nav = (r/'src/TrackNavigator.cpp').read_text()
midi = (r/'src/TrackNavigatorMidi.cpp').read_text()
fx = (r/'src/FxNavigatorMemories.cpp').read_text()
core = (r/'src/Extension.cpp').read_text()
tests = (r/'Testing/ProfileTests.cpp').read_text()
assert 'return read(fixedSpeechSection, identity) == "1"' in mem
assert 'LReaParams.FixedCCSpeechByTarget' in mem and 'LReaParams.FixedCCSpeechByTarget' in profile
assert 'memory_.fixedCcSpeech(identity)' in midi
assert 'memory_.fixedCcSpeech(speechTarget)' in midi
assert 'memory_.setFixedCcSpeech(target, on)' in nav
assert 'memory_.fixedCcSpeech(target)' in nav
assert 'memory_.ccSpeech(page, bare)' not in nav
assert 'memory_.ccSpeech(target.send ? "Sends" : "Track", target.parameter)' not in midi
assert 'memory_.ccSpeech(section, key)' not in midi
assert 'if (step == 0) continue;' in manager
assert 'if (memory_.valueSpeech(entry.first)) continue;' in manager
assert 'if (!memory_.fixedCcSpeech(entry.first)) continue;' in manager
assert 'if (guid.empty()) continue;' in manager
assert 'Navigation Memory' not in manager
assert '"Track Positions", "Volume Ranges"' in manager
assert 'memory_.clearVolumeRange(item.key)' in manager
assert 'memory_.setFixedCcSpeech(item.key.substr(2), false)' in manager
assert 'if (value.empty()) { bytes.erase(match, matchEnd - match); return bytes; }' in mem
assert 'if (value.empty()) return bytes;' in mem
assert 'void clearVolumeRange(const std::string& page);' in head
assert 'if(!standalone && !editF7_)' not in fx
assert 'memoryReturnF7_=editF7_' in fx
assert "k.vk == 'M'" in (r/'src/FxNavigator.cpp').read_text() and 'openFxMemories(false)' in (r/'src/FxNavigator.cpp').read_text()
assert 'openFxMemories(true)' in core and 'openTrackMemories(true)' in core
assert 'Scoped MIDI speech not restored independently per track' in tests
assert 'Reset must remove default overrides from project TP' in tests
assert 'Parameter Library' not in (r/'CMakeLists.txt').read_text()
print('TEST55.4 source contract PASS (no local native compilation)')
