"""TEST55.2 regression contracts; no local C++ compilation or REAPER runtime."""
from pathlib import Path
root = Path(__file__).resolve().parents[1]
manager = (root/'src/TrackNavigatorMemories.cpp').read_text()
nav = (root/'src/TrackNavigator.cpp').read_text()
extra = (root/'src/TrackNavigatorExtra.cpp').read_text()
midi = (root/'src/TrackNavigatorMidi.cpp').read_text()
core = (root/'src/Extension.cpp').read_text()
# F8: opens with exactly one initial item announcement; standalone action
# gets its single initial announcement from launchNavigator/announceTitle.
assert 'if (!standalone) speakMemory("Track Memories")' in manager
assert 'if (memoryManager_) { speakMemory("Track Memories"); return; }' in nav
assert 'if(navigator_.begin() && navigator_.openFxMemories(true))' in core
assert 'while (memoryColumn_ < 4 && memoryItems_.empty())' in manager
assert 'if (!memoryItems_.empty()) { speakMemory(); return; }' in manager
assert 'if (memoryRow_ != previous) speakMemory();' in manager
assert 'if (next == before) return;' in manager
assert 'savedColumn != memoryColumn_ || savedRow != memoryRow_' in manager
assert 'std::string(labels[col]) + ". " + item.label' in nav
# All write paths respect the saved project range, not only keyboard nudges.
assert 'value = amp(std::clamp(db(value), range.first, range.second));' in nav
assert 'memory_.volumeRange(page_ == Page::tracks' in nav
assert 'const auto limits = memory_.volumeRange(page_ == Page::tracks' in extra
assert 'Volume outside configured range' in extra
assert 'const auto volumeLimits = memory_.volumeRange(section);' in midi
assert 'volumeLimits.second - volumeLimits.first' in midi
assert 'pickup.applied(norm(get(*target)))' in midi
assert 'info += ". Volume range "' in nav
# Sanity-check the boundary and MIDI numeric model for sample user limits.
import math
lo, hi = -60.0, 0.0
for cc in range(128):
    db = lo + (hi-lo)*cc/127.0
    amp = 10**(db/20)
    assert lo - 1e-9 <= 20*math.log10(amp) <= hi+1e-9
assert max(lo, min(hi, 7.5)) == hi
assert max(lo, min(hi, -80)) == lo
# Track positions remain installed; no redefinition of the user shortcuts.
assert 'saveTrackSlot(slot)' in nav and 'recallTrackSlot(slot)' in nav
assert 'Parameter Library' not in (root/'CMakeLists.txt').read_text()
print('TEST55.2 memory UI and Volume range source contracts PASS (native compile pending)')
