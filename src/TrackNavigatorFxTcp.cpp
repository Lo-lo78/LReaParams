#include "lrp/TrackNavigator.h"
#include <algorithm>
#include <cmath>
#include <cwctype>
#include <cstdio>
#include <cstring>
#include <cctype>
#include <string_view>
#include <vector>
#include <sstream>
#include <iomanip>
#include <locale>

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
// Match FX Params' Ctrl+F contract: unquoted case-insensitive substring,
// quoted exact whole word or phrase; in multiword quotes the final word
// may be a prefix. Filter only names, never formatted values or FX IDs.
std::string lowerSearch(std::string value) {
    for (char& c : value) c = static_cast<char>(std::tolower(static_cast<unsigned char>(c)));
    return value;
}
std::vector<std::string> searchWords(const std::string& text) {
    std::vector<std::string> result;
    std::string word;
    for (unsigned char c : text) {
        if (std::isalnum(c) || c >= 128 || c == '_') word.push_back(static_cast<char>(std::tolower(c)));
        else if (!word.empty()) { result.push_back(std::move(word)); word.clear(); }
    }
    if (!word.empty()) result.push_back(std::move(word));
    return result;
}
}

bool TrackNavigator::fxTcpMatchesSearch(const std::string& label, const std::string& query) {
    if (query.empty()) return true;
    if (query.size() < 2 || query.front() != '"' || query.back() != '"')
        return lowerSearch(label).find(lowerSearch(query)) != std::string::npos;
    const auto sought = searchWords(query.substr(1, query.size() - 2));
    const auto available = searchWords(label);
    if (sought.empty() || sought.size() > available.size()) return false;
    for (size_t pos = 0; pos + sought.size() <= available.size(); ++pos) {
        bool ok = true;
        for (size_t i = 0; i < sought.size(); ++i) {
            const bool lastPrefix = i + 1 == sought.size() && sought.size() > 1;
            if (lastPrefix ? available[pos + i].compare(0, sought[i].size(), sought[i]) != 0
                           : available[pos + i] != sought[i]) { ok = false; break; }
        }
        if (ok) return true;
    }
    return false;
}

