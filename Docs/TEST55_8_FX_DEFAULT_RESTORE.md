# TEST55.8 — FX Default restore and memory navigation

Base: TEST55.7. Source only; MSVC compilation is exclusively via GitHub Actions.

## Fix

- A complete FX Default snapshot is saved as native indices, parameter names and normalized values.
  Certain synthesizers rename their parameters as presets change. The previous reader discarded
  those values, producing `Default parameter identities changed. No changes` even if the count
  and physical IDs were still valid. The reader now first tries strict name validation, then
  safely retries by native index **only for a complete contiguous snapshot**. It rejects duplicates,
  missing IDs, invalid values, changed counts and detectable reorderings of the same parameter labels.
- Original `.fx` snapshot bytes are preserved. No silent regeneration or overwrite.
- Enter on `Default values` restores the stored FX sound **without deleting any other memories**,
  switches to the normal Plugin Order grid and announces the current parameter.
- Delete on `Default values` still asks for Yes/No confirmation before resetting all memories;
  Ctrl+Shift+Backspace uses the same verified audio-restoration engine.
- Existing ReaEQ structural default uses its independent chunk-based restoration unchanged.

## Manual REAPER/NVDA checks

1. Open a synth with a saved Default, change its sound, use Ctrl+Shift+Backspace.
   Verify the sound actually returns to the saved configuration.
2. Set a synth preset that changes parameter labels but not count, then restore Default.
3. Ctrl+Shift+M, select `Default values`, press Enter: restore audio and return to the
   FX parameter grid (not FX Memories), with CC/groups/positions intact.
4. Open FX Memories, select `Default values`, press Delete; choose No then Yes to
   check that cancellation is nondestructive and confirmation is required for clearing.
5. Check REAPER Undo, ReaEQ band layouts and a plugin with modified parameter count.
   Unsafe layout changes must not modify audio.
6. Reenter the FX, test F8 Original/Compare; verify it still works.

Notes: Static checks are not MSVC compilation or a real audio test. An old snapshot
from a genuinely reordered plugin with renamed labels may still require a freshly
captured default; users should back up project and profile before restoring.
