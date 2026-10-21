"""TEST61.16: per-view F1/F2 width and cursor memory, source only (no native build)."""
from pathlib import Path
root = Path(__file__).resolve().parents[1]
header = (root/'include/lrp/FxNavigator.h').read_text(encoding='utf-8')
nav = (root/'src/FxNavigator.cpp').read_text(encoding='utf-8')
views = (root/'src/FxNavigatorOrder.cpp').read_text(encoding='utf-8')
profile = (root/'src/FxOrder.cpp').read_text(encoding='utf-8')
manager = (root/'src/FxNavigatorMemories.cpp').read_text(encoding='utf-8')
assert 'std::array<ViewCursor, 14> viewCursors' in header
assert 'std::array<ViewCursor, 14> viewCursors_' in header
assert 'groupSlot_ + 1 : fxOrder_.custom ? 1 : 0' in views
assert 'void FxNavigator::captureViewCursor()' in views
assert 'void FxNavigator::restoreViewCursor(' in views
assert 'cursor.position = f7FilterActive_ ? f7OriginalPosition(viewPos_) : viewPos_' in views
assert 'if (editF7_) return;' in views and 'cursor.columns = std::clamp(columns_, 1, 200);' in views
assert 'if (cursor.remembered && cursor.position >= 0)' in views
assert 'rebuildView(cursor.parameter, cursor.position)' in views
assert 'group_grid_size_v1::slot::' in views and 'grid_size_v1' in views
assert 'custom_order_grid_size_v1' in views and 'group_last_position_v1::slot::' in views
assert 'viewCursors_ = pos.viewCursors;' in views and 'pos.viewCursors = viewCursors_' in nav
assert 'rememberPosition(); // Save the outgoing Plugin/Custom cursor and grid.' in nav
assert 'restoreViewCursor(old);' in nav
assert "rememberPosition(); // Capture the outgoing group's independent grid." in views
assert 'restoreViewCursor(parameter_);' in views
assert 'if(next!=columns_){columns_=next;' in nav and 'rememberPosition();speech_("Grid "' in nav
assert 'serializeViewCursors()' in nav
assert 'lrp_context_grids_v1=' in profile and 'MoveFileExW' in profile
assert 'extraValue("lrp_context_grids_v1") == contextGrids' in profile
assert 'restoreViewCursor(memoryReturnParam_, memoryReturnPosition_);' in manager
assert 'Group' in views and 'F7' in views
# Legacy contracts still present.
assert 'std::to_string(groupSlot) + "," + std::to_string(viewPosition)' in profile
assert 'if (viewCursors_[static_cast<size_t>(currentViewIndex())].position >= 0) return;' in nav
print('TEST61.16 PASS: 14 independent layouts, Lua legacy fallback, persistent .fx, session overlay and F1/F2 capture')
