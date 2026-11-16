"""TEST70.1: Lossless FX Type / Name preference split and legacy INI migration."""
from pathlib import Path
r = Path(__file__).resolve().parents[1]
s = (r/'src/Preferences.cpp').read_text(encoding='utf-8')
h = (r/'include/lrp/Preferences.h').read_text(encoding='utf-8')
# TEST70.2 expanded capacity to six for the independent Track F4 Mode field.
# The FX templates remain five-part and retain their IDs and INI encoding.
assert 'std::array<int, 6> order' in h and 'std::array<bool, 6> enabled' in h
assert 'L"Name", L"Track", L"Custom message", L"Type"' in s
assert 'L"Track", L"Name", L"Custom message", L"Type"' in s
assert 'if (count == 5 && order.size() == 4)' in s
assert 'if (count == 5 && enabled.size() == 4)' in s
assert 'cfg.enabled[4] = false;' in s
assert 'p.fxTitle.order = {{0, 4, 1, 2, 3}}' in s
assert 'splitReaperFxName(fx)' in s
assert 'return {{}, raw};' in s
assert 'loadTitle(path, L"FxTitle", p.fxTitle, 5)' in s
assert 'saveTitle(path, L"FxTitle", p.fxTitle, 5)' in s
print('TEST70.1 FX Type / Name and migrated templates PASS')
