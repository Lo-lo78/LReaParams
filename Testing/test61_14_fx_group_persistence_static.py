"""TEST61.14 — contract for persistent group + exact position in .fx (source only)."""
from pathlib import Path
root=Path(__file__).resolve().parents[1]
order=(root/'src/FxOrder.cpp').read_text(encoding='utf-8')
nav=(root/'src/FxNavigator.cpp').read_text(encoding='utf-8')
view=(root/'src/FxNavigatorOrder.cpp').read_text(encoding='utf-8')
tests=(root/'Testing/ProfileTests.cpp').read_text(encoding='utf-8')
header=(root/'include/lrp/FxOrder.h').read_text(encoding='utf-8')
assert 'lrp_last_navigation_v1' in order and '"[Extra]"' in order
assert 'FxOrder::lastView() const' in order and 'std::optional<LastView> lastView() const' in header
assert 'lastParameterRecord() == newRecord && oldView' in order
assert 'std::to_string(groupSlot) + "," + std::to_string(viewPosition)' in order
assert 'sha256(original) != loadedDigest_' in order
assert 'MoveFileExW' in order and 'writeNewVerified' in order
assert 'fxOrder_.persistLastParameter(parameter_, parameterName_, groupSlot_' in nav
assert 'f7OriginalPosition(viewPos_)' in nav
assert 'const auto last=fxOrder_.lastView()' in view
assert 'if (!restoredFromSession)' in view and 'groupSlot_=last->groupSlot' in view
assert 'group!=fxOrder_.groups.end() && !group->second.empty()' in view
assert 'lastView()->viewPosition==2' in tests and 'viewPosition==2' in tests
assert 'Group or duplicate parameter occurrence not restored' in tests
assert 'Stale LastParam save overwrote an external change' in tests
print('TEST61.14 PASS: persistent group + exact occurrence, no local build')
