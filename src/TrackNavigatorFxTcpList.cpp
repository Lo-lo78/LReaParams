#include "lrp/TrackNavigator.h"
#include <algorithm>
#include <cctype>
#include <cwctype>
#include <cstdio>
#include <cstring>
#include <sstream>
#include <string_view>

namespace lrp {
namespace {
std::string fxGuidText(const GUID& g) {
    char text[64]{};
    std::snprintf(text, sizeof(text), "{%08lX-%04hX-%04hX-%02hhX%02hhX-%02hhX%02hhX%02hhX%02hhX%02hhX%02hhX}",
        static_cast<unsigned long>(g.Data1), static_cast<unsigned short>(g.Data2),
        static_cast<unsigned short>(g.Data3), g.Data4[0], g.Data4[1], g.Data4[2], g.Data4[3],
        g.Data4[4], g.Data4[5], g.Data4[6], g.Data4[7]);
    return text;
}
std::string upper(std::string value) {
    for (char& c : value) c = static_cast<char>(std::toupper(static_cast<unsigned char>(c)));
    return value;
}
std::string_view trimmed(std::string_view value) {
    while (!value.empty() && (value.front() == ' ' || value.front() == '\t')) value.remove_prefix(1);
    while (!value.empty() && (value.back() == '\r' || value.back() == ' ' || value.back() == '\t')) value.remove_suffix(1);
    return value;
}
bool begins(std::string_view value, std::string_view prefix) {
    return value.size() >= prefix.size() && value.substr(0, prefix.size()) == prefix;
}
bool fxHeader(std::string_view value) {
    value = trimmed(value);
    return begins(value, "<VST") || begins(value, "<JS") || begins(value, "<CLAP") ||
        begins(value, "<AU") || begins(value, "<DX") || begins(value, "<VIDEO_EFFECT");
}
bool tcpLine(std::string_view value) {
    value = trimmed(value);
    return begins(value, "PARM_TCP ") || value == "PARM_TCP";
}
// Modify a single parameter in the matched FXID's PARM_TCP record only.
// Refuse unexpected chunks; do not rebuild all TCP controls or damage FX data.
bool changeTcpChunk(const std::string& original, const std::string& guid, int param, bool add,
                    std::string& result) {
    std::vector<std::string> lines;
    {
        std::istringstream input(original);
        for (std::string line; std::getline(input, line); ) lines.push_back(std::move(line));
    }
    if (lines.empty()) return false;
    const std::string wanted = upper(guid);
    int fxid = -1, matched = 0;
    for (int i = 0; i < static_cast<int>(lines.size()); ++i) {
        const std::string_view line = trimmed(lines[static_cast<size_t>(i)]);
        if (begins(line, "FXID ") && upper(std::string(line)).find(wanted) != std::string::npos) {
            fxid = i; ++matched;
        }
    }
    if (matched != 1 || fxid < 0) return false;
    // Require a plugin header before the matched FXID, and do not touch data
    // belonging to a following FX or nested plugin structure.
    int start = -1;
    for (int i = fxid - 1; i >= 0; --i) {
        if (fxHeader(lines[static_cast<size_t>(i)])) { start = i; break; }
    }
    if (start < 0) return false;
    int end = static_cast<int>(lines.size());
    for (int i = fxid + 1; i < static_cast<int>(lines.size()); ++i) {
        const auto line = trimmed(lines[static_cast<size_t>(i)]);
        if (fxHeader(line) || begins(line, "BYPASS ") || begins(line, "FXID ")) { end = i; break; }
    }
    // TCP metadata normally follows FXID and precedes WAK / the next FX.
    int oldTcp = -1, wak = -1;
    for (int i = fxid + 1; i < end; ++i) {
        const auto line = trimmed(lines[static_cast<size_t>(i)]);
        if (tcpLine(line)) {
            if (oldTcp >= 0) return false; // ambiguous multiple records
            oldTcp = i;
        }
        if (begins(line, "WAK ") && wak < 0) wak = i;
    }
    std::vector<int> indices;
    if (oldTcp >= 0) {
        const std::string_view line = trimmed(lines[static_cast<size_t>(oldTcp)]);
        std::istringstream tokens{std::string(line.substr(std::string_view("PARM_TCP").size()))};
        for (std::string token; tokens >> token;) {
            if (token.empty() || !std::all_of(token.begin(), token.end(), [](char c) {return c >= '0' && c <= '9';}))
                return false; // Do not reserialize an unknown extended format.
            try { indices.push_back(std::stoi(token)); } catch (...) { return false; }
        }
    }
    const bool present = std::find(indices.begin(), indices.end(), param) != indices.end();
    if (present == add) return false;
    if (add) indices.push_back(param);
    else indices.erase(std::remove(indices.begin(), indices.end(), param), indices.end());
    if (oldTcp >= 0) {
        // Preserve the existing leading indentation of REAPER's chunk.
        const std::string& old = lines[static_cast<size_t>(oldTcp)];
        const size_t prefix = old.find_first_not_of(" \t");
        std::string replacement = old.substr(0, prefix == std::string::npos ? 0 : prefix) + "PARM_TCP";
        for (int number : indices) replacement += " " + std::to_string(number);
        if (!replacement.empty() && !old.empty() && old.back() == '\r') replacement += '\r';
        if (indices.empty()) lines.erase(lines.begin() + oldTcp);
        else lines[static_cast<size_t>(oldTcp)] = std::move(replacement);
    } else if (add) {
        // In conventional track chunks PARM_TCP belongs after FXID, before WAK.
        const int pos = wak >= 0 ? wak : fxid + 1;
        const std::string& anchor = lines[static_cast<size_t>(fxid)];
        const size_t prefix = anchor.find_first_not_of(" \t");
        lines.insert(lines.begin() + pos,
            anchor.substr(0, prefix == std::string::npos ? 0 : prefix) +
            "PARM_TCP " + std::to_string(param) + (anchor.back() == '\r' ? "\r" : ""));
    }
    std::string revised;
    revised.reserve(original.size() + 24);
    for (const auto& line : lines) { revised += line; revised += '\n'; }
    if (revised == original) return false;
    result = std::move(revised);
    return true;
}
std::string getChunk(MediaTrack* track) {
    if (!GetTrackStateChunk) return {};
    thread_local std::vector<char> buffer(16 * 1024 * 1024, 0);
    buffer.front() = buffer.back() = 0;
    if (!GetTrackStateChunk(track, buffer.data(), static_cast<int>(buffer.size()), false)) return {};
    const size_t size = std::strlen(buffer.data());
    return size < buffer.size() - 1 ? std::string(buffer.data(), size) : std::string();
}
} // namespace

bool TrackNavigator::fxTcpParameterVisible(int fxIndex, int paramIndex) const {
    if (!CountTCPFXParms || !GetTCPFXParm || !track_) return false;
    const int count = std::clamp(CountTCPFXParms(project_, track_), 0, 8192);
    for (int i = 0; i < count; ++i) {
        int fx = -1, param = -1;
        if (GetTCPFXParm(project_, track_, i, &fx, &param) && fx == fxIndex && param == paramIndex)
            return true;
    }
    return false;
}
void TrackNavigator::rebuildFxTcpParameterGrid(int preferFx, int preferParam) {
    if (preferFx < 0 && fxTcpListPosition_ >= 0 && fxTcpListPosition_ < static_cast<int>(fxTcpListEntries_.size())) {
        const auto& old = fxTcpListEntries_[static_cast<size_t>(fxTcpListPosition_)];
        preferFx = old.fxIndex; preferParam = old.paramIndex;
    }
    fxTcpListEntries_.clear();
    if (!track_ || !TrackFX_GetCount || !TrackFX_GetNumParams || !TrackFX_GetParamName) return;
    const int fxCount = std::clamp(TrackFX_GetCount(track_), 0, 1024);
    const int first = fxTcpListFxIndex_ >= 0 ? fxTcpListFxIndex_ : 0;
    const int last = fxTcpListFxIndex_ >= 0 ? fxTcpListFxIndex_ + 1 : fxCount;
    for (int fx = first; fx < last && fx < fxCount; ++fx) {
        // Avoid showing parameters from an FX now occupying a reused index.
        if (fxTcpListFxIndex_ >= 0) {
            const GUID* current = TrackFX_GetFXGUID ? TrackFX_GetFXGUID(track_, fx) : nullptr;
            if (!current || std::memcmp(current, &fxTcpListFxGuid_, sizeof(GUID)) != 0) continue;
        }
        const int count = std::clamp(TrackFX_GetNumParams(track_, fx), 0, 32768);
        for (int param = 0; param < count; ++param) {
            const bool visible = fxTcpParameterVisible(fx, param);
            if (fxTcpListVisibleOnly_ && !visible) continue;
            char name[1024]{};
            TrackFX_GetParamName(track_, fx, param, name, sizeof(name));
            const std::string paramName = name[0] ? name : "Parameter " + std::to_string(param + 1);
            std::string label = paramName;
            if (fxTcpListFxIndex_ < 0) {
                char fxName[1024]{};
                if (TrackFX_GetFXName) TrackFX_GetFXName(track_, fx, fxName, sizeof(fxName));
                label = std::string(fxName[0] ? fxName : "FX " + std::to_string(fx + 1)) + ", " + label;
            }
            const GUID* guid = TrackFX_GetFXGUID ? TrackFX_GetFXGUID(track_, fx) : nullptr;
            if (!guid) continue;
            fxTcpListEntries_.push_back({fx, param, *guid, std::move(label), paramName, visible});
        }
    }
    fxTcpListPosition_ = std::clamp(fxTcpListPosition_, 0,
        std::max(0, static_cast<int>(fxTcpListEntries_.size()) - 1));
    if (preferFx >= 0 && preferParam >= 0) {
        for (int i = 0; i < static_cast<int>(fxTcpListEntries_.size()); ++i) {
            const auto& e = fxTcpListEntries_[static_cast<size_t>(i)];
            if (e.fxIndex == preferFx && e.paramIndex == preferParam) { fxTcpListPosition_ = i; break; }
        }
    }
}
std::string TrackNavigator::fxTcpParameterGridReview(bool details) const {
    if (fxTcpListEntries_.empty()) return "No parameters";
    const auto& e = fxTcpListEntries_[static_cast<size_t>(fxTcpListPosition_)];
    // Normal arrow navigation contains ONLY the parameter name, no values.
    if (!details) return e.name;
    return std::string(fxTcpListVisibleOnly_ ? "Visible TCP parameters. " : "FX parameter grid. ") +
        e.name + (e.visible ? ", visible in TCP" : ", not in TCP") +
        ". " + std::to_string(fxTcpListPosition_ + 1) + " of " +
        std::to_string(fxTcpListEntries_.size()) + ". Grid " + std::to_string(fxTcpListGridHeight_);
}
void TrackNavigator::openFxTcpParameterGrid(bool visibleOnly) {
    if (!track_) return;
    fxTcpListOpen_ = true;
    valueMode_ = false; // the names-only grid never edits a plugin value
    fxTcpListVisibleOnly_ = visibleOnly;
    fxTcpListFxIndex_ = visibleOnly ? -1 : (currentFxTcpColumn() ? currentFxTcpColumn()->fxIndex : -1);
    if (!visibleOnly && fxTcpListFxIndex_ >= 0 && TrackFX_GetFXGUID) {
        const GUID* id = TrackFX_GetFXGUID(track_, fxTcpListFxIndex_);
        if (id) fxTcpListFxGuid_ = *id;
    }
    fxTcpListPosition_ = 0;
    fxTcpListGridHeight_ = std::clamp(fxTcpListGridHeight_, 1, 200);
    rebuildFxTcpParameterGrid();
    speech_(std::string(visibleOnly ? "Visible TCP parameter grid. " : "FX parameter grid. ") +
        std::to_string(fxTcpListEntries_.size()) + " parameters. " + fxTcpParameterGridReview(false));
}
void TrackNavigator::closeFxTcpParameterGrid(bool announceCurrent) {
    const bool wasOpen = fxTcpListOpen_;
    fxTcpListOpen_ = false;
    fxTcpListEntries_.clear();
    rebuildFxTcp(true);
    rememberFxTcpPosition();
    if (announceCurrent && wasOpen) speech_(fxTcpReview(true));
}
bool TrackNavigator::setFxTcpParameterVisible(int fxIndex, int paramIndex, bool visible) {
    if (!track_ || !project_ || !ValidatePtr2(project_, track_, "MediaTrack*") ||
        !TrackFX_GetFXGUID || !TrackFX_GetCount || !TrackFX_GetNumParams || !CountTCPFXParms || !GetTCPFXParm ||
        !Undo_BeginBlock2 || !Undo_EndBlock2) return false;
    if (fxIndex < 0 || fxIndex >= TrackFX_GetCount(track_) ||
        paramIndex < 0 || paramIndex >= TrackFX_GetNumParams(track_, fxIndex)) return false;
    const GUID* id = TrackFX_GetFXGUID(track_, fxIndex);
    if (!id || fxTcpParameterVisible(fxIndex, paramIndex) == visible) return false;
    const std::string stableGuid = fxGuidText(*id);
    // Save the original chunk before attempting either API for safe rollback.
    const std::string oldChunk = getChunk(track_);
    Undo_BeginBlock2(project_);
    bool ok = false;
    if (TrackFX_SetNamedConfigParm) {
        const std::string key = "param." + std::to_string(paramIndex) + ".tcp";
        if (TrackFX_SetNamedConfigParm(track_, fxIndex, key.c_str(), visible ? "1" : "0"))
            ok = (fxTcpParameterVisible(fxIndex, paramIndex) == visible);
    }
    if (!ok && !oldChunk.empty() && SetTrackStateChunk) {
        std::string revised;
        if (changeTcpChunk(oldChunk, stableGuid, paramIndex, visible, revised) &&
            SetTrackStateChunk(track_, revised.c_str(), false))
            ok = fxTcpParameterVisible(fxIndex, paramIndex) == visible;
    }
    if (!ok && !oldChunk.empty() && SetTrackStateChunk) {
        // Avoid leaving partially changed state if REAPER rejects readback.
        SetTrackStateChunk(track_, oldChunk.c_str(), false);
    }
    Undo_EndBlock2(project_, visible ? "LReaParams: add FX parameter to TCP" :
                   "LReaParams: remove FX parameter from TCP", UNDO_STATE_TRACKCFG | UNDO_STATE_FX);
    if (ok) {
        if (TrackList_AdjustWindows) TrackList_AdjustWindows(false);
        if (UpdateArrange) UpdateArrange();
    }
    return ok;
}
void TrackNavigator::commitFxTcpParameterGrid(bool keepOpen) {
    if (fxTcpListEntries_.empty()) { if (!keepOpen) closeFxTcpParameterGrid(); return; }
    const FxTcpListEntry e = fxTcpListEntries_[static_cast<size_t>(fxTcpListPosition_)];
    // Never act on an index that now belongs to another FX instance.
    const GUID* currentGuid = TrackFX_GetFXGUID ? TrackFX_GetFXGUID(track_, e.fxIndex) : nullptr;
    if (!currentGuid || std::memcmp(currentGuid, &e.fxGuid, sizeof(GUID)) != 0) {
        speech_("FX chain changed. Reopen parameter grid"); return;
    }
    int oldVisibleRow = 0;
    if (e.fxIndex >= 0 && e.fxIndex < static_cast<int>(fxTcpColumns_.size())) {
        const FxTcpColumn& column = fxTcpColumns_[static_cast<size_t>(e.fxIndex)];
        for (int i = 0; i < static_cast<int>(column.parameters.size()); ++i) {
            if (column.parameters[static_cast<size_t>(i)].index == e.paramIndex) {
                oldVisibleRow = i + 1; break;
            }
        }
    }
    const bool desired = fxTcpListVisibleOnly_ ? false :
        (keepOpen ? !e.visible : true);
    if (desired != e.visible && !setFxTcpParameterVisible(e.fxIndex, e.paramIndex, desired)) {
        speech_("Could not change TCP parameter"); return;
    }
    // Reload the API truth rather than trusting the previous visual flag.
    rebuildFxTcp(true);
    if (fxTcpColumns_.empty()) {
        fxTcpListOpen_ = false;
        fxTcpListEntries_.clear();
        selectPage(Page::tracks);
        speech_("No track FX");
        return;
    }
    if (!keepOpen) {
        fxTcpColumn_ = std::clamp(e.fxIndex, 0, static_cast<int>(fxTcpColumns_.size()) - 1);
        fxTcpRow_ = 0;
        if (desired && currentFxTcpColumn()) {
            const auto& params = currentFxTcpColumn()->parameters;
            for (int i = 0; i < static_cast<int>(params.size()); ++i)
                if (params[static_cast<size_t>(i)].index == e.paramIndex) { fxTcpRow_ = i + 1; break; }
        } else if (currentFxTcpColumn()) {
            // When removing a visible control, return to its former neighbor,
            // not always to the FX header. The header is the empty fallback.
            const int count = static_cast<int>(currentFxTcpColumn()->parameters.size());
            fxTcpRow_ = std::min(oldVisibleRow, count);
        }
        fxTcpListOpen_ = false;
        fxTcpListEntries_.clear();
        rememberFxTcpPosition();
        speech_(std::string(desired ? (e.visible ? "Selected. " : "Added. ") : "Removed. ") +
                fxTcpReview(false));
        return;
    }
    rebuildFxTcpParameterGrid(e.fxIndex, e.paramIndex);
    speech_(std::string(desired ? "Added. " : "Removed. ") + fxTcpParameterGridReview(false));
}
void TrackNavigator::jumpFxTcpGridByInitial(wchar_t letter, bool backwards) {
    const int count = static_cast<int>(fxTcpListEntries_.size());
    if (!letter || !count) return;
    for (int offset = 1; offset <= count; ++offset) {
        const int index = backwards
            ? (fxTcpListPosition_ + count - offset) % count
            : (fxTcpListPosition_ + offset) % count;
        // Visible global grid prefixes the FX name for context; search only
        // the real parameter name, exactly like FX Params' cycling.
        if (!fxTcpInitialMatch(fxTcpListEntries_[static_cast<size_t>(index)].parameterName, letter)) continue;
        fxTcpListPosition_ = index;
        speech_(fxTcpParameterGridReview(false));
        return;
    }
    // Silent if no such initial exists.
}

void TrackNavigator::handleFxTcpParameterGridKey(const Key& k) {
    if (k.ctrl && k.shift && !k.alt && k.vk == 'M') {
        if (!k.repeat) openTrackMemories(false);
        return;
    }
    if (k.vk == VK_ESCAPE || (k.vk == VK_F4 && !k.ctrl && !k.alt && !k.shift)) {
        if (!k.repeat) closeFxTcpParameterGrid();
        return;
    }
    if ((k.vk == VK_F1 || k.vk == VK_F2) && !k.ctrl && !k.alt && !k.shift) {
        const int next = std::clamp(fxTcpListGridHeight_ + (k.vk == VK_F1 ? -1 : 1), 1, 200);
        if (next != fxTcpListGridHeight_) {
            fxTcpListGridHeight_ = next;
            speech_("Grid " + std::to_string(next));
        }
        return;
    }
    // F6 is reserved for a future Track Params environment, not a grid mutation.
    if (k.vk == VK_F6 && !k.ctrl && !k.shift && !k.alt) return;
    if (k.vk == VK_TAB && !k.ctrl && !k.shift && !k.alt) {
        if (!k.repeat) speech_(fxTcpParameterGridReview(true));
        return;
    }
    if (k.vk == VK_RETURN && !k.alt && !k.shift) {
        if (!k.repeat) commitFxTcpParameterGrid(k.ctrl);
        return;
    }
    if (fxTcpSearchCharacter(k)) {
        if (!k.repeat) jumpFxTcpGridByInitial(fxTcpSearchCharacter(k), k.shift);
        return;
    }
    if (fxTcpListEntries_.empty() || k.alt || k.shift) return;
    const int size = static_cast<int>(fxTcpListEntries_.size());
    const int height = fxTcpListGridHeight_;
    const int start = (fxTcpListPosition_ / height) * height;
    const int end = std::min(size - 1, start + height - 1);
    int next = fxTcpListPosition_;
    if (k.ctrl && !k.shift && (k.vk == VK_HOME || k.vk == VK_END))
        next = k.vk == VK_HOME ? 0 : size - 1;
    else if (!k.ctrl) {
        switch (k.vk) {
            case VK_UP: if (next > start) --next; break;
            case VK_DOWN: if (next < end) ++next; break;
            case VK_LEFT: if (next - height >= 0) next -= height; break;
            case VK_RIGHT: if (next + height < size) next += height; break;
            case VK_PRIOR: next = std::max(start, next - 5); break;
            case VK_NEXT: next = std::min(end, next + 5); break;
            case VK_HOME: next = start; break;
            case VK_END: next = end; break;
            default: return;
        }
    }
    if (next != fxTcpListPosition_) {
        fxTcpListPosition_ = next;
        speech_(fxTcpParameterGridReview(false));
    }
}
} // namespace lrp
