# TEST62.6 — Selected-only navigation in FX Memories and Track Memories

The TEST62.5 multiple-selection and bulk-delete functions are unchanged.

When FX Memories or Track Memories is open:

- **Shift+Space:** toggle selected/unselected on the current row.
- **Ctrl+A:** select all the memories in the current column.
- **Alt+Shift+Down:** jump to the next selected row in the same column.
- **Alt+Shift+Up:** jump to the previous selected row in the same column.
- **Alt+Shift+Left / Right:** do nothing, without changing columns or steps.
- **Left / Right:** ordinary column changes, unchanged.
- **Alt+Left / Right:** ordinary step adjustments, unchanged.
- **Delete:** delete the selected memories in the current column (or current row without selection).

A jump announces **Selected.** first, followed by the column and selected memory label. On the first or last selected row, there is no wrap and the key is silent, as in the F7 editor. If no rows are selected, the announcement is **0 selected**. Selections in another column do not affect the jump.

## Manual NVDA + OSARA checks

1. Open Ctrl+Shift+M in FX Params; in a column with at least five entries, select row 2 and row 4 using Shift+Space.
2. Return to row 1. Alt+Shift+Down must jump to row 2, and again to row 4. Alt+Shift+Up returns to row 2. NVDA must say Selected first.
3. From row 4, Alt+Shift+Down must be silent. Alt+Shift+Right/Left must not move columns or change a step.
4. Repeat in Track Params memories and confirm the same behavior.
5. Check that Ctrl+A, Shift+Space, Delete, and the normal arrows still work.
6. If no entries are selected, Alt+Shift+Up/Down should report 0 selected. The shortcut must not change the selected memory or column.

The automated test is source-level only. GitHub Actions must compile on Windows; real NVDA and REAPER behavior still requires manual testing.
