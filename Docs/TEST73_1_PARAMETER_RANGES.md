# TEST73.1 – Parameter and CC ranges (not a stable release)

Starting point: LReaParams 0.0.73. The existing published ReaPack history, index generator, and push script are unchanged.

## Range shortcuts – FX Params and Track Params

- **Alt+R**: range of the selected writable parameter. The native accessible dialog has Minimum, Maximum, OK and Cancel in Tab order. Enter confirms, Escape cancels without saving. The range controls the extension’s keyboard travel; the existing Step remains independent.
- **Alt+C**: MIDI CC input range, **0–127**, for the selected parameter. Requires an enabled fixed CC already assigned to that parameter. The adjusted limits appear next to the CC in the MIDI CC memories column; default limits do not add text.
- **Alt+F**: MIDI CC input range, **0–127**, for the active learned floating CC. The range is stored **only in memory** until REAPER exits, across FX and Track navigators. It is never serialized or shown in any memories column.

The dialog title includes the selected parameter name. Both numeric fields are editable. Decimal comma is accepted. Minimum must be strictly below Maximum. The default range can be restored by setting the entire allowed interval.

## Parameter units

- FX Params and FX TCP parameters use deterministic **normalized 0–100 percent**, not parsed text labels. This deliberately avoids guessing the scale of continuous/combo parameters such as those displaying Hertz.
- Track Params Volume uses **dB**. Pan and Width use **percent**. Discrete send/track controls use their numeric integer states where editable.
- The new Parameter Ranges memories column contains only customized persistent ranges. MIDI CC memories show customized CC limits next to assigned fixed CCs.
- No global volume-range rule remains, and **Ctrl+Shift+I** is removed. The former Volume Ranges memories column is removed; older section data, if present, has no effect.

## Tests and known boundaries

Source-only audit and targeted static checks validate the integration. This test version **must be built with MSVC and tested in REAPER with NVDA/OSARA** before tagging or publishing. In particular, verify combo movement, MIDI pickup, focus return after Enter/Escape, normal/Value/F7 navigation, project reload, per-track/send isolation, and the floating range’s process lifetime. F5–F7 special Track pages are not currently included in the generalized range editor.
