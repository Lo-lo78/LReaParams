#pragma once
#include "Navigator.h"
#include "ReaperApi.h"
#include <array>

namespace lrp {
enum class InputBackend { sdkAccelerator, mainThreadHook, ownedWindow };
class InputRouter {
public:
    explicit InputRouter(reaper_plugin_info_t* api, Navigator& navigator);
    ~InputRouter();
    bool start(InputBackend backend, HWND keyboardWindow = nullptr);
    // Called directly by the Lua-style keyboard window, on REAPER's UI thread.
    // Unknown keys remain inside that window instead of escaping into REAPER.
    bool enqueueOwnedKey(HWND window, UINT vk, bool repeat) noexcept;
    void select(Navigator& navigator) noexcept { stop(); navigator_ = &navigator; }
    void stop() noexcept;
    bool pop(Key& key) noexcept;
    bool exitRequested() const noexcept { return exitRequested_; }
    bool environmentSafe() const noexcept;
    void refreshAllowedWindows(HWND floating) noexcept;
    bool switchOwnedWindow(HWND keyboardWindow) noexcept;
private:
    static int translate(MSG*, accelerator_register_t*) noexcept;
    static LRESULT CALLBACK hook(int, WPARAM, LPARAM) noexcept;
    bool route(MSG&, bool removed) noexcept;
    bool safeTarget(HWND target) const noexcept;
    void requestExit() noexcept;
    reaper_plugin_info_t* api_;
    Navigator* navigator_;
    accelerator_register_t accelerator_{};
    HHOOK hook_{};
    HWND main_{}, originalRoot_{}, floating_{}, ownedWindow_{};
    DWORD threadId_{};
    bool registered_ = false, capturing_ = false, exitRequested_ = false, escapeHookOnly_ = false;
    std::array<HWND, 256> swallowed_{};
    std::array<Key, 128> queue_{};
    std::size_t head_ = 0, tail_ = 0;
    static InputRouter* current_;
};
}
