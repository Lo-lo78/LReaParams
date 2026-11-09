# LReaParams 0.0.69 — Used in F7 and Persistent Used View

This release builds on 0.0.68 with improvements from TEST68.1, TEST68.2 and TEST68.3.

## What's new

- **Used remembers where you left off:** Escape closes FX Params without leaving Used; reopening the same FX resumes the Used view and its parameter position. Each FX instance remembers its own view.
- **Ctrl+L in Used:** exits Used and returns directly to the previous Plugin Order, Custom Order or Group, without unrelated Custom Order / F7 prompts.
- **Ctrl+Shift+L in F7:** toggles Used with the previous F7 context and its independent selection.
- **F7 Used selection:** Shift+Space, Shift+arrows and Ctrl+A select parameters, Ctrl+C copies the physical parameter IDs, and Ctrl+V pastes them into groups; Ctrl+Shift+F1–F12 can save a selection to an available group slot.
- **Safe Ctrl+Delete:** in F7/Used it does not remove a Used entry or modify any underlying group; in FX Params/Used it retains the existing remove-from-Used action.

## Preserved behavior and compatibility

- Keeps existing Used per-instance list and project storage format, with a separate view preference so 0.0.68 can still read the Used collection.
- Preserves 14 existing FX contexts, independent grids and Standard/Keyboard themes, F3 Grid/Step/Group or Memory slots reporting, and all other shortcuts.
- No .fx profile format migration, no changes to the existing ReaPack index generator, and no rewriting historical releases.
- Updated source, installer, About and seven-language accessible guides.

## Installation

Download the **0.0.69 Windows x64 Setup ZIP** from this release, close REAPER, extract the ZIP and run the installer. Alternatively, update from the existing ReaPack repository after its publishing workflow has completed.

**Platform:** Windows x64 / REAPER x64. **License:** GPL-3.0-only.
