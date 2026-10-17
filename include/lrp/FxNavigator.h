#pragma once
#include "ReaperApi.h"
#include "Navigator.h"
#include "FxOrder.h"
#include "MidiControl.h"
#include <filesystem>
#include <array>
#include <set>
#include <string>
#include <climits>
#include <functional>
#include <vector>

namespace lrp {
class FxNavigator final : public Navigator {
public:
    explicit FxNavigator(std::function<void(const std::string&)> speech) : speech_(std::move(speech)) {}
    void setResourceRoot(std::filesystem::path root) { resourceRoot_ = std::move(root); }
    bool begin() override;
    // One-shot explicit target for shared Ctrl+Tab. No REAPER selection mutation.
    void setNextStartTrack(MediaTrack* track) noexcept { nextStartTrack_ = track; }
    void pollMidi();
    // A parked navigator is an independent MIDI-only snapshot. No keyboard
    // focus or native window is retained while REAPER's main timer polls it.
    void prepareBackgroundMidi();
    bool midiRunning() const noexcept { return learnCc_ || fixedCc_ || floatingCc_ || floatingWaiting_; }
    bool sameMidiFx(const FxNavigator& other) const noexcept;
    bool openFxMemories(bool standalone = false);
    enum class NativeFxWindow { none, chain, addFx };
    NativeFxWindow consumeNativeFxWindowRequest() noexcept {
        auto request = nativeFxWindowRequest_;
        nativeFxWindowRequest_ = NativeFxWindow::none;
        return request;
    }
    MediaTrack* currentTrackForNativeWindow() const noexcept { return track_; }
    MediaItem_Take* currentTakeForNativeWindow() const noexcept { return take_; }
    int currentFxForNativeWindow() const noexcept {
        const int cursor = fxBrowserMode_ ? browserVisibleIndex() : -1;
        return cursor >= 0 ? entries_[static_cast<size_t>(cursor)].index : fx_;
    }
    bool isMemoryManager() const noexcept { return memoryManager_; } // seven-column Lua F8 navigator
    void end() noexcept override;
    bool active() const noexcept override { return active_; }
    bool valid() const;
    bool contextUnchanged() const override;
    bool accepts(const Key& key) const noexcept override;
    void handle(const Key& key) override;
    void announce() override;
    void announceTitle() override;
    std::wstring windowTitle() const override;
    std::string reviewLine() const override;
    bool nativeValueSlider() const override { return active_ && valueMode_ && !memoryManager_ && !fxBrowserMode_; }
    // Native Windows EDIT control for F7 rename and Ctrl+F search.
    bool nativeTextField() const noexcept { return active_ && (textEdit_ || searchMode_ || numericEdit_) && !memoryManager_ && !fxBrowserMode_; }
    std::string nativeTextValue() const { return numericEdit_ ? numericBuffer_ : textEdit_ ? textBuffer_ : search_; }
    std::string nativeTextLabel() const { return numericEdit_ ? "Parameter value" : textEdit_ ? (textEditParam_ == -1 ? "Group name" : "Parameter name") : "Find parameter"; }
    void setNativeText(const std::string& text);
    double valueFraction() const override;
    std::string sliderLabel() const override;
    HWND floatingWindow() const override;
    bool uiStillOpen() const override;
private:
    void loadSearchHistory();
    void saveSearchHistory();
    void handleRecent(const Key&);
    bool recentMode_=false;
    bool handleAdvanced(const Key&);
    bool acceptsAdvanced(const Key&) const noexcept;
    void resetMidiContext();
    void applyMidi(int param, int value);
    void clearNativeLearn(int param);
    bool setRawValue(int param,double value);
    double rawValue(int param) const;
    void navigatePreset(int direction);
    void numericBegin();
    void numericCommit();
    TrackEnvelope* envelope(int param,bool create) const;
    bool envelopeActive(int param) const;
    bool setEnvelope(int param,bool active);
    void toggleEnvelope(bool all);
    void navigateEnvelope(int direction);
    bool learnCc_=false, fixedCc_=false, floatingCc_=false, floatingWaiting_=false;
    int learnParam_=-1, floatingChannel_=0, floatingNumber_=0, floatingParam_=-1;
    int midiSequence_=0;
    std::map<int,Pickup> pickup_;
    std::map<int,std::string> midiSpoken_;
    ULONGLONG midiSpeechTime_=0;
    std::string midiPendingSpeech_;
    bool numericEdit_=false;
    std::string numericBuffer_,numericUnit_;
    bool numericFormatted_=false;
    bool numericFormat(double norm,double& value,std::string& unit) const;
    std::vector<std::string> searchHistory_;
    int historyIndex_=-1;
    // Lua ReaComp / ReaGate accessible controls (0.0.44).
    bool isReaComp() const;
    bool isReaGate() const;
    bool dynamicsVirtualValid(int id) const;
    std::string dynamicsVirtualName(int id) const;
    std::string dynamicsVirtualFormatted(int id) const;
    bool dynamicsDetectorInput(int id) const;
    bool dynamicsToggle(int id) const;
    bool dynamicsRms(int id) const;
    std::string dynamicsRealFormatted(int id,const std::string& formatted) const;
    std::string dynamicsAlias(int id) const;
    std::vector<int> dynamicsPluginOrder() const;
    double dynamicsFraction(int id) const;
    bool dynamicsSetDetector(double normalized);
    bool dynamicsSetDetectorAt(int param,double normalized);
    void dynamicsNudgeDetector(int direction,bool big);
    bool isReaEq() const;
    int eqBandCount() const;
    bool eqVirtualValid(int id) const;
    std::string eqVirtualName(int id) const;
    std::string eqVirtualFormatted(int id) const;
    double eqVirtualFraction(int id) const;
    bool eqVirtualSet(int id,double normalized);
    void eqVirtualNudge(int direction,bool big);
    void eqBandAction();
    int eqTargetBand_ = 0;
    bool eqActionMidiHigh_ = false;
    std::string namedConfig(const std::string& key) const;
    bool writeNamedConfig(const std::string& key,const std::string& value);
    bool captureReaEqDefault();
    bool restoreReaEqDefault();
    double eqGainNorm(int param) const;
    bool writeEqGain(int param,double norm);
    bool eqBandParam(int param,int type) const;
    void refreshAfterStructure(int preferred);
    struct CompareSnapshot { std::string eqChunk; std::vector<double> values; std::vector<std::string> names; };
    struct CompareState { GUID guid{};ReaProject* project{};MediaItem_Take* take{};GUID track{};
        CompareSnapshot original,edited;bool armed=false,originalActive=false; };
    std::vector<CompareState> compareStates_;
    CompareState& compareState();
    const CompareState* findCompareState() const;
    CompareSnapshot captureCompare() const;
    bool applyCompare(const CompareSnapshot& snapshot);
    bool setCompare(double value);
    std::string compareFormatted() const;
    struct FxEntry { int index{}; GUID guid{}; std::string name; };
    bool selectFx(int index);
    void switchFx(int direction);
    void switchTrack(int direction);
    bool switchToContext(MediaTrack* destination, MediaItem_Take* destinationTake, const std::string& what);
    void switchItem(int direction);
    void returnToTrackFx();
    void openCurrentFxChain();
    void openNativeFxBrowser();
    void enterFxBrowser();
    void browserKey(const Key& key);
    void browserMove(int amount);
    void browserSwitchColumn(int direction);
    void browserSelect();
    void browserMoveFx(int direction);
    std::string browserSpeech() const;
    int browserVisibleIndex() const;
    bool browserEntryInScope(int entryIndex) const;
    void browserCycleByInitial(wchar_t character, bool backwards);

