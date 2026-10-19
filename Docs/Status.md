# TEST56.10.2 — F5 connettore pin audio, 128 canali (solo sorgente)

F5 ora usa il numero reale di canali della traccia fino a 128. I canali 65–128 usano il secondo banco API `pin + 0x1000000`; ogni banco rimane indipendente, comprese lettura, toggle, Undo e readback. F4, F1–F3, FX Params e profili `.tp` non sono stati modificati; F6 è ancora da migrare. [Piano di test](TEST56_10_F5_AUDIO_PIN_CONNECTOR.md). Solo controlli statici Python; build GitHub Actions e prova NVDA/REAPER da eseguire.

# TEST56.9.1 — F4 Fixed CC regression correction

- Fixed: the project `.tp` storage writer and native profile parser rejected
  the `FxTcp|{trackGUID}|{fxGUID}|parameter` identity. This aborted learn and
  returned focus to REAPER TCP. Both layers now validate this form safely.
- Ctrl+T speech for F4 uses the same new validation. Existing F1–F3 mappings
  and the Floating CC engine are unchanged.
- A future disk/storage failure in CC learn is reported in NVDA without
  terminating navigation. Existing in-memory mappings are restored on failure.
- 14 selected static suites plus overall audit passed. The historical full
  source-only suite timed out after earlier checks; not claimed complete.
- No native build, CTest or MIDI hardware tests run locally.

## TEST56.4 — F4 search and visible TCP grid columns

Source-only changes complete. GitHub Actions native build, CTest and REAPER/NVDA verification pending.

## TEST56.3 — F4 keyboard and Value

F6 riservato; Alt+Invio apre i controlli TCP visibili. Ricerca ciclica e inversa nelle due griglie. Valori FX TCP modificabili mediante Value e Alt+frecce, con validazione GUID e Undo, Step persistenti nello stesso `.tp`. Test di sorgente, nessuna build locale. [Guida](TEST56_3_F4_VALUE_CYCLIC_NAVIGATION.md).

## TEST56.2 — F4 parameter selection

Nuova griglia accessibile con nomi dei parametri FX, altezza regolabile con F1/F2 e operazioni TCP tramite Invio/Ctrl+Invio. Comandi F4/F6 in linea con il Lua, contenuti senza valori audio. Protezione FXID, verifica visibilità REAPER e Undo.

**Source-only; MSVC GitHub Actions e test REAPER/NVDA non ancora eseguiti.**

## 0.0.56 — TEST56.1: F4 FX TCP navigation (source-only)

Prima griglia F4 C++ basata su CountTCPFXParms/GetTCPFXParm. Colonne per FX (incluse quelle prive di parametri TCP), righe per controlli TCP esposti, bordi silenziosi, continuità F1/F2/F3, lettura NVDA e navigazione fra tracce con FX. **Nessun editor né MIDI F4 in questa TEST**. Solo controlli sorgente: MSVC GitHub Actions e REAPER/NVDA restano da provare. [Guida](TEST56_1_F4_TCP_NAVIGATION.md).

## TEST55.12 — Width envelope in F1 (source-only)

- Corretto il percorso del parametro Width: riconoscimento dei blocchi `<WIDTHENV2` e `<WIDTHENV` nella traccia, creazione con GUID/punto iniziale come nel Lua originale, attivazione/armamento e verifica reale del chunk senza dipendere soltanto dal puntatore restituito dall’API.
- Conservati i punti esistenti, gli automation item e il routing; rollback se REAPER rifiuta il risultato. Ctrl+Maiusc+A invariato.
- Build C++ e collaudo NVDA/REAPER NON eseguiti localmente. GitHub Actions e test audio richiesti.

## TEST55.9 + TEST55.10 — final pass on Track Params F1/F2/F3 (source-only)

