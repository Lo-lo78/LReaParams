# LReaParams 0.0.67 — Independent FX Grid and Step resets

This release promotes the user-tested TEST66.2 changes. It includes everything in 0.0.66, including Keyboard mode, calibrated Page keys, RX 11 readback, 14 independent FX grids, group/parameter persistence, FX/Track accessibility, and the existing ReaPack release automation.

## What changed in FX Params

- **Backspace** resets the selected parameter to its default (unchanged).
- **Ctrl+Backspace** resets only the Step for the selected parameter.
- **Shift+Backspace** once resets only the current Grid size to 10 columns.
- **Shift+Backspace** twice quickly opens a native accessible Grid size edit, accepting whole numbers from 1 to 400. Enter confirms; Escape cancels. The first press is delayed to disambiguate single and double press; a double press does not reset the Grid first.
- **Ctrl+Shift+Backspace** again resets all plugin parameters, as in public release 0.0.66.
- **F3** remains unchanged: "Grid 10. Step 0. Group slots" or "Memory slots" according to Alt+G / Alt+M. This status is deliberately preserved.

## Preservation and publishing

All 14 independent grids and their per-context persistence, stored `.fx` profiles, plugin memories and historical ReaPack releases remain unchanged. The extension uses the exact existing profile keys and data format.

The `build-windows.yml` workflow compiles and packages a versioned **0.0.67** installer and matching source archive after a push. Only after that build succeeds should a new stable GitHub release `v0.0.67` be published and the **0.0.67** installer ZIP be attached. The `publish-reapack.yml` workflow then runs on `release: published`, builds the standalone DLL from the release tag and regenerates `index.xml` from all published releases. Its automatic index commit on `main` is expected; it does not delete old ReaPack versions. Do not force-push or overwrite the historical index.

Static tests and guide consistency must pass; the Windows native build and installer require GitHub Actions, and final accessibility verification requires REAPER plus NVDA/OSARA.
