# LReaParams 0.0.65 — Keyboard theme and Value step calibration

## FX Params: optional Keyboard theme (from TEST64.1–64.3)

The Keyboard theme is an alternative *working interaction* for FX Params, not an F7 configuration interface. Every plugin has 14 independent saved theme choices in its existing `.fx` profile: Plugin Order, Custom Order, and Group 1 through Group 12. **F4** changes only the current context between Standard and Keyboard; this is immediate and does not change the selected parameter or its Step. Navigating to a different context or FX restores that context's saved choice, defaulting to Standard for existing profiles.

The 36 keys `1 2 3 4 5 6 7 8 9 0`, `Q W E R T Y U I O P`, `A S D F G H J K L`, and `Z X C V B N M` select parameters by their existing deterministic order. Empty positions are **silent** and preserve the current selection. **Alt+Up/Down** changes 36-parameter blocks and selects the first parameter of the new block. **Up/Down, Page Up/Down, Home/End** adjust the selected parameter, and **Left/Right** adjust Step, as in Standard Value. Page Up/Down's coarse increment is validated against the arrow increment: if the plug-in's declared large increment is invalid or smaller, a larger fallback is derived from the normal increment (TEST64.3). The same adjustment engine serves Standard Value and Keyboard.

All other original shortcuts remain active, including **Ctrl+B** bypass, **Ctrl+Shift+D** Delta, **Ctrl+Page Up/Down** FX move, **Ctrl+Up/Down** FX navigation, F7, F8, automation, numeric edit and MIDI commands. **F7 is always Standard**. Track Params, FX Browser, Memory dialogs and text entry are unchanged.

## Existing iZotope RX compatibility

Retains the RX-family deferred formatted-value readback from 0.0.64: the parameter changes immediately, while spoken updated values may follow with a brief delay. Older pending announcements are cancelled when necessary. No new RX-specific DSP behavior is introduced.

## Build, compatibility and publication

- Public version: **0.0.65** in CMake, About, NSIS installer/EXE metadata, Windows Actions artifacts and all seven HTML-guide languages.
- User `.fx` and `.tp` profiles, FX order, group entries, default values and REAPER projects are preserved. Theme preferences are an optional profile key; missing keys mean Standard.
- The Windows GitHub Actions build runs version/installer/keyboard/step/RX regression checks, then MSVC compilation, CTest and NSIS packaging. Inspect its output before release.
- Publishing a **stable** GitHub Release with tag `v0.0.65` triggers the existing ReaPack workflow, which compiles a matching standalone `reaper_lreaparams.dll`, attaches it and regenerates `index.xml` if successful. The installer ZIP can be attached manually to the release, independently.

This release source is prepared from TEST64.3. Final MSVC build and REAPER/NVDA/OSARA release validation must be confirmed on Windows before publication. TEST64.1–64.3 are described in Docs/TEST64_1_KEYBOARD_THEMES.md and Docs/TEST64_3_PAGE_STEP_CALIBRATION.md.
