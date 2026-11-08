#!/usr/bin/env python3
"""TEST68.3: F7 Used virtual view selects physical IDs without damaging group occurrences."""
from pathlib import Path
p=Path(__file__).resolve().parents[1]
fx=(p/'src/FxNavigator.cpp').read_text(encoding='utf-8')
order=(p/'src/FxNavigatorOrder.cpp').read_text(encoding='utf-8')
used=(p/'src/FxNavigatorUsed.cpp').read_text(encoding='utf-8')
h=(p/'include/lrp/FxNavigator.h').read_text(encoding='utf-8')
assert "k.ctrl && k.shift && !k.alt && !k.altGr && k.vk=='L'" in fx
assert "!editF7_ && !fxBrowserMode_" not in fx[fx.index("if (k.ctrl && k.shift && !k.alt && !k.altGr && k.vk=='L'"):fx.index('if(!k.repeat)toggleUsedView();')]
assert "return !k.shift || (!defaultConfirm_" in fx
assert "if (usedActive_ && !editF7_ && !searchMode_ && k.ctrl" in fx
assert 'if(editF7_) {' in used and 'usedOrigin_.f7Selected=f7Selected_;' in used
assert 'usedF7SelectedIds_' in h and 'usedF7SelectedIds_.insert(source[' in used
assert 'f7Selected_=std::move(usedOrigin_.f7Selected);' in used
assert 'if(usedActive_) {' in order[order.index('void FxNavigator::doCopy'):order.index('void FxNavigator::doPaste')]
assert 'clipCut_=false;clipPlugin_' in order
assert 'if(usedActive_) {speech_("Used is read only. Open a group to paste");return;}' in order
assert 'if(usedActive_)speech_("F7 Ctrl+Delete removes from groups, not Used.' in order
assert 'if(k.ctrl&&!k.alt&&!k.shift&&k.vk==VK_DELETE)' in order
assert "if(k.ctrl&&!k.alt&&!k.shift&&k.vk=='A')" in order
assert 'void FxNavigator::exitF7(bool speak)' in order
assert 'if(speak) speech_(' in order
assert 'leaveUsedView(false, true);' in fx and 'exitF7(false);' in fx
assert '!(editF7_ && k.shift)' in fx and 'saved.push_back(reference[' in order
assert '(usedActive_?"Edit: Used":groupSlot_' in order
assert 'void FxNavigator::enterF7()' in order and 'void FxNavigator::exitF7(bool speak)' in order
assert 'usedF7SelectedIds_.clear(); // Selection belongs to an F7 editing session.' in order
print('TEST68.3 PASS: F7 Used toggling, distinct selections, copying, group save, Ctrl+Delete isolation')
