# LReaParams 0.0.64 — release notes (2026-11-06)

## iZotope RX 11: updated values spoken correctly

In iZotope RX 11 modules, REAPER can accept a parameter change before the plugin's formatted text has refreshed. Earlier LReaParams versions could announce the preceding slider or combo-box value on a change, while reviewing the parameter afterwards showed the correct new value.

LReaParams now reads the settled formatted value back for versioned RX plugins before speaking. The parameter write itself remains immediate. This applies to Alt+arrows, Alt+Page Up/Down, Alt+Home/End, Value mode, parameter reset, F7 selected-parameter changes and direct numeric editing. New edits replace old pending speech; moving to a different parameter, FX or context cancels obsolete announcements. The tiny delay is restricted to RX; other plugins retain immediate feedback.

This release is based on **TEST63.1**, which the project owner successfully tested with iZotope RX 11 in REAPER and NVDA/OSARA. A slight speech latency was observed and considered acceptable. This does not establish compatibility with every RX module, version, or host configuration.

## Release consistency / compatibility

- 0.0.64: About dialog, CMake version, Windows x64 NSIS EXE/ZIP artifact names, and English/Italian/Spanish/French/Russian/Simplified Chinese/Japanese HTML guides.
- The existing FX/Track functions, keyboard commands, `.fx` and `.tp` profiles, ReaPack URL and installer settings are unchanged. No old presets are converted.
- `Testing/test63_1_rx_delayed_speech_static.py` remains in the Windows build workflow; version consistency and installer tests are updated to 0.0.64.
- **Before publication**: the GitHub Actions Windows MSVC build, CTest suite and installer artifact should be green; confirm the released tag `v0.0.64` points to that commit.
- After publishing a **non-prerelease** GitHub Release, `.github/workflows/publish-reapack.yml` builds the DLL from the release tag, uploads `reaper_lreaparams.dll` to the release, and updates `index.xml` on `main` after successful compilation and tests. Uploading an EXE installer ZIP manually is optional and does not trigger indexing by itself.

See `Docs/TEST63_1_RX_SPEECH.md` and prior `Docs/RELEASE_NOTES_0_0_63.md`.
