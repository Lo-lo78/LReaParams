# LReaParams 0.0.68 — Used Parameters (Usati)

This release adds the **Used / Usati** FX Params virtual view from TEST67.1 on top of the *already published* 0.0.67 independent Grid and Step release. It preserves all 0.0.67 shortcuts and behaviour.

## What's new

- **Ctrl+Shift+L:** toggle between Used and the previous Plugin Order, Custom Order or Group view, restoring the previous position.
- **Used list:** each real FX parameter is added when successfully modified through LReaParams, in stable first-edit order and without duplicates. Preset loading and playback automation do not populate Used; edits external to LReaParams are not monitored.
- **Ctrl+Delete in Used:** remove only the selected entry, without modifying the value, automation or existing groups. Editing that parameter again appends it to the list.
- **Independent settings:** Used has its own Grid size, cursor and F4 Standard/Keyboard theme. Each FX instance stores its Used list in the REAPER project, keyed by FX GUID. Save the project to retain the collection.
- F7 always remains Standard; the existing 14 contexts and `.fx` profile schema are unchanged. F3 retains Grid, Step, and Group slots / Memory slots information.

## Carried forward from 0.0.67

Backspace: current parameter reset. Ctrl+Backspace: only Step reset. Shift+Backspace: only Grid reset. Double Shift+Backspace: accessible numeric Grid size editor, integers 1–400. Ctrl+Shift+Backspace: reset all plugin parameter values.

## Compatibility and release process

Build **0.0.68** using GitHub Actions, check the new installer and test the Used feature in REAPER. Then publish **one** stable GitHub Release with tag `v0.0.68` on the tested commit and attach the matching installer ZIP. Publishing triggers the existing ReaPack workflow to build `reaper_lreaparams.dll` from the release tag and regenerate `index.xml` from **all** stable releases containing a standalone DLL. The historical 0.0.67 tag and release are preserved, not rewritten.

The source-only tests do not replace the native Windows/MSVC build and real NVDA/OSARA testing.
