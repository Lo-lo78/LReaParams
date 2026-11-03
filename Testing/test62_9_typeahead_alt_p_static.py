"""Source-level contracts for TEST62.9 (native REAPER runtime still required)."""
from pathlib import Path
r=Path(__file__).resolve().parents[1]
e=(r/'src/Extension.cpp').read_text(encoding='utf-8')
f=(r/'src/FxNavigator.cpp').read_text(encoding='utf-8')
t=(r/'src/TrackNavigator.cpp').read_text(encoding='utf-8')
fm=(r/'src/FxNavigatorMemories.cpp').read_text(encoding='utf-8')
tm=(r/'src/TrackNavigatorMemories.cpp').read_text(encoding='utf-8')
router=(r/'src/InputRouter.cpp').read_text(encoding='utf-8')
core=(r/'include/lrp/TypeAhead.h').read_text(encoding='utf-8')
assert "msg->wParam == 'P'" in e and '(GetKeyState(VK_MENU) & 0x8000)' in e
assert '!fixedFxChainShortcutMatches(msg)' in e
assert 'actionShortcutMatches(msg)' not in e
assert 'isFocusedFxList()' in e and 'GetDlgCtrlID(focus) != 1076' in e
assert 'shortcutHelp()' in e and 'current_ && current_->active()' in e
assert 'GetKeyState(VK_RMENU)' in e
assert 'key.time = message.time;' in router
assert 'key.time = static_cast<DWORD>(GetMessageTime());' in router
assert core.count('static_cast<std::uint32_t>(eventTime - lastTime_)') == 1
assert 'sameLetterCycle' in core and 'typeAheadWide' in core
assert 'typeAhead_.find' in f and 'typeAhead_.find' in t
assert 'typeAhead_.find' in fm and 'typeAhead_.find' in tm
assert 'memoryTypeAhead(k)' in fm and 'memoryTypeAhead(k)' in tm
assert 'const auto& selected=memorySelected_' in tm and 'k.vk == VK_DOWN' in tm, 'Preserve selected navigation'
assert 'if (k.altGr && k.character)' in f
assert 'if (editF7_ && handleF7(k)) return;' in f
assert 'add_executable(typeahead_tests Testing/TypeAheadTests.cpp)' in (r/'CMakeLists.txt').read_text()
print('TEST62.9 static checks PASS: context Alt+P, timestamped type-ahead, F7, both memory managers')
