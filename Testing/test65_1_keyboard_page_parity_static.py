"""TEST65.1: Keyboard and Standard Value share identical step handling.

Source-routing checks: final behavior must also be confirmed on Windows/REAPER.
"""
from pathlib import Path
R=Path(__file__).resolve().parents[1]
fx=(R/'src/FxNavigator.cpp').read_text(encoding='utf-8')
step=(R/'include/lrp/ParameterStepSizing.h').read_text(encoding='utf-8')
header=(R/'include/lrp/FxNavigator.h').read_text(encoding='utf-8')
keyboard_start=fx.index('    // TEST64.1: the only Keyboard-specific gestures.')
keyboard_end=fx.index('    // TEST62.9: incrementally match typed words', keyboard_start)
keyboard=fx[keyboard_start:keyboard_end]
value_start=fx.index('    // TEST65.1: ONE value-key dispatch')
value_end=fx.index('    if(visible_.empty())return;', value_start)
value=fx[value_start:value_end]
assert 'VK_PRIOR' not in keyboard and 'VK_NEXT' not in keyboard
assert 'nudge(' not in keyboard, 'Keyboard must not have a private nudge'
assert 'keyboard::pageTarget' in keyboard and 'keyboard::keyTarget' in keyboard
assert 'if(k.alt||valueMode_||keyboardThemeActive())' in value
assert 'const bool big=k.vk==VK_PRIOR||k.vk==VK_NEXT;' in value
assert 'else nudge(direction,big);' in value
assert 'const double step = parameter_step::amount(known, normal, large, big, stepScale_);' in fx
assert 'if (keyboardThemeActive())' in fx
assert '((valueMode_ && !clearAutomationConfirm_) || keyboardThemeActive())' in header
for name in ('toggleBypass();return;', 'clearProjectDeltaSolo()', 'switchFx(',
             'browserMoveFx(', 'if (editF7_ && handleF7(k)) return;'):
    assert name in fx[:keyboard_start], name
assert 'k.vk == VK_DOWN ? 1 : -1' in keyboard
print('TEST65.1 keyboard/Value Page and arrow parity PASS')
