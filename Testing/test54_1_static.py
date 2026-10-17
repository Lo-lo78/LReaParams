"""TEST54.1 project-scoped Track CC persistence and shared shortcut contracts.
Only static checks; native builds/tests are performed by GitHub Actions.
"""
from pathlib import Path
from version_contract import version_at_least
r=Path(__file__).resolve().parents[1]
assert version_at_least(r, (0,0,54,1))
track=(r/'src/TrackNavigator.cpp').read_text()
mem=(r/'src/TrackMemory.cpp').read_text()
mid=(r/'src/TrackNavigatorMidi.cpp').read_text()
h=(r/'include/lrp/TrackMemory.h').read_text()
ext=(r/'src/Extension.cpp').read_text()
router=(r/'src/InputRouter.cpp').read_text()
profile=(r/'src/Profile.cpp').read_text()
unit=(r/'Testing/ProfileTests.cpp').read_text()
assert 'memory_.load(resource_, projectFilename)' in track
assert 'EnumProjects(-1, projectFilename' in track
assert 'L"Tracks" / L"Projects"' in mem
assert 'sha256(canonical).substr(0, 12)' in mem
assert 'LReaParamsProjectID' in mem
assert 'FXParams.ProjectTrack' in mem
assert 'Tracks" / L"Track CC Map.tp' in mem # read-only source material
assert 'file_ = directory /' in mem
assert 'file_ = resource_ / L"LReaParams" / L"Tracks" / L"Track CC Map.tp"' not in mem
assert 'void load(const std::filesystem::path& resource, const std::string& projectFilename)' in h
assert 'fixedCc_ = memory_.fixedEnabled()' in track
assert 'memory_.setFixedEnabled(true)' in mid and 'memory_.setFixedEnabled(false)' in mid
assert 'void TrackMemory::setFixedEnabled' in mem and 'LReaParams.MidiSettings' in mem
assert 'name == "LReaParams.MidiSettings"' in profile
assert 'ccParameterSuffix() + (currentEnvelopeActive() ? ". Auto" : "")' in track
assert 'CC channel ' in track and 'return ccParameterSuffix()' in track
assert 'k.vk == VK_SPACE && !k.shift && !k.alt' in track
assert 'Main_OnCommand(40044, 0)' in track and 'Main_OnCommand(40073, 0)' in track
assert 'interceptTransport(message)' in router
assert '(k.ctrl && !k.alt && !k.shift && k.vk == VK_DELETE)' in track
assert '(f1 && k.vk == VK_DELETE)' in track # Ctrl+Shift+Delete is now deselect all
assert 'LReaParams: FX Params (native test)' not in ext
assert 'LReaParams: Track Params (basic native controls)' not in ext
assert 'LReaParams: Track Memories (future)' not in ext
assert 'tmAgain.load(trackRoot, savedProject)' in unit
assert 'tmAgain.fixedEnabled()' in unit and 'tmAgain.ccLink' in unit
assert 'Unrelated projects with the same name' in unit
assert 'Project save stole legacy import target' in unit
print('TEST54.1 project .tp, persistent Fixed CC, speech/transport and compatibility source contracts PASS')
