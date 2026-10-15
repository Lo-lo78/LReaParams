#pragma once
#include "ReaperApi.h"
#include "Navigator.h"
#include "FxOrder.h"
#include <filesystem>
#include <array>
#include <set>
#include <string>
#include <functional>
#include <vector>

namespace lrp {
class FxNavigator final : public Navigator {
public:
    explicit FxNavigator(std::function<void(const std::string&)> speech) : speech_(std::move(speech)) {}
    void setResourceRoot(std::filesystem::path root) { resourceRoot_ = std::move(root); }
    bool begin() override;
    bool openFxMemories(bool standalone = false);
    bool isMemoryManager() const noexcept { return memoryManager_; } // seven-column Lua F8 navigator
    void end() noexcept override { active_ = false; valueMode_ = false; searchMode_ = false; editF7_ = false; textEdit_ = false; memoryManager_ = false; memoryStandalone_ = false; groupSlot_ = 0; search_.clear(); entries_.clear(); count_ = 0; }
    bool active() const noexcept override { return active_; }
    bool valid() const;
    bool contextUnchanged() const override;
    bool accepts(const Key& key) const noexcept override;
    void handle(const Key& key) override;
    void announce() override;
    void announceTitle() override;
    std::wstring windowTitle() const override;
    std::string reviewLine() const override;
    bool nativeValueSlider() const override { return active_ && valueMode_ && !memoryManager_; }
    double valueFraction() const override;
    std::string sliderLabel() const override;
    HWND floatingWindow() const override;
    bool uiStillOpen() const override;
private:
    struct FxEntry { int index{}; GUID guid{}; std::string name; };
    bool selectFx(int index);
    void switchFx(int direction);
    void switchTrack(int direction);
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
    void rememberPosition();
    std::string contextName() const;
    std::string fxDisplayName() const;
    std::string statusSuffix() const;
    bool isBypassed() const;
    void toggleBypass();
    bool deltaParameter(MediaTrack* track, MediaItem_Take* take, int fx, int& index) const;
    void toggleDeltaSolo();
    void clearProjectDeltaSolo();
    void runLuaFunctionAction(int command);
    void toggleSlotAccess();
    int count() const;
    std::string parameterName() const;
    std::string currentParameterSpeech() const;
    std::string formattedValue() const;
    void nudge(int direction, bool big);
    void setValue(double value);
    void navigate(int delta);
    void findMatching(bool forward);
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
    void selectF7(bool shift, int target, const std::string& direction = "");
    bool handleF7(const Key& key);
    void saveStructure();
    void doCopy(bool cut);
    void doPaste();
    void hideSelected();
    void openGroup(int slot);
    void saveGroup(int slot);
    void handleTextEdit(const Key& key);
    std::string displayName() const;
    ReaProject* project_{};
    MediaTrack* track_{};
    MediaItem_Take* take_{};
    GUID trackGuid_{}, fxGuid_{};
    std::vector<FxEntry> entries_;
    std::vector<StoredContext> sessionMemory_;
    int browserIndex_ = 0;
    int fx_{}, parameter_{}, count_{}, columns_ = 10;
    int stepScale_ = 0;
    bool active_ = false, valueMode_ = false, hadUi_ = false, searchMode_ = false;
    std::string search_;
    FxOrder fxOrder_;
    std::filesystem::path resourceRoot_;
    std::vector<int> visible_;
    int viewPos_ = 0;
    int groupSlot_ = 0, slotMode_ = 0; // 0 = Groups; 1 = memory positions (pending)
    bool editF7_ = false, textEdit_ = false, groupEditAll_ = false;
    bool memoryManager_ = false, memoryStandalone_ = false;
    bool memoryReturnF7_ = false;
    int memoryReturnParam_ = 0, memoryReturnPosition_ = 0, memoryReturnGroup_ = 0;
    int memoryCol_ = 0, memoryRow_ = 0;
    std::array<std::vector<MemoryEntry>,7> memoryColumns_{};

    int f7ReturnPos_ = 0, f7ReturnGroup_ = 0, f7ReturnParam_ = 0;
    std::set<int> f7Selected_, f7BaseSelection_;
    std::vector<int> f7SnakePath_;
    std::vector<std::string> f7SnakeDirections_;
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
