#include "lrp/TrackNavigator.h"
#include <string>
#include <cstring>
#include <vector>

namespace lrp {
namespace {
// Only rewrite top-level ACT/VIS lines: do not touch automation items or
// nested source envelopes. Same technique already used by FX Params.
std::string rewriteState(std::string chunk, const char* key, bool enabled) {
    int depth = 0;
    bool found = false;
    const std::string prefix = std::string(key) + " ";
    std::size_t start = 0;
    while (start < chunk.size()) {
        const std::size_t end = chunk.find('\n', start);
        const std::size_t length = (end == std::string::npos ? chunk.size() : end) - start;
        const std::string line = chunk.substr(start, length);
        if (depth == 1 && line.compare(0, prefix.size(), prefix) == 0) {
            const std::size_t following = line.find(' ', prefix.size());
            const std::string replacement = prefix + (enabled ? "1" : "0") +
                (following == std::string::npos ? "" : line.substr(following));
            chunk.replace(start, length, replacement);
            found = true;
            start += replacement.size();
        } else {
            if (!line.empty() && line[0] == '<') ++depth;
            else if (line == ">") --depth;
            start += length;
        }
        if (start >= chunk.size()) break;
        ++start;
    }
    return found ? chunk : std::string();
}
bool isShown(const std::string& chunk) {
    int depth = 0;
    bool active = false, visible = false;
    std::size_t start = 0;
    while (start < chunk.size()) {
        const auto end = chunk.find('\n', start);
        const auto len = (end == std::string::npos ? chunk.size() : end) - start;
        const std::string line = chunk.substr(start, len);
        if (depth == 1 && line.compare(0, 4, "ACT ") == 0) active = line.size() > 4 && line[4] == '1';
        if (depth == 1 && line.compare(0, 4, "VIS ") == 0) visible = line.size() > 4 && line[4] == '1';
        if (!line.empty() && line[0] == '<') ++depth;
        else if (line == ">") --depth;
        if (end == std::string::npos) break;
        start = end + 1;
    }
    return active && visible;
}
std::string envelopeChunk(TrackEnvelope* env) {
    if (!env || !GetEnvelopeStateChunk) return {};
    // Limit reads: no truncation will be written back to REAPER.
    thread_local std::vector<char> text(4 * 1024 * 1024, 0);
    text.front() = text.back() = 0;
    if (!GetEnvelopeStateChunk(env, text.data(), static_cast<int>(text.size()), false)) return {};
    const std::size_t len = std::char_traits<char>::length(text.data());
    if (len >= text.size() - 1) return {};
    return std::string(text.data(), len);
}
bool setShown(TrackEnvelope* env, bool on) {
    const std::string old = envelopeChunk(env);
    if (old.empty()) return false;
    const auto active = rewriteState(old, "ACT", on);
    if (active.empty()) return false;
    const auto visible = rewriteState(active, "VIS", on);
    if (visible.empty()) return false;
    return SetEnvelopeStateChunk && SetEnvelopeStateChunk(env, visible.c_str(), true);
}
} // namespace

bool TrackNavigator::currentEnvelopeActive() const {
    const Entry* e = current();
    if (!active_ || !track_ || !e) return false;
    const char* name = nullptr;
    if (e->type == Entry::volume) name = "Volume";
    else if (e->type == Entry::pan) name = "Pan";
    else if (e->type == Entry::width && page_ == Page::tracks) name = "Width";
    else if (e->type == Entry::flag && e->parm == "B_MUTE") name = "Mute";
    else return false;
    TrackEnvelope* env = nullptr;
    if (page_ == Page::tracks) {
        if (GetTrackEnvelopeByName) env = GetTrackEnvelopeByName(track_, name);
    } else if (GetSetTrackSendInfo) {
        const char* param = e->type == Entry::volume ? "P_ENV:<VOLENV" :
            e->type == Entry::pan ? "P_ENV:<PANENV" : "P_ENV:<MUTEENV";
        env = static_cast<TrackEnvelope*>(GetSetTrackSendInfo(track_, e->category, e->index, param, nullptr));
    }
    return env && ValidatePtr2(project_, env, "TrackEnvelope*") && isShown(envelopeChunk(env));
}

void TrackNavigator::toggleCurrentAutomation() {
    const Entry* e = current();
    if (!e || !track_) return;
    const char* name = nullptr;
    int nativeAction = 0;
    if (e->type == Entry::volume) { name = "Volume"; nativeAction = 40406; }
    else if (e->type == Entry::pan) { name = "Pan"; nativeAction = 40407; }
    else if (e->type == Entry::width && page_ == Page::tracks) name = "Width";
    else if (e->type == Entry::flag && e->parm == "B_MUTE") { name = "Mute"; nativeAction = 40867; }
    else { speech_("No automation"); return; }
    TrackEnvelope* env = nullptr;
    if (page_ == Page::tracks) {
        if (GetTrackEnvelopeByName) env = GetTrackEnvelopeByName(track_, name);
    } else if (GetSetTrackSendInfo) {
        const char* param = e->type == Entry::volume ? "P_ENV:<VOLENV" :
            e->type == Entry::pan ? "P_ENV:<PANENV" : "P_ENV:<MUTEENV";
        env = static_cast<TrackEnvelope*>(GetSetTrackSendInfo(track_, e->category, e->index, param, nullptr));
    }
    if (env && ValidatePtr2(project_, env, "TrackEnvelope*")) {
        const bool enable = !currentEnvelopeActive();
        Undo_BeginBlock2(project_);
        const bool ok = setShown(env, enable);
        Undo_EndBlock2(project_, "LReaParams: Track Params envelope", UNDO_STATE_TRACKCFG);
        if (ok) { UpdateArrange(); speech_(std::string(enable ? "Auto. " : "Auto off. ") + parameterValueSpeech()); }
        else speech_("Automation change failed");
        return;
    }
    if (page_ != Page::tracks || !nativeAction || !Main_OnCommand) {
        // Never synthesize malformed AUXRECV/Width envelope chunk data.
        speech_("Automation envelope not present. Creation for this field is not yet migrated");
        return;
    }
    // Native REAPER action creates track volume/pan/mute envelopes safely.
    // Temporarily select ONLY our F1 cursor track, not the user's multi-track
    // selection, and restore by GUID after the REAPER action completes.
    const auto selected = selectedTrackGuids();
    for (int i = 0, n = CountTracks(project_); i < n; ++i)
        if (MediaTrack* tr = GetTrack(project_, i)) SetTrackSelected(tr, tr == track_);
    refreshTrackSelection();
    Main_OnCommand(nativeAction, 0);
    for (int i = 0, n = CountTracks(project_); i < n; ++i) {
        MediaTrack* tr = GetTrack(project_, i);
        if (!tr) continue;
        const GUID* guid = GetTrackGUID(tr);
        bool originally = false;
        if (guid) for (const GUID& item : selected)
            if (std::memcmp(guid, &item, sizeof(GUID)) == 0) { originally = true; break; }
        SetTrackSelected(tr, originally);
    }
    refreshTrackSelection();
    UpdateArrange();
    if (currentEnvelopeActive()) speech_("Auto. " + parameterValueSpeech());
    else speech_("Automation change not confirmed");
}
} // namespace lrp
