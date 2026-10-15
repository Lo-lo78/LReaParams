#pragma once
#include <windows.h>
#include <functional>
#include <string>

namespace lrp {
// Keyboard owner in the style of the original Lua gfx window.
// A top-level 1px window keeps the NVDA+T title; its focused native STATIC
// child has no system text caret (no unsolicited NVDA character echo).
// It exposes the current parameter as native accessible text. NVDA+Up is
// experimental without an EDIT caret; Ctrl+R repeats the current item via OSARA.
class TitleProxy final {
public:
    explicit TitleProxy(HWND host) noexcept : host_(host) {}
    ~TitleProxy() { shutdown(); }
    TitleProxy(const TitleProxy&) = delete;
    TitleProxy& operator=(const TitleProxy&) = delete;
    bool activate(const std::wstring& title, const std::string& initialReviewLine,
                  std::function<void()> closeNavigator,
                  std::function<bool(UINT, bool)> keyboardKey);
    HWND hwnd() const noexcept { return edit_; } // non-editable focus owner for InputRouter
    void updateTitle(const std::wstring& title);
    void updateReviewLine(const std::string& utf8Text);
    void reassertFocusAfterNavigationKey() noexcept;
    void hideAndRestore() noexcept;
    void shutdown() noexcept;
    bool active() const noexcept { return window_ && edit_ && IsWindow(window_) &&
        GetForegroundWindow() == window_ && GetFocus() == edit_; }
private:
    static LRESULT CALLBACK windowProc(HWND, UINT, WPARAM, LPARAM) noexcept;
    static LRESULT CALLBACK editProc(HWND, UINT, WPARAM, LPARAM) noexcept;
    bool ensureWindow();
    void onF12(LPARAM keyData) noexcept;
    static constexpr const wchar_t* kClass = L"LReaParams_ReviewWindow_v2";
    HWND host_{};
    HWND window_{};
    HWND edit_{};
    HWND originalForeground_{};
    HWND originalFocus_{};
    HINSTANCE instance_{};
    WNDPROC originalEditProc_{};
    bool classRegistered_ = false;
    std::wstring title_;
    std::wstring reviewText_;
    std::function<void()> closeNavigator_;
    std::function<bool(UINT, bool)> keyboardKey_;
};
} // namespace lrp
