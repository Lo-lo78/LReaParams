TEST56.9: Final F4 cleanup. Ctrl+E accessible numeric editor with formatted host values when monotonic, raw host units fallback, FX GUID checks, no duplicated confirmation speech. Ctrl+Shift+T now controls F4 keyboard value announcements; discrete host step alignment and conservative JSFX integer fallback. F4 aliases and manual order intentionally excluded. Builds only through GitHub Actions; no local C++ compilation.

TEST56.8: F4 MIDI CC Fixed per TrackGUID/FXGUID/parameter, Floating, pickup, Ctrl+T speech off by default, Track Memories and project .tp persistence; Ctrl+Q background MIDI. No local native compilation; GitHub Actions only.

TEST56.7: F4 headerless 8-row TCP parameter grid; Alt+Enter opens names-only add grid from anywhere; unified Ctrl+PageUp/Down moves FX in both Track F4 and FX Params; FX browser Ctrl+Shift+Up/Down changes tracks without leaving browser. Source only, GitHub Actions build; no local C++ build.

TEST56.6: F4 compact FX Params-style grid; one FX at a time, 8 rows per parameter column, Ctrl+Up/Down FX, Ctrl+Shift+Up/Down track, Alt+Shift+Up/Down physical FX move. Ctrl+Home/End navigates; Alt+Home/End changes value. Alt+Enter visible-control editor retired; Delete removes a TCP control. No local C++ build; GitHub Actions only.

TEST56.4 F4 parameter filtering, concise Value speech and per-FX visible TCP grid.
No native compilation performed. Build using GitHub Actions.
LReaParams 0.0.56 — TEST56.2: F4 names-only parameter grid, Ctrl+Enter TCP toggle, Enter commit, F1/F2 grid height. Builds only via GitHub Actions; no local native compilation. Parameter Library excluded.

TEST56.5: Source-only changes for REAPER F4 FX controls. GitHub Actions is the sole build environment; local native build not executed.
