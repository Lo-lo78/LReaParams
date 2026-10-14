#pragma once
#include "Navigator.h"
#include "ReaperApi.h"
#include <vector>

namespace lrp {
// Basic native track/send navigator. Advanced Lua pages and MIDI CC mapping
// remain deferred; no placeholder action is presented as full equivalence.
class TrackNavigator final : public Navigator {
public:
    explicit TrackNavigator(std::function<void(const std::string&)> speech) : speech_(std::move(speech)) {}
    bool begin() override;
    void end() noexcept override { active_ = false; valueMode_ = false; }
    bool active() const noexcept override { return active_; }
    bool contextUnchanged() const override;
    bool accepts(const Key&) const noexcept override;
    void handle(const Key&) override;
    void announce() override;
private:
    struct Entry { std::string title; std::string parm; int category = 99; int index = -1; enum Type { volume, pan, width, flag, solo } type{}; };
    double get(const Entry&) const;
    void put(const Entry&, double);
    void nudge(int direction, bool coarse);
    void move(int delta);
    static std::string valueText(const Entry&, double);
    std::vector<Entry> entries_;
    ReaProject* project_{};
    MediaTrack* track_{};
    GUID guid_{};
    int sends_{}, receives_{}, parameter_{}, columnHeight_ = 10;
    bool active_ = false, valueMode_ = false;
    std::function<void(const std::string&)> speech_;
};
}
