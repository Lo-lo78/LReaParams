"""0.0.44.3 source-only validation of initial-character cycling; no native compilation."""
from pathlib import Path
from version_contract import version_at_least
root = Path(__file__).resolve().parents[1]
assert version_at_least(root, (0,0,44,3))
router=(root/'src/InputRouter.cpp').read_text()
navigator=(root/'src/FxNavigator.cpp').read_text()
header=(root/'include/lrp/Navigator.h').read_text()
lua=(root/'Legacy/Speak FX Params - TrackTake Navigator.lua').read_text(errors='replace')
assert 'function list_cycle_by_initial(letter)' in lua
assert 'function handle_letter_jump(char)' in lua
assert 'wchar_t character{}' in header and 'bool altGr{}' in header
assert 'ToUnicodeEx(' in router and 'GetKeyboardLayout(0)' in router
assert 'key.character = printableKey(vk)' in router and 'VK_RMENU' in router
assert router.count('key.character = printableKey(vk)') == 2
assert '0x04, layout' in router, 'Must not damage keyboard dead-key state'
assert 'void FxNavigator::cycleByInitial(wchar_t character)' in navigator
assert 'const int index = (viewPos_ + offset) % total;' in navigator
assert 'fxOrder_.label(visible_[static_cast<size_t>(index)])' in navigator
assert 'if (index == viewPos_) announce();' in navigator
assert 'if (!k.ctrl && !k.alt && k.character) return true;' in navigator
assert 'if (k.altGr && k.character) return true;' in navigator
assert 'k.shift && !k.alt && !k.ctrl) return k.character' in navigator
assert 'if (!valueMode_) cycleByInitial(k.character);' in navigator
assert 'if (editF7_ && handleF7(k)) return;' in navigator
# Pure reference-level examples for the Lua forward/wrap matching rule.
def cycle(names, current, letter):
    for offset in range(1,len(names)+1):
        i=(current+offset)%len(names)
        if names[i].casefold().startswith(letter.casefold()):return i
    return current
labels=['Pan','Envelope','Portamento','Pitch','1 Oscillator','#Shape']
assert cycle(labels,0,'p')==2 and cycle(labels,2,'p')==3
assert cycle(labels,3,'p')==0 and cycle(labels,0,'1')==4
assert cycle(labels,4,'#')==5 and cycle(labels,4,'!')==4
# Only first character matters; a search for substring remains Ctrl+F.
assert cycle(['Mode Pan','Pan'],0,'p')==1
print('0.0.44.3 initial-character FX navigation contracts PASS. No compilation.')
