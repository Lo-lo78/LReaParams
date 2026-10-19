# TEST61.5 — Native guides and About (source-only)

The two supplied Lua HTML guides (FX Params 0.346, Track Params 0.184), their original Lua sources, and the 0.0.61 TEST61.4 native C++ project were compared to migrate end-user documentation. The unrelated Stretch Marker script and Parameter Library are excluded.

## Outputs

- `Guide/index.html`: native accessible guide index.
- `Guide/LReaParams - FX Params.html`: FX grid, edit/memory, fixed/floating MIDI CC, A/B Compare F8, browser F10, Audio Pin Connector F11, track/take/monitor contexts, 128-channel pin routing.
- `Guide/LReaParams - Track Params.html`: all native F1–F7 pages, TCP parameter chooser, Track MIDI F5, Hardware F6 and its Add column usable even with zero hardware outputs, ReaRoute F7, project `.tp` scope.
- `src/Extension.cpp`: refreshed user-visible About message, matching the new page/shortcut layout and linking readers to guide files.
- GitHub Actions: second artifact containing the HTML guides; existing DLL artifact is unchanged.

This change adds documentation and revises the About text only. It does **not** modify the navigator engine, audio pin mappings, track routing, profiles, CC/automation behavior, ReaRoute logic, or CMake. No C++ compilation or REAPER/NVDA runtime validation has been performed. The GitHub Actions workflow remains responsible for compilation and native tests.
