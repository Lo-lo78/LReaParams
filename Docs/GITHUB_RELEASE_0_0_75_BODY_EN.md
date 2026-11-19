# LReaParams 0.0.75 — Accessible Native Render Navigation

**19 November 2026 · Windows x64 · Native REAPER extension**

## New in this release

- Navigate **REAPER's original Render to File dialog** without replacing its interface or changing the rendering workflow.
- **Ctrl+F** finds native Render controls by name. **F3 / Shift+F3** move to the next/previous search match.
- **Alt+letter / Alt+Shift+letter** navigate forward/backward through the assigned native controls, including wrapping cycles for shared letters.
- **Alt+Z** focuses **Sample rate** (**Alt+S** also works).
- **Alt+1 / Alt+2** focus the native **Primary / Secondary** output-format tabs. Native **Ctrl+Tab / Ctrl+Shift+Tab** are preserved.
- Format-specific controls can announce their **Primary / Secondary** context when REAPER exposes that information.

**Safety:** these shortcuts move focus only. They do not start rendering, activate a button, toggle a checkbox or modify render parameters. Continue editing with REAPER's standard keyboard controls. Disabled or unsupported native controls retain normal REAPER behavior.

All earlier FX/Track Params features are retained, including the **0.0.74 parameter ranges and MIDI CC improvements**.

## Installation

Download the **LReaParams 0.0.75 Windows x64 Setup EXE** attached to this release, install, then restart REAPER. Accessible HTML guides are included. See the source repository for the full source and release documentation.

## ReaPack

Publishing this **stable GitHub Release `v0.0.75`** starts the existing ReaPack publishing workflow. It compiles and attaches the standalone `reaper_lreaparams.dll`, then refreshes `index.xml` from **all eligible published releases**. Earlier ReaPack versions and their original tagged guides remain available. This process is automatic after release publication; a source push alone does not trigger it.

Project: https://github.com/Lo-lo78/LReaParams
