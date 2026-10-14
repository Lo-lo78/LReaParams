# Matrice funzionale e gate di equivalenza

Questa tabella è una mappa di lavoro: **non dichiara conclusa la migrazione**.
FX indica Speak FX Params 0.346; Track indica Speak Track Params 0.184;
Library indica Parameter Library 0.102. Le righe fanno riferimento ai file
originali in Legacy, mantenuti byte per byte. Per ogni definizione vedere il CSV
LuaFunctionInventory: 2.265 definizioni nominate e 213 anonime, 2.478 in totale.
Le definizioni ripetute sono mantenute separatamente: non assumere che la prima
sia quella attiva. Il censimento lessicale è completo rispetto ai file allegati;
la revisione semantica di tutte le funzioni non è completata.

| Funzione/famiglia e fonte | Trigger e condizione | Comportamento/stato | API o adapter | Test di equivalenza | C++ consegnato |
| --- | --- | --- | --- | --- | --- |
| speak, tutti i Lua | Annunci dei controller, se speech_suspended falso | Parlato OSARA, fallback console Lua | API nativa verificata outputMessage | Nessuna doppia lettura, assenza OSARA | Speech callback, sottoinsieme; manca delayed speech/cancellazione completa |
| FX contesto e main_loop:35877 | Attivazione, track/take/FX/browser | Identità FX, posizioni e restore | Focused/touched SDK, TrackFX/TakeFX | Due istanze, GUID, catena, progetto, master | Risoluzione di test e validazione; browser/restore da migrare |
| FX list_move_vertical:22613, horizontal:22683 | Frecce, griglia | Verticale dentro colonna, orizzontale cambia colonna | Modello logico | Bordo colonna e ultima colonna incompleta | Implementato nel sottoinsieme, runtime non verificato |
| FX handle_step_grid_keys:35104 | F1/F2, Alt+Sinistra/Destra | Grid e step per parametro/profilo | Modello + storage Extra | Passi e persistenza identici | Grid 1–200 runtime; scala di test diversa, porting da fare |
| FX handle_value_mode_key:25003 | Invio, Ctrl+V, Tab, frecce, Home/End | Value con ritorno, edit/reset speciali | Param APIs + adapter | Range discreti, toggles, special plugin | Invio/Tab/frecce/Home/End subset; resto da migrare |
| FX value_nudge:24489 | Alt+frecce oppure Value | Passi normali/grossi, formattazione, bordi silenziosi | SDK + ReaEQ/ReaComp/Lexicon/JSFX | Stesso singolo passo su ogni categoria | SDK e fallback di fattibilità; non equivalente completo |
| FX ricerca, recent, nomi e jump | Lettere, search/edit/recent secondo main_loop | Filtri, nome reale/display, ricerche persistenti | Stringhe + clipboard + ExtState | Stessi risultati/ordine/annunci | Ricerca ASCII Ctrl+F e salti Home/End/PageUp/Down introdotti; storico e ricerca completa da migrare |
| FX CustomOrder/hidden/slots/groups | Gestori F e modificatori; condizioni esatte in CSV | Alias, duplicati, ordine e gruppi per profilo | ProfileStore | Roundtrip + nav e operazioni identiche | Parser conserva dati; controller non migrato |
| FX handle_group_edit_grid_key:19878 | F7 e selezioni, Ctrl+Tab da F7 | Percorso selezione, occorrenze duplicate, ritorno | Modello di selezione | Aggiunta/toggle/taglia/incolla/ritorno | Non migrato |
| FX handle_memory_manager_key:5801 | F8, recinto protetto | Default snapshot e memorie | Snapshot + profilo | Cancellazione, rigenerazione, ritorno | Non migrato |
| FX paramlib_apply_return_packet:30358 | F10 griglia, Ctrl+Tab F7 | Plugin identity, selezione/cella, ritorno | Controller in memoria previsto | Nessun handoff file, selezione identica | Formato letto; controller non migrato |
| FX fx_compare_save_state:3738 | Parametro virtuale Compare -300000 | Snapshot originale/edited, sessione | FX state + ExtState volatile | Identica alternanza senza scritture involontarie | Indice negativo nel parser; motore non migrato |
| FX preset:33287 | Alt+F1/F2 | Preset precedente/successivo | FX preset SDK | Nomi e restore contesto | Non migrato |
| FX automazione:33623 e envelope helpers | Gesture documentate nel Lua | Stati envelope, clear, navigazione | Envelopes/chunks/Undo | Stato RPP identico al Lua dopo azione | Non migrato |
| FX cc_runtime_poll_recent_input:32072 | Shift+C, Ctrl+Alt+C, Ctrl+Shift+C, Ctrl+T | Fixed/floating/learn, pickup e annunci CC | MIDI recent input + mapping | Niente salti iniziali, stessa rimappatura ReaEQ | Non migrato |
| FX transport/marker/OSARA Peak Watcher | Space/Ctrl+Space, Ctrl+1..0, Ctrl+I/O, Alt+F10..12 | Azioni REAPER senza duplicazioni | Action SDK | Una sola azione per pressione | In Fase 0 esce e passa; forwarding semantico Lua da migrare |
| Track handle_key:26712 | F1 Tracks / F2 Sends / F3 Receives / F4 FX | Sezioni, intestazioni, navigazione e contesto | Track/routing/FX TCP | Tutti i controlli, stessa griglia e focus | Non migrato |
| Track handle_grid_key:24055 | Griglia e gesture per sezione | Valori traccia/routing, scelta e azioni | Track/Send APIs + Undo | Volume, pan, width, mute, solo, phase e altre voci | 0.0.2: volume/pan/width/mute/solo/arm/phase/FX enabled e sends/receives base, Undo; non equivalenza completa |
| Track handle_value_mode_key:20635 | Value e ritorno | Range volume configurabili, valori discreti | Adapter volume/routing | Valori, annunci e limiti identici | 0.0.2: Value nativo con passi fissi, passi Lua specializzati e persistenti pendenti |
| Track F4 FX list / alias / order:27871 | FX TCP, lista, Ctrl+Enter, editing alias | Ordine visibile, aggiunta/rimozione TCP | FX named config + profilo progetto | Stesso FX/parametro, GUID e ordine | Parser conserva; controller non migrato |
| Track handle_pin_audio_key:11545 | F5 in contesto FX | Audio pin connector | Pin mappings | Routing identico, Undo e ritorno | Non migrato |
| Track handle_pin_midi_key:12414 | F6 Track MIDI | MIDI della traccia, non solo del plugin | Track MIDI settings | Tutte le selezioni e bypass | Non migrato |
| Track handle_filter_edit_key:23093 | Filtro e campi editazione | Spazio come testo, cursore e parole | Editor logico/clipboard | Nessun trasporto mentre si scrive | Non migrato |
| Track CC maps/session cursor/track memory | Ctrl+M, Ctrl+F1..12, Ctrl+Shift+F1..12, CC gestures | GUID, memoria runtime; profili Track/ProjectTrack | ExtState + file + MIDI | Fine sessione, progetto, tracce omonime | File preservati; runtime non migrato |
| Library main_loop:1399 | F1 celle; F2 selezione solo da F7 | Griglia, iniziali, Tab e backslash | Controller in memoria previsto | Ritorno e disponibilità pagine identici | Non migrato |
| Library load_current_cell:1319 | Invio su F1 | Applica cella e ritorna, verifica plugin | Packet/controller previsto | Indici+nomi+identità, nessuna applicazione automatica | Non migrato |
| Library salvataggio/eliminazione | Ctrl+S su F2; Delete F1 doppia pressione, F2 rimozione | Nome, cella, selezione | Store .pp previsto | Cancel, Unicode, conferma eliminazione | Parser .pp presente, UI non migrata |
| Library F10 / Ctrl+Tab / Esc | Ritorno oppure chiusura secondo Lua | Distingue ritorno al contesto e uscita | Router di modalità previsto | Posizione originale e preview dati | Non migrato |
| gfx.init/getchar e JS_VKeys, tre Lua | Ciclo input originale | Finestra ausiliaria vietata nel porting | SDK accelerator / WH_GETMESSAGE | Acceptance.md gate input | Sostituzione di fattibilità, non parità delle keymap |
| Profili FX/Track/PP | Avvio / Import legacy profiles | Parsing+backup+conversione, nessun apply | C++ filesystem/Win32/CNG | Tutti 55, conflitti e roundtrip | Sorgente e test nativi presenti; oracolo Python eseguito |
| ExtState diretto, 46 chiamate | Preferenze/runtime secondo wrapper | Nessun dato runtime reso persistente | API main thread prevista | Restart e precedenza delle preferenze native | Inventario, porting non implementato |

`LuaShortcutEvidence.csv` contiene 1.492 righe di evidenza: definizioni dei codici,
condizioni effettive e commenti delle scorciatoie. Non è una keymap C++ già
implementata. Include anche commenti storici: quando un commento e il ramo
eseguibile differiscono, vince il ramo realmente raggiunto dalla versione allegata.

`LuaApiInventory.csv` elenca le chiamate REAPER per modulo. La colonna del CSV
funzioni «persistence_calls» è un indizio lessicale, non una classificazione
garantita: le chiamate ai wrapper vanno seguite durante il porting. Non basta
contare le righe o avere una DLL compilabile per dichiarare equivalenza.
