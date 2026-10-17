"""TEST51 source-only routing contracts and synthetic bitfield checks.
Does NOT run a C++ compiler, REAPER, CTest or Windows APIs.
"""
from pathlib import Path
from version_contract import version_at_least
root=Path(__file__).resolve().parents[1]
s=(root/'src/TrackNavigator.cpp').read_text(encoding='utf-8')
h=(root/'include/lrp/TrackNavigator.h').read_text(encoding='utf-8')
api=(root/'include/lrp/ReaperApi.h').read_text(encoding='utf-8')
lua=(root/'Legacy/Speak Track Params - TrackTake Navigator.lua').read_text(encoding='utf-8')
assert version_at_least(root,(0,0,51))
assert "(k.vk == VK_UP || k.vk == VK_DOWN)" in s
assert 'moveToFolder(k.vk == VK_UP ? -1 : 1)' in s
assert 'return f1 && !k.shift && (k.vk == VK_UP || k.vk == VK_DOWN)' in s
assert "k.vk == 'V'" not in s
assert 'if (k.vk == VK_RETURN)' in s and 'valueMode_ = !valueMode_' in s
assert 'detailHeight = 14' in h and 'entries_.push_back(' in s
assert '#define REAPERAPI_WANT_GetSetTrackSendInfo' in api
assert 'MediaTrack* TrackNavigator::routingEndpoint' in s
assert 'GetSetTrackSendInfo(track_, e.category, e.index, parm, nullptr)' in s
assert 'ValidatePtr2(project_, peer, "MediaTrack*")' in s
assert 'const char* field = source ? "I_SRCCHAN" : "I_DSTCHAN";' in s
assert 'old & ~1023' in s
assert 'requiredChannels > 128' in s
assert 'SetMediaTrackInfo_Value(channelTrack, "I_NCHAN", requiredChannels)' in s
assert 'if (widened) SetMediaTrackInfo_Value(channelTrack, "I_NCHAN", previousChannelCount)' in s
assert 'TrackList_AdjustWindows(false)' in s and 'UpdateArrange()' in s
assert 'case Entry::audioSource: next = std::clamp(old + direction, -1.0, 63.0)' in s
assert 'case Entry::audioDestination: next = std::clamp(old + direction, 0.0, 63.0)' in s
assert 'std::clamp(old + direction, 0.0, 3.0)' in s
assert 'std::clamp(old + direction * (coarse ? 8.0 : 1.0), 0.0, 16.0)' in s
assert 'case 2: return "Post FX deprecated"' in s
assert 'case 3: return "Post FX"' in s
assert 'routing_pair_step_from_direction' in lua and 'audio_source_pair_step_from_direction' in lua
assert 'send_ensure_audio_source_channels' in lua and 'send_ensure_audio_destination_channels' in lua
# independent synthetic model to sanity-check the masks and channel counts
# mirrored from REAPER API and the Lua, without executing C++.
def src_mode(old,mode): return (old&1023)|(mode<<10)
def src_pair(old,pair): return -1 if pair<0 else (pair*2)|((0 if old<0 else old)&~1023)
def dst_pair(old,pair): return (pair*2)|(old&~1023)
def required(raw,source):
    if raw<0: return 0
    if source:
        mode=raw>>10
        width=1 if mode==1 else 2 if mode==0 else mode*2
    else: width=1 if (raw&1024) else 2
    return (raw&1023)+width
assert src_mode(4,3)==(4|(3<<10))
assert src_pair(3<<10,5)==((3<<10)|10)
assert src_pair(0,-1)==-1
assert src_pair(-1,0)==0
assert dst_pair(1024,3)==1030
assert required(src_pair(0,63),True)==128
assert required(src_pair(8<<10,63),True)==142  # safely rejected
assert required(dst_pair(1024,63),False)==127
assert required(dst_pair(0,63),False)==128
assert required(src_mode(126,1),True)==127
flags=0x5102AA07
for mask, shift, candidate in [(31,0,16),(31<<5,5,11),(255<<14,14,16),(255<<22,22,7)]:
    updated=(flags&~mask)|(candidate<<shift)
    assert (updated&~mask)==(flags&~mask)
    assert ((updated&mask)>>shift)==candidate
print('TEST51 source contracts and synthetic routing bitfields PASS (NO build)')
