"""0.0.65 release package: version, About, docs, theme and step calibration."""
from pathlib import Path
from reapack_index_contract import verify_optional_reapack_index
R=Path(__file__).resolve().parents[1]
def read(x):return (R/x).read_text(encoding='utf-8')
assert 'project(LReaParams VERSION 0.0.65' in read('CMakeLists.txt')
assert 'LReaParams 0.0.65 - Native REAPER extension' in read('src/Extension.cpp')
assert 'TEST64.3 Keyboard and Value Page step calibration' not in read('src/Extension.cpp')
assert 'F4 toggles Standard/Keyboard separately' in read('src/Extension.cpp')
assert '!define APP_VERSION "0.0.65"' in read('Installer/LReaParams.nsi')
assert 'VIProductVersion "0.0.65.0"' in read('Installer/LReaParams.nsi')
assert 'LReaParams-0.0.65-Windows-x64-SETUP-EXE' in read('.github/workflows/build-windows.yml')
assert 'LReaParams-0.0.65-Source.zip' in read('.github/workflows/build-windows.yml')
assert 'release-0-0-65-keyboard' in read('Guide/LReaParams - FX Params.html')
assert 'FX_RELEASE_065_HTML' in read('Tools/generate_guides_i18n.py')
assert '14 independent' in read('Docs/RELEASE_NOTES_0_0_65.md')
assert 'lrp_keyboard_themes_v1' in read('src/FxNavigatorOrder.cpp')
assert 'parameter_step::amount(known, normal, large, big,' in read('src/FxNavigator.cpp')
for lang in ['it','es','fr','ru','zh-CN','ja']:
    g=read(f'Guide/{lang}/fx.html')
    assert '0.0.65' in g and 'release-0-0-65-keyboard' in g, lang
    for file in ['index.html','track.html']:
        assert '0.0.65' in read(f'Guide/{lang}/{file}'), (lang,file)
# The release publisher commits index.xml to main. Its presence is expected in CI.
verify_optional_reapack_index(R)
print('TEST65 release metadata and Keyboard docs PASS')
