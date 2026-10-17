#include "lrp/TrackMemory.h"
#include "lrp/Storage.h"
#include <windows.h>
#include <algorithm>
#include <stdexcept>

namespace lrp {
namespace {
constexpr const char* stepsSection = "LReaParams.StepScales";
constexpr const char* speechSection = "LReaParams.ParameterSpeech";
constexpr const char* navigationSection = "LReaParams.NavigationMemory";

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
        const bool hasNewline = matchEnd > match && bytes[matchEnd - 1] == '\n';
        const std::string oldEol = hasNewline && matchEnd - match >= 2 && bytes[matchEnd - 2] == '\r' ? "\r\n" : "\n";
        bytes.replace(match, matchEnd - match, line + (hasNewline ? oldEol : ""));
        return bytes;
    }
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
    resource_.clear(); file_.clear(); profile_ = {}; digest_.clear(); pendingLegacyPayload_.clear(); edits_.clear();
    loaded_ = existed_ = false;
}
void TrackMemory::load(const std::filesystem::path& root) {
    reset();
    if (root.empty()) throw ProfileError("Track memory resource path missing");
    resource_ = root;
    file_ = resource_ / L"LReaParams" / L"Tracks" / L"Track CC Map.tp";
    if (std::filesystem::exists(file_)) {
        if (std::filesystem::is_symlink(file_)) throw ProfileError("Track profile symlink refused");
        const auto bytes = readFile(file_);
        profile_ = parseNative(bytes);
        if (profile_.kind != ProfileKind::track || profile_.headers.count("TrackGUID") ||
            profile_.headers.at("F4CCScope").empty())
            throw ProfileError("Unrelated Track profile: refusing write");
        digest_ = sha256(bytes); existed_ = true;
    } else {
        // The legacy importer runs asynchronously. If the original main TXT
        // has not yet been imported, NEVER create a competing empty .tp: doing
        // so would turn the historic mapping into an import conflict.
        for (const auto& legacy : {
            resource_ / L"Scripts" / L"Lo-lo - Scripts" / L"Utility" / L"Scripts" / L"Tracks" / L"Track CC Map.txt",
            resource_ / L"LReaParams" / L"Tracks" / L"Track CC Map.txt"}) {
            if (!std::filesystem::exists(legacy)) continue;
            if (std::filesystem::is_symlink(legacy)) throw ProfileError("Legacy Track map symlink refused");
            const auto candidate = readFile(legacy);
            try {
                const auto parsed = parseLegacy(candidate);
                if (parsed.kind == ProfileKind::track && !parsed.headers.count("TrackGUID")) {
                    pendingLegacyPayload_ = candidate;
                    profile_ = parsed;
                    break;
                }
            } catch (const ProfileError&) { /* obsolete Version 1 maps cannot be imported */ }
        }
        // Same required Version=2 section names as the Lua main CC map.
        // Don't create this file until a preference actually changes.
        if (pendingLegacyPayload_.empty()) profile_ = parseLegacy("# Speak Track Params - TrackTake Navigator\n"
            "# Main Track CC map; additional LReaParams sections store preferences.\n"
            "Version=2\nF4CCScope=ProjectTrack\n\n[Track]\n\n[Sends]\n\n"
            "[Receives]\n\n[FXParams.Plugin]\n");
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
void TrackMemory::setStep(const std::string& id, int value) { edit(stepsSection, id, std::to_string(std::clamp(value, -10, 10))); }
bool TrackMemory::valueSpeech(const std::string& id) const { return read(speechSection, id) != "0"; }
void TrackMemory::setValueSpeech(const std::string& id, bool on) { edit(speechSection, id, on ? "1" : "0"); }
bool TrackMemory::ccSpeech(const std::string& page, const std::string& id) const {
    return read("CCSpeech." + page, ccKey(id)) == "1";
}
void TrackMemory::setCcSpeech(const std::string& page, const std::string& id, bool on) {
    if (page != "Track" && page != "Sends" && page != "Receives") throw ProfileError("Unsupported CC speech page");
    edit("CCSpeech." + page, ccKey(id), on ? "1" : "");
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
    if (verified.kind != ProfileKind::track || verified.headers.count("TrackGUID"))
        throw ProfileError("Track memory profile identity changed");
    const auto bytes = serializeNative(verified);
    if (existed_) {
        if (!std::filesystem::exists(file_) || std::filesystem::is_symlink(file_))
            throw ProfileError("Track CC map removed or replaced externally");
        const auto current = readFile(file_);
        if (sha256(current) != digest_) throw ProfileError("Track CC map modified externally; not overwritten");
        if (current == bytes) { profile_ = std::move(verified); edits_.clear(); return; }
        const auto backup = resource_ / L"LReaParams" / L"Backups" / L"ProfileEdits" /
            std::filesystem::u8path(sha256(current) + ".tp");
        if (!writeNewVerified(backup, current)) throw ProfileError("Could not back up Track CC map");
    } else if (!pendingLegacyPayload_.empty()) {
        // Only the importer may create the target while the old map is pending.
        // Rebase user preferences onto its exact imported bytes after verifying
        // identity. A genuinely different newly-created file is a conflict.
        if (!std::filesystem::exists(file_))
            throw ProfileError("Track CC map import pending; no empty profile written");
        if (std::filesystem::is_symlink(file_)) throw ProfileError("Track CC map symlink refused");
        const auto fresh = readFile(file_);
        const auto parsed = parseNative(fresh);
        if (parsed.kind != ProfileKind::track || parsed.payload != pendingLegacyPayload_)
            throw ProfileError("Imported Track CC map differs; refusing overwrite");
        digest_ = sha256(fresh); existed_ = true;
        profile_ = parsed; pendingLegacyPayload_.clear();
        // Re-serialize with the imported map as the base and retain edits.
        flush();
        return;
    } else if (std::filesystem::exists(file_)) {
        throw ProfileError("Track CC map appeared externally; not overwritten");
    }
    std::filesystem::create_directories(file_.parent_path());
    auto temporary = file_;
    temporary += L".tmp-" + std::to_wstring(GetCurrentProcessId());
    if (std::filesystem::exists(temporary)) throw ProfileError("Stale Track memory temp file");
    if (!writeNewVerified(temporary, bytes)) throw ProfileError("Could not stage Track CC map");
    try {
        if (parseNative(readFile(temporary)).payload != payload) throw ProfileError("Track CC map verification failed");
        if (!MoveFileExW(temporary.c_str(), file_.c_str(), MOVEFILE_REPLACE_EXISTING | MOVEFILE_WRITE_THROUGH))
            throw ProfileError("Could not replace Track CC map; backup preserved");
    } catch (...) {
        std::error_code ec; std::filesystem::remove(temporary, ec); throw;
    }
    if (readFile(file_) != bytes) throw ProfileError("Track CC map readback mismatch");
    profile_ = std::move(verified); digest_ = sha256(bytes); existed_ = true; edits_.clear();
}
} // namespace lrp
