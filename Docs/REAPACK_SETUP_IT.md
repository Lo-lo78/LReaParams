# LReaParams - Pubblicazione automatica su ReaPack

Questi file si **aggiungono** al repository pubblico `Lo-lo78/LReaParams`.
Non rimpiazzano il workflow Windows esistente e non modificano il C++.

## Cosa contiene

- `index.xml` (radice): indice ReaPack, inizialmente vuoto.
- `.github/workflows/publish-reapack.yml`: workflow GitHub Actions.
- `Tools/generate_reapack_index.py`: generatore dell'XML dalle release.
- `Testing/test_reapack_index_generator.py`: test offline del formato.
- `Testing/reapack_fixture.json`: dati di esempio solo per i test.

## Prima attivazione (necessaria solo una volta)

1. Copia le cartelle e `index.xml` dalla cartella di questa consegna
   nella radice del repository LReaParams, rispettando i percorsi.
   **Unisci** `.github`, `Tools`, `Testing`: non cancellare le cartelle esistenti.
2. Da Git Bash, nella cartella del progetto, esegui:

   `git add . && git commit -m "Add automatic ReaPack publishing" && git push`

3. Su GitHub entra nel repository, sezione **Actions**.
   Apri **Publish LReaParams to ReaPack**, poi **Run workflow**.
4. Come `tag` digita esattamente `v0.0.63`, quindi conferma.
5. Attendi il completamento del workflow: il job Windows compila e testa
   la DLL corrispondente al tag, carica `reaper_lreaparams.dll` fra gli
   asset della release 0.0.63; il job Linux rigenera `index.xml` e lo
   pubblica nella branch `main`.
6. Solo dopo il completamento verde, apri e verifica:

   https://raw.githubusercontent.com/Lo-lo78/LReaParams/main/index.xml

   Deve contenere `<version name="0.0.63" ...>` e il collegamento alla DLL.
7. Da REAPER, con ReaPack già installato:
   Extensions > ReaPack > Import repositories.
   Inserisci:

   https://raw.githubusercontent.com/Lo-lo78/LReaParams/main/index.xml

   Poi Extensions > ReaPack > Browse packages, cerca `LReaParams`,
   seleziona Install e applica la transazione. Riavvia REAPER.

## Release future

Pubblica normalmente la release GitHub (per esempio `v0.0.64`), con lo
stesso procedimento di sempre. Il nuovo workflow:

1. Compila/testa il sorgente **esatto del tag** Windows x64 con MSVC.
2. Aggiunge alla release il file DLL installabile direttamente da ReaPack.
3. Consulta tutte le release pubbliche stabili (non i soli dati di `main`).
4. Inserisce nell'XML soltanto quelle con DLL autonoma disponibile.
5. Registra tutte le guide HTML e gli altri file Guide presenti nel tag.
6. Committa l'indice solo se cambia. Gli utenti aggiornano
   sincronizzando ReaPack.

**Importante:** aggiorna versione CMake, About e installer come sempre
**prima** di creare il nuovo tag. Il workflow verifica che il numero della
release e `project(LReaParams VERSION ...)` coincidano.

## Installazione e compatibilità

ReaPack installa:
- DLL: `REAPER resource path/UserPlugins/reaper_lreaparams.dll`
- Guide: `REAPER resource path/UserPlugins/Guide/...`

È un percorso già riconosciuto dall'azione `LReaParams: Open User Guide`
della versione 0.0.63. La nuova installazione **non** tocca:
- `REAPER resource path/LReaParams/Plugins/*.fx`
- `REAPER resource path/LReaParams/Tracks/*.tp`
- `REAPER resource path/LReaParams/Settings`
- altre memorie, backup o configurazioni personali.

L'installer Windows rimane pubblico e indipendente, con il proprio
disinstallatore. ReaPack installa la DLL e le guide, **non** l'installer
NSIS né il relativo programma di disinstallazione, e non lo esegue.

Se hai già installato LReaParams con il setup, potrebbe esistere anche
`REAPER resource path/LReaParams/Guide`. L'azione della guida in 0.0.63
preferisce quella posizione alla copia sotto `UserPlugins/Guide`, quindi
in una installazione mista è possibile vedere la guida precedente finché
non viene aggiornata con l'installer. La DLL resta aggiornata con ReaPack.
Per un futuro intervento sul C++ si può dare precedenza alle guide ReaPack
oppure gestire esplicitamente i due metodi d'installazione.

Non distribuire la DLL x64 a macOS o Linux: l'indice usa `platform="win64"`.

**Il workflow non è stato eseguito sul tuo account durante la preparazione
di questi file.** I test locali verificano la generazione XML, non la
compilazione su Windows né una vera installazione tramite ReaPack.

## In caso di problema

- Se `Run workflow` non compare: verifica che il file
  `.github/workflows/publish-reapack.yml` sia sulla branch `main`
  e che Actions sia abilitato sul repository.
- Se il job non può caricare la DLL o fare push: controlla in GitHub
  Settings > Actions > General la policy relativa ai permessi di
  `GITHUB_TOKEN`, e che sia consentita la scrittura sul repository.
  Una protezione della branch `main` può richiedere una regola apposita
  o una PR al posto del push diretto.
- Se fallisce il build Windows: il generatore XML non pubblica la DLL
  incompleta e non avanza la versione.
- Se l'XML non include una vecchia release: è intenzionale finché non
  esiste il suo file `reaper_lreaparams.dll` fra gli asset pubblici.
- Se la guida non si apre: controlla i percorsi `Guide` sopra e se
  esiste una vecchia copia dell'installer.

## Collegamenti tecnici

- Formato XML ufficiale: https://github.com/cfillion/reapack/wiki/Index-Format
- Codice ReaPack per percorsi di installazione:
  https://github.com/cfillion/reapack/blob/master/src/source.cpp
- Repository LReaParams: https://github.com/Lo-lo78/LReaParams
