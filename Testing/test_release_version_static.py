"""Check public release version consistency; source-only, no native build."""
from pathlib import Path
import re

ROOT = Path(__file__).resolve().parents[1]

def read(path):
    return (ROOT / path).read_text(encoding='utf-8')

cmake = read('CMakeLists.txt')
m = re.search(r'project\(LReaParams VERSION (\d+\.\d+\.\d+) LANGUAGES CXX\)', cmake)
assert m, 'Missing CMake project version'
version = m.group(1)
assert version == '0.0.62', f'Unexpected release version: {version}'

about = read('src/Extension.cpp')
assert f'LReaParams {version} - Native REAPER extension' in about
assert '14 independent grids' in about and 'Ctrl+Alt+B restores the FX view' in about
assert 'F12 alone is reserved' in about

nsi = read('Installer/LReaParams.nsi')
for fragment in (f'!define APP_VERSION "{version}"',
                 f'VIProductVersion "{version}.0"',
                 f'VIAddVersionKey "FileVersion" "{version}"',
                 f'LReaParams-{version}-Source.zip'):
    assert fragment in nsi, fragment

workflow = read('.github/workflows/build-windows.yml')
for filename in (f'LReaParams-{version}-Windows-x64-MULTILINGUAL',
                 f'LReaParams-{version}-HTML-Guides',
                 f'LReaParams-{version}-Source.zip',
                 f'LReaParams-{version}-Windows-x64-Setup.exe',
                 f'LReaParams-{version}-Windows-x64-SETUP-EXE',
                 f'LReaParams-{version}-COMPLETE-SOURCE'):
    assert filename in workflow, filename
assert 'LReaParams-0.0.61-' not in workflow
assert 'LReaParams-0.0.61-' not in nsi
assert f'LReaParams {version}' in read('README.md')
assert f'LReaParams {version}' in read('Docs/RELEASE_NOTES_0_0_62.md')

for guide in ['Guide/index.html','Guide/LReaParams - FX Params.html',
              'Guide/LReaParams - Track Params.html','Guide/INSTALL.txt']:
    assert version in read(guide), guide
for language in ['it','es','fr','ru','zh-CN','ja']:
    for file in ['index.html','fx.html','track.html']:
        assert version in read(f'Guide/{language}/{file}'), (language,file)

# These are compatibility/data format identifiers, not user-visible version labels.
assert 'PageLayoutVersion' in read('src/TrackNavigator.cpp')
assert '"61"' in read('src/TrackNavigator.cpp')
print('Release version consistency PASS: 0.0.62 About, CMake, installer, Actions and 7 guide languages')
