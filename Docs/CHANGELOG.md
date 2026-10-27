## 0.0.62 — public release of TEST61.16.1 (2026-10-27)
- Bumped the public version in the native About, CMake, NSIS, Windows installer metadata, GitHub Actions and the accessible guides.
- The release includes the TEST61.14–61.16 FX context persistence, online restoration and 14 independent grids detailed below; no new FX navigation behavior introduced in this version-only bump.
- Historical TEST61 labels, persistent file format versions and `PageLayoutVersion=61` are unchanged for compatibility. See [0.0.62 release notes](RELEASE_NOTES_0_0_62.md).
- Native build and REAPER/NVDA testing via GitHub Actions and installed DLL still required.

## TEST61.16.1 — GitHub Actions TEST48 static regression repair (2026-10-21)
- Fixed obsolete TEST48 source-only assertion: it now accepts and requires `captureViewCursor()` between `syncParameterStep()` and `ensureContextMemory()`.
- This is a test contract update only. The C++ code, 14 independent grids, F1/F2, persistent `.fx`, F7, Esc and offline/online restoration are unchanged.
- No local native compilation. Windows DLL build remains GitHub Actions only.

## TEST61.16 — Memoria FX per contesto (2026-10-21)
- F1/F2 memorizza la larghezza di griglia **del contesto corrente**, non una larghezza globale per il plugin: Plugin Order, Custom Order e 12 Group distinti.
- Ogni contesto conserva anche parametro e posizione/occorrenza, indipendentemente da F7 e dalle modifiche dei valori.
- Memoria per istanza durante la sessione, fallback condiviso persistente nel `.fx`; lettura dei vecchi campi Lua; salvataggio protetto senza riscrivere Custom Order o CC.
- TEST61.15 offline/online e TEST61.14 Esc/riapertura conservati. Fonte `Docs/TEST61_16_INDEPENDENT_FX_GRIDS.md`. Build Windows solo GitHub Actions.

## TEST61.15 — Ctrl+Alt+B immediate FX parameter restore (2026-10-21)
- Rebinding the FX parameters directly after returning online: returns to the same group and parameter, without Escape/Enter or reopening FX Params.
- For VSTi taking time to load, nonblocking timer-based retry (GUID guarded, 250 ms checks, 90 s limit) returns automatically when parameters become available; browsing a different FX cancels retry.
- Track/Take/Monitor FX API parity, preserved .fx persistent memory and F7 behavior. Source-only checks; GitHub Actions native build pending.


## TEST61.8 — Consent-first import and accessible keyboard settings (2026-10-19)
- Startup no longer silently imports or converts old Lua TXT profiles. If legacy files exist, a one-time accessible native question asks **Y** (convert safely) or **N** (leave unchanged); Escape also declines. Answer stored in `LReaParams/Settings/LegacyImportChoice.txt`. The prompt will not recur after an answer; manual import always remains available. No legacy TXT = no startup dialog.
- Existing REAPER action `LReaParams: Import legacy profiles` (`_LREAPARAMSIMPORTLEGACY`) now asks for explicit Y/N confirmation **every invocation**. Without legacy files it displays an informational message.
- Existing REAPER action `_LREAPARAMSSETTINGS` is now described as `LReaParams: Settings (Keyboard Input)`; it is a two-choice menu: **1** SDK accelerator (default) / **2** REAPER main-thread compatibility hook; Escape cancels. Mode lasts only until REAPER is closed.
- Native Windows Task Dialog buttons are explicitly labeled in English with Y/N and 1/2 shortcuts; unmodified keys are routed only while the dialog is focused. Native FX/Track automation confirmations already use Y/N and are unchanged.
- The same protected importer creates verified backups, never overwrites differing native profiles, and only deletes TXT in *active* LReaParams folders after verification; old Lua source files remain intact.
- No C++ or native compilation locally. Tests check source contracts; confirm actual keyboard/OSARA behavior on GitHub-built DLL.

## TEST61.7 — GitHub Actions source-only regression fix (2026-10-19)
- Corrected legacy TEST27 string expectation by clarifying the F12 About text (`F12 alone is reserved`; Ctrl+F12 continues to address memory slot 12).
- Corrected the legacy TEST42 check to verify the Stop Background MIDI action without requiring it to be the last enum entry; the TEST61.6 Open User Guide action remains registered.
- All 83 Python checks declared by the current GitHub Actions workflow passed locally; no C++, CMake, MSVC or native build was run.
- No behavior, action identifiers, navigation logic, MIDI routing, HTML guides or translation contents were changed.

## TEST61.4 — F6 Hardware Output creation
- Track F6 now opens on empty hardware-output lists; Add column supports Enter and device-aware Alt+arrows.
- Native CreateTrackSend(track, nullptr), hardware destination mapping, read-back and failure rollback, Undo.
- Deleting last output stays in F6 Add; ReaRoute category destinations remain separate. No local build.

TEST61.3: Audio Pin Connector FX F11 — annunci sintetici: "Attive." solo quando il collegamento esiste; nessuna parola di stato se non collegato. Conferme dei tasti coerenti. Codice audio e routing invariati. Nessuna compilazione locale.

TEST61.1 — GitHub Actions source-test compatibility repair (2026-10-19): corrected obsolete TEST55.5 (ReaRoute formerly F8, now F7) and TEST56.1/56.2 (Track Page enumeration and F4 selector function keys). C++ unchanged; no native compilation performed locally.

TEST61 / LReaParams 0.0.61: FX F10 Browser↔Grid (Ctrl+P removed), FX F11 128-channel audio pin connector for Track, Take and Monitor FX; Track F5 MIDI, F6 Hardware, F7 ReaRoute, with one-time .tp page cursor conversion; six OSARA Peak Watcher actions restored. No local build; MSVC through GitHub Actions. See Docs/TEST61_FX_PIN_MIGRATION.md.

