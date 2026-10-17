"""TEST54.2 source contracts and synthetic examples. No C++ compilation."""
from pathlib import Path
from version_contract import version_at_least
r = Path(__file__).resolve().parents[1]
assert version_at_least(r, (0, 0, 54, 2))
auto = (r/'src/TrackNavigatorAutomation.cpp').read_text()
fx = (r/'src/FxNavigator.cpp').read_text()
track = (r/'src/TrackNavigator.cpp').read_text()
app = (r/'src/Extension.cpp').read_text()
api = (r/'include/lrp/ReaperApi.h').read_text()
spec = (r/'Legacy/Speak Track Params - TrackTake Navigator.lua').read_text()
assert 'speech_(std::string(enable ? "Auto. " : "Auto off. ") + parameterValueSpeech())' not in auto
assert 'return std::string(on ? "Auto. " : "Auto off. ") + e->title' in auto
assert 'ccParameterSuffix();' in auto
assert 'resolveTarget(project_, track_, e->category, e->index)' in auto
assert '++seen == ordinal' in auto and '++ordinal' in auto
assert 'AUXVOLENV' in auto and 'AUXPANENV' in auto and 'AUXMUTEENV' in auto
assert 'routingEnvelopeBlock(chunk, route.receive, tag)' in auto
assert 'SetTrackStateChunk(route.destination, chunk.c_str(), true)' in auto
assert 'const bool created = setRoutingShown(route, tag, true);' in auto
assert 'routingShown(route, tag) != on' in auto and 'armIsOn(routingEnvelopeBlock(checked, route.receive, tag))' in auto
assert 'ensureArmed' in auto and 'ARM 1' in auto
for action in ('_BR_SHOW_SEND_ENV_VOL_SEL_TRACK','_BR_SHOW_SEND_ENV_PAN_SEL_TRACK',
               '_BR_SHOW_SEND_ENV_MUTE_SEL_TRACK'):
    assert action in auto and action in spec
assert 'NamedCommandLookup(routingSwsAction(name))' in auto
assert 'Main_OnCommand(action, 0)' in auto
assert 'const auto selected = selectedTrackGuids();' in auto
assert 'GetTrackGUID(tr)' in auto and 'SetTrackSelected(tr, originally)' in auto
assert 'REAPERAPI_WANT_GetTrackStateChunk' in api and 'REAPERAPI_WANT_SetTrackStateChunk' in api
assert 'if (k.ctrl && !k.alt && !k.shift && k.vk == VK_TAB) return true;' in track
assert 'k.vk == VK_TAB &&' in fx and 'nextStartTrack_' in fx
assert 'navigator_.setNextStartTrack(preferred)' in app
assert 'MediaTrack* preferred = wasTrack ? trackNavigator_.cursorTrack() : nullptr' in app
assert 'if (target->begin()) {' in app and 'launchNavigator(target);' in app and 'if (previous->begin()) launchNavigator(previous);' in app
assert 'exitNavigation(false);' in app
# Duplicate sends must resolve by occurrence against the SAME destination.
send_destinations = ['Bass','Keys','Bass','Bass']
receives_from_source = ['LoLo','Other','LoLo','LoLo']
for send_index, wanted_receive in ((0,0),(2,2),(3,3)):
    occurrence=sum(d == 'Bass' for d in send_destinations[:send_index+1])
    found=[i for i,s in enumerate(receives_from_source) if s=='LoLo'][occurrence-1]
    assert found == wanted_receive
assert ('Auto. ' + 'Volume, 0.0 dB').count('Auto') == 1
print('TEST54.2 automation speech, AUXRECV creation, duplicate mapping and Ctrl+Tab source contracts PASS')