std::string TrackNavigator::fxTcpActiveFilter() const {
    return fxTcpListOpen_ ? fxTcpGridFilter_ : fxTcpMainFilter_;
}
bool TrackNavigator::fxTcpHasMatches(const std::string& query) const {
    if (!track_ || !TrackFX_GetCount || !TrackFX_GetNumParams || !TrackFX_GetParamName) return false;
    const int count = std::clamp(TrackFX_GetCount(track_), 0, 1024);
    const int first = fxTcpListOpen_ && !fxTcpListVisibleOnly_ ? fxTcpListFxIndex_ : 0;
    const int last = fxTcpListOpen_ && !fxTcpListVisibleOnly_ ? first + 1 : count;
    for (int fx = std::max(0, first); fx < std::min(count, last); ++fx) {
        const int params = std::clamp(TrackFX_GetNumParams(track_, fx), 0, 32768);
        for (int p = 0; p < params; ++p) {
            if (fxTcpListOpen_ && fxTcpListVisibleOnly_ && !fxTcpParameterVisible(fx, p)) continue;
            if (!fxTcpListOpen_ && !fxTcpParameterVisible(fx, p)) continue;
            char name[1024]{};
            TrackFX_GetParamName(track_, fx, p, name, sizeof(name));
            if (fxTcpMatchesSearch(name[0] ? name : "Parameter " + std::to_string(p + 1), query)) return true;
        }
    }
    return false;
}
void TrackNavigator::toggleFxTcpFilter() {
    if (!fxTcpActiveFilter().empty()) { clearFxTcpFilter(); return; }
    if (!nativeFilterAvailable_) { speech_("Enable the native keyboard window to edit a filter"); return; }
    valueMode_ = false;
    filterBuffer_.clear();
    filterEditing_ = true;
    speech_(nativeTextLabel() + ". Type text and press Enter; Escape cancels.");
}
void TrackNavigator::applyFxTcpFilter() {
    // Keep the native edit and caret available if nothing matches.
    std::string query = filterBuffer_;
    const size_t start = query.find_first_not_of(" \r\n\t");
    if (start == std::string::npos) { clearFxTcpFilter(); return; }
    const size_t end = query.find_last_not_of(" \r\n\t");
    query = query.substr(start, end - start + 1);
    if (!fxTcpHasMatches(query)) { speech_("No results for " + query + ". Edit the filter or press Escape"); return; }
    filterEditing_ = false; filterBuffer_.clear();
    if (fxTcpListOpen_) {
        fxTcpGridFilter_ = query;
        rebuildFxTcpParameterGrid();
        if (fxTcpListVisibleOnly_ && !fxTcpVisibleColumns_.empty() &&
            fxTcpVisibleColumns_[static_cast<size_t>(fxTcpListColumn_)].empty()) {
            // A filter must land on a MATCH, not on an empty FX header.
            for (int fx = 0; fx < static_cast<int>(fxTcpVisibleColumns_.size()); ++fx) {
                if (fxTcpVisibleColumns_[static_cast<size_t>(fx)].empty()) continue;
                fxTcpListColumn_ = fx;
                fxTcpListRow_ = 1;
                syncFxTcpVisibleSelection();
                break;
            }
        }
    } else {
        fxTcpMainFilter_ = query;
        rebuildFxTcp(true);
        // Select the first matching parameter, keeping its actual FX column.
        bool selected = false;
        if (fxTcpColumns_.empty()) { fxTcpMainFilter_.clear(); speech_("No track FX"); return; }
        for (int offset = 0, count = static_cast<int>(fxTcpColumns_.size()); offset < count; ++offset) {
            const int c = (fxTcpColumn_ + offset) % count;
            if (!fxTcpColumns_[static_cast<size_t>(c)].parameters.empty()) {
                fxTcpColumn_ = c; fxTcpRow_ = 1; selected = true; break;
            }
        }
        if (!selected) { fxTcpMainFilter_.clear(); rebuildFxTcp(true); speech_("No results"); return; }
        rememberFxTcpPosition();
    }
    const int count = fxTcpListOpen_ ? static_cast<int>(fxTcpListEntries_.size()) : [&] {
        int n = 0; for (const auto& col : fxTcpColumns_) n += static_cast<int>(col.parameters.size()); return n;
    }();
    speech_("Search results. " + std::to_string(count) + " results. " + fxTcpReview(false));
}
void TrackNavigator::cancelFxTcpFilter() {
    filterEditing_ = false;
    filterBuffer_.clear();
    speech_("Search cleared. " + fxTcpReview(false));
}
void TrackNavigator::clearFxTcpFilter() {
    filterEditing_ = false; filterBuffer_.clear();
    if (fxTcpListOpen_) { fxTcpGridFilter_.clear(); rebuildFxTcpParameterGrid(); }
    else { fxTcpMainFilter_.clear(); rebuildFxTcp(true); }
    speech_("Search cleared. " + fxTcpReview(false));
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
        if (!fxTcpMatchesSearch(name[0] ? name : "Parameter " + std::to_string(param + 1), fxTcpMainFilter_)) continue;
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
        fxTcpRow_ = std::clamp(oldRow, fxTcpHeight() > 1 ? 1 : 0, fxTcpHeight() - 1);
        if (oldParam >= 0 && hadOldGuid &&
            std::memcmp(&fxTcpColumns_[static_cast<size_t>(fxTcpColumn_)].guid, &oldGuid, sizeof(GUID)) == 0) {
            const auto& params = fxTcpColumns_[static_cast<size_t>(fxTcpColumn_)].parameters;
            for (int i = 0; i < static_cast<int>(params.size()); ++i)
                if (params[static_cast<size_t>(i)].index == oldParam) { fxTcpRow_ = i + 1; break; }
        }
    }
    // No header is part of F4 navigation. With TCP parameters, select one;
    // row zero is a non-interactive empty state only.
    if (fxTcpHeight() > 1 && fxTcpRow_ == 0) fxTcpRow_ = 1;
}

std::string TrackNavigator::fxTcpValueSpeech() const {
    const auto* column = currentFxTcpColumn();
    const auto* parameter = currentFxTcpParameter();
    if (!column || !parameter) return {};
    char formatted[512]{};
    if (TrackFX_GetFormattedParamValue)
        TrackFX_GetFormattedParamValue(track_, column->fxIndex, parameter->index, formatted, sizeof(formatted));
    return formatted[0] ? std::string(formatted) : "value unavailable";
}

