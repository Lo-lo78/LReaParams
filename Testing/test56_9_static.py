"""Source-only contracts for F4 completion. Never runs a C++ build."""
from pathlib import Path
r = Path(__file__).resolve().parents[1]
f = (r/'src/TrackNavigatorFxTcp.cpp').read_text()
n = (r/'src/TrackNavigator.cpp').read_text()
h = (r/'include/lrp/TrackNavigator.h').read_text()
api = (r/'include/lrp/ReaperApi.h').read_text()
assert "k.vk == 'E'" in f and 'beginFxTcpNumericEdit();' in f
assert "k.vk == 'E'" in n and 'page_ == Page::fxTcp' in n
assert 'if (numericEditing_) {' in f and 'commitFxTcpNumericEdit();' in f
assert 'nativeTextField()' in h and 'numericBuffer_' in h
assert 'fxTcpNumericGuid_' in h and 'fxTcpNumericTrack_' in h
assert 'TrackFX_FormatParamValueNormalized' in f and 'fxTcpFormatNumeric' in f
assert 'TrackFX_SetParam(track_' in f and 'writeFxTcpRawValue' in f
assert 'memory_.valueSpeech(fxTcpStepKey())' in f
assert 'suppressPutSpeech_ = true;' in f and 'suppressPutSpeech_ = false;' in f
assert 'if (known && toggle)' in f and 'std::round(old / step)' in f
assert 'high - low >= 2.0 && high - low <= 64.0' in f
assert '#define REAPERAPI_WANT_TrackFX_SetParam' in api
assert '#define REAPERAPI_WANT_TrackFX_FormatParamValueNormalized' in api
print('TEST56.9 F4 numeric, speech preference and discrete parameter source checks PASS')
