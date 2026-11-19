"""Source-only invariants for experimental native Render navigation."""
from pathlib import Path
root = Path(__file__).resolve().parents[1]
src = (root / 'src/RenderNavigation.cpp').read_text(encoding='utf-8')
hdr = (root / 'include/lrp/RenderNavigation.h').read_text(encoding='utf-8')
ext = (root / 'src/Extension.cpp').read_text(encoding='utf-8')
cm = (root / 'CMakeLists.txt').read_text(encoding='utf-8')
for needle in ('WH_GETMESSAGE', 'WM_NULL', 'isRender(', 'GetForegroundWindow()',
               'Find Render control', 'VK_F3', 'VK_TAB', 'VK_RETURN', 'VK_ESCAPE',
               'VK_CONTROL', 'VK_MENU', 'focusControl(', 'refreshControls(',
               'EnumChildWindows(', 'lastTabFocus_', 'lastTabId_',
               'lastTabName_', 'get_accName(', 'accSelect(', 'ROLE_SYSTEM_PAGETAB', 'get_accSelection('):
    assert needle in (src+hdr), needle
assert 'src/RenderNavigation.cpp' in cm
assert 'renderNavigation_.start()' in ext
assert 'renderNavigation_.tick()' in ext
assert 'renderNavigation_.stop()' in ext
for forbidden in ('Main_OnCommand(', 'SetMediaTrackInfo_Value(', 'TrackFX_SetParam(',
                  'RenderFile(', 'BM_CLICK', 'SendInput(', 'mouse_event(',
                  'SetWindowTextW(', 'WritePrivateProfileString('):
    assert forbidden not in src, forbidden
assert 'case 1: return L"Render";' in src
assert 'case 1046: return L"Tail";' in src
assert 'case 1041: return L"Sample rate";' in src
# Windows RECT coordinates use LONG, unlike the int literals/temporaries.
# MSVC rejects ambiguous std::min/std::max template deduction without a fixed type.
for expression in (
    'std::min<int>(horizontal + vertical*3, above + std::abs(a.left-dst.left))',
    'std::max<int>(0, (bounds.right-bounds.left-420)/2)',
    'std::max<int>(0, (bounds.bottom-bounds.top-110)/3)',
):
    assert expression in src, expression
print('TEST74.1 render focus-only source PASS')

# Never synthesize tab-clicks, rendering actions or changes to render settings.
assert 'TabCtrl_SetCurSel(' not in src
assert 'TCN_SELCHANGE' not in src
assert 'selectAccessibleTab(tabs, page)' in src
assert 'if (selectedPage() != page) return focusControl(tab);' in src
print('TEST74.2 accessible tabs PASS')
