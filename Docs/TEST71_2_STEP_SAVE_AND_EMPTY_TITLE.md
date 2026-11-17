# TEST71.2 - Empty titles and explicit Step save

- If every Title component is disabled in Messages, the title must be blank (no automatic FX Params / Track Params). Only the parameter-value announcement remains, without a leading punctuation mark.
- FX and Track F1-F3: Alt+Left/Right previews a Step, used immediately for value increments without modifying the profile. Alt+S saves the current Step for the active parameter. Unsaved adjustments are discarded on parameter change/re-entry. Ctrl+Backspace also previews Step 0 (save it with Alt+S).
- FX F7 multi-selection: Step adjustments are previewed for selected parameters; Alt+S commits them to the FX profile.
- Track F4 FX TCP: Alt+Left/Right previews Step; Alt+S writes it to the .tp memory. Unsaved preview is discarded on changing FX/parameter.
- FX Memories and Track Memories: adjusting Step with Alt+Left/Right previews only; use Alt+S to save. An explicit Delete or memory reset retains its previous meaning.
- No updates to version number, ReaPack workflow, publisher or index.xml.

Test in REAPER/NVDA: disable all parts of the FX and Track Title; change FX and track; set Step +3 without saving, leave and return (old value expected); set Step +3 and Alt+S, leave and return (+3 expected); repeat in Track F1/F2/F3 and F4.
