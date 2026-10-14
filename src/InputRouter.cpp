#include "lrp/InputRouter.h"
#include <cwchar>
#include <cwctype>

namespace lrp {
InputRouter* InputRouter::current_ = nullptr;
InputRouter::InputRouter(reaper_plugin_info_t* api, Navigator& navigator) : api_(api), navigator_(&navigator), main_(api->hwnd_main) {
    accelerator_.translateAccel = translate; accelerator_.isLocal = true; accelerator_.user = this;
}
InputRouter::~InputRouter() { stop(); }
bool InputRouter::start(InputBackend backend) {
    stop(); threadId_ = GetCurrentThreadId();
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
        capturing_ = registered_;
    } else {
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
    swallowed_.fill(nullptr); head_ = tail_ = 0; originalRoot_ = floating_ = nullptr; exitRequested_ = false;
}
void InputRouter::requestExit() noexcept { capturing_ = false; exitRequested_ = true; head_ = tail_ = 0; }
void InputRouter::refreshAllowedWindows(HWND floating) noexcept { floating_ = floating; }
bool InputRouter::safeTarget(HWND target) const noexcept {
    if (!target || !IsWindow(target) || !IsWindowEnabled(main_)) return false;
    DWORD pid = 0;
    if (GetWindowThreadProcessId(target, &pid) != threadId_ || pid != GetCurrentProcessId()) return false;
    GUITHREADINFO info{sizeof(info)};
    if (!GetGUIThreadInfo(threadId_, &info) || (info.flags & (GUI_INMENUMODE | GUI_POPUPMENUMODE | GUI_SYSTEMMENUMODE | GUI_INMOVESIZE))) return false;
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
    // Give every F12 combination to OSARA. Never toggle help ourselves.
    if (vk == VK_F12) { requestExit(); return false; }
    if (vk == VK_CONTROL || vk == VK_SHIFT || vk == VK_MENU || vk == VK_LCONTROL || vk == VK_RCONTROL ||
        vk == VK_LSHIFT || vk == VK_RSHIFT || vk == VK_LMENU || vk == VK_RMENU) return false;
    if (!environmentSafe() || !safeTarget(message.hwnd)) { requestExit(); return false; }
    Key key{vk, (GetKeyState(VK_CONTROL) & 0x8000) != 0, (GetKeyState(VK_MENU) & 0x8000) != 0,
        (GetKeyState(VK_SHIFT) & 0x8000) != 0, (message.lParam & (1LL << 30)) != 0, message.hwnd};
    if (!navigator_->accepts(key)) {
        // Phase 0 has a deliberately small map. Exit before handing any other command to REAPER.
        requestExit(); return false;
    }
    const auto next = (tail_ + 1) % queue_.size();
    if (next == head_) { requestExit(); return false; }
    queue_[tail_] = key; tail_ = next; swallowed_[vk] = message.hwnd; return true;
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
        if (self->route(message, true)) { message.message = WM_NULL; message.wParam = 0; message.lParam = 0; }
    }
    return CallNextHookEx(nullptr, code, param, data);
}
}
