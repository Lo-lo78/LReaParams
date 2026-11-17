# TEST71.1 — Consistent spoken FX titles (LReaParams 0.0.71)

When changing FX with Ctrl+Up/Down or changing the track with Ctrl+Shift+Up/Down
in FX Params, the complete initial spoken heading now uses the same configurable
**Messages > FX Params > Title: FX Params** layout as the accessible window title.
This includes the Type and Name elements, their enabled states, ordering, and
custom text. The selected parameter/value follows the heading. Bypassed and
Delta Solo states still come from the shared title status formatter.

Track Params F4's spoken FX-column and visible-TCP-parameter list labels use
the independent **Messages > Track Params > Title: FX TCP (F4)** Type/Name
settings. They do not repeat the full title in each parameter movement.

The underlying raw REAPER FX names, GUIDs, stored positions and profile keys are
unchanged. The split removes prefixes only from presentation when Type is off,
not from identity. No changes to the version, release tags, installer, ReaPack
workflows, or `index.xml` are needed for this test build.

## Manual screen-reader verification
1. In FX Params, confirm default title and Ctrl+Up/Down and Ctrl+Shift+Up/Down
   announce the FX *without* `VST3i:` / other recognized type prefixes.
2. Turn Type on and move Type above/below Name; the same change must be reflected
   in window title and switch announcements.
3. Disable Name or Track or the FX Params heading, and optionally edit Custom
   message: every FX/track switch must respect the resulting layout.
4. With Bypassed and Delta Solo active, verify status is still announced.
5. In Track Params F4, verify the FX-column navigation and TCP parameter-picker
   announcements reflect its *independent* Type/Name preferences.
6. Confirm `Preferences.ini` persistence and restoration of the current FX,
   track and parameter after Ctrl+P.
