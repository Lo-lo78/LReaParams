#include "lrp/Preferences.h"
#include <windows.h>
#include <commctrl.h>
#include <algorithm>
#include <string>
#include <cwchar>

namespace lrp {
namespace {
bool nameFirst = true;
constexpr int IDC_SHORTCUTS=101, IDC_MESSAGES=102, IDC_KEYBOARD=103, IDC_CAPTURE=104;
constexpr int IDC_OK=IDOK, IDC_CANCEL=IDCANCEL;
constexpr int MOD_CTRL=1, MOD_ALT=2, MOD_SHIFT=4;
Key shortcut(UINT vk, int mods=0) { Key k{}; k.vk=vk; k.ctrl=(mods&MOD_CTRL)!=0; k.alt=(mods&MOD_ALT)!=0; k.shift=(mods&MOD_SHIFT)!=0; return k; }
bool same(const Key& a,const Key& b) { return a.vk==b.vk && a.ctrl==b.ctrl && a.alt==b.alt && a.shift==b.shift; }
void add(Preferences& p,const wchar_t* name,UINT vk,int mods=0) { const Key k=shortcut(vk,mods); p.shortcuts.push_back({name,k,k}); }
std::wstring keyName(const Key& k) {
    std::wstring s;
    if(k.ctrl)s+=L"Ctrl+"; if(k.alt)s+=L"Alt+"; if(k.shift)s+=L"Shift+";
    wchar_t temp[100]{};
    const UINT scan=MapVirtualKeyW(k.vk,MAPVK_VK_TO_VSC);
    const LONG scanCode=static_cast<LONG>(scan<<16) | ((k.vk==VK_LEFT||k.vk==VK_RIGHT||k.vk==VK_UP||k.vk==VK_DOWN||k.vk==VK_HOME||k.vk==VK_END||k.vk==VK_DELETE||k.vk==VK_PRIOR||k.vk==VK_NEXT)?(1L<<24):0);
    if(GetKeyNameTextW(scanCode,temp,100)>0) s+=temp;
    else s+=L"VK "+std::to_wstring(k.vk);
    return s;
}
struct DialogState { Preferences pending; HWND hwnd{}, shortcuts{}, messages{}, keyboard{}, capture{}; bool editing=false; int index=0; WNDPROC oldCapture=nullptr; };
void fillShortcuts(DialogState* st) {
    SendMessageW(st->shortcuts,LB_RESETCONTENT,0,0);
    for(const auto& item:st->pending.shortcuts) {
        const std::wstring line=keyName(item.assigned)+L" - "+item.description;
        SendMessageW(st->shortcuts,LB_ADDSTRING,0,reinterpret_cast<LPARAM>(line.c_str()));
    }
    SendMessageW(st->shortcuts,LB_SETCURSEL,st->index,0);
}
void refresh(DialogState* st) {
    const int i=static_cast<int>(SendMessageW(st->shortcuts,LB_GETCURSEL,0,0));
    if(i>=0 && i<static_cast<int>(st->pending.shortcuts.size()))st->index=i;
    if(!st->editing) SetWindowTextW(st->capture,keyName(st->pending.shortcuts[st->index].assigned).c_str());
    SendMessageW(st->messages,LB_SETCURSEL,st->pending.pluginFirst?0:1,0);
    SendMessageW(st->keyboard,LB_SETCURSEL,st->pending.compatibilityHook?1:0,0);
}
LRESULT CALLBACK captureProc(HWND hwnd,UINT msg,WPARAM wp,LPARAM lp) {
    auto* st=reinterpret_cast<DialogState*>(GetWindowLongPtrW(GetParent(hwnd),GWLP_USERDATA));
    if(!st)return DefWindowProcW(hwnd,msg,wp,lp);
    if(msg==WM_GETDLGCODE)return DLGC_WANTALLKEYS;
    if(msg==WM_KEYDOWN||msg==WM_SYSKEYDOWN) {
        const UINT vk=static_cast<UINT>(wp);
        if(vk==VK_CONTROL||vk==VK_MENU||vk==VK_SHIFT||vk==VK_LCONTROL||vk==VK_RCONTROL||vk==VK_LMENU||vk==VK_RMENU||vk==VK_LSHIFT||vk==VK_RSHIFT)return 0;
        if(vk==VK_ESCAPE) {st->editing=false;refresh(st);SetFocus(st->shortcuts);return 0;}
        if(vk==VK_TAB && !(GetKeyState(VK_CONTROL)&0x8000) && !(GetKeyState(VK_MENU)&0x8000)) {
            st->editing=false;refresh(st);
            HWND next=GetNextDlgTabItem(st->hwnd,hwnd,(GetKeyState(VK_SHIFT)&0x8000)!=0);
            if(next)SetFocus(next);return 0;
        }
        if(vk==VK_RETURN && !st->editing) {st->editing=true;SetWindowTextW(hwnd,L"Press a new shortcut (Escape cancels)");return 0;}
        Key candidate=shortcut(vk,(GetKeyState(VK_CONTROL)&0x8000?MOD_CTRL:0)|(GetKeyState(VK_MENU)&0x8000?MOD_ALT:0)|(GetKeyState(VK_SHIFT)&0x8000?MOD_SHIFT:0));
        if(!st->editing)st->editing=true;
        if(vk==VK_TAB||vk==VK_ESCAPE||vk==VK_F12||(!candidate.ctrl&&!candidate.alt&&!candidate.shift&&(vk==VK_SPACE||vk==VK_RETURN))) {
            MessageBeep(MB_ICONWARNING);SetWindowTextW(hwnd,L"Reserved shortcut. Try another key.");return 0;
        }
        for(size_t i=0;i<st->pending.shortcuts.size();++i)if(static_cast<int>(i)!=st->index && same(st->pending.shortcuts[i].assigned,candidate)) {
            MessageBeep(MB_ICONWARNING);SetWindowTextW(hwnd,L"Shortcut already assigned. Try another key.");return 0;
        }
        st->pending.shortcuts[st->index].assigned=candidate;
        st->editing=false;fillShortcuts(st);refresh(st);SetFocus(st->shortcuts);return 0;
    }
    return CallWindowProcW(st->oldCapture,hwnd,msg,wp,lp);
}
LRESULT CALLBACK cycleListProc(HWND hwnd,UINT msg,WPARAM wp,LPARAM lp,UINT_PTR,DWORD_PTR) {
    if(msg==WM_KEYDOWN && wp==VK_SPACE) {
        const int count=static_cast<int>(SendMessageW(hwnd,LB_GETCOUNT,0,0));
        if(count>0) {
            const int i=static_cast<int>(SendMessageW(hwnd,LB_GETCURSEL,0,0));
            SendMessageW(hwnd,LB_SETCURSEL,(i+1)%count,0);
            SendMessageW(GetParent(hwnd),WM_COMMAND,MAKEWPARAM(GetDlgCtrlID(hwnd),LBN_SELCHANGE),reinterpret_cast<LPARAM>(hwnd));
        }
        return 0;
    }
    return DefSubclassProc(hwnd,msg,wp,lp);
}
LRESULT CALLBACK wndProc(HWND hwnd,UINT msg,WPARAM wp,LPARAM lp) {
    auto* st=reinterpret_cast<DialogState*>(GetWindowLongPtrW(hwnd,GWLP_USERDATA));
    if(msg==WM_CREATE) {
        st=reinterpret_cast<DialogState*>(reinterpret_cast<CREATESTRUCTW*>(lp)->lpCreateParams);
        st->hwnd=hwnd;SetWindowLongPtrW(hwnd,GWLP_USERDATA,reinterpret_cast<LONG_PTR>(st));
        auto label=[&](const wchar_t* str,int x,int w) {CreateWindowW(L"STATIC",str,WS_VISIBLE|WS_CHILD,x,14,w,23,hwnd,nullptr,GetModuleHandleW(nullptr),nullptr);};
        label(L"Shortcuts",18,330);label(L"Messages",370,225);label(L"Keyboard input",615,270);
        st->shortcuts=CreateWindowExW(WS_EX_CLIENTEDGE,L"LISTBOX",L"",WS_CHILD|WS_VISIBLE|WS_TABSTOP|WS_VSCROLL|LBS_NOTIFY|LBS_NOINTEGRALHEIGHT,16,43,345,293,hwnd,reinterpret_cast<HMENU>(IDC_SHORTCUTS),nullptr,nullptr);
        st->messages=CreateWindowExW(WS_EX_CLIENTEDGE,L"LISTBOX",L"",WS_CHILD|WS_VISIBLE|WS_TABSTOP|LBS_NOTIFY,370,43,229,110,hwnd,reinterpret_cast<HMENU>(IDC_MESSAGES),nullptr,nullptr);
        st->keyboard=CreateWindowExW(WS_EX_CLIENTEDGE,L"LISTBOX",L"",WS_CHILD|WS_VISIBLE|WS_TABSTOP|LBS_NOTIFY,610,43,271,110,hwnd,reinterpret_cast<HMENU>(IDC_KEYBOARD),nullptr,nullptr);
        SetWindowSubclass(st->messages,cycleListProc,1,0);
        SetWindowSubclass(st->keyboard,cycleListProc,2,0);
        const wchar_t* msgopts[]={L"FX Params - VST3i: LB-303 (Lo-lo) - bass",L"FX Params - bass - VST3i: LB-303 (Lo-lo)"};
        for(const auto* text:msgopts)SendMessageW(st->messages,LB_ADDSTRING,0,reinterpret_cast<LPARAM>(text));
        const wchar_t* modes[]={L"1 - REAPER SDK accelerator (recommended default)",L"2 - Main-thread keyboard hook (compatibility)"};
        for(const auto* text:modes)SendMessageW(st->keyboard,LB_ADDSTRING,0,reinterpret_cast<LPARAM>(text));
        CreateWindowW(L"STATIC",L"Selected shortcut: Tab to the field and press the new key combination.",WS_VISIBLE|WS_CHILD,16,345,570,22,hwnd,nullptr,nullptr,nullptr);
        st->capture=CreateWindowExW(WS_EX_CLIENTEDGE,L"EDIT",L"",WS_CHILD|WS_VISIBLE|WS_TABSTOP|ES_READONLY,16,368,345,29,hwnd,reinterpret_cast<HMENU>(IDC_CAPTURE),nullptr,nullptr);
        st->oldCapture=reinterpret_cast<WNDPROC>(SetWindowLongPtrW(st->capture,GWLP_WNDPROC,reinterpret_cast<LONG_PTR>(captureProc)));
        SetWindowPos(st->capture,st->shortcuts,0,0,0,0,SWP_NOMOVE|SWP_NOSIZE|SWP_NOACTIVATE);
        CreateWindowW(L"BUTTON",L"OK",WS_CHILD|WS_VISIBLE|WS_TABSTOP|BS_DEFPUSHBUTTON,675,363,98,34,hwnd,reinterpret_cast<HMENU>(IDC_OK),nullptr,nullptr);
        CreateWindowW(L"BUTTON",L"Cancel",WS_CHILD|WS_VISIBLE|WS_TABSTOP,783,363,98,34,hwnd,reinterpret_cast<HMENU>(IDC_CANCEL),nullptr,nullptr);
        for(HWND ctrl:{st->shortcuts,st->messages,st->keyboard,st->capture})SendMessageW(ctrl,WM_SETFONT,reinterpret_cast<WPARAM>(GetStockObject(DEFAULT_GUI_FONT)),TRUE);
        fillShortcuts(st);refresh(st);return 0;
    }
    if(!st)return DefWindowProcW(hwnd,msg,wp,lp);
    if(msg==WM_SYSKEYDOWN && (GetKeyState(VK_MENU)&0x8000) && (wp=='1'||wp=='2')) {
        const int index=wp=='1'?0:1;
        SendMessageW(st->keyboard,LB_SETCURSEL,index,0);
        st->pending.compatibilityHook=index==1;return 0;
    }
    if(msg==WM_COMMAND) {
        const int id=LOWORD(wp);const int notice=HIWORD(wp);
        if(id==IDOK) {SetWindowLongPtrW(hwnd,GWLP_USERDATA,0);st->hwnd=nullptr;DestroyWindow(hwnd);return 0;}
        if(id==IDCANCEL) {st->pending.shortcuts.clear();SetWindowLongPtrW(hwnd,GWLP_USERDATA,0);st->hwnd=nullptr;DestroyWindow(hwnd);return 0;}
        if(id==IDC_SHORTCUTS && notice==LBN_SELCHANGE){refresh(st);return 0;}
        if(id==IDC_MESSAGES && notice==LBN_SELCHANGE){st->pending.pluginFirst=SendMessageW(st->messages,LB_GETCURSEL,0,0)==0;return 0;}
        if(id==IDC_KEYBOARD && notice==LBN_SELCHANGE){st->pending.compatibilityHook=SendMessageW(st->keyboard,LB_GETCURSEL,0,0)==1;return 0;}
    }
    if(msg==WM_CLOSE){SendMessageW(hwnd,WM_COMMAND,IDCANCEL,0);return 0;}
    return DefWindowProcW(hwnd,msg,wp,lp);
}
}
Preferences defaultPreferences() {
    Preferences p;
    add(p,L"Find parameter / track",'F',MOD_CTRL);
    add(p,L"Switch between FX Params and Track Params",VK_TAB,MOD_CTRL);
    add(p,L"FX / Track Memories",'M',MOD_CTRL|MOD_SHIFT);
    add(p,L"Back to REAPER, keep MIDI running",'Q',MOD_CTRL);
    add(p,L"Change FX, previous",VK_UP,MOD_CTRL);
    add(p,L"Change FX, next",VK_DOWN,MOD_CTRL);
    add(p,L"Move FX, previous",VK_PRIOR,MOD_CTRL);
    add(p,L"Move FX, next",VK_NEXT,MOD_CTRL);
    add(p,L"Change track, previous",VK_UP,MOD_CTRL|MOD_SHIFT);
    add(p,L"Change track, next",VK_DOWN,MOD_CTRL|MOD_SHIFT);
    add(p,L"Open native FX chain",'F',MOD_CTRL|MOD_SHIFT);
    add(p,L"Open native FX browser",'F',MOD_ALT|MOD_SHIFT);
    add(p,L"FX browser / parameter grid",VK_F10);
    add(p,L"FX audio pin connector",VK_F11);
    add(p,L"Toggle FX parameter keyboard theme",VK_F4);
    add(p,L"FX parameter comparison",VK_F8);
    add(p,L"Read current context",VK_TAB);
    add(p,L"Change Grid / Value",VK_RETURN);
    add(p,L"Step decrease",VK_LEFT,MOD_ALT);
    add(p,L"Step increase",VK_RIGHT,MOD_ALT);
    add(p,L"Reset parameter value",VK_BACK);
    add(p,L"Reset parameter step",VK_BACK,MOD_CTRL);
    add(p,L"Reset FX values",VK_BACK,MOD_CTRL|MOD_SHIFT);
    add(p,L"Copy parameter value",'C',MOD_CTRL);
    add(p,L"Paste parameter value",'V',MOD_CTRL);
    add(p,L"Used parameters",'L',MOD_CTRL|MOD_SHIFT);
    add(p,L"Track page F1",VK_F1);
    add(p,L"Track page F2",VK_F2);
    add(p,L"Track page F3",VK_F3);
    add(p,L"Track page F5",VK_F5);
    add(p,L"Track page F6",VK_F6);
    add(p,L"Track page F7",VK_F7);
    return p;
}
Preferences loadPreferences(const std::filesystem::path& file) {
    Preferences p=defaultPreferences(); const std::wstring path=file.wstring();
    p.pluginFirst=GetPrivateProfileIntW(L"Messages",L"PluginFirst",1,path.c_str())!=0;
    p.compatibilityHook=GetPrivateProfileIntW(L"Keyboard",L"CompatibilityHook",0,path.c_str())!=0;
    for(size_t i=0;i<p.shortcuts.size();++i) {
        const std::wstring key=L"Shortcut"+std::to_wstring(i);
        const int value=GetPrivateProfileIntW(L"Shortcuts",key.c_str(),-1,path.c_str());
        if(value<0)continue;
        const Key c=shortcut(static_cast<UINT>(value&255),value>>8);
        bool duplicate=false;
        for(size_t j=0;j<p.shortcuts.size();++j)if(i!=j && same(p.shortcuts[j].assigned,c))duplicate=true;
        if(!duplicate && c.vk && c.vk!=VK_ESCAPE && c.vk!=VK_F12)p.shortcuts[i].assigned=c;
    }
    return p;
}
bool savePreferences(const std::filesystem::path& file,const Preferences& p) {
    const auto path=file.wstring();
    if(!WritePrivateProfileStringW(L"Messages",L"PluginFirst",p.pluginFirst?L"1":L"0",path.c_str()))return false;
    if(!WritePrivateProfileStringW(L"Keyboard",L"CompatibilityHook",p.compatibilityHook?L"1":L"0",path.c_str()))return false;
    for(size_t i=0;i<p.shortcuts.size();++i){
        const auto& k=p.shortcuts[i].assigned;
        const int v=static_cast<int>(k.vk)|(k.ctrl?MOD_CTRL<<8:0)|(k.alt?MOD_ALT<<8:0)|(k.shift?MOD_SHIFT<<8:0);
        const std::wstring name=L"Shortcut"+std::to_wstring(i), value=std::to_wstring(v);
        if(!WritePrivateProfileStringW(L"Shortcuts",name.c_str(),value.c_str(),path.c_str()))return false;
    }
    return true;
}
std::optional<Preferences> editPreferences(HWND owner,const Preferences& current) {
    static const wchar_t* cls=L"LReaParamsPreferencesV1";
    static bool registered=false;
    if(!registered){WNDCLASSW wc{};wc.lpfnWndProc=wndProc;wc.hInstance=GetModuleHandleW(nullptr);wc.lpszClassName=cls;wc.hCursor=LoadCursorW(nullptr,IDC_ARROW);wc.hbrBackground=reinterpret_cast<HBRUSH>(COLOR_BTNFACE+1);if(!RegisterClassW(&wc) && GetLastError()!=ERROR_CLASS_ALREADY_EXISTS)return std::nullopt;registered=true;}
    DialogState state;state.pending=current;
    HWND hwnd=CreateWindowExW(WS_EX_DLGMODALFRAME|WS_EX_CONTROLPARENT,cls,L"LReaParams - Preferences",WS_POPUP|WS_CAPTION|WS_SYSMENU|WS_VISIBLE,CW_USEDEFAULT,CW_USEDEFAULT,914,458,owner,nullptr,GetModuleHandleW(nullptr),&state);
    if(!hwnd)return std::nullopt;
    EnableWindow(owner,FALSE);SetForegroundWindow(hwnd);SetFocus(state.shortcuts);
    MSG msg{};
    while(state.hwnd && GetMessageW(&msg,nullptr,0,0)>0) {
        if(!IsDialogMessageW(hwnd,&msg)){TranslateMessage(&msg);DispatchMessageW(&msg);}
    }
    EnableWindow(owner,TRUE);SetForegroundWindow(owner);
    if(state.pending.shortcuts.empty())return std::nullopt;
    return state.pending;
}
Key mapPreferredShortcut(Key key,const Preferences& p) noexcept {
    if(key.altGr)return key;
    // Do not steal typing in search, rename, F7, or native text controls.
    for(const auto& entry:p.shortcuts)if(same(key,entry.assigned)) {
        Key out=key;out.vk=entry.original.vk;out.ctrl=entry.original.ctrl;out.alt=entry.original.alt;out.shift=entry.original.shift;
        if(out.vk!=key.vk)out.character=0;
        return out;
    }
    for(const auto& entry:p.shortcuts)if(!same(entry.original,entry.assigned) && same(key,entry.original)) {key.vk=0;return key;}
    return key;
}
void setFxNameFirst(bool value) noexcept {nameFirst=value;}
bool fxNameFirst() noexcept {return nameFirst;}
}
