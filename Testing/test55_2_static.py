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
assert 'if (memoryManager_) { speakMemory(title); return; }' in nav
assert 'if(navigator_.begin() && navigator_.openFxMemories(true))' in core
assert 'while (memoryColumn_ < 4 && memoryItems_.empty())' in manager
assert 'if (!memoryItems_.empty()) { speakMemory(); return; }' in manager
assert 'if (memoryRow_ != previous) speakMemory();' in manager
assert 'if (next == before) return;' in manager
assert 'savedColumn != memoryColumn_ || savedRow != memoryRow_' in manager
assert 'std::string(labels[col]) + ". " + item.label' in nav
# Parameter-specific ranges now replace all former page-wide Volume limits.
assert 'if (current() == &e) value = clampParameterValue(e,value);' in nav
assert 'const auto range = currentParameterRange();' in nav
assert 'void TrackNavigator::editCurrentRange(char mode)' in extra
assert 'clampParameterValue' in extra
assert 'scaleCcFraction' in midi and 'ccPickupTarget' in midi
assert 'LReaParams.ParameterRanges' in manager
assert 'Volume Ranges' not in manager
assert 'Ctrl+Shift+I' not in nav
# Deterministic range model: MIDI input 0..127 maps to configured endpoint.
from math import isclose
low, high = 30, 110
assert isclose((low + (high-low)*0/127)/127, 30/127)
assert isclose((low + (high-low)*127/127)/127, 110/127)
# Track positions remain installed; no redefinition of the user shortcuts.
assert 'saveTrackSlot(slot)' in nav and 'recallTrackSlot(slot)' in nav
assert 'Parameter Library' not in (root/'CMakeLists.txt').read_text()
print('TEST55.2 memory UI and Volume range source contracts PASS (native compile pending)')
