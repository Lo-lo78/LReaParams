"""TEST61.11: UI flow guard for accessible multilingual NSIS installer (source only)."""
from pathlib import Path
import re

root = Path(__file__).resolve().parents[1]
nsis = (root/'Installer'/'LReaParams.nsi').read_text(encoding='utf-8')
wf = (root/'.github/workflows/build-windows.yml').read_text(encoding='utf-8')
assert 'AutoCloseWindow true' in nsis
assert '!insertmacro MUI_PAGE_INSTFILES' in nsis
assert re.search(r'^\s*!insertmacro MUI_PAGE_FINISH\b', nsis, re.M)
assert '!define MUI_LANGDLL_ALWAYSSHOW' in nsis
assert '!define MUI_LANGDLL_ALLLANGUAGES' in nsis
assert '!insertmacro MUI_LANGDLL_DISPLAY' in nsis
assert '!define MUI_WELCOMEPAGE_TEXT "$(InstallerWelcome)"' in nsis
assert '!define MUI_DIRECTORYPAGE_TEXT_TOP "$(ResourceDirectoryHelp)"' in nsis
for name in ('English','Italian','Spanish','French','Russian','SimpChinese','Japanese'):
    assert f'!insertmacro MUI_LANGUAGE "{name}"' in nsis
for sym in ('InstallerWelcome', 'ResourceDirectoryHelp'):
    assert f'LangString {sym} ${{LANG_ITALIAN}}' in nsis
    assert f'LangString {sym} ${{LANG_ENGLISH}}' in nsis
assert '!insertmacro MUI_RESERVEFILE_LANGDLL' in nsis
assert 'MessageBox MB_ICONINFORMATION|MB_OK "$(BeforeInstall)"' not in nsis
assert not re.search(r'^\s*MessageBox MB_ICONINFORMATION\|MB_OK', nsis, re.M)
assert 'MessageBox MB_ICONEXCLAMATION|MB_YESNO|MB_DEFBUTTON2 "$(PathUnrecognized)"' in nsis
assert 'LReaParams\\Guide' in nsis
assert 'WriteUninstaller' in nsis
assert 'test61_11_installer_accessibility_static.py' in wf
print('TEST61.11 PASS: multilingual Next/Back wizard, no blocking OK, explicit Finish page')
