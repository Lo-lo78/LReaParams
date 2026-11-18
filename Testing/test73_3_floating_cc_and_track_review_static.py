"""TEST73.3: Track review readback, concise CC speech, global volatile Floating CC."""
from pathlib import Path
root=Path(__file__).resolve().parents[1]
header=(root/'include/lrp/ParameterRanges.h').read_text()
fx=(root/'src/FxNavigatorAdvanced.cpp').read_text()
track=(root/'src/TrackNavigator.cpp').read_text()
track_midi=(root/'src/TrackNavigatorMidi.cpp').read_text()
extension=(root/'src/Extension.cpp').read_text()
assert 'struct FloatingCcSession' in header
assert 'inline FloatingCcSession& floatingCcSession()' in header
assert 'return floatingCcSession().range;' in header
assert 'bool enabled = false;' in header
assert 'floatingCcSession().assign(cc.channel, cc.number);' in fx
assert 'floatingCcSession().assign(cc.channel, cc.number);' in track_midi
assert 'floatingCc_ = floating.active();' in fx
assert 'if (floating.enabled && floating.learned()) {' in track
assert 'floatingCcSession().enabled = false;' in track_midi
assert 'floatingCcSession().enabled=false' in fx
assert 'static ParameterRange range' not in header
assert 'pendingMidiSpeech_ = (target.parameter == "Volume" ?' in track_midi
assert 'pendingMidiSpeech_ = label + ", "' not in track_midi
assert '(floating ? std::string() : savedTrackLabel' not in track_midi
assert 'trackNavigator_.tickMidi();' in extension
before=extension.index('const std::string previous = titleProxyActive_ ? trackNavigator_.reviewLine()')
after=extension.index('titleProxy_.updateReviewLine(next);', before)
assert before < extension.index('trackNavigator_.tickMidi();', before) < after
assert 'titleProxy_.syncValueControl(trackNavigator_.nativeValueSlider()' in extension
# No new ReaPack persistence or mutation.
assert 'floatingCcSession()' not in (root/'src/TrackMemory.cpp').read_text()
print('TEST73.3 PASS: current Track Params values, concise CC speech, volatile shared CC')
