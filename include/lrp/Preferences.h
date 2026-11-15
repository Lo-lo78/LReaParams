#pragma once
#include "Navigator.h"
#include <filesystem>
#include <optional>
#include <vector>
#include <string>
namespace lrp {
struct ShortcutPreference { std::wstring description; Key original{}, assigned{}; };
struct Preferences {
    bool pluginFirst = true;
    bool compatibilityHook = false;
    std::vector<ShortcutPreference> shortcuts;
};
Preferences defaultPreferences();
Preferences loadPreferences(const std::filesystem::path& file);
bool savePreferences(const std::filesystem::path& file, const Preferences& preferences);
// Transactional: cancelled dialogs do not change the supplied preferences.
std::optional<Preferences> editPreferences(HWND owner, const Preferences& current);
Key mapPreferredShortcut(Key key, const Preferences& preferences) noexcept;
// Sets the shared title-format preference for FX Params and FX Memories.
void setFxNameFirst(bool enabled) noexcept;
bool fxNameFirst() noexcept;
}
