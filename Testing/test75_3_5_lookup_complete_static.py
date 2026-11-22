#!/usr/bin/env python3
"""TEST75.3.5: regression contract for Render lookup completeness (static)."""
from pathlib import Path
root=Path(__file__).resolve().parents[1]
prefs=(root/'src/Preferences.cpp').read_text(encoding='utf-8')
render=(root/'src/RenderNavigation.cpp').read_text(encoding='utf-8')

# Alt+1 and Alt+2 must resolve to their actual tab destination, not an
# unrelated automatic Alt+letter mapping or a guessed HWND.
snapshot=render.split('std::vector<RenderControlInfo> RenderNavigation::preferenceControls()',1)[1].split('const RenderShortcutPreference* RenderNavigation::overrideFor',1)[0]
assert "control.tabPage == 0 || control.tabPage == 1" in snapshot
assert "control.tabPage == 0 ? '1' : '2'" in snapshot
assert 'tabKey.alt = true;' in snapshot
assert 'item.automatic.push_back(tabKey);' in snapshot
for identity in ('preferences', 'find', 'next-result', 'previous-result', 'help'):
    assert f'addCommand(L"{identity}"' in snapshot,identity
assert 'entry.identity = std::wstring(L"internal|") + id;' in snapshot
# These are internal read-only commands: do not save them as focus overrides.
assert 'isRenderCommand(st->renderVisible[static_cast<size_t>(index)])' in prefs
assert 'isRenderCommand(st->renderVisible[static_cast<size_t>(selected)])' in prefs
# The lookup reflects both the personal override precedence and forward
# Alt+letter masking of the reverse Alt+Shift+letter cycle.
lookup=prefs.split('void findShortcut(',1)[1].split('void resetSingleShortcut(',1)[0]
assert 'const bool masked = maskedRenderAutomatic(st->pending, key);' in lookup
assert 'if (user && same(user->assigned, key))' in lookup
assert 'if (!personalized && !masked)' in lookup
assert 'Shortcut not found in this section' in lookup
assert 'SetFocus(st->shortcuts)' in lookup
assert 'Main_OnCommand' not in lookup
assert 'forward.shift = false;' in prefs
# Both Alt+D and the existing Alt+S open the lookup, but neither executes
# mnemonic actions while the shortcut interrogation field has focus.
assert prefs.count("(vk == 'S' || vk == 'D')") >= 1
assert "(msg.wParam == 'S' || msg.wParam == 'D')" in prefs
assert 'if (hwnd == st->lookup)' in prefs
assert 'if (isDialogMessage && isShortcutInput && !altTab)' in prefs
assert 'MB_YESNO | MB_ICONQUESTION | MB_DEFBUTTON2' in prefs
# Existing FX and Track customization indices remain unchanged; only
# ephemeral list rows represent Ctrl+P and Shift+F1.
assert 'constexpr size_t kOpenPreferencesRow = std::numeric_limits<size_t>::max();' in prefs
assert 'constexpr size_t kShortcutHelpRow = kOpenPreferencesRow - 1;' in prefs
assert 'st->visible.push_back(kOpenPreferencesRow);' in prefs
assert 'st->visible.push_back(kShortcutHelpRow);' in prefs
assert 'if (isFixedNavigatorRow(st->visible[static_cast<size_t>(index)]))' in prefs
assert 'if (isFixedNavigatorRow(index))' in prefs
assert 'const Key& effective = row == kOpenPreferencesRow' in prefs
print('TEST75.3.5 Render lookup completeness static PASS')
