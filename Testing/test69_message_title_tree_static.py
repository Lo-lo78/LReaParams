"""TEST 69: mutable title templates and accessible Messages/Title page (source-only)."""
from pathlib import Path
root = Path(__file__).resolve().parents[1]
pref = (root/'src/Preferences.cpp').read_text(encoding='utf-8')
head = (root/'include/lrp/Preferences.h').read_text(encoding='utf-8')
fx = (root/'src/FxNavigator.cpp').read_text(encoding='utf-8')
track = (root/'src/TrackNavigator.cpp').read_text(encoding='utf-8')
ext = (root/'src/Extension.cpp').read_text(encoding='utf-8')
assert 'struct TitleMessage' in head and 'fxTitle;' in head and 'trackTitle;' in head
assert 'st->fxMsgNode = insertNode(st->tree, st->nodes[0], L"FX Params")' in pref
assert 'st->trackMsgNode = insertNode(st->tree, st->nodes[0], L"Track Params")' in pref
assert 'st->fxNode = insertNode(st->tree, st->nodes[1], L"FX Params")' in pref
assert 'st->trackNode = insertNode(st->tree, st->nodes[1], L"Track Params")' in pref
assert 'L"Title: FX Params"' in pref and 'L"Title: Sends (F2)"' in pref and 'st->messageTopics' in pref
assert 'reorderMessagePart(st, vk == VK_UP ? -1 : 1)' in pref
assert 'toggleMessagePart(st)' in pref and 'startCustomEditor(st)' in pref
assert 'if (part == customPart(st->messageScope, topic)) return;' in pref
assert 'L"Disabled - "' in pref
assert 'closeCustomEditor(st, true)' in pref and 'closeCustomEditor(st, false)' in pref
assert 'if (st->editingCustom) closeCustomEditor(st, id == IDOK)' in pref
assert 'GetPrivateProfileStringW' in pref and 'loadTitle(path, L"FxTitle", p.fxTitle, 5)' in pref
assert 'loadTitle(path, L"TrackTitle", p.trackTitle, 3)' in pref
assert 'saveTitle(path, L"FxTitle", p.fxTitle, 5)' in pref
assert 'saveTitle(path, L"TrackTitle", p.trackTitle, 3)' in pref
assert 'if (legacy.empty() && !p.pluginFirst)' in pref
assert 'std::string formatFxTitle(' in pref and 'std::wstring formatTrackTitle(' in pref
assert 'formatFxTitle(fxDisplayName(), contextName(), status)' in fx
assert 'formatTrackTitle(wideUtf8(trackName()))' in track
assert ext.count('setTitleMessages(preferences_)') == 2
assert 'state.accepted ? std::make_optional(state.pending) : std::nullopt' in pref
assert 'Tools\\push_lreaparams.cmd' in (root/'Docs/PREFERENCES_TEST.md').read_text(encoding='utf-8')
print('TEST69 Message titles: nested tree, ordered parts, custom edit, persisted FX/Track templates PASS (static)')
