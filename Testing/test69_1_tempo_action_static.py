from pathlib import Path
root=Path(__file__).resolve().parents[1]
ext=(root/'src/Extension.cpp').read_text(encoding='utf-8')
impl=(root/'src/TempoAction.cpp').read_text(encoding='utf-8')
core=(root/'include/lrp/TempoDetector.h').read_text(encoding='utf-8')
cmake=(root/'CMakeLists.txt').read_text(encoding='utf-8')
assert 'LREAPARAMSDETECTITEMBPM' in ext
assert 'case tempoDetection:' in ext and 'tempoAction_.start()' in ext
assert 'tempoAction_.tick()' in ext and 'tempoAction_.stop()' in ext
assert 'CountSelectedMediaItems(project)!=1' in impl
assert 'TakeIsMIDI(take)' in impl
assert 'GetAudioAccessorSamples' in impl and 'CreateTakeAudioAccessor' in impl
assert 'GetMediaItemInfo_Value' in impl
assert 'SetCurrentBPM(project, double(bpm), false)' in impl
assert 'SetMediaItemInfo_Value(item,"C_BEATATTACHMODE",0.0)' in impl
assert 'SetMediaItemInfo_Value(item,"C_AUTOSTRETCH",0.0)' in impl
assert 'Undo_BeginBlock2(project)' in impl and 'Undo_EndBlock2(project' in impl
assert 'BPM not reliable' in impl and 'std::to_string(bpm)+" BPM"' in impl
assert 'AudioAccessorStateChanged' in impl and 'ValidatePtr2' in impl
assert 'const double four =' in core and 'const double center=' in core
assert 'TempoDetectorTests.cpp' in cmake and 'src/TempoAction.cpp' in cmake
print('TEST69.1 native BPM action PASS')
