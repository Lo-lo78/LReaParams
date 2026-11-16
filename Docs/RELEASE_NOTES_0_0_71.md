# LReaParams 0.0.71 — Independent FX Type and Name in accessible titles

**Release date:** 16 November 2026. **Platform:** REAPER x64 on Windows x64. **License:** GPL-3.0-only.

## New: plugin Type and Name as separate title parts

- **FX Params → Preferences → Messages → FX Params:** The title templates for **FX Params**, **FX Memories** and **FX Pin Connector** now have separate **Type** and **Name** elements. The FX Browser title is unchanged.
- **Type is disabled by default; Name is enabled.** For example, `VST3i: LJuno-116 (Lo-lo)` is presented as `LJuno-116 (Lo-lo)` unless Type is enabled.
- **Deterministic extraction:** only recognized REAPER technology prefixes at the beginning of the FX name, followed by a colon, are separated; unknown or unsupported prefixes are not removed. The plugin name itself is not edited in REAPER.
- In the title component list, **Space** toggles fixed elements, **Alt+Up/Down** reorders them and **Enter** edits Custom message where available. Name, Type, Track and any custom message can be arranged independently.

## Track Params F4: FX TCP title

- **Preferences → Messages → Track Params → Title: FX TCP (F4)** now provides **Track Params**, **Track**, **Type**, **Name**, **Mode**, **Custom message**.
- **Type is off by default**, Name and Mode are on. Mode announces `TCP parameters` or `Add TCP parameters` without including the plugin name.
- For example, `Track Params - Track 1 - VST3i: LJuno-116 (Lo-lo) - TCP parameters` becomes `Track Params - Track 1 - LJuno-116 (Lo-lo) - TCP parameters` by default.

## Compatibility and history

- The 0.0.70 INI title layouts for FX and Track F4 are migrated while retaining prior choices, component order and Custom message; Type is not silently activated during migration.
- Existing `.fx` and `.tp` profiles, MIDI, automation, FX/Track keymaps, Used, Grid/Keyboard modes, send/receive routing, the original 0.0.70 Preferences workflow and navigation behavior remain unchanged.
- No historical Git tags, published releases, `index.xml` entries or past release notes have been removed or replaced.

## Distribution

1. Push the source with **`Tools\push_lreaparams.cmd`**. It protects the remote-generated `index.xml`, rebases onto `origin/main` and never uses a force push.
2. After the Windows build is successful, obtain the `LReaParams-0.0.71-Windows-x64-SETUP-EXE` artifact, containing the matching installer.
3. Publish a **stable** GitHub Release with tag **`v0.0.71`**, pointed at the tested commit. Attach only the 0.0.71 installer ZIP; do not republish or move any earlier tag.
4. The existing `release: published` ReaPack workflow compiles the native DLL from that release tag and regenerates `index.xml` from all eligible stable releases. Verify both workflow jobs complete successfully.

The source archive does **not** contain a compiled DLL or installer. The Windows build and screen-reader runtime behavior must be verified through GitHub Actions and REAPER/NVDA/OSARA.