# 0.0.59 — TEST59 F8 ReaRoute (sorgente)

Migrazione nativa della griglia ReaRoute, con input della traccia, controlli di creazione output, colonne di output virtuali, 11 righe, valori e routing REAPER, Undo, lettura di verifica e `.tp`. F7 ora isola i soli hardware output fisici. Nessun alias F4 o modifica delle scorciatoie di trasporto. Solo sorgente, compilazione GitHub Actions. [Dettagli](TEST59_F8_REAROUTE.md).

# 0.0.58 — TEST58 F7 Hardware Outputs (sorgente)

Migrazione nativa C++ della griglia F7, category 1, 11 righe per ogni uscita; valore per valore, Undo, lettura dopo scrittura, Delete, memoria `.tp` e tasti. Rifiniture F6 tastiera e bordi silenziosi. F1-F6 ed FX Params mantenuti. Non compilato localmente. [Guida](TEST58_F7_HARDWARE_OUTPUTS.md).

# 0.0.57 — TEST57 F6 Track MIDI (sorgente)

- Migrazione della pagina F6 del Lua: 5 voci verticali relative alla traccia, indipendenti dal singolo FX: hardware output, hardware channel, MIDI input channel map, MIDI control channel, MIDI routing (nota/collegamento F2-F3).
- API native REAPER, limite di 32 dispositivi / 16 canali, nomi dei dispositivi se presenti, Undo e readback; navigazione e gestore memorie coerenti con NVDA/OSARA.
- Salvataggio di posizione F6 nello stesso `.tp`; accesso F6 da F1-F5, F4+Alt+Invio e F5; F5 128 canali invariato.
- Test Python source-only e workflow per compilazione esclusiva tramite GitHub Actions. **Nessun build/CTEST/reale test hardware locale.** [Guida](TEST57_F6_TRACK_MIDI.md).

# 0.0.56 — TEST56.10.2 — F5 128-channel audio pins (source only)

- Extend F5 from 64 to 128 track channels without changing REAPER's `I_NCHAN` or the FX instance.
- Use the documented `pin + 0x1000000` index for the independent channel 65–128 mapping bank; retain both 32-bit words, read/modify/write the correct bank and confirm through readback.
- Preserve independent input/output pin columns, navigation, Undo, NVDA review, F4 return and all prior FX/Track functions. Add static boundary checks and GitHub Actions step. F6 not implemented in this test.
- No local native build or REAPER/NVDA runtime verification.

# TEST56.9.1 — F4 Fixed CC writer and focus-loss repair

- Accept valid `FxTcp|{trackGUID}|{fxGUID}|nativeParameterIndex` Fixed CC mappings
  and per-target MIDI speech settings in both the memory writer and the native
  `.tp` parser for the same project file.
- Fix exception that terminated Track Params after the first F4 learn event;
  storage errors during learning now report an error rather than exiting.
- Add source and native regression cases for two FX instances, persistence,
  invalid identities, opt-in speech, and deletion. Floating CC unchanged.
- No local compilation; build and native CTest are delegated to GitHub Actions.

## 0.0.56 TEST56.9 — F4 consolidation (source-only)

- Finalized F4 accessible Ctrl+E numeric edit, using shared Win32 EDIT and host formatted numeric values when safe; raw-value fallback and GUID-target guard.
- Ctrl+Shift+T now correctly suppresses keyboard value-change announcements for F4 without affecting manual NVDA review or the independent MIDI speech preference.
- Improved host-provided discrete step alignment and conservative small-integer JSFX stepping.
- No aliases or custom parameter ordering. All F1/F2/F3 features retained and F5 not yet implemented.
- Native MSVC compilation and REAPER/NVDA functional tests reserved for GitHub Actions and the user's machine.

## 0.0.56 — TEST56.8 (F4 MIDI CC)

- Fixed CC per GUID traccia, GUID istanza FX e parametro TCP; riordino della catena senza perdere il destinatario.
- Floating, pickup normalizzato, toggle e Ctrl+Q background.
- Ctrl+T parlato MIDI Off per impostazione predefinita, Ctrl+Maiusc+T parlato modifiche; Ctrl+Canc cancella CC.
- Track Memories mostra le nuove assegnazioni, tutte nell’unico `.tp` del progetto.
- Controlli statici; compilazione MSVC e collaudo in REAPER demandati a GitHub Actions/utente.

## TEST56.4 — F4: concise Value speech, Ctrl+F, visible FX columns (source only)

- Value speech only on change; Ctrl+F FX Params-compatible search; Alt+Home/End.
- Alt+Enter visible grid mirrors the F4 FX columns; names-only parameter review; specific window title.
- Historical F1/F2/F3, FX Params and .tp formats unchanged. Native validation through GitHub Actions only.

## TEST56.3 — F4 TCP keyboard and Value (source only)
- F6 now reserved; visible TCP selection moved to Alt+Enter.
- Cyclic letter/number search in F4 and selector; Shift reverses direction.
- Value editing with FX parameter step sizes, safety checks and Undo.
- Native Windows build and REAPER/NVDA still required via GitHub Actions.

## TEST56.2 — F4 parameter-name grid

- FX header Enter: accessible multi-column names-only parameter grid; F1/F2 adjust height (1..200).
- Enter: add/show current parameter in TCP and return to corresponding F4 position; Ctrl+Enter: toggle while remaining in grid.
- F6: visible TCP parameters grid, Enter removes and returns to F4.
- Protected TCP changes by GUID, native API readback, targeted chunk fallback and Undo. No modification of parameter audio values.
- Previous TEST56.1 and F1/F2/F3 behavior preserved; no local compilation.

