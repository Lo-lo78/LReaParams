"""Source-only guard for native Preferences accessibility and safe navigator return."""
from pathlib import Path
root = Path(__file__).resolve().parents[1]
pref = (root / "src/Preferences.cpp").read_text(encoding="utf-8")
router = (root / "src/InputRouter.cpp").read_text(encoding="utf-8")
extension = (root / "src/Extension.cpp").read_text(encoding="utf-8")
assert 'st->nodes[0] = insertNode(st->tree, TVI_ROOT, L"Messages")' in pref
assert 'st->nodes[1] = insertNode(st->tree, TVI_ROOT, L"Shortcuts")' in pref
assert 'st->fxNode = insertNode(st->tree, st->nodes[1], L"FX Params")' in pref
assert 'st->trackNode = insertNode(st->tree, st->nodes[1], L"Track Params")' in pref
assert 'st->nodes[2] = insertNode(st->tree, TVI_ROOT, L"Advanced")' in pref
assert 'st->fxMsgNode = insertNode(st->tree, st->nodes[0], L"FX Params")' in pref
assert 'st->trackMsgNode = insertNode(st->tree, st->nodes[0], L"Track Params")' in pref
assert 'L"Active - "' in pref  # only the Advanced leaf uses Active
assert 'TVM_SETITEMW' not in pref  # avoid extra tree speech updates
assert 'st->ok = CreateWindowW' in pref and 'st->cancel = CreateWindowW' in pref
assert 'pageTab(&state, focused,' in pref
assert 'focused == state.ok' in pref and 'focused == state.cancel' in pref
assert 'if (msg == WM_CHAR && wp == VK_TAB) return 0;' in pref
assert 'isDialogMessage && !taskSwitch && IsDialogMessageW(hwnd, &msg)' in pref
assert 'st->accepted = id == IDOK;' in pref
assert 'state.accepted ? std::make_optional(state.pending) : std::nullopt' in pref
assert 'savePreferences(preferencesPath_, *edited)' in extension
assert 'Preferences cancelled. Changes not saved' in extension
assert "key.vk == 'P'" in extension and 'actions_[preferencesAction].command' in extension
assert 'bool opensPreferences(const Key& k)' in router
assert 'if (!preferencesKey && !navigator_->accepts(key))' in router
assert "(vk == 'P' && ctrl && !alt && !shift)" in pref
assert 'launchNavigator(suspended, true);' in extension
assert 'if (preferencesDialogOpen_) return;' in extension
print('TEST Preferences: accessible tree, Tab, OK persistence and Ctrl+P return PASS (static)')
