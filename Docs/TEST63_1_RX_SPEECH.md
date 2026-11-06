# TEST63.1 — iZotope RX 11: parameter speech readback

Based on the existing 0.0.63 release sources. This is a TEST change; the
public release version, installer and preset/profile formats remain 0.0.63.

## Reported regression

In `VST3: RX 11 De-click (iZotope)` and other RX 11 modules, changing a
combo/slider with Alt+arrows, Page Up/Down, Home or End speaks the previous
formatted value. A later NVDA parameter review reports the new value. The
host write is successful, but RX formats its displayed value after the write.

## Fix

The native REAPER normalized parameter setter remains immediate. RX module
parameter announcements are queued to the already-existing main-thread REAPER
timer, wait at least 65 ms, then require two matching formatted-readback
samples before speaking a value that differs from the pre-write display. If
RX rounds to the same text, wait at least 300 ms. The timer will not endlessly
hold a message (750 ms cap); if readback remains clearly stale, announce that
the value was updated without misreporting the old number.

Only versioned `RX N` FX labels receive this behavior. Other FX retain their
existing immediate announcements. A newer write replaces the old pending
message. Navigation, changed FX/track/take/project, dialogs, and exit cancel
old announcements. The settled readback is reused in both the spoken value
and the status suffix (CC and Auto), to avoid an immediate second RX query.

Included: single-value Alt/Value adjustments (arrows, Page Up/Down, Home,
End), current-parameter default reset, F7 selected-parameter adjustments,
and numeric editing.

## Manual Windows accessibility test

1. Open `VST3: RX 11 De-click (iZotope)` in FX Params. Select Sensitivity.
2. Use Alt+Up/Down and Alt+Page Up/Down. Each voice announcement must match
   the value obtained by NVDA review after the change.
3. Press Alt+Home (maximum) and Alt+End (minimum), also while in Value mode.
   Confirm the announcement refers to the new endpoint, not the old one.
4. Test a discrete RX combo in both directions, including first/last choice.
5. Hold repeated arrows and move rapidly to another parameter. There must be
   no late voice announcement belonging to the parameter left behind.
6. Switch FX, track and take, leave/reenter FX Params, and verify stale
   announcements cannot appear.
7. Test F7 selection and numeric direct input on RX, then repeat the same
   controls in ReaEQ, LJuno-116 and a non-RX plugin; there must be no
   added voice latency outside the RX family.

Test coverage: source-only static check in
`Testing/test63_1_rx_delayed_speech_static.py`; native Windows/MSVC compilation
and iZotope RX runtime behavior require GitHub Actions and local REAPER tests.
