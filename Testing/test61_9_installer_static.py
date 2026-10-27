"""TEST61.9: source-only tests of NSIS package paths, preservation and license."""
from pathlib import Path
import re
import subprocess
import sys

root = Path(__file__).resolve().parents[1]
nsis = (root / 'Installer' / 'LReaParams.nsi').read_text(encoding='utf-8')
workflow = (root / '.github' / 'workflows' / 'build-windows.yml').read_text(encoding='utf-8')
readme = (root / 'README.md').read_text(encoding='utf-8')
manifest_script = root / 'Tools' / 'create_installer_manifest.py'
assert 'GNU GENERAL PUBLIC LICENSE' in (root / 'LICENSE').read_text(encoding='utf-8')
assert (root / 'THIRD_PARTY_NOTICES.md').is_file()
assert 'GPL-3.0-only' in readme
assert 'RequestExecutionLevel user' in nsis
assert 'SetCompressor /SOLID zlib' in nsis
assert 'InstallDir "$APPDATA\\REAPER"' in nsis
assert 'ValidateResourceDirectory' in nsis
assert 'IfFileExists "$INSTDIR\\reaper.ini"' in nsis
assert 'LReaParams\\Guide' in nsis
assert 'LReaParams\\Plugins' in nsis and 'LReaParams\\Tracks' in nsis
assert 'LReaParams\\Settings' in nsis and 'LReaParams\\Backups' in nsis
assert 'UserPlugins\\reaper_lreaparams.dll' in nsis
assert 'LReaParams-0.0.62-Source.zip' in nsis
assert 'Uninstall-LReaParams.exe' in nsis
assert 'MUI_UNPAGE_CONFIRM' in nsis
assert 'MUI_PAGE_DIRECTORY' in nsis
assert 'MUI_PAGE_CUSTOMFUNCTION_LEAVE ValidateResourceDirectory' in nsis
for locale in ('English','Italian','Spanish','French','Russian','SimpChinese','Japanese'):
    assert f'MUI_LANGUAGE "{locale}"' in nsis, locale
# Critical safety: NEVER recursively delete LReaParams or Guide, or any profiles.
assert not re.search(r'RMDir\s+/r\s+"\$INSTDIR\\LReaParams', nsis, re.I)
for profile in ('Plugins', 'Tracks', 'Settings', 'Backups', 'Params'):
    assert not re.search(r'(?:Delete|RMDir)\s+[^\n]*\\LReaParams\\'+profile+r'(?:\\|"|\s)', nsis, re.I)
assert 'File /r "${PROJECT_ROOT}\\Guide\\*.*"' in nsis
assert 'CreateDirectory "$INSTDIR\\LReaParams\\Plugins"' in nsis
assert workflow.count('LReaParams-0.0.62-Windows-x64-SETUP-EXE') == 1
assert 'git archive --format=zip --output=dist/LReaParams-0.0.62-Source.zip HEAD' in workflow
assert 'choco install nsis' in workflow
assert 'makensis.exe' in workflow
assert 'test61_8_legacy_import_choices_static.py' in workflow
assert 'LReaParams-0.0.62-Windows-x64-MULTILINGUAL' in workflow
assert 'LReaParams-Windows-x64-NATIVE-TEST' in workflow
subprocess.run([sys.executable, str(manifest_script)], cwd=root, check=True)
manifest = (root/'Installer'/'Guide-Uninstall.nsh').read_text(encoding='utf-8')
files = sorted(p.relative_to(root/'Guide') for p in (root/'Guide').rglob('*') if p.is_file())
deletes = re.findall(r'^Delete "\$INSTDIR\\LReaParams\\Guide\\([^\"]+)"$', manifest, re.M)
assert len(files) == len(deletes)
assert {str(f).replace('/', '\\') for f in files} == set(deletes)
assert not re.search(r'\bRMDir /r\b', manifest)
print(f'TEST61.9 PASS: EXE installer is configured, {len(files)} guide files safely removable; native build not run')
