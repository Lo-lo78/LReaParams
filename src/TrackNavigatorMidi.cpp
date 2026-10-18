#include "lrp/TrackNavigator.h"
#include "lrp/Storage.h"
#include <algorithm>
#include <cmath>
#include <cstdio>
#include <cstring>
#include <string>
#include <utility>
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
std::string fxGuidString(const GUID& g) {
    char text[64]{};
    std::snprintf(text, sizeof(text), "{%08lX-%04hX-%04hX-%02hhX%02hhX-%02hhX%02hhX%02hhX%02hhX%02hhX%02hhX}",
        static_cast<unsigned long>(g.Data1), static_cast<unsigned short>(g.Data2),
        static_cast<unsigned short>(g.Data3), g.Data4[0], g.Data4[1], g.Data4[2], g.Data4[3],
        g.Data4[4], g.Data4[5], g.Data4[6], g.Data4[7]);
    return text;
}
}

bool TrackNavigator::midiTarget(std::string& section, std::string& key) const {
    section.clear(); key.clear();
    const Entry* e = current();
    if (!track_) return false;
    if (page_ == Page::fxTcp) {
        // Only a selected, *visible* TCP parameter can be learned. The names-only
        // addition grid is not a MIDI editing surface.
        const auto* c = currentFxTcpColumn();
        const auto* p = currentFxTcpParameter();
        if (fxTcpListOpen_ || !c || !p || !fxTcpSelectedIdentityValid()) return false;
        section = "F4";
        key = p->name;
        return true;
    }
    if (!e) return false;
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
    if (page_ == Page::fxTcp) {
        const auto* fx = currentFxTcpColumn();
        const auto* param = currentFxTcpParameter();
        if (!fx || !param || !fxTcpSelectedIdentityValid()) return false;
        identity = "FxTcp|" + owner + "|" + fxGuidString(fx->guid) +
            "|" + std::to_string(param->index);
        return true;
    }
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
    bool fxTcp = false;
    int fxParam = -1;
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
    } else if (parts.size() == 4 && parts[0] == "FxTcp") {
        int parameter = -1;
        try {
            std::size_t used = 0;
            parameter = std::stoi(parts[3], &used);
            if (used != parts[3].size() || parameter < 0 || parameter > 32767) return false;
        } catch (...) { return false; }
        out = {};
        out.source = parts[1];
        out.destination = parts[2]; // FX instance GUID, NOT another track.
        out.fxTcp = true;
        out.fxParam = parameter;
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
    if (!validGuid(out.source) || ((out.send || out.fxTcp) && !validGuid(out.destination))) return false;
    if (out.fxTcp) return true;
    if (out.send) return out.parameter == "Volume" || out.parameter == "Pan" || out.parameter == "Mute";
    return out.parameter == "Volume" || out.parameter == "Pan" || out.parameter == "Width" ||
        out.parameter == "Mute" || out.parameter == "Solo" || out.parameter == "PhaseInvert";
}
}

// REAPER does not expose a permanent GUID per send. Hash the source's outgoing
// routing topology at learn time and validate it before every Fixed CC edit.
// If a send is inserted/deleted/reordered or its destination changes, fail
// closed rather than unexpectedly controlling the next send with that ordinal.
// Completely indistinguishable duplicate sends cannot be disambiguated by the
// REAPER API; the user must relearn after structural routing edits.
std::string TrackNavigator::fixedRoutingSignature(const std::string& identity) const {
    FixedTarget target;
    if (!decodeFixedTarget(identity, target) || !target.send || !GetSetTrackSendInfo) return {};
    MediaTrack* source = findSavedTrack(target.source);
    if (!source) return {};
    const int count = GetTrackNumSends(source, 0);
    if (count < 0 || count > 512) return {};
    std::string topology = "LReaParams.SendTopology.v1|" + target.source + "|" + std::to_string(count);
    for (int i = 0; i < count; ++i) {
        auto* peer = static_cast<MediaTrack*>(GetSetTrackSendInfo(source, 0, i, "P_DESTTRACK", nullptr));
        if (!peer || !ValidatePtr2(project_, peer, "MediaTrack*")) return {};
        const auto guid = trackGuidText(peer);
        if (guid.empty()) return {};
        topology += "|" + guid;
    }
    return sha256(topology);
}

