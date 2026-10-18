#include "lrp/TrackNavigator.h"
#include <algorithm>
#include <cmath>
#include <cwctype>
#include <cstdio>
#include <cstring>

namespace lrp {
namespace {
std::string guidLabel(const GUID& g) {
    char text[64]{};
    std::snprintf(text, sizeof(text), "{%08lX-%04hX-%04hX-%02hhX%02hhX-%02hhX%02hhX%02hhX%02hhX%02hhX%02hhX}",
        static_cast<unsigned long>(g.Data1), static_cast<unsigned short>(g.Data2),
        static_cast<unsigned short>(g.Data3), g.Data4[0], g.Data4[1], g.Data4[2], g.Data4[3],
        g.Data4[4], g.Data4[5], g.Data4[6], g.Data4[7]);
    return text;
}
}

const TrackNavigator::FxTcpColumn* TrackNavigator::currentFxTcpColumn() const {
    if (fxTcpColumn_ < 0 || fxTcpColumn_ >= static_cast<int>(fxTcpColumns_.size())) return nullptr;
    return &fxTcpColumns_[static_cast<size_t>(fxTcpColumn_)];
}
const TrackNavigator::FxTcpParameter* TrackNavigator::currentFxTcpParameter() const {
    const FxTcpColumn* column = currentFxTcpColumn();
    if (!column || fxTcpRow_ <= 0 || fxTcpRow_ > static_cast<int>(column->parameters.size())) return nullptr;
    return &column->parameters[static_cast<size_t>(fxTcpRow_ - 1)];
}
int TrackNavigator::fxTcpHeight() const {
    const FxTcpColumn* column = currentFxTcpColumn();
    return column ? 1 + static_cast<int>(column->parameters.size()) : 1;
}

void TrackNavigator::rebuildFxTcp(bool preserveSelection) {
    GUID oldGuid{};
    bool hadOldGuid = false;
    int oldParam = -1;
    const int oldColumn = fxTcpColumn_;
    const int oldRow = fxTcpRow_;
    if (preserveSelection) {
        if (const FxTcpColumn* currentColumn = currentFxTcpColumn()) {
            oldGuid = currentColumn->guid;
            hadOldGuid = true;
            if (const FxTcpParameter* parameter = currentFxTcpParameter()) oldParam = parameter->index;
        }
    }
    fxTcpColumns_.clear();
    fxTcpColumn_ = fxTcpRow_ = 0;
    if (!track_ || !project_ || !TrackFX_GetCount || !TrackFX_GetFXGUID ||
        !CountTCPFXParms || !GetTCPFXParm || !TrackFX_GetNumParams) return;

    // Enumerate every FX header, even when REAPER shows zero TCP knobs.
    const int count = std::clamp(TrackFX_GetCount(track_), 0, 1024);
    fxTcpColumns_.reserve(static_cast<size_t>(count));
    for (int fx = 0; fx < count; ++fx) {
        FxTcpColumn column;
        column.fxIndex = fx;
        if (const GUID* guid = TrackFX_GetFXGUID(track_, fx)) column.guid = *guid;
        char name[1024]{};
        if (TrackFX_GetFXName) TrackFX_GetFXName(track_, fx, name, sizeof(name));
        column.name = name[0] ? name : "FX " + std::to_string(fx + 1);
        fxTcpColumns_.push_back(std::move(column));
    }
    // REAPER's TCP API returns only the displayed knobs, preserving its order.
    // Do not enumerate all plugin parameters or infer from track-state chunks.
    const int knobCount = std::clamp(CountTCPFXParms(project_, track_), 0, 8192);
    for (int i = 0; i < knobCount; ++i) {
        int fx = -1, param = -1;
        if (!GetTCPFXParm(project_, track_, i, &fx, &param)) continue;
        if (fx < 0 || fx >= static_cast<int>(fxTcpColumns_.size())) continue;
        if (param < 0 || param >= TrackFX_GetNumParams(track_, fx)) continue;
        char name[1024]{};
        if (TrackFX_GetParamName) TrackFX_GetParamName(track_, fx, param, name, sizeof(name));
        fxTcpColumns_[static_cast<size_t>(fx)].parameters.push_back(
            {param, name[0] ? name : "Parameter " + std::to_string(param + 1)});
    }
    if (!fxTcpColumns_.empty() && preserveSelection) {
        fxTcpColumn_ = std::clamp(oldColumn, 0, static_cast<int>(fxTcpColumns_.size()) - 1);
        if (hadOldGuid) {
            for (int i = 0; i < static_cast<int>(fxTcpColumns_.size()); ++i) {
                if (std::memcmp(&fxTcpColumns_[static_cast<size_t>(i)].guid, &oldGuid, sizeof(GUID)) == 0) {
                    fxTcpColumn_ = i;
                    break;
                }
            }
        }
        fxTcpRow_ = std::clamp(oldRow, 0, fxTcpHeight() - 1);
        if (oldParam >= 0 && hadOldGuid &&
            std::memcmp(&fxTcpColumns_[static_cast<size_t>(fxTcpColumn_)].guid, &oldGuid, sizeof(GUID)) == 0) {
            const auto& params = fxTcpColumns_[static_cast<size_t>(fxTcpColumn_)].parameters;
            for (int i = 0; i < static_cast<int>(params.size()); ++i)
                if (params[static_cast<size_t>(i)].index == oldParam) { fxTcpRow_ = i + 1; break; }
        }
    }
}

std::string TrackNavigator::fxTcpReview(bool includeContext) const {
    if (fxTcpListOpen_) return fxTcpParameterGridReview(includeContext);
    const FxTcpColumn* column = currentFxTcpColumn();
    if (!column) return "No track FX";
    std::string name = "FX " + std::to_string(column->fxIndex + 1) + ", " + column->name;
    if (fxTcpRow_ == 0) {
        if (TrackFX_GetEnabled && !TrackFX_GetEnabled(track_, column->fxIndex)) name += ", bypassed";
        if (TrackFX_GetOffline && TrackFX_GetOffline(track_, column->fxIndex)) name += ", offline";
        if (includeContext && column->parameters.empty()) name += ", no TCP parameters";
        return name;
    }
    const FxTcpParameter* parameter = currentFxTcpParameter();
    if (!parameter) return name;
    char formatted[512]{};
    if (TrackFX_GetFormattedParamValue)
        TrackFX_GetFormattedParamValue(track_, column->fxIndex, parameter->index, formatted, sizeof(formatted));
    std::string value = formatted[0] ? formatted : "value unavailable";
    std::string result = parameter->name + ", " + value;
    if (includeContext) result = name + ", " + result + ", TCP parameter " +
        std::to_string(fxTcpRow_) + " of " + std::to_string(column->parameters.size());
    return result;
}

void TrackNavigator::rememberFxTcpPosition() {
    if (const FxTcpColumn* column = currentFxTcpColumn()) {
        memory_.setPosition("LastPage", "F4");
        memory_.setPosition("F4.TrackGUID", rowGuid());
        memory_.setPosition("F4.FxGUID", guidLabel(column->guid));
        memory_.setPosition("F4.Row", std::to_string(fxTcpRow_));
    }
}

bool TrackNavigator::selectFxTcpPage() {
    if (!track_ || !TrackFX_GetCount || TrackFX_GetCount(track_) <= 0) {
        speech_("No track FX"); return false;
    }
    if (!CountTCPFXParms || !GetTCPFXParm) {
        speech_("REAPER TCP FX parameter API unavailable"); return false;
    }
    // Do not switch pages if the native API cannot provide a meaningful view.
    rememberPosition();
    page_ = Page::fxTcp;
    entries_.clear(); // F4 owns separate FX TCP value targets; discard stale F1/F2/F3 entries.
    valueMode_ = false;
    fxTcpListOpen_ = false; fxTcpListEntries_.clear();
    resetSelectionStroke();
    rebuildFxTcp(false);
    if (fxTcpColumns_.empty()) { page_ = Page::tracks; buildEntries(); speech_("No track FX"); return false; }
    if (memory_.position("F4.TrackGUID") == rowGuid()) {
        const std::string wanted = memory_.position("F4.FxGUID");
        for (int i = 0; i < static_cast<int>(fxTcpColumns_.size()); ++i) {
            if (guidLabel(fxTcpColumns_[static_cast<size_t>(i)].guid) == wanted) {
                fxTcpColumn_ = i; break;
            }
        }
        try { fxTcpRow_ = std::clamp(std::stoi(memory_.position("F4.Row")), 0, fxTcpHeight() - 1); }
        catch (...) { fxTcpRow_ = 0; }
    }
    rememberFxTcpPosition();
    announceTitle();
    return true;
}

void TrackNavigator::moveFxTcpColumn(int delta) {
    if (fxTcpColumns_.empty()) return;
    const int next = std::clamp(fxTcpColumn_ + delta, 0, static_cast<int>(fxTcpColumns_.size()) - 1);
    if (next == fxTcpColumn_) return; // Silent boundary, as FX Memories.
    fxTcpColumn_ = next;
    valueMode_ = false;
    fxTcpRow_ = std::min(fxTcpRow_, fxTcpHeight() - 1);
    rememberFxTcpPosition();
    // A new FX column needs its name once; vertical movements stay concise.
    speech_(fxTcpReview(true));
}
void TrackNavigator::moveFxTcpRow(int delta) {
    const int next = std::clamp(fxTcpRow_ + delta, 0, fxTcpHeight() - 1);
    if (next == fxTcpRow_) return;
    fxTcpRow_ = next;
    valueMode_ = false;
    rememberFxTcpPosition();
    speech_(fxTcpReview(false));
}

wchar_t TrackNavigator::fxTcpSearchCharacter(const Key& k) {
    if (k.ctrl || k.alt || k.altGr) return 0;
    if (k.character && std::iswalnum(static_cast<wint_t>(k.character))) return k.character;
    // With Shift the number-row keys produce punctuation on many keyboard
    // layouts. Preserve Shift+digit = reverse search, using its physical digit.
    if (k.shift && k.vk >= '0' && k.vk <= '9') return static_cast<wchar_t>(k.vk);
    if (k.shift && k.vk >= VK_NUMPAD0 && k.vk <= VK_NUMPAD9)
        return static_cast<wchar_t>(L'0' + (k.vk - VK_NUMPAD0));
    return 0;
}

bool TrackNavigator::fxTcpInitialMatch(const std::string& label, wchar_t letter) {
    if (label.empty() || !letter) return false;
    CharLowerBuffW(&letter, 1);
    const unsigned char start = static_cast<unsigned char>(label.front());
    const int length = start < 0x80 ? 1 : start < 0xc0 ? 0 :
        start < 0xe0 ? 2 : start < 0xf0 ? 3 : 4;
    if (!length || label.size() < static_cast<size_t>(length)) return false;
    wchar_t first[2]{};
    if (MultiByteToWideChar(CP_UTF8, MB_ERR_INVALID_CHARS, label.data(), length, first, 2) != 1) return false;
    CharLowerBuffW(first, 1);
    return first[0] == letter;
}

void TrackNavigator::jumpFxTcpByInitial(wchar_t letter, bool backwards) {
    const FxTcpColumn* column = currentFxTcpColumn();
    if (!letter || !column || column->parameters.empty()) return;
    const int count = static_cast<int>(column->parameters.size());
    // The FX header (row 0) is never a letter-search result. Cycling is
    // limited to this FX's visible TCP parameter names, not the FX names.
    const int initial = fxTcpRow_ <= 0 ? (backwards ? 0 : -1) : fxTcpRow_ - 1;
    for (int offset = 1; offset <= count; ++offset) {
        const int index = (initial + (backwards ? -offset : offset) % count + count * 2) % count;
        if (!fxTcpInitialMatch(column->parameters[static_cast<size_t>(index)].name, letter)) continue;
        fxTcpRow_ = index + 1;
        valueMode_ = false;
        rememberFxTcpPosition();
        speech_(fxTcpReview(false));
        return;
    }
}

std::string TrackNavigator::fxTcpStepKey() const {
    const FxTcpColumn* column = currentFxTcpColumn();
    const FxTcpParameter* param = currentFxTcpParameter();
    if (!column || !param) return {};
    // One step per FX parameter in the project .tp, not per track-wide Pan/Volume.
    return "F4." + guidLabel(column->guid) + "." + std::to_string(param->index);
}

bool TrackNavigator::writeFxTcpValue(double normalized) {
    if (!std::isfinite(normalized) || !track_ || !project_ || !TrackFX_GetFXGUID ||
        !TrackFX_GetParamNormalized || !TrackFX_SetParamNormalized ||
        !Undo_BeginBlock2 || !Undo_EndBlock2) return false;
    const FxTcpColumn* column = currentFxTcpColumn();
    const FxTcpParameter* param = currentFxTcpParameter();
    if (!column || !param || !TrackFX_GetCount ||
        column->fxIndex < 0 || column->fxIndex >= TrackFX_GetCount(track_)) return false;
    const GUID* currentGuid = TrackFX_GetFXGUID(track_, column->fxIndex);
    if (!currentGuid || std::memcmp(currentGuid, &column->guid, sizeof(GUID)) != 0 ||
        !fxTcpParameterVisible(column->fxIndex, param->index)) {
        speech_("FX TCP structure changed. Reopen F4"); return false;
    }
    normalized = std::clamp(normalized, 0.0, 1.0);
    const double previous = TrackFX_GetParamNormalized(track_, column->fxIndex, param->index);
    if (!std::isfinite(previous) || std::abs(previous - normalized) < 1e-12) return false;
    Undo_BeginBlock2(project_);
    const bool ok = TrackFX_SetParamNormalized(track_, column->fxIndex, param->index, normalized);
    if (TrackFX_EndParamEdit) TrackFX_EndParamEdit(track_, column->fxIndex, param->index);
    Undo_EndBlock2(project_, "LReaParams: Track F4 FX TCP parameter", UNDO_STATE_FX);
    if (!ok) { speech_("FX parameter change refused"); return false; }
    speech_(fxTcpReview(false));
    return true;
}

void TrackNavigator::nudgeFxTcpValue(int direction, bool coarse) {
    const auto* column = currentFxTcpColumn();
    const auto* param = currentFxTcpParameter();
    if (!column || !param || !TrackFX_GetParamNormalized) return;
    double normal = 0, small = 0, large = 0;
    bool toggle = false;
    const bool known = TrackFX_GetParameterStepSizes &&
        TrackFX_GetParameterStepSizes(track_, column->fxIndex, param->index,
                                     &normal, &small, &large, &toggle);
    const double old = TrackFX_GetParamNormalized(track_, column->fxIndex, param->index);
    if (!std::isfinite(old)) return;
    if (known && toggle) { writeFxTcpValue(direction > 0 ? 1.0 : 0.0); return; }
    double step = known ? (coarse ? large : normal) : 0.0;
    if (!std::isfinite(step) || step <= 0.0 || step > 1.0) step = coarse ? 0.01 : 0.001;
    step *= std::pow(2.0, memory_.step(fxTcpStepKey()));
    writeFxTcpValue(old + direction * step);
}

void TrackNavigator::handleFxTcpKey(const Key& k) {
    // The parameter-selection grid owns its own keys, including F1/F2 grid size.
    if (fxTcpListOpen_) { handleFxTcpParameterGridKey(k); return; }
    if (k.ctrl && k.shift && !k.alt && k.vk == 'M') {
        if (!k.repeat) openTrackMemories(false);
        return;
    }
    if (k.ctrl && !k.shift && !k.alt && (k.vk == 'Q' || k.vk == VK_TAB)) {
        // Ctrl+Q and Ctrl+Tab are dispatched by the extension's central router.
        return;
    }
    if (k.vk == VK_SPACE && !k.shift && !k.alt) {
        if (!k.repeat) {
            if (k.ctrl) { if (Main_OnCommand) Main_OnCommand(40073, 0); }
            else {
                const int state = GetPlayState ? GetPlayState() : 0;
                if ((state & 2) && OnPlayButton) OnPlayButton();
                else if (Main_OnCommand) Main_OnCommand(40044, 0);
            }
        }
        return;
    }
    if (k.ctrl && !k.shift && !k.alt && (k.vk == VK_UP || k.vk == VK_DOWN)) {
        const int dir = k.vk == VK_UP ? -1 : 1;
        for (int i = row_ + dir; i >= 0 && i < static_cast<int>(rows_.size()); i += dir) {
            MediaTrack* candidate = rows_[static_cast<size_t>(i)].track;
            if (!candidate || !ValidatePtr2(project_, candidate, "MediaTrack*") ||
                !TrackFX_GetCount || TrackFX_GetCount(candidate) <= 0) continue;
            rememberFxTcpPosition();
            row_ = i;
            track_ = candidate;
            syncCursorToReaper();
            rebuildFxTcp(false);
            rememberFxTcpPosition();
            speech_(trackName() + ". " + fxTcpReview(true));
            return;
        }
        return; // Silent edge: no other visible track with FX.
    }
    if (k.vk == VK_F4) return;
    if (k.vk == VK_F1) { valueMode_ = false; selectPage(Page::tracks); return; }
    if (k.vk == VK_F2) { valueMode_ = false; selectPage(Page::sends); return; }
    if (k.vk == VK_F3) { valueMode_ = false; selectPage(Page::receives); return; }
    if (k.vk == VK_ESCAPE) {
        if (valueMode_) { valueMode_ = false; speech_("Grid, " + fxTcpReview(false)); }
        else selectPage(Page::tracks);
        return;
    }
    // Function keys change environments; Alt+Enter owns the editable TCP-visible
    // selection grid. F6 is explicitly reserved for a future environment.
    if (k.vk == VK_F6 && !k.ctrl && !k.shift && !k.alt) return;
    if (k.vk == VK_RETURN && k.alt && !k.ctrl && !k.shift) {
        if (!k.repeat) openFxTcpParameterGrid(true);
        return;
    }
    if (k.vk == VK_RETURN && !k.ctrl && !k.alt && !k.shift) {
        if (!k.repeat) {
            if (fxTcpRow_ == 0) openFxTcpParameterGrid(false);
            else {
                valueMode_ = !valueMode_;
                speech_(std::string(valueMode_ ? "Value, " : "Grid, ") + fxTcpReview(false));
            }
        }
        return;
    }

    if (!valueMode_ && fxTcpSearchCharacter(k)) {
        if (!k.repeat) jumpFxTcpByInitial(fxTcpSearchCharacter(k), k.shift);
        return;
    }
    // Values are changed only in Value mode or with Alt+Up/Down, never by
    // ordinary Grid arrow navigation. Mirror FX Params' scaled steps.
    if (!k.ctrl && k.alt && !k.shift && (k.vk == VK_LEFT || k.vk == VK_RIGHT)) {
        const std::string key = fxTcpStepKey();
        if (!key.empty() && !k.repeat) {
            const int now = memory_.step(key);
            const int next = std::clamp(now + (k.vk == VK_RIGHT ? 1 : -1), -10, 10);
            if (next != now) {
                memory_.setStep(key, next);
                memory_.flush();
                speech_("Step " + std::to_string(next));
            }
        }
        return;
    }
    if (!k.ctrl && !k.shift && (valueMode_ || k.alt) &&
        (k.vk == VK_UP || k.vk == VK_DOWN || k.vk == VK_PRIOR || k.vk == VK_NEXT)) {
        nudgeFxTcpValue((k.vk == VK_UP || k.vk == VK_PRIOR) ? 1 : -1,
                        k.vk == VK_PRIOR || k.vk == VK_NEXT);
        return;
    }
    if (valueMode_ && !k.ctrl && !k.alt && !k.shift &&
        (k.vk == VK_HOME || k.vk == VK_END)) {
        writeFxTcpValue(k.vk == VK_HOME ? 1.0 : 0.0);
        return;
    }
    if (k.vk == VK_TAB && !k.ctrl && !k.alt && !k.shift) {
        if (!k.repeat) {
            const std::string key = fxTcpStepKey();
            speech_((valueMode_ ? "Value, " : "") + fxTcpReview(true) +
                (key.empty() ? "" : ". Step " + std::to_string(memory_.step(key))));
        }
        return;
    }
    if (valueMode_) return; // ordinary arrows do not navigate the active Value slider

    // Re-query the TCP API after external FX / TCP configuration edits.
    // Reattach to the GUID and parameter ID, not a now-stale column index.
    rebuildFxTcp(true);
    if (fxTcpColumns_.empty()) { speech_("No track FX"); selectPage(Page::tracks); return; }
    if (k.ctrl && !k.alt && !k.shift && (k.vk == VK_HOME || k.vk == VK_END)) {
        const int target = k.vk == VK_HOME ? 0 : static_cast<int>(fxTcpColumns_.size()) - 1;
        moveFxTcpColumn(target - fxTcpColumn_);
        return;
    }
    if (k.ctrl || k.alt || k.shift) return;
    switch (k.vk) {
        case VK_LEFT: moveFxTcpColumn(-1); break;
        case VK_RIGHT: moveFxTcpColumn(1); break;
        case VK_UP: moveFxTcpRow(-1); break;
        case VK_DOWN: moveFxTcpRow(1); break;
        case VK_PRIOR: moveFxTcpRow(-5); break;
        case VK_NEXT: moveFxTcpRow(5); break;
        case VK_HOME: moveFxTcpRow(-fxTcpRow_); break;
        case VK_END: moveFxTcpRow(fxTcpHeight() - 1 - fxTcpRow_); break;
        default: break;
    }
}
} // namespace lrp
