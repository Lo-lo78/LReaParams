# LReaParams 0.0.44.1 — ReaComp / ReaGate (sorgente GitHub Actions)

Questa versione riparte dalla 0.0.43.5 già collaudata dall'utente per
Ctrl+Spazio e aggiunge le funzioni accessibili del Lua FX Params per
**ReaComp** e **ReaGate**: nomi e ordine dei parametri, scelta discreta
Detector input, toggle On/Off, RMS/Peak, riepilogo virtuale dei filtri,
F7/F8 e MIDI CC del detector. Dettagli e prove in
`Docs/TEST44_REACOMP_REAGATE.md`.

**Non compilare localmente**. Consegnato esclusivamente il sorgente C++,
workflow GitHub Actions, SDK congelato, Lua originali e test. L'esito dei
test C++ e il comportamento in REAPER/NVDA sono ancora da verificare.

---

# LReaParams 0.0.43.5 — Ctrl+Spazio senza doppio inoltro a REAPER (solo sorgente)

**Correzione del problema confermato in REAPER:** il comando Play/Pause 40073 da solo non basta se la **stessa pressione fisica** di Ctrl+Spazio raggiunge anche l'Action List nativa di REAPER. Il Lua usa infatti `JS_VKeys_Intercept` per impedire questa seconda interpretazione del tasto. Nella DLL ora `WH_GETMESSAGE`, limitato al thread dell'interfaccia di REAPER e attivo esclusivamente durante la navigazione, cattura Ctrl+Spazio **prima** delle scorciatoie Main: accoda una sola operazione a FX Params e neutralizza il messaggio originale. Copre sia la finestra nativa NVDA (Grid/Value/F7/F8) sia il backend senza finestra.

REAPER esegue ancora `40073` in FX Params per Ctrl+Spazio; Spazio da solo usa `40044` (con ripresa immediata dalla pausa), e Maiusc+Spazio in F7 seleziona normalmente. La cattura evita campi Windows EDIT, Alt/Maiusc, NVDA/Insert e Track Params. Il relativo hook si disinstalla alla chiusura del navigatore. Nessuna scorciatoia globale rimane attiva in background.

**Non è stato compilato o collaudato in REAPER:** i controlli Python sono soltanto statici. Verifica prima la sequenza Ctrl+Spazio x3 con la 0.0.43.5, confrontando con l'azione di REAPER quando FX Params è chiuso. Se ancora non funziona, raccogliere lo stato Play/Pause/Stop annunciato da OSARA dopo ciascuna pressione prima di modificare altro.

# LReaParams 0.0.43.4 — Ctrl+Spazio: Play/Pause nativo 40073 in FX Params (sorgente)

**Spazio** in FX Params comanda Play/Stop di REAPER; se la riproduzione è in pausa, Spazio la riprende immediatamente. **Ctrl+Spazio** richiama direttamente l’azione REAPER 40073 (Play/pause), per riprendere dalla posizione di pausa. Le combinazioni valgono nella griglia, in Value, in F7 e in F8; sono intercettate una sola volta per pressione. **Maiusc+Spazio in F7** continua a selezionare i parametri; nei campi EDIT nativi (ricerca, rinomina, modifica numerica) Spazio resta carattere di testo e non attiva il trasporto. Il navigatore non pronuncia messaggi aggiuntivi per il trasporto. Non è stato modificato Track Params.

Nessun CMake, MSBuild, Visual Studio o build locale: la DLL e i test nativi verranno compilati esclusivamente dal tuo workflow GitHub Actions. Prove consigliate: alternanza Play/Stop, Ctrl+Spazio in riproduzione/in pausa, ripresa con Spazio da pausa, F7 Maiusc+Spazio e inserimento spazi nei campi EDIT.

# LReaParams 0.0.43.2 — ReaEQ: verifica degli aggiornamenti delle bande (solo sorgente)

**Correzione mirata:** `ReaEQ band update failed` poteva essere pronunciato quando `Band Enabled` o `Band Type` cambiavano correttamente, perché il C++ considerava attendibile solo il valore booleano restituito dall'API REAPER. La 0.0.43.2 verifica anche la nuova proprietà e, se serve, il chunk ReaEQ. Non elimina il messaggio per gli errori reali. **Le funzioni di aggiunta/rimozione bande non sono state modificate.** Non è stata eseguita alcuna compilazione locale.

Prova in REAPER con un progetto di test: passa Enabled da On a Off e viceversa, cambia Type e verifica che NVDA annunci il valore corretto senza `ReaEQ band update failed`. Se il plugin rifiuta davvero la modifica, il messaggio deve apparire. Dopo questo collaudo si può riprendere la 0.0.44 (ReaComp e ReaGate).

