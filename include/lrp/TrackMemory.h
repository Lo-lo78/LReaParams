#pragma once
#include "Profile.h"
#include <filesystem>
#include <map>
#include <string>

namespace lrp {
// TEST54.1: one native Track Params profile per saved REAPER project.
// Old global Track CC Map.tp is read-only seed material for first use.
// The same .tp will also host future per-track F4 entries.
class TrackMemory {
public:
    void load(const std::filesystem::path& resource, const std::string& projectFilename);
    const std::filesystem::path& file() const noexcept { return file_; }
    bool fixedEnabled() const;
    void setFixedEnabled(bool on);
    void flush();
    void reset() noexcept;
    int step(const std::string& parameter) const;
    void setStep(const std::string& parameter, int step);
    bool valueSpeech(const std::string& parameter) const;
    void setValueSpeech(const std::string& parameter, bool enabled);
    bool ccSpeech(const std::string& page, const std::string& parameter) const;
    void setCcSpeech(const std::string& page, const std::string& parameter, bool enabled);
    // Read and patch existing Lua-compatible MIDI maps; never rebuild the .tp.
    std::string ccLink(const std::string& section, const std::string& key) const;
    void setCcLink(const std::string& section, const std::string& key, const std::string& link);
    std::map<std::string, std::string> ccLinks(const std::string& section) const;
    std::string position(const std::string& key) const;
    void setPosition(const std::string& key, const std::string& value);
private:
    std::string read(const std::string& section, const std::string& key) const;
    void edit(const std::string& section, const std::string& key, const std::string& value);
    std::filesystem::path resource_, file_;
    std::string projectIdentity_;
    Profile profile_{};
    std::string digest_, pendingLegacyPayload_;
    // Section -> key -> requested value. Only explicitly edited keys are patched.
    std::map<std::string, std::map<std::string, std::string>> edits_;
    bool loaded_ = false, existed_ = false;
};
}
