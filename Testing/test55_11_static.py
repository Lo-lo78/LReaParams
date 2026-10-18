"""TEST55.11: accessible automation confirmation in both native navigators.
Only verifies source contracts; REAPER and NVDA must be checked after CI build.
"""
from pathlib import Path
root = Path(__file__).resolve().parents[1]
fx = (root/'src/FxNavigator.cpp').read_text(encoding='utf-8')
track = (root/'src/TrackNavigator.cpp').read_text(encoding='utf-8')
fa = (root/'src/FxNavigatorAdvanced.cpp').read_text(encoding='utf-8')
fxh = (root/'include/lrp/FxNavigator.h').read_text(encoding='utf-8')
th = (root/'include/lrp/TrackNavigator.h').read_text(encoding='utf-8')
title = (root/'src/TitleProxy.cpp').read_text(encoding='utf-8')
ext = (root/'src/Extension.cpp').read_text(encoding='utf-8')
for label, code, header in [('FX',fx,fxh),('Track',track,th)]:
    assert 'bool clearAutomationYes_ = false;' in header, label
    assert 'if (clearAutomationConfirm_)' in code, label
    assert 'clearAutomationYes_ ? "Yes selected" : "No selected"' in code, label
    assert 'k.vk == VK_LEFT || k.vk == VK_RIGHT' in code, label
    assert 'speech_(yes ? "Yes" : "No")' in code, label
    assert 'k.vk == VK_TAB' in code and 'speech_(reviewLine());' in code, label
    assert "k.vk == 'Y' || (k.vk == VK_RETURN && clearAutomationYes_)" in code, label
    assert "k.vk == 'N' || k.vk == VK_ESCAPE || k.vk == VK_RETURN" in code, label
    assert 'clearAutomationYes_ = false;' in code, label
    assert 'if (k.ctrl || k.alt) return;' in code, label
assert fx.index('if (clearAutomationConfirm_)\n        return std::string') < fx.index('if (memoryManager_) return memoryReview();')
assert track.index('if (clearAutomationConfirm_)\n        return std::string') < track.index('if (memoryManager_) {\n        if (memoryItems_.empty())')
assert track.index('if (clearAutomationConfirm_) {',track.index('void TrackNavigator::handle(')) < track.index('if (memoryManager_) { handleMemory(k); return; }')
assert track.index('if (clearAutomationConfirm_) {',track.index('void TrackNavigator::handle(')) < track.index('k.vk == VK_TAB',track.index('void TrackNavigator::handle('))
assert 'valueMode_ && !clearAutomationConfirm_' in fxh
assert '!valueMode_ || clearAutomationConfirm_' in track
assert 'clearAutomationYes_ = false;\n            clearAutomationConfirm_ = true;' in fa
assert 'clearAutomationYes_ = false;\n            clearAutomationConfirm_ = true;' in track
assert 'if (newReview != oldReview) titleProxy_.updateReviewLine(newReview);' in ext
assert 'if (msg == WM_GETTEXT)' in title and 'SetFocus(edit_);' in title
assert 'toggleEnvelope(true);' in fx
assert 'clearTrackAutomations();' in track
print('TEST55.11 accessible automation review/Yes-No state contracts PASS; runtime untested')
