# LReaParams 0.0.66 — Keyboard Page parity and ReaPack CI fixes

## Keyboard Page Up/Down and Value parity

- Keyboard remains an optional theme for each of the 14 independent FX Params contexts, selected with F4. It is not active in F7.
- Removed the separate interception of unmodified Page Up/Down in Keyboard. Standard Value and Keyboard now use the same shared value-adjustment handling, preserving Step calibration, arrow behavior and REAPER parameter semantics.
- The 36 deterministic keys, silent unused positions, Alt+Up/Down page navigation, all Ctrl combinations and normal FX navigation remain unchanged.
- The user's REAPER test confirmed that the TEST65.1.1 interaction behaves correctly.

## CI and ReaPack publishing improvements

- GitHub Actions source-only checks now accept an already-generated `index.xml` on the checked-out repository, as well as a fresh source archive without the XML. Existing indexes are checked for validity, not deleted.
- Git synchronization helper `Tools\push_lreaparams.cmd` retains the remote ReaPack index while integrating local changes and pushing source updates safely.
- Publishing a stable GitHub Release with a matching `v0.0.66` tag triggers `Publish LReaParams to ReaPack`: build/test Windows native DLL, attach it to the release, regenerate and commit `index.xml`.
- The manual repair workflow supports a blank tag to select the latest published stable release; this does not replace the automatic release trigger.

## Compatibility and release process

- About, CMake, NSIS installer metadata, GitHub Actions artifact names and accessible guides in seven languages indicate **0.0.66**.
- Preserves existing profiles, user themes/groups, shortcuts and the iZotope RX family deferred speech correction.
- This archive contains complete **source**, not a compiled EXE or DLL. Push and verify the Windows Actions build before creating the stable release and attaching its installer ZIP. Verify publishing job results after release; do not assume ReaPack succeeded until both jobs report Success.