// Fixed FX CCs are bound to the physical track and FX-instance GUID, not
// current Track Params cursor, FX ordinal, or the TCP control's visible row.
bool TrackNavigator::resolveFxTcpMidi(const std::string& identity,
                                       MediaTrack*& owner, int& fxIndex,
                                       int& parameterIndex) const {
    owner = nullptr; fxIndex = parameterIndex = -1;
    FixedTarget target;
    if (!decodeFixedTarget(identity, target) || !target.fxTcp || !project_ ||
        !TrackFX_GetCount || !TrackFX_GetFXGUID || !TrackFX_GetNumParams) return false;
    owner = findSavedTrack(target.source);
    if (!owner || !ValidatePtr2(project_, owner, "MediaTrack*")) return false;
    const int count = std::clamp(TrackFX_GetCount(owner), 0, 1024);
    for (int i = 0; i < count; ++i) {
        const GUID* live = TrackFX_GetFXGUID(owner, i);
        if (!live || fxGuidString(*live) != target.destination) continue;
        if (target.fxParam >= TrackFX_GetNumParams(owner, i)) return false;
        fxIndex = i;
        parameterIndex = target.fxParam;
        return true;
    }
    return false; // removed FX must never fall back to another instance.
}

bool TrackNavigator::applyFxTcpMidi(const std::string& identity, int ccValue, bool floating) {
    MediaTrack* owner = nullptr;
    int fx = -1, parameter = -1;
    if (!resolveFxTcpMidi(identity, owner, fx, parameter) ||
        !TrackFX_GetParamNormalized || !TrackFX_SetParamNormalized) return false;
    const double currentValue = TrackFX_GetParamNormalized(owner, fx, parameter);
    if (!std::isfinite(currentValue)) return false;
    Pickup& pickup = midiPickup_[identity];
    double normal = 0, small = 0, large = 0;
    bool toggle = false;
    const bool stepped = TrackFX_GetParameterStepSizes &&
        TrackFX_GetParameterStepSizes(owner, fx, parameter, &normal, &small, &large, &toggle);
    // Discrete and binary controls must not wait for analog pickup.
    if (!(stepped && toggle) && !pickup.allows(ccValue, std::clamp(currentValue, 0.0, 1.0)))
        return false;
    const double next = stepped && toggle ? (ccValue >= 64 ? 1.0 : 0.0) : ccValue / 127.0;
    if (std::abs(next - currentValue) < 1e-9) return false;
    if (!TrackFX_SetParamNormalized(owner, fx, parameter, next)) return false;
    if (TrackFX_EndParamEdit) TrackFX_EndParamEdit(owner, fx, parameter);
    pickup.applied(std::clamp(TrackFX_GetParamNormalized(owner, fx, parameter), 0.0, 1.0));
    // Speech defaults OFF per target. MIDI feedback never repeats the full
    // GUI announcement unless explicitly enabled with Ctrl+T.
    if (memory_.fixedCcSpeech(identity)) {
        char paramName[1024]{}, formatted[512]{}, fxName[1024]{};
        if (TrackFX_GetParamName) TrackFX_GetParamName(owner, fx, parameter, paramName, sizeof(paramName));
        if (TrackFX_GetFormattedParamValue)
            TrackFX_GetFormattedParamValue(owner, fx, parameter, formatted, sizeof(formatted));
        if (TrackFX_GetFXName) TrackFX_GetFXName(owner, fx, fxName, sizeof(fxName));
        pendingMidiSpeech_ = (floating ? std::string() : savedTrackLabel(trackGuidText(owner)) + ", ") +
            (fxName[0] ? std::string(fxName) + ", " : std::string()) +
            (paramName[0] ? std::string(paramName) : "Parameter " + std::to_string(parameter + 1)) +
            ", " + (formatted[0] ? std::string(formatted) : std::to_string(next));
    }
    return true;
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
    if (section == "F4" && page_ == Page::fxTcp && track_) {
        std::string identity;
        if (midiFixedIdentity(identity)) applyFxTcpMidi(identity, value, true);
        return;
    }
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
    std::string speechTarget;
    if (midiFixedIdentity(speechTarget) && memory_.fixedCcSpeech(speechTarget))
        pendingMidiSpeech_ = key + ", " + valueText(*target, get(*target));
}

