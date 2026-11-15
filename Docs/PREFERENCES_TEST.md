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

The hierarchy (Messages and Shortcuts initially expanded) is:

- `Messages` (level 0, initial selection)
  - `FX Params` (level 1): editable FX window title parts
  - `Track Params` (level 1): editable Track window title parts
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

Tab cycles on Shortcuts and Advanced: `Tree -> selected page contents -> OK -> Cancel -> Tree`.
On Messages: `Tree -> message category (Title) -> title elements -> OK -> Cancel -> Tree`.
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

Messages has its own expanded FX Params and Track Params tree children.
Each child has a message category list (currently `Title`) followed by the
ordered elements that build the native Windows title. FX Title starts with
`FX Params`, `Plugin`, `Track`, and `Custom message`; Track Title starts with
`Track Params`, `Track`, and `Custom message`.

On a fixed title element, **Space** toggles enabled/disabled. The selected row
uses the prefix `Disabled -` only while disabled; enabled rows have no
redundant `Active` prefix. **Alt+Up/Down** moves a row through the title even
when disabled. **Enter** on fixed elements does nothing; **Enter** on `Custom
message` opens a real, labeled Windows edit field. Enter commits the edited
text to the pending Preferences session, Escape cancels that edit only.
Clearing the custom text removes it from the title. Space on `Custom message`
changes nothing: editing is always Enter. Tab from the edit commits and
continues the navigation cycle. **OK** saves all changes, **Cancel/Escape**
closes without saving. Changes are held in the pending state until OK.

Title parts are separate for FX and Track navigators and persist under
`[Messages] FxTitleOrder/FxTitleEnabled/FxTitleCustom` and the analogous
`TrackTitle*` keys in Preferences.ini. Files from older tests with just
`PluginFirst` retain their original Plugin/Track order when upgraded. An
empty title (all parts disabled) falls back to its page name for accessibility.
The FX Memories and Track Memories special titles remain unchanged.

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
2. Down: `FX Params` level 1 (under Messages); Down: `Track Params` level 1;
   Down: `Shortcuts` level 0; then its `FX Params` and `Track Params` children;
   finally `Advanced` level 0. No `Active` prefix or repeated previous node.
3. On a Messages child: Tab goes to `Title`, Tab goes to its elements,
   Tab goes to OK, Cancel, and tree. Shift+Tab reverses without error tones.
   On a Shortcuts child: Tab opens that keymap directly.
4. In Messages/FX Params/Title: disable `FX Params` with Space, reorder
   Plugin and Track with Alt+Up/Down, edit Custom with Enter, then use OK.
   Reopen and restart REAPER; ensure the title persists, including when only
   Plugin is enabled. Repeat on Track Params. Test Cancel and editing Escape.
5. Confirm that original FX/Track memory-manager titles are not affected.
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

## Ctrl+P return to the exact navigator position (next TEST)

There are now **two distinct entry paths**:

* **Ctrl+P inside FX Params or Track Params:** the keyboard input router and
  TitleProxy focus window are suspended, but the navigator is **not ended**.
  The selected track, FX, page, parameter occurrence, value/grid mode, editor
  state, and session memory remain in the existing navigator object. After
  either **OK or Escape**, the same navigation object is reactivated and
  announces its current parameter. REAPER's selected track is not resynced
  during reactivation, and any parked background MIDI state is left alone.
  Editing a text buffer before invoking Preferences must not lose the text.
* **LReaParams: Preferences from the REAPER Action List** when there is no
  active navigator: the dialog opens independently. OK or Escape returns
  to the ordinary REAPER interface (TCP/previous REAPER focus), without
  launching FX Params or Track Params.

The modal event loop blocks normal navigator timer handling while visible;
otherwise it would interpret a hidden TitleProxy window as a lost navigation
session. The previously selected FX/track identity is validated on return.
If it was removed/changed while the dialog was open, navigation closes safely
instead of trying to manipulate a stale parameter.

### Focus and state manual acceptance (Windows, NVDA and OSARA)

1. FX Params: select a non-first parameter inside a group. Ctrl+P, press OK:
   same FX, group, parameter and control mode, ready for the next arrow key.
   Repeat with Escape; no changes should be saved.
2. Track Params: select an F2 send, F4 FX TCP parameter or F7 entry.
   Ctrl+P, Escape or OK: same page and position, with no new call to begin().
3. FX Params/Track Params with focused native Value slider, Grid and native
   search/rename EDIT: repeat, checking native input focus and buffers.
4. Direct Action List launch when no navigator is open: both OK and Escape
   should return to REAPER, not enter either navigator.
5. Change the keyboard backend and press OK from within a navigator:
   re-established input must use the new backend selection. Change a shortcut
   and press Escape: the old shortcut must remain effective.
6. Alt+Tab away and back while Preferences is open; then OK or Escape:
   no focus trap, no forced navigation exit.

`Testing/test69_preferences_resume_static.py` checks source wiring. The real
focus behavior remains a Windows + NVDA runtime acceptance test.

## TEST Preferences: immediate shortcut conflict announcement (15 November 2026)

- Open Preferences > Shortcuts > FX Params, choose a binding and press Enter.
- Press a combination already assigned to **another** FX Params command. OSARA
  announces immediately: `Ctrl+F is already assigned to <command>. Try another shortcut.`
  (actual key and command vary). No confirmation dialog or system beep appears.
- The shortcut capture remains active and the previous binding is unchanged.
  Try a free shortcut, then press OK to commit, or Escape to cancel.
- Repeat in Track Params. The same key is allowed in FX and Track scopes,
  because they are independent navigators.
- Reserved combinations also receive immediate voice feedback without a beep.
- Check that WM_CHAR from the read-only capture control does not generate a
  Windows error sound for either occupied or valid keys.
- Verify Alt+Tab focus restore and Ctrl+P exact-position resume as before.
- OSARA outputMessage is required for the spoken notification; the capture
  field also displays the message without stealing keyboard focus.
