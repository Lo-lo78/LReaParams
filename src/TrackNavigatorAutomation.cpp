#include "lrp/TrackNavigator.h"
#include <string>
#include <cstring>
#include <vector>
#include <algorithm>
#include <string_view>

namespace lrp {
namespace {
// Change only the top-level properties of an envelope, preserving its points,
// automation items, GUID, lane settings, and nested data.
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
            else if (line == ">" || line == ">\r") --depth;
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
        else if (line == ">" || line == ">\r") --depth;
        if (end == std::string::npos) break;
        start = end + 1;
    }
    return active && visible;
}
std::string envelopeChunk(TrackEnvelope* env) {
    if (!env || !GetEnvelopeStateChunk) return {};
    // Never write a truncated chunk back into REAPER.
    thread_local std::vector<char> text(4 * 1024 * 1024, 0);
    text.front() = text.back() = 0;
    if (!GetEnvelopeStateChunk(env, text.data(), static_cast<int>(text.size()), false)) return {};
    const std::size_t len = std::char_traits<char>::length(text.data());
    if (len >= text.size() - 1) return {};
    return std::string(text.data(), len);
}
std::string ensureArmed(std::string visible) {
    std::string armed = rewriteState(visible, "ARM", true);
    if (!armed.empty()) return armed;
    // A valid envelope can lack an ARM line. Insert it only at the end of
    // this single, complete envelope block, never into track routing data.
    const auto close = visible.rfind("\n>");
    if (close == std::string::npos) return {};
    visible.insert(close + 1, "ARM 1\n");
    return visible;
}
bool setShown(TrackEnvelope* env, bool on) {
    const std::string old = envelopeChunk(env);
    if (old.empty()) return false;
    const auto active = rewriteState(old, "ACT", on);
    if (active.empty()) return false;
    const auto visible = rewriteState(active, "VIS", on);
    if (visible.empty()) return false;
    // An armed send envelope must actually be write-enabled, not just visible.
    // Preserve an existing ARM state when hiding the envelope.
    const auto armed = on ? ensureArmed(visible) : std::string();
    if (on && armed.empty()) return false;
    const std::string& result = on ? armed : visible;
    return SetEnvelopeStateChunk && SetEnvelopeStateChunk(env, result.c_str(), true);
}