- Ctrl+Q now parks **Track Params MIDI** in a separate background-only navigator and restores ordinary TCP focus. Fixed CC maps continue to target exact saved track GUIDs and outgoing routes; Floating CC keeps the current parameter context from before Ctrl+Q. A fresh sequence baseline blocks stale events. Both FX and Track background MIDI are stopped by the existing stop-background-MIDI REAPER action; no two active navigators share a controller event.
- **Ctrl+Maiusc+Alt+A** is unified in FX and Track Params. Both require Y/Enter confirmation (N/Esc cancels). FX scope: all envelopes belonging to the current FX (track FX or Take FX). Track scope: current track envelopes including FX, plus outgoing send envelopes resolved in destination AUXRECV. Points and automation items are preserved; ACT/VIS are disabled, no envelope is deleted. A single REAPER Undo block covers each operation.
- **Ctrl+Maiusc+A on F1 Width** can now create a standard WIDTHENV2 using an inspected, complete track chunk if the envelope is missing. Native name/chunk lookup is validated, the resulting envelope is checked, and unsuccessful creation is rolled back. No guessed native action IDs and no changes to other track chunks. It may fail safely when REAPER rejects the inserted envelope.
- Other F1/F2/F3 behavior, navigation, memory per-project `.tp`, FX Compare F8 and FX Default recovery remain unchanged. Test snapshots, target scope, REAPER actions, NVDA prompts and SWS routing should be checked on GitHub/REAPER before moving to F4.
- Validation: all source-only Python tests + Tools/audit.py; NO native build, MSVC/CTest execution or REAPER test was run here. GitHub Actions will compile and execute C++ tests; runtime checks remain necessary for Width and parked MIDI.

## TEST55.8 — FX Default restoration (source only)

- Fixed legacy saved Default values being incorrectly rejected when synth presets change parameter names without changing native parameter IDs and count. Complete/safe index fallback; reject actual reorders and changed counts.
- Enter on Default in FX Memories restores sound and returns to normal FX grid without erasing other FX memories.
- Delete on Default still requires a Yes/No confirmation for restore + clear.
- Original/Compare F8, Track Params, all .fx/.tp mappings and accessibility shortcuts remain unchanged.
- Native MSVC compilation and REAPER/NVDA audible test not performed locally. GitHub Actions must verify.

## TEST55.7 — F8 Original al primo ingresso (source only)
- L’ingresso cattura l’attuale stato dell’FX senza applicarlo. Original/Compare sopravvivono a uscita e rientro nello stesso FX durante la sessione e sono separati per istanza. F8 doppio continua a essere l’unico aggiornamento esplicito del riferimento. Le cache dei progetti chiusi vengono scartate. [Guida](TEST55_7_FIRST_ENTRY_ORIGINAL.md). Build e runtime da verificare.

## TEST55.6 — F8 Compare A/B (source only)
- Singolo F8 alterna; doppio F8 conferma Original. Nessuna modifica sonora all'ingresso in FX Params.
- Compare non più voce nella navigazione o nelle memorie. Gestori sempre con Ctrl+Maiusc+M.
- GitHub Actions: compilazione C++ e test runtime ancora da confermare. [Guida](TEST55_6_F8_COMPARE_AB.md).

## TEST55.5 — Gestori memorie, shortcut uniforme (source only)
- **Ctrl+Maiusc+M** in FX Params apre FX Memories; in Track Params apre Track Memories. Stesso tasto o Esc chiude il gestore.
- **F8 di FX Params è libero**; **Alt+F8 Track** non apre più le memorie. Le azioni native REAPER mantengono gli stessi Command ID.
- Nessun cambiamento a preferenze, associazioni MIDI, formato profili o memoria persistente. [Verifiche](TEST55_5_UNIFIED_MEMORY_SHORTCUT.md).

## TEST55.4 — Unified memory defaults (source only)
- Track Params: Fixed/Floating CC speech OFF unless enabled with Ctrl+T for a specific target GUID. Historical generic CC speech flags are preserved but never leak into physical targets.
- Track Memories: only stored deviations from defaults; no zero steps, empty slots, or automatic navigation entries. Explicit Volume Ranges replace the automatic navigation column.
- FX Params F8 now directly opens the same FX Memories manager even outside F7. REAPER actions still launch their existing managers.
- 56/56 source-only scripts passed, plus Tools/audit.py. Native compilation and NVDA/REAPER behavior NOT TESTED locally.

## 0.0.55 — TEST55.3 Fixed CC per GUID della traccia

Bindings Fixed indipendenti dal cursore, salvati nel `.tp` di progetto; legacy type-wide inattivi, senza perdita dati. Vedi Docs/TEST55_3_FIXED_CC_PER_TRACK.md.

## 0.0.55 — Track Memories e range Volume

Track Memories autonomo o Alt+F8, cinque categorie, 12 slot di traccia persistenti per progetto, gestione MIDI CC Fixed e preferenze dei parametri, range volume per pagina con Ctrl+Maiusc+I. F4–F8 e automazioni globali restano incompleti. Solo sorgente e verifiche statiche. [Guida](TEST55_TRACK_MEMORIES.md).

