"""Check the CMake project version without pinning historical regression tests.

Old source-only tests must remain valid after the project version advances.
No native compilation or imported project code is involved.
"""
from pathlib import Path
import re


def version_at_least(project_root, minimum):
    cmake = (Path(project_root) / "CMakeLists.txt").read_text(encoding="utf-8")
    match = re.search(
        r"(?m)^\s*project\(\s*LReaParams\s+VERSION\s+"
        r"(\d+)\.(\d+)\.(\d+)(?:\.(\d+))?(?=\s|\))",
        cmake,
    )
    if match is None:
        return False
    current = tuple(int(part or 0) for part in match.groups())
    required = tuple(minimum) + (0,) * (4 - len(minimum))
    return current >= required
