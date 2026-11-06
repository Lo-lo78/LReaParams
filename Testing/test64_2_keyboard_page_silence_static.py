"""TEST64.2 - quiet empty slots and explicit keyboard Page Up/Down value handling.
Checks structural code invariants; Windows/NVDA integration still requires real testing.
"""
from pathlib import Path
r = Path(__file__).resolve().parents[1]
fx = (r/'src/FxNavigator.cpp').read_text(encoding='utf-8')
proxy = (r/'src/TitleProxy.cpp').read_text(encoding='utf-8')
order = (r/'src/FxNavigatorOrder.cpp').read_text(encoding='utf-8')
start = fx.index('    // TEST64.1: the only Keyboard-specific gestures.')
end = fx.index('    // TEST62.9: incrementally match typed words', start)
keyboard = fx[start:end]
assert 'if (target < 0) return;' in keyboard
assert 'if (target < 0) speech_("Empty")' not in keyboard
assert 'if (target == viewPos_) announce();' in keyboard
assert 'else positionChanged(target);' in keyboard
assert 'k.vk == VK_PRIOR || k.vk == VK_NEXT' in keyboard
assert 'nudge(k.vk == VK_PRIOR ? 1 : -1, true)' in keyboard
assert keyboard.index('nudge(k.vk == VK_PRIOR ? 1 : -1, true)') < keyboard.index('keyboard::pageTarget')
assert 'k.vk == VK_DOWN ? 1 : -1' in keyboard
assert 'if (msg == WM_GETDLGCODE && hwnd == slider_)' in proxy
assert 'DLGC_WANTALLKEYS | DLGC_WANTARROWS' in proxy
assert 'if (keyboardKey_) keyboardKey_' in proxy  # no parallel value engine
# Commands remain shared and ordered before Keyboard logic.
for snippet in ['toggleBypass();return;', 'clearProjectDeltaSolo()', 'browserMoveFx(',
                'switchFx(', 'if (editF7_ && handleF7(k)) return;',
                'toggleKeyboardTheme();']:
    assert snippet in fx[:start], snippet
assert 'lrp_keyboard_themes_v1' in order
print('TEST64.2 quiet empty slots, Page keys, shared shortcut handling PASS')
