"""Release 0.0.71 metadata, Type/Name title split and non-destructive ReaPack integration."""
from pathlib import Path
import re
import importlib.util
import xml.etree.ElementTree as ET
from reapack_index_contract import verify_optional_reapack_index
r=Path(__file__).resolve().parents[1]
rd=lambda n:(r/n).read_text(encoding='utf-8')
assert 'project(LReaParams VERSION 0.0.76 LANGUAGES CXX)' in rd('CMakeLists.txt')
assert 'LReaParams 0.0.76 - Native REAPER extension' in rd('src/Extension.cpp')
assert 'Release date: 22 November 2026' in rd('src/Extension.cpp')
assert '!define APP_VERSION "0.0.76"' in rd('Installer/LReaParams.nsi')
assert 'LReaParams-0.0.76-Windows-x64-SETUP-EXE' in rd('.github/workflows/build-windows.yml')
assert 'Title: FX TCP (F4)' in rd('Docs/GITHUB_RELEASE_0_0_71_BODY_EN.md') or 'Track Params F4' in rd('Docs/GITHUB_RELEASE_0_0_71_BODY_EN.md')
assert 'TEST70.1' in rd('.github/workflows/build-windows.yml')
assert 'TEST70.2' in rd('.github/workflows/build-windows.yml')
assert 'LReaParams 0.0.70' in rd('Docs/RELEASE_NOTES_0_0_70.md')
assert 'LReaParams 0.0.71' in rd('Docs/RELEASE_NOTES_0_0_71.md')
for file in ('Guide/LReaParams - FX Params.html', 'Guide/LReaParams - Track Params.html'):
    assert 'release-0-0-70-preferences' in rd(file)
    assert 'release-0-0-71-type-name' in rd(file)
for lang in ('it','es','fr','ru','zh-CN','ja'):
    for section in ('fx','track'):
        assert 'release-0-0-70-preferences' in rd(f'Guide/{lang}/{section}.html')
        assert 'release-0-0-71-type-name' in rd(f'Guide/{lang}/{section}.html')
assert 'git restore --source=origin/main --staged --worktree -- index.xml' in rd('Tools/push_lreaparams.cmd')
assert 'git pull --rebase origin main' in rd('Tools/push_lreaparams.cmd')
publisher=rd('.github/workflows/publish-reapack.yml')
assert 'types: [published]' in publisher and 'ref: ${{ env.RELEASE_TAG }}' in publisher
assert 'git add index.xml' in publisher and 'generate_reapack_index.py --output index.xml' in publisher
verify_optional_reapack_index(r)
spec=importlib.util.spec_from_file_location('reapack',r/'Tools/generate_reapack_index.py')
m=importlib.util.module_from_spec(spec);spec.loader.exec_module(m)
def rel(v):
    return {'tag_name':f'v{v}','draft':False,'prerelease':False,'published_at':'2026-11-16T12:00:00Z',
            'assets':[{'name':'reaper_lreaparams.dll','state':'uploaded',
                       'browser_download_url':f'https://github.com/Lo-lo78/LReaParams/releases/download/v{v}/reaper_lreaparams.dll'}]}
versions=m.release_versions([rel(v) for v in ('0.0.71','0.0.70','0.0.69','0.0.68','0.0.67','0.0.66','0.0.65','0.0.63')],lambda _:['Guide/index.html'])
index=ET.fromstring(m.build_index(versions,m.DEFAULT_REPO))
assert [v.attrib['name'] for v in index.findall('./category/reapack/version')]==['0.0.63','0.0.65','0.0.66','0.0.67','0.0.68','0.0.69','0.0.70','0.0.71']
print('Release 0.0.71 Type/Name metadata, guides and historical ReaPack index PASS')
