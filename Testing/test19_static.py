"""Source-only contract tests for focus-sensitive Main shortcuts in REAPER FX chain.
Run with Python only. The REAPER/NVDA runtime behavior remains unverified.
"""
from pathlib import Path
root = Path(__file__).resolve().parents[1]
e = (root / 'src/Extension.cpp').read_text()
f = (root / 'src/FxNavigator.cpp').read_text()
a = (root / 'include/lrp/ReaperApi.h').read_text()
for s in ('<accelerator', '"-accelerator"', 'fxChainShortcutHook', 'isFocusedFxList()',
          'GetDlgCtrlID(focus) != 1076', 'GetTouchedOrFocusedFX(1,',
          'GetActionShortcutDesc(section, command', 'CountActionShortcuts(section, command)',
          'kbd_formatKeyName(&accel',
          'shortcutHelp()', 'current_ && current_->active()'):
    assert s in e, f'FX chain shortcut guard missing: {s}'
for s in ('GetTrackMediaItem(owner, item)', 'GetTake(mediaItem, takeIdx)',
          'GetTouchedOrFocusedFX(1,', 'if (!track_ && masterSelected'):
    assert s in f, f'Focused FX owner not prioritized: {s}'
for api in ('CountActionShortcuts', 'GetActionShortcutDesc', 'SectionFromUniqueID', 'kbd_formatKeyName'):
    assert f'#define REAPERAPI_WANT_{api}' in a, api
assert 'WM_KEYDOWN' in e and 'WM_SYSKEYDOWN' in e
assert 'VK_INSERT' in e and 'hwndCaret' in e
assert 'SetWindowsHookEx' not in e, 'No new Windows hook permitted'
print('Shared TEST19 accelerator source contracts PASS under TEST20 routing. Runtime not tested.')
