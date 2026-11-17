from pathlib import Path

source = (Path(__file__).resolve().parents[1] / "src" / "TrackNavigator.cpp").read_text(encoding="utf-8")
start = source.index("void TrackNavigator::announceTitle()")
end = source.index("std::wstring TrackNavigator::windowTitle()", start)
block = source[start:end]
assert "page_ == Page::tracks" in block
assert "title.find(trackName())" in block
assert "prefix + selected + parameterValueSpeech()" in block
assert "prefix + currentParameterSpeech()" in block
print("Track Params entry duplicate guard PASS")
