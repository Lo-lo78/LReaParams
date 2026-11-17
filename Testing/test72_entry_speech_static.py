"""Regression for single contextual FX / Track opening announcement."""
from pathlib import Path
root = Path(__file__).resolve().parents[1]
ext = (root / 'src/Extension.cpp').read_text(encoding='utf-8')
track = (root / 'src/TrackNavigator.cpp').read_text(encoding='utf-8')
fx = (root / 'src/FxNavigator.cpp').read_text(encoding='utf-8')
proxy = (root / 'src/TitleProxy.cpp').read_text(encoding='utf-8')
assert 'desired->windowTitle(), std::string{}' in ext
assert 'initialFocusReviewSuppressed_ = true;' in proxy
assert 'initialFocusReviewSuppressed_ ? 0' in proxy
assert 'initialFocusReviewSuppressed_ = false;' in proxy
assert 'titleProxy_.updateReviewLine(desired->reviewLine())' in ext
assert ext.index('desired->windowTitle(), std::string{}') < ext.index('titleProxy_.updateReviewLine(desired->reviewLine())') < ext.index('else desired->announceTitle();')
assert 'speech_(prefix + selected + entry->title + ", " + valueText(*entry, get(*entry)) + statusSuffix());' in track
assert 'speech_(prefix + currentParameterSpeech());' in track  # routing pages unchanged
assert 'title + ". " + currentParameterSpeech()' in fx
print('Entry speech regression OK')
