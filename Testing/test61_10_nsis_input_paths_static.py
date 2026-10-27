"""TEST61.10: guard absolute NSIS source inputs (no local compilation)."""
from pathlib import Path
import re

root = Path(__file__).resolve().parents[1]
s = (root/'Installer'/'LReaParams.nsi').read_text(encoding='utf-8')
w = (root/'.github/workflows/build-windows.yml').read_text(encoding='utf-8')
assert '!ifndef PROJECT_ROOT' in s
assert '!error "PROJECT_ROOT is required:' in s
assert '"/DPROJECT_ROOT=$projectRoot"' in w
assert "$projectRoot = (Resolve-Path .).Path.TrimEnd('\\')" in w
assert 'Installer input file is missing:' in w
assert 'Test-Path -LiteralPath $absoluteFile -PathType Leaf' in w
assert 'test61_10_nsis_input_paths_static.py' in w
# With a relative script path, NSIS implicitly prefixes File input with the script
# folder. The former File "${__FILEDIR__}\..\package" doubled "Installer".
assert '${__FILEDIR__}' not in s
for inp in (
    'package\\UserPlugins\\reaper_lreaparams.dll',
    'Guide\\*.*',
    'LICENSE',
    'THIRD_PARTY_NOTICES.md',
    'dist\\LReaParams-0.0.62-Source.zip',
    'dist\\SOURCE-COMMIT.txt',
):
    assert '${PROJECT_ROOT}\\'+inp in s, inp
assert '!include "${PROJECT_ROOT}\\Installer\\Guide-Uninstall.nsh"' in s
assert 'OutFile "${PROJECT_ROOT}\\dist\\LReaParams-${APP_VERSION}-Windows-x64-Setup.exe"' in s
for path in ('Guide/index.html','LICENSE','THIRD_PARTY_NOTICES.md'):
    assert (root/path).is_file(),path
# No full recursive delete of the user's persistent profile trees.
assert not re.search(r'RMDir\s+/r\s+"\$INSTDIR\\LReaParams',s,re.I)
print('TEST61.10 PASS: NSIS File, include and output paths use absolute project root; workflow preflight present')
