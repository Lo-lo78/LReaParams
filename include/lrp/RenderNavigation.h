#pragma once

// TEST74.5: bidirectional focus-only Render navigation and dedicated sample rate.
// No parameter setting, button activation, render action, or disk persistence.
#ifdef _WIN32
#ifndef WIN32_LEAN_AND_MEAN
#define WIN32_LEAN_AND_MEAN
#endif
#include <windows.h>
#include <functional>
#include <array>
#include <map>
#include <string>
#include <vector>

namespace lrp {
class RenderNavigation {
public:
    explicit RenderNavigation(HWND reaperMain,
        std::function<void(const std::string&)> speak = {});
    ~RenderNavigation();
    bool start() noexcept;
    void stop() noexcept;
    void tick() noexcept;

private:
    struct Control {
        HWND hwnd{};
        std::wstring name;
        UINT id{};
        bool format = false;
        bool tab = false;
        int tabPage = -1;
    };
    static thread_local RenderNavigation* active_;
    static LRESULT CALLBACK keyHook(int, WPARAM, LPARAM);
    static LRESULT CALLBACK searchWindowProc(HWND, UINT, WPARAM, LPARAM);
    static LRESULT CALLBACK searchEditProc(HWND, UINT, WPARAM, LPARAM);
    bool onKey(MSG&);
    std::string describeHelpKey(UINT vk, bool ctrl, bool alt, bool shift);
    void announceHelp(const std::string& message) noexcept;
    HWND renderFromFocus(HWND focus) const;
    bool isRender(HWND candidate) const;
    bool isInRoot(HWND child) const noexcept;
    void refreshControls(HWND root);
    std::wstring controlName(HWND child, bool format) const;
    std::wstring nearbyLabel(HWND child) const;
    void rebuildAccelerators();
    bool jumpKey(wchar_t letter);
    bool jumpKeyDirection(wchar_t letter, int direction);
    bool focusControl(HWND target) noexcept;
    std::vector<Control> results(const std::wstring& query);
    bool searchStep(int direction);
    void findDialog();
    void finishFind(bool accept);
    void closeFind() noexcept;
    HWND findFormatTab() const;
    bool focusPageTab(int page);
    int selectedFormatPage() const; // Read-only: never selects a tab or changes render settings.
    void resetDialog() noexcept;
    bool namedFocus(const wchar_t* name) noexcept;
    std::function<void(const std::string&)> speak_;
    HWND main_{};
    DWORD thread_{};
    HHOOK hook_{};
    HWND render_{};
    mutable HWND cachedFormatTab_{};
    HWND find_{};
    HWND edit_{};
    HWND focusBeforeFind_{};
    WNDPROC originalEditProc_{};
    bool inJump_ = false;
    bool helpMode_ = false;
    HWND helpFocus_{};
    std::array<HWND, 256> helpReleases_{};
    std::wstring query_;
    HWND lastResult_{};
    int lastResultPage_ = -1;
    std::vector<Control> controls_;
    std::map<wchar_t, std::vector<HWND>> accelerators_;
    std::map<wchar_t, size_t> cycle_;
};
} // namespace lrp
#endif
