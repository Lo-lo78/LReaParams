> Documento storico TEST30. Per stato attuale e limiti prevalgono Status.md e FxCommandMatrix.csv.

# TEST21 — Outside F7 commands and Master/Monitor FX title

## Keyboard tests in REAPER + NVDA

1. On Master regular FX, check NVDA+T says `FX Params - Master - plugin`. On Monitor FX, check `FX Params - Monitor FX - plugin` and Ctrl+Up/Down retains correct area.
2. Ctrl+B twice on Track, Master, Monitor and Take FX: expect `Bypassed` then `Enabled`; title suffix appears only while bypassed.
3. Ctrl+D twice on a supported FX with a REAPER Delta wrapper: Delta Solo on/off. On unsupported plugins, no other FX parameter may be altered.
4. Ctrl+Shift+D with Delta Solo active on multiple FX; check all project FX. Repeat with none active: expect the short message `No Delta Solo` when the wrappers can be detected. The native clear action is still executed if available, including nested FX. Native host action lookup first, fallback by wrapper when unavailable.
5. Tab outside F7 alternates spoken `Plugin Order` and `Custom Order` according to Ctrl+L. F3 says Grid, Step, slot type.
6. Alt+G cycles Groups / Memory positions and the chosen access mode is retained per plugin in the .fx profile. Ctrl+G and Ctrl+M continue to select explicitly.
7. F5/F6/F9 follow Lua's native REAPER commands 40280, 40281, 40282.
8. Enter F7, select a few items: Tab still announces the selection count.
9. Verify unmodified F10, Alt+F10/F11/F12, and Ctrl+Shift+B are not swallowed by the new FX shortcuts.

## Limitations

- The C++ source is not compiled in this environment. Runtime integration with OSARA and the REAPER FX Chain is unverified.
- Delta Solo's control is accessed only if the final REAPER FX wrapper parameter is explicitly named `Delta` or `Delta Solo` (English). Localized names can require adaptation. The host's project-wide native action is found by its English Action List description; if lookup fails, the fallback scans Master/Monitor, Track/input, and all Take FX but not nested FX containers.
- Only existing F7 core behaviors are preserved; this update does not claim to complete every Lua function.
