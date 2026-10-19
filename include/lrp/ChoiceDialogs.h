#pragma once
#include <windows.h>
#include <optional>

namespace lrp {
// Native Win32, screen-reader accessible dialogs. The two documented shortcuts
// act on physical virtual keys rather than localized Windows button mnemonics.
// Escape/close returns nullopt, and never selects the potentially destructive option.
std::optional<bool> confirmLegacyImport(HWND owner, bool atStartup);
// 1 = REAPER SDK accelerator; 2 = main-thread compatibility hook.
std::optional<int> chooseKeyboardBackend(HWND owner, bool usingCompatibilityHook);
}
