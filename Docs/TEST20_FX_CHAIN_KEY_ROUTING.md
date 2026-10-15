# TEST20 — FX Chain P and Ctrl+Shift+P

## Expected behavior

- **TCP/Main:** user assigns `P` to FX Params in the Main Action List; it opens FX Params. User assigns `Ctrl+Shift+P` to Track Params; it opens Track Params. The DLL does not hardcode either chord in TCP.
- **FX Chain native FX list:** `Ctrl+Shift+P` is a dedicated built-in shortcut to open the currently focused FX using FX Params. The only explicit shortcut in the bridge is this chord.
- **FX Chain native FX list:** `P` works only if the user has bound P to the FX Params action in REAPER's Main Action List; no binding, no interception. The bridge attempts to relay other FX Params bindings as well.
- The list must really have focus (control ID 1076, current FX reported by GetTouchedOrFocusedFX); plugin UI, editable fields and other windows are not intercepted.
- The independent REAPER action `_LREAPARAMSTRACKPARAMS` still opens Track Params when invoked outside the FX list. FX Params has its own action.

## Known limitation

No local builds executed. Runtime in REAPER with OSARA, hook priority and recognition of dynamically assigned P or nontrivial Action List bindings must be tested. This version preserves all unrelated FX editor features of TEST19.

## Smoke test

1. In Main Action List assign P to FX Params and Ctrl+Shift+P to Track Params.
2. In TCP press Ctrl+Shift+P: expect Track Params. Press P: expect FX Params.
3. In FX Chain select an FX entry, press Ctrl+Shift+P: expect FX Params for selected FX.
4. In FX Chain select an FX entry, press P: expect the same FX Params (only with Action List assignment).
5. Remove P's Action List assignment: pressing P should no longer invoke LReaParams in the FX list.
6. Test search/edit fields, VST plugin UI, OSARA Shortcut Help and opening an FX Chain on a track not selected in TCP.
