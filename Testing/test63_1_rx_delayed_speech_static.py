"""TEST63.1: iZotope RX synchronous write / deferred formatted readback contract.

This is a source-only guard. Real RX 11 timing must be tested in REAPER on
Windows with NVDA/OSARA after the GitHub Actions MSVC build.
"""
from pathlib import Path
root = Path(__file__).resolve().parents[1]
h = (root / 'include/lrp/FxNavigator.h').read_text(encoding='utf-8')
fx = (root / 'src/FxNavigator.cpp').read_text(encoding='utf-8')
advanced = (root / 'src/FxNavigatorAdvanced.cpp').read_text(encoding='utf-8')
main = (root / 'src/Extension.cpp').read_text(encoding='utf-8')
assert 'void pollRxValueSpeech();' in h
assert 'struct RxValueAnnouncement' in h
assert 'bool isIzotopeRx() const;' in h
assert 'std::isdigit(static_cast<unsigned char>(name[pos+3]))' in fx
assert 'if(!isIzotopeRx())' in fx
assert 'speech_(prefix + (valueOnly ? formattedValue() : currentParameterSpeech()));' in fx
assert 'pending.beforeNormalized = beforeNormalized;' in fx
assert 'pending.beforeValue = beforeValue;' in fx
assert 'elapsed < 65' in fx
assert 'pending.matchingSamples < 2' in fx
assert 'elapsed < 300' in fx
assert 'if(elapsed < 750) return;' in fx
assert 'sample != pending.beforeValue' in fx
assert 'pending.project = project_' in fx and 'project_ != pending.project' in fx
assert 'pending.track = track_' in fx and 'track_ != pending.track' in fx
assert 'pending.take = take_' in fx and 'take_ != pending.take' in fx
assert 'pending.parameter = parameter_' in fx and 'parameter_ != pending.parameter' in fx
assert 'pending.fxGuid = fxGuid_' in fx and '!same(&fxGuid_, pending.fxGuid)' in fx
assert 'rxValueAnnouncement_.active = false; // Never announce the previous FX.' in fx
assert 'rxValueAnnouncement_.active = false;' in fx
assert 'if(!valueKey) rxValueAnnouncement_.active = false;' in fx
assert 'announceParameterWrite({}, true, beforeDisplay, before);' in fx
assert 'announceParameterWrite("Reset. ", false, beforeDisplay, beforeNorm);' in fx
assert 'false, beforeDisplay, beforeNorm);' in fx  # F7 selected values
assert 'announceParameterWrite({}, true, beforeDisplay, beforeNorm);' in advanced
assert 'navigator_.pollRxValueSpeech();' in main
assert main.index('navigator_.pollRxValueSpeech();') < main.index('while (budget-- && input_.pop(key))')
assert 'Sleep(' not in fx[fx.index('void FxNavigator::pollRxValueSpeech()'):fx.index('void FxNavigator::setValue(double value)')]
assert 'if(valueOnly) { speech_(prefix + sample); return; }' in fx
assert 'std::string spoken = displayName() + ", " + sample;' in fx
print('TEST63.1 iZotope RX delayed formatted readback PASS (source-only; REAPER runtime pending)')