void TrackNavigator::applyFixedMidi(const std::string& identity, int value) {
    FixedTarget target;
    if (!decodeFixedTarget(identity, target)) return;
    if (target.fxTcp) { applyFxTcpMidi(identity, value, false); return; }
    // Resolve per message. Never cache a MediaTrack* across REAPER track edits.
    MediaTrack* source = findSavedTrack(target.source);
    if (!source) return; // Deleted track: its map remains inert, not reassigned.
    MediaTrack* dest = target.send ? findSavedTrack(target.destination) : nullptr;
    if (target.send && (!dest || !GetSetTrackSendInfo)) return;
    // Legacy ordinal-only sends have no guard and are deliberately inactive
    // until relearned. An altered route graph must never hijack a Fixed CC.
    if (target.send) {
        const auto saved = memory_.routingGuard(identity);
        if (saved.empty() || saved != fixedRoutingSignature(identity)) return;
    }
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
    if (memory_.fixedCcSpeech(identity)) {
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

void TrackNavigator::prepareBackgroundMidi() {
    // Copy a UI navigator for Ctrl+Q, then drop all UI ownership and pending
    // learn/edit operations. This copy never writes cursor positions to .tp.
    backgroundMode_ = true;
    memoryManager_ = memoryStandalone_ = false;
    clearAutomationConfirm_ = false;
    learnCc_ = floatingWaiting_ = false;
    filterEditing_ = numericEditing_ = rangeEditing_ = false;
    pendingMidiSpeech_.clear();
    midiSequence_ = recentSequence(); // never replay MIDI received before Ctrl+Q
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
    if (!midiSequence_ && !backgroundMode_) { midiSequence_ = newest; return; } // foreground latch only
    midiSequence_ = newest;
    for (auto it = items.rbegin(); it != items.rend(); ++it) {
        const auto cc = it->cc;
        if (learnCc_) {
            const std::string link = std::to_string(cc.channel) + "," + std::to_string(cc.number);
            // Validate outgoing routing before modifying any mapping: a
            // failed learn must not wipe an older valid CC association.
            std::string signature;
            if (learnIdentity_.rfind("Sends|", 0) == 0) {
                signature = fixedRoutingSignature(learnIdentity_);
                if (signature.empty()) {
                    learnCc_ = false;
                    speech_("Routing unavailable. CC not learned");
                    continue;
                }
            }
            // A physical controller has one Fixed target per project.
            // Do not destroy imported generic Lua entries: they are inactive
            // compatibility data and cannot drive other tracks.
            // Saving a Fixed map must never close the accessible navigator if
            // the project .tp becomes unavailable or is externally modified.
            // A failure restores the pre-learn memory state, leaving existing
            // associations intact and the focus inside Track Params.
            TrackMemory beforeLearn = memory_;
            try {
                for (const auto& row : memory_.fixedCcLinks()) {
                    int oldCh = 0, oldCC = 0;
                    if (row.first != learnIdentity_ && parseCc(row.second, oldCh, oldCC) &&
                        oldCh == cc.channel && oldCC == cc.number)
                        memory_.setFixedCcLink(row.first, "");
                }
                // Store the guard in the same .tp transaction as this Fixed CC.
                // Track parameters do not need a routing guard; send/receive do.
                if (!signature.empty()) memory_.setRoutingGuard(learnIdentity_, signature);
                memory_.setFixedCcLink(learnIdentity_, link);
                memory_.setFixedEnabled(true);
                memory_.flush();
            } catch (const std::exception&) {
                memory_ = std::move(beforeLearn);
                learnCc_ = false;
                learnIdentity_.clear();
                speech_("CC learn failed. Could not save project Track memory");
                continue;
            }
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
                std::string id = group + "." + key;
                if (group == "F4" && !midiFixedIdentity(id)) continue;
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
