#pragma once
#include <cstdint>
#include <cwctype>
#include <string>
#ifdef _WIN32
#include <windows.h>
#endif
#include <utility>

namespace lrp {
// Shift+digits become punctuation on layouts such as Italian (Shift+1 -> !).
// Only type-ahead navigation interprets the physical number-row key as its
// digit. Native edit boxes, parameter values and other shortcuts retain the
// layout-translated character supplied by InputRouter.
inline wchar_t typeAheadCharacter(std::uint32_t virtualKey, bool shift,
                                  wchar_t translated) noexcept {
    if (shift && virtualKey >= static_cast<std::uint32_t>('0') &&
                 virtualKey <= static_cast<std::uint32_t>('9'))
        return static_cast<wchar_t>(virtualKey);
    // Also support numeric keypad VK_NUMPAD0..9 when Windows sends those VKs.
    if (shift && virtualKey >= 0x60U && virtualKey <= 0x69U)
        return static_cast<wchar_t>(L'0' + (virtualKey - 0x60U));
    return translated;
}
// Ephemeral keyboard navigation, never part of a .fx/.tp profile.
// Keyboard event times must be captured when REAPER receives the key,
// not when OSARA/NVDA has finished speaking the previous result.
#ifdef _WIN32
inline std::wstring typeAheadWide(const std::string& utf8) {
    if (utf8.empty()) return {};
    const int length = MultiByteToWideChar(CP_UTF8, MB_ERR_INVALID_CHARS,
        utf8.c_str(), static_cast<int>(utf8.size()), nullptr, 0);
    if (length <= 0) return {};
    std::wstring out(static_cast<size_t>(length), L'\0');
    return MultiByteToWideChar(CP_UTF8, MB_ERR_INVALID_CHARS,
        utf8.c_str(), static_cast<int>(utf8.size()), out.data(), length) == length ? out : std::wstring{};
}
#endif
class TypeAhead {
public:
    static constexpr std::uint32_t intervalMs = 1000;
    void reset() noexcept { buffer_.clear(); lastTime_ = 0; }
    const std::wstring& text() const noexcept { return buffer_; }

    template <class Label>
    int find(wchar_t character, std::uint32_t eventTime, bool repeated,
             int current, int count, bool backwards, Label&& label) {
        if (repeated || character < L'!' || count <= 0) return -1;
        const wchar_t c = lower(character);
        const bool contiguous = !buffer_.empty() &&
            static_cast<std::uint32_t>(eventTime - lastTime_) <= intervalMs;
        const bool sameLetterCycle = contiguous && buffer_.size() == 1 && buffer_[0] == c;
        const std::wstring candidate = contiguous && !sameLetterCycle ? buffer_ + c : std::wstring(1, c);
        // Single letters cycle from the NEXT entry. A multi-character match
        // must include the CURRENT entry so typing F then I does not skip the
        // Filter entry already reached by F.
        int match = locate(candidate, current, count, backwards,
                           candidate.size() == 1, label);
        if (match < 0 && candidate.size() > 1) {
            // An impossible prefix starts a new search with the last letter.
            // Never leave the keyboard locked to a misspelled partial word.
            match = locate(std::wstring(1, c), current, count, backwards, true, label);
            buffer_.assign(1, c);
        } else if (match >= 0) buffer_ = candidate;
        else buffer_.clear();
        lastTime_ = eventTime;
        return match;
    }
private:
    static wchar_t lower(wchar_t c) noexcept {
#ifdef _WIN32
        // Respect Windows Unicode case conversion also for Italian accents.
        CharLowerBuffW(&c, 1);
        return c;
#else
        return static_cast<wchar_t>(std::towlower(static_cast<wint_t>(c)));
#endif
    }
    // Rank beginning-of-label above beginning-of-word; never match an
    // arbitrary substring, because that makes quick typing unpredictable.
    static int rank(const std::wstring& label, const std::wstring& prefix) {
        if (prefix.empty()) return -1;
        for (std::size_t i = 0; i + prefix.size() <= label.size(); ++i) {
            const bool atWord = i == 0 || !std::iswalnum(static_cast<wint_t>(label[i - 1]));
            if (!atWord) continue;
            bool matches = true;
            for (std::size_t j = 0; j < prefix.size(); ++j) {
                if (lower(label[i + j]) != prefix[j]) { matches = false; break; }
            }
            if (matches) return i == 0 ? 0 : 1;
        }
        return -1;
    }
    template <class Label>
    static int locate(const std::wstring& prefix, int current, int count,
                      bool backwards, bool cycle, Label&& label) {
        int fallback = -1;
        for (int offset = cycle ? 1 : 0; offset < count + (cycle ? 1 : 0); ++offset) {
            const int index = backwards ? (current + count - (offset % count)) % count
                                        : (current + offset) % count;
            const int quality = rank(label(index), prefix);
            if (quality == 0) return index;
            if (quality == 1 && fallback < 0) fallback = index;
        }
        return fallback;
    }
    std::wstring buffer_;
    std::uint32_t lastTime_ = 0;
};
} // namespace lrp
