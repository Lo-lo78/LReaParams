# LReaParams 0.0.68 — pubblicazione sicura e conservazione dello storico

**Attenzione: v0.0.67 è già pubblicata su GitHub, con i reset separati di Griglia e Step.** Non ricreare v0.0.67, non spostare il tag e non sovrascrivere il suo installer. La nuova funzione Usati va pubblicata come **v0.0.68**.

1. Copia i file del nuovo ZIP **0.0.68 RELEASE_SOURCE** nel repository Git LReaParams esistente. Non cancellare `.git`, `.github` o `index.xml`, non eseguire `git init` e non usare `git push --force`.
2. Dalla radice del repository esegui `Tools\push_lreaparams.cmd "Release 0.0.68 - Used Parameters virtual view"`. In caso di conflitti o messaggi di errore, fermati prima di creare un tag.
3. In Actions > **Build LReaParams Windows x64**, controlla **il run associato al nuovo commit**. Deve terminare con Success, compresi i test. Scarica l'artefatto **LReaParams-0.0.68-Windows-x64-SETUP-EXE**. Estrailo e verifica che contenga `LReaParams-0.0.68-Windows-x64-Setup.exe`; prova About 0.0.68 e Usati con NVDA/OSARA.
4. Apri **New release** e crea il tag **`v0.0.68`** con target il **commit già compilato**. Titolo: `LReaParams 0.0.68 - Used Parameters (Usati)`. Descrizione: `Docs/GITHUB_RELEASE_0_0_68_BODY_EN.md`. Allega solo lo ZIP di setup 0.0.68, non il sorgente né il vecchio installer. Pubblica come release stabile.
5. L'evento `release: published` avvia il workflow **Publish LReaParams to ReaPack**. Dopo il job `build-native-release-asset`, deve completarsi `regenerate-reapack-index` e comparire `reaper_lreaparams.dll` nella release.
6. Verifica che `index.xml` contenga **0.0.68 e tutte le precedenti versioni disponibili**. Il workflow aggiunge un commit automatico sul remoto: prima di modifiche successive, sincronizza il repository locale con `git pull --rebase origin main`.

**Non editare la vecchia release 0.0.67 per pubblicare Usati**: modificarne soltanto il testo non aggiorna la DLL né garantisce il lancio del workflow ReaPack. Non cancellare tag storici o l'indice esistente.
