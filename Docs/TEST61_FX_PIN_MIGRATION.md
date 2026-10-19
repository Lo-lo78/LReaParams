# LReaParams 0.0.61 — TEST61 — F10 / F11 and Track page migration

## FX Params

- **F10** replaces **Ctrl+P**, which is now completely unassigned within the FX Params navigator. From the parameter grid, F10 opens the internal FX browser. From the browser, F10 loads the selected FX and returns to its parameter grid (same action as Enter). Preserves browser selection, Master/Monitor scope and existing session parameter memory. Ctrl+Page Up/Down still moves the selected FX; Ctrl+Left/Right still navigates item/take.
- **F11** opens the native **Audio Pin Connector** for the current Track FX, Take FX, or Monitor FX (using `TrackFX_*` / `TakeFX_*` APIs). From the FX browser, F11 first selects the focused FX, then opens the pin matrix if a parameter grid is available. FX GUID/context validation is retained.
- Pin matrix: **Left/Right** selects the input/output pin column, **Up/Down** the track channel. Home/End first/last channel, Page Up/Down ±5 channels, Ctrl+Home/End absolute matrix edges. Ctrl+Up/Down and Ctrl+Left/Right find connected cells by column/row, Ctrl+Alt+arrow scans the whole matrix. **Enter/Space** toggles the selected pin; **Delete** disconnects. **Tab** or F11 reviews the current cell. **Escape** returns to the exact FX parameter and Value/F7 state. F10 goes to the FX browser. Silent navigation edges.
- Bank 1: channels 1–64; bank 2: 65–128, indexed with `pin + 0x1000000`, each as low/high 32-bit words. No track channel resizing; current `I_NCHAN` bounds the presented matrix. Undo, host write confirmation, and readback verification of the changed cell are preserved.
- Pin Connector uses the static NVDA review/focus, not the Value slider. No additional profile, files, REAPER FX parameter changes, or duplicate audio-processing code.

## Track Params

- **F1:** Tracks; **F2:** Sends; **F3:** Receives; **F4:** FX TCP; **F5:** Track MIDI; **F6:** Physical Hardware Outputs; **F7:** ReaRoute. F8 is now free in Track Params.
- The previous Track F5 pin page and its C++ module were removed; F4 remains accessible and retains TCP parameter mappings and CC functions. F6 strictly excludes ReaRoute output destinations; F7 owns only ReaRoute outputs. F5 is independent of the FX selection.
- **One-time, idempotent `.tp` cursor upgrade:** copies navigation keys and last page F6→F5, F7→F6, F8→F7, with `PageLayoutVersion=61`. The old Track F5 pin page, if it was the last opened, maps to F4. Values for CC, automation, parameters, memory slots and unrelated sections remain untouched. Keep a backup before the first live test.

## OSARA Peak Watcher

- Alt+F10/F11/F12: watcher 1 reset, channel 1, channel 2. Alt+Shift+F10/F11/F12: corresponding watcher 2 commands. Dispatches original OSARA `_OSARA_` NamedCommandLookup actions, no duplicate speech. Applies to both navigators outside text editing, including FX Pin Connector.

## Manual REAPER/NVDA test

1. On a track with two FX, open FX Params. F10 opens browser, select second FX, F10 returns to parameter grid; Ctrl+P must no longer change navigator mode.
2. From Grid, Value, and F7, F11 enters Pin Connector and Escape restores the prior state. Check the NVDA focus, Tab and native review.
3. Track with 128 channels: test 64, 65, 96, 97 and 128 on input and output; verify changes with REAPER’s native pin matrix, Undo, and ensure no unrelated bit or track channel count changed.
4. Repeat with Take FX and Master Monitor FX; ensure modifications target the correct context.
5. Open Track Params on a copy of an existing project whose `.tp` has F6/F7/F8 cursor memories; check F5 MIDI, F6 hardware, F7 ReaRoute and restoration after reopening. Test F7 with no ReaRoute output and F6 with no physical output.
6. Check the six Alt+F10/F11/F12 combinations with OSARA; F10/F11 **without Alt** keep their FX functions. Repeat from Track Params.
7. Check Ctrl+Page Up/Down FX move and Ctrl+Left/Right item/take unchanged. Try Ctrl+Tab between FX and Track navigators; verify no stale focus or CC context.

**Scope:** source-only. No local native compilation, Visual Studio, MSBuild, CMake, REAPER or NVDA runtime tests performed. GitHub Actions will compile and run native tests.