## 0.0.56 — TEST56.1
- F4 FX TCP: navigazione nativa in sola lettura, parametri esposti nei Track Controls, memoria GUID/posizione nel progetto; ritorno alle pagine originali e scorciatoie condivise. Compilazione solo tramite GitHub Actions.

## 0.0.55 — TEST55.12
- Riparata la creazione/riattivazione dell’automazione Width in Track Params F1, usando la struttura completa `WIDTHENV2` del Lua e verificando il chunk reale della traccia. Supporto a blocchi Width legacy; gli altri parametri e i profili rimangono invariati.
- Nuova prova statica in GitHub Actions. Non compilato localmente.

## TEST55.8 — FX Default restoration
- Complete index-verified fallback for preset-dependent parameter names; no snapshot overwrites.
- Enter on FX Memories > Default restores and returns to Plugin Order without clearing unrelated memories.
- Delete remains the guarded clear/reset path; structural ReaEQ default unchanged.
- Source-only; GitHub Actions required.

## 0.0.55 — TEST55.7
- Acquisizione A/B alla prima selezione dell’istanza FX, con conservazione per la sessione anche dopo Esc/Ctrl+Tab. Evitata la ricattura involontaria su rientro; cleanup dei progetti chiusi. F8 invariato (singolo A/B, doppio aggiorna Original). Nessuna modifica ai profili.

## 0.0.55 — TEST55.6: F8 Compare A/B
- FX Params: F8 singolo alterna Original/Compare, doppio F8 aggiorna Original con il suono corrente.
- L'ingresso in FX non applica mai Original e non cambia il suono memorizzato dal progetto; cattura soltanto una base provvisoria per la sessione.
- Il vecchio Compare virtuale viene escluso da ordine, griglia, gruppi e FX Memories; legacy `.fx` non riscritti in ingresso.
- Gestione differita della singola pressione con il tempo di doppio clic Windows, senza cambio sonoro intermedio sul doppio gesto.
- [Prove manuali](TEST55_6_F8_COMPARE_AB.md); nessuna build locale.

## 0.0.55 — TEST55.5: Ctrl+Maiusc+M per entrambe le memorie

- Un solo gesto in FX Params e Track Params; toggling e ritorno con Esc; F8 FX senza funzione per usi futuri; Alt+F8 Track rimosso.
- Gestori, `.fx`/`.tp`, associazioni CC e Command ID delle azioni restano invariati. Nessuna build locale; GitHub Actions compilerà la DLL.

## TEST55.4 — Unified FX and Track memory behavior
- Fixed and Floating Track MIDI CC speech defaults OFF; per-target GUID speech preferences persist separately and do not bleed between same-name parameters on different tracks.
- Track Memories now lists only deviations from defaults; replaces automatic Navigation Memory listings with explicitly saved Volume Ranges. Empty manager starts without fabricated rows.
- Resetting a memory drops its key from the project TP rather than leaving a blank placeholder.
- FX F8 opens FX Memories from Grid/Value without requiring F7 first. Dedicated FX/Track Memories REAPER actions still use their respective managers.
- No local native build or runtime test performed.

## TEST55.3 — Fixed MIDI CC per-track GUID

- Track Fixed CC bound to an immutable REAPER Track GUID, not the navigated Pan/Volume type.
- Send/Receive CC bound to source/destination GUIDs plus send ordinal; Floating CC unchanged.
- Project `.tp` receives `[LReaParams.FixedCCByTarget]`; previous type-wide maps preserved and shown as inactive legacy entries in Track Memories.
- Ctrl+Delete and Alt+F8 delete individual scoped associations; per-GUID MIDI pickup.
- Added Windows native profile persistence tests and source-only static checks.

## TEST55.1 — MSVC compile fix (GitHub Actions)

- `src/TrackNavigatorMemories.cpp`: separate the `std::string` and `size_t` local `auto` declarations at the two Track Memories speech/CC handlers (C3538).
- Added source-only TEST55 regression assertions; no behavior, MIDI CC, shortcuts, or `.tp` format changes.
- No local build performed. MSVC and native tests pending GitHub Actions.

### 0.0.55 — Track Memories
- Attivata l’azione Track Memories e Alt+F8 da Track Params. Cinque categorie navigabili da tastiera con lettura NVDA.
- Persistenza delle dodici memorie traccia (GUID) e range Volume nel profilo `.tp` specifico del progetto.
- Gestione/azzeramento delle associazioni Fixed CC, degli Step e degli annunci; F7/F8 normali conservati per il Lua.
- Aggiunti controlli di regressione; nessuna build locale.

### 0.0.54.3 — Numeric Edit e FX vuoti

- Track Params Ctrl+E: nessun annuncio secondario `Set.` dopo la conferma, lasciando l’aggiornamento accessibile del parametro.
- FX Params: `No track FX` o `No take FX` nel contesto esplicitamente selezionato; non apre FX estranei se la selezione è vuota.
- Ctrl+Tab su una traccia senza FX conserva Track Params e il suo focus; Master/Monitor FX invariati.
- Solo test statici: compilazione e prove NVDA/REAPER demandate a GitHub Actions.

### 0.0.54.2 — Track automation e Ctrl+Tab

- Ctrl+Maiusc+A: elimina l’annuncio duplicato `Auto`, mantenendo il CC nella posizione corretta.
- Send/Receive: modifica gli envelope AUXRECV già presenti, distinguendo i collegamenti duplicati. Gli envelope mancanti richiedono SWS/BR: le relative azioni agiscono sui send della traccia sorgente.
- Quando abilita l’envelope, imposta anche `ARM 1`, senza toccare punti o automation item, e verifica la modifica prima di annunciarla.
- Ctrl+Tab alterna Track Params e FX Params tramite il focus nativo della DLL; dal Track apre l’FX della traccia sotto il cursore.
- La compilazione è riservata a GitHub Actions.

