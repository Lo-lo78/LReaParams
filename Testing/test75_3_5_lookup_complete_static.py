#!/usr/bin/env python3
"""TEST75.3.5: regression contract for Render lookup completeness (static)."""
from pathlib import Path
root=Path(__file__).resolve().parents[1]
prefs=(root/'src/Preferences.cpp').read_text(encoding='utf-8')
render=(root/'src/RenderNavigation.cpp').read_text(encoding='utf-8')

# The native tab entries remain discoverable, but Alt+1 and Alt+2 must
# NOT be synthetically inserted into the automatic lookup map.
snapshot=render.split('std::vector<RenderControlInfo> RenderNavigation::preferenceControls()',1)[1].split('const RenderShortcutPreference* RenderNavigation::overrideFor',1)[0]
assert 'const std::wstring id = identityFor(control);' in snapshot
assert 'item.automatic.push_back(tabKey);' not in snapshot
assert 'const HWND tab = findFormatTab();' in render
assert 'entry.tabPage = i;' in render
for identity in ('preferences', 'find', 'next-result', 'previous-result', 'help'):
    assert f'addCommand(L"{identity}"' in snapshot,identity
assert 'entry.identity = std::wstring(L"internal|") + id;' in snapshot
# These are internal read-only commands: do not save them as focus overrides.
assert 'isRenderCommand(st->renderVisible[static_cast<size_t>(index)])' in prefs
assert 'isRenderCommand(st->renderVisible[static_cast<size_t>(selected)])' in prefs
# The lookup reflects both the personal override precedence and forward
# Alt+letter masking of the reverse Alt+Shift+letter cycle.
lookup=prefs.split('bool findShortcut(',1)[1].split('void resetSingleShortcut(',1)[0]
assert 'const bool masked = maskedRenderAutomatic(st->pending, key);' in lookup
assert 'if (user && same(user->assigned, key))' in lookup
assert 'if (!personalized && !masked)' in lookup
assert 'if (found < 0) return false;' in lookup
assert 'Shortcut not found in this section' in prefs
assert 'SetFocus(st->shortcuts)' in lookup
assert 'Main_OnCommand' not in lookup
assert 'forward.shift = false;' in prefs
# Only Alt+S enters the lookup (TEST75.3.7); Alt+D is not a lookup
# accelerator. Inside the interrogation field all keys are searchable data.
assert "alt && !ctrl && !shift && vk == 'S'" in prefs
assert "msg.message == WM_SYSKEYDOWN && msg.wParam == 'S'" in prefs
assert "(vk == 'S' || vk == 'D')" not in prefs
assert "(msg.wParam == 'S' || msg.wParam == 'D')" not in prefs
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
