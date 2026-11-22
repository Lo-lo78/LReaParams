#!/usr/bin/env python3
"""TEST75.3.4 source invariants; does not substitute for Windows/NVDA runtime tests."""
from pathlib import Path
r=Path(__file__).resolve().parents[1]
p=(r/'src/Preferences.cpp').read_text(encoding='utf-8')
router=(r/'src/InputRouter.cpp').read_text(encoding='utf-8')
header=(r/'include/lrp/InputRouter.h').read_text(encoding='utf-8')
# Every F1..F12 gesture is eligible: F12 is no longer blanket-reserved.
capture=p.split('if (hwnd == st->capture) {',1)[1].split('if (st->currentScope == ShortcutScope::render)',1)[0]
assert 'F1..F12 (plain or with modifiers) are valid personal shortcuts.' in capture
assert 'vk == VK_F12 && !ctrl' not in capture
assert 'vk == VK_F10 || vk == VK_F11 || vk == VK_F12' not in capture
assert '(vk == VK_F1 && shift && !ctrl && !alt)' in capture # Shift+F1 stays reserved
# F12 does not get rejected on load; an assigned key must take precedence over
# the legacy unassigned F12 no-op/exit behavior across keyboard backends.
ini=p.split('for (size_t i = 0; i < p.shortcuts.size(); ++i) {',1)[1].split('const int renderCount',1)[0]
assert '(candidate.vk == VK_F12 && !candidate.ctrl)' not in ini
assert 'bool InputRouter::assignedF12(const Key& physical) const noexcept' in router
assert 'bool assignedF12(const Key& physical) const noexcept;' in header
assert 'const bool personalizedF12 = down && self->assignedF12(shortcut);' in router
assert 'swallowedRelease || personalizedF12' in router
assert router.count('!assignedF12(physical)') == 2
# Alt+S focuses lookup; Alt+R resets section, ONLY outside shortcut input.
assert 'L"&Reset section..."' in p
assert 'msg.wParam == \'S\'' in p and 'focusShortcutLookup(&state, static_cast<UINT>(msg.wParam));' in p
assert 'msg.wParam == \'R\'' in p and 'MAKEWPARAM(IDC_RESET_SECTION, BN_CLICKED)' in p
assert 'focused != state.lookup && !(state.capturing && focused == state.capture)' in p
# The shortcut input first bypasses Windows' dialog-mnemonic interpretation.
pump=p.split('const bool isShortcutInput = state.page == Page::shortcuts',1)[1]
assert pump.index('if (isDialogMessage && isShortcutInput && !altTab)') < pump.index('IsDialogMessageW(hwnd, &msg)')
lookup=p.split('if (hwnd == st->lookup) {',1)[1].split('if (hwnd == st->messages && alt',1)[0]
assert 'findShortcut(st, shortcut(vk' in lookup
assert 'vk == VK_F12' not in lookup and 'vk == \'S\'' not in lookup
# Enter on Reset asks the No-default confirmation; only OK commits changes.
assert 'focused == state.resetSection && msg.wParam == VK_RETURN' in p
assert 'SendMessageW(hwnd, WM_COMMAND, MAKEWPARAM(IDC_RESET_SECTION, BN_CLICKED)' in p
reset=p.split('void resetCurrentSection(',1)[1].split('// Selection changes',1)[0]
assert 'MB_YESNO | MB_ICONQUESTION | MB_DEFBUTTON2' in reset
assert 'if (answer != IDYES) return;' in reset
assert 'savePreferences(' not in reset
assert 'state.accepted ? std::make_optional(state.pending) : std::nullopt' in p
print('TEST75.3.4 F1-F12, lookup Alt+S, Reset Alt+R/Enter, transactional save: static PASS')
