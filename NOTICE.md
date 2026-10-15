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
