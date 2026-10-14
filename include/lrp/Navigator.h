#pragma once
#include <windows.h>
#include <string>
#include <utility>
#include <functional>

namespace lrp {
struct Key { UINT vk{}; bool ctrl{}, alt{}, shift{}, repeat{}; HWND window{}; };
// All native navigators share one input owner. No control uses a hidden window.
class Navigator {
public:
    virtual ~Navigator() = default;
    virtual bool begin() = 0;
    virtual void end() noexcept = 0;
    virtual bool active() const noexcept = 0;
    virtual bool contextUnchanged() const = 0;
    virtual bool accepts(const Key&) const noexcept = 0;
    virtual void handle(const Key&) = 0;
    virtual void announce() = 0;
    virtual void announceTitle() = 0; // one OSARA announcement at mode entry
    virtual std::wstring windowTitle() const = 0; // NVDA+T via offscreen title proxy
    virtual HWND floatingWindow() const { return nullptr; }
    virtual bool uiStillOpen() const { return true; }
};
}
