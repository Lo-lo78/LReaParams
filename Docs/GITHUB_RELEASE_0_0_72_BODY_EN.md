# LReaParams 0.0.72 — Empty Titles and Explicit Step Saving

**Release date:** 17 November 2026  
**Platform:** REAPER x64 · Windows x64  
**License:** GPL-3.0-only

## What's new

- **Empty titles stay empty.** When every title component is disabled in Preferences, no implicit `FX Params` / `Track Params` caption is forced back in.
- **Alt+S saves the current parameter Step.** Adjustments can be made without automatically replacing the previously stored Step; saving is now an intentional command in the supported FX and Track contexts.
- Retains the independently configurable FX plugin Type/Name components introduced in 0.0.71, with existing shortcuts, preferences and profiles preserved.

## Installation and ReaPack

Use the matching **0.0.72 Windows x64 installer** from this release's attachments. Publishing stable **`v0.0.72`** triggers the existing automated ReaPack workflow: it builds the standalone `reaper_lreaparams.dll` from the exact tag and rebuilds `index.xml` from all eligible stable published releases, retaining previous versions. The `index.xml` file must not be manually replaced.

Source: https://github.com/Lo-lo78/LReaParams
