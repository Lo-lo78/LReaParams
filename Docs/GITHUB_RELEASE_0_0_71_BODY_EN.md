# LReaParams 0.0.71 — Independent FX Type and Name Titles

**Release date:** 16 November 2026  
**Platform:** REAPER x64 · Windows x64  
**License:** GPL-3.0-only

## What's new

- **FX Params, FX Memories and FX Pin Connector:** split the plugin's title into separate **Type** and **Name** components. **Type is hidden by default**; Name is shown. FX Browser remains unchanged.
- For example, `VST3i: LJuno-116 (Lo-lo)` is announced as `LJuno-116 (Lo-lo)` in the default title.
- Deterministic extraction only of recognized **leading** REAPER FX-type prefixes (VST/VSTi, VST2/VST2i, VST3/VST3i, CLAP/CLAPi, JS/JSFX, DX/DXi, AU/AUi and LV2/LV2i). Unrecognized names are not truncated.
- **Track Params F4 (FX TCP):** independently configurable **Type**, **Name** and **Mode** components. Mode keeps `TCP parameters` / `Add TCP parameters` separate from the FX name.
- **Preferences → Messages:** toggle individual title parts with Space; reorder them with Alt+Up/Down; edit Custom message with Enter. The saved 0.0.70 title layouts migrate while preserving existing user settings and custom text. The new Type element stays disabled unless explicitly enabled.

## Accessibility and compatibility

- Existing native accessible Preferences, Ctrl+P position restoration, independent shortcut maps, track-selection/routing operations, FX Used view, grids, parameter memories and MIDI functionality remain available.
- No changes to existing `.fx`/`.tp` profile formats, previously published tags or historical ReaPack versions.

## Installation and ReaPack

- Use the **0.0.71 Windows x64 installer** from this release's attachments.
- Publishing this stable **`v0.0.71`** release triggers the existing ReaPack workflow, which compiles the standalone `reaper_lreaparams.dll` from the exact release tag and regenerates `index.xml` from all eligible published versions, retaining the previous history.
- Source: https://github.com/Lo-lo78/LReaParams
