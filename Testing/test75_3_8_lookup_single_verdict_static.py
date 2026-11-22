#!/usr/bin/env python3
"""TEST75.3.8: one definitive lookup verdict per physical key press."""
from pathlib import Path
p = (Path(__file__).resolve().parents[1] / 'src/Preferences.cpp').read_text(encoding='utf-8')
lookup = p.split('bool findShortcut(DialogState* st, const Key& key)', 1)[1].split('void resetSingleShortcut(', 1)[0]
subclass = p.split('LRESULT CALLBACK pageProc(', 1)[1].split('LRESULT CALLBACK wndProc(', 1)[0]
pump = p.split('std::optional<Preferences> editPreferences(', 1)[1].split('Key mapPreferredShortcut(', 1)[0]
assert 'if (found < 0) return false;' in lookup
assert 'Shortcut not found in this section' not in lookup
assert 'return true;' in lookup and 'SetFocus(st->shortcuts);' in lookup
assert 'UINT lookupQueryVk = 0;' in p and 'bool lookupMissPending = false;' in p
assert 'msg == WM_SYSKEYDOWN && (lp & (static_cast<LPARAM>(1) << 29)) != 0' in subclass
assert 'if (findShortcut(st, shortcut(vk' in subclass
assert 'st->lookupMissPending = false;' in subclass
assert 'st->lookupMissPending = true;' in subclass
assert 'msg.message == WM_KEYUP || msg.message == WM_SYSKEYUP' in pump
assert 'static_cast<UINT>(msg.wParam) == state.lookupQueryVk' in pump
assert 'if (missing && state.announce)' in pump
assert pump.count('state.announce("Shortcut not found in this section")') == 1
assert 'if (isDialogMessage && isShortcutInput && !altTab)' in pump
assert "msg.message == WM_SYSKEYDOWN && msg.wParam == 'S'" in pump
assert "msg.wParam == 'D'" not in pump
print('TEST75.3.8 lookup single verdict: static PASS')
