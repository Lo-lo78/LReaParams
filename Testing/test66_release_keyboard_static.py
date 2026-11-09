"""0.0.66 release package: version, About, docs, theme and step calibration."""
from pathlib import Path
from reapack_index_contract import verify_optional_reapack_index
R=Path(__file__).resolve().parents[1]
def read(x):return (R/x).read_text(encoding='utf-8')
assert 'project(LReaParams VERSION 0.0.69' in read('CMakeLists.txt')
assert 'LReaParams 0.0.69 - Native REAPER extension' in read('src/Extension.cpp')
assert 'TEST65.1.1)' not in read('src/Extension.cpp')
assert 'F4 toggles Standard/Keyboard separately' in read('src/Extension.cpp')
assert '!define APP_VERSION "0.0.69"' in read('Installer/LReaParams.nsi')
assert 'VIProductVersion "0.0.69.0"' in read('Installer/LReaParams.nsi')
assert 'LReaParams-0.0.69-Windows-x64-SETUP-EXE' in read('.github/workflows/build-windows.yml')
assert 'LReaParams-0.0.69-Source.zip' in read('.github/workflows/build-windows.yml')
assert 'release-0-0-66-keyboard' in read('Guide/LReaParams - FX Params.html')
assert 'FX_RELEASE_066_HTML' in read('Tools/generate_guides_i18n.py')
assert '14 independent' in read('Docs/RELEASE_NOTES_0_0_66.md')
assert 'lrp_keyboard_themes_v1' in read('src/FxNavigatorOrder.cpp')
assert 'parameter_step::amount(known, normal, large, big,' in read('src/FxNavigator.cpp')
for lang in ['it','es','fr','ru','zh-CN','ja']:
    g=read(f'Guide/{lang}/fx.html')
    assert '0.0.66' in g and 'release-0-0-66-keyboard' in g, lang
    for file in ['index.html','track.html']:
        assert '0.0.69' in read(f'Guide/{lang}/{file}'), (lang,file)
# The release publisher commits index.xml to main. Its presence is expected in CI.
verify_optional_reapack_index(R)
print('Release 0.0.66 metadata and Keyboard docs PASS')
