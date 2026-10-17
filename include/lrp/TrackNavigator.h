#pragma once
#include "Navigator.h"
#include "ReaperApi.h"
#include "TrackMemory.h"
#include <vector>

namespace lrp {
// F1: one track per row, nine parameter columns.
// F2/F3: one send/receive per COLUMN, fourteen parameter ROWS, as in Lua.
class TrackNavigator final : public Navigator {
public:
    explicit TrackNavigator(std::function<void(const std::string&)> speech) : speech_(std::move(speech)) {}
    void setResourceRoot(const std::filesystem::path& root) { resource_ = root; }
    bool begin() override;
    void end() noexcept override;
    bool active() const noexcept override { return active_; }
    bool contextUnchanged() const override;
    bool accepts(const Key&) const noexcept override;
    void handle(const Key&) override;
    void announce() override;
    void announceTitle() override;
    std::wstring windowTitle() const override;
    std::string reviewLine() const override;
    bool nativeValueSlider() const override;
    double valueFraction() const override;
    std::string sliderLabel() const override;
private:
    struct Entry {
        std::string title;
        std::string parm;
        int category = 99, index = -1;
        enum Type { volume, pan, width, flag, solo, sendCount, receiveCount, fxCount,
            header, audioSourceMode, audioSource, audioDestination, sendType,
            midiSource, midiDestination, midiSourceBus, midiDestinationBus,
            midiFollowsFader, midiMerge } type{};
    };
    struct TrackRow { MediaTrack* track{}; GUID guid{}; int projectIndex{}; };
    enum class Page { tracks, sends, receives };
    static constexpr int detailHeight = 14;
    void buildEntries();
    bool selectPage(Page);
    void restorePosition();
    void rememberPosition();
    std::string parameterKey() const;
    std::string pageKey() const;
    std::string rowGuid() const;
    bool ccSpeechSupported() const;
    void moveTrack(int delta);
    void moveParameter(int delta);
    void moveDetailColumn(int delta);
    void nudge(int direction, bool coarse);
    void toggle(const Entry&);
    double get(const Entry&) const;
    void put(const Entry&, double);
    std::string trackName() const;
    std::string detailPeerName(int category, int index) const;
    std::string currentParameterSpeech() const;
    std::string parameterValueSpeech() const;
    void announceTrack();
    std::string valueText(const Entry&, double) const;
    const Entry* current() const;
    std::vector<TrackRow> rows_;
    std::vector<Entry> entries_;
    ReaProject* project_{};
    MediaTrack* track_{};
    MediaTrack* initialSelection_{};
    int trackCount_{};
    int row_{};
    int parameter_{};       // F1: 0..8 column; F2/F3: 0..13 vertical field
    int detailIndex_{};     // F2/F3 send/receive column
    int stepScale_{};       // TEST49: restored from the current parameter's .tp preference
    int sends_{}, receives_{};
    Page page_ = Page::tracks;
    bool active_ = false, valueMode_ = false;
    std::function<void(const std::string&)> speech_;
    std::filesystem::path resource_;
    TrackMemory memory_;
};
}
