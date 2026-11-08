"""Guard against publishing Used on the already occupied 0.0.67 tag."""
from pathlib import Path
import importlib.util, xml.etree.ElementTree as ET
r=Path(__file__).resolve().parents[1]
rd=lambda p:(r/p).read_text(encoding='utf-8')
assert 'project(LReaParams VERSION 0.0.68 LANGUAGES CXX)' in rd('CMakeLists.txt')
assert 'LReaParams 0.0.68 - Native REAPER extension' in rd('src/Extension.cpp')
assert 'v0.0.68' in rd('Docs/REAPACK_SETUP_IT.md')
assert 'Already' not in rd('Docs/RELEASE_NOTES_0_0_67.md')
assert '0.0.67' in rd('Docs/RELEASE_NOTES_0_0_67.md')
assert 'Ctrl+Shift+L' in rd('Docs/RELEASE_NOTES_0_0_68.md')
assert 'release-0-0-67-grid' in rd('Guide/LReaParams - FX Params.html')
assert 'release-0-0-68-used' in rd('Guide/LReaParams - FX Params.html')
for l in ('it','es','fr','ru','zh-CN','ja'):
 t=rd(f'Guide/{l}/fx.html'); assert 'release-0-0-67-grid' in t and 'release-0-0-68-used' in t
pub=rd('.github/workflows/publish-reapack.yml')
assert 'git add index.xml' in pub and 'git add .' not in pub
assert 'ref: ${{ env.RELEASE_TAG }}' in pub
print('Historical v0.0.67 and new v0.0.68 Used release separated: PASS')
