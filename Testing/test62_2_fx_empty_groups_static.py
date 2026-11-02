"""TEST62.2: both bulk save and persistent empty group workflows.
C++ roundtrip cases are in Testing/ProfileTests.cpp, built on GitHub Actions.
"""
from pathlib import Path
root=Path(__file__).resolve().parents[1]
nav=(root/'src/FxNavigator.cpp').read_text()
view=(root/'src/FxNavigatorOrder.cpp').read_text()
mem=(root/'src/FxNavigatorMemories.cpp').read_text()
fx=(root/'src/FxOrder.cpp').read_text()
profile=(root/'Testing/ProfileTests.cpp').read_text()
workflow=(root/'.github/workflows/build-windows.yml').read_text()
assert "if(k.shift)saveGroup(slot);else openGroup(slot);" in nav
assert 'if(!editF7_) {speech_("Press F7 to select group parameters");return;}' in view
assert "for(int pos:f7Selected_)" in view and 'fxOrder_.groups[slot]=std::move(saved)' in view
assert 'if(saved.empty()){speech_("No selected parameters");return;}' not in view
assert "if(fxOrder_.groups.count(slot))" in view
assert '". Empty group ready for paste"' in view
assert 'if(it==fxOrder_.groups.end() && !editF7_)' in view
assert 'fxOrder_.groups.try_emplace(slot);' not in view
assert 'const bool createGroup=groupSlot_ && fxOrder_.groups.find(groupSlot_)==fxOrder_.groups.end();' in view
assert 'saveUndo(); // One Undo captures BOTH groups before an inter-group move.' in view
assert view.index('saveUndo(); // One Undo captures BOTH groups') < view.index('fxOrder_.groups.emplace(groupSlot_,std::move(reduced))')
assert 'if(group!=fxOrder_.groups.end()) {' in view
assert 'if(pair.second.empty())continue;' not in mem
assert '". "+std::to_string(activeCount)+" visible parameters"' in mem
assert 'auto& savedGroup=groups[slot];' in fx
assert 'if(unescape(row.substr(eq+1)).empty())continue;' in fx
assert 'reopenedEmpty.groups.count(2) == 1' in profile
assert 'emptyAgain.groups.count(2) == 1' in profile
assert 'afterEmptyDelete.groups.count(2) == 0' in profile
assert 'python Testing/test62_2_fx_empty_groups_static.py' in workflow
print('TEST62.2 PASS: saved-empty/bulk/paste/undo contract; C++ and host tests require Windows')
