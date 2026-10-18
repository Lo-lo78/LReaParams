"""TEST55.9+55.10: source-only safety and shortcut contracts; native build in CI."""
from pathlib import Path
r=Path(__file__).resolve().parents[1]
ex=(r/'src/Extension.cpp').read_text()
tr=(r/'src/TrackNavigator.cpp').read_text()
fm=(r/'src/TrackNavigatorMidi.cpp').read_text()
ta=(r/'src/TrackNavigatorAutomation.cpp').read_text()
fx=(r/'src/FxNavigator.cpp').read_text()
fa=(r/'src/FxNavigatorAdvanced.cpp').read_text()
api=(r/'include/lrp/ReaperApi.h').read_text()
assert 'backgroundTrackMidi_ = trackNavigator_' in ex
assert 'backgroundTrackMidi_.prepareBackgroundMidi();' in ex
assert 'backgroundTrackMidi_.tickMidi();' in ex
assert 'backgroundTrackMidi_.contextUnchanged()' in ex
assert 'backgroundTrackMidi_.end();' in ex
assert 'desired == &trackNavigator_) backgroundMidi_.end();' in ex
assert '(current_ == &navigator_ || current_ == &trackNavigator_)' in ex
assert 'backgroundMode_ = true;' in fm
assert 'midiSequence_ = recentSequence();' in fm
assert 'if (!midiSequence_ && !backgroundMode_)' in fm
assert 'if (backgroundMode_) return active_ && project_' in tr
assert 'if (active_ && !backgroundMode_)' in tr
assert 'clearAutomationConfirm_' in tr and 'clearAutomationConfirm_' in fx
assert 'k.ctrl && k.shift && k.alt && !k.altGr && k.vk == \'A\'' in tr
assert 'k.ctrl && k.shift && k.vk==\'A\'' in fa
assert 'if (k.alt)' in fa and 'No selected' in fa and 'Y confirms' in fa
assert 'No selected' in tr and 'Y confirms' in tr and 'clearTrackAutomations();' in tr
assert 'toggleEnvelope(true);' in fx
assert 'setWidthShown(track_, project_, enable)' in ta
assert 'WIDTHENV2' in ta and 'EGUID ' in ta and 'PT 0 ' in ta and 'SetTrackStateChunk(track, revised.c_str(), false)' in ta
assert 'SetTrackStateChunk(track, oldChunk.c_str(), false)' in ta
assert 'GetTrackEnvelopeByChunkName' in ta
assert 'CountTrackEnvelopes(track_)' in ta
assert 'setShown(env, false)' in ta
assert 'resolveTarget(project_, track_, 0, i)' in ta
assert 'setRoutingShown(route, tag, false)' in ta
assert 'Undo_BeginBlock2(project_)' in ta
assert 'Undo_EndBlock2(project_, "LReaParams: disable Track automation"' in ta
assert 'REAPERAPI_WANT_GetTrackEnvelopeByChunkName' in api
assert 'REAPERAPI_WANT_CountTrackEnvelopes' in api
assert 'REAPERAPI_WANT_GetTrackEnvelope' in api
assert 'Parameter Library.cpp' not in (r/'CMakeLists.txt').read_text()
print('TEST55.10 source contracts PASS; no native compile or DAW tests')
