#pragma once
#include <windows.h>
#include <string>
#include <utility>
#include <functional>

namespace lrp {
// character is the printable character produced by the active keyboard layout,
// captured at key-down (not the virtual-key numeric code). It stays empty for
// non-text gestures such as arrows, F keys, Ctrl+shortcuts and dead keys.
struct Key { UINT vk{}; bool ctrl{}, alt{}, shift{}, repeat{}; HWND window{}; wchar_t character{}; bool altGr{}; };
// All native navigators share one owned, offscreen keyboard window.
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
    virtual std::wstring windowTitle() const = 0; // NVDA+T
    virtual std::string reviewLine() const = 0; // accessible parameter and value on request
    virtual bool nativeValueSlider() const { return false; }
    virtual double valueFraction() const { return 0.0; } // 0..1, for native slider only
    virtual std::string sliderLabel() const { return {}; }
    virtual HWND floatingWindow() const { return nullptr; }
    virtual bool uiStillOpen() const { return true; }
};
}
