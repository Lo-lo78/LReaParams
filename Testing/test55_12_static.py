"""TEST55.12: Width creation and verification must match the Lua's native envelope.
Source-only checks. Actual runtime behaviour requires GitHub Actions and REAPER.
"""
from pathlib import Path
r = Path(__file__).resolve().parents[1]
a = (r/'src/TrackNavigatorAutomation.cpp').read_text()
api = (r/'include/lrp/ReaperApi.h').read_text()
legacy = (r/'Legacy/Speak Track Params - TrackTake Navigator.lua').read_text()
assert '#define REAPERAPI_WANT_genGuid' in api
assert 'f1_track_auto_make_env_chunk' in legacy
assert 'bool widthShown(MediaTrack* track)' in a
assert 'std::string widthEnvelopeBlock(' in a
assert 'depth == 1 && (line == "<WIDTHENV2" || line == "<WIDTHENV")' in a
assert 'if (!block.empty()) return isShown(block);' in a
assert 'std::string newWidthEnvelope(MediaTrack* track)' in a
for term in ['genGuid(&guid);', 'EGUID ', 'ACT 1 -1', 'VIS 1 1 1.0',
             'ARM 1', 'DEFSHAPE 0 -1 -1', 'PT 0 %.12f 0']:
    assert term in a, term
assert 'const double value = GetMediaTrackInfo_Value(track, "D_WIDTH")' in a
assert 'std::string revised = oldChunk;' in a
assert 'revised.replace(offset, count, armed);' in a
assert 'if (oldChunk.find("<WIDTHENV") != std::string::npos) return false;' in a
assert 'revised.insert(finalClose + 1, created);' in a
assert 'SetTrackStateChunk(track, revised.c_str(), false)' in a
assert 'isShown(newBlock) == on &&' in a
assert '(!on || armIsOn(newBlock))' in a
assert 'SetTrackStateChunk(track, oldChunk.c_str(), false);' in a
assert 'if (e->type == Entry::width && page_ == Page::tracks) return widthShown(track_);' in a
assert 'const bool changed = setWidthShown(track_, project_, enable);' in a
assert 'if (changed && currentEnvelopeActive() == enable)' in a
assert 'if (TrackList_AdjustWindows) TrackList_AdjustWindows(false);' in a
assert 'Undo_BeginBlock2(project_)' in a and 'Undo_EndBlock2(project_' in a
assert 'createWidthEnvelope(' not in a
print('TEST55.12 Width native envelope state/source contracts PASS; runtime untested')
