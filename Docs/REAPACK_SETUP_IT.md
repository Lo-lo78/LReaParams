# LReaParams 0.0.72 — pubblicazione GitHub e ReaPack senza perdere lo storico

**Nuova release:** `v0.0.72` (17 novembre 2026). Le versioni `v0.0.71`, `v0.0.70`, `v0.0.69` e tutte le precedenti restano pubblicate e indicizzate se idonee. **Non spostare, eliminare o ricreare vecchi tag; non sovrascrivere manualmente `index.xml`.**

1. Estrai lo ZIP GitHub Ready **0.0.72** nel clone Git locale già esistente. Preserva `.git` e `index.xml` del clone; non inizializzare un nuovo repository.
2. Dalla radice del repository esegui:

   `Tools\push_lreaparams.cmd "Release 0.0.72 - Empty titles and explicit Step saving"`

   Lo script originale recupera l'indice remoto e fa commit, rebase e push senza forzature. Se si ferma su un errore Git, non usare `git push --force` o `git reset --hard`.
3. Verifica il workflow **Build LReaParams Windows x64**. Scarica l'artefatto `LReaParams-0.0.72-Windows-x64-SETUP-EXE`; verifica l'installer e prova in REAPER/NVDA/OSARA i titoli vuoti e il salvataggio Step con Alt+S.
4. In **GitHub Releases → Draft a new release**, usa tag `v0.0.72` sul commit verificato, titolo `LReaParams 0.0.72 - Empty Titles and Explicit Step Saving` e descrizione da `Docs/GITHUB_RELEASE_0_0_72_BODY_EN.md`. Allega solo il pacchetto installer 0.0.72.
5. Pubblica come release **stabile**, non prerelease. Solo l'evento `release: published` avvia il publisher automatico ReaPack; il semplice push non lo avvia.
6. Attendi la conclusione positiva dei job `build-native-release-asset` e `regenerate-reapack-index`. Il secondo ricostruisce l'indice da **tutte** le release stabili con DLL idonea, mantenendo lo storico.
7. Controlla l'indice aggiornato e le voci precedenti. Per ripetere il publisher usa l'azione manuale con tag `v0.0.72`. Dopo il commit automatico dell'indice, aggiorna il clone locale usando `git pull --rebase origin main`.

**Non modificare:** `Tools/push_lreaparams.cmd`, `.github/workflows/publish-reapack.yml`, `Tools/generate_reapack_index.py`. Lo ZIP sorgenti non include `index.xml`: esso viene recuperato dal repository e gestito dalla pubblicazione automatica.
