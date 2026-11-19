"""TEST74.5: focus-only reverse accelerator cycles and sample-rate pin.

These are source/model checks, not a substitute for Windows REAPER + NVDA tests.
"""
from pathlib import Path
root = Path(__file__).resolve().parents[1]
src = (root / 'src/RenderNavigation.cpp').read_text(encoding='utf-8')
hdr = (root / 'include/lrp/RenderNavigation.h').read_text(encoding='utf-8')
doc = (root / 'Docs/TEST74_1_RENDER_NAVIGATION.md').read_text(encoding='utf-8')

for needle in ('bool jumpKeyDirection(wchar_t letter, int direction);',):
    assert needle in hdr, needle
for needle in ('bool RenderNavigation::jumpKeyDirection(wchar_t letter, int direction)',
               'const bool reverse = direction < 0;',
               'reverse ? (i + count - 1) % count : (i + 1) % count',
               'reverseOffset = 2 % count',
               'cycle_[letter] = (index + 1) % count;',
               "return shift ? jumpKeyDirection(static_cast<wchar_t>(vk - 'A' + L'a'), -1)",
               'sampleRateId = GetDlgCtrlID(h) == 1041',
               "accelerators_[L'z']", "accelerators_[L's']",
               'namedSampleRate = name == L"sample rate"',
               'return focused == target || (focused && IsChild(target, focused))'):
    assert needle in src, needle
assert 'Alt+Shift+letter' in doc
assert 'Alt+Z Sample rate' in doc

# Mirror the index arithmetic and exercise both directions and wraparound.
def step(n, direction, saved_next=None, focused=None):
    assert n >= 1
    if saved_next is None:
        first = n-1 if direction < 0 else 0
    else:
        first = ((saved_next+n-(2 % n)) % n) if direction < 0 else saved_next % n
    if focused is not None:
        first = (focused+n-1) % n if direction < 0 else (focused+1) % n
    index = first
    return index, (index+1) % n
for n in range(1, 20):
    ix, next_ix = step(n, +1)
    assert ix == 0
    for k in range(1, n+3):
        ix, next_ix = step(n, +1, next_ix, ix)
        assert ix == k % n
    ix, next_ix = step(n, -1, next_ix, ix)
    assert ix == (k-1) % n
    for m in range(1, n+3):
        ix, next_ix = step(n, -1, next_ix, ix)
        assert ix == (k-1-m) % n
    ix, next_ix = step(n, +1, next_ix, ix)
    assert ix == (k-m) % n
    ix, next_ix = step(n, -1)
    assert ix == n-1

for forbidden in ('Main_OnCommand(', 'RenderFile(', 'BM_CLICK',
                  'SendInput(', 'SetWindowTextW(', 'TCM_SETCURSEL'):
    assert forbidden not in src, forbidden
for name in ('Tools/push_lreaparams.cmd', 'Tools/generate_reapack_index.py',
             '.github/workflows/publish-reapack.yml'):
    assert (root/name).exists(), name
print('TEST74.5 reverse cycles, sample-rate pin and focus-only safety PASS')
