# LReaParams 0.0.70 TEST70.2 — Track Params F4 title Type / Name

This is a test on top of the **0.0.70 official release** and **TEST70.1**;
no public version change is made.

## Preferences

Go to **Messages → Track Params → Title: FX TCP (F4)**.
The title has six independently reorderable elements:

1. Track Params (enabled)
2. Track (enabled)
3. Type (**disabled by default**)
4. Name (enabled)
5. Mode (enabled; either `TCP parameters` or `Add TCP parameters`)
6. Custom message (editable with Enter)

Space enables/disables the selected fixed component; Alt+Up/Down moves it;
Enter edits only Custom message. The dialog's **OK** writes `Preferences.ini`;
Escape/Cancel discards pending changes. The original Ctrl+P return-to-parameter
behavior is unchanged.

`TrackFX_GetFXName` supplies the raw FX name. The same strict, start-of-name
`Type: Name` recognizer used by FX Params splits it without changing the FX
name inside REAPER. Unrecognized prefixes remain in Name, unchanged.

Example default F4 title:

- Before: `Track Params - Track 1 - VST3i: LJuno-116 (Lo-lo) - TCP parameters`
- Now: `Track Params - Track 1 - LJuno-116 (Lo-lo) - TCP parameters`

Enabling Type restores the recognized prefix as a separate movable component.
FX Params, FX Memories and FX Pin Connector retain their existing Type/Name
settings. Other Track Params pages do not contain plugin names and are
unchanged.

## Compatibility / regression

The existing `TrackTitlePage3*` INI keys are retained. Previously saved
four-part F4 layouts are expanded to six: old Name remains part 2,
old Custom remains part 3; new Type (4) defaults off; new Mode (5) inherits
the old page-label setting. Saved ordering and custom text are preserved.
The old prefix checker remains unchanged.

## Manual verification (Windows + NVDA)

1. In REAPER Track Params F4, select a VST3i and check its title contains
   the name but not `VST3i:`; repeat with VST, JS and CLAP.
2. Open Ctrl+P, navigate to Messages → Track Params → Title: FX TCP (F4).
   Press Tab to the elements; check the six rows and Type disabled by default.
3. Toggle Type, reorder, toggle Name, toggle Mode and edit Custom message;
   OK saves and Ctrl+P restores the exact selected parameter.
4. Reopen Preferences and restart REAPER to confirm persistence. Repeat with
   Cancel/Escape to verify pending changes do not persist.
5. Check that both `TCP parameters` and `Add TCP parameters` are presented
   correctly in F4, and that other Track Params titles remain unchanged.
6. Check upgrading an existing `Preferences.ini` with a custom F4 title.

Do not modify `Tools\push_lreaparams.cmd`, ReaPack workflows, or `index.xml`.
To push source safely:
`Tools\push_lreaparams.cmd "TEST70.2: Separate Track F4 FX Type and Name in customizable title"`.
