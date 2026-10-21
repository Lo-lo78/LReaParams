## TEST61.16.1 — Correzione del controllo GitHub Actions

Il vecchio test statico TEST48 si aspettava due istruzioni C++ consecutive.
TEST61.16 aggiunge correttamente `captureViewCursor()` fra loro per ricordare
separatamente le griglie dei gruppi. Il test TEST48 e' aggiornato per verificare
tutte e tre le istruzioni nell'ordine corretto. **Sorgenti C++ invariati**;
compilazione DLL esclusivamente tramite GitHub Actions.

## TEST61.16 — FX Params: 14 griglie indipendenti

**Plugin Order, Custom Order e ciascuno dei 12 Group** ora conservano individualmente la larghezza F1/F2 e la posizione dell'ultimo parametro, anche senza editare. Le preferenze sono immediate nella sessione e persistenti nel `.fx` condiviso al cambio contesto o all'uscita; sono compatibili con le vecchie chiavi Lua. Esc, F7 e Ctrl+Alt+B della TEST61.15 rimangono operativi. Dettagli e prove: `Docs/TEST61_16_INDEPENDENT_FX_GRIDS.md`. **Compilazione solo tramite GitHub Actions.**

## TEST61.15 — Ctrl+Alt+B ripristina subito il gruppo e i parametri FX

- Quando metti un FX o strumento **offline**, LReaParams ricorda gruppo,
  parametro e posizione e passa a FX Browser, dove Ctrl+Alt+B rimane attivo.
- Quando rimetti lo stesso FX **online** con Ctrl+Alt+B, ritorna subito alla
  griglia dei parametri nello stesso gruppo e nello stesso punto, senza dover
  uscire e rientrare con l'azione FX Params.
- Se uno strumento espone i parametri con ritardo, la DLL riprova sul timer
  nativo REAPER senza bloccare l'interfaccia; il ripristino è protetto dal GUID.
- Memoria persistente TEST61.14, FX diversi, F7, Take e Monitor FX invariati.

Vedere `Docs/TEST61_15_FX_ONLINE_RESTORE.md`. **Non compilare localmente**:
verifica sorgenti e build nativa tramite GitHub Actions.

## TEST61.14 — FX Params: gruppo e posizione sopravvivono al riavvio di REAPER

- Esc dalla griglia di un gruppo chiude FX Params direttamente (come in
  TEST61.13); ora il gruppo viene ricordato **anche dopo aver riavviato REAPER**.
- Oltre al parametro `LastParam`, il profilo condiviso del plugin `.fx` salva
  gruppo e occorrenza esatta della posizione in `[Extra]` usando
  `lrp_last_navigation_v1=gruppo,posizione` (posizione a base zero).
- F7 non si riapre come editor. I gruppi cancellati/vuoti ritornano alla
  griglia normale. La memoria dell'istanza vince finche' dura la sessione.
- Compatibile con vecchi `.fx`: le altre impostazioni, MIDI, default, ordini
  e profili non sono modificati dal salvataggio della posizione.

Per i test e i limiti della persistenza per plugin condiviso, vedere
`Docs/TEST61_14_PERSISTENT_FX_GROUP.md`.

**Non compilare in locale:** usare GitHub Actions per compilare e provare
la DLL in REAPER con NVDA/OSARA.

## TEST61.12 — Cartella risorse dinamica e schermata Fine / Finish

- La cartella predefinita **non** contiene un nome utente fisso: NSIS risolve
  `$APPDATA\REAPER` **sul PC dell'utente che esegue il setup**, non su quello
  che compila l'installer. Ogni utente ha la propria directory in Roaming.
  `InstallDirRegKey` può proporre il percorso scelto precedentemente dallo
  stesso utente (utile per REAPER portatile), consultando soltanto HKCU.
- Le descrizioni del setup in tutte le **7 lingue** non mostrano percorsi
  personali né istruzioni su precedenti finestre modali. Il campo destinazione
  mostra invece la vera cartella selezionata, sempre modificabile.
- Dopo **Installa** viene mostrata una pagina di completamento tradotta.
  **Fine** in italiano / **Finish** in inglese chiude il programma. Non è
  richiesto un altro pulsante dopo Fine.
- Nessuna modifica al C++ della DLL, ai file installati o alla disinstallazione;
  gli archivi esistenti di GitHub Actions sono conservati.

**Senza build locale:** provare su GitHub Actions e in Windows con NVDA.
Verifica statica: `python Testing/test61_12_installer_path_finish_static.py`.

## TEST61.11 — Installer NSIS: navigazione NVDA (comportamento finale sostituito da TEST61.12)

Solo il file `Installer/LReaParams.nsi` e i test/documenti del setup sono stati
modificati; il codice C++ della DLL resta quello della TEST61.10.

- All'avvio **compare sempre la scelta della lingua**, anche se una precedente
  installazione aveva memorizzato English. I pulsanti standard NSIS sono
  localizzati: **Avanti / Indietro / Installa** in italiano; **Next / Back /
  Install** in inglese, e analogamente nelle altre cinque lingue.
- La pagina iniziale spiega di chiudere REAPER e descrive il flusso da tastiera.
  La pagina della cartella delle risorse spiega anche come scegliere REAPER portable.
- Eliminata la **finestra modale OK prima di copiare i file**, fonte di un passaggio
  poco chiaro con NVDA. Dopo la scelta della cartella parte direttamente
  l'installazione. La conferma di percorso non riconosciuto (`reaper.ini`
  mancante) rimane per evitare installazioni nella cartella sbagliata.