## 0.0.54.4 — Sincronizzazione Track Params, FX Params e TCP

La traccia proprietaria del navigatore corrente è la fonte autorevole. I movimenti normali in F1 e fra tracce con routing in F2/F3 modificano la reale selezione TCP. Ctrl+Tab passa il riferimento della traccia corrente in entrambe le direzioni, e l'apertura di FX Params da una catena/take seleziona la traccia proprietaria in REAPER. Le selezioni multiple create esplicitamente con Maiusc continuano a funzionare. Test nativi/GitHub Actions e REAPER/NVDA ancora da eseguire.

## 0.0.54.3 — Annunci Ctrl+E e catene FX vuote

Tolto il doppio `Set.` dopo la conferma numerica; contesti Track/Take senza FX segnalati senza selezioni implicite di altre catene. Ctrl+Tab da Track Params su traccia priva di FX resta in Track Params. [Dettagli](TEST54_3_NUMERIC_SPEECH_EMPTY_FX.md). Solo sorgente.

## 0.0.54.2 — Automazioni Track e Ctrl+Tab

Ctrl+Maiusc+A senza Auto duplicato. Automazioni Volume/Pan/Mute di send e receive: stato ACT/VIS/ARM sul relativo AUXRECV, con riconoscimento di routing duplicati; creazione via SWS/BR quando mancante, con verifica. Ctrl+Tab alterna i navigatori FX e Track. [Guida e limiti](TEST54_2_AUTOMATION_CTRL_TAB.md). Solo sorgente, da compilare su GitHub Actions.

## 0.0.54.1 — Memorie Track per progetto

Profilo `.tp` per progetto con importazione non distruttiva dei CC globali. Stato Fixed On/Off persistente; Step, parlato e navigazione nello stesso profilo. Spazio/Ctrl+Spazio come FX Params. [Dettagli](TEST54_1_PROJECT_TP_FIXED_CC.md). F4 futuro, non ancora migrato.

## 0.0.54 — TEST54 prima migrazione runtime MIDI Track e Ctrl+E

MIDI CC F1/F2/F3 (Fixed, Floating, pickup, learn e parlato); Ctrl+E con campo nativo; Enter su intestazioni send/receive si sposta sul collegamento gemello, anche duplicato. Non ancora completato: Ctrl+Q Track background, automazioni Width/Send/Receive da creare, clear all, range volume e F4-F8. [Dettagli](TEST54_TRACK_CC_NUMERIC_ROUTING.md). Solo 49 suite statiche, nessuna compilazione o verifica NVDA.

## 0.0.53 — TEST53.2: annunci direzionali F2/F3

Correzione TEST53.1: Verticale = solo parametro e valore (header solo Send/Receive); Orizzontale = contesto traccia soltanto al primo link o al cambio peer, e suffisso progressivo dei collegamenti della stessa traccia. Tab completo, Search cleared breve. [Test](TEST53_2_DIRECTIONAL_ROUTING_SPEECH.md). Da compilare in GitHub Actions e provare con NVDA.

## 0.0.53 — TEST53.1 bugfix paste, speech, search

Mantenuta la TEST53, corretto Ctrl+V rispetto al cursore F1 mediante GUID e riposizionamento del gruppo; annunci completi per ogni colonna e riga F2/F3, numerazione peer ripetuti; `Search cleared` in uscita dal filtro senza uscire dal navigatore. [Test manuale](TEST53_1_TRACK_PASTE_SPEECH_SEARCH.md).

## 0.0.53 — F1/F2/F3 Ctrl+F

Nuovo filtro basato sul Lua, input tramite EDIT nativo NVDA, ricerca per traccia o colonne Send/Receive e preservazione degli indici reali anche per i routing duplicati. La persistenza `.tp` rimane invariata. [Guida](TEST53_TRACK_FILTERS.md). Restano da migrare MIDI CC runtime Track, envelope mancanti, clear-all e sezioni F4-F8. Nessuna build locale.

# 0.0.51 — estesa prima di F4

