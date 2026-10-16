# 0.0.44.4 — Persistent last parameter per FX profile

Following the original `Speak FX Params - TrackTake Navigator.lua`, the navigator
now saves `LastParam=<physical-or-virtual-index>\t<accessible-parameter-name>`
in `REAPER/LReaParams/Plugins/<plugin>.fx` when leaving FX Params or switching
FX/track. `LastParam` is stored **per plugin definition**, as in the Lua: the
position remains available after restarting REAPER, even months later.

The 0.0.44.3 session memory still has priority while REAPER remains open:
per-instance FX GUID, grid, step and duplicated-entry position remain unchanged.
Only when there is no per-instance session position does FX Params read `LastParam`
from the plugin profile and rebuild the visible grid at the remembered parameter.

Position-only saves update just the LastParam line, preserving all other bytes
of the `.fx` payload, including Custom Order, groups, CC links, default snapshots
and extensions unknown to C++. Before overwriting an existing profile the DLL
checks its loaded SHA-256 and stores a backup under
`LReaParams/Backups/ProfileEdits`. It stages and validates the replacement
before atomically replacing the original. An externally changed or read-only
profile is not overwritten. No write is performed on each keypress.

A parked background MIDI context is not allowed to overwrite the foreground
navigator's remembered position upon its later shutdown.

## Manual NVDA / REAPER test (after GitHub Actions build)

1. Open FX Params on ReaComp, move to `Detector Highpass`, exit navigation.
2. Close REAPER. Reopen it (or a different project with the same plugin) and
   open FX Params: it should start at `Detector Highpass`.
3. Navigate to `Ratio`; close FX Params, switch to another plugin and back.
   It should recall the per-instance session position.
4. Close/restart REAPER and reopen ReaComp: it should recall `Ratio`.
5. Repeat with virtual ReaEQ controls and Monitor FX; test Custom Order.
6. Verify F7 groups, CC, Auto, defaults, and Ctrl+Space still work unchanged.
7. Inspect `.fx`: only LastParam should change as a result of navigation.

The SDK build and native profile tests run **only in the user's GitHub Actions**.
No CMake, MSBuild, Visual Studio or local compilation is performed.
