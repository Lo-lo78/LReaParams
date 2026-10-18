"""TEST55.13 source-only contracts; real build belongs to GitHub Actions."""
from pathlib import Path
r = Path(__file__).resolve().parents[1]
nav = (r/'src/TrackNavigator.cpp').read_text()
head = (r/'include/lrp/TrackNavigator.h').read_text()
midi = (r/'src/TrackNavigatorMidi.cpp').read_text()
mem = (r/'src/TrackMemory.cpp').read_text()
headmem = (r/'include/lrp/TrackMemory.h').read_text()
manager = (r/'src/TrackNavigatorMemories.cpp').read_text()
folder = (r/'src/TrackNavigatorFolders.cpp').read_text()
routing = (r/'src/TrackNavigatorRouting.cpp').read_text()
lua = (r/'Legacy/Speak Track Params - TrackTake Navigator.lua').read_text()
assert 'function grid_jump_by_initial_in_tracks_row' in lua
assert 'function grid_jump_by_initial_in_current_column' in lua
assert 'void TrackNavigator::jumpByInitial(wchar_t letter)' in nav
assert 'if (!k.repeat) jumpByInitial(k.character);' in nav
assert 'std::iswalnum' in nav and 'std::towlower' in nav
assert 'syncCursorToReaper();' in nav
assert 'detailIndex_ * detailHeight + next' in nav
assert 'parameter_ = next;' in nav
assert 'stepScale_ = memory_.step(parameterKey());' in nav
assert 'std::string fixedRoutingSignature(const std::string& identity) const' in head
assert 'LReaParams.SendTopology.v1' in midi
assert 'return sha256(topology)' in midi
assert 'saved.empty() || saved != fixedRoutingSignature(identity)' in midi
assert 'memory_.setRoutingGuard(learnIdentity_, signature)' in midi
assert 'LReaParams.FixedRoutingGuards' in mem
assert 'invalidateSendGuardsForSource' in mem and 'invalidateSendGuardsForSource' in headmem
assert 'memory_.invalidateSendGuardsForSource' in folder
assert 'memory_.invalidateSendGuardsForSource' in routing
assert 'routing changed, relearn CC' in manager
# The user explicitly rejected per-track steps: existing type-level Step key remains.
assert 'stepScale_ = memory_.step(parameterKey());' in nav
assert 'memory_.setStep(parameterKey(), stepScale_)' in nav
assert 'StepByTrack' not in mem and 'StepByTrack' not in nav
assert 'Track|' not in mem.split('int TrackMemory::step(')[1].split('bool TrackMemory::valueSpeech')[0]
print('TEST55.13 initial cycling, guarded routing and shared steps PASS (static only)')
