"""TEST56.6: source-only FX Params style F4 layout; no local native build."""
from pathlib import Path
p=Path(__file__).resolve().parents[1]
main=(p/'src/TrackNavigatorFxTcp.cpp').read_text()
nav=(p/'src/TrackNavigator.cpp').read_text()
h=(p/'include/lrp/TrackNavigator.h').read_text()
lst=(p/'src/TrackNavigatorFxTcpList.cpp').read_text()
w=(p/'.github/workflows/build-windows.yml').read_text()
# 8-high parameter grid belongs to one FX only: no parameter from another FX.
assert 'void TrackNavigator::moveFxTcpGrid(unsigned int key)' in main
assert 'const int first = (index / 8) * 8;' in main
assert 'const int last = std::min(count - 1, first + 7);' in main
assert 'if (index + 8 < count) next += 8' in main
assert 'if (index >= 8) next -= 8' in main
assert 'moveFxTcpGrid(k.vk);' in main
assert 'Grid column ' in main and 'row ' in main
assert 'void moveFxTcpGrid(unsigned int key)' in h
# The same track / FX switching keys as FX Params.
assert 'if (k.ctrl && k.shift && !k.alt && (k.vk == VK_UP || k.vk == VK_DOWN))' in main
assert 'if (k.ctrl && !k.shift && !k.alt && (k.vk == VK_UP || k.vk == VK_DOWN))' in main
assert 'moveFxTcpColumn(k.vk == VK_UP ? -1 : 1)' in main
assert 'if (k.ctrl && !k.shift && !k.alt && (k.vk == VK_PRIOR || k.vk == VK_NEXT))' in main
assert 'moveFxTcpFx(k.vk == VK_PRIOR ? -1 : 1)' in main
assert "(k.vk == VK_UP || k.vk == VK_DOWN || k.vk == 'A')) return true;" in nav
# Ctrl+Home/End travels to first/last parameter; Alt changes value in Grid and Value.
assert 'moveFxTcpRow((k.vk == VK_HOME ? 1 : count) - fxTcpRow_)' in main
assert 'Alt+Home/End ALWAYS changes the value' in main
assert 'writeFxTcpValue(k.vk == VK_HOME ? 1.0 : 0.0)' in main
assert 'if (k.vk == VK_RETURN && k.alt && !k.ctrl && !k.shift)' not in main
assert 'openFxTcpParameterGrid(true)' not in main
assert 'if (k.alt && !k.ctrl && !k.shift && k.vk == VK_RETURN)' in main
# Header has been retired; Alt+Enter opens the names-only grid from any F4 cell.
assert 'if (!k.repeat) { rebuildFxTcp(true); openFxTcpParameterGrid(false); }' in main
assert 'if (currentFxTcpParameter()) {' in main
assert 'setFxTcpParameterVisible(fx, param, false)' in main
assert 'fxTcpListGridHeight_' in h and 'commitFxTcpParameterGrid(k.ctrl)' in lst
# This layout is preserved; TEST56.7 also normalizes FX Params' reordering keys.
assert 'test56_6_static.py' in w
print('TEST56.6 source contract PASS; MSVC/REAPER/NVDA not executed')
