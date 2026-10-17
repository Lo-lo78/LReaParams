"""TEST53.1 regression contracts, Python-only: no native build or REAPER execution."""
from pathlib import Path
root = Path(__file__).resolve().parents[1]
edit = (root / 'src/TrackNavigatorEdit.cpp').read_text(encoding='utf-8')
nav = (root / 'src/TrackNavigator.cpp').read_text(encoding='utf-8')
filt = (root / 'src/TrackNavigatorFilter.cpp').read_text(encoding='utf-8')
hdr = (root / 'include/lrp/TrackNavigator.h').read_text(encoding='utf-8')
flow = (root / 'src/Extension.cpp').read_text(encoding='utf-8')
workflow = (root / '.github/workflows/build-windows.yml').read_text(encoding='utf-8')
# Never silently downgrade a routing-aware SWS action to a native, routing-losing paste.
assert '_S&M_PASTSNDRCV1' in edit
assert 'SWS/S&M not installed' in edit
assert 'ReorderSelectedTracks(anchorIndex + 1, 0)' in edit
assert 'const GUID currentGuid = rows_[row_].guid' in edit
assert 'const bool wasHere = std::any_of(existing.begin(), existing.end()' in edit
assert 'if (!wasHere) added.push_back(*id)' in edit
assert 'for (int j = 0; j < static_cast<int>(added.size()) && alreadyAfter; ++j)' in edit
assert 'if (!alreadyAfter)' in edit
assert 'if (tr) SetTrackSelected(tr, newTrack)' in edit
assert 'Undo_BeginBlock2(project_)' in edit
assert 'if (action == TrackClipboardAction::paste && !pasted)' in edit
assert 'if (!filterQuery_.empty())' in edit
# Peer identity is the underlying source/destination track, independent of
# column filters and other sends to different peers.
assert 'detailPeerOccurrence(int category, int index) const' in hdr
assert 'P_DESTTRACK' in nav and 'P_SRCTRACK' in nav
assert 'if (other == target) ++ordinal;' in nav
assert 'if (occurrence > 1)' in nav
assert 'if (occurrence > 1) label +=' in nav
assert 'std::string TrackNavigator::detailColumnSpeech(int previousColumn) const' in nav
# Both cancellation in EDIT and clearing an active query must keep navigator
# open and speak a fresh value in the same style as FX Params.
assert filt.count('speech_("Search cleared. " + parameterValueSpeech());') == 2
assert 'void TrackNavigator::cancelFilter()' in filt
assert 'void TrackNavigator::clearFilter()' in filt
assert 'titleProxy_.syncTextControl(trackNavigator_.nativeTextField()' in flow
assert 'TEST53.1' in workflow
# Pure order/occurrence examples: these do not prove REAPER semantics, but
# guard intent for multiple pasted tracks and duplicate sends.
def splice_after(items, anchor, pasted):
    remaining = [x for x in items if x not in pasted]
    at = remaining.index(anchor) + 1
    return remaining[:at] + [x for x in items if x in pasted] + remaining[at:]
assert splice_after(['new1','new2','Drums','Bass','FX'], 'Bass', {'new1','new2'}) == ['Drums','Bass','new1','new2','FX']
assert splice_after(['Drums','Bass','FX','new1','new2'], 'Bass', {'new1','new2'}) == ['Drums','Bass','new1','new2','FX']
assert splice_after(['Drums','Bass','new1','new2','FX'], 'Bass', {'new1','new2'}) == ['Drums','Bass','new1','new2','FX']
peers=['Bass','Drums','Bass','Bass','Drums']
ordinal = [sum(p == peers[i] for p in peers[:i+1]) for i in range(len(peers))]
assert ordinal == [1,1,2,3,2]
print('TEST53.1 paste anchor, duplicated peer speech and search-clear source contracts PASS (no build)')