F1: folder aperte/chiuse e suffisso `end folder Nome` per folder annidate; Ctrl+Invio toggla. F2/F3: Canc elimina il singolo send/receive (anche istanze duplicate); MIDI Merge è stato derivato da MIDI source, non un parametro con bit autonomo. [Verifiche](TEST51_FOLDERS_AND_DELETE.md). Non è completa la migrazione di F1/F2/F3. Solo sorgente, nessuna build locale.

# 0.0.51 (TEST51 aggiornata): Track Params — F1 creazione send/receive, F2/F3 routing

**F1 crea send e receive tramite Ctrl+Maiusc+S e Ctrl+Maiusc+R in due passaggi**, mantenendo la selezione multipla originale del Lua. Esc cancella la procedura in sospeso, Tab ne legge lo stato. I collegamenti sono raggruppati in una sola operazione Undo e le tracce memorizzate vengono riconsultate per GUID. [Guida TEST51 add routing](TEST51_F1_ADD_SEND_RECEIVE.md).

Altre novità TEST51: Ctrl+Alt+Su/Giù naviga fra folder; Ctrl+Maiusc+V rimosso. F2/F3 mantengono 14 voci verticali per send/receive; source/destination audio editabili entro 128 canali, con espansione automatica delle tracce reali, e MIDI bus 0–16. Nessuna modifica ai profili `.tp`, alla memoria o a FX Params. **Mancano ancora la cancellazione dei singoli send/receive in F2/F3, salto peer, filtri, automazioni e CC runtime, oltre a F4–F8.** Solo test statici, build GitHub Actions e collaudo REAPER/NVDA ancora necessari. [TEST51 F2/F3](TEST51_TRACK_ROUTING_AND_SHORTCUTS.md).

# 0.0.50 (TEST50): Track Params — F1 selezione e Tab

Tab sostituisce Ctrl+R per le informazioni su Track Params. F1 comprende selezione reale delle tracce tramite gesti Lua, intervalli cumulativi, navigazione fra folder e Ctrl+Maiusc+V per la modalità Value; gli annunci segnalano la selezione. La memoria persistente `.tp` e FX Params restano come TEST49. **Non è la migrazione integrale di F1**: le operazioni clipboard con routing, spostamento fisico delle tracce, filter/ricerca e automazioni devono ancora essere portate dal Lua. GitHub Actions e REAPER/NVDA devono ancora confermare compilazione e comportamento. [TEST50](TEST50_TRACK_F1_SELECTION_TAB.md).

# 0.0.49 (TEST49): Track Params memoria persistente

Il navigatore Track F1/F2/F3 salva Step, annunci delle variazioni e posizioni; Ctrl+T memorizza le preferenze MIDI del Lua senza runtime MIDI Track. Il supporto alle restanti pagine e CC operativi rimane incompleto. [Piano di prova](TEST49_TRACK_PERSISTENT_MEMORY.md). **NON compilato localmente**.

## 0.0.48 — Step per parametro e parlato MIDI CC selettivo (candidato sorgente)

- **Step per parametro:** Alt+Sinistra/Destra mantiene l'intervallo esistente
  `Step -10` ... `Step 0` ... `Step +10`, ma la scala è ora associata al
  **parametro reale** del plugin, non al parametro visitato per ultimo.
  Cambiando parametro, lo Step si ripristina automaticamente. Le copie dello
  stesso parametro in Custom Order condividono lo Step; i parametri diversi no.
- **Persistenza:** i valori sono salvati in `[Extra]` del profilo `.fx` nella
  chiave `lrp_param_step_scales_v1`, con indice, nome host e Step. Il salvataggio
  avviene quando lasci il parametro, cambi FX/traccia o esci dalla finestra,
  non su ogni modifica di valore. Il salvataggio usa il backup e la protezione
  anti-sovrascrittura esistente; non scrive nei progetti REAPER.
- **Retrocompatibilità Lua:** la chiave originale `param_step_scales_v1` non
  viene riscritta. Se non esiste un valore nativo, il vecchio `v3:n` (e le
  codifiche `v2`/numeriche) viene tradotto alla potenza di due più vicina della
  griglia nativa. Poiché Lua aveva 18 moltiplicatori e il C++ usa 21 livelli,
  la sensibilità numerica esatta può differire: è una compatibilità approssimata,
  non una parità dei moltiplicatori. Nomi duplicati ambigui non vengono usati
  come fallback.
