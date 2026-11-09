from pathlib import Path
p=Path(__file__).resolve().parents[1]
s=(p/'src/TempoAction.cpp').read_text()
a=s[s.index('void TempoAction::nextSegment()'):s.index('void TempoAction::finish()')]
assert 'auto r=tempo::analyze(mono_)' in a
assert 'if(r.valid) estimates_.push_back(r)' in a
assert 'tempo_map::analyze' not in a
assert 'tempo::combine(estimates_)' in s
assert 'void TempoAction::finishMap()' in s
print('TEST69.6 fixed BPM detector isolated from adaptive tracker PASS')
