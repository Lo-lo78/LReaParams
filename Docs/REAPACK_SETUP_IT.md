# LReaParams 0.0.71 — pubblicazione GitHub e ReaPack senza perdere lo storico

**Nuova release:** `v0.0.71` (16 novembre 2026). Le `v0.0.70`, `v0.0.69` e tutte le precedenti rimangono pubblicate. **Non spostare, cancellare o ricreare tag precedenti; non riscrivere manualmente `index.xml`.**

1. Estrai il contenuto dello ZIP **0.0.71 GitHub Ready** nella cartella Git locale già esistente. Conserva `.git` e l'eventuale `index.xml` presente nel clone; non usare `git init` o `git push --force`.
2. Dalla radice del repository esegui:

   `Tools\push_lreaparams.cmd "Release 0.0.71 - Customizable FX Type and Name titles"`

   Lo script originale recupera l'indice remoto, crea il commit, esegue `git pull --rebase origin main` e invia un push normale.
3. Controlla **GitHub Actions → Build LReaParams Windows x64**. Scarica `LReaParams-0.0.71-Windows-x64-SETUP-EXE`, verifica l'EXE **0.0.71** e prova About, FX Params e Track Params F4 con NVDA/OSARA prima della release stabile.
4. Crea **GitHub Releases → Draft a new release**, tag **`v0.0.71`** sul commit appena verificato, titolo **`LReaParams 0.0.71 - Independent FX Type and Name Titles`** e descrizione da `Docs/GITHUB_RELEASE_0_0_71_BODY_EN.md`. Allega lo ZIP dell'installer di **0.0.71**; non usare asset di versioni precedenti.
5. Premi **Publish release** come **stabile**, non prerelease. Il `release: published` avvia automaticamente `Publish LReaParams to ReaPack`. Un semplice push del sorgente NON avvia questo publisher.
6. Il job `build-native-release-asset` compila la DLL dal tag della release e allega `reaper_lreaparams.dll`. `regenerate-reapack-index` recupera tutte le release stabili idonee, genera `index.xml` e lo aggiorna su `main` senza eliminare le vecchie versioni.
7. Verifica il workflow verde e la nuova voce **0.0.71** insieme allo storico. Se occorre ripetere il publisher, usa **Run workflow** e il tag `v0.0.71`, senza cambiare versioni o tag. Dopo il commit automatico ReaPack sincronizza la copia locale (`git pull --rebase origin main`).

**Non alterare:** `Tools\push_lreaparams.cmd`, `.github/workflows/publish-reapack.yml`, `Tools/generate_reapack_index.py`. Il pacchetto dei sorgenti non deve includere `index.xml`; il clone remoto può e deve conservarlo.
