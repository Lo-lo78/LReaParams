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
    check(title_src.count('CreateWindowExW(')==1,'Expected one title proxy')
    for marker in ['WS_EX_TOOLWINDOW','-32000','SW_HIDE','DestroyWindow','UnregisterClassW','SetForegroundWindow','WM_KEYDOWN']:
        check(marker in title_src,'Title proxy lifecycle contract missing: '+marker)
    for cpp in (ROOT/'src').glob('*.cpp'):
        if cpp.name != 'TitleProxy.cpp':
            check(not re.search(r'CreateWindow(?:Ex)?[AW]?\s*\(',cpp.read_text()),'Unexpected window creation: '+cpp.name)
    check('PM_REMOVE' in all_cpp and 'CallNextHookEx' in all_cpp,'Thread hook lifecycle contract missing')
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
