#!/usr/bin/env python3
"""TEST68.2: Ctrl+L in Used only exits Used, preserving original Ctrl+L."""
from pathlib import Path
root=Path(__file__).resolve().parents[1]
fx=(root/'src/FxNavigator.cpp').read_text(encoding='utf-8')
used=(root/'src/FxNavigatorUsed.cpp').read_text(encoding='utf-8')
start=fx.index('// TEST68.2: Ctrl+L inside Used')
end=fx.index('// Native Win32 EDIT owns ordinary typing',start)
block=fx[start:end]
assert "if (usedActive_ && k.ctrl && !k.shift && !k.alt && !k.altGr && k.vk=='L' &&" in block
assert 'if(!k.repeat)leaveUsedView(true);' in block
assert 'return;' in block
assert 'fxOrder_.storedCustomOrder()' not in block
assert 'leaveGroupToCustomOrder()' not in block
# The new routing precedes both the generic Used context-exit path and
# historical Custom/Plugin Order toggle.
assert end < fx.index('const bool switchContext=k.ctrl && !k.alt')
historical=fx.index("if (k.ctrl && !k.alt && !k.shift && k.vk=='L') {",end)
assert end < historical
historical_block=fx[historical:fx.index('if (k.vk==VK_F7',historical)]
assert 'if (groupSlot_) {leaveGroupToCustomOrder();return;}' in historical_block
assert 'if (!fxOrder_.storedCustomOrder()) {speech_("No Custom Order. Press F7");return;}' in historical_block
assert 'fxOrder_.custom=!fxOrder_.custom;' in historical_block
# Ctrl+Shift+L remains the two-way Used toggle, and explicit exit saves OTHER.
assert "k.ctrl && k.shift && !k.alt && !k.altGr && k.vk=='L'" in fx
assert 'if(!k.repeat)toggleUsedView();' in fx
assert 'void FxNavigator::leaveUsedView(bool speak, bool keepForNextEntry)' in used
assert 'usedState_.resume=keepForNextEntry;' in used
assert 'if(usedActive_) leaveUsedView(true);' in used
print('TEST68.2 PASS: Ctrl+L in Used exits only; regular Ctrl+L and Used history unchanged')
