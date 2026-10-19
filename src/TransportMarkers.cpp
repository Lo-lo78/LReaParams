#include "lrp/TransportMarkers.h"
#include <algorithm>
#include <cmath>
#include <string>
#include <vector>

namespace lrp {
namespace {
constexpr double kEpsilon = 0.000001;
struct Marker { double pos{}; int number{}; std::string name; };

std::string timelinePosition(ReaProject* project, double pos) {
    if (!TimeMap2_timeToBeats) return "";
    int measure = 0, length = 0, denominator = 0;
    const double beat = TimeMap2_timeToBeats(project, pos, &measure, &length,
                                             nullptr, &denominator);
    if (!std::isfinite(beat) || measure < 0 || beat < 0) return "";
    const int integral = static_cast<int>(std::floor(beat));
    const int percent = std::clamp(static_cast<int>(std::floor((beat - integral) * 100.0 + .00001)),0,99);
    return "Bar " + std::to_string(measure + 1) + " beat " +
           std::to_string(integral + 1) + " " + std::to_string(percent) + "%";
}
std::vector<Marker> markerList(ReaProject* project) {
    std::vector<Marker> result;
    if (!CountProjectMarkers || !EnumProjectMarkers3) return result;
    int markers = 0, regions = 0;
    CountProjectMarkers(project, &markers, &regions);
    const int total = markers + regions;
    if (total <= 0) return result;
    result.reserve(static_cast<size_t>(markers));
    for (int i = 0; i < total; ++i) {
        bool region = false;
        double pos = 0, end = 0;
        int id = 0, color = 0;
        const char* name = nullptr;
        if (EnumProjectMarkers3(project, i, &region, &pos, &end, &name, &id, &color) &&
            !region && std::isfinite(pos))
            result.push_back({pos, id, name ? name : ""});
    }
    std::sort(result.begin(),result.end(),[](const Marker& a,const Marker& b){
        return a.pos == b.pos ? a.number < b.number : a.pos < b.pos;
    });
    return result;
}
void goToMarker(const Marker& target, ReaProject* project, int& edge,
                const std::function<void(const std::string&)>& speech) {
    if (!SetEditCurPos2) { speech("Cursor navigation unavailable"); return; }
    SetEditCurPos2(project, target.pos, true, true);
    edge = 0;
    std::string phrase = "Marker " + std::to_string(target.number);
    if (!target.name.empty()) phrase += " " + target.name;
    const auto time = timelinePosition(project, target.pos);
    if (!time.empty()) phrase += ". " + time;
    speech(phrase);
}
} // namespace

bool isTransportMarkerShortcut(const Key& k) noexcept {
    if (k.altGr) return false;
    if (k.ctrl && !k.alt && !k.shift)
        return (k.vk >= '0' && k.vk <= '9') || k.vk == 'I' || k.vk == 'O';
    if ((k.vk == VK_PRIOR || k.vk == VK_NEXT) && k.alt) {
        // Ctrl+Alt Page = beat; Alt+Shift Page = measure;
        // Ctrl+Alt+Shift Page = measure start. Plain Alt+Page unchanged.
        return (k.ctrl || k.shift);
    }
    return false;
}

void executeTransportMarkerShortcut(const Key& k, ReaProject* project, int& edge,
                                    const std::function<void(const std::string&)>& speech) {
    if (!isTransportMarkerShortcut(k)) return;
    // REAPER actions and set-cursor calls target the foreground project. A
    // navigator attached to a project changed in the meantime must never
    // move the cursor in another project.
    if (!project || !EnumProjects || EnumProjects(-1, nullptr, 0) != project) {
        speech("Project changed");
        return;
    }
    if (k.vk == VK_PRIOR || k.vk == VK_NEXT) {
        if (!Main_OnCommand) { speech("Cursor navigation unavailable"); return; }
        const bool down = k.vk == VK_NEXT;
        const int command = k.ctrl && k.shift ? (down ? 41040 : 41041) :
                            k.shift ? (down ? 41042 : 41043) : (down ? 41044 : 41045);
        Main_OnCommand(command, 0);
        edge = 0;
        const double pos = GetCursorPositionEx ? GetCursorPositionEx(project) :
                           (GetCursorPosition ? GetCursorPosition() : 0.0);
        const auto phrase = timelinePosition(project, pos);
        if (!phrase.empty()) speech(phrase);
        return;
    }
    const auto markers = markerList(project);
    if (markers.empty()) {
        if (edge != 3) { speech("No markers"); edge = 3; }
        return;
    }
    if (k.vk >= '0' && k.vk <= '9') {
        const int number = k.vk == '0' ? 10 : static_cast<int>(k.vk - '0');
        const auto selected = std::find_if(markers.begin(), markers.end(),
                             [number](const Marker& m){return m.number == number;});
        if (selected != markers.end()) goToMarker(*selected, project, edge, speech);
        else if (static_cast<size_t>(number) <= markers.size())
            goToMarker(markers[static_cast<size_t>(number - 1)], project, edge, speech);
        else { edge = 0; speech("Marker " + std::to_string(number) + " not found"); }
        return;
    }
    if (!GetCursorPositionEx && !GetCursorPosition) { speech("Cursor navigation unavailable"); return; }
    const double pos = GetCursorPositionEx ? GetCursorPositionEx(project) : GetCursorPosition();
    const bool forward = k.vk == 'O';
    const Marker* selected = nullptr;
    for (const auto& m : markers) {
        if (forward && m.pos > pos + kEpsilon) { selected = &m; break; }
        if (!forward && m.pos < pos - kEpsilon) selected = &m;
    }
    if (selected) goToMarker(*selected, project, edge, speech);
    else {
        const int newEdge = forward ? 2 : 1;
        if (edge != newEdge) speech(forward ? "Last marker" : "First marker");
        edge = newEdge;
    }
}
} // namespace lrp
