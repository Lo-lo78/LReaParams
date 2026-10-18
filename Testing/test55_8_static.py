"""TEST55.8 FX Default restoration and memory return. Source contracts only."""
from pathlib import Path
r=Path(__file__).resolve().parents[1]
order=(r/'src/FxOrder.cpp').read_text()
head=(r/'include/lrp/FxOrder.h').read_text()
fx=(r/'src/FxNavigator.cpp').read_text()
mem=(r/'src/FxNavigatorMemories.cpp').read_text()
tests=(r/'Testing/ProfileTests.cpp').read_text()
assert 'std::map<int,double> FxOrder::defaultValuesByIndex() const' in order
assert 'std::map<int,double> defaultValuesByIndex() const;' in head
assert 'values.size()!=static_cast<size_t>(count_)' in order
assert 'values.count(id)' in order
assert 'savedNames==currentNames' in order
assert 'oneLine(paramName_(id))!=parts[1]' in order
assert 'values=fxOrder_.defaultValuesByIndex();' in fx
assert 'Default parameter count changed. No changes' in fx
assert 'Default parameter identities changed. No changes' in fx
assert 'if(!resetAllToDefault(false))return;' in mem
assert 'memoryStandalone_=false;' in mem
assert 'memoryExit(false);' in mem
assert 'Default restored. ' in mem
assert 'defaultConfirm_=true;' in mem and 'memoryDelete()' in mem
assert 'Changed synth labels lost a complete Default snapshot' in tests
assert 'Changed FX parameter count accepted old Default' in tests
assert 'Reordered parameter labels accepted old Default' in tests
assert 'Duplicate Default native parameter ID accepted' in tests
print('TEST55.8 FX Default source contracts PASS')
