"""TEST71.2: no fallback titles; Step persistence requires Alt+S (source-only)."""
from pathlib import Path
r=Path(__file__).resolve().parents[1]
pref=(r/'src/Preferences.cpp').read_text(encoding='utf-8')
fx=(r/'src/FxNavigator.cpp').read_text(encoding='utf-8')
order=(r/'src/FxNavigatorOrder.cpp').read_text(encoding='utf-8')
track=(r/'src/TrackNavigator.cpp').read_text(encoding='utf-8')
fxmem=(r/'src/FxNavigatorMemories.cpp').read_text(encoding='utf-8')
trackmem=(r/'src/TrackNavigatorMemories.cpp').read_text(encoding='utf-8')
f4=(r/'src/TrackNavigatorFxTcp.cpp').read_text(encoding='utf-8')
workflow=(r/'.github/workflows/publish-reapack.yml').read_text(encoding='utf-8')
assert 'if (result.empty()) return {};' in pref
assert 'return result; // Fully disabled Track title is intentionally blank.' in pref
assert 'return result; // No hidden fallback when every title part is disabled.' in pref
assert 'if (title.empty()) return {}; // Disabled title means no caption' in fx
assert 'if (pageTitle.empty()) return {};' in track
assert 'const std::string prefix = title.empty() ? "" : title + ". ";' in track
assert 'title.empty() ? currentParameterSpeech()' in fx
assert 'Save current parameter step' in pref
assert "fx(p, L\"Save current parameter step\", 'S', kPrefAlt)" in pref
assert "track(p, L\"Save current parameter step\", 'S', kPrefAlt)" in pref
# Dedicated Alt+S save path for FX (including F7 selection) and Track F1-F3/F4.
assert 'else markParameterStepChanged();' in fx
assert 'if (flushParameterSteps())' in fx
assert 'previewSelectedSteps_.clear();' in order
assert 'previewSelectedSteps_[id]=next;' in order
assert 'pos.stepScale = savedStepForParameter(parameter_);' in fx
assert 'stepScale_=next;lastControl_=LastControl::step;rememberPosition();' in fx
assert "if (k.alt && !k.ctrl && !k.shift && k.vk == 'S')" in track
assert 'memory_.setStep(parameterKey(), stepScale_);' in track
assert 'const double factor = std::pow(2.0, stepScale_);' in track
assert 'memory_.setStep(parameterKey(), 0); stepScale_ = 0; memory_.flush();' not in track
assert 'fxTcpPreviewKey_ = key;' in f4
assert 'fxTcpPreviewStep_ = next;' in f4
assert 'const int now = workingFxTcpStep();' in f4
assert 'memory_.setStep(key, value);' in f4
assert 'memoryPreviewSteps_[e.param]=next;' in fxmem
assert 'memoryPreviewSteps_[id] = next;' in trackmem
assert 'memory_.setStep(id, next);' not in trackmem
assert 'release:' in workflow
print('TEST71.2 empty title and explicit Step persistence source contracts PASS')