- Eliminata la **pagina Finish**: al completamento corretto l'installer
  **si chiude automaticamente**, senza ulteriori Invio o OK. Gli errori
  di installazione rimangono segnalati con finestre dedicate.
- Nessuna modifica alla disinstallazione, ai file installati, ai profili
  o al workflow degli artefatti precedenti.

**Senza compilazione locale:** verificare il nuovo EXE da GitHub Actions su
Windows usando NVDA. Controllo statico dedicato:
`python Testing/test61_11_installer_accessibility_static.py`.

## TEST61.10 — Riparazione percorso sorgenti NSIS (GitHub Actions)

Nella TEST61.9 GitHub Actions aveva gia completato con successo la build
C++ e i tre artefatti ZIP, ma `makensis` non trovava la DLL in
`Installer\Installer\..\package\UserPlugins`. NSIS interpreta i percorsi
del comando `File` rispetto alla cartella contenente lo script, non alla
working directory della shell. La TEST61.10 passa il percorso assoluto del
repository attraverso `/DPROJECT_ROOT=...` e lo applica **a tutti** gli input
(`DLL`, guide, avvisi legali, sorgenti e manifest di disinstallazione) e
all'output EXE. Una verifica PowerShell accerta che siano presenti tutti i
file prima dell'invocazione di NSIS. Il test `test61_10_nsis_input_paths_static.py`
evita regressioni. Nessuna modifica alle funzioni della DLL o ai dati utente.

**Non eseguire build locali:** GitHub Actions genera l'installer e la DLL.

## TEST61.9 — Installer EXE GitHub Actions e licenza

GitHub Actions adesso genera un quarto artefatto:
**`LReaParams-0.0.61-Windows-x64-SETUP-EXE`**. Dopo avere estratto lo ZIP
scaricato da Actions, eseguire **`LReaParams-0.0.61-Windows-x64-Setup.exe`**.

L'installer NSIS (Windows x64, per utente, senza privilegi amministrativi per
la cartella predefinita) propone la selezione di 7 lingue e della cartella
**delle risorse** di REAPER. Percorso predefinito:
`%APPDATA%\REAPER`. Per REAPER portable selezionare invece la cartella
portatile contenente `reaper.ini`. Prima dell'installazione chiudere REAPER.

