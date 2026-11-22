# LReaParams 0.0.76 — Accessible Render, Shortcut Help & Customizable Messages

Release date: 22 November 2026. Platform: Windows x64, native REAPER extension. Accessible with NVDA and OSARA.

## New in this release

- **Shift+F1 shortcut exploration** in FX Params, Track Params and Render: query LReaParams gestures without triggering commands or losing focus. Press Shift+F1 again to exit. Outside these contexts the key belongs to REAPER.
- **Native Render to File navigation (introduced in 0.0.75):** Ctrl+F searches controls, F3/Shift+F3 navigates results, and Alt+letter/Alt+Shift+letter moves focus without activating controls. Existing Alt+1/Alt+2 tab navigation remains available.
- **Render Shortcuts in Ctrl+P:** discover controls exposed by the current Render configuration, keep automatic keys unless individually overridden, and save only the user's custom bindings. Previously personalized but unavailable controls remain editable.
- **Shortcut management:** Alt+S opens shortcut lookup without executing the queried keys; F1–F12 can be queried or assigned where permitted. Delete resets a single binding; Alt+R opens section reset with No selected, followed by OK to save or Cancel/Escape to discard.
- **Customizable navigator speech:** existing title templates stay intact; FX/Track message entries can be enabled/disabled or customized. `{original}` preserves dynamic content in a custom announcement.

## Compatibility and installation

Previous 0.0.75 native Render navigation, 0.0.74 MIDI CC/range functions, Used parameters, Keyboard view, FX/Track memories and existing `.fx` / `.tp` user profiles are preserved. This release adds no separate Render replacement window.

Download and install the matching **LReaParams 0.0.76 Windows x64 setup** produced by the verified GitHub Actions build. The complete seven-language accessible guide is included in the distribution. Detailed documentation: `Docs/RELEASE_NOTES_0_0_75.md` and `Docs/RENDER_NAVIGATION.md`.

## ReaPack and release history

The existing **Publish LReaParams to ReaPack** workflow starts when this stable GitHub Release is published. It builds the standalone DLL from the exact `v0.0.76` tag, attaches the DLL to this release, and updates the ReaPack index from all eligible published versions, preserving historic releases. Source pushes alone do not update ReaPack. Do not manually overwrite `index.xml` or recreate previous tags. If publishing fails, use the workflow's manual rerun with the existing release tag after diagnosing the error.
