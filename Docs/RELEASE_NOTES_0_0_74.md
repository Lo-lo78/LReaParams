# LReaParams 0.0.74 — Parameter ranges and floating MIDI CC

Release date: 18 November 2026

- **Alt+R**: set an individual editable range for the selected FX or Track parameter, including Volume. The existing Step remains independent. The accessible dialog has Minimum, Maximum, OK and Cancel, with Enter to confirm and Escape to cancel. Both paths restore the previous navigator position.
- **Alt+C**: configure an individual 0–127 range for an already-enabled fixed MIDI CC assignment. The memories CC column shows custom limits; unmodified CCs keep their original display.
- **Alt+F**: configure a 0–127 range for the currently learned floating CC. Its channel, number and range are shared across FX Params and Track Params in RAM only, for the lifetime of the REAPER session. They are not saved to profiles or memories.
- **Shift+C**: Fixed CC on announces the number of assigned fixed parameters; Fixed CC off resumes the learned floating controller and announces its channel and number, if active. Switching to fixed CC does not erase the floating CC session.
- **Track Params MIDI**: when MIDI speech is enabled, speak only the value; update the native accessible value immediately so NVDA review reads the latest change.
- Removed the experimental Volume-only Ctrl+Shift+I command and its dedicated Volume Ranges memories column. General per-parameter ranges replace them.
- Existing plugin configurations, keyboard navigation, FX/Track memories and previous releases are otherwise retained.

ReaPack: the existing `release: published` workflow, historical index generator and safe push script are unchanged. A published stable release triggers a separate build/upload of the native DLL and regeneration of `index.xml` from all eligible historical releases.
