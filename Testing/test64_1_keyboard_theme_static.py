"""TEST64.1 FX Params Keyboard overlay: mapping, persistence, no shortcut losses.
This validates source structure only; test the native DLL with NVDA in REAPER.
"""
from pathlib import Path
r = Path(__file__).resolve().parents[1]
header = (r/'include/lrp/FxNavigator.h').read_text(encoding='utf-8')
fx = (r/'src/FxNavigator.cpp').read_text(encoding='utf-8')
order = (r/'src/FxNavigatorOrder.cpp').read_text(encoding='utf-8')
track = (r/'src/TrackNavigator.cpp').read_text(encoding='utf-8')
map_header = (r/'include/lrp/KeyboardTheme.h').read_text(encoding='utf-8')
assert '"1234567890QWERTYUIOPASDFGHJKLZXCVBNM"' in map_header
assert 'pageSize = 36' in map_header and 'contextCount = 14' in map_header
assert 'lrp_keyboard_themes_v1' in order
assert 'loadKeyboardThemes();' in order
assert 'keyboardThemes_ = keyboard::decode' in order
assert 'keyboardThemes_[context] = !previous;' in order
assert 'keyboard::encode(keyboardThemes_)' in order
assert 'keyboardThemes_[context] = previous;' in order
assert 'saveStructure();' in order[order.index('void FxNavigator::toggleKeyboardTheme()'):order.index('void FxNavigator::captureViewCursor()')]
assert 'currentViewIndex()' in order and 'groupSlot_ + 1' in order
assert '!editF7_ && !textEdit_' in order
assert '!searchMode_ && !recentMode_' in order
assert '!fxBrowserMode_ && !pinAudioMode_' in order
assert 'keyboardThemeActive()' in fx
assert 'k.vk == VK_F4 && !k.ctrl && !k.alt && !k.shift && !k.altGr' in fx
assert 'if (!k.repeat) toggleKeyboardTheme();' in fx
assert 'keyboard::pageTarget(viewPos_' in fx
assert 'if (target >= 0) positionChanged(target)' in fx
assert 'keyboard::keyTarget(viewPos_, keyIndex' in fx
assert 'if (target < 0) speech_("Empty")' in fx
assert 'if(k.alt||valueMode_||keyboardThemeActive())' in fx
assert '(valueMode_ && !clearAutomationConfirm_) || keyboardThemeActive()' in header
assert 'editF7_ ? L" - F7 Edit" : keyboardThemeActive() ? L" - Keyboard"' in fx
# Keyboard dispatch comes AFTER shortcuts, leaving each shared handler intact.
cutoff = fx.index('    // TEST64.1: the only Keyboard-specific gestures.')
for key in ['toggleBypass()', 'clearProjectDeltaSolo()', 'toggleDeltaSolo()',
            'browserMoveFx(', 'switchFx(', 'openFxMemories(false)',
            'handleAdvanced(k)', 'if (editF7_ && handleF7(k))',
            'k.vk=='F'', 'k.vk == VK_F7']:
    assert key in fx[:cutoff], key
assert 'if (k.ctrl && !k.shift && !k.alt &&' in fx[:cutoff]
assert "k.vk == VK_PRIOR || k.vk == VK_NEXT" in fx[:cutoff]
# Keyboard must not infect Track Params F4 or edit controller.
assert 'keyboardThemes_' not in track
f7_start = fx.index('    if (k.vk==VK_F7 && !k.ctrl && !k.alt && !k.shift)')
assert f7_start < fx.index('    if (editF7_ && handleF7(k))') < cutoff
print('TEST64.1 keyboard themes and shortcut isolation PASS (source-only)')
