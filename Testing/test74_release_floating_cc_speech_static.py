"""0.0.74 speech, documentation, and ReaPack continuity checks."""
from pathlib import Path
r=Path(__file__).resolve().parents[1]
def rd(p):return (r/p).read_text(encoding='utf-8')
track=rd('src/TrackNavigatorMidi.cpp')
fx=rd('src/FxNavigatorAdvanced.cpp')
assert 'Fixed CC map off' not in track
assert 'Floating CC. Channel ' in track
assert 'Floating CC. Channel ' in fx
assert 'std::to_string(session.number)' in track and 'std::to_string(session.number)' in fx
assert 'session.suspendForFixed(false)' in track and 'session.suspendForFixed(fixedCc_)' in fx
assert 'Fixed CC on. ' in fx and 'Fixed CC map on. ' in track
assert '0.0.74 - Native REAPER extension' in rd('src/Extension.cpp')
for lang in ('it','es','fr','ru','zh-CN','ja'):
    for name in ('fx','track'):
        guide=rd(f'Guide/{lang}/{name}.html')
        assert 'release-0-0-74-ranges' in guide, (lang,name)
for name in ('FX Params','Track Params'):
    assert 'release-0-0-74-ranges' in rd(f'Guide/LReaParams - {name}.html')
assert 'types: [published]' in rd('.github/workflows/publish-reapack.yml')
assert 'generate_reapack_index.py --output index.xml' in rd('.github/workflows/publish-reapack.yml')
assert 'git restore --source=origin/main --staged --worktree -- index.xml' in rd('Tools/push_lreaparams.cmd')
assert 'git pull --rebase origin main' in rd('Tools/push_lreaparams.cmd')
assert not (r/'index.xml').exists()
print('0.0.74 release MIDI speech, guides and ReaPack continuity PASS')
