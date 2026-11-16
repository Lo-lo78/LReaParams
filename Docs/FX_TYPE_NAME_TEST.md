# TEST70.1 - FX Type and Name title components

FX Params > Preferences (Ctrl+P) > Messages > FX Params > Title: FX Params.
The formerly combined Plugin component is now split into independently configurable **Type** and **Name**. Type is disabled by default; Name remains enabled. Space toggles a part and Alt+Up/Down changes its order. This applies to the FX Params, FX Memories and FX Pin Connector titles; FX Browser has no plugin name part.

For REAPER names beginning with an exact supported format marker followed by a colon and a space, such as `VST3i: LJuno-116 (Lo-lo)`, the title uses `LJuno-116 (Lo-lo)` for Name and `VST3i:` for Type. Supported markers: VST3i, VST3, VST2i, VST2, VSTi, VST, CLAPi, CLAP, JSFX, JS, DXi, DX, AUi, AU, LV2i, LV2. Unknown prefixes are not stripped, to avoid truncating plugin names. Matching is anchored and case-insensitive.

The previous title component order and enablement in Preferences.ini is migrated from four to five parts without losing saved ordering, custom text or enabled states. The new Type part is inserted directly before Name and starts disabled. No changes are made to stored FX identification or to FX parameter browser data.

Verification: Tools/audit.py, Testing/test69_message_title_tree_static.py and Testing/test70_1_fx_type_name_static.py. Windows MSVC and NVDA runtime tests still required.
