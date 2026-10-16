"""TEST41 source-only contract. Execute without compiler/REAPER."""
from pathlib import Path
root=Path(__file__).resolve().parents[1]
fx=(root/'src/FxNavigator.cpp').read_text(encoding='utf-8')
adv=(root/'src/FxNavigatorAdvanced.cpp').read_text(encoding='utf-8')
start=fx.index('std::string FxNavigator::currentParameterSpeech() const {')
end=fx.index('std::string FxNavigator::editorParameterSpeech() const {',start)
body=fx[start:end]
assert 'displayName() + ", " + formattedValue()' in body
assert 'parameter_ >= 0 && parameter_ < count_' in body
assert 'envelopeActive(parameter_)' in body
assert 'spoken += ". Auto"' in body
assert 'return spoken;' in body
assert 'speech_(editF7_ ? editorParameterSpeech() : currentParameterSpeech());' in fx
assert 'return valueMode_ ? "Value, " + currentParameterSpeech() : currentParameterSpeech();' in fx
assert 'speech_(formattedValue());' in fx
assert 'GetEnvelopeStateChunk(env,buffer.data()' in adv
assert 'thread_local std::vector<char> buffer(4*1024*1024);' in adv
assert 'void FxNavigator::navigateEnvelope(int direction)' in adv
assert 'if(target!=viewPos_)positionChanged(target);' in adv
print('TEST41 Auto suffix routing and read-only envelope contract PASS — native/runtime not run')
