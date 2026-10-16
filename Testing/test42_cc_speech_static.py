"""0.0.42.1 source-only contract: CC precedes Auto, F8 unchanged."""
from pathlib import Path
r = Path(__file__).resolve().parents[1]
fx = (r/'src/FxNavigator.cpp').read_text(encoding='utf-8')
adv = (r/'src/FxNavigatorAdvanced.cpp').read_text(encoding='utf-8')
hdr = (r/'include/lrp/FxNavigator.h').read_text(encoding='utf-8')
mem = (r/'src/FxNavigatorMemories.cpp').read_text(encoding='utf-8')
start = fx.index('std::string FxNavigator::currentParameterSpeech() const {')
end = fx.index('std::string FxNavigator::editorParameterSpeech() const {', start)
body = fx[start:end]
assert body.index('currentParameterCcSpeech()') < body.index('envelopeActive(parameter_)')
assert 'if (!ccSpeech.empty()) spoken += ". " + ccSpeech;' in body
assert 'spoken += ". Auto"' in body
assert 'return spoken;' in body
assert 'std::string currentParameterCcSpeech() const;' in hdr
assert 'std::string FxNavigator::currentParameterCcSpeech() const {' in adv
assert 'fxOrder_.ccLinks.find(parameter_)' in adv
assert 'parseLink(link->second, channel, number)' in adv
assert '"CC channel " + std::to_string(channel) + " CC " + std::to_string(number)' in adv
assert 'floatingCc_ || floatingWaiting_' in adv
assert 'param." + std::to_string(parameter_) + ".learn.midi1' in adv
assert 'TakeFX_GetNamedConfigParm(take_, fx_' in adv
assert 'TrackFX_GetNamedConfigParm(track_, fx_' in adv
assert 'std::string(c_str())' in adv   # documented CC0 safety
assert 'fxOrder_.ccLinks' in mem
assert 'speech_(editF7_ ? editorParameterSpeech() : currentParameterSpeech());' in fx
assert 'return valueMode_ ? "Value, " + currentParameterSpeech() : currentParameterSpeech();' in fx
assert 'speech_(formattedValue());' in fx
assert any('project(LReaParams VERSION 0.0.'+v in (r/'CMakeLists.txt').read_text() for v in ('42.1','43','44'))
print('TEST42.1 CC-before-Auto accessible speech source contract PASS; runtime not tested')
