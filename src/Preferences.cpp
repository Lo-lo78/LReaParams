#include "lrp/Preferences.h"
#include <windows.h>
#include <commctrl.h>
#include <algorithm>
#include <string>
#include <vector>
#include <utility>
#include <cwchar>
#include <array>
#include <cwctype>

namespace lrp {
namespace {
bool nameFirst = true;
TitleMessage activeFxTitle{};
TitleMessage activeTrackTitle;
constexpr int IDC_TREE = 101, IDC_SHORTCUTS = 103;
constexpr int IDC_CAPTURE = 104, IDC_MESSAGES = 105, IDC_ADVANCED = 106;
constexpr int IDC_MESSAGE_TOPICS = 107, IDC_CUSTOM_EDIT = 108;
constexpr int kPrefCtrl = 1, kPrefAlt = 2, kPrefShift = 4;
constexpr wchar_t kClassName[] = L"LReaParamsPreferencesV1";

enum class Page { messages = 0, shortcuts = 1, advanced = 2 };
int titlePartCount(ShortcutScope scope) { return scope == ShortcutScope::fx ? 4 : 3; }
int customPart(ShortcutScope scope) { return titlePartCount(scope) - 1; }
TitleMessage& titleFor(Preferences& p, ShortcutScope scope) {
    return scope == ShortcutScope::fx ? p.fxTitle : p.trackTitle;
}
const TitleMessage& titleFor(const Preferences& p, ShortcutScope scope) {
    return scope == ShortcutScope::fx ? p.fxTitle : p.trackTitle;
}
void normalizeTitle(TitleMessage& title, int count) {
    // Guard user-edited/corrupt INI files: a template must be a permutation.
    std::array<bool, 4> seen{};
    for (int i = 0; i < count; ++i) {
        const int part = title.order[static_cast<size_t>(i)];
        if (part < 0 || part >= count || seen[static_cast<size_t>(part)]) {
            for (int j = 0; j < count; ++j) title.order[static_cast<size_t>(j)] = j;
            break;
        }
        seen[static_cast<size_t>(part)] = true;
    }
    if (title.custom.size() > 240) title.custom.resize(240);
    for (auto& c : title.custom) if (c == L'\r' || c == L'\n' || c == L'\t') c = L' ';
    title.enabled[static_cast<size_t>(count - 1)] = !title.custom.empty();
}

Key shortcut(UINT vk, int mods = 0) {
    Key k{}; k.vk = vk; k.ctrl = (mods & kPrefCtrl) != 0;
    k.alt = (mods & kPrefAlt) != 0; k.shift = (mods & kPrefShift) != 0;
    return k;
}
bool same(const Key& a, const Key& b) {
    return a.vk == b.vk && a.ctrl == b.ctrl && a.alt == b.alt && a.shift == b.shift;
}
// Use UTF-8 for OSARA's outputMessage API. Never create a blocking dialog.
std::string toUtf8(const std::wstring& text) {
    if (text.empty()) return {};
    const int bytes = WideCharToMultiByte(CP_UTF8, 0, text.c_str(),
        static_cast<int>(text.size()), nullptr, 0, nullptr, nullptr);
    if (bytes <= 0) return {};
    std::string result(static_cast<size_t>(bytes), '\0');
    WideCharToMultiByte(CP_UTF8, 0, text.c_str(), static_cast<int>(text.size()),
        result.data(), bytes, nullptr, nullptr);
    return result;
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
// Deliberately use the native TreeView's accessible selection state.
// No additional spoken status prefixes or selection-reinsertion are needed.
constexpr UINT kRestoreFocus = WM_APP + 31;
struct DialogState {
    Preferences pending;
    std::function<void(const std::string&)> announce;
    HWND hwnd{}, tree{}, shortcuts{}, capture{}, messages{}, advanced{};
    HWND messageTopics{}, customLabel{}, customEdit{};
    HWND ok{}, cancel{}, lastFocused{};
    HTREEITEM nodes[3]{}, fxNode{}, trackNode{}, fxMsgNode{}, trackMsgNode{};
    Page page = Page::messages;
    ShortcutScope currentScope = ShortcutScope::fx;
    ShortcutScope messageScope = ShortcutScope::fx;
    std::vector<size_t> visible;
    int selectedInScope[2]{};
    bool created = false, capturing = false, editingCustom = false, accepted = false;
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
void fillMessageParts(DialogState* st, int selected = 0) {
    TitleMessage& cfg = titleFor(st->pending, st->messageScope);
    const int count = titlePartCount(st->messageScope);
    const wchar_t* fxNames[] = {L"FX Params", L"Plugin", L"Track", L"Custom message"};
    const wchar_t* trackNames[] = {L"Track Params", L"Track", L"Custom message"};
    SendMessageW(st->messages, LB_RESETCONTENT, 0, 0);
    for (int i = 0; i < count; ++i) {
        const int part = cfg.order[static_cast<size_t>(i)];
        const bool custom = part == customPart(st->messageScope);
        std::wstring line = custom ? L"Custom message" :
            (st->messageScope == ShortcutScope::fx ? fxNames[part] : trackNames[part]);
        if (custom) {
            if (!cfg.custom.empty()) line += L": " + cfg.custom;
            line += L" (Enter to edit)";
        } else if (!cfg.enabled[static_cast<size_t>(part)]) line = L"Disabled - " + line;
        SendMessageW(st->messages, LB_ADDSTRING, 0, reinterpret_cast<LPARAM>(line.c_str()));
    }
    selectList(st->messages, std::clamp(selected, 0, count - 1));
}
void updateChoices(DialogState* st) {
    const wchar_t* const backendOptions[] = {
        L"1 - REAPER SDK accelerator (recommended default)",
        L"2 - Main-thread keyboard hook (compatibility)"
    };
    buildChoices(st->advanced, st->pending.compatibilityHook ? 1 : 0, backendOptions, 2);
}
void closeCustomEditor(DialogState* st, bool commit) {
    if (!st->editingCustom) return;
    if (commit) {
        wchar_t buffer[241]{};
        GetWindowTextW(st->customEdit, buffer, 241);
        TitleMessage& cfg = titleFor(st->pending, st->messageScope);
        cfg.custom = buffer;
        normalizeTitle(cfg, titlePartCount(st->messageScope));
    }
    st->editingCustom = false;
    ShowWindow(st->customEdit, SW_HIDE);
    ShowWindow(st->customLabel, SW_HIDE);
    const int selection = listSelection(st->messages);
    fillMessageParts(st, selection);
    SetFocus(st->messages);
}
void startCustomEditor(DialogState* st) {
    const int selection = listSelection(st->messages);
    const TitleMessage& cfg = titleFor(st->pending, st->messageScope);
    const int count = titlePartCount(st->messageScope);
    if (selection < 0 || selection >= count ||
        cfg.order[static_cast<size_t>(selection)] != customPart(st->messageScope)) return;
    st->editingCustom = true;
    SetWindowTextW(st->customEdit, cfg.custom.c_str());
    ShowWindow(st->customLabel, SW_SHOW);
    ShowWindow(st->customEdit, SW_SHOW);
    SetFocus(st->customEdit);
    SendMessageW(st->customEdit, EM_SETSEL, 0, -1);
}
void toggleMessagePart(DialogState* st) {
    const int selected = listSelection(st->messages);
    const int count = titlePartCount(st->messageScope);
    if (selected < 0 || selected >= count) return;
    TitleMessage& cfg = titleFor(st->pending, st->messageScope);
    const int part = cfg.order[static_cast<size_t>(selected)];
    if (part == customPart(st->messageScope)) return; // Custom is edited using Enter.
    cfg.enabled[static_cast<size_t>(part)] = !cfg.enabled[static_cast<size_t>(part)];
    fillMessageParts(st, selected);
    // Report the resulting state immediately without opening a confirmation.
    const wchar_t* fxNames[] = {L"FX Params", L"Plugin", L"Track"};
    const wchar_t* trackNames[] = {L"Track Params", L"Track"};
    const std::wstring feedback = std::wstring(cfg.enabled[static_cast<size_t>(part)] ? L"Enabled - " : L"Disabled - ") +
        (st->messageScope == ShortcutScope::fx ? fxNames[part] : trackNames[part]);
    if (st->announce) st->announce(toUtf8(feedback));
}
void reorderMessagePart(DialogState* st, int direction) {
    const int selected = listSelection(st->messages);
    const int count = titlePartCount(st->messageScope);
    const int dest = selected + direction;
    if (selected < 0 || dest < 0 || dest >= count) return;
    auto& order = titleFor(st->pending, st->messageScope).order;
    std::swap(order[static_cast<size_t>(selected)], order[static_cast<size_t>(dest)]);
    fillMessageParts(st, dest);
}
void announceCapture(DialogState* st, HWND capture, const std::wstring& message) {
    // Keep the entry and keyboard focus unchanged: the user can immediately
    // try a different gesture. OSARA reads this at once without OK or Escape.
    SetWindowTextW(capture, message.c_str());
    if (st->announce) st->announce(toUtf8(message));
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
// Selection changes never recreate tree nodes or rename the item under
// NVDA/OSARA. This prevents stale/duplicate announcements after an arrow key.
void showPage(DialogState* st, Page page) {
    if (!st->created) return;
    st->page = page;
    if (st->capturing) cancelCapture(st);
    if (st->editingCustom) closeCustomEditor(st, true);
    ShowWindow(st->messageTopics, page == Page::messages ? SW_SHOW : SW_HIDE);
    ShowWindow(st->messages, page == Page::messages ? SW_SHOW : SW_HIDE);
    ShowWindow(st->advanced, page == Page::advanced ? SW_SHOW : SW_HIDE);
    ShowWindow(st->shortcuts, page == Page::shortcuts ? SW_SHOW : SW_HIDE);
    ShowWindow(st->capture, SW_HIDE);
    ShowWindow(st->customEdit, SW_HIDE);
    ShowWindow(st->customLabel, SW_HIDE);
}
HWND lastPageControl(DialogState* st) {
    switch (st->page) {
        case Page::shortcuts: return st->shortcuts;
        case Page::advanced: return st->advanced;
        default: return st->messages;
    }
}
// Tab cycles through the selected tree page, OK, Cancel, and back to tree.
// Shift+Tab follows the same path backwards. There is no redundant scope combo:
// the FX Params/Track Params scope is selected as a child in the native tree.
void pageTab(DialogState* st, HWND from, bool backward) {
    HWND next = st->tree;
    if (from == st->tree) next = backward ? st->cancel : (st->page == Page::messages ? st->messageTopics : lastPageControl(st));
    else if (from == st->cancel) next = backward ? st->ok : st->tree;
    else if (from == st->ok) next = backward ? lastPageControl(st) : st->cancel;
    else if (st->page == Page::messages && from == st->messageTopics)
        next = backward ? st->tree : st->messages;
    else if (from == lastPageControl(st))
        next = backward ? (st->page == Page::messages ? st->messageTopics : st->tree) : st->ok;
    if (next && IsWindowVisible(next) && IsWindowEnabled(next)) SetFocus(next);
}
HTREEITEM insertNode(HWND tree, HTREEITEM parent, const wchar_t* text) {
    TVINSERTSTRUCTW item{};
    item.hParent = parent;
    item.hInsertAfter = TVI_LAST;
    item.item.mask = TVIF_TEXT;
    item.item.pszText = const_cast<wchar_t*>(text);
    return reinterpret_cast<HTREEITEM>(SendMessageW(tree, TVM_INSERTITEMW, 0,
        reinterpret_cast<LPARAM>(&item)));
}
LRESULT CALLBACK pageProc(HWND hwnd, UINT msg, WPARAM wp, LPARAM lp, UINT_PTR, DWORD_PTR ref) {
    auto* st = reinterpret_cast<DialogState*>(ref);
    if (msg == WM_SETFOCUS) st->lastFocused = hwnd;
    // Buttons keep the normal Win32 handling for Enter/Space while still
    // remembering focus for Alt+Tab; only page controls own custom keys.
    if (hwnd == st->ok || hwnd == st->cancel)
        return DefSubclassProc(hwnd, msg, wp, lp);
    if (msg == WM_GETDLGCODE) return DefSubclassProc(hwnd, msg, wp, lp) | DLGC_WANTTAB | DLGC_WANTALLKEYS;
    // READONLY EDIT gets WM_CHAR even when we consumed WM_KEYDOWN; otherwise
    // Windows can sound its default invalid-input beep during shortcut capture.
    if (hwnd == st->capture && (msg == WM_CHAR || msg == WM_SYSCHAR)) return 0;
    if (hwnd == st->customEdit && msg == WM_CHAR &&
        (wp == VK_RETURN || wp == VK_ESCAPE || wp == VK_TAB)) return 0;
    // Some Win32 controls beep on translated Tab characters after focus has
    // already changed. The modal pump consumes the physical Tab, and this
    // fallback consumes the character so there is no native error tone.
    if (msg == WM_CHAR && wp == VK_TAB) return 0;
    // Alt+Up/Down are handled by the message-part list, not the system menu.
    if (hwnd == st->messages && msg == WM_SYSCHAR && (wp == VK_UP || wp == VK_DOWN)) return 0;
    if (msg == WM_KEYDOWN || msg == WM_SYSKEYDOWN) {
        const UINT vk = static_cast<UINT>(wp);
        const bool shift = (GetKeyState(VK_SHIFT) & 0x8000) != 0;
        const bool ctrl = (GetKeyState(VK_CONTROL) & 0x8000) != 0;
        const bool alt = (GetKeyState(VK_MENU) & 0x8000) != 0;
        if (hwnd == st->customEdit) {
            if (vk == VK_RETURN && !alt) {
                closeCustomEditor(st, true);
                if (ctrl) SendMessageW(st->hwnd, WM_COMMAND, IDOK, 0);
                return 0;
            }
            if (vk == VK_ESCAPE && !ctrl && !alt) { closeCustomEditor(st, false); return 0; }
            if (vk == VK_TAB && !ctrl && !alt) {
                closeCustomEditor(st, true);
                pageTab(st, st->messages, shift);
                return 0;
            }
            return DefSubclassProc(hwnd, msg, wp, lp);
        }
        if (hwnd == st->messages && alt && !ctrl && (vk == VK_UP || vk == VK_DOWN)) {
            reorderMessagePart(st, vk == VK_UP ? -1 : 1); return 0;
        }
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
                (vk == 'P' && ctrl && !alt && !shift) || // Ctrl+P always opens Preferences
                (vk == VK_F12 && !ctrl) || vk == VK_INSERT || vk == VK_NUMPAD0 ||
                (vk == VK_SPACE && ctrl) ||
                (alt && (vk == VK_F10 || vk == VK_F11 || vk == VK_F12))) {
                announceCapture(st, hwnd, L"Reserved shortcut: " + keyName(candidate) +
                    L". Try another shortcut.");
                return 0;
            }
            if (st->visible.empty()) return 0;
            const size_t selected = st->visible[static_cast<size_t>(st->selectedInScope[scopeIndex(st->currentScope)])];
            for (size_t i = 0; i < st->pending.shortcuts.size(); ++i) {
                if (i != selected && st->pending.shortcuts[i].scope == st->currentScope &&
                    same(st->pending.shortcuts[i].assigned, candidate)) {
                    announceCapture(st, hwnd, keyName(candidate) +
                        L" is already assigned to " + st->pending.shortcuts[i].description +
                        L". Try another shortcut.");
                    return 0;
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
        if (hwnd == st->messages && vk == VK_RETURN && !ctrl && !alt) {
            startCustomEditor(st); return 0;
        }
        if (hwnd == st->messages && vk == VK_SPACE && !ctrl && !alt) {
            toggleMessagePart(st); return 0;
        }
        if (hwnd == st->advanced && vk == VK_SPACE && !ctrl && !alt) {
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
        st->tree = CreateWindowExW(WS_EX_CLIENTEDGE, WC_TREEVIEWW, L"",
            WS_VISIBLE | WS_CHILD | WS_TABSTOP | TVS_HASBUTTONS | TVS_HASLINES |
            TVS_LINESATROOT | TVS_SHOWSELALWAYS | TVS_DISABLEDRAGDROP,
            16, 18, 219, 400, hwnd, reinterpret_cast<HMENU>(static_cast<INT_PTR>(IDC_TREE)), nullptr, nullptr);
        st->shortcuts = CreateWindowExW(WS_EX_CLIENTEDGE, L"LISTBOX", L"",
            WS_CHILD | WS_TABSTOP | WS_VSCROLL | LBS_NOTIFY | LBS_NOINTEGRALHEIGHT,
            252, 18, 465, 359, hwnd, reinterpret_cast<HMENU>(static_cast<INT_PTR>(IDC_SHORTCUTS)), nullptr, nullptr);
        st->capture = CreateWindowExW(WS_EX_CLIENTEDGE, L"EDIT", L"",
            WS_CHILD | WS_TABSTOP | ES_READONLY,
            252, 381, 465, 29, hwnd, reinterpret_cast<HMENU>(static_cast<INT_PTR>(IDC_CAPTURE)), nullptr, nullptr);
        st->messages = CreateWindowExW(WS_EX_CLIENTEDGE, L"LISTBOX", L"",
            WS_CHILD | WS_TABSTOP | LBS_NOTIFY,
            252, 121, 465, 240, hwnd, reinterpret_cast<HMENU>(static_cast<INT_PTR>(IDC_MESSAGES)), nullptr, nullptr);
        st->messageTopics = CreateWindowExW(WS_EX_CLIENTEDGE, L"LISTBOX", L"",
            WS_CHILD | WS_TABSTOP | LBS_NOTIFY,
            252, 18, 465, 89, hwnd, reinterpret_cast<HMENU>(static_cast<INT_PTR>(IDC_MESSAGE_TOPICS)), nullptr, nullptr);
        st->customLabel = CreateWindowW(L"STATIC", L"Custom message:", WS_CHILD,
            252, 367, 465, 18, hwnd, nullptr, nullptr, nullptr);
        st->customEdit = CreateWindowExW(WS_EX_CLIENTEDGE, L"EDIT", L"",
            WS_CHILD | WS_TABSTOP | ES_AUTOHSCROLL,
            252, 384, 465, 28, hwnd, reinterpret_cast<HMENU>(static_cast<INT_PTR>(IDC_CUSTOM_EDIT)), nullptr, nullptr);
        SendMessageW(st->customEdit, EM_LIMITTEXT, 240, 0);
        SendMessageW(st->messageTopics, LB_ADDSTRING, 0, reinterpret_cast<LPARAM>(L"Title"));
        selectList(st->messageTopics, 0);
        st->advanced = CreateWindowExW(WS_EX_CLIENTEDGE, L"LISTBOX", L"",
            WS_CHILD | WS_TABSTOP | LBS_NOTIFY,
            252, 18, 465, 160, hwnd, reinterpret_cast<HMENU>(static_cast<INT_PTR>(IDC_ADVANCED)), nullptr, nullptr);
        st->ok = CreateWindowW(L"BUTTON", L"&OK", WS_CHILD | WS_VISIBLE | WS_TABSTOP | BS_DEFPUSHBUTTON,
            508, 434, 98, 32, hwnd, reinterpret_cast<HMENU>(static_cast<INT_PTR>(IDOK)), nullptr, nullptr);
        st->cancel = CreateWindowW(L"BUTTON", L"&Cancel", WS_CHILD | WS_VISIBLE | WS_TABSTOP,
            618, 434, 98, 32, hwnd, reinterpret_cast<HMENU>(static_cast<INT_PTR>(IDCANCEL)), nullptr, nullptr);
        for (HWND control : {st->tree, st->shortcuts, st->capture, st->messages, st->messageTopics, st->customLabel, st->customEdit, st->advanced, st->ok, st->cancel})
            SendMessageW(control, WM_SETFONT, reinterpret_cast<WPARAM>(GetStockObject(DEFAULT_GUI_FONT)), TRUE);
        for (HWND control : {st->tree, st->shortcuts, st->capture, st->messages, st->messageTopics, st->customEdit,
                             st->advanced, st->ok, st->cancel})
            SetWindowSubclass(control, pageProc, 1, reinterpret_cast<DWORD_PTR>(st));
        fillShortcuts(st);
        fillMessageParts(st);
        updateChoices(st);
        st->nodes[0] = insertNode(st->tree, TVI_ROOT, L"Messages");
        st->fxMsgNode = insertNode(st->tree, st->nodes[0], L"FX Params");
        st->trackMsgNode = insertNode(st->tree, st->nodes[0], L"Track Params");
        st->nodes[1] = insertNode(st->tree, TVI_ROOT, L"Shortcuts");
        st->fxNode = insertNode(st->tree, st->nodes[1], L"FX Params");
        st->trackNode = insertNode(st->tree, st->nodes[1], L"Track Params");
        st->nodes[2] = insertNode(st->tree, TVI_ROOT, L"Advanced");
        // Child categories are directly accessible with Down/Up.
        SendMessageW(st->tree, TVM_EXPAND, TVE_EXPAND, reinterpret_cast<LPARAM>(st->nodes[0]));
        SendMessageW(st->tree, TVM_EXPAND, TVE_EXPAND, reinterpret_cast<LPARAM>(st->nodes[1]));
        st->created = true;
        showPage(st, Page::messages);
        SendMessageW(st->tree, TVM_SELECTITEM, TVGN_CARET, reinterpret_cast<LPARAM>(st->nodes[0]));
        st->lastFocused = st->tree;
        return 0;
    }
    if (!st) return DefWindowProcW(hwnd, msg, wp, lp);
    if (msg == WM_NOTIFY && st->created && reinterpret_cast<LPNMHDR>(lp)->idFrom == IDC_TREE &&
        reinterpret_cast<LPNMHDR>(lp)->code == TVN_SELCHANGEDW) {
        const HTREEITEM selected = reinterpret_cast<LPNMTREEVIEWW>(lp)->itemNew.hItem;
        if (selected == st->nodes[0]) showPage(st, Page::messages);
        else if (selected == st->fxMsgNode || selected == st->trackMsgNode) {
            const ShortcutScope next = selected == st->fxMsgNode ? ShortcutScope::fx : ShortcutScope::track;
            if (st->messageScope != next) {
                st->messageScope = next;
                fillMessageParts(st);
            }
            showPage(st, Page::messages);
        }
        else if (selected == st->nodes[2]) showPage(st, Page::advanced);
        else if (selected == st->nodes[1]) showPage(st, Page::shortcuts);
        else if (selected == st->fxNode || selected == st->trackNode) {
            const auto newScope = selected == st->fxNode ? ShortcutScope::fx : ShortcutScope::track;
            if (st->currentScope != newScope) {
                st->currentScope = newScope;
                fillShortcuts(st);
            }
            showPage(st, Page::shortcuts);
        }
        return 0;
    }
    // Alt+Tab must never leave focus stuck on the disabled REAPER owner or
    // on the dialog frame instead of its active child. Restore asynchronously
    // only when this dialog is foreground; do not steal focus from other apps.
    if (msg == WM_ACTIVATE) {
        if (LOWORD(wp) != WA_INACTIVE && st->created)
            PostMessageW(hwnd, kRestoreFocus, 0, 0);
        return DefWindowProcW(hwnd, msg, wp, lp);
    }
    if (msg == WM_SETFOCUS && st->created) {
        HWND target = st->lastFocused;
        if (!target || !IsWindow(target) || !IsWindowVisible(target)) target = st->tree;
        if (target && GetFocus() == hwnd) SetFocus(target);
        return 0;
    }
    if (msg == kRestoreFocus && st->created && GetForegroundWindow() == hwnd) {
        HWND target = st->lastFocused;
        if (!target || !IsWindow(target) || !IsWindowVisible(target)) target = st->tree;
        if (GetFocus() != target) SetFocus(target);
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
            if (st->editingCustom) closeCustomEditor(st, id == IDOK);
            st->accepted = id == IDOK;
            st->hwnd = nullptr;
            SetWindowLongPtrW(hwnd, GWLP_USERDATA, 0);
            DestroyWindow(hwnd);
            return 0;
        }
        if (id == IDC_MESSAGE_TOPICS && notice == LBN_SELCHANGE) {
            // Title is currently the only message category.
            selectList(st->messageTopics, 0);
            return 0;
        }
        if (id == IDC_SHORTCUTS && notice == LBN_SELCHANGE) { updateSelection(st); return 0; }
        if (id == IDC_SHORTCUTS && notice == LBN_DBLCLK) { startCapture(st); return 0; }
        if (id == IDC_MESSAGES && notice == LBN_DBLCLK) {
            startCustomEditor(st); return 0;
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
    p.shortcuts = std::move(unique);
    p.trackTitle.enabled = {{true, true, false, false}};
    return p;
}
namespace {
std::wstring readIni(const std::wstring& path, const wchar_t* section, const wchar_t* key) {
    std::array<wchar_t, 512> buffer{};
    GetPrivateProfileStringW(section, key, L"", buffer.data(),
        static_cast<DWORD>(buffer.size()), path.c_str());
    return buffer.data();
}
void loadTitle(const std::wstring& path, const wchar_t* prefix, TitleMessage& cfg, int count) {
    const std::wstring orderKey = std::wstring(prefix) + L"Order";
    const std::wstring enabledKey = std::wstring(prefix) + L"Enabled";
    const std::wstring customKey = std::wstring(prefix) + L"Custom";
    const std::wstring order = readIni(path, L"Messages", orderKey.c_str());
    const std::wstring enabled = readIni(path, L"Messages", enabledKey.c_str());
    if (static_cast<int>(order.size()) == count) {
        for (int i = 0; i < count; ++i) cfg.order[static_cast<size_t>(i)] = order[static_cast<size_t>(i)] - L'0';
    }
    if (static_cast<int>(enabled.size()) == count) {
        for (int i = 0; i < count; ++i) cfg.enabled[static_cast<size_t>(i)] = enabled[static_cast<size_t>(i)] == L'1';
    }
    cfg.custom = readIni(path, L"Messages", customKey.c_str());
    normalizeTitle(cfg, count);
}
bool saveTitle(const std::wstring& path, const wchar_t* prefix, const TitleMessage& cfg, int count) {
    const std::wstring orderKey = std::wstring(prefix) + L"Order";
    const std::wstring enabledKey = std::wstring(prefix) + L"Enabled";
    const std::wstring customKey = std::wstring(prefix) + L"Custom";
    std::wstring order, enabled;
    for (int i = 0; i < count; ++i) {
        order += static_cast<wchar_t>(L'0' + cfg.order[static_cast<size_t>(i)]);
        enabled += cfg.enabled[static_cast<size_t>(i)] ? L'1' : L'0';
    }
    return WritePrivateProfileStringW(L"Messages", orderKey.c_str(), order.c_str(), path.c_str()) &&
           WritePrivateProfileStringW(L"Messages", enabledKey.c_str(), enabled.c_str(), path.c_str()) &&
           WritePrivateProfileStringW(L"Messages", customKey.c_str(), cfg.custom.c_str(), path.c_str());
}
} // namespace
Preferences loadPreferences(const std::filesystem::path& file) {
    Preferences p = defaultPreferences();
    const std::wstring path = file.wstring();
    p.pluginFirst = GetPrivateProfileIntW(L"Messages", L"PluginFirst", 1, path.c_str()) != 0;
    p.compatibilityHook = GetPrivateProfileIntW(L"Keyboard", L"CompatibilityHook", 0, path.c_str()) != 0;
    // Upgrade the previous two-way "PluginFirst" setting without losing it.
    const auto legacy = readIni(path, L"Messages", L"FxTitleOrder");
    if (legacy.empty() && !p.pluginFirst) p.fxTitle.order = {{0, 2, 1, 3}};
    loadTitle(path, L"FxTitle", p.fxTitle, 4);
    loadTitle(path, L"TrackTitle", p.trackTitle, 3);
    for (size_t i = 0; i < p.shortcuts.size(); ++i) {
        const std::wstring key = L"Shortcut" + std::to_wstring(i);
        const int value = GetPrivateProfileIntW(L"Shortcuts", key.c_str(), -1, path.c_str());
        if (value < 0) continue;
        const Key candidate = shortcut(static_cast<UINT>(value & 255), value >> 8);
        if (!candidate.vk || candidate.vk == VK_ESCAPE || (candidate.vk == VK_F12 && !candidate.ctrl) ||
            (candidate.vk == 'P' && candidate.ctrl && !candidate.alt && !candidate.shift)) continue;
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
    if (!saveTitle(path, L"FxTitle", p.fxTitle, 4) || !saveTitle(path, L"TrackTitle", p.trackTitle, 3)) return false;
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
std::optional<Preferences> editPreferences(HWND owner, const Preferences& current,
    const std::function<void(const std::string&)>& announce) {
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
    DialogState state; state.pending = current; state.announce = announce;
    // Disable the owner before displaying the popup, as for a native modal
    // Win32 dialog. A disabled owner cannot compete with its dialog for focus.
    const bool disabledOwner = owner && IsWindow(owner) && IsWindowEnabled(owner);
    if (disabledOwner) EnableWindow(owner,FALSE);
    HWND hwnd = CreateWindowExW(WS_EX_DLGMODALFRAME | WS_EX_CONTROLPARENT,
        kClassName, L"LReaParams - Preferences", WS_POPUP | WS_CAPTION | WS_SYSMENU,
        CW_USEDEFAULT, CW_USEDEFAULT, 752, 512, owner, nullptr, GetModuleHandleW(nullptr), &state);
    if (!hwnd) {
        if (disabledOwner && IsWindow(owner)) EnableWindow(owner,TRUE);
        return std::nullopt;
    }
    ShowWindow(hwnd, SW_SHOW);
    UpdateWindow(hwnd);
    SetActiveWindow(hwnd);
    SetFocus(state.tree);
    MSG msg{};
    while (state.hwnd) {
        const BOOL got = GetMessageW(&msg, nullptr, 0, 0);
        if (got <= 0) {
            if (got == 0) PostQuitMessage(static_cast<int>(msg.wParam));
            if (state.hwnd) DestroyWindow(state.hwnd);
            break;
        }
        // Do not let the nested modal loop claim keyboard messages from
        // unrelated REAPER windows or from another foreground application.
        const bool isDialogMessage = msg.hwnd == hwnd || (msg.hwnd && IsChild(hwnd, msg.hwnd));
        if (isDialogMessage && msg.message == WM_KEYDOWN && msg.wParam == VK_TAB &&
            !(GetKeyState(VK_CONTROL) & 0x8000) &&
            !(GetKeyState(VK_MENU) & 0x8000)) {
            const HWND focused = GetFocus();
            if (focused == state.capture && state.capturing) {
                state.capturing = false;
                ShowWindow(state.capture, SW_HIDE);
                SetFocus(state.tree);
                continue;
            }
            if (focused == state.customEdit && state.editingCustom) {
                closeCustomEditor(&state, true);
                pageTab(&state, state.messages, (GetKeyState(VK_SHIFT) & 0x8000) != 0);
                continue;
            }
            if (focused == state.tree || focused == state.shortcuts ||
                focused == state.messages || focused == state.messageTopics || focused == state.advanced ||
                focused == state.ok || focused == state.cancel) {
                pageTab(&state, focused, (GetKeyState(VK_SHIFT) & 0x8000) != 0);
                continue;
            }
        }
        // Alt+Tab is a system task-switch gesture, not dialog navigation.
        const bool taskSwitch = (msg.message == WM_SYSKEYDOWN || msg.message == WM_SYSKEYUP) &&
            msg.wParam == VK_TAB;
        if (!(isDialogMessage && !taskSwitch && IsDialogMessageW(hwnd, &msg))) {
            TranslateMessage(&msg);
            DispatchMessageW(&msg);
        }
    }
    if (disabledOwner && IsWindow(owner)) {
        EnableWindow(owner,TRUE);
        // Restore REAPER only when it belongs to the foreground thread;
        // otherwise preserve the user's Alt+Tab destination.
        if (GetActiveWindow() == nullptr || GetActiveWindow() == owner)
            SetActiveWindow(owner);
    }
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

// Ordered, individually enabled title parts. No redundant separators if an
// element is disabled or the custom text is blank.
namespace lrp {
void setTitleMessages(const Preferences& settings) {
    activeFxTitle = settings.fxTitle;
    activeTrackTitle = settings.trackTitle;
    normalizeTitle(activeFxTitle, 4);
    normalizeTitle(activeTrackTitle, 3);
}
std::string formatFxTitle(const std::string& fx, const std::string& track,
    const std::string& status) {
    const std::string names[] = {"FX Params", fx, track, toUtf8(activeFxTitle.custom)};
    std::string result;
    for (int i = 0; i < 4; ++i) {
        const int part = activeFxTitle.order[static_cast<size_t>(i)];
        if (part < 0 || part >= 4 || !activeFxTitle.enabled[static_cast<size_t>(part)] || names[part].empty()) continue;
        if (!result.empty()) result += " - ";
        result += names[part];
    }
    if (result.empty()) result = "FX Params"; // Never leave a nameless accessible window.
    if (!status.empty()) {
        // Preserve the original announcement order when the heading is first:
        // "FX Params. Bypassed. Plugin - Track".
        if (activeFxTitle.order[0] == 0 && activeFxTitle.enabled[0]) {
            const std::string prefix = "FX Params - ";
            if (result.compare(0, prefix.size(), prefix) == 0)
                result = "FX Params. " + status + ". " + result.substr(prefix.size());
            else if (result == "FX Params") result += ". " + status;
            else result += ". " + status;
        } else result += ". " + status;
    }
    return result;
}
std::wstring formatTrackTitle(const std::wstring& track) {
    const std::wstring names[] = {L"Track Params", track, activeTrackTitle.custom};
    std::wstring result;
    for (int i = 0; i < 3; ++i) {
        const int part = activeTrackTitle.order[static_cast<size_t>(i)];
        if (part < 0 || part >= 3 || !activeTrackTitle.enabled[static_cast<size_t>(part)] || names[part].empty()) continue;
        if (!result.empty()) result += L" - ";
        result += names[part];
    }
    return result.empty() ? L"Track Params" : result;
}
} // namespace lrp
