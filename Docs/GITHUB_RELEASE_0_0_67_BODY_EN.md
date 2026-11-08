# LReaParams 0.0.67 — Used Parameters and Independent Grid Controls

This release brings the new **Used (Usati)** virtual FX-parameter view, independent Grid and Step reset controls, and an accessible numeric Grid editor. It includes the previous 0.0.66 Keyboard, accessibility and ReaPack improvements.

## What's new

- **Ctrl+Shift+L:** toggle between the current FX context (Plugin Order, Custom Order, or Group) and the **Used** virtual view. The previous context, cursor, Grid and theme are restored when you return.
- **Automatic Used collection:** real parameters successfully edited through LReaParams enter the list once, in first-edit order. Preset changes and playback automation do not automatically populate the list.
- **Ctrl+Delete in Used:** remove the current entry from Used without changing its FX value or any other group. Editing the parameter again adds it to the end.
- **Independent Used settings:** Used has its own Grid, cursor and F4 Standard/Keyboard theme. Its collection is saved per FX instance in the REAPER project, without modifying existing `.fx` profiles or the 14 original contexts.
- **Backspace:** reset the current parameter. **Ctrl+Backspace:** reset only the current Step. **Shift+Backspace:** reset only the Grid to 10. **Double Shift+Backspace:** accessible Grid-size input from 1 to 400 (Enter confirms, Escape cancels). **Ctrl+Shift+Backspace:** reset all FX parameter values.
- **F3 remains unchanged**, announcing Grid, Step and Group slots / Memory slots, depending on Alt+G / Alt+M.

## Compatibility

- Preserves the original 12 groups, Plugin Order, Custom Order, independent Keyboard/Standard preferences, FX Memories, F7 Standard editor and accessible NVDA/OSARA navigation.
- Maintains previous ReaPack package identity and available published release history.
- Windows x64 / REAPER x64. LReaParams is open source under GPL-3.0; additional third-party notices are included in the source.

## Installation

Download the **LReaParams 0.0.67 Windows x64 Setup ZIP** from the assets below, extract it, close REAPER, and run the setup EXE. Alternatively, update from the existing LReaParams ReaPack repository after its publishing workflow completes.

ReaPack repository: https://raw.githubusercontent.com/Lo-lo78/LReaParams/main/index.xml

Source code: https://github.com/Lo-lo78/LReaParams
