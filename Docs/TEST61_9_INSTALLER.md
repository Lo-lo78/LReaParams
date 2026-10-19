# TEST61.9 — Installer Windows x64 accessibile

L'installer è generato da GitHub Actions partendo da TEST61.8; non modifica il
sorgente C++ della DLL, né le funzioni delle pagine F1–F11.

## Scelta dell'artefatto GitHub Actions

Per installare con una finestra guidata:
`LReaParams-0.0.61-Windows-x64-SETUP-EXE`.
Lo ZIP dell'artefatto contiene il file
`LReaParams-0.0.61-Windows-x64-Setup.exe`: estrarre lo ZIP ed eseguire l'EXE.

Rimangono disponibili:
- `LReaParams-0.0.61-Windows-x64-MULTILINGUAL`: installazione manuale;
- `LReaParams-Windows-x64-NATIVE-TEST`: sola DLL;
- `LReaParams-0.0.61-HTML-Guides`: guide HTML;
- `LReaParams-0.0.61-COMPLETE-SOURCE`: sorgente corrispondente al commit.

## Utilizzo accessibile con NVDA

Chiudere REAPER, avviare il setup, scegliere la lingua dell'installer.
Le finestre standard NSIS possono essere percorse con Tab, Maiusc+Tab e Invio.
Scegliere la directory **delle risorse REAPER**:

- installazione normale: `%APPDATA%\REAPER` (predefinita);
- installazione portable: selezionare la directory portable che contiene
  `reaper.ini` (tipicamente la stessa del programma).

Un avviso richiede conferma se `reaper.ini` non viene trovato: il percorso
potrebbe essere sbagliato. Il setup è per utente: non richiede privilegi
amministrativi per la cartella standard. Nelle cartelle di sistema protette,
l'utente deve avere adeguati permessi di scrittura.

## File installati

`<ResourcePath>\UserPlugins\reaper_lreaparams.dll`

`<ResourcePath>\LReaParams\Guide\index.html` (e tutte le traduzioni)

`<ResourcePath>\LReaParams\Licenses\GPL-3.0.txt`

`<ResourcePath>\LReaParams\Licenses\THIRD_PARTY_NOTICES.md`

`<ResourcePath>\LReaParams\Source\LReaParams-0.0.61-Source.zip`

`<ResourcePath>\LReaParams\Source\SOURCE-COMMIT.txt`

`<ResourcePath>\LReaParams\Uninstall-LReaParams.exe`

I profili .fx e .tp, gli archivi di backup, le preferenze e i file legacy
rimangono invariati. Nessun import legacy viene eseguito dall'installer:
REAPER proporrà la conferma Y/N gestita dalla DLL TEST61.8.

## Disinstallazione

Eseguire `Uninstall-LReaParams.exe` o usare l'elenco delle applicazioni
installate di Windows. La procedura elimina la DLL e soltanto i file
distribuiti con l'installer, senza cancellare i dati dell'utente nelle cartelle
`Plugins`, `Tracks`, `Settings`, `Backups` o altri contenuti.

## Distribuzione sotto GPLv3

Il file LICENSE introduce la proposta di licenza GPL-3.0-only per il codice
originale di LReaParams. L'autore deve verificare di detenere i diritti sui
sorgenti pubblicati, inclusi i Lua storici. Gli header REAPER SDK restano
soggetti alle loro condizioni permissive, documentate in
`THIRD_PARTY_NOTICES.md`. NSIS e il compressore zlib hanno licenza permissiva.
Una copia del sorgente corrispondente al commit della build viene inclusa
nell'EXE, con il link al repository e l'hash del commit.

## Build

Modifiche GitHub Actions: build MSVC e CTest esistenti, generazione del pacchetto
manuale, `git archive` dell'HEAD corrente, installazione di NSIS, `makensis`
e upload dell'EXE. Nessuna build locale prevista.
