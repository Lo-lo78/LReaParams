"""TEST50 source-only behavior contracts. Not an MSVC or REAPER runtime test."""
from pathlib import Path
from version_contract import version_at_least
root = Path(__file__).resolve().parents[1]
cpp = (root / 'src/TrackNavigator.cpp').read_text(encoding='utf-8')
h = (root / 'include/lrp/TrackNavigator.h').read_text(encoding='utf-8')
api = (root / 'include/lrp/ReaperApi.h').read_text(encoding='utf-8')
assert version_at_least(root, (0, 0, 50))
assert 'k.vk == VK_TAB' in cpp and 'info += ". Step " + std::to_string(memory_.step(id))' in cpp
# Ctrl+R without Shift remains unbound; TEST51 adds only Ctrl+Shift+R
# for Add Receive, and does not restore the old Ctrl+R review shortcut.
assert 'k.vk == VK_TAB' in cpp
if "(k.vk == 'S' || k.vk == 'R')" in cpp:
    assert "if (k.ctrl && k.shift && !k.alt && (k.vk == 'S' || k.vk == 'R'))" in cpp
else:
    assert "k.vk == 'R'" not in cpp
assert 'std::to_string(CountSelectedTracks(project_)) + " tracks selected"' in cpp
assert 'k.vk == \'A\'' in cpp and 'k.vk == VK_DELETE' in cpp
assert 'k.vk == VK_SPACE' in cpp and 'toggleCursorTrackSelection' in cpp
assert 'void TrackNavigator::applyRangeSelection' in cpp
assert 'selectionBase_.clear();' in cpp and 'selectionAnchorRow_' in h
assert 'selectionBase_.insert(tr)' in cpp
assert 'std::unordered_set<MediaTrack*> wanted = selectionBase_' in cpp
assert 'SetTrackSelected(tr, wanted.count(tr) != 0)' in cpp
assert 'initialSelection_ = GetSelectedTrack2(project_, 0, true);' in cpp
assert 'const int next = direction < 0 ? 0 : static_cast<int>(rows_.size()) - 1;' in cpp
assert 'k.vk == VK_PRIOR || k.vk == VK_NEXT' in cpp and 'void TrackNavigator::moveToFolder' in cpp
if version_at_least(root, (0, 0, 51)):
    # TEST51 freed Ctrl+Shift+V for Value; TEST52 intentionally reuses
    # *Ctrl+V without Shift* for SWS Paste tracks with routing in F1.
    assert "k.ctrl && k.shift && !k.alt && k.vk == 'V'" not in cpp
    assert "k.ctrl && !k.alt && k.shift && k.vk == 'V'" not in cpp
    assert 'if (k.vk == VK_RETURN)' in cpp and 'valueMode_ = !valueMode_' in cpp
else:
    assert "k.vk == 'V'" in cpp and 'valueMode_ = !valueMode_' in cpp
assert 'REAPERAPI_WANT_SetTrackSelected' in api and 'REAPERAPI_WANT_IsTrackSelected' in api
assert 'if (page_ == Page::tracks) {' in cpp and 'Selected. ' in cpp
assert 'memory_.setValueSpeech(id, on)' in cpp and 'memory_.setStep(parameterKey(), stepScale_)' in cpp
assert 'GetTrackNumSends(track_, 0)' in cpp and 'detailHeight = 14' in h
print('TEST50 static contracts passed (no compilation)')
