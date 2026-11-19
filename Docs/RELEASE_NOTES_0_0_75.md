# LReaParams 0.0.75 — Native Render window navigation

**Release date:** 19 November 2026  
**Platform:** Windows x64 · Native REAPER extension · NVDA / OSARA

## New: faster access to REAPER's native Render to File window

The usual REAPER action **40015** still opens the *original* Render to File dialog. LReaParams adds keyboard navigation only while that native dialog is active:

- **Ctrl+F** opens an accessible control-name search. Enter focuses the first matching visible control, Escape cancels.
- **F3** and **Shift+F3** move forward/backward through search results with wraparound.
- **Alt+letter** moves forward through the controls assigned to that accelerator; **Alt+Shift+letter** moves backward. Shared letters cycle in both directions.
- **Alt+Z** focuses **Sample rate**; **Alt+S** also remains an alias. If the native input is disabled, REAPER must first enable it.
- **Alt+1** and **Alt+2** focus the native **Primary** and **Secondary** output-format tab labels. **Ctrl+Tab / Ctrl+Shift+Tab** remain REAPER-native.
- For a format-dependent control, a short **Primary** or **Secondary** context is announced when its state is available; no context is guessed if it cannot be read.

**Important:** accelerators only move *keyboard focus*. They never press Render, toggle a checkbox, change a sample rate or adjust any render setting. Once focused, use the control's ordinary REAPER keys (Space, Enter, arrows, etc.). Controls disabled by REAPER are not forced into focus. Some codec-specific or custom controls may still require native Tab navigation.

See [Render navigation reference](RENDER_NAVIGATION.md) for detailed keys, caveats and manual acceptance checks.

## Compatibility and preservation

All features previously released in **0.0.74** remain, including Alt+R per-parameter ranges, Alt+C fixed MIDI CC ranges, Alt+F session-only floating CC ranges, their accessible dialogs, memory columns, and Track MIDI announcements. FX Params, Track Params, `.fx` / `.tp` profiles, previous published tags and release assets are not replaced by this release.

The GitHub stable-release publisher is preserved exactly. A published **`v0.0.75`** release triggers the existing workflow, builds and uploads `reaper_lreaparams.dll`, and regenerates the ReaPack index from **all eligible stable published releases** with their tagged guides. Do **not** manually overwrite `index.xml` or delete historical versions. The tested source is committed through `Tools\push_lreaparams.cmd` in the existing local clone.

## Validation

Static/source tests verify Render key handling, version metadata, installer naming, multilingual guide sections and ReaPack preservation. A successful GitHub Actions MSVC build and native CTest are still required before release; verify the native Render UI with NVDA/OSARA on Windows.
