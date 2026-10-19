#!/usr/bin/env python3
"""Create a safe NSIS uninstall list ONLY for shipped offline Guide files.

Run before makensis. This script generates installer source; it does not build.
"""
from pathlib import Path

root = Path(__file__).resolve().parents[1]
guide = root / 'Guide'
assert guide.is_dir()
paths = sorted((p.relative_to(guide) for p in guide.rglob('*') if p.is_file()), key=lambda p: str(p).casefold())
assert len(paths) >= 20
result = ['; Generated automatically from Guide/ files. Do not edit by hand.',
          '; Remove ONLY shipped documentation, never user-provided files.']
for path in paths:
    if any(part in ('.', '..') or '"' in part or '$' in part or '\n' in part for part in path.parts):
        raise ValueError(f'Unsafe NSIS path: {path}')
    win_path = str(path).replace("/", "\\")
    result.append(f'Delete "$INSTDIR\\LReaParams\\Guide\\{win_path}"')
dirs = sorted((p.relative_to(guide) for p in guide.rglob('*') if p.is_dir()), key=lambda p: (-len(p.parts), str(p).casefold()))
for path in dirs:
    if any(part in ('.', '..') or '"' in part or '$' in part for part in path.parts):
        raise ValueError(f'Unsafe NSIS directory: {path}')
    win_path = str(path).replace("/", "\\")
    result.append(f'RMDir "$INSTDIR\\LReaParams\\Guide\\{win_path}"')
result.append('RMDir "$INSTDIR\\LReaParams\\Guide"')
target = root / 'Installer' / 'Guide-Uninstall.nsh'
target.write_text('\n'.join(result) + '\n', encoding='utf-8')
print(f'Generated {target.name}: {len(paths)} files; {len(dirs)} subfolders')