Installa:
- `%REAPER_RESOURCES%\UserPlugins\reaper_lreaparams.dll`;
- `%REAPER_RESOURCES%\LReaParams\Guide\` (tutte le 7 lingue);
- `%REAPER_RESOURCES%\LReaParams\Licenses\` (GPL-3.0 e attribuzioni);
- `%REAPER_RESOURCES%\LReaParams\Source\` (ZIP dei sorgenti della stessa
  revisione GitHub compilata e hash del commit);
- `%REAPER_RESOURCES%\LReaParams\Uninstall-LReaParams.exe`.

I dati in `Plugins`, `Tracks`, `Settings` e `Backups` NON vengono mai
sovrascritti o rimossi; l'installer crea queste cartelle solo se mancanti.
Il disinstallatore elimina soltanto la DLL e i file inclusi nel pacchetto,
mai i profili e le impostazioni. È disponibile anche nelle impostazioni
App installate di Windows. Lo ZIP `MULTILINGUAL` e le guide restano artefatti
separati per installazione manuale.

**Licenza:** LReaParams viene proposto sotto GNU GPL version 3 only
(`GPL-3.0-only`, SPDX)
(`LICENSE`, `THIRD_PARTY_NOTICES.md`), a condizione che il titolare dei
diritti confermi di poter applicare questa licenza a tutti i propri sorgenti,
compresi quelli Lua storici. I componenti di terzi mantengono i loro avvisi.
La gratuità da sola non equivale a una licenza open source.

**Nessuna compilazione locale:** il workflow Windows/MSVC e makensis girano
esclusivamente in GitHub Actions. Test: `python Testing/test61_9_installer_static.py`.

## TEST61.8 — Import legacy Lua settings and keyboard Settings action

The existing REAPER action **LReaParams: Import legacy profiles** now asks **Y** to import, **N** to leave files untouched; **Escape** cancels. At startup the same question appears only once when old Lua TXT profiles are found. Your choice is saved in `LReaParams\Settings\LegacyImportChoice.txt`. To import later run the action at any time. No automatic conversion occurs without confirmation. Original Lua TXT files remain in their old folder, native .fx/.tp differences are not overwritten, and verified backups are retained.

**LReaParams: Settings (Keyboard Input)** is *not* a general settings screen: press **1** for the recommended REAPER SDK accelerator, **2** for the main-thread compatibility hook, **Escape** for unchanged; the selection lasts only for this REAPER session. Task Dialog labels and direct shortcuts are independent of Windows Yes/No button localization. In-navigator Y/N automation and memory confirmations are unchanged.

**Source only, no local build; compile via GitHub Actions.**

# LReaParams 0.0.61 — TEST61.7 GitHub Actions test repair

The TEST61.6 workflow stopped before CMake at TEST27, because About used `Bare F12 reserved` where a historical Python check required `F12 alone is reserved`. After this check, historical TEST42 also expected Stop Background MIDI to be the final action in the enum, but the multilingual guide action is now appended. TEST61.7 resolves both mismatches, preserves the actual behavior and seven-language guide, and passes the complete set of 83 workflow Python tests (source-only; **no native compilation**).

# LReaParams 0.0.61 — TEST61.6 multilingual user guides

**NEW REAPER action:** `LReaParams: Open User Guide` (also under Extensions > LReaParams). Assign any keyboard shortcut using the REAPER Main Action List. The action opens the default browser to the [language selection page](Guide/index.html), then offers FX Params or Track Params.

**Seven languages:** English (complete original manuals), Italiano, Español, Français, Русский, 简体中文 and 日本語. The six translations are **concise functional guides** with page descriptions, current shortcuts and links to the full English references; they are not line-by-line translations of the long originals. All pages are offline HTML, UTF-8, keyboard accessible, with native links and headings. No JavaScript, external services or internet connection is required.

**Installation:** The GitHub Actions multilingual installation artifact contains the correct REAPER resource directory structure:

- `UserPlugins/reaper_lreaparams.dll`
- `LReaParams/Guide/index.html`, `en/index.html`, `it/`, `es/`, `fr/`, `ru/`, `zh-CN/`, `ja/` and the complete original English pages.

Place these folders in the REAPER resource directory. The separate guides artifact contains just the Guide folder. If `Guide/index.html` is not found, the action explains where to install it. See [Guide/INSTALL.txt](Guide/INSTALL.txt).

**Migration scope:** FX Params F10 browser, F11 Audio Pin Connector, F8 Compare; Track Params F5 MIDI, F6 Hardware Outputs with Add and F7 ReaRoute. No legacy Lua launcher or Stretch Marker script is part of the package. **No local native compilation**: use the GitHub Actions workflow, then verify in REAPER with NVDA/OSARA.

> **TEST61.4 — Track Params F6 Hardware Outputs:** F6 si apre anche quando la traccia non ha uscite hardware. La colonna «Add hardware output» è accessibile con Ctrl+Home o freccia sinistra dalla prima uscita; Invio crea una vera uscita in REAPER. Alt+Su/Giù sceglie la destinazione fisica disponibile, leggendo anche i nomi dei canali del driver; dopo la creazione si entra nella colonna dell’uscita. Delete sull’ultima uscita ritorna alla colonna Add, senza uscire da F6. Undo, rollback e isolamento rispetto a F7 ReaRoute. **Solo sorgente: compilazione GitHub Actions.** [Guida TEST61.4](Docs/TEST61_4_F6_ADD_HARDWARE_OUTPUT.md).

> **TEST61.3 — annunci F11 Audio Pin Connector:** collegamento presente: `Attive. Input ...` oppure `Attive. Output ...`; collegamento assente: `Input ...` o `Output ...` senza prefisso. Anche la lettura dopo Invio, Spazio e Canc usa la stessa formula. Solo stringhe vocali: nessuna modifica ai pin, ai routing, ai tasti o alle memorie. Nessuna compilazione locale.

> **TEST61.2 — correzione errore C2677 MSVC:** corretti tre confronti duplicati `page_ == page_ == Page::trackMidi` nelle funzioni `nativeValueSlider`, `valueFraction` e `sliderLabel` di `src/TrackNavigator.cpp`. Aggiunto test statico di regressione nel workflow prima della compilazione. F10/F11, Peak Watcher e dati `.tp` invariati. Nessuna compilazione locale.

> **TEST61.1 — riparazione workflow GitHub Actions:** aggiornati i test statici storici TEST55.5 e TEST56.1/56.2, che facevano ancora riferimento alle pagine F5/F8 antecedenti alla migrazione TEST61. Nessuna modifica al codice C++, alle API audio, alle scorciatoie, ai file `.tp` o agli FX. Il precedente workflow si fermava prima di CMake/MSVC; la compilazione nativa resta da effettuare su GitHub Actions.

> **LReaParams 0.0.61 — TEST61:** FX Params **F10** sostituisce Ctrl+P per passare da Browser a Grid e viceversa; **F11** apre il Pin Connector per Track/Take/Monitor FX fino a 128 canali. Track Params scala le pagine: F5 MIDI, F6 Hardware, F7 ReaRoute; i cursori `.tp` vengono migrati una sola volta, F8 libero. Ripristinati Alt+F10/F11/F12 e Alt+Shift con azioni OSARA Peak Watcher. [Guida e collaudo TEST61](Docs/TEST61_FX_PIN_MIGRATION.md). **Solo sorgente GitHub Actions, senza compilazione locale.**

> Le sezioni delle versioni precedenti sono cronologia: le scorciatoie correnti prevalgono sulle indicazioni storiche che citano Ctrl+P o F10 libero.

> **LReaParams 0.0.60 — TEST60:** navigazione comune per marker e trasporto a beat/misure in FX Params e Track Params, rispettando Ctrl+Pagina Su/Giù per gli FX e Ctrl+frecce per item/take. [Guida TEST60](Docs/TEST60_MARKER_TRANSPORT.md). **Nessuna compilazione locale: solo GitHub Actions.**

> **LReaParams 0.0.59 — TEST59 F8 ReaRoute:** migrata dal Lua la pagina F8 in C++, con input ReaRoute, aggiunta uscite, 11 righe per ciascuna colonna, parametri audio, Undo, NVDA e posizioni `.tp`. F7 ora mostra soltanto gli output fisici, separati da quelli ReaRoute. Non sono stati aggiunti alias/riordinamento F4 né scorciatoie di trasporto. [Guida e test F8](Docs/TEST59_F8_REAROUTE.md). **Solo sorgente per GitHub Actions: nessuna compilazione locale.**

> **LReaParams 0.0.58 — TEST58 F7 Hardware Outputs:** migrata dal Lua la griglia di 11 righe per ogni uscita hardware fisica, con Volume, Pan, Mute, Phase, Mono, audio source/mode, hardware destination, Send type e Pan law. Navigazione e modifica da tastiera, Delete con Undo, verifica delle scritture e memoria del cursore nel `.tp`. Rifiniture F6: ripetizione valore con barra rovesciata e limiti silenziosi. F5 resta a 128 canali. [Guida e collaudo](Docs/TEST58_F7_HARDWARE_OUTPUTS.md). **Solo sorgente, compilazione GitHub Actions.**

> **LReaParams 0.0.57 — TEST57 F6 Track MIDI:** migrata dal Lua la pagina MIDI della traccia, indipendente dall'FX, con 4 valori modificabili e quinta voce MIDI routing verso F2/F3. Alt+frecce, Alt+Pagina, Alt+Home/End, Invio, Tab, titoli NVDA/OSARA e memorie della posizione `.tp`. F5 rimane a 128 canali; F1-F4/FX Params non modificati. [Guida e prove](Docs/TEST57_F6_TRACK_MIDI.md). **Solo sorgente: compilazione GitHub Actions.** I riferimenti storici sotto a «F6 riservato» descrivono le TEST precedenti.

> **TEST56.10.1 — F5 semplificato:** rimosso Ctrl+S e tutto lo stato per il collegamento in due passaggi. Invio/Spazio collega o scollega la cella corrente; Canc la scollega. Nessun cambiamento alle API audio, al focus, all’Undo o alle altre sezioni. Compilazione esclusivamente tramite GitHub Actions.

> **TEST56.10 — F5 Audio Pin Connector (prima fase):** griglia di routing dei pin audio per FX selezionato in F4, con lettura e modifica per canale, Undo, ricerca dei collegamenti attivi e ritorno a F4. L'FX è risolto tramite GUID prima delle operazioni. F6 resta riservato. [Guida](Docs/TEST56_10_F5_AUDIO_PIN_CONNECTOR.md). **Nessuna compilazione locale; soltanto GitHub Actions.**

> **TEST56.9.1 — F4 Fixed CC repair:** corrected the project `.tp` writer to accept
> `FxTcp|{trackGUID}|{fxGUID}|parameter` identities for both MIDI mapping and
> Ctrl+T speech. The previous writer threw during learn and stopped Track
> Params, returning focus to REAPER TCP. Added safeguards and native regression
> tests for persistence, independent FX instances and deletion. Floating CC
> unchanged. [Test guide](Docs/TEST56_9_1_F4_FIXED_CC_PERSISTENCE.md).
> Compile **only with GitHub Actions**, no local build.

## TEST56.9 — Close Track Params F4 before F5

- Ctrl+E in F4 opens the existing NVDA-accessible native edit control. The field starts with the current value, in formatted units when the host provides a stable monotonic numeric formatter, otherwise raw REAPER parameter units. Enter confirms; Escape cancels. Unsupported or out-of-range values are rejected, keeping the edit field open. A changed/removed FX cannot receive a stale edit.
- Ctrl+Shift+T controls keyboard value speech on F4. With speech off, nudges and Home/End do not announce values, while Tab and NVDA review still expose the parameter. MIDI CC speech remains a separate opt-in.
- Discrete/toggle parameters prefer REAPER-provided steps. Small integer-range JSFX controls get conservative raw-integer stepping when no trustworthy step is provided. No aliases, manual ordering, new grids, or .tp schema changes.
- GitHub Actions performs MSVC build and native testing. No local native compilation was performed for this package.

> **TEST56.8 / LReaParams 0.0.56 (ATTUALE):** MIDI CC per i parametri TCP di F4, riutilizzando il motore Track Params: Ctrl+Alt+C learn Fixed (GUID traccia + GUID FX + indice parametro), Maiusc+C mappa Fixed On/Off, Ctrl+Maiusc+C Floating, Ctrl+T parlato MIDI inizialmente Off, Ctrl+Maiusc+T parlato valore, Ctrl+Canc cancella l’associazione corrente. Le preferenze restano nel singolo `.tp` del progetto; Track Memories mostra e gestisce le nuove voci FX. Pickup per parametri continui e Ctrl+Q MIDI in background. [Guida](Docs/TEST56_8_F4_MIDI_CC.md). **Nessuna compilazione locale: solo GitHub Actions.**

> **TEST56.7 / LReaParams 0.0.56 (ATTUALE):** F4 senza intestazione navigabile: mostra solo parametri TCP e valori, in griglia fissa di 8 righe. Alt+Invio da qualunque posizione F4 apre la griglia dei nomi dei parametri da aggiungere, anche se l’FX non ne ha di visibili. Invio cambia Grid/Value. **Ctrl+Pagina Su/Giù** sposta fisicamente l’FX tanto in Track F4 quanto in FX Params (anche nel browser); nel browser FX Params **Ctrl+Maiusc+Su/Giù** passa tra tracce con FX mantenendo il browser attivo. Ctrl+Su/Giù continua a cambiare FX. [Guida TEST56.7](Docs/TEST56_7_UNIFIED_FX_BROWSER_SHORTCUTS.md). Nessuna compilazione locale: solo GitHub Actions.

> **TEST56.6 / LReaParams 0.0.56 (ATTUALE):** F4 ora è un mini FX Params: un solo FX alla volta, parametri TCP disposti in colonne da 8 righe. Ctrl+Su/Giù cambia FX, Ctrl+Maiusc+Su/Giù cambia traccia, Alt+Maiusc+Su/Giù sposta fisicamente l’FX. Ctrl+Home/End primo/ultimo parametro nell’FX corrente; Alt+Home/End massimo/minimo valore (anche in Grid). Alt+Invio e la griglia dei parametri visibili sono rimossi: Canc rimuove il parametro TCP. Invio sull’intestazione apre sempre la griglia di selezione dei nomi, con F1/F2 per l’altezza e Ctrl+Invio per aggiungere/rimuovere senza uscire. [Guida attuale TEST56.6](Docs/TEST56_6_F4_COMPACT_FX_GRID.md). **Solo sorgente; compila esclusivamente GitHub Actions.** Le note TEST56.1–56.5 successive sono cronologia e possono riportare scorciatoie superate.

> **TEST56.5 / LReaParams 0.0.56:** Alt+Home/End ora intercettati prima delle scorciatoie REAPER; in Grid raggiungono primo/ultimo parametro TCP, in Value impostano massimo/minimo. F4 aggiunge Ctrl+B bypass, Ctrl+D Delta Solo, Ctrl+Maiusc+Su/Giù spostamento FX, Canc rimozione controllo TCP, Ctrl+Maiusc+A automazione FX e conferma globale Ctrl+Maiusc+Alt+A. [Guida TEST56.5](Docs/TEST56_5_F4_FX_CONTROL_AUTOMATION.md). Nessuna compilazione locale.

> **TEST56.4 / LReaParams 0.0.56:** F4 annuncia soltanto il valore dopo una modifica; Ctrl+F in F4 e nelle griglie di selezione ricerca con la stessa regola di FX Params (virgolette incluse); Alt+Home/End primo/ultimo parametro. Alt+Invio apre la griglia dei parametri TCP visibili, ora a **colonne per FX**, con nomi senza valori, e titolo **Visible TCP parameters - Remove**. [Guida TEST56.4](Docs/TEST56_4_F4_FILTER_VISIBLE_COLUMNS.md). Nessuna compilazione locale.

> **TEST56.3 / LReaParams 0.0.56:** F6 libero; Alt+Invio apre i parametri TCP già visibili. Ricerca alfanumerica ciclica e inversa in F4 e nelle griglie dei nomi. Prima modifica Value dei parametri TCP con Step `.tp` e Undo. **Nessuna compilazione locale.** [Guida TEST56.3](Docs/TEST56_3_F4_VALUE_CYCLIC_NAVIGATION.md).

> **TEST56.2 / LReaParams 0.0.56:** F4, Invio su intestazione FX apre una **griglia dei soli nomi dei parametri**, con le direzioni e F1/F2 della griglia FX Params. Invio aggiunge al TCP e torna a F4; Ctrl+Invio aggiunge/rimuove senza uscire. F6 da F4 apre la griglia dei controlli TCP visibili per rimuoverli. [Guida TEST56.2](Docs/TEST56_2_F4_TCP_PARAMETER_GRID.md). **Non compilato localmente**: build solo GitHub Actions.

> **TEST56.1 / LReaParams 0.0.56:** prima migrazione F4, griglia FX TCP nativa in sola navigazione (una colonna per FX, header sempre presente, parametri TCP reali, lettura NVDA e bordi silenziosi). Modifiche e lista completa dei parametri verranno nelle TEST56 successive. **Non compilato localmente**: build soltanto via GitHub Actions. [Guida TEST56.1](Docs/TEST56_1_F4_TCP_NAVIGATION.md).

> **TEST55.13 / LReaParams 0.0.55:** ricerca ciclica per iniziale come nel Lua (F1 per traccia, F2/F3 per parametro nella colonna), protezione dei CC Fixed di send/receive quando cambia la struttura del routing. **Gli Step rimangono condivisi per tipo di parametro, non per traccia.** Solo sorgente per GitHub Actions, senza compilazione locale. [Guida TEST55.13](Docs/TEST55_13_INITIAL_ROUTING_REFINEMENTS.md).

> **TEST55.12 / LReaParams 0.0.55:** Correzione automazione Width in F1 con envelope nativo completo (`EGUID`, `PT`, armamento), verifica tramite chunk anche quando l’API non aggiorna subito il puntatore. Nessuna compilazione locale. [Guida e collaudo](Docs/TEST55_12_WIDTH_AUTOMATION.md).

> **TEST55.9 + TEST55.10 / LReaParams 0.0.55:** Ctrl+Q Track Params con MIDI Fixed/Floating in background; Ctrl+Maiusc+Alt+A con conferma e Undo su entrambi i navigatori; creazione Width in F1 con verifica e ripristino in caso di errore. F1/F2/F3 revisionati prima di F4. Sorgente per GitHub Actions, senza build locale. [Guida](Docs/TEST55_10_F1_F3_CLOSURE.md).

> **TEST55.8 / LReaParams 0.0.55:** risolto il ripristino dei Default FX con nomi dei parametri variabili; Invio su Default ripristina il suono e ritorna alla griglia senza cancellare le altre memorie. Canc continua a richiedere conferma per il reset completo. [Guida](Docs/TEST55_8_FX_DEFAULT_RESTORE.md). Nessuna compilazione locale.

> **TEST55.7 / LReaParams 0.0.55:** Original catturato al **primo ingresso** nell’istanza FX, senza cambiare il suono; sopravvive a Esc/Ctrl+Tab e al ritorno nello stesso FX durante la sessione. F8 singolo confronta, doppio aggiorna Original. [Guida e collaudo](Docs/TEST55_7_FIRST_ENTRY_ORIGINAL.md). Nessuna compilazione locale.

> **TEST55.6 / LReaParams 0.0.55:** F8 in FX Params è Compare A/B. Singolo alterna Original e Compare; doppio conferma il suono attuale come nuovo Original senza cambiare lato. L'ingresso nell'FX non applica snapshot e mantiene il suono reale del progetto. Compare non è più un parametro; Ctrl+Maiusc+M conserva i gestori memorie. [Guida e collaudo](Docs/TEST55_6_F8_COMPARE_AB.md). Nessuna compilazione locale.

> **TEST55.5 / LReaParams 0.0.55:** Ctrl+Maiusc+M apre FX Memories o Track Memories in base al navigatore; Esc o lo stesso gesto torna indietro. Rimosso Alt+F8 Track e liberato F8 FX per il futuro. [Guida](Docs/TEST55_5_UNIFIED_MEMORY_SHORTCUT.md). Non compilato localmente.

> **TEST55.4 / LReaParams 0.0.55:** unificazione delle memorie: Track MIDI CC silenzioso di default, Ctrl+T specifico per il target GUID, solo preferenze personalizzate in Track Memories; FX F8 indipendente da F7. [Guida](Docs/TEST55_4_UNIFIED_MEMORIES.md). Nessuna compilazione locale.

> **TEST55.3 / LReaParams 0.0.55:** CC Fixed specifici di traccia GUID e send sorgente/destinazione/occorrenza; Floating segue il cursore. Track Memories mostra i CC specifici e marca le vecchie mappe generali come inattive. Un solo `.tp` per progetto. Nessuna build locale. [Dettagli](Docs/TEST55_3_FIXED_CC_PER_TRACK.md).

> **TEST55.2 / LReaParams 0.0.55:** Track Memories ora annuncia la prima voce, salta le categorie vuote e mantiene silenziosi i bordi come FX Memories. Ctrl+Maiusc+I applica il Volume range del `.tp` a tastiera, Value, Ctrl+E e MIDI CC/pickup; Tab comunica i limiti. [Guida TEST55.2](Docs/TEST55_2_F8_VOLUME_RANGE.md). Nessuna compilazione locale.

> **TEST55.1:** risolti due errori di compilazione MSVC C3538 in `src/TrackNavigatorMemories.cpp` (dichiarazioni `auto` con tipi diversi). Nessuna modifica funzionale rispetto alla TEST55; compilazione esclusivamente via GitHub Actions.

> **TEST55 / LReaParams 0.0.55:** Track Memories operativo con Alt+F8 e azione REAPER, CC Fixed/Step/parlato/12 posizioni/posizioni F1-F3 nel `.tp` del progetto; Ctrl+Maiusc+I range Volume. Non compila localmente; [guida](Docs/TEST55_TRACK_MEMORIES.md).

> **TEST54.4 / LReaParams 0.0.54.4:** La traccia corrente è sincronizzata tra navigazione F1/F2/F3, FX Params e selezione reale del TCP. Ctrl+Tab da FX Params ritorna sulla traccia proprietaria dell'FX/take effettivamente aperto; Esc non riporta alla traccia iniziale. La selezione multipla resta disponibile con Maiusc e gli appositi comandi. [Guida TEST54.4](Docs/TEST54_4_TRACK_FX_TCP_SYNC.md). Sorgente, nessuna compilazione locale.

> **TEST54.3 / LReaParams 0.0.54.3:** Ctrl+E conferma senza il doppio annuncio `Set.`; FX Params rifiuta tracce e take privi di effetti con `No track FX` / `No take FX`. Ctrl+Tab su traccia vuota non lascia Track Params. [Guida](Docs/TEST54_3_NUMERIC_SPEECH_EMPTY_FX.md). Nessuna compilazione locale.

> **TEST54.2 / LReaParams 0.0.54.2:** Ctrl+Maiusc+A senza doppio Auto; envelope reali Send/Receive (AUXRECV, SWS/BR per creazione); Ctrl+Tab tra Track Params e FX Params. [Guida](Docs/TEST54_2_AUTOMATION_CTRL_TAB.md). Nessuna compilazione locale.

> **TEST54.1 / LReaParams 0.0.54.1:** profilo Track Params per progetto, Fixed CC persistente, annunci CC prima di Auto, Ctrl+Canc e trasporto condiviso. [Guida](Docs/TEST54_1_PROJECT_TP_FIXED_CC.md). Nessuna build locale.

> **TEST54 / LReaParams 0.0.54:** MIDI CC Fixed/Floating Track Params per F1-F3, Ctrl+E, Enter dal Send/Receive header verso il collegamento gemello. [Guida e limiti](Docs/TEST54_TRACK_CC_NUMERIC_ROUTING.md). Nessuna compilazione locale eseguita; test GitHub Actions obbligatorio.

> **TEST53.2 / LReaParams 0.0.53:** F2/F3 ora distinguono annunci verticali brevi (parametro e valore) e annunci orizzontali con traccia + Send/Receive e numerazione duplicati, evitando la ripetizione del nome sulla stessa traccia collegata. [Guida e casi di prova](Docs/TEST53_2_DIRECTIONAL_ROUTING_SPEECH.md). Solo sorgente per GitHub Actions.

# LReaParams 0.0.53 — TEST53.1 correzioni F1/F2/F3

Incolla dopo la posizione F1, annunci delle tracce collegate con numerazione solo dei send/receive ripetuti e `Search cleared` con valore corrente. [Istruzioni e prove](Docs/TEST53_1_TRACK_PASTE_SPEECH_SEARCH.md). Nessuna build locale.

# LReaParams 0.0.53 — TEST53 Track Params Ctrl+F

Filtro nativo e accessibile per F1/F2/F3 (tracce, send, receive) con indice REAPER reale per i collegamenti duplicati. La memoria `.tp`, le automazioni e la selezione rimangono compatibili con TEST52. [Dettagli e test NVDA](Docs/TEST53_TRACK_FILTERS.md). Nessuna compilazione locale eseguita.

---

# LReaParams 0.0.52 — TEST52: Track Params F1/F2/F3

Continua la migrazione dei Lua originali con **Ctrl+C/X/V tramite SWS/S&M e routing**, **Alt+Maiusc+Su/Giù per spostamento fisico folder-aware**, **Ctrl+Su/Giù tra tracce con send/receive** e **Ctrl+Maiusc+A per gli envelope supportati**. `Auto` viene annunciato dopo il valore quando l'automazione esistente è attiva e visibile. Gli envelope mancanti di send/receive e Width non vengono creati artificialmente.

Compatibilità mantenuta con la memoria `.tp`, la TEST51 e FX Params; Parameter Library esclusa. **Nessuna compilazione locale eseguita.** GitHub Actions deve verificare la build e il successivo test REAPER/NVDA. Dettagli: [TEST52 guida e piano di test](Docs/TEST52_TRACK_CLIPBOARD_MOVE_AUTOMATION.md).

---

# LReaParams 0.0.51 — TEST51 estesa: folder annidate + cancellazione F2/F3

L'ultima traccia di ogni folder annuncia anche `end folder Nome`, anche per folder annidate. In F1 **Ctrl+Invio** apre e chiude le folder, mantenendo **Invio** per Value. In F2/F3 **Canc** elimina il collegamento corrente con risoluzione dell'istanza reale anche per receive duplicati. `MIDI merge` è uno stato di sola lettura derivato dalla sorgente MIDI, come nel Lua; Invio ne spiega la semantica.

La TEST51 precedente con Add Send/Receive, routing audio/MIDI, Tab e memoria `.tp` rimane presente. **NESSUNA build locale**. Prova MSVC e test runtime esclusivamente in GitHub Actions e REAPER/NVDA. [Guida TEST51 estesa](Docs/TEST51_FOLDERS_AND_DELETE.md).

---

# LReaParams 0.0.51 — aggiornamento F1 Add Send / Add Receive

Questa revisione della **stessa TEST51** introduce la creazione di send e receive in F1 secondo la procedura a due passaggi del Lua originale: Ctrl+Maiusc+S memorizza le sorgenti e Ctrl+Maiusc+R memorizza le destinazioni. Ripeti la stessa combinazione dopo aver selezionato il secondo gruppo. Esc annulla l'operazione in sospeso, Tab ne legge lo stato. Selezioni multiple e controllo delle autoconnessioni inclusi; le route sono annullabili tramite Undo di REAPER.

Rimane invariato tutto il resto della 0.0.51, inclusa la memoria persistente `.tp`, il motore FX Params e la navigazione F2/F3. **Nessuna compilazione locale:** usa GitHub Actions, quindi testa in REAPER e con NVDA. I test Python sono statici e non attestano il comportamento runtime. Dettagli in `Docs/TEST51_F1_ADD_SEND_RECEIVE.md`.

---

> **TEST51 / LReaParams 0.0.51:** Track Params F2/F3: coppie sorgente/destinazione audio modificabili, espansione dei canali fino a 128, bus MIDI 0–16 e Send type 0–3. Ctrl+Maiusc+V rimosso (Invio basta); folder su Ctrl+Alt+Su/Giù. [Dettagli e test manuali](Docs/TEST51_TRACK_ROUTING_AND_SHORTCUTS.md). Solo sorgente per GitHub Actions; nessuna compilazione locale.

> **TEST50 / LReaParams 0.0.50:** Tab ora legge le informazioni di Track Params al posto di Ctrl+R. La pagina F1 introduce selezione multipla, intervalli Shift e navigazione tra folder. [Dettagli e prove](Docs/TEST50_TRACK_F1_SELECTION_TAB.md). Solo sorgente, compilazione esclusiva tramite GitHub Actions.

> **TEST49 / LReaParams 0.0.49:** Track Params F1/F2/F3 ora dispone di Step persistenti individuali, annunci editing per parametro e memoria delle posizioni nel file `Tracks/Track CC Map.tp`. Ctrl+T memorizza il parlato MIDI Track ma il runtime MIDI non è ancora migrato. Vedere [test e scorciatoie](Docs/TEST49_TRACK_PERSISTENT_MEMORY.md). Solo sorgente, nessuna compilazione locale.

# LReaParams 0.0.48 — F7 e FX Memories F8

Aggiornamento della 0.0.46.5; preserva Track Params, le funzionalità FX
collaudate, la memoria persistente e le scorciatoie. Migrazione mirata dei
comportamenti F7/F8 dal Lua, con conferma sicura del Default anche su Canc,
limiti espliciti agli editor da F8 e supporto ai virtuali in Hidden. Dettagli,
limiti e prove manuali in `Docs/TEST47_F7_F8_COMPLETION.md`.

**NON compilare localmente: GitHub Actions è l'unico ambiente di build.**

# LReaParams 0.0.46.5 — Monitor FX Delta Solo globale

**Ctrl+Maiusc+D** continua a usare l’azione nativa di REAPER per azzerare Delta Solo sugli FX del progetto. Poiché i **Monitor FX** sono una catena separata non salvata nel progetto, dopo l’azione nativa la DLL controlla esplicitamente i Delta Solo dei Monitor FX e li disattiva, verificando il valore effettivo. Se una modifica resta attiva, annuncia `Delta Solo not cleared` invece di confermare falsamente il successo.

**Ctrl+D** rimane invariato: attiva/disattiva Delta Solo solo sull’FX corrente o evidenziato nel browser. Nessuna modifica a Master/Monitor come colonne, bypass, offline, riordino, F7/F8, Track Params, profili e MIDI.

Nessuna compilazione locale: usare solo GitHub Actions e verificare in REAPER con NVDA.

---

# LReaParams 0.0.46.4 — Browser Master / Monitor: due colonne

**Ctrl+P** apre il browser nella catena di partenza. **Freccia Destra** dalla colonna Master passa alla colonna Monitor FX; **Freccia Sinistra** dalla colonna Monitor ritorna a Master. Ogni colonna ricorda la propria posizione mentre il browser è aperto. La freccia opposta sul bordo esterno non fa nulla.

Le due catene NON vengono unite: Su/Giù, Ctrl+Su/Giù, Pagina Su/Giù, ricerca per iniziale, riordino Ctrl+Maiusc+Su/Giù e azioni sul singolo FX rimangono confinati alla colonna corrente. Invio e Ctrl+P aprono la griglia dell'FX evidenziato, anche dopo un cambio di colonna. Se una colonna è vuota, viene annunciato il relativo contesto con `No FX` e puoi tornare indietro.

**Solo sorgente. Nessuna compilazione locale.** Il comportamento effettivo sarà verificato con GitHub Actions, REAPER e NVDA.

---

# Cronologia: 0.0.46.3 — Browser Master / Monitor separati

- Quando si apre FX Params dalla lista nativa di REAPER, l’FX realmente focalizzato ha precedenza su un’altra catena eventualmente visibile.
- **Ctrl+P da Master FX:** il browser contiene soltanto la catena Master FX; nessun passaggio ai Monitor FX tramite frecce, ricerca o riordino.
- **Ctrl+P da Monitor FX:** il browser contiene soltanto i Monitor FX.
- **Ctrl+Su/Giù fuori dal browser:** naviga fra gli effetti della catena corrente senza attraversare Master/Monitor.
- **Su/Giù o Ctrl+Su/Giù nel browser:** si spostano esclusivamente fra gli FX della catena di apertura.
- **Pagina Su/Giù:** sposta di cinque FX nella stessa catena. **Ctrl+Maiusc+Su/Giù:** riordina fisicamente gli FX solo all'interno della catena.
- **Nella precedente 0.0.46.3** Sinistra/Destra non cambiava colonna; **la 0.0.46.4 ripristina il passaggio orizzontale**. Per aprire l'altra catena, selezionala esplicitamente in REAPER e riapri FX Params.
- Bypass, Delta Solo, Offline e ricerca per iniziale sono limitati all'FX evidenziato nella catena corrente. Ctrl+Maiusc+D conserva il comportamento globale di disattivazione Delta Solo.

Nessuna modifica a Track Params, ai formati dei profili, MIDI, automazioni, F7/F8 e Clipboard. L'elenco interno conserva entrambi i tipi di FX solo per mantenere GUID e memorie di sessione; **non** è una catena unica esposta all'utente.

**Non compilare localmente.** Compilazione e collaudo esclusivamente tramite GitHub Actions e REAPER/NVDA.

---

# LReaParams 0.0.46.2 — FX Browser Delta Solo e Offline

# LReaParams 0.0.45 — sorgente FX Clipboard / Default Snapshot

# LReaParams 0.0.44.4 — Fix compilazione GitHub Actions

Corretto il riferimento a `VK_0` (costante non esistente in Win32) in `src/InputRouter.cpp`, sostituendolo con il codice virtual-key ASCII del tasto `0` (`'0'`, equivalente a `0x30`). Errore segnalato da MSVC: C2065. Nessuna modifica alla gestione degli eventi, all’ordinamento dei parametri o alla memoria persistente. Aggiunto controllo preventivo in `Testing/test44_4_static.py`.

**Nessuna compilazione locale.** La DLL va compilata esclusivamente con GitHub Actions.

---

# LReaParams 0.0.44.4 — FX positions survive REAPER restarts

FX Params now saves the last visited parameter as Lua-compatible `LastParam`
inside the plugin's `.fx` profile when leaving or switching FX/track. Re-entering
after closing REAPER restores the saved parameter. Session memory remains more
specific and takes priority while REAPER stays open. Other profile content is
preserved and position-only writes are verified and backed up. See
`Docs/TEST44_4_PERSISTENT_FX_POSITION.md`.

**Do not compile locally.** Use GitHub Actions for MSVC and CTest.

---

# LReaParams 0.0.44.3 — ReaComp / ReaGate (sorgente GitHub Actions)

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

**Git commit 0.0.44.3 (Windows CMD):**

```cmd
git add . && git commit -m "0.0.44.3: add cyclic FX parameter navigation by initial" && git push
```

## TEST55.11 — conferma automazioni accessibile

Ctrl+Maiusc+Alt+A ora espone la domanda e la scelta Yes/No anche a NVDA+Freccia Su. No e predefinito; Freccia Sinistra sceglie Yes, Destra No; Invio conferma la scelta, Y conferma subito, N o Esc annulla. Vedere Docs/TEST55_11_AUTOMATION_CONFIRM_NVDA.md.
