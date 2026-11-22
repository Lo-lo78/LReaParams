"""TEST75.3.3: a shortcut query never activates the Preferences mnemonics."""
from pathlib import Path
s=(Path(__file__).resolve().parents[1]/'src/Preferences.cpp').read_text(encoding='utf-8')
page=s.split('LRESULT CALLBACK pageProc(', 1)[1].split('LRESULT CALLBACK wndProc(', 1)[0]
lookup=page.index('if (hwnd == st->lookup) {')
alt_handlers=page.index('if (hwnd != st->capture && alt) {')
assert lookup < alt_handlers, 'Lookup must be checked before Alt+O/Alt+C direct handlers'
raw=s.split('const bool isShortcutInput = state.page == Page::shortcuts',1)[1]
assert raw.index('if (isDialogMessage && isShortcutInput && !altTab)') < raw.index('IsDialogMessageW(hwnd, &msg)'), 'Bypass dialog mnemonics during shortcut lookup and capture'
assert 'SendMessageW(focused, msg.message, msg.wParam, msg.lParam);' in raw
assert 'msg.message == WM_SYSCHAR' in raw and 'msg.message == WM_SYSDEADCHAR' in raw
assert 'const bool inShortcutInput = st->page == Page::shortcuts' in s
assert 'if (inShortcutInput && msg == WM_SYSCHAR) return 0;' in s
assert 'L"&Reset section..."' in s and 'L"&OK"' in s and 'L"&Cancel"' in s
assert 'Shortcut not found in this section' in s
print('TEST75.3.3 keyboard lookup vs dialog mnemonics: static PASS')