### 0.0.54.1 — GitHub Actions compilation fix
- Corrected a duplicate `stale` fixture variable in `Testing/ProfileTests.cpp` (MSVC C2371 and cascading C2039); TrackMemory test now uses `staleTrack`.
- No changes to DLL source, MIDI CC, `.tp` storage, shortcuts, or project routing.
- Rebuild and native tests must run on GitHub Actions; no local native build was performed.

## 0.0.54.1 — Track Fixed CC e profilo di progetto

Le memorie Track Params sono ora per progetto, con Fixed CC persistente, annunci CC prima di Auto e trasporto condiviso con FX Params. Ctrl+Canc elimina il CC anche in F1; Ctrl+Maiusc+Canc deseleziona le tracce. Rinominati i comandi REAPER senza cambiarne gli ID. F4 futuro nello stesso `.tp`. Solo sorgente.

## 0.0.53 — TEST53.2: annunci distinti Su/Giù e Sinistra/Destra in F2/F3

F2/F3 verticalmente dice solo parametro e valore; orizzontalmente dichiara `traccia, Send/Receive, parametro, valore` e omette la traccia nei duplicati consecutivi (`Send 2`, `Receive 3`). Ritorna a nominare il peer quando cambia. Primo link sempre `Send`/`Receive`. Tab conserva il contesto completo; filtri e paste TEST53.1 invariati. [Guida](TEST53_2_DIRECTIONAL_ROUTING_SPEECH.md). Solo controlli statici, nessuna build locale.

## 0.0.53 — TEST53.1 correzioni F1/F2/F3

- Ctrl+V SWS continua a preservare routing, ma riposiziona il gruppo di GUID appena incollati dopo la traccia corrente, se SWS non lo fa.
- Annunci verticali e orizzontali F2/F3 con nome peer, parametro, valore; `Send/Receive N` soltanto dalla seconda istanza verso la stessa traccia.
- Ctrl+F clear e Ctrl+F poi Esc: `Search cleared. <parametro>, <valore>` senza uscire dalla griglia.
- Solo controlli statici; build e REAPER/NVDA non eseguiti localmente.

## 0.0.53 — F1/F2/F3 Ctrl+F

Nuovo filtro basato sul Lua, input tramite EDIT nativo NVDA, ricerca per traccia o colonne Send/Receive e preservazione degli indici reali anche per i routing duplicati. La persistenza `.tp` rimane invariata. [Guida](TEST53_TRACK_FILTERS.md). Restano da migrare MIDI CC runtime Track, envelope mancanti, clear-all e sezioni F4-F8. Nessuna build locale.

## 0.0.52 — Track Params: clipboard con routing, move, F2/F3 navigation, automation

- F1 Ctrl+C/X/V via SWS/S&M (nessun fallback a copia senza routing); invalidazione dei vecchi puntatori dopo cut/paste e ripristino del cursore per GUID.
- F1 Alt+Maiusc+Su/Giù sposta fisicamente i blocchi con i figli delle folder, ripristinando la selezione logica.
- F2/F3 Ctrl+Su/Giù salta tra tracce che contengono routing, mantenendo il campo verticale.
- Ctrl+Maiusc+A F1 e F2/F3 cambia lo stato degli envelope esistenti, con aggiunta `Auto` agli annunci; F1 Volume/Pan/Mute può crearli via azione nativa. F1 Width e send/receive non vengono creati se assenti.
- Non migrati: filtro Ctrl+F, clear all automation, Track MIDI CC runtime e F4-F8. Nessuna build locale: solo controlli statici. [Guida](TEST52_TRACK_CLIPBOARD_MOVE_AUTOMATION.md).

## 0.0.51 — estensione folder annidate e Canc F2/F3

- F1 parla `end folder Nome` sulle righe che chiudono una o più folder; Ctrl+Invio toggla la folder e ricostruisce il cursore sulle sole tracce visibili.
- F2/F3 Canc elimina il send/receive corrente in Undo, risolvendo il vero indice della sorgente nei receive duplicati.
- MIDI Merge resta stato derivato, read-only come nel Lua.
- Nessuna compilazione locale. [Guida](TEST51_FOLDERS_AND_DELETE.md).

# 0.0.51 — aggiornamento F1: Add Send / Add Receive (senza cambiare versione)

- **Ctrl+Maiusc+S** in F1: memorizza tutte le tracce sorgenti selezionate e deseleziona le tracce. Dopo aver selezionato le destinazioni, la seconda pressione crea tutte le coppie di send (escluse le autoconnessioni).
- **Ctrl+Maiusc+R** in F1: memorizza tutte le tracce destinatarie, quindi seleziona le sorgenti e ripremi per creare i receive con `CreateTrackSend(sorgente, destinatario)`.
- **Esc** annulla soltanto la creazione in sospeso, senza uscire dal navigatore; **Tab** legge numero e tipo delle tracce memorizzate e il gesto successivo.
- GUID ripristinati sulle tracce ancora esistenti, esito con contatori creati/saltati/falliti, Undo di un gruppo; seconda selezione mantenuta e singola operazione su thread UI.
- Se non sono selezionate tracce nella seconda fase, l'operazione resta in sospeso. Se si prova il comando opposto durante una creazione in sospeso, il navigatore chiede di concluderla o annullarla.
- Rimangono esclusi la cancellazione di send/receive su F2/F3, il salto al peer, automazioni e funzioni F4-F8 non migrate.
- Nessuna build locale; controlli Python soltanto statici. Vedere `Docs/TEST51_F1_ADD_SEND_RECEIVE.md`.

