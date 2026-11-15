# Preferences - experimental source test based on 0.0.69

New REAPER action: `LReaParams: Preferences` (`_LREAPARAMSPREFERENCES`).
The old `LReaParams: Settings (Keyboard Input)` (`_LREAPARAMSSETTINGS`) is untouched.

The window has three columns:
1. Shortcuts: one shortcut followed by its purpose. Navigate the list, Tab into the shortcut input, press the new chord; Escape cancels capture. Changes are staged until OK. Duplicate keys and reserved gestures are rejected. The initial catalog provides 32 common mapped gestures (NOT yet every conditional shortcut). Some core gestures (Escape, bare F12, transport-specific keys) are not remappable. Changes to a chord only apply when FX/Track Params owns the keyboard.
2. Messages: Space cycles between FX-before-track (default) and track-before-FX. The preview uses the LB-303/bass example. FX Params/FX Memories title and FX context-switch speech honor the order.
3. Keyboard input: Space cycles the REAPER SDK and compatibility hook. This new Preferences setting is persistent; the pre-existing single-purpose Settings action still applies per session.

Saved only upon OK into `<REAPER resource path>/LReaParams/Preferences.ini`.

IMPORTANT: Not compiled locally: Windows MSVC and REAPER SDK environment is required. Test in GitHub Actions before release. The shortcut catalog is an initial group, not an exhaustive inventory, and the runtime remapper needs in-REAPER validation across text fields, browser, FX Memories and F7.

Suggested checks:
- Default title is `FX Params - VST3i: LB-303 (Lo-lo) - bass`.
- In Messages, Space changes the order; Cancel leaves order unchanged. OK persists after REAPER restart.
- In Keyboard input, Space changes the backend; OK persists after restart.
- Change Ctrl+F to Ctrl+Y; after OK Ctrl+Y invokes Search and Ctrl+F no longer invokes Search in the navigator.
- Cancel another shortcut change, restart: previous assignment remains.
- When native EDIT receives typing, no unwanted accelerator translation occurs.
- The older `_LREAPARAMSSETTINGS` still chooses backend for the current session.

## TEST fix: source audit for the Preferences dialog

The first GitHub Actions run was stopped at `Tools/audit.py` by
`RuntimeError: Unexpected window creation: Preferences.cpp`, before MSVC compilation.
`Tools/audit.py` now permits **only** the explicit, user-invoked native
`Preferences.cpp` dialog in addition to the pre-existing `TitleProxy.cpp`
window. It checks the expected number of window/child creation sites and
the modal lifecycle markers; creation remains forbidden in all other modules.
The original `Tools/push_lreaparams.cmd` and the ReaPack `index.xml` are unchanged.
This is a source-audit fix, not proof of successful compilation or runtime behavior.

## TEST fix: Windows MSVC Preferences.cpp compilation

The next GitHub Actions run passed the source audit but MSVC stopped at
`Preferences.cpp(13,27): error C2059: syntax error: constant`.
The local modifier bit flags previously declared as `MOD_ALT` and `MOD_SHIFT`
collided with predefined Windows SDK macros. Renamed the internal flags to
`kPrefCtrl`, `kPrefAlt` and `kPrefShift` throughout Preferences.cpp.
The stored bitfield layout (Ctrl=1, Alt=2, Shift=4) remains unchanged.
The Win32 child control identifiers now cast through `INT_PTR` before `HMENU`
to avoid MSVC warning C4312 on 64-bit Windows.
This patch has not yet passed a Windows MSVC compilation; the GitHub Actions
workflow remains the authoritative confirmation.
