"""Source-only contract checks for TEST21; never compile or invoke REAPER."""
from pathlib import Path
r=Path(__file__).resolve().parents[1]
s=(r/'src/FxNavigator.cpp').read_text()
h=(r/'include/lrp/ReaperApi.h').read_text()
for marker in ('context = "Monitor FX"','fxWindowTitleBase()',
  'toggleBypass()', 'toggleDeltaSolo()', 'clearProjectDeltaSolo()',
  'deltaParameter(', '"No Delta Solo"', '"Clear delta solo for all project FX"',
  'k.vk==VK_F3', 'k.vk==VK_F5', 'k.vk==VK_F6', 'k.vk==VK_F9',
  'runLuaFunctionAction(k.vk==VK_F5?40280:k.vk==VK_F6?40281:40282)',
  '"Custom Order":"Plugin Order"', 'chooseSlotAccess(', '"Memory positions"',
  'k.vk==VK_F10', 'k.vk==VK_F11', 'k.vk==VK_F12'):
  assert marker in s, marker
assert "((k.vk=='B' && !k.shift)||k.vk=='D')" in s
assert '#define REAPERAPI_WANT_Main_OnCommand' in h
assert 'project(LReaParams VERSION ' in (r/'CMakeLists.txt').read_text()
print('TEST21 source contract PASS — no native build')
