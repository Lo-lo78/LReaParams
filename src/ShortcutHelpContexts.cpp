#include "lrp/FxNavigator.h"
#include "lrp/TrackNavigator.h"
#include "lrp/KeyboardTheme.h"

namespace lrp {
namespace {
bool plain(const Key& k) { return !k.ctrl && !k.alt && !k.shift && !k.altGr; }
bool arrow(UINT vk) { return vk == VK_UP || vk == VK_DOWN || vk == VK_LEFT || vk == VK_RIGHT; }
bool navigation(UINT vk) { return arrow(vk) || vk == VK_PRIOR || vk == VK_NEXT ||
                                  vk == VK_HOME || vk == VK_END; }
const char* navigateLabel(UINT vk) {
    switch (vk) {
    case VK_UP: return "up"; case VK_DOWN: return "down";
    case VK_LEFT: return "left"; case VK_RIGHT: return "right";
    case VK_PRIOR: return "Page Up"; case VK_NEXT: return "Page Down";
    case VK_HOME: return "first"; case VK_END: return "last";
    default: return "";
    }
}
}
std::string FxNavigator::shortcutDescription(const Key& k) const {
    // Invoked only for effective, accepted keys. Never use handle(), SetFocus,
    // state setters, REAPER actions or a temporary remapped navigator.
    if (clearAutomationConfirm_ || defaultConfirm_) {
        if (plain(k) && (k.vk == 'Y' || k.vk == 'N' || k.vk == VK_RETURN || k.vk == VK_ESCAPE))
            return "Respond to the current LReaParams confirmation";
        if (plain(k) && (arrow(k.vk) || k.vk == VK_TAB))
            return "Review the current LReaParams confirmation";
        return "No active shortcut while the confirmation is open";
    }
    if (gridNumericEdit_ || numericEdit_ || textEdit_ || searchMode_) {
        if (plain(k) && k.vk == VK_RETURN) return "Confirm the current edit or search";
        if (plain(k) && k.vk == VK_ESCAPE) return "Cancel the current edit or search";
        if (searchMode_ && plain(k) && arrow(k.vk)) return "Navigate search matches";
        if (plain(k) && k.character) return "Text entry in the current LReaParams field";
        return "No documented LReaParams command in this editing context";
    }
    if (pinAudioMode_ && plain(k) && navigation(k.vk))
        return std::string("Navigate FX audio pin connector: ") + navigateLabel(k.vk);
    if (fxBrowserMode_ && plain(k) && navigation(k.vk))
        return std::string("Navigate FX browser: ") + navigateLabel(k.vk);
    if (memoryManager_ && plain(k) && navigation(k.vk))
        return std::string("Navigate FX Memories: ") + navigateLabel(k.vk);
    if (recentMode_ && plain(k) && navigation(k.vk))
        return std::string("Navigate recent parameter searches: ") + navigateLabel(k.vk);
    if (k.alt && !k.ctrl && !k.shift && !k.altGr && !pinAudioMode_ && !fxBrowserMode_ &&
        !memoryManager_ && !recentMode_) {
        if (k.vk == 'R') return "Edit current parameter range";
        if (k.vk == 'C') return "Edit current fixed MIDI CC range";
        if (k.vk == 'F') return "Edit current floating MIDI CC range";
    }
    if (usedActive_ && k.ctrl && !k.alt && k.vk == 'L')
        return k.shift ? "Toggle Used parameters view" : "Exit Used parameters view";
    if (keyboardThemeActive()) {
        if (plain(k)) {
            const int index = keyboard::offset(k.vk);
            if (index >= 0) {
                const int target = keyboard::keyTarget(viewPos_, index, static_cast<int>(visible_.size()));
                if (target < 0) return "No parameter assigned to this key on the current keyboard page";
                return "Focus parameter " + std::to_string(target + 1) + " on the current keyboard page";
            }
        }
        if (k.alt && !k.ctrl && !k.shift && (k.vk == VK_UP || k.vk == VK_DOWN))
            return k.vk == VK_UP ? "Previous keyboard page" : "Next keyboard page";
    }
    if (editF7_ && plain(k) && navigation(k.vk))
        return std::string("Navigate F7 parameter editor: ") + navigateLabel(k.vk);
    if ((valueMode_ || keyboardThemeActive()) && plain(k) && navigation(k.vk))
        return std::string("Adjust current parameter: ") + navigateLabel(k.vk);
    if (plain(k) && navigation(k.vk))
        return std::string("Navigate current parameter grid: ") + navigateLabel(k.vk);
    if (plain(k) && k.character && !valueMode_ && !editF7_ && !pinAudioMode_ &&
        !fxBrowserMode_ && !memoryManager_)
        return "Jump to parameter by its initial character";
    if (plain(k) && k.vk == VK_ESCAPE)
        return valueMode_ ? "Exit Value mode" : editF7_ ? "Leave F7 editor" : "Exit current FX navigation context";
    return {};
}
std::string TrackNavigator::shortcutDescription(const Key& k) const {
    if (clearAutomationConfirm_) {
        if (plain(k) && (k.vk == 'Y' || k.vk == 'N' || k.vk == VK_RETURN || k.vk == VK_ESCAPE))
            return "Respond to the current automation confirmation";
        if (plain(k) && (arrow(k.vk) || k.vk == VK_TAB))
            return "Review automation confirmation choices";
        return "No active shortcut while the confirmation is open";
    }
    if (filterEditing_ || numericEditing_) {
        if (plain(k) && k.vk == VK_RETURN) return "Confirm current text entry";
        if (plain(k) && k.vk == VK_ESCAPE) return "Cancel current text entry";
        if (plain(k) && k.character) return "Text entry in current LReaParams field";
        return "No documented LReaParams command in this editing context";
    }
    if (k.alt && !k.ctrl && !k.shift && !k.altGr && !memoryManager_) {
        if (k.vk == 'R') return "Edit current parameter range";
        if (k.vk == 'C') return "Edit current fixed MIDI CC range";
        if (k.vk == 'F') return "Edit current floating MIDI CC range";
    }
    if (memoryManager_ && plain(k) && navigation(k.vk))
        return std::string("Navigate Track Memories: ") + navigateLabel(k.vk);
    if (page_ == Page::fxTcp) {
        if (plain(k) && navigation(k.vk))
            return std::string(fxTcpListOpen_ ? "Navigate FX TCP parameter list: " : "Navigate FX TCP grid: ") + navigateLabel(k.vk);
        if (plain(k) && k.vk == VK_F1 && fxTcpListOpen_) return "Decrease FX TCP list grid height";
        if (plain(k) && k.vk == VK_F2 && fxTcpListOpen_) return "Increase FX TCP list grid height";
    }
    if ((page_ == Page::trackMidi || page_ == Page::hardwareOutputs || page_ == Page::reaRoute) &&
        plain(k) && navigation(k.vk)) {
        const char* page = page_ == Page::trackMidi ? "Track MIDI" :
                           page_ == Page::hardwareOutputs ? "Hardware outputs" : "ReaRoute";
        return std::string("Navigate ") + page + ": " + navigateLabel(k.vk);
    }
    if ((page_ == Page::sends || page_ == Page::receives) && plain(k)) {
        if (k.vk == VK_LEFT || k.vk == VK_RIGHT)
            return std::string("Move through ") + (page_ == Page::sends ? "send" : "receive") + " columns";
        if (k.vk == VK_UP || k.vk == VK_DOWN || k.vk == VK_PRIOR || k.vk == VK_NEXT)
            return std::string("Move through ") + (page_ == Page::sends ? "send" : "receive") + " parameters";
        if (k.vk == VK_DELETE) return "Delete current routing";
    }
    if (page_ == Page::tracks && plain(k)) {
        if (k.character && !valueMode_) return "Jump to track by initial character";
        if (k.vk == VK_LEFT || k.vk == VK_RIGHT) return "Move between track parameters";
        if (k.vk == VK_UP || k.vk == VK_DOWN || k.vk == VK_PRIOR || k.vk == VK_NEXT)
            return "Navigate tracks";
    }
    if (plain(k) && k.vk == VK_RETURN && !memoryManager_) {
        if (valueMode_) return "Exit Value mode";
        if (page_ == Page::tracks) {
            if (const auto* entry = current()) {
                if (entry->type == Entry::flag || entry->type == Entry::solo ||
                    entry->type == Entry::midiFollowsFader)
                    return "Toggle " + entry->title;
                if (entry->type == Entry::sendCount) return "Open Sends page";
                if (entry->type == Entry::receiveCount) return "Open Receives page";
                if (entry->type == Entry::fxCount) return "Open FX TCP page";
            }
        }
        return "Open Value mode or activate the current control";
    }
    if (plain(k) && k.vk == VK_ESCAPE)
        return valueMode_ ? "Exit Value mode" : page_ != Page::tracks ?
            "Return to Tracks page" : "Exit Track Params";
    return {};
}
} // namespace lrp
