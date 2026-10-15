"""Source-only contract checks. No native build or runtime FX Chain verification."""
from pathlib import Path
r=Path(__file__).resolve().parents[1]
s=(r/'src/Extension.cpp').read_text()
assert "msg->wParam == 'P'" in s
assert 'fixedFxChainShortcutMatches(MSG* msg)' in s
assert 'fixedFxChainShortcutMatches(msg) || actionShortcutMatches(msg)' in s
assert 'const int command = actions_[0].command; // FX Params ONLY' in s
assert 'if (index == 1 && isFocusedFxList()) index = 0;' not in s
assert 'GetDlgCtrlID(focus) != 1076' in s
assert 'GetTouchedOrFocusedFX(1,' in s
assert 'shortcutHelp()' in s
assert 'GetActionShortcutDesc(section, command' in s
assert '<accelerator' in s
assert 'SetWindowsHookEx' not in s
assert 'project(LReaParams VERSION ' in (r/'CMakeLists.txt').read_text()
print('TEST20 static contract PASS; native build and behavior not tested')
