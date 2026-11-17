"""Regression: native NVDA entry focus with OSARA fallback only."""
from pathlib import Path
root = Path(__file__).resolve().parents[1]
ext = (root / 'src/Extension.cpp').read_text(encoding='utf-8')
proxy = (root / 'src/TitleProxy.cpp').read_text(encoding='utf-8')
track = (root / 'src/TrackNavigator.cpp').read_text(encoding='utf-8')
assert 'desired->windowTitle(), desired->reviewLine()' in ext
assert 'reviewText_ = toWide(initialReviewLine)' in proxy
assert 'initialFocusReviewSuppressed_' not in proxy
assert 'if (!titleProxyActive_) {' in ext
block = ext.split('if (!titleProxyActive_) {', 1)[1].split('}', 1)[0]
assert 'desired->announceTitle();' in block
assert ext.index('desired->windowTitle(), desired->reviewLine()') < ext.index('if (!titleProxyActive_) {')
assert 'void TrackNavigator::announce() { speech_(parameterValueSpeech()); }' in track
print('Native NVDA entry regression OK')
