TEST61.1 / 0.0.61: Corrected three stale source-only Python tests which expected the pre-TEST61 Track Params page layout. No C++ behavior changes. GitHub Actions still needs to run the actual native build.

TEST61 / 0.0.61: FX Params F10 browser/grid replaces Ctrl+P; F11 hosts the moved 128-channel audio pin connector (Track/Take/Monitor); Track Params F5/F6/F7 replace previous F6/F7/F8 with one-time .tp cursor migration. Direct OSARA Peak Watcher actions for Alt+F10/F11/F12 (+Shift). No local compilation.

TEST60 (0.0.60): scorciatoie condivise Marker + Transport (FX/Track) senza alias F4, senza rimappare Ctrl+Page e Ctrl+frecce. Fonte Lua invariata. Compilazione SOLO GitHub Actions.

TEST59 / LReaParams 0.0.59: native Track Params F8 ReaRoute migrated from the original Lua. Separate track input, output creation, 11-row per-output grid; native send routing APIs, Undo, project .tp cursor memory, and physical/virtual output isolation in F7. No F4 aliases/manual sorting and no transport key remapping. SOURCE ONLY. Compiled and tested only by GitHub Actions; no local native build.

TEST58 / LReaParams 0.0.58: Track Params F7 Hardware Outputs migrated in C++ (11-row columns, native REAPER hardware routing, Undo, persistent navigation); F6 backslash and silent-edge refinements. No local compilation or build, source only for GitHub Actions.

TEST56.10.1: Removed redundant Ctrl+S two-stage Audio Pin Connector routing, including pending origin state, its helper and announcements. Enter/Space and Delete continue to edit the actual selected matrix cell with REAPER API readback and Undo. No local compilation; GitHub Actions only.

TEST56.9.1: Correct F4 Fixed MIDI CC persistence. The TrackMemory writer AND native .tp parser now recognize scoped FxTcp identities; this fixes exceptions on first learn that closed the navigator and returned focus to REAPER TCP. Added focused error handling, native regression tests and GitHub Actions source check. Floating MIDI unchanged. No local compilation; MSVC and CTest run through GitHub Actions.

TEST56.9: Final F4 cleanup. Ctrl+E accessible numeric editor with formatted host values when monotonic, raw host units fallback, FX GUID checks, no duplicated confirmation speech. Ctrl+Shift+T now controls F4 keyboard value announcements; discrete host step alignment and conservative JSFX integer fallback. F4 aliases and manual order intentionally excluded. Builds only through GitHub Actions; no local C++ compilation.

TEST56.8: F4 MIDI CC Fixed per TrackGUID/FXGUID/parameter, Floating, pickup, Ctrl+T speech off by default, Track Memories and project .tp persistence; Ctrl+Q background MIDI. No local native compilation; GitHub Actions only.

TEST56.7: F4 headerless 8-row TCP parameter grid; Alt+Enter opens names-only add grid from anywhere; unified Ctrl+PageUp/Down moves FX in both Track F4 and FX Params; FX browser Ctrl+Shift+Up/Down changes tracks without leaving browser. Source only, GitHub Actions build; no local C++ build.

TEST56.6: F4 compact FX Params-style grid; one FX at a time, 8 rows per parameter column, Ctrl+Up/Down FX, Ctrl+Shift+Up/Down track, Alt+Shift+Up/Down physical FX move. Ctrl+Home/End navigates; Alt+Home/End changes value. Alt+Enter visible-control editor retired; Delete removes a TCP control. No local C++ build; GitHub Actions only.

TEST56.4 F4 parameter filtering, concise Value speech and per-FX visible TCP grid.
No native compilation performed. Build using GitHub Actions.
LReaParams 0.0.56 — TEST56.2: F4 names-only parameter grid, Ctrl+Enter TCP toggle, Enter commit, F1/F2 grid height. Builds only via GitHub Actions; no local native compilation. Parameter Library excluded.

TEST56.5: Source-only changes for REAPER F4 FX controls. GitHub Actions is the sole build environment; local native build not executed.
