"""TEST62.8: source-only contracts; Windows C++ tests run on GitHub Actions."""
from pathlib import Path
r = Path(__file__).resolve().parents[1]
ex = (r/'src/Extension.cpp').read_text(encoding='utf-8')
st = (r/'src/Storage.cpp').read_text(encoding='utf-8')
h = (r/'include/lrp/Storage.h').read_text(encoding='utf-8')
api = (r/'include/lrp/ReaperApi.h').read_text(encoding='utf-8')
t = (r/'Testing/ProfileTests.cpp').read_text(encoding='utf-8')
assert '#define REAPERAPI_WANT_GetUserFileName' in api
assert 'LREAPARAMSIMPORTSELECTEDTXT' in ex
assert 'case importSelectedTxt:' in ex and 'requestSelectedTxtImport()' in ex
assert 'GetUserFileName(2,' in ex and 'Legacy TXT profiles|*.txt' in ex
assert 'Scripts" / L"Lo-lo - Scripts" / L"Utility" / L"Scripts' in ex
assert 'for (int i : {importLegacy, importSelectedTxt, openData, settings})' in ex
assert 'case importLegacy:' in ex and 'requestLegacyImport(false)' in ex
assert 'startSelected(const fs::path& root' in st
assert 'importSelectedProfiles(const fs::path& resource' in st
assert 'importSelectedProfiles(const fs::path& resourceRoot' in h
assert 'profile.kind == ProfileKind::fx ? L"Plugins" : L"Tracks"' in st
assert 'const auto native = serializeNative(profile)' in st
assert 'const auto verified = parseNative(readFile(target))' in st
assert 'source.filename()' in st and 'fs::absolute(selected)' in st
assert 'const auto backup = root / L"Backups"' in st
assert 'ImportConflicts' in st and 'if (readFile(target) == native)' in st
# Selected import must never use the bulk importer's deletion primitive.
selected = st[st.index('ImportReport importSelectedProfiles('):st.index('ImportWorker::~ImportWorker()')]
assert 'FileDispositionInfo' not in selected and 'fs::remove(source)' not in selected
assert 'std::vector<fs::path>& sources' in h and 'startSelected' in h
assert 'Mixed selected import lost FX or Track profile data' in t
assert 'Selected import overwrote a modified native profile' in t
assert 'Selected TXT was modified or removed' in t
assert 'Selected import ignored cancellation' in t
print('TEST62.8: selected multi-file FX/Track import static checks PASS; Win64 runtime pending')
