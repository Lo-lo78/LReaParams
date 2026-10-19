"""TEST56.10.2 — 128-channel F5 pin-bank source contract and boundary model.

Only Python source checks and arithmetic: NO native compilation, REAPER or NVDA.
"""
from pathlib import Path

root = Path(__file__).resolve().parents[1]
src = (root / "src/TrackNavigatorPinAudio.cpp").read_text(encoding="utf-8")
sdk = (root / "third_party/reaper-sdk/reaper_plugin_functions.h").read_text(encoding="utf-8")

# The REAPER SDK documents a second independent 64-bit bank at pin+0x1000000.
assert "Add 0x1000000 to pin index in order to access the second 64 bits" in sdk
assert "constexpr int kMaxAudioTrackChannels = 128;" in src
assert "constexpr int kSecond64PinBank = 0x1000000;" in src
assert "channel >= 64 ? kSecond64PinBank : 0" in src
assert "return channel % 64;" in src
assert 'GetMediaTrackInfo_Value(track_, "I_NCHAN")' in src
assert "pinAudioChannels_ = std::clamp(static_cast<int>(channels), 2, kMaxAudioTrackChannels);" in src
assert "pinAudioInputs_ = std::clamp(inputPins, 0, kMaxAudioTrackChannels);" in src
assert "pinAudioOutputs_ = std::clamp(outputPins, 0, kMaxAudioTrackChannels);" in src

read = src.split("bool TrackNavigator::pinAudioSelected(", 1)[1].split(
    "std::string TrackNavigator::pinAudioReview(", 1
)[0]
write = src.split("bool TrackNavigator::pinAudioSet(", 1)[1].split(
    "void TrackNavigator::pinAudioMove(", 1
)[0]
for body in (read, write):
    assert "const int bankPin = pinIndexForChannel(pin, channel);" in body
    assert "const int bit = channelWithinPinBank(channel);" in body
    assert "TrackFX_GetPinMappings(track_, fx, output ? 1 : 0, bankPin, &high)" in body
    assert "std::uint32_t" in body
    assert "bit < 32" in body
assert "(bit - 32)" in read
assert "const std::uint32_t mask = std::uint32_t{1} << (bit % 32);" in write
assert "std::uint32_t& bits = bit < 32 ? lowBits : highBits;" in write
assert "TrackFX_SetPinMappings(track_, fx, output ? 1 : 0, bankPin," in write
assert "pinAudioSelected(column, channel) == selected" in write
assert "Undo_BeginBlock2" in write and "Undo_EndBlock2" in write
assert "SetMediaTrackInfo_Value" not in src, "F5 must never resize a track"

# Pure-Python bit-bank MODEL for boundary coverage; not a C++/host runtime test.
# The other three 32-bit words MUST remain unchanged by a single-cell write.
def index_word_bit(pin, channel):
    assert 0 <= channel < 128
    bank_pin = pin + (0x1000000 if channel >= 64 else 0)
    within = channel % 64
    return bank_pin, within // 32, 1 << (within % 32)

for pin in (0, 1, 63, 127):
    masks = {pin: [0xA5A5A5A5, 0x5A5A5A5A, 0, 0]}
    for channel in (0, 31, 32, 63, 64, 65, 95, 96, 126, 127):
        bankpin, word, mask = index_word_bit(pin, channel)
        assert bankpin == pin + (0x1000000 if channel >= 64 else 0)
        assert 0 <= word < 2 and 0 < mask <= 0x80000000
        realword = (2 if channel >= 64 else 0) + word
        old = masks[pin][:]
        masks[pin][realword] |= mask
        assert (masks[pin][realword] & mask) != 0
        assert all(masks[pin][i] == old[i] for i in range(4) if i != realword)
        masks[pin][realword] &= ~mask
        assert (masks[pin][realword] & mask) == 0
        assert all(masks[pin][i] == old[i] for i in range(4) if i != realword)

assert index_word_bit(0, 63) == (0, 1, 0x80000000)
assert index_word_bit(0, 64) == (0x1000000, 0, 1)
assert index_word_bit(0, 127) == (0x1000000, 1, 0x80000000)
print("PASS TEST56.10.2: F5 128 channels, independent bit banks, boundaries and readback")