std::string TrackNavigator::fxTcpReview(bool includeContext) const {
    if (fxTcpListOpen_) return fxTcpParameterGridReview(includeContext);
    const FxTcpColumn* column = currentFxTcpColumn();
    if (!column) return "No track FX";
    std::string name = "FX " + std::to_string(column->fxIndex + 1) + ", " + column->name;
    if (fxTcpRow_ == 0) {
        if (TrackFX_GetEnabled && !TrackFX_GetEnabled(track_, column->fxIndex)) name += ", bypassed";
        if (TrackFX_GetOffline && TrackFX_GetOffline(track_, column->fxIndex)) name += ", offline";
        if (column->parameters.empty()) name += ", no TCP parameters. Alt+Enter to add";
        return name;
    }
    const FxTcpParameter* parameter = currentFxTcpParameter();
    if (!parameter) return name;
    char formatted[512]{};
    if (TrackFX_GetFormattedParamValue)
        TrackFX_GetFormattedParamValue(track_, column->fxIndex, parameter->index, formatted, sizeof(formatted));
    std::string value = formatted[0] ? formatted : "value unavailable";
    std::string result = parameter->name + ", " + value;
    result += ccParameterSuffix(); // FX Params contract: CC before Auto.
    if (fxTcpAutomationActive()) result += ". Auto";
    if (includeContext) result = name + ", " + result + ", TCP parameter " +
        std::to_string(fxTcpRow_) + " of " + std::to_string(column->parameters.size()) +
        ". Grid column " + std::to_string((fxTcpRow_ - 1) / 8 + 1) +
        ", row " + std::to_string((fxTcpRow_ - 1) % 8 + 1) + " of 8";
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
    fxTcpListOpen_ = false; fxTcpListEntries_.clear(); fxTcpMainFilter_.clear(); fxTcpGridFilter_.clear();
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
        try { fxTcpRow_ = std::clamp(std::stoi(memory_.position("F4.Row")),
            fxTcpHeight() > 1 ? 1 : 0, fxTcpHeight() - 1); }
        catch (...) { fxTcpRow_ = fxTcpHeight() > 1 ? 1 : 0; }
    } else if (fxTcpHeight() > 1) fxTcpRow_ = 1;
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
    fxTcpRow_ = std::clamp(fxTcpRow_, fxTcpHeight() > 1 ? 1 : 0, fxTcpHeight() - 1);
    rememberFxTcpPosition();
    // A new FX announces its name once; vertical movement remains concise.
    speech_(fxTcpReview(true));
}
void TrackNavigator::moveFxTcpRow(int delta) {
    const int next = std::clamp(fxTcpRow_ + delta, fxTcpHeight() > 1 ? 1 : 0, fxTcpHeight() - 1);
    if (next == fxTcpRow_) return;
    fxTcpRow_ = next;
    valueMode_ = false;
    rememberFxTcpPosition();
    speech_(fxTcpReview(false));
}

// TEST56.7: FX Params-style grid of eight TCP parameters per column.
// No interactive FX header: the FX name belongs to the title and Tab review.
void TrackNavigator::moveFxTcpGrid(unsigned int key) {
    const auto* col = currentFxTcpColumn();
    if (!col) return;
    const int count = static_cast<int>(col->parameters.size());
    if (!count) return; // Empty FX remains accessible through Alt+Enter.
    if (fxTcpRow_ == 0) fxTcpRow_ = 1; // Legacy saved header position.
    const int index = fxTcpRow_ - 1;
    const int first = (index / 8) * 8;
    const int last = std::min(count - 1, first + 7);
    int next = index;
    switch (key) {
        case VK_UP: if (index > first) --next; break;
        case VK_DOWN: if (index < last) ++next; break;
        case VK_LEFT: if (index >= 8) next -= 8; break;
        case VK_RIGHT: if (index + 8 < count) next += 8; break;
        case VK_HOME: next = first; break;
        case VK_END: next = last; break;
        case VK_PRIOR: next = std::max(first, index - 5); break;
        case VK_NEXT: next = std::min(last, index + 5); break;
        default: return;
    }
    if (next != index) moveFxTcpRow(next + 1 - fxTcpRow_);
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
    if (!suppressPutSpeech_ && memory_.valueSpeech(fxTcpStepKey()))
        speech_(fxTcpValueSpeech()); // FX Params: only the new value, if speech enabled.
    return true;
}

