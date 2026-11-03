"""Historical input routing contracts updated to TEST62.9 type-ahead."""
from pathlib import Path
from version_contract import version_at_least
r=Path(__file__).resolve().parents[1]
assert version_at_least(r,(0,0,44,3))
router=(r/'src/InputRouter.cpp').read_text(encoding='utf-8')
fx=(r/'src/FxNavigator.cpp').read_text(encoding='utf-8')
header=(r/'include/lrp/Navigator.h').read_text(encoding='utf-8')
core=(r/'include/lrp/TypeAhead.h').read_text(encoding='utf-8')
lua=(r/'Legacy/Speak FX Params - TrackTake Navigator.lua').read_text(errors='replace')
assert 'function list_cycle_by_initial(letter)' in lua
assert 'function handle_letter_jump(char)' in lua
assert 'wchar_t character{}' in header and 'bool altGr{}' in header
assert 'DWORD time{}' in header
assert 'ToUnicodeEx(' in router and 'GetKeyboardLayout(0)' in router
assert router.count('key.character = printableKey(vk)') == 2
assert '0x04, layout' in router
assert 'typeAhead_.find(character, eventTime, repeated' in fx
assert 'fxOrder_.label(visible_[static_cast<size_t>(index)])' in fx
assert 'if (matched == viewPos_) announce();' in fx
assert 'if (editF7_ && handleF7(k)) return;' in fx
assert 'sameLetterCycle' in core and 'rank(label(index), prefix)' in core
print('TEST44.3 updated: printable layout and initial cycling now enhanced by type-ahead')
