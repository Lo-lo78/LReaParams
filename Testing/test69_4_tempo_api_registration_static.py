from pathlib import Path
p=Path(__file__).resolve().parents[1]
api=(p/'include/lrp/ReaperApi.h').read_text(encoding='utf-8')
header=(p/'include/lrp/TempoAction.h').read_text(encoding='utf-8')
source=(p/'src/TempoAction.cpp').read_text(encoding='utf-8')
functions=('AudioAccessorStateChanged','CreateTakeAudioAccessor','DestroyAudioAccessor',
'GetAudioAccessorSamples','GetMediaItemTakeInfo_Value','SetCurrentBPM',
'SetMediaItemInfo_Value','SetMediaItemTakeInfo_Value','TakeIsMIDI')
for name in functions:
    assert f'#define REAPERAPI_WANT_{name}\n' in api, name
    assert name in source, name
assert '#include "lrp/ReaperApi.h"' in header
assert '#include "reaper_plugin.h"' not in header
assert '#define REAPERAPI_MINIMAL' in api
print('TEST69.4 native BPM API registration PASS')
