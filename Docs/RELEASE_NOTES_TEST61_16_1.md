# LReaParams 0.0.61 — TEST61.16.1

## Release highlights

- **14 independent FX grids:** Plugin Order, Custom Order and 12 groups independently remember grid width (F1/F2), parameter and exact occurrence.
- **Persistent FX context:** current group, exact grid position and per-view grids saved in each plugin type’s `.fx` profile; each instance keeps its own memory during the REAPER session.
- **Return from offline:** Ctrl+Alt+B toggles FX offline/online and restores its previous grid and parameter automatically, including delayed-loading plugins (nonblocking checks, up to 90 seconds).
- **Escape from a group:** directly closes FX Params and remembers the group; F7 still closes its own editor first.
- **TEST61.16.1:** fixes an outdated Python static test expectation. No additional runtime C++ behavior changes in this subrevision.
- **This package:** refreshed accessible HTML FX documentation in English, Italian, Spanish, French, Russian, Simplified Chinese and Japanese; updated guide generator.

## Validation and publication

The supplied archive contains **source code**, not a verified compiled installer or DLL. Run the GitHub Actions Windows workflow and review its build, static tests and artifacts before marking the release production-ready. Test the resulting DLL with REAPER, OSARA and NVDA, particularly switching context, restarting REAPER and toggling offline/online.

## Compatibility notes

Existing `.fx` profiles and historical Lua fields remain supported. The `.fx` fallback is shared by plugin type across REAPER restarts, not individually persisted per FX GUID. F7 edit mode is never automatically restored. See `Docs/TEST61_14_PERSISTENT_FX_GROUP.md`, `Docs/TEST61_15_FX_ONLINE_RESTORE.md` and `Docs/TEST61_16_INDEPENDENT_FX_GRIDS.md`.
