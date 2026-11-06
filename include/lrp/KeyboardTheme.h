#pragma once
// TEST64.1: pure, platform-independent helpers for the optional FX Params
// Keyboard theme. Exactly 36 physical alphanumeric virtual keys per page.
// No second FX value engine, profile editor or REAPER shortcut dispatcher.
#include <array>
#include <string>
#include <string_view>

namespace lrp::keyboard {
inline constexpr std::string_view keys = "1234567890QWERTYUIOPASDFGHJKLZXCVBNM";
inline constexpr int pageSize = 36;
inline constexpr int contextCount = 14; // Plugin, Custom, Group 1..12
static_assert(keys.size() == pageSize, "Keyboard must contain exactly 36 keys");

inline int offset(unsigned int virtualKey) noexcept {
    // Windows VK_0..VK_9 and VK_A..VK_Z equal their ASCII uppercase names.
    // Ignore OEM, numpad and non-alphanumeric keys here.
    if (!((virtualKey >= '0' && virtualKey <= '9') ||
          (virtualKey >= 'A' && virtualKey <= 'Z'))) return -1;
    const auto found = keys.find(static_cast<char>(virtualKey));
    return found == std::string_view::npos ? -1 : static_cast<int>(found);
}
inline int keyTarget(int currentPosition, int keyIndex, int total) noexcept {
    if (currentPosition < 0 || currentPosition >= total ||
        keyIndex < 0 || keyIndex >= pageSize) return -1;
    const int first = (currentPosition / pageSize) * pageSize;
    const int target = first + keyIndex;
    return target < total ? target : -1;
}
inline int pageTarget(int currentPosition, int direction, int total) noexcept {
    if (currentPosition < 0 || currentPosition >= total ||
        (direction != -1 && direction != 1)) return -1;
    const int currentPage = currentPosition / pageSize;
    const int pages = (total + pageSize - 1) / pageSize;
    const int next = currentPage + direction;
    return next >= 0 && next < pages ? next * pageSize : -1;
}
inline std::array<bool, contextCount> decode(std::string_view serialized) noexcept {
    std::array<bool, contextCount> themes{};
    // Invalid/old profile => Standard in every context. No partial override.
    if (serialized.size() != contextCount) return themes;
    for (const char c : serialized) if (c != '0' && c != '1') return {};
    for (int i = 0; i < contextCount; ++i)
        themes[static_cast<std::size_t>(i)] = serialized[static_cast<std::size_t>(i)] == '1';
    return themes;
}
inline std::string encode(const std::array<bool, contextCount>& themes) {
    // Omit the optional Extra record when everything is Standard.
    std::string value(contextCount, '0');
    bool any = false;
    for (int i = 0; i < contextCount; ++i) {
        if (themes[static_cast<std::size_t>(i)]) {
            value[static_cast<std::size_t>(i)] = '1';
            any = true;
        }
    }
    return any ? value : std::string{};
}
} // namespace lrp::keyboard
