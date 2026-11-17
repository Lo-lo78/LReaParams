#pragma once
#include <windows.h>
#include <functional>
#include <string>

namespace lrp {
// Keyboard owner in the style of the original Lua gfx window.
// A top-level 1px window keeps the NVDA+T title; its focused native STATIC
// child has no system text caret (no unsolicited NVDA character echo).
// The focused STATIC's caption never changes. Its subclass responds to
// explicit WM_GETTEXT queries with the current parameter and value without
// raising text-change notifications that could duplicate OSARA speech.
// NVDA+Up is experimental without an EDIT caret; Ctrl+R always reviews via OSARA.
class TitleProxy final {
public:
    explicit TitleProxy(HWND host) noexcept : host_(host) {}
    ~TitleProxy() { shutdown(); }
    TitleProxy(const TitleProxy&) = delete;
    TitleProxy& operator=(const TitleProxy&) = delete;
    bool activate(const std::wstring& title, const std::string& initialReviewLine,
                  std::function<void()> closeNavigator,
                  std::function<bool(HWND, UINT, bool)> keyboardKey);
    HWND hwnd() const noexcept { return nativeEditMode_ ? nativeEdit_ : sliderMode_ ? slider_ : edit_; }
    void syncTextControl(bool enabled, const std::string& title, const std::string& initialValue);
    std::string textValue() const;
    void syncValueControl(bool valueMode, const std::string& parameter, double position);
    void updateTitle(const std::wstring& title);
    void updateReviewLine(const std::string& utf8Text);
    void reassertFocusAfterNavigationKey() noexcept;
    void hideAndRestore() noexcept;
    void shutdown() noexcept;
    bool active() const noexcept { return window_ && edit_ && IsWindow(window_) &&
        GetForegroundWindow() == window_ && GetFocus() == hwnd(); }
private:
    static LRESULT CALLBACK windowProc(HWND, UINT, WPARAM, LPARAM) noexcept;
    static LRESULT CALLBACK editProc(HWND, UINT, WPARAM, LPARAM) noexcept;
    static LRESULT CALLBACK sliderProc(HWND, UINT, WPARAM, LPARAM) noexcept;
    static LRESULT CALLBACK nativeEditProc(HWND, UINT, WPARAM, LPARAM) noexcept;
    LRESULT dispatchKeyOwner(HWND hwnd, UINT msg, WPARAM wp, LPARAM lp, WNDPROC original) noexcept;
    bool ensureWindow();
    void onF12(LPARAM keyData) noexcept;
    static constexpr const wchar_t* kClass = L"LReaParams_ReviewWindow_v2";
    HWND host_{};
    HWND window_{};
    HWND edit_{};
    HWND slider_{};
    HWND nativeEdit_{};
    HWND nativeLabel_{};
    HWND originalForeground_{};
    HWND originalFocus_{};
    HINSTANCE instance_{};
    WNDPROC originalEditProc_{};
    WNDPROC originalSliderProc_{};
    WNDPROC originalNativeEditProc_{};
    bool sliderMode_ = false;
    bool nativeEditMode_ = false;
    bool classRegistered_ = false;
    std::wstring title_;
    std::wstring reviewText_;
    std::wstring sliderLabel_;
    std::function<void()> closeNavigator_;
    std::function<bool(HWND, UINT, bool)> keyboardKey_;
};
} // namespace lrp
