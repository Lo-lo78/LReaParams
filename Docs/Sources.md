> Documento storico TEST30. Per stato attuale e limiti prevalgono Status.md e FxCommandMatrix.csv.

# Fonti tecniche consultate

Le definizioni utilizzate sono state lette nei repository ufficiali; non sono
ABI ricostruiti da ipotesi o dalle firme Lua.

- REAPER SDK: https://github.com/justinfrankel/reaper-sdk
  Commit consultato e incluso: `c0eafe87863b2bf69c5c822760f1b32a753b211b`.
  Header: sdk/reaper_plugin.h e sdk/reaper_plugin_functions.h.
  Contratti: accelerator_register_t, gaccel, hookcommand2, hookcustommenu,
  toggleaction, timer, GetTouchedOrFocusedFX, TrackFX/TakeFX API, Undo.
- OSARA: https://github.com/jcsteh/osara
  Commit consultato: `b18dbc7ed4106423aae52d0b9f52687fe9b93f71`.
  src/exports.cpp: API_osara_outputMessage e API_osara_isShortcutHelpEnabled.
  src/reaper_osara.cpp: Shortcut Help, esempio menu Main extensions.
  L'export versione in questa revisione è vararg: non viene inventata una
  firma nativa osara_getVersion non registrata.
- SWS: https://github.com/reaper-oss/sws — riferimento generale del piano;
  nessun codice SWS è incorporato e non è una dipendenza.
- JS_ReaScriptAPI: https://github.com/juliansader/js_ReaScriptAPI — riferimento
  del piano e dipendenza dei Lua; nessuna dipendenza nella DLL nativa.
- GitHub Actions ufficiali: https://github.com/actions/checkout e
  https://github.com/actions/upload-artifact. I tag v7 sono stati risolti con
  git ls-remote e il workflow usa gli SHA verificati, non hash inventati.
- Runner: https://github.com/actions/runner-images/blob/main/images/windows/Windows2025-Readme.md
  Per GitHub Actions ottobre 2026, il workflow usa il runner
  windows-2025-vs2026 e il generatore Visual Studio 18 2026 x64.
  Vedi: https://github.com/actions/runner-images/issues/14017

Questi SHA identificano dipendenze/riferimenti pubblici. Non sono commit del
futuro repository LReaParams: qui non è stato effettuato alcun commit remoto.
