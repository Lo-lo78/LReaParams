# TEST74.1 — Native Render window keyboard navigation (Windows x64)

This is an experimental source-only feature added on top of the released 0.0.74.
**The REAPER 40015 action remains unchanged.** No alternate Render dialog,
rendering API, preference changes, or setting writes are performed.

## User controls (only while REAPER's native Render to File dialog is focused)

- Ctrl+F opens a small search field. Type a control name, Enter focuses the
  first currently visible matching control, Escape restores prior focus.
- F3 / Shift+F3 focus next / previous result immediately (wrap around).
- Alt+1 / Alt+2 focus the **Primary output format / Secondary output format
  tab item itself**, not a field or a previously visited control inside it.
- Ctrl+Tab and Ctrl+Shift+Tab are **not intercepted** by this module. Their
  native REAPER behavior is retained without a special page-switch handler.
- Alt+letter navigates directly to a control. **Alt+Shift+letter goes
  backwards** through the same group of controls. When multiple controls
  share a letter, both shortcuts cycle with wraparound; changing direction
  starts from the currently focused matching control whenever possible.
  The first suitable unused letter from a name is preferred; when no
  distinct letter remains, the shortcut cycles through sharing controls.
  The main anchors are:
  Alt+R Render, Alt+T Tail, **Alt+Z Sample rate** (Alt+S remains an alias), Alt+N File name,
  Alt+D Output directory, Alt+F Output format, Alt+O Source, Alt+B Bounds,
  Alt+C Channels, Alt+P Presets, Alt+W Wildcards, Alt+Q Queue,
  Alt+G Save settings, Alt+V Render speed, Alt+E Resample,
  Alt+I Silently increment, Alt+H Dither.
- When Alt+letter reaches a control inside the currently displayed output-
  format page, LReaParams briefly announces **Primary** or **Secondary**
  before leaving the native control to NVDA. This context is read from the
  selected tab's native Windows/MSAA state: if that state is not available,
  LReaParams stays silent rather than guessing. Other Render controls do
  not receive a misleading page prefix.
- **An Alt+letter moves focus only. It NEVER presses a button, starts a
  render, changes a checkbox, chooses a format or writes a project setting.**
  Use REAPER's original Space/Enter/arrows yourself after reaching it.

## Technical scope

The extension installs a thread-local WH_GETMESSAGE listener on REAPER's main
UI thread. It only consumes additional navigation keys when the foreground
window is positively identified as the native render dialog by multiple
current child control signatures. All other windows (including subdialogs,
render progress, queues and other programs) are left untouched.

A fresh walk of all visible/enabled keyboard-focusable children is used for
search and accelerators. A main sample-rate widget using native ID 1041 is
also admitted even if REAPER supplies a nonstandard class/Tab-stop; a
labeled replacement is considered if the native ID is missing. Alt+Z is
reserved for sample rate alone. Disabled native controls cannot be focused. Format-dependent controls are discovered dynamically
instead of being hardcoded as an exhaustive list. An optional ID-to-label
mapping improves access to older REAPER render controls. Labels for unknown
controls are recovered from native captions/nearby static labels.

Alt+1/Alt+2 only move keyboard focus to the corresponding native tab item.
For MSAA child tabs this uses `SELFLAG_TAKEFOCUS` (not selection); for a Win32
`SysTabControl32`, `TCM_SETCURFOCUS` targets the requested tab item. Depending
on REAPER's standard tab semantics, moving focus can also display that tab's
page, but never adjusts a rendering setting. The previous page-control focus
memory and Ctrl+Tab override have been removed. If a custom tab item cannot
be focused unambiguously, the shortcut leaves REAPER's native navigation
available instead of guessing or jumping into a format field.

## Acceptance checks (requires Windows REAPER with NVDA/OSARA)

1. Open 40015 from Ctrl+Alt+R, File menu and Actions list. Original focus and
   Tab/Shift+Tab, selection, Space, Enter and rendering must be unchanged.
2. Search `sample`, Enter, then NVDA must read the native sample-rate combo.
   Press Alt+Z to jump directly there without modifying the sample rate; verify
   Alt+S still reaches the same input. If the combo is disabled by REAPER,
   first make it available with the native "Use project sample rate" setting.
3. Search `format`, Enter, then F3/Shift+F3 and test wraparound; no setting
   may change when merely moving focus.
4. Search a native button (`render`), then press Alt+R. The render must NOT
   start until you personally press REAPER's native Space/Enter.
5. Alt+T focuses Tail without toggling it. Alt+1 and Alt+2 focus the
   Primary/Secondary tab *labels themselves* (verify NVDA reads the tab).
   Ctrl+Tab / Ctrl+Shift+Tab must NOT be overridden by LReaParams.
6. Test Alt+letter and Alt+Shift+letter on a key that cycles through several
   controls. After two forward moves, reverse should return to the previous
   item, then continue backwards, including wraparound. Check that either
   direction only changes focus. Test both gestures inside output format pages: the brief Primary or
   Secondary announcement should match the selected native tab, while NVDA
   reads the target control normally. Outside those pages, no page prefix.
7. Test WAV/FLAC/MP3/video-specific fields and enabled/disabled conditions.
8. Open a Metadata, File chooser or Normalize subdialog: Render-specific
   keys must stop intercepting until the original Render window regains focus.
9. Close Render or start a render and confirm all shortcuts behave normally
   elsewhere in REAPER, without OSARA duplicate announcements.

**Not yet verified on a live Windows REAPER build:** exact tab-control class,
MSAA selection behavior, newer REAPER control IDs, full visible-control
coverage and key routing within every codec-specific subdialog. Missing
controls remain accessible via REAPER's untouched native Tab navigation.
