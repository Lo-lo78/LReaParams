"""0.0.48 FX per-parameter Step + optional CC speech source contracts.

Source-only, no C++ compilation. Runtime behaviour must be verified in REAPER.
"""
from pathlib import Path
from version_contract import version_at_least

root=Path(__file__).resolve().parents[1]
assert version_at_least(root,(0,0,48))
nav=(root/'src/FxNavigator.cpp').read_text(encoding='utf-8')
order=(root/'src/FxNavigatorOrder.cpp').read_text(encoding='utf-8')
advanced=(root/'src/FxNavigatorAdvanced.cpp').read_text(encoding='utf-8')
mem=(root/'src/FxNavigatorMemories.cpp').read_text(encoding='utf-8')
ctx=(root/'src/FxNavigatorContexts.cpp').read_text(encoding='utf-8')
header=(root/'include/lrp/FxNavigator.h').read_text(encoding='utf-8')
legacy=(root/'Legacy/Speak FX Params - TrackTake Navigator.lua').read_text(encoding='utf-8')

assert 'param_step_scales_v1' in legacy and 'cc_param_speech_v1::' in legacy
# The native 21-level scale must not overwrite the Lua 18-level source data.
assert 'lrp_param_step_scales_v1' in order
assert 'param_step_scales_v1' in order
assert 'luaStepMultipliers[]' in order and 'std::log2(factor)' in order
assert 'const auto wanted=stepParameterName(param);' in order
assert 'return originalName(track_,take_,fx_,param);' in order
assert 'if(matchCount>1)return 0;' in order
assert 'fxOrder_.setExtraValue(nativeParamStepsKey,data);' in order
assert 'if(!fxOrder_.save())return false;' in order
assert 'void FxNavigator::syncParameterStep()' in order
assert 'stepScale_=savedStepForParameter(parameter_);' in order
assert 'loadParameterSteps();' in order
assert 'if(parameterStepsDirty_)stageParameterSteps();' in order
assert 'parameterStepsDirty_=false;' in order
# No disk write on every value nudge: write only when leaving a changed param,
# switching FX/context, or closing the navigator.
assert 'syncParameterStep();\n    auto& state = ensureContextMemory();' in nav
assert 'flushParameterSteps();\n        flushPersistentPosition();' in nav
assert 'flushParameterSteps();\n    flushPersistentPosition();' in ctx
assert 'flushParameterSteps();\n        // end() is noexcept' in nav
assert 'markParameterStepChanged();rememberPosition();' in nav
assert 'markParameterStepChanged();rememberPosition();' in mem
assert 'columns_=10;stepScale_=0;markParameterStepChanged();' in nav
assert 'if (!fxBrowserMode_) syncParameterStep();' in nav
# CC speech is per parameter and must never disable normal Grid speech.
assert 'cc_param_speech_v1::' in advanced
assert 'void FxNavigator::queueCcSpeech' in advanced
assert 'midiPendingSpeech_=param==parameter_?value:' in advanced
assert 'if(midiSpoken_[param]==formatted)return;' in advanced
assert 'CC speech on. ' in advanced and 'CC speech off. ' in advanced
assert 'midiSpoken_.erase(parameter_);midiPendingSpeech_.clear();' in advanced
assert 'void FxNavigator::announce()' in nav
assert 'editF7_ ? editorParameterSpeech() : currentParameterSpeech()' in nav
# Prevent accidental retirement of Parameter Library or C++ compilation here.
assert '"LREAPARAMSFXMEMORIES"' in (root/'src/Extension.cpp').read_text()
print('0.0.48 per-param Step + Ctrl+T MIDI speech source contracts PASS (no compilation)')
