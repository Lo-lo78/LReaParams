# LReaParams - Pubblicazione automatica su ReaPack

Il repository `Lo-lo78/LReaParams` contiene già il workflow di pubblicazione ReaPack.
Questa consegna 0.0.64 comprende l'intero sorgente e mantiene la
pubblicazione automatica. Non occorre reinstallare o aggiungere il repository.

**Attenzione:** lo ZIP 0.0.64 non contiene volutamente `index.xml`.
La copia locale del repository conserva quello esistente, già popolato
dalle release pubbliche. Non sostituirlo con un indice vuoto e non cancellarlo.
Il workflow `publish-reapack.yml` lo rigenererà quando pubblicherai la release.

## Il repository ReaPack è già attivo

L'utente ha già importato `https://raw.githubusercontent.com/Lo-lo78/LReaParams/main/index.xml` in ReaPack. Non serve reimportare l'URL o creare un secondo catalogo.

Per aggiornare con la nuova versione 0.0.64:

1. Sostituisci i sorgenti del repository con il progetto completo 0.0.64. Esegui `git add . && git commit -m "Release 0.0.64 iZotope RX 11 readback fix" && git push`.
2. Controlla che **Build LReaParams Windows x64** compili senza errori e produca l'installer `LReaParams-0.0.64-Windows-x64-SETUP-EXE`.
3. Solo allora crea una **nuova release stabile** (non draft e non prerelease) con il tag `v0.0.64` sul commit di `main` appena compilato.
4. Pubblica la release. **Questo evento**, non il caricamento di un EXE.zip, avvia il workflow `Publish LReaParams to ReaPack`.
5. Il job Windows compila la DLL dal tag esatto e la allega alla release come `reaper_lreaparams.dll`; poi il job Linux rigenera e committa l'indice `index.xml` su `main`.
6. Verifica su GitHub Actions che entrambi i job siano verdi; soltanto allora la nuova versione è disponibile tramite ReaPack > Synchronize packages.

Il file EXE distribuito nello ZIP di Actions può essere aggiunto manualmente tra gli asset della release per installare LReaParams senza ReaPack, ma **non** aggiorna da solo l'indice. Il file `index.xml` non si modifica a mano.

## Release future

Pubblica normalmente la release GitHub (ad esempio `v0.0.65`, per la successiva), con lo
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
dalla versione 0.0.63 e nella 0.0.64. La nuova installazione **non** tocca:
- `REAPER resource path/LReaParams/Plugins/*.fx`
- `REAPER resource path/LReaParams/Tracks/*.tp`
- `REAPER resource path/LReaParams/Settings`
- altre memorie, backup o configurazioni personali.

L'installer Windows rimane pubblico e indipendente, con il proprio
disinstallatore. ReaPack installa la DLL e le guide, **non** l'installer
NSIS né il relativo programma di disinstallazione, e non lo esegue.

Se hai già installato LReaParams con il setup, potrebbe esistere anche
`REAPER resource path/LReaParams/Guide`. L'azione della guida in 0.0.64
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
