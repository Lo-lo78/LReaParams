# LReaParams 0.0.69 — pubblicazione GitHub e ReaPack senza perdere lo storico

**Non modificare né spostare i tag pubblicati, incluso v0.0.68.** La nuova release è `v0.0.69`.

1. Copia il contenuto di questo sorgente nella cartella Git esistente. Conserva `.git`, `index.xml` e le impostazioni del repository. Non usare `git init`, `git push --force` o `git add -A` in una cartella errata.
2. Dalla radice esegui `Tools\push_lreaparams.cmd "Release 0.0.69 - Used in F7 and persistent Used view"`. Se Git segnala conflitti o errori, non creare il tag.
3. In Actions, controlla che **Build LReaParams Windows x64** per il commit appena inviato sia verde. Scarica `LReaParams-0.0.69-Windows-x64-SETUP-EXE` e verifica la presenza di `LReaParams-0.0.69-Windows-x64-Setup.exe`. Prova About e la funzione Used in F7 con NVDA/OSARA.
4. Crea UNA release stabile: tag `v0.0.69`, target il commit compilato, titolo `LReaParams 0.0.69 - Used in F7 and Persistent Used View`. Copia la descrizione da `Docs/GITHUB_RELEASE_0_0_69_BODY_EN.md`, allega SOLO lo ZIP dell'installer della 0.0.69.
5. Dopo Publish release apri Actions > Publish LReaParams to ReaPack. Se il run automatico non parte, usa **Run workflow** su `main` e inserisci `v0.0.69`. Non ricreare il tag.
6. Controlla il job `build-native-release-asset` che allega `reaper_lreaparams.dll` alla release e il job `regenerate-reapack-index` che aggiorna solamente `index.xml` ricostruendo lo storico dalle release stabili con DLL.
7. Verifica che `index.xml` elenchi la nuova `0.0.69` e le versioni precedenti. Una volta aggiornato l'indice con commit automatico, sincronizza il repository locale con `git pull --rebase origin main` prima di un nuovo push.

Non modificare manualmente lo storico in `index.xml` né cancellare asset delle release precedenti. Una modifica al generatore dell'indice non è necessaria per aggiungere una nuova release stabile.
