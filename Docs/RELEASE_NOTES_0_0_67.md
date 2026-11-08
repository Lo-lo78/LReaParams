# LReaParams 0.0.67 — Used Parameters and Independent FX Grid/Step Controls

This release promotes the user-tested TEST66.2 and TEST67.1 changes. It includes everything in 0.0.66, including Keyboard mode, calibrated Page keys, RX 11 readback, 14 independent FX grids, group/parameter persistence, FX/Track accessibility, and the existing ReaPack release automation.

## What changed in FX Params

- **Backspace** resets the selected parameter to its default (unchanged).
- **Ctrl+Backspace** resets only the Step for the selected parameter.
- **Shift+Backspace** once resets only the current Grid size to 10 columns.
- **Shift+Backspace** twice quickly opens a native accessible Grid size edit, accepting whole numbers from 1 to 400. Enter confirms; Escape cancels. The first press is delayed to disambiguate single and double press; a double press does not reset the Grid first.
- **Ctrl+Shift+Backspace** again resets all plugin parameters, as in public release 0.0.66.
- **F3** remains unchanged: "Grid 10. Step 0. Group slots" or "Memory slots" according to Alt+G / Alt+M. This status is deliberately preserved.

## New: Used (Usati) virtual FX view

- **Ctrl+Shift+L:** switch between Plugin Order, Custom Order or the current Group and a virtual **Used** list. Press it again to return to the exact previous context and cursor.
- **Automatic collection:** after LReaParams successfully modifies a real parameter, the parameter is recorded once in first-edit order. Further edits preserve its position. Loading a preset or receiving playback automation does not populate Used. Edits performed externally to LReaParams are not monitored.
- **Ctrl+Delete in Used:** remove the selected entry from the list, **not** its FX value, envelope or membership of other groups. If edited again, it will be added at the end.
- **Independent Grid and theme:** Used has its own cursor, Grid and F4 Standard/Keyboard preference. The 14 historic contexts continue to work unchanged; F7 remains Standard.
- **Per-instance persistence:** the list is saved in the REAPER **project** by FX GUID. Save the project to keep it across sessions. It is not saved in global `.fx` profiles, and does not change existing profile keys.
- The label is **Used** in the English speech engine and **Usati** in Italian documentation. Synthetic virtual ReaEQ-only controls are outside the first release's Used collection.

## Preservation and publishing

All 14 historic independent grids and their per-context persistence, stored `.fx` profiles, plugin memories and historical ReaPack releases remain unchanged. The extension uses the exact existing profile keys and data format.

The `build-windows.yml` workflow compiles and packages a versioned **0.0.67** installer and matching source archive after a push. Only after that build succeeds should a new stable GitHub release `v0.0.67` be published and the **0.0.67** installer ZIP be attached. The `publish-reapack.yml` workflow then runs on `release: published`, builds the standalone DLL from the release tag and regenerates `index.xml` from all published releases. Its automatic index commit on `main` is expected; it does not delete old ReaPack versions. Do not force-push or overwrite the historical index.

Static tests and guide consistency must pass; the Windows native build and installer require GitHub Actions, and final accessibility verification requires REAPER plus NVDA/OSARA.
