"""Test64.3: both Value and Keyboard use the same monotonic step function."""
from pathlib import Path
r=Path(__file__).resolve().parents[1]
fx=(r/'src/FxNavigator.cpp').read_text(encoding='utf-8')
order=(r/'src/FxNavigatorOrder.cpp').read_text(encoding='utf-8')
steps=(r/'include/lrp/ParameterStepSizing.h').read_text(encoding='utf-8')
assert fx.count('parameter_step::amount(known, normal, large, big,') == 1
assert 'const double step = parameter_step::amount(known, normal, large, big, stepScale_);' in fx
assert 'void FxNavigator::nudgeSelectedF7(int direction,bool big)' in fx # F7 multi edit unchanged
assert fx.count('else nudge(direction,big);') == 1
assert 'big=k.vk==VK_PRIOR||k.vk==VK_NEXT;' in fx
assert 'else nudge(direction,big);' in fx
assert 'large > arrow' in steps and 'arrow * 10.0' in steps
assert '2.0, std::clamp(userStepScale, -10, 10)' in steps
assert 'lrp_keyboard_themes_v1' in order
print('TEST64.3 Page/Value/Keyboard shared step calibration PASS')
