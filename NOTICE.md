# Provenienza

Il progetto LReaParams e il materiale Lua sono stati forniti/richiesti da Lo-lo.
I tre file in Legacy sono copie inalterate degli allegati, con autore dichiarato
nei loro header: **Lo-lo + GPT**. Non vengono eseguiti, modificati o redistribuiti
nell'artifact binario. Sono riferimenti per verificare il successivo porting.
Questo pacchetto non attribuisce una nuova licenza ai materiali dell'utente.

Gli header in third_party/reaper-sdk provengono da Cockos Incorporated;
mantengono integralmente i rispettivi avvisi e la licenza contenuta nei file.
Repository e commit esatti sono in third_party/reaper-sdk/manifest.json.

Il codice OSARA non è copiato né linkato staticamente. La DLL invoca soltanto
le API registrate da OSARA nell'host. OSARA rimane un'estensione distinta.
I riferimenti al suo sorgente servono a verificare il contratto delle API.

Le fixture pubblicabili sono sintetiche: nomi di plugin, parametri, celle,
progetti e GUID personali sono sostituiti. Gli originali di dati.zip non sono
inclusi. README e Docs distinguono implementazione, test e porting pendente.

TEST16 (0.0.17): Track Params passive NVDA+Up review reduced to parameter and value in Grid; contextual row announcements and Ctrl+R unchanged. No local compilation.

TEST17 (0.0.18): source-only initial FX Custom Order integration and principal F7 editor operations with native .fx profile persistence and backups. F7 not fully equivalent to Lua; F8 and advanced related editors pending. No local compilation.

TEST20 (0.0.21): only Ctrl+Shift+P hardcoded when native FX Chain list is focused; P remains a REAPER Main Action List user binding, with FX Params shortcut bridge. No local compilation.

TEST22 (0.0.23): Home/End order corrected in FX grid and memory navigation; Bypassed/Delta Solo moved before context/plugin in speech and NVDA title. No local compilation.

TEST23 (0.0.24): F7 filtered search and undo/redo; native Win32 EDIT for rename/search, group labels, Alt+G/Alt+M, Backspace resets and default memory snapshots. No local build.

TEST24 (0.0.25): selected F7 parameters announced; Tab position counts, explicit F7 Custom Order creation and context-aware group/parameter rename. No local build.

TEST25 (0.0.26): Ctrl+Fn repeated group returns Plugin Order; F8 Enter navigates outside edit except Hidden, F8 Default restores and exits to Plugin Order; quoted word-boundary search. No local build.

TEST26 (0.0.27): supersedes TEST25's unconditional Plugin Order group exit;
restores the originating order and current F7 state, adds Ctrl+F12 as group/position
slot 12 without claiming OSARA's bare F12, filters the grid for Ctrl+F in both
modes, and navigates selected F7 grid cells with Alt+arrows. No local build.

TEST27 (0.0.28): Alt+Shift+arrows navigates selected F7 parameters; bare F12 is reserved and inert while LReaParams owns focus. Ctrl+F12 and Ctrl+Shift+F12 retain slot 12. No local build.
