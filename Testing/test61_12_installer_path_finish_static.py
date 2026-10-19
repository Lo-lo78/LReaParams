"""TEST61.12: dynamically selected user resources, localized completion page (no build)."""
from pathlib import Path
import re

root = Path(__file__).resolve().parents[1]
s = (root/'Installer/LReaParams.nsi').read_text(encoding='utf-8')
w = (root/'.github/workflows/build-windows.yml').read_text(encoding='utf-8')
assert 'InstallDir "$APPDATA\\REAPER"' in s
assert 'InstallDirRegKey HKCU "${SETTINGS_KEY}" "ResourcePath"' in s
assert 'RequestExecutionLevel user' in s
assert 'WriteRegStr HKCU "${SETTINGS_KEY}" "ResourcePath" "$INSTDIR"' in s
assert '!insertmacro MUI_PAGE_DIRECTORY' in s
assert 'IfFileExists "$INSTDIR\\reaper.ini" directory_ok' in s
assert re.search(r'^!insertmacro MUI_PAGE_INSTFILES\n(?:[^\n]*\n){0,5}!define MUI_FINISHPAGE_TEXT "\$\(InstallerFinished\)"\n!insertmacro MUI_PAGE_FINISH', s, re.M)
assert 'AutoCloseWindow true' in s
assert 'MUI_FINISHPAGE_NOAUTOCLOSE' not in [line.strip() for line in s.splitlines() if line.strip().startswith('!define')]
for sym in ('InstallerWelcome', 'ResourceDirectoryHelp', 'InstallerFinished'):
    for locale in ('ENGLISH','ITALIAN','SPANISH','FRENCH','RUSSIAN','SIMPCHINESE','JAPANESE'):
        match = re.search(r'^LangString '+sym+r' \$\{LANG_'+locale+r'\} "(.*)"$', s, re.M)
        assert match, (sym,locale)
        if sym == 'ResourceDirectoryHelp':
            assert '$APPDATA' not in match.group(1), locale
            assert 'OK' not in match.group(1), locale
        if sym == 'InstallerWelcome':
            assert 'OK' not in match.group(1),locale
assert not re.search(r'C:\\Users\\|SiRecog',s,re.I)
assert not re.search(r'^\s*MessageBox MB_ICONINFORMATION\|MB_OK',s,re.M)
assert 'test61_12_installer_path_finish_static.py' in w
print('TEST61.12 PASS: HKCU dynamic resource path, 7-language instructions, one Finish page')
