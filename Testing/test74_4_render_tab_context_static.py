"""TEST74.4: audible context for focus-only Alt+letter navigation.
The selected output-format page must be READ (never changed) from REAPER.
"""
from pathlib import Path
r = Path(__file__).resolve().parents[1]
s = (r / 'src/RenderNavigation.cpp').read_text(encoding='utf-8')
h = (r / 'include/lrp/RenderNavigation.h').read_text(encoding='utf-8')
assert 'int selectedFormatPage() const;' in h
start = s.index('int RenderNavigation::selectedFormatPage() const {')
stop = s.index('bool RenderNavigation::focusPageTab(int page)', start)
read = s[start:stop]
for evidence in ('TCM_GETCURSEL', 'STATE_SYSTEM_SELECTED', 'get_accSelection(',
                 'return selected[0] != selected[1]', 'return -1;'):
    assert evidence in read, evidence
for forbidden in ('TCM_SETCURSEL', 'TCM_SETCURFOCUS', 'accSelect(',
                  'SendInput(', 'BM_CLICK', 'SetFocus(', 'SetWindowTextW('):
    assert forbidden not in read, forbidden
start = s.index('bool RenderNavigation::jumpKey(wchar_t letter) {')
stop = s.index('std::vector<RenderNavigation::Control> RenderNavigation::results(', start)
jump = s[start:stop]
for evidence in ('c.format && !c.tab', 'selectedFormatPage()',
                 'speak_(page == 0 ? "Primary" : "Secondary")',
                 'if (focusControl(target))'):
    assert evidence in jump, evidence
assert jump.index('speak_(page == 0') < jump.index('if (focusControl(target))')
# The module is still focus-only; tab switch gestures and ReaPack are unchanged.
assert 'if (ctrl && !alt && vk == VK_TAB' not in s
for forbidden in ('Main_OnCommand(', 'RenderFile(', 'SetMediaTrackInfo_Value(',
                  'SendInput(', 'BM_CLICK'):
    assert forbidden not in s
print('TEST74.4 format-page context and focus-only behavior PASS')