- **Ctrl+T:** era già disponibile, ma ora gli annunci delle variazioni MIDI
  sono uniformati al Lua: solo i parametri abilitati parlano; sul parametro
  corrente viene letto il **solo valore**, su un altro parametro nome e valore;
  una variazione formattata identica all'ultima non viene ripetuta. Il parlato
  ordinario (frecce, NVDA+Su) rimane sempre attivo, e gli stati persistono in
  `cc_param_speech_v1::<indice>`.
- **NON finale:** non è ancora stata provata la piena equivalenza con l'intero
  Lua. Mancano almeno il browser gerarchico dei container FX e la verifica di
  casi speciali/preset e dei contesti Take FX; le altre lacune di Status.md e
  FxCommandMatrix.csv restano da censire/chiudere.
- **Validazione:** soltanto verifiche statiche locali. Compilazione MSVC/CTest
  e prova di NVDA, MIDI reale e ripristino dopo riavvio demandate a GitHub Actions
  e al collaudo REAPER. **Nessuna build locale eseguita.**

## 0.0.47 — F7/F8 e sicurezza Default

F8 Default Delete usa conferma Yes/No senza cancellazione preventiva, F7 da F8
è limitato alle colonne supportate dal Lua e Hidden include i virtuali Dynamics.
Conservate memorie, filtri, gruppi e le operazioni F7 esistenti. Sorgente da
compilare su GitHub Actions; consultare `Docs/TEST47_F7_F8_COMPLETION.md`.

## 0.0.46.5 — Ctrl+Maiusc+D include Monitor FX

L'azione nativa `Clear delta solo for all project FX` non garantisce l'azzeramento dei Monitor FX, che appartengono alla catena monitor separata dal progetto. La DLL ora esegue l'azione nativa e verifica separatamente ogni Monitor FX (`0x1000000 + indice`), disattivando eventuali Delta Solo residui e verificando il risultato. Ctrl+D rimane invariato. Nessuna modifica a Track Params e agli altri comportamenti già collaudati.

## 0.0.46.4 — Browser Master/Monitor a colonne

- **Destra:** Master → Monitor FX. **Sinistra:** Monitor FX → Master.
- Ogni colonna mantiene il proprio cursore; non si attraversano catene con i comandi verticali, la ricerca per iniziale o il riordino.
- Browser e griglia rimangono separati; Invio/Ctrl+P dalla colonna corrente apre l'FX effettivamente evidenziato.
- La colonna vuota resta riconoscibile e il ritorno all'altra colonna è possibile.
- Verifica reale rimandata a GitHub Actions e REAPER/NVDA. Nessuna compilazione locale.

## 0.0.46.3 — Browser Master/Monitor FX separati

Quando FX Params viene aperto sulla lista nativa degli effetti, l’FX focalizzato viene scelto prima di eventuali altre catene visibili. La lista interna mantiene gli FX di entrambe le catene Master/Monitor per GUID e memorie, ma **il browser visualizza e naviga solo nella catena di ingresso**. Sono stati rimossi i passaggi Sinistra/Destra fra colonne. Tutti gli spostamenti e i comandi FX rispettano il confine della catena, incluso Ctrl+Su/Giù dalla griglia e Ctrl+Maiusc+Su/Giù per il riordino nel browser. Il titolo indica la catena scelta. Il codice è da compilare e collaudare con GitHub Actions/REAPER.

## 0.0.46.2 — Delta Solo e Offline nel browser FX

- **Ctrl+D** nel browser alterna Delta Solo **soltanto sull’FX evidenziato**, senza cambiare il plugin della griglia o il profilo corrente. **Ctrl+Maiusc+D** ora richiama l’azzeramento Delta Solo globale, come nella griglia.
- **Ctrl+Alt+B** nel browser e nella griglia alterna l’FX **Offline/Online** (stesso shortcut del Lua). L’operazione impiega `TrackFX_SetOffline` / `TakeFX_SetOffline` e verifica lo stato letto dopo il cambiamento.
- Quando si mette offline l’FX dalla griglia, si passa al browser interno per poterlo riportare online: non si lascia un controllo Value con parametri ormai rimossi. La posizione del parametro era già stata salvata prima del cambiamento.
- Anche una catena con tutti gli FX offline può aprire direttamente il browser, per poterli riattivare dopo il riavvio di REAPER.
- Il browser annuncia Offline, Bypassed e Delta Solo soltanto quando attivi; supporta Track FX, Take FX e Monitor FX; resta agganciato al GUID dell’istanza durante la ricostruzione della lista.
- Come nelle versioni precedenti, l’effetto reale sul progetto e la lettura NVDA richiedono collaudo in REAPER. Nessuna compilazione locale.

