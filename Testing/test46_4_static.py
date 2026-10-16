"""0.0.46.4: Master/Monitor horizontal columns, isolated vertical navigation.

Source-only contract checks; no CMake, C++ builds or DAW runtime.
"""
from pathlib import Path
from version_contract import version_at_least

root = Path(__file__).resolve().parents[1]
assert version_at_least(root, (0, 0, 46, 4))
hdr = (root/'include/lrp/FxNavigator.h').read_text(encoding='utf-8')
ctx = (root/'src/FxNavigatorContexts.cpp').read_text(encoding='utf-8')
cpp = (root/'src/FxNavigator.cpp').read_text(encoding='utf-8')

def method(source, signature):
    start = source.index(signature)
    start_brace = source.index('{', start)
    depth = 0
    for pos in range(start_brace, len(source)):
        depth += (source[pos] == '{') - (source[pos] == '}')
        if depth == 0:
            return source[start:pos+1]
    raise AssertionError(signature)

switch = method(ctx, 'void FxNavigator::browserSwitchColumn(')
key = method(ctx, 'void FxNavigator::browserKey(')
move = method(ctx, 'void FxNavigator::browserMove(')
move_fx = method(ctx, 'void FxNavigator::browserMoveFx(')
cycle = method(ctx, 'void FxNavigator::browserCycleByInitial(')
select = method(ctx, 'void FxNavigator::browserSelect(')
speech = method(ctx, 'std::string FxNavigator::browserSpeech(')
enter = method(ctx, 'void FxNavigator::enterFxBrowser(')

assert 'void browserSwitchColumn(int direction);' in hdr
assert 'browserMasterCursor_' in hdr and 'browserMonitorCursor_' in hdr
assert 'const bool targetMonitor = direction > 0;' in switch
assert 'if (browserScopeMonitor_ == targetMonitor) return;' in switch
assert 'browserEntryInScope(remembered)' in switch
assert 'speech_(browserSpeech())' in switch
assert 'if (take_ || track_ != GetMasterTrack(project_)' in switch
assert 'browserSwitchColumn(k.vk==VK_LEFT?-1:1)' in key
assert 'browserEntryInScope(next + step)' in move
assert 'browserEntryInScope(targetIndex)' in move_fx
assert 'browserEntryInScope(j)' in cycle
assert 'browserVisibleIndex()' in select
assert 'if (browserEntryInScope(i))' in speech
assert 'browserMasterCursor_ = browserMonitorCursor_ = -1' in enter
assert 'browserMasterCursor_ = browserMonitorCursor_ = -1' in cpp
assert 'Master FX. No FX' in speech and 'Monitor FX. No FX' in speech
assert 'switchItem(k.vk==VK_LEFT?-1:1)' in key  # Ctrl+Left/Right unaffected

# Example: 3 Master FX and 2 Monitor FX. Vertical lists are isolated,
# while horizontal arrows switch between the two lists.
items = [0, 1, 2, 0x1000000, 0x1000001]
def in_column(position, monitor):
    return 0 <= position < len(items) and bool(items[position] & 0x1000000) == monitor

def move_vertical(position, direction, monitor):
    next_position = position + direction
    return next_position if in_column(next_position, monitor) else position

assert move_vertical(2, 1, False) == 2
assert move_vertical(3, -1, True) == 3
assert move_vertical(1, 1, False) == 2
assert move_vertical(4, -1, True) == 3
assert next(i for i in range(len(items)) if in_column(i, True)) == 3
assert next(i for i in range(len(items)) if in_column(i, False)) == 0
print('TEST46.4 Master/Monitor horizontal switching, vertical isolation PASS')
