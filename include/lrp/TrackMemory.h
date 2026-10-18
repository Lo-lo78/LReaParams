#pragma once
#include "Profile.h"
#include <filesystem>
#include <map>
#include <string>
#include <utility>

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
    // TEST55.3: per-target Fixed CC, in this project's existing TP file.
    // Older [Track]/[Sends]/[Receives] CC maps remain unchanged and inert.
    // Identity: Track|{GUID}|Parameter, Sends|{sourceGUID}|{destGUID}|ordinal|Parameter,
    // or FxTcp|{trackGUID}|{fxGUID}|nativeParameterIndex.
    std::string fixedCcLink(const std::string& identity) const;
    void setFixedCcLink(const std::string& identity, const std::string& link);
    std::map<std::string, std::string> fixedCcLinks() const;
    // Fingerprint of the outgoing-send topology at CC learn time. Absent or
    // changed guard: do not apply an ambiguous legacy Fixed CC send mapping.
    std::string routingGuard(const std::string& identity) const;
    void setRoutingGuard(const std::string& identity, const std::string& signature);
    void invalidateSendGuardsForSource(const std::string& sourceGuid);
    // Independent, initially OFF, speech preference for each exact Fixed CC target.
    // The same identity is shared by an outgoing Send and its incoming Receive.
    bool fixedCcSpeech(const std::string& identity) const;
    void setFixedCcSpeech(const std::string& identity, bool on);
    // Read and patch existing Lua-compatible MIDI maps; never rebuild the .tp.
    std::string ccLink(const std::string& section, const std::string& key) const;
    void setCcLink(const std::string& section, const std::string& key, const std::string& link);
    std::map<std::string, std::string> ccLinks(const std::string& section) const;
    // Read-only snapshots include unsaved in-memory edits. Empty entries are not memories.
    std::map<std::string, std::string> entries(const std::string& section) const;
    // A scoped REAPER dB range; absent preferences preserve the 0.0.54 behavior.
    std::pair<double, double> volumeRange(const std::string& page) const;
    void setVolumeRange(const std::string& page, double low, double high);
    void clearVolumeRange(const std::string& page);
    std::string trackSlot(int slot) const;
    void setTrackSlot(int slot, const std::string& guid);
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
