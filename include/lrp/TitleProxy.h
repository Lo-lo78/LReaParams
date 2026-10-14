#pragma once
#include <windows.h>
#include <functional>
#include <string>

namespace lrp {
// Lua gfx.init-style keyboard owner: offscreen, titled, never covers a plugin.
// Unlike TEST5 it delivers keys directly from its window procedure, rather
// than relying on a REAPER accelerator or a WH_GETMESSAGE hook.
// All operations are on REAPER's UI thread.
class TitleProxy final {
public:
    explicit TitleProxy(HWND host) noexcept : host_(host) {}
    ~TitleProxy() { shutdown(); }
    TitleProxy(const TitleProxy&) = delete;
    TitleProxy& operator=(const TitleProxy&) = delete;
    bool activate(const std::wstring& title, std::function<void()> closeNavigator,
                  std::function<bool(UINT, bool)> keyboardKey);
    HWND hwnd() const noexcept { return window_; }
    // Called after a key changes an FX: some plug-ins steal focus on parameter set.
    void reassertFocusAfterNavigationKey() noexcept;
    void updateTitle(const std::wstring& title);
    void hideAndRestore() noexcept;
    void shutdown() noexcept;
    bool active() const noexcept { return window_ && IsWindow(window_) &&
        GetForegroundWindow() == window_ && GetFocus() == window_; }
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
    std::function<bool(UINT, bool)> keyboardKey_;
};
} // namespace lrp
