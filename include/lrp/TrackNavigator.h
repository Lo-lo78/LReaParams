#pragma once
#include "Navigator.h"
#include "ReaperApi.h"
#include "TrackMemory.h"
#include "MidiControl.h"
#include <map>
#include <vector>
#include <unordered_set>

namespace lrp {
// F1: one track per row, nine parameter columns.
// F2/F3: one send/receive per COLUMN, fourteen parameter ROWS, as in Lua.
class TrackNavigator final : public Navigator {
public:
    explicit TrackNavigator(std::function<void(const std::string&)> speech) : speech_(std::move(speech)) {}
    void setResourceRoot(const std::filesystem::path& root) { resource_ = root; }
    void setNativeFilterAvailable(bool enabled) noexcept { nativeFilterAvailable_ = enabled; }
    bool begin() override;
    // One-shot target when returning from FX Params, including Take FX.
    // Do not reopen from a stale TCP selection.
    void setNextStartTrack(MediaTrack* track) noexcept { nextStartTrack_ = track; }
    void end() noexcept override;
    bool active() const noexcept override { return active_; }
    bool contextUnchanged() const override;
    bool accepts(const Key&) const noexcept override;
    void handle(const Key&) override;
    void announce() override;
    void announceTitle() override;
    void tickMidi() { pollMidi(); }
    bool midiRunning() const noexcept { return active_ && (fixedCc_ || floatingCc_); }
    void prepareBackgroundMidi();
    bool openTrackMemories(bool standalone);
    bool isMemoryManager() const noexcept { return memoryManager_; }
    // Ctrl+Tab targets the track under the logical F1/F2/F3 cursor, not
    // the first physical track selected in REAPER.
    MediaTrack* cursorTrack() const noexcept { return active_ ? track_ : nullptr; }
    std::wstring windowTitle() const override;
    std::string reviewLine() const override;
    // TEST53: a real Win32 EDIT owns filter text/selection/caret, including UTF-8.
    // The extension binds this to the existing accessible keyboard window.
    bool nativeTextField() const noexcept { return active_ && (filterEditing_ || numericEditing_); }
    std::string nativeTextValue() const { return numericEditing_ ? numericBuffer_ : filterBuffer_; }
    std::string nativeTextLabel() const { if (page_ == Page::fxTcp && filterEditing_) return fxTcpListOpen_ ? "Filter FX parameter grid" : "Filter TCP FX parameters"; if (rangeEditing_) return "Volume range minimum and maximum dB";
        if (numericEditing_) return "Parameter value"; return page_ == Page::tracks ? "Filter tracks" :
        page_ == Page::sends ? "Filter sends" : "Filter receives"; }
    void setNativeText(const std::string& text) { if (numericEditing_) numericBuffer_ = text; else if (filterEditing_) filterBuffer_ = text; }
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
    enum class Page { tracks, sends, receives, fxTcp };
    // TEST56.1: F4 is a view of native REAPER TCP parameters, not a copy of
    // the full FX parameter list. Each FX has a header, including empty FXs.
    struct FxTcpParameter { int index = -1; std::string name; };
    struct FxTcpColumn { int fxIndex = -1; GUID guid{}; std::string name;
        std::vector<FxTcpParameter> parameters; };
    void rebuildFxTcp(bool preserveSelection);
    bool selectFxTcpPage();
    void handleFxTcpKey(const Key& key);
    void rememberFxTcpPosition();
    std::string fxTcpReview(bool includeContext) const;
    int fxTcpHeight() const;
    const FxTcpColumn* currentFxTcpColumn() const;
    const FxTcpParameter* currentFxTcpParameter() const;
    void moveFxTcpColumn(int delta);
    void moveFxTcpRow(int delta);
    static bool fxTcpInitialMatch(const std::string& label, wchar_t letter);
    static wchar_t fxTcpSearchCharacter(const Key& k);
    void jumpFxTcpByInitial(wchar_t letter, bool backwards);
    void jumpFxTcpGridByInitial(wchar_t letter, bool backwards);
    std::string fxTcpStepKey() const;
    bool writeFxTcpValue(double normalized);
    void nudgeFxTcpValue(int direction, bool coarse);
    std::string fxTcpValueSpeech() const;
    static bool fxTcpMatchesSearch(const std::string& label, const std::string& query);
    void toggleFxTcpFilter();
    void applyFxTcpFilter();
    void cancelFxTcpFilter();
    void clearFxTcpFilter();
    std::string fxTcpActiveFilter() const;
    bool fxTcpHasMatches(const std::string& query) const;
    // TEST56.2: names-only, FX Params-style grid for choosing TCP controls.
    struct FxTcpListEntry { int fxIndex = -1; int paramIndex = -1; GUID fxGuid{};
        std::string name; std::string parameterName; bool visible = false; };
    void openFxTcpParameterGrid(bool visibleOnly);
    void closeFxTcpParameterGrid(bool announceCurrent = true);
    void rebuildFxTcpParameterGrid(int preferFx = -1, int preferParam = -1);
    std::string fxTcpParameterGridReview(bool details) const;
    void handleFxTcpParameterGridKey(const Key&);
    bool setFxTcpParameterVisible(int fxIndex, int paramIndex, bool visible);
    void commitFxTcpParameterGrid(bool keepOpen);
    void rebuildFxTcpVisibleColumns(int preferFx = -1, int preferParam = -1);
    void moveFxTcpVisibleColumn(int delta);
    void moveFxTcpVisibleRow(int delta);
    void syncFxTcpVisibleSelection();
    bool fxTcpParameterVisible(int fxIndex, int paramIndex) const;
    bool fxTcpListOpen_ = false, fxTcpListVisibleOnly_ = false;
    int fxTcpListFxIndex_ = -1, fxTcpListPosition_ = 0, fxTcpListGridHeight_ = 10;
    GUID fxTcpListFxGuid_{};
    // In the Alt+Enter view one column belongs to each FX, as in F4.
    std::vector<std::vector<int>> fxTcpVisibleColumns_;
    int fxTcpListColumn_ = 0, fxTcpListRow_ = 0; // row zero is the FX header
    std::string fxTcpMainFilter_, fxTcpGridFilter_;
    std::vector<FxTcpListEntry> fxTcpListEntries_;
    std::vector<FxTcpColumn> fxTcpColumns_;
    int fxTcpColumn_ = 0, fxTcpRow_ = 0;
    static constexpr int detailHeight = 14;
    void buildEntries();
    // TEST55: F8-like project TP memory manager, with no separate F7 editor.
    struct MemoryItem { std::string key, label, value; int slot = 0; };
    void rebuildMemoryList();
    void speakMemory(const std::string& prefix = "") const;
    void handleMemory(const Key&);
    void memoryExit();
    void memoryActivate();
    void memoryDelete();
    void memoryAdjustStep(int delta);
    void saveTrackSlot(int slot);
    void recallTrackSlot(int slot);
    MediaTrack* findSavedTrack(const std::string& guid) const;
    std::string trackGuidText(MediaTrack* track) const;
    std::string savedTrackLabel(const std::string& guid) const;
    // Lua Ctrl+F: scoped logical filter, with no mutations to REAPER tracks.
    void toggleFilter();
    void applyFilter();
    void cancelFilter();
    void clearFilter();
    bool routeMatchesFilter(MediaTrack* owner, int category, int index) const;
    int matchingRoutingCount(MediaTrack* owner, int category) const;
    bool trackMatchesFilter(MediaTrack* track) const;
    bool rebuildForFilter(bool keepCurrentTrack);
    std::string filterSuffix() const;
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
    // Plain navigation follows the real TCP selected track. Explicit F1
    // multi-selection commands remain in charge of their own selection.
    void syncCursorToReaper();
    void moveToFolder(int direction);
    // Folder hierarchy mirrors the Lua stack: a track may close several
    // nested folders and each of their names must be spoken in order.
    void rebuildVisibleRows();
    std::vector<MediaTrack*> endingFolders(MediaTrack* track) const;
    std::string folderAwareTrackLabel() const;
    void toggleCurrentFolder();
    // F2/F3 Delete: remove the exact routing instance, including duplicate
    // receives coming from the same source track.
    void deleteCurrentRouting();
    void jumpToLinkedRouting(); // Enter on F2/F3 header; retain Value for editable fields
    void beginNumericEdit();
    void beginVolumeRangeEdit();
    void commitNumericEdit();
    // TEST54 CC map in the same main .tp as Lua, with pickup and no stale MIDI replay.
    void midiShortcut(const Key&);
    void pollMidi();
    bool midiTarget(std::string& section, std::string& key) const;
    // Resolve source/destination GUIDs and the exact repeated send ordinal.
    bool midiFixedIdentity(std::string& identity) const;
    std::string fixedRoutingSignature(const std::string& identity) const;
    void applyMidi(const std::string& section, const std::string& key, int value); // Floating, follows cursor
    void applyFixedMidi(const std::string& identity, int value); // Fixed, follows saved GUIDs
    void resetMidiState();
    // TEST52: native SWS clipboard keeps track-to-track routing intact.
    enum class TrackClipboardAction { cut, copy, paste };
    void trackClipboard(TrackClipboardAction action);
    // Lua folder-aware move: expand selected folder blocks temporarily, then
    // restore the original logical selection by GUID after REAPER reorders.
    void moveSelectedTracks(int direction);
    void refreshAfterTrackEdit(const GUID* preferredGuid, int fallbackRow);
    void clearPhysicalSelection();
    // F1/F2/F3 envelope controls: preserve existing point and item data.
    bool currentEnvelopeActive() const;
    void toggleCurrentAutomation();
    void clearTrackAutomations();
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

