"""0.0.69 release metadata, F7 Used functionality, and ReaPack history safety."""
from pathlib import Path
import importlib.util
import xml.etree.ElementTree as ET
r=Path(__file__).resolve().parents[1]
read=lambda f:(r/f).read_text(encoding='utf-8')
assert 'VERSION 0.0.69' in read('CMakeLists.txt')
assert 'LReaParams 0.0.69 - Native REAPER extension' in read('src/Extension.cpp')
assert '!define APP_VERSION "0.0.69"' in read('Installer/LReaParams.nsi')
assert 'LReaParams-0.0.69-Windows-x64-SETUP-EXE' in read('.github/workflows/build-windows.yml')
assert 'release-0-0-69-used-f7' in read('Guide/LReaParams - FX Params.html')
assert 'release-0-0-68-used' in read('Guide/LReaParams - FX Params.html')
for lang in ['it','es','fr','ru','zh-CN','ja']:
    doc=read('Guide/'+lang+'/fx.html')
    assert 'release-0-0-69-used-f7' in doc and 'release-0-0-68-used' in doc
for v in ('67','68','69'):
    assert (r/f'Docs/RELEASE_NOTES_0_0_{v}.md').is_file()
assert 'F7' in read('Docs/RELEASE_NOTES_0_0_69.md')
assert 'Ctrl+Shift+L' in read('Docs/RELEASE_NOTES_0_0_69.md')
assert 'usedF7SelectedIds_' in read('include/lrp/FxNavigator.h')
assert 'LReaParams.UsedParameters.v1' in read('src/FxNavigatorUsed.cpp')
assert 'SetExtState(' not in read('src/FxNavigatorUsed.cpp')
assert 'git add index.xml' in read('.github/workflows/publish-reapack.yml')
assert 'git add .' not in read('.github/workflows/publish-reapack.yml')
assert 'ref: ${{ env.RELEASE_TAG }}' in read('.github/workflows/publish-reapack.yml')
spec=importlib.util.spec_from_file_location('genidx',r/'Tools/generate_reapack_index.py')
m=importlib.util.module_from_spec(spec);spec.loader.exec_module(m)
def rel(v):
    return {'tag_name':f'v{v}','draft':False,'prerelease':False,'published_at':'2026-11-09T12:00:00Z','assets':[{'name':'reaper_lreaparams.dll','state':'uploaded','browser_download_url':f'https://github.com/Lo-lo78/LReaParams/releases/download/v{v}/reaper_lreaparams.dll'}]}
versions=m.release_versions([rel(v) for v in ('0.0.69','0.0.67','0.0.63','0.0.68','0.0.66','0.0.65')],lambda _:['Guide/index.html'])
root=ET.fromstring(m.build_index(versions,m.DEFAULT_REPO))
assert [e.attrib['name'] for e in root.findall('./category/reapack/version')]==['0.0.63','0.0.65','0.0.66','0.0.67','0.0.68','0.0.69']
print('Release 0.0.69 metadata, F7 Used, persistence and all ReaPack history: PASS')
