"""TEST65.1: release automation and local Git sync guard (source only)."""
from pathlib import Path
from reapack_index_contract import verify_optional_reapack_index
r=Path(__file__).resolve().parents[1]
w=(r/'.github/workflows/publish-reapack.yml').read_text(encoding='utf-8')
s=(r/'Tools/push_lreaparams.cmd').read_text(encoding='utf-8')
assert 'types: [published]' in w
assert 'workflow_dispatch:' in w
assert "required: false" in w and "default: ''" in w
assert 'gh release view --repo $env:GITHUB_REPOSITORY --json tagName --jq .tagName' in w
assert 'RELEASE_TAG=$tag' in w
assert 'ref: ${{ env.RELEASE_TAG }}' in w
assert 'gh release upload $env:RELEASE_TAG' in w
assert 'python3 Tools/generate_reapack_index.py --output index.xml' in w
assert 'git fetch origin main' in w and 'git reset --hard origin/main' in w
assert 'for attempt in 1 2 3' in w
assert 'git push origin HEAD:main' in w
assert 'git fetch origin main' in s
assert 'git restore --source=origin/main --staged --worktree -- index.xml' in s
assert 'git pull --rebase origin main' in s
assert 'git push origin main' in s
assert 'git push --force' not in s
# GitHub's main checkout already includes the generated catalog after a release.
verify_optional_reapack_index(r)
print('TEST65.1 automatic ReaPack publishing, fallback and Git safety PASS')
