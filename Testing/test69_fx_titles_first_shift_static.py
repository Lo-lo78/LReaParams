"""Source-only guards: FX title topics and first Shift+arrow stroke."""
from pathlib import Path
root = Path(__file__).resolve().parents[1]
read = lambda path: (root/path).read_text(encoding="utf-8")
pref = read("src/Preferences.cpp")
header = read("include/lrp/Preferences.h")
fx = read("src/FxNavigator.cpp")
track = read("src/TrackNavigator.cpp")
for name in ("Title: FX Params", "Title: FX Memories", "Title: FX Browser", "Title: FX Pin Connector"):
    assert name in pref, name
assert "std::array<TitleMessage, 3> fxExtraTitles" in header
assert "FxTitlePage" in pref and "loadTitle(path, key.c_str(), p.fxExtraTitles" in pref
assert "saveTitle(path, key.c_str(), p.fxExtraTitles" in pref
assert "activeFxExtraTitles = settings.fxExtraTitles" in pref
assert "formatFxPageTitle(fxDisplayName(), contextName(), 1, status)" in fx
assert "formatFxPageTitle({}, browserContext, 2)" in fx
assert "formatFxPageTitle(fxDisplayName(), contextName(), 3)" in fx
section = track.split("void TrackNavigator::extendTrackSelection(int direction, bool page) {")[1].split("void TrackNavigator::extendTrackSelectionToEdge")[0]
assert "if (!selectionStroke_)" in section
first = section.split("if (!selectionStroke_)")[1].split("const int jump")[0]
assert "selectionAnchorRow_ = row_;" in first and "applyRangeSelection(row_, row_);" in first
assert "announceSelection();" in first and "return;" in first
assert "row_ = next;" not in first
assert "row_ = next;" in section.split("const int jump")[1]
assert "if (selectionBuilding_) return;" in track  # retain disjoint selections when cursor moves
assert "Tools\\push_lreaparams.cmd" in read("Docs/PREFERENCES_TEST.md")
print("TEST69 FX Memories/Browser/Pin title templates and first-press Shift anchor PASS (static)")
