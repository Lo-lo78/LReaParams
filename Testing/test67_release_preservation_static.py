"""0.0.68 release metadata, F3 speech, Grid/Step and ReaPack history safeguards."""
from pathlib import Path
r=Path(__file__).resolve().parents[1]
def read(x): return (r/x).read_text(encoding='utf-8')
cmake=read('CMakeLists.txt'); about=read('src/Extension.cpp'); nav=read('src/FxNavigator.cpp'); ci=read('.github/workflows/build-windows.yml'); pub=read('.github/workflows/publish-reapack.yml')
assert 'project(LReaParams VERSION 0.0.68' in cmake
assert 'LReaParams 0.0.68 - Native REAPER extension' in about
assert 'FX Backspace: Backspace resets parameter' in about
assert 'FX Used (Usati): Ctrl+Shift+L toggles' in about
assert 'Used remembers parameters edited through LReaParams' in about
assert 'Group slots' in nav and 'Memory slots' in nav or 'Group slots' in about
assert 'if (k.vk == VK_BACK && !k.alt && !k.altGr)' in nav
assert 'resetCurrentStep()' in nav and 'resetCurrentGrid()' in nav and 'beginGridNumericEdit()' in nav
assert 'resetAllToDefault()' in nav
assert 'GetDoubleClickTime()' in nav
assert 'LReaParams-0.0.68-Windows-x64-SETUP-EXE' in ci
assert 'dist/LReaParams-0.0.68-Source.zip' in ci
assert 'types: [published]' in pub and 'ref: ${{ env.RELEASE_TAG }}' in pub
assert 'python3 Tools/generate_reapack_index.py --output index.xml' in pub
assert 'git add index.xml' in pub and 'git add .' not in pub
assert (r/'Docs/RELEASE_NOTES_0_0_66.md').is_file() and (r/'Docs/RELEASE_NOTES_0_0_68.md').is_file()
for lang in ['it','es','fr','ru','zh-CN','ja']:
    txt=read(f'Guide/{lang}/fx.html')
    assert 'release-0-0-67-grid' in txt
    assert 'release-0-0-68-used' in txt
    assert 'release-0-0-66-keyboard' in txt
assert 'release-0-0-67-grid' in read('Guide/LReaParams - FX Params.html')
assert 'release-0-0-68-used' in read('Guide/LReaParams - FX Params.html')
print('Release 0.0.68 metadata, F3, Grid/Step and ReaPack preservation PASS')
