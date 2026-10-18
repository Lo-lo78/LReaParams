#include "lrp/TrackNavigator.h"
#include <algorithm>
#include <cmath>
#include <string>
#include <vector>

namespace lrp {
namespace {
int recentSequence() {
    char data[1024]{}; int size = sizeof(data), timestamp = 0, device = 0, loop = 0;
    double position = 0;
    return MIDI_GetRecentInputEvent(0, data, &size, &timestamp, &device, &position, &loop);
}
bool parseCc(const std::string& text, int& channel, int& controller) {
    const auto separator = text.find_first_of(",:");
    if (separator == std::string::npos) return false;
    try {
        std::size_t a = 0, b = 0;
        channel = std::stoi(text.substr(0, separator), &a);
        const auto tail = text.substr(separator + 1);
        controller = std::stoi(tail, &b);
        return a == separator && b == tail.size() && channel >= 1 && channel <= 16 &&
            controller >= 0 && controller <= 127;
    } catch (...) { return false; }
}
const char* sectionFor(bool tracks, bool sends) { return tracks ? "Track" : sends ? "Sends" : "Receives"; }
}

bool TrackNavigator::midiTarget(std::string& section, std::string& key) const {
    section.clear(); key.clear();
    const Entry* e = current();
    if (!e || !track_) return false;
    section = sectionFor(page_ == Page::tracks, page_ == Page::sends);
    if (e->type == Entry::volume) key = "Volume";
    else if (e->type == Entry::pan) key = "Pan";
    else if (e->type == Entry::width && page_ == Page::tracks) key = "Width";
    else if (e->type == Entry::flag && e->parm == "B_MUTE") key = "Mute";
    else if (e->type == Entry::flag && e->parm == "B_PHASE" && page_ == Page::tracks) key = "PhaseInvert";
    else if (e->type == Entry::solo && page_ == Page::tracks) key = "Solo";
    return !key.empty();
}

// Fixed identities use immutable REAPER track GUIDs. A receive is normalized
// to the matching outgoing send: both F2 and F3 refer to one actual connection.
bool TrackNavigator::midiFixedIdentity(std::string& identity) const {
    identity.clear();
    std::string section, key;
    if (!midiTarget(section, key)) return false;
    const std::string owner = trackGuidText(track_);
    if (owner.empty()) return false;
    if (page_ == Page::tracks) {
        identity = "Track|" + owner + "|" + key;
        return true;
    }
    const Entry* entry = current();
    if (!entry || entry->index < 0 || !GetSetTrackSendInfo) return false;
    const char* peerField = page_ == Page::sends ? "P_DESTTRACK" : "P_SRCTRACK";
    auto* peer = static_cast<MediaTrack*>(
        GetSetTrackSendInfo(track_, entry->category, entry->index, peerField, nullptr));
    const std::string peerGuid = trackGuidText(peer);
    if (peerGuid.empty()) return false;
    const std::string& source = page_ == Page::sends ? owner : peerGuid;
    const std::string& dest = page_ == Page::sends ? peerGuid : owner;
    const int ordinal = detailPeerOccurrence(entry->category, entry->index);
    if (ordinal < 1) return false;
    identity = "Sends|" + source + "|" + dest + "|" + std::to_string(ordinal) + "|" + key;
    return true;
}

namespace {
// Read only our own structural keys. Corrupted or unrelated project entries
// must never accidentally control a different track/send.
struct FixedTarget {
    bool send = false;
    std::string source, destination, parameter;
    int ordinal = 0;
};
bool decodeFixedTarget(const std::string& id, FixedTarget& out) {
    std::vector<std::string> parts;
    std::size_t start = 0;
    for (;;) {
        const auto at = id.find('|', start);
        parts.push_back(id.substr(start, at == std::string::npos ? at : at - start));
        if (at == std::string::npos) break;
        start = at + 1;
    }
    if (parts.size() == 3 && parts[0] == "Track") {
        out = {false, parts[1], {}, parts[2], 0};
    } else if (parts.size() == 5 && parts[0] == "Sends") {
        int occurrence = 0;
        try {
            std::size_t used = 0;
            occurrence = std::stoi(parts[3], &used);
            if (used != parts[3].size() || occurrence < 1 || occurrence > 512) return false;
        } catch (...) { return false; }
        out = {true, parts[1], parts[2], parts[4], occurrence};
    } else return false;
    const auto validGuid = [](const std::string& g) {
        if (g.size() != 38 || g.front() != '{' || g.back() != '}') return false;
        for (std::size_t i = 1; i < 37; ++i) {
            if (i == 9 || i == 14 || i == 19 || i == 24) { if (g[i] != '-') return false; }
            else if (!((g[i] >= '0' && g[i] <= '9') ||
                (g[i] >= 'A' && g[i] <= 'F') || (g[i] >= 'a' && g[i] <= 'f'))) return false;
        }
        return true;
    };
    if (!validGuid(out.source) || (out.send && !validGuid(out.destination))) return false;
    if (out.send) return out.parameter == "Volume" || out.parameter == "Pan" || out.parameter == "Mute";
    return out.parameter == "Volume" || out.parameter == "Pan" || out.parameter == "Width" ||
        out.parameter == "Mute" || out.parameter == "Solo" || out.parameter == "PhaseInvert";
}
}

void TrackNavigator::resetMidiState() {
    learnCc_ = fixedCc_ = floatingCc_ = floatingWaiting_ = false;
    learnSection_.clear(); learnKey_.clear(); learnIdentity_.clear(); floatingTarget_.clear();
    floatingChannel_ = floatingNumber_ = -1;
    midiPickup_.clear(); pendingMidiSpeech_.clear(); midiSpeechAt_ = 0;
    midiSequence_ = 0;
}

void TrackNavigator::midiShortcut(const Key& k) {
    std::string section, key;
    const bool supported = midiTarget(section, key);
    const bool learn = k.ctrl && k.alt && !k.shift && k.vk == 'C';
    const bool toggleFixed = !k.ctrl && !k.alt && k.shift && k.vk == 'C';
    const bool toggleFloating = k.ctrl && !k.alt && k.shift && k.vk == 'C';
    if (learn) {
        if (learnCc_) { learnCc_ = false; speech_("CC learn cancelled"); return; }
        if (!supported) { speech_("No MIDI CC target for this field"); return; }
        std::string identity;
        if (!midiFixedIdentity(identity)) { speech_("Track or routing unavailable for CC learn"); return; }
        learnSection_ = section; learnKey_ = key; learnIdentity_ = identity;
        learnCc_ = true; midiSequence_ = recentSequence();
        speech_("CC learn. Move a MIDI control");
        return;
    }
    if (toggleFixed) {
        if (fixedCc_) {
            fixedCc_ = false; memory_.setFixedEnabled(false); memory_.flush();
            midiPickup_.clear(); speech_("Fixed CC map off"); return;
        }
        int count = 0;
        for (const auto& entry : memory_.fixedCcLinks()) {
            int ch = 0, cc = 0; FixedTarget target;
            if (parseCc(entry.second, ch, cc) && decodeFixedTarget(entry.first, target)) ++count;
        }
        if (!count) { speech_("No fixed CC map"); return; }
        fixedCc_ = true; floatingCc_ = floatingWaiting_ = false;
        memory_.setFixedEnabled(true); memory_.flush();
        midiSequence_ = recentSequence(); midiPickup_.clear();
        speech_("Fixed CC map on. " + std::to_string(count) + " parameters");
        return;
    }
    if (toggleFloating) {
        if (floatingCc_ || floatingWaiting_) {
            floatingCc_ = floatingWaiting_ = false;
            speech_("Floating CC off");
        } else {
            if (!supported) { speech_("No MIDI CC target for this field"); return; }
            floatingWaiting_ = true; fixedCc_ = false;
            midiSequence_ = recentSequence(); midiPickup_.clear();
            speech_("Floating CC learn. Move a MIDI control");
        }
        return;
    }
    if (k.ctrl && !k.shift && !k.alt && k.vk == VK_DELETE) {
        if (!supported) { speech_("No fixed CC target"); return; }
        std::string identity;
        if (!midiFixedIdentity(identity)) { speech_("Routing unavailable"); return; }
        const bool has = !memory_.fixedCcLink(identity).empty();
        if (has) { memory_.setFixedCcLink(identity, ""); memory_.flush(); midiPickup_.clear(); }
        speech_(has ? "Fixed CC removed. " + key : "No fixed CC on " + key);
    }
}

void TrackNavigator::applyMidi(const std::string& section, const std::string& key, int value) {
    // An association names a control TYPE; its target is the current track
    // or the current send/receive. Never apply to every track in the project.
    if (section != sectionFor(page_ == Page::tracks, page_ == Page::sends) || !track_) return;
    const Entry* target = nullptr;
    const int index = page_ == Page::tracks ? -1 : current() ? current()->index : -1;
    for (const auto& entry : entries_) {
        if (entry.index != index) continue;
        if (key == "Volume" && entry.type == Entry::volume) target = &entry;
        else if (key == "Pan" && entry.type == Entry::pan) target = &entry;
        else if (key == "Width" && entry.type == Entry::width) target = &entry;
        else if (key == "Mute" && entry.type == Entry::flag && entry.parm == "B_MUTE") target = &entry;
        else if (key == "PhaseInvert" && entry.type == Entry::flag && entry.parm == "B_PHASE") target = &entry;
        else if (key == "Solo" && entry.type == Entry::solo) target = &entry;
        if (target) break;
    }
    if (!target) return;
    const bool binary = target->type == Entry::flag || target->type == Entry::solo;
    const double before = get(*target);
    // Fixed and Floating CC share the project's real Volume range. The
    // normalized pickup must use precisely the same span as the CC mapping.
    const auto volumeLimits = memory_.volumeRange(section);
    const auto norm = [target, volumeLimits](double v) {
        if (target->type == Entry::volume)
            return std::clamp(((v <= 0 ? -150.0 : 20.0 * std::log10(v)) - volumeLimits.first) /
                (volumeLimits.second - volumeLimits.first), 0.0, 1.0);
        if (target->type == Entry::pan || target->type == Entry::width)
            return std::clamp((v + 1.0) / 2.0, 0.0, 1.0);
        return std::clamp(v, 0.0, 1.0);
    };
    const std::string id = section + "." + key;
    Pickup& pickup = midiPickup_[id];
    if (!binary && !pickup.allows(value, norm(before))) return;
    const double fraction = value / 127.0;
    const double next = binary ? (value >= 64 ? 1.0 : 0.0) :
        target->type == Entry::volume ?
            (fraction <= 0.0 && volumeLimits.first <= -150.0 ? 0.0 :
                std::pow(10.0, (volumeLimits.first +
                    (volumeLimits.second - volumeLimits.first) * fraction) / 20.0)) :
            fraction * 2.0 - 1.0;
    if (std::abs(next - before) < 0.000001) return;
    suppressPutSpeech_ = true;
    try { put(*target, next); } catch (...) { suppressPutSpeech_ = false; throw; }
    suppressPutSpeech_ = false;
    pickup.applied(norm(get(*target)));
    if (memory_.ccSpeech(section, key)) pendingMidiSpeech_ = key + ", " + valueText(*target, get(*target));
}

void TrackNavigator::applyFixedMidi(const std::string& identity, int value) {
    FixedTarget target;
    if (!decodeFixedTarget(identity, target)) return;
    // Resolve per message. Never cache a MediaTrack* across REAPER track edits.
    MediaTrack* source = findSavedTrack(target.source);
    if (!source) return; // Deleted track: its map remains inert, not reassigned.
    MediaTrack* dest = target.send ? findSavedTrack(target.destination) : nullptr;
    if (target.send && (!dest || !GetSetTrackSendInfo)) return;
    int sendIndex = -1;
    if (target.send) {
        int occurrence = 0;
        const int count = std::clamp(GetTrackNumSends(source, 0), 0, 512);
        for (int i = 0; i < count; ++i) {
            auto* peer = static_cast<MediaTrack*>(
                GetSetTrackSendInfo(source, 0, i, "P_DESTTRACK", nullptr));
            if (peer == dest && ++occurrence == target.ordinal) { sendIndex = i; break; }
        }
        if (sendIndex < 0) return; // Routing removed/reordered: no accidental fallback.
    }
    const char* parm = target.parameter == "Volume" ? "D_VOL" :
        target.parameter == "Pan" ? "D_PAN" : target.parameter == "Width" ? "D_WIDTH" :
        target.parameter == "Mute" ? "B_MUTE" : target.parameter == "Solo" ? "I_SOLO" :
        "B_PHASE";
    const bool binary = target.parameter == "Mute" || target.parameter == "Solo" ||
        target.parameter == "PhaseInvert";
    const double before = target.send ? GetTrackSendInfo_Value(source, 0, sendIndex, parm) :
        GetMediaTrackInfo_Value(source, parm);
    if (!std::isfinite(before)) return;
    const auto limits = memory_.volumeRange(target.send ? "Sends" : "Track");
    const auto normalized = [&](double v) {
        if (target.parameter == "Volume")
            return std::clamp(((v <= 0 ? -150.0 : 20.0 * std::log10(v)) - limits.first) /
                (limits.second - limits.first), 0.0, 1.0);
        if (target.parameter == "Pan" || target.parameter == "Width")
            return std::clamp((v + 1.0) / 2.0, 0.0, 1.0);
        return std::clamp(v, 0.0, 1.0);
    };
    Pickup& pickup = midiPickup_[identity];
    if (!binary && !pickup.allows(value, normalized(before))) return;
    const double fraction = value / 127.0;
    const double next = binary ? (value >= 64 ? 1.0 : 0.0) :
        target.parameter == "Volume" ?
            (fraction <= 0.0 && limits.first <= -150.0 ? 0.0 :
                std::pow(10.0, (limits.first + (limits.second - limits.first) * fraction) / 20.0)) :
            fraction * 2.0 - 1.0;
    if (std::abs(next - before) < 0.000001) return;
    const bool changed = target.send ? SetTrackSendInfo_Value(source, 0, sendIndex, parm, next) :
        SetMediaTrackInfo_Value(source, parm, next);
    if (!changed) return;
    pickup.applied(normalized(next));
    TrackList_AdjustWindows(false);
    UpdateArrange();
    if (memory_.ccSpeech(target.send ? "Sends" : "Track", target.parameter)) {
        std::string label = savedTrackLabel(target.source);
        if (target.send) {
            label += ", Send to " + savedTrackLabel(target.destination);
            if (target.ordinal > 1) label += " " + std::to_string(target.ordinal);
        }
        pendingMidiSpeech_ = label + ", " + target.parameter + ", " +
            (target.parameter == "Volume" ?
                (next <= 0 ? "minus infinity dB" : std::to_string(20.0 * std::log10(next)) + " dB") :
                binary ? (next >= 0.5 ? "on" : "off") :
                target.parameter == "Pan" ? std::to_string(static_cast<int>(std::abs(next) * 100.0)) +
                    (next < 0 ? " percent left" : " percent right") :
                    std::to_string(static_cast<int>(next * 100.0)) + " percent");
    }
}

void TrackNavigator::pollMidi() {
    if (!active_ || memoryManager_ || !contextUnchanged()) return;
    const bool running = learnCc_ || fixedCc_ || floatingCc_ || floatingWaiting_;
    if (!running) return;
    if (filterEditing_ || numericEditing_) {
        midiSequence_ = recentSequence(); return; // never replay MIDI after editing text
    }
    struct Item { MidiCc cc; };
    std::vector<Item> items;
    int newest = midiSequence_;
    for (int i = 0; i < 128; ++i) {
        char bytes[1024]{}; int size = sizeof(bytes), ts = 0, dev = 0, loop = 0;
        double pos = 0;
        const int seq = MIDI_GetRecentInputEvent(i, bytes, &size, &ts, &dev, &pos, &loop);
        if (i == 0) newest = seq;
        if (!seq || seq == midiSequence_) break;
        if (auto cc = decodeCc(reinterpret_cast<unsigned char*>(bytes),
            std::clamp(size, 0, static_cast<int>(sizeof(bytes))))) items.push_back({*cc});
    }
    if (!midiSequence_) { midiSequence_ = newest; return; } // latch historic events
    midiSequence_ = newest;
    for (auto it = items.rbegin(); it != items.rend(); ++it) {
        const auto cc = it->cc;
        if (learnCc_) {
            const std::string link = std::to_string(cc.channel) + "," + std::to_string(cc.number);
            // A physical controller has one Fixed target per project.
            // Do not destroy imported generic Lua entries: they are inactive
            // compatibility data and cannot drive other tracks.
            for (const auto& row : memory_.fixedCcLinks()) {
                int oldCh = 0, oldCC = 0;
                if (row.first != learnIdentity_ && parseCc(row.second, oldCh, oldCC) &&
                    oldCh == cc.channel && oldCC == cc.number)
                    memory_.setFixedCcLink(row.first, "");
            }
            memory_.setFixedCcLink(learnIdentity_, link);
            memory_.setFixedEnabled(true);
            memory_.flush();
            const auto target = learnKey_;
            learnCc_ = false; fixedCc_ = true; floatingCc_ = floatingWaiting_ = false;
            learnIdentity_.clear();
            midiPickup_.clear();
            speech_("CC learned. Channel " + std::to_string(cc.channel) + " CC " +
                std::to_string(cc.number) + ". " + target);
            continue; // learn event must never modify the target
        }
        if (floatingWaiting_) {
            floatingChannel_ = cc.channel; floatingNumber_ = cc.number;
            floatingWaiting_ = false; floatingCc_ = true;
            midiPickup_.clear();
            speech_("Floating CC. Channel " + std::to_string(cc.channel) +
                " CC " + std::to_string(cc.number));
            continue;
        }
        if (fixedCc_) {
            for (const auto& row : memory_.fixedCcLinks()) {
                int ch = 0, number = 0;
                if (parseCc(row.second, ch, number) && ch == cc.channel && number == cc.number)
                    applyFixedMidi(row.first, cc.value);
            }
        } else if (floatingCc_ && cc.channel == floatingChannel_ && cc.number == floatingNumber_) {
            std::string group, key;
            if (midiTarget(group, key)) {
                const std::string id = group + "." + key;
                if (floatingTarget_ != id) { floatingTarget_ = id; midiPickup_.clear(); }
                applyMidi(group, key, cc.value);
            }
        }
    }
    if (!pendingMidiSpeech_.empty() && GetTickCount64() - midiSpeechAt_ >= 180) {
        speech_(pendingMidiSpeech_); pendingMidiSpeech_.clear(); midiSpeechAt_ = GetTickCount64();
    }
}
} // namespace lrp
