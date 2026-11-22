#!/usr/bin/env python3
"""TEST75.3.7: only Alt+S reaches shortcut lookup in Preferences."""
from pathlib import Path
p=(Path(__file__).resolve().parents[1]/'src/Preferences.cpp').read_text(encoding='utf-8')
subclass=p.split('// Only Alt+S focuses Shortcut lookup.',1)[1].split("vk == 'R'",1)[0]
assert "alt && !ctrl && !shift && vk == 'S'" in subclass
window=p.split('if (msg == WM_SYSCHAR && (GetKeyState(VK_MENU) & 0x8000)) {',1)[1].split("(wp == 'r' || wp == 'R')",1)[0]
assert "(wp == 's' || wp == 'S')" in window
assert "wp == 'd'" not in window and "wp == 'D'" not in window
pump=p.split('// Only Alt+S focuses the shortcut lookup',1)[1].split('// Alt+R invokes Reset',1)[0]
assert "msg.message == WM_SYSKEYDOWN && msg.wParam == 'S'" in pump
assert "msg.wParam == 'D'" not in pump
assert 'if (isDialogMessage && isShortcutInput && !altTab)' in p
assert 'if (isDialogMessage && state.lookupActivator)' in p
assert 'Alt+S/Alt+D' not in p
assert "focusShortcutLookup(st, vk); return 0;" in p
assert "focusShortcutLookup(&state, static_cast<UINT>(msg.wParam));" in p
print('TEST75.3.7 only Alt+S activates Preferences shortcut lookup: static PASS')