# 0.0.51 — Track Params F2/F3 audio/MIDI routing

- F1: eliminato Ctrl+Maiusc+V (Invio per Value); Ctrl+Alt+Su/Giù salta tra le folder al posto di Ctrl+Alt+Pagina Su/Giù.
- F2/F3: source/destination audio ora editabili, con protezione bitfield, gestione `None`, verifica del peer e incremento automatico `I_NCHAN` entro 128. Bassa API C++ tipizzata.
- Send type secondo Lua 0–3, MIDI bus 0–16, stato MIDI merge in sola lettura; annunci di routing aggiornati. Nessuna modifica al formato `.tp` o a FX Params. [Dettagli](TEST51_TRACK_ROUTING_AND_SHORTCUTS.md).
- Non migrati in TEST51: add/delete sends, salto peer, ricerca, automazione send e CC runtime Track. Non sono state eseguite build native o prove REAPER/NVDA.

# 0.0.50 — Track Params F1 selezione / Tab informazioni

- Tab sostituisce Ctrl+R per il riepilogo completo delle informazioni in Track Params (anche F2/F3); FX Params invariato.
- Selezione tracce F1: Ctrl+A, Maiusc+Spazio/Ctrl+Maiusc+Spazio, Canc/Ctrl+Canc, Maiusc+frecce/Pagine, Ctrl+Maiusc+Su/Giù. Il cursore invisibile è indipendente dalla selezione REAPER; ribasamento del controllo dopo selezioni richieste dal navigatore.
- Ctrl+Alt+Pagina Su/Giù: salto alla folder visibile precedente/successiva, preservando la colonna e senza selezione reale della traccia.
- Ctrl+Maiusc+V: alterna Grid/Value in F1; lo Step e le preferenze `.tp` della TEST49 sono preservati.
- Non ancora migrate: cut/copy/paste tracks with routing, riordino fisico, filtri e automazioni F1, F4–F8, routing completo F2/F3, MIDI CC runtime. Vedere test manuali, nessuna compilazione locale.

# 0.0.49 — Track Params / memoria persistente

- Step separati per parametro F1/F2/F3, preferenza annunci editing, Ctrl+T compatibile con CCSpeech Lua; ripristino pagina/parametro/colonna.
- Aggiornamenti conservativi del file esistente `Tracks/Track CC Map.tp`, backup SHA-256, conflitti esterni protetti, parser e test nativi ampliati.
- Invariato il motore FX Params e fuori scope Parameter Library. Runtime MIDI Track e sezioni F4-F8 rimandati.
- **Solo sorgente**; build MSVC e test runtime saranno eseguiti in GitHub Actions/dall’utente.

## 0.0.48 — Step per parametro e parlato MIDI CC

- Step -10..+10 persistente per parametro FX, anche dopo riavvio REAPER.
- Recupero (approssimato) dei valori Step v3/v2 dal Lua, senza alterare il
  campo legacy nel profilo `.fx`.
- Ctrl+T mantiene il toggling individuale CC speech; durante cambi MIDI il
  valore solo viene annunciato per il parametro corrente, nome+valore per
  altri; deduplicazione del valore formattato.
- Nuovo test statico e fixture C++ di persistenza per GitHub Actions.
- Nessun cambio a Track Params, F7/F8 strutturali, MIDI learn, Ctrl+Spazio o
  browser Master/Monitor. Nessuna compilazione locale.

## 0.0.47
- F8 Default: Canc e Invio richiedono conferma Yes/No; nessun reset o
  cancellazione di snapshot prima della conferma.
- F8: F7 disponibile solo da posizioni, gruppi, MIDI CC e Custom Order.
- Hidden Parameters include virtuali ReaComp e ReaGate; Invio resta disabilitato.
- Reset dello stato modale di F8 all'uscita; nuovi test statici GitHub.
- Nessuna modifica al motore Track Params o agli adattatori audio.

## 0.0.46.5 — Ctrl+Maiusc+D include Monitor FX

L'azione nativa `Clear delta solo for all project FX` non garantisce l'azzeramento dei Monitor FX, che appartengono alla catena monitor separata dal progetto. La DLL ora esegue l'azione nativa e verifica separatamente ogni Monitor FX (`0x1000000 + indice`), disattivando eventuali Delta Solo residui e verificando il risultato. Ctrl+D rimane invariato. Nessuna modifica a Track Params e agli altri comportamenti già collaudati.

## 0.0.46.4 — Browser Master/Monitor a colonne

- **Destra:** Master → Monitor FX. **Sinistra:** Monitor FX → Master.
- Ogni colonna mantiene il proprio cursore; non si attraversano catene con i comandi verticali, la ricerca per iniziale o il riordino.
- Browser e griglia rimangono separati; Invio/Ctrl+P dalla colonna corrente apre l'FX effettivamente evidenziato.
- La colonna vuota resta riconoscibile e il ritorno all'altra colonna è possibile.
- Verifica reale rimandata a GitHub Actions e REAPER/NVDA. Nessuna compilazione locale.

## 0.0.46.3 — Master e Monitor FX come catene distinte

Il browser FX interno Ctrl+P è vincolato alla catena del contesto da cui è stato aperto: Master oppure Monitor. Nessuna navigazione orizzontale tra le due catene. Frecce verticali (anche Ctrl+Su/Giù), ricerca per iniziale, pagina, stato e riordino rimangono all'interno della catena. Anche Ctrl+Su/Giù fuori dal browser si ferma ai limiti Master/Monitor. Sono mantenuti Offline/Online, Bypass, Delta Solo, profili e GUID esistenti. Test statico `Testing/test46_3_static.py`, collaudo REAPER necessario; nessuna build locale.

