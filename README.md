# LReaParams — 0.0.7 TEST6 (sorgente GitHub-ready)

Estensione C++17 per REAPER su Windows x64. **TEST6 verifica il possesso
reale della tastiera, come nei Lua originali.** Non è ancora la migrazione
completa di FX Params, Track Params e Parameter Library.

## Novità TEST6 — focus gestito come gfx.getchar()

- La finestra Win32 da **1 × 1 pixel, fuori schermo**, è il vero proprietario
  della tastiera per tutta la navigazione, anziché un semplice titolo temporaneo.
  Non copre le GUI dei plugin: gli effetti restano visibili e utilizzabili con il mouse.
- La finestra riceve `WM_KEYDOWN`/`WM_SYSKEYDOWN` direttamente e passa i comandi
  al navigatore attraverso una coda. Non richiede il backend `WH_GETMESSAGE`
  quando questa modalità è attiva. Tasti non assegnati non provocano uscita
  dalla navigazione e non si propagano al TCP di REAPER.
- **Correzione rispetto a TEST5:** la finestra di un pixel è riconosciuta come
  contesto autorizzato di input. TEST5 la rifiutava quando REAPER non aveva
  un FX focused/touched, provocando l'uscita immediata nel TCP.
- Il titolo si aggiorna durante Grid/Value/FX browser/Track Params e può essere
  letto con NVDA+T. Le modifiche dei parametri avvengono tramite le API REAPER.
- Dopo un tasto di navigazione la DLL può recuperare il focus se un plugin lo
  ha sottratto. Non forza il focus in un ciclo continuo: se si passa a un'altra
  applicazione o si apre un dialogo, la navigazione si interrompe.
- Escape resta interno; F12 chiude il navigatore e viene inoltrato verso REAPER
  per OSARA Shortcut Help: **funzione da verificare sulla DAW reale**.
- Il menu `Extensions → LReaParams → Lua-style keyboard window (1px)` consente
  di disattivare questa modalità solo per diagnosi, tornando al vecchio backend.

Le funzioni precedenti sono conservate: FX F1/F2 per dimensione griglia;
Ctrl+Home/End per estremi dei parametri; browser con più FX; Track Params
con righe di tracce orizzontali (F1), F2 Sends, F3 Receives; menu Memories
separato ma non ancora operativo.

**Non compilare localmente.** La compilazione è demandata a GitHub Actions.
Per i test specifici usa `Docs/FocusOwnerTest.md`.

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
- **Tastiera (modalità senza finestra opzionale)**: backend SDK accelerator (predefinito) più
  hook `WH_GETMESSAGE` limitato al solo Escape sul thread principale, per provare
  a sottrarre Escape a REAPER quando la navigazione è attiva. Secondo backend
  sperimentale `WH_GETMESSAGE` per tutte le chiavi supportate. Nessun hook globale
  né overlay. La cattura di Escape richiede collaudo reale nelle diverse GUI.

**Non ancora funzionanti**: applicazione dei profili `.fx` al navigatore,
Parameter Library nativa, la maggior parte delle funzioni avanzate dei due
navigatori Lua, migrazione delle ExtState e salvataggio delle modifiche nei
nuovi profili. `Legacy/` conserva il sorgente originale per il porting.

La navigazione cattura i tasti solo se attiva e in un contesto considerato
sicuro. F12 viene sempre rilasciato a OSARA. Nel backend precedente un tasto non riconosciuto termina la navigazione;
con la finestra Lua-style, invece, rimane confinato nella finestra di input.

## Documentazione

- `Docs/FirstTest.md` — test accessibile passo passo per la TEST5.
- `Docs/Status.md` — funzionalità realmente implementate e TODO.
- `Docs/Acceptance.md` — prove approfondite input, OSARA e perdita del focus.
- `Docs/Architecture.md`, `Docs/Formats.md`, `Docs/FunctionalMatrix.md`.
- `Docs/Specification.txt` — specifica iniziale della migrazione.
- `Docs/Lua*` — inventari del codice originale.

`Tools/audit.py` esegue soltanto controlli statici dei sorgenti e dei profili.
I test C++ vengono eseguiti dal workflow Actions; non sono stati eseguiti qui.

## TEST5 — storico

Ripristinati **F1/F2 di FX Params** per diminuire/aumentare l'altezza della griglia.
Track Params conserva F1/F2/F3 per Tracks/Sends/Receives.
Nuovo titolo Win32 di un pixel fuori dallo schermo, attivo solo nella navigazione:
NVDA+T puo' leggere la modalita' di LReaParams. La GUI FX resta visibile.
L'opzione **Extensions > LReaParams > NVDA title window (1px)** permette di disabilitare
il comportamento sperimentale. Vedere `Docs/TitleProxyTest.md`.
Non e' stata eseguita nessuna compilazione o prova in REAPER.