bool TrackNavigator::writeFxTcpRawValue(double raw) {
    if (!std::isfinite(raw) || !fxTcpSelectedIdentityValid() ||
        !TrackFX_GetParam || !TrackFX_SetParam || !Undo_BeginBlock2 || !Undo_EndBlock2) return false;
    const auto* column = currentFxTcpColumn();
    const auto* parameter = currentFxTcpParameter();
    if (!column || !parameter || !fxTcpParameterVisible(column->fxIndex, parameter->index)) return false;
    double low = 0.0, high = 1.0;
    const double previous = TrackFX_GetParam(track_, column->fxIndex, parameter->index, &low, &high);
    if (!std::isfinite(low) || !std::isfinite(high) || !std::isfinite(previous) ||
        raw < std::min(low, high) || raw > std::max(low, high)) return false;
    if (std::abs(previous - raw) < 1e-12) return true; // valid no-op
    Undo_BeginBlock2(project_);
    const bool ok = TrackFX_SetParam(track_, column->fxIndex, parameter->index, raw);
    if (TrackFX_EndParamEdit) TrackFX_EndParamEdit(track_, column->fxIndex, parameter->index);
    Undo_EndBlock2(project_, "LReaParams: Track F4 numeric parameter", UNDO_STATE_FX);
    if (!ok) { speech_("FX parameter change refused"); return false; }
    if (!suppressPutSpeech_ && memory_.valueSpeech(fxTcpStepKey())) speech_(fxTcpValueSpeech());
    return true;
}

bool TrackNavigator::fxTcpFormatNumeric(double norm, double& result, std::string& unit) const {
    const auto* column = currentFxTcpColumn();
    const auto* parameter = currentFxTcpParameter();
    if (!column || !parameter || !TrackFX_FormatParamValueNormalized) return false;
    char buffer[1024]{};
    if (!TrackFX_FormatParamValueNormalized(track_, column->fxIndex, parameter->index,
                                             norm, buffer, sizeof(buffer))) return false;
    std::istringstream input(buffer);
    input.imbue(std::locale::classic());
    if (!(input >> result) || !std::isfinite(result)) return false;
    std::getline(input, unit);
    return true;
}

void TrackNavigator::beginFxTcpNumericEdit() {
    if (!nativeFilterAvailable_ || filterEditing_ || numericEditing_ || fxTcpListOpen_) {
        speech_("Numeric editor unavailable"); return;
    }
    rebuildFxTcp(true);
    if (!fxTcpSelectedIdentityValid() || !currentFxTcpParameter() ||
        !TrackFX_GetParam || !TrackFX_GetParamNormalized) {
        speech_("No TCP parameter for numeric editing"); return;
    }
    const auto* column = currentFxTcpColumn();
    const auto* parameter = currentFxTcpParameter();
    double low = 0.0, high = 1.0;
    double current = TrackFX_GetParam(track_, column->fxIndex, parameter->index, &low, &high);
    if (!std::isfinite(current)) { speech_("Numeric value unavailable"); return; }
    fxTcpNumericFormatted_ = false;
    fxTcpNumericUnit_.clear();
    double first = 0, last = 0;
    std::string a, b;
    if (fxTcpFormatNumeric(0, first, a) && fxTcpFormatNumeric(1, last, b) &&
        a == b && first != last) {
        bool monotonic = true;
        double previous = first;
        for (int i = 1; i <= 64; ++i) {
            double value = 0; std::string unit;
            if (!fxTcpFormatNumeric(i / 64.0, value, unit) || unit != a ||
                (last > first ? value < previous : value > previous)) {
                monotonic = false; break;
            }
            previous = value;
        }
        std::string currentUnit;
        double displayed = 0;
        const double norm = TrackFX_GetParamNormalized(track_, column->fxIndex, parameter->index);
        if (monotonic && std::isfinite(norm) &&
            fxTcpFormatNumeric(norm, displayed, currentUnit) && currentUnit == a) {
            fxTcpNumericFormatted_ = true;
            fxTcpNumericUnit_ = a;
            current = displayed;
        }
    }
    std::ostringstream text;
    text.imbue(std::locale::classic());
    text << std::setprecision(12) << current;
    numericBuffer_ = text.str();
    fxTcpNumericGuid_ = column->guid;
    fxTcpNumericParameter_ = parameter->index;
    fxTcpNumericTrack_ = rowGuid();
    numericEditing_ = true;
    rangeEditing_ = false;
    valueMode_ = false;
    speech_(fxTcpNumericFormatted_ ? "Parameter value. " + fxTcpNumericUnit_ :
                                   "Parameter value. Host raw units");
}

