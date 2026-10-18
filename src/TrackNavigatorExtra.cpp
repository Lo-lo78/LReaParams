#include "lrp/TrackNavigator.h"
#include <sstream>
#include <stdexcept>
#include <algorithm>
#include <cmath>
#include <cstring>
#include <exception>
#include <string>

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
void TrackNavigator::beginVolumeRangeEdit() {
    const Entry* e = current();
    if (!e || e->type != Entry::volume || !nativeFilterAvailable_ ||
        filterEditing_ || numericEditing_ || pendingRouting_ != RoutingKind::none) {
        speech_("Select a Volume parameter to edit its range"); return;
    }
    const auto limits = memory_.volumeRange(page_ == Page::tracks ? "Track" :
        page_ == Page::sends ? "Sends" : "Receives");
    std::ostringstream text;
    text << limits.first << "," << std::min(limits.second, 12.0);
    numericBuffer_ = text.str();
    numericEditing_ = rangeEditing_ = true;
    valueMode_ = false;
    speech_("Volume range. Enter minimum and maximum dB separated by comma. Escape cancels");
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
    rangeEditing_ = false;
    numericEditing_ = true;
    numericBuffer_.clear();
    speech_("Parameter value. Enter a number, then Enter. Escape cancels");
}
void TrackNavigator::commitNumericEdit() {
    if (!numericEditing_) return;
    if (rangeEditing_) {
        try {
            const auto comma = numericBuffer_.find(',');
            if (comma == std::string::npos) throw std::invalid_argument("Missing comma");
            std::size_t n = 0, m = 0;
            const auto lhs = numericBuffer_.substr(0, comma);
            const auto rhs = numericBuffer_.substr(comma + 1);
            const double low = std::stod(lhs, &n), high = std::stod(rhs, &m);
            if (lhs.substr(n).find_first_not_of(" \t") != std::string::npos ||
                rhs.substr(m).find_first_not_of(" \t") != std::string::npos)
                throw std::invalid_argument("Invalid characters");
            memory_.setVolumeRange(page_ == Page::tracks ? "Track" :
                page_ == Page::sends ? "Sends" : "Receives", low, high);
            memory_.flush();
            numericEditing_ = rangeEditing_ = false;
            speech_("Volume range saved. Minimum " + lhs + ", maximum " + rhs + " dB");
        } catch (...) { speech_("Invalid volume range. Enter two numbers from -150 to +12 dB, minimum below maximum"); }
        return;
    }
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
                    const auto limits = memory_.volumeRange(page_ == Page::tracks ? "Track" :
                        page_ == Page::sends ? "Sends" : "Receives");
                    if (typed < limits.first || typed > limits.second) {
                        speech_("Volume outside configured range. Minimum " +
                            std::to_string(limits.first) + " dB, maximum " +
                            std::to_string(limits.second) + " dB");
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
