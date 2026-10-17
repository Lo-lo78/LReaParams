#pragma once
#include "Navigator.h"
#include "ReaperApi.h"
#include "TrackMemory.h"
#include <vector>
#include <unordered_set>

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
    // TEST50 F1 selection: cursor rows are independent from REAPER's selected tracks.
    void resetSelectionStroke();
    void captureBaseSelection();
    void applyRangeSelection(int first, int last);
    void selectVisibleTracks();
    void toggleCursorTrackSelection(bool deselectOnly);
    void clearTrackSelection();
    void extendTrackSelection(int direction, bool page);
    void extendTrackSelectionToEdge(int direction);
    void announceSelection() const;
    void refreshTrackSelection();
    void moveToFolder(int direction);
    // TEST51.1: Lua-compatible, two-pass F1 sends and receives. Stored GUIDs
    // are re-resolved at commit time; no dangling MediaTrack* is retained.
    enum class RoutingKind { none, send, receive };
    std::vector<GUID> selectedTrackGuids() const;
    MediaTrack* trackByGuid(const GUID& guid) const;
    void addTrackRouting(RoutingKind kind);
    void startTrackRouting(RoutingKind kind);
    void completeTrackRouting();
    void cancelTrackRouting();
    void resetPendingRouting() noexcept;
    std::string pendingRoutingStatus() const;

    void moveTrack(int delta);
    void moveParameter(int delta);
    void moveDetailColumn(int delta);
    void nudge(int direction, bool coarse);
    void toggle(const Entry&);
    double get(const Entry&) const;
    void put(const Entry&, double);
    MediaTrack* routingEndpoint(const Entry&, bool source) const;
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
    bool selectionStroke_ = false;
    int selectionAnchorRow_ = 0;
    std::unordered_set<MediaTrack*> selectionBase_;
    RoutingKind pendingRouting_ = RoutingKind::none;
    std::vector<GUID> pendingTrackGuids_;
    std::function<void(const std::string&)> speech_;
    std::filesystem::path resource_;
    TrackMemory memory_;
};
}