## 0.0.46.1 — FX Chain, Take FX, browser nativo e browser interno

Aggiunta navigazione per contesto FX: Ctrl+P browser interno (lista separata
con colonne Master/Monitor), Ctrl+Sinistra/Destra fra item Take FX,
Ctrl+W ritorno ai Track FX e Ctrl+Maiusc+Su/Giù fra tracce. Ctrl+Pagina Su/Giù è libero. Il browser
supporta ordinamento degli effetti nella catena e apertura della catena FX
o del browser nativo REAPER. GUID, profili, parametri e memoria persistente
vengono preservati in caso di cambio riuscito; nessuna sostituzione silenziosa
degli FX dopo un riordino. Comandi e collaudo dettagliati in
`Docs/TEST46_FX_CONTEXT_BROWSER.md`.

**Stato:** modifica del codice sorgente, NON ancora compilata e NON
collaudata con REAPER/NVDA. I dettagli del focus e dei trasferimenti di FX
richiedono prova GitHub Actions e runtime. Rimangono le fasi F7/F8 e audit
finale del Lua (0.0.47–0.0.48). Parameter Library continua a essere esclusa.

## 0.0.45 — Clipboard FX e Default Snapshot sicuri

Clipboard sistema: Ctrl+C copia il valore normalizzato del parametro (nuova funzione nativa), Ctrl+Alt+Maiusc+C copia l'intero FX in formato Lua `FXPARAM_SNAPSHOT_V1`, Ctrl+V applica il contenuto FX solo dopo la validazione. F7 mantiene Ctrl+C/X/V strutturali; EDIT Windows mantiene la Clipboard testuale. Default reset rinforzato con controlli preventivi e rollback su errore. Vedi `Docs/TEST45_CLIPBOARD_DEFAULTS.md`. Nessuna compilazione locale.

## 0.0.44.5 — Navigazione inversa per iniziale con Maiusc

Le iniziali digitabili senza Maiusc continuano a ciclare in avanti; con Maiusc la ricerca procede all’indietro, con wrap, sul nome visibile del parametro. Conservate le selezioni F7 e la memoria FX persistente. Vedere TEST44_5_SHIFT_REVERSE_INITIAL.md. Solo sorgente; compilazione tramite GitHub Actions.

## 0.0.44.4 — Last FX parameter persists after REAPER restart

FX Params now stores `LastParam` inside each plugin `.fx` file when the user closes the navigator or switches FX/track. When REAPER restarts, the parameter position is restored from that field if there is no more-specific current session position. Profile edits are backed up and guarded against concurrent changes; a background MIDI navigator cannot overwrite this position. See `Docs/TEST44_4_PERSISTENT_FX_POSITION.md`.

Still source-only, pending MSVC and real REAPER/NVDA tests. The rest of the migration remains incomplete.

# Stato 0.0.44.2 — adattatori ReaComp/ReaGate

Aggiunti in C++ gli adattatori non audio dei parametri speciali di
ReaComp e ReaGate: detector, nomi, interruttori, filtro virtuale,
Custom Order e memorie. Non dichiarata equivalenza completa al Lua,
né eseguita una compilazione locale. Consulta TEST44_REACOMP_REAGATE.md.
Il trasporto Ctrl+Spazio della 0.0.43.5 è stato confermato funzionante
dall'utente; l'adattatore di 0.0.44 resta da collaudare.

# Correzione puntuale 0.0.42.1 — parlato CC e Auto

Questa revisione della 0.0.42 annuncia le associazioni MIDI sui parametri FX
anche fuori da F8, nell'ordine `parametro, valore. CC channel N CC M. Auto`.
L'informazione CC è letta in sola lettura dal profilo FX corrente o,
come fallback, dal learn MIDI nativo REAPER. Non indica se Fixed CC è
attualmente attivato: indica l'esistenza di una mappatura valida. Durante
Floating CC i link fissi sono taciuti come nella lettura del Lua.
`Auto` rimane visibile solo con envelope esistente e ACT=1.
Nessuna modifica alle associazioni o al MIDI in background.
Nessuna compilazione o prova REAPER/NVDA: per quelle usare GitHub Actions.

# Stato sorgente 0.0.42 — MIDI CC in background

