#pragma once
#include "lrp/TempoDetector.h"
#include "lrp/TempoMapEngine.h"
#include "lrp/ReaperApi.h"
#include <functional>
#include <utility>
#include <string>
#include <cstddef>
#include <vector>

namespace lrp {
class TempoAction {
public:
    using Speak = std::function<void(const std::string&)>;
    explicit TempoAction(Speak callback): speak_(std::move(callback)) {}
    ~TempoAction();
    void start();
    void startMap();
    void tick();
    void stop();
    bool active() const { return accessor_ != nullptr; }
private:
    struct Segment { double start=0, duration=0; };
    Speak speak_;
    ReaProject* project_ = nullptr;
    MediaItem* item_ = nullptr;
    MediaItem_Take* take_ = nullptr;
    AudioAccessor* accessor_ = nullptr;
    std::vector<Segment> segments_;
    std::vector<tempo::Result> estimates_;
    std::vector<float> mono_;
    std::size_t segment_ = 0;
    std::size_t frame_ = 0;
    bool mapMode_ = false;
    tempo_map::Stream mapStream_;
    bool timebaseTemporary_ = false;
    double previousTimebase_ = 0.0;
    double previousAutoStretch_ = 0.0;
    void restoreTimebase();
    void nextSegment();
    void startInternal(bool tempoMap);
    void finishMap();
    void finish();
};
}
