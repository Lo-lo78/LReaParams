"""TEST56.8: source-only F4 MIDI contracts, not an MSVC/runtime test."""
from pathlib import Path
r = Path(__file__).resolve().parents[1]
h = (r/'include/lrp/TrackNavigator.h').read_text()
m = (r/'src/TrackNavigatorMidi.cpp').read_text()
f = (r/'src/TrackNavigatorFxTcp.cpp').read_text()
n = (r/'src/TrackNavigator.cpp').read_text()
mem = (r/'src/TrackNavigatorMemories.cpp').read_text()
assert 'identity = "FxTcp|" + owner + "|" + fxGuidString(fx->guid)' in m
assert 'out.fxTcp = true;' in m and 'if (out.fxTcp) return true;' in m
assert 'TrackFX_GetFXGUID(owner, i)' in m and 'target.fxParam >= TrackFX_GetNumParams(owner, i)' in m
assert 'if (target.fxTcp) { applyFxTcpMidi(identity, value, false); return; }' in m
assert 'if (section == "F4" && page_ == Page::fxTcp && track_)' in m
assert 'TrackFX_GetParamNormalized(owner, fx, parameter)' in m
assert 'TrackFX_SetParamNormalized(owner, fx, parameter, next)' in m
assert 'pickup.allows(ccValue, std::clamp(currentValue, 0.0, 1.0))' in m
assert 'memory_.fixedCcSpeech(identity)' in m
assert 'midiFixedIdentity(id)' in m and 'group == "F4"' in m
assert 'if (fxTcpListOpen_) { handleFxTcpParameterGridKey(k); return; }' in f
assert 'midiShortcut(k);' in f and 'k.vk == VK_DELETE' in f
assert 'memory_.setFixedCcSpeech(id, on); memory_.flush();' in f
assert 'result += ccParameterSuffix(); // FX Params contract: CC before Auto.' in f
assert 'if (fxTcpAutomationActive()) result += ". Auto";' in f
assert 'if (k.ctrl && !k.alt && k.vk == \'T\') return true;' in n
assert 'if (k.ctrl && !k.shift && !k.alt && k.vk == VK_DELETE) return true;' in n
assert 'identity.rfind("FxTcp|", 0) == 0' in mem
assert 'fxGuidString(*guid)' not in mem  # each TU has its own helper
assert 'TrackFX_GetFXName(owner, fx, name, sizeof(name))' in mem
# no duplicate MIDI engine or new .tp files: keep shared TrackMemory and pollMidi.
assert not (r/'src/TrackNavigatorFxTcpMidi.cpp').exists()
assert 'void TrackNavigator::pollMidi()' in m
print('TEST56.8 F4 MIDI source contracts PASS (not compiled or run in REAPER)')
