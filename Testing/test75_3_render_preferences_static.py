#!/usr/bin/env python3
"""Source invariants: TEST75.3 Render custom bindings and transactional preferences.
These are static checks, NOT a Windows/MSVC runtime validation.
"""
from pathlib import Path
r=Path(__file__).resolve().parents[1]
read=lambda path:(r/path).read_text(encoding='utf-8')
pref=read('src/Preferences.cpp')
render=read('src/RenderNavigation.cpp')
header=read('include/lrp/Preferences.h')
ext=read('src/Extension.cpp')
script=read('Tools/push_lreaparams.cmd')
assert 'enum class ShortcutScope { fx, track, render }' in header
assert 'std::vector<RenderShortcutPreference> renderShortcuts' in header
assert 'std::vector<RenderControlInfo> renderDiscovered, renderVisible' in pref
assert 'st->renderNode = insertNode(st->tree, st->nodes[1], L"Render")' in pref
assert 'state.renderDiscovered = renderControls' in pref
assert 'const auto renderControls = renderNavigation_.preferenceControls();' in ext
assert 'const HWND renderOwner = renderNavigation_.activeRenderDialog();' in ext
assert 'if (renderNavigation_.takePreferencesRequest())' in ext
assert 'pendingPreferences_ = true' in render
assert 'if (ctrl && !alt && !shift && vk == \'P\')' in render
assert 'renderNavigation_.setPreferences(&preferences_)' in ext
# Scan does not change the codec/tab or activate native controls.
scan=render.split('std::vector<RenderControlInfo> RenderNavigation::preferenceControls()',1)[1].split('const RenderShortcutPreference* RenderNavigation::overrideFor',1)[0]
assert 'refreshControls(root)' in scan and 'IsWindowVisible(h)' in scan
for action in ['SetFocus(', 'TCM_SETCURSEL', 'BM_CLICK', 'Main_OnCommand(', 'focusPageTab(']:
    assert action not in scan, action
# Identity includes codec, page, native ID, class/name and parent.
identity=render.split('std::wstring RenderNavigation::identityFor',1)[1].split('std::vector<RenderControlInfo>',1)[0]
assert 'currentCodecName()' in identity and 'selectedFormatPage()' in identity
assert 'GetDlgCtrlID(parent)' in identity and 'c.name' in identity
# Read-only inspector uses the same actual override mappings.
assert 'if (const auto* user = overrideFor(physical))' in render
assert 'if (autoLetterReserved(letter))' in render
assert 'if (const auto* binding = overrideFor(physical)) return focusOverride(*binding);' in render
assert 'autoLetterReserved(static_cast<wchar_t>(vk - \'A\' + L\'a\'))' in render
assert 'return true; // always swallow this personalized shortcut' in render
assert 'No active Render control assigned to this letter' in render
# Reset only changes pending preferences, never the live persisted config.
reset=pref.split('void resetCurrentSection(',1)[1].split('// Selection changes',1)[0]
assert 'MB_YESNO | MB_ICONQUESTION | MB_DEFBUTTON2' in reset
assert 'if (answer != IDYES) return;' in reset
assert 'st->pending.renderShortcuts.clear();' in reset
assert 'entry.assigned = entry.original;' in reset
assert 'savePreferences(' not in reset
assert 'state.accepted ? std::make_optional(state.pending) : std::nullopt' in pref
assert 'if (!edited)' in ext and 'savePreferences(preferencesPath_, *edited)' in ext
# Undo single Render custom mapping; unmodified entries remain automatic.
assert 'changes.erase(std::remove_if(changes.begin(), changes.end()' in pref
assert 'if (hwnd == st->shortcuts && vk == VK_DELETE' in pref
assert 'existing automatic Render mapper remains in full control' in pref
# Conflicting personal/personal bindings require explicit confirmation, No default.
assert 'MB_YESNO | MB_ICONQUESTION | MB_DEFBUTTON2' in pref
assert 'other.identity == item.identity || !same(other.assigned, candidate)' in pref
assert 'if (!updated) changes.push_back(' in pref
# Search must never execute an extension command.
lookup=pref.split('bool findShortcut(',1)[1].split('void resetSingleShortcut(',1)[0]
assert 'SetFocus(st->shortcuts)' in lookup and 'if (found < 0) return false;' in lookup
assert 'Shortcut not found in this section' in pref
for action in ['handle(', 'PostMessageW(', 'Main_OnCommand(', 'SetDlgItemTextW(', 'click(']:
    assert action not in lookup, action
# Only personal Render assignments are serialized, not the default auto map.
assert 'WritePrivateProfileStringW(L"RenderShortcuts", nullptr, nullptr' in pref
assert 'GetPrivateProfileIntW(L"RenderShortcuts", L"Count"' in pref
assert 'WritePrivateProfileStringW(L"RenderShortcuts", L"Count"' in pref
assert 'git restore --source=origin/main --staged --worktree -- index.xml' in script
print('TEST75.3 Render Preferences/shortcut lookup/reset/persistence static PASS')
