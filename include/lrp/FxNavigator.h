#pragma once
#include "ReaperApi.h"
#include "Navigator.h"
#include <string>
#include <functional>
#include <vector>

namespace lrp {
class FxNavigator final : public Navigator {
public:
    explicit FxNavigator(std::function<void(const std::string&)> speech) : speech_(std::move(speech)) {}
    bool begin() override;
    void end() noexcept override { active_ = false; valueMode_ = false; searchMode_ = false; search_.clear(); entries_.clear(); count_ = 0; }
    bool active() const noexcept override { return active_; }
    bool valid() const;
    bool contextUnchanged() const override;
    bool accepts(const Key& key) const noexcept override;
    void handle(const Key& key) override;
    void announce() override;
    void announceTitle() override;
    std::wstring windowTitle() const override;
    std::string reviewLine() const override;
    HWND floatingWindow() const override;
    bool uiStillOpen() const override;
private:
    struct FxEntry { int index{}; GUID guid{}; std::string name; };
    bool selectFx(int index);
    void switchFx(int direction);
    // Session-only memory (no files, no REAPER ExtState and no RPP changes).
    // A context is identified by project, track GUID and optional take.
    struct StoredFxPosition {
        GUID fxGuid{};
        int parameter = 0;
        std::string parameterName;
        int gridHeight = 10;
        int stepScale = 0;
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
    int count() const;
    std::string parameterName() const;
    std::string currentParameterSpeech() const;
    void nudge(int direction, bool big);
    void setValue(double value);
    void navigate(int delta);
    void findMatching(bool forward);
    void searchPreview();
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
    std::string parameterName_;
    std::function<void(const std::string&)> speech_;
};
}
