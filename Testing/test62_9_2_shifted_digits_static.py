"""TEST62.9.2: Shift+digits use physical numeric VK only in type-ahead search."""
from pathlib import Path
r=Path(__file__).resolve().parents[1]
core=(r/'include/lrp/TypeAhead.h').read_text(encoding='utf-8')
router=(r/'src/InputRouter.cpp').read_text(encoding='utf-8')
fx=(r/'src/FxNavigator.cpp').read_text(encoding='utf-8')
fm=(r/'src/FxNavigatorMemories.cpp').read_text(encoding='utf-8')
track=(r/'src/TrackNavigator.cpp').read_text(encoding='utf-8')
tm=(r/'src/TrackNavigatorMemories.cpp').read_text(encoding='utf-8')
assert 'typeAheadCharacter(std::uint32_t virtualKey, bool shift' in core
assert "virtualKey <= static_cast<std::uint32_t>('9')" in core
assert 'return static_cast<wchar_t>(virtualKey);' in core
assert 'key.character = printableKey(vk)' in router, 'Keep native layout interpretation outside type-ahead'
for label,source in [('fx',fx),('fx memories',fm),('track',track),('track memories',tm)]:
    assert 'typeAheadCharacter(k.vk, k.shift, k.character)' in source, label
assert 'cycleByInitial(typeAheadCharacter' in fx
assert 'jumpByInitial(typeAheadCharacter' in track
assert 'typeAhead_.find(typeAheadCharacter' in fm
assert 'typeAhead_.find(typeAheadCharacter' in tm
assert 'typeAhead_.find(letter, eventTime, repeated, row_, count, backwards,' in track
assert 'typeAhead_.find(letter, eventTime, repeated, parameter_, detailHeight, backwards,' in track
print('TEST62.9.2 shifted number-row search PASS')
