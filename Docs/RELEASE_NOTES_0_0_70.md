# LReaParams 0.0.70 — Accessible Preferences, Customizable Titles and Multi-Track Selection

**Release date:** 15 November 2026. **Platform:** REAPER x64 on Windows x64. **License:** GPL-3.0-only.

## New: native, accessible Preferences

- New REAPER action: **LReaParams: Preferences** (`_LREAPARAMSPREFERENCES`). The existing **LReaParams: Settings (Keyboard Input)** (`_LREAPARAMSSETTINGS`) stays available separately.
- Tree navigation: **Messages** (FX Params / Track Params), **Shortcuts** (FX Params / Track Params) and **Advanced**. Tab moves into the selected page and then to OK, Cancel and back to the tree. Shift+Tab moves backwards. The last tree item is remembered for the current REAPER session.
- **Ctrl+P** opens Preferences in either navigator without losing the current FX, track, page, group or parameter; both OK and Escape resume that same position. Launching Preferences directly from REAPER's Action List closes back to REAPER instead.
- **Shortcuts**: independent FX Params and Track Params keymaps, capture new keys, speak occupied combinations immediately without a confirmation dialog, and commit changes only on OK (Ctrl+Enter is also available). The dialog supports Alt+Tab and ordinary Windows focus changes.
- **Messages**: editable title templates. FX Params provides four titles: FX Params, FX Memories, FX Browser, FX Pin Connector. Track Params provides twelve titles: Track F1, Sends F2, Receives F3, FX TCP F4, Track MIDI F5, Hardware outputs F6, ReaRoute F7 and five Track Memories headings. Tab first selects a title, then its component list. Space toggles a fixed component, Alt+Up/Down changes its order and Enter edits the optional custom text.
- **Advanced**: REAPER SDK accelerator (recommended) or main-thread keyboard hook (compatibility), persisted in `LReaParams/Preferences.ini`.

## Track Params: F1 track-selection behavior

- A first **Shift+Up/Down** selects the *current* track, announces "Selected" and does not move. Further Shift+arrow presses extend the selection to adjacent tracks.
- **Shift+Space** adds/removes individual tracks. Ordinary arrows can move the current cursor without discarding an explicit multi-selection, permitting separated groups of selected tracks (for example, 3, 4, 7, 9, 11, 12) for multiple Send or Receive destinations.
- Ordinary arrows with only one implicitly selected track do not announce "Selected" on every move; Tab reports the selected track concisely.

## Compatibility and release history

- Existing `.fx`, `.tp`, Used-project state and earlier per-plugin preferences remain compatible. The old Plugin/Track title-order preference is migrated into the new title layout where applicable.
- FX/Track navigation, the 14 independent FX grids, Keyboard mode, Used in F7 and prior MIDI/routing operations remain available.
- The 0.0.69 and earlier release notes remain unchanged. No existing GitHub tags or historical ReaPack versions are removed or overwritten.
- The original `Tools\push_lreaparams.cmd` is the supported push path. On publishing a **stable GitHub Release tagged `v0.0.70`**, the existing `Publish LReaParams to ReaPack` workflow builds the standalone DLL from that tag and regenerates `index.xml` from **all** eligible published releases. A source push by itself only runs the normal Windows build.

## Installation

Build and test the **0.0.70** Windows x64 Setup with GitHub Actions; attach the matching installer ZIP to the **v0.0.70 stable release**. ReaPack will update automatically after the release publisher succeeds. Never attach an installer from a different version.
