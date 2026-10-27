# LReaParams 0.0.62 — GitHub release notes

LReaParams 0.0.62 is the public release of the source lineage TEST61.16.1. The TEST61 labels identify the development/test milestones, not the public product version.

## Highlights

- **Fourteen independent FX grids:** Plugin Order, Custom Order and 12 groups separately remember their F1/F2 width, selected parameter and exact grid occurrence.
- **Restored FX navigation:** each FX instance keeps its context during the session, while the shared plugin `.fx` profile records group, cursor and grid settings as a compatible fallback across REAPER restarts.
- **FX offline/online restoration:** Ctrl+Alt+B returns to the previous FX group and parameter automatically when the same FX goes back online, with nonblocking retry for delayed loading.
- **Predictable Escape:** pressing Esc from a group closes FX Params and remembers the group; F7 editing closes before exiting navigation.
- **Accessible documentation:** updated FX references in seven languages, with the matching generator and a versioned guide index.
- **Release identity:** About, CMake project, NSIS product and Windows file metadata, GitHub Actions package names and included source archive all identify **0.0.62**.

## Compatibility

Existing `.fx` profiles and previous Lua-compatible fields remain supported. Profiles are shared by plugin type across sessions rather than a persistent per-instance/GUID store. The internal `PageLayoutVersion=61`, the historical TEST61 filenames and profile format `Version=2/3` are deliberately unchanged; they are not the public product version.

## Validation before publishing

All **95 source-only regression scripts** and `Tools/audit.py` passed locally on 2026-10-27; detailed results: `Docs/RELEASE_0_0_62_STATIC_VALIDATION.txt`. The source archive does not contain a locally compiled or runtime-verified DLL. Confirm the Windows GitHub Actions build and CTest, then validate the installer and REAPER navigation with NVDA/OSARA. Use release tag `v0.0.62`.

See `Docs/RELEASE_NOTES_TEST61_16_1.md` for detailed TEST61.16.1 history and `Docs/TEST61_14_PERSISTENT_FX_GROUP.md`, `Docs/TEST61_15_FX_ONLINE_RESTORE.md`, `Docs/TEST61_16_INDEPENDENT_FX_GRIDS.md`.
