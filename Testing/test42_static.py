"""0.0.42 contracts: source-only, no C++ or Windows runtime invoked."""
from version_contract import version_at_least
from pathlib import Path
r=Path(__file__).resolve().parents[1]
ext=(r/'src/Extension.cpp').read_text()
fx=(r/'src/FxNavigator.cpp').read_text()
advanced=(r/'src/FxNavigatorAdvanced.cpp').read_text()
mem=(r/'src/FxNavigatorMemories.cpp').read_text()
hdr=(r/'include/lrp/FxNavigator.h').read_text()
order=(r/'include/lrp/FxOrder.h').read_text()
api=(r/'include/lrp/ReaperApi.h').read_text()
assert version_at_least(r, (0, 0, 42))
assert 'stopBackgroundMidi, actionCount' in ext
assert 'LREAPARAMSSTOPMIDIBACKGROUND' in ext
assert 'backgroundMidi_ = navigator_' in ext
assert 'backgroundMidi_.prepareBackgroundMidi()' in ext
assert 'parkMidiAndReturnToReaper();' in ext
assert 'SetCursorContext(0, nullptr)' in ext
assert 'REAPERAPI_WANT_SetCursorContext' in api
assert "key.ctrl && !key.shift && !key.alt && key.vk == 'Q'" in ext
assert "k.ctrl && !k.shift && !k.alt && k.vk == 'Q'" in fx
assert 'backgroundMidi_.contextUnchanged()' in ext
assert 'backgroundMidi_.pollMidi();' in ext
assert 'backgroundMidi_.sameMidiFx(navigator_)' in ext
assert 'backgroundMidi_.end();' in ext
assert 'void FxNavigator::prepareBackgroundMidi()' in advanced
assert 'void FxNavigator::sameMidiFx(' not in advanced # actual signature returns bool
assert 'bool FxNavigator::sameMidiFx(' in advanced
assert 'fxOrder_.rebindParamName([this]' in advanced
assert 'rebindParamName(std::function<std::string(int)>' in order
assert 'bool midiRunning() const noexcept' in hdr
assert 'e.label=fxOrder_.label(pair.first)+". Channel "' in mem
assert 'MIDI_GetRecentInputEvent(index' in advanced
assert 'std::vector<Event> pending' in advanced
assert 'if(!state.allows(value,current))return;' in advanced
assert 'if(floatingWaiting_ && !fixedCc_)' in advanced
assert 'fixedCc_=fxOrder_.extraValue("cc_runtime_fixed_map_enabled_v1")' in advanced
assert ext.index('backgroundMidi_.pollMidi();')<ext.index('if (!current_ || !current_->active()) return;')
assert 'Testing/test42_static.py' in (r/'.github/workflows/build-windows.yml').read_text()
assert 'Sleep(' not in advanced and 'CreateThread(' not in advanced
print('TEST42 source checks PASS; MSVC/REAPER/NVDA/MIDI hardware not executed')