struct ChunkLine { std::size_t begin{}, end{}; std::string_view text; };
std::string_view strip(std::string_view value) {
    while (!value.empty() && (value.front() == ' ' || value.front() == '\t')) value.remove_prefix(1);
    while (!value.empty() && (value.back() == '\r' || value.back() == ' ' || value.back() == '\t')) value.remove_suffix(1);
    return value;
}
std::vector<ChunkLine> splitLines(const std::string& chunk) {
    std::vector<ChunkLine> lines;
    std::size_t start = 0;
    while (start < chunk.size()) {
        const auto next = chunk.find('\n', start);
        const auto finish = next == std::string::npos ? chunk.size() : next + 1;
        const auto length = (next == std::string::npos ? chunk.size() : next) - start;
        lines.push_back({start, finish, strip(std::string_view(chunk.data() + start, length))});
        start = finish;
    }
    return lines;
}
// REAPER stores send envelopes under AUXRECV on the destination track. Match
// both the RECEIVE INDEX and the exact AUX...ENV tag; pointer-only APIs are
// insufficient for absent Volume/Mute envelopes and duplicate connections.
std::string routingEnvelopeBlock(const std::string& chunk, int receiveIndex, const char* tag,
                                 std::size_t* offset = nullptr, std::size_t* count = nullptr) {
    const auto lines = splitLines(chunk);
    int depth = 0, receive = -1;
    bool inTargetReceive = false;
    const std::string expected = std::string("<") + tag;
    for (std::size_t i = 0; i < lines.size(); ++i) {
        const auto line = lines[i].text;
        if (depth == 1 && line.substr(0, 8) == "AUXRECV ") {
            inTargetReceive = (++receive == receiveIndex);
        }
        if (inTargetReceive && depth == 1 && line == expected) {
            const std::size_t start = lines[i].begin;
            int blockDepth = 1;
            for (std::size_t j = i + 1; j < lines.size(); ++j) {
                const auto nested = lines[j].text;
                if (!nested.empty() && nested.front() == '<') ++blockDepth;
                else if (nested == ">") --blockDepth;
                if (blockDepth == 0) {
                    const std::size_t end = lines[j].end;
                    if (offset) *offset = start;
                    if (count) *count = end - start;
                    return chunk.substr(start, end - start);
                }
            }
            return {}; // Malformed envelope: refuse modification.
        }
        if (!line.empty() && line.front() == '<') ++depth;
        else if (line == ">" || line == ">\r") --depth;
        if (depth < 0) return {};
    }
    return {};
}
std::string readTrackChunk(MediaTrack* track) {
    if (!track || !GetTrackStateChunk) return {};
    // Protect large projects: never write a truncated track-state chunk.
    thread_local std::vector<char> buffer(16 * 1024 * 1024, 0);
    buffer.front() = buffer.back() = 0;
    if (!GetTrackStateChunk(track, buffer.data(), static_cast<int>(buffer.size()), false)) return {};
    const std::size_t length = std::char_traits<char>::length(buffer.data());
    return length < buffer.size() - 1 ? std::string(buffer.data(), length) : std::string();
}
const char* routingTag(const char* name) {
    return std::strcmp(name, "Volume") == 0 ? "AUXVOLENV" :
           std::strcmp(name, "Pan") == 0 ? "AUXPANENV" : "AUXMUTEENV";
}
const char* routingSwsAction(const char* name) {
    return std::strcmp(name, "Volume") == 0 ? "_BR_SHOW_SEND_ENV_VOL_SEL_TRACK" :
           std::strcmp(name, "Pan") == 0 ? "_BR_SHOW_SEND_ENV_PAN_SEL_TRACK" :
           "_BR_SHOW_SEND_ENV_MUTE_SEL_TRACK";
}
struct RouteTarget { MediaTrack* destination{}; MediaTrack* source{}; int receive = -1; };
RouteTarget resolveTarget(ReaProject* project, MediaTrack* owner, int category, int index) {
    if (!owner || index < 0 || !GetSetTrackSendInfo) return {};
    if (category == -1) {
        auto* src = static_cast<MediaTrack*>(GetSetTrackSendInfo(owner, -1, index, "P_SRCTRACK", nullptr));
        if (src && ValidatePtr2(project, src, "MediaTrack*")) return {owner, src, index};
        return {};
    }
    if (category != 0) return {};
    auto* dest = static_cast<MediaTrack*>(GetSetTrackSendInfo(owner, 0, index, "P_DESTTRACK", nullptr));
    if (!dest || !ValidatePtr2(project, dest, "MediaTrack*")) return {};
    int ordinal = 0;
    for (int send = 0; send <= index; ++send)
        if (GetSetTrackSendInfo(owner, 0, send, "P_DESTTRACK", nullptr) == dest) ++ordinal;
    int seen = 0;
    for (int recv = 0, total = GetTrackNumSends(dest, -1); recv < total; ++recv)
        if (GetSetTrackSendInfo(dest, -1, recv, "P_SRCTRACK", nullptr) == owner && ++seen == ordinal)
            return {dest, owner, recv};
    return {};
}
bool routingShown(const RouteTarget& route, const char* tag) {
    if (!route.destination || route.receive < 0) return false;
    const auto chunk = readTrackChunk(route.destination);
    return !chunk.empty() && isShown(routingEnvelopeBlock(chunk, route.receive, tag));
}
bool armIsOn(const std::string& chunk) {
    int depth = 0;
    const auto lines = splitLines(chunk);
    for (const auto& line : lines) {
        if (depth == 1 && line.text.substr(0, 4) == "ARM ")
            return line.text.size() > 4 && line.text[4] == '1';
        if (!line.text.empty() && line.text.front() == '<') ++depth;
        else if (line.text == ">") --depth;
    }
    return false;
}
bool setRoutingShown(const RouteTarget& route, const char* tag, bool on) {
    if (!route.destination || route.receive < 0 || !SetTrackStateChunk) return false;
    std::string chunk = readTrackChunk(route.destination);
    if (chunk.empty()) return false;
    std::size_t offset = 0, length = 0;
    const auto old = routingEnvelopeBlock(chunk, route.receive, tag, &offset, &length);
    if (old.empty()) return false;
    auto active = rewriteState(old, "ACT", on);
    if (active.empty()) return false;
    auto visible = rewriteState(active, "VIS", on);
    if (visible.empty()) return false;
    // Keep automation armed when enabling. Do not alter the arm when disabling.
    auto armed = on ? ensureArmed(visible) : std::string();
    if (on && armed.empty()) return false;
    chunk.replace(offset, length, on ? armed : visible);
    if (!SetTrackStateChunk(route.destination, chunk.c_str(), true)) return false;
    if (routingShown(route, tag) != on) return false;
    if (!on) return true;
    const auto checked = readTrackChunk(route.destination);
    return !checked.empty() && armIsOn(routingEnvelopeBlock(checked, route.receive, tag));
}
// Only a standard REAPER envelope header is added, leaving every existing
// track chunk byte intact. There is no guessed action ID or accidental default
// envelope rewrite. Incompatible chunks fail without changing the project.
TrackEnvelope* trackWidthEnvelope(MediaTrack* track) {
    TrackEnvelope* env = GetTrackEnvelopeByChunkName ?
        GetTrackEnvelopeByChunkName(track, "<WIDTHENV2") : nullptr;
    return env ? env : (GetTrackEnvelopeByName ? GetTrackEnvelopeByName(track, "Width") : nullptr);
}
bool createWidthEnvelope(MediaTrack* track, ReaProject* project) {
    if (!track || !project || !SetTrackStateChunk) return false;
    if (auto* existing = trackWidthEnvelope(track))
        return ValidatePtr2(project, existing, "TrackEnvelope*") && setShown(existing, true);
    std::string oldChunk = readTrackChunk(track);
    if (oldChunk.empty()) return false;
    // If an envelope already exists under the native chunk tag, do not add a
    // duplicate. The caller should instead resolve it through REAPER's API.
    if (oldChunk.find("<WIDTHENV2\n") != std::string::npos ||
        oldChunk.find("<WIDTHENV2\r\n") != std::string::npos) return false;
    const auto close = oldChunk.rfind("\n>");
    if (close == std::string::npos || close + 2 >= oldChunk.size() + 1) return false;
    // Insert directly before the track's final '>'; no FX chain/AUXRECV edits.
    std::string newChunk = oldChunk;
    newChunk.insert(close + 1, "<WIDTHENV2\nACT 1\nVIS 1 1 1\nLANEHEIGHT 0 0\nARM 1\nDEFSHAPE 0 -1 -1\n>\n");
    if (!SetTrackStateChunk(track, newChunk.c_str(), true)) return false;
    auto* env = trackWidthEnvelope(track);
    if (env && ValidatePtr2(project, env, "TrackEnvelope*") && isShown(envelopeChunk(env))) return true;
    // Undo an unsupported or ignored chunk structure immediately.
    SetTrackStateChunk(track, oldChunk.c_str(), true);
    return false;
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
    if (page_ != Page::tracks) {
        return routingShown(resolveTarget(project_, track_, e->category, e->index), routingTag(name));
    }
    TrackEnvelope* env = (page_ == Page::tracks && e->type == Entry::width) ?
        trackWidthEnvelope(track_) : (GetTrackEnvelopeByName ? GetTrackEnvelopeByName(track_, name) : nullptr);
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
    // Do not append parameterValueSpeech(): it already includes '. Auto'.
    // FX Params announces Auto exactly once, followed by parameter and value.
    const auto feedback = [this, e](bool on) {
        return std::string(on ? "Auto. " : "Auto off. ") + e->title + ", " +
            valueText(*e, get(*e)) + ccParameterSuffix();
    };
    if (page_ != Page::tracks) {
        const auto route = resolveTarget(project_, track_, e->category, e->index);
        if (!route.destination || !route.source) { speech_("Routing unavailable"); return; }
        const char* tag = routingTag(name);
        const bool enabled = routingShown(route, tag);
        const auto oldChunk = readTrackChunk(route.destination);
        if (oldChunk.empty()) { speech_("Automation chunk unavailable; no changes"); return; }
        const bool exists = !routingEnvelopeBlock(oldChunk, route.receive, tag).empty();
        if (exists) {
            Undo_BeginBlock2(project_);
            const bool ok = setRoutingShown(route, tag, !enabled);
            Undo_EndBlock2(project_, "LReaParams: send/receive automation", UNDO_STATE_TRACKCFG);
            if (!ok) { speech_("Automation change failed"); return; }
            if (TrackList_AdjustWindows) TrackList_AdjustWindows(false);
            UpdateArrange();
            speech_(feedback(!enabled));
            return;
        }
        // The Lua uses SWS/BR to create missing send envelopes, which are
        // stored on the destination's AUXRECV rather than the source track.
        // These SWS actions may create envelopes for ALL sends on the source.
        if (!NamedCommandLookup || !Main_OnCommand) {
            speech_("Creating send envelopes requires SWS/BR"); return;
        }
        const int action = NamedCommandLookup(routingSwsAction(name));
        if (!action) { speech_("Creating send envelopes requires SWS/BR"); return; }
        const auto selected = selectedTrackGuids();
        Undo_BeginBlock2(project_);
        for (int i = 0, n = CountTracks(project_); i < n; ++i)
            if (MediaTrack* tr = GetTrack(project_, i)) SetTrackSelected(tr, tr == route.source);
        refreshTrackSelection();
        Main_OnCommand(action, 0);
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
        // Validate the actual destination envelope before telling NVDA 'Auto'.
        const bool created = setRoutingShown(route, tag, true);
        Undo_EndBlock2(project_, "LReaParams: create send/receive automation", UNDO_STATE_TRACKCFG);
        if (TrackList_AdjustWindows) TrackList_AdjustWindows(false);
        UpdateArrange();
        speech_(created ? feedback(true) : "Send/receive automation not created");
        return;
    }
    TrackEnvelope* env = (page_ == Page::tracks && e->type == Entry::width) ?
        trackWidthEnvelope(track_) : (GetTrackEnvelopeByName ? GetTrackEnvelopeByName(track_, name) : nullptr);
    if (env && ValidatePtr2(project_, env, "TrackEnvelope*")) {
        const bool enable = !currentEnvelopeActive();
        Undo_BeginBlock2(project_);
        const bool ok = setShown(env, enable);
        Undo_EndBlock2(project_, "LReaParams: Track Params envelope", UNDO_STATE_TRACKCFG);
        if (ok && currentEnvelopeActive() == enable) { UpdateArrange(); speech_(feedback(enable)); }
        else speech_("Automation change not confirmed");
        return;
    }
    if (e->type == Entry::width && page_ == Page::tracks) {
        Undo_BeginBlock2(project_);
        const bool created = createWidthEnvelope(track_, project_);
        Undo_EndBlock2(project_, "LReaParams: create track Width automation", UNDO_STATE_TRACKCFG);
        if (TrackList_AdjustWindows) TrackList_AdjustWindows(false);
        UpdateArrange();
        speech_(created && currentEnvelopeActive() ? feedback(true) :
            "Width automation could not be created. No changes");
        return;
    }
    if (!nativeAction || !Main_OnCommand) {
        speech_("Automation envelope unavailable");
        return;
    }
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
    if (currentEnvelopeActive()) speech_(feedback(true));
    else speech_("Automation change not confirmed");
}
void TrackNavigator::clearTrackAutomations() {
    if (!active_ || !track_ || !project_ || !ValidatePtr2(project_, track_, "MediaTrack*")) {
        speech_("Track unavailable. No changes"); return;
    }
    if (!CountTrackEnvelopes || !GetTrackEnvelope) {
        speech_("Automation API unavailable. No changes"); return;
    }
    int changed = 0, failed = 0;
    Undo_BeginBlock2(project_);
    // GetTrackEnvelope enumerates real envelope instances, including FX
    // envelopes and track envelopes, without creating new lanes.
    const int total = std::clamp(CountTrackEnvelopes(track_), 0, 8192);
    for (int i = 0; i < total; ++i) {
        TrackEnvelope* env = GetTrackEnvelope(track_, i);
        if (!env || !ValidatePtr2(project_, env, "TrackEnvelope*")) { ++failed; continue; }
        const std::string old = envelopeChunk(env);
        if (old.empty()) { ++failed; continue; }
        if (rewriteState(old, "ACT", false) == old &&
            rewriteState(old, "VIS", false) == old) continue;
        if (setShown(env, false)) ++changed;
        else ++failed;
    }
    // Send envelopes are stored in AUXRECV blocks on *destination* tracks;
    // disabling only the source's envelopes would leave these running.
    const int sends = std::clamp(GetTrackNumSends(track_, 0), 0, 512);
    for (int i = 0; i < sends; ++i) {
        const auto route = resolveTarget(project_, track_, 0, i);
        if (!route.destination) { ++failed; continue; }
        for (const char* tag : {"AUXVOLENV", "AUXPANENV", "AUXMUTEENV"}) {
            const std::string old = routingEnvelopeBlock(readTrackChunk(route.destination), route.receive, tag);
            if (old.empty()) continue;
            if (rewriteState(old, "ACT", false) == old &&
                rewriteState(old, "VIS", false) == old) continue;
            if (setRoutingShown(route, tag, false)) ++changed;
            else ++failed;
        }
    }
    Undo_EndBlock2(project_, "LReaParams: disable Track automation", UNDO_STATE_TRACKCFG | UNDO_STATE_FX);
    if (TrackList_AdjustWindows) TrackList_AdjustWindows(false);
    UpdateArrange();
    if (failed) speech_("Automation partially disabled. " + std::to_string(changed) +
        " changed, " + std::to_string(failed) + " failed");
    else speech_("Automation off. " + std::to_string(changed) + " envelopes");
}

} // namespace lrp
