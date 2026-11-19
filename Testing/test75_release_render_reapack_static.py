"""0.0.75 Release: Render shortcuts, versioned outputs and ReaPack continuity."""
from pathlib import Path
import importlib.util
import xml.etree.ElementTree as ET

root = Path(__file__).resolve().parents[1]
rd = lambda p: (root / p).read_text(encoding='utf-8')
version = '0.0.75'
assert f'project(LReaParams VERSION {version} LANGUAGES CXX)' in rd('CMakeLists.txt')
assert f'LReaParams {version} - Native REAPER extension' in rd('src/Extension.cpp')
assert 'Release date: 19 November 2026' in rd('src/Extension.cpp')
assert f'!define APP_VERSION "{version}"' in rd('Installer/LReaParams.nsi')
assert f'LReaParams-{version}-Windows-x64-SETUP-EXE' in rd('.github/workflows/build-windows.yml')
assert f'LReaParams-{version}-Source.zip' in rd('.github/workflows/build-windows.yml')
assert 'Alt+Z' in rd('Docs/RENDER_NAVIGATION.md')
assert 'Alt+Shift+letter' in rd('Docs/RENDER_NAVIGATION.md')
assert 'Alt+Shift+letter' in rd('src/Extension.cpp')
for p in ['Guide/LReaParams - FX Params.html', 'Guide/LReaParams - Track Params.html']:
    g = rd(p)
    for id in ['release-0-0-70-preferences','release-0-0-71-type-name','release-0-0-74-ranges','release-0-0-75-render']:
        assert f'id="{id}"' in g, (p,id)
for lang in ('it','es','fr','ru','zh-CN','ja'):
    for section in ('fx','track'):
        g = rd(f'Guide/{lang}/{section}.html')
        assert 'release-0-0-74-ranges' in g and 'release-0-0-75-render' in g
assert 'types: [published]' in rd('.github/workflows/publish-reapack.yml')
assert 'ref: ${{ env.RELEASE_TAG }}' in rd('.github/workflows/publish-reapack.yml')
assert 'git restore --source=origin/main --staged --worktree -- index.xml' in rd('Tools/push_lreaparams.cmd')
assert 'git pull --rebase origin main' in rd('Tools/push_lreaparams.cmd')
assert not (root / 'index.xml').exists(), 'Source release must not include generated index.xml'

spec = importlib.util.spec_from_file_location('reapack', root / 'Tools/generate_reapack_index.py')
m = importlib.util.module_from_spec(spec)
spec.loader.exec_module(m)
def rel(v):
    return {'tag_name':f'v{v}','draft':False,'prerelease':False,
            'published_at':'2026-11-19T12:00:00Z',
            'assets':[{'name':'reaper_lreaparams.dll','state':'uploaded',
                       'browser_download_url':f'https://github.com/Lo-lo78/LReaParams/releases/download/v{v}/reaper_lreaparams.dll'}]}
versions = ('0.0.63','0.0.65','0.0.66','0.0.67','0.0.68','0.0.69','0.0.70','0.0.71','0.0.72','0.0.73','0.0.74','0.0.75')
entries = m.release_versions([rel(v) for v in reversed(versions)], lambda _: ['Guide/index.html','Guide/it/fx.html'])
xml = ET.fromstring(m.build_index(entries, m.DEFAULT_REPO))
assert [v.attrib['name'] for v in xml.findall('./category/reapack/version')] == list(versions)
print('0.0.75 Render, full ReaPack history and release metadata PASS')
