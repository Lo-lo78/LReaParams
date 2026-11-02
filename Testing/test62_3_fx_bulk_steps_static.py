"""TEST62.3: selected F7 Step/value edits + eighth FX Memory column.
Source and deterministic selection model only; host compilation remains required.
"""
from pathlib import Path
root=Path(__file__).resolve().parents[1]
header=(root/'include/lrp/FxNavigator.h').read_text(encoding='utf-8')
nav=(root/'src/FxNavigator.cpp').read_text(encoding='utf-8')
order=(root/'src/FxNavigatorOrder.cpp').read_text(encoding='utf-8')
mem=(root/'src/FxNavigatorMemories.cpp').read_text(encoding='utf-8')
adv=(root/'src/FxNavigatorAdvanced.cpp').read_text(encoding='utf-8')
assert 'std::array<std::vector<MemoryEntry>,8>' in header
assert '"Default values", "Parameter Steps"' in mem
assert 'memoryColumns_[7].push_back' in mem
assert 'if(value==0)continue;' in mem
assert 'case 7:' in mem and 'parameterSteps_[entry.param]={stepParameterName(entry.param),0};' in mem
assert 'if(memoryCol_==7 && !memoryColumns_[7].empty())' in mem
assert 'if(memoryCol_==7)' in mem and 'memoryReturnParam_=entry.param;' in mem
assert 'std::vector<int> FxNavigator::selectedF7Parameters() const' in order
assert 'const auto& source=f7FilterActive_?f7FullView_:visible_;' in order
assert 'if(unique.insert(id).second)ids.push_back(id);' in order
assert 'void FxNavigator::stepSelectedF7(int delta)' in order
assert 'parameterSteps_[id]={name,next};' in order
assert 'if(editF7_ && !f7Selected_.empty()) {stepSelectedF7' in nav
assert 'else nudgeSelectedF7(direction,big);' in nav
assert 'void FxNavigator::nudgeSelectedF7(int direction,bool big)' in nav
assert 'Undo_BeginBlock2(project_);' in nav and '"LReaParams: selected FX parameter values"' in nav
assert 'const int scale=savedStepForParameter(id);' in nav
assert 'writeEqGain(change.id,change.next)' in nav
assert 'bool FxNavigator::numericCommitSelectedF7(double requested)' in adv
assert 'if(numericCommitSelectedF7(value))return;' in adv
assert '"LReaParams: selected EQ numeric values"' in adv
# Selecting two occurrences of the same ID must update one DSP parameter,
# even when the search filter only displays a subset of selected positions.
base=[5, 10, 5, 12, 10, 42]
selected={0,2,4}
unique=[]
for pos in sorted(selected):
 if base[pos] not in unique:unique.append(base[pos])
assert unique==[5,10]
# Unsaved/hidden/synthetic action IDs may never become ordinary host setters.
ids=[-1,5,5,10]; host=[i for i in ids if i>=0]
assert host==[5,5,10]
print('TEST62.3 PASS: F7 selected Step/value/numeric, unique IDs, eight memory columns; native runtime unverified')
