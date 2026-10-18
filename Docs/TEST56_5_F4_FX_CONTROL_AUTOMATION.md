# LReaParams 0.0.56 — TEST56.5 (source-only, GitHub Actions build)

Base: TEST56.4. This iteration does **not** change FX Params, Track Params F1/F2/F3, the project `.tp` layout or the Lua legacy material. No local CMake/MSBuild/CTest/native compile was run.

## New or corrected gestures on the F4 TCP FX grid

- **Alt+Home/Alt+End (Grid):** first/last TCP **parameter** of the selected FX column, leaving the FX header intact; silent boundary. Extra queue-level capture prevents REAPER's main accelerator from pre-empting the combo while the native keyboard owner has focus.
- **Alt+Home/Alt+End (Value):** write maximum/minimum normalized value (same as Home/End in Value). The FX must still be the same GUID.
- **Ctrl+B:** toggle bypass for the current FX, report `Bypassed` / `Enabled`.
- **Ctrl+D:** toggle Delta Solo only if the last FX parameter is actually labelled `Delta` or `Delta Solo` (matching FX Params). Otherwise report unavailable.
- **Ctrl+Shift+Up/Down:** move the selected FX physically one place in the chain, with a single Undo and GUID-based relocation; does **not** reorder track list or parameter rows.
- **Delete (on TCP parameter):** remove *only* the selected TCP parameter control, using the pre-existing verified TCP setter/Undo. On an FX header, Delete does nothing.
- **Ctrl+Shift+A (on TCP parameter):** create/show/arm or hide the actual REAPER parameter envelope with `GetFXEnvelope`, preserving all existing points and automation items; verify the resulting state before announcing Auto. Do not confuse two FX instances with identical names.
- **Ctrl+Shift+Alt+A:** opens the existing accessible global automation confirmation; default is No and NVDA review reads the question.

No other F4 functionality is claimed complete: alias editing, persistent custom TCP parameter order, F4 MIDI CC routing, special JSFX/text-combo behavior and Ctrl+E numeric edit still require subsequent tests.

## Checklist after GitHub Actions, in REAPER/NVDA

1. Put two TCP parameters in one ReaEQ; on the first and last press Alt+Home/Alt+End and verify selection jumps and stops silently. Repeat in Value mode and verify value max/min, with only value spoken.
2. Put ReaEQ and ReaComp on a track, use Ctrl+B, confirm only the currently selected FX bypass changes; try Ctrl+D in ReaComp and an FX that does not have a Delta wrapper parameter.
3. Move the second FX up with Ctrl+Shift+Up and back down, then Undo; check GUID/focus and the original TCP controls remain attached.
4. Press Delete on an FX header (no deletion) and on a visible TCP parameter (only that control disappears). Verify REAPER Undo restores it.
5. In F4 on a TCP parameter, toggle Ctrl+Shift+A twice. Check real envelope active/visible/armed status and that any existing automation items/points remain.
6. Ctrl+Shift+Alt+A, use NVDA+Up, cancel with Esc, then confirm with Y in a separate safe project.
7. Ctrl+F, Alt+Enter, Ctrl+Shift+M, Ctrl+Tab and all F1/F2/F3 gestures should be unchanged.

The Python test checks source contracts only; successful MSVC compilation and REAPER runtime still require the user's GitHub Actions and NVDA test.
