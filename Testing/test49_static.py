"""Source-only TEST49 sanity assertions; not a substitute for MSVC/CTest."""
from pathlib import Path
root = Path(__file__).resolve().parents[1]
cpp = (root / 'src/TrackNavigator.cpp').read_text()
mem = (root / 'src/TrackMemory.cpp').read_text()
hdr = (root / 'include/lrp/TrackNavigator.h').read_text()
parser = (root / 'src/Profile.cpp').read_text()
ext = (root / 'src/Extension.cpp').read_text()
cmake = (root / 'CMakeLists.txt').read_text()
from version_contract import version_at_least
assert version_at_least(root, (0, 0, 49))
assert 'src/TrackMemory.cpp' in cmake
assert 'setResourceRoot(resource_)' in ext
assert 'TrackMemory memory_' in hdr
assert 'memory_.load(resource_, projectFilename)' in cpp
assert 'memory_.setStep(parameterKey(), stepScale_)' in cpp
assert 'memory_.setValueSpeech(id, on)' in cpp
assert 'memory_.setCcSpeech(page, bare, on)' in cpp
assert 'memory_.valueSpeech(parameterKey())' in cpp
assert 'rememberPosition(); memory_.flush();' in cpp
assert 'CCSpeech.' in mem and 'LReaParams.StepScales' in mem
assert 'LReaParams.NavigationMemory' in mem
assert 'sha256(current) != digest_' in mem
assert 'MoveFileExW' in mem and 'writeNewVerified(backup, current)' in mem
assert 'parseNative(readFile(temporary))' in mem
assert 'name == "LReaParams.StepScales"' in parser
assert 'name == "LReaParams.ParameterSpeech"' in parser
assert 'Track CC Map.tp' in mem and 'LReaParamsProjectID' in mem and 'L"Projects"' in mem
print('TEST49 static contracts passed (NO compilation)')
