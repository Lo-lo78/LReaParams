"""Source-only guards for Track title templates and accessible disjoint F1 selection."""
from pathlib import Path
root = Path(__file__).resolve().parents[1]
pref = (root / 'src/Preferences.cpp').read_text(encoding='utf-8')
head = (root / 'include/lrp/Preferences.h').read_text(encoding='utf-8')
track = (root / 'src/TrackNavigator.cpp').read_text(encoding='utf-8')
track_head = (root / 'include/lrp/TrackNavigator.h').read_text(encoding='utf-8')
routing = (root / 'src/TrackNavigatorRouting.cpp').read_text(encoding='utf-8')
assert 'int lastTreeChoice = 0;' in pref
assert 'lastTreeChoice = i;' in pref
assert 'std::clamp(lastTreeChoice, 0, 6)' in pref
assert 'SetFocus(state.tree);' in pref
for title in ['Track (F1)', 'Sends (F2)', 'Receives (F3)', 'FX TCP (F4)',
              'Track MIDI (F5)', 'Hardware outputs (F6)', 'ReaRoute (F7)',
              'MIDI CC', 'Parameter Steps', 'Parameter Speech',
              'Track Positions', 'Volume Ranges']:
    assert title in pref, title
assert 'std::array<TitleMessage, 11> trackExtraTitles' in head
assert 'fillMessageTopics(st);' in pref
assert 'st->selectedTopic[scopeIndex(st->messageScope)] = selected;' in pref
assert 'TrackTitlePage' in pref and 'loadTitle(path, key.c_str()' in pref
assert 'saveTitle(path, key.c_str()' in pref
assert 'void setTitleMessages(const Preferences& settings)' in pref
for idx in range(1, 7):
    assert f'formatTrackPageTitle(wideUtf8(trackName()), {idx}' in track
assert '7 + std::clamp(memoryColumn_, 0, 4)' in track
assert 'bool selectionBuilding_ = false;' in track_head
assert 'if (selectionBuilding_) return;' in track
assert 'selectionBuilding_ = CountSelectedTracks(project_) > 1;' in track
assert 'selectionAnchorRow_ = row_;' in track
assert 'applyRangeSelection(row_, row_);' in track
assert 'announceSelection();\n        return;' in track
assert 'selectionBuilding_ = true;' in track
assert 'if (page_ == Page::tracks) {' in track
assert 'CountSelectedTracks(project_) > 1 && IsTrackSelected(track_)' in track
assert 'selectionBuilding_ = false;' in routing
# Model first-press anchor selection followed by extension and separate islands.
selected = {3}; cursor = 3; in_stroke = False; anchor = None

def shift_down():
    global cursor, selected, in_stroke, anchor
    if not in_stroke:
        in_stroke = True
        anchor = cursor
        selected.add(cursor)
        return
    cursor += 1
    selected |= set(range(anchor, cursor + 1))

def down_to(dest):
    global cursor, in_stroke
    cursor = dest
    in_stroke = False

def shift_space():
    global selected
    if cursor in selected: selected.remove(cursor)
    else: selected.add(cursor)

shift_down()           # Start at track 3 (no cursor move)
assert cursor == 3 and selected == {3}
shift_down()           # Extend to track 4
assert cursor == 4 and selected == {3, 4}
down_to(7); shift_space()
down_to(9); shift_space()
down_to(10); shift_down()  # Start another island at 10
assert cursor == 10 and 11 not in selected
shift_down(); shift_down()  # 11 and 12
assert selected == {3, 4, 7, 9, 10, 11, 12}, selected
# To select 11/12 while excluding 10, start the stroke *on* track 11.
selected = {3, 4, 7, 9}; down_to(11); shift_down(); shift_down()
assert selected == {3, 4, 7, 9, 11, 12}, selected
print('TEST69 Track titles / remembered tree / first-press Shift and discontinuous multi-selection PASS (static)')
