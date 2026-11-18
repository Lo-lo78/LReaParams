"""TEST73.4: value-only Track MIDI speech and non-destructive Fixed/Float toggle."""
from pathlib import Path
root = Path(__file__).resolve().parents[1]
header = (root/'include/lrp/ParameterRanges.h').read_text()
track = (root/'src/TrackNavigatorMidi.cpp').read_text()
fx = (root/'src/FxNavigatorAdvanced.cpp').read_text()
track_enter = (root/'src/TrackNavigator.cpp').read_text()
assert 'bool suspendedByFixed = false;' in header
assert 'bool active() const noexcept { return enabled && !suspendedByFixed && learned(); }' in header
assert 'void suspendForFixed(bool on) noexcept { suspendedByFixed = on; }' in header
assert 'session.suspendForFixed(false);' in track
assert 'floatingCc_ = session.active();' in track
assert 'floatingCcSession().suspendForFixed(true);' in track
assert 'floatingCcSession().suspendForFixed(true);' in fx
assert 'session.suspendForFixed(fixedCc_);' in fx
assert 'if (!fixedCc_ && session.active()) {' in fx
assert 'floatingCc_ = true;' in fx
assert 'fixedCc_ = floating.suspendedByFixed;' in fx and 'fixedCc_ = floating.suspendedByFixed;' in track_enter
# Track MIDI speech is value-only in F1-F3 and F4 (fixed or floating).
assert 'pendingMidiSpeech_ = valueText(*target, get(*target));' in track
assert 'pendingMidiSpeech_ = (target.parameter == "Volume" ?' in track
assert 'pendingMidiSpeech_ = formatted[0] ? std::string(formatted) : std::to_string(next);' in track
assert 'pendingMidiSpeech_ = key + ", "' not in track
assert 'pendingMidiSpeech_ = target.parameter + ", "' not in track
print('TEST73.4 PASS: value-only readback, floating CC survives Fixed on/off')
