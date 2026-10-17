"""TEST51 folder/end-folder/delete source-only checks and synthetic examples.
No compiler or REAPER calls are performed.
"""
from pathlib import Path
r=Path(__file__).resolve().parents[1]
h=(r/'include/lrp/TrackNavigator.h').read_text()
c=(r/'src/TrackNavigator.cpp').read_text()
f=(r/'src/TrackNavigatorFolders.cpp').read_text()
lua=(r/'Legacy/Speak Track Params - TrackTake Navigator.lua').read_text()
a=(r/'include/lrp/ReaperApi.h').read_text()
w=(r/'.github/workflows/build-windows.yml').read_text()
cm=(r/'CMakeLists.txt').read_text()
assert 'project(LReaParams VERSION 0.0.51' in cm
assert 'TrackNavigatorFolders.cpp' in cm
assert 'REAPERAPI_WANT_RemoveTrackSend' in a
assert 'GetTrackNumSends(source, 0)' in f and '"P_DESTTRACK"' in f
assert '--occurrence == 0' in f
assert 'RemoveTrackSend(source, 0, realIndex)' in f
assert 'Undo_BeginBlock2(project_)' in f and 'Undo_EndBlock2(project_' in f
assert 'std::lround(GetMediaTrackInfo_Value(track, "I_FOLDERDEPTH"))' in f
assert 'result.push_back(stack.back()); // inner -> outer' in f
assert 'label += ", end folder " + nameOf(folder)' in f
assert 'std::string(closed ? "closed folder " : "open folder ")' in f
assert 'GetMediaTrackInfo_Value(tr, "I_FOLDERCOMPACT") >= 2.0' in f
assert 'if (hiddenLevel >= 0 && nesting <= hiddenLevel) hiddenLevel = -1' in f
assert 'rebuildVisibleRows();' in c and 'rebuildVisibleRows();' in f
assert 'k.vk == VK_RETURN' in c and 'toggleCurrentFolder();' in c
assert 'k.vk == VK_DELETE' in c and 'deleteCurrentRouting();' in c
assert 'valueMode_ = !valueMode_' in c
assert 'set MIDI source to None for off' in c
assert 'e.type == Entry::midiMerge' in c
assert 'get_track_end_folder_tracks' in lua
assert 'delete_current_send_or_receive()' in lua
assert 'send_get_midi_merge_formatted' in lua
assert 'test51_folders_delete_static.py' in w
assert 'Parameter Library.cpp' not in cm

# Mirror REAPER's end-folder depth semantics on examples.
def suffixes(tracks):
 stack=[]; out=[]
 for name,delta in tracks:
  if delta > 0: stack.extend([name] * delta); out.append((name, []))
  elif delta < 0:
   ends=[]
   for _ in range(-delta):
    if stack: ends.append(stack.pop())
   out.append((name, ends))
  else: out.append((name, []))
 return out
assert suffixes([('Bass',1),('Sub Bass',-1)])[-1] == ('Sub Bass',['Bass'])
assert suffixes([('Instruments',1),('Bass',1),('Sub Bass',-2)])[-1] == ('Sub Bass',['Bass','Instruments'])
assert suffixes([('Outer',1),('Inner',1),('Note',-1),('Tail',-1)])[-2:] == [('Note',['Inner']),('Tail',['Outer'])]
# Source-send index of the Nth receive of the same source+destination.
def source_idx(dests, peer, occurrence):
 for i,d in enumerate(dests):
  if d == peer:
   occurrence-=1
   if occurrence==0:return i
 return -1
assert source_idx(['D','X','D'], 'D', 2)==2
assert source_idx(['D','X','D'], 'D', 1)==0
assert source_idx(['X'], 'D', 1)==-1
print('TEST51 folder labels/toggle and receive removal source contracts PASS (NO build)')
