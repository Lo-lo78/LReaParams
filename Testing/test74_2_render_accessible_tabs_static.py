"""TEST74.2: tab switching uses only the native MSAA tab role, never render controls."""
from pathlib import Path
r = Path(__file__).resolve().parents[1]
s = (r/'src/RenderNavigation.cpp').read_text(encoding='utf-8')
for needle in ('ROLE_SYSTEM_PAGETAB', 'Primary output format', 'Secondary output format',
               'accSelect(SELFLAG_TAKESELECTION', 'get_accSelection(',
               'lastTabFocus_', 'selectedPage()', 'VK_TAB', 'cachedFormatTab_'):
    assert needle in s, needle
for forbidden in ('TabCtrl_SetCurSel(', 'TCN_SELCHANGE', 'BM_CLICK', 'SendInput(', 'mouse_event('):
    assert forbidden not in s, forbidden
assert 'if (selectedPage() != page) return focusControl(tab);' in s
print('TEST74.2 native accessible-tab navigation PASS')
