"""TEST56.9.1: catch F4 Fixed CC identity and focus regression, source-only."""
from pathlib import Path
r = Path(__file__).resolve().parents[1]
memory = (r / "src/TrackMemory.cpp").read_text(encoding="utf-8")
midi = (r / "src/TrackNavigatorMidi.cpp").read_text(encoding="utf-8")
parser = (r / "src/Profile.cpp").read_text(encoding="utf-8")
profile = (r / "Testing/ProfileTests.cpp").read_text(encoding="utf-8")
assert 'bool isFixedFxTcpIdentity(const std::string& id)' in memory
assert 'bool isScopedFixedCcIdentity(const std::string& identity)' in memory
assert memory.count('if (!isScopedFixedCcIdentity(identity))') == 2
assert 'isGuid(std::string_view(id).substr(prefix.size()' in memory
assert 'isGuid(std::string_view(id).substr(trackEnd + 1' in memory
assert 'return value <= 32767;' in memory
assert 'TrackMemory beforeLearn = memory_;' in midi
assert 'memory_ = std::move(beforeLearn);' in midi
assert 'speech_("CC learn failed. Could not save project Track memory");' in midi
assert 'memory_.setFixedCcLink(learnIdentity_, link);' in midi
assert 'memory_.flush();' in midi
assert 'fxTcpA' in profile and 'fxTcpB' in profile
assert 'tmAgain.fixedCcLink(fxTcpA) == "3,74"' in profile
assert 'afterF4Delete.fixedCcLink(fxTcpA).empty()' in profile
assert 'rejected([&] { tm.setFixedCcLink("FxTcp|"' in profile
print("TEST56.9.1 Fixed F4 CC persistence and focus regression contract PASS (source-only)")
