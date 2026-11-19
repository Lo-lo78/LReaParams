"""TEST74.3: focus only on the Primary/Secondary tab item. No Ctrl+Tab override."""
from pathlib import Path
r = Path(__file__).resolve().parents[1]
s = (r/'src/RenderNavigation.cpp').read_text(encoding='utf-8')
h = (r/'include/lrp/RenderNavigation.h').read_text(encoding='utf-8')
for needle in ('ROLE_SYSTEM_PAGETAB', 'Primary output format',
               'Secondary output format', 'accSelect(SELFLAG_TAKEFOCUS',
               'TCM_SETCURFOCUS', 'TCM_GETCURFOCUS',
               'focusPageTab(c.tabPage)',
               "return focusPageTab(vk == '1' ? 0 : 1)",
               'focusAccessibleTab(tabs, page)',
               'get_accFocus(', 'STATE_SYSTEM_FOCUSED'):
    assert needle in s, needle
for forbidden in ('SELFLAG_TAKESELECTION', 'changePage(', 'selectedPage()',
                  'rememberFocus(', 'lastTabFocus_', 'lastTabId_', 'lastTabName_',
                  'if (ctrl && !alt && vk == VK_TAB',
                  'TabCtrl_SetCurSel(', 'TCM_SETCURSEL', 'TCN_SELCHANGE',
                  'BM_CLICK', 'SendInput(', 'mouse_event('):
    assert forbidden not in s+h, forbidden
# No fallback from a tab accelerator to an unrelated format control.
assert 'focusControl(remembered)' not in s
assert 'return focusControl(tab);' not in s[s.index('bool RenderNavigation::focusPageTab('):s.index('void RenderNavigation::findDialog()')]
print('TEST74.3 native Primary/Secondary tab-item focus PASS')
