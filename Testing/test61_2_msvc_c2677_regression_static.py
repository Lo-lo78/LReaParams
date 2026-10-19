"""TEST61.2: guard against MSVC C2677 introduced by duplicated page_ equality."""
from pathlib import Path
import re
root = Path(__file__).resolve().parents[1]
src = (root / 'src' / 'TrackNavigator.cpp').read_text(encoding='utf-8')
for name, expected in (
    ('nativeValueSlider', 'return false;'),
    ('valueFraction', 'return 0.0;'),
    ('sliderLabel', 'return "";'),
):
    signature = ('bool ' if name == 'nativeValueSlider' else
                 'double ' if name == 'valueFraction' else 'std::string ')
    start = src.index(signature + 'TrackNavigator::' + name + '() const {')
    body = src[start:src.index('\n}', start)]
    expected_line = ('if (page_ == Page::trackMidi || page_ == Page::hardwareOutputs '
                     '|| page_ == Page::reaRoute) ' + expected)
    assert expected_line in body, f'{name}: incorrect page guard'
# Catch an entire class of copy/paste errors before reaching the MSVC build step.
for cpp in (root / 'src').rglob('*.cpp'):
    text = cpp.read_text(encoding='utf-8')
    assert not re.search(r'\b([a-zA-Z_]\w*)\s*==\s*\1\s*==', text), cpp
print('PASS TEST61.2: corrected page comparisons, no duplicate equality chains')
