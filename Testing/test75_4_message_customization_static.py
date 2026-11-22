"""TEST75.4: exhaustive source-message catalog + safe preference wiring."""
from pathlib import Path
import re
ROOT = Path(__file__).resolve().parents[1]
src = (ROOT/'src/Preferences.cpp').read_text()
ext = (ROOT/'src/Extension.cpp').read_text()
cat = (ROOT/'src/MessageCatalog.cpp').read_text()
head = (ROOT/'include/lrp/Preferences.h').read_text()
cmake = (ROOT/'CMakeLists.txt').read_text()
assert 'speechMessageCatalog()' in src and 'messageDefinition(' in src
assert 'baseMessageTopics(' in src and 'kFxTitleCount' in src and 'kTrackTitleCount' in src
for marker in ['Message (Space to disable)', 'Message (Space to enable)',
               'Custom message', 'editableMessageOverride', 'removeEmptyMessageOverrides',
               'messageOverride(', 'editableMessageOverride(st->pending', 'L"SpeechMessages"',
               'rule.enabled', 'rule.custom.c_str()']:
    assert marker in src, marker
assert 'std::vector<SpeechMessageOverride> speechMessages;' in head
assert 'setSpeechMessageOverrides(preferences_.speechMessages);' in ext
assert 'src/MessageCatalog.cpp' in cmake
assert 'if (overrides.empty()) { output(message); return; }' in cat
assert 'const std::string token = "{original}"' in cat
ids = re.findall(r'\{SpeechScope::(fx|track), "((?:FX|TRACK)-[a-f0-9]{16})",',cat)
assert len(ids) > 500 and len(ids)==len(set(ids))
assert sum(scope=='fx' for scope,_ in ids) > 250
assert sum(scope=='track' for scope,_ in ids) > 200
assert len(list((ROOT/'src').glob('FxNavigator*.cpp'))) > 5
for scope,glob in [('fx','FxNavigator*.cpp'),('track','TrackNavigator*.cpp')]:
    for f in (ROOT/'src').glob(glob):
        text=f.read_text()
        assert '#define speech_(...) ::lrp::emitConfigurableSpeech(::lrp::SpeechScope::'+scope in text, str(f)
        assert '"lrp/MessageCatalog.h"' in text
# Preserve the existing title order and exact Win32 dialog control count.
assert 'constexpr int kFxTitleCount = 4;' in src
assert 'constexpr int kTrackTitleCount = 12;' in src
assert src.count('CreateWindowExW(') == 9 and src.count('CreateWindowW(') == 4
print('TEST75.4 message catalog and preferences contracts PASS,',len(ids),'messages')
