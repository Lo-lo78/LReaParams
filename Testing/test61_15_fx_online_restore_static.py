"""TEST61.15: Offline->online restores the FX grid in place (source-only)."""
from pathlib import Path
root = Path(__file__).resolve().parents[1]
contexts = (root/'src/FxNavigatorContexts.cpp').read_text(encoding='utf-8')
nav = (root/'src/FxNavigator.cpp').read_text(encoding='utf-8')
header = (root/'include/lrp/FxNavigator.h').read_text(encoding='utf-8')
extension = (root/'src/Extension.cpp').read_text(encoding='utf-8')
view = (root/'src/FxNavigatorOrder.cpp').read_text(encoding='utf-8')

assert 'void FxNavigator::toggleOffline()' in contexts
assert 'TakeFX_SetOffline(take_, entry.index, !wasOffline)' in contexts
assert 'TrackFX_SetOffline(track_, entry.index, !wasOffline)' in contexts
assert 'rememberPosition();flushPersistentPosition();' in contexts
assert 'if (nowOffline)' in contexts
assert 'fxBrowserMode_=true;valueMode_=false;' in contexts
assert 'if (enterOnlineParameters(newCursor)) return;' in contexts
assert 'bool FxNavigator::enterOnlineParameters(int entryIndex)' in contexts
assert 'if (!selectFx(entryIndex)) return false;' in contexts
assert 'fxBrowserMode_ = false;' in contexts
assert 'speech_("Online. " + fxContextAnnouncement());' in contexts
assert 'onlineReturnGuid_ = entry.guid;' in contexts
assert 'bool FxNavigator::pollOnlineParameters()' in contexts
assert 'guidEquals(&entries_[static_cast<size_t>(selected)].guid, onlineReturnGuid_)' in contexts
assert 'guidEquals(actual, onlineReturnGuid_)' in contexts
assert 'onlineReturnNextCheck_ = now + 250;' in contexts
assert 'return params > 0 && enterOnlineParameters(selected);' in contexts
assert 'onlineReturnPending_ = false; // F10 is an explicit request to browse.' in contexts
assert 'if (next != old) {onlineReturnPending_ = false;' in contexts
assert 'onlineReturnPending_ = false; browserCursor_ = j;' in contexts
assert 'bool pollOnlineParameters();' in header
assert 'onlineReturnPending_ = false; onlineReturnNextCheck_ = 0;' in nav
assert 'navigator_.pollOnlineParameters() && titleProxyActive_' in extension
assert 'titleProxy_.updateTitle(navigator_.windowTitle());' in extension
assert 'restoreParameterPosition();' in nav and 'restorePersistedParameter();' in nav
assert 'groupSlot_=pos.groupSlot;' in view
print('TEST61.15 PASS: online rebind, GUID-safe delayed recovery, group and focus (source only)')
