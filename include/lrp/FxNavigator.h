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
    void end() noexcept override { active_ = false; browserMode_ = false; valueMode_ = false; searchMode_ = false; search_.clear(); entries_.clear(); }
    bool active() const noexcept override { return active_; }
    bool valid() const;
    bool contextUnchanged() const override;
    bool accepts(const Key& key) const noexcept override;
    void handle(const Key& key) override;
    void announce() override;
    void announceTitle() override;
    std::wstring windowTitle() const override;
    HWND floatingWindow() const override;
    bool uiStillOpen() const override;
private:
    struct FxEntry { int index{}; GUID guid{}; std::string name; };
    void browserAnnounce();
    bool selectFx(int index);
    void browserMove(int delta);
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
    int browserIndex_ = 0;
    int fx_{}, parameter_{}, count_{}, columns_ = 10;
    int stepScale_ = 0;
    bool active_ = false, browserMode_ = false, valueMode_ = false, hadUi_ = false, searchMode_ = false;
    std::string search_;
    std::string parameterName_;
    std::function<void(const std::string&)> speech_;
};
}
