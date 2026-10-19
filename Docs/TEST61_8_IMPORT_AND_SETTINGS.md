# TEST61.8 — Accessible import and Settings

## Existing command IDs (unchanged)

- `_LREAPARAMSIMPORTLEGACY`: LReaParams: Import legacy profiles.
- `_LREAPARAMSSETTINGS`: LReaParams: Settings (Keyboard Input).

## Import

The DLL **no longer imports TXT files automatically** in `Extension::init`.
If TXT files are present in the historical Lua Plugins/Tracks or the active LReaParams Plugins/Tracks folders, on the first REAPER start with this version a native modal dialog asks the user once:

- **Y** / Yes: start the verified legacy converter on a worker thread; no native profile overwritten; originals in the historical scripts directory left intact; active-folder TXT removed only after backup, conversion and marker verification.
- **N** / No: no files touched.
- **Escape**: cancel, treated as No at startup.

At startup the choice is recorded in `REAPER resource path/LReaParams/Settings/LegacyImportChoice.txt` so a declined import does not pop up on every launch. The action still runs at any time and always asks before writing. Without TXT files, the startup prompt is skipped, while the manual action reports that nothing was found.

To see the startup question again intentionally, remove the choice marker after closing REAPER; a new question will appear on next launch only if legacy TXT files still exist. This marker does not store profiles.

## Settings

The old `MB_YESNOCANCEL` box was misleading: Windows localizes the labels (Sì/No), while its explanatory body was English. The replacement uses named options:

1. **1:** REAPER SDK accelerator + Escape-only hook (recommended, default).
2. **2:** Main-thread WH_GETMESSAGE hook (compatibility).

**Escape** keeps the current setting. The change is session-only; no permanent configuration or plugin parameters change. All buttons are standard Windows accessible Task Dialog buttons with stable English labels; unmodified Y/N or 1/2 keys are intercepted only in their respective modal dialog. Tab, arrows, Enter and Alt+button mnemonics remain available.

## Verification

- Run GitHub Actions MSVC compilation and `ctest`.
- In NVDA, check that Y/N works regardless of the Windows language.
- Decline startup import, reopen REAPER, confirm no second prompt, then run the manual action and approve.
- Change Settings to 2, close and reopen REAPER, confirm default 1 restored.
- Check old source TXT files remain, backup files are present, and existing native profiles are unchanged.
- Confirm that Ctrl+Shift+Alt+A and the FX Memories default-delete confirmations still use Y/N.

No native compilation or REAPER runtime executed locally.
