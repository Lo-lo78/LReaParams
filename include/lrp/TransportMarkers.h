#pragma once
#include "Navigator.h"
#include "ReaperApi.h"
#include <functional>
#include <string>

namespace lrp {
// Shared, exact shortcut contract for FX Params (including FX browser/F7/F8)
// and Track Params F1-F8.  Never activate these chords in native EDIT fields,
// confirmation prompts, or while a Right-Alt/AltGr character is being typed.
bool isTransportMarkerShortcut(const Key& key) noexcept;
void executeTransportMarkerShortcut(const Key& key, ReaProject* project,
                                    int& spokenMarkerEdge,
                                    const std::function<void(const std::string&)>& speech);
} // namespace lrp
