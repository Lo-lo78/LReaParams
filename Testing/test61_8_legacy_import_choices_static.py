"""TEST61.8 source-only safety and keyboard dialog checks (no compiler)."""
from pathlib import Path
root=Path(__file__).resolve().parents[1]
ext=(root/'src/Extension.cpp').read_text(encoding='utf-8')
choice=(root/'src/ChoiceDialogs.cpp').read_text(encoding='utf-8')
cmake=(root/'CMakeLists.txt').read_text(encoding='utf-8')
action=ext[ext.index('case importLegacy:'):ext.index('case openData:')]
assert 'requestLegacyImport(false);' in action
assert 'importer_.start(resource_)' not in ext[:ext.index('    bool shortcutHelp() const')], 'Auto import on startup without consent'
assert 'requestLegacyImport(true);' in ext
assert 'LegacyImportChoice.txt' in ext and 'writeNewVerified(marker' in ext
assert 'confirmLegacyImport(info_.hwnd_main, atStartup)' in ext
assert 'if (!answer || !*answer)' in ext
assert 'hasLegacyProfiles()' in ext
assert 'if (started) announceImport_ = true;' in ext
assert 'LREAPARAMSIMPORTLEGACY' in ext and 'LREAPARAMSSETTINGS' in ext
settings=ext[ext.index('case settings:'):ext.index('case openGuide:')]
assert 'chooseKeyboardBackend' in settings and 'MB_YESNOCANCEL' not in settings
assert 'InputBackend::sdkAccelerator' in settings and 'InputBackend::mainThreadHook' in settings
assert 'TD_INFORMATION_ICON' in choice and 'dialog.pszMainIcon' in choice
assert 'TaskDialogIndirect(' in choice and 'TDF_ALLOW_DIALOG_CANCELLATION' in choice
assert 'SetWindowsHookExW(WH_GETMESSAGE' in choice
assert 'GetCurrentThreadId()' in choice and 'IsChild(' in choice
assert 'TDM_CLICK_BUTTON' in choice and 'UnhookWindowsHookEx' in choice
assert "'Y', 'N'" in choice and "'1', '2'" in choice
assert 'options, IDNO' in choice, 'Import must default to NO'
assert 'return std::nullopt' in choice
assert 'src/ChoiceDialogs.cpp' in cmake and 'comctl32' in cmake
for name in ['FxNavigator.cpp', 'TrackNavigator.cpp', 'FxNavigatorMemories.cpp']:
    text=(root/'src'/name).read_text(encoding='utf-8')
    assert "k.vk == 'Y'" in text or "k.vk=='Y'" in text, name
    assert "k.vk == 'N'" in text or "k.vk=='N'" in text, name
print('TEST61.8 dialogs and consent checks PASS; runtime verification pending')
