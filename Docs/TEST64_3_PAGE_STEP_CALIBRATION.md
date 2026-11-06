# TEST64.3 — Page Up / Page Down calibration

User report: Page Up/Down increments could be much smaller than Up/Down arrows on FX combos; raising the per-parameter Step by +4 was needed to obtain a comparable change.

Root cause in `FxNavigator::nudge`: the FX-supplied `large` increment was accepted without verifying it exceeded the `normal` increment. Keyboard and Standard Value already shared `nudge`.

Fix: One pure step-sizing helper is used by both navigation modes. When valid `large > normal`, keep the FX-specified large step. Otherwise derive the coarse increment as `min(1, 10 * normal)` with existing fallback normal=0.001, page=0.01. The user Step multiplier `2^scale` is applied *once* to either path. No new Keyboard key handling or shortcuts.

Manual test: use a stepped combo with a low Step value, press Up, then Page Up at the **same Step**. Verify that Page Up is at least as effective as Up, without increasing Step. Verify the same result in Standard Value and Keyboard. Re-test Page Down, numeric sliders, toggles, and iZotope RX readback. F7 multi-parameter editing retains its previous step behavior.

This is experimental: MSVC/GitHub Actions and real NVDA/REAPER testing are pending.
