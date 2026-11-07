# LReaParams 0.0.65 TEST65.1.1 — GitHub Actions fix

## Failure reproduced from build log (November 7, 2026)

The `build-windows` job stopped before CMake at `Testing/test65_release_keyboard_static.py:23` with `AssertionError: Do not ship a stale index.xml in the source ZIP`.
The ReaPack workflow intentionally commits `index.xml` into `main` after a release, while the distributed source archive intentionally omits it. Thus the CI checkout includes a valid `index.xml` even when the source archive did not.
A second test, `test65_1_reapack_release_automation_static.py`, had the same invalid requirement.

## Fix

Both static tests now allow the generated catalog to be present in a Git checkout and validate its XML package identity and DLL release links. They also work when `index.xml` is absent. New TEST65.1.1 tests both cases, as well as rejecting malformed XML. The existing Git-sync `.cmd` and ReaPack release workflow remain unchanged; there is no need to delete the index from GitHub.

The public version remains **0.0.65**. TEST65.1.1 is a development build. No release tag or ReaPack publish event is created by a source push.

## Usage

Copy source files over the local repo; run `Tools\push_lreaparams.cmd "TEST65.1.1 Fix CI tests with generated ReaPack index"`. It preserves the remote-generated `index.xml`, commits, rebases, and pushes.

The source ZIP omits `index.xml` intentionally, but `main` will continue tracking it. After pushing, verify the `Build LReaParams Windows x64` job reports **Success**. Test the resulting DLL in REAPER before publishing a new stable release.
