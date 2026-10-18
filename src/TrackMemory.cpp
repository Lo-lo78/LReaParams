#include "lrp/TrackMemory.h"
#include "lrp/Storage.h"
#include <windows.h>
#include <algorithm>
#include <cctype>
#include <cmath>
#include <sstream>
#include <iomanip>
#include <stdexcept>

namespace lrp {
namespace {
constexpr const char* stepsSection = "LReaParams.StepScales";
constexpr const char* speechSection = "LReaParams.ParameterSpeech";
constexpr const char* navigationSection = "LReaParams.NavigationMemory";
constexpr const char* midiSection = "LReaParams.MidiSettings";
constexpr const char* fixedByTargetSection = "LReaParams.FixedCCByTarget";
constexpr const char* fixedSpeechSection = "LReaParams.FixedCCSpeechByTarget";
constexpr const char* routingGuardSection = "LReaParams.FixedRoutingGuards";

std::string patchLine(std::string bytes, const std::string& section,
                      const std::string& key, const std::string& value) {
    // Patch only the exact key and leave all unrelated headers, comments,
    // unknown sections, UTF-8 and LF/CRLF bytes untouched.
    const std::string line = key + "=" + value;
    const std::string eol = bytes.find("\r\n") != std::string::npos ? "\r\n" : "\n";
    std::size_t begin = std::string::npos, end = bytes.size(), match = std::string::npos, matchEnd = 0;
    std::string active;
    for (std::size_t at = 0; at < bytes.size();) {
        const std::size_t next = bytes.find('\n', at);
        const std::size_t stop = next == std::string::npos ? bytes.size() : next + 1;
        std::string text = bytes.substr(at, (next == std::string::npos ? stop : next) - at);
        if (!text.empty() && text.back() == '\r') text.pop_back();
        if (text.size() >= 2 && text.front() == '[' && text.back() == ']') {
            if (active == section && end == bytes.size()) end = at;
            active = text.substr(1, text.size() - 2);
            if (active == section) begin = at;
        } else if (active == section && text.rfind(key + "=", 0) == 0) {
            if (match != std::string::npos) throw ProfileError("Duplicate Track memory key");
            match = at; matchEnd = stop;
        }
        at = stop;
    }
    if (match != std::string::npos) {
        // Default/reset means no stored override, as in FX Memories.
        if (value.empty()) { bytes.erase(match, matchEnd - match); return bytes; }
        const bool hasNewline = matchEnd > match && bytes[matchEnd - 1] == '\n';
        const std::string oldEol = hasNewline && matchEnd - match >= 2 && bytes[matchEnd - 2] == '\r' ? "\r\n" : "\n";
        bytes.replace(match, matchEnd - match, line + (hasNewline ? oldEol : ""));
        return bytes;
    }
    if (value.empty()) return bytes; // Do not create empty/default settings.
    if (begin != std::string::npos) {
        if (end == bytes.size()) end = bytes.size();
        const bool needsEol = end > 0 && bytes[end - 1] != '\n';
        bytes.insert(end, (needsEol ? eol : "") + line + eol);
        return bytes;
    }
    if (!bytes.empty() && bytes.back() != '\n') bytes += eol;
    bytes += eol + "[" + section + "]" + eol + line + eol;
    return bytes;
}
std::string ccKey(const std::string& p) {
    if (p == "PhaseInvert") return "PhaseInvert";
    return p;
}
}
void TrackMemory::reset() noexcept {
    resource_.clear(); file_.clear(); projectIdentity_.clear(); profile_ = {}; digest_.clear(); edits_.clear();
    loaded_ = existed_ = false;
}
// Project profiles live under Tracks/Projects/<project>/ and contain all
// F1/F2/F3 MIDI mappings and preferences. The old global map is read-only
// seed material, never the target of an edit. The project filename hash
// prevents unrelated projects with the same display name from sharing CCs.
void TrackMemory::load(const std::filesystem::path& root, const std::string& projectFilename) {
    reset();
    if (root.empty()) throw ProfileError("Track memory resource path missing");
    resource_ = root;
    const bool saved = !projectFilename.empty();
    std::string name = "Default";
    std::string suffix = "Default";
    if (saved) {
        const auto input = std::filesystem::u8path(projectFilename);
        name = input.stem().u8string();
        if (name.empty()) name = "Project";
        // Hash the normalized full project path, NOT only its display name.
        // Different projects called Song.rpp get independent profiles.
        std::string canonical = projectFilename;
        std::transform(canonical.begin(), canonical.end(), canonical.begin(),
            [](unsigned char ch) { return static_cast<char>(std::tolower(ch)); });
        suffix = sha256(canonical).substr(0, 12);
    }
    for (char& ch : name) {
        const auto c = static_cast<unsigned char>(ch);
        if (c < 128 && !(std::isalnum(c) || ch == '-' || ch == '_' || ch == ' ')) ch = '_';
    }
    while (!name.empty() && (name.back() == ' ' || name.back() == '.')) name.pop_back();
    if (name.empty()) name = "Project";
    if (name.size() > 90) {
        name.resize(90);
        while (!name.empty() &&
            (static_cast<unsigned char>(name.back()) & 0xC0u) == 0x80u)
            name.pop_back();
        if (!name.empty() && (static_cast<unsigned char>(name.back()) & 0x80u))
            name.pop_back(); // avoid a partial UTF-8 lead byte
    }
    projectIdentity_ = suffix;
    const auto directory = resource_ / L"LReaParams" / L"Tracks" / L"Projects" / std::filesystem::u8path(name);
    file_ = directory / std::filesystem::u8path(name + "_" + suffix + ".tp");
    if (std::filesystem::exists(file_)) {
        if (std::filesystem::is_symlink(file_)) throw ProfileError("Project Track profile symlink refused");
        const auto bytes = readFile(file_);
        profile_ = parseNative(bytes);
        if (profile_.kind != ProfileKind::track || profile_.headers.count("TrackGUID") ||
            profile_.headers.at("F4CCScope") != "ProjectTrack" ||
            profile_.headers.count("LReaParamsProjectID") == 0 ||
            profile_.headers.at("LReaParamsProjectID") != projectIdentity_)
            throw ProfileError("Unrelated project Track profile: refusing write");
        digest_ = sha256(bytes); existed_ = true;
    } else {
        // One-time import/copy from the historic shared mapping. The importer
        // can be working concurrently, so prefer the converted .tp and fall
        // back to the old .txt, without creating or altering either one.
        const auto global = resource_ / L"LReaParams" / L"Tracks" / L"Track CC Map.tp";
        for (const auto& source : {
            global,
            resource_ / L"LReaParams" / L"Tracks" / L"Track CC Map.txt",
            resource_ / L"Scripts" / L"Lo-lo - Scripts" / L"Utility" / L"Scripts" / L"Tracks" / L"Track CC Map.txt"}) {
            if (!std::filesystem::exists(source)) continue;
            if (std::filesystem::is_symlink(source)) throw ProfileError("Legacy Track map symlink refused");
            const auto bytes = readFile(source);
            try {
                const auto parsed = source.extension() == L".tp" ? parseNative(bytes) : parseLegacy(bytes);
                if (parsed.kind != ProfileKind::track || parsed.headers.count("TrackGUID")) continue;
                profile_ = parsed;
                break;
            } catch (const ProfileError&) { /* unsupported legacy data: keep searching */ }
        }
        if (profile_.payload.empty()) {
            profile_ = parseLegacy("# LReaParams project Track Params profile\n"
                "Version=2\nF4CCScope=ProjectTrack\n\n[Track]\n\n[Sends]\n\n"
                "[Receives]\n\n[FXParams.Plugin]\n");
        }
        std::string payload = profile_.payload;
        // Keep imported assignments, steps and speech. Convert only the
        // identity header; the historic global file is left unchanged.
        const auto headerPos = payload.find("F4CCScope=");
        if (headerPos == std::string::npos) throw ProfileError("Old Track map missing CC scope");
        const auto headerEnd = payload.find('\n', headerPos);
        payload.replace(headerPos, headerEnd == std::string::npos ? payload.size() - headerPos : headerEnd - headerPos,
            "F4CCScope=ProjectTrack");
        const auto position = payload.find("F4CCScope=ProjectTrack");
        payload.insert(position, "LReaParamsProjectID=" + projectIdentity_ + "\n");
        // F4 uses this same project .tp in future releases: no F4 subfolder
        // and no separate per-track .tp is created by the C++ navigator.
        if (payload.find("[FXParams.ProjectTrack]") == std::string::npos)
            payload += "\n[FXParams.ProjectTrack]\n";
        profile_ = parseLegacy(std::move(payload));
    }
    loaded_ = true;
}

std::string TrackMemory::read(const std::string& section, const std::string& key) const {
    if (const auto pending = edits_.find(section); pending != edits_.end()) {
        if (const auto it = pending->second.find(key); it != pending->second.end()) return it->second;
    }
    if (const auto sectionIt = profile_.sections.find(section); sectionIt != profile_.sections.end()) {
        for (const auto& row : sectionIt->second) {
            if (row.rfind(key + "=", 0) == 0) return row.substr(key.size() + 1);
        }
    }
    return {};
}
void TrackMemory::edit(const std::string& section, const std::string& key, const std::string& value) {
    if (!loaded_) throw ProfileError("Track memory not loaded");
    if (key.empty() || key.size() > 200 ||
        key.find_first_of("\r\n=]") != std::string::npos ||
        value.size() > 256 || value.find_first_of("\r\n") != std::string::npos)
        throw ProfileError("Unsafe Track memory key/value");
    if (read(section, key) != value) edits_[section][key] = value;
}
int TrackMemory::step(const std::string& id) const {
    const auto s = read(stepsSection, id);
    try {
        if (s.empty()) return 0;
        std::size_t length = 0; const int result = std::stoi(s, &length);
        return length == s.size() ? std::clamp(result, -10, 10) : 0;
    } catch (...) { return 0; }
}
void TrackMemory::setStep(const std::string& id, int value) {
    edit(stepsSection, id, value == 0 ? "" : std::to_string(std::clamp(value, -10, 10)));
}
bool TrackMemory::valueSpeech(const std::string& id) const { return read(speechSection, id) != "0"; }
void TrackMemory::setValueSpeech(const std::string& id, bool on) { edit(speechSection, id, on ? "" : "0"); }
bool TrackMemory::ccSpeech(const std::string& page, const std::string& id) const {
    return read("CCSpeech." + page, ccKey(id)) == "1";
}
void TrackMemory::setCcSpeech(const std::string& page, const std::string& id, bool on) {
    if (page != "Track" && page != "Sends" && page != "Receives") throw ProfileError("Unsupported CC speech page");
    edit("CCSpeech." + page, ccKey(id), on ? "1" : "");
}
std::string TrackMemory::fixedCcLink(const std::string& identity) const {
    return read(fixedByTargetSection, identity);
}
void TrackMemory::setFixedCcLink(const std::string& identity, const std::string& link) {
    // Never allow a legacy generic parameter name in the scoped namespace.
    if (identity.rfind("Track|{", 0) != 0 && identity.rfind("Sends|{", 0) != 0)
        throw ProfileError("Missing track GUID in Fixed CC identity");
    if (link.size() > 32) throw ProfileError("Invalid Fixed CC link");
    edit(fixedByTargetSection, identity, link);
    if (link.empty() && identity.rfind("Sends|{", 0) == 0)
        edit(routingGuardSection, identity, "");
}
std::string TrackMemory::routingGuard(const std::string& identity) const {
    return read(routingGuardSection, identity);
}
void TrackMemory::setRoutingGuard(const std::string& identity, const std::string& signature) {
    if (identity.rfind("Sends|{", 0) != 0 || (signature.size() != 64 && !signature.empty()))
        throw ProfileError("Invalid Fixed CC routing guard");
    edit(routingGuardSection, identity, signature);
}
void TrackMemory::invalidateSendGuardsForSource(const std::string& sourceGuid) {
    const std::string prefix = "Sends|" + sourceGuid + "|";
    for (const auto& item : entries(routingGuardSection))
        if (item.first.rfind(prefix, 0) == 0 && !item.second.empty())
            edit(routingGuardSection, item.first, "");
}
bool TrackMemory::fixedCcSpeech(const std::string& identity) const {
    // No entry = silent, exactly like FX Params. Never fall back to a
    // type-wide legacy Track.Pan preference for a specific physical track.
    return read(fixedSpeechSection, identity) == "1";
}
void TrackMemory::setFixedCcSpeech(const std::string& identity, bool on) {
    if (identity.rfind("Track|{", 0) != 0 && identity.rfind("Sends|{", 0) != 0)
        throw ProfileError("Missing target GUID in Track CC speech identity");
    edit(fixedSpeechSection, identity, on ? "1" : "");
}
std::map<std::string, std::string> TrackMemory::fixedCcLinks() const {
    auto all = entries(fixedByTargetSection);
    for (auto it = all.begin(); it != all.end();) {
        if (it->second.empty()) it = all.erase(it);
        else ++it;
    }
    return all;
}
std::string TrackMemory::ccLink(const std::string& section, const std::string& key) const {
    if (section != "Track" && section != "Sends" && section != "Receives") return {};
    return read(section, key);
}
void TrackMemory::setCcLink(const std::string& section, const std::string& key, const std::string& link) {
    if (section != "Track" && section != "Sends" && section != "Receives")
        throw ProfileError("Unsupported Track CC section");
    edit(section, key, link);
}
std::map<std::string, std::string> TrackMemory::ccLinks(const std::string& section) const {
    std::map<std::string, std::string> result;
    if (section != "Track" && section != "Sends" && section != "Receives") return result;
    if (const auto it = profile_.sections.find(section); it != profile_.sections.end()) {
        for (const auto& line : it->second) {
            const auto pos = line.find('=');
            if (pos != std::string::npos) result[line.substr(0, pos)] = line.substr(pos + 1);
        }
    }
    if (const auto it = edits_.find(section); it != edits_.end())
        for (const auto& item : it->second) result[item.first] = item.second;
    return result;
}
bool TrackMemory::fixedEnabled() const {
    const std::string saved = read(midiSection, "FixedEnabled");
    if (saved == "1") return true;
    if (saved == "0") return false;
    // An imported type-wide Lua map is not a Fixed target: no track GUID.
    // Never reactivate it across every track merely because it is present.
    return !fixedCcLinks().empty();
}
void TrackMemory::setFixedEnabled(bool on) { edit(midiSection, "FixedEnabled", on ? "1" : "0"); }
std::map<std::string, std::string> TrackMemory::entries(const std::string& section) const {
    std::map<std::string, std::string> found;
    if (const auto it = profile_.sections.find(section); it != profile_.sections.end()) {
        for (const std::string& line : it->second) {
            const auto eq = line.find('=');
            if (eq != std::string::npos && eq > 0) found[line.substr(0, eq)] = line.substr(eq + 1);
        }
    }
    if (const auto it = edits_.find(section); it != edits_.end())
        for (const auto& item : it->second) found[item.first] = item.second;
    return found;
}
std::pair<double, double> TrackMemory::volumeRange(const std::string& page) const {
    if (page != "Track" && page != "Sends" && page != "Receives") return {-150.0, 48.0};
    const auto value = read("LReaParams.VolumeRanges", page);
    if (value.empty()) return {-150.0, 48.0};
    try {
        const auto separator = value.find(',');
        if (separator == std::string::npos) return {-150.0, 48.0};
        std::size_t n = 0, m = 0;
        const double low = std::stod(value.substr(0, separator), &n);
        const auto end = value.substr(separator + 1);
        const double high = std::stod(end, &m);
        if (n != separator || m != end.size() || !std::isfinite(low) || !std::isfinite(high) ||
            low < -150.0 || high > 12.0 || high - low < 0.01) return {-150.0, 48.0};
        return {low, high};
    } catch (...) { return {-150.0, 48.0}; }
}
void TrackMemory::setVolumeRange(const std::string& page, double low, double high) {
    if ((page != "Track" && page != "Sends" && page != "Receives") ||
        !std::isfinite(low) || !std::isfinite(high) || low < -150 || high > 12 || high - low < 0.01)
        throw ProfileError("Volume range must be between -150 and +12 dB");
    std::ostringstream out;
    out << std::fixed << std::setprecision(2) << low << ',' << high;
    edit("LReaParams.VolumeRanges", page, out.str());
}
void TrackMemory::clearVolumeRange(const std::string& page) {
    if (page != "Track" && page != "Sends" && page != "Receives")
        throw ProfileError("Unsupported Track Volume range section");
    edit("LReaParams.VolumeRanges", page, "");
}
std::string TrackMemory::trackSlot(int slot) const {
    if (slot < 1 || slot > 12) return {};
    return read("LReaParams.TrackPositions", "Slot" + std::to_string(slot));
}
void TrackMemory::setTrackSlot(int slot, const std::string& guid) {
    if (slot < 1 || slot > 12) throw ProfileError("Invalid Track memory slot");
    if (!guid.empty() && (guid.size() != 38 || guid.front() != '{' || guid.back() != '}'))
        throw ProfileError("Invalid Track memory GUID");
    edit("LReaParams.TrackPositions", "Slot" + std::to_string(slot), guid);
}
std::string TrackMemory::position(const std::string& key) const { return read(navigationSection, key); }
void TrackMemory::setPosition(const std::string& key, const std::string& value) { edit(navigationSection, key, value); }
void TrackMemory::flush() {
    if (!loaded_ || edits_.empty()) return;
    std::string payload = profile_.payload;
    for (const auto& section : edits_)
        for (const auto& item : section.second)
            payload = patchLine(std::move(payload), section.first, item.first, item.second);
    Profile verified = parseLegacy(payload);
    if (verified.kind != ProfileKind::track || verified.headers.count("TrackGUID") ||
        verified.headers.count("LReaParamsProjectID") == 0 ||
        verified.headers.at("LReaParamsProjectID") != projectIdentity_)
        throw ProfileError("Track memory profile identity changed");
    const auto bytes = serializeNative(verified);
    if (existed_) {
        if (!std::filesystem::exists(file_) || std::filesystem::is_symlink(file_))
            throw ProfileError("Project Track profile removed or replaced externally");
        const auto current = readFile(file_);
        if (sha256(current) != digest_) throw ProfileError("Project Track profile modified externally; not overwritten");
        if (current == bytes) { profile_ = std::move(verified); edits_.clear(); return; }
        const auto backup = resource_ / L"LReaParams" / L"Backups" / L"ProfileEdits" /
            std::filesystem::u8path(sha256(current) + ".tp");
        if (!writeNewVerified(backup, current)) throw ProfileError("Could not back up project Track profile");
    } else if (std::filesystem::exists(file_)) {
        throw ProfileError("Project Track profile appeared externally; not overwritten");
    }
    // writeNewVerified() creates directories only after checking every parent
    // for Windows reparse points/junctions; do NOT pre-create them here.
    auto temporary = file_;
    temporary += L".tmp-" + std::to_wstring(GetCurrentProcessId());
    if (std::filesystem::exists(temporary)) throw ProfileError("Stale Track memory temp file");
    if (!writeNewVerified(temporary, bytes)) throw ProfileError("Could not stage project Track profile");
    try {
        if (parseNative(readFile(temporary)).payload != payload) throw ProfileError("Project Track profile verification failed");
        if (!MoveFileExW(temporary.c_str(), file_.c_str(), MOVEFILE_REPLACE_EXISTING | MOVEFILE_WRITE_THROUGH))
            throw ProfileError("Could not replace project Track profile; backup preserved");
    } catch (...) {
        std::error_code ec; std::filesystem::remove(temporary, ec); throw;
    }
    if (readFile(file_) != bytes) throw ProfileError("Project Track profile readback mismatch");
    profile_ = std::move(verified); digest_ = sha256(bytes); existed_ = true; edits_.clear();
}
} // namespace lrp
