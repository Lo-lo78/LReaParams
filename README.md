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

    git status && git add . && git commit -m "0.0.43.2: verify ReaEQ band changes before reporting errors" && git push
