#include "lrp/RenderNavigation.h"
#include "lrp/ShortcutHelp.h"
#ifdef _WIN32
#include <commctrl.h>
#include <oleacc.h>
#include <cstdlib>
#include <algorithm>
#include <array>
#include <cwchar>
#include <cwctype>
#include <limits>
#include <utility>

namespace lrp {
namespace {
std::wstring getText(HWND window) {
    if (!window || !IsWindow(window)) return {};
    const int size = GetWindowTextLengthW(window);
    if (size < 1 || size > 65536) return {};
    std::wstring out(static_cast<size_t>(size + 1), L'\0');
    const int got = GetWindowTextW(window, &out[0], size + 1);
    out.resize(static_cast<size_t>(std::max(got, 0)));
    return out;
}
std::wstring lower(std::wstring input) {
    std::transform(input.begin(), input.end(), input.begin(), [](wchar_t c) {return std::towlower(c);});
    return input;
}
bool has(const std::wstring& s, const wchar_t* needle) {return lower(s).find(needle) != std::wstring::npos;}
bool isDescendant(HWND root, HWND item) {
    return root && item && (root == item || IsChild(root, item));
}
std::wstring klass(HWND h) {
    wchar_t out[96]{}; if (h) GetClassNameW(h, out, 96);
    return lower(out);
}
struct Children {std::vector<HWND> windows;};
BOOL CALLBACK enumChild(HWND h, LPARAM user) {
    auto* result = reinterpret_cast<Children*>(user);
    result->windows.push_back(h);
    return TRUE;
}
std::vector<HWND> children(HWND h) {
    Children result;
    if (IsWindow(h)) EnumChildWindows(h, enumChild, reinterpret_cast<LPARAM>(&result));
    return result.windows;
}
HWND directOrNested(HWND root, int id) {
    if (!root) return nullptr;
    for (HWND h : children(root)) if (GetDlgCtrlID(h) == id && IsWindowVisible(h)) return h;
    return nullptr;
}
// The ID table is deliberately advisory: it is never used to set a value.
// IDs are scoped because output-format subdialogs reuse several main-dialog IDs.
const wchar_t* knownMain(int id) {
    switch (id) {
    case 1: return L"Render";
    case 2: return L"Cancel";
    case 1000: return L"Resample mode";
    case 1001: return L"Render speed";
    case 1002: return L"Bounds";
    case 1003: return L"Source";
    case 1007: return L"Output directory";
    case 1008: return L"Render to path";
    case 1009: return L"Start";
    case 1010: return L"End";
    case 1011: return L"Length";
    case 1012: return L"Tail duration";
    case 1013: return L"File name";
    case 1030: return L"Browse output directory";
    case 1041: return L"Sample rate";
    case 1042: return L"Silently increment filenames";
    case 1046: return L"Tail";
    case 1056: return L"Region manager";
    case 1057: return L"Presets";
    case 1059: return L"Multichannel tracks";
    case 1060: return L"Save project copy";
    case 1061: return L"Noise shaping";
    case 1062: return L"Use project sample rate";
    case 1063: return L"Mono media to mono files";
    case 1064: return L"Region matrix";
    case 1065: return L"Wildcards";
    case 1116: return L"Output format";
    case 1154: return L"Add rendered items to tracks";
    case 1307: return L"Dither";
    case 1397: return L"Channels";
    case 1447: return L"Add to render queue";
    case 1448: return L"Open render queue";
    case 1449: return L"Save settings";
    case 1808: return L"Delay queued render";
    default: return nullptr;
    }
}
// Identifiers in the format-specific controls can be reused by all codecs;
// use captions/neighbor labels rather than mislabel WAV controls as MP3.
std::wstring classKind(HWND h) {
    const auto cls = klass(h);
    if (cls.find(L"combo") != std::wstring::npos) return L"Combo";
    if (cls.find(L"edit") != std::wstring::npos) return L"Edit";
    if (cls == L"button") return L"Button";
    if (cls.find(L"trackbar") != std::wstring::npos || cls.find(L"fader") != std::wstring::npos) return L"Slider";
    if (cls.find(L"tab") != std::wstring::npos) return L"Tab";
    return L"Control";
}
bool isInput(HWND h) {
    const auto cls = klass(h);
    if (cls == L"static") return false;
    if (cls.find(L"combo") != std::wstring::npos || cls.find(L"edit") != std::wstring::npos ||
        cls == L"button" || cls.find(L"trackbar") != std::wstring::npos ||
        cls.find(L"fader") != std::wstring::npos || cls.find(L"tab") != std::wstring::npos ||
        cls.find(L"listbox") != std::wstring::npos || cls.find(L"updown") != std::wstring::npos ||
        cls.find(L"listview") != std::wstring::npos || cls.find(L"treeview") != std::wstring::npos)
        return true;
    // Include future REAPER custom controls only if the application makes
    // them keyboard-focusable; never focus a decorative static HWND.
    return (GetWindowLongPtrW(h, GWL_STYLE) & WS_TABSTOP) != 0;
}
// REAPER may expose its output-format pages as MSAA child tabs of a
// generic WDL window, rather than as a Win32 SysTabControl32 HWND.
// Match BOTH labels and the page-tab accessibility role before operating.
struct AccessibleTabs {
    HWND window{};
    LONG items[2]{};
};
bool readAccessibleTabs(HWND window, AccessibleTabs& tabs) {
    IAccessible* acc = nullptr;
    if (FAILED(AccessibleObjectFromWindow(window, OBJID_CLIENT, IID_IAccessible,
        reinterpret_cast<void**>(&acc))) || !acc) return false;
    LONG count = 0;
    if (FAILED(acc->get_accChildCount(&count)) || count < 2 || count > 128) {
        acc->Release(); return false;
    }
    LONG matching[2]{};
    for (LONG i = 1; i <= count; ++i) {
        VARIANT child{}; child.vt = VT_I4; child.lVal = i;
        VARIANT role{}; VariantInit(&role);
        if (FAILED(acc->get_accRole(child, &role)) || role.vt != VT_I4 ||
            role.lVal != ROLE_SYSTEM_PAGETAB) {VariantClear(&role); continue;}
        VariantClear(&role);
        BSTR name = nullptr;
        if (SUCCEEDED(acc->get_accName(child, &name)) && name) {
            const auto label = lower(std::wstring(name, SysStringLen(name)));
            if (label.find(L"primary output format") != std::wstring::npos) matching[0] = i;
            if (label.find(L"secondary output format") != std::wstring::npos) matching[1] = i;
        }
        if (name) SysFreeString(name);
    }
    acc->Release();
    if (!matching[0] || !matching[1]) return false;
    tabs.window = window;
    tabs.items[0] = matching[0]; tabs.items[1] = matching[1];
    return true;
}
bool findAccessibleTabs(HWND root, AccessibleTabs& tabs) {
    // A custom control may expose the page tabs directly on the dialog HWND.
    if (readAccessibleTabs(root, tabs)) return true;
    for (HWND h : children(root)) {
        if (IsWindowVisible(h) && IsWindowEnabled(h) && readAccessibleTabs(h, tabs)) return true;
    }
    return false;
}
// Focus only: do not select a page, invoke a button, or move into a format field.
// The two MSAA PAGETAB children might share one HWND (custom WDL tab control).
// SELFLAG_TAKEFOCUS addresses the *item*, not merely its containing HWND.
bool focusAccessibleTab(const AccessibleTabs& tabs, int page) {
    if (page < 0 || page > 1 || !IsWindow(tabs.window) ||
        !IsWindowVisible(tabs.window) || !IsWindowEnabled(tabs.window)) return false;
    IAccessible* acc = nullptr;
    if (FAILED(AccessibleObjectFromWindow(tabs.window, OBJID_CLIENT, IID_IAccessible,
        reinterpret_cast<void**>(&acc))) || !acc) return false;
    VARIANT child{}; child.vt = VT_I4; child.lVal = tabs.items[page];
    // Take keyboard focus only, leaving the tab's native selection behavior to REAPER.
    const HRESULT result = acc->accSelect(SELFLAG_TAKEFOCUS, child);
    // Some MSAA providers report success without actually focusing the requested
    // item. Confirm focus rather than silently claiming a successful jump.
    bool focused = false;
    if (SUCCEEDED(result)) {
        VARIANT focus{}; VariantInit(&focus);
        if (SUCCEEDED(acc->get_accFocus(&focus)) && focus.vt == VT_I4 &&
            focus.lVal == tabs.items[page]) focused = true;
        VariantClear(&focus);
        if (!focused) {
            VARIANT state{}; VariantInit(&state);
            if (SUCCEEDED(acc->get_accState(child, &state)) && state.vt == VT_I4 &&
                (state.lVal & STATE_SYSTEM_FOCUSED)) focused = true;
            VariantClear(&state);
        }
    }
    acc->Release();
    return focused;
}

const wchar_t* const findClass = L"LRP_RenderFind_74_1";
} // namespace

thread_local RenderNavigation* RenderNavigation::active_ = nullptr;
RenderNavigation::RenderNavigation(HWND main, std::function<void(const std::string&)> speak)
    : speak_(std::move(speak)), main_(main) {}
RenderNavigation::~RenderNavigation() { stop(); }
bool RenderNavigation::start() noexcept {
    if (hook_) return true;
    thread_ = GetCurrentThreadId();
    active_ = this;
    hook_ = SetWindowsHookExW(WH_GETMESSAGE, keyHook, nullptr, thread_);
    if (!hook_) {active_ = nullptr; return false;}
    return true;
}
void RenderNavigation::stop() noexcept {
    closeFind();
    if (hook_) { UnhookWindowsHookEx(hook_); hook_ = nullptr; }
    if (active_ == this) active_ = nullptr;
    resetDialog();
    helpReleases_.fill(nullptr);
    UnregisterClassW(findClass, GetModuleHandleW(nullptr));
}
void RenderNavigation::resetDialog() noexcept {
    helpMode_ = false; helpFocus_ = nullptr;
    helpReleases_.fill(nullptr);
    render_ = nullptr;
    cachedFormatTab_ = nullptr;
    controls_.clear(); accelerators_.clear(); cycle_.clear();
    lastResult_ = nullptr; lastResultPage_ = -1;
}

bool RenderNavigation::isRender(HWND root) const {
    if (!root || !IsWindow(root) || root == main_) return false;
    DWORD pid = 0;
    if (GetWindowThreadProcessId(root, &pid) != thread_ || pid != GetCurrentProcessId()) return false;
    // Check a *combination* of genuine render-dialog controls. Matching the
    // window title alone would intercept other dialogs, e.g. Render Queue.
    const auto list = children(root);
    int found = 0;
    for (HWND h : list) {
        if (!IsWindowVisible(h)) continue;
        const int id = GetDlgCtrlID(h);
        const auto cls = klass(h);
        if ((id == 1041 && cls.find(L"combobox") != std::wstring::npos) ||
            (id == 1013 && cls.find(L"edit") != std::wstring::npos) ||
            (id == 1447 && cls == L"button") ||
            (id == 1057 && cls == L"button") ||
            (id == 1116 && cls.find(L"combobox") != std::wstring::npos)) {
            ++found;
        }
    }
    return found >= 3 && (found >= 4 || has(getText(root), L"render"));
}
HWND RenderNavigation::renderFromFocus(HWND focus) const {
    if (!focus || !IsWindow(focus)) return nullptr;
    // Do not steal keyboard events from a child modal (Metadata, file chooser,
    // Normalize/Fade) even if the Render dialog remains open behind it.
    HWND root = GetAncestor(focus, GA_ROOT);
    if (root && GetForegroundWindow() == root &&
        (root == render_ || isRender(root))) return root;
    return nullptr;
}
bool RenderNavigation::isInRoot(HWND h) const noexcept {return render_ && isDescendant(render_, h);}
void RenderNavigation::tick() noexcept {
    try {
        if (GetCurrentThreadId() != thread_ || !hook_) return;
        if (render_ && !IsWindow(render_)) {resetDialog(); return;}
        // Leaving the Render focus context disarms help. In particular,
        // Metadata, file pickers and the TCP must not inherit this mode.
        if (helpMode_ && (!IsWindow(helpFocus_) || renderFromFocus(GetFocus()) != render_)) {
            helpMode_ = false; helpFocus_ = nullptr;
        }
        if (find_ && !IsWindow(find_)) {find_ = edit_ = nullptr; originalEditProc_ = nullptr;}
    } catch (...) {
        // Never let an optional dialog-navigation aid stop the REAPER extension.
    }
}

std::wstring RenderNavigation::nearbyLabel(HWND control) const {
    HWND parent = GetParent(control);
    if (!parent) return {};
    RECT dst{}; if (!GetWindowRect(control, &dst)) return {};
    int best = std::numeric_limits<int>::max();
    std::wstring label;
    for (HWND h : children(parent)) {
        if (h == control || !IsWindowVisible(h) || klass(h) != L"static") continue;
        const auto text = getText(h);
        if (text.empty()) continue;
        RECT a{}; if (!GetWindowRect(h, &a)) continue;
        const int vertical = std::abs((a.top+a.bottom)-(dst.top+dst.bottom))/2;
        const int horizontal = a.right <= dst.left + 18 ? std::abs(dst.left-a.right) : 500;
        // Label may also be immediately above its input box.
        const int above = a.bottom <= dst.top+10 && dst.top-a.bottom < 40 ? 60+dst.top-a.bottom : 500;
        const int distance = std::min<int>(horizontal + vertical*3, above + std::abs(a.left-dst.left));
        if (distance < best && distance < 320) {best = distance; label = text;}
    }
    while (!label.empty() && (label.back() == L':' || std::iswspace(label.back()))) label.pop_back();
    return label;
}
std::wstring RenderNavigation::controlName(HWND h, bool format) const {
    const auto cls = klass(h);
    const int id = GetDlgCtrlID(h);
    const auto raw = getText(h);
    // Prefer actual UI captions and labels to an ID table that might be stale.
    if (cls == L"button" && !raw.empty()) return raw;
    if (!format) if (const auto name = knownMain(id)) return name;
    const auto associated = nearbyLabel(h);
    if (!associated.empty()) return associated;
    if (cls.find(L"edit") == std::wstring::npos && !raw.empty()) return raw;
    // Use the same native accessibility name exposed to NVDA if an unnamed
    // REAPER custom control lacks a neighboring Windows STATIC label.
    IAccessible* accessible = nullptr;
    if (SUCCEEDED(AccessibleObjectFromWindow(h, OBJID_CLIENT, IID_IAccessible,
        reinterpret_cast<void**>(&accessible))) && accessible) {
        VARIANT self{}; self.vt = VT_I4; self.lVal = CHILDID_SELF;
        BSTR accessibleName = nullptr;
        if (SUCCEEDED(accessible->get_accName(self, &accessibleName)) && accessibleName) {
            std::wstring label(accessibleName, SysStringLen(accessibleName));
            SysFreeString(accessibleName);
            accessible->Release();
            if (!label.empty()) return label;
        } else {
            if (accessibleName) SysFreeString(accessibleName);
            accessible->Release();
        }
    }
    return classKind(h) + L" " + std::to_wstring(id);
}

void RenderNavigation::refreshControls(HWND root) {
    if (render_ != root) {
        resetDialog(); render_ = root;
    }
    controls_.clear();
    const HWND host = directOrNested(root, 58000);
    for (HWND h : children(root)) {
        if (!IsWindowVisible(h) || !IsWindowEnabled(h)) continue;
        // REAPER can wrap its sample-rate combo in a custom HWND without
        // the usual class/WS_TABSTOP signature. Its known dialog ID is a
        // safe discovery hint; focusing is still subject to Win32 validation.
        const bool sampleRateId = GetDlgCtrlID(h) == 1041 && klass(h) != L"static";
        if (!isInput(h) && !sampleRateId) continue;
        const auto parentClass = klass(GetParent(h));
        if (parentClass.find(L"combo") != std::wstring::npos && !sampleRateId) continue;
        const bool format = host && isDescendant(host, h);
        Control entry{}; entry.hwnd = h; entry.id = static_cast<UINT>(GetDlgCtrlID(h));
        entry.format = format;
        entry.name = controlName(h, format);
        const auto cls = klass(h);
        entry.tab = cls.find(L"tab") != std::wstring::npos;
        controls_.push_back(std::move(entry));
    }
    // Treat both tab *items* as separate searchable destinations, even though
    // they can share a Win32 HWND. Focus the item itself, never its format fields.
    if (HWND tab = findFormatTab()) {
        for (int i = 0; i < 2; ++i) {
            Control entry{};
            entry.hwnd = tab; entry.tab = true; entry.format = true; entry.tabPage = i;
            entry.name = i == 0 ? L"Primary output format" : L"Secondary output format";
            controls_.push_back(std::move(entry));
        }
    }
    rebuildAccelerators();
}
void RenderNavigation::rebuildAccelerators() {
    accelerators_.clear(); // Preserve cycling indices across catalog refreshes.
    std::vector<bool> assigned(controls_.size(), false);

    // Reserve Z for the main Render sample-rate input. Prefer the known native
    // ID, but also support REAPER versions that expose it under a different
    // ID with an accessible name/nearby label. Never confuse it with the
    // separate "Use project sample rate" checkbox or a codec-specific field.
    size_t sampleRate = controls_.size();
    for (int pass = 0; pass < 2 && sampleRate == controls_.size(); ++pass) {
        for (size_t j = 0; j < controls_.size(); ++j) {
            const auto& control = controls_[j];
            if (control.format || control.tab || control.tabPage >= 0) continue;
            const auto cls = klass(control.hwnd);
            if (cls == L"button" || cls == L"static") continue;
            const bool inputLike = cls.find(L"combo") != std::wstring::npos ||
                cls.find(L"edit") != std::wstring::npos ||
                (GetWindowLongPtrW(control.hwnd, GWL_STYLE) & WS_TABSTOP) != 0;
            if (!inputLike && control.id != 1041) continue;
            const auto name = lower(control.name);
            const bool namedSampleRate = name == L"sample rate";
            if ((pass == 0 && control.id == 1041) ||
                (pass == 1 && namedSampleRate)) {
                sampleRate = j;
                break;
            }
        }
    }
    // An absent/disabled rate combo must not make Alt+Z jump elsewhere.
    accelerators_[L'z'];
    if (sampleRate < controls_.size()) {
        accelerators_[L'z'].push_back(controls_[sampleRate].hwnd);
        // Preserve the earlier TEST74.4 Alt+S shortcut as an alias.
        accelerators_[L's'].push_back(controls_[sampleRate].hwnd);
        assigned[sampleRate] = true;
    }

    // Explicit single-key anchors retain the user's preferred gestures.
    // The renderer is never started by Alt+R: SetFocus is the ONLY operation.
    constexpr std::pair<wchar_t, int> pinned[] = {
        {L'r',1},{L't',1046},{L'n',1013},{L'd',1007},
        {L'f',1116},{L'o',1003},{L'b',1002},{L'c',1397},
        {L'p',1057},{L'w',1065},{L'q',1447},{L'g',1449},
        {L'v',1001},{L'e',1000},{L'i',1042},{L'h',1307}
    };
    for (const auto& fixed : pinned) {
        for (size_t j = 0; j < controls_.size(); ++j) {
            if (assigned[j] || controls_[j].format || controls_[j].tab ||
                static_cast<int>(controls_[j].id) != fixed.second) continue;
            accelerators_[fixed.first].push_back(controls_[j].hwnd);
            assigned[j] = true; break;
        }
    }
    // Some high-value buttons have labels but no stable published control ID.
    // Match their actual visible text, never click/activate them.
    constexpr std::pair<wchar_t, const wchar_t*> named[] = {
        {L'm', L"metadata"}, {L'l', L"normalize"}, {L'y', L"dry run"}
    };
    for (const auto& anchor : named) {
        for (size_t j = 0; j < controls_.size(); ++j) {
            if (assigned[j] || controls_[j].tab || controls_[j].format) continue;
            if (has(controls_[j].name, anchor.second)) {
                accelerators_[anchor.first].push_back(controls_[j].hwnd);
                assigned[j] = true; break;
            }
        }
    }
    // Dynamic mapping: prefer a DIFFERENT letter in the control's own name.
    // Only when all letters are occupied share one and cycle on repeated Alt+key.
    for (size_t j = 0; j < controls_.size(); ++j) {
        const auto& entry = controls_[j];
        if (assigned[j] || entry.tabPage >= 0) continue;
        wchar_t fallback = 0;
        for (wchar_t c : lower(entry.name)) {
            if (c < L'a' || c > L'z') continue;
            if (!fallback) fallback = c;
            if (accelerators_.count(c) == 0) {
                accelerators_[c].push_back(entry.hwnd); assigned[j] = true; break;
            }
        }
        if (!assigned[j] && fallback) accelerators_[fallback].push_back(entry.hwnd);
    }
}

bool RenderNavigation::focusControl(HWND target) noexcept {
    if (!isInRoot(target) || !IsWindowVisible(target) || !IsWindowEnabled(target)) return false;
    inJump_ = true;
    SetFocus(target);
    inJump_ = false;
    const HWND focused = GetFocus();
    // A native combo can put keyboard focus on its inner edit HWND.
    return focused == target || (focused && IsChild(target, focused));
}
bool RenderNavigation::jumpKey(wchar_t letter) {
    return jumpKeyDirection(letter, +1);
}
bool RenderNavigation::jumpKeyDirection(wchar_t letter, int direction) {
    refreshControls(render_);
    const auto it = accelerators_.find(letter);
    if (it == accelerators_.end() || it->second.empty()) return false;
    const auto& targets = it->second;
    const size_t count = targets.size();
    const bool reverse = direction < 0;

    // A fresh reverse cycle begins at the last item. When the user is already
    // on one of the letter's controls, both directions continue from there;
    // otherwise use the saved next-forward position across other shortcuts.
    const auto previous = cycle_.find(letter);
    size_t first = 0;
    if (previous == cycle_.end()) {
        first = reverse ? count - 1 : 0;
    } else {
        const size_t nextForward = previous->second % count;
        const size_t reverseOffset = 2 % count;
        first = reverse ? (nextForward + count - reverseOffset) % count : nextForward;
    }
    const HWND focused = GetFocus();
    for (size_t i = 0; i < count; ++i) {
        if (focused && (targets[i] == focused || IsChild(targets[i], focused))) {
            first = reverse ? (i + count - 1) % count : (i + 1) % count;
            break;
        }
    }
    for (size_t attempt = 0; attempt < count; ++attempt) {
        const size_t index = reverse ? (first + count - attempt) % count
                                     : (first + attempt) % count;
        const HWND target = targets[index];
        // Only controls actually inside the format page receive this context.
        // Main Render controls do not inherit the currently selected format tab.
        bool insideFormatPage = false;
        for (const auto& c : controls_) {
            if (c.hwnd == target && c.format && !c.tab) {
                insideFormatPage = true;
                break;
            }
        }
        const int page = insideFormatPage ? selectedFormatPage() : -1;
        // Announce the page before NVDA's native control focus announcement.
        // Neither direction changes the format selection or any render value.
        if (page >= 0 && speak_ && isInRoot(target) &&
            IsWindowVisible(target) && IsWindowEnabled(target)) {
            speak_(page == 0 ? "Primary" : "Secondary");
        }
        if (focusControl(target)) {
            cycle_[letter] = (index + 1) % count;
            return true;
        }
    }
    return false;
}
std::vector<RenderNavigation::Control> RenderNavigation::results(const std::wstring& query) {
    std::vector<Control> found;
    const auto term = lower(query);
    for (const auto& control : controls_) {
        if (!control.hwnd || !IsWindow(control.hwnd) || term.empty()) continue;
        if (lower(control.name).find(term) != std::wstring::npos) found.push_back(control);
    }
    return found;
}
bool RenderNavigation::searchStep(int dir) {
    if (query_.empty()) return false;
    refreshControls(render_);
    const auto matched = results(query_);
    if (matched.empty()) return false;
    int at = -1;
    for (size_t i = 0; i < matched.size(); ++i) {
        if (matched[i].hwnd == lastResult_ && matched[i].tabPage == lastResultPage_) {
            at = static_cast<int>(i); break;
        }
    }
    const int count = static_cast<int>(matched.size());
    int next = at < 0 ? (dir > 0 ? 0 : count-1) : (at + dir + count) % count;
    for (int tries = 0; tries < count; ++tries, next = (next + dir + count) % count) {
        const auto& c = matched[static_cast<size_t>(next)];
        bool done = false;
        if (c.tabPage >= 0) done = focusPageTab(c.tabPage);
        else if (c.format && !IsWindowVisible(c.hwnd)) done = false;
        else done = focusControl(c.hwnd);
        if (done) {lastResult_ = c.hwnd; lastResultPage_ = c.tabPage; return true;}
    }
    return false;
}

HWND RenderNavigation::findFormatTab() const {
    if (!render_) return nullptr;
    AccessibleTabs tabs{};
    if (cachedFormatTab_ && IsWindow(cachedFormatTab_) &&
        isDescendant(render_, cachedFormatTab_) &&
        (readAccessibleTabs(cachedFormatTab_, tabs) ||
         klass(cachedFormatTab_) == L"systabcontrol32")) return cachedFormatTab_;
    cachedFormatTab_ = nullptr;
    if (findAccessibleTabs(render_, tabs)) {
        cachedFormatTab_ = tabs.window; return tabs.window;
    }
    for (HWND h : children(render_)) {
        if (!IsWindowVisible(h) || !IsWindowEnabled(h)) continue;
        if (klass(h) == L"systabcontrol32" &&
            SendMessageW(h, TCM_GETITEMCOUNT, 0, 0) >= 2) {
            cachedFormatTab_ = h; return h;
        }
    }
    return nullptr;
}
// A format control can be shown by either output-format page. Determine the
// ACTIVE page from REAPER's native accessibility state, not from its caption,
// focus history or the position of a control in the window. Read-only.
int RenderNavigation::selectedFormatPage() const {
    const HWND tab = findFormatTab();
    if (!tab) return -1;
    if (klass(tab) == L"systabcontrol32") {
        const LRESULT selected = SendMessageW(tab, TCM_GETCURSEL, 0, 0);
        return selected == 0 || selected == 1 ? static_cast<int>(selected) : -1;
    }
    AccessibleTabs tabs{};
    if (!readAccessibleTabs(tab, tabs)) return -1;
    IAccessible* acc = nullptr;
    if (FAILED(AccessibleObjectFromWindow(tabs.window, OBJID_CLIENT, IID_IAccessible,
        reinterpret_cast<void**>(&acc))) || !acc) return -1;
    bool selected[2]{};
    for (int page = 0; page < 2; ++page) {
        VARIANT child{}; child.vt = VT_I4; child.lVal = tabs.items[page];
        VARIANT state{}; VariantInit(&state);
        if (SUCCEEDED(acc->get_accState(child, &state)) && state.vt == VT_I4 &&
            (state.lVal & STATE_SYSTEM_SELECTED)) selected[page] = true;
        VariantClear(&state);
    }
    // Some custom tab providers expose the selected item through
    // get_accSelection instead of STATE_SYSTEM_SELECTED.
    if (selected[0] == selected[1]) {
        VARIANT selection{}; VariantInit(&selection);
        if (SUCCEEDED(acc->get_accSelection(&selection)) && selection.vt == VT_I4) {
            for (int page = 0; page < 2; ++page)
                if (selection.lVal == tabs.items[page]) selected[page] = true;
        }
        VariantClear(&selection);
    }
    acc->Release();
    // Never announce Primary/Secondary if both/neither were confirmed.
    return selected[0] != selected[1] ? (selected[0] ? 0 : 1) : -1;
}

bool RenderNavigation::focusPageTab(int page) {
    if (page < 0 || page > 1) return false;
    const HWND tab = findFormatTab();
    if (!tab) return false;
    // For a native Win32 tab, TCM_SETCURFOCUS targets the actual tab item,
    // rather than selecting a field in the current format settings pane.
    // Normal tab controls may select the page as a natural consequence of
    // moving focus; that behavior is REAPER's own, not a render-setting edit.
    if (klass(tab) == L"systabcontrol32") {
        if (!focusControl(tab)) return false;
        SendMessageW(tab, TCM_SETCURFOCUS, static_cast<WPARAM>(page), 0);
        return SendMessageW(tab, TCM_GETCURFOCUS, 0, 0) == page;
    }
    AccessibleTabs tabs{};
    if (readAccessibleTabs(tab, tabs)) return focusAccessibleTab(tabs, page);
    // Unknown custom tab implementation: never pretend we reached one of
    // the two page items by focusing a generic container instead.
    return false;
}

void RenderNavigation::findDialog() {
    if (find_ || !render_) return;
    focusBeforeFind_ = GetFocus();
    WNDCLASSW wc{};
    wc.lpfnWndProc = searchWindowProc;
    wc.hInstance = GetModuleHandleW(nullptr);
    wc.lpszClassName = findClass;
    wc.hCursor = LoadCursorW(nullptr, IDC_ARROW);
    RegisterClassW(&wc); // ERROR_CLASS_ALREADY_EXISTS is harmless.
    RECT bounds{}; GetWindowRect(render_, &bounds);
    const int x = bounds.left + std::max<int>(0, (bounds.right-bounds.left-420)/2);
    const int y = bounds.top + std::max<int>(0, (bounds.bottom-bounds.top-110)/3);
    find_ = CreateWindowExW(WS_EX_DLGMODALFRAME, findClass,
        L"Find Render control - Enter to focus, Esc to cancel",
        WS_OVERLAPPED | WS_CAPTION | WS_SYSMENU, x, y, 440, 116,
        render_, nullptr, wc.hInstance, this);
    if (!find_) return;
    HWND instruction = CreateWindowExW(0, L"STATIC", L"Control name (F3 next, Shift+F3 previous):",
        WS_CHILD | WS_VISIBLE, 12, 10, 398, 20, find_, nullptr, wc.hInstance, nullptr);
    edit_ = CreateWindowExW(WS_EX_CLIENTEDGE, L"EDIT", query_.c_str(),
        WS_CHILD | WS_VISIBLE | WS_TABSTOP | ES_AUTOHSCROLL, 12, 36, 398, 25,
        find_, reinterpret_cast<HMENU>(static_cast<INT_PTR>(101)), wc.hInstance, nullptr);
    if (!edit_) {DestroyWindow(find_); find_ = nullptr; return;}
    HFONT font = static_cast<HFONT>(GetStockObject(DEFAULT_GUI_FONT));
    SendMessageW(instruction, WM_SETFONT, reinterpret_cast<WPARAM>(font), TRUE);
    SendMessageW(edit_, WM_SETFONT, reinterpret_cast<WPARAM>(font), TRUE);
    SetWindowLongPtrW(edit_, GWLP_USERDATA, reinterpret_cast<LONG_PTR>(this));
    originalEditProc_ = reinterpret_cast<WNDPROC>(SetWindowLongPtrW(edit_, GWLP_WNDPROC,
        reinterpret_cast<LONG_PTR>(searchEditProc)));
    ShowWindow(find_, SW_SHOWNORMAL);
    SetForegroundWindow(find_);
    SetFocus(edit_);
    SendMessageW(edit_, EM_SETSEL, 0, -1);
}
void RenderNavigation::closeFind() noexcept {
    if (find_ && IsWindow(find_)) DestroyWindow(find_);
    find_ = edit_ = nullptr;
    originalEditProc_ = nullptr;
}
void RenderNavigation::finishFind(bool accept) {
    if (!find_) return;
    if (edit_) query_ = getText(edit_);
    const HWND restore = focusBeforeFind_;
    if (accept && !query_.empty()) {
        refreshControls(render_);
        if (results(query_).empty()) {
            if (speak_) speak_("No matching Render control");
            if (edit_) { SetFocus(edit_); SendMessageW(edit_, EM_SETSEL, 0, -1); }
            return; // Keep the search field open to correct the query.
        }
    }
    closeFind();
    if (render_ && IsWindow(render_)) SetForegroundWindow(render_);
    if (accept && !query_.empty()) {
        // A fresh Enter always selects the first match. Later F3 uses lastResult_.
        lastResult_ = nullptr; lastResultPage_ = -1;
        if (searchStep(+1)) return;
    }
    if (restore) focusControl(restore);
}
LRESULT CALLBACK RenderNavigation::searchWindowProc(HWND hwnd, UINT msg, WPARAM wp, LPARAM lp) {
    auto* self = reinterpret_cast<RenderNavigation*>(GetWindowLongPtrW(hwnd, GWLP_USERDATA));
    if (msg == WM_NCCREATE) {
        const auto* cs = reinterpret_cast<const CREATESTRUCTW*>(lp);
        SetWindowLongPtrW(hwnd, GWLP_USERDATA, reinterpret_cast<LONG_PTR>(cs->lpCreateParams));
        return TRUE;
    }
    if (msg == WM_CLOSE) {
        if (self) {
            try {self->finishFind(false);} catch (...) {self->closeFind();}
        } else DestroyWindow(hwnd);
        return 0;
    }
    if (msg == WM_NCDESTROY && self && self->find_ == hwnd) {
        self->find_ = self->edit_ = nullptr;
        self->originalEditProc_ = nullptr;
    }
    return DefWindowProcW(hwnd, msg, wp, lp);
}
LRESULT CALLBACK RenderNavigation::searchEditProc(HWND hwnd, UINT msg, WPARAM wp, LPARAM lp) {
    auto* self = reinterpret_cast<RenderNavigation*>(GetWindowLongPtrW(hwnd, GWLP_USERDATA));
    if (self && msg == WM_KEYDOWN) {
        if (wp == VK_RETURN || wp == VK_ESCAPE) {
            try {self->finishFind(wp == VK_RETURN);} catch (...) {self->closeFind();}
            return 0;
        }
    }
    if (msg == WM_CHAR && (wp == VK_RETURN || wp == VK_ESCAPE)) return 0;
    return self && self->originalEditProc_ ? CallWindowProcW(self->originalEditProc_, hwnd, msg, wp, lp) : DefWindowProcW(hwnd,msg,wp,lp);
}
LRESULT CALLBACK RenderNavigation::keyHook(int code, WPARAM removed, LPARAM data) {
    auto* self = active_;
    try {
        if (code >= 0 && removed == PM_REMOVE && self && data) {
            auto* msg = reinterpret_cast<MSG*>(data);
            const bool down = msg->message == WM_KEYDOWN || msg->message == WM_SYSKEYDOWN;
            const bool up = msg->message == WM_KEYUP || msg->message == WM_SYSKEYUP;
            const UINT vk = static_cast<UINT>(msg->wParam);
            bool consumed = false;
            if (up && vk < self->helpReleases_.size() &&
                self->helpReleases_[vk] == msg->hwnd) {
                self->helpReleases_[vk] = nullptr;
                consumed = true;
            } else if (down && self->onKey(*msg)) {
                // Swallow only help-mode key releases. Existing render shortcuts
                // retain their pre-existing key-up handling.
                if (self->helpMode_ || (vk == VK_F1 && (GetKeyState(VK_SHIFT) & 0x8000) &&
                    !(GetKeyState(VK_CONTROL) & 0x8000) && !(GetKeyState(VK_MENU) & 0x8000)))
                    if (vk < self->helpReleases_.size()) self->helpReleases_[vk] = msg->hwnd;
                consumed = true;
            }
            if (consumed) {
                msg->message = WM_NULL; // no native action was invoked
                msg->wParam = 0; msg->lParam = 0;
            }
        }
    } catch (...) {
        // Never let an exception trigger a Render action while inspecting.
        // Outside help, keep the original fail-open behavior.
        if (self && self->helpMode_ && data) {
            auto* message = reinterpret_cast<MSG*>(data);
            message->message = WM_NULL;
            message->wParam = 0; message->lParam = 0;
        }
    }
    return CallNextHookEx(self ? self->hook_ : nullptr, code, removed, data);
}
void RenderNavigation::announceHelp(const std::string& message) noexcept {
    try { if (speak_) speak_(message); } catch (...) {}
}
std::string RenderNavigation::describeHelpKey(UINT vk, bool ctrl, bool alt, bool shift) {
    const Key physical{vk, ctrl, alt, shift};
    const std::string gesture = shortcutHelpKeyName(physical) + ". ";
    if (!alt && ctrl && !shift && vk == 'F')
        return gesture + "Find a control in the Render window";
    if (!alt && !ctrl && vk == VK_F3) {
        if (query_.empty()) return gesture + "No stored Render search results";
        return gesture + (shift ? "Previous Render search result" : "Next Render search result");
    }
    if (!ctrl && alt && !shift && (vk == '1' || vk == '2')) {
        if (findFormatTab()) return gesture + (vk == '1' ?
            "Focus Primary output format tab" : "Focus Secondary output format tab");
        return gesture + "Output format tabs unavailable";
    }
    if (!ctrl && alt && vk >= 'A' && vk <= 'Z') {
        // Read the actual, current accelerator map. No SetFocus, no jumping,
        // no cycling-index update, no activation and no render command.
        refreshControls(render_);
        const wchar_t letter = static_cast<wchar_t>(vk - 'A' + L'a');
        const auto it = accelerators_.find(letter);
        if (it == accelerators_.end() || it->second.empty())
            return gesture + "No active Render control assigned to this letter";
        std::vector<std::string> names;
        for (HWND h : it->second) {
            if (!isInRoot(h) || !IsWindowVisible(h) || !IsWindowEnabled(h)) continue;
            for (const auto& c : controls_) {
                if (c.hwnd != h || c.tabPage >= 0) continue;
                const auto name = shortcutHelpUtf8(c.name);
                if (!name.empty() && std::find(names.begin(), names.end(), name) == names.end())
                    names.push_back(name);
                break;
            }
        }
        if (names.empty()) return gesture + "No active Render control assigned to this letter";
        std::string result = gesture + (shift ? "Focus previous control: " : "Focus control: ");
        for (size_t i = 0; i < names.size(); ++i) {
            if (i) result += ", ";
            result += names[i];
        }
        if (names.size() > 1) result += ". Cycles through " + std::to_string(names.size()) + " controls";
        return result;
    }
    return gesture + "No LReaParams Render shortcut in this context";
}
bool RenderNavigation::onKey(MSG& msg) {
    if (inJump_ || find_ || !IsWindow(msg.hwnd)) {
        // Native modal/search windows are not owned by this help context.
        if (helpMode_) { helpMode_ = false; helpFocus_ = nullptr; }
        return false;
    }
    HWND root = renderFromFocus(GetFocus());
    if (!root) { helpMode_ = false; helpFocus_ = nullptr; return false; }
    if (render_ != root) {resetDialog(); render_ = root;}
    if (msg.hwnd != GetFocus() && !isInRoot(msg.hwnd)) return false;
    GUITHREADINFO gui{sizeof(gui)};
    if (GetGUIThreadInfo(thread_, &gui) &&
        (gui.flags & (GUI_INMENUMODE | GUI_POPUPMENUMODE | GUI_SYSTEMMENUMODE | GUI_INMOVESIZE))) return false;
    const bool alt = (GetKeyState(VK_MENU) & 0x8000) != 0;
    const bool ctrl = (GetKeyState(VK_CONTROL) & 0x8000) != 0;
    const bool shift = (GetKeyState(VK_SHIFT) & 0x8000) != 0;
    const UINT vk = static_cast<UINT>(msg.wParam);
    const bool toggle = vk == VK_F1 && shift && !alt && !ctrl;
    if (toggle || helpMode_) {
        // The focus is intentionally never moved into a help window.
        if (helpMode_ && GetFocus() != helpFocus_) {
            helpMode_ = false; helpFocus_ = nullptr;
            return false;
        }
        const bool repeat = (msg.lParam & (1LL << 30)) != 0;
        if (toggle) {
            if (!repeat) {
                helpMode_ = !helpMode_;
                helpFocus_ = helpMode_ ? GetFocus() : nullptr;
                announceHelp(helpMode_ ?
                    "LReaParams Render shortcut help on. Press a shortcut to hear its function. Shift F1 to exit" :
                    "LReaParams Render shortcut help off");
            }
        } else if (!repeat && vk != VK_SHIFT && vk != VK_CONTROL && vk != VK_MENU &&
                   vk != VK_LSHIFT && vk != VK_RSHIFT && vk != VK_LCONTROL && vk != VK_RCONTROL &&
                   vk != VK_LMENU && vk != VK_RMENU) {
            announceHelp(describeHelpKey(vk, ctrl, alt, shift));
        }
        return true; // block ALL native/extension execution during help
    }
    if (alt && ctrl) return false; // never intercept AltGr or existing multi-modifier REAPER gestures
    if (ctrl && !alt && !shift && vk == 'F') {findDialog(); return find_ != nullptr;}
    if (!alt && !ctrl && vk == VK_F3) { searchStep(shift ? -1 : 1); return true; }
    if (alt && !ctrl) {
        if (!shift && (vk == '1' || vk == '2'))
            return focusPageTab(vk == '1' ? 0 : 1);
        if (vk >= 'A' && vk <= 'Z')
            return shift ? jumpKeyDirection(static_cast<wchar_t>(vk - 'A' + L'a'), -1)
                         : jumpKey(static_cast<wchar_t>(vk - 'A' + L'a'));
    }
    return false;
}
} // namespace lrp
#endif
