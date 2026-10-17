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
                                       "Track Positions", "Navigation Memory"};
const char* trackPages[] = {"Track", "Sends", "Receives"};
// Show default settings as well as customized entries; users must be able to
// edit a parameter before any explicit preference has ever been saved.
const char* defaultParameterIds[] = {
    "Track.Volume", "Track.Pan", "Track.Width", "Track.Mute", "Track.Solo",
    "Track.PhaseInvert", "Track.SendCount", "Track.ReceiveCount", "Track.FXCount",
    "Sends.Volume", "Sends.Pan", "Sends.Mute", "Sends.AudioSourceMode", "Sends.AudioSource",
    "Sends.AudioDestination", "Sends.SendType", "Sends.MidiSource", "Sends.MidiDestination",
    "Sends.MidiSourceBus", "Sends.MidiDestinationBus", "Sends.MidiFollowsFader", "Sends.MidiMerge",
    "Receives.Volume", "Receives.Pan", "Receives.Mute", "Receives.AudioSourceMode",
    "Receives.AudioSource", "Receives.AudioDestination", "Receives.SendType", "Receives.MidiSource",
    "Receives.MidiDestination", "Receives.MidiSourceBus", "Receives.MidiDestinationBus",
    "Receives.MidiFollowsFader", "Receives.MidiMerge"
};
const char* defaultMidiIds[] = {
    "Track.Volume", "Track.Pan", "Track.Width", "Track.Mute", "Track.Solo", "Track.PhaseInvert",
    "Sends.Volume", "Sends.Pan", "Sends.Mute", "Receives.Volume", "Receives.Pan", "Receives.Mute"
};
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
    return true;
}
void TrackNavigator::rebuildMemoryList() {
    memoryItems_.clear();
    if (memoryColumn_ == 0) {
        for (const auto* group : trackPages) {
            for (const auto& entry : memory_.ccLinks(group)) {
                if (entry.second.empty()) continue;
                memoryItems_.push_back({std::string(group) + "." + entry.first,
                    std::string(group) + ", " + entry.first + ", CC " + entry.second,
                    entry.second, 0});
            }
        }
    } else if (memoryColumn_ == 1) {
        std::set<std::string> keys(std::begin(defaultParameterIds), std::end(defaultParameterIds));
        for (const auto& entry : memory_.entries("LReaParams.StepScales")) keys.insert(entry.first);
        for (const auto& id : keys) {
            const auto value = std::to_string(memory_.step(id));
            memoryItems_.push_back({id, id + ", Step " + value, value, 0});
        }
    } else if (memoryColumn_ == 2) {
        std::set<std::string> keys(std::begin(defaultParameterIds), std::end(defaultParameterIds));
        for (const auto& entry : memory_.entries("LReaParams.ParameterSpeech")) keys.insert(entry.first);
        for (const auto& id : keys) {
            const bool on = memory_.valueSpeech(id);
            memoryItems_.push_back({"V:" + id, id + ", Value speech " + (on ? "on" : "off"),
                                    on ? "1" : "0", 0});
        }
        std::set<std::string> midiKeys(std::begin(defaultMidiIds), std::end(defaultMidiIds));
        for (const auto* group : trackPages)
            for (const auto& entry : memory_.entries(std::string("CCSpeech.") + group))
                midiKeys.insert(std::string(group) + "." + entry.first);
        for (const auto& id : midiKeys) {
            const auto dot = id.find('.');
            if (dot == std::string::npos) continue;
            const auto page = id.substr(0, dot), key = id.substr(dot + 1);
            const bool on = memory_.ccSpeech(page, key);
            memoryItems_.push_back({"C:" + id, id + ", MIDI speech " + (on ? "on" : "off"),
                                    on ? "1" : "0", 0});
        }
    } else if (memoryColumn_ == 3) {
        for (int slot = 1; slot <= 12; ++slot) {
            auto guid = memory_.trackSlot(slot);
            memoryItems_.push_back({"Slot" + std::to_string(slot),
                "Slot " + std::to_string(slot) + ", " + savedTrackLabel(guid), guid, slot});
        }
    } else if (memoryColumn_ == 4) {
        const auto active = memory_.position("LastPage");
        for (const auto* page : {"F1", "F2", "F3"}) {
            const auto value = memory_.position(std::string(page) + ".Parameter");
            memoryItems_.push_back({page, std::string(page) + (active == page ? ", last page" : "") +
                (value.empty() ? ", no stored parameter" : ", " + value), value, 0});
        }
    }
    memoryRow_ = memoryItems_.empty() ? 0 : std::clamp(memoryRow_, 0, static_cast<int>(memoryItems_.size()) - 1);
}
void TrackNavigator::speakMemory(const std::string& prefix) const {
    const std::string header = prefix.empty() ? "" : prefix + ". ";
    const auto col = static_cast<size_t>(std::clamp(memoryColumn_, 0, 4));
    if (memoryItems_.empty()) { speech_(header + columnNames[col] + ". No memories"); return; }
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
    memory_.setStep(id, std::clamp(memory_.step(id) + delta, -10, 10));
    memory_.flush();
    stepScale_ = memory_.step(parameterKey());
    rebuildMemoryList();
    speakMemory();
}
void TrackNavigator::memoryDelete() {
    if (memoryItems_.empty()) { speakMemory(); return; }
    const auto item = memoryItems_[static_cast<size_t>(memoryRow_)];
    if (memoryColumn_ == 0) {
        const auto dot = item.key.find('.');
        if (dot == std::string::npos) return;
        memory_.setCcLink(item.key.substr(0, dot), item.key.substr(dot + 1), "");
        midiPickup_.clear();
    } else if (memoryColumn_ == 1) {
        memory_.setStep(item.key, 0);
        stepScale_ = memory_.step(parameterKey());
    } else if (memoryColumn_ == 2) {
        // Restore the default behavior (value speech on, CC speech off).
        if (item.key.rfind("V:", 0) == 0) memory_.setValueSpeech(item.key.substr(2), true);
        else if (item.key.rfind("C:", 0) == 0) {
            const auto key = item.key.substr(2);
            const auto dot = key.find('.');
            if (dot != std::string::npos) memory_.setCcSpeech(key.substr(0, dot), key.substr(dot + 1), false);
        }
    } else if (memoryColumn_ == 3) {
        if (item.value.empty()) { speech_("Slot already empty"); return; }
        memory_.setTrackSlot(item.slot, "");
    } else {
        speech_("Navigation positions update automatically. Press Enter to recall"); return;
    }
    memory_.flush();
    const auto label = item.label;
    rebuildMemoryList();
    speech_((memoryColumn_ == 0 || memoryColumn_ == 3 ? "Deleted. " : "Reset. ") + label);
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
            const auto id = item.key.substr(2);
            const auto dot = id.find('.');
            if (dot == std::string::npos) return;
            const auto page = id.substr(0, dot), key = id.substr(dot + 1);
            memory_.setCcSpeech(page, key, !memory_.ccSpeech(page, key));
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
        memory_.setPosition("LastPage", item.key);
        memory_.flush();
        // Reopen the saved page on this track; its last column is resolved by real index.
        memoryManager_ = memoryStandalone_ = false;
        memoryItems_.clear();
        restorePosition();
        speech_("Restored. " + currentParameterSpeech());
    }
}
void TrackNavigator::handleMemory(const Key& k) {
    if (k.repeat && (k.vk == VK_RETURN || k.vk == VK_DELETE || k.vk == VK_F8 || k.vk == VK_ESCAPE)) return;
    if (k.vk == VK_ESCAPE || k.vk == VK_F8) { memoryExit(); return; }
    if (k.vk == VK_TAB) { speakMemory(); return; }
    if (k.vk == VK_RETURN) { memoryActivate(); return; }
    if (k.vk == VK_DELETE) { memoryDelete(); return; }
    if (k.alt && (k.vk == VK_LEFT || k.vk == VK_RIGHT)) {
        memoryAdjustStep(k.vk == VK_LEFT ? -1 : 1); return;
    }
    if (k.vk == VK_LEFT || k.vk == VK_RIGHT) {
        memoryColumn_ = std::clamp(memoryColumn_ + (k.vk == VK_LEFT ? -1 : 1), 0, 4);
        memoryRow_ = 0;
        rebuildMemoryList(); speakMemory(); return;
    }
    if (k.vk == VK_UP || k.vk == VK_DOWN || k.vk == VK_PRIOR || k.vk == VK_NEXT ||
        k.vk == VK_HOME || k.vk == VK_END) {
        if (memoryItems_.empty()) { speakMemory(); return; }
        const int last = static_cast<int>(memoryItems_.size()) - 1;
        if (k.vk == VK_HOME) memoryRow_ = 0;
        else if (k.vk == VK_END) memoryRow_ = last;
        else memoryRow_ = std::clamp(memoryRow_ + (k.vk == VK_UP ? -1 :
            k.vk == VK_DOWN ? 1 : k.vk == VK_PRIOR ? -5 : 5), 0, last);
        speakMemory();
    }
}
} // namespace lrp
