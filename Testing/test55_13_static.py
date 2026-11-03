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
# TEST62.9: original initial navigation became incremental type-ahead.
# The keyboard event timestamp and repeat flag are now forwarded to the
# same shared matcher used by FX Params and the memory managers.
type_ahead = (r/'include/lrp/TypeAhead.h').read_text(encoding='utf-8')
assert 'void TrackNavigator::jumpByInitial(wchar_t letter, DWORD eventTime, bool repeated, bool backwards)' in nav
assert 'jumpByInitial(typeAheadCharacter(k.vk, k.shift, k.character),' in nav
assert 'std::iswalnum' in nav
assert 'typeAhead_.find(letter, eventTime, repeated, row_, count, backwards,' in nav
assert 'typeAhead_.find(letter, eventTime, repeated, parameter_, detailHeight, backwards,' in nav
assert 'static constexpr std::uint32_t intervalMs = 1000;' in type_ahead
assert 'sameLetterCycle' in type_ahead

assert 'syncCursorToReaper();' in nav
assert 'detailIndex_ * detailHeight + i' in nav
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
print('TEST55.13 incremental navigation, guarded routing and shared steps PASS (static only)')