## 0.0.46.2 — Browser Delta Solo e FX Offline

- Ctrl+D nel browser: Delta Solo dell’FX evidenziato. Ctrl+Maiusc+D: disattiva tutti i Delta Solo del progetto.
- Ctrl+Alt+B (Lua): mette Offline/Online l’FX corrente della griglia o l’effetto evidenziato nel browser.
- Annunci di stato aggiornati; riassociazione sicura del browser dopo il cambio Offline, mantenendo GUID e posizione. Lo stato offline passa al browser perché un FX offline può non esporre parametri.
- Verifiche statiche aggiunte, senza compilazioni locali.

## 0.0.46.1 — Correzione scorciatoie FX Params

- Rimossa Ctrl+Pagina Su/Giù dalla gestione FX Params e dal browser FX: non va più a un’altra traccia.
- Ctrl+Su/Giù resta cambio FX; Ctrl+Maiusc+Su/Giù resta cambio traccia.
- Pagina Su/Giù senza modificatori continua a spostarsi di 5 FX nel browser; tutto il resto invariato.
- Correzione soltanto sorgente; non è stata eseguita alcuna compilazione.

## 0.0.46 — FX Chain, Take FX, browser

- Ctrl+P navigazione nel browser FX con Master/Monitor, conteggio e tasti rapidi.
- Ctrl+Sinistra/Destra per gli item con Take FX; Ctrl+W ritorna ai Track FX.
- Ctrl+Maiusc+Su/Giù rimane il solo comando LReaParams per cambiare traccia con FX; rimossa la combinazione duplicata Ctrl+Pagina Su/Giù (ora non intercettata).
- Ctrl+Maiusc+Su/Giù nel browser sposta gli FX nella stessa catena con Undo.
- Ctrl+Maiusc+F e Alt+Maiusc+F aprono finestre native dopo rilascio focus.
- Nuovo test statico TEST46, nessuna compilazione locale.

## 0.0.45 — Clipboard FX e Default Snapshot sicuri

Clipboard sistema: Ctrl+C copia il valore normalizzato del parametro (nuova funzione nativa), Ctrl+Alt+Maiusc+C copia l'intero FX in formato Lua `FXPARAM_SNAPSHOT_V1`, Ctrl+V applica il contenuto FX solo dopo la validazione. F7 mantiene Ctrl+C/X/V strutturali; EDIT Windows mantiene la Clipboard testuale. Default reset rinforzato con controlli preventivi e rollback su errore. Vedi `Docs/TEST45_CLIPBOARD_DEFAULTS.md`. Nessuna compilazione locale.

## 0.0.44.5 — Navigazione indietro con Maiusc

- Maiusc+lettera/numero/punteggiatura passa al parametro precedente con la stessa iniziale; senza Maiusc continua in avanti.
- Supporto Plugin/Custom Order, gruppi, ricerche filtrate e F7; nessuna modifica agli input dei campi testo e alla memoria persistente FX.
- Test statico TEST44.5 e workflow aggiornati; nessuna compilazione locale.

## 0.0.44.4 — GitHub Actions compilation hotfix

- Fixed MSVC C2065 in `src/InputRouter.cpp`: `VK_0` is not defined in Windows SDK; use `'0'` (virtual-key 0x30).
- Added a regression assertion in the already-registered TEST44.4 static suite.
- Kept source and package version 0.0.44.4; no runtime changes intended.
- No local C++ compilation.

## 0.0.44.4 — Persistent FX positions

- Per-plugin `.fx` LastParam read/write as in Lua; survives REAPER restart.
- Restore from profile if no per-instance session memory; save only on exit/switch.
- Atomic verified position-only profile update with SHA-256 conflict check and backups.
- Background MIDI snapshot cannot overwrite a newer position.
- Added static checks and native profile CTest cases (GitHub Actions only).

## 0.0.44.3 — Navigazione rapida per iniziale (pre-0.0.45)

- Riprodotto `list_cycle_by_initial` del Lua: pressione ripetuta di lettere, cifre e punteggiatura per ciclare tra i nomi dei parametri visibili; ritorno circolare, silenzio se assente.
- Traduzione locale di key-down Windows con `ToUnicodeEx` (layout, Shift, AltGr) senza generare WM_CHAR o alterare lo stato dei tasti morti.
- Compatibile con Plugin Order, Custom Order, gruppi, ricerche filtrate e F7; conservazione selezioni e memoria sessione.
- Nessuna modifica a MIDI, Auto, ReaEQ, ReaComp, ReaGate, Track Params, profili o trasporto Space/Ctrl+Space.
- Solo audit e verifiche statiche. Non compilato né eseguito in REAPER.

## 0.0.44.2 — Detector Input sparse host normalization
- Decode SignIn as raw enum or as normalized [0,1] using the 1084-step host scale.
- Remove the incorrect raw-range prerequisite for normalized fallback.
- Verify real readback before announcing success for all eight modes.
- Both ReaComp and ReaGate, including Value and MIDI CC; Track Params unchanged.

