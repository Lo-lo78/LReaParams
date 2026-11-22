# LReaParams 0.0.76 — Accessible Render, shortcut help and configurable messages

**Release date:** 22 November 2026  
**Platform:** Windows x64 · Native REAPER extension · NVDA / OSARA

## Shift+F1: context-sensitive shortcut exploration

- **Shift+F1** turns shortcut exploration on or off while an LReaParams context is active: **FX Params, Track Params or the native Render window**.
- While exploring, pressing a gesture announces its *current LReaParams function*; it does not execute the action, change a parameter or move the focus. Press Shift+F1 again to return to normal operation at the same control.
- The help resolves the active page/context and user remappings; it is not a replacement for OSARA's REAPER Action List shortcut help.
- **Outside active LReaParams contexts, Shift+F1 belongs to REAPER**, including any user-assigned action.

## Render: automatic and personalized shortcuts

REAPER action **40015** still opens the original **Render to File** window. LReaParams supplements its native controls:

- **Ctrl+F** searches visible controls; **F3 / Shift+F3** navigate results.
- **Alt+letter / Alt+Shift+letter** move the focus among available controls; shared automatic letters cycle. **Alt+Z** focuses Sample rate and **Alt+R** focuses Render without starting it.
- **Alt+1 / Alt+2** still focus the Primary and Secondary tabs. These are fixed Render navigation gestures, not automatically generated Alt+letter choices; they are not artificially injected into the Preferences shortcut lookup when no personal gesture exists.
- **Ctrl+Tab / Ctrl+Shift+Tab** and control activation remain native REAPER functions. Render accelerators **only move focus**: they never click a button, change a checkbox or start rendering.
- **Ctrl+P → Shortcuts → Render** shows recognizable controls from the Render configuration currently exposed, plus any already-personalized controls that are temporarily unavailable. **No personal gesture means automatic navigation remains unchanged**. A user-defined gesture takes precedence over the corresponding automatic gesture without redistributing the old cycle.
- Personal assignments persist in Preferences. A format-specific unavailable control remains editable; no format or tab is silently changed while scanning.

## Ctrl+P Preferences improvements

- **Shortcuts** has separate FX Params, Track Params and Render sections. FX/Track retain their fixed, user-remappable mappings.
- **Alt+S** is the **only** accelerator entering **Search by shortcut**. Within that field, all queried shortcut gestures are inert: **Alt+R, Alt+O, Alt+C, Alt+D** and other combinations never activate dialog buttons. The shortcut is looked up without executing it; a miss leaves the existing selection intact.
- **F1–F12**, including supported modifier combinations, may be captured and searched. Certain essential navigation or accessibility combinations remain reserved (including Shift+F1).
- **Delete** restores a single shortcut to its default (FX/Track) or removes the personal override (Render).
- **Alt+R** selects **Reset section**. A confirmation starts on **No**. A Yes answer resets only the selected section *in the pending preferences*; **OK** saves and **Cancel/Escape** abandons changes.
- The lookup only reports shortcuts mapped by LReaParams. REAPER Action List bindings remain REAPER/OSARA's responsibility.

## Ctrl+P Messages: individual speech announcements

- Existing title templates remain intact and keep their original positions: **four FX** and **twelve Track** titles.
- The message list then exposes **301 FX** and **276 Track** navigator announcement types found in this source version. Each can be **enabled or disabled** independently or given an optional **custom message**.
- For dynamic announcements, the literal token **`{original}`** inserts the original current text (for example, parameter names and values). An empty custom field keeps the original; disabled messages remain silent.
- The overrides are kept in the existing Preferences system (`[SpeechMessages]`), apply after **OK**, and are discarded by **Cancel/Escape**. The navigator logic and title layouts are unchanged.

## Compatibility and historical ReaPack safety

All 0.0.75 native Render navigation and 0.0.74 parameter and MIDI CC ranges, FX/Track memories, `.fx` and `.tp` profile compatibility, Keyboard/Used modes, custom title configurations and previous functionality remain.

**Do not alter previous tags, releases or index history.** In the existing Git clone, publish source changes only with `Tools\push_lreaparams.cmd "Release 0.0.76 - Context shortcut help Render preferences and configurable messages"`. Verify MSVC and CTest, then publish a **new stable `v0.0.76` release only if that tag is not already used**. Attach its matching Windows installer. On the GitHub **`release: published`** event the existing `Publish LReaParams to ReaPack` workflow runs separately: it builds the native DLL from that tag, attaches the DLL to the same release and regenerates `index.xml` from **all eligible stable releases**, including older tagged versions. **No manual XML commit, forced push or tag recreation.** If that run fails, retry the existing workflow manually with the *same* valid release tag.

## Validation

The source tests cover Render, Preferences, shortcut help, message overrides and historic ReaPack workflow contracts. Full release readiness additionally requires the GitHub Actions Windows build, CTest, and a final NVDA/OSARA smoke test. Source ZIPs contain no precompiled DLL or installer.
