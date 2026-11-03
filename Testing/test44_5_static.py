"""Historical initial-char backwards and Unicode contract (updated TEST62.9)."""
from pathlib import Path
from version_contract import version_at_least
r=Path(__file__).resolve().parents[1]
assert version_at_least(r,(0,0,44,5))
s=(r/'src/FxNavigator.cpp').read_text(encoding='utf-8')
h=(r/'include/lrp/FxNavigator.h').read_text(encoding='utf-8')
rtr=(r/'src/InputRouter.cpp').read_text(encoding='utf-8')
a=(r/'include/lrp/TypeAhead.h').read_text(encoding='utf-8')
assert 'void cycleByInitial(wchar_t character, DWORD eventTime, bool repeated, bool backwards = false);' in h
assert 'void FxNavigator::cycleByInitial(wchar_t character, DWORD eventTime, bool repeated, bool backwards)' in s
assert s.count('cycleByInitial(k.character, k.time, k.repeat, k.shift);') == 1
assert 'cycleByInitial(typeAheadCharacter(k.vk, k.shift, k.character),' in s
assert 'const int index = backwards ?' in a and 'sameLetterCycle' in a
assert 'if (editF7_ && handleF7(k)) return;' in s
assert 'if (k.altGr && k.character)' in s
assert 'ToUnicodeEx(' in rtr and "vk < '0'" in rtr
assert "character < L'!'" in a, 'Printable punctuation and digits must still navigate'
print('TEST44.5 updated: reverse initial navigation and printable keys preserved by TEST62.9')
