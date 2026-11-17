"""TEST72.4: title and parameter are in the same native focus text."""
from pathlib import Path
root = Path(__file__).resolve().parents[1]
src = (root/'src/TitleProxy.cpp').read_text(encoding='utf-8')
ext = (root/'src/Extension.cpp').read_text(encoding='utf-8')
assert 'reviewText_ = title_ + L". " + reviewText_;' in src
assert 'if (reviewText_.empty()) reviewText_ = title_;' in src
assert src.index('reviewText_ = title_ + L". " + reviewText_;') < src.index('SetFocus(edit_);')
assert 'if (!titleProxyActive_) {' in ext
assert 'titleProxy_.activate(' in ext
print('TEST72.4 native title+parameter focus text PASS')