La 0.0.42 mantiene l'annuncio `. Auto` della 0.0.41 e aggiunge **Ctrl+Q**: dopo il ritorno al focus di REAPER, il timer principale continua a elaborare i CC del contesto FX parcheggiato, anche quando il navigatore non è visibile. L'azione `_LREAPARAMSSTOPMIDIBACKGROUND` ferma esplicitamente il contesto. Consultare `TEST42_BACKGROUND_MIDI.md`. Il nuovo codice non è stato compilato o collaudato in REAPER.

Questo archivio amplia TEST30 su più fasi della roadmap. NON completa tutta la parità Lua. Non è stata eseguita alcuna compilazione locale, CMake configure, build o prova della DLL. I test C++ inclusi saranno eseguiti dal workflow GitHub Actions dell'utente. Le verifiche Python sono controlli di testo e formati, non provano la correttezza eseguibile del C++.

| Fase | Stato del sorgente | Limiti residui |
|---|---|---|
| 0: eliminazione terzo navigatore | Implementata: azione, dispatch, menu, formato e ramo importazione rimossi; enum per gli indici azione | File preesistenti ignorati, mai eliminati |
| 1: learn CC | Implementato per parametri fisici e Compare, primo CC nuovo, profilo, riassegnazione duplicati, rimozione learn nativo | Non copre i virtuali ReaEQ/ReaComp; colonna F8 legge e seleziona i link ma non è un editor MIDI completo |
| 2: fixed/pickup | Implementati Shift+C, persistenza flag, crossing/tolleranza 1/127, riarmo dopo modifica esterna, anti-jitter Lua; Gain ReaEQ esteso | Attivo anche dopo Ctrl+Q nel singolo contesto parcheggiato, con stop su cambio identità; nessuna polarità inventata (il link Lua salva canale e CC) |
| 3: Floating/parlato | Implementati Ctrl+Shift+C, capture, parametro corrente, pickup, ritorno fixed, Ctrl+T persistente per parametro, accorpamento parlato | Parlato limitato a un annuncio ogni 180 ms; sessione Floating conservata con Ctrl+Q, non ricostruita dopo una chiusura ordinaria o un riavvio |
| 4: automazione | Ctrl+Shift+A ACT/VIS, Ctrl+Shift+Alt+A solo FX corrente, Alt+F3/F4 nella griglia visibile, Undo | Griglia filtrata/gruppo limita la navigazione, mentre Lua può uscire verso la griglia completa; confermare Monitor FX nel runtime |
| 5: preset/numeri/ricerche | Alt+F1/F2; Ctrl+E vero EDIT con inversione dei formatter monotoni o unità raw dichiarate; storico 20 voci, import storico Lua in lettura, salvataggio Settings | Adattatori specifici non monotoni e unità variabili non coperti; i recenti si applicano al recinto corrente; alcuni gesti extra mancanti |
| 6: plugin speciali | ReaEQ: codec chunk, default strutturale, coda wrapper, Gain esteso, virtuali Enabled/Type/Target/Action, aggiunta/rimozione bande in sorgente (NON collaudate in REAPER) | Restano gli adattamenti completi per frequenze/Q e la verifica runtime dell’aggiunta/rimozione bande; ReaComp/ReaGate: adattatori del Lua introdotti in 0.0.44; collaudo runtime necessario |
| 7: Compare/default F8 | Compare virtuale -300000 prima dei tre wrapper, stato per progetto/traccia/take/FX GUID; snapshot normali o chunk ReaEQ; reset, F8 conferma No/Yes e rigenerazione default | ReaEQ Compare non include virtuali non ancora esposti; singolo reset rifiuta numero bande diverso; salvataggi concorrenti mantengono il controllo digest preesistente, non una transazione interprocesso completa |
| 8: F7/F8/contesti | Conservati i controller TEST30, selezioni, duplicati, filtri, gruppi, undo struttura; Compare accetta memorie/alias/CC senza mandare indici negativi al motore fisico | Non concluso audit semantico di tutte le 1109 funzioni Lua FX; persistono differenze rare da verificare |
| 9: consegna | Progetto completo, test statici, test C++ per Actions, matrice e guida | Compilazione Windows e collaudo REAPER/NVDA/OSARA NON eseguiti |

## Elenco storico delle lacune pre-0.0.46 (verificare con le sezioni successive)

