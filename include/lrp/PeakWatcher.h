#pragma once
#include "Navigator.h"
#include "ReaperApi.h"

namespace lrp {
// OSARA owns the audible response. These are the original Lua named actions.
inline bool isPeakWatcherShortcut(const Key& k) noexcept {
    return k.alt && !k.ctrl && !k.altGr && k.vk >= VK_F10 && k.vk <= VK_F12;
}
inline void executePeakWatcherShortcut(const Key& k) {
    if (k.repeat || !isPeakWatcherShortcut(k) || !Main_OnCommand || !NamedCommandLookup) return;
    const char* watcher1[] = {"_OSARA_RESETPEAKWATCHERT1",
        "_OSARA_REPORTPEAKWATCHERT1C1", "_OSARA_REPORTPEAKWATCHERT1C2"};
    const char* watcher2[] = {"_OSARA_RESETPEAKWATCHERT2",
        "_OSARA_REPORTPEAKWATCHERT2C1", "_OSARA_REPORTPEAKWATCHERT2C2"};
    const int index = static_cast<int>(k.vk - VK_F10);
    const int id = NamedCommandLookup(k.shift ? watcher2[index] : watcher1[index]);
    if (id > 0) Main_OnCommand(id, 0);
}
} // namespace lrp
