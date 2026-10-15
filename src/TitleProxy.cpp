#include "lrp/TitleProxy.h"
#include <algorithm>
#include <cmath>
#include <commctrl.h>
#include <cwchar>
#include <utility>

namespace lrp {
namespace {
std::wstring toWide(const std::string& text) {
    if (text.empty()) return {};
    int len = MultiByteToWideChar(CP_UTF8, MB_ERR_INVALID_CHARS, text.c_str(), -1, nullptr, 0);
    const UINT codepage = len > 0 ? CP_UTF8 : CP_ACP;
    if (len <= 0) len = MultiByteToWideChar(codepage, 0, text.c_str(), -1, nullptr, 0);
    if (len <= 0) return L"";
    std::wstring result(static_cast<size_t>(len), L'\0');
    if (!MultiByteToWideChar(codepage, 0, text.c_str(), -1, &result[0], len)) return L"";
    result.resize(static_cast<size_t>(len - 1));
    for (auto& c : result) if (c == L'\r' || c == L'\n' || c == L'\t') c = L' ';
    return result;
}
}

bool TitleProxy::ensureWindow() {
    if (window_ && IsWindow(window_) && edit_ && IsWindow(edit_) && slider_ && IsWindow(slider_) && nativeEdit_ && IsWindow(nativeEdit_)) return true;
    instance_ = GetModuleHandleW(nullptr);
    if (!classRegistered_) {
        WNDCLASSW wc{};
        wc.lpfnWndProc = windowProc;
        wc.hInstance = instance_;
        wc.lpszClassName = kClass;
        if (!RegisterClassW(&wc) && GetLastError() != ERROR_CLASS_ALREADY_EXISTS) return false;
        classRegistered_ = true;
    }
    window_ = CreateWindowExW(WS_EX_TOOLWINDOW, kClass, L"LReaParams",
        WS_POPUP | WS_CAPTION, -32000, -32000, 1, 1,
        host_, nullptr, instance_, this);
    if (!window_) return false;
    // TEST12: keep a STATIC keyboard owner, but do not mutate its native
    // caption while it owns focus.  SetWindowTextW would broadcast a native
    // accessibility name/text-change event, which NVDA can speak on top of
    // the explicit OSARA announcement.  We expose the latest review text
    // ON DEMAND via WM_GETTEXT/WM_GETTEXTLENGTH instead.  No edit caret,
    // no artificial name-change event for each parameter movement.
    edit_ = CreateWindowExW(0, L"STATIC", L"", WS_CHILD | WS_VISIBLE |
        WS_TABSTOP | SS_NOTIFY | SS_LEFT, 0, 0, 1, 1,
        window_, nullptr, instance_, nullptr);
    if (!edit_) { DestroyWindow(window_); window_ = nullptr; return false; }
    INITCOMMONCONTROLSEX classes{sizeof(INITCOMMONCONTROLSEX), ICC_BAR_CLASSES};
    if (!InitCommonControlsEx(&classes)) {
        DestroyWindow(window_); window_ = nullptr; edit_ = nullptr; return false;
    }
    // A real standard Windows trackbar gives NVDA a native slider role in Value.
    // The focusable STATIC still owns keyboard input when navigating Grid.
    slider_ = CreateWindowExW(0, TRACKBAR_CLASSW, L"Value",
        WS_CHILD | WS_TABSTOP | TBS_HORZ | TBS_NOTICKS,
        0, 0, 1, 1, window_, nullptr, instance_, nullptr);
    if (!slider_) { DestroyWindow(window_); window_ = nullptr; edit_ = nullptr; return false; }
    SendMessageW(slider_, TBM_SETRANGEMIN, FALSE, 0);
    SendMessageW(slider_, TBM_SETRANGEMAX, FALSE, 10000);
    // Standard EDIT + associated STATIC label: NVDA gets caret, selection,
    // clipboard and text-control semantics from Windows, not a simulated field.
    nativeLabel_ = CreateWindowExW(0, L"STATIC", L"Find parameter", WS_CHILD | WS_VISIBLE,
        0, 0, 1, 1, window_, nullptr, instance_, nullptr);
    ShowWindow(nativeLabel_,SW_HIDE);
    nativeEdit_ = CreateWindowExW(WS_EX_CLIENTEDGE, L"EDIT", L"",
        WS_CHILD | WS_TABSTOP | ES_AUTOHSCROLL | WS_BORDER,
        0, 0, 1, 1, window_, nullptr, instance_, nullptr);
    if(!nativeLabel_||!nativeEdit_) {
        DestroyWindow(window_);window_=nullptr;edit_=slider_=nativeLabel_=nativeEdit_=nullptr;return false;
    }
    SendMessageW(nativeEdit_,EM_LIMITTEXT,240,0);
    SetWindowLongPtrW(nativeEdit_, GWLP_USERDATA, reinterpret_cast<LONG_PTR>(this));
    SetLastError(0);
    const auto oldNative = SetWindowLongPtrW(nativeEdit_, GWLP_WNDPROC,
                                            reinterpret_cast<LONG_PTR>(&TitleProxy::nativeEditProc));
    if(!oldNative && GetLastError()){
        DestroyWindow(window_);window_=nullptr;edit_=slider_=nativeLabel_=nativeEdit_=nullptr;return false;
    }
    originalNativeEditProc_=reinterpret_cast<WNDPROC>(oldNative);
    SetWindowLongPtrW(slider_, GWLP_USERDATA, reinterpret_cast<LONG_PTR>(this));
    SetLastError(0);
    const LONG_PTR previousSlider = SetWindowLongPtrW(slider_, GWLP_WNDPROC,
                                                       reinterpret_cast<LONG_PTR>(&TitleProxy::sliderProc));
    if (!previousSlider && GetLastError()) {
        DestroyWindow(window_); window_ = nullptr; edit_ = slider_ = nullptr; return false;
    }
    originalSliderProc_ = reinterpret_cast<WNDPROC>(previousSlider);
    SetWindowLongPtrW(edit_, GWLP_USERDATA, reinterpret_cast<LONG_PTR>(this));
    SetLastError(0);
    const LONG_PTR old = SetWindowLongPtrW(edit_, GWLP_WNDPROC,
                                           reinterpret_cast<LONG_PTR>(&TitleProxy::editProc));
    if (!old && GetLastError()) {
        DestroyWindow(window_); window_ = nullptr; edit_ = slider_ = nullptr; return false;
    }
    originalEditProc_ = reinterpret_cast<WNDPROC>(old);
    return true;
}

bool TitleProxy::activate(const std::wstring& title, const std::string& initialReviewLine,
                          std::function<void()> closeNavigator,
                          std::function<bool(HWND, UINT, bool)> keyboardKey) {
    hideAndRestore();
    if (!ensureWindow()) return false;
    originalForeground_ = GetForegroundWindow();
    originalFocus_ = GetFocus();
    closeNavigator_ = std::move(closeNavigator);
    keyboardKey_ = std::move(keyboardKey);
    title_ = title;
    sliderMode_ = false;nativeEditMode_=false;
    sliderLabel_.clear();
    ShowWindow(nativeEdit_,SW_HIDE);
    ShowWindow(nativeLabel_,SW_HIDE);
    ShowWindow(slider_, SW_HIDE);
    ShowWindow(edit_, SW_SHOW);
    reviewText_ = toWide(initialReviewLine);
    if (reviewText_.size() > 8192) reviewText_.resize(8192);
    // The child STATIC's stored caption is deliberately constant (empty).
    // Its window procedure answers WM_GETTEXT with reviewText_ when NVDA or
    // another client explicitly asks.  We never call SetWindowTextW(edit_)
    // during navigation: only OSARA should initiate movement speech.
    SetWindowTextW(window_, title_.c_str());
    ShowWindow(window_, SW_SHOW);
    SetForegroundWindow(window_);
    SetFocus(edit_);
    if (!active()) { hideAndRestore(); return false; }
    return true;
}

void TitleProxy::syncValueControl(bool valueMode, const std::string& parameter, double position) {
    if (!window_ || !IsWindowVisible(window_) || !slider_) return;
    if (valueMode) {
        // FX Params and Track Params deliberately use the very same real
        // TRACKBAR_CLASSW, not a simulated Value field. REAPER is authoritative
        // for all key handling; this trackbar reflects its normalized position.
        const double safe = std::isfinite(position) ? std::clamp(position, 0.0, 1.0) : 0.0;
        const int scaled = static_cast<int>(std::lround(safe * 10000.0));
        if (static_cast<int>(SendMessageW(slider_, TBM_GETPOS, 0, 0)) != scaled)
            SendMessageW(slider_, TBM_SETPOS, FALSE, scaled);
        const std::wstring label = L"Value, " + toWide(parameter);
        if (label != sliderLabel_) {
            sliderLabel_ = label;
            // Only change the native name when the focused PARAMETER changes,
            // never on each nudge: this avoids duplicate NVDA name-change events.
            SetWindowTextW(slider_, sliderLabel_.c_str());
        }
        if (!sliderMode_) {
            ShowWindow(edit_, SW_HIDE);
            ShowWindow(slider_, SW_SHOW);
            sliderMode_ = true;
            // Put actual Windows keyboard focus on the trackbar. Changing just
            // the title or review text would leave NVDA on the Grid control.
            SetFocus(slider_);
        }
        return;
    }
    if (sliderMode_) {
        ShowWindow(slider_, SW_HIDE);
        ShowWindow(edit_, SW_SHOW);
        sliderMode_ = false;
        SetFocus(edit_);
    }
}

void TitleProxy::syncTextControl(bool enabled, const std::string& label, const std::string& initialValue) {
    if(!window_||!nativeEdit_||!IsWindowVisible(window_))return;
    if(enabled){
        if(!nativeEditMode_) {
            SetWindowTextW(nativeLabel_,toWide(label).c_str());
            SetWindowTextW(nativeEdit_,toWide(initialValue).c_str());
            SendMessageW(nativeEdit_,EM_SETSEL,0,-1);
            ShowWindow(edit_,SW_HIDE);
            ShowWindow(slider_,SW_HIDE);
            ShowWindow(nativeLabel_,SW_SHOW);
            ShowWindow(nativeEdit_,SW_SHOW);
            nativeEditMode_=true;
            SetFocus(nativeEdit_);
        }
    } else if(nativeEditMode_){
        ShowWindow(nativeEdit_,SW_HIDE);
        ShowWindow(nativeLabel_,SW_HIDE);
        nativeEditMode_=false;
        if(sliderMode_){ShowWindow(slider_,SW_SHOW);SetFocus(slider_);}
        else {ShowWindow(edit_,SW_SHOW);SetFocus(edit_);}
    }
}
std::string TitleProxy::textValue() const {
    if(!nativeEdit_||!nativeEditMode_)return {};
    const int length=GetWindowTextLengthW(nativeEdit_);
    if(length<0||length>16384)return {};
    std::wstring wide(static_cast<size_t>(length+1),L'\0');
    const int copied=GetWindowTextW(nativeEdit_,wide.data(),length+1);
    wide.resize(static_cast<size_t>(std::max(0,copied)));
    if(wide.empty())return {};
    const int bytes=WideCharToMultiByte(CP_UTF8,0,wide.data(),static_cast<int>(wide.size()),nullptr,0,nullptr,nullptr);
    if(bytes<=0)return {};
    std::string value(static_cast<size_t>(bytes),'\0');
    WideCharToMultiByte(CP_UTF8,0,wide.data(),static_cast<int>(wide.size()),value.data(),bytes,nullptr,nullptr);
    return value;
}
void TitleProxy::updateTitle(const std::wstring& title) {
    if (!window_ || !IsWindowVisible(window_) || title == title_) return;
    title_ = title;
    SetWindowTextW(window_, title_.c_str());
}
void TitleProxy::updateReviewLine(const std::string& utf8Text) {
    if (!edit_ || !IsWindowVisible(window_)) return;
    auto line = toWide(utf8Text);
    if (line.size() > 8192) line.resize(8192);
    if (line == reviewText_) return;
    // Passive update: expose new text on the next explicit query, without
    // firing EVENT_OBJECT_NAMECHANGE/other Windows accessibility events.
    // Avoid SetWindowTextW on the focused STATIC at all costs.
    reviewText_ = std::move(line);
}
void TitleProxy::reassertFocusAfterNavigationKey() noexcept {
    if (!window_ || !hwnd() || !IsWindowVisible(window_) || !IsWindowEnabled(host_)) return;
    HWND front = GetForegroundWindow();
    if (!front) return;
    DWORD pid = 0;
    if (GetWindowThreadProcessId(front, &pid) != GetCurrentThreadId() || pid != GetCurrentProcessId()) return;
    GUITHREADINFO gui{sizeof(gui)};
    if (!GetGUIThreadInfo(GetCurrentThreadId(), &gui)) return;
    if (gui.flags & (GUI_INMENUMODE | GUI_POPUPMENUMODE | GUI_SYSTEMMENUMODE | GUI_INMOVESIZE)) return;
    // Do not steal focus from a REAPER text-entry field or modal dialog.
    if (front != window_ && gui.hwndCaret) return;
    if (front != window_) SetForegroundWindow(window_);
    if (GetForegroundWindow() == window_ && GetFocus() != hwnd()) SetFocus(hwnd());
}
void TitleProxy::hideAndRestore() noexcept {
    if (!window_) return;
    const bool ours = GetForegroundWindow() == window_;
    const HWND oldForeground = originalForeground_;
    const HWND oldFocus = originalFocus_;
    closeNavigator_ = {};
    keyboardKey_ = {};
    sliderMode_ = false; nativeEditMode_=false;
    originalForeground_ = originalFocus_ = nullptr;
    if (IsWindowVisible(window_)) ShowWindow(window_, SW_HIDE);
    if (ours) {
        if (oldForeground && IsWindow(oldForeground)) SetForegroundWindow(oldForeground);
        else if (host_ && IsWindow(host_)) SetForegroundWindow(host_);
        if (oldFocus && IsWindow(oldFocus) && GetWindowThreadProcessId(oldFocus, nullptr) == GetCurrentThreadId())
            SetFocus(oldFocus);
    }
}
void TitleProxy::shutdown() noexcept {
    hideAndRestore();
    if(nativeEdit_ && IsWindow(nativeEdit_) && originalNativeEditProc_)
        SetWindowLongPtrW(nativeEdit_,GWLP_WNDPROC,reinterpret_cast<LONG_PTR>(originalNativeEditProc_));
    if (edit_ && IsWindow(edit_) && originalEditProc_)
        SetWindowLongPtrW(edit_, GWLP_WNDPROC, reinterpret_cast<LONG_PTR>(originalEditProc_));
    if (slider_ && IsWindow(slider_) && originalSliderProc_)
        SetWindowLongPtrW(slider_, GWLP_WNDPROC, reinterpret_cast<LONG_PTR>(originalSliderProc_));
    if (window_) { DestroyWindow(window_); window_ = nullptr; }
    edit_ = slider_ = nativeEdit_ = nativeLabel_ = nullptr;
    sliderLabel_.clear();
    originalEditProc_ = originalSliderProc_ = originalNativeEditProc_ = nullptr;
    if (classRegistered_) { UnregisterClassW(kClass, instance_); classRegistered_ = false; }
}
void TitleProxy::onF12(LPARAM) noexcept {
    auto close = std::move(closeNavigator_);
    try { if (close) close(); else hideAndRestore(); }
    catch (...) { hideAndRestore(); }
    if (host_ && IsWindow(host_)) {
        const LPARAM sc = static_cast<LPARAM>(MapVirtualKeyW(VK_F12, MAPVK_VK_TO_VSC)) << 16;
        PostMessageW(host_, WM_KEYDOWN, VK_F12, sc | 1);
        PostMessageW(host_, WM_KEYUP, VK_F12, sc | 0xC0000001L);
    }
}
LRESULT CALLBACK TitleProxy::windowProc(HWND hwnd, UINT msg, WPARAM wp, LPARAM lp) noexcept {
    if (msg == WM_NCCREATE) {
        auto* info = reinterpret_cast<CREATESTRUCTW*>(lp);
        SetWindowLongPtrW(hwnd, GWLP_USERDATA, reinterpret_cast<LONG_PTR>(info->lpCreateParams));
    }
    if (msg == WM_NCDESTROY) SetWindowLongPtrW(hwnd, GWLP_USERDATA, 0);
    return DefWindowProcW(hwnd, msg, wp, lp);
}
LRESULT CALLBACK TitleProxy::editProc(HWND hwnd, UINT msg, WPARAM wp, LPARAM lp) noexcept {
    auto* self = reinterpret_cast<TitleProxy*>(GetWindowLongPtrW(hwnd, GWLP_USERDATA));
    if (!self || !self->originalEditProc_) return DefWindowProcW(hwnd, msg, wp, lp);
    return self->dispatchKeyOwner(hwnd, msg, wp, lp, self->originalEditProc_);
}
LRESULT CALLBACK TitleProxy::sliderProc(HWND hwnd, UINT msg, WPARAM wp, LPARAM lp) noexcept {
    auto* self = reinterpret_cast<TitleProxy*>(GetWindowLongPtrW(hwnd, GWLP_USERDATA));
    if (!self || !self->originalSliderProc_) return DefWindowProcW(hwnd, msg, wp, lp);
    return self->dispatchKeyOwner(hwnd, msg, wp, lp, self->originalSliderProc_);
}
LRESULT CALLBACK TitleProxy::nativeEditProc(HWND hwnd,UINT msg,WPARAM wp,LPARAM lp) noexcept {
    auto* self=reinterpret_cast<TitleProxy*>(GetWindowLongPtrW(hwnd,GWLP_USERDATA));
    if(!self || !self->originalNativeEditProc_)return DefWindowProcW(hwnd,msg,wp,lp);
    if(msg==WM_GETDLGCODE)return DLGC_WANTALLKEYS | DLGC_WANTARROWS | DLGC_WANTCHARS;
    if((msg==WM_KEYDOWN||msg==WM_SYSKEYDOWN) && wp==VK_F12) {
        if(!(lp & (1LL<<30)))self->onF12(lp);return 0;
    }
    if((msg==WM_KEYDOWN||msg==WM_SYSKEYDOWN) &&
       (wp==VK_RETURN||wp==VK_ESCAPE||wp==VK_UP||wp==VK_DOWN||
        (wp=='F' && (GetKeyState(VK_CONTROL)&0x8000)))) {
        try {if(self->keyboardKey_)self->keyboardKey_(hwnd,static_cast<UINT>(wp),(lp & (1LL<<30))!=0);}
        catch(...) {auto close=std::move(self->closeNavigator_);try{if(close)close();}catch(...){}}
        return 0;
    }
    if((msg==WM_CHAR||msg==WM_SYSCHAR) &&
       (wp==VK_RETURN||wp==VK_ESCAPE||wp==VK_F12||wp==6))return 0;
    if(msg==WM_CLOSE){auto close=std::move(self->closeNavigator_);
        try{if(close)close();}catch(...){}return 0;}
    return CallWindowProcW(self->originalNativeEditProc_,hwnd,msg,wp,lp);
}
LRESULT TitleProxy::dispatchKeyOwner(HWND hwnd, UINT msg, WPARAM wp, LPARAM lp, WNDPROC original) noexcept {
    // WM_GETTEXT remains a passive review query: no changing captions while
    // the value changes, and no duplicate OSARA/native text-change speech.
    if (msg == WM_GETTEXTLENGTH) return static_cast<LRESULT>(reviewText_.size());
    if (msg == WM_GETTEXT) {
        if (!lp || !wp) return 0;
        auto* target = reinterpret_cast<wchar_t*>(lp);
        const auto length = std::min(reviewText_.size(), static_cast<size_t>(wp - 1));
        if (length) std::wmemcpy(target, reviewText_.data(), length);
        target[length] = L'\0';
        return static_cast<LRESULT>(length);
    }
    if (msg == WM_GETDLGCODE) return DLGC_WANTALLKEYS | DLGC_WANTARROWS | DLGC_WANTCHARS;
    if ((msg == WM_KEYDOWN || msg == WM_SYSKEYDOWN) && wp == VK_F12) {
        if (!(lp & (1LL << 30))) onF12(lp);
        return 0;
    }
    if ((msg == WM_KEYUP || msg == WM_SYSKEYUP) && wp == VK_F12) return 0;
    if (msg == WM_KEYDOWN || msg == WM_SYSKEYDOWN) {
        // The OSARA/REAPER navigation backend stays authoritative for ALL keys.
        // No native trackbar key may edit the control independently of REAPER.
        try { if (keyboardKey_) keyboardKey_(hwnd, static_cast<UINT>(wp), (lp & (1LL << 30)) != 0); }
        catch (...) {
            auto close = std::move(closeNavigator_);
            try { if (close) close(); } catch (...) {}
        }
        return 0;
    }
    if (msg == WM_KEYUP || msg == WM_SYSKEYUP || msg == WM_CHAR ||
        msg == WM_SYSCHAR || msg == WM_DEADCHAR || msg == WM_SYSDEADCHAR) return 0;
    if (msg == WM_CLOSE) {
        auto close = std::move(closeNavigator_);
        try { if (close) close(); else hideAndRestore(); }
        catch (...) { hideAndRestore(); }
        return 0;
    }
    return CallWindowProcW(original, hwnd, msg, wp, lp);
}
} // namespace lrp