## 0.0.44.1 — ReaComp/ReaGate: memoria della posizione e Detector Input
- Ripristino della posizione tramite GUID e indice del parametro, accettando sia il nome originale sia l’alias accessibile del Lua: evita il ritorno a Threshold causato da differenze come Hipass / Detector Highpass.
- Detector input: mantiene gli otto valori raw discreti del Lua. Se REAPER non conferma il valore richiesto e lo include nell’intervallo dichiarato del parametro, tenta anche la corrispondente scrittura normalizzata; verifica poi il valore finale. Non annuncia modalità non applicate.
- In caso di mancata applicazione pronuncia `Detector input unchanged`; dettagli tecnici (valore richiesto, risposta API, intervallo) soltanto in OutputDebugStringA, non a NVDA.
- Nessuna modifica a Track Params, ReaEQ, MIDI CC globale, dati `.fx`, scorciatoie o trasporto. Verifiche statiche; nessuna compilazione locale. La compatibilità con le modalità alte di ReaComp/ReaGate richiede un test REAPER reale.

## 0.0.44 GitHub Actions static-test correction
- Fixed the TEST42 source check that rejected version 0.0.44 and prevented CMake from starting.
- Historical regression tests now compare against their minimum supported version rather than pinning a future release number.
- No C++ source, REAPER runtime behavior, or Track Params changes. GitHub Actions will compile and test natively.

## 0.0.44 — ReaComp e ReaGate accessibili

- Adattatori Lua per Plugin Order, alias, Detector input discreto a otto
  sorgenti, toggle On/Off e formato RMS size di ReaComp.
- Riepilogo read-only Detector filter range con ID Lua -200000/-210000;
  riconosciuto in F7, F8 e nei vecchi profili .fx, senza alterare l'audio.
- ReaGate: Invert gate, pre-open/Lookahead, blocco MIDI e ordine Lua.
- MIDI CC del detector usa solo raw validi e pickup; mantenuti Ctrl+Spazio
  della 0.0.43.5, ReaEQ e Track Params.
- Test Python statico e fixture C++ per GitHub Actions; nessuna build locale.

## 0.0.43.5 — Inoltro Ctrl+Spazio prima dell'Action List

- Riparato il percorso dei tasti, non soltanto la chiamata 40073: il vecchio Ctrl+Spazio poteva raggiungere REAPER due volte tramite l'acceleratore nativo e la DLL, producendo uno Stop al posto di Pause e un riavvio dal cursore.
- Aggiunto hook `WH_GETMESSAGE` **thread-local** anche per il controllo nativo Grid/Value e filtro Ctrl+Spazio nel backend SDK; il tasto down viene consumato prima della traduzione nativa, l'up corrispondente è consumato, ripetizioni non eseguono più azioni.
- Lo stesso Ctrl+Spazio viene messo nella coda già esistente della navigazione e continua a usare Play/Pause REAPER `40073` una sola volta; nessuna modifica a Spazio semplice e Maiusc+Spazio.
- Esclusi campi EDIT, tasti aggiuntivi, altri processi/finestra, Track Params. Rilascio automatico hook al termine della navigazione.
- Solo controlli statici; non compilato né provato con REAPER/NVDA.

# 0.0.43.4 — Ctrl+Spazio: azione nativa REAPER 40073

- Ctrl+Spazio da FX Params richiama direttamente `Main_OnCommand(40073, 0)`, per Play/pause reale con ripresa dal punto di pausa; rimosso il ramo manuale `OnPauseButton` / `OnPlayButton` da questo comando.
- Invariati Spazio (Play/stop), Maiusc+Spazio in F7, campi EDIT, Track Params, ReaEQ, profili e MIDI CC.
- Aggiunti test statici e guida `Docs/TEST43_4_NATIVE_PLAY_PAUSE.md`; nessuna compilazione locale.

# 0.0.43.3 — Trasporto FX Params con Spazio / Ctrl+Spazio

- Spazio: Play/Stop via azione REAPER 40044; dalla pausa ripresa immediata via `OnPlayButton`.
- Ctrl+Spazio: Play/Pause; `OnPauseButton` mentre suona/registra, `OnPlayButton` da fermo/in pausa; fallback all'azione 40073.
- Routing nella griglia, Value, F7 ed FX Memories F8; nessuna retrigger per auto-repeat.
- Maiusc+Spazio conserva la selezione in F7. Ricerca, rinomina e campo numerico nativo non intercettano lo Spazio.
- Nessuna modifica a ReaEQ, Track Params, CC/Auto, profili o DLL/Action IDs. Solo sorgenti e test statici; nessuna compilazione locale.

# 0.0.43.2 — ReaEQ: evitare falsi messaggi di errore sulle bande

- Corretto `ReaEQ band update failed` dopo modifiche riuscite di Band Enabled e Band Type: il valore restituito dall'API di scrittura da solo non prova il fallimento.
- Dopo la scrittura, verifica la proprietà tramite lettura indipendente; se necessario controlla anche i campi Enabled/Type nel chunk effettivo di ReaEQ.
- Non nasconde gli errori autentici: se la scrittura non viene accettata e nessuna lettura conferma il valore richiesto, mantiene il messaggio di errore.
- Restano invariati aggiunta/rimozione delle bande, ordine dei parametri, FX/Track Params, MIDI, profili e accessibilità. Test statici e C++ preparati per GitHub Actions; nessuna compilazione locale.

# 0.0.43.1 — ReaEQ: corretta posizione di Enabled e Type

- Plugin Order ReaEQ resta esattamente nell’ordine del Lua: `Enabled`, `Type`, tre parametri reali per banda, poi gestione bande e controlli globali.
- Fix per vecchie Custom Order `.fx` nate prima dei virtuali: invece di accodare tutti Enabled/Type dopo Global Gain, inserisce i virtuali mancanti prima del primo parametro reale della rispettiva banda.
- Ripara il caso delle Custom Order già salvate dalla 0.0.43 con il blocco dei virtuali interamente in coda. Lascia intatti eventuali spostamenti espliciti dei virtuali che non corrispondono a quel blocco automatico.
- Non modifica automaticamente i file `.fx`; preserva alias, gruppi, selezione, MIDI CC e memoria. Aggiunti test C++ per ordine, migrazione e idempotenza, più verifica non compilante nel workflow.
- Nessuna compilazione locale o verifica runtime in REAPER/NVDA.

