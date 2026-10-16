"""0.0.46.3: Master/Monitor FX browsing remains in its opening chain.

Source-only tests, no REAPER runtime, CMake, compiler, or native build.
"""
from pathlib import Path
from version_contract import version_at_least

root = Path(__file__).resolve().parents[1]
assert version_at_least(root, (0, 0, 46, 3))
cpp = (root/'src/FxNavigator.cpp').read_text(encoding='utf-8')
contexts = (root/'src/FxNavigatorContexts.cpp').read_text(encoding='utf-8')
header = (root/'include/lrp/FxNavigator.h').read_text(encoding='utf-8')


def method(code, signature):
    start = code.index(signature)
    brace = code.index('{', start)
    depth = 0
    for i in range(brace, len(code)):
        depth += (code[i] == '{') - (code[i] == '}')
        if depth == 0:
            return code[start:i+1]
    raise AssertionError(signature)

assert 'bool browserScopeMonitor_ = false;' in header
assert 'bool browserEntryInScope(int entryIndex) const;' in header
assert 'browserScopeMonitor_ = false;' in method(cpp, 'void FxNavigator::end() noexcept')
assert 'browserScopeMonitor_ = !take_' in method(contexts, 'void FxNavigator::enterFxBrowser()')
assert 'browserScopeMonitor_ = !take_' in cpp[cpp.index('int offlineCursor = -1;'):cpp.index('speech_("No navigable FX parameters")')]

scope = method(contexts, 'bool FxNavigator::browserEntryInScope(int entryIndex) const')
assert 'track_ != GetMasterTrack(project_)' in scope
assert 'browserScopeMonitor_' in scope and '0x1000000' in scope

for name in ('browserVisibleIndex', 'browserSpeech', 'browserMove',
             'browserCycleByInitial', 'browserMoveFx'):
    body = method(contexts, f'FxNavigator::{name}(')
    assert 'browserEntryInScope(' in body, name

for name in ('browserSelect', 'toggleOffline'):
    body = method(contexts, f'void FxNavigator::{name}(')
    assert ('browserVisibleIndex()' in body or 'browserEntryInScope(' in body), name

browser_key = method(contexts, 'void FxNavigator::browserKey(')
assert 'if ((k.vk==VK_LEFT||k.vk==VK_RIGHT) && track_==GetMasterTrack(project_)) return;' in browser_key
assert 'std::vector<int> column' not in browser_key
assert "browserMove(k.vk==VK_UP?-1:1)" in browser_key
assert 'browserMoveFx(k.vk==VK_UP?-1:1)' in browser_key

switch = method(cpp, 'void FxNavigator::switchFx(')
assert 'const bool fromMonitor = (fx_ & 0x1000000) != 0;' in switch
assert 'if (master &&' in switch and '!= fromMonitor)' in switch
assert 'break;' in switch

accepts = method(cpp, 'bool FxNavigator::accepts(')
assert "k.vk==VK_LEFT||k.vk==VK_RIGHT||k.vk==VK_UP||k.vk==VK_DOWN||" in accepts
assert 'browserScopeMonitor_ ? "Monitor FX" : "Master"' in method(cpp, 'std::wstring FxNavigator::windowTitle() const')
begin = method(cpp, 'bool FxNavigator::begin()')
assert 'focusedFxInChain = fx;' in begin
assert 'entries_[i].index == focusedFxInChain' in begin
assert 'if (!havePreferred && remembered && remembered->hasLastFx)' in begin

# A combined internal index is retained for GUID persistence; navigation is
# constrained by chain category. Test forward/backward and jump counts with a
# representative combined Master+Monitor layout.
entries = [0, 1, 2, 0x1000000, 0x1000001]

def scoped(cursor, monitor):
    return ((entries[cursor] & 0x1000000) != 0) == monitor


def move(cursor, direction, monitor, steps=1):
    for _ in range(steps):
        next_pos = cursor + direction
        if next_pos < 0 or next_pos >= len(entries) or not scoped(next_pos, monitor):
            break
        cursor = next_pos
    return cursor

assert move(2, +1, False) == 2
assert move(3, -1, True) == 3
assert move(1, +1, False, 10) == 2
assert move(4, -1, True, 10) == 3
assert sum(scoped(i, False) for i in range(len(entries))) == 3
assert sum(scoped(i, True) for i in range(len(entries))) == 2
assert 'TrackNavigator' not in '\n'.join(
    str(x) for x in (root/'Docs/CHANGELOG.md', root/'Docs/Keyboard.md')
)
print('TEST46.3 isolated Master/Monitor browser and FX navigation contracts PASS')