void TrackNavigator::commitFxTcpNumericEdit() {
    if (!numericEditing_) return;
    if (!fxTcpSelectedIdentityValid() || !currentFxTcpParameter() ||
        rowGuid() != fxTcpNumericTrack_ ||
        std::memcmp(&currentFxTcpColumn()->guid, &fxTcpNumericGuid_, sizeof(GUID)) != 0 ||
        currentFxTcpParameter()->index != fxTcpNumericParameter_) {
        numericEditing_ = false;
        speech_("FX changed. Numeric edit cancelled");
        return;
    }
    std::istringstream text(numericBuffer_);
    text.imbue(std::locale::classic());
    double desired = 0;
    if (!(text >> desired) || !(text >> std::ws).eof() || !std::isfinite(desired)) {
        speech_("Invalid number"); return;
    }
    bool ok = false;
    suppressPutSpeech_ = true;
    if (fxTcpNumericFormatted_) {
        double first = 0, last = 0; std::string a, b;
        if (fxTcpFormatNumeric(0, first, a) && fxTcpFormatNumeric(1, last, b) &&
            a == b && a == fxTcpNumericUnit_ &&
            desired >= std::min(first, last) && desired <= std::max(first, last)) {
            double left = 0, right = 1;
            bool formatterOk = true;
            for (int i = 0; i < 48; ++i) {
                const double mid = (left + right) * 0.5;
                double shown = 0; std::string unit;
                if (!fxTcpFormatNumeric(mid, shown, unit) || unit != a) {
                    formatterOk = false; break;
                }
                if ((last > first) == (shown < desired)) left = mid;
                else right = mid;
            }
            if (formatterOk) ok = writeFxTcpValue((left + right) * 0.5);
            if (formatterOk && !ok && TrackFX_GetParamNormalized) {
                const double now = TrackFX_GetParamNormalized(track_, currentFxTcpColumn()->fxIndex,
                                                               currentFxTcpParameter()->index);
                ok = std::isfinite(now) && std::abs(now - (left + right) * 0.5) < 1e-7;
            }
        }
    } else {
        ok = writeFxTcpRawValue(desired);
    }
    suppressPutSpeech_ = false;
    if (!ok) { speech_("Value unavailable or outside host range"); return; }
    numericEditing_ = false;
    // The focused Win32 EDIT already confirmed the value; avoid a second
    // parameter/CC/Auto announcement after the field closes.
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
    const double scale = std::pow(2.0, memory_.step(fxTcpStepKey()));
    if (known && std::isfinite(step) && step > 0.0 && step <= 1.0) {
        // The host reports discrete steps in normalized coordinates. Snap to
        // the nearest step before moving, avoiding stuck combo/menu values.
        const double increments = std::max(1.0, std::round(scale));
        const double next = (std::round(old / step) + direction * increments) * step;
        writeFxTcpValue(next);
        return;
    }
    // Conservative JSFX discrete fallback: only when the exposed raw range
    // is a small integer domain, with an integer current value. A regular
    // 0..1 continuous parameter must NEVER be treated as a binary switch.
    if (TrackFX_GetParam) {
        double low = 0.0, high = 1.0;
        const double raw = TrackFX_GetParam(track_, column->fxIndex, param->index, &low, &high);
        if (std::isfinite(raw) && std::isfinite(low) && std::isfinite(high) &&
            high - low >= 2.0 && high - low <= 64.0 &&
            std::abs(low - std::round(low)) < 1e-7 &&
            std::abs(high - std::round(high)) < 1e-7 &&
            std::abs(raw - std::round(raw)) < 1e-7) {
            const double amount = std::max(1.0, std::round((coarse ? 5.0 : 1.0) * scale));
            writeFxTcpRawValue(std::clamp(std::round(raw) + direction * amount, low, high));
            return;
        }
    }
    step = coarse ? 0.01 : 0.001;
    writeFxTcpValue(old + direction * step * scale);
}

