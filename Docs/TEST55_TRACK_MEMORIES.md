# TEST55 — Track Memories e volume range nel progetto

**Base:** LReaParams 0.0.54.4, senza includere Parameter Library e senza build locale.

## Memoria per progetto

Continua ad essere usato **un solo file** `LReaParams/Tracks/Projects/<Nome>/<Nome>_<hash>.tp` per progetto.
Nel medesimo file si conservano le associazioni MIDI CC Fixed (Track, Sends, Receives), le preferenze degli Step, il parlato, la navigazione F1–F3, i nuovi 12 slot delle tracce e i range del volume. È preservata la sezione futura `FXParams.ProjectTrack` per F4. Non vengono modificati i vecchi `Track CC Map.tp` generali.

## Accesso e navigazione

- **Alt+F8** da Track Params apre Track Memories; l'azione REAPER **LReaParams: Track Memories** apre direttamente lo stesso gestore.
- Freccia sinistra/destra cambia categoria; Su/Giù cambia riga; Home/End e Pagina Su/Giù funzionano nelle liste.
- Tab legge la memoria corrente; Esc/F8 esce. Aprendo dall'azione autonoma, Esc torna a REAPER; da Track Params torna a Track Params.
- **MIDI CC**: Canc elimina un'associazione Fixed, senza alterare il floating runtime. Le altre associazioni dello stesso `.tp` rimangono intatte.
- **Parameter Steps**: Alt+Sinistra/Destra modifica lo Step salvato; Canc riporta allo Step predefinito 0.
- **Parameter Speech**: Invio alterna On/Off, Canc ripristina il default.
- **Track Positions**: 12 memorie. Invio su slot vuoto salva la traccia corrente, su slot occupato la richiama. Canc svuota lo slot. Gli slot occupati **non vengono sovrascritti**.
- **Navigation Memory**: indica F1/F2/F3 e consente di rientrare nella sezione con Invio. Le posizioni si aggiornano automaticamente.
- **F7/F8 del navigatore normale** rimangono riservati alle sezioni originali ancora da migrare; Track Memories usa solo Alt+F8.

## Shortcut track positions

In F1, **Ctrl+Maiusc+F1…F12** salva la traccia nello slot scelto, se vuoto. **Ctrl+F1…F12** richiama lo slot. Gli identificatori di traccia sono GUID, non indici, così riordinare le tracce non confonde le memorie. Una traccia rimossa o nascosta non viene richiamata erroneamente.

## Range Volume

Su Volume in F1, F2 o F3 **Ctrl+Maiusc+I** apre un campo di testo NVDA. Inserire due dB separati da virgola, ad esempio `-60,12`, e confermare con Invio. Limiti consentiti da -150 a +12 dB, con minimo inferiore al massimo. Esc annulla. Il range influenza i passi di Volume e gli estremi Home/End, senza modificare automaticamente il volume della traccia. Una preferenza non definita mantiene il comportamento precedente della 0.0.54.4.

## Verifiche prioritarie in REAPER

1. Associare un CC Fixed a Track Volume, chiudere e riaprire Track Params, verificare che funzioni e sia elencato in Alt+F8. Eliminare il CC dalla memoria e verificare che altri CC restino operativi.
2. Salvare due slot su tracce differenti. Riordinarle e richiamare ciascuno slot. Chiudere e riaprire REAPER, verificare le posizioni nel `.tp` del medesimo progetto.
3. Modificare lo Step e il parlato, uscire e riaprire e verificare persistenza e lettura con Tab.
4. Impostare range Volume `-60,12`, verificare Alt+Home/End e salvataggio dopo riapertura.
5. Provare Alt+F8 e l'azione autonoma con NVDA, controllando tasti, focus, Esc e Ctrl+Tab; verificare che nessun CC modifichi parametri mentre si consulta Track Memories.
6. Aprire due progetti con lo stesso nome in percorsi diversi: memorie separate.

## Limiti dichiarati

Nella TEST55 restano da migrare **la creazione dell'envelope Width mancante**, la gestione globale delle automazioni del Lua e la ricezione MIDI Track in background. F4 e le sezioni successive saranno trattate separatamente. Sono previsti test statici e test nativi di serializzazione, ma la compatibilità MSVC e NVDA/REAPER non è stata collaudata localmente.
