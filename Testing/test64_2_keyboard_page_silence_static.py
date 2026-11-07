"""TEST64.2+TEST65.1 - quiet empty slots and shared Page Up/Down value handling.
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
# No private Page handler: Keyboard uses the same adjustment as Standard Value.
assert 'nudge(' not in keyboard
assert 'VK_PRIOR' not in keyboard and 'VK_NEXT' not in keyboard
assert 'keyboard::pageTarget' in keyboard
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
print('TEST64.2+65.1 quiet slots, unified Page key and shortcut routing PASS')
