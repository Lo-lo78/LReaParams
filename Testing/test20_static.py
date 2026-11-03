"""Source-only TEST20 updated by TEST62.9 context shortcut change."""
from pathlib import Path
r=Path(__file__).resolve().parents[1]
s=(r/'src/Extension.cpp').read_text(encoding='utf-8')
assert "msg->wParam == 'P'" in s
assert 'fixedFxChainShortcutMatches(MSG* msg)' in s
assert '!fixedFxChainShortcutMatches(msg)' in s
assert 'actionShortcutMatches(msg)' not in s
assert '!(GetKeyState(VK_CONTROL) & 0x8000)' in s
assert '!(GetKeyState(VK_SHIFT) & 0x8000)' in s
assert '(GetKeyState(VK_MENU) & 0x8000)' in s
assert 'GetDlgCtrlID(focus) != 1076' in s
assert 'GetTouchedOrFocusedFX(1,' in s
assert 'shortcutHelp()' in s
assert '<accelerator' in s
assert 'SetWindowsHookEx' not in s
print('TEST20 revised: FX Chain Alt+P only; P is not intercepted by LReaParams')
