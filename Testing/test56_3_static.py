"""TEST56.3: F4 value navigation and TCP grids. Static only; do not compile here."""
from pathlib import Path
p=Path(__file__).resolve().parents[1]
h=(p/'include/lrp/TrackNavigator.h').read_text(encoding='utf-8')
n=(p/'src/TrackNavigator.cpp').read_text(encoding='utf-8')
f=(p/'src/TrackNavigatorFxTcp.cpp').read_text(encoding='utf-8')
g=(p/'src/TrackNavigatorFxTcpList.cpp').read_text(encoding='utf-8')
w=(p/'.github/workflows/build-windows.yml').read_text(encoding='utf-8')
assert 'k.vk == VK_RETURN && k.alt && !k.ctrl && !k.shift' not in f  # retired
assert 'openFxTcpParameterGrid(true)' not in f  # use Delete in F4
assert 'if (k.vk == VK_F6 && !k.ctrl && !k.shift && !k.alt) return;' in f
assert 'fxTcpListVisibleOnly_ = !fxTcpListVisibleOnly_' not in g
assert 'k.vk == VK_F6 && !k.ctrl && !k.shift && !k.alt) return;' in g
assert 'std::iswalnum' in f and 'fxTcpSearchCharacter(k)' in g and 'k.shift' in f and 'k.shift' in g
assert "k.shift && k.vk >= '0' && k.vk <= '9'" in f
assert 'fxTcpInitialMatch' in f and 'CP_UTF8' in f
assert 'parameterName' in h and 'parameterName, letter' in g
assert 'writeFxTcpValue' in f and 'nudgeFxTcpValue' in f
assert 'TrackFX_SetParamNormalized' in f and 'TrackFX_EndParamEdit' in f
assert 'fxTcpParameterVisible(column->fxIndex, param->index)' in f
assert 'std::memcmp(currentGuid, &column->guid, sizeof(GUID)) != 0' in f
assert 'memory_.step(fxTcpStepKey())' in f and 'memory_.setStep(key, next)' in f
assert 'if (page_ == Page::fxTcp)' in n and 'currentFxTcpParameter()' in n
assert 'python Testing/test56_3_static.py' in w
print('TEST56.3 static contracts PASS; native build and REAPER/NVDA runtime pending')
