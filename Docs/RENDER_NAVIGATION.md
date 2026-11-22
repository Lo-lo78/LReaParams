# Render to File — accessible navigation and personalized shortcuts (LReaParams 0.0.75)

LReaParams adds navigation shortcuts to the **existing native REAPER Render to File window** (action 40015), not a replacement rendering interface. The shortcuts operate only when that window is identified and focused. Outside it, REAPER, OSARA and NVDA behave normally.

| Shortcut | Purpose |
| --- | --- |
| Ctrl+F | Search a native control by name; Enter focuses a visible match, Escape cancels |
| F3 / Shift+F3 | Next / previous search result; wraps around |
| Alt+letter / Alt+Shift+letter | Forward / reverse movement through controls assigned that letter; cycles when shared |
| Alt+Z | Focus main Sample rate control; Alt+S is also an alias |
| Alt+R / Alt+T | Focus Render / Tail; **does not** activate them |
| Alt+1 / Alt+2 | Focus native Primary / Secondary output-format tab labels |
| Ctrl+Tab / Ctrl+Shift+Tab | REAPER's native tab handling, unchanged |

Other main accelerator anchors include Alt+N File name, Alt+D Output directory, Alt+F Output format, Alt+O Source, Alt+B Bounds, Alt+C Channels, Alt+P Presets, Alt+W Wildcards, Alt+Q Queue, Alt+G Save settings, Alt+V Render speed, Alt+E Resample, Alt+I Silently increment and Alt+H Dither. Letters can cycle among multiple controls when necessary; controls are discovered dynamically based on the visible REAPER UI.

## Ctrl+P: personal shortcuts for native Render controls

Render's **automatic** Alt+letter keys remain the default. Open Render with the desired format and tab selected, then press **Ctrl+P → Shortcuts → Render**. The preferences list contains controls the native dialog currently exposes, plus previously personalized controls that are now temporarily unavailable. A blank personal shortcut means the usual automatic behavior. **Enter** assigns a personal shortcut; **Delete** restores that control to automatic navigation. No automatic accelerator is saved as a personal shortcut.

Press **Alt+S** to focus **Search by shortcut**. In this field, gestures are queried and never executed: Alt+R, Alt+O, Alt+C and all other combinations are data rather than dialog commands. A successful lookup selects the corresponding entry; a miss does not change the selection. Render's built-in **Alt+1 / Alt+2** tab-focus gestures are **not injected as artificial matches** into the preferences lookup; a user-assigned shortcut for Primary/Secondary is searchable normally.

**Alt+R** activates **Reset section** in the Preferences dialog (not the Render button). The confirmation starts on **No**. Confirming Yes clears the Render personal overrides **pending OK**; Cancel/Escape discards unsaved changes. Outside Ctrl+P, **Alt+R** keeps its ordinary focus-only Render meaning.

## Shortcut help: Shift+F1

While Render is actively handled by LReaParams, **Shift+F1** toggles shortcut exploration. Press a gesture to hear its current function without performing it or changing focus. Press Shift+F1 again to return to the same position. Outside LReaParams-managed contexts, Shift+F1 remains available to REAPER. The same mode works inside FX Params and Track Params.

**Focus-only rule:** pressing any of these accelerators never clicks a button, starts rendering, toggles a setting or changes a value. After moving focus, use the ordinary Space/Enter/arrows keys if you want to operate the control. If Sample rate is disabled, first change REAPER's native use-project-sample-rate option as appropriate. LReaParams does not enable disabled controls.

When moving to a format-specific field, the extension announces **Primary** or **Secondary** before NVDA reads the native control, if REAPER exposes a reliable selected-tab state. It stays silent rather than guessing if the state cannot be determined. The **Alt+1/Alt+2** commands focus tab items, not fields inside them; the native dialog may determine how focus affects the displayed page.

**Limitations:** Native codec-specific, custom and disabled controls may not all respond to the assigned letters. Use native Tab/Shift+Tab in those cases. Subdialogs (such as file chooser, metadata and normalization) are not re-routed by Render shortcuts. The search does not change settings.

Manual checklist: Open REAPER Render to File; use Ctrl+F to search `sample`; verify F3/Shift+F3 wrap; press Alt+Z without changing the rate; cycle Alt+letter forwards then Alt+Shift+letter backwards; focus Alt+1/2 tabs; verify native Ctrl+Tab; focus Alt+R and verify rendering does not start until Space/Enter; close the dialog and verify shortcuts return to normal. Test with NVDA and OSARA after the Windows build.

Historical development notes: [TEST74.1 through TEST74.5](TEST74_1_RENDER_NAVIGATION.md).
