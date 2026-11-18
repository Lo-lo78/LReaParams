# TEST74.1 — Native Render window keyboard navigation (Windows x64)

This is an experimental source-only feature added on top of the released 0.0.74.
**The REAPER 40015 action remains unchanged.** No alternate Render dialog,
rendering API, preference changes, or setting writes are performed.

## User controls (only while REAPER's native Render to File dialog is focused)

- Ctrl+F opens a small search field. Type a control name, Enter focuses the
  first currently visible matching control, Escape restores prior focus.
- F3 / Shift+F3 focus next / previous result immediately (wrap around).
- Alt+1 / Alt+2 navigate to Primary / Secondary output-format page.
- Ctrl+Tab / Ctrl+Shift+Tab switch between the two output-format pages only
  when the focus is inside the tab, format selector or format-settings area.
- Alt+letter navigates directly to a control. The first suitable unused
  letter from its name is preferred; when no distinct letter remains the
  shortcut cycles through controls sharing that letter. The main anchors are:
  Alt+R Render, Alt+T Tail, Alt+S Sample rate, Alt+N File name,
  Alt+D Output directory, Alt+F Output format, Alt+O Source, Alt+B Bounds,
  Alt+C Channels, Alt+P Presets, Alt+W Wildcards, Alt+Q Queue,
  Alt+G Save settings, Alt+V Render speed, Alt+E Resample,
  Alt+I Silently increment, Alt+H Dither.
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
search and accelerators. Format-dependent controls are discovered dynamically
instead of being hardcoded as an exhaustive list. An optional ID-to-label
mapping improves access to older REAPER render controls. Labels for unknown
controls are recovered from native captions/nearby static labels.

The two tabs are selected using the native tab-control/MSAA interface when
available; selection changes the VISIBLE PAGE only and never touches any
render value. Each tab remembers its last focus by HWND, control ID and name,
with safe fallback if REAPER has recreated its child controls.

## Acceptance checks (requires Windows REAPER with NVDA/OSARA)

1. Open 40015 from Ctrl+Alt+R, File menu and Actions list. Original focus and
   Tab/Shift+Tab, selection, Space, Enter and rendering must be unchanged.
2. Search `sample`, Enter, then NVDA must read the native sample-rate combo.
3. Search `format`, Enter, then F3/Shift+F3 and test wraparound; no setting
   may change when merely moving focus.
4. Search a native button (`render`), then press Alt+R. The render must NOT
   start until you personally press REAPER's native Space/Enter.
5. Alt+T focuses Tail without toggling it; Alt+1/Alt+2 navigate the tab pages.
   Ctrl+Tab restores each remembered control when the page is revisited.
6. Test WAV/FLAC/MP3/video-specific fields and enabled/disabled conditions.
7. Open a Metadata, File chooser or Normalize subdialog: Render-specific
   keys must stop intercepting until the original Render window regains focus.
8. Close Render or start a render and confirm all shortcuts behave normally
   elsewhere in REAPER, without OSARA duplicate announcements.

**Not yet verified on a live Windows REAPER build:** exact tab-control class,
MSAA selection behavior, newer REAPER control IDs, full visible-control
coverage and key routing within every codec-specific subdialog. Missing
controls remain accessible via REAPER's untouched native Tab navigation.
