> Documento storico TEST30. Per stato attuale e limiti prevalgono Status.md e FxCommandMatrix.csv.

# TEST15 — Track navigation speech and unified FX Value (0.0.16)

Source only: build by GitHub Actions. No local CMake, MSVC, nor binaries.

## Track Params

- F1: Left/Right or Home/End changes parameter on the SAME row: announce only
  `Parameter, value` (example: `Width, 100 percent`).
- F1: Up/Down, Page Up/Down, Ctrl+Home/End changes track row: announce
  `Track name, Parameter, value` (example: `Track 3, Width, 100 percent`).
- F2/F3: navigating parameters on a fixed track uses `Parameter, value`.
- NVDA+Up (WM_GETTEXT on the keyboard owner, on demand) reads the FULL
  current track, page/send context, parameter and value. Ctrl+R explicitly
  speaks that same full context.
- Enter on Volume/Pan/Width still enters native slider; Mute/Solo/Phase
  still toggle directly; all other controls retain their TEST14 behavior.
- Altering a value still announces ONLY the formatted value.

## FX Params

- Enter is aligned with Track Params: Value mode announces the same review
  line and requests the same real Win32 trackbar (TRACKBAR_CLASSW) and focus.
- The shared TitleProxy now refreshes the native parameter label only when
  it CHANGES, and keeps the current position synced without text-change
  notifications for every value edit.
- Escape/Enter return to Grid with the same full context announcement as
  Track Params. The FX title, track-session memory and actual parameter
  editing algorithms remain unchanged.

## Essential NVDA + REAPER manual checks

1. Track Params F1 move Left/Right and Up/Down: verify concise versus full
   spoken context. Use NVDA+Up without changing track to review full context.
2. FX Params: Enter on a Pro-Q 4 parameter; Windows native slider should
   own focus and NVDA+Up should retrieve parameter and formatted value.
   Compare behavior with Track Params Volume (same native control).
3. FX Params: Enter again, and Escape to Grid; focus must return to Grid.
4. Both modes: ALT+Up/Down and Value arrows speak value ONLY, not two messages.
5. Switch FX and tracks, check NVDA+T and per-track session FX memory.
6. F2/F3 no sends or receives: page entry remains blocked. Toggle controls
   must continue to respond directly to Enter.

Note: We cannot verify actual NVDA's Windows role/speech without running
REAPER with OSARA on Windows; this needs testing after Actions produces the DLL.
