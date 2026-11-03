# LReaParams 0.0.63 — release notes

**Release date:** 2026-11-03. **Source base:** TEST62.9.2. This is the next public release after 0.0.62; TEST62.x labels are internal development milestones, not public versions.

## FX Params — groups, editing and memories

- Plugin Order is always the original, unmodified parameter list. Custom Order and the 12 groups keep their own occurrences and independent navigation grids. Empty groups may be explicitly saved and recalled.
- F7 `Ctrl+C` copies occurrences between compatible contexts. `Ctrl+X` can reorder within a context or move between groups; cutting between Custom Order and groups is blocked. `Ctrl+Delete` removes only group occurrences; `Ctrl+Shift+Delete` hides parameters globally in Custom Order and all groups, **never** in Plugin Order. Restore hidden parameters individually from FX Memories.
- `Ctrl+L` from any group returns straight to Custom Order, including from F7. A second `Ctrl+L` switches to Plugin Order.
- F7 supports multi-selection for Step changes (`Alt+Left/Right`), value changes using individual Steps (`Alt+Up/Down` and large steps) and compatible bulk numeric editing with `Ctrl+E`.
- Seven-column FX Memories include per-group copied occurrences, Hidden Parameters and Parameter Steps. Selected memory rows support `Shift+Space`, `Ctrl+A`, `Alt+Shift+Up/Down` and batch Delete. Destructive Default restore keeps confirmation.

## Track Params and common navigation

- Track Memories gains the same selected-row and selected-only vertical navigation, without moving between columns.
- Type-ahead incremental search accumulates characters for 1000 ms in FX grids/F7/groups, Track F1–F3 and both memory managers. Search handles multiword name prefixes, digits, punctuation and reverse Shift, including physical digit keys on Italian/European keyboard layouts.
- `Alt+P` in the **native FX Chain list** opens FX Params on the highlighted plugin; `P` still searches the REAPER list and `Alt+P` outside the list remains untouched.
- New **LReaParams: Import selected legacy TXT files** action under REAPER Action List and Extensions > LReaParams. Choose one or more old Lua FX/Track TXT profiles; original files are never modified and existing .fx/.tp profiles are not overwritten on conflict.

## Publication and accessibility

- About dialog, CMake version, NSIS installer/file version, GitHub Actions artifact names and all seven offline HTML guide languages identify **0.0.63**.
- Release ZIP/installer includes the source, license and offline guides. Existing user profiles are preserved by installation and uninstall.
- The TEST62.9.2 source-only regression check is included in the GitHub Actions pipeline.
- **No Windows DLL or installer was compiled in this source-only preparation.** Before publishing the GitHub Release, confirm GitHub Actions MSVC + CTest success and verify REAPER/NVDA/OSARA and the installer. Suggested release tag: `v0.0.63`.

For implementation details see `Docs/TEST62_1_*.md` through `Docs/TEST62_9_2_SHIFT_DIGIT_SEARCH.md` and the earlier `Docs/RELEASE_NOTES_0_0_62.md`.
