# LReaParams — 0.0.6 TEST5 Native Test (sorgente GitHub-ready)

Estensione Windows x64 di REAPER scritta in C++17. **Questa è una prima versione
sperimentale da collaudare, NON la migrazione completa dei tre Lua originali.**
La DLL non crea alcuna finestra di navigazione o pixel fuori schermo. Le azioni
si trovano in Extensions → LReaParams e nella Action List.

## Novità TEST5: titoli e memorie

- Le modalità annunciano un **titolo virtuale** tramite OSARA all'attivazione:
  `LReaParams - FX Params - Grid/FX browser` oppure
  `LReaParams - Track Params - Tracks/Sends/Receives`.
  Non esistono finestre aggiuntive: perciò **NVDA+T continuerà a leggere il
  titolo della finestra REAPER**. Non si modifica il titolo della DAW, che deve
  rimanere intatto e visibile al collaboratore.
- Menu **Extensions → LReaParams → Memories** con `FX Memories`,
  `Track Memories` e `Parameter Library`. Sono per ora voci **in attesa di
  migrazione**, non funzioni operative; i profili importati rimangono intatti.
- **FX Params: F1–F11 riservati** (F1/F2 non cambiano più la griglia).
  **Track Params: F1–F3** conservano le pagine dei Lua,
  **F4–F11 riservati**. I tasti riservati non escono dalla navigazione
  né attivano comandi REAPER. **F12 resta di OSARA**.

## Compilazione: esclusivamente GitHub Actions

**TEST3:** nuova F1 di Track Params a righe orizzontali (traccia = riga, 9 parametri = colonne): Su/Giù cambia traccia senza cambiare la selezione nel TCP, Sinistra/Destra cambia parametro. Home/End estremi della riga, Ctrl+Home/End prima/ultima traccia stessa colonna. F2 Sends e F3 Receives separati. FX Params Ctrl+Home/End per primo/ultimo parametro. Escape interno con hook thread-only e senza azione separata nel menu.

**TEST2:** avvio di FX Params dal contesto traccia/item, senza dover toccare un parametro. Se è presente un solo FX entra direttamente nella griglia, con due o più FX apre il browser vocale (Su/Giù, Invio, Esc, Alt+B per riaprirlo). Supporta anche i Monitor FX del master. Nessuna finestra ausiliaria.

**TEST1 FIX1:** corretto il workflow per il runner Windows 2025 con
Visual Studio 2026 (CMake generator `Visual Studio 18 2026`).
Nessuna compilazione locale effettuata.


Non è stata eseguita alcuna compilazione locale, non sono stati generati binari.

1. Crea il repository `Lo-lo78/LReaParams`.
2. Estrai questo ZIP e carica **tutti i file e le cartelle** alla radice del
   repository, inclusa la cartella nascosta `.github`.
3. Fai il primo commit su `main`. GitHub Actions esegue **Build LReaParams Windows x64**.
4. Scarica l'artifact **LReaParams-Windows-x64-NATIVE-TEST**. Contiene
   `reaper_lreaparams.dll` (se la build riesce).
5. Chiudi REAPER, copia la DLL nella cartella `UserPlugins` della resource path,
   poi riapri REAPER con OSARA e NVDA.
6. Prova su un **progetto di test**, partendo da `Docs/FirstTest.md`.

**Qualunque errore di compilazione deve essere corretto nei sorgenti; non
modificare a mano la DLL.** Un workflow verde non dimostra che i tasti siano
catturati in tutte le GUI dei plugin: occorre il test in REAPER.

## Cosa è utilizzabile

- **FX Params**: apertura tramite contesto della traccia/item selezionato, browser vocale con due o più FX, parametri reali
  track/take, griglia per colonne, Value, modifica in tempo reale, ricerca
  locale con Ctrl+F, Home/End e PageUp/PageDown nella griglia, Undo e annunci OSARA.
- **Track Params (basic controls)**: F1 riprende la matrice del Lua: ogni traccia visibile nel TCP e non nascosta da una cartella chiusa ha una riga orizzontale con 9 campi (Volume, Pan, Width, Mute, Solo, Phase invert, Send count, Receive count, FX count). La navigazione nella matrice NON seleziona davvero la traccia nel TCP. F2/F3 sono pagine parziali per send e receive (volume, pan, mute), non equivalenti alle 14 colonne dei Lua.
- **Dati storici**: importa i TXT riconosciuti da
  `REAPER/Scripts/Lo-lo - Scripts/Utility/Scripts/{Plugins,Params,Tracks}`
  nella cartella sorella `REAPER/LReaParams`, convertendoli in `.fx`, `.pp`, `.tp`.
  Gli originali nella cartella `Scripts` vengono preservati.
- **Tastiera senza finestra**: backend SDK accelerator (predefinito) più
  hook `WH_GETMESSAGE` limitato al solo Escape sul thread principale, per provare
  a sottrarre Escape a REAPER quando la navigazione è attiva. Secondo backend
  sperimentale `WH_GETMESSAGE` per tutte le chiavi supportate. Nessun hook globale
  né overlay. La cattura di Escape richiede collaudo reale nelle diverse GUI.

**Non ancora funzionanti**: applicazione dei profili `.fx` al navigatore,
Parameter Library nativa, la maggior parte delle funzioni avanzate dei due
navigatori Lua, migrazione delle ExtState e salvataggio delle modifiche nei
nuovi profili. `Legacy/` conserva il sorgente originale per il porting.

La navigazione cattura i tasti solo se attiva e in un contesto considerato
sicuro. F12 viene sempre rilasciato a OSARA. In questa fase un tasto non
riconosciuto termina la navigazione per evitare di bloccare REAPER.

## Documentazione

- `Docs/FirstTest.md` — test accessibile passo passo per la TEST5.
- `Docs/Status.md` — funzionalità realmente implementate e TODO.
- `Docs/Acceptance.md` — prove approfondite input, OSARA e perdita del focus.
- `Docs/Architecture.md`, `Docs/Formats.md`, `Docs/FunctionalMatrix.md`.
- `Docs/Specification.txt` — specifica iniziale della migrazione.
- `Docs/Lua*` — inventari del codice originale.

`Tools/audit.py` esegue soltanto controlli statici dei sorgenti e dei profili.
I test C++ vengono eseguiti dal workflow Actions; non sono stati eseguiti qui.

## TEST5 — NVDA+T e griglia FX

Ripristinati **F1/F2 di FX Params** per diminuire/aumentare l'altezza della griglia.
Track Params conserva F1/F2/F3 per Tracks/Sends/Receives.
Nuovo titolo Win32 di un pixel fuori dallo schermo, attivo solo nella navigazione:
NVDA+T puo' leggere la modalita' di LReaParams. La GUI FX resta visibile.
L'opzione **Extensions > LReaParams > NVDA title window (1px)** permette di disabilitare
il comportamento sperimentale. Vedere `Docs/TitleProxyTest.md`.
Non e' stata eseguita nessuna compilazione o prova in REAPER.
