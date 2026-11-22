"""Source-only safety tests for Shift+F1 inspector; runtime testing is Windows/MSVC."""
from pathlib import Path
r = Path(__file__).resolve().parents[1]
read = lambda p: (r / p).read_text(encoding='utf-8')
router = read('src/InputRouter.cpp')
header = read('include/lrp/InputRouter.h')
help = read('src/ShortcutHelp.cpp')
contexts = read('src/ShortcutHelpContexts.cpp')
render = read('src/RenderNavigation.cpp')
prefs = read('src/Preferences.cpp')
ext = read('src/Extension.cpp')
cmake = read('CMakeLists.txt')
assert all(x in cmake for x in ('src/ShortcutHelp.cpp', 'src/ShortcutHelpContexts.cpp'))
assert 'shortcutHelpToggle(physical)' in router
assert 'helpToggle || helpCapture || swallowedRelease' in router
assert 'inspectKey(physical)' in router
assert 'head_ = tail_ = 0;' in router
assert 'GetFocus() != helpFocus_' in router
assert 'helpMode_ = false; helpFocus_ = nullptr;' in router
assert 'return false; // Outside LReaParams, the gesture belongs to REAPER.' in router
assert 'shortcutHelpDescription(physical, preferences_, *navigator_)' in router
assert 'mapPreferredShortcut(physical, *preferences, scope)' in help
assert 'navigator.accepts(mapped)' in help
assert 'navigator.shortcutDescription(mapped)' in help
assert 'entry.assigned' in help and 'entry.description' in help
assert 'candidate.vk == VK_F1 && candidate.shift && !candidate.ctrl && !candidate.alt' in prefs
assert 'vk == VK_F1 && shift && !ctrl && !alt' in prefs
assert 'if (input_.shortcutHelpActive())' in ext
assert 'head_ = tail_ = 0;\n        sayHelp' in router
for method in ('void InputRouter::sayHelp', 'bool InputRouter::inspectKey'):
    block=router[router.index(method):router.find('\n}',router.index(method))+2]
    for side_effect in ('navigator_->handle(', 'SetFocus(', 'Main_OnCommand(', 'TrackFX_SetParam(', 'PostMessageW('):
        assert side_effect not in block, (method,side_effect)
assert 'bool RenderNavigation::onKey(MSG& msg)' in render
assert 'refreshControls(render_)' in render
assert 'accelerators_.find(letter)' in render
assert 'helpReleases_[vk]' in render and 'msg->message = WM_NULL' in render
assert 'if (helpMode_ && GetFocus() != helpFocus_)' in render
method=render[render.index('std::string RenderNavigation::describeHelpKey'):render.index('bool RenderNavigation::onKey')]
for side_effect in ('SetFocus(', 'focusControl(', 'jumpKey(', 'focusPageTab(', 'Main_OnCommand(', 'BM_CLICK', 'SetWindowTextW('):
    assert side_effect not in method, side_effect
assert 'FxNavigator::shortcutDescription' in contexts
assert 'TrackNavigator::shortcutDescription' in contexts
# Leave the user-controlled release history and publication workflow alone.
assert 'git restore --source=origin/main --staged --worktree -- index.xml' in read('Tools/push_lreaparams.cmd')
print('TEST75.2 Shift+F1 interception/configuration/focus/Render static PASS')