    void jumpByInitial(wchar_t letter); // Lua: F1 track names, F2/F3 fields in current column
    void moveTrack(int delta);
    void moveParameter(int delta);
    void moveDetailColumn(int delta);
    void switchDetailTrack(int direction); // Lua Ctrl+Up/Down F2/F3
    void nudge(int direction, bool coarse);
    void toggle(const Entry&);
    double get(const Entry&) const;
    void put(const Entry&, double);
    MediaTrack* routingEndpoint(const Entry&, bool source) const;
    std::string trackName() const;
    std::string detailPeerName(int category, int index) const;
    int detailPeerOccurrence(int category, int index) const;
    std::string currentParameterSpeech() const;
    // Only Left/Right sends/receives include peer context and per-peer ordinal.
    std::string detailColumnSpeech(int previousColumn) const;
    std::string parameterValueSpeech() const;
    // Like FX Params: parameter, value, CC channel/number, Auto.
    // The CC is read from the project .tp regardless of Fixed map on/off.
    std::string ccParameterSuffix() const;
    std::string statusSuffix() const;
    void announceTrack();
    std::string valueText(const Entry&, double) const;
    const Entry* current() const;
    bool memoryManager_ = false, memoryStandalone_ = false;
    int memoryColumn_ = 0, memoryRow_ = 0;
    std::vector<MemoryItem> memoryItems_;
    std::vector<TrackRow> rows_;
    std::vector<Entry> entries_;
    std::string filterQuery_; // scoped to this Track Params session (Lua runtime state)
    std::string filterBuffer_;
    std::string numericBuffer_;
    bool numericEditing_ = false;
    bool rangeEditing_ = false;
    bool learnCc_ = false, fixedCc_ = false, floatingCc_ = false, floatingWaiting_ = false;
    std::string learnSection_, learnKey_, learnIdentity_;
    int midiSequence_ = 0, floatingChannel_ = -1, floatingNumber_ = -1;
    std::string floatingTarget_;
    std::map<std::string, Pickup> midiPickup_;
    bool suppressPutSpeech_ = false;
    std::string pendingMidiSpeech_;
    ULONGLONG midiSpeechAt_ = 0;
    bool filterEditing_ = false;
    bool nativeFilterAvailable_ = false;
    ReaProject* project_{};
    MediaTrack* track_{};
    MediaTrack* nextStartTrack_{};
    MediaTrack* initialSelection_{};
    int trackCount_{};
    int row_{};
    int parameter_{};       // F1: 0..8 column; F2/F3: 0..13 vertical field
    int detailIndex_{};     // F2/F3 send/receive column
    int stepScale_{};       // TEST49: restored from the current parameter's .tp preference
    int sends_{}, receives_{};
    int lastEndFolderTrackIndex_ = -1;
    std::size_t nextEndFolderIndex_ = 0;
    Page page_ = Page::tracks;
    bool active_ = false, valueMode_ = false;
    bool backgroundMode_ = false, clearAutomationConfirm_ = false;
    bool clearAutomationYes_ = false;
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