    bool rebuildEntries();
    // Session-only memory (no files, no REAPER ExtState and no RPP changes).
    // A context is identified by project, track GUID and optional take.
    struct StoredFxPosition {
        GUID fxGuid{};
        int parameter = 0;
        std::string parameterName;
        int gridHeight = 10;
        int stepScale = 0;
        int viewPosition = 0;
        bool customView = false;
        std::set<int> f7Selected;
    };
    struct StoredContext {
        ReaProject* project{};
        GUID trackGuid{};
        MediaItem_Take* take{};
        GUID lastFxGuid{};
        std::string lastFxName;
        bool lastFxMonitor = false;
        int lastFxOccurrence = 1;
        int observedVisibleFx = -1;
        bool hasLastFx = false;
        std::vector<StoredFxPosition> positions;
    };
    StoredContext* contextMemory() noexcept;
    const StoredContext* contextMemory() const noexcept;
    StoredContext& ensureContextMemory();
    int visibleFxIndex() const;
    int rememberedFxIndex(const StoredContext& state) const;
    void restoreParameterPosition();
    void restorePersistedParameter();
    void flushPersistentPosition() noexcept;
    void rememberPosition();
    std::string contextName() const;
    std::string fxDisplayName() const;
    // Spoken context and window-title state share the same source of truth.
    bool deltaSoloActive() const;
    std::string statusSummary() const;
    std::string fxContextAnnouncement() const;
    std::string fxWindowTitleBase(bool memories = false) const;
    bool isBypassed() const;
    void toggleBypass();
    bool deltaParameter(MediaTrack* track, MediaItem_Take* take, int fx, int& index) const;
    void toggleDeltaSolo();
    void toggleOffline();
    void clearProjectDeltaSolo();
    void runLuaFunctionAction(int command);
    void chooseSlotAccess(int mode);
    std::string groupLabel(int slot) const;
    void resetCurrentToDefault();
    bool resetAllToDefault(bool announceResult = true);
    void resetGridAndStep();
    // Lua param_step_scales_v1, with a native -10..+10 override in the same
    // plugin profile. Changing parameter loads that parameter's Step only.
    using StepSetting = std::pair<std::string,int>;
    std::map<int,StepSetting> parameterSteps_;
    int stepActiveParameter_ = INT_MIN;
    bool parameterStepsDirty_ = false;
    void loadParameterSteps();
    void syncParameterStep();
    void markParameterStepChanged();
    void stageParameterSteps();
    bool flushParameterSteps() noexcept;
    int savedStepForParameter(int param) const;
    std::string stepParameterName(int param) const;
    void queueCcSpeech(int param,const std::string& formatted);

