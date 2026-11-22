#!/usr/bin/env python3
"""TEST75.3.6 source-only regression checks; Windows/NVDA runtime still required."""
from pathlib import Path
r = Path(__file__).resolve().parents[1]
pref = (r / 'src/Preferences.cpp').read_text(encoding='utf-8')
ext = (r / 'src/Extension.cpp').read_text(encoding='utf-8')
render = (r / 'src/RenderNavigation.cpp').read_text(encoding='utf-8')
# The lookup activator must be swallowed until release, not queried again.
assert 'UINT lookupActivator = 0;' in pref
assert 'void focusShortcutLookup(DialogState* st, UINT activator)' in pref
assert 'st->lookupActivator = activator;' in pref
assert 'focusShortcutLookup(&state, static_cast<UINT>(msg.wParam));' in pref
assert 'focusShortcutLookup(st, vk);' in pref
assert 'if (isDialogMessage && state.lookupActivator)' in pref
assert 'if (msg.message == WM_KEYUP || msg.message == WM_SYSKEYUP)' in pref
assert 'state.lookupActivator = 0;' in pref
assert 'if (matchingCharacter) continue;' in pref
assert 'if (st->lookupActivator == vk) return 0;' in pref
# The user receives a not-found message only for a genuinely unmatched key.
lookup = pref.split('void findShortcut(DialogState* st, const Key& key)',1)[1].split('void resetSingleShortcut(',1)[0]
assert lookup.index('if (found < 0) {') < lookup.index('Shortcut not found in this section')
assert lookup.index('Shortcut not found in this section') < lookup.index('selectList(st->shortcuts, found)')
assert 'SetFocus(st->shortcuts)' in lookup
# Modal owner and focus chain: enabling before DestroyWindow avoids leaving
# Render as the only manually foregrounded window with a stale active owner.
close = pref.split('if (id == IDOK || id == IDCANCEL) {',1)[1].split('if (id == IDC_MESSAGE_TOPICS',1)[0]
assert close.index('EnableWindow(st->modalOwner, TRUE)') < close.index('DestroyWindow(hwnd)')
assert close.index('DestroyWindow(hwnd)') < close.index('SetActiveWindow(st->modalOwner)')
assert 'state.modalOwner = owner;' in pref
assert 'state.modalOwnerDisabled = true;' in pref
assert 'if (state.modalOwnerDisabled && owner && IsWindow(owner))' in pref
# No changes to the existing Render key execution or final-focus restoration.
assert 'const HWND focusBeforePreferences = renderOwner ? GetFocus() : nullptr;' in ext
assert 'SetForegroundWindow(renderOwner);' in ext
assert 'SetFocus(focusBeforePreferences);' in ext
assert 'bool RenderNavigation::onKey(MSG& msg)' in render
print('TEST75.3.6 lookup activator and modal owner restoration static PASS')
