#pragma once
#include "Navigator.h"
#include <filesystem>
#include <array>
#include <functional>
#include <optional>
#include <vector>
#include <string>
namespace lrp {
enum class ShortcutScope { fx, track };
struct ShortcutPreference { std::wstring description; Key original{}, assigned{}; ShortcutScope scope = ShortcutScope::fx; };
// Reusable ordered message parts. FX: Heading, Plugin, Track, Custom;
// Track: Heading, Track, Custom. The fourth Track slot is reserved.
struct TitleMessage {
    std::array<int, 4> order{{0, 1, 2, 3}};
    std::array<bool, 4> enabled{{true, true, true, false}};
    std::wstring custom;
};
struct Preferences {
    bool pluginFirst = true;
    bool compatibilityHook = false;
    std::vector<ShortcutPreference> shortcuts;
    TitleMessage fxTitle;
    // Independently configurable titles: FX Memories, FX Browser and FX Pin Connector.
    // Existing FxTitle INI keys and shortcut indices remain untouched.
    std::array<TitleMessage, 3> fxExtraTitles{};
    TitleMessage trackTitle;
    // One distinct template for each additional Track Params window title:
    // Sends, Receives, FX TCP, Track MIDI, Hardware outputs, ReaRoute,
    // and the five Track Memories column titles. F1 stays trackTitle.
    std::array<TitleMessage, 11> trackExtraTitles{};
};
Preferences defaultPreferences();
Preferences loadPreferences(const std::filesystem::path& file);
bool savePreferences(const std::filesystem::path& file, const Preferences& preferences);
// Transactional: cancelled dialogs do not change the supplied preferences.
// Immediate non-modal feedback through REAPER/OSARA (no warning MessageBox).
std::optional<Preferences> editPreferences(HWND owner, const Preferences& current,
    const std::function<void(const std::string&)>& announce);
Key mapPreferredShortcut(Key key, const Preferences& preferences, ShortcutScope scope) noexcept;
// Sets the shared title-format preference for FX Params and FX Memories.
void setFxNameFirst(bool enabled) noexcept;
bool fxNameFirst() noexcept;
// Applied transactionally after Preferences.ini is saved; runtime title display
// is not affected by Cancel or Escape from the preferences window.
void setTitleMessages(const Preferences& settings);
std::string formatFxTitle(const std::string& fx, const std::string& track,
    const std::string& status = {});
// titleIndex 1: FX Memories; 2: FX Browser; 3: FX Pin Connector.
std::string formatFxPageTitle(const std::string& fx, const std::string& context,
    int titleIndex, const std::string& status = {});
std::wstring formatTrackTitle(const std::wstring& track);
std::wstring formatTrackPageTitle(const std::wstring& track, int titleIndex,
    const std::wstring& pageText = {});

}
