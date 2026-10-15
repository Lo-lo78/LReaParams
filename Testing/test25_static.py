"""TEST25 static contracts and example search semantics; no native compilation."""
from pathlib import Path
import re
root = Path(__file__).resolve().parents[1]
nav = (root / 'src/FxNavigator.cpp').read_text(encoding='utf-8')
order = (root / 'src/FxNavigatorOrder.cpp').read_text(encoding='utf-8')
mem = (root / 'src/FxNavigatorMemories.cpp').read_text(encoding='utf-8')
header = (root / 'include/lrp/FxNavigator.h').read_text(encoding='utf-8')
assert 'VERSION 0.0.31' in (root / 'CMakeLists.txt').read_text()
assert 'if(groupSlot_==slot)' in order
assert 'groupReturnCustom_=fxOrder_.custom;' in order
assert 'fxOrder_.custom=wasCustom;' in order
assert 'bool FxNavigator::matchesSearch' in nav
assert 'matchesSearch(fxOrder_.label(id),search_)' in nav
assert 'matchesSearch(label,query)' in order
assert 'std::vector<std::string> words(' in nav
assert 'wanted.size()>1' in nav
assert 'query.front()' in nav and 'query.back()' in nav
assert 'bool resetAllToDefault(bool announceResult = true)' in header
assert 'bool FxNavigator::resetAllToDefault(bool announceResult)' in nav
assert 'if(!resetAllToDefault(false))return;' in mem
assert 'memoryReturnF7_=false;' in mem
assert 'memoryReturnGroup_=0;' in mem
assert 'fxOrder_.custom=false;' in mem
assert 'speech_("Default restored. Plugin Order. "+currentParameterSpeech())' in mem
assert 'if(memoryCol_==2 && !toEdit)' in mem
assert 'memoryReturnF7_=false;' in mem and 'memoryExit(!toEdit);' in mem
# These cases are behavioral examples for the specified word-matching rule.
# They do not run or validate the C++ executable.
def words(value):
    return re.findall(r'[\w]+', value.lower(), flags=re.UNICODE)
def expected_search(label, query):
    if len(query) < 2 or not (query[0] == query[-1] == '"'):
        return query.lower() in label.lower()
    want, have = words(query[1:-1]), words(label)
    if not want or len(want) > len(have):
        return False
    return any(all((h.startswith(w) if i == len(want)-1 and len(want)>1 else h == w)
                  for i, (w, h) in enumerate(zip(want, have[start:])))
               for start in range(len(have)-len(want)+1))
assert expected_search('Slot 1 Filter', '"slot 1 fil"')
assert not expected_search('Slot 10 Filter', '"slot 1 fil"')
assert not expected_search('Slot 19 LFO1', '"slot 1 lfo1"')
assert expected_search('Kick', '"kick"')
assert not expected_search('Kickoff', '"kick"')
assert expected_search('Kickoff', 'kick')
assert expected_search('Slot 1 - Filter', '"slot 1 fil"')
print('TEST25 static/source and search-example checks PASS; REAPER/NVDA unverified')
