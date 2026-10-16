"""F7/F8 parity and safety contracts against Lua, source only (no compilation)."""
from pathlib import Path
from version_contract import version_at_least
root = Path(__file__).resolve().parents[1]
assert version_at_least(root,(0,0,47))
mem = (root/'src/FxNavigatorMemories.cpp').read_text(encoding='utf-8')
order = (root/'src/FxNavigatorOrder.cpp').read_text(encoding='utf-8')
fx = (root/'src/FxNavigator.cpp').read_text(encoding='utf-8')
legacy = (root/'Legacy/Speak FX Params - TrackTake Navigator.lua').read_text(encoding='utf-8')
workflow = (root/'.github/workflows/build-windows.yml').read_text(encoding='utf-8')
# Seven ordered Lua management columns, with persisted real slot numbers.
for label in ('Memory positions','Groups','Hidden parameters','MIDI CC',
              'Custom order','Copied parameters','Default values'):
    assert f'"{label}"' in mem
assert 'e.slot=pair.first' in mem
assert 'e.rawPos=pos' in mem
assert 'memoryReturnPosition_=visiblePosition-1' in mem
# The user intentionally chose no Enter for hidden parameters; Delete unhides
# one element without leaving the manager.  Do not adopt the newer Lua Enter.
assert 'if(memoryCol_==2 && !toEdit)' in mem
assert 'case 2: fxOrder_.hidden.erase(entry.param);saveStructure();break;' in mem
assert 'dynamicsVirtualValid(id)' in mem
# F7-from-F8 may select only the four Lua editor-compatible columns.
assert 'if(toEdit && memoryCol_!=0 && memoryCol_!=1 && memoryCol_!=3 && memoryCol_!=4)' in mem
assert 'memoryLoad(true)' in mem
assert 'if(editF7_ && !memoryReturnF7Filter_.empty())applyF7Filter' in mem
# Default Delete must never destroy or regenerate the snapshot without the
# same modal Yes/No confirmation used for Enter. No must be the default.
case = mem[mem.index('        case 6:',mem.index('void FxNavigator::memoryDelete()')):
           mem.index('        default:return;',mem.index('void FxNavigator::memoryDelete()'))]
assert 'defaultConfirm_=true;' in case and 'defaultYes_=false;' in case
assert 'saveDefaultRows({})' not in case
assert 'if(k.vk==\'Y\'||defaultYes_)' in mem
assert 'if(k.repeat)return;' in mem
assert 'if(k.ctrl || k.alt || k.shift)return;' in mem
assert 'if(!resetAllToDefault(false))return;' in mem
assert 'fxOrder_.deleteCustomOrder();' in mem
# Native F7 EDIT fields, selected occurrences, filtered selection and Undo
# remain in the same C++ controller as in 0.0.46.5.
for marker in ('f7OriginalPosition(', 'f7SnakePath_', 'saveUndo()',
               'undoStack_', 'redoStack_', 'doCopy(', 'doPaste(',
               'hideSelected()', 'textEditParam_', 'fxOrder_.groupNames[groupSlot_]'):
    assert marker in order or marker in (root/'include/lrp/FxNavigator.h').read_text(), marker
assert 'nativeTextField()' in (root/'include/lrp/FxNavigator.h').read_text()
for marker in ('function memory_manager_delete_current()',
               'function handle_default_snapshot_confirm_key(char)',
               'function memory_manager_load_current_for_f7()'):
    assert marker in legacy
assert 'python Testing/test47_static.py' in workflow
assert 'Parameter Library' not in (root/'src/Extension.cpp').read_text()
print('TEST47 F7/F8 parity and confirmation safety PASS (source only)')
