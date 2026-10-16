"""0.0.43.5: transport shortcut gets consumed before REAPER Action List.
Static source audit only: this is not a runtime keyboard/REAPER test.
"""
from version_contract import version_at_least
from pathlib import Path
root=Path(__file__).resolve().parents[1]
router=(root/'src/InputRouter.cpp').read_text()
header=(root/'include/lrp/InputRouter.h').read_text()
fx=(root/'src/FxNavigator.cpp').read_text()
track=(root/'src/TrackNavigator.cpp').read_text()
old=(root/'Legacy/Speak FX Params - TrackTake Navigator.lua').read_text()
workflow=(root/'.github/workflows/build-windows.yml').read_text()
assert version_at_least(root, (0, 0, 43, 5))
assert 'JS_VKeys_Intercept' in old and 'transport_space_set_intercept' in old
assert 'bool interceptTransport(MSG&) noexcept;' in header
assert 'bool InputRouter::interceptTransport(MSG& message) noexcept' in router
assert 'SetWindowsHookExW(WH_GETMESSAGE, hook, nullptr, threadId_)' in router
owned=router[router.index('if (backend == InputBackend::ownedWindow) {'):router.index('if (GetWindowThreadProcessId(main_')]
assert 'current_ = this;' in owned and 'hook_ = SetWindowsHookExW(WH_GETMESSAGE' in owned
assert 'capturing_ = hook_ != nullptr;' in owned
intercept=router[router.index('bool InputRouter::interceptTransport('):router.index('bool InputRouter::enqueueOwnedKey(')]
for marker in ('message.wParam != VK_SPACE', 'swallowed_[VK_SPACE] = nullptr;',
               'GetKeyState(VK_CONTROL)', 'GetKeyState(VK_SHIFT)',
               'GetKeyState(VK_MENU)', 'environmentSafe()',
               'GetFocus() != ownedWindow_', '_wcsicmp(cls, L"EDIT")',
               'navigator_->accepts(key)', 'enqueueOwnedKey(message.hwnd, VK_SPACE, repeat)',
               'return route(message, true);'):
    assert marker in intercept, marker
hook=router[router.index('LRESULT CALLBACK InputRouter::hook('):]
assert 'self->interceptTransport(message)' in hook
assert 'self->swallowed_[VK_SPACE] == message.hwnd' in hook
assert 'message.message = WM_NULL;' in hook
assert hook.index('consumed = self->interceptTransport(message)') < hook.index('message.message = WM_NULL;')
assert 'else if (!self->ownedWindow_' in hook  # no double-dispatch to owned Win32 WndProc
assert 'if (!k.repeat)' in fx[fx.index('void FxNavigator::handle('):]
assert 'Main_OnCommand(40073, 0)' in fx and 'Main_OnCommand(40044, 0)' in fx
assert 'if(k.shift&&!k.ctrl&&!k.alt&&k.vk==VK_SPACE)' in (root/'src/FxNavigatorOrder.cpp').read_text()
assert 'Main_OnCommand(40073' not in track
assert 'Testing/test43_5_static.py' in workflow
print('0.0.43.5 Ctrl+Space event routing audit PASS (no REAPER runtime exercised)')
