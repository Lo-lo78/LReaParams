"""TEST28 source-level invariants and a non-native selection reference model.

No compiler, REAPER, or GUI is invoked. The Python model specifies expected
continuous range semantics; actual native behavior must be tested in REAPER.
"""
from pathlib import Path
root = Path(__file__).resolve().parents[1]
fx = (root / 'src/FxNavigatorOrder.cpp').read_text(encoding='utf-8')
h = (root / 'include/lrp/FxNavigator.h').read_text(encoding='utf-8')
assert 'VERSION 0.0.' in (root / 'CMakeLists.txt').read_text()
assert 'bool sweep = false' in h
assert 'bool f7SnakeUnselect_ = false;' in h
assert 'if(target==viewPos_)return;' in fx  # border produces NO message
assert 'const int distance=sweep?std::abs(target-start):1;' in fx
assert 'const int next=sweep?viewPos_+stride:target;' in fx
assert 'for(int i=0;i<distance;++i)' in fx
assert 'f7SnakePath_.push_back(next);f7SnakeDirections_.push_back(direction);' in fx
assert 'f7SnakePath_.pop_back();f7SnakeDirections_.pop_back();' in fx
assert 'if(f7SnakeUnselect_)f7Selected_.erase(original);' in fx
assert 'f7OriginalPosition(pos)' in fx
assert 'const bool sweep=k.vk==VK_PRIOR||k.vk==VK_NEXT||k.vk==VK_HOME||k.vk==VK_END;' in fx
assert 'selectF7(true,target,direction,sweep);return true;' in fx
assert 'No selected parameter in that direction' not in fx
# The reference below expresses the user-facing range invariants (not a C++ execution).
def span(current, destination):
    if current == destination:
        return set()  # quiet edge, no cursor or selection change
    step = 1 if destination > current else -1
    return set(range(current, destination+step, step))
# From the middle of a column to its end/start, do not include untouched cells.
assert span(4, 9) == {4,5,6,7,8,9}
assert span(4, 0) == {0,1,2,3,4}
# A five-cell Page jump must not select just the endpoints.
assert span(2, 7) == {2,3,4,5,6,7}
# Returning over the same stretch retracts all previously touched cells.
assert span(7, 2) == span(2, 7)
# At either edge, the key is silent and no new path is created.
assert span(0, 0) == set() and span(9, 9) == set()
# Occurrence position is kept separate from parameter ID, including duplicates.
filtered_positions = [2, 7, 11]
assert [filtered_positions[p] for p in span(0, 2)] == [2, 7, 11]
print('TEST28 selection range and silent-edge source contracts PASS (native test pending)')
