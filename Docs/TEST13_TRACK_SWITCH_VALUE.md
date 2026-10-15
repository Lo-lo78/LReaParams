# TEST13 — Keyboard, track memory, native Value control

Source only. Build ONLY via GitHub Actions. No local CMake / compiler runs.

## Manual acceptance checks in REAPER + NVDA + OSARA

1. Start FX Params on track 1 with multiple FX. NVDA+T should say the
   FX Params title, plugin name and track, without LReaParams or Grid.
2. Move to FX 3 with Ctrl+Down, then to parameter 20. Use Ctrl+Shift+Down to
   skip over an FX-free track to another track with FX. Navigate to another
   FX/parameter on the second track. Ctrl+Shift+Up should return to FX 3,
   parameter 20 on track 1. Repeat multiple times and after Escape/re-enter.
3. With only current track containing FX, Ctrl+Shift+Up/Down should announce
   that no other tracks have FX. At a one-sided boundary with FX on the
   opposite side, the message should distinguish previous/next.
4. Change plugin value with Alt+Up/Down, Alt+Page Up/Down, Alt+Home/End;
   speak only the value. Navigating the grid should speak parameter and value.
5. In FX Params, Alt+Left repeatedly reaches Step -10, Alt+Right can reach
   Step +10. Step 0 is the unscaled step. Test persistence after reopening.
6. Enter FX Value: NVDA should recognize a standard native Win32 slider;
   initial announcement is 'Value, parameter, formatted value'. NVDA+Up
   should allow current parameter/value review; arrows edit only once; Escape
   returns to Grid. Check for extra NVDA speech on each value change.
7. Open Track Params; for Volume, Pan and Width press Enter and check the
   native slider. Adjust values: speak only value. Escape returns to Grid.
   Toggle Mute/Solo/Phase by Enter directly, without slider.
8. Track Params F1/F2/F3 on tracks with no sends/receives: F2/F3 or Enter on
   empty count must remain on F1 with 'No sends' / 'No receives'.
9. Track Params Step -10..+10 affects Volume/Pan/Width steps but does NOT
   change discrete on/off and routing semantics.
10. Regression tests: NVDA+T, Ctrl+R, F12/OSARA help, closing the window,
    re-entering from REAPER TCP, untouched advanced track fields, GUI float,
    REAPER project switching, shutdown/unload, no stuck keystrokes.

## Known limits

- Native slider access is an implementation-level change, not verified with
  NVDA/OSARA in a running REAPER session. Win32 role announcements can depend
  on NVDA versions. The plugin must be checked against real screen-reader
  feedback and adjusted if it duplicates the OSARA value.
- The track list switch is intentionally limited to normal FX chains, not
  master or take FX. The currently selected master track does not move.
- FX with no navigable parameters are skipped, including when their track
  contains an FX container entry.
