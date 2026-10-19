# LReaParams 0.0.59 — TEST59: Track Params F8 ReaRoute

**Source only for GitHub Actions; never built or run locally.** This is a first native C++ migration of Lua F8 (`Legacy/Speak Track Params - TrackTake Navigator.lua`, section `3.5E - F8 REAROUTE BRIDGE`), not a claim of validated behavior in REAPER/NVDA. No aliases, manual TCP ordering, FX Params shortcut changes, or global transport shortcut remapping were included.

## Three logical regions, always accessible

Press **F8** to enter the 11-row, column-oriented ReaRoute bridge for the current track, even if there are no outputs. The grid contains:

1. **Column 1 — ReaRoute input:** ReaRoute input (header), Input enabled, Input type, Input channel or pair, Input start, Input width, Track channels, Input raw value, Input note, Output side, ReaRoute note.
2. **Column 2 — ReaRoute output controls:** ReaRoute output (header), ReaRoute output count, **Add ReaRoute output** (press Enter), Output hint, and informational fields for output volume/pan/mute/phase/mono/source/destination.
3. **Columns 3 onward — one column per existing ReaRoute output:** ReaRoute output (header), Volume, Pan, Mute, Phase invert, Mono, Audio source mode, Audio source, ReaRoute destination, Send type, Pan law.

The output count excludes physical hardware outputs. The ReaRoute hardware-output indices are not assumed contiguous: the native implementation re-enumerates REAPER `GetTrackNumSends(track,1)` and filters destinations with `(I_DSTCHAN & 1023)` in **512–527**. `CreateTrackSend(track,nullptr)` adds a hardware-type output and sets destination 512 (= ReaRoute channel 1/2). On failure, creation is rolled back. Delete removes **only** the currently selected ReaRoute output; it cannot delete one by pressing Delete on the Input or Output-control columns.

**F7 safety refinement:** F7 now filters its physical outputs to destinations below 512 and resolves the actual underlying hardware index for read, write, toggle and delete. It will not delete ReaRoute outputs. This matters when F7 and F8 coexist on a track.

## Value behavior

- Input uses `I_RECINPUT`: disabled `-1`; mono 512+, stereo 512+ with bit 1024; multichannel 512+ with bit 2048. Channel start 1–16 (stereo 1–15). Selecting a channel when input is disabled enables a stereo ReaRoute input, mirroring Lua behavior. Changing input **does not** change recording arm or monitoring.
- Track channels uses `I_NCHAN` in even numbers 2–128 and **only grows**, consistent with the original Lua `track_ensure_channel_count` behavior (lowering is intentionally not forced through this control).
- Audio source offsets can extend track channels when needed, never beyond 128; attempts to set an invalid source or destination are rejected. ReaRoute output destination start can be 1–15 for stereo, 1–16 for mono; its destination flag is preserved.
- Output parameters use the existing REAPER fields D_VOL, D_PAN, B_MUTE, B_PHASE, B_MONO, I_SRCCHAN, I_DSTCHAN, I_SENDMODE, D_PANLAW. Volume uses the existing send range in the `.tp` file. Writes are verified and registered in REAPER Undo.
- When an unrelated physical/audio input is already disabled on the F8 Input enabled row, pressing Alt+Down does not clear that unrelated input.

## Navigation and screen reader

- **Left/Right:** previous/next logical column at the same row. **Up/Down:** previous/next row, among 11. **Page Up/Down:** jump 5 rows. **Home/End:** first/last row. **Ctrl+Home/End:** first/last column.
- **Alt+Up/Down:** change value, **Alt+Page Up/Down:** coarse adjustment, **Alt+Home/End:** maximum/minimum. At unchanged limits the operation is silent.
- **Enter** on Add ReaRoute output creates and selects it. On enabled, Mute, Phase invert or Mono it toggles the flag; on other adjustable fields it toggles Grid/Value. **Escape** exits Value first, then returns to F1.
- **Delete** on any row of a ReaRoute output column deletes only that output (with Undo). On the two control columns, Delete announces that no ReaRoute output was selected.
- **Tab/F8** reads full track, column and row context. Backslash repeats the current parameter/value. NVDA+Up reads the passive review line. NVDA+T reads the native F8 window title.
- **F1–F7** switch pages with their existing semantics; Ctrl+Shift+M opens Track Memories. Ctrl+Tab and Ctrl+Q are left to the existing shared navigator/transport router. No new transport shortcuts have been assigned.

## Persistence

Track project memory `.tp`: `LastPage=F8`, `F8.TrackGUID`, `F8.Row`, `F8.Column`. Row/column restoration applies to the same track GUID; otherwise F8 starts at Input header. F7 column indices now refer to physical-only outputs, not all outputs in category 1.

## Runtime checklist after GitHub Actions build

1. Open F8 on a track with **zero** ReaRoute outputs. Check Input and Output controls are present and no crash or focus escape occurs. On Input enabled test Off/On and type Mono/Stereo/Multichannel; inspect REAPER's recording input. Check this does **not** arm the track or change input monitoring.
2. Create output via **Column 2 > Add ReaRoute output > Enter**. Check it appears at Channel 1/2 and Undo removes it. Verify that C++ announces the new output and places focus on its header.
3. Create two ReaRoute outputs with one real hardware output interleaved. Verify F8 shows only the two ReaRoute outputs; F7 shows only the real hardware output.
4. On an F8 output test all 11 rows, especially Destination 15/16 stereo edge, 16 mono edge, audio source expansion 64/65/128, send mode (including legacy 2), pan law and Enter toggles. Check Undo/Redo and actual I_DSTCHAN values.
5. Delete the **second** ReaRoute output on row 10. Verify only that output disappears, F7 physical output and ordinary F2/F3 sends remain unchanged. Undo restores the deleted ReaRoute output.
6. Test left/right and Home/End at boundaries (quiet), Tab, backslash, Grid/Value, Escape, F1/F4/F5/F6/F7/F8, Ctrl+Shift+M and restored `.tp` position after exiting/reentering, including the case with no output.
7. Verify FX Params and its existing Ctrl+Page Up/Down FX-moving shortcut are unaltered.
8. Confirm the Windows x64 MSVC compile, source tests, CTest, actual REAPER 7.x and NVDA/OSARA focus/announcements. These are **not** equivalent to static Python tests.
