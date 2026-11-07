# LReaParams 0.0.65 TEST65.1 — Keyboard Page parity and ReaPack

This is a **test build**, not a published stable release. The release stays at v0.0.65 until the next stable version is prepared.

## Parameter adjustment

The separate Keyboard Page Up/Down interception is removed. Keyboard, Standard Value and Alt-adjustment all use the **same single** input branch and `nudge(direction, big)`; `big` comes from `VK_PRIOR`/`VK_NEXT` in that branch. Arrow keys use `big=false`. `parameter_step::amount` and the existing host step calibration are not changed.

The 36-key selection, Alt+Up/Down block changes, F4, all 14 persisted themes, native slider role, RX speech delay and every pre-existing Ctrl shortcut remain untouched. F7 has no Keyboard mode.

## ReaPack release procedure

1. The `Build LReaParams Windows x64` workflow produces the standalone setup artifact on pushes to `main`. Test it in Windows first.
2. A **new stable GitHub Release** with an exact new tag matching `CMakeLists.txt` and the installer ZIP triggers `publish-reapack.yml` on `release: published`. It compiles and uploads the standalone DLL from the tag and rebuilds `main/index.xml`.
3. To repair an existing release if GitHub does not trigger the publishing workflow: use `Publish LReaParams to ReaPack` > **Run workflow** > leave the tag **blank** to publish the latest stable release. An exact `vX.Y.Z` also works. A trailing period is invalid.
4. The `index.xml` file is generated on `main` by GitHub Actions, making the local repository behind after a successful release. To avoid fetch-first push failures, use `Tools\push_lreaparams.cmd "Commit description"` from the repository directory. The script fetches main, preserves the generated XML, commits source changes, rebases and pushes; on conflict it stops without force pushing.

The source ZIP deliberately does not include `index.xml` so it cannot overwrite the published catalog. The release workflow retries up to three times if a concurrent push updates `main` during XML generation.

## Checks

Static Python checks cannot establish the actual Windows key routing, parameter readback timing or GitHub release-event delivery. Verify on REAPER with NVDA and check the two publication jobs for `Success` when publishing a future stable release.
