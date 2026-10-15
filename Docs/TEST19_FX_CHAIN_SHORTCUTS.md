> Historical TEST19 design note. **Superseded by `Docs/TEST20_FX_CHAIN_KEY_ROUTING.md` for the current behavior.**

# TEST19 – Action List shortcuts in FX Chain

## Goal

Mirror the context-sensitive idea from OSARA's `OSARA_PARAMS` action:

- A user-assigned shortcut for LReaParams: Track Params opens Track Params
  on the TCP, or FX Params for the current effect when REAPER's FX *list*
  is focused.
- A user-assigned shortcut for LReaParams: FX Params opens FX Params on
  TCP and FX Chain; from FX Chain it targets the FX currently focused in
  that chain, not an effect on an unrelated selected track.
- The IDs `_LREAPARAMSTRACKPARAMS` and `_LREAPARAMSFXPARAMS` remain unchanged.

## Implementation

- REAPER SDK `<accelerator` registered on DLL load and deregistered on DLL
  unload. No new Win32 hooks or system-wide interception.
- Only a focused REAPER FX selection list, native control ID `1076`, is
  eligible. The focused FX must be confirmed via
  `GetTouchedOrFocusedFX(mode=1)` with its stale bit clear. OSARA detects
  this same control in its `src/fxChain.cpp` source.
- Only *keyboard shortcuts actually assigned* to the FX Params or Track
  Params commands in REAPER's Main section may be intercepted, as
  compared via `CountActionShortcuts`, `GetActionShortcutDesc`, and
  `kbd_formatKeyName`. The implementation does not hardcode P or Ctrl+Shift+P.
- Shortcut Help mode in OSARA, editable fields, menus, stale FX references,
  keys with NVDA modifier, unrelated windows, and active LReaParams
  navigation all bypass the bridge.
- A normal Action List invocation of Track Params is also redirected to
  FX Params when the focused FX *list* is confirmed.
- Track/take owner from `GetTouchedOrFocusedFX` gets precedence over
  selected tracks/items when opening FX Params from the FX list.

## Important limitations (TEST19 is an experiment)

- Recognition of user-defined keyboard shortcuts relies on REAPER's text
  descriptions matching its own `kbd_formatKeyName`; alternate naming,
  global scopes, custom multi-stroke bindings or unusual keyboard layouts
  may not match. MIDI/OSC shortcuts are not intercepted.
- Only the effect **list** is targeted. Text input/search widgets and
  embedded VST GUI controls must retain their keyboard input.
- Hook ordering with installed extensions, native FX list key handling,
  focus ownership, and accessibility announcements need an actual
  Windows/REAPER/OSARA test. Static checks cannot confirm these.
- If the accelerator fails to register, the extension declines to load
  rather than silently claiming FX Chain shortcuts work.

## Test in REAPER

1. In Main Action List, map `P` to LReaParams: FX Params and `Ctrl+Shift+P`
   to LReaParams: Track Params. Confirm existing OSARA shortcut conflicts
   are cleared if needed.
2. From TCP, `Ctrl+Shift+P` should open Track Params; `P` FX Params.
3. In FX Chain focus an FX entry using keyboard arrows. Press `P`:
   expected FX Params for the highlighted FX, not merely track FX 1.
4. Return to FX Chain and press `Ctrl+Shift+P`: expected identical FX Params.
5. Open a different track's FX Chain without selecting that track in TCP;
   verify the FX's *owning* track and FX selection are respected.
6. Remove/alter a shortcut in Action List and verify the bridge responds
   only to the current binding, not the old one.
7. On the FX name/search edit fields and within the plugin UI, confirm P
   can be typed normally. F12 shortcut help remains functional.
8. Repeatedly open and exit FX Params; confirm NVDA reads one announcement,
   and REAPER/OSARA retain normal navigation when LReaParams is closed.

No native builds or executable tests were run in preparing these sources.
