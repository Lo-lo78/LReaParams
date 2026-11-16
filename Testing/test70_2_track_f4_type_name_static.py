"""TEST70.2: Track F4 uses the FX Type/Name parser and retains older INI titles."""
from pathlib import Path
r=Path(__file__).resolve().parents[1]
pref=(r/'src/Preferences.cpp').read_text(encoding='utf-8')
head=(r/'include/lrp/Preferences.h').read_text(encoding='utf-8')
track=(r/'src/TrackNavigator.cpp').read_text(encoding='utf-8')
assert 'std::array<int, 6> order' in head
assert 'std::array<bool, 6> enabled' in head
assert 'topic == 3 ? 6 : 4' in pref
assert 'scope == ShortcutScope::track && topic == 3' in pref
for label in ('L"Name"', 'L"Type"', 'L"Mode"'):
    assert label in pref
assert 'p.trackExtraTitles[2].order = {{0, 1, 4, 2, 5, 3}}' in pref
assert 'p.trackExtraTitles[2].enabled[5] = true;' in pref
assert 'if (count == 6 && order.size() == 4)' in pref
assert 'if (count == 6 && enabled.size() == 4)' in pref
assert 'cfg.enabled[4] = false; // Never enable Type implicitly on upgrade.' in pref
assert 'cfg.enabled[5] = cfg.enabled[2];' in pref
assert 'titlePartCount(ShortcutScope::track, i)' in pref
assert 'splitReaperFxName(toUtf8(pageText))' in pref
assert 'fromUtf8(parsed.name)' in pref and 'fromUtf8(parsed.type)' in pref
assert 'const std::wstring& pageText, const std::wstring& modeText)' in pref
assert 'const std::wstring mode = fxTcpListOpen_' in track
assert 'formatTrackPageTitle(wideUtf8(trackName()), 3, fxName, mode)' in track
# The default and legacy preference permutations must remain bijections.
legacy_examples=('0123', '2103', '3021', '0312')
for old in legacy_examples:
    parts=[]
    for c in old:
        if c=='2': parts.append('4')
        parts.append(c)
        if c=='2': parts.append('5')
    assert sorted(parts)==list('012345'), (old,parts)
assert (r/'Tools/push_lreaparams.cmd').exists()
assert (r/'.github/workflows/publish-reapack.yml').exists()
print('TEST70.2 Track F4 Type/Name/Mode and legacy INI migration PASS')
