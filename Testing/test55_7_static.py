"""TEST55.7 first-entry Original and per-FX session snapshots. SOURCE ONLY."""
from pathlib import Path
r=Path(__file__).resolve().parents[1]
fx=(r/'src/FxNavigator.cpp').read_text()
adv=(r/'src/FxNavigatorAdvanced.cpp').read_text()
h=(r/'include/lrp/FxNavigator.h').read_text()
# Exit must NOT invalidate the snapshots for an FX visited previously.
end=fx.split('void FxNavigator::end() noexcept {',1)[1].split('void FxNavigator::restorePersistedParameter()',1)[0]
assert 'compareStates_.clear()' not in end
assert 'pendingF8At_ = 0;' in end
# First entry copies the actual (possibly project-saved) sound; no restore.
enter=fx.split('bool FxNavigator::selectFx(int index) {',1)[1].split('int FxNavigator::count()',1)[0]
assert 'initializeCompare();' in enter
init=adv.split('void FxNavigator::initializeCompare() {',1)[1].split('bool FxNavigator::toggleCompare()',1)[0]
assert 'existing && existing->armed' in init
assert 'state.original = captureCompare();' in init
assert 'state.edited = state.original;' in init
assert 'applyCompare(' not in init
assert 'originalActive = false' in init
# Double F8 updates the reference; single F8 does not overwrite Original.
toggle=adv.split('bool FxNavigator::toggleCompare() {',1)[1].split('bool FxNavigator::updateOriginal()',1)[0]
assert 'state.original = ' not in toggle
update=adv.split('bool FxNavigator::updateOriginal() {',1)[1].split('void FxNavigator::resolveF8()',1)[0]
assert 'state.original = captureCompare();' in update
assert 'GetDoubleClickTime()' in adv
# Never leak old projects into the new session, but preserve OTHER OPEN tabs.
begin=fx.split('bool FxNavigator::begin() {',1)[1].split('bool FxNavigator::rebuildEntries()',1)[0]
assert 'compareStates_.erase(std::remove_if' in begin
assert 'EnumProjects(index, nullptr, 0)' in begin
# Track Params and persisted FX/.tp profile formats must not be touched.
assert 'compareStates_' in h
print('TEST55.7 first entry, re-entry, double F8, project tab pruning PASS (static only)')
