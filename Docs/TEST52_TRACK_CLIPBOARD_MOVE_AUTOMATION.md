# LReaParams 0.0.52 — TEST52 Track Params (source-only)

## Source of truth and constraints

Based exclusively on the complete `0.0.51 TEST51_NESTED_FOLDERS_DELETE_ROUTING` source. The original `Speak Track Params - TrackTake Navigator.lua` remains the behavioral reference. `Parameter Library.lua` is **not** migrated or included as a compiled component. No local C++ build, CMake, MSBuild, Visual Studio, CTest or REAPER test has been executed. Run the included GitHub Actions workflow, then verify in REAPER/NVDA.

## F1: SWS/S&M track clipboard preserving routing

- **Ctrl+C:** copy all actually selected REAPER tracks (or the logical F1 current track if none is selected) via `_S&M_COPYSNDRCV1`.
- **Ctrl+X:** same selection rules; `_S&M_CUTSNDRCV1`. After the cut all track pointers are treated as invalid: the entire visible model is rebuilt from REAPER. The nearest surviving row is selected in the invisible cursor without forcing a physical TCP selection.
- **Ctrl+V:** temporarily selects only the current F1 cursor track as the SWS paste anchor; invokes `_S&M_PASTSNDRCV1`, reanchors on the first selected pasted track if available, and restores the invisible navigation. Ctrl+Shift+V is **not** restored; **Enter** remains Grid/Value.
- SWS/S&M is an external dependency for these specific actions. If not installed, no plain REAPER copy/paste fallback is used, to prevent accidental loss of inter-track routing.
- The SWS action itself handles its own Undo/clipboard; no second independently implemented routing copy engine is created.
- A successful command dispatch is not proof that tracks were copied or pasted: the announcement warns about unchanged track counts on cut/paste. Only the user can verify the result in REAPER.

## F1: folder-aware physical move

- **Alt+Shift+Up/Down:** move selected tracks one physical step using `ReorderSelectedTracks`, following the Lua's inclusive folder-block expansion.
- Selected folder parents expand temporarily to include all descendants, including the final track that closes multiple nested folders. Children already covered by a selected folder are not separate roots.
- After the reorder, restore *only* the original logical selected tracks by GUID; move the invisible cursor back to its track by GUID and retain the current F1 parameter column.
- Top/bottom are safe silent boundaries with short feedback. The operation is Undoable through REAPER.
- Existing **Ctrl+Alt+Up/Down** for folder *navigation* is unchanged, as is **Ctrl+Enter** for folder open/close.

## F2/F3: next/previous track with routing

- **Ctrl+Up/Down** searches the preceding/following *visible* F1 track containing sends (F2) or receives (F3).
- Keep the vertical parameter field and stay on the same page; reset to the first routing column on the destination track. No silent cursor jump to REAPER's selected-track anchor.
- The search stops at the project boundary and does not leave the navigator or select tracks in the TCP.

## Ctrl+Shift+A: automation

- On F1 **Volume**, **Pan**, **Mute** and **Width**; F2/F3 **Volume**, **Pan**, **Mute**.
- Existing envelopes use the `GetEnvelopeStateChunk` / `SetEnvelopeStateChunk` APIs; only top-level `ACT` and `VIS` are changed, so envelope points and automation items are left alone. Each operation is undoable.
- With no envelope present, F1 Volume/Pan/Mute use REAPER native actions 40406/40407/40867 after temporarily selecting *only* the logical current track and restoring the original selection by GUID. This path must be tested manually.
- **No envelope creation implemented for F1 Width and for F2/F3 sends/receives.** This is explicitly announced: creating send envelopes safely (including AUXRECV chunk handling and SWS fallback) is not done in TEST52.
- When a supported existing envelope is active and visible, append `Auto` after the announced value in normal Grid navigation and in Tab info, following the FX Params convention. No forged `Auto` status is stored in `.tp`; it is read directly from REAPER.

## Manual regression plan after GitHub Actions succeeds

1. Start F1 and test Ctrl+C, Ctrl+X, Ctrl+V on a single track with a send, then repeat with two or more selected tracks. Confirm that the SWS commands preserve send/receive connections and that Ctrl+Z works. Repeat with SWS disabled: a warning must appear and no plain clipboard fallback should run.
2. Cut the last visible track, then a track inside a nested folder. Verify that no old track pointer crashes REAPER and that the F1 cursor lands on a valid surviving track.
3. Create outer `Instruments`, inner `Bass`, and ending track `Sub Bass` closing both. Select `Bass` and move with Alt+Shift+Down/Up. The children must remain with the folder. Confirm Undo/Redo and that only the originally selected tracks remain selected afterward.
4. In F2 and F3, with some tracks having no send/receive, Ctrl+Down skips empty tracks, preserves the vertical field, and goes to column 1 on the new track. Boundary stays silent.
5. F1 Volume, Pan, Mute: Ctrl+Shift+A with and without an existing envelope. Confirm real envelope visibility and `Auto` suffix. Then test an existing Width envelope. F2/F3: test only an already-present send/receive envelope (Volume, Pan or Mute); do not expect creation in this TEST.
6. Confirm F1 Tab, Enter Value, Ctrl+Shift+S/R two-pass route creation, F2/F3 Canc, folder end-labels, Step memory `.tp`, speech toggles and FX Params remain unchanged.

## Remaining migration, not claimed in TEST52

F1/F2/F3 Ctrl+F filter/edit (including text search, filtered routing columns), full envelope creation and global Ctrl+Shift+Alt+A automation cleanup, track MIDI CC learn/runtime/pickup, additional Lua numeric edit/range operations, and F4-F8 sections. The project should not be called fully migrated until these are implemented and tested.
