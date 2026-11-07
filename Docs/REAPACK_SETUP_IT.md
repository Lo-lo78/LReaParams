# LReaParams 0.0.66 — distribuzione GitHub e ReaPack

Il catalogo già importato è `https://raw.githubusercontent.com/Lo-lo78/LReaParams/main/index.xml`. Non importare un secondo indirizzo.

1. Copia il sorgente completo nel repository locale **senza eliminare `index.xml`**. Usa `Tools\push_lreaparams.cmd "Release 0.0.66 Keyboard Page parity and ReaPack CI fixes"` per sincronizzare i commit generati da GitHub Actions, creare il commit e fare il push.
2. In Actions verifica che **Build LReaParams Windows x64** termini con **Success** per il nuovo commit e scarica l'artefatto `LReaParams-0.0.66-Windows-x64-SETUP-EXE`. Non pubblicare se il build fallisce.
3. Crea una nuova GitHub Release stabile da `main` con **tag esatto `v0.0.66`**, senza punto finale. Allega lo ZIP contenente l'EXE del setup, non questo ZIP dei sorgenti. Non scegliere pre-release.
4. **Publish release** avvia automaticamente il workflow `Publish LReaParams to ReaPack` tramite l'evento `release: published`. Il caricamento dello ZIP da solo non avvia nulla.
5. Il job `build-native-release-asset` compila e carica `reaper_lreaparams.dll`; il job `regenerate-reapack-index` rigenera e committa l'XML. Entrambi devono riportare **Success**.
6. Se il trigger automatico non parte, avvia manualmente lo stesso workflow da `main`; lascia vuoto il campo tag per usare l'ultima release stabile. Non digitare `v0.0.66.`.
7. Controlla che la release contenga la DLL, che `index.xml` riporti `version name="0.0.66"`, poi sincronizza i pacchetti da REAPER.

L'aggiornamento automatico di `index.xml` genera un commit remoto; è normale dover sincronizzare Git locale prima del successivo push. Non utilizzare `git push --force` e non cancellare l'indice.
