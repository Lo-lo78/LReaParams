# LReaParams 0.0.72 — Empty titles and explicit Step save

**Release date:** 17 November 2026. **Platform:** REAPER x64 on Windows x64. **License:** GPL-3.0-only.

## Changes

- **Truly blank titles:** when every configured title component is disabled, no hidden default `FX Params` or `Track Params` title reappears. This applies across the FX and Track navigation contexts covered by the TEST71.2 source checks.
- **Save Step with Alt+S:** changes to the current per-parameter Step can be previewed without automatically persisting them. Press **Alt+S** to store the current Step intentionally. Covers the main FX/Track navigation and the supported parameter-grid/memory contexts.
- The independent **Type** / **Name** title components from 0.0.71 and existing preferences, projects, profiles and navigation remain supported.

## GitHub / ReaPack publishing without rewriting history

1. Copy sources into the **existing** Git clone, keeping `.git` and the existing local `index.xml` intact.
2. Run `Tools\push_lreaparams.cmd "Release 0.0.72 - Empty titles and explicit Step saving"`. Do not use a force push or `git init`.
3. Verify the Windows Actions build and test the new installer in REAPER with NVDA/OSARA.
4. Publish a stable GitHub Release tagged **`v0.0.72`**, pointed at the tested commit, and attach the matching installer ZIP only.
5. The unchanged automatic `release: published` publisher builds the standalone DLL from the tag and regenerates `index.xml` using all eligible published releases. Confirm both jobs and the historical entries.

**The source ZIP includes neither a compiled DLL nor the generated `index.xml`.** The release and full runtime still require validation on Windows and in REAPER.
