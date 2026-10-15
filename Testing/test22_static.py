"""TEST22 — Navigation and status contracts, source-only (no build)."""
from pathlib import Path
r=Path(__file__).resolve().parents[1]
fx=(r/'src/FxNavigator.cpp').read_text()
f7=(r/'src/FxNavigatorOrder.cpp').read_text()
f8=(r/'src/FxNavigatorMemories.cpp').read_text()
h=(r/'include/lrp/FxNavigator.h').read_text()
# Standard order: Ctrl+Home global first; Ctrl+End global last.
assert 'if (k.ctrl && !k.shift && !k.alt && k.vk==VK_HOME){navigate(-viewPos_);return;}' in fx
assert 'if (k.ctrl && !k.shift && !k.alt && k.vk==VK_END){navigate(static_cast<int>(visible_.size())-1-viewPos_);return;}' in fx
assert 'if(k.vk==VK_HOME){navigate(start-viewPos_);return;}' in fx
assert 'if(k.vk==VK_END){navigate(end-viewPos_);return;}' in fx
assert 'if (k.vk == VK_HOME) setValue(1)' in fx
assert 'if (k.vk == VK_END) setValue(0)' in fx
assert 'else if(k.vk==VK_HOME)target=start;' in f7
assert 'else if(k.vk==VK_END)target=end;' in f7
assert 'for(int c=k.vk==VK_HOME?0:6;c>=0&&c<7;c+=(k.vk==VK_HOME?1:-1))' in f8
assert 'memoryCol_=c;memoryRow_=k.vk==VK_HOME?0:' in f8
assert 'if(k.vk==VK_HOME)target=0;' in f8
assert 'else if(k.vk==VK_END)target=size-1;' in f8
assert 'Lua Home/End intentionally reversed' not in f8
# One status data source, consistent UI and FX change announcements.
assert 'bool FxNavigator::deltaSoloActive() const' in fx
assert 'return value > 0.5;' in fx
assert 'if (bypassed && delta) return "Bypassed - Delta Solo";' in fx
assert 'if (isBypassed()) message += "Bypassed. ";' in fx
assert 'if (deltaSoloActive()) message += "Delta Solo. ";' in fx
assert 'fxContextAnnouncement()' in h
assert fx.count('speech_(fxContextAnnouncement());')==2
assert 'fxWindowTitleBase(bool memories) const' in fx
assert 'status.empty() ? " - " : ". " + status + ". "' in fx
assert 'speech_(fxWindowTitleBase() + ". " + currentParameterSpeech());' in fx
assert 'if (memoryManager_) return wideUtf8(fxWindowTitleBase(true));' in fx
assert 'while (visibleName.size() > 1' in fx
assert 'project(LReaParams VERSION ' in (r/'CMakeLists.txt').read_text()
print('TEST22 source contracts PASS — host behavior not tested')
