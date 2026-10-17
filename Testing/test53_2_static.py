"""TEST53.2: speech-direction contracts only. Does not compile C++ or run REAPER."""
from pathlib import Path
r=Path(__file__).resolve().parents[1]
nav=(r/'src/TrackNavigator.cpp').read_text()
hdr=(r/'include/lrp/TrackNavigator.h').read_text()
workflow=(r/'.github/workflows/build-windows.yml').read_text()
# Vertical movement, read current parameter/value only; header has no value.
vertical=nav.split('std::string TrackNavigator::parameterValueSpeech() const {',1)[1].split('void TrackNavigator::announce()',1)[0]
assert 'if (e->type == Entry::header) return e->title;' in vertical
assert 'e->title + ", " + valueText(*e, get(*e))' in vertical
assert 'detailPeerName' not in vertical and 'currentParameterSpeech' not in vertical
# Navigation up/down calls moveParameter->announce->parameterValueSpeech.
assert 'if (next != parameter_) { parameter_ = next; stepScale_ = memory_.step(parameterKey()); rememberPosition(); announce(); }' in nav
assert 'void TrackNavigator::announce() { speech_(parameterValueSpeech()); }' in nav
# Horizontal movement includes peer + Send/Receive, except duplicates of same peer.
column=nav.split('std::string TrackNavigator::detailColumnSpeech(int previousColumn) const {',1)[1].split('std::string TrackNavigator::reviewLine() const {',1)[0]
assert 'const std::string direction = page_ == Page::sends ? "Send" : "Receive";' in column
assert 'const int occurrence = detailPeerOccurrence(e->category, e->index)' in column
assert 'if (!samePeer || occurrence == 1)' in column
assert 'detailPeerName(e->category, e->index) + ", "' in column
assert 'if (occurrence > 1) prefix += " " + std::to_string(occurrence)' in column
assert 'if (e->type == Entry::header) return prefix;' in column
assert 'previous.index' in column and 'e->index' in column
assert 'ValidatePtr2(project_, peer, "MediaTrack*")' in column
assert 'detailColumnSpeech(previousColumn)' in nav
assert 'detailColumnSpeech(int previousColumn) const' in hdr
# Tab stays complete and indexed, while Search cleared uses vertical-only speech.
assert 'std::string info = currentParameterSpeech()' in nav
assert 'if (occurrence > 1) label += " " + std::to_string(occurrence);' in nav
filt=(r/'src/TrackNavigatorFilter.cpp').read_text()
assert filt.count('speech_("Search cleared. " + parameterValueSpeech());') == 2
assert 'Testing/test53_2_static.py' in workflow
# Synthetic examples (both directions and a filtered view); checks spec, not C++ runtime.
def simulate(peers,visible_columns, prev_col, next_col, send=True):
    peer=peers[visible_columns[next_col]]
    occurrence=sum(p==peer for p in peers[:visible_columns[next_col]+1])
    same=prev_col is not None and peers[visible_columns[prev_col]]==peer
    prefix='' if same and occurrence>1 else peer+', '
    return prefix+('Send' if send else 'Receive')+((' '+str(occurrence)) if occurrence>1 else '')+', Volume, -6 dB'
peers=['Bass','Bass','Drums','Bass']
assert simulate(peers,list(range(4)),None,0)=='Bass, Send, Volume, -6 dB'
assert simulate(peers,list(range(4)),0,1)=='Send 2, Volume, -6 dB'
assert simulate(peers,list(range(4)),1,2)=='Drums, Send, Volume, -6 dB'
assert simulate(peers,list(range(4)),2,3)=='Bass, Send 3, Volume, -6 dB'
assert simulate(peers,list(range(4)),1,0)=='Bass, Send, Volume, -6 dB'
assert simulate(peers,[0,3],0,1,False)=='Receive 3, Volume, -6 dB'
assert simulate(peers,[2,3],0,1,False)=='Bass, Receive 3, Volume, -6 dB'
print('TEST53.2 directional peer speech source contracts and examples PASS (no build)')