// Never address an FX by a stale column index after REAPER reordered its chain.
bool TrackNavigator::fxTcpSelectedIdentityValid() const {
    const auto* column = currentFxTcpColumn();
    if (!project_ || !track_ || !ValidatePtr2(project_, track_, "MediaTrack*") ||
        !column || !TrackFX_GetFXGUID || !TrackFX_GetCount ||
        column->fxIndex < 0 || column->fxIndex >= TrackFX_GetCount(track_)) return false;
    const GUID* live = TrackFX_GetFXGUID(track_, column->fxIndex);
    return live && std::memcmp(live, &column->guid, sizeof(GUID)) == 0;
}
void TrackNavigator::toggleFxTcpBypass() {
    rebuildFxTcp(true);
    if (!fxTcpSelectedIdentityValid() || !TrackFX_GetEnabled || !TrackFX_SetEnabled) {
        speech_("FX no longer available"); return;
    }
    const int fx = currentFxTcpColumn()->fxIndex;
    const bool before = TrackFX_GetEnabled(track_, fx);
    if (Undo_BeginBlock2) Undo_BeginBlock2(project_);
    TrackFX_SetEnabled(track_, fx, !before);
    if (Undo_EndBlock2) Undo_EndBlock2(project_, "LReaParams: F4 toggle FX bypass", UNDO_STATE_FX);
    if (TrackFX_GetEnabled(track_, fx) == before) { speech_("Bypass not changed"); return; }
    speech_(before ? "Bypassed" : "Enabled");
}
void TrackNavigator::toggleFxTcpDeltaSolo() {
    rebuildFxTcp(true);
    if (!fxTcpSelectedIdentityValid() || !TrackFX_GetNumParams ||
        !TrackFX_GetParamName || !TrackFX_GetParamNormalized ||
        !TrackFX_SetParamNormalized) { speech_("FX no longer available"); return; }
    const int fx = currentFxTcpColumn()->fxIndex;
    const int count = TrackFX_GetNumParams(track_, fx);
    if (count <= 0) { speech_("Delta Solo unavailable for this FX"); return; }
    const int param = count - 1;
    char label[256]{};
    if (!TrackFX_GetParamName(track_, fx, param, label, sizeof(label))) {
        speech_("Delta Solo unavailable for this FX"); return;
    }
    // Only REAPER's special final wrapper parameter, never an ordinary knob.
    std::string name(label);
    std::transform(name.begin(), name.end(), name.begin(), [](unsigned char c) {
        return static_cast<char>(std::tolower(c));
    });
    if (name != "delta" && name != "delta solo") {
        speech_("Delta Solo unavailable for this FX"); return;
    }
    const double old = TrackFX_GetParamNormalized(track_, fx, param);
    const double target = old > .5 ? 0.0 : 1.0;
    if (Undo_BeginBlock2) Undo_BeginBlock2(project_);
    const bool ok = TrackFX_SetParamNormalized(track_, fx, param, target);
    if (TrackFX_EndParamEdit) TrackFX_EndParamEdit(track_, fx, param);
    if (Undo_EndBlock2) Undo_EndBlock2(project_, "LReaParams: F4 Delta Solo", UNDO_STATE_FX);
    if (!ok || (TrackFX_GetParamNormalized(track_, fx, param) > .5) != (target > .5)) {
        speech_("Delta Solo not changed"); return;
    }
    speech_(target > .5 ? "Delta Solo on" : "Delta Solo off");
}
void TrackNavigator::moveFxTcpFx(int direction) {
    rebuildFxTcp(true);
    if (!fxTcpSelectedIdentityValid() || !TrackFX_CopyToTrack ||
        !Undo_BeginBlock2 || !Undo_EndBlock2 ||
        !TrackFX_GetFXGUID) { speech_("FX cannot be moved"); return; }
    const int from = currentFxTcpColumn()->fxIndex;
    const int total = TrackFX_GetCount(track_);
    const int to = from + direction;
    if (to < 0 || to >= total) return; // silent edge
    // REAPER's CopyToTrack move indexes follow the current chain, not
    // the displayed TCP parameter order. Verify the FX GUID after moving.
    const GUID moving = currentFxTcpColumn()->guid;
    Undo_BeginBlock2(project_);
    TrackFX_CopyToTrack(track_, from, track_, to, true);
    Undo_EndBlock2(project_, "LReaParams: F4 move FX", UNDO_STATE_FX);
    rebuildFxTcp(true);
    for (int i = 0; i < static_cast<int>(fxTcpColumns_.size()); ++i) {
        if (std::memcmp(&fxTcpColumns_[static_cast<size_t>(i)].guid, &moving, sizeof(GUID)) != 0) continue;
        fxTcpColumn_ = i;
        fxTcpRow_ = std::clamp(fxTcpRow_, fxTcpHeight() > 1 ? 1 : 0, fxTcpHeight() - 1);
        rememberFxTcpPosition();
        speech_(fxTcpReview(true));
        return;
    }
    speech_("Moved FX not found");
}
void TrackNavigator::removeCurrentFxTcpControl() {
    rebuildFxTcp(true);
    if (fxTcpRow_ == 0) return; // Delete never deletes an FX header / the FX.
    if (!fxTcpSelectedIdentityValid()) { speech_("FX no longer available"); return; }
    const auto* col = currentFxTcpColumn();
    const auto* p = currentFxTcpParameter();
    if (!col || !p) return;
    const int fx = col->fxIndex, param = p->index;
    if (!fxTcpParameterVisible(fx, param)) { speech_("TCP parameter no longer visible"); return; }
    if (!setFxTcpParameterVisible(fx, param, false)) {
        speech_("TCP parameter not removed"); return;
    }
    rebuildFxTcp(true);
    rememberFxTcpPosition();
    speech_("TCP parameter removed. " + fxTcpReview(false));
}

