"""TEST52 source-only migration contract and synthetic folder examples.

No C++, CMake, MSBuild, GitHub workflow execution, or REAPER runtime calls.
"""
from pathlib import Path
from version_contract import version_at_least
root = Path(__file__).resolve().parents[1]
cpp = (root/'src/TrackNavigator.cpp').read_text(encoding='utf-8')
edit = (root/'src/TrackNavigatorEdit.cpp').read_text(encoding='utf-8')
auto = (root/'src/TrackNavigatorAutomation.cpp').read_text(encoding='utf-8')
h = (root/'include/lrp/TrackNavigator.h').read_text(encoding='utf-8')
api = (root/'include/lrp/ReaperApi.h').read_text(encoding='utf-8')
cm = (root/'CMakeLists.txt').read_text(encoding='utf-8')
lua = (root/'Legacy/Speak Track Params - TrackTake Navigator.lua').read_text(encoding='utf-8')
assert version_at_least(root, (0, 0, 52))
for name in ['TrackNavigatorEdit.cpp','TrackNavigatorAutomation.cpp']:
    assert f'src/{name}' in cm
for macro in ['NamedCommandLookup','ReorderSelectedTracks','GetTrackEnvelopeByName']:
    assert f'#define REAPERAPI_WANT_{macro}' in api
for name in ['_S&M_CUTSNDRCV1','_S&M_COPYSNDRCV1','_S&M_PASTSNDRCV1']:
    assert name in edit and name in lua
assert 'NamedCommandLookup(named)' in edit
assert 'if (command <= 0)' in edit and 'Tracks with routing were not changed' in edit
assert 'Main_OnCommand(command, 0)' in edit
assert 'refreshAfterTrackEdit' in edit and 'GetTrackGUID' in edit
assert 'clearPhysicalSelection();' in edit and 'clearPhysicalSelection();' not in auto
assert 'void TrackNavigator::moveSelectedTracks' in edit
assert 'ReorderSelectedTracks(before, 0)' in edit
assert 'folderLast(project_, i, count)' in edit
assert 'std::vector<GUID> originallySelected' in edit
assert 'for (const GUID& original : originallySelected)' in edit
assert 'SetTrackSelected(tr, logical);' in edit
assert "k.vk == 'C'" in cpp and "k.vk == 'X'" in cpp and "k.vk == 'V'" in cpp
assert 'k.alt && k.shift' in cpp and 'moveSelectedTracks(k.vk == VK_UP ? -1 : 1)' in cpp
assert 'switchDetailTrack(k.vk == VK_UP ? -1 : 1)' in cpp
assert 'void TrackNavigator::switchDetailTrack' in cpp and ('GetTrackNumSends(nextTrack, category)' in cpp or 'matchingRoutingCount(nextTrack, category)' in cpp)
assert 'Ctrl+Shift+V' in cpp and 'k.vk == VK_RETURN' in cpp
assert 'toggleCurrentAutomation();' in cpp and 'currentEnvelopeActive()' in cpp
assert 'Auto' in cpp and 'GetEnvelopeStateChunk' in auto and 'SetEnvelopeStateChunk' in auto
assert 'resolveTarget(project_, track_, e->category, e->index)' in auto
assert 'routingEnvelopeBlock(oldChunk, route.receive, tag)' in auto
assert 'SetTrackStateChunk(route.destination, chunk.c_str(), true)' in auto
assert 'Main_OnCommand(action, 0)' in auto
assert 'createWidthEnvelope(track_, project_)' in auto  # TEST55.10 completes Width creation
assert 'Main_OnCommand(nativeAction, 0)' in auto
assert 'const auto selected = selectedTrackGuids();' in auto
assert 'thread_local std::vector<char>' in auto
assert 'Parameter Library.cpp' not in cm
# folder expansion synthetic model; inclusive final row is essential.
def folder_last(depths, start):
    if depths[start] <= 0: return start
    level=depths[start]
    for i in range(start+1,len(depths)):
        level+=depths[i]
        if level<=0:return i
    return len(depths)-1
assert folder_last([1,1,0,-1,-1,0],0)==4
assert folder_last([1,1,0,-1,-1,0],1)==3
assert folder_last([1,-1,0],0)==1
assert folder_last([1,1,-2,0],0)==2
print('TEST52 clipboard, folder-aware move, automation and F2/F3 switch source contracts PASS (NO build)')
