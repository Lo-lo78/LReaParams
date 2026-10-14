#include "lrp/TitleProxy.h"
#include <utility>

namespace lrp {
bool TitleProxy::ensureWindow() {
    if (window_ && IsWindow(window_)) return true;
    instance_ = GetModuleHandleW(nullptr);
    if (!classRegistered_) {
        WNDCLASSW wc{};
        wc.lpfnWndProc = windowProc;
        wc.hInstance = instance_;
        wc.lpszClassName = kClass;
        if (!RegisterClassW(&wc)) return false;
        classRegistered_ = true;
    }
    // No WS_EX_NOACTIVATE: NVDA+T reports the active foreground window.
    // WS_EX_TOOLWINDOW keeps this tiny off-screen window out of Alt+Tab.
    window_ = CreateWindowExW(WS_EX_TOOLWINDOW, kClass, L"LReaParams",
                              WS_POPUP | WS_CAPTION, -32000, -32000, 1, 1,
                              host_, nullptr, instance_, this);
    return window_ != nullptr;
}

bool TitleProxy::activate(const std::wstring& title, std::function<void()> closeNavigator,
                          std::function<bool(UINT, bool)> keyboardKey) {
    hideAndRestore();
    if (!ensureWindow()) return false;
    originalForeground_ = GetForegroundWindow();
    originalFocus_ = GetFocus();
    closeNavigator_ = std::move(closeNavigator);
    keyboardKey_ = std::move(keyboardKey);
    title_ = title;
    SetWindowTextW(window_, title_.c_str());
    ShowWindow(window_, SW_SHOW);
    SetForegroundWindow(window_);
    SetFocus(window_);
    if (GetForegroundWindow() != window_ || GetFocus() != window_) {
        hideAndRestore();
        return false;
    }
    return true;
}

void TitleProxy::updateTitle(const std::wstring& title) {
    if (!window_ || !IsWindowVisible(window_) || title == title_) return;
    title_ = title;
    SetWindowTextW(window_, title_.c_str());
}

void TitleProxy::reassertFocusAfterNavigationKey() noexcept {
    if (!window_ || !IsWindowVisible(window_) || !IsWindowEnabled(host_)) return;
    // Respect switching to other applications and any REAPER modal dialogs.
    HWND front = GetForegroundWindow();
    if (!front) return;
    DWORD pid = 0;
    if (GetWindowThreadProcessId(front, &pid) != GetCurrentThreadId() ||
        pid != GetCurrentProcessId()) return;
    GUITHREADINFO gui{sizeof(gui)};
    if (!GetGUIThreadInfo(GetCurrentThreadId(), &gui) ||
        (gui.flags & (GUI_INMENUMODE | GUI_POPUPMENUMODE |
                      GUI_SYSTEMMENUMODE | GUI_INMOVESIZE)) || gui.hwndCaret)
        return;
    if (front != window_) SetForegroundWindow(window_);
    if (GetForegroundWindow() == window_ && GetFocus() != window_)
        SetFocus(window_);
}

void TitleProxy::hideAndRestore() noexcept {
    if (!window_) return;
    const bool foregroundOwned = GetForegroundWindow() == window_;
    const HWND previousForeground = originalForeground_;
    const HWND previousFocus = originalFocus_;
    closeNavigator_ = {};
    keyboardKey_ = {};
    originalForeground_ = originalFocus_ = nullptr;
    if (IsWindowVisible(window_)) ShowWindow(window_, SW_HIDE);
    // Never steal focus back if the user / remote collaborator clicked away.
    if (foregroundOwned) {
        if (previousForeground && IsWindow(previousForeground))
            SetForegroundWindow(previousForeground);
        else if (host_ && IsWindow(host_))
            SetForegroundWindow(host_);
        if (previousFocus && IsWindow(previousFocus)) {
            DWORD pid = 0;
            if (GetWindowThreadProcessId(previousFocus, &pid) == GetCurrentThreadId() && pid == GetCurrentProcessId())
                SetFocus(previousFocus);
        }
    }
}

void TitleProxy::shutdown() noexcept {
    hideAndRestore();
    if (window_) { DestroyWindow(window_); window_ = nullptr; }
    if (classRegistered_) { UnregisterClassW(kClass, instance_); classRegistered_ = false; }
}

void TitleProxy::onF12(LPARAM) noexcept {
    // OSARA's F12 shortcut belongs to REAPER. Restore host focus before
    // forwarding the key into REAPER's message pump (no SendInput/global hook).
    auto close = std::move(closeNavigator_);
    try { if (close) close(); else hideAndRestore(); }
    catch (...) { hideAndRestore(); }
    if (host_ && IsWindow(host_)) {
        const LPARAM sc = static_cast<LPARAM>(MapVirtualKeyW(VK_F12, MAPVK_VK_TO_VSC)) << 16;
        PostMessageW(host_, WM_KEYDOWN, VK_F12, sc | 1);
        PostMessageW(host_, WM_KEYUP, VK_F12, sc | 0xC0000001L);
    }
}

LRESULT CALLBACK TitleProxy::windowProc(HWND hwnd, UINT msg, WPARAM wp, LPARAM lp) noexcept {
    if (msg == WM_NCCREATE) {
        auto* info = reinterpret_cast<CREATESTRUCTW*>(lp);
        SetWindowLongPtrW(hwnd, GWLP_USERDATA, reinterpret_cast<LONG_PTR>(info->lpCreateParams));
    }
    auto* self = reinterpret_cast<TitleProxy*>(GetWindowLongPtrW(hwnd, GWLP_USERDATA));
    if (self) {
        if (msg == WM_GETDLGCODE) return DLGC_WANTALLKEYS;
        if ((msg == WM_KEYDOWN || msg == WM_SYSKEYDOWN) && wp == VK_F12) {
            if (!(lp & (1LL << 30))) self->onF12(lp);
            return 0;
        }
        if ((msg == WM_KEYUP || msg == WM_SYSKEYUP) && wp == VK_F12) return 0;
        if (msg == WM_KEYDOWN || msg == WM_SYSKEYDOWN) {
            // Direct keyboard ownership, like gfx.getchar in the legacy Lua.
            // No transient focus trip through REAPER's TCP or accelerators.
            try {
                if (self->keyboardKey_) self->keyboardKey_(
                    static_cast<UINT>(wp), (lp & (1LL << 30)) != 0);
            } catch (...) {
                auto close = std::move(self->closeNavigator_);
                try { if (close) close(); } catch (...) {}
            }
            return 0; // Unsupported keys stay inside the navigation window.
        }
        if (msg == WM_KEYUP || msg == WM_SYSKEYUP ||
            msg == WM_CHAR || msg == WM_SYSCHAR || msg == WM_DEADCHAR ||
            msg == WM_SYSDEADCHAR) return 0;
        if (msg == WM_CLOSE) {
            auto close = std::move(self->closeNavigator_);
            try { if (close) close(); else self->hideAndRestore(); }
            catch (...) { self->hideAndRestore(); }
            return 0;
        }
        if (msg == WM_NCDESTROY) SetWindowLongPtrW(hwnd, GWLP_USERDATA, 0);
    }
    return DefWindowProcW(hwnd, msg, wp, lp);
}
} // namespace lrp
