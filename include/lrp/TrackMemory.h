#pragma once
#include "Profile.h"
#include <filesystem>
#include <map>
#include <string>

namespace lrp {
// TEST49: Track Params preferences are part of the existing main .tp, not a
// parallel settings file.  REAPER values and MIDI CC mappings are untouched.
class TrackMemory {
public:
    void load(const std::filesystem::path& resource);
    void flush();
    void reset() noexcept;
    int step(const std::string& parameter) const;
    void setStep(const std::string& parameter, int step);
    bool valueSpeech(const std::string& parameter) const;
    void setValueSpeech(const std::string& parameter, bool enabled);
    bool ccSpeech(const std::string& page, const std::string& parameter) const;
    void setCcSpeech(const std::string& page, const std::string& parameter, bool enabled);
    std::string position(const std::string& key) const;
    void setPosition(const std::string& key, const std::string& value);
private:
    std::string read(const std::string& section, const std::string& key) const;
    void edit(const std::string& section, const std::string& key, const std::string& value);
    std::filesystem::path resource_, file_;
    Profile profile_{};
    std::string digest_, pendingLegacyPayload_;
    // Section -> key -> requested value. Only explicitly edited keys are patched.
    std::map<std::string, std::map<std::string, std::string>> edits_;
    bool loaded_ = false, existed_ = false;
};
}
