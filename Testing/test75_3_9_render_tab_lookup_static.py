#!/usr/bin/env python3
"""The 75.3.9 Alt+digit lookup special-case was superseded by 75.3.10.
Keep the historical test filename, but enforce the current user requirement.
"""
from pathlib import Path
root=Path(__file__).resolve().parents[1]
src=(root/'src/Preferences.cpp').read_text(encoding='utf-8')
render=(root/'src/RenderNavigation.cpp').read_text(encoding='utf-8')
lookup=src.split('bool findShortcut(DialogState* st, const Key& key)',1)[1].split('void resetSingleShortcut(',1)[0]
proc=src.split('LRESULT CALLBACK pageProc(',1)[1].split('LRESULT CALLBACK wndProc(',1)[0]
assert 'lookupResolvedTabVk' not in src
assert 'renderTabGesture' not in src
assert 'personalTabOverride' not in lookup
assert 'tabId' not in lookup
assert 'item.automatic.push_back(tabKey);' not in render
assert 'if (user && same(user->assigned, key))' in lookup
assert 'for (const auto& automatic : item.automatic)' in lookup
assert 'if (found < 0) return false;' in lookup
assert 'const bool queriedAlt = alt || (msg == WM_SYSKEYDOWN &&' in proc
assert 'st->lookupQueryVk = 0;' in proc and 'st->lookupMissPending = false;' in proc
# Render's own tab actions remain active and configurable overrides take precedence.
assert "if (!shift && (vk == '1' || vk == '2'))" in render
assert "return focusPageTab(vk == '1' ? 0 : 1);" in render
assert 'if (const auto* binding = overrideFor(physical)) return focusOverride(*binding);' in render
print('TEST75.3.10 Render tab lookup: no synthetic Alt digits; static PASS')
