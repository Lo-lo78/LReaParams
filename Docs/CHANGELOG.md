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
