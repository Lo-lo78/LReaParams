# ExtState: inventario e politica di migrazione

`LuaExtStateCalls.csv` conserva tutte le 46 chiamate dirette individuate nei
tre file, incluse le espressioni di chiave dinamiche e il parametro persist.
Le guardie `if reaper.GetExtState then` non sono chiamate e non sono contate.
Parameter Library non usa ExtState direttamente: nel Lua scambia packet TXT.

| Sezione | Chiave/famiglia | Persistenza originale | Azione prevista nel porting |
| --- | --- | --- | --- |
| OSARA_FX_Params_Param_Browse | recent_searches_v1 | true | Importare una volta le ricerche; non sovrascrivere quelle native |
| OSARA_FX_Params_Param_Browse | last_fx_v1::<context>; last_fx_v1::fallback::<context> tramite save_global_state | true | Ricostruire identità e fallback secondo i Lua, conservando la provenienza |
| OSARA_FX_Params_Param_Browse | stale_item_guid_v1, stale_item_track_v1 | false | Memoria di sessione, non trasformare in preferenza persistente |
| OSARA_FX_Params_Param_Browse | cc_focus_session_active_v1/channel_v1/cc_v1/status_v1 | false | Importazione solo runtime quando esisterà il motore CC |
| OSARA_FX_Params_Param_Browse | fx_compare_session_v1::<context>::<FX> | false | Compare per istanza, runtime; non applicare snapshot automaticamente |
| LoLo_SpeakTrackParams_VolumeRange | volume_range_ext_key(key), dipendente da track/routing | true | Copiare range min|max validati senza sostituire preferenze native |
| LoLo_SpeakTrackParams_Runtime | track_memory_slot_1..12 | false | Memorie tracce per sessione; convalida GUID |
| LoLo_SpeakTrackParams_Runtime | cursor_memory_enabled, cursor_memory_last_section, cursor_memory_<section> | false | Ripristino logico runtime, non coordinate schermo |
| LoLo_SpeakTrackParams_Runtime | title_detail_enabled | false | Riprogettare l'annuncio: non creare finestre o titoli invisibili |
| LoLo_SpeakTrackParams_Runtime | floating_cc_active, floating_cc_channel, floating_cc_number | false | Runtime, non persistere controller attivi automaticamente |
| LoLo_SpeakTrackParams_Runtime | fixed_cc_map_enabled | false | Runtime; riattivazione solo con comportamento equivalente |

Le costanti EXT_LAST_PARAM_PREFIX/ENTRY/AREA non dimostrano da sole scritture
ExtState persistenti: molti dati del navigatore FX sono ormai delegati al profilo
TXT tramite get/set_plugin_state. Il CSV delle chiamate e i wrapper originali
sono l'autorità, non il nome della costante. Non risultano chiamate dirette
GetProjExtState/SetProjExtState nei tre sorgenti forniti.

**Stato Fase 0:** nessuna importazione ExtState implementata, nessuna chiave
storica letta o scritta dalla DLL. Questo evita di importare parzialmente uno
stato che i moduli ancora assenti non sanno interpretare. Non è un requisito
scartato: resta una parte obbligatoria della Fase 5.

Per la Fase 5 usare GetExtState dal thread principale per chiavi note, distinguere
"manca" da un valore vuoto deliberato e registrare la versione importata. Le
chiavi dinamiche non possono essere inventate né enumerate con un'API inesistente:
vanno ricostruite dal contesto o lette da una fonte persistente documentata solo
per le famiglie persistenti, con validazione e senza toccare il file INI originale.
Gli stati runtime non devono essere ripristinati da un vecchio INI o da backup.
