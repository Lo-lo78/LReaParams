#include "lrp/TrackNavigator.h"
#include <algorithm>
#include <cstdio>
#include <cstring>
#include <stdexcept>
#include <set>
#include <iterator>

namespace lrp {
namespace {
constexpr const char* columnNames[] = {"MIDI CC", "Parameter Steps", "Parameter Speech",
                                       "Track Positions", "Volume Ranges"};
const char* trackPages[] = {"Track", "Sends", "Receives"};
// Like FX Memories, show saved *differences* from the default, not every
// possible parameter, zero-step, silent CC, or unused track slot.
std::string guidString(const GUID& g) {
    char text[64]{};
    std::snprintf(text, sizeof(text), "{%08lX-%04hX-%04hX-%02hhX%02hhX-%02hhX%02hhX%02hhX%02hhX%02hhX%02hhX}",
        static_cast<unsigned long>(g.Data1), static_cast<unsigned short>(g.Data2),
        static_cast<unsigned short>(g.Data3), g.Data4[0], g.Data4[1], g.Data4[2], g.Data4[3],
        g.Data4[4], g.Data4[5], g.Data4[6], g.Data4[7]);
    return text;
}
}
std::string TrackNavigator::trackGuidText(MediaTrack* target) const {
    const GUID* guid = target && ValidatePtr2(project_, target, "MediaTrack*") ? GetTrackGUID(target) : nullptr;
    return guid ? guidString(*guid) : std::string();
}
MediaTrack* TrackNavigator::findSavedTrack(const std::string& guid) const {
    if (guid.empty() || !project_) return nullptr;
    if (MediaTrack* master = GetMasterTrack(project_))
        if (trackGuidText(master) == guid) return master;
    for (int i = 0, count = CountTracks(project_); i < count; ++i) {
        MediaTrack* candidate = GetTrack(project_, i);
        if (candidate && trackGuidText(candidate) == guid) return candidate;
    }
    return nullptr;
}
std::string TrackNavigator::savedTrackLabel(const std::string& guid) const {
    MediaTrack* track = findSavedTrack(guid);
    if (!track) return guid.empty() ? "Empty" : "Track unavailable";
    char name[2048]{};
    if (GetTrackName) GetTrackName(track, name, static_cast<int>(sizeof(name)));
    const int n = static_cast<int>(GetMediaTrackInfo_Value(track, "IP_TRACKNUMBER"));
    const std::string label = name[0] ? name : "unnamed";
    return "Track " + std::to_string(n) + ", " + label;
}
void TrackNavigator::saveTrackSlot(int slot) {
    if (pendingRouting_ != RoutingKind::none || learnCc_) {
        speech_("Finish routing or CC learn before saving a track position"); return;
    }
    const auto existing = memory_.trackSlot(slot);
    if (!existing.empty()) {
        speech_("Slot " + std::to_string(slot) + " occupied. " + savedTrackLabel(existing) +
                ". Delete it from Track Memories to replace");
        return;
    }
    const std::string guid = trackGuidText(track_);
    if (guid.empty()) { speech_("No track to save"); return; }
    memory_.setTrackSlot(slot, guid);
    memory_.flush();
    speech_("Slot " + std::to_string(slot) + " saved. " + savedTrackLabel(guid));
}
void TrackNavigator::recallTrackSlot(int slot) {
    if (pendingRouting_ != RoutingKind::none || learnCc_) {
        speech_("Finish routing or CC learn before recalling a track position"); return;
    }
    const auto saved = memory_.trackSlot(slot);
    if (saved.empty()) { speech_("Empty track memory " + std::to_string(slot)); return; }
    MediaTrack* wanted = findSavedTrack(saved);
    if (!wanted) { speech_("Saved track no longer exists. Slot " + std::to_string(slot)); return; }
    // The physical track is authoritative; never use a stale row index.
    const auto it = std::find_if(rows_.begin(), rows_.end(),
        [wanted](const TrackRow& item) { return item.track == wanted; });
    if (it == rows_.end()) {
        speech_("Saved track is hidden in TCP. Open its parent folder first"); return;
    }
    rememberPosition();
    row_ = static_cast<int>(it - rows_.begin());
    track_ = wanted;
    page_ = Page::tracks;
    detailIndex_ = 0;
    valueMode_ = false;
    buildEntries();
    parameter_ = std::clamp(parameter_, 0, static_cast<int>(entries_.size()) - 1);
    stepScale_ = memory_.step(parameterKey());
    syncCursorToReaper();
    rememberPosition();
    speech_("Slot " + std::to_string(slot) + ". " + savedTrackLabel(saved) + ". " + parameterValueSpeech());
}
bool TrackNavigator::openTrackMemories(bool standalone) {
    if (!active_ || memoryManager_ || filterEditing_ || numericEditing_) return false;
    if (pendingRouting_ != RoutingKind::none || learnCc_) {
        speech_("Finish or cancel routing and CC learn before opening Track Memories");
        return false;
    }
    // The editor never changes REAPER parameter values by opening.
    rememberPosition();
    valueMode_ = false;
    memoryStandalone_ = standalone;
    memoryManager_ = true;
    memoryColumn_ = memoryRow_ = 0;
    rebuildMemoryList();
    // Mirror FX Memories: open on the first populated column rather than
    // silently landing on an empty MIDI list. Announce the first item once.
    while (memoryColumn_ < 4 && memoryItems_.empty()) {
        ++memoryColumn_;
        rebuildMemoryList();
    }
    if (!standalone) speakMemory("Track Memories");
    // The standalone action gets its single initial announcement from
    // Extension::launchNavigator -> announceTitle(), as FX Memories does.
    return true;
}
void TrackNavigator::rebuildMemoryList() {
    memoryItems_.clear();
    // Human-readable target names in MIDI CC and speech lists, not raw GUIDs.
    const auto targetLabel = [this](const std::string& identity) {
        const auto first = identity.find('|');
        if (first == std::string::npos) return identity;
        if (identity.rfind("Track|", 0) == 0) {
            const auto last = identity.rfind('|');
            if (last == first || last == std::string::npos) return identity;
            return savedTrackLabel(identity.substr(first + 1, last - first - 1)) +
                ", " + identity.substr(last + 1);
        }
        if (identity.rfind("Sends|", 0) == 0) {
            const auto second = identity.find('|', first + 1);
            if (second == std::string::npos) return identity;
            const auto third = identity.find('|', second + 1);
            if (third == std::string::npos) return identity;
            const auto fourth = identity.find('|', third + 1);
            if (fourth == std::string::npos) return identity;
            return savedTrackLabel(identity.substr(first + 1, second - first - 1)) +
                ", Send " + identity.substr(third + 1, fourth - third - 1) +
                " to " + savedTrackLabel(identity.substr(second + 1, third - second - 1)) +
                ", " + identity.substr(fourth + 1);
        }
        return identity;
    };
    if (memoryColumn_ == 0) {
        // One memory per physical Track or Send; old Lua type-wide mappings
        // remain visible as explicitly INACTIVE compatibility entries.
        for (const auto& entry : memory_.fixedCcLinks()) {
            std::string label = targetLabel(entry.first);
            const auto comma = entry.second.find(',');
            label += comma == std::string::npos ? ", CC " + entry.second :
                ", Channel " + entry.second.substr(0, comma) + ", CC " + entry.second.substr(comma + 1);
            if (entry.first.rfind("Sends|", 0) == 0) {
                const auto guard = memory_.routingGuard(entry.first);
                if (guard.empty() || guard != fixedRoutingSignature(entry.first))
                    label += ", routing changed, relearn CC";
            }
            memoryItems_.push_back({"S:" + entry.first, label, entry.second, 0});
        }
        for (const auto* group : trackPages) {
            for (const auto& entry : memory_.ccLinks(group)) {
                if (entry.second.empty()) continue;
                const auto comma = entry.second.find(',');
                const std::string controller = comma == std::string::npos ? "CC " + entry.second :
                    "Channel " + entry.second.substr(0, comma) + ", CC " + entry.second.substr(comma + 1);
                memoryItems_.push_back({std::string("L:") + group + "." + entry.first,
                    std::string("Legacy inactive, ") + group + ", " + entry.first + ", " + controller,
                    entry.second, 0});
            }
        }
    } else if (memoryColumn_ == 1) {
        for (const auto& entry : memory_.entries("LReaParams.StepScales")) {
            const int step = memory_.step(entry.first);
            if (step == 0) continue; // No Step 0 rows, including old empty keys.
            memoryItems_.push_back({entry.first, entry.first + ", Step " +
                std::to_string(step), std::to_string(step), 0});
        }
    } else if (memoryColumn_ == 2) {
        for (const auto& entry : memory_.entries("LReaParams.ParameterSpeech")) {
            // Keyboard value speech defaults ON. Store and show only OFF.
            if (memory_.valueSpeech(entry.first)) continue;
            memoryItems_.push_back({"V:" + entry.first,
                entry.first + ", Value speech off", "0", 0});
        }
        for (const auto& entry : memory_.entries("LReaParams.FixedCCSpeechByTarget")) {
            // CC speech defaults OFF for each physical Track/Send identity.
            if (!memory_.fixedCcSpeech(entry.first)) continue;
            memoryItems_.push_back({"C:" + entry.first,
                targetLabel(entry.first) + ", MIDI speech on", "1", 0});
        }
        // A legacy type-wide speech preference does not activate any new
        // Fixed target. Keep its bytes intact but do not display it as active.
    } else if (memoryColumn_ == 3) {
        for (int slot = 1; slot <= 12; ++slot) {
            const auto guid = memory_.trackSlot(slot);
            if (guid.empty()) continue; // Unused slots are not memories.
            memoryItems_.push_back({"Slot" + std::to_string(slot),
                "Slot " + std::to_string(slot) + ", " + savedTrackLabel(guid), guid, slot});
        }
    } else if (memoryColumn_ == 4) {
        // Automatic last cursor positions are *not* user-created memories.
        // Explicitly configured volume ranges are, and belong in this manager.
        for (const auto& entry : memory_.entries("LReaParams.VolumeRanges")) {
            if (entry.second.empty()) continue;
            memoryItems_.push_back({entry.first, entry.first + ", " + entry.second + " dB",
                entry.second, 0});
        }
    }
    memoryRow_ = memoryItems_.empty() ? 0 : std::clamp(memoryRow_, 0, static_cast<int>(memoryItems_.size()) - 1);
}
void TrackNavigator::speakMemory(const std::string& prefix) const {
    const std::string header = prefix.empty() ? "" : prefix + ". ";
    const auto col = static_cast<size_t>(std::clamp(memoryColumn_, 0, 4));
    if (memoryItems_.empty()) {
        bool any = false;
        // Empty startup profiles must say 'No memories' once, as in FX Memories.
        for (int i = 0; i < 5 && !any; ++i) {
            // Rebuild in a local copy would be more expensive; read-only
            // section scans avoid changing the user's current column.
            if (i == 0) {
                any = !memory_.fixedCcLinks().empty();
                for (const auto* page : trackPages) {
                    for (const auto& link : memory_.ccLinks(page))
                        if (!link.second.empty()) { any = true; break; }
                    if (any) break;
                }
            }
            else if (i == 1) {
                for (const auto& e : memory_.entries("LReaParams.StepScales"))
                    if (memory_.step(e.first) != 0) { any = true; break; }
            } else if (i == 2) {
                for (const auto& e : memory_.entries("LReaParams.ParameterSpeech"))
                    if (!memory_.valueSpeech(e.first)) { any = true; break; }
                if (!any) for (const auto& e : memory_.entries("LReaParams.FixedCCSpeechByTarget"))
                    if (memory_.fixedCcSpeech(e.first)) { any = true; break; }
            } else if (i == 3) {
                for (int slot = 1; slot <= 12; ++slot)
                    if (!memory_.trackSlot(slot).empty()) { any = true; break; }
            } else any = !memory_.entries("LReaParams.VolumeRanges").empty();
        }
        speech_(any ? header + columnNames[col] + ". No memories" : "Track Memories. No memories");
        return;
    }
    speech_(header + columnNames[col] + ". " + memoryItems_[static_cast<size_t>(memoryRow_)].label);
}
void TrackNavigator::memoryExit() {
    const bool standalone = memoryStandalone_;
    memoryManager_ = memoryStandalone_ = false;
    memoryItems_.clear();
    if (standalone) end();
    else announceTitle();
}
void TrackNavigator::memoryAdjustStep(int delta) {
    if (memoryItems_.empty() || memoryColumn_ != 1) return;
    const auto id = memoryItems_[static_cast<size_t>(memoryRow_)].key;
    const int before = memory_.step(id);
    const int next = std::clamp(before + delta, -10, 10);
    if (next == before) return; // Silent step limit, like FX Params.
    memory_.setStep(id, next);
    memory_.flush();
    stepScale_ = memory_.step(parameterKey());
    rebuildMemoryList();
    speakMemory();
}
void TrackNavigator::memoryDelete() {
    if (memoryItems_.empty()) { speakMemory(); return; }
    const auto item = memoryItems_[static_cast<size_t>(memoryRow_)];
    const int removedColumn = memoryColumn_;
    if (memoryColumn_ == 0) {
        if (item.key.rfind("S:", 0) == 0)
            memory_.setFixedCcLink(item.key.substr(2), "");
        else if (item.key.rfind("L:", 0) == 0) {
            const auto legacy = item.key.substr(2);
            const auto dot = legacy.find('.');
            if (dot == std::string::npos) return;
            memory_.setCcLink(legacy.substr(0, dot), legacy.substr(dot + 1), "");
        } else return;
        midiPickup_.clear();
    } else if (memoryColumn_ == 1) {
        memory_.setStep(item.key, 0);
        stepScale_ = memory_.step(parameterKey());
    } else if (memoryColumn_ == 2) {
        // Restore the default behavior (value speech on, CC speech off).
        if (item.key.rfind("V:", 0) == 0) memory_.setValueSpeech(item.key.substr(2), true);
        else if (item.key.rfind("C:", 0) == 0)
            memory_.setFixedCcSpeech(item.key.substr(2), false);
    } else if (memoryColumn_ == 3) {
        if (item.value.empty()) { speech_("Slot already empty"); return; }
        memory_.setTrackSlot(item.slot, "");
    } else if (memoryColumn_ == 4) {
        memory_.clearVolumeRange(item.key);
    }
    memory_.flush();
    const auto label = item.label;
    rebuildMemoryList();
    if (memoryItems_.empty()) {
        const int oldColumn = memoryColumn_;
        bool moved = false;
        for (int c = oldColumn + 1; c < 5; ++c) {
            memoryColumn_ = c; memoryRow_ = 0; rebuildMemoryList();
            if (!memoryItems_.empty()) { moved = true; break; }
        }
        if (!moved) {
            for (int c = oldColumn - 1; c >= 0; --c) {
                memoryColumn_ = c; memoryRow_ = 0; rebuildMemoryList();
                if (!memoryItems_.empty()) { moved = true; break; }
            }
        }
        if (!moved) { memoryColumn_ = oldColumn; memoryRow_ = 0; rebuildMemoryList(); }
    }
    speech_((removedColumn == 0 || removedColumn == 3 ? "Deleted. " : "Reset. ") +
        label + ". " + (memoryItems_.empty() ? "No memories" :
        std::string(columnNames[static_cast<size_t>(memoryColumn_)]) + ". " +
        memoryItems_[static_cast<size_t>(memoryRow_)].label));
}
void TrackNavigator::memoryActivate() {
    if (memoryItems_.empty()) { speakMemory(); return; }
    const auto item = memoryItems_[static_cast<size_t>(memoryRow_)];
    if (memoryColumn_ == 0) { speech_("Press Delete to remove this CC association"); return; }
    if (memoryColumn_ == 1) { speech_("Use Alt Left or Right to change the step, Delete to reset"); return; }
    if (memoryColumn_ == 2) {
        if (item.key.rfind("V:", 0) == 0) {
            const auto id = item.key.substr(2);
            memory_.setValueSpeech(id, !memory_.valueSpeech(id));
        } else if (item.key.rfind("C:", 0) == 0) {
            const auto target = item.key.substr(2);
            memory_.setFixedCcSpeech(target, !memory_.fixedCcSpeech(target));
        }
        memory_.flush(); rebuildMemoryList(); speakMemory(); return;
    }
    if (memoryColumn_ == 3) {
        if (item.value.empty()) {
            saveTrackSlot(item.slot); rebuildMemoryList(); return;
        }
        // Exit manager before recall: it updates the real TCP selection.
        memoryManager_ = memoryStandalone_ = false;
        memoryItems_.clear();
        recallTrackSlot(item.slot);
        return;
    }
    if (memoryColumn_ == 4) {
        speech_("Edit this range with Control Shift I on the Volume parameter; Delete restores the default");
    }
}
void TrackNavigator::handleMemory(const Key& k) {
    if (k.repeat && (k.vk == VK_RETURN || k.vk == VK_DELETE || k.vk == VK_ESCAPE ||
        (k.ctrl && k.shift && !k.alt && k.vk == 'M'))) return;
    if (k.vk == VK_ESCAPE || (k.ctrl && k.shift && !k.alt && k.vk == 'M')) {
        memoryExit(); return;
    }
    if (k.vk == VK_TAB) { speakMemory(); return; }
    if (k.ctrl && !k.shift && !k.alt && (k.vk == VK_HOME || k.vk == VK_END)) {
        const int step = k.vk == VK_HOME ? 1 : -1;
        for (int c = step > 0 ? 0 : 4; c >= 0 && c < 5; c += step) {
            const int savedColumn = memoryColumn_, savedRow = memoryRow_;
            memoryColumn_ = c;
            memoryRow_ = step > 0 ? 0 : 1000000;
            rebuildMemoryList();
            if (!memoryItems_.empty()) {
                if (savedColumn != memoryColumn_ || savedRow != memoryRow_) speakMemory();
                return;
            }
            memoryColumn_ = savedColumn; memoryRow_ = savedRow;
        }
        return;
    }
    if (k.vk == VK_RETURN) { memoryActivate(); return; }
    if (k.vk == VK_DELETE) { memoryDelete(); return; }
    if (k.alt && (k.vk == VK_LEFT || k.vk == VK_RIGHT)) {
        memoryAdjustStep(k.vk == VK_LEFT ? -1 : 1); return;
    }
    if (k.vk == VK_LEFT || k.vk == VK_RIGHT) {
        // Same silent boundaries and empty-column skipping as FX Memories F8.
        // Preserve the current row where possible when changing categories.
        const int step = k.vk == VK_LEFT ? -1 : 1;
        const int previousColumn = memoryColumn_;
        const int previousRow = memoryRow_;
        for (int next = previousColumn + step; next >= 0 && next < 5; next += step) {
            memoryColumn_ = next;
            memoryRow_ = previousRow;
            rebuildMemoryList();
            if (!memoryItems_.empty()) { speakMemory(); return; }
        }
        memoryColumn_ = previousColumn;
        memoryRow_ = previousRow;
        rebuildMemoryList();
        return; // Silent at the first/last populated column.
    }
    if (k.vk == VK_UP || k.vk == VK_DOWN || k.vk == VK_PRIOR || k.vk == VK_NEXT ||
        k.vk == VK_HOME || k.vk == VK_END) {
        if (memoryItems_.empty()) return;
        const int last = static_cast<int>(memoryItems_.size()) - 1;
        const int previous = memoryRow_;
        if (k.vk == VK_HOME) memoryRow_ = 0;
        else if (k.vk == VK_END) memoryRow_ = last;
        else memoryRow_ = std::clamp(memoryRow_ + (k.vk == VK_UP ? -1 :
            k.vk == VK_DOWN ? 1 : k.vk == VK_PRIOR ? -5 : 5), 0, last);
        if (memoryRow_ != previous) speakMemory(); // Silent on a boundary.
        return;
    }
}
} // namespace lrp
