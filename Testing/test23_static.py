"""TEST23 source contracts: no CMake or native build executed."""
from pathlib import Path
r=Path(__file__).resolve().parents[1]
fx=(r/'src/FxNavigator.cpp').read_text()
order=(r/'src/FxNavigatorOrder.cpp').read_text()
mem=(r/'src/FxNavigatorMemories.cpp').read_text()
proxy=(r/'src/TitleProxy.cpp').read_text()
profile=(r/'src/Profile.cpp').read_text()
model=(r/'src/FxOrder.cpp').read_text()
ext=(r/'src/Extension.cpp').read_text()
assert "k.vk=='G'||k.vk=='M'" in fx
assert "chooseSlotAccess(k.vk=='G'?0:1)" in fx
assert 'groupLabel(groupSlot_)' in fx and 'groupLabel(slot)' in order
assert 'VK_BACK' in fx and 'resetCurrentToDefault()' in fx and 'resetAllToDefault()' in fx
assert 'columns_=10;stepScale_=0' in fx
assert 'snapshotDefaultsIfMissing()' in order and 'saveDefaultValues' in model
assert 'defaultValues() const' in model and 'hasStructuralDefault()' in fx
assert 'resetAllToDefault();' in mem and 'memoryColumns_[6]' in mem
assert 'nativeEditProc' in proxy and 'L"EDIT"' in proxy and 'ES_AUTOHSCROLL' in proxy
assert 'textValue() const' in proxy and 'syncTextControl' in ext
assert 'f7OriginalPosition' in order and 'f7FullView_' in order
assert 'f7FilterPositions_' in order and 'applyF7Filter' in order
assert 'f7Undo' in order and 'saveUndo()' in order
assert 'META\\tREA_EQ_' in profile
assert 'VERSION 0.0.24' in (r/'CMakeLists.txt').read_text()
print('TEST23 static contracts PASS; Windows/native runtime not verified')