- Collaudare i nuovi virtuali ReaEQ e aggiunta/rimozione bande (0.0.43); completare i controlli speciali Frequency/Q e gli adattatori non monotoni del Lua.
- Adattatori ReaComp/ReaGate implementati in 0.0.44, ma richiedono collaudo REAPER e verifica con plugin/versioni reali.
- Clipboard snapshot e copia/incolla completati nella 0.0.45; collaudo dichiarato riuscito dall’utente.
- Browser FX interno, riordino nella catena, navigazione Take/Track e apertura delle finestre native aggiunti nella 0.0.46. Restano da verificare con REAPER e NVDA; non c’è un editor FX Container gerarchico.
- Background MIDI Ctrl+Q implementato per un singolo contesto FX parcheggiato (richiede collaudo hardware); il trasporto Space/Ctrl+Space è presente nel navigatore FX; Ctrl+Space ora invoca 40073 in 0.0.43.4 (da collaudare), ma restano i marker globali e lo switch Ctrl+Tab verso Track Params.
- Compatibilità semantica totale con virtuali negativi dei vecchi profili: le voci non supportate sono conservate come record opachi in ordine, slot, gruppi e associazioni, senza esporle come controlli. Non è possibile modificarle finché manca il relativo adattatore; i backup conservano il precedente .fx.
- La persistenza dei profili preserva sezioni sconosciute, campi Extra e commenti; le sezioni gestite vengono riserializzate, quindi non conserva il posizionamento originale dei commenti ; le voci dinamiche non supportate sono conservate come record opachi.

## Differenze deliberate o conservate da TEST30

Ctrl+R ora apre lo storico Lua; la rilettura completa è su Ctrl+Shift+R. Track Params conserva Ctrl+R e il suo codice non è stato modificato. Alt+G/Alt+M, Ctrl+Shift+Up/Down e Ctrl+D mantengono il comportamento TEST30 autorizzato dall'handoff anche dove il vecchio Lua differisce. F12 singolo resta riservato, Ctrl+F12 conserva slot 12, Alt+F10/F11/F12 resta a OSARA. F10 e Ctrl+Tab non aprono una libreria. Il tasto P rimane assegnabile dall'utente.

Il pacchetto è un candidato sorgente da compilare e verificare: non va descritto come migrazione completa o DLL già funzionante.

- 0.0.43.1: correzione posizione di Enabled/Type nelle Custom Order esistenti di ReaEQ; richiede test NVDA sul vecchio profilo.

- 0.0.43.2: verifica scrittura ReaEQ Enabled/Type dopo il setter per evitare false segnalazioni `ReaEQ band update failed`; collaudo REAPER necessario.

## 0.0.44.1 source fix
Position recovery now accepts Lua aliases as well as original REAPER parameter names. The detector setter tries exact raw values first, then normalized writing only within a verified host range; debug readback captures unconfirmed high-value modes. Physical REAPER testing pending.


## 0.0.44.3 — Navigazione rapida per iniziale (prima di 0.0.45)

Nella griglia FX Params (Plugin Order, Custom Order, gruppi, risultati filtrati
e editor F7), premere un carattere stampabile porta al **prossimo parametro
visibile che inizia con quel carattere**, seguendo la lista circolarmente.
Premendo `P` più volte si cicla per esempio tra `Pan`, `Portamento`, e
qualsiasi altro parametro che inizi con P; analogamente `1`, `#`, `(`,
`-` e altri caratteri di punteggiatura, dove presenti nelle etichette.
Le lettere sono confrontate senza distinzione tra maiuscole/minuscole.
Se non c'è corrispondenza, nessun annuncio e nessun cambiamento della posizione.
Il caso di un'unica corrispondenza rilegge il parametro anche se è già corrente.

La conversione usa `ToUnicodeEx` e la disposizione tastiera Windows corrente:
non si confondono i codici VK_OEM della punteggiatura con i caratteri digitati.
Le scorciatoie con Ctrl/Alt, il trasporto, gli editor di testo Windows,
Value, F8 e la navigazione Track Params non sono modificati.
La posizione raggiunta usa la stessa memoria di sessione della navigazione
ordinaria; in F7 le selezioni esistenti vengono conservate.

**Solo sorgenti:** compilazione esclusivamente con GitHub Actions.
Per il collaudo, provare una P ripetuta, numeri e punteggiatura su un plugin
con etichette corrispondenti; controllare anche F7 e un gruppo salvato.
