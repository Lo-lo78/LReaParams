"""TEST61.3: F11 concise pin announcements. Source-only: do not compile locally."""
from pathlib import Path
p = Path(__file__).resolve().parents[1] / "src/FxNavigatorPinAudio.cpp"
s = p.read_text(encoding="utf-8")
start = s.index("std::string FxNavigator::pinAudioReview(bool context) const {")
end = s.index("bool FxNavigator::pinAudioSet(", start)
review = s[start:end]
assert 'pinAudioSelected(pinAudioColumn_, pinAudioChannel_) ? "Attive. " : "";' in review
assert '"Disconnected. "' not in review
assert '"Connected. "' not in review
assert 'message += output ? "Output " : "Input ";' in review
assert 'message += output ? ". Sends to track channel " : ". Receives from track channel ";' in review
assert 'speech_(pinAudioReview(false));' in s
assert 'speech_(pinAudioReview(true));' in s
assert 'pinAudioSet(pinAudioColumn_, pinAudioChannel_, connect) ?' in s
assert 'pinAudioSet(pinAudioColumn_, pinAudioChannel_, false) ?' in s
assert 'speech_("Not connected")' not in s
assert 'if (!pinAudioSelected(pinAudioColumn_, pinAudioChannel_)) { speech_(pinAudioReview(false)); return; }' in s
print("PASS TEST61.3: connected and empty pin announcements and all feedback paths")
