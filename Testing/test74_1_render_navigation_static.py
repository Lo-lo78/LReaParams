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
               'lastTabName_', 'get_accName(', 'accSelect(', 'TCN_SELCHANGE'):
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
print('TEST74.1 render focus-only source PASS')