# 0.0.43 — ReaEQ: controlli virtuali, bande strutturali

- Mappatura degli ID virtuali Lua, tipi filtro non lineari, proprietà Enabled/Type e Target/Band Action, chunk 33*N e controlli di verifica/Undo.
- Custom Order/F7 e F8 leggono gli ID virtuali esistenti; il motore MIDI e il reset individuale li riconoscono.
- Test C++ per codec, conversioni, add/remove, test statico e workflow aggiornato.
- La compilazione Windows e i test REAPER/NVDA restano da effettuare.

# 0.0.42.1 — FX Params: stato MIDI CC nei parametri (prima della 0.43)

- Annuncio del CC associato **subito dopo nome e valore** e **prima di Auto**: `Cutoff, 1200 Hz. CC channel 1 CC 74. Auto`.
- Fonte della mappa identica a F8 (`fxOrder_.ccLinks`); link visualizzato anche con Fixed CC temporaneamente disattivato. Nessun profilo viene modificato.
- Fallback in sola lettura ai MIDI Learn nativi di REAPER (`param.N.learn.midi1`) per Track/Take FX, se manca il link interno; non crea link né cattura CC.
- Durante Floating CC i normali link fissi vengono temporaneamente omessi dal parlato come nel Lua originale.
- Riuso del metodo `currentParameterSpeech()` in Grid, F7, Value e NVDA+Freccia Su. Alt+Frecce continua a pronunciare solo il valore.
- Nessuna modifica a MIDI runtime, Track Params, profili, UI, scorciatoie, action ID o backend GitHub Actions. Nessuna build locale effettuata.

# 0.0.42 — FX Params: Ctrl+Q e MIDI in background

- Ctrl+Q restituisce il focus a REAPER lasciando parcheggiato un singolo contesto MIDI completo (learn/fixed/pickup/floating), se attivo.
- Timer main-thread continua a ricevere CC anche senza finestra FX Params; nessuna intercettazione globale della tastiera.
- Identità progetto/traccia/take/FX verificata a ogni ciclo; contesti scaduti disattivati in sicurezza e reintegro al rientro sullo stesso FX senza doppie applicazioni.
- Rilegatura sicura del callback FxOrder al navigatore parcheggiato; persistenza `.fx` invariata.
- Nuova azione `_LREAPARAMSSTOPMIDIBACKGROUND` per fermare manualmente il controllo; F8 mostra `Channel N. CC M`.
- Test statici e documentazione del collaudo hardware aggiunti; **nessuna build locale** né verifica REAPER/NVDA/MIDI eseguita.

# 0.0.41 — FX Params: annuncio stato Auto

- Corretto `currentParameterSpeech()` per annunciare `. Auto` dopo il valore solo se il parametro fisico dispone di un envelope REAPER attivo (ACT=1).
- La lettura si riflette su Grid, F7, navigazione Alt+F3/F4, annunci del cambio FX e NVDA+Freccia Su.
- Nessun suffisso per gli envelope non attivi o i parametri virtuali; le modifiche valore continuano ad annunciare soltanto il valore.
- Lette le informazioni con l’API già usata dal navigatore; buffer riutilizzato per limitare le allocazioni.
- Non cambia l’attivazione dell’automazione; codice non compilato, serve collaudo in REAPER.

# Modifiche rispetto a TEST30

- Rimozione completa del terzo navigatore dal codice attivo, azione e menu; rimozione Lua dedicato, parser/fixture .pp e ramo Params dall'importatore.
- ID REAPER conservati e indici azione sostituiti con enum.
- Motore MIDI timer main thread, batch cronologico limitato, learn persistente, disassociazione, fixed, pickup, anti-jitter e Floating.
- Parlato MIDI per parametro con chiavi Lua e accorpamento notifiche.
- Preset Track/Take, envelope ACT/VIS circoscritti all'FX e navigazione Auto.
- EDIT numerico, formatter monotoni e raw esplicito; storico persistente e import in sola lettura da Lua.
- Compare virtuale con snapshot per identità; default ReaEQ strutturale e Gain esteso.
- F8 conferma Default, cancellazione/rigenerazione, pulizia delle memorie; supporto Compare nei profili e nella rinomina F7.
- Test C++ pickup/codec e salvataggio profili, nuovi controlli statici e workflow aggiornato.

Non completati: vedere Status.md e FxCommandMatrix.csv. Nessuna compilazione locale. TrackNavigator.cpp resta byte per byte uguale a TEST30.

## Analisi degli allegati

La specifica è il TXT estratto da ISTRUZIONI_ASTRA_LREAPARAMS(1).zip, conservato come Specification.txt. La base è TEST30; i due Lua contenuti in Scripts(3).zip sono identici, byte per byte, a quelli in Legacy nella base. Il terzo Lua è stato letto soltanto per identificare cosa eliminare e non viene distribuito.

- SHA-256 ISTRUZIONI_ASTRA_LREAPARAMS(1).zip: `da15c5be70420e1f141e2bae8fae8932e2bc4a15c36ef1cf0b21785c41d94065`
- SHA-256 LReaParams_TEST30_F7_CTRL_SHIFT_HOME_END_GITHUB_READY_SOURCE(1).zip: `1bcbc4867004aa5bf3fb2a16cc1f4bb3da5665fa887cc10b4c2a8099ef6ded62`
- SHA-256 Scripts(3).zip: `44d7174608bde1dc5895d97d72ad30202e79997fa8cab578f5964cafc08dcbcc`
