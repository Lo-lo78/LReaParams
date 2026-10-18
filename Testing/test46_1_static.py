"""0.0.46.1: FX track-navigation key routing contracts. Source only; no build."""
from pathlib import Path
from version_contract import version_at_least
r=Path(__file__).resolve().parents[1]
assert version_at_least(r,(0,0,46,1))
fx=(r/'src/FxNavigator.cpp').read_text(encoding='utf-8')
browser=(r/'src/FxNavigatorContexts.cpp').read_text(encoding='utf-8')
# Since TEST56.7 Ctrl+PageUp/Down reorders FX both in grid and browser.
assert "(k.vk=='W'||k.vk==VK_LEFT||k.vk==VK_RIGHT)) return true;" in fx
assert "k.vk==VK_PRIOR||k.vk==VK_NEXT||k.vk=='P'||k.vk=='B'" in fx
assert "k.vk==VK_PRIOR||k.vk==VK_NEXT" in fx
assert "browserMoveFx(k.vk == VK_PRIOR ? -1 : 1)" in fx
assert 'if (k.vk==VK_PRIOR || k.vk==VK_NEXT) {switchTrack' not in browser
# Preserve Ctrl+Up/Down for FX, Ctrl+Shift+Up/Down for tracks.
assert "if(k.ctrl && !k.alt && !k.shift && (k.vk==VK_UP||k.vk==VK_DOWN))" in fx
assert "if (k.ctrl && k.shift && !k.alt && (k.vk==VK_UP||k.vk==VK_DOWN))" in fx
# Plain PageUp/Down remain active in both parameter and browser navigation.
assert 'browserMove(k.vk==VK_PRIOR?-5:5)' in browser
assert 'k.vk==VK_PRIOR||k.vk==VK_NEXT' in fx
assert 'Parameter Library' not in (r/'src/Extension.cpp').read_text(encoding='utf-8')
print('TEST46.1 FX keyboard routing source contracts PASS')
