#pragma once
#include <windows.h>
#include <functional>
#include <string>

namespace lrp {
// Experimental accessibility-only top-level window, 1x1 px outside the desktop.
// It owns keyboard focus only while a navigator runs, so NVDA+T reports its
// real window title. It never overlays a plugin or changes the host caption.
// All operations are on REAPER's UI thread.
class TitleProxy final {
public:
    explicit TitleProxy(HWND host) noexcept : host_(host) {}
    ~TitleProxy() { shutdown(); }
    TitleProxy(const TitleProxy&) = delete;
    TitleProxy& operator=(const TitleProxy&) = delete;
    bool activate(const std::wstring& title, std::function<void()> closeNavigator);
    void updateTitle(const std::wstring& title);
    void hideAndRestore() noexcept;
    void shutdown() noexcept;
    bool active() const noexcept { return window_ && GetForegroundWindow() == window_; }
private:
    static LRESULT CALLBACK windowProc(HWND, UINT, WPARAM, LPARAM) noexcept;
    bool ensureWindow();
    void onF12(LPARAM keyData) noexcept;
    static constexpr const wchar_t* kClass = L"LReaParams_NvdaTitleProxy_v1";
    HWND host_{};
    HWND window_{};
    HWND originalForeground_{};
    HWND originalFocus_{};
    HINSTANCE instance_{};
    bool classRegistered_ = false;
    std::wstring title_;
    std::function<void()> closeNavigator_;
};
} // namespace lrp
