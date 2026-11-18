#include "lrp/RangeDialog.h"
#include <string>
#include <vector>
#include <cmath>
#include <cwchar>
#include <algorithm>

namespace lrp {
namespace {
// DialogBoxIndirectParamW runs an internal message loop: REAPER keeps firing
// its timer during this time, even though the active window is the dialog.
thread_local unsigned rangeDialogDepth = 0;
}
bool rangeDialogModalActive() noexcept { return rangeDialogDepth != 0; }
std::wstring rangeNameUtf8(const std::string& text) {
    if (text.empty()) return {};
    const int length = MultiByteToWideChar(CP_UTF8, 0, text.c_str(), -1, nullptr, 0);
    if (length <= 0) return {};
    std::wstring result(static_cast<std::size_t>(length), L'\0');
    if (!MultiByteToWideChar(CP_UTF8, 0, text.c_str(), -1, result.data(), length)) return {};
    result.resize(static_cast<std::size_t>(length - 1));
    return result;
}
namespace {
constexpr int minimumId = 1101, maximumId = 1102;
struct DialogState {
    ParameterRange result;
    double minAllowed = 0, maxAllowed = 1;
    bool integers = false;
    HWND minimumEdit = nullptr, maximumEdit = nullptr;
    bool accepted = false;
};
std::wstring format(double value) {
    wchar_t buffer[64]{};
    std::swprintf(buffer, 64, L"%.12g", value);
    return buffer;
}
bool parse(HWND edit, double& value, bool integer) {
    wchar_t text[128]{};
    GetWindowTextW(edit, text, 128);
    std::wstring input(text);
    // Accept decimal comma on Italian Windows keyboards in each independent field.
    std::replace(input.begin(), input.end(), L',', L'.');
    wchar_t* end = nullptr;
    const double parsed = std::wcstod(input.c_str(), &end);
    if (end == input.c_str() || !std::isfinite(parsed) ||
        (integer && parsed != std::trunc(parsed))) return false;
    while (*end == L' ' || *end == L'\t') ++end;
    if (*end) return false;
    value = parsed;
    return true;
}
INT_PTR CALLBACK proc(HWND hwnd, UINT message, WPARAM wp, LPARAM lp) {
    auto* state = reinterpret_cast<DialogState*>(GetWindowLongPtrW(hwnd, DWLP_USER));
    switch (message) {
    case WM_INITDIALOG: {
        state = reinterpret_cast<DialogState*>(lp);
        SetWindowLongPtrW(hwnd, DWLP_USER, reinterpret_cast<LONG_PTR>(state));
        const HINSTANCE instance = GetModuleHandleW(nullptr);
        auto control = [&](const wchar_t* cls, const wchar_t* caption, DWORD style,
                           int x,int y,int w,int h,int id) -> HWND {
            HWND child = CreateWindowExW(cls[0] == L'E' ? WS_EX_CLIENTEDGE : 0,
                cls, caption, WS_CHILD|WS_VISIBLE|style,x,y,w,h,hwnd,
                reinterpret_cast<HMENU>(static_cast<INT_PTR>(id)),instance,nullptr);
            SendMessageW(child, WM_SETFONT,
                reinterpret_cast<WPARAM>(GetStockObject(DEFAULT_GUI_FONT)), TRUE);
            return child;
        };
        control(L"STATIC", L"Minimum", 0,14,14,240,18,0);
        state->minimumEdit = control(L"EDIT", format(state->result.minimum).c_str(),
            WS_TABSTOP|ES_AUTOHSCROLL,14,34,270,25,minimumId);
        control(L"STATIC", L"Maximum", 0,14,67,240,18,0);
        state->maximumEdit = control(L"EDIT", format(state->result.maximum).c_str(),
            WS_TABSTOP|ES_AUTOHSCROLL,14,87,270,25,maximumId);
        control(L"BUTTON", L"OK", WS_TABSTOP|BS_DEFPUSHBUTTON,78,132,95,26,IDOK);
        control(L"BUTTON", L"Cancel", WS_TABSTOP|BS_PUSHBUTTON,183,132,101,26,IDCANCEL);
        SendMessageW(state->minimumEdit, EM_SETSEL, 0, -1);
        SetFocus(state->minimumEdit);
        return FALSE;
    }
    case WM_COMMAND:
        if (!state) return FALSE;
        if (LOWORD(wp) == IDCANCEL) { EndDialog(hwnd, IDCANCEL); return TRUE; }
        if (LOWORD(wp) == IDOK) {
            double low=0,high=0;
            if (!parse(state->minimumEdit,low,state->integers) ||
                !parse(state->maximumEdit,high,state->integers) ||
                low < state->minAllowed || high > state->maxAllowed || low >= high) {
                MessageBoxW(hwnd, (L"Enter minimum below maximum. Allowed range: " +
                    format(state->minAllowed) + L" to " + format(state->maxAllowed)).c_str(),
                    L"Invalid range", MB_OK|MB_ICONWARNING);
                SetFocus(state->minimumEdit);
                return TRUE;
            }
            state->result = {low,high}; state->accepted = true;
            EndDialog(hwnd, IDOK); return TRUE;
        }
        return FALSE;
    case WM_CLOSE: EndDialog(hwnd, IDCANCEL); return TRUE;
    }
    return FALSE;
}
}
bool editParameterRange(HWND owner,const std::wstring& title,
                        double low,double high,ParameterRange& value,bool integers) {
    // Empty dialog template with controls created by WM_INITDIALOG so Windows
    // provides native keyboard dialog navigation and accessible labels.
    alignas(DWORD) BYTE bytes[512]{};
    auto* dlg = reinterpret_cast<DLGTEMPLATE*>(bytes);
    dlg->style = WS_POPUP|WS_CAPTION|WS_SYSMENU|DS_MODALFRAME|DS_CENTER|WS_VISIBLE;
    dlg->dwExtendedStyle = WS_EX_CONTROLPARENT;
    dlg->cdit = 0;
    dlg->x = 0; dlg->y = 0; dlg->cx = 300; dlg->cy = 176;
    // DLGTEMPLATE on Windows has an 18-byte serialized header; using its
    // padded sizeof would shift the menu/class/title fields into the wrong place.
    auto* fields = reinterpret_cast<WORD*>(bytes + 18);
    fields[0] = 0; fields[1] = 0;
    auto* caption = reinterpret_cast<WCHAR*>(bytes + 22);
    wcsncpy(caption, title.c_str(), 120);
    DialogState state{value,low,high,integers};
    // The navigator's keyboard owner is focused when Alt+R/C/F is pressed.
    // Remember that exact control, including native Value/EDIT modes, so
    // OK/Enter AND Cancel/Escape return to the SAME navigator location.
    const HWND priorFocus = GetFocus();
    const bool ownedFocus = owner && priorFocus && IsWindow(priorFocus) &&
        GetAncestor(priorFocus, GA_ROOT) == owner;
    ++rangeDialogDepth;
    const auto ok = DialogBoxIndirectParamW(GetModuleHandleW(nullptr), dlg,
        owner, proc, reinterpret_cast<LPARAM>(&state));
    // After the modal loop exits, Windows has re-enabled its owner. Restore
    // the original title/parameter focus before allowing the REAPER timer to
    // validate the navigation context again. Do not reopen the navigator:
    // doing so would discard its current page/selection or reset its MIDI state.
    if (ownedFocus && IsWindow(owner) && IsWindowVisible(owner) &&
        IsWindowEnabled(owner) && IsWindow(priorFocus)) {
        SetForegroundWindow(owner);
        if (GetForegroundWindow() == owner) SetFocus(priorFocus);
    }
    --rangeDialogDepth;
    if (ok != IDOK || !state.accepted) return false;
    value=state.result;return true;
}
} // namespace lrp
