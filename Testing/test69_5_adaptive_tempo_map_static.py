from pathlib import Path
root=Path(__file__).resolve().parents[1]
api=(root/'include/lrp/ReaperApi.h').read_text()
source=(root/'src/TempoAction.cpp').read_text()
actions=(root/'src/Extension.cpp').read_text()
core=(root/'include/lrp/TempoMapEngine.h').read_text()
cmake=(root/'CMakeLists.txt').read_text()
for name in ('CountTempoTimeSigMarkers','GetTempoTimeSigMarker','SetTempoTimeSigMarker','Undo_DoUndo2'):
    assert '#define REAPERAPI_WANT_'+name in api,name
    assert name in source,name
assert 'LREAPARAMSCREATETEMPOMAP' in actions
assert 'case tempoMapping:' in actions and 'tempoAction_.startMap()' in actions
assert 'if(existingTempoCount>1)' in source
assert 'restoreTimebase();' in source
assert 'std::setprecision(3)' in source
assert 'tempo_map::Stream' in source and 'mapStream_.feed' in source
assert 'class Stream' in core and 'inline Analysis analyze' in core
assert 'TempoMapTests.cpp' in cmake
print('TEST69.5 adaptive tempo map static PASS')
