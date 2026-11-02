# LReaParams 0.0.62 – TEST62.3: editing multiple selected FX parameters and Step memories

Experimental source for GitHub Actions (not yet validated in REAPER/NVDA). Derived from TEST62.2.

## F7, selected parameters

- Use existing F7 selection gestures (Shift+Space, Ctrl+A, Shift+arrows). A selected parameter may occur more than once in Custom Order / a group; it is edited only once at the DSP level.
- **Alt+Left / Alt+Right:** set **all selected parameter Steps** to the same next value (-10 through +10), based on the currently focused Step. With no selection the original single-parameter behavior is preserved. NVDA announces the new Step and number of unique selected parameters. These Steps are persistent in the `.fx` plugin profile, shared between Custom Order and all groups.
- **Alt+Up / Alt+Down** (and Alt+Page Up/Down): move selected parameter values, **each using its own saved Step**. The operation is grouped into one REAPER Undo. If a selected parameter type cannot be modified safely in bulk (e.g. synthetic virtual band action, dynamics detector mode), no selected values are written; the user is told why. Ordinary single focused selection retains the original special parameter handlers.
- **Ctrl+E** in F7 opens the existing numeric editor. When multiple unique parameters are selected, entering an exact numeric value applies it to all only if compatible. For ReaEQ, all selected controls must be the **same band property** (e.g. all Gains). Example: select three ReaEQ band Gains, Ctrl+E, enter `-3`, press Enter; all three become -3 dB in a single Undo. A mixture of Gain/Frequency/Bandwidth is rejected without writing values. For other plug-ins, formatted numeric editing requires compatible units, monotonic formatter and valid range for each selected parameter; raw numeric editing requires a valid host range for each. Failed host writes attempt rollback and report possible incomplete undo.
- Ctrl+E with no bulk selection preserves the previous single-parameter numeric editor.
- The source/selection/order is not changed by Step and value edits. Plugin Order's parameter listing is unmodified (values remain editable as before).

## FX Memories (Ctrl+Shift+M or the existing FX Memories action)

A new **eighth column**, `Parameter Steps`, is appended **after Default values**; the first seven columns retain their positions. Each nonzero Step appears as `<parameter name>. Step <signed number>`.

- Left/Right browse nonempty columns, Up/Down browse rows, Tab repeats.
- While in Parameter Steps, Alt+Left / Alt+Right adjusts the *memory row's parameter Step*, not the parameter currently focused in the grid. Step 0 removes the row from this memory list.
- Delete on a Step memory resets that parameter to Step 0. This only resets its Step, not its sound value, group membership, or visibility.
- Enter on a Step memory opens the corresponding parameter in Plugin Order, which always shows the complete original list.
- Legacy Lua Step settings remain readable; native Step changes are saved under `lrp_param_step_scales_v1` in the existing `.fx` file (the original Lua key is not overwritten).

## Recommended checks in REAPER

1. Insert ReaEQ with at least three bands. Open FX Params, F7 and select three Gains; Alt+Left/Right should alter all selected Steps. Check a few separately with F3 / step navigation.
2. Ctrl+E, write `-3`, press Enter. Verify all three ReaEQ gains report -3 dB; one REAPER Undo should revert the whole batch.
3. Give the selected gains unequal starting values, then Alt+Up and confirm each moves by its own stored Step, rather than forcing the same absolute value.
4. In FX Memories navigate to `Parameter Steps`; verify each saved nonzero Step is listed, modify one with Alt+Left/Right, and remove one with Delete. Return to FX Params; settings must be reflected there and survive reopening the plugin / REAPER.
5. Select two occurrences of the same parameter within a group (Ctrl+C/V duplicate); applying a value edit must change the DSP control once, not twice.
6. Check filtered F7 selection and intentionally hidden parameters: edits must use unfiltered occurrence positions and not affect hidden or unselected controls inadvertently.
7. Recheck TEST62.1 and TEST62.2: named groups say `Group Bass`; empty groups remain saved; copy/cut/paste and existing seven memory columns remain unchanged.

## Build status

Python static source checks only. Windows x64 MSVC build, profile C++ tests and interactive NVDA/OSARA/REAPER behavior require GitHub Actions and user testing. Public version number remains 0.0.62.
