"""TEST62.7 source regression for the group Ctrl+L escape (runtime via REAPER)."""
from pathlib import Path
r=Path(__file__).resolve().parents[1]
nav=(r/'src/FxNavigator.cpp').read_text(encoding='utf-8')
order=(r/'src/FxNavigatorOrder.cpp').read_text(encoding='utf-8')
head=(r/'include/lrp/FxNavigator.h').read_text(encoding='utf-8')
assert 'void leaveGroupToCustomOrder();' in head
assert 'void FxNavigator::leaveGroupToCustomOrder()' in order
block=order.split('void FxNavigator::leaveGroupToCustomOrder()',1)[1].split('void FxNavigator::openGroup(',1)[0]
for expected in ('if(!groupSlot_)return;', 'rememberPosition();', 'clearF7Filter();',
                 'groupSlot_=0;', 'groupReturnActive_=false;', 'editF7_=false;',
                 'f7ReturnGroup_=0;', 'fxOrder_.custom=true;',
                 'restoreViewCursor(fallbackParam,fallbackPosition);', 'saveStructure();',
                 'flushPersistentPosition();', 'speech_("Custom order. "+currentParameterSpeech());'):
    assert expected in block, expected
assert 'if(!fxOrder_.storedCustomOrder() && !fxOrder_.createCustomOrder())' in block
assert 'groupReturnParam_' in block and 'groupReturnPosition_' in block
assert 'f7Selected_=originalSelection;' in block
ctrl=nav.split("if (k.ctrl && !k.alt && !k.shift && k.vk=='L') {",1)[1].split('if (k.vk==VK_F7',1)[0]
assert 'if (k.repeat) return;' in ctrl
assert 'if (groupSlot_) {leaveGroupToCustomOrder();return;}' in ctrl
assert ctrl.index('if (groupSlot_)') < ctrl.index('if (editF7_)')
assert 'fxOrder_.custom=!fxOrder_.custom;' in ctrl
assert 'Group active. Ctrl+L unavailable' not in nav
# Ctrl+Fn on an active group must remain the original, return-to-origin path.
assert 'if(groupSlot_==slot)' in order
orig=order.split('void FxNavigator::openGroup(int slot)',1)[1]
assert 'fxOrder_.custom=wasCustom;' in orig and 'editF7_=wasEditing;' in orig
assert 'groupReturnSelection_=f7Selected_;' in orig
# No changes to Track Params.
assert 'memorySelected_' in (r/'src/TrackNavigatorMemories.cpp').read_text()
print('TEST62.7 PASS: group Ctrl+L -> Custom, F7 exit and subsequent ordinary toggle')
