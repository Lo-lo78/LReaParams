#include "lrp/ReaperApi.h"
#include "lrp/FxNavigator.h"
#include "lrp/TrackNavigator.h"
#include "lrp/InputRouter.h"
#include "lrp/TitleProxy.h"
#include "lrp/Storage.h"
#include "lrp/ChoiceDialogs.h"
#include <shellapi.h>
#include <array>
#include <memory>
#include <string>
#include <stdexcept>
#include <system_error>
#include <cctype>
#include <algorithm>
#include <cwctype>

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
    explicit Extension(reaper_plugin_info_t* info) : info_(*info), navigator_([this](const std::string& text) { speak(text); }), backgroundMidi_([this](const std::string& text) { speak(text); }), backgroundTrackMidi_([this](const std::string& text) { speak(text); }), trackNavigator_([this](const std::string& text) { speak(text); }), input_(&info_, navigator_), titleProxy_(info->hwnd_main) {}
    ~Extension() { shutdown(); }
    void init() {
        if (REAPERAPI_LoadAPI(info_.GetFunc) != 0) throw std::runtime_error("Required REAPER API missing");
        mainThread_ = GetCurrentThreadId();
        const char* path = GetResourcePath(); if (!path || !*path) throw std::runtime_error("No resource path");
        resource_ = fs::u8path(path);
        navigator_.setResourceRoot(resource_);
        backgroundMidi_.setResourceRoot(resource_);
        backgroundTrackMidi_.setResourceRoot(resource_);
        trackNavigator_.setResourceRoot(resource_);
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
        startupImportCheckPending_ = true; // No automatic conversion without user consent
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
    // Ctrl+Q uses one parked MIDI context at a time, independent of keyboard
    // focus. The current foreground navigator is copied before end() clears it.
    void parkMidiAndReturnToReaper() {
        if (!current_ || !current_->active()) return;
        const bool wasFx = current_ == &navigator_;
        const bool wasTrack = current_ == &trackNavigator_;
        if (!wasFx && !wasTrack) return;
        backgroundMidi_.end();
        backgroundTrackMidi_.end();
        if (wasFx && navigator_.midiRunning()) {
            backgroundMidi_ = navigator_;
            backgroundMidi_.prepareBackgroundMidi();
        } else if (wasTrack && trackNavigator_.midiRunning()) {
            backgroundTrackMidi_ = trackNavigator_;
            backgroundTrackMidi_.prepareBackgroundMidi();
        }
        exitNavigation(false);
        SetCursorContext(0, nullptr);
        if (IsWindow(info_.hwnd_main) && IsWindowEnabled(info_.hwnd_main)) {
            SetForegroundWindow(info_.hwnd_main);
            SetFocus(info_.hwnd_main);
        }
        speak(backgroundMidi_.active() || backgroundTrackMidi_.midiRunning() ?
            "Back to REAPER. MIDI active" : "Back to REAPER");
    }
    void exitNavigation(bool announce) {
        const bool wasActive = current_ && current_->active();
        input_.stop(); titleProxy_.hideAndRestore(); titleProxyActive_ = false;
        navigator_.end(); trackNavigator_.end(); current_ = nullptr;
        refreshToggles();
        if (announce && wasActive) speak("LReaParams navigation off");
    }
    void fail() noexcept {
        backgroundMidi_.end();
        backgroundTrackMidi_.end();
        // Fail open at the ABI boundary: unregister capture, discard queued commands.
        input_.stop(); titleProxy_.hideAndRestore(); titleProxyActive_ = false;
        navigator_.end(); trackNavigator_.end(); current_ = nullptr;
        if (RefreshToolbar2 && GetCurrentThreadId() == mainThread_) refreshToggles();
        OutputDebugStringW(L"LReaParams: navigation stopped after a callback failure.\n");
    }
    void refreshToggles() const {
        for (int i : {fxParams, trackParams}) if (actions_[i].command) RefreshToolbar2(0, actions_[i].command);
    }
    int toggle(int command) const noexcept {
        if (command == actions_[fxParams].command) return current_ == &navigator_ && navigator_.active() && !navigator_.isMemoryManager() ? 1 : 0;
        if (command == actions_[trackParams].command) return current_ == &trackNavigator_ && trackNavigator_.active() ? 1 : 0;
        if (command == actions_[nvdaTitle].command) return titleModeEnabled_ ? 1 : 0;
        return -1;
    }
    bool action(int command) {
        std::size_t index = actions_.size();
        for (std::size_t i = 0; i < actions_.size(); ++i) if (actions_[i].command == command) { index = i; break; }
        if (index == actions_.size()) return false;
        // Let OSARA announce shortcut help; do not execute any of our actions in help mode.
        if (shortcutHelp() && info_.GetFunc("osara_isShortcutHelpEnabled")) return false;
        switch (index) {
        case fxParams: case trackParams: {
            Navigator* desired = index == fxParams ? static_cast<Navigator*>(&navigator_) : static_cast<Navigator*>(&trackNavigator_);
            if (current_ == desired && current_->active()) { exitNavigation(true); break; }
            exitNavigation(false);
            if (!speechAvailable() || !info_.GetFunc("osara_isShortcutHelpEnabled")) {
                ShowMessageBox("LReaParams requires OSARA with outputMessage and isShortcutHelpEnabled exports. No keyboard capture was installed.", "LReaParams", 0); break;
            }
            if (desired->begin()) launchNavigator(desired);
            break;
        }
        case importLegacy:
            exitNavigation(false);
            requestLegacyImport(false);
            break;
        case openData: {
            exitNavigation(false);
            const auto root = resource_ / L"LReaParams";
            const auto result = reinterpret_cast<INT_PTR>(ShellExecuteW(info_.hwnd_main, L"open", root.c_str(), nullptr, nullptr, SW_SHOWNORMAL));
            if (result <= 32) speak("Cannot open LReaParams data folder.");
            break;
        }
        case settings: {
            exitNavigation(false);
            const auto choice = chooseKeyboardBackend(info_.hwnd_main,
                backend_ == InputBackend::mainThreadHook);
            if (!choice) { speak("Keyboard setting unchanged"); break; }
            if (*choice == 1) {
                backend_ = InputBackend::sdkAccelerator;
                speak("Keyboard: REAPER SDK accelerator. Current session only");
            } else {
                backend_ = InputBackend::mainThreadHook;
                speak("Keyboard: main-thread compatibility hook. Current session only");
            }
            break;
        }
        case openGuide: {
            exitNavigation(false);
            // Prefer the data folder, which survives DLL updates and is writable.
            // Also accept older manual installation layouts for compatibility.
            const std::array<fs::path, 3> roots{{
                resource_ / L"LReaParams" / L"Guide",
                resource_ / L"UserPlugins" / L"Guide",
                resource_ / L"Guide"
            }};
            fs::path guide;
            for (const auto& root : roots) {
                std::error_code ec;
                const auto candidate = root / L"index.html";
                if (fs::is_regular_file(candidate, ec)) { guide = candidate; break; }
            }
            if (guide.empty()) {
                MessageBoxW(info_.hwnd_main,
                    L"Guide/index.html was not found.\n\n"
                    L"Copy the complete Guide folder (including all language subfolders) "
                    L"to your REAPER resource path\\LReaParams\\Guide, then run this action again.",
                    L"LReaParams - Open User Guide", MB_OK | MB_ICONWARNING);
                break;
            }
            const auto result = reinterpret_cast<INT_PTR>(ShellExecuteW(
                info_.hwnd_main, L"open", guide.c_str(), nullptr, nullptr, SW_SHOWNORMAL));
            if (result <= 32)
                MessageBoxW(info_.hwnd_main,
                    L"Windows could not open the HTML user guide in the default browser.",
                    L"LReaParams - Open User Guide", MB_OK | MB_ICONWARNING);
            break;
        }
        case about:
            exitNavigation(false);
            ShowMessageBox(
                "LReaParams 0.0.61 - Native REAPER extension\n\n"
                "Accessible FX Params and Track Params for NVDA and OSARA.\n"
                "Developed by Lo-lo and contributors.\n\n"
                "FX Params: F7 structural edit; F8 Compare A/B (double F8 updates Original); "
                "F10 FX Browser/Grid; F11 Audio Pin Connector (up to 128 channels).\n"
                "Track Params: F1 Tracks; F2 Sends; F3 Receives; F4 FX TCP; "
                "F5 Track MIDI; F6 Hardware Outputs (includes Add); F7 ReaRoute. "
                "Track F8 is unused.\n\n"
                "Ctrl+Tab switches navigators; Ctrl+Shift+M opens FX/Track Memories.\n"
                "Ctrl+Alt+C fixed MIDI learn; Shift+C fixed CC on/off; Ctrl+Shift+C floating CC.\n"
                "Ctrl+Shift+A toggles the current envelope; "
                "Ctrl+Shift+Alt+A opens automation-clear confirmation.\n"
                "Ctrl+E numeric edit; Ctrl+F search; Ctrl+Q live MIDI background.\n"
                "Alt+F1/F2 presets; Alt+F3/F4 automated FX parameters.\n"
                "Space Play/Stop; Ctrl+Space Play/Pause; Ctrl+I/O markers; "
                "Ctrl+1 through Ctrl+0 marker jumps.\n"
                "Alt+F10/F11/F12 and Alt+Shift+F10/F11/F12: OSARA Peak Watcher.\n"
                "F12 alone is reserved; Ctrl+F12 memory slot 12. Ctrl+P no longer opens the FX Browser.\n\n"
                "Open User Guide: choose English, Italian, Spanish, French, Russian, "
                "Simplified Chinese or Japanese; then FX Params or Track Params.\n"
                "Install Guide in REAPER resource path / LReaParams / Guide.\n"
                "Data: REAPER resource path / LReaParams / Plugins (.fx) and Tracks (.tp).\n"
                "The original Lua launcher scripts are not required.\n\n"
                "Import legacy profiles: Y imports the old Lua TXT settings, N leaves them unchanged. "
                "At startup the one-time question appears only when legacy TXT files are found. "
                "Run Import legacy profiles later to import manually.\n"
                "Settings: 1 chooses REAPER SDK keyboard accelerator (recommended), "
                "2 chooses the compatibility hook. Escape keeps the mode unchanged. "
                "This keyboard selection lasts only for the current REAPER session.",
                "About LReaParams", 0);
            break;
        case fxMemories: {
            // Dedicated REAPER action opens native FX Memories; plain F8 is
            // Compare A/B. Reuse the FX navigator and focus owner.
            exitNavigation(false);
            if (!speechAvailable() || !info_.GetFunc("osara_isShortcutHelpEnabled")) {
                speak("FX Memories requires OSARA");break;
            }
            if(navigator_.begin() && navigator_.openFxMemories(true))
                launchNavigator(&navigator_);
            break;
        }
        case trackMemories:
            exitNavigation(false);
            if (!speechAvailable() || !info_.GetFunc("osara_isShortcutHelpEnabled")) {
                speak("Track Memories requires OSARA"); break;
            }
            if (trackNavigator_.begin() && trackNavigator_.openTrackMemories(true))
                launchNavigator(&trackNavigator_);
            break;
        case stopBackgroundMidi:
            backgroundMidi_.end();
            backgroundTrackMidi_.end();
            speak("Background MIDI off");
            break;
        case nvdaTitle:
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
        const int command = actions_[fxParams].command; // FX Params ONLY
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
        return action(actions_[fxParams].command) ? 1 : 0;
    }
    void launchNavigator(Navigator* desired) {
                // Reopening the very same FX transfers control back to the
                // foreground and prevents two contexts driving one parameter.
                if (desired == &navigator_ && backgroundMidi_.sameMidiFx(navigator_))
                    backgroundMidi_.end();
                // No two navigators may apply the same incoming MIDI CC.
                backgroundTrackMidi_.end();
                if (desired == &trackNavigator_) backgroundMidi_.end();
                current_ = desired;
                // The track owning an FX (also a Take FX) must be the real
                // TCP selection when opening FX Params. Otherwise Escape can
                // return to the track that was selected BEFORE the FX switch.
                if (desired == &navigator_ && !navigator_.isMemoryManager()) {
                    MediaTrack* fxTrack = navigator_.cursorTrack();
                    ReaProject* project = EnumProjects(-1, nullptr, 0);
                    if (project && fxTrack && ValidatePtr2(project, fxTrack, "MediaTrack*") &&
                        (CountSelectedTracks(project) != 1 || !IsTrackSelected(fxTrack))) {
                        SetOnlyTrackSelected(fxTrack);
                        TrackList_AdjustWindows(false);
                        UpdateArrange();
                    }
                }
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
                if (desired == &trackNavigator_)
                    trackNavigator_.setNativeFilterAvailable(titleProxyActive_);
                if (titleProxyActive_) {
                    titleProxy_.syncValueControl(desired->nativeValueSlider(), desired->sliderLabel(), desired->valueFraction());
                    if (desired==&navigator_)titleProxy_.syncTextControl(navigator_.nativeTextField(),
                        navigator_.nativeTextLabel(),navigator_.nativeTextValue());
                    else if (desired==&trackNavigator_)titleProxy_.syncTextControl(trackNavigator_.nativeTextField(),
                        trackNavigator_.nativeTextLabel(),trackNavigator_.nativeTextValue());
                }
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
    bool containsLegacyTxt(const fs::path& directory) const {
        std::error_code ec;
        if (!fs::is_directory(directory, ec) || fs::is_symlink(directory, ec)) return false;
        fs::recursive_directory_iterator it(directory, fs::directory_options::skip_permission_denied, ec);
        const fs::recursive_directory_iterator end;
        for (; !ec && it != end; it.increment(ec)) {
            if (it->is_symlink(ec)) {
                if (it->is_directory(ec)) it.disable_recursion_pending();
                ec.clear();
                continue;
            }
            if (ec) { ec.clear(); continue; }
            if (!it->is_regular_file(ec)) { ec.clear(); continue; }
            auto ext = it->path().extension().wstring();
            std::transform(ext.begin(), ext.end(), ext.begin(),
                [](wchar_t c) { return static_cast<wchar_t>(std::towlower(c)); });
            if (ext == L".txt") return true;
        }
        return false;
    }
    bool hasLegacyProfiles() const {
        const auto legacy = resource_ / L"Scripts" / L"Lo-lo - Scripts" / L"Utility" / L"Scripts";
        const auto current = resource_ / L"LReaParams";
        return containsLegacyTxt(legacy / L"Plugins") || containsLegacyTxt(legacy / L"Tracks") ||
            containsLegacyTxt(current / L"Plugins") || containsLegacyTxt(current / L"Tracks");
    }
    void requestLegacyImport(bool atStartup) {
        if (!hasLegacyProfiles()) {
            if (!atStartup) MessageBoxW(info_.hwnd_main,
                L"No legacy TXT profiles were found in the old Lua Plugins/Tracks folders "
                L"or in the current LReaParams Plugins/Tracks folders. Nothing was changed.",
                L"LReaParams - Import legacy profiles", MB_OK | MB_ICONINFORMATION);
            return;
        }
        const auto answer = confirmLegacyImport(info_.hwnd_main, atStartup);
        if (atStartup) {
            // One-shot startup consent; N or Escape means 'do not import'. If a
            // later import is wanted, the explicit action always remains available.
            // The consent marker lives outside active profile directories.
            const fs::path marker = resource_ / L"LReaParams" / L"Settings" /
                L"LegacyImportChoice.txt";
            try {
                writeNewVerified(marker, answer.value_or(false) ?
                    "LREAPARAMS_LEGACY_IMPORT_CHOICE_V1\nChoice=Yes\n" :
                    "LREAPARAMS_LEGACY_IMPORT_CHOICE_V1\nChoice=No\n");
            } catch (...) { OutputDebugStringW(L"LReaParams: could not save startup import preference.\n"); }
        }
        if (!answer || !*answer) {
            if (!atStartup) speak("Legacy import cancelled. No profiles changed");
            return;
        }
        const bool started = importer_.start(resource_);
        if (started) announceImport_ = true;
        speak(started ? "Import started. Verified backups are retained" :
            "Legacy profile import already running");
    }
    void tick() {
        if (GetCurrentThreadId() != mainThread_) { fail(); return; }
        if (startupImportCheckPending_ && IsWindowVisible(info_.hwnd_main) &&
            IsWindowEnabled(info_.hwnd_main)) {
            startupImportCheckPending_ = false;
            std::error_code ec;
            const fs::path marker = resource_ / L"LReaParams" / L"Settings" / L"LegacyImportChoice.txt";
            if (!fs::exists(marker, ec) && !ec) requestLegacyImport(true);
        }
        if (auto report = importer_.poll()) {
            OutputDebugStringA(("LReaParams " + report->summary() + "\n").c_str());
            if (announceImport_) { speak(report->summary()); announceImport_ = false; }
        }
        // Background CC has no window/focus dependency: validate identities
        // on every REAPER main-thread tick, including while Track Params is up.
        if (backgroundMidi_.active()) {
            try {
                if (!backgroundMidi_.contextUnchanged() || !backgroundMidi_.midiRunning())
                    backgroundMidi_.end();
                else if (!navigator_.active() || !backgroundMidi_.sameMidiFx(navigator_))
                    backgroundMidi_.pollMidi();
            } catch (const std::exception&) {
                backgroundMidi_.end();
                OutputDebugStringW(L"LReaParams: invalid parked MIDI context stopped.\n");
            } catch (...) {
                backgroundMidi_.end();
                OutputDebugStringW(L"LReaParams: parked MIDI callback stopped.\n");
            }
        }
        if (backgroundTrackMidi_.active()) {
            try {
                if (!backgroundTrackMidi_.contextUnchanged() || !backgroundTrackMidi_.midiRunning())
                    backgroundTrackMidi_.end();
                else if (current_ != &trackNavigator_ && current_ != &navigator_)
                    backgroundTrackMidi_.tickMidi();
            } catch (...) {
                backgroundTrackMidi_.end();
                OutputDebugStringW(L"LReaParams: parked Track MIDI stopped safely.\n");
            }
        }
        if (!current_ || !current_->active()) return;
        if (titleProxyActive_ && !titleProxy_.active()) { exitNavigation(false); return; }
        if (shortcutHelp() || input_.exitRequested() || !current_->contextUnchanged() || !current_->uiStillOpen() || !input_.environmentSafe()) {
            exitNavigation(false); return;
        }
        if (current_ == &trackNavigator_) trackNavigator_.tickMidi();
        if(current_==&navigator_) {
            const auto previous=current_->reviewLine();
            // An FX may finish loading its parameter list after Ctrl+Alt+B
            // makes it online. Return to the original group/grid automatically.
            if (navigator_.pollOnlineParameters() && titleProxyActive_) {
                titleProxy_.updateTitle(navigator_.windowTitle());
                titleProxy_.updateReviewLine(navigator_.reviewLine());
                titleProxy_.syncValueControl(navigator_.nativeValueSlider(),
                    navigator_.sliderLabel(), navigator_.valueFraction());
                titleProxy_.reassertFocusAfterNavigationKey();
            }
            navigator_.pollMidi();
            navigator_.pollCompare(); // Resolve single F8 after double-press window.
            const auto next=current_->reviewLine();
            if(titleProxyActive_ && next!=previous) {
                titleProxy_.updateReviewLine(next);
                titleProxy_.syncValueControl(current_->nativeValueSlider(),current_->sliderLabel(),current_->valueFraction());
            }
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
            // Read a real Win32 EDIT just before Enter/Escape or search arrows;
            // its own caret/selection/Unicode editor handles ordinary typing.
            if (titleProxyActive_ && current_==&navigator_ && navigator_.nativeTextField())
                navigator_.setNativeText(titleProxy_.textValue());
            else if (titleProxyActive_ && current_==&trackNavigator_ && trackNavigator_.nativeTextField())
                trackNavigator_.setNativeText(titleProxy_.textValue());
            // Ctrl+Tab uses the current REAL FX/Track owner in both directions.
            // The TCP is synchronized; never resume the track where the user
            // originally entered LReaParams after navigating to another FX.
            if (key.ctrl && !key.alt && !key.shift && key.vk == VK_TAB && !key.repeat &&
                !((current_ == &navigator_ && (navigator_.nativeTextField() || navigator_.isMemoryManager())) ||
                  (current_ == &trackNavigator_ && (trackNavigator_.nativeTextField() || trackNavigator_.isMemoryManager())))) {
                const bool wasTrack = current_ == &trackNavigator_;
                MediaTrack* preferred = wasTrack ? trackNavigator_.cursorTrack() : navigator_.cursorTrack();
                // Ctrl+Tab is contextual. An empty FX chain must not close
                // Track Params, move to another track, or speak two messages
                // while restoring its focus. The Master Monitor chain is a
                // real FX context and must remain reachable.
                if (wasTrack) {
                    ReaProject* project = EnumProjects(-1, nullptr, 0);
                    if (!project || !preferred || !ValidatePtr2(project, preferred, "MediaTrack*")) {
                        speak("No track FX"); return;
                    }
                    const bool monitorFx = preferred == GetMasterTrack(project) &&
                        TrackFX_GetRecCount(preferred) > 0;
                    if (TrackFX_GetCount(preferred) <= 0 && !monitorFx) {
                        speak("No track FX"); return;
                    }
                }
                // Preserve the chosen track through end(), which clears the
                // old navigator's active state. Track Params explicitly takes
                // the FX owner rather than the stale selected TCP track.
                exitNavigation(false);
                if (wasTrack) navigator_.setNextStartTrack(preferred);
                else trackNavigator_.setNextStartTrack(preferred);
                Navigator* target = wasTrack ? static_cast<Navigator*>(&navigator_) :
                    static_cast<Navigator*>(&trackNavigator_);
                if (target->begin()) {
                    launchNavigator(target);
                } else {
                    // A missing FX must not strand the user outside LReaParams.
                    // Restore the previous navigator and its persisted position.
                    Navigator* previous = wasTrack ? static_cast<Navigator*>(&trackNavigator_) :
                        static_cast<Navigator*>(&navigator_);
                    // Failed transfers restore the same track, not the one
                    // that happened to be selected on initial entry.
                    if (wasTrack) trackNavigator_.setNextStartTrack(preferred);
                    else navigator_.setNextStartTrack(preferred);
                    if (previous->begin()) launchNavigator(previous);
                    else speak(wasTrack ? "FX Params unavailable" : "Track Params unavailable");
                }
                return;
            }
            // Do not let Ctrl+Q fall through to REAPER, or let the UI
            // navigator clear the MIDI state before we park its own copy.
            if ((current_ == &navigator_ || current_ == &trackNavigator_) &&
                key.ctrl && !key.shift && !key.alt && key.vk == 'Q' && !key.repeat &&
                !((current_ == &navigator_ && (navigator_.nativeTextField() || navigator_.isMemoryManager())) ||
                  (current_ == &trackNavigator_ && (trackNavigator_.nativeTextField() || trackNavigator_.isMemoryManager())))) {
                parkMidiAndReturnToReaper();
                return;
            }
            current_->handle(key);
            if (current_ == &navigator_) {
                const auto request = navigator_.consumeNativeFxWindowRequest();
                if (request != FxNavigator::NativeFxWindow::none) {
                    MediaTrack* targetTrack = navigator_.currentTrackForNativeWindow();
                    MediaItem_Take* targetTake = navigator_.currentTakeForNativeWindow();
                    const int targetFx = navigator_.currentFxForNativeWindow();
                    // Remove native focus owner BEFORE handing control to REAPER.
                    exitNavigation(false);
                    if (request == FxNavigator::NativeFxWindow::addFx) {
                        if (Main_OnCommand) Main_OnCommand(40271, 0);
                    } else if (request == FxNavigator::NativeFxWindow::chain) {
                        if (targetTake && ValidatePtr2(EnumProjects(-1,nullptr,0), targetTake, "MediaItem_Take*"))
                            TakeFX_Show(targetTake, targetFx, 1);
                        else if (targetTrack && ValidatePtr2(EnumProjects(-1,nullptr,0), targetTrack, "MediaTrack*"))
                            TrackFX_Show(targetTrack, targetFx, 1);
                    }
                    return;
                }
            }
            if (!current_->active()) { exitNavigation(false); speak("LReaParams navigation off"); break; }
            if (titleProxyActive_) {
                const std::wstring newTitle = current_->windowTitle();
                const std::string newReview = current_->reviewLine();
                if (newTitle != oldTitle) titleProxy_.updateTitle(newTitle);
                if (newReview != oldReview) titleProxy_.updateReviewLine(newReview);
                const HWND oldKeyboard = titleProxy_.hwnd();
                titleProxy_.syncValueControl(current_->nativeValueSlider(),
                                             current_->sliderLabel(), current_->valueFraction());
                if(current_==&navigator_)titleProxy_.syncTextControl(navigator_.nativeTextField(),
                    navigator_.nativeTextLabel(),navigator_.nativeTextValue());
                else if(current_==&trackNavigator_)titleProxy_.syncTextControl(trackNavigator_.nativeTextField(),
                    trackNavigator_.nativeTextLabel(),trackNavigator_.nativeTextValue());
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
            // their own navigator mode; FX F8 remains Compare A/B.
            AppendMenuW(sub, MF_STRING, static_cast<UINT_PTR>(actions_[fxParams].command), actions_[fxParams].menu);
            AppendMenuW(sub, MF_STRING, static_cast<UINT_PTR>(actions_[trackParams].command), actions_[trackParams].menu);
            HMENU memories = CreatePopupMenu();
            if (memories) {
                AppendMenuW(memories, MF_STRING, static_cast<UINT_PTR>(actions_[fxMemories].command), actions_[fxMemories].menu);
                AppendMenuW(memories, MF_STRING, static_cast<UINT_PTR>(actions_[trackMemories].command), actions_[trackMemories].menu);
                if (!AppendMenuW(sub, MF_POPUP, reinterpret_cast<UINT_PTR>(memories), L"Memories"))
                    DestroyMenu(memories);
            }
            AppendMenuW(sub, MF_SEPARATOR, 0, nullptr);
            AppendMenuW(sub, MF_STRING, static_cast<UINT_PTR>(actions_[stopBackgroundMidi].command), actions_[stopBackgroundMidi].menu);
            for (int i : {importLegacy, openData, settings})
                AppendMenuW(sub, MF_STRING, static_cast<UINT_PTR>(actions_[i].command), actions_[i].menu);
            AppendMenuW(sub, MF_STRING, static_cast<UINT_PTR>(actions_[nvdaTitle].command), actions_[nvdaTitle].menu);
            AppendMenuW(sub, MF_STRING, static_cast<UINT_PTR>(actions_[openGuide].command), actions_[openGuide].menu);
            AppendMenuW(sub, MF_STRING, static_cast<UINT_PTR>(actions_[about].command), actions_[about].menu);
            if (!AppendMenuW(menu, MF_POPUP, reinterpret_cast<UINT_PTR>(sub), L"LReaParams")) DestroyMenu(sub);
        } else if (flag == 1) updateMenu(menu);
    }
    void shutdown() noexcept {
        input_.stop(); titleProxy_.shutdown(); titleProxyActive_ = false;
        backgroundMidi_.end(); backgroundTrackMidi_.end(); navigator_.end(); trackNavigator_.end(); current_ = nullptr;
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
            if (command == static_cast<UINT>(actions_[nvdaTitle].command))
                CheckMenuItem(menu, command, MF_BYCOMMAND | (titleModeEnabled_ ? MF_CHECKED : MF_UNCHECKED));
            for (int a : {fxParams, trackParams}) {
                if (command != static_cast<UINT>(actions_[a].command)) continue;
                const Navigator* target = a == fxParams ? static_cast<const Navigator*>(&navigator_) : static_cast<const Navigator*>(&trackNavigator_);
                const bool selected = current_ == target && target->active();
                CheckMenuItem(menu, command, MF_BYCOMMAND | (selected ? MF_CHECKED : MF_UNCHECKED));
            }
        }
    }
    reaper_plugin_info_t info_;
    DWORD mainThread_{};
    FxNavigator navigator_;
    FxNavigator backgroundMidi_; // FX parked after Ctrl+Q
    TrackNavigator backgroundTrackMidi_; // Track MIDI parked after Ctrl+Q
    TrackNavigator trackNavigator_;
    Navigator* current_ = nullptr;
    InputRouter input_;
    TitleProxy titleProxy_;
    ImportWorker importer_;
    fs::path resource_;
    InputBackend backend_ = InputBackend::sdkAccelerator;
    bool hookRegistered_ = false, toggleRegistered_ = false, menuRegistered_ = false, timerRegistered_ = false, announceImport_ = false;
    bool startupImportCheckPending_ = false;
    bool titleModeEnabled_ = true, titleProxyActive_ = false;
    accelerator_register_t fxChainAccel_{};
    bool fxChainAccelRegistered_ = false;
    enum ActionIndex { fxParams, trackParams, importLegacy, openData, settings, about, fxMemories, trackMemories, nvdaTitle, stopBackgroundMidi, openGuide, actionCount };
    std::array<Action, actionCount> actions_{{
        {"LREAPARAMSFXPARAMS", "LReaParams: FX Params", L"FX Params"},
        {"LREAPARAMSTRACKPARAMS", "LReaParams: Track Params", L"Track Params"},
        {"LREAPARAMSIMPORTLEGACY", "LReaParams: Import legacy profiles", L"Import legacy profiles"},
        {"LREAPARAMSOPENDATAFOLDER", "LReaParams: Open Data Folder", L"Open Data Folder"},
        {"LREAPARAMSSETTINGS", "LReaParams: Settings (Keyboard Input)", L"Keyboard Settings"},
        {"LREAPARAMSABOUT", "LReaParams: About LReaParams", L"About LReaParams"},
        {"LREAPARAMSFXMEMORIES", "LReaParams: FX Memories", L"FX Memories"},
        {"LREAPARAMSTRACKMEMORIES", "LReaParams: Track Memories", L"Track Memories"},
        {"LREAPARAMSNVDATITLE", "LReaParams: Accessibility Focus Window (toggle)", L"Accessibility Focus Window"},
        {"LREAPARAMSSTOPMIDIBACKGROUND", "LReaParams: Stop background MIDI", L"Stop background MIDI"},
        {"LREAPARAMSOPENUSERGUIDE", "LReaParams: Open User Guide", L"Open User Guide"}
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
