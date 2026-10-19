# TEST61.4 — Track Params F6: Add Hardware Output

Source only for GitHub Actions; no local build or REAPER/NVDA runtime test was performed.

## Overview

F6 always opens on the current track even if it has no hardware outputs. Its additional virtual **Add hardware output** column is located immediately to the left of existing physical output columns. It has three rows: Add hardware output, New hardware destination, Available hardware destinations. Existing outputs still contain the original 11 rows and are kept separate from F7 ReaRoute.

## Keyboard

- **F6**: opens the hardware outputs page even with zero outputs.
- On an empty track, focus starts on **Add hardware output**. **Enter** adds an output routed to the selected physical audio destination.
- **Alt+Up/Down**: choose the hardware destination pair. **Alt+Page Up/Down**: move four choices. **Alt+Home/End**: first/last available destination.
- **Up/Down**: explore the three Add rows. **Tab**: read the current row with track context.
- **Right**: enter the first existing output column. **Left** from the first output, or **Ctrl+Home**, returns to Add.
- After Enter, focus moves to the newly created output; all 11 existing controls work as before.
- **Delete** in an output column removes only that physical hardware output. Deleting the final one stays on F6 Add. Delete on Add never removes anything.
- **Escape** returns to Tracks. **F7** opens ReaRoute.

## Native API and safety

- `GetNumAudioOutputs` and `GetOutputChannelName` list actual output channels from the active audio device. In the case of an odd channel count, the remaining last channel is offered as mono.
- `CreateTrackSend(track, nullptr)` creates the native hardware output, and `SetTrackSendInfo_Value(..., 1, index, "I_DSTCHAN", destination)` selects the physical output. Destination is checked by reading it back.
- A failed configuration attempts to remove the newly created hardware send, avoiding a stranded send or a ReaRoute destination.
- Physical destination low bits remain below 512; ReaRoute destinations 512+ belong only to F7.
- Operations use REAPER Undo, refresh the arrangement, and never alter the track's source channel count automatically.
- `F6.Column=-1` persists the Add column without migrating or renumbering existing `.tp` positions. Existing saved output columns remain 0-based.

## GitHub Actions + NVDA verification

1. Use a track with **zero hardware outputs**, open F6 and verify it opens the Add column.
2. Use Alt+Up/Down to select audio device output pairs; Tab should announce the chosen destination with any available channel names.
3. Press Enter, confirm hardware output 1 has been created and routed to the selected channels in REAPER's routing UI.
4. Add a second hardware output using Ctrl+Home and Enter; inspect the 11 rows on each output.
5. Delete the second and then the first. Verify F6 stays open, announcing Add, and that Ctrl+Z restores the delete.
6. Repeat with ReaRoute outputs already present in F7: none should be modified by F6 creation or deletion.
7. Test with an audio driver that has no exposed hardware outputs: Enter should announce unavailability, not create a phantom output.
8. Build the DLL with GitHub Actions; verify focus and NVDA/OSARA announcements in REAPER.
