"""LReaParams v0.0.76 candidate metadata, accessible guides and ReaPack history."""
from pathlib import Path
import re
root=Path(__file__).resolve().parents[1]
rd=lambda path:(root/path).read_text(encoding='utf-8')
assert 'project(LReaParams VERSION 0.0.76 LANGUAGES CXX)' in rd('CMakeLists.txt')
assert 'LReaParams 0.0.76 - Native REAPER extension' in rd('src/Extension.cpp')
assert 'New in 0.0.76:' in rd('src/Extension.cpp')
assert '!define APP_VERSION "0.0.76"' in rd('Installer/LReaParams.nsi')
assert 'VIProductVersion "0.0.76.0"' in rd('Installer/LReaParams.nsi')
assert 'LReaParams-0.0.76-Source.zip' in rd('.github/workflows/build-windows.yml')
assert 'LReaParams-0.0.76-Windows-x64-SETUP-EXE' in rd('.github/workflows/build-windows.yml')
assert (root/'Docs/RELEASE_NOTES_0_0_75.md').exists()  # do not erase historical files
assert (root/'Docs/RELEASE_NOTES_0_0_76.md').exists()
assert (root/'Docs/GITHUB_RELEASE_0_0_76_BODY_EN.md').exists()
assert 'v0.0.76' in rd('Docs/REAPACK_SETUP_IT.md')
assert 'types: [published]' in rd('.github/workflows/publish-reapack.yml')
assert 'git restore --source=origin/main --staged --worktree -- index.xml' in rd('Tools/push_lreaparams.cmd')
assert 'git pull --rebase origin main' in rd('Tools/push_lreaparams.cmd')
from reapack_index_contract import verify_optional_reapack_index
verify_optional_reapack_index(root)  # publisher-owned history can exist on main
for lang in ('en','it','es','fr','ru','zh-CN','ja'):
 for kind in ('fx','track'):
  path=f'Guide/LReaParams - {"FX Params" if kind=="fx" else "Track Params"}.html' if lang=='en' else f'Guide/{lang}/{kind}.html'
  content=rd(path)
  assert 'release-0-0-75-render' in content, (lang,kind,'history')
  assert 'release-0-0-76-current' in content, (lang,kind,'new')
  assert 'release-0-0-75-current' not in content, (lang,kind,'obsolete')
  assert '<title>LReaParams 0.0.76' in content, (lang,kind,'title')
assert '0.0.76' in rd('Guide/index.html')
assert '0.0.76' in rd('Guide/INSTALL.txt')
print('LReaParams 0.0.76 current version, seven-language guides and historical ReaPack safeguards PASS')
