"""LReaParams 0.0.75 release metadata and ReaPack history safety."""
from pathlib import Path
from reapack_index_contract import verify_optional_reapack_index
r=Path(__file__).resolve().parents[1]
rd=lambda n:(r/n).read_text(encoding='utf8')
assert 'project(LReaParams VERSION 0.0.75 LANGUAGES CXX)' in rd('CMakeLists.txt')
assert 'LReaParams 0.0.75 - Native REAPER extension' in rd('src/Extension.cpp')
assert 'Release date: 19 November 2026' in rd('src/Extension.cpp')
assert '!define APP_VERSION "0.0.75"' in rd('Installer/LReaParams.nsi')
assert 'LReaParams-0.0.75-Windows-x64-SETUP-EXE' in rd('.github/workflows/build-windows.yml')
assert 'LReaParams 0.0.71' in rd('Docs/RELEASE_NOTES_0_0_71.md')
assert 'LReaParams 0.0.74' in rd('Docs/RELEASE_NOTES_0_0_74.md')
assert 'release-0-0-71-type-name' in rd('Guide/LReaParams - FX Params.html')
assert 'release-0-0-72-empty-step' in rd('Guide/LReaParams - FX Params.html')
assert 'git restore --source=origin/main --staged --worktree -- index.xml' in rd('Tools/push_lreaparams.cmd')
assert 'git pull --rebase origin main' in rd('Tools/push_lreaparams.cmd')
assert 'types: [published]' in rd('.github/workflows/publish-reapack.yml')
# GitHub Actions checks out main where index.xml legitimately exists.
# Validate it when present without requiring deletion of ReaPack history.
verify_optional_reapack_index(r)
print('Release 0.0.75 source metadata and historical ReaPack safeguards PASS')
