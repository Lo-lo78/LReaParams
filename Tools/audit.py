"""Source-only checks: never invoke CMake, compilers, Lua, or native binaries."""
from pathlib import Path
import csv
import json
import hashlib
import re
import sys
from collections import Counter
from profile_oracle import parse_legacy, encode, decode
ROOT = Path(__file__).resolve().parents[1]


def check(ok, message):
    if not ok: raise RuntimeError(message)


def corpus(path, expected=True):
    counts = Counter()
    for p in path.rglob('*.txt'):
        original = p.read_bytes(); parsed = parse_legacy(original); counts[parsed[0]] += 1
        restored = decode(encode(original))
        check(restored == original and parse_legacy(restored) == parsed, 'Roundtrip mismatch')
    if expected: check(counts == {'FX':48,'PP':3,'TRACK':4}, 'All 55 profiles required')
    print('Python oracle roundtrip:', dict(counts), 'PASS')


def reject(data):
    try: parse_legacy(data)
    except (ValueError, KeyError, UnicodeError): return
    raise RuntimeError('Invalid profile accepted by Python oracle')


def main():
    for p in ['CMakeLists.txt','.github/workflows/build-windows.yml','src/Extension.cpp','src/InputRouter.cpp','src/FxNavigator.cpp','src/Profile.cpp','src/Storage.cpp','Testing/ProfileTests.cpp']:
        check((ROOT/p).is_file() and (ROOT/p).stat().st_size > 0, 'Required source missing: '+p)
    sdk=ROOT/'third_party/reaper-sdk'
    manifest=json.loads((sdk/'manifest.json').read_text())
    for name,digest in manifest['files'].items():
        check(hashlib.sha256((sdk/name).read_bytes()).hexdigest()==digest,'SDK bytes changed')
    header=(ROOT/'include/lrp/ReaperApi.h').read_text()
    api=(sdk/'reaper_plugin_functions.h').read_text()
    for name in re.findall(r'#define REAPERAPI_WANT_(\w+)',header):
        check('REAPERAPI_FUNCNAME('+name+')' in api,'Unknown SDK API '+name)
    rows=list(csv.DictReader((ROOT/'Docs/LuaManifest.csv').open(encoding='utf-8-sig')))
    check(sum(int(r['lines']) for r in rows)==68512,'Lua line count changed')
    for row in rows:
        check(hashlib.sha256((ROOT/'Legacy'/row['file']).read_bytes()).hexdigest()==row['sha256'],'Original Lua changed')
    all_cpp='\n'.join(p.read_text() for p in (ROOT/'src').glob('*.cpp'))
    for forbidden in [r'SetWindowsHookExW\(WH_KEYBOARD_LL',r'SetProjExtState\s*\(',r'SetExtState\s*\(']:
        check(not re.search(forbidden,all_cpp),'Unexpected window/global hook/state write')
    # One purpose-built offscreen title proxy is allowed; forbid other window creation.
    title_src=(ROOT/'src/TitleProxy.cpp').read_text()
    check(title_src.count('CreateWindowExW(')==3,'Expected titled owner, review label and native Value trackbar')
    for marker in ['WS_EX_TOOLWINDOW','-32000','SW_HIDE','DestroyWindow','UnregisterClassW','SetForegroundWindow','WM_KEYDOWN']:
        check(marker in title_src,'Title proxy lifecycle contract missing: '+marker)
    check('L"STATIC"' in title_src and 'SS_NOTIFY' in title_src and
          'WS_TABSTOP' in title_src and 'updateReviewLine' in title_src and
          'WM_GETDLGCODE' in title_src,
          'TEST11 focused non-editable text label missing')
    check('L"EDIT"' not in title_src and 'EM_SETSEL' not in title_src,
          'An EDIT caret would reintroduce NVDA character chatter')
    # TEST12: parameter text must be queryable by NVDA WITHOUT notifying it
    # of every move.  The Win32 focus owner must never change its text using
    # SetWindowTextW, which generates a second unsolicited accessibility event.
    check('if (msg == WM_GETTEXTLENGTH)' in title_src and
          'if (msg == WM_GETTEXT)' in title_src and
          'SetWindowTextW(edit_,' not in '\n'.join(line for line in title_src.splitlines()
                                        if not line.lstrip().startswith('//')),
          'Focused native text must be updated passively, not via name-change events')
    # TEST9 regression markers: the native session memory must survive end()/begin()
    # without accidentally writing to REAPER project state or legacy TXT files.
    fx_header=(ROOT/'include/lrp/FxNavigator.h').read_text()
    fx_source=(ROOT/'src/FxNavigator.cpp').read_text()
    for marker in ['sessionMemory_', 'StoredContext', 'StoredFxPosition',
                   'rememberPosition()', 'restoreParameterPosition()',
                   'rememberedFxIndex(', 'observedVisibleFx',
                   'lastFxOccurrence', 'lastFxGuid']:
        check(marker in fx_header or marker in fx_source,
              'Session FX memory contract missing: '+marker)
    check('SetExtState' not in fx_source and 'SetProjExtState' not in fx_source,
          'Session FX memory must not write REAPER state')
    # TEST10 source regressions: absolute value direction, quiet boundaries,
    # and focused non-editable accessible content (runtime behavior unverified).
    check('k.vk == VK_HOME) setValue(1)' in fx_source and
          'k.vk == VK_END) setValue(0)' in fx_source,
          'FX Alt+Home/End must use maximum/minimum in that order')
    check('const bool high = k.vk == VK_HOME' in (ROOT/'src/TrackNavigator.cpp').read_text(),
          'Track Alt+Home/End must use maximum/minimum in that order')
    check('if (next == viewPos_) return;' in fx_source and
          'if (next != parameter_)' in (ROOT/'src/TrackNavigator.cpp').read_text(),
          'Grid bounds must not reannounce unchanged selection')
    check('if (newReview != oldReview) titleProxy_.updateReviewLine(newReview);' in (ROOT/'src/Extension.cpp').read_text() and
          'if (newTitle != oldTitle || newReview != oldReview)' in (ROOT/'src/Extension.cpp').read_text(),
          'Boundary must not send redundant review/focus updates')
    check('desired->windowTitle(), desired->reviewLine()' in (ROOT/'src/Extension.cpp').read_text() and
          'reviewText_ = toWide(initialReviewLine)' in title_src,
          'Initial native text must be filled before focus')
    check('fxWindowTitleBase()' in fx_source and 'L"LReaParams - FX Params - "' not in fx_source,
          'FX NVDA+T title must not contain LReaParams')
    check('switchTrack(' in fx_source and 'SetOnlyTrackSelected(' in fx_source and
          'std::clamp(stepScale_' in fx_source and '-10, 10)' in fx_source,
          'TEST13 track switch and extended FX step range missing')
    check('TRACKBAR_CLASSW' in title_src and 'syncValueControl' in title_src and
          'switchOwnedWindow' in (ROOT/'src/InputRouter.cpp').read_text(),
          'TEST13 native accessible Value slider missing')
    track_src=(ROOT/'src/TrackNavigator.cpp').read_text()
    # TEST16: NVDA+Up uses the passive reviewLine, now parameter/value ONLY.
    # Moving tracks still speaks track context; explicit Ctrl+R stays full.
    check('void TrackNavigator::announce() { speech_(parameterValueSpeech()); }' in track_src and
          'row_ = next; track_ = rows_[row_].track; announceTrack();' in track_src and
          'if (!k.repeat) announceTrack();' in track_src and
          'if (!valueMode_) return parameterValueSpeech();' in track_src and
          'std::string TrackNavigator::reviewLine() const' in track_src,
          'TEST16 native NVDA Track review contract missing')
    check('if (valueMode_) speech_(reviewLine());' in fx_source and
          'void TitleProxy::syncValueControl' in title_src and
          'SetFocus(slider_);' in title_src and
          'titleProxy_.reassertFocusAfterNavigationKey();' in (ROOT/'src/Extension.cpp').read_text(),
          'TEST15 native FX Value focus handoff contract missing')
    check(track_src.count('entries_.push_back(')==14, 'F2/F3 must have 14 fields per column')
    for marker in ['moveDetailColumn', 'VK_RETURN', 'Entry::midiFollowsFader',
                   'detailIndex_ * detailHeight + parameter_', 'toggle(*e)']:
        check(marker in track_src, 'Track grid/Enter feature missing: '+marker)
    for cpp in (ROOT/'src').glob('*.cpp'):
        if cpp.name != 'TitleProxy.cpp':
            check(not re.search(r'CreateWindow(?:Ex)?[AW]?\s*\(',cpp.read_text()),'Unexpected window creation: '+cpp.name)
    check('PM_REMOVE' in all_cpp and 'CallNextHookEx' in all_cpp,'Thread hook lifecycle contract missing')
    # TEST6: the focus window owns the keys, without passing via the TCP.
    router=(ROOT/'src/InputRouter.cpp').read_text()
    extension=(ROOT/'src/Extension.cpp').read_text()
    check('enqueueOwnedKey' in router and 'InputBackend::ownedWindow' in router,
          'Owned window keyboard queue missing')
    check('enqueueOwnedKey' in extension and 'InputBackend::ownedWindow' in extension,
          'Owned window not connected to navigator')
    check('WM_SYSKEYDOWN' in title_src and 'keyboardKey_' in title_src and
          'DLGC_WANTALLKEYS' in title_src,
          'Window procedure keyboard ownership missing')
    check("k.vk == 'R'" in fx_source and "k.vk == 'R'" in (ROOT/'src/TrackNavigator.cpp').read_text(),
          'Explicit Ctrl+R parameter review missing')
    check('reassertFocusAfterNavigationKey' in title_src,
          'Post-parameter-change focus recovery missing')
    corpus(ROOT/'Testing/fixtures')
    if len(sys.argv)>1: corpus(Path(sys.argv[1]))
    reject(b'Version=3\n'); reject(b'Version=2\nOther=unknown\n'); reject(b'PARAMLIB_V1\nMode=handoff\n')
    sample=next((ROOT/'Testing/fixtures/Params').glob('*.txt')).read_bytes()
    reject(sample.replace(b'Mode=cell',b'Mode=return'))
    reject(re.sub(rb'Count=\d+',b'Count=999999',sample))
    fx=next((ROOT/'Testing/fixtures/Plugins').glob('*.txt')).read_bytes()
    reject(fx+b'\n[CustomOrder]\n')
    for variant in [b'\xef\xbb\xbf'+fx,fx.replace(b'\n',b'\r\n'),fx+b'\n[Future]\nopaque-data\n']:
        check(decode(encode(variant))==variant,'BOM/CRLF/unknown section lost')
    check(not any(p.suffix.lower() in ('.exe','.dll','.obj','.pdb') for p in ROOT.rglob('*') if p.is_file()),'Unexpected binary in source package')
    print('Source-only audit PASS. Native compilation/tests and REAPER runtime tests NOT RUN.')

if __name__=='__main__':main()
