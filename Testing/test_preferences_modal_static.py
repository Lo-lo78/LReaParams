"""Source-only guard for TEST Preferences native accessibility regressions."""
from pathlib import Path
root = Path(__file__).resolve().parents[1]
pref = (root / "src/Preferences.cpp").read_text(encoding="utf-8")
router = (root / "src/InputRouter.cpp").read_text(encoding="utf-8")
extension = (root / "src/Extension.cpp").read_text(encoding="utf-8")
assert 'const wchar_t* nodes[] = {L"Messages", L"Shortcuts", L"Advanced"}' in pref
assert 'L"Active - "' in pref  # only the leaf options use Active
assert 'TVM_SETITEMW' not in pref  # no extra tree speech updates
assert 'st->ok = CreateWindowW' in pref and 'st->cancel = CreateWindowW' in pref
assert 'pageTab(&state, focused,' in pref
assert 'focused == state.ok' in pref and 'focused == state.cancel' in pref
assert 'if (msg == WM_CHAR && wp == VK_TAB) return 0;' in pref
assert 'if (!IsDialogMessageW(hwnd, &msg))' in pref
assert 'st->accepted = id == IDOK;' in pref
assert 'state.accepted ? std::make_optional(state.pending) : std::nullopt' in pref
assert 'savePreferences(preferencesPath_, *edited)' in extension
assert 'if (!edited) { speak("Preferences cancelled. Changes not saved")' in extension
assert "key.vk == 'P'" in extension and 'actions_[preferencesAction].command' in extension
assert 'bool opensPreferences(const Key& k)' in router
assert 'if (!preferencesKey && !navigator_->accepts(key))' in router
assert "(vk == 'P' && ctrl && !alt && !shift)" in pref
print('TEST Preferences: tree, no Tab beep path, OK persistence and Ctrl+P routes PASS (static)')
