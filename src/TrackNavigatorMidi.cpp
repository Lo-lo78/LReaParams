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

void TrackNavigator::resetMidiState() {
    learnCc_ = fixedCc_ = floatingCc_ = floatingWaiting_ = false;
    learnSection_.clear(); learnKey_.clear(); floatingTarget_.clear();
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
        learnSection_ = section; learnKey_ = key;
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
        for (const char* group : {"Track", "Sends", "Receives"})
            for (const auto& entry : memory_.ccLinks(group)) {
                int ch = 0, cc = 0;
                if (parseCc(entry.second, ch, cc)) ++count;
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
        const bool has = !memory_.ccLink(section, key).empty();
        if (has) { memory_.setCcLink(section, key, ""); memory_.flush(); midiPickup_.clear(); }
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
    // The same 0..1 pickup range is used for Fixed and Floating controllers.
    // Volumes are in decibels (-60..+12); mute/solo/phase are switches.
    const auto norm = [target](double v) {
        if (target->type == Entry::volume)
            return std::clamp((v <= 0 ? -60.0 : 20.0 * std::log10(v)) / 72.0 + 60.0 / 72.0, 0.0, 1.0);
        if (target->type == Entry::pan || target->type == Entry::width)
            return std::clamp((v + 1.0) / 2.0, 0.0, 1.0);
        return std::clamp(v, 0.0, 1.0);
    };
    const std::string id = section + "." + key;
    Pickup& pickup = midiPickup_[id];
    if (!binary && !pickup.allows(value, norm(before))) return;
    const double fraction = value / 127.0;
    const double next = binary ? (value >= 64 ? 1.0 : 0.0) :
        target->type == Entry::volume ? (fraction <= 0.0 ? 0.0 :
            std::pow(10.0, (-60.0 + 72.0 * fraction) / 20.0)) : fraction * 2.0 - 1.0;
    if (std::abs(next - before) < 0.000001) return;
    suppressPutSpeech_ = true;
    try { put(*target, next); } catch (...) { suppressPutSpeech_ = false; throw; }
    suppressPutSpeech_ = false;
    pickup.applied(norm(get(*target)));
    if (memory_.ccSpeech(section, key)) pendingMidiSpeech_ = key + ", " + valueText(*target, get(*target));
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
            for (const char* group : {"Track", "Sends", "Receives"})
                for (const auto& row : memory_.ccLinks(group)) {
                    int oldCh = 0, oldCC = 0;
                    if ((group != learnSection_ || row.first != learnKey_) &&
                        parseCc(row.second, oldCh, oldCC) && oldCh == cc.channel && oldCC == cc.number)
                        memory_.setCcLink(group, row.first, "");
                }
            memory_.setCcLink(learnSection_, learnKey_, link);
            memory_.setFixedEnabled(true);
            memory_.flush();
            const auto target = learnKey_;
            learnCc_ = false; fixedCc_ = true; floatingCc_ = floatingWaiting_ = false;
        memory_.setFixedEnabled(true); memory_.flush();
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
            for (const char* group : {"Track", "Sends", "Receives"}) {
                for (const auto& row : memory_.ccLinks(group)) {
                    int ch = 0, number = 0;
                    if (parseCc(row.second, ch, number) && ch == cc.channel && number == cc.number)
                        applyMidi(group, row.first, cc.value);
                }
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
