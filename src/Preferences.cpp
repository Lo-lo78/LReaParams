#include "lrp/Preferences.h"
#include <windows.h>
#include <commctrl.h>
#include <algorithm>
#include <string>
#include <vector>
#include <utility>
#include <cwchar>

namespace lrp {
namespace {
bool nameFirst = true;
constexpr int IDC_TREE = 101, IDC_SCOPE = 102, IDC_SHORTCUTS = 103;
constexpr int IDC_CAPTURE = 104, IDC_MESSAGES = 105, IDC_ADVANCED = 106;
constexpr int kPrefCtrl = 1, kPrefAlt = 2, kPrefShift = 4;
constexpr wchar_t kClassName[] = L"LReaParamsPreferencesV1";

enum class Page { messages = 0, shortcuts = 1, advanced = 2 };
Key shortcut(UINT vk, int mods = 0) {
    Key k{}; k.vk = vk; k.ctrl = (mods & kPrefCtrl) != 0;
    k.alt = (mods & kPrefAlt) != 0; k.shift = (mods & kPrefShift) != 0;
    return k;
}
bool same(const Key& a, const Key& b) {
    return a.vk == b.vk && a.ctrl == b.ctrl && a.alt == b.alt && a.shift == b.shift;
}
void add(Preferences& p, ShortcutScope scope, const wchar_t* name, UINT vk, int mods = 0) {
    const Key k = shortcut(vk, mods);
    p.shortcuts.push_back({name, k, k, scope});
}
void fx(Preferences& p, const wchar_t* name, UINT vk, int mods = 0) { add(p, ShortcutScope::fx, name, vk, mods); }
void track(Preferences& p, const wchar_t* name, UINT vk, int mods = 0) { add(p, ShortcutScope::track, name, vk, mods); }
std::wstring keyName(const Key& k) {
    std::wstring s;
    if (k.ctrl) s += L"Ctrl+";
    if (k.alt) s += L"Alt+";
    if (k.shift) s += L"Shift+";
    wchar_t name[100]{};
    const UINT scan = MapVirtualKeyW(k.vk, MAPVK_VK_TO_VSC);
    const LONG code = static_cast<LONG>(scan << 16) |
        ((k.vk == VK_LEFT || k.vk == VK_RIGHT || k.vk == VK_UP || k.vk == VK_DOWN ||
          k.vk == VK_HOME || k.vk == VK_END || k.vk == VK_DELETE ||
          k.vk == VK_PRIOR || k.vk == VK_NEXT) ? (1L << 24) : 0);
    if (GetKeyNameTextW(code, name, 100) > 0) s += name;
    else s += L"VK " + std::to_wstring(k.vk);
    return s;
}
struct DialogState {
    Preferences pending;
    HWND hwnd{}, tree{}, scope{}, shortcuts{}, capture{}, messages{}, advanced{};
    HWND hint{};
    HTREEITEM nodes[3]{};
    Page page = Page::messages;
    ShortcutScope currentScope = ShortcutScope::fx;
    std::vector<size_t> visible;
    int selectedInScope[2]{};
    bool created = false, capturing = false, accepted = false;
};
int scopeIndex(ShortcutScope scope) { return scope == ShortcutScope::fx ? 0 : 1; }
int listSelection(HWND list) { return static_cast<int>(SendMessageW(list, LB_GETCURSEL, 0, 0)); }
void selectList(HWND list, int position) { SendMessageW(list, LB_SETCURSEL, position, 0); }
void buildChoices(HWND list, int selected, const wchar_t* const* items, int count) {
    SendMessageW(list, LB_RESETCONTENT, 0, 0);
    for (int i = 0; i < count; ++i) {
        std::wstring s = i == selected ? L"Active - " : L"";
        s += items[i];
        SendMessageW(list, LB_ADDSTRING, 0, reinterpret_cast<LPARAM>(s.c_str()));
    }
    selectList(list, selected);
}
void fillShortcuts(DialogState* st) {
    const int selection = st->selectedInScope[scopeIndex(st->currentScope)];
    st->visible.clear();
    SendMessageW(st->shortcuts, LB_RESETCONTENT, 0, 0);
    for (size_t i = 0; i < st->pending.shortcuts.size(); ++i) {
        const auto& e = st->pending.shortcuts[i];
        if (e.scope != st->currentScope) continue;
        st->visible.push_back(i);
        const std::wstring line = keyName(e.assigned) + L" - " + e.description;
        SendMessageW(st->shortcuts, LB_ADDSTRING, 0, reinterpret_cast<LPARAM>(line.c_str()));
    }
    if (!st->visible.empty()) {
        const int selected = std::clamp(selection, 0, static_cast<int>(st->visible.size()) - 1);
        selectList(st->shortcuts, selected);
        st->selectedInScope[scopeIndex(st->currentScope)] = selected;
    }
}
void updateSelection(DialogState* st) {
    const int index = listSelection(st->shortcuts);
    if (index >= 0 && index < static_cast<int>(st->visible.size()))
        st->selectedInScope[scopeIndex(st->currentScope)] = index;
}
void updateChoices(DialogState* st) {
    const wchar_t* const messageOptions[] = {L"Plugin - Track", L"Track - Plugin"};
    const wchar_t* const backendOptions[] = {
        L"1 - REAPER SDK accelerator (recommended default)",
        L"2 - Main-thread keyboard hook (compatibility)"
    };
    buildChoices(st->messages, st->pending.pluginFirst ? 0 : 1, messageOptions, 2);
    buildChoices(st->advanced, st->pending.compatibilityHook ? 1 : 0, backendOptions, 2);
}
void cancelCapture(DialogState* st) {
    st->capturing = false;
    ShowWindow(st->capture, SW_HIDE);
    SetFocus(st->shortcuts);
}
void startCapture(DialogState* st) {
    updateSelection(st);
    if (st->visible.empty()) return;
    st->capturing = true;
    ShowWindow(st->capture, SW_SHOW);
    SetWindowTextW(st->capture, L"Press a new shortcut. Escape cancels.");
    SetFocus(st->capture);
}
void updateTreeLabels(DialogState* st) {
    const wchar_t* names[] = {L"Messages", L"Shortcuts", L"Advanced"};
    for (int i = 0; i < 3; ++i) {
        const std::wstring text = (static_cast<int>(st->page) == i ? L"Active - " : L"") +
            std::wstring(names[i]);
        TVITEMW item{}; item.mask = TVIF_TEXT; item.hItem = st->nodes[i];
        item.pszText = const_cast<wchar_t*>(text.c_str());
        if (item.hItem) SendMessageW(st->tree, TVM_SETITEMW, 0, reinterpret_cast<LPARAM>(&item));
    }
}
void showPage(DialogState* st, Page page) {
    if (!st->created) return;
    st->page = page;
    if (st->capturing) cancelCapture(st);
    ShowWindow(st->messages, page == Page::messages ? SW_SHOW : SW_HIDE);
    ShowWindow(st->advanced, page == Page::advanced ? SW_SHOW : SW_HIDE);
    ShowWindow(st->scope, page == Page::shortcuts ? SW_SHOW : SW_HIDE);
    ShowWindow(st->shortcuts, page == Page::shortcuts ? SW_SHOW : SW_HIDE);
    ShowWindow(st->capture, SW_HIDE);
    if (page == Page::shortcuts) {
        SetWindowTextW(st->hint, L"Select FX Params or Track Params. Enter on a shortcut to change it.");
    } else if (page == Page::messages) {
        SetWindowTextW(st->hint, L"Space changes the message order. The active choice is marked Active.");
    } else {
        SetWindowTextW(st->hint, L"Space changes the keyboard input method. The active choice is marked Active.");
    }
    updateTreeLabels(st);
}
HWND lastPageControl(DialogState* st) {
    switch (st->page) {
        case Page::shortcuts: return st->shortcuts;
        case Page::advanced: return st->advanced;
        default: return st->messages;
    }
}
HWND firstPageControl(DialogState* st) { return st->page == Page::shortcuts ? st->scope : lastPageControl(st); }
void pageTab(DialogState* st, HWND from, bool backward) {
    HWND next = st->tree;
    if (from == st->tree) next = backward ? lastPageControl(st) : firstPageControl(st);
    else if (st->page == Page::shortcuts) {
        if (from == st->scope && !backward) next = st->shortcuts;
        else if (from == st->shortcuts && backward) next = st->scope;
    }
    SetFocus(next);
}
void updateScope(DialogState* st) {
    const int selected = static_cast<int>(SendMessageW(st->scope, CB_GETCURSEL, 0, 0));
    st->currentScope = selected == 1 ? ShortcutScope::track : ShortcutScope::fx;
    fillShortcuts(st);
}
LRESULT CALLBACK pageProc(HWND hwnd, UINT msg, WPARAM wp, LPARAM lp, UINT_PTR, DWORD_PTR ref) {
    auto* st = reinterpret_cast<DialogState*>(ref);
    if (msg == WM_GETDLGCODE) return DefSubclassProc(hwnd, msg, wp, lp) | DLGC_WANTTAB | DLGC_WANTALLKEYS;
    if (msg == WM_KEYDOWN || msg == WM_SYSKEYDOWN) {
        const UINT vk = static_cast<UINT>(wp);
        const bool shift = (GetKeyState(VK_SHIFT) & 0x8000) != 0;
        const bool ctrl = (GetKeyState(VK_CONTROL) & 0x8000) != 0;
        const bool alt = (GetKeyState(VK_MENU) & 0x8000) != 0;
        if (hwnd != st->capture && alt) {
            if (vk == '1' || vk == '2') {
                st->pending.compatibilityHook = vk == '2';
                updateChoices(st); return 0;
            }
            if (vk == 'O' || vk == 'C') {
                SendMessageW(st->hwnd, WM_COMMAND, vk == 'O' ? IDOK : IDCANCEL, 0);
                return 0;
            }
        }
        if (hwnd == st->capture) {
            if (vk == VK_ESCAPE) { cancelCapture(st); return 0; }
            if (vk == VK_TAB && !ctrl && !alt) {
                st->capturing = false; ShowWindow(st->capture, SW_HIDE);
                SetFocus(st->tree); return 0;
            }
            if (vk == VK_CONTROL || vk == VK_MENU || vk == VK_SHIFT ||
                vk == VK_LCONTROL || vk == VK_RCONTROL || vk == VK_LMENU ||
                vk == VK_RMENU || vk == VK_LSHIFT || vk == VK_RSHIFT) return 0;
            const Key candidate = shortcut(vk, (ctrl ? kPrefCtrl : 0) |
                (alt ? kPrefAlt : 0) | (shift ? kPrefShift : 0));
            // Keep REAPER transport, the NVDA modifier and OSARA's peak watchers free.
            if ((!ctrl && !alt && !shift && (vk == VK_SPACE || vk == VK_RETURN)) ||
                (vk == VK_F12 && !ctrl) || vk == VK_INSERT || vk == VK_NUMPAD0 ||
                (vk == VK_SPACE && ctrl) ||
                (alt && (vk == VK_F10 || vk == VK_F11 || vk == VK_F12))) {
                MessageBeep(MB_ICONWARNING);
                SetWindowTextW(hwnd, L"Reserved shortcut. Try another key."); return 0;
            }
            if (st->visible.empty()) return 0;
            const size_t selected = st->visible[static_cast<size_t>(st->selectedInScope[scopeIndex(st->currentScope)])];
            for (size_t i = 0; i < st->pending.shortcuts.size(); ++i) {
                if (i != selected && st->pending.shortcuts[i].scope == st->currentScope &&
                    same(st->pending.shortcuts[i].assigned, candidate)) {
                    MessageBeep(MB_ICONWARNING);
                    SetWindowTextW(hwnd, L"Already assigned in this list. Try another key."); return 0;
                }
            }
            st->pending.shortcuts[selected].assigned = candidate;
            fillShortcuts(st);
            cancelCapture(st);
            return 0;
        }
        if (vk == VK_TAB && !ctrl && !alt) { pageTab(st, hwnd, shift); return 0; }
        if (vk == VK_RETURN && ctrl && !alt) {
            SendMessageW(st->hwnd, WM_COMMAND, IDOK, 0); return 0;
        }
        if (vk == VK_ESCAPE && !ctrl && !alt) {
            SendMessageW(st->hwnd, WM_COMMAND, IDCANCEL, 0); return 0;
        }
        if (hwnd == st->shortcuts && vk == VK_RETURN && !ctrl && !alt) {
            startCapture(st); return 0;
        }
        if ((hwnd == st->messages || hwnd == st->advanced) && vk == VK_SPACE && !ctrl && !alt) {
            const int count = static_cast<int>(SendMessageW(hwnd, LB_GETCOUNT, 0, 0));
            if (count > 0) {
                const int next = (listSelection(hwnd) + 1) % count;
                selectList(hwnd, next);
                SendMessageW(st->hwnd, WM_COMMAND,
                    MAKEWPARAM(GetDlgCtrlID(hwnd), LBN_SELCHANGE), reinterpret_cast<LPARAM>(hwnd));
            }
            return 0;
        }
    }
    return DefSubclassProc(hwnd, msg, wp, lp);
}
LRESULT CALLBACK wndProc(HWND hwnd, UINT msg, WPARAM wp, LPARAM lp) {
    auto* st = reinterpret_cast<DialogState*>(GetWindowLongPtrW(hwnd, GWLP_USERDATA));
    if (msg == WM_CREATE) {
        st = reinterpret_cast<DialogState*>(reinterpret_cast<CREATESTRUCTW*>(lp)->lpCreateParams);
        st->hwnd = hwnd;
        SetWindowLongPtrW(hwnd, GWLP_USERDATA, reinterpret_cast<LONG_PTR>(st));
        st->hint = CreateWindowW(L"STATIC", L"", WS_VISIBLE | WS_CHILD,
            252, 12, 472, 27, hwnd, nullptr, nullptr, nullptr);
        CreateWindowW(L"STATIC", L"Choose a page. Tab navigates the page and tree. Ctrl+Enter saves; Escape cancels.",
            WS_VISIBLE | WS_CHILD, 16, 12, 226, 51, hwnd, nullptr, nullptr, nullptr);
        st->tree = CreateWindowExW(WS_EX_CLIENTEDGE, WC_TREEVIEWW, L"",
            WS_VISIBLE | WS_CHILD | WS_TABSTOP | TVS_SHOWSELALWAYS | TVS_DISABLEDRAGDROP,
            16, 70, 219, 348, hwnd, reinterpret_cast<HMENU>(static_cast<INT_PTR>(IDC_TREE)), nullptr, nullptr);
        st->scope = CreateWindowExW(WS_EX_CLIENTEDGE, L"COMBOBOX", L"",
            WS_CHILD | WS_TABSTOP | CBS_DROPDOWNLIST | WS_VSCROLL,
            252, 57, 465, 180, hwnd, reinterpret_cast<HMENU>(static_cast<INT_PTR>(IDC_SCOPE)), nullptr, nullptr);
        st->shortcuts = CreateWindowExW(WS_EX_CLIENTEDGE, L"LISTBOX", L"",
            WS_CHILD | WS_TABSTOP | WS_VSCROLL | LBS_NOTIFY | LBS_NOINTEGRALHEIGHT,
            252, 93, 465, 282, hwnd, reinterpret_cast<HMENU>(static_cast<INT_PTR>(IDC_SHORTCUTS)), nullptr, nullptr);
        st->capture = CreateWindowExW(WS_EX_CLIENTEDGE, L"EDIT", L"",
            WS_CHILD | WS_TABSTOP | ES_READONLY,
            252, 380, 465, 29, hwnd, reinterpret_cast<HMENU>(static_cast<INT_PTR>(IDC_CAPTURE)), nullptr, nullptr);
        st->messages = CreateWindowExW(WS_EX_CLIENTEDGE, L"LISTBOX", L"",
            WS_CHILD | WS_TABSTOP | LBS_NOTIFY,
            252, 55, 465, 120, hwnd, reinterpret_cast<HMENU>(static_cast<INT_PTR>(IDC_MESSAGES)), nullptr, nullptr);
        st->advanced = CreateWindowExW(WS_EX_CLIENTEDGE, L"LISTBOX", L"",
            WS_CHILD | WS_TABSTOP | LBS_NOTIFY,
            252, 55, 465, 120, hwnd, reinterpret_cast<HMENU>(static_cast<INT_PTR>(IDC_ADVANCED)), nullptr, nullptr);
        CreateWindowW(L"BUTTON", L"&OK", WS_CHILD | WS_VISIBLE | WS_TABSTOP | BS_DEFPUSHBUTTON,
            508, 434, 98, 32, hwnd, reinterpret_cast<HMENU>(static_cast<INT_PTR>(IDOK)), nullptr, nullptr);
        CreateWindowW(L"BUTTON", L"&Cancel", WS_CHILD | WS_VISIBLE | WS_TABSTOP,
            618, 434, 98, 32, hwnd, reinterpret_cast<HMENU>(static_cast<INT_PTR>(IDCANCEL)), nullptr, nullptr);
        for (HWND control : {st->tree, st->scope, st->shortcuts, st->capture, st->messages, st->advanced, st->hint})
            SendMessageW(control, WM_SETFONT, reinterpret_cast<WPARAM>(GetStockObject(DEFAULT_GUI_FONT)), TRUE);
        for (HWND control : {st->tree, st->scope, st->shortcuts, st->capture, st->messages, st->advanced})
            SetWindowSubclass(control, pageProc, 1, reinterpret_cast<DWORD_PTR>(st));
        SendMessageW(st->scope, CB_ADDSTRING, 0, reinterpret_cast<LPARAM>(L"FX Params"));
        SendMessageW(st->scope, CB_ADDSTRING, 0, reinterpret_cast<LPARAM>(L"Track Params"));
        SendMessageW(st->scope, CB_SETCURSEL, 0, 0);
        fillShortcuts(st);
        updateChoices(st);
        const wchar_t* nodes[] = {L"Messages", L"Shortcuts", L"Advanced"};
        for (int i = 0; i < 3; ++i) {
            TVINSERTSTRUCTW item{};
            item.hParent = TVI_ROOT; item.hInsertAfter = TVI_LAST;
            item.item.mask = TVIF_TEXT;
            item.item.pszText = const_cast<wchar_t*>(nodes[i]);
            st->nodes[i] = reinterpret_cast<HTREEITEM>(SendMessageW(st->tree, TVM_INSERTITEMW,
                0, reinterpret_cast<LPARAM>(&item)));
        }
        st->created = true;
        showPage(st, Page::messages);
        SendMessageW(st->tree, TVM_SELECTITEM, TVGN_CARET, reinterpret_cast<LPARAM>(st->nodes[0]));
        return 0;
    }
    if (!st) return DefWindowProcW(hwnd, msg, wp, lp);
    if (msg == WM_NOTIFY && st->created && reinterpret_cast<LPNMHDR>(lp)->idFrom == IDC_TREE &&
        reinterpret_cast<LPNMHDR>(lp)->code == TVN_SELCHANGEDW) {
        const HTREEITEM selected = reinterpret_cast<LPNMTREEVIEWW>(lp)->itemNew.hItem;
        for (int i = 0; i < 3; ++i)
            if (st->nodes[i] == selected) { showPage(st, static_cast<Page>(i)); break; }
        return 0;
    }
    if (msg == WM_SYSKEYDOWN && (GetKeyState(VK_MENU) & 0x8000) && (wp == '1' || wp == '2')) {
        st->pending.compatibilityHook = wp == '2';
        updateChoices(st);
        return 0;
    }
    if (msg == WM_SYSCHAR && (GetKeyState(VK_MENU) & 0x8000)) {
        if (wp == 'o' || wp == 'O') { SendMessageW(hwnd, WM_COMMAND, IDOK, 0); return 0; }
        if (wp == 'c' || wp == 'C') { SendMessageW(hwnd, WM_COMMAND, IDCANCEL, 0); return 0; }
    }
    if (msg == WM_COMMAND) {
        const int id = LOWORD(wp);
        const int notice = HIWORD(wp);
        if (id == IDOK || id == IDCANCEL) {
            st->accepted = id == IDOK;
            st->hwnd = nullptr;
            SetWindowLongPtrW(hwnd, GWLP_USERDATA, 0);
            DestroyWindow(hwnd);
            return 0;
        }
        if (id == IDC_SCOPE && notice == CBN_SELCHANGE) { updateScope(st); return 0; }
        if (id == IDC_SHORTCUTS && notice == LBN_SELCHANGE) { updateSelection(st); return 0; }
        if (id == IDC_SHORTCUTS && notice == LBN_DBLCLK) { startCapture(st); return 0; }
        if (id == IDC_MESSAGES && notice == LBN_SELCHANGE) {
            st->pending.pluginFirst = listSelection(st->messages) == 0;
            updateChoices(st); return 0;
        }
        if (id == IDC_ADVANCED && notice == LBN_SELCHANGE) {
            st->pending.compatibilityHook = listSelection(st->advanced) == 1;
            updateChoices(st); return 0;
        }
    }
    if (msg == WM_CLOSE) { SendMessageW(hwnd, WM_COMMAND, IDCANCEL, 0); return 0; }
    return DefWindowProcW(hwnd, msg, wp, lp);
}
} // namespace

Preferences defaultPreferences() {
    Preferences p;
    // Preserve indices 0..31 from the original Preferences TEST: existing
    // Preferences.ini files keep their remappings after this UI update.
    fx(p, L"Find parameter", 'F', kPrefCtrl);
    fx(p, L"Switch between FX Params and Track Params", VK_TAB, kPrefCtrl);
    fx(p, L"FX Memories", 'M', kPrefCtrl | kPrefShift);
    fx(p, L"Back to REAPER, keep MIDI running", 'Q', kPrefCtrl);
    fx(p, L"Previous FX", VK_UP, kPrefCtrl);
    fx(p, L"Next FX", VK_DOWN, kPrefCtrl);
    fx(p, L"Move FX, previous", VK_PRIOR, kPrefCtrl);
    fx(p, L"Move FX, next", VK_NEXT, kPrefCtrl);
    fx(p, L"Previous track", VK_UP, kPrefCtrl | kPrefShift);
    fx(p, L"Next track", VK_DOWN, kPrefCtrl | kPrefShift);
    fx(p, L"Open native FX chain", 'F', kPrefCtrl | kPrefShift);
    fx(p, L"Open native FX browser", 'F', kPrefAlt | kPrefShift);
    fx(p, L"FX browser / parameter grid", VK_F10);
    fx(p, L"FX audio pin connector", VK_F11);
    fx(p, L"FX parameter keyboard theme", VK_F4);
    fx(p, L"FX parameter comparison", VK_F8);
    fx(p, L"Read current FX context", VK_TAB);
    fx(p, L"Change Grid / Value", VK_RETURN);
    fx(p, L"Decrease parameter step", VK_LEFT, kPrefAlt);
    fx(p, L"Increase parameter step", VK_RIGHT, kPrefAlt);
    fx(p, L"Reset parameter value", VK_BACK);
    fx(p, L"Reset parameter step", VK_BACK, kPrefCtrl);
    fx(p, L"Reset all FX values", VK_BACK, kPrefCtrl | kPrefShift);
    fx(p, L"Copy parameter value / F7 selection", 'C', kPrefCtrl);
    fx(p, L"Paste parameter value", 'V', kPrefCtrl);
    fx(p, L"Used parameters", 'L', kPrefCtrl | kPrefShift);
    track(p, L"Tracks page", VK_F1);
    track(p, L"Sends page", VK_F2);
    track(p, L"Receives page", VK_F3);
    track(p, L"Track MIDI page", VK_F5);
    track(p, L"Hardware outputs page", VK_F6);
    track(p, L"ReaRoute page", VK_F7);

    // More FX Params gestures, supported by the native input router and
    // navigator. Shortcut descriptions explain their contextual behavior.
    fx(p, L"Decrease grid height", VK_F1);
    fx(p, L"Increase grid height", VK_F2);
    fx(p, L"Announce grid and step", VK_F3);
    fx(p, L"Edit parameter order / groups", VK_F7);
    fx(p, L"Plugin Order / Custom Order", 'L', kPrefCtrl);
    fx(p, L"Toggle FX bypass", 'B', kPrefCtrl);
    fx(p, L"Toggle FX Delta Solo", 'D', kPrefCtrl);
    fx(p, L"Clear project FX Delta Solo", 'D', kPrefCtrl | kPrefShift);
    fx(p, L"FX offline / online", 'B', kPrefCtrl | kPrefAlt);
    fx(p, L"Return from Take FX to Track FX", 'W', kPrefCtrl);
    fx(p, L"Previous item with Take FX", VK_LEFT, kPrefCtrl);
    fx(p, L"Next item with Take FX", VK_RIGHT, kPrefCtrl);
    fx(p, L"Numeric parameter editing", 'E', kPrefCtrl);
    fx(p, L"Recent parameter searches", 'R', kPrefCtrl);
    fx(p, L"Read complete FX status", 'R', kPrefCtrl | kPrefShift);
    fx(p, L"MIDI CC learn", 'C', kPrefCtrl | kPrefAlt);
    fx(p, L"Fixed MIDI CC on / off", 'C', kPrefShift);
    fx(p, L"Floating MIDI CC capture", 'C', kPrefCtrl | kPrefShift);
    fx(p, L"MIDI CC parameter speech", 'T', kPrefCtrl);
    fx(p, L"Toggle parameter automation", 'A', kPrefCtrl | kPrefShift);
    fx(p, L"Confirm clear FX automation", 'A', kPrefCtrl | kPrefShift | kPrefAlt);
    fx(p, L"Previous FX preset", VK_F1, kPrefAlt);
    fx(p, L"Next FX preset", VK_F2, kPrefAlt);
    fx(p, L"Previous automated parameter", VK_F3, kPrefAlt);
    fx(p, L"Next automated parameter", VK_F4, kPrefAlt);
    fx(p, L"Groups mode", 'G', kPrefAlt);
    fx(p, L"Memory positions mode", 'M', kPrefAlt);
    fx(p, L"Copy entire FX snapshot", 'C', kPrefCtrl | kPrefAlt | kPrefShift);
    fx(p, L"Reset grid to 10 (double press: numeric size)", VK_BACK, kPrefShift);
    fx(p, L"First parameter", VK_HOME, kPrefCtrl);
    fx(p, L"Last parameter", VK_END, kPrefCtrl);
    fx(p, L"Set value to maximum", VK_HOME, kPrefAlt);
    fx(p, L"Set value to minimum", VK_END, kPrefAlt);
    fx(p, L"Increase value", VK_UP, kPrefAlt);
    fx(p, L"Decrease value", VK_DOWN, kPrefAlt);
    fx(p, L"Increase value (coarse)", VK_PRIOR, kPrefAlt);
    fx(p, L"Decrease value (coarse)", VK_NEXT, kPrefAlt);
    fx(p, L"Select parameter in F7 / Memories", VK_SPACE, kPrefShift);
    fx(p, L"Cut selection in F7", 'X', kPrefCtrl);
    fx(p, L"Select all in F7 / Memories", 'A', kPrefCtrl);
    fx(p, L"Undo F7 editor", 'Z', kPrefCtrl);
    fx(p, L"Redo F7 editor", 'Y', kPrefCtrl);
    fx(p, L"Remove group occurrences in F7", VK_DELETE, kPrefCtrl);
    fx(p, L"Hide selected parameters in F7", VK_DELETE, kPrefCtrl | kPrefShift);
    fx(p, L"Rename parameter or group in F7", VK_RETURN, kPrefCtrl);
    for (int i = 0; i < 12; ++i) {
        fx(p, (L"Recall FX group / memory " + std::to_wstring(i + 1)).c_str(), VK_F1 + i, kPrefCtrl);
        fx(p, (L"Store FX group / memory " + std::to_wstring(i + 1)).c_str(), VK_F1 + i, kPrefCtrl | kPrefShift);
    }
    fx(p, L"Previous marker", 'I', kPrefCtrl);
    fx(p, L"Next marker", 'O', kPrefCtrl);
    fx(p, L"Previous beat", VK_PRIOR, kPrefCtrl | kPrefAlt);
    fx(p, L"Next beat", VK_NEXT, kPrefCtrl | kPrefAlt);
    fx(p, L"Previous measure", VK_PRIOR, kPrefAlt | kPrefShift);
    fx(p, L"Next measure", VK_NEXT, kPrefAlt | kPrefShift);
    fx(p, L"Previous measure start", VK_PRIOR, kPrefCtrl | kPrefAlt | kPrefShift);
    fx(p, L"Next measure start", VK_NEXT, kPrefCtrl | kPrefAlt | kPrefShift);
    for (int i = 1; i <= 10; ++i)
        fx(p, (L"Jump to marker " + std::to_wstring(i)).c_str(),
            i == 10 ? '0' : '0' + i, kPrefCtrl);
    fx(p, L"Navigate parameter up", VK_UP);
    fx(p, L"Navigate parameter down", VK_DOWN);
    fx(p, L"Navigate parameter left", VK_LEFT);
    fx(p, L"Navigate parameter right", VK_RIGHT);
    fx(p, L"Navigate parameter Page Up", VK_PRIOR);
    fx(p, L"Navigate parameter Page Down", VK_NEXT);
    fx(p, L"Navigate to first visible parameter", VK_HOME);
    fx(p, L"Navigate to last visible parameter", VK_END);

    // Track Params keeps independent assignments, including keys that also
    // exist on the FX page. The original 32 values above stay index-stable.
    track(p, L"FX TCP page", VK_F4);
    track(p, L"Switch between Track Params and FX Params", VK_TAB, kPrefCtrl);
    track(p, L"Track Memories", 'M', kPrefCtrl | kPrefShift);
    track(p, L"Back to REAPER, keep MIDI running", 'Q', kPrefCtrl);
    track(p, L"Search tracks / routing", 'F', kPrefCtrl);
    track(p, L"Read current track parameter", VK_TAB);
    track(p, L"Change Grid / Value", VK_RETURN);
    track(p, L"Add Send", 'S', kPrefCtrl | kPrefShift);
    track(p, L"Add Receive", 'R', kPrefCtrl | kPrefShift);
    track(p, L"Numeric parameter editing", 'E', kPrefCtrl);
    track(p, L"Toggle current automation", 'A', kPrefCtrl | kPrefShift);
    track(p, L"Confirm clear track automation", 'A', kPrefCtrl | kPrefShift | kPrefAlt);
    track(p, L"MIDI CC learn", 'C', kPrefCtrl | kPrefAlt);
    track(p, L"Fixed MIDI CC on / off", 'C', kPrefShift);
    track(p, L"Floating MIDI CC capture", 'C', kPrefCtrl | kPrefShift);
    track(p, L"MIDI CC parameter speech", 'T', kPrefCtrl);
    track(p, L"Toggle value speech", 'T', kPrefCtrl | kPrefShift);
    track(p, L"Track volume range editor", 'I', kPrefCtrl | kPrefShift);
    track(p, L"Reset parameter step", VK_BACK, kPrefCtrl);
    track(p, L"Copy tracks and routing in F1", 'C', kPrefCtrl);
    track(p, L"Cut tracks and routing in F1", 'X', kPrefCtrl);
    track(p, L"Paste tracks and routing in F1", 'V', kPrefCtrl);
    track(p, L"Select all visible tracks in F1", 'A', kPrefCtrl);
    track(p, L"Clear selected tracks in F1", VK_DELETE, kPrefCtrl | kPrefShift);
    track(p, L"Select current track / memory entry", VK_SPACE, kPrefShift);
    track(p, L"Toggle current track selection in F1", VK_SPACE, kPrefCtrl | kPrefShift);
    track(p, L"Extend selection Page Up in F1", VK_PRIOR, kPrefShift);
    track(p, L"Extend selection Page Down in F1", VK_NEXT, kPrefShift);
    track(p, L"Extend track selection upward in F1", VK_UP, kPrefShift);
    track(p, L"Extend track selection downward in F1", VK_DOWN, kPrefShift);
    track(p, L"Move selected tracks up in F1", VK_UP, kPrefAlt | kPrefShift);
    track(p, L"Move selected tracks down in F1", VK_DOWN, kPrefAlt | kPrefShift);
    track(p, L"Previous folder in F1", VK_UP, kPrefCtrl | kPrefAlt);
    track(p, L"Next folder in F1", VK_DOWN, kPrefCtrl | kPrefAlt);
    track(p, L"Extend selection to previous track", VK_UP, kPrefCtrl | kPrefShift);
    track(p, L"Extend selection to next track", VK_DOWN, kPrefCtrl | kPrefShift);
    track(p, L"Toggle folder in F1", VK_RETURN, kPrefCtrl);
    track(p, L"Previous track in F2/F3", VK_UP, kPrefCtrl);
    track(p, L"Next track in F2/F3", VK_DOWN, kPrefCtrl);
    track(p, L"Delete current routing in F2/F3", VK_DELETE);
    track(p, L"Parameter up", VK_UP);
    track(p, L"Parameter down", VK_DOWN);
    track(p, L"Parameter left", VK_LEFT);
    track(p, L"Parameter right", VK_RIGHT);
    track(p, L"Parameter Page Up", VK_PRIOR);
    track(p, L"Parameter Page Down", VK_NEXT);
    track(p, L"First parameter", VK_HOME);
    track(p, L"Last parameter", VK_END);
    track(p, L"Increase value", VK_UP, kPrefAlt);
    track(p, L"Decrease value", VK_DOWN, kPrefAlt);
    track(p, L"Increase value (coarse)", VK_PRIOR, kPrefAlt);
    track(p, L"Decrease value (coarse)", VK_NEXT, kPrefAlt);
    track(p, L"Set value to maximum", VK_HOME, kPrefAlt);
    track(p, L"Set value to minimum", VK_END, kPrefAlt);
    for (int i = 0; i < 12; ++i) {
        track(p, (L"Recall track memory " + std::to_wstring(i + 1)).c_str(), VK_F1 + i, kPrefCtrl);
        track(p, (L"Store track memory " + std::to_wstring(i + 1)).c_str(), VK_F1 + i, kPrefCtrl | kPrefShift);
    }
    track(p, L"Previous marker", 'I', kPrefCtrl);
    track(p, L"Next marker", 'O', kPrefCtrl);
    track(p, L"Previous beat", VK_PRIOR, kPrefCtrl | kPrefAlt);
    track(p, L"Next beat", VK_NEXT, kPrefCtrl | kPrefAlt);
    track(p, L"Previous measure", VK_PRIOR, kPrefAlt | kPrefShift);
    track(p, L"Next measure", VK_NEXT, kPrefAlt | kPrefShift);
    track(p, L"Previous measure start", VK_PRIOR, kPrefCtrl | kPrefAlt | kPrefShift);
    track(p, L"Next measure start", VK_NEXT, kPrefCtrl | kPrefAlt | kPrefShift);
    for (int i = 1; i <= 10; ++i)
        track(p, (L"Jump to marker " + std::to_wstring(i)).c_str(),
            i == 10 ? '0' : '0' + i, kPrefCtrl);
    // Deduplicate aliases used in different screens: one physical gesture gets
    // one binding per navigator, with a description covering its contexts.
    std::vector<ShortcutPreference> unique;
    unique.reserve(p.shortcuts.size());
    for (auto& entry : p.shortcuts) {
        const bool existing = std::any_of(unique.begin(), unique.end(), [&](const ShortcutPreference& other) {
            return entry.scope == other.scope && same(entry.original, other.original);
        });
        if (!existing) unique.push_back(std::move(entry));
    }
    return Preferences{p.pluginFirst, p.compatibilityHook, std::move(unique)};
}
Preferences loadPreferences(const std::filesystem::path& file) {
    Preferences p = defaultPreferences();
    const std::wstring path = file.wstring();
    p.pluginFirst = GetPrivateProfileIntW(L"Messages", L"PluginFirst", 1, path.c_str()) != 0;
    p.compatibilityHook = GetPrivateProfileIntW(L"Keyboard", L"CompatibilityHook", 0, path.c_str()) != 0;
    for (size_t i = 0; i < p.shortcuts.size(); ++i) {
        const std::wstring key = L"Shortcut" + std::to_wstring(i);
        const int value = GetPrivateProfileIntW(L"Shortcuts", key.c_str(), -1, path.c_str());
        if (value < 0) continue;
        const Key candidate = shortcut(static_cast<UINT>(value & 255), value >> 8);
        if (!candidate.vk || candidate.vk == VK_ESCAPE || (candidate.vk == VK_F12 && !candidate.ctrl)) continue;
        bool duplicate = false;
        for (size_t j = 0; j < p.shortcuts.size(); ++j)
            if (i != j && p.shortcuts[i].scope == p.shortcuts[j].scope &&
                same(p.shortcuts[j].assigned, candidate)) { duplicate = true; break; }
        if (!duplicate) p.shortcuts[i].assigned = candidate;
    }
    return p;
}
bool savePreferences(const std::filesystem::path& file, const Preferences& p) {
    const std::wstring path = file.wstring();
    if (!WritePrivateProfileStringW(L"Messages", L"PluginFirst", p.pluginFirst ? L"1" : L"0", path.c_str())) return false;
    if (!WritePrivateProfileStringW(L"Keyboard", L"CompatibilityHook", p.compatibilityHook ? L"1" : L"0", path.c_str())) return false;
    for (size_t i = 0; i < p.shortcuts.size(); ++i) {
        const Key& k = p.shortcuts[i].assigned;
        const int encoded = static_cast<int>(k.vk) |
            (k.ctrl ? kPrefCtrl << 8 : 0) | (k.alt ? kPrefAlt << 8 : 0) | (k.shift ? kPrefShift << 8 : 0);
        const std::wstring name = L"Shortcut" + std::to_wstring(i), value = std::to_wstring(encoded);
        if (!WritePrivateProfileStringW(L"Shortcuts", name.c_str(), value.c_str(), path.c_str())) return false;
    }
    return true;
}
std::optional<Preferences> editPreferences(HWND owner, const Preferences& current) {
    static bool registered = false;
    if (!registered) {
        INITCOMMONCONTROLSEX common{sizeof(INITCOMMONCONTROLSEX), ICC_TREEVIEW_CLASSES};
        if (!InitCommonControlsEx(&common)) return std::nullopt;
        WNDCLASSW wc{}; wc.lpfnWndProc = wndProc; wc.hInstance = GetModuleHandleW(nullptr);
        wc.lpszClassName = kClassName; wc.hCursor = LoadCursorW(nullptr, IDC_ARROW);
        wc.hbrBackground = reinterpret_cast<HBRUSH>(COLOR_BTNFACE + 1);
        if (!RegisterClassW(&wc) && GetLastError() != ERROR_CLASS_ALREADY_EXISTS) return std::nullopt;
        registered = true;
    }
    DialogState state; state.pending = current;
    HWND hwnd = CreateWindowExW(WS_EX_DLGMODALFRAME | WS_EX_CONTROLPARENT,
        kClassName, L"LReaParams - Preferences", WS_POPUP | WS_CAPTION | WS_SYSMENU | WS_VISIBLE,
        CW_USEDEFAULT, CW_USEDEFAULT, 752, 512, owner, nullptr, GetModuleHandleW(nullptr), &state);
    if (!hwnd) return std::nullopt;
    EnableWindow(owner,FALSE); SetForegroundWindow(hwnd); SetFocus(state.tree);
    MSG msg{};
    while (state.hwnd && GetMessageW(&msg, nullptr, 0, 0) > 0) {
        if (!IsDialogMessageW(hwnd, &msg)) { TranslateMessage(&msg); DispatchMessageW(&msg); }
    }
    EnableWindow(owner,TRUE); SetForegroundWindow(owner);
    return state.accepted ? std::make_optional(state.pending) : std::nullopt;
}
Key mapPreferredShortcut(Key key, const Preferences& p, ShortcutScope scope) noexcept {
    if (key.altGr) return key;
    for (const auto& entry : p.shortcuts) {
        if (entry.scope != scope || !same(key, entry.assigned)) continue;
        Key out = key;
        out.vk = entry.original.vk; out.ctrl = entry.original.ctrl;
        out.alt = entry.original.alt; out.shift = entry.original.shift;
        if (out.vk != key.vk) out.character = 0;
        return out;
    }
    for (const auto& entry : p.shortcuts) {
        if (entry.scope == scope && !same(entry.original, entry.assigned) &&
            same(key, entry.original)) { key.vk = 0; return key; }
    }
    return key;
}
void setFxNameFirst(bool value) noexcept { nameFirst = value; }
bool fxNameFirst() noexcept { return nameFirst; }
} // namespace lrp
