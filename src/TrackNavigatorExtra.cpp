#include "lrp/TrackNavigator.h"
#include "lrp/RangeDialog.h"
#include <sstream>
#include <stdexcept>
#include <algorithm>
#include <cmath>
#include <cstring>
#include <exception>
#include <string>

// Every navigator speech call is catalogued by source expression, not line
// number. Existing announcements and navigation remain unchanged by default.
#include "lrp/MessageCatalog.h"
#define speech_(...) ::lrp::emitConfigurableSpeech(::lrp::SpeechScope::track, __FILE__, #__VA_ARGS__, speech_, (__VA_ARGS__))

namespace lrp {
void TrackNavigator::jumpToLinkedRouting() {
    if (page_ == Page::tracks || !current()) return;
    if (!GetSetTrackSendInfo) { speech_("Routing API unavailable"); return; }
    const Entry selected = *current();
    if (selected.type != Entry::header) return;
    const bool fromSend = page_ == Page::sends;
    const int sourceCat = fromSend ? 0 : -1;
    const int targetCat = fromSend ? -1 : 0;
    const char* peerParm = fromSend ? "P_DESTTRACK" : "P_SRCTRACK";
    auto* peer = static_cast<MediaTrack*>(GetSetTrackSendInfo(track_, sourceCat, selected.index,
        peerParm, nullptr));
    if (!peer || !ValidatePtr2(project_, peer, "MediaTrack*")) {
        speech_("Linked track unavailable"); return;
    }
    // Index among routes to/from this PARTICULAR peer. Do not use the
    // display-column index, because filters and unrelated routing change it.
    int ordinal = 0;
    for (int i = 0; i <= selected.index; ++i) {
        if (GetSetTrackSendInfo(track_, sourceCat, i, peerParm, nullptr) == peer) ++ordinal;
    }
    int corresponding = -1, seen = 0;
    const char* reverse = fromSend ? "P_SRCTRACK" : "P_DESTTRACK";
    const int count = GetTrackNumSends(peer, targetCat);
    for (int i = 0; i < count; ++i) {
        if (GetSetTrackSendInfo(peer, targetCat, i, reverse, nullptr) == track_ &&
            ++seen == ordinal) { corresponding = i; break; }
    }
    if (corresponding < 0) { speech_("Matching send or receive not found"); return; }
    if (!filterQuery_.empty()) {
        speech_("Clear the filter before jumping to the linked routing"); return;
    }
    int destinationRow = -1;
    for (int i = 0; i < static_cast<int>(rows_.size()); ++i)
        if (rows_[static_cast<size_t>(i)].track == peer) { destinationRow = i; break; }
    if (destinationRow < 0) { speech_("Linked track hidden in a closed folder"); return; }
    rememberPosition();
    row_ = destinationRow;
    track_ = peer;
    syncCursorToReaper();
    page_ = fromSend ? Page::receives : Page::sends;
    detailIndex_ = parameter_ = 0;
    midiPickup_.clear();
    valueMode_ = false;
    buildEntries();
    const int cols = static_cast<int>(entries_.size()) / detailHeight;
    for (int i = 0; i < cols; ++i)
        if (entries_[static_cast<size_t>(i * detailHeight)].index == corresponding) {
            detailIndex_ = i; break;
        }
    stepScale_ = memory_.step(parameterKey());
    rememberPosition();
    speech_(trackName() + ". " + currentParameterSpeech());
}
std::string TrackNavigator::parameterRangeIdentity() const {
    // F4 already has a stable physical FX-instance identity used by MIDI learn.
    if (page_ == Page::fxTcp) {
        std::string id;
        return midiFixedIdentity(id) ? id : std::string();
    }
    if (!track_ || (page_ != Page::tracks && page_ != Page::sends && page_ != Page::receives)) return {};
    const Entry* e = current();
    if (!e || e->type == Entry::header || e->type == Entry::sendCount ||
        e->type == Entry::receiveCount || e->type == Entry::fxCount ||
        e->type == Entry::midiMerge) return {};
    const auto id = parameterKey();
    const auto dot = id.find('.');
    if (dot == std::string::npos) return {};
    const std::string key = id.substr(dot + 1);
    const std::string owner = trackGuidText(track_);
    if (owner.empty()) return {};
    if (page_ == Page::tracks) return "Track|" + owner + "|" + key;
    if (!GetSetTrackSendInfo || e->index < 0) return {};
    const auto* peer = static_cast<MediaTrack*>(GetSetTrackSendInfo(track_, e->category,
        e->index, page_ == Page::sends ? "P_DESTTRACK" : "P_SRCTRACK", nullptr));
    const std::string other = trackGuidText(const_cast<MediaTrack*>(peer));
    const int ordinal = detailPeerOccurrence(e->category,e->index);
    if (other.empty() || ordinal < 1) return {};
    const std::string source = page_ == Page::sends ? owner : other;
    const std::string destination = page_ == Page::sends ? other : owner;
    return "Sends|" + source + "|" + destination + "|" +
           std::to_string(ordinal) + "|" + key;
}
ParameterRange TrackNavigator::parameterRangeBounds() const {
    if (page_ == Page::fxTcp) return {0,100}; // Normalized FX parameter percent.
    const Entry* e = current();
    if (!e) return {0,1};
    switch (e->type) {
        case Entry::volume: return {-150,48}; // REAPER dB, including mute at -150.
        case Entry::pan: case Entry::width: return {-100,100};
        case Entry::flag: case Entry::solo: case Entry::midiFollowsFader: return {0,1};
        case Entry::audioSourceMode: return {0,8};
        case Entry::audioSource: return {-1,63};
        case Entry::audioDestination: return {0,63};
        case Entry::sendType: return {0,3};
        // MIDI source is a DISCRETE 18-position combo: All (0),
        // channels 1..16, None (raw state 31). Display indices 0..17,
        // never expose invalid raw MIDI states 17..30 in range limits.
        case Entry::midiSource: return {0,17};
        case Entry::midiDestination: case Entry::midiSourceBus:
        case Entry::midiDestinationBus: return {0,16};
        default: return {0,1};
    }
}
ParameterRange TrackNavigator::currentParameterRange() const {
    const ParameterRange fallback = parameterRangeBounds();
    const std::string identity = parameterRangeIdentity();
    if (identity.empty()) return fallback;
    ParameterRange saved{};
    if (parseParameterRange(memory_.parameterRange(identity), saved,
                            fallback.minimum, fallback.maximum)) return saved;
    return fallback;
}
double TrackNavigator::clampParameterValue(const Entry& e, double raw) const {
    const auto range = currentParameterRange();
    if (e.type == Entry::volume) {
        const double dbValue = raw <= 0 ? -150.0 : 20.0 * std::log10(raw);
        const double bounded = range.clamp(dbValue);
        return bounded <= -150.0 ? 0.0 : std::pow(10.0,bounded/20.0);
    }
    if (e.type == Entry::pan || e.type == Entry::width)
        return range.clamp(raw * 100.0) / 100.0;
    if (e.type == Entry::midiSource) {
        const double ordinal = raw >= 31.0 ? 17.0 : raw;
        const int bounded = static_cast<int>(range.clamp(ordinal));
        return bounded >= 17 ? 31.0 : static_cast<double>(bounded);
    }
    return range.clamp(raw);
}
void TrackNavigator::editCurrentRange(char mode) {
    if (learnCc_ || filterEditing_ || numericEditing_ || memoryManager_ ||
        pendingRouting_ != RoutingKind::none) {
        speech_("Finish the current operation before editing a range"); return;
    }
    const std::string id = parameterRangeIdentity();
    if (id.empty()) { speech_("No editable parameter range for this field"); return; }
    const bool midi = mode != 'R', floating = mode == 'F';
    if (mode == 'C' && (!fixedCc_ || memory_.fixedCcLink(id).empty())) {
        speech_("Assign and enable a fixed MIDI CC before editing its range"); return;
    }
    if (floating && !floatingCc_) {
        speech_("Enable and learn a floating MIDI CC before editing its range"); return;
    }
    ParameterRange range = midi ? ParameterRange{0,127} : currentParameterRange();
    if (midi) {
        if (floating) range = floatingCcSessionRange();
        else parseParameterRange(memory_.ccRange(id), range, 0,127,true);
    }
    const auto allowed = midi ? ParameterRange{0,127} : parameterRangeBounds();
    std::wstring title = floating ? L"Floating CC range (session only)" :
                               midi ? L"Fixed CC range (0 to 127)" :
                               page_ == Page::fxTcp ? L"FX TCP parameter range (normalized percent)" :
                               (current() && current()->type == Entry::volume) ? L"Volume parameter range (dB)" :
                               (current() && (current()->type == Entry::pan || current()->type == Entry::width)) ?
                                   L"Parameter range (percent)" : L"Parameter range";
    if (page_ == Page::fxTcp) {
        if (const auto* param = currentFxTcpParameter()) title += L" - " + rangeNameUtf8(param->name);
    } else if (current()) title += L" - " + rangeNameUtf8(current()->title);
    const bool integer = midi || (!midi && page_ != Page::fxTcp && current() &&
        current()->type != Entry::volume && current()->type != Entry::pan &&
        current()->type != Entry::width);
    if (!editParameterRange(GetForegroundWindow(),title,allowed.minimum,allowed.maximum,range,integer)) return;
    if (floating) floatingCcSessionRange() = range;
    else {
        const bool defaults = range.minimum == allowed.minimum && range.maximum == allowed.maximum;
        if (midi) memory_.setCcRange(id,defaults ? "" : rangeText(range));
        else memory_.setParameterRange(id,defaults ? "" : rangeText(range));
        memory_.flush();
    }
    midiPickup_.clear();
    speech_(std::string(floating?"Floating CC range":midi?"Fixed CC range":"Parameter range") +
            " saved. " + rangeText(range));
}
void TrackNavigator::beginNumericEdit() {
    const Entry* e = current();
    if (!e || !nativeFilterAvailable_ || filterEditing_ || pendingRouting_ != RoutingKind::none) {
        speech_("Numeric editor unavailable"); return;
    }
    if (e->type == Entry::header || e->type == Entry::sendCount ||
        e->type == Entry::receiveCount || e->type == Entry::fxCount ||
        e->type == Entry::midiMerge) { speech_("Read only"); return; }
    valueMode_ = false;
    numericEditing_ = true;
    numericBuffer_.clear();
    speech_("Parameter value. Enter a number, then Enter. Escape cancels");
}
void TrackNavigator::commitNumericEdit() {
    if (!numericEditing_) return;
    const Entry* e = current();
    if (!e) { numericEditing_ = false; return; }
    std::string input = numericBuffer_;
    const auto first = input.find_first_not_of(" \t\r\n");
    if (first == std::string::npos) { speech_("Enter a number"); return; }
    input = input.substr(first);
    try {
        std::size_t parsed = 0;
        const double typed = std::stod(input, &parsed);
        const auto unit = input.substr(parsed);
        if (!std::isfinite(typed) || (unit.find_first_not_of(" \t\r\n") != std::string::npos &&
            unit != "dB" && unit != "db" && unit != "%")) {
            speech_("Invalid numeric value"); return;
        }
        if (unit == "%" && e->type != Entry::pan && e->type != Entry::width) {
            speech_("Percent unit only for Pan or Width"); return;
        }
        if ((unit == "dB" || unit == "db") && e->type != Entry::volume) {
            speech_("Decibel unit only for Volume"); return;
        }
        double raw = typed;
        switch (e->type) {
            case Entry::volume:
                if (typed < -150.0 || typed > 48.0 || unit == "%") { speech_("Volume range -150 to 48 dB"); return; }
                {
                    const auto limits = currentParameterRange();
                    if (typed < limits.minimum || typed > limits.maximum) {
                        speech_("Volume outside configured range. Minimum " +
                            std::to_string(limits.minimum) + " dB, maximum " +
                            std::to_string(limits.maximum) + " dB");
                        return;
                    }
                }
                raw = typed <= -150 ? 0.0 : std::pow(10.0, typed / 20.0); break;
            case Entry::pan: case Entry::width:
                if (typed < -100 || typed > 100) { speech_("Range -100 to 100 percent"); return; }
                raw = typed / 100.0; break;
            case Entry::flag: case Entry::solo: case Entry::midiFollowsFader:
                if (typed != 0 && typed != 1) { speech_("Use 0 for off or 1 for on"); return; }
                break;
            case Entry::audioSource: if (typed < -1 || typed > 63) { speech_("Audio source pair out of range"); return; } break;
            case Entry::audioDestination: if (typed < 0 || typed > 63) { speech_("Audio destination pair out of range"); return; } break;
            case Entry::audioSourceMode: if (typed < 0 || typed > 8) { speech_("Audio mode out of range"); return; } break;
            case Entry::sendType: if (typed < 0 || typed > 3) { speech_("Send type out of range"); return; } break;
            case Entry::midiSource: if ((typed < 0 || typed > 16) && typed != 31) { speech_("MIDI source out of range"); return; } break;
            case Entry::midiDestination: case Entry::midiSourceBus: case Entry::midiDestinationBus:
                if (typed < 0 || typed > 16) { speech_("MIDI destination or bus out of range"); return; } break;
            default: speech_("Not editable numerically"); return;
        }
        // Numeric routing selectors are integers; reject silent truncation.
        if (e->type != Entry::volume && e->type != Entry::pan && e->type != Entry::width && raw != std::trunc(raw)) {
            speech_("Enter a whole number"); return;
        }
        numericEditing_ = false;
        suppressPutSpeech_ = true;
        try { put(*e, raw); } catch (...) { suppressPutSpeech_ = false; throw; }
        suppressPutSpeech_ = false;
        // Match FX Params: the native EDIT has already accepted the value.
        // Closing it updates the accessible Grid/Value review line; a second
        // OSARA message here repeats parameter, CC and Auto unnecessarily.
    } catch (const std::exception&) { speech_("Invalid numeric value"); }
}
} // namespace lrp
