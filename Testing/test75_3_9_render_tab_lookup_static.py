#!/usr/bin/env python3
"""TEST75.3.9: Render Alt+1/Alt+2 lookup selects the real tab with a final success."""
from pathlib import Path
src=(Path(__file__).resolve().parents[1]/'src/Preferences.cpp').read_text(encoding='utf-8')
lookup=src.split('bool findShortcut(DialogState* st, const Key& key)',1)[1].split('void resetSingleShortcut(',1)[0]
proc=src.split('LRESULT CALLBACK pageProc(',1)[1].split('LRESULT CALLBACK wndProc(',1)[0]
pump=src.split('std::optional<Preferences> editPreferences(',1)[1]
assert "(key.vk == '1' || key.vk == '2')" in lookup
assert 'const std::wstring tabId = key.vk == \'1\' ? L"tab|0" : L"tab|1";' in lookup
assert 'st->renderVisible[i].identity == tabId' in lookup
assert 'if (!personalTabOverride && key.alt && !key.ctrl && !key.shift' in lookup
assert lookup.index('const bool personalTabOverride') < lookup.index('bool personalized = false;')
assert 'return false; // A missing tab is not reported as available.' in lookup
assert 'st->lookupResolvedTabVk == vk' in proc
assert 'if (renderTabGesture) st->lookupResolvedTabVk = vk;' in proc
assert 'if (findShortcut(st, query)) {' in proc
success=proc.split('if (findShortcut(st, query)) {',1)[1].split('} else {',1)[0]
assert 'st->lookupQueryVk = 0;' in success
assert 'st->lookupMissPending = false;' in success
assert 'UINT lookupResolvedTabVk = 0;' in src
assert 'static_cast<UINT>(msg.wParam) == state.lookupResolvedTabVk' in pump
assert 'state.lookupQueryVk = 0;' in pump and 'state.lookupMissPending = false;' in pump
assert 'continue;' in pump.split('static_cast<UINT>(msg.wParam) == state.lookupResolvedTabVk)',1)[1].split('}',1)[0]
assert 'state.announce("Shortcut not found in this section")' in pump
assert "msg.wParam == 'S'" in pump and "msg.wParam == 'D'" not in pump
print('TEST75.3.9 Render tab lookup and definitive success: static PASS')