# LReaParams 0.0.43.1 — ReaEQ: ordine delle bande (candidato sorgente)

**Correzione 0.0.43.1:** l’ordine nativo ReaEQ conserva, per ogni banda, `Enabled → Type → Frequency → Gain → Bandwidth`. La 0.0.43 caricava le vecchie Custom Order e aggiungeva i virtuali mancanti in fondo, dopo `Global Gain`. Ora la migrazione in memoria li inserisce davanti ai tre parametri reali della banda corrispondente, senza perdere la disposizione personalizzata dei parametri fisici, copie, alias e gruppi; corregge anche la coda virtuale salvata accidentalmente dalla 0.0.43. Il profilo `.fx` non viene scritto solo per aver aperto il plugin. Verifica in REAPER la Plugin Order e la Custom Order con Ctrl+L, usando NVDA. Nessuna compilazione locale eseguita.

La 0.0.43 migra le proprietà virtuali Enabled e Type delle bande ReaEQ, Target Band e Band Action con aggiunta/rimozione reali. Mantiene i MIDI CC e la parola Auto della 0.0.42.1. **Non compilata localmente.** Guida specifica: `Docs/TEST43_REAEQ_VIRTUALS.md`.

## Versione precedente: 0.0.42.1 — CC e Auto

Estensione nativa C++ per Windows x64, derivata da TEST30 (0.0.31). Restano FX Params, Track Params e le azioni ausiliarie esistenti. L'archivio contiene solo sorgenti, riferimenti Lua, SDK incluso e test: nessuna DLL o build locale.

**Correzione 0.0.42.1:** i parametri collegati a un MIDI CC ora vengono annunciati
nella lettura normale, in F7, in Value e con NVDA+Freccia Su come
`Cutoff, 1200 Hz. CC channel 1 CC 74. Auto`. `Auto` rimane ultimo e viene letto
solo se esiste un envelope FX attivo; senza CC non viene aggiunto alcun suffisso.
I collegamenti F8 restano invariati, compreso MIDI Learn nativo come fallback
in sola lettura. Non cambia l'annuncio dei soli valori con Alt+Frecce.

**Base 0.0.42:** Ctrl+Q lascia la tastiera a REAPER/TCP e mantiene i CC del singolo FX lasciato in background; l'azione `LReaParams: Stop background MIDI` li ferma. Il polling resta sul thread principale e protegge l'identità dell'FX. F8 legge il canale e il numero CC con etichette esplicite. Conservato l'annuncio `. Auto` della 0.0.41. Nessuna modifica a Track Params o al formato dei profili. Vedere `Docs/TEST42_BACKGROUND_MIDI.md`.

Leggere prima **Docs/Status.md**: la migrazione è avanzata su tutta la roadmap, ma la parità completa Lua NON è raggiunta. Le lacune sono elencate senza placeholder di successo.

File principali:

- Docs/CHANGELOG.md: modifiche effettive e confronto degli allegati.
- Docs/FxCommandMatrix.csv: funzione Lua, gesto, contesto, codice C++, stato e prova.
- Docs/Keyboard.md: guida tastiera attuale.
- Docs/ManualTests.md: prove da svolgere dopo la compilazione.
- Docs/Validation.md: risultati e limiti delle verifiche.
- Docs/Specification.txt: handoff originale fornito per questa richiesta.

Per compilare, caricare il contenuto dello ZIP alla radice del repository, includendo .github/workflows. Eseguire il workflow Build LReaParams Windows x64 in GitHub Actions; l'artifact contiene reaper_lreaparams.dll. Installare in UserPlugins della resource path REAPER, a REAPER chiuso. I dati usati sono LReaParams/Plugins, Tracks, Settings, Backups. Nessuna scansione o pulizia delle vecchie cartelle del navigatore rimosso.

Controlli locali ammessi, senza compilazione:

    python Tools/run_static.py

Il workflow esegue poi build MSVC e CTest sul runner. Non è stato eseguito dall'assistente.

Comando Windows CMD da lanciare nella cartella del repository:

    git status && git add . && git commit -m "0.0.43.4: use native REAPER action 40073 for Ctrl Space" && git push

## Correzioni 0.0.44.1
Posizione FX memorizzata anche su parametri con alias del Lua e gestione prudente degli otto valori discreti di Detector Input ReaComp/ReaGate; vedere `Docs/TEST44_1_POSITION_DETECTOR.md`. Nessuna compilazione locale.
