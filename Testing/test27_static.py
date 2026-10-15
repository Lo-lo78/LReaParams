"""TEST27 keyboard regression tests: static only; no compiler invoked."""
from pathlib import Path
root=Path(__file__).resolve().parents[1]
order=(root/'src/FxNavigatorOrder.cpp').read_text()
fx=(root/'src/FxNavigator.cpp').read_text()
router=(root/'src/InputRouter.cpp').read_text()
proxy=(root/'src/TitleProxy.cpp').read_text()
assert 'VERSION 0.0.28' in (root/'CMakeLists.txt').read_text()
assert 'if(k.alt&&k.shift&&!k.ctrl&&' in order
assert 'if(k.alt&&!k.ctrl&&!k.shift&&' not in order
assert 'if (!k.ctrl && k.alt && k.shift) return k.vk==VK_UP' in fx
assert 'if (!k.ctrl && k.alt && !k.shift) return k.vk==VK_UP' not in fx
assert 'if (k.ctrl && !k.alt && k.vk >= VK_F1 && k.vk <= VK_F12)' in fx
assert 'vk == VK_F12 && !(GetKeyState(VK_CONTROL) & 0x8000)' in router
assert 'swallowed_[vk] = message.hwnd;' in router
assert 'Bare F12 intentionally does nothing' in proxy
assert 'Bare F12 is a reserved no-op' in proxy
assert 'if(!(lp & (1LL<<30)))self->onF12(lp);' in proxy  # only Alt/Shift modified F12
assert 'F12 alone is reserved' in (root/'src/Extension.cpp').read_text()
print('TEST27 keyboard contracts PASS; native build and NVDA test pending')
