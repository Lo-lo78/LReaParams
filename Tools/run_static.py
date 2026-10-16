"""Run only Python text/format checks. Never launches a native build."""
from pathlib import Path
import subprocess,sys
root=Path(__file__).resolve().parents[1]
commands=[root/'Tools/audit.py',*sorted((root/'Testing').glob('test*_static.py'))]
for path in commands:
    subprocess.run([sys.executable,str(path)],cwd=root,check=True)
print(f'{len(commands)} source-only suites passed. C++/REAPER tests NOT RUN.')