void TrackNavigator::handleFxTcpKey(const Key& k) {
    if (numericEditing_) {
        if (!k.repeat && k.vk == VK_RETURN) commitFxTcpNumericEdit();
        else if (!k.repeat && k.vk == VK_ESCAPE) {
            numericEditing_ = rangeEditing_ = false;
            // No change to FX and no automatic exit from F4.
            speech_("Edit cancelled. " + fxTcpReview(false));
        }
        return;
    }
    if (filterEditing_) {
        if (k.repeat) return;
        if (k.vk == VK_RETURN) applyFxTcpFilter();
        else if (k.vk == VK_ESCAPE || (k.ctrl && !k.shift && !k.alt && k.vk == 'F')) cancelFxTcpFilter();
        return;
    }
    // The names-only TCP addition grid must never start learn/edit MIDI.
    if (fxTcpListOpen_) { handleFxTcpParameterGridKey(k); return; }
    if ((k.ctrl && k.alt && !k.shift && k.vk == 'C') ||
        (!k.ctrl && !k.alt && k.shift && k.vk == 'C') ||
        (k.ctrl && !k.alt && k.shift && k.vk == 'C') ||
        (k.ctrl && !k.alt && !k.shift && k.vk == VK_DELETE)) {
        if (!k.repeat) midiShortcut(k);
        return;
    }
    if (k.vk == VK_ESCAPE && learnCc_) {
        learnCc_ = false; learnSection_.clear(); learnKey_.clear(); learnIdentity_.clear();
        speech_("CC learn cancelled"); return;
    }
    if (k.ctrl && !k.alt && k.vk == 'T') {
        if (k.repeat || !currentFxTcpParameter()) return;
        if (k.shift) {
            const auto key = fxTcpStepKey();
            const bool on = !memory_.valueSpeech(key);
            memory_.setValueSpeech(key, on); memory_.flush();
            speech_(on ? "Value speech on" : "Value speech off");
        } else {
            std::string id;
            if (!midiFixedIdentity(id)) { speech_("MIDI speech target unavailable"); return; }
            const bool on = !memory_.fixedCcSpeech(id);
            memory_.setFixedCcSpeech(id, on); memory_.flush();
            speech_(on ? "MIDI speech on" : "MIDI speech off");
        }
        return;
    }
    if (k.ctrl && !k.shift && !k.alt && k.vk == 'E') {
        if (!k.repeat) beginFxTcpNumericEdit();
        return;
    }
    if (k.ctrl && !k.shift && !k.alt && k.vk == 'F') {
        if (!k.repeat) toggleFxTcpFilter();
        return;
    }
    if (k.ctrl && !k.shift && !k.alt && k.vk == 'B') {
        if (!k.repeat) toggleFxTcpBypass();
        return;
    }
    if (k.ctrl && !k.shift && !k.alt && k.vk == 'D') {
        if (!k.repeat) toggleFxTcpDeltaSolo();
        return;
    }
    // Unified FX reorder gesture in both navigators: Ctrl+PageUp/Down.
    // Ctrl+Shift+Up/Down remains reserved for changing tracks.
    if (k.ctrl && !k.shift && !k.alt && (k.vk == VK_PRIOR || k.vk == VK_NEXT)) {
        if (!k.repeat) moveFxTcpFx(k.vk == VK_PRIOR ? -1 : 1);
        return;
    }
    if (k.ctrl && k.shift && !k.alt && k.vk == 'A') {
        if (!k.repeat) toggleFxTcpAutomation();
        return;
    }
    if (k.ctrl && k.shift && k.alt && !k.altGr && k.vk == 'A') {
        if (!k.repeat) {
            clearAutomationYes_ = false;
            clearAutomationConfirm_ = true;
            speech_("Disable all automation on current track, including send envelopes and FX? No selected. Left and Right choose Yes or No. Enter accepts, Y confirms, N or Escape cancels");
        }
        return;
    }
    if (!k.ctrl && !k.alt && !k.shift && k.vk == VK_DELETE) {
        if (!k.repeat) removeCurrentFxTcpControl();
        return;
    }
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
    if (k.ctrl && k.shift && !k.alt && (k.vk == VK_UP || k.vk == VK_DOWN)) {
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
    if (k.ctrl && !k.shift && !k.alt && (k.vk == VK_UP || k.vk == VK_DOWN)) {
        if (!k.repeat) {
            rebuildFxTcp(true);
            moveFxTcpColumn(k.vk == VK_UP ? -1 : 1);
        }
        return;
    }
    if (!k.ctrl && !k.alt && !k.shift && k.vk == VK_F5) {
        if (!k.repeat) enterPinAudio();
        return;
    }
    if (k.vk == VK_F4) return;
    if (k.vk == VK_F1) { valueMode_ = false; selectPage(Page::tracks); return; }
    if (k.vk == VK_F2) { valueMode_ = false; selectPage(Page::sends); return; }
    if (k.vk == VK_F3) { valueMode_ = false; selectPage(Page::receives); return; }
    if (k.vk == VK_ESCAPE) {
        if (valueMode_) { valueMode_ = false; speech_("Grid, " + fxTcpReview(false)); }
        else if (!fxTcpMainFilter_.empty()) clearFxTcpFilter();
        else selectPage(Page::tracks);
        return;
    }
    // Alt+Enter opens the names-only grid for adding TCP controls from
    // ANY F4 cell, including an FX with no controls yet.
    if (k.alt && !k.ctrl && !k.shift && k.vk == VK_RETURN) {
        if (!k.repeat) { rebuildFxTcp(true); openFxTcpParameterGrid(false); }
        return;
    }
    if (k.vk == VK_F6 && !k.ctrl && !k.shift && !k.alt) return;
    if (k.vk == VK_RETURN && !k.ctrl && !k.alt && !k.shift) {
        if (!k.repeat) {
            if (currentFxTcpParameter()) {
                valueMode_ = !valueMode_;
                speech_(std::string(valueMode_ ? "Value, " : "Grid, ") + fxTcpReview(false));
            } else speech_("No TCP parameters. Press Alt+Enter to add");
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
    if (valueMode_ && !k.ctrl && !k.shift &&
        (k.vk == VK_HOME || k.vk == VK_END)) {
        writeFxTcpValue(k.vk == VK_HOME ? 1.0 : 0.0);
        return;
    }
    // Alt+Home/End ALWAYS changes the value, including in Grid mode.
    // Ctrl+Home/End instead navigates to the first/last TCP parameter.
    if (!k.ctrl && !k.shift && k.alt &&
        (k.vk == VK_HOME || k.vk == VK_END)) {
        if (!k.repeat) writeFxTcpValue(k.vk == VK_HOME ? 1.0 : 0.0);
        return;
    }
    if (k.vk == VK_TAB && !k.ctrl && !k.alt && !k.shift) {
        if (!k.repeat) {
            const std::string key = fxTcpStepKey();
            std::string id;
            const bool ccSpeaking = midiFixedIdentity(id) && memory_.fixedCcSpeech(id);
            speech_((valueMode_ ? "Value, " : "") + fxTcpReview(true) +
                (key.empty() ? "" : ". Step " + std::to_string(memory_.step(key))) +
                (key.empty() ? "" : (memory_.valueSpeech(key) ? ". Value speech on" : ". Value speech off")) +
                (ccSpeaking ? ". MIDI speech on" : ". MIDI speech off"));
        }
        return;
    }
    if (valueMode_) return; // ordinary arrows do not navigate the active Value slider
    // Re-query the TCP API after external FX / TCP configuration edits.
    // Reattach to the GUID and parameter ID, not a now-stale column index.
    rebuildFxTcp(true);
    if (fxTcpColumns_.empty()) { speech_("No track FX"); selectPage(Page::tracks); return; }
    if (k.ctrl && !k.alt && !k.shift && (k.vk == VK_HOME || k.vk == VK_END)) {
        const int count = fxTcpHeight() - 1;
        if (count > 0) moveFxTcpRow((k.vk == VK_HOME ? 1 : count) - fxTcpRow_);
        return;
    }
    if (k.ctrl || k.alt || k.shift) return;
    // Normal arrows never change FX: only navigate the current 8-high grid.
    moveFxTcpGrid(k.vk);
}
} // namespace lrp
