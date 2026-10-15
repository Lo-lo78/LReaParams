#include "lrp/ReaperApi.h"
#include "lrp/FxNavigator.h"
#include "lrp/TrackNavigator.h"
#include "lrp/InputRouter.h"
#include "lrp/TitleProxy.h"
#include "lrp/Storage.h"
#include <shellapi.h>
#include <array>
#include <memory>
#include <string>
#include <stdexcept>
#include <cctype>
#include <algorithm>

namespace lrp {
namespace {
class Extension;
std::unique_ptr<Extension> app;
bool actionHook(KbdSectionInfo*, int, int, int, int, HWND) noexcept;
int toggleHook(int) noexcept;
void menuHook(const char*, void*, int) noexcept;
void timerHook() noexcept;
int fxChainShortcutHook(MSG*, accelerator_register_t*) noexcept;
struct Action {
    const char* id;
    const char* description;
    const wchar_t* menu;
    gaccel_register_t accel{};
    int command{};
    bool registered = false;
};
class Extension {
public:
    explicit Extension(reaper_plugin_info_t* info) : info_(*info), navigator_([this](const std::string& text) { speak(text); }), trackNavigator_([this](const std::string& text) { speak(text); }), input_(&info_, navigator_), titleProxy_(info->hwnd_main) {}
    ~Extension() { shutdown(); }
    void init() {
        if (REAPERAPI_LoadAPI(info_.GetFunc) != 0) throw std::runtime_error("Required REAPER API missing");
        mainThread_ = GetCurrentThreadId();
        const char* path = GetResourcePath(); if (!path || !*path) throw std::runtime_error("No resource path");
        resource_ = fs::u8path(path);
        navigator_.setResourceRoot(resource_);
        for (auto& a : actions_) {
            a.command = info_.Register("command_id", const_cast<char*>(a.id));
            if (a.command <= 0 || a.command > 65535) throw std::runtime_error("Cannot register action ID");
            a.accel.accel.cmd = static_cast<WORD>(a.command); a.accel.desc = a.description;
            a.registered = info_.Register("gaccel", &a.accel) != 0;
            if (!a.registered) throw std::runtime_error("Cannot register action");
        }
        // The FX chain can consume letter keys before the Main section sees them.
        // The key bridge only activates on REAPER's focused FX list (ID 1076).
        // Ctrl+Shift+P is its explicit context shortcut; all other FX keys
        // come only from the user's Main Action List bindings for FX Params.
        fxChainAccel_.translateAccel = fxChainShortcutHook;
        fxChainAccel_.isLocal = true;
        fxChainAccel_.user = this;
        fxChainAccelRegistered_ = info_.Register("<accelerator", &fxChainAccel_) != 0;
        hookRegistered_ = info_.Register("hookcommand2", reinterpret_cast<void*>(actionHook)) != 0;
        toggleRegistered_ = info_.Register("toggleaction", reinterpret_cast<void*>(toggleHook)) != 0;
        menuRegistered_ = info_.Register("hookcustommenu", reinterpret_cast<void*>(menuHook)) != 0;
        timerRegistered_ = info_.Register("timer", reinterpret_cast<void*>(timerHook)) != 0;
        if (!hookRegistered_ || !toggleRegistered_ || !menuRegistered_ || !timerRegistered_ || !fxChainAccelRegistered_) throw std::runtime_error("Callback registration failed");
        AddExtensionsMainMenu();
        importer_.start(resource_); // no REAPER APIs are called by this worker
    }
    bool shortcutHelp() const {
        const auto query = reinterpret_cast<bool(*)()>(info_.GetFunc("osara_isShortcutHelpEnabled"));
        return !query || query(); // absence means do not intercept
    }
    bool speechAvailable() const { return info_.GetFunc("osara_outputMessage") != nullptr; }
    void speak(const std::string& text) {
        if (GetCurrentThreadId() != mainThread_) return;
        auto output = reinterpret_cast<void(*)(const char*)>(info_.GetFunc("osara_outputMessage"));
        if (output && !text.empty()) output(text.c_str());
    }
    void exitNavigation(bool announce) {
        const bool wasActive = current_ && current_->active();
        input_.stop(); titleProxy_.hideAndRestore(); titleProxyActive_ = false;
        navigator_.end(); trackNavigator_.end(); current_ = nullptr;
        refreshToggles();
        if (announce && wasActive) speak("LReaParams navigation off");
    }
    void fail() noexcept {
        // Fail open at the ABI boundary: unregister capture, discard queued commands.
        input_.stop(); titleProxy_.hideAndRestore(); titleProxyActive_ = false;
        navigator_.end(); trackNavigator_.end(); current_ = nullptr;
        if (RefreshToolbar2 && GetCurrentThreadId() == mainThread_) refreshToggles();
        OutputDebugStringW(L"LReaParams: navigation stopped after a callback failure.\n");
    }
    void refreshToggles() const {
        for (int i : {0, 1}) if (actions_[i].command) RefreshToolbar2(0, actions_[i].command);
    }
    int toggle(int command) const noexcept {
        if (command == actions_[0].command) return current_ == &navigator_ && navigator_.active() && !navigator_.isMemoryManager() ? 1 : 0;
        if (command == actions_[1].command) return current_ == &trackNavigator_ && trackNavigator_.active() ? 1 : 0;
        if (command == actions_[2].command) return 0;
        if (command == actions_[9].command) return titleModeEnabled_ ? 1 : 0;
        return -1;
    }
    bool action(int command) {
        std::size_t index = actions_.size();
        for (std::size_t i = 0; i < actions_.size(); ++i) if (actions_[i].command == command) { index = i; break; }
        if (index == actions_.size()) return false;
        // Let OSARA announce shortcut help; do not execute any of our actions in help mode.
        if (shortcutHelp() && info_.GetFunc("osara_isShortcutHelpEnabled")) return false;
        switch (index) {
        case 0: case 1: {
            Navigator* desired = index == 0 ? static_cast<Navigator*>(&navigator_) : static_cast<Navigator*>(&trackNavigator_);
            if (current_ == desired && current_->active()) { exitNavigation(true); break; }
            exitNavigation(false);
            if (!speechAvailable() || !info_.GetFunc("osara_isShortcutHelpEnabled")) {
                ShowMessageBox("LReaParams requires OSARA with outputMessage and isShortcutHelpEnabled exports. No keyboard capture was installed.", "LReaParams", 0); break;
            }
            if (desired->begin()) launchNavigator(desired);
            break;
        }
        case 2:
            exitNavigation(false);
            speak("Parameter Library has not yet been migrated. Imported library files are preserved in LReaParams Params.");
            break;
        case 3:
            exitNavigation(false);
            announceImport_ = true;
            speak(importer_.start(resource_) ? "Import started" : "Import already running");
            break;
        case 4: {
            exitNavigation(false);
            const auto root = resource_ / L"LReaParams";
            const auto result = reinterpret_cast<INT_PTR>(ShellExecuteW(info_.hwnd_main, L"open", root.c_str(), nullptr, nullptr, SW_SHOWNORMAL));
            if (result <= 32) speak("Cannot open data folder. Initial import may still be running.");
            break;
        }
        case 5: {
            exitNavigation(false);
            const int answer = MessageBoxW(info_.hwnd_main,
                L"Native test keyboard backend, current REAPER session only.\n\nYes: main REAPER thread hook (WH_GETMESSAGE).\nNo: REAPER SDK accelerator plus Escape-only hook (default).\nCancel: keep current setting.\n\nCapture is confined to REAPER's main thread and active navigator.",
                L"LReaParams Settings", MB_YESNOCANCEL | MB_ICONINFORMATION);
            if (answer == IDYES) backend_ = InputBackend::mainThreadHook;
            else if (answer == IDNO) backend_ = InputBackend::sdkAccelerator;
            break;
        }
        case 6:
            exitNavigation(false);
            ShowMessageBox("LReaParams 0.0.22 TEST21 OUTSIDE F7 FX COMMANDS\n\n"
                "FX: Ctrl+Up/Down changes FX. Ctrl+Shift+Up/Down switches to tracks with FX, restoring the last FX and parameter per track.\n"
                "FX: Ctrl+L Plugin / Custom Order, F7 edits Custom Order; Shift+Space selects, Ctrl+X/C/V moves or copies, Ctrl+Delete hides.\n"
                "FX: F1/F2 grid height. Ctrl+Home/End absolute. Alt+Left/Right steps -10 to +10.\n"
                "Track: Left/Right and NVDA+Up review parameter and value only; Up/Down changes track and speaks its name. Ctrl+R reviews full context.\n"
                "Track: F1 rows; F2/F3 only when sends/receives exist. Alt+Left/Right adjusts continuous steps.\n"
                "A native Windows trackbar owns keyboard focus in Value; Grid retains the quiet STATIC review label.\n"
                "NVDA+T: FX Params - track - FX name; Track Params - track (and page for Sends/Receives). NVDA+Up queries parameter and value.\n"
                "F12 is forwarded back to REAPER for OSARA shortcut help (verify in REAPER).\n"
                "Use 'Lua-style keyboard window (1px)' to disable this focus mode if necessary.\n\n"
                "F8 opens the seven-column FX Memories navigator. Advanced MIDI CC and Default reset operations are protected until fully migrated.", "About LReaParams", 0);
            break;
        case 7: {
            // Dedicated REAPER action opens the same Lua F8 manager, not a
            // second profile editor. Use the shared FX navigator and focus owner.
            exitNavigation(false);
            if (!speechAvailable() || !info_.GetFunc("osara_isShortcutHelpEnabled")) {
                speak("FX Memories requires OSARA");break;
            }
            if(navigator_.begin() && navigator_.openFxMemories(true))
                launchNavigator(&navigator_);
            break;
        }
        case 8:
            exitNavigation(false);
            speak("LReaParams - Track Memories. Memory management is reserved for a later test; no memory was changed.");
            break;
        case 9:
            exitNavigation(false);
            titleModeEnabled_ = !titleModeEnabled_;
            speak(titleModeEnabled_ ? "Lua-style keyboard window enabled" : "Lua-style keyboard window disabled");
            break;
        default: break;
        }
        return true;
    }
    // This uses the same focused-FX query that OSARA uses. Restrict to the
    // native FX selection list, NOT the VST UI or any user-editable control.
    bool isFocusedFxList() const noexcept {
        if (GetCurrentThreadId() != mainThread_ || !IsWindowEnabled(info_.hwnd_main)) return false;
        HWND focus = GetFocus();
        if (!focus || GetDlgCtrlID(focus) != 1076) return false;
        DWORD pid = 0;
        if (GetWindowThreadProcessId(focus, &pid) != mainThread_ || pid != GetCurrentProcessId()) return false;
        GUITHREADINFO threadInfo{sizeof(threadInfo)};
        if (!GetGUIThreadInfo(mainThread_, &threadInfo) ||
            (threadInfo.flags & (GUI_INMENUMODE | GUI_POPUPMENUMODE | GUI_SYSTEMMENUMODE | GUI_INMOVESIZE)) ||
            threadInfo.hwndCaret) return false;
        int tr = -1, item = -1, take = -1, fx = -1, state = 0;
        return GetTouchedOrFocusedFX(1, &tr, &item, &take, &fx, &state) && !(state & 1);
    }
    // Ctrl+Shift+P is the sole hardcoded FX Chain chord. It intentionally
    // overrides the Track Params assignment only while the focused FX list
    // owns the keyboard; the same chord still opens Track Params in TCP.
    bool fixedFxChainShortcutMatches(MSG* msg) const noexcept {
        return msg && (msg->message == WM_KEYDOWN || msg->message == WM_SYSKEYDOWN) &&
               msg->wParam == 'P' &&
               (GetKeyState(VK_CONTROL) & 0x8000) &&
               (GetKeyState(VK_SHIFT) & 0x8000) &&
               !(GetKeyState(VK_MENU) & 0x8000) &&
               !(GetKeyState(VK_INSERT) & 0x8000) &&
               !(GetKeyState(VK_NUMPAD0) & 0x8000);
    }
    // Other keys (including P) must be configured by the user in REAPER's
    // Main Action List for the FX Params action; never hardcode a bare P.
    bool actionShortcutMatches(MSG* msg) const noexcept {
        if (!msg || (msg->message != WM_KEYDOWN && msg->message != WM_SYSKEYDOWN) ||
            msg->wParam > 255) return false;
        const UINT vk = static_cast<UINT>(msg->wParam);
        if (vk == VK_CONTROL || vk == VK_SHIFT || vk == VK_MENU ||
            vk == VK_LCONTROL || vk == VK_RCONTROL || vk == VK_LSHIFT ||
            vk == VK_RSHIFT || vk == VK_LMENU || vk == VK_RMENU ||
            (GetKeyState(VK_INSERT) & 0x8000) || (GetKeyState(VK_NUMPAD0) & 0x8000)) return false;
        ACCEL accel{};
        accel.fVirt = FVIRTKEY;
        if (GetKeyState(VK_CONTROL) & 0x8000) accel.fVirt |= FCONTROL;
        if (GetKeyState(VK_SHIFT) & 0x8000) accel.fVirt |= FSHIFT;
        if (GetKeyState(VK_MENU) & 0x8000) accel.fVirt |= FALT;
        accel.key = static_cast<WORD>(vk);
        char current[256]{};
        kbd_formatKeyName(&accel, current);
        const auto normalize = [](const char* txt) {
            std::string value;
            for (const unsigned char* p = reinterpret_cast<const unsigned char*>(txt); *p; ++p)
                if (!std::isspace(*p)) value.push_back(static_cast<char>(std::tolower(*p)));
            return value;
        };
        const std::string currentDesc = normalize(current);
        if (currentDesc.empty()) return false;
        KbdSectionInfo* section = SectionFromUniqueID(0);
        if (!section) return false;
        const int command = actions_[0].command; // FX Params ONLY
        const int count = CountActionShortcuts(section, command);
        for (int i = 0; i < count; ++i) {
            char desc[256]{};
            if (GetActionShortcutDesc(section, command, i, desc, sizeof(desc)) &&
                currentDesc == normalize(desc)) return true;
        }
        return false;
    }
    int interceptFxChainShortcut(MSG* msg) {
        if (!isFocusedFxList() || shortcutHelp() || current_ && current_->active() ||
            !(fixedFxChainShortcutMatches(msg) || actionShortcutMatches(msg))) return 0;
        // Use the same normal launch path, shared session memory and access API.
        // Return 1 so REAPER won't also process the original key for search.
        return action(actions_[0].command) ? 1 : 0;
    }
    void launchNavigator(Navigator* desired) {
                current_ = desired;
                input_.select(*desired);
                // Lua gfx.init-style focus owner: keys go straight from its
                // Win32 window procedure into the navigator queue, without a
                // REAPER accelerator/hook. No more fall-through to the TCP.
                titleProxyActive_ = titleModeEnabled_ && titleProxy_.activate(
                    desired->windowTitle(), desired->reviewLine(),
                    [this] { exitNavigation(false); },
                    [this](HWND window, UINT vk, bool repeat) {
                        return input_.enqueueOwnedKey(window, vk, repeat);
                    });
                if (titleProxyActive_) titleProxy_.syncValueControl(desired->nativeValueSlider(),
                    desired->sliderLabel(), desired->valueFraction());
                const InputBackend selected = titleProxyActive_ ? InputBackend::ownedWindow : backend_;
                if (!input_.start(selected, titleProxyActive_ ? titleProxy_.hwnd() : nullptr)) {
                    exitNavigation(false); speak("Keyboard capture unavailable"); }
                else {
                    // The accessible non-editable review label is populated before focus.
                    // Issue one explicit contextual OSARA announcement.
                    desired->announceTitle();
                }
                refreshToggles();
    }
    void tick() {
        if (GetCurrentThreadId() != mainThread_) { fail(); return; }
        if (auto report = importer_.poll()) {
            OutputDebugStringA(("LReaParams " + report->summary() + "\n").c_str());
            if (announceImport_) { speak(report->summary()); announceImport_ = false; }
        }
        if (!current_ || !current_->active()) return;
        if (titleProxyActive_ && !titleProxy_.active()) { exitNavigation(false); return; }
        if (shortcutHelp() || input_.exitRequested() || !current_->contextUnchanged() || !current_->uiStillOpen() || !input_.environmentSafe()) {
            exitNavigation(false); return;
        }
        input_.refreshAllowedWindows(current_->floatingWindow());
        Key key; unsigned budget = 16;
        while (budget-- && input_.pop(key)) {
            // Validate again after dequeue: a queued key must never address a replacement FX.
            if (!current_->contextUnchanged() || GetFocus() != key.window) { exitNavigation(false); return; }
            // A boundary key changes neither selection nor value.
            // Avoid sending redundant title, text or focus updates to NVDA.
            const std::wstring oldTitle = titleProxyActive_ ? current_->windowTitle() : L"";
            const std::string oldReview = titleProxyActive_ ? current_->reviewLine() : "";
            current_->handle(key);
            if (!current_->active()) { exitNavigation(false); speak("LReaParams navigation off"); break; }
            if (titleProxyActive_) {
                const std::wstring newTitle = current_->windowTitle();
                const std::string newReview = current_->reviewLine();
                if (newTitle != oldTitle) titleProxy_.updateTitle(newTitle);
                if (newReview != oldReview) titleProxy_.updateReviewLine(newReview);
                const HWND oldKeyboard = titleProxy_.hwnd();
                titleProxy_.syncValueControl(current_->nativeValueSlider(),
                                             current_->sliderLabel(), current_->valueFraction());
                if (titleProxy_.hwnd() != oldKeyboard) {
                    // FX plugins may asynchronously restore focus while their
                    // formatted parameter value is queried. Recover the native
                    // slider focus BEFORE rebinding the owned keyboard, subject
                    // to the usual modal/edit-field safety checks. This is
                    // especially important on FX Value entry and mirrors the
                    // proven Track Params path.
                    titleProxy_.reassertFocusAfterNavigationKey();
                    if (!input_.switchOwnedWindow(titleProxy_.hwnd())) {
                        OutputDebugStringW(L"LReaParams: native Value/Grid focus transition failed.\n");
                        exitNavigation(false); return;
                    }
                }
                // Only recover keyboard focus after a meaningful change.
                // At the grid boundary this must be completely silent.
                if (newTitle != oldTitle || newReview != oldReview)
                    titleProxy_.reassertFocusAfterNavigationKey();
            }
        }
    }
    void menu(const char* id, HMENU menu, int flag) {
        if (!id || std::strcmp(id, "Main extensions") != 0) return;
        if (flag == 0) {
            HMENU sub = CreatePopupMenu(); if (!sub) return;
            // Memory actions have independent REAPER command IDs and launch
            // their own navigator mode; the FX command preserves the Lua F8 grid.
            AppendMenuW(sub, MF_STRING, static_cast<UINT_PTR>(actions_[0].command), actions_[0].menu);
            AppendMenuW(sub, MF_STRING, static_cast<UINT_PTR>(actions_[1].command), actions_[1].menu);
            HMENU memories = CreatePopupMenu();
            if (memories) {
                AppendMenuW(memories, MF_STRING, static_cast<UINT_PTR>(actions_[7].command), actions_[7].menu);
                AppendMenuW(memories, MF_STRING, static_cast<UINT_PTR>(actions_[8].command), actions_[8].menu);
                AppendMenuW(memories, MF_SEPARATOR, 0, nullptr);
                AppendMenuW(memories, MF_STRING, static_cast<UINT_PTR>(actions_[2].command), actions_[2].menu);
                if (!AppendMenuW(sub, MF_POPUP, reinterpret_cast<UINT_PTR>(memories), L"Memories"))
                    DestroyMenu(memories);
            }
            AppendMenuW(sub, MF_SEPARATOR, 0, nullptr);
            for (int i = 3; i <= 5; ++i)
                AppendMenuW(sub, MF_STRING, static_cast<UINT_PTR>(actions_[i].command), actions_[i].menu);
            AppendMenuW(sub, MF_STRING, static_cast<UINT_PTR>(actions_[9].command), actions_[9].menu);
            AppendMenuW(sub, MF_STRING, static_cast<UINT_PTR>(actions_[6].command), actions_[6].menu);
            if (!AppendMenuW(menu, MF_POPUP, reinterpret_cast<UINT_PTR>(sub), L"LReaParams")) DestroyMenu(sub);
        } else if (flag == 1) updateMenu(menu);
    }
    void shutdown() noexcept {
        input_.stop(); titleProxy_.shutdown(); titleProxyActive_ = false;
        navigator_.end(); trackNavigator_.end(); current_ = nullptr;
        if (fxChainAccelRegistered_) {
            info_.Register("-accelerator", &fxChainAccel_);
            fxChainAccelRegistered_ = false;
        }
        if (timerRegistered_) info_.Register("-timer", reinterpret_cast<void*>(timerHook));
        if (menuRegistered_) info_.Register("-hookcustommenu", reinterpret_cast<void*>(menuHook));
        if (toggleRegistered_) info_.Register("-toggleaction", reinterpret_cast<void*>(toggleHook));
        if (hookRegistered_) info_.Register("-hookcommand2", reinterpret_cast<void*>(actionHook));
        timerRegistered_ = menuRegistered_ = toggleRegistered_ = hookRegistered_ = false;
        for (auto& a : actions_) if (a.registered) { info_.Register("-gaccel", &a.accel); a.registered = false; }
        importer_.stop(); // Worker must finish before its code can be unloaded.
    }
private:
    void updateMenu(HMENU menu) {
        for (int i = 0; i < GetMenuItemCount(menu); ++i) {
            if (HMENU sub = GetSubMenu(menu, i)) updateMenu(sub);
            const auto command = GetMenuItemID(menu, i);
            if (command == static_cast<UINT>(actions_[9].command))
                CheckMenuItem(menu, command, MF_BYCOMMAND | (titleModeEnabled_ ? MF_CHECKED : MF_UNCHECKED));
            for (int a : {0, 1}) {
                if (command != static_cast<UINT>(actions_[a].command)) continue;
                const Navigator* target = a == 0 ? static_cast<const Navigator*>(&navigator_) : static_cast<const Navigator*>(&trackNavigator_);
                const bool selected = current_ == target && target->active();
                CheckMenuItem(menu, command, MF_BYCOMMAND | (selected ? MF_CHECKED : MF_UNCHECKED));
            }
        }
    }
    reaper_plugin_info_t info_;
    DWORD mainThread_{};
    FxNavigator navigator_;
    TrackNavigator trackNavigator_;
    Navigator* current_ = nullptr;
    InputRouter input_;
    TitleProxy titleProxy_;
    ImportWorker importer_;
    fs::path resource_;
    InputBackend backend_ = InputBackend::sdkAccelerator;
    bool hookRegistered_ = false, toggleRegistered_ = false, menuRegistered_ = false, timerRegistered_ = false, announceImport_ = false;
    bool titleModeEnabled_ = true, titleProxyActive_ = false;
    accelerator_register_t fxChainAccel_{};
    bool fxChainAccelRegistered_ = false;
    std::array<Action, 10> actions_{{
        {"LREAPARAMSFXPARAMS", "LReaParams: FX Params (native test)", L"FX Params"},
        {"LREAPARAMSTRACKPARAMS", "LReaParams: Track Params (basic native controls)", L"Track Params (basic controls)"},
        {"LREAPARAMSPARAMETERLIBRARY", "LReaParams: Parameter Library (pending migration)", L"Parameter Library (pending migration)"},
        {"LREAPARAMSIMPORTLEGACY", "LReaParams: Import legacy profiles", L"Import legacy profiles"},
        {"LREAPARAMSOPENDATAFOLDER", "LReaParams: Open Data Folder", L"Open Data Folder"},
        {"LREAPARAMSSETTINGS", "LReaParams: Settings", L"Settings"},
        {"LREAPARAMSABOUT", "LReaParams: About LReaParams", L"About LReaParams"},
        {"LREAPARAMSFXMEMORIES", "LReaParams: FX Memories", L"FX Memories"},
        {"LREAPARAMSTRACKMEMORIES", "LReaParams: Track Memories (future)", L"Track Memories (future)"},
        {"LREAPARAMSNVDATITLE", "LReaParams: Toggle Lua-style keyboard focus window", L"Lua-style keyboard window (1px)"}
    }};
};
int fxChainShortcutHook(MSG* msg, accelerator_register_t* ctx) noexcept {
    try {
        auto* source = ctx ? static_cast<Extension*>(ctx->user) : nullptr;
        return source ? source->interceptFxChainShortcut(msg) : 0;
    } catch (...) {
        if (app) app->fail();
        return 0; // Fail open: REAPER keeps the keystroke.
    }
}
bool actionHook(KbdSectionInfo*, int command, int, int, int, HWND) noexcept {
    try { return app && app->action(command); } catch (...) { if (app) app->fail(); return true; }
}
int toggleHook(int command) noexcept { return app ? app->toggle(command) : -1; }
void menuHook(const char* id, void* menu, int flag) noexcept {
    try { if (app) app->menu(id, static_cast<HMENU>(menu), flag); } catch (...) { if (app) app->fail(); }
}
void timerHook() noexcept { try { if (app) app->tick(); } catch (...) { if (app) app->fail(); } }
}
}
extern "C" REAPER_PLUGIN_DLL_EXPORT int REAPER_PLUGIN_ENTRYPOINT(REAPER_PLUGIN_HINSTANCE, reaper_plugin_info_t* info) {
    if (!info) { lrp::app.reset(); return 0; }
    if (info->caller_version != REAPER_PLUGIN_VERSION || !info->GetFunc || !info->Register || !info->hwnd_main) return 0;
    try { lrp::app = std::make_unique<lrp::Extension>(info); lrp::app->init(); return 1; }
    catch (...) { lrp::app.reset(); OutputDebugStringW(L"LReaParams failed to initialize.\n"); return 0; }
}
