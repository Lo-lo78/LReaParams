#include "lrp/Profile.h"
#include <algorithm>
#include <cmath>
#include <cctype>
#include <locale>
#include <sstream>
#include <set>
#include <regex>
#include <limits>

namespace lrp {
namespace {
void require(bool test, const char* message) { if (!test) throw ProfileError(message); }
std::string trim(std::string s) {
    const auto a = s.find_first_not_of(" \t\r\n");
    if (a == std::string::npos) return {};
    return s.substr(a, s.find_last_not_of(" \t\r\n") - a + 1);
}
long long integer(const std::string& s, long long lo, long long hi) {
    const std::size_t offset = lo < 0 && !s.empty() && s[0] == '-' ? 1 : 0;
    require(s.size() > offset && std::all_of(s.begin() + offset, s.end(), [](unsigned char c) { return std::isdigit(c) != 0; }), "Invalid integer");
    std::size_t end = 0;
    long long n = 0;
    try { n = std::stoll(s, &end); } catch (...) { throw ProfileError("Integer overflow"); }
    require(end == s.size() && n >= lo && n <= hi, "Integer out of range");
    return n;
}
void normalized(const std::string& s) {
    static const std::regex syntax(R"([+-]?(?:[0-9]+(?:\.[0-9]*)?|\.[0-9]+)(?:[eE][+-]?[0-9]+)?)");
    require(std::regex_match(s, syntax), "Invalid decimal");
    std::istringstream stream(s); stream.imbue(std::locale::classic());
    double value = 0; stream >> value;
    require(!stream.fail() && std::isfinite(value) && value >= 0 && value <= 1, "Value outside 0..1");
}
Field field(const std::string& s) {
    const auto pos = s.find('=');
    require(pos != std::string::npos && pos > 0, "Expected key=value");
    return {s.substr(0, pos), s.substr(pos + 1)};
}
void paramRef(const std::string& s, bool withValue) {
    const auto fields = split(s, '\t');
    require(withValue ? fields.size() == 3u : (fields.size() == 2u || fields.size() == 3u), "Invalid parameter record");
    // Negative IDs are real Lua virtual parameters (e.g. Compare = -300000).
    // A third non-value column in a reference is a display alias.
    integer(fields[0], -2147483648LL, 2147483647); require(!fields[1].empty(), "Empty parameter name");
    if (withValue) normalized(fields[2]);
}
void refList(std::string s) {
    // Lua escapes newlines when embedding records in key=value fields.
    std::size_t pos = 0;
    while ((pos = s.find("\\n", pos)) != std::string::npos) { s.replace(pos, 2, "\n"); ++pos; }
    for (const auto& line : split(s, '\n')) if (!line.empty()) paramRef(line, false);
}
void ccValue(const std::string& s) {
    if (s.empty()) return;
    const auto fields = split(s, ','); require(fields.size() == 2, "Invalid MIDI CC record");
    integer(fields[0], 1, 16); integer(fields[1], 0, 127);
}
}
std::vector<std::string> split(std::string_view s, char delimiter) {
    std::vector<std::string> out; std::size_t start = 0;
    for (;;) { const auto pos = s.find(delimiter, start);
        out.emplace_back(s.substr(start, pos == s.npos ? s.size() - start : pos - start));
        if (pos == s.npos) break; start = pos + 1;
    } return out;
}
const char* kindName(ProfileKind k) noexcept {
    switch (k) { case ProfileKind::fx: return "FX"; case ProfileKind::track: return "TRACK"; default: return "TRACK"; }
}
const char* extension(ProfileKind k) noexcept {
    switch (k) { case ProfileKind::fx: return ".fx"; case ProfileKind::track: return ".tp"; default: return ".tp"; }
}
Profile parseLegacy(std::string bytes) {
    require(!bytes.empty() && bytes.size() <= maxProfileBytes, "Empty or oversized profile");
    require(bytes.find('\0') == std::string::npos, "NUL in text profile");
    Profile out; out.payload = std::move(bytes);
    std::string text = out.payload;
    if (text.compare(0, 3, "\xEF\xBB\xBF") == 0) text.erase(0, 3);
    std::string section;
    std::set<std::string> sectionNames;
    for (auto line : split(text, '\n')) {
        if (!line.empty() && line.back() == '\r') line.pop_back();
        if (trim(line).empty() || line[0] == '#' || line[0] == ';') continue;
        if (line[0] == '[') {
            require(line.size() > 2 && line.back() == ']', "Invalid section");
            section = line.substr(1, line.size() - 2);
            require(sectionNames.insert(section).second, "Duplicate section");
            out.sections[section]; continue;
        }
        if (!section.empty()) out.sections[section].push_back(line);
        else { auto f = field(line); require(out.headers.emplace(f.key, f.value).second, "Duplicate header"); }
    }
    const auto h = [&](const char* key) -> std::string {
        const auto it = out.headers.find(key); require(it != out.headers.end(), "Required header missing"); return it->second;
    };
    if (h("Version") == "3") {
        out.kind = ProfileKind::fx;
        require(!h("PluginRaw").empty(), "Empty plugin identity");
        const auto last = h("LastParam"); if (!last.empty()) paramRef(last, false);
        h("LastEntry"); h("LastArea"); h("QuickGroup");
        require(h("SlotAccessMode") == "param" || h("SlotAccessMode") == "group", "Invalid slot mode");
        require(h("CustomOrderView") == "plugin" || h("CustomOrderView") == "custom", "Invalid order view");
        for (const char* name : {"CustomOrder", "DefaultValues", "ParamSlots", "GroupSlots"})
            require(out.sections.count(name) != 0, "Missing FX section");
        for (const auto& l : out.sections.at("CustomOrder")) paramRef(l, false);
        for (const auto& l : out.sections.at("DefaultValues")) {
            // Lua's ReaEQ structural defaults are META<TAB>KEY<TAB>VALUE,
            // not numbered parameters. Preserve their VST chunk unchanged.
            if(l.rfind("META\tREA_EQ_",0)==0){
                require(l.find('\t',5)!=std::string::npos,"Malformed ReaEQ default metadata");
                continue;
            }
            paramRef(l,true);
        }
        for (const char* name : {"ParamSlots", "GroupSlots"}) {
            std::set<long long> slots;
            for (const auto& l : out.sections.at(name)) {
                const auto f = field(l); require(slots.insert(integer(f.key, 1, 12)).second, "Duplicate slot");
                if (!f.value.empty()) { if (std::string(name) == "ParamSlots") paramRef(f.value, false); else refList(f.value); }
            }
        }
        if (!h("QuickGroup").empty()) refList(h("QuickGroup"));
        if (out.sections.count("Extra")) for (const auto& l : out.sections.at("Extra")) field(l);
    } else if (h("Version") == "2") {
        out.kind = ProfileKind::track;
        const bool project = out.headers.count("TrackGUID") != 0;
        if (project) {
            require(!h("Project").empty() && !h("TrackName").empty(), "Missing project identity");
            static const std::regex guid(R"(\{[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}\})");
            require(std::regex_match(h("TrackGUID"), guid), "Invalid track GUID");
            require(out.sections.count("FXParams") != 0, "Missing project FXParams");
        } else {
            require(h("F4CCScope") == "Plugin" || h("F4CCScope") == "ProjectTrack", "Invalid CC scope");
            for (const char* name : {"Track", "Sends", "Receives", "FXParams.Plugin"})
                require(out.sections.count(name) != 0, "Missing track CC section");
        }
        for (const auto& pair : out.sections) {
            const auto& name = pair.first;
            if (name == "Track" || name == "Sends" || name == "Receives" || name == "FXParams" || name == "FXParams.Plugin") {
                for (const auto& l : pair.second) ccValue(field(l).value);
            } else if (name == "CCSpeech" || name.rfind("CCSpeech.", 0) == 0) {
                for (const auto& l : pair.second) { const auto f = field(l); require(f.value.empty() || f.value == "1", "Invalid CC speech flag"); }
            } else if (name == "F4Order") {
                for (const auto& l : pair.second) { const auto f = field(l); if (!f.value.empty()) for (const auto& v : split(f.value, ',')) integer(v, 0, 2147483647); }
            } else if (name == "LReaParams.StepScales") {
                for (const auto& l : pair.second) {
                    const auto f = field(l);
                    require(f.key.size() <= 200 && !f.key.empty(), "Invalid Track Step key");
                    if (!f.value.empty()) integer(f.value, -10, 10);
                }
            } else if (name == "LReaParams.ParameterSpeech") {
                for (const auto& l : pair.second) {
                    const auto f = field(l);
                    require(f.key.size() <= 200 && !f.key.empty() &&
                            (f.value.empty() || f.value == "0" || f.value == "1"), "Invalid Track speech preference");
                }
            } else if (name == "LReaParams.FixedCCSpeechByTarget") {
                static const std::regex scopedTrack(
                    R"(Track\|\{[0-9A-Fa-f]{8}-[0-9A-Fa-f]{4}-[0-9A-Fa-f]{4}-[0-9A-Fa-f]{4}-[0-9A-Fa-f]{12}\}\|(Volume|Pan|Width|Mute|Solo|PhaseInvert))");
                static const std::regex scopedSend(
                    R"(Sends\|\{[0-9A-Fa-f]{8}-[0-9A-Fa-f]{4}-[0-9A-Fa-f]{4}-[0-9A-Fa-f]{4}-[0-9A-Fa-f]{12}\}\|\{[0-9A-Fa-f]{8}-[0-9A-Fa-f]{4}-[0-9A-Fa-f]{4}-[0-9A-Fa-f]{4}-[0-9A-Fa-f]{12}\}\|([1-9][0-9]{0,2})\|(Volume|Pan|Mute))");
                static const std::regex scopedFxTcp(
                    R"(FxTcp\|\{[0-9A-Fa-f]{8}-[0-9A-Fa-f]{4}-[0-9A-Fa-f]{4}-[0-9A-Fa-f]{4}-[0-9A-Fa-f]{12}\}\|\{[0-9A-Fa-f]{8}-[0-9A-Fa-f]{4}-[0-9A-Fa-f]{4}-[0-9A-Fa-f]{4}-[0-9A-Fa-f]{12}\}\|([0-9]{1,5}))");
                for (const auto& l : pair.second) {
                    const auto f = field(l);
                    std::smatch fxParts;
                    const bool fxTcp = std::regex_match(f.key, fxParts, scopedFxTcp);
                    if (fxTcp) integer(fxParts[1].str(), 0, 32767);
                    require((std::regex_match(f.key, scopedTrack) || std::regex_match(f.key, scopedSend) || fxTcp) &&
                        (f.value.empty() || f.value == "1"), "Invalid per-target MIDI speech flag");
                }
            } else if (name == "LReaParams.FixedCCByTarget") {
                // Project-specific Fixed CCs are keyed by immutable track GUIDs.
                // For sends, the ordinal distinguishes duplicate connections.
                static const std::regex scopedTrack(
                    R"(Track\|\{[0-9A-Fa-f]{8}-[0-9A-Fa-f]{4}-[0-9A-Fa-f]{4}-[0-9A-Fa-f]{4}-[0-9A-Fa-f]{12}\}\|(Volume|Pan|Width|Mute|Solo|PhaseInvert))");
                static const std::regex scopedSend(
                    R"(Sends\|\{[0-9A-Fa-f]{8}-[0-9A-Fa-f]{4}-[0-9A-Fa-f]{4}-[0-9A-Fa-f]{4}-[0-9A-Fa-f]{12}\}\|\{[0-9A-Fa-f]{8}-[0-9A-Fa-f]{4}-[0-9A-Fa-f]{4}-[0-9A-Fa-f]{4}-[0-9A-Fa-f]{12}\}\|([1-9][0-9]{0,2})\|(Volume|Pan|Mute))");
                static const std::regex scopedFxTcp(
                    R"(FxTcp\|\{[0-9A-Fa-f]{8}-[0-9A-Fa-f]{4}-[0-9A-Fa-f]{4}-[0-9A-Fa-f]{4}-[0-9A-Fa-f]{12}\}\|\{[0-9A-Fa-f]{8}-[0-9A-Fa-f]{4}-[0-9A-Fa-f]{4}-[0-9A-Fa-f]{4}-[0-9A-Fa-f]{12}\}\|([0-9]{1,5}))");
                for (const auto& l : pair.second) {
                    const auto f = field(l);
                    std::smatch fxParts;
                    const bool fxTcp = std::regex_match(f.key, fxParts, scopedFxTcp);
                    if (fxTcp) integer(fxParts[1].str(), 0, 32767);
                    require(std::regex_match(f.key, scopedTrack) || std::regex_match(f.key, scopedSend) || fxTcp,
                        "Invalid scoped Track/Send/FX CC identity");
                    ccValue(f.value);
                }
            } else if (name == "LReaParams.MidiSettings") {
                for (const auto& l : pair.second) {
                    const auto f = field(l);
                    require(f.key == "FixedEnabled" && (f.value == "0" || f.value == "1"),
                        "Invalid project Track MIDI setting");
                }
            } else if (name == "LReaParams.VolumeRanges") {
                for (const auto& l : pair.second) {
                    const auto f = field(l);
                    require(f.key == "Track" || f.key == "Sends" || f.key == "Receives", "Invalid volume range scope");
                    const auto comma = f.value.find(',');
                    require(comma != std::string::npos, "Missing volume range separator");
                    try {
                        const auto loText = f.value.substr(0, comma);
                        const auto hiText = f.value.substr(comma + 1);
                        std::size_t n = 0, m = 0;
                        const double low = std::stod(loText, &n);
                        const double high = std::stod(hiText, &m);
                        require(n == loText.size() && m == hiText.size() &&
                                std::isfinite(low) && std::isfinite(high) && low >= -150.0 &&
                                high <= 12.0 && high - low >= 0.01, "Invalid volume range limits");
                    } catch (const std::exception&) { throw ProfileError("Invalid volume range limits"); }
                }
            } else if (name == "LReaParams.TrackPositions") {
                static const std::regex trackGuid(R"(\{[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}\})");
                for (const auto& l : pair.second) {
                    const auto f = field(l);
                    require(f.key.rfind("Slot", 0) == 0, "Invalid track memory key");
                    const auto number = integer(f.key.substr(4), 1, 12);
                    (void)number;
                    require(f.value.empty() || std::regex_match(f.value, trackGuid), "Invalid saved track GUID");
                }
            } else if (name == "LReaParams.NavigationMemory") {
                for (const auto& l : pair.second) {
                    const auto f = field(l);
                    require(!f.key.empty() && f.key.size() <= 200 && f.value.size() <= 256, "Invalid Track navigation preference");
                }
            }
        }
    } else throw ProfileError("Unknown profile version");
    return out;
}
std::string serializeNative(const Profile& p) {
    const auto valid = parseLegacy(p.payload);
    require(valid.kind == p.kind, "Payload kind mismatch");
    return std::string("LREAPARAMS_PROFILE_V1\nKind=") + kindName(p.kind) + "\nPayloadBytes=" + std::to_string(p.payload.size()) + "\n\n" + p.payload;
}
Profile parseNative(std::string bytes) {
    const auto end = bytes.find("\n\n"); require(end != std::string::npos && end < 150, "Invalid native header");
    const auto lines = split(std::string_view(bytes).substr(0, end), '\n');
    require(lines.size() == 3 && lines[0] == "LREAPARAMS_PROFILE_V1", "Unknown native version");
    const auto k = field(lines[1]), n = field(lines[2]);
    require(k.key == "Kind" && n.key == "PayloadBytes", "Invalid native fields");
    const auto size = integer(n.value, 1, static_cast<long long>(maxProfileBytes));
    require(static_cast<std::size_t>(size) == bytes.size() - end - 2, "Native payload length mismatch");
    auto out = parseLegacy(bytes.substr(end + 2)); require(k.value == kindName(out.kind), "Native type mismatch"); return out;
}
}
