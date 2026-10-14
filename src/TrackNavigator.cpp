#include "lrp/TrackNavigator.h"
#include <algorithm>
#include <cmath>
#include <cstring>
#include <iomanip>
#include <sstream>
#include <stdexcept>

namespace lrp {
namespace {
constexpr double minDb = -150.0, maxDb = 48.0;
double db(double amplitude) { return amplitude <= 0 ? minDb : 20.0 * std::log10(amplitude); }
double amp(double decibels) { return decibels <= minDb ? 0.0 : std::pow(10.0, decibels / 20.0); }
std::string num(double v, int places = 1) {
    std::ostringstream o; o << std::fixed << std::setprecision(places) << v; return o.str();
}
}

bool TrackNavigator::begin() {
    end();
    project_ = EnumProjects(-1, nullptr, 0);
    if (!project_) { speech_("Track Params: no project"); return false; }
    trackCount_ = CountTracks(project_);
    initialSelection_ = GetSelectedTrack2(project_, 0, true);
    int nesting = 0;
    int hiddenLevel = -1;
    for (int i = 0; i < trackCount_; ++i) {
        auto* track = GetTrack(project_, i);
        if (!track) continue;
        const int depth = static_cast<int>(GetMediaTrackInfo_Value(track, "I_FOLDERDEPTH"));
        const bool underCollapsedFolder = hiddenLevel >= 0 && nesting > hiddenLevel;
        const bool visible = GetMediaTrackInfo_Value(track, "B_SHOWINTCP") > 0.5;
        if (visible && !underCollapsedFolder) {
            if (const GUID* guid = GetTrackGUID(track)) rows_.push_back({track, *guid, i});
        }
        if (!underCollapsedFolder && GetMediaTrackInfo_Value(track, "I_FOLDERCOMPACT") >= 2.0 && depth > 0)
            hiddenLevel = nesting;
        nesting = std::max(0, nesting + depth);
        if (hiddenLevel >= 0 && nesting <= hiddenLevel) hiddenLevel = -1;
    }
    if (rows_.empty()) { speech_("Track Params: no visible tracks"); return false; }
    row_ = 0;
    for (int i = 0; i < static_cast<int>(rows_.size()); ++i) {
        if (rows_[i].track == initialSelection_) { row_ = i; break; }
    }
    track_ = rows_[row_].track;
    parameter_ = detailIndex_ = 0;
    page_ = Page::tracks;
    valueMode_ = false;
    buildEntries();
    active_ = true;
    return true;
}

bool TrackNavigator::contextUnchanged() const {
    if (!active_ || EnumProjects(-1, nullptr, 0) != project_ || CountTracks(project_) != trackCount_ ||
        row_ < 0 || row_ >= static_cast<int>(rows_.size())) return false;
    // An externally changed selection ends the session; moving between our
    // logical rows never changes REAPER's actual selected track.
    if (GetSelectedTrack2(project_, 0, true) != initialSelection_) return false;
    const auto& row = rows_[row_];
    if (GetTrack(project_, row.projectIndex) != row.track ||
        !ValidatePtr2(project_, row.track, "MediaTrack*")) return false;
    const auto* guid = GetTrackGUID(row.track);
    if (!guid || std::memcmp(guid, &row.guid, sizeof(GUID)) != 0 || track_ != row.track) return false;
    if (page_ != Page::tracks &&
        (GetTrackNumSends(track_, 0) != sends_ || GetTrackNumSends(track_, -1) != receives_)) return false;
    return true;
}

bool TrackNavigator::accepts(const Key& k) const noexcept {
    if (!active_ || k.shift) return false;
    if (k.ctrl) return !k.alt && (k.vk == VK_HOME || k.vk == VK_END);
    if (k.alt) return k.vk == VK_UP || k.vk == VK_DOWN || k.vk == VK_PRIOR || k.vk == VK_NEXT;
    switch (k.vk) {
        case VK_ESCAPE: case VK_RETURN: case VK_TAB:
        case VK_LEFT: case VK_RIGHT: case VK_UP: case VK_DOWN:
        case VK_HOME: case VK_END: case VK_PRIOR: case VK_NEXT:
        case VK_F1: case VK_F2: case VK_F3: return true;
        default: return false;
    }
}

void TrackNavigator::buildEntries() {
    entries_.clear();
    if (page_ == Page::tracks) {
        // Exact nine-field horizontal F1 row from the original Track Params Lua.
        entries_ = {
            {"Volume", "D_VOL", 99, -1, Entry::volume},
            {"Pan", "D_PAN", 99, -1, Entry::pan},
            {"Width", "D_WIDTH", 99, -1, Entry::width},
            {"Mute", "B_MUTE", 99, -1, Entry::flag},
            {"Solo", "I_SOLO", 99, -1, Entry::solo},
            {"Phase invert", "B_PHASE", 99, -1, Entry::flag},
            {"Send count", "", 99, -1, Entry::sendCount},
            {"Receive count", "", 99, -1, Entry::receiveCount},
            {"FX count", "", 99, -1, Entry::fxCount}
        };
        return;
    }
    sends_ = std::clamp(GetTrackNumSends(track_, 0), 0, 512);
    receives_ = std::clamp(GetTrackNumSends(track_, -1), 0, 512);
    const int category = page_ == Page::sends ? 0 : -1;
    const int count = category == 0 ? sends_ : receives_;
    for (int i = 0; i < count; ++i) {
        entries_.push_back({"Volume", "D_VOL", category, i, Entry::volume});
        entries_.push_back({"Pan", "D_PAN", category, i, Entry::pan});
        entries_.push_back({"Mute", "B_MUTE", category, i, Entry::flag});
    }
}

bool TrackNavigator::selectPage(Page page) {
    if (page == page_) { announceTitle(); return true; }
    page_ = page; parameter_ = detailIndex_ = 0; valueMode_ = false;
    buildEntries();
    if (entries_.empty()) {
        speech_(std::string("LReaParams - Track Params - ") +
                (page_ == Page::sends ? "Sends. No sends on this track" : "Receives. No receives on this track"));
        return true;
    }
    speech_("LReaParams - Track Params - " +
            std::string(page_ == Page::tracks ? "Tracks" : page_ == Page::sends ? "Sends" : "Receives") +
            ". " + currentParameterSpeech());
    return true;
}

std::string TrackNavigator::trackName() const {
    char name[2048]{};
    if (track_ && GetTrackName(track_, name, sizeof(name)) && name[0]) return name;
    return "Track " + std::to_string(rows_[row_].projectIndex + 1);
}

double TrackNavigator::get(const Entry& e) const {
    if (e.type == Entry::sendCount) return GetTrackNumSends(track_, 0);
    if (e.type == Entry::receiveCount) return GetTrackNumSends(track_, -1);
    if (e.type == Entry::fxCount) return TrackFX_GetCount(track_);
    return e.index < 0 ? GetMediaTrackInfo_Value(track_, e.parm.c_str()) :
        GetTrackSendInfo_Value(track_, e.category, e.index, e.parm.c_str());
}

void TrackNavigator::put(const Entry& e, double value) {
    if (e.type == Entry::sendCount || e.type == Entry::receiveCount || e.type == Entry::fxCount) {
        speech_("Read only"); return;
    }
    if (!contextUnchanged() || !std::isfinite(value)) throw std::runtime_error("Track context changed");
    const double before = get(e); if (before == value) { announce(); return; }
    struct UndoScope {
        ReaProject* project;
        explicit UndoScope(ReaProject* p) : project(p) { Undo_BeginBlock2(p); }
        ~UndoScope() { Undo_EndBlock2(project, "LReaParams: track control", UNDO_STATE_TRACKCFG); }
    } undo(project_);
    const bool ok = e.index < 0 ? SetMediaTrackInfo_Value(track_, e.parm.c_str(), value) :
        SetTrackSendInfo_Value(track_, e.category, e.index, e.parm.c_str(), value);
    if (!ok) throw std::runtime_error("REAPER refused track change");
    announce();
}

std::string TrackNavigator::valueText(const Entry& e, double value) {
    if (e.type == Entry::sendCount || e.type == Entry::receiveCount || e.type == Entry::fxCount)
        return std::to_string(static_cast<int>(value));
    if (e.type == Entry::flag) return value > 0.5 ? "on" : "off";
    if (e.type == Entry::solo) return value >= 0.5 ? "solo " + std::to_string(static_cast<int>(value)) : "off";
    if (e.type == Entry::volume) return value <= 0 ? "minus infinity dB" : num(db(value)) + " dB";
    if (e.type == Entry::pan) return std::abs(value) < 0.00001 ? "center" :
        num(std::abs(value) * 100.0, 0) + (value < 0 ? " percent left" : " percent right");
    return num(value * 100.0, 0) + " percent";
}

std::string TrackNavigator::currentParameterSpeech() const {
    if (!contextUnchanged()) throw std::runtime_error("Track context changed");
    if (entries_.empty()) return "No entries";
    const auto& e = entries_.at(static_cast<std::size_t>(parameter_));
    std::string label = trackName() + ", ";
    if (page_ == Page::sends || page_ == Page::receives)
        label += (page_ == Page::sends ? "Send " : "Receive ") + std::to_string(e.index + 1) + ", ";
    return label + e.title + ", " + valueText(e, get(e));
}
void TrackNavigator::announce() {
    speech_(currentParameterSpeech());
}
void TrackNavigator::announceTitle() {
    if (!active_) return;
    const char* pageName = page_ == Page::tracks ? "Tracks" : page_ == Page::sends ? "Sends" : "Receives";
    speech_("LReaParams - Track Params - " + std::string(pageName) +
            (valueMode_ ? " - Value. " : " - Grid. ") + currentParameterSpeech());
}

std::wstring TrackNavigator::windowTitle() const {
    if (!active_) return L"LReaParams - Track Params";
    const wchar_t* page = page_ == Page::tracks ? L"Tracks" : page_ == Page::sends ? L"Sends" : L"Receives";
    return std::wstring(L"LReaParams - Track Params - ") + page + (valueMode_ ? L" - Value" : L" - Grid");
}
void TrackNavigator::moveTrack(int delta) {
    if (page_ != Page::tracks) return;
    const int next = std::clamp(row_ + delta, 0, static_cast<int>(rows_.size()) - 1);
    if (next != row_) {
        row_ = next;
        track_ = rows_[row_].track;
        // Retain the same horizontal parameter when changing rows.
        announce();
    }
}
void TrackNavigator::moveParameter(int delta) {
    if (entries_.empty()) return;
    const int col = page_ == Page::tracks ? parameter_ : parameter_ % 3;
    const int limit = page_ == Page::tracks ? static_cast<int>(entries_.size()) - 1 : 2;
    const int next = std::clamp(col + delta, 0, limit);
    if (next != col) {
        parameter_ = page_ == Page::tracks ? next : detailIndex_ * 3 + next;
        announce();
    }
}
void TrackNavigator::moveDetailRow(int delta) {
    if (page_ == Page::tracks || entries_.empty()) return;
    const int rowCount = static_cast<int>(entries_.size()) / 3;
    const int next = std::clamp(detailIndex_ + delta, 0, rowCount - 1);
    if (next != detailIndex_) { detailIndex_ = next; parameter_ = detailIndex_ * 3 + (parameter_ % 3); announce(); }
}
void TrackNavigator::nudge(int direction, bool coarse) {
    if (entries_.empty()) return;
    const auto& e = entries_.at(static_cast<std::size_t>(parameter_));
    const double old = get(e);
    double next = old;
    switch (e.type) {
        case Entry::volume: next = amp(std::clamp(db(old) + (coarse ? 3.0 : 0.5) * direction, minDb, maxDb)); break;
        case Entry::pan: case Entry::width: next = std::clamp(old + direction * (coarse ? 0.1 : 0.01), -1.0, 1.0); break;
        case Entry::flag: case Entry::solo: next = direction > 0 ? 1.0 : 0.0; break;
        default: speech_("Read only"); return;
    }
    put(e, next);
}

void TrackNavigator::handle(const Key& k) {
    if (!contextUnchanged()) throw std::runtime_error("Track context changed");
    if (k.vk == VK_ESCAPE) {
        if (valueMode_) { valueMode_ = false; speech_("LReaParams - Track Params - Grid"); }
        else if (page_ != Page::tracks) selectPage(Page::tracks);
        else end();
        return;
    }
    if (k.vk == VK_F1) { selectPage(Page::tracks); return; }
    if (k.vk == VK_F2) { selectPage(Page::sends); return; }
    if (k.vk == VK_F3) { selectPage(Page::receives); return; }
    if (k.vk == VK_RETURN) {
        if (k.repeat) return;
        if (!valueMode_ && page_ == Page::tracks && parameter_ == 6) { selectPage(Page::sends); return; }
        if (!valueMode_ && page_ == Page::tracks && parameter_ == 7) { selectPage(Page::receives); return; }
        if (!valueMode_ && page_ == Page::tracks && parameter_ == 8) {
            speech_("Track FX page not yet migrated. Use FX Params."); return;
        }
        valueMode_ = !valueMode_; speech_(valueMode_ ? "LReaParams - Track Params - Value" : "LReaParams - Track Params - Grid"); return;
    }
    if (k.vk == VK_TAB) { announce(); return; }
    if (k.ctrl && k.vk == VK_HOME) { if (page_ == Page::tracks) moveTrack(-row_); else moveDetailRow(-detailIndex_); return; }
    if (k.ctrl && k.vk == VK_END) {
        if (page_ == Page::tracks) moveTrack(static_cast<int>(rows_.size()) - 1 - row_);
        else moveDetailRow(static_cast<int>(entries_.size()) / 3 - 1 - detailIndex_);
        return;
    }
    if (k.alt || valueMode_) {
        if (k.vk == VK_UP || k.vk == VK_DOWN || k.vk == VK_PRIOR || k.vk == VK_NEXT)
            nudge(k.vk == VK_UP || k.vk == VK_PRIOR ? 1 : -1, k.vk == VK_PRIOR || k.vk == VK_NEXT);
        else if (valueMode_ && (k.vk == VK_HOME || k.vk == VK_END) && !entries_.empty()) {
            const auto& e = entries_.at(static_cast<std::size_t>(parameter_));
            put(e, k.vk == VK_HOME ? (e.type == Entry::pan || e.type == Entry::width ? -1.0 : 0.0) : 1.0);
        }
        return;
    }
    if (k.vk == VK_HOME) { moveParameter(-(page_ == Page::tracks ? parameter_ : parameter_ % 3)); return; }
    if (k.vk == VK_END) { moveParameter((page_ == Page::tracks ? 8 : 2) - (page_ == Page::tracks ? parameter_ : parameter_ % 3)); return; }
    if (k.vk == VK_LEFT) { moveParameter(-1); return; }
    if (k.vk == VK_RIGHT) { moveParameter(1); return; }
    if (k.vk == VK_UP) { if (page_ == Page::tracks) moveTrack(-1); else moveDetailRow(-1); return; }
    if (k.vk == VK_DOWN) { if (page_ == Page::tracks) moveTrack(1); else moveDetailRow(1); return; }
    if (k.vk == VK_PRIOR) { if (page_ == Page::tracks) moveTrack(-5); else moveDetailRow(-5); return; }
    if (k.vk == VK_NEXT) { if (page_ == Page::tracks) moveTrack(5); else moveDetailRow(5); return; }
}
}
