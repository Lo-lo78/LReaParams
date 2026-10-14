#pragma once
#include "Navigator.h"
#include "ReaperApi.h"
#include <vector>

namespace lrp {
// Native F1 track matrix: each visible track is one horizontal row.
// F2/F3 retain the basic send/receive controls as separate detail matrices.
class TrackNavigator final : public Navigator {
public:
    explicit TrackNavigator(std::function<void(const std::string&)> speech) : speech_(std::move(speech)) {}
    bool begin() override;
    void end() noexcept override { active_ = false; valueMode_ = false; rows_.clear(); entries_.clear(); }
    bool active() const noexcept override { return active_; }
    bool contextUnchanged() const override;
    bool accepts(const Key&) const noexcept override;
    void handle(const Key&) override;
    void announce() override;
    void announceTitle() override;
    std::wstring windowTitle() const override;
private:
    struct Entry {
        std::string title;
        std::string parm;
        int category = 99, index = -1;
        enum Type { volume, pan, width, flag, solo, sendCount, receiveCount, fxCount } type{};
    };
    struct TrackRow { MediaTrack* track{}; GUID guid{}; int projectIndex{}; };
    enum class Page { tracks, sends, receives };
    void buildEntries();
    bool selectPage(Page);
    void moveTrack(int delta);
    void moveParameter(int delta);
    void moveDetailRow(int delta);
    void nudge(int direction, bool coarse);
    double get(const Entry&) const;
    void put(const Entry&, double);
    std::string trackName() const;
    std::string currentParameterSpeech() const;
    static std::string valueText(const Entry&, double);
    std::vector<TrackRow> rows_;
    std::vector<Entry> entries_;
    ReaProject* project_{};
    MediaTrack* track_{};
    MediaTrack* initialSelection_{};
    int trackCount_{};
    int row_{};
    int parameter_{};
    int detailIndex_{};
    int sends_{}, receives_{};
    Page page_ = Page::tracks;
    bool active_ = false, valueMode_ = false;
    std::function<void(const std::string&)> speech_;
};
}
