"""0.0.70 version, accessible Preferences and non-destructive ReaPack publisher."""
from pathlib import Path
import importlib.util
from reapack_index_contract import verify_optional_reapack_index
import xml.etree.ElementTree as ET
r=Path(__file__).resolve().parents[1]
rd=lambda x:(r/x).read_text(encoding='utf-8')
assert 'project(LReaParams VERSION 0.0.73 LANGUAGES CXX)' in rd('CMakeLists.txt')
assert 'LReaParams 0.0.73 - Native REAPER extension' in rd('src/Extension.cpp')
assert '!define APP_VERSION "0.0.73"' in rd('Installer/LReaParams.nsi')
assert 'LReaParams-0.0.73-Windows-x64-SETUP-EXE' in rd('.github/workflows/build-windows.yml')
assert 'LREAPARAMSPREFERENCES' in rd('src/Extension.cpp')
assert 'constexpr int kFxTitleCount = 4' in rd('src/Preferences.cpp')
assert 'constexpr int kTrackTitleCount = 12' in rd('src/Preferences.cpp')
assert 'v0.0.71' in rd('Docs/REAPACK_SETUP_IT.md')
assert 'Ctrl+P' in rd('Docs/RELEASE_NOTES_0_0_70.md')
for name in ('Guide/LReaParams - FX Params.html','Guide/LReaParams - Track Params.html'):
    assert 'release-0-0-70-preferences' in rd(name)
for lang in ('it','es','fr','ru','zh-CN','ja'):
    for section in ('fx','track'):
        assert 'release-0-0-70-preferences' in rd(f'Guide/{lang}/{section}.html')
push=rd('Tools/push_lreaparams.cmd')
pub=rd('.github/workflows/publish-reapack.yml')
assert 'git restore --source=origin/main --staged --worktree -- index.xml' in push
assert 'git pull --rebase origin main' in push and 'git push origin main' in push
assert 'git push --force' not in push
assert 'types: [published]' in pub and 'ref: ${{ env.RELEASE_TAG }}' in pub
assert 'git add index.xml' in pub and 'git add .' not in pub
assert 'generate_reapack_index.py --output index.xml' in pub
assert (r/'Docs/RELEASE_NOTES_0_0_69.md').is_file()
# A clean source ZIP has no index.xml, but a GitHub checkout of main
# legitimately contains the catalog committed by the ReaPack publisher.
# The protected push script restores that remote version before each commit.
# Validate it when present; do not reject or remove the history.
verify_optional_reapack_index(r)
spec=importlib.util.spec_from_file_location('reapack', r/'Tools/generate_reapack_index.py')
m=importlib.util.module_from_spec(spec);spec.loader.exec_module(m)
def rel(v):
    return {'tag_name':f'v{v}', 'draft':False, 'prerelease':False,
            'published_at':'2026-11-15T12:00:00Z',
            'assets':[{'name':'reaper_lreaparams.dll','state':'uploaded',
                       'browser_download_url':f'https://github.com/Lo-lo78/LReaParams/releases/download/v{v}/reaper_lreaparams.dll'}]}
versions=m.release_versions([rel(x) for x in ('0.0.70','0.0.69','0.0.68','0.0.67','0.0.66','0.0.65','0.0.63')],lambda _:['Guide/index.html'])
root=ET.fromstring(m.build_index(versions,m.DEFAULT_REPO))
assert [x.attrib['name'] for x in root.findall('./category/reapack/version')] == ['0.0.63','0.0.65','0.0.66','0.0.67','0.0.68','0.0.69','0.0.70']
assert 'LReaParams 0.0.70' in rd('Docs/RELEASE_NOTES_0_0_70.md')
print('Historical 0.0.70 Preferences and full ReaPack history: PASS')
