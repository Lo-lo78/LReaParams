# LReaParams 0.0.62 — TEST62.2 (FX Params: saved empty groups)

**Status:** source-only test for GitHub Actions. Windows MSVC DLL and interactive
REAPER / NVDA / OSARA behavior have not been verified locally. Built on TEST62.1.

## Two equally supported ways to create groups

Choose **Alt+G** for group shortcuts and open **F7**.

1. **Bulk:** Select one or more parameters (F7), press **Ctrl+Shift+F1..F12**.
   The selection becomes the new Group 1..12 in one operation. The shortcut
   is *not* removed; existing populated or saved-empty groups are protected.
2. **Empty first:** In F7, clear the selection with **Delete** (not Ctrl+Delete).
   Press **Ctrl+Shift+F1..F12**. The slot is now a *saved empty group*, and is
   immediately written to the `.fx` profile as e.g. `2=` under `[GroupSlots]`.
   It is a valid memory even with **zero parameters**, so it can be opened
   with Ctrl+F2 without entering F7 first.
3. **Paste first:** From Custom Order F7, copy parameters with Ctrl+C. Press
   **Ctrl+F1..F12** to enter a previously unsaved slot *while F7 is active*.
   This slot is temporary until a successful **Ctrl+V**. The paste creates
   and saves it automatically. If paste is cancelled, the slot stays unsaved;
   Undo of the first paste also removes that newly created slot.

A previously saved group that becomes empty after removing its last parameter
remains saved, instead of disappearing. Use FX Memories to delete its slot.

## FX Memories, Ctrl+Shift+M

The Groups column includes saved empty groups and announces:

- `Group Bass. 0 visible parameters` when custom-named Bass.
- `Group 2. 0 visible parameters` when unnamed.

The sixth column, Copied parameters, still lists only **parameter occurrences**;
therefore a group with zero parameters has no entry there. The group itself
appears in the **Groups** column.

The existing convention always includes the `Group` prefix before any custom
name (`Group Bass`, `Group Filters`) or default slot number (`Group 2`).
The other five columns and custom/global hidden behavior remain unchanged.

## Regression checks

- Build and C++ profile roundtrip on GitHub Actions (TEST62.2 fixtures in
  `Testing/ProfileTests.cpp`), then test on REAPER Windows.
- Bulk save with 2 selected, verify both present and source intact.
- Save with 0 selected, check Groups column and reopen group from Ctrl+Fn
  outside F7; rename to `Group Bass` with Ctrl+Enter in F7.
- Copy from Custom; paste into *saved* and *unsaved* empty groups.
- Test Undo of an initial paste into an unsaved group.
- Delete the last group parameter, restart REAPER, ensure the empty group still
  exists and can receive Ctrl+V.
- Delete saved empty group via FX Memories, restart REAPER and ensure it stays
  deleted (no phantom `slot=` record).
- Confirm Plugin Order remains unchanged, and Track Params functionality remains
  unaffected by this FX-only change.
