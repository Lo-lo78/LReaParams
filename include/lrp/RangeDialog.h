#pragma once
#include "ParameterRanges.h"
#include <windows.h>
#include <string>
namespace lrp {
// True only while a native range dialog owns the REAPER UI thread.
// Extension::tick must not end navigation because its focus is temporarily modal.
bool rangeDialogModalActive() noexcept;
// Display the selected parameter name, including UTF-8 plug-in names,
// in each native dialog title so NVDA identifies the edited control.
std::wstring rangeNameUtf8(const std::string& text);
// Native modal Windows dialog. Two separate labeled EDIT fields, standard
// Tab/Shift+Tab, Enter/OK and Escape/Cancel. No saved intermediate edits.
bool editParameterRange(HWND owner, const std::wstring& title,
                        double allowedMin, double allowedMax,
                        ParameterRange& value, bool integers = false);
} // namespace lrp
