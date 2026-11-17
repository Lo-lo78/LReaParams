"""TEST71.1: FX/track switch speech uses editable title templates."""
from pathlib import Path
r = Path(__file__).resolve().parents[1]
fx = (r/'src/FxNavigator.cpp').read_text(encoding='utf-8')
fxctx = (r/'src/FxNavigatorContexts.cpp').read_text(encoding='utf-8')
track = (r/'src/TrackNavigatorFxTcp.cpp').read_text(encoding='utf-8')
tracklist = (r/'src/TrackNavigatorFxTcpList.cpp').read_text(encoding='utf-8')
pref = (r/'src/Preferences.cpp').read_text(encoding='utf-8')
header = (r/'include/lrp/Preferences.h').read_text(encoding='utf-8')
assert 'return title.empty() ? currentParameterSpeech() : title + ". " + currentParameterSpeech();' in fx
assert 'if (result.empty()) return {};' in pref
assert 'if (!memories) return formatFxTitle(fxDisplayName(), contextName(), status);' in fx
assert 'speech_(fxContextAnnouncement());' in fx # FX and track switches
assert 'speech_(what + ". " + fxContextAnnouncement());' in fxctx # Context switch
assert 'formatTrackFxNameForSpeech(column->name)' in track
assert 'formatTrackFxNameForSpeech(' in tracklist
assert 'std::string formatTrackFxNameForSpeech(const std::string& raw);' in header
assert 'const auto parsed = splitReaperFxName(raw);' in pref
assert 'const auto& cfg = activeTrackExtraTitles[2];' in pref
assert 'part != 2 && part != 4' in pref
assert 'return {{}, raw};' in pref # unknown prefixes stay intact
print('TEST71.1 FX/Track switch and F4 spoken Type/Name preferences PASS')
