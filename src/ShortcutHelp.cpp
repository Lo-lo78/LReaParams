#include "lrp/ShortcutHelp.h"
#include <windows.h>
#include <string>

namespace lrp {
namespace {
bool sameGesture(const Key& a, const Key& b) noexcept {
    return a.vk == b.vk && a.ctrl == b.ctrl && a.alt == b.alt &&
        a.shift == b.shift && !a.altGr && !b.altGr;
}
std::string keyBase(UINT vk) {
    if (vk >= 'A' && vk <= 'Z') return std::string(1, static_cast<char>(vk));
    if (vk >= '0' && vk <= '9') return std::string(1, static_cast<char>(vk));
    if (vk >= VK_F1 && vk <= VK_F24) return "F" + std::to_string(vk - VK_F1 + 1);
    switch (vk) {
    case VK_UP: return "Up"; case VK_DOWN: return "Down";
    case VK_LEFT: return "Left"; case VK_RIGHT: return "Right";
    case VK_PRIOR: return "Page Up"; case VK_NEXT: return "Page Down";
    case VK_HOME: return "Home"; case VK_END: return "End";
    case VK_TAB: return "Tab"; case VK_RETURN: return "Enter";
    case VK_BACK: return "Backspace"; case VK_DELETE: return "Delete";
    case VK_ESCAPE: return "Escape"; case VK_SPACE: return "Space";
    case VK_INSERT: return "Insert";
    }
    wchar_t name[80]{};
    UINT sc = MapVirtualKeyW(vk, MAPVK_VK_TO_VSC);
    if (GetKeyNameTextW(static_cast<LONG>(sc << 16), name, 80)) return shortcutHelpUtf8(name);
    return "Key " + std::to_string(vk);
}
}
bool shortcutHelpToggle(const Key& key) noexcept {
    return key.vk == VK_F1 && key.shift && !key.ctrl && !key.alt && !key.altGr;
}
std::string shortcutHelpUtf8(const std::wstring& text) {
    if (text.empty()) return {};
    const int count = WideCharToMultiByte(CP_UTF8, 0, text.data(), static_cast<int>(text.size()),
        nullptr, 0, nullptr, nullptr);
    if (count <= 0) return {};
    std::string out(static_cast<size_t>(count), '\0');
    WideCharToMultiByte(CP_UTF8, 0, text.data(), static_cast<int>(text.size()),
        &out[0], count, nullptr, nullptr);
    return out;
}
std::string shortcutHelpKeyName(const Key& key) {
    std::string out;
    if (key.altGr) out += "AltGr+";
    else {
        if (key.ctrl) out += "Ctrl+";
        if (key.alt) out += "Alt+";
    }
    if (key.shift) out += "Shift+";
    return out + keyBase(key.vk);
}
std::string shortcutHelpDescription(const Key& physical, const Preferences* preferences,
                                    const Navigator& navigator) {
    const std::string gesture = shortcutHelpKeyName(physical) + ". ";
    if (!navigator.active()) return gesture + "No LReaParams navigation context";
    // Ctrl+P is Extension-owned, deliberately excluded from remapping.
    if (physical.vk == 'P' && physical.ctrl && !physical.alt && !physical.shift && !physical.altGr)
        return gesture + "Open LReaParams Preferences";
    const ShortcutScope scope = navigator.isTrackNavigator() ? ShortcutScope::track : ShortcutScope::fx;
    const Key mapped = preferences ? mapPreferredShortcut(physical, *preferences, scope) : physical;
    if (!mapped.vk || !navigator.accepts(mapped))
        return gesture + "No active LReaParams shortcut in this context";
    // A navigator can describe a special dynamic page's behavior more precisely
    // than the user-editable Preferences label. This is always read-only.
    if (const std::string current = navigator.shortcutDescription(mapped); !current.empty())
        return gesture + current;
    if (preferences) {
        for (const auto& entry : preferences->shortcuts) {
            if (entry.scope == scope && sameGesture(entry.assigned, physical))
                return gesture + shortcutHelpUtf8(entry.description);
        }
    }
    // Unregistered keys may be text entry, OSARA peak gestures, or future
    // navigator keys. Never invent a command or read REAPER's Action List.
    return gesture + "No documented LReaParams shortcut in this context";
}
} // namespace lrp
