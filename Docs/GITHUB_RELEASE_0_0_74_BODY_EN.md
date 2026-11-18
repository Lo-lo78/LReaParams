# LReaParams 0.0.74 — Parameter Ranges and Floating MIDI CC

**18 November 2026 · Windows x64 · REAPER native extension**

## New and improved

- **Alt+R:** individual minimum and maximum for the selected FX or Track parameter, including Volume. The parameter Step remains independent.
- **Alt+C:** individual MIDI CC input range (0–127), available only when a fixed CC is already assigned and enabled for that parameter.
- **Alt+F:** floating CC range (0–127) shared across FX Params and Track Params for the current REAPER session only. Nothing is written to disk for the floating CC.
- Accessible Minimum / Maximum / OK / Cancel dialogs return you to the same parameter with either confirmation or cancellation.
- **Shift+C:** disabling the fixed CC map restores the learned floating CC and announces its channel and controller number; enabling fixed CC reports the assignment count.
- Track Params MIDI value changes now update NVDA readback immediately, with value-only MIDI speech when enabled.
- Added **Parameter Ranges** in memories; customized fixed CC limits appear alongside CC mappings. Removed the old volume-specific Ctrl+Shift+I and Volume Ranges column.

## Installation

Download the **LReaParams 0.0.74 Windows x64 installer** attached to this release. Exit and restart REAPER after installation. The source and accessible guides are included.

## ReaPack

The stable GitHub release activates the existing separate ReaPack publishing workflow. It builds the native `reaper_lreaparams.dll` and updates `index.xml` from all eligible release versions without rewriting historical tags or removing earlier versions.

Project: https://github.com/Lo-lo78/LReaParams