    void copyParameterValue();
    void copyFxSnapshot();
    void pasteFxClipboard();
    void snapshotDefaultsIfMissing();
    int count() const;
    std::string parameterName() const;
    std::string currentParameterCcSpeech() const;
    std::string currentParameterSpeech() const;
    std::string editorParameterSpeech() const;
    std::string viewPositionSpeech() const;
    std::string formattedValue() const;
    void nudge(int direction, bool big);
    void setValue(double value);
    void navigate(int delta);
    void cycleByInitial(wchar_t character);
    void cycleByInitial(wchar_t character, bool backwards);
    void findMatching(bool forward);
    // Quoted queries match adjacent words: whole preceding words and a
    // possible final prefix. A quoted single word requires a whole word.
    static bool matchesSearch(const std::string& label, const std::string& query);
    void searchPreview();
    void loadFxOrder();
    enum class MemoryKind { position, group, hidden, cc, custom, copies, defaults };
    struct MemoryEntry { int param = -1; int slot = 0; int rawPos = -1; int occurrence = 0; std::string label; };
    void rebuildMemoryColumns();
    bool memoryHasEntries() const;
    std::string memoryColumnName() const;
    std::string memoryReview() const;
    void speakMemory(const std::string& prefix = "");
    void memoryExit(bool announceReturn = true);
    void memoryNavigate(const Key&);
    void memoryLoad(bool toEdit);
    void memoryDelete();
    bool memorySelectColumn(int direction);

