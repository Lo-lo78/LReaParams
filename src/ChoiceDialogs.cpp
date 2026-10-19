#include "lrp/ChoiceDialogs.h"
#include <commctrl.h>

namespace lrp {
namespace {
struct ChoiceState {
    HWND hwnd{};
    HHOOK hook{};
    UINT firstKey{};
    UINT secondKey{};
    int firstID{};
    int secondID{};
};
thread_local ChoiceState* currentChoice = nullptr;

LRESULT CALLBACK keyHook(int code, WPARAM removed, LPARAM data) {
    ChoiceState* state = currentChoice;
    if (code >= 0 && removed == PM_REMOVE && state && state->hwnd && data) {
        auto* message = reinterpret_cast<MSG*>(data);
        if ((message->message == WM_KEYDOWN || message->message == WM_SYSKEYDOWN) &&
            (message->hwnd == state->hwnd || IsChild(state->hwnd, message->hwnd)) &&
            !(GetKeyState(VK_CONTROL) & 0x8000) &&
            !(GetKeyState(VK_MENU) & 0x8000)) {
            const int id = message->wParam == state->firstKey ? state->firstID :
                message->wParam == state->secondKey ? state->secondID : 0;
            if (id) {
                // Task Dialog commands are sent to the correct dialog window;
                // this never delivers a Y/N key to REAPER or a navigator.
                SendMessageW(state->hwnd, TDM_CLICK_BUTTON, static_cast<WPARAM>(id), 0);
                message->message = WM_NULL;
                return 0;
            }
        }
    }
    return CallNextHookEx(state ? state->hook : nullptr, code, removed, data);
}
HRESULT CALLBACK choiceEvents(HWND hwnd, UINT notice, WPARAM, LPARAM, LONG_PTR context) {
    auto* state = reinterpret_cast<ChoiceState*>(context);
    if (state) {
        if (notice == TDN_CREATED) state->hwnd = hwnd;
        else if (notice == TDN_DESTROYED) state->hwnd = nullptr;
    }
    return S_OK;
}

std::optional<int> runChoice(HWND owner, const wchar_t* title, const wchar_t* question,
    const wchar_t* explanation, const TASKDIALOG_BUTTON (&buttons)[2],
    int defaultID, UINT firstKey, UINT secondKey) {
    ChoiceState state{};
    state.firstKey = firstKey;
    state.secondKey = secondKey;
    state.firstID = buttons[0].nButtonID;
    state.secondID = buttons[1].nButtonID;
    // A thread-local hook exists only while our modal dialog is open.
    // TaskDialog buttons themselves also support Alt+Y/N or Alt+1/2,
    // Tab, Shift+Tab and Enter if the hook could not be installed.
    ChoiceState* previous = currentChoice;
    currentChoice = &state;
    state.hook = SetWindowsHookExW(WH_GETMESSAGE, keyHook, nullptr, GetCurrentThreadId());
    TASKDIALOGCONFIG dialog{};
    dialog.cbSize = sizeof(dialog);
    dialog.hwndParent = owner;
    dialog.dwFlags = TDF_ALLOW_DIALOG_CANCELLATION | TDF_SIZE_TO_CONTENT;
    dialog.pszWindowTitle = title;
    dialog.pszMainInstruction = question;
    dialog.pszContent = explanation;
    dialog.pszMainIcon = TD_INFORMATION_ICON;
    dialog.cButtons = 2;
    dialog.pButtons = buttons;
    dialog.nDefaultButton = defaultID;
    dialog.pfCallback = choiceEvents;
    dialog.lpCallbackData = reinterpret_cast<LONG_PTR>(&state);
    int pressed = 0;
    const HRESULT result = TaskDialogIndirect(&dialog, &pressed, nullptr, nullptr);
    if (state.hook) UnhookWindowsHookEx(state.hook);
    currentChoice = previous;
    if (FAILED(result)) {
        MessageBoxW(owner, L"The accessible choice dialog could not be displayed. No changes were made.",
            L"LReaParams", MB_OK | MB_ICONERROR);
        return std::nullopt;
    }
    if (pressed != buttons[0].nButtonID && pressed != buttons[1].nButtonID) return std::nullopt;
    return pressed;
}
}

std::optional<bool> confirmLegacyImport(HWND owner, bool atStartup) {
    const TASKDIALOG_BUTTON options[] = {
        {IDYES, L"&Yes (Y) - Import old Lua profiles"},
        {IDNO, L"&No (N) - Do not import"}
    };
    const auto answer = runChoice(owner, L"LReaParams - Legacy profile import",
        L"Import FX Params and Track Params settings from the old Lua scripts?",
        atStartup ?
            L"Y: Convert the legacy TXT profiles into native .fx and .tp files. "
            L"Existing native profiles will not be overwritten. Backups are created.\n\n"
            L"N: Leave the legacy profiles unchanged. You can import at any time with "
            L"the REAPER action LReaParams: Import legacy profiles.\n\n"
            L"Press Y or N, use the buttons with Tab and Enter, or press Escape to cancel. "
            L"This startup question is asked only once."
            :
            L"Y: Import and safely convert old TXT profiles. Existing .fx/.tp files "
            L"are not overwritten; backups are retained.\n\n"
            L"N: Do nothing.\n\n"
            L"Press Y or N, use the buttons with Tab and Enter, or press Escape to cancel.",
        options, IDNO, 'Y', 'N');
    if (!answer) return std::nullopt;
    return *answer == IDYES;
}

std::optional<int> chooseKeyboardBackend(HWND owner, bool usingCompatibilityHook) {
    const TASKDIALOG_BUTTON options[] = {
        {101, L"&1 - REAPER SDK accelerator (recommended default)"},
        {102, L"&2 - Main-thread keyboard hook (compatibility)"}
    };
    const auto answer = runChoice(owner, L"LReaParams - Keyboard settings",
        L"Choose how LReaParams receives keyboard input",
        usingCompatibilityHook ?
            L"Current mode: Main-thread hook (compatibility).\n\n"
            L"1: REAPER SDK accelerator plus Escape-only hook (recommended).\n"
            L"2: Alternative WH_GETMESSAGE hook, limited to REAPER's main thread "
            L"and the active navigator.\n\n"
            L"Press 1 or 2 to choose, or Escape to keep the current mode. "
            L"The change lasts only for this REAPER session."
            :
            L"Current mode: REAPER SDK accelerator (default).\n\n"
            L"1: REAPER SDK accelerator plus Escape-only hook (recommended).\n"
            L"2: Alternative WH_GETMESSAGE hook, limited to REAPER's main thread "
            L"and the active navigator.\n\n"
            L"Press 1 or 2 to choose, or Escape to keep the current mode. "
            L"The change lasts only for this REAPER session.",
        options, usingCompatibilityHook ? 102 : 101, '1', '2');
    if (!answer) return std::nullopt;
    return *answer == 101 ? 1 : 2;
}
}
