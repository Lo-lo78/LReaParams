"""0.0.46.5: native global Delta clear + explicit Monitor FX cleanup.

Source-only contract: NO native build.
"""
from pathlib import Path
from version_contract import version_at_least

root=Path(__file__).resolve().parents[1]
assert version_at_least(root,(0,0,46,5))
s=(root/'src/FxNavigator.cpp').read_text(encoding='utf-8')
start=s.index('void FxNavigator::clearProjectDeltaSolo()')
end=s.index('void FxNavigator::runLuaFunctionAction(',start)
clear=s[start:end]
assert 'Main_OnCommand(clearAction,0);' in clear
assert 'MediaTrack* master = GetMasterTrack(project_);' in clear
assert 'TrackFX_GetRecCount(master)' in clear
assert 'const int monitorFx = 0x1000000 + i;' in clear
assert 'deltaParameter(master,nullptr,monitorFx,delta)' in clear
assert 'TrackFX_SetParamNormalized(master,monitorFx,delta,0.0)' in clear
assert 'TrackFX_GetParamNormalized(master,monitorFx,delta)<=0.5' in clear
assert 'Delta Solo not cleared' in clear
native=clear.index('Main_OnCommand(clearAction,0);')
manual=clear.index('TrackFX_SetParamNormalized(master,monitorFx,delta,0.0)')
ret=clear.index('return;',manual)
assert native < manual < ret, 'Must clear Monitor FX before native action branch returns'
assert 'scanTrack(GetMasterTrack(project_));' in clear
assert 'clearTrack(GetMasterTrack(project_));' in clear
assert 'void FxNavigator::toggleDeltaSolo()' in s
print('TEST46.5 Monitoring FX Delta Solo global clear PASS')
