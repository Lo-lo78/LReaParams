from pathlib import Path
p=Path(__file__).resolve().parents[1]
s=(p/'src/TempoAction.cpp').read_text(encoding='utf8')
h=(p/'include/lrp/TempoAction.h').read_text(encoding='utf8')
assert 'previousTimebase_' in h and 'previousAutoStretch_' in h
assert 'void TempoAction::restoreTimebase()' in s
assert 'restoreTimebase();' in s[s.index('void TempoAction::stop()'):s.index('void TempoAction::start()')]
assert s.index('SetMediaItemInfo_Value(item,"C_BEATATTACHMODE",0.0)') < s.index('CreateTakeAudioAccessor(take)')
assert s.index('SetCurrentBPM(project, double(bpm), false)') < s.index('    restoreTimebase();',s.index('    Undo_BeginBlock2(project);'))
for k in ('D_POSITION','D_LENGTH','D_PLAYRATE'):
    assert k in s
assert 'UNDO_STATE_ALL' in s
print('TEST69.3 restore original item timebase source contracts PASS')
