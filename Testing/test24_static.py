"""TEST24 source contracts only. Native compilation and GUI behaviour NOT verified."""
from pathlib import Path
r=Path(__file__).resolve().parents[1]
nav=(r/'src/FxNavigator.cpp').read_text()
order=(r/'src/FxNavigatorOrder.cpp').read_text()
profile=(r/'src/FxOrder.cpp').read_text()
header=(r/'include/lrp/FxOrder.h').read_text()
assert any('VERSION 0.0.'+str(v) in (r/'CMakeLists.txt').read_text() for v in (25,26,27,28,29,30,31,40,41))
assert 'createCustomOrder()' in order and 'if (!fxOrder_.storedCustomOrder())' in nav
assert 'bool FxOrder::createCustomOrder()' in profile and 'customCreated_' in header
assert 'if(stored)for(int id:order)' in profile
assert 'f7OriginalPosition(viewPos_)' in nav and 'editorParameterSpeech()' in nav
assert 'speech_(editF7_ ? editorParameterSpeech() : currentParameterSpeech());' in nav
assert 'Edit: Custom Order' in order and 'viewPositionSpeech()' in nav and 'viewPositionSpeech()' in order
assert 'textEditParam_=(slotMode_==0)?-1:parameter_' in order
assert 'Press F7 to rename' in nav and 'Open a group to rename' in order
assert 'if (k.ctrl && !k.alt && !k.shift && (k.vk==\'G\'||k.vk==\'M\'))' not in nav
assert 'if (k.ctrl && k.vk == \'G\'' not in nav
assert 'if (k.ctrl && k.vk == \'M\'' not in nav
assert 'applyF7Filter(query);' in nav  # TEST26: filtered grid also outside F7
assert 'applyF7Filter(query)' in nav and 'syncTextControl' in (r/'src/TitleProxy.cpp').read_text()
print('TEST24 source-only contracts PASS; host speech/focus must be tested in REAPER')
