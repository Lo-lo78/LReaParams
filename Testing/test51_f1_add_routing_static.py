"""TEST51 extension: source-only F1 send/receive creation and safety.
No compiler, build system, REAPER or Windows runtime is invoked.
"""
from pathlib import Path
from version_contract import version_at_least
root = Path(__file__).resolve().parents[1]
main = (root/'src/TrackNavigator.cpp').read_text(encoding='utf-8')
routing = (root/'src/TrackNavigatorRouting.cpp').read_text(encoding='utf-8')
header = (root/'include/lrp/TrackNavigator.h').read_text(encoding='utf-8')
api = (root/'include/lrp/ReaperApi.h').read_text(encoding='utf-8')
cmake = (root/'CMakeLists.txt').read_text(encoding='utf-8')
workflow = (root/'.github/workflows/build-windows.yml').read_text(encoding='utf-8')
lua = (root/'Legacy/Speak Track Params - TrackTake Navigator.lua').read_text(encoding='utf-8')
assert version_at_least(root, (0, 0, 51))
assert 'src/TrackNavigatorRouting.cpp' in cmake
assert '#define REAPERAPI_WANT_CreateTrackSend' in api
assert 'if (k.ctrl && k.shift && !k.alt && (k.vk == \'S\' || k.vk == \'R\'))' in main
assert "addTrackRouting(k.vk == 'S' ? RoutingKind::send : RoutingKind::receive)" in main
assert "(k.vk == 'S' || k.vk == 'R')" in main.split('bool TrackNavigator::accepts', 1)[1]
assert 'if (!k.repeat) addTrackRouting(' in main
assert 'pendingRoutingStatus()' in main  # Tab review during unfinished routing
assert 'if (pendingRouting_ != RoutingKind::none) { cancelTrackRouting(); return; }' in main
assert 'resetPendingRouting(); rows_.clear();' in main  # no pending state after exit
assert 'std::vector<GUID> pendingTrackGuids_;' in header
assert 'std::vector<GUID> TrackNavigator::selectedTrackGuids() const' in routing
assert 'CountTracks(project_)' in routing and 'IsTrackSelected(tr)' in routing
assert 'std::vector<GUID> TrackNavigator::selectedTrackGuids()' in routing  # ordered by project
assert 'pendingTrackGuids_ = tracks;' in routing
assert 'SetTrackSelected(tr, false)' in routing and 'refreshTrackSelection();' in routing
assert 'if (selectedNow.empty()) {' in routing and 'return; // do not discard the first stage' in routing
assert 'const auto& sourceGuids = receive ? selectedNow : pendingTrackGuids_;' in routing
assert 'const auto& destinationGuids = receive ? pendingTrackGuids_ : selectedNow;' in routing
assert 'MediaTrack* TrackNavigator::trackByGuid(const GUID& guid) const' in routing
assert 'ValidatePtr2(project_, tr, "MediaTrack*")' in routing
assert 'sameGuid(sourceGuids[s], destinationGuids[d])' in routing
assert 'CreateTrackSend(source, destination) >= 0' in routing
assert 'Undo_BeginBlock2(project_)' in routing and 'Undo_EndBlock2(project_' in routing
assert 'UNDO_STATE_TRACKCFG' in routing
assert 'if (page_ != Page::tracks) { speech_("Only in Tracks"); return; }' in routing
assert 'pendingRouting_ != kind' in routing and 'Finish or cancel Add receive first' in routing
assert 'if (added) { TrackList_AdjustWindows(false); UpdateArrange(); }' in routing
assert 'TrackNavigator::cancelTrackRouting' in routing
assert 'handle_add_send_shortcut()' in lua and 'handle_add_receive_shortcut()' in lua
assert 'Ctrl Shift S' in lua and 'Ctrl Shift R' in lua
assert 'test51_f1_add_routing_static.py' in workflow

# Standalone synthetic matrix of the Lua's ordered Cartesian-product rules.
def matrix(first, second, receive=False):
    sources, dests = (second, first) if receive else (first, second)
    return [(a,b) for a in sources for b in dests if a!=b], sum(a==b for a in sources for b in dests)
assert matrix(['A','B'],['C','D']) == ([('A','C'),('A','D'),('B','C'),('B','D')], 0)
assert matrix(['C','D'],['A','B'],True) == ([('A','C'),('A','D'),('B','C'),('B','D')], 0)
assert matrix(['A','B'],['B','C']) == ([('A','B'),('A','C'),('B','C')], 1)
assert matrix(['A'],['A']) == ([],1)
print('TEST51 F1 send/receive routing contracts PASS (source only; no build)')
