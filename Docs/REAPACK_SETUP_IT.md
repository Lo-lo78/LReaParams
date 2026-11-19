# LReaParams 0.0.75 — pubblicazione GitHub e ReaPack senza perdere lo storico

**Nuova release stabile:** `v0.0.75` (19 novembre 2026). **Precedente:** `v0.0.74` (18 novembre 2026). Tutte le versioni precedenti idonee, incluse `v0.0.73`, `v0.0.72`, `v0.0.71`, `v0.0.69` e i vecchi tag, devono rimanere pubblicate e indicizzate.

## Procedura protetta

1. Estrai lo ZIP **GitHub Ready 0.0.75** nel **clone Git locale già esistente**. Non cancellare `.git` né il file `index.xml` eventualmente presente nel clone. Non inizializzare un nuovo repository.
2. Dalla radice del clone esegui **solo**:

   ```cmd
   Tools\push_lreaparams.cmd "Release 0.0.75 - Accessible native Render navigation and reverse accelerators"
   ```

   Lo script recupera `origin/main` e ripristina `index.xml` dal repository remoto prima del commit; poi usa `git pull --rebase origin main` e `git push origin main` senza forzature. Se restituisce un errore, non usare `git push --force`, `git reset --hard` o un comando Git generico.
3. In **GitHub → Actions → Build LReaParams Windows x64**, verifica che il push abbia compilato con MSVC e superato CTest. Scarica l'artefatto **`LReaParams-0.0.75-Windows-x64-SETUP-EXE`**, che contiene `LReaParams-0.0.75-Windows-x64-Setup.exe`. Prova con REAPER, NVDA e OSARA la finestra Render nativa, Alt+Shift+lettera e Alt+Z. Il pacchetto SOURCE non contiene DLL/installer precompilati.
4. In **GitHub → Releases → Draft a new release**, crea **un nuovo tag `v0.0.75`** sul commit appena verificato, **senza spostare alcun tag esistente**. Titolo: **`LReaParams 0.0.75 - Accessible Native Render Navigation`**. Incolla la descrizione da **`Docs/GITHUB_RELEASE_0_0_75_BODY_EN.md`** e allega l'installer EXE compilato per la 0.0.75.
5. Pubblica la release come **stabile**: non Draft e non Prerelease. **Solo l'evento GitHub `release: published` attiva il workflow `Publish LReaParams to ReaPack`**; il normale push dei sorgenti avvia la build di controllo, non la pubblicazione ReaPack.
6. Controlla che il workflow `Publish LReaParams to ReaPack` termini con entrambi i job riusciti: `build-native-release-asset` compila dal tag esatto e allega `reaper_lreaparams.dll` alla release; `regenerate-reapack-index` recupera **tutte le release stabili con DLL valida**, legge le guide dal **tag specifico di ciascuna release** e aggiorna `index.xml` in `main`, mantenendo tutte le versioni precedenti.
7. Verifica nel repository il nuovo `index.xml` (versione 0.0.75 e tutte le precedenti idonee). Aggiorna poi il clone locale con `git pull --rebase origin main` quando non ci sono modifiche locali in sospeso.

## Se il workflow di pubblicazione fallisce

- Non rimuovere o ricreare release/tag vecchi; non fare commit manuali di `index.xml`.
- Dopo aver risolto il problema, rilancia **Actions → Publish LReaParams to ReaPack → Run workflow** con input **`v0.0.75`**. Questo workflow supporta il ripristino manuale e verifica la coerenza fra tag e `project(... VERSION ...)`.
- Il workflow esclude esplicitamente draft, prerelease e release senza una DLL standalone valida. Per questo occorre controllare il completamento del primo job.

**File protetti e immutati:** `Tools/push_lreaparams.cmd`, `Tools/generate_reapack_index.py`, `.github/workflows/publish-reapack.yml`. Lo ZIP sorgente **non** include `index.xml`: quel file appartiene alla cronologia Git del repository e alla pubblicazione automatica. Non eliminare lo storico ReaPack per aggiornare una singola release.
