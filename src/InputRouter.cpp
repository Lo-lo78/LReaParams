#include "lrp/InputRouter.h"
#include "lrp/TransportMarkers.h"
#include <cwchar>
#include <cwctype>


namespace lrp {
namespace {
// Use the user's actual Windows keyboard layout, including shifted digits and
// OEM punctuation. VK codes (especially VK_OEM_*) are not printable characters.
// Flag 0x04 avoids altering the thread's dead-key state (Windows 10 1607+).
// No WM_CHAR is synthesized: that would double-dispatch native EDIT fields.
wchar_t printableKey(UINT vk) noexcept {
    if (vk == VK_SPACE || vk < '0' || vk > VK_OEM_CLEAR) return 0;
    BYTE state[256]{};
    if (!GetKeyboardState(state)) return 0;
    const HKL layout = GetKeyboardLayout(0);
    const UINT scan = MapVirtualKeyExW(vk, MAPVK_VK_TO_VSC, layout);
    if (!scan) return 0;
    wchar_t chars[4]{};
    const int length = ToUnicodeEx(vk, scan, state, chars, 4, 0x04, layout);
    // A single Unicode code unit, not a dead key or multi-character macro.
    if (length != 1 || chars[0] < 0x21 || chars[0] == 0x7f ||
        (chars[0] >= 0xd800 && chars[0] <= 0xdfff)) return 0;
    return chars[0];
}
}
InputRouter* InputRouter::current_ = nullptr;
InputRouter::InputRouter(reaper_plugin_info_t* api, Navigator& navigator) : api_(api), navigator_(&navigator), main_(api->hwnd_main) {
    accelerator_.translateAccel = translate; accelerator_.isLocal = true; accelerator_.user = this;
}
InputRouter::~InputRouter() { stop(); }
bool InputRouter::start(InputBackend backend, HWND keyboardWindow) {
    stop(); threadId_ = GetCurrentThreadId();
    if (backend == InputBackend::ownedWindow) {
        if (!keyboardWindow || !IsWindow(keyboardWindow) ||
            GetWindowThreadProcessId(keyboardWindow, nullptr) != threadId_ ||
            GetForegroundWindow() != GetAncestor(keyboardWindow, GA_ROOT) || GetFocus() != keyboardWindow ||
            !IsWindowEnabled(main_)) return false;
        ownedWindow_ = keyboardWindow;
        originalRoot_ = keyboardWindow;
        floating_ = navigator_->floatingWindow();
        exitRequested_ = false;
        // REAPER can translate Ctrl+Space as its own Main shortcut before the
        // focused Win32 child receives WM_KEYDOWN. The child WndProc alone is
        // therefore insufficient: one physical press could execute the Lua-
        // style command AND the Main-section command. Consume at queue removal.
        // This is a thread-local WH_GETMESSAGE hook, not a global keyboard hook.
        current_ = this;
        escapeHookOnly_ = true;
        hook_ = SetWindowsHookExW(WH_GETMESSAGE, hook, nullptr, threadId_);
        capturing_ = hook_ != nullptr;
        if (!capturing_) { stop(); return false; }
        return true;
    }
    if (GetWindowThreadProcessId(main_, nullptr) != threadId_) return false;
    originalRoot_ = GetAncestor(GetFocus(), GA_ROOT);
    floating_ = navigator_->floatingWindow();
    if (!originalRoot_) originalRoot_ = main_;
    if (originalRoot_ != main_ && originalRoot_ != floating_) {
        int tr = 0, item = -1, take = -1, fx = -1, state = 0;
        if (!GetTouchedOrFocusedFX(1, &tr, &item, &take, &fx, &state) || (state & 1) || !navigator_->contextUnchanged())
            originalRoot_ = main_;
    }
    // A modal window must never become the trusted navigation root.
    if (!IsWindowEnabled(main_)) return false;
    exitRequested_ = false; current_ = this;
    if (backend == InputBackend::sdkAccelerator) {
        registered_ = api_->Register("accelerator", &accelerator_) != 0;
        // Escape must be consumed before REAPER's native Escape command.
        // A thread-local WH_GETMESSAGE hook intercepts Escape and the
        // Ctrl+Space transport gesture before native REAPER accelerators.
        // All other navigation keys use the REAPER accelerator backend.
        escapeHookOnly_ = true;
        if (registered_) hook_ = SetWindowsHookExW(WH_GETMESSAGE, hook, nullptr, threadId_);
        capturing_ = registered_ && hook_ != nullptr;
    } else {
        escapeHookOnly_ = false;
        // Thread-specific hook: no WH_KEYBOARD_LL, no global/process injection, no window.
        hook_ = SetWindowsHookExW(WH_GETMESSAGE, hook, nullptr, threadId_);
        capturing_ = hook_ != nullptr;
    }
    if (!capturing_) { stop(); return false; }
    return true;
}
void InputRouter::stop() noexcept {
    capturing_ = false;
    if (registered_) { api_->Register("-accelerator", &accelerator_); registered_ = false; }
    if (hook_) { UnhookWindowsHookEx(hook_); hook_ = nullptr; }
    if (current_ == this) current_ = nullptr;
    swallowed_.fill(nullptr); head_ = tail_ = 0; originalRoot_ = floating_ = ownedWindow_ = nullptr;
    exitRequested_ = false; escapeHookOnly_ = false;
}
void InputRouter::requestExit() noexcept { capturing_ = false; exitRequested_ = true; head_ = tail_ = 0; }
void InputRouter::refreshAllowedWindows(HWND floating) noexcept { floating_ = floating; }
bool InputRouter::switchOwnedWindow(HWND keyboardWindow) noexcept {
    if (!capturing_ || !ownedWindow_ || !keyboardWindow || !IsWindow(keyboardWindow) ||
        GetWindowThreadProcessId(keyboardWindow, nullptr) != threadId_ ||
        GetForegroundWindow() != GetAncestor(keyboardWindow, GA_ROOT) ||
        GetFocus() != keyboardWindow) return false;
    ownedWindow_ = keyboardWindow;
    originalRoot_ = keyboardWindow;
    return true;
}
bool InputRouter::safeTarget(HWND target) const noexcept {
    if (!target || !IsWindow(target) || !IsWindowEnabled(main_)) return false;
    DWORD pid = 0;
    if (GetWindowThreadProcessId(target, &pid) != threadId_ || pid != GetCurrentProcessId()) return false;
    GUITHREADINFO info{sizeof(info)};
    if (!GetGUIThreadInfo(threadId_, &info) || (info.flags & (GUI_INMENUMODE | GUI_POPUPMENUMODE | GUI_SYSTEMMENUMODE | GUI_INMOVESIZE))) return false;
    // The owned native STATIC has no caret.  It still legitimately owns the
    // keyboard; never mistake it for another REAPER editable control.
    // Do not override it using GetTouchedOrFocusedFX (the TEST5 failure).
    if (ownedWindow_ && target == ownedWindow_)
        return GetFocus() == ownedWindow_ &&
            GetForegroundWindow() == GetAncestor(ownedWindow_, GA_ROOT);
    if (info.hwndCaret) return false;
    const auto root = GetAncestor(target, GA_ROOT);
    if (root != main_ && root != originalRoot_ && root != floating_) return false;
    for (HWND h = target; h; h = GetParent(h)) {
        wchar_t cls[256]{}; GetClassNameW(h, cls, 256);
        for (wchar_t& c : cls) c = static_cast<wchar_t>(std::towlower(c));
        if (std::wcsstr(cls, L"edit") || std::wcsstr(cls, L"combobox") || std::wcsstr(cls, L"scintilla")) return false;
        // FX chain itself may be #32770; nested modal dialogs may not.
        if (std::wcscmp(cls, L"#32770") == 0 && h != originalRoot_ && h != floating_) return false;
        if (h == root) break;
    }
    return true;
}
bool InputRouter::environmentSafe() const noexcept {
    DWORD pid = 0; GetWindowThreadProcessId(GetForegroundWindow(), &pid);
    return pid == GetCurrentProcessId() && safeTarget(GetFocus());
}
bool InputRouter::route(MSG& message, bool removed) noexcept {
    if (!removed) return false;
    const bool down = message.message == WM_KEYDOWN || message.message == WM_SYSKEYDOWN;
    const bool up = message.message == WM_KEYUP || message.message == WM_SYSKEYUP;
    if ((!down && !up) || message.wParam > 255) return false;
    const auto vk = static_cast<UINT>(message.wParam);
    if (up) {
        const HWND consumedFor = swallowed_[vk]; swallowed_[vk] = nullptr;
        return capturing_ && consumedFor && consumedFor == message.hwnd;
    }
    if (!capturing_) return false;
    // NVDA uses Insert or Numpad Insert as an NVDA modifier by default.
    // Do not treat an NVDA gesture such as NVDA+T as an unknown navigation key.
    if ((GetKeyState(VK_INSERT) & 0x8000) || (GetKeyState(VK_NUMPAD0) & 0x8000)) return false;
    // Bare F12 is deliberately unassigned and reserved for this extension.
    // Never forward it to OSARA/REAPER or close navigation. Ctrl+F12 and
    // Ctrl+Shift+F12 remain slot 12; Alt+F12 remains free for OSARA watchers.
    if (vk == VK_F12 && !(GetKeyState(VK_CONTROL) & 0x8000) &&
        !(GetKeyState(VK_MENU) & 0x8000) && !(GetKeyState(VK_SHIFT) & 0x8000)) {
        if (!environmentSafe() || !safeTarget(message.hwnd)) { requestExit(); return false; }
        swallowed_[vk] = message.hwnd;
        return true;
    }
    if (vk == VK_F12 && !(GetKeyState(VK_CONTROL) & 0x8000)) { requestExit(); return false; }
    if (vk == VK_CONTROL || vk == VK_SHIFT || vk == VK_MENU || vk == VK_LCONTROL || vk == VK_RCONTROL ||
        vk == VK_LSHIFT || vk == VK_RSHIFT || vk == VK_LMENU || vk == VK_RMENU) return false;
    if (!environmentSafe() || !safeTarget(message.hwnd)) { requestExit(); return false; }
    Key key{vk, (GetKeyState(VK_CONTROL) & 0x8000) != 0, (GetKeyState(VK_MENU) & 0x8000) != 0,
        (GetKeyState(VK_SHIFT) & 0x8000) != 0, (message.lParam & (1LL << 30)) != 0, message.hwnd};
    key.altGr = key.ctrl && key.alt && (GetKeyState(VK_RMENU) & 0x8000);
    if ((!key.ctrl && !key.alt) || key.altGr) key.character = printableKey(vk);
    if (!navigator_->accepts(key)) {
        // Phase 0 has a deliberately small map. Exit before handing any other command to REAPER.
        requestExit(); return false;
    }
    const auto next = (tail_ + 1) % queue_.size();
    if (next == head_) { requestExit(); return false; }
    queue_[tail_] = key; tail_ = next; swallowed_[vk] = message.hwnd; return true;
}
bool InputRouter::interceptTransport(MSG& message) noexcept {
    if (!capturing_ || message.wParam != VK_SPACE) return false;
    const bool down = message.message == WM_KEYDOWN || message.message == WM_SYSKEYDOWN;
    const bool up = message.message == WM_KEYUP || message.message == WM_SYSKEYUP;
    if (!down && !up) return false;

    // Consume the release even when Ctrl has already been released, but only
    // when this navigator consumed the corresponding physical key-down.
    if (up) {
        if (!swallowed_[VK_SPACE] || swallowed_[VK_SPACE] != message.hwnd) return false;
        if (ownedWindow_) {
            swallowed_[VK_SPACE] = nullptr;
            return true;
        }
        return route(message, true);
    }
    if (!(GetKeyState(VK_CONTROL) & 0x8000) ||
        (GetKeyState(VK_SHIFT) & 0x8000) ||
        (GetKeyState(VK_MENU) & 0x8000) ||
        (GetKeyState(VK_INSERT) & 0x8000) ||
        (GetKeyState(VK_NUMPAD0) & 0x8000)) return false;

    if (!ownedWindow_) {
        // Normal SDK accelerator mode: use the same validated queue as all
        // other navigation keys, but precede REAPER's native shortcut parser.
        return route(message, true);
    }

    // Native FX or Track keyboard owner: Ctrl+Space shares the REAPER
    // Play/Pause action. Never intercept inside a Win32 EDIT field.
    if (message.hwnd != ownedWindow_ || GetFocus() != ownedWindow_ ||
        !environmentSafe()) return false;
    wchar_t cls[64]{};
    GetClassNameW(ownedWindow_, cls, 64);
    if (_wcsicmp(cls, L"EDIT") == 0) return false;
    const bool repeat = (message.lParam & (1LL << 30)) != 0;
    Key key{VK_SPACE, true, false, false, repeat, message.hwnd};
    if (!navigator_->accepts(key)) return false;
    if (!enqueueOwnedKey(message.hwnd, VK_SPACE, repeat)) return false;
    swallowed_[VK_SPACE] = message.hwnd;
    return true;
}

bool InputRouter::enqueueOwnedKey(HWND window, UINT vk, bool repeat) noexcept {
    if (!capturing_ || !ownedWindow_ || window != ownedWindow_ ||
        GetCurrentThreadId() != threadId_ || !environmentSafe()) {
        requestExit(); return false;
    }
    // NVDA intercepts its own gestures. If an Insert-based gesture reaches
    // this window anyway, do not convert it to a navigation command.
    if ((GetKeyState(VK_INSERT) & 0x8000) || (GetKeyState(VK_NUMPAD0) & 0x8000))
        return true;
    if (vk == VK_SHIFT || vk == VK_CONTROL || vk == VK_MENU ||
        vk == VK_LSHIFT || vk == VK_RSHIFT || vk == VK_LCONTROL ||
        vk == VK_RCONTROL || vk == VK_LMENU || vk == VK_RMENU)
        return true;
    Key key{vk, (GetKeyState(VK_CONTROL) & 0x8000) != 0,
        (GetKeyState(VK_MENU) & 0x8000) != 0,
        (GetKeyState(VK_SHIFT) & 0x8000) != 0, repeat, window};
    key.altGr = key.ctrl && key.alt && (GetKeyState(VK_RMENU) & 0x8000);
    if ((!key.ctrl && !key.alt) || key.altGr) key.character = printableKey(vk);
    // A gfx.getchar-style keyboard owner does not close on an unsupported key
    // and never leaks such a key to the TCP, FX or project.
    if (!navigator_->accepts(key)) return true;
    const auto next = (tail_ + 1) % queue_.size();
    if (next == head_) { requestExit(); return false; }
    queue_[tail_] = key; tail_ = next;
    return true;
}
bool InputRouter::pop(Key& key) noexcept {
    if (head_ == tail_) return false;
    key = queue_[head_]; head_ = (head_ + 1) % queue_.size(); return true;
}
int InputRouter::translate(MSG* message, accelerator_register_t* record) noexcept {
    if (!message || !record || !record->user) return 0;
    auto* self = static_cast<InputRouter*>(record->user);
    return self->route(*message, true) ? 1 : 0;
}
LRESULT CALLBACK InputRouter::hook(int code, WPARAM param, LPARAM data) noexcept {
    auto* self = current_;
    if (code >= 0 && self && data && param == PM_REMOVE) {
        auto& message = *reinterpret_cast<MSG*>(data);
        const bool isSpace = message.wParam == VK_SPACE;
        const bool down = message.message == WM_KEYDOWN || message.message == WM_SYSKEYDOWN;
        const bool up = message.message == WM_KEYUP || message.message == WM_SYSKEYUP;
        const bool chordDown = isSpace && down &&
            (GetKeyState(VK_CONTROL) & 0x8000) &&
            !(GetKeyState(VK_SHIFT) & 0x8000) &&
            !(GetKeyState(VK_MENU) & 0x8000);
        const bool chordUp = isSpace && up &&
            self->swallowed_[VK_SPACE] == message.hwnd;
        bool consumed = false;
        // Intercept the exact F4 Alt+Home/End gesture at queue removal as
        // well: REAPER can consume WM_SYSKEYDOWN as a Main accelerator before
        // our focused TitleProxy STATIC/sliders receive it. No global hook.
        const bool altEdge = (message.wParam == VK_HOME || message.wParam == VK_END) &&
            ((down && (GetKeyState(VK_MENU) & 0x8000)) ||
             (up && self->swallowed_[static_cast<UINT>(message.wParam)] == message.hwnd));
        // In accelerator mode REAPER can otherwise execute its own action
        // for Ctrl+digits/Alt+Page before our extension receives the key.
        // Do not intercept unrelated combinations or native editing fields.
        const UINT vk = static_cast<UINT>(message.wParam);
        const Key shortcut{vk, (GetKeyState(VK_CONTROL) & 0x8000) != 0,
                           (GetKeyState(VK_MENU) & 0x8000) != 0,
                           (GetKeyState(VK_SHIFT) & 0x8000) != 0,
                           (message.lParam & (1LL << 30)) != 0, message.hwnd,
                           0, (GetKeyState(VK_RMENU) & 0x8000) != 0};
        const bool shortcutDown = down && isTransportMarkerShortcut(shortcut);
        const bool shortcutUp = up &&
            (vk == VK_PRIOR || vk == VK_NEXT || vk == 'I' || vk == 'O' ||
             (vk >= '0' && vk <= '9')) &&
            self->swallowed_[vk] == message.hwnd;
        if ((shortcutDown || shortcutUp) && self->navigator_ &&
            (shortcutUp || self->navigator_->accepts(shortcut))) {
            consumed = self->route(message, true);
        } else if (chordDown || chordUp) {
            // Run first even in accelerator and native focus-window modes:
            // REAPER must not also dispatch its Action List Ctrl+Space binding.
            consumed = self->interceptTransport(message);
        } else if (altEdge && self->navigator_ &&
                   self->navigator_->accepts(Key{static_cast<UINT>(message.wParam),
                     (GetKeyState(VK_CONTROL) & 0x8000) != 0,
                     (GetKeyState(VK_MENU) & 0x8000) != 0,
                     (GetKeyState(VK_SHIFT) & 0x8000) != 0,
                     (message.lParam & (1LL << 30)) != 0, message.hwnd})) {
            consumed = self->route(message, true);
        } else if (!self->ownedWindow_ &&
                   (!self->escapeHookOnly_ ||
                    ((down || up) && message.wParam == VK_ESCAPE))) {
            consumed = self->route(message, true);
        }
        if (consumed) {
            message.message = WM_NULL;
            message.wParam = 0;
            message.lParam = 0;
        }
    }
    return CallNextHookEx(nullptr, code, param, data);
}
} // namespace lrp
