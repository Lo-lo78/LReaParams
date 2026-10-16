> Documento storico TEST30. Per stato attuale e limiti prevalgono Status.md e FxCommandMatrix.csv.

# TEST12 — One announcement per parameter movement

Cause addressed: TEST11's focused Win32 STATIC was rewritten via
`SetWindowTextW` after each navigation move. That can raise an accessibility
name/text-change event that NVDA reads separately from `osara_outputMessage`.

Change: keep the STATIC's native caption unmodified after creation. Handle
WM_GETTEXT and WM_GETTEXTLENGTH in its subclass to expose the current review
line only when an assistive client asks; the extension updates its stored
string without notifying Windows every time. OSARA retains movement speech.

## Manual checks (NVDA and OSARA)

1. Enter FX Params. Press Down once for one new parameter. Expect ONE voice
   announcement (name and value), not two. Repeat with another parameter.
2. Navigate rapidly and slowly. Confirm no letters are spoken.
3. At the top/bottom of the grid, repeat the blocked direction: silence.
4. Switch FX with Ctrl+Up/Down; the new effect and parameter are announced.
5. Alt+Up/Down modifies values and announces each actual change once.
6. In Track Params F1/F2/F3, repeat 1–5.
7. Ctrl+R deliberately repeats the current parameter on request.
8. NVDA+T still reads the name of the FX and track / Track Params page.
9. NVDA+Up: check whether it now reads the current text. Its behavior is
   not guaranteed without a text caret or custom NVDA support.

If duplicates persist, note whether they happen on navigation, value
editing, switching effects or only when opening the window: other access
events or REAPER/OSARA could be responsible. Do not throttle arbitrary
repeated strings; two different parameters can have identical names/values.

Source-only package: DO NOT run a local C++ build. GitHub Actions handles it.
