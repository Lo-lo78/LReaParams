"""Source-only acceptance guards. These are not C++ execution or runtime proof."""
from pathlib import Path
import hashlib, re, zipfile
ROOT=Path(__file__).resolve().parents[1]
def read(p): return (ROOT/p).read_text(encoding='utf-8')
source='\n'.join(p.read_text() for p in (ROOT/'src').glob('*.cpp'))
headers='\n'.join(p.read_text() for p in (ROOT/'include/lrp').glob('*.h'))
for obsolete in ['LREAPARAMSPARAMETERLIBRARY','ProfileKind::library','".pp"','L"Params"','PARAMLIB_V1']:
    assert obsolete not in source+headers, obsolete
assert not (ROOT/'Legacy/Parameter Library.lua').exists()
assert not (ROOT/'Testing/fixtures/Params').exists()
for action in ['FXPARAMS','TRACKPARAMS','FXMEMORIES']:
    assert '"LREAPARAMS'+action+'"' in source
extension=read('src/Extension.cpp')
assert not re.search(r'actions_\[\d+\]',extension)
advanced=read('src/FxNavigatorAdvanced.cpp')
for token in ['MIDI_GetRecentInputEvent(index','index<256','pending.rbegin()',
              'pickup_[param]','cc_runtime_fixed_map_enabled_v1','cc_param_speech_v1::',
              'clearNativeLearn(learnParam_)','TrackFX_NavigatePresets','TakeFX_NavigatePresets',
              'GetFXEnvelope','TakeFX_GetEnvelope','SetEnvelopeStateChunk','UNDO_STATE_ITEMS',
              'snapshot.names','compareParamIndex','restoreReaEqDefault','CHUNK_ONLY',
              'Host raw units','FormatParamValueNormalized','recent_searches_v1']:
    assert token in advanced,token
assert 'Sleep(' not in advanced and 'CreateThread(' not in advanced
midi=read('include/lrp/MidiControl.h')
for token in ['1.0/127.0','0.0005','diff>=3','diff<=1?3:2']:
    assert token in midi,token
assert 'src/FxNavigatorAdvanced.cpp' in read('CMakeLists.txt')
assert 'Testing/test40_static.py' in read('.github/workflows/build-windows.yml')
# Check lexical delimiters across all C++ translation units and local headers.
for p in [*ROOT.glob('src/*.cpp'),*ROOT.glob('include/lrp/*.h'),*ROOT.glob('Testing/*.cpp')]:
    s=re.sub(r'//[^\n]*|/\*.*?\*/|"(?:\\.|[^"\\])*"|\'(?:\\.|[^\'\\])*\'', '',p.read_text(),flags=re.S)
    stack=[]
    for char in s:
        if char in '{([':stack.append(char)
        elif char in '})]': assert stack and stack.pop()=='{(['['})]'.index(char)],str(p)
    assert not stack,str(p)
print('TEST40 scope, API wiring and lexical guards PASS; native/runtime not executed')