    void rebuildView(int preferParam, int preferPosition = -1);
    void positionChanged(int position, bool announcePosition = true);
    void enterF7();
    void exitF7();
    void selectF7(bool shift, int target, const std::string& direction = "", bool sweep = false);
    void selectF7ToGlobalEdge(bool toEnd);
    bool handleF7(const Key& key);
    void saveStructure();
    struct EditHistory { std::vector<int> order; std::map<int,std::string> aliases;
        std::set<int> hidden; std::map<int,std::vector<int>> groups;
        std::map<int,std::string> groupNames; };
    EditHistory captureHistory() const;
    void restoreHistory(const EditHistory& state);
    void saveUndo();
    void f7Undo(bool redo);
    std::vector<EditHistory> undoStack_, redoStack_;
    void doCopy(bool cut);
    void doPaste();
    void hideSelected();
    void openGroup(int slot);
    void saveGroup(int slot);
    void handleTextEdit(const Key& key);
    std::string displayName() const;
    ReaProject* project_{};
    MediaTrack* track_{};
    MediaTrack* nextStartTrack_{};
    MediaItem_Take* take_{};
    GUID trackGuid_{}, fxGuid_{};
    std::vector<FxEntry> entries_;
    std::vector<StoredContext> sessionMemory_;
    int browserIndex_ = 0;
    NativeFxWindow nativeFxWindowRequest_ = NativeFxWindow::none;
    bool fxBrowserMode_ = false;
    // Master and Monitor are separate browser columns. Left/Right may switch
    // columns; vertical movement and FX operations never cross their borders.
    bool browserScopeMonitor_ = false;
    int browserCursor_ = 0; // cursor in entries_, independent of the current grid FX
    int browserMasterCursor_ = -1, browserMonitorCursor_ = -1; // per-column cursor

    int fx_{}, parameter_{}, count_{}, columns_ = 10;
    int stepScale_ = 0;
    bool active_ = false, valueMode_ = false, hadUi_ = false, searchMode_ = false;
    bool persistentPositionWriter_ = true; // disabled for background-MIDI snapshots

    std::string search_;
    FxOrder fxOrder_;
    std::filesystem::path resourceRoot_;
    std::vector<int> visible_;
    int viewPos_ = 0;
    // The view from which the first group was loaded (also across group switches).
    bool groupReturnActive_ = false, groupReturnCustom_ = false, groupReturnEdit_ = false;
    int groupReturnParam_ = 0, groupReturnPosition_ = 0;
    std::string groupReturnFilter_;
    std::set<int> groupReturnSelection_;
    int groupSlot_ = 0, slotMode_ = 0; // 0 = Groups; 1 = memory positions (pending)
    bool editF7_ = false, textEdit_ = false, groupEditAll_ = false;
    enum class LastControl { none, step, grid } lastControl_ = LastControl::none;
    // F7 filtered view: selection is kept in unfiltered occurrence coordinates.
    bool f7FilterActive_ = false;
    std::vector<int> f7FullView_;
    std::vector<int> f7FilterPositions_;
    std::string f7FilterQuery_;
    int f7OriginalPosition(int filteredPos) const;
    void clearF7Filter();
    void applyF7Filter(const std::string& query, bool speak = true);
    int f7FullPosition_ = 0;
    bool defaultConfirm_=false, defaultYes_=false, defaultRegenerate_=false;
    bool memoryManager_ = false, memoryStandalone_ = false;
    bool memoryReturnF7_ = false;
    std::string memoryReturnF7Filter_;
    int memoryReturnParam_ = 0, memoryReturnPosition_ = 0, memoryReturnGroup_ = 0;
    int memoryCol_ = 0, memoryRow_ = 0;
    std::array<std::vector<MemoryEntry>,7> memoryColumns_{};

    int f7ReturnPos_ = 0, f7ReturnGroup_ = 0, f7ReturnParam_ = 0;
    std::set<int> f7Selected_, f7BaseSelection_;
    std::vector<int> f7SnakePath_;
    std::vector<std::string> f7SnakeDirections_;
    bool f7SnakeUnselect_ = false; // Lua paint/unpaint mode, captured at snake start
    std::vector<int> clip_; // cut/paste retains duplicate occurrences
    std::string clipPlugin_;
    GUID clipFxGuid_{};
    int clipSourceGroup_ = 0;
    std::set<int> clipPositions_;
    bool clipCut_ = false;
    int textEditParam_ = -1; // Ctrl+Enter alias when >= 0, group rename if < 0
    std::string textBuffer_;
    std::wstring textWide_;
    std::size_t textCursor_ = 0;
    bool textFresh_ = true;
    std::string parameterName_;
    std::function<void(const std::string&)> speech_;
};
}
