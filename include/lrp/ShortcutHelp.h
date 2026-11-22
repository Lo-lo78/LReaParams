#pragma once
// Shift+F1 is a focus-transparent, context-owned shortcut inspector.
// This module never runs a navigator handler or queries REAPER's Action List.
#include "Preferences.h"
#include <string>

namespace lrp {
bool shortcutHelpToggle(const Key& key) noexcept;
std::string shortcutHelpKeyName(const Key& key);
std::string shortcutHelpUtf8(const std::wstring& text);
// The *physical* gesture is resolved through the exact current Preferences
// mapping, and the effective navigator is queried WITHOUT executing the key.
std::string shortcutHelpDescription(const Key& physical, const Preferences* preferences,
                                    const Navigator& navigator);
} // namespace lrp
