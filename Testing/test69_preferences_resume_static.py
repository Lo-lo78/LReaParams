#!/usr/bin/env python3
"""TEST Preferences: modal Ctrl+P preserves active FX/Track navigator state."""
from pathlib import Path
s = (Path(__file__).resolve().parents[1]/'src/Extension.cpp').read_text(encoding='utf-8')
case = s.split('case preferencesAction: {',1)[1].split('case openGuide:',1)[0]
launch = s.split('void launchNavigator(',1)[1].split('bool containsLegacyTxt(',1)[0]
tick = s.split('void tick() {',1)[1].split('void menu(',1)[0]
assert 'Navigator* suspended = current_ && current_->active()' in case
assert 'preferencesDialogOpen_ = true' in case
assert 'input_.stop();' in case and 'titleProxy_.hideAndRestore();' in case
assert case.index('input_.stop();') < case.index('editPreferences(')  # Render can be the modal owner
assert 'titleProxy_.textValue()' in case and 'setNativeText(' in case
assert 'if (suspended) {' in case
assert 'suspended->contextUnchanged() && suspended->uiStillOpen()' in case
assert 'launchNavigator(suspended, true);' in case
assert 'preferencesDialogOpen_ = false;' in case
assert 'exitNavigation(false);' not in case.split('if (suspended) {',1)[1].split('} else {',1)[0]
assert 'if (!resumeAfterPreferences)' in launch
assert 'if (!resumeAfterPreferences && desired == &navigator_' in launch
assert 'if (resumeAfterPreferences) desired->announce();' in launch
assert 'desired->begin()' not in case and 'suspended->begin()' not in case
assert 'if (preferencesDialogOpen_) return;' in tick
assert 'key.vk == \'P\'' in tick
print('TEST Preferences RETURN PASS: Ctrl+P suspend/restore state; direct action remains independent')
