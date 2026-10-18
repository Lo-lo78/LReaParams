# TEST56.9.1 — F4 Fixed MIDI CC: persistence and focus-loss correction

## Reproduced failure in source (TEST56.9)

F4 learns the right CC event using `Ctrl+Alt+C`, constructs a scoped identity
`FxTcp|{trackGUID}|{fxGUID}|nativeParameterIndex`, then calls
`TrackMemory::setFixedCcLink()`. Both the TrackMemory setter **and the project
profile parser** previously accepted only `Track|{...}` and `Sends|{...}` identities. The resulting `ProfileError`
escaped the tick callback; Extension handled it by stopping navigation.
This explains the return of focus to REAPER TCP and the missing learned CC.
`Ctrl+T` in F4 had the same identity rejection in `setFixedCcSpeech()`.

## Changes

- Accept structurally valid F4 CC identities in both writers while preserving
  the existing Track and Send identity formats. Update the `.tp` parser for the
  same schema. Reject malformed GUIDs, trailing fields and native parameter
  indices over 32767.
- Save F4 Fixed CC and opt-in CC speech in the **same project `.tp`**. Existing
  mappings and other sections remain untouched; no migration or new file.
- If a future storage failure happens while learning, report the failure in
  NVDA and **keep Track Params open**. Restore the in-memory mapping on failure,
  rather than letting a storage exception terminate the navigator.
- Add native ProfileTests for two independent FX instances, reload, deletion,
  default-Off speech, and malformed identities. Add source regression check
  to GitHub Actions.

## Manual REAPER / NVDA test after GitHub Actions

1. In F4 select a TCP parameter of ReaEQ and press `Ctrl+Alt+C`.
2. Move a physical MIDI CC once. NVDA should say `CC learned...` and **remain
   within F4** (not return to REAPER TCP).
3. Use Tab on the parameter: the CC should be shown. Move the controller through
   pickup, and confirm the FX parameter changes. A different FX stays unaffected.
4. Exit and re-enter Track Params, then restart REAPER and reopen the same
   project. The Fixed CC must persist in the project's `.tp`.
5. Press `Ctrl+T` on the same parameter, verify opt-in speech works and persists.
6. In Track Memories (`Ctrl+Shift+M`), verify the mapping; `Ctrl+Delete` on F4
   removes only that CC. The Floating CC mode must behave as before.

**No local compilation or C++ tests performed.** Run MSVC build and CTest
exclusively via GitHub Actions; test MIDI and NVDA in REAPER.
