"""TEST53 F1/F2/F3 filter contract (source-only; no native build)."""
from pathlib import Path
from version_contract import version_at_least
root = Path(__file__).resolve().parents[1]
cpp = (root/'src/TrackNavigator.cpp').read_text(encoding='utf-8')
filter_cpp = (root/'src/TrackNavigatorFilter.cpp').read_text(encoding='utf-8')
folders = (root/'src/TrackNavigatorFolders.cpp').read_text(encoding='utf-8')
header = (root/'include/lrp/TrackNavigator.h').read_text(encoding='utf-8')
app = (root/'src/Extension.cpp').read_text(encoding='utf-8')
cmake = (root/'CMakeLists.txt').read_text(encoding='utf-8')
workflow = (root/'.github/workflows/build-windows.yml').read_text(encoding='utf-8')
lua = (root/'Legacy/Speak Track Params - TrackTake Navigator.lua').read_text(encoding='utf-8')
assert version_at_least(root,(0,0,53))
assert 'src/TrackNavigatorFilter.cpp' in cmake
assert 'void TrackNavigator::toggleFilter()' in filter_cpp
assert 'void TrackNavigator::applyFilter()' in filter_cpp
assert 'void TrackNavigator::clearFilter()' in filter_cpp
assert 'void TrackNavigator::cancelFilter()' in filter_cpp
assert 'void TrackNavigator::handle' in cpp and "k.vk == 'F'" in cpp
assert 'trackMatchesFilter(tr)' in folders
assert 'bool TrackNavigator::routeMatchesFilter' in filter_cpp
assert 'if (!routeMatchesFilter(track_, cat, i)) continue;' in cpp
assert 'entries_[static_cast<size_t>(i * detailHeight)].index == oldRawIndex' in filter_cpp
assert 'e->index' in cpp and 'std::to_string(e ? e->index : detailIndex_)' in cpp
assert 'GetSetTrackSendInfo(owner, category, index' in filter_cpp
assert 'previousRows = rows_' in filter_cpp and 'rows_ = previousRows' in filter_cpp
assert 'if (!rebuildForFilter(true))' in filter_cpp
assert 'filterQuery_.clear()' in filter_cpp
assert 'std::wstring utf8Wide' in filter_cpp and 'CharLowerBuffW' in filter_cpp
assert 'nativeTextField()' in header and 'setNativeText' in header
assert 'trackNavigator_.setNativeText(titleProxy_.textValue())' in app
assert 'titleProxy_.syncTextControl(trackNavigator_.nativeTextField()' in app
assert 'setNativeFilterAvailable(titleProxyActive_)' in app
assert 'filterEditing_' in header and 'nativeFilterAvailable_' in header
assert 'Enable the LReaParams native keyboard window' in filter_cpp
assert 'if (!filterQuery_.empty())' in folders  # collapsing filters must not invalidate cursor
assert 'matchingRoutingCount(nextTrack, category)' in cpp
assert 'GetTrackNumSends(nextTrack, category)' not in cpp
assert 'TrackNavigator::deleteCurrentRouting' in folders
assert 'Ctrl+F' in lua or 'KEY_CTRL_F' in lua
assert 'test53_static.py' in workflow
assert 'Parameter Library.cpp' not in cmake
# Pure synthetic checks on source behavior: duplicate sends retain raw IDs,
# while visible columns are a compact subset. This must be tested again in REAPER.
routes = [(0,'Bass'),(1,'Drums'),(2,'Bass'),(3,'Strings')]
filtered = [(raw,name) for raw,name in routes if 'bass' in name.lower()]
assert [raw for raw,_ in filtered] == [0,2]
assert filtered[1][0] != 1
assert [name for name in ('Grand Piano','Strings','Piano Soft') if 'piano' in name.lower()] == ['Grand Piano','Piano Soft']
print('TEST53 filter, accessible text edit, raw routing IDs and rollback source contracts PASS (no build)')
