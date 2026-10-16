"""0.0.44.5: Forward initial key; Shift+initial key searches backward.
Source only. Must not compile C++ or execute REAPER.
"""
from pathlib import Path
from version_contract import version_at_least
root=Path(__file__).resolve().parents[1]
assert version_at_least(root,(0,0,44,5))
source=(root/'src/FxNavigator.cpp').read_text()
header=(root/'include/lrp/FxNavigator.h').read_text()
router=(root/'src/InputRouter.cpp').read_text()
assert 'void cycleByInitial(wchar_t character, bool backwards);' in header
assert 'void FxNavigator::cycleByInitial(wchar_t character, bool backwards)' in source
assert '(viewPos_ + total - (offset % total)) % total' in source
assert '(viewPos_ + offset) % total' in source
assert 'if (k.shift) cycleByInitial(k.character, true);' in source
assert source.count('if (k.shift) cycleByInitial(k.character, true);')==2, 'Both normal and AltGr paths must reverse'
assert 'else cycleByInitial(k.character);' in source
assert 'if (editF7_ && handleF7(k)) return;' in source
assert 'if (!valueMode_)' in source and 'if (k.altGr && k.character)' in source
assert 'ToUnicodeEx(' in router and "vk < '0'" in router, 'Retain working MSVC fix and local keyboard layout'

# Model algorithm: begin searching from neighbor, wrap around in requested direction.
def cycle(names, current, char, reverse=False):
    if not names: return None
    step=-1 if reverse else 1
    for offset in range(1,len(names)+1):
        pos=(current+step*offset)%len(names)
        if names[pos].casefold().startswith(char.casefold()): return pos
    return current
names=['Pan','Envelope','Portamento','Pitch','Resonance','1 Osc','#Shape']
assert cycle(names,0,'p')==2 and cycle(names,0,'P',True)==3
assert cycle(names,3,'P',True)==2 and cycle(names,2,'p',True)==0
assert cycle(names,0,'p',True)==3 and cycle(names,3,'p')==0
assert cycle(names,5,'1',True)==5 and cycle(names,6,'#',True)==6
assert cycle(names,4,'!')==4
print('TEST44.5 reverse initial-character navigation PASS (source only).')
