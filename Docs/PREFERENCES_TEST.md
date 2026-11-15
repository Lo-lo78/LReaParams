# LReaParams 0.0.69 TEST — Preferences tree and focus

The action `LReaParams: Preferences` (`_LREAPARAMSPREFERENCES`) opens a
native Windows preferences window. It does **not** replace the old
`LReaParams: Settings (Keyboard Input)` (`_LREAPARAMSSETTINGS`): the old
settings action continues to work independently for the current session.

## Tree and speech

The focus starts on the native TreeView. There is no introductory speech
static and no `Active` prefix on page labels. Native Windows/NVDA selection,
level, and position announcements are left to the TreeView. Tree items are
created once; no renaming or re-insertion occurs on Up/Down.

The hierarchy (Shortcuts initially expanded) is:

- `Messages` (level 0, initial selection)
- `Shortcuts` (level 0)
  - `FX Params` (level 1)
  - `Track Params` (level 1)
- `Advanced` (level 0)

Up/Down moves through the visible tree nodes in that order. Left/Right may
collapse/expand the Shortcuts branch using ordinary Windows TreeView behavior.
Selecting either child changes the shortcut list immediately without moving
keyboard focus out of the tree. Selecting the parent `Shortcuts` uses the last
FX/Track selection, initially `FX Params`.

## Tab / Shift+Tab and shortcuts

Tab cycles: `Tree -> selected page contents -> OK -> Cancel -> Tree`.
Shift+Tab goes backwards through exactly the same controls. In Shortcuts,
there is no FX/Track combo: selecting either child of the tree and pressing
Tab goes **directly to its shortcut list**. This is intentional, leaving
room to add further keymap families as child nodes.

The list displays each assigned key before its function description. Enter
or double-click opens a capture field for a replacement gesture. Escape from
the capture cancels *only* that capture and returns to the key list. Regular
Tab while capturing exits capture to the tree. The keymap still uses
independent FX and Track assignments; duplicate mappings within a single
keymap are refused. The first 32 shortcut indices from the earlier
Preferences TEST are preserved so existing `Preferences.ini` values remain
addressable.

After modifying a shortcut, **OK**, **Ctrl+Enter** or **Alt+O** commits the
whole Preferences session and writes `Preferences.ini` under the REAPER
resource path's `LReaParams` directory. **Cancel**, **Alt+C**, or **Escape**
cancels without any disk write. Ctrl+P from FX Params or Track Params opens
Preferences and is reserved, not remappable.

## Messages and Advanced

Messages offers `Plugin - Track` (default) and `Track - Plugin`. These are
generic, not hard-coded examples from a project. Space cycles and the
selected choice is marked `Active` *within the choices*, not in the tree.

Advanced offers `1 - REAPER SDK accelerator (recommended default)` and
`2 - Main-thread keyboard hook (compatibility)`. Space cycles and the
selected choice is marked `Active` inside the list. Alt+1/Alt+2 also select
the backend. The choice is committed only after OK, and persists across
REAPER sessions via `Preferences.ini`.

## Windows task switching and modal focus

The owner is disabled while the modal dialog is visible, then re-enabled
after OK or Cancel. The internal message loop now only applies dialog key
translation to messages targeted at the Preferences window or its children;
it does not intercept other REAPER window messages. Alt+Tab messages keep
their normal system handling. When the user returns to Preferences, it
restores focus to the last visible control, falling back to the tree. This
focus repair is conditional on Preferences being foreground to prevent
stealing focus from a different application.

## Manual acceptance checks (Windows + NVDA + OSARA)

1. Open Preferences: hear `Messages`, not "Choose a page...".
2. Down: `Shortcuts` level 0; Down: `FX Params` level 1; Down: `Track Params`
   level 1; Down: `Advanced` level 0. No `Active - Shortcuts` or repeated
   previous tree entry should be announced.
3. On each shortcut child: Tab immediately opens the correct list. More
   Tabs go to OK, Cancel, and tree. Shift+Tab reverses without error tones.
4. Alt+Tab to another Windows app and return, both when focused on the tree
   and when focused on a shortcut list/OK: arrows/Tab work **immediately**,
   without the extra Tab previously needed to unlock the dialog.
5. Change a shortcut and OK, reopen, and restart REAPER: saved. Change
   another and Escape: unchanged. Repeat in both FX and Track scopes.
6. Confirm Ctrl+P still opens Preferences and the old keyboard-only Settings
   action continues to work separately.

## Release safety

The project remains a **0.0.69 TEST**. The original
`Tools/push_lreaparams.cmd` and `.github/workflows/publish-reapack.yml`
remain unchanged, and `index.xml` is not included. Publish sources only
using `Tools\push_lreaparams.cmd "Commit message"`, never with force-push or
manual changes to the ReaPack index.

`python Tools/audit.py` is source-only; an actual Windows/MSVC build and
NVDA/REAPER runtime tests are required before claiming success.
