#include "lrp/TitleProxy.h"
#include <algorithm>
#include <utility>

namespace lrp {
namespace {
std::wstring toWide(const std::string& text) {
    if (text.empty()) return {};
    int len = MultiByteToWideChar(CP_UTF8, MB_ERR_INVALID_CHARS, text.c_str(), -1, nullptr, 0);
    const UINT codepage = len > 0 ? CP_UTF8 : CP_ACP;
    if (len <= 0) len = MultiByteToWideChar(codepage, 0, text.c_str(), -1, nullptr, 0);
    if (len <= 0) return L"";
    std::wstring result(static_cast<size_t>(len), L'\0');
    if (!MultiByteToWideChar(codepage, 0, text.c_str(), -1, &result[0], len)) return L"";
    result.resize(static_cast<size_t>(len - 1));
    for (auto& c : result) if (c == L'\r' || c == L'\n' || c == L'\t') c = L' ';
    return result;
}
}

bool TitleProxy::ensureWindow() {
    if (window_ && IsWindow(window_) && edit_ && IsWindow(edit_)) return true;
    instance_ = GetModuleHandleW(nullptr);
    if (!classRegistered_) {
        WNDCLASSW wc{};
        wc.lpfnWndProc = windowProc;
        wc.hInstance = instance_;
        wc.lpszClassName = kClass;
        if (!RegisterClassW(&wc) && GetLastError() != ERROR_CLASS_ALREADY_EXISTS) return false;
        classRegistered_ = true;
    }
    window_ = CreateWindowExW(WS_EX_TOOLWINDOW, kClass, L"LReaParams",
        WS_POPUP | WS_CAPTION, -32000, -32000, 1, 1,
        host_, nullptr, instance_, this);
    if (!window_) return false;
    // Standard Windows EDIT is deliberately used instead of custom-drawn text:
    // NVDA can inspect its real caret with NVDA+Up, even off screen.
    edit_ = CreateWindowExW(0, L"EDIT", L"", WS_CHILD | WS_VISIBLE |
        ES_READONLY | ES_AUTOHSCROLL, 0, 0, 1, 1,
        window_, nullptr, instance_, nullptr);
    if (!edit_) { DestroyWindow(window_); window_ = nullptr; return false; }
    SetWindowLongPtrW(edit_, GWLP_USERDATA, reinterpret_cast<LONG_PTR>(this));
    SetLastError(0);
    const LONG_PTR old = SetWindowLongPtrW(edit_, GWLP_WNDPROC,
                                           reinterpret_cast<LONG_PTR>(&TitleProxy::editProc));
    if (!old && GetLastError()) {
        DestroyWindow(window_); window_ = nullptr; edit_ = nullptr; return false;
    }
    originalEditProc_ = reinterpret_cast<WNDPROC>(old);
    return true;
}

bool TitleProxy::activate(const std::wstring& title, const std::string& initialReviewLine,
                          std::function<void()> closeNavigator,
                          std::function<bool(UINT, bool)> keyboardKey) {
    hideAndRestore();
    if (!ensureWindow()) return false;
    originalForeground_ = GetForegroundWindow();
    originalFocus_ = GetFocus();
    closeNavigator_ = std::move(closeNavigator);
    keyboardKey_ = std::move(keyboardKey);
    title_ = title;
    reviewText_ = toWide(initialReviewLine);
    if (reviewText_.size() > 8192) reviewText_.resize(8192);
    // Populate the native review line BEFORE the EDIT receives focus.
    // Changing a focused EDIT immediately after activation caused NVDA to
    // announce the window, then an empty edit, then its changed text.
    SetWindowTextW(window_, title_.c_str());
    SetWindowTextW(edit_, reviewText_.c_str());
    SendMessageW(edit_, EM_SETSEL, 0, 0);
    ShowWindow(window_, SW_SHOW);
    SetForegroundWindow(window_);
    SetFocus(edit_);
    if (!active()) { hideAndRestore(); return false; }
    return true;
}

void TitleProxy::updateTitle(const std::wstring& title) {
    if (!window_ || !IsWindowVisible(window_) || title == title_) return;
    title_ = title;
    SetWindowTextW(window_, title_.c_str());
}
void TitleProxy::updateReviewLine(const std::string& utf8Text) {
    if (!edit_ || !IsWindowVisible(window_)) return;
    auto line = toWide(utf8Text);
    if (line.size() > 8192) line.resize(8192);
    if (line == reviewText_) return;
    reviewText_ = std::move(line);
    SetWindowTextW(edit_, reviewText_.c_str());
    // Keep the system caret on the single line. No selection is highlighted.
    SendMessageW(edit_, EM_SETSEL, 0, 0);
}
void TitleProxy::reassertFocusAfterNavigationKey() noexcept {
    if (!window_ || !edit_ || !IsWindowVisible(window_) || !IsWindowEnabled(host_)) return;
    HWND front = GetForegroundWindow();
    if (!front) return;
    DWORD pid = 0;
    if (GetWindowThreadProcessId(front, &pid) != GetCurrentThreadId() || pid != GetCurrentProcessId()) return;
    GUITHREADINFO gui{sizeof(gui)};
    if (!GetGUIThreadInfo(GetCurrentThreadId(), &gui)) return;
    if (gui.flags & (GUI_INMENUMODE | GUI_POPUPMENUMODE | GUI_SYSTEMMENUMODE | GUI_INMOVESIZE)) return;
    // Do not steal focus from a REAPER text-entry field or modal dialog.
    if (front != window_ && gui.hwndCaret) return;
    if (front != window_) SetForegroundWindow(window_);
    if (GetForegroundWindow() == window_ && GetFocus() != edit_) SetFocus(edit_);
}
void TitleProxy::hideAndRestore() noexcept {
    if (!window_) return;
    const bool ours = GetForegroundWindow() == window_;
    const HWND oldForeground = originalForeground_;
    const HWND oldFocus = originalFocus_;
    closeNavigator_ = {};
    keyboardKey_ = {};
    originalForeground_ = originalFocus_ = nullptr;
    if (IsWindowVisible(window_)) ShowWindow(window_, SW_HIDE);
    if (ours) {
        if (oldForeground && IsWindow(oldForeground)) SetForegroundWindow(oldForeground);
        else if (host_ && IsWindow(host_)) SetForegroundWindow(host_);
        if (oldFocus && IsWindow(oldFocus) && GetWindowThreadProcessId(oldFocus, nullptr) == GetCurrentThreadId())
            SetFocus(oldFocus);
    }
}
void TitleProxy::shutdown() noexcept {
    hideAndRestore();
    if (edit_ && IsWindow(edit_) && originalEditProc_)
        SetWindowLongPtrW(edit_, GWLP_WNDPROC, reinterpret_cast<LONG_PTR>(originalEditProc_));
    if (window_) { DestroyWindow(window_); window_ = nullptr; }
    edit_ = nullptr;
    originalEditProc_ = nullptr;
    if (classRegistered_) { UnregisterClassW(kClass, instance_); classRegistered_ = false; }
}
void TitleProxy::onF12(LPARAM) noexcept {
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
    if (msg == WM_NCDESTROY) SetWindowLongPtrW(hwnd, GWLP_USERDATA, 0);
    return DefWindowProcW(hwnd, msg, wp, lp);
}
LRESULT CALLBACK TitleProxy::editProc(HWND hwnd, UINT msg, WPARAM wp, LPARAM lp) noexcept {
    auto* self = reinterpret_cast<TitleProxy*>(GetWindowLongPtrW(hwnd, GWLP_USERDATA));
    if (!self || !self->originalEditProc_) return DefWindowProcW(hwnd, msg, wp, lp);
    if (msg == WM_GETDLGCODE) return DLGC_WANTALLKEYS;
    if ((msg == WM_KEYDOWN || msg == WM_SYSKEYDOWN) && wp == VK_F12) {
        if (!(lp & (1LL << 30))) self->onF12(lp);
        return 0;
    }
    if ((msg == WM_KEYUP || msg == WM_SYSKEYUP) && wp == VK_F12) return 0;
    if (msg == WM_KEYDOWN || msg == WM_SYSKEYDOWN) {
        // NVDA's own gesture interception happens before this window proc.
        // Navigation keys never modify the native read-only review line.
        try { if (self->keyboardKey_) self->keyboardKey_(static_cast<UINT>(wp), (lp & (1LL << 30)) != 0); }
        catch (...) {
            auto close = std::move(self->closeNavigator_);
            try { if (close) close(); } catch (...) {}
        }
        return 0;
    }
    if (msg == WM_KEYUP || msg == WM_SYSKEYUP || msg == WM_CHAR ||
        msg == WM_SYSCHAR || msg == WM_DEADCHAR || msg == WM_SYSDEADCHAR) return 0;
    if (msg == WM_CLOSE) {
        auto close = std::move(self->closeNavigator_);
        try { if (close) close(); else self->hideAndRestore(); }
        catch (...) { self->hideAndRestore(); }
        return 0;
    }
    return CallWindowProcW(self->originalEditProc_, hwnd, msg, wp, lp);
}
} // namespace lrp
