# LReaParams 0.0.62 — TEST62.5: Multi-selection in FX and Track Memories

Base: **complete TEST62.4**, including F7 removal/hide shortcuts, group persistence and FX Step memories. The public version stays **0.0.62**. This package contains C++ source, not a locally compiled Windows DLL.

## Memory manager shortcuts (both FX Params and Track Params)

- **Shift+Space**: toggle the current row selected / not selected. Announcement begins with `Selected.` / `Not selected.` followed by the column and row.
- **Ctrl+A**: select **all entries in the current column**, not every column. Announces count and current item.
- **Arrows / Page Up / Page Down / Home / End**: move without losing the selection. On arrival at a selected row, announcement begins with `Selected.`.
- **Tab**: read column, row and selected state.
- **Delete**: delete/reset **all selected entries in the current column**; if none selected there, delete/reset only the current row. Delete does not select; it performs the operation.
- **Escape**: close memory manager. Temporary selections are not saved in `.fx` or `.tp` and reset on reopen.

Selection is tracked independently per column, and all selections clear after a destructive operation or a relevant Step edit. When deleting duplicate copied FX occurrences within the same group, entries are deleted from the last raw position backwards, preserving precise identity; the remaining copy is not affected unless selected.

## Special cases

- **FX Default values**: Delete keeps the prior explicit Yes/No confirmation and destructive default reset semantics. Never silently clear the snapshot with Ctrl+A.
- **FX Hidden parameters**: Delete restores only the selected hidden parameter(s); Plugin Order always remains complete.
- **FX Copied parameters**: Delete removes only selected Custom Order copies or selected occurrences within their respective group; any created group remains stored even when emptied.
- **Track Parameter Steps**: Delete restores the default step on the selected entries, not the original REAPER parameter values.
- **Track MIDI CC, speech preferences, track positions, volume ranges**: Delete acts only on chosen memory entries in the current column; current track parameter values are not reset.

## Recommended manual NVDA/OSARA tests

1. Open FX Memories (Ctrl+Shift+M); Shift+Space on two non-adjacent copied occurrences; use arrows and Tab and confirm `Selected` always comes first on selected rows.
2. Delete the two occurrences and confirm that other copies survive, including duplicates in the same group. Confirm that the logical cursor does not jump to the first available row unexpectedly.
3. Ctrl+A on FX Copied parameters; verify count, selected speech and deletion only in the current column.
4. In FX Hidden parameters, select two hidden parameters and Delete; they must reappear in their saved Custom Order/groups, without changing Plugin Order.
5. Select FX Default values and press Delete; choose **No** and verify that nothing was erased.
6. Open Track Memories; test Shift+Space, Ctrl+A, Tab and Delete on Parameter Steps and Track Positions, then reopen and ensure removed entries stayed removed.
7. Switch between columns with some selected rows, then press Delete: only the **current column** must be affected. Exit/reopen: no rows preselected.
8. Verify other TEST62.4 F7 shortcuts and group functionality continue to work.

Windows GitHub Actions performs the actual compile; these local tests are static. No interactive REAPER/NVDA host test is claimed.
