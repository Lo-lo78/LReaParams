# Preferences - TEST tree navigation for LReaParams 0.0.69

Action List: `LReaParams: Preferences` (`_LREAPARAMSPREFERENCES`).

The existing `LReaParams: Settings (Keyboard Input)` (`_LREAPARAMSSETTINGS`) has not been changed. Its selection is session-only; Advanced in Preferences stores the selection across restarts.

## Page tree and keyboard

The Preferences dialog opens **with focus on the native Win32 TreeView**. There are three sibling items, in this order:

1. `Active - Messages` (initial page)
2. `Shortcuts`
3. `Advanced`

The currently selected item always receives the `Active - ` prefix; the other two do not. Up/Down change the page without shifting focus away from the tree.

Tab/Shift+Tab form a closed loop for the active page:

- Messages: `Tree -> message choice -> Tree`.
- Shortcuts: `Tree -> FX Params / Track Params combo -> shortcut list -> Tree`.
- Advanced: `Tree -> keyboard input choice -> Tree`.
- Shift+Tab follows the same path in reverse, including Tree -> last control of the selected page.

The dialog retains native OK and Cancel buttons. **Ctrl+Enter** saves and closes from page controls; **Alt+O** activates OK; **Alt+C** or **Escape** cancels. All changes, including shortcut remappings, are pending until OK. The extension writes its preferences only after the dialog successfully returns an accepted result.

## Messages

The choices are generic, no project/plug-in names:

- `Active - Plugin - Track` (default)
- `Track - Plugin`

Space cycles and Up/Down select. `Active - ` moves to the selected choice. The actual FX Params title and context announcements use the chosen order; the example text is not taken from a user project.

## Shortcuts

Tab from the tree focuses a **native combo** for choosing **FX Params** or **Track Params**. Tab again focuses the list of shortcuts for that navigator; a third Tab returns to the tree. Shift+Tab travels backwards.

Each item starts with its current keyboard gesture, followed by ` - ` and a description. **Enter or double-click** a selected item opens a native key-capture field. Press the intended key combination, then return automatically to the shortcut list; Escape from key capture cancels only that capture. Tab without Ctrl/Alt in capture returns directly to the tree (no change).

The list follows the 0.0.69 source: Backspace resets a parameter, Ctrl+Backspace the step, Shift+Backspace the grid (double press opens grid size), and Ctrl+Shift+Backspace resets the whole FX. The list includes the original mappings plus additional navigation, F7, FX browser, group/memory slots, Track routing, Track selection, marker and MIDI/automation gestures supported by the native navigators. Some gestures are context-dependent and use the same chord in multiple pages; they appear once per FX/Track navigator. This is not a separate per-subpage keymap. Keys belonging to native text EDIT controls are not remapped. Escape, bare F12, REAPER transport Space/Ctrl+Space, the NVDA Insert modifier, and OSARA peak-watcher Alt+F10..F12 are protected.

FX Params and Track Params have independent assignments. The same gesture can be mapped differently in those two lists; duplicate gestures within one list are rejected. The first 32 slots retain their original stored indices from the earlier Preferences TEST so previous `Preferences.ini` values remain addressable. More entries are appended after those slots.

## Advanced

- `Active - 1 - REAPER SDK accelerator (recommended default)` (default)
- `2 - Main-thread keyboard hook (compatibility)`

Space cycles, Up/Down selects. Alt+1/Alt+2 are also supported while Preferences controls have focus. No backend switch is committed until OK.

## Save path

`<REAPER resource path>/LReaParams/Preferences.ini`

## Regression/acceptance checks

- On initial open, NVDA should read the first TreeView entry as `Active - Messages`; focus should be on the TreeView, not a listbox.
- Down reads `Active - Shortcuts`; Tab reaches the FX/Track combo; next Tab reaches the shortcuts; next Tab returns to the tree. Shift+Tab is the exact reverse.
- Down again reads `Active - Advanced`, Tab reaches the accelerator selection, Space toggles the Active marker, Tab returns to tree.
- From Shortcuts choose Track Params and remap an ordinary Track-only gesture; verify the FX equivalent is unchanged.
- Enter on an FX shortcut should focus the read-only capture field (not press the OK button). Escape from capture returns to the shortcut list without changing it.
- Make a key change, cancel the dialog, reopen: previous binding must still be present.
- Make a key change, Ctrl+Enter or OK, restart REAPER: new binding must persist and work in the correct navigator.
- Try a duplicate within the same navigator: reject with warning; a gesture assigned in the other navigator does not count as a duplicate.
- Messages preview is generic `Plugin - Track` / `Track - Plugin`; FX Params NVDA+T title uses corresponding order.
- Original Settings action `_LREAPARAMSSETTINGS` still operates independently and is not replaced.
- REAPER MIDI transport, OSARA NVDA shortcuts, native EDIT input, Fx Memories and F7 navigation must not regress.

## Source audit and publish hygiene

`python Tools/audit.py` passes on this tree-navigation source. Native Windows MSVC compilation and REAPER/NVDA testing are still required; the static pass **is not** proof of runtime success.

The project-provided `Tools/push_lreaparams.cmd` and `.github/workflows/publish-reapack.yml` remain byte-identical to the last working Preferences TEST. No `index.xml` is included or overwritten. Keep the existing release number at 0.0.69 until the test is confirmed.
