# LReaParams — 0.0.3 TEST2 Native Test (sorgente GitHub-ready)

Estensione Windows x64 di REAPER scritta in C++17. **Questa è una prima versione
sperimentale da collaudare, NON la migrazione completa dei tre Lua originali.**
La DLL non crea alcuna finestra di navigazione o pixel fuori schermo. Le azioni
si trovano in Extensions → LReaParams e nella Action List.

## Compilazione: esclusivamente GitHub Actions

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
- **Track Params (basic controls)**: traccia selezionata (anche master),
  volume, pan, width, mute, solo, record arm, inversione di fase, FX enabled,
  oltre a volume/pan/mute di sends e receives.
- **Dati storici**: importa i TXT riconosciuti da
  `REAPER/Scripts/Lo-lo - Scripts/Utility/Scripts/{Plugins,Params,Tracks}`
  nella cartella sorella `REAPER/LReaParams`, convertendoli in `.fx`, `.pp`, `.tp`.
  Gli originali nella cartella `Scripts` vengono preservati.
- **Tastiera senza finestra**: backend SDK accelerator (predefinito); secondo
  backend sperimentale `WH_GETMESSAGE` limitato al thread principale di REAPER.
  Nessun hook globale né overlay.

**Non ancora funzionanti**: applicazione dei profili `.fx` al navigatore,
Parameter Library nativa, la maggior parte delle funzioni avanzate dei due
navigatori Lua, migrazione delle ExtState e salvataggio delle modifiche nei
nuovi profili. `Legacy/` conserva il sorgente originale per il porting.

La navigazione cattura i tasti solo se attiva e in un contesto considerato
sicuro. F12 viene sempre rilasciato a OSARA. In questa fase un tasto non
riconosciuto termina la navigazione per evitare di bloccare REAPER.

## Documentazione

- `Docs/FirstTest.md` — test accessibile passo passo per la 0.0.2.
- `Docs/Status.md` — funzionalità realmente implementate e TODO.
- `Docs/Acceptance.md` — prove approfondite input, OSARA e perdita del focus.
- `Docs/Architecture.md`, `Docs/Formats.md`, `Docs/FunctionalMatrix.md`.
- `Docs/Specification.txt` — specifica iniziale della migrazione.
- `Docs/Lua*` — inventari del codice originale.

`Tools/audit.py` esegue soltanto controlli statici dei sorgenti e dei profili.
I test C++ vengono eseguiti dal workflow Actions; non sono stati eseguiti qui.
