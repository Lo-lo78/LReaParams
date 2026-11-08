# LReaParams 0.0.67 — pubblicazione GitHub e ReaPack (storico preservato)

**Ultima release GitHub pubblica verificata prima della preparazione: 0.0.66.** La TEST67.1 viene integrata nella nuova release stabile **0.0.67**. Non riutilizzare installer 0.0.66, e non pubblicare 0.0.68 saltando la 0.0.67.

Il catalogo esistente è `https://raw.githubusercontent.com/Lo-lo78/LReaParams/main/index.xml`: **non crearne un secondo e non cancellare quello esistente**. Le versioni storiche sono determinate dai tag stabili con DLL di ogni release.

1. **Copia il contenuto** dello ZIP dei sorgenti in una cartella Git del repository già esistente. **Non cancellare `.git` o `index.xml`**. Lo ZIP non include la cartella `.git`; non fare `git init` né forzare push.
2. Apri `cmd` nella radice del repository ed esegui:

   `Tools\push_lreaparams.cmd "Release 0.0.67 - Used Parameters and Independent Grid Controls"`

   Lo script conserva l'`index.xml` remoto e usa il rebase per integrare i commit automatici di GitHub. Se appare un conflitto, **fermarsi**, senza `push --force` o `reset --hard` sulla copia locale.
3. In **Actions → Build LReaParams Windows x64**, apri **il nuovo run associato esattamente al commit appena inviato**. Attendi **Success** per build e test. Se è rosso, **non creare il tag**.
4. Scarica l'artefatto **`LReaParams-0.0.67-Windows-x64-SETUP-EXE`** del nuovo run: contiene `LReaParams-0.0.67-Windows-x64-Setup.exe`. Prova la nuova versione in REAPER e verifica l'About 0.0.67, la lista Usati e i comandi Backspace.
5. Crea **una sola** GitHub Release stabile: **tag `v0.0.67`**, titolo `LReaParams 0.0.67 - Used Parameters and Independent Grid Controls`, target **il commit testato** su `main`, non un commit diverso. Allega l'artefatto ZIP del setup **0.0.67**. Non selezionare **pre-release**. Pubblica la release con **Publish release**.
6. L'evento **`release: published`** avvia il workflow **Publish LReaParams to ReaPack**. Il job **`build-native-release-asset`** compila dal **tag** e carica `reaper_lreaparams.dll`; solo dopo, **`regenerate-reapack-index`** ricostruisce e invia `index.xml` usando **tutte** le release stabili dotate di DLL.
7. Controlla che **entrambi i job siano verdi** e che nella release esista `reaper_lreaparams.dll`. Controlla in `index.xml` la versione `0.0.67` *insieme* alle versioni precedenti. In REAPER aggiorna i repository e verifica che la 0.0.67 sia proposta da ReaPack.
8. Solo in seguito, per un prossimo aggiornamento Git locale, sincronizza il commit automatico di ReaPack: usa di nuovo `Tools\push_lreaparams.cmd` quando hai vere modifiche, oppure `git pull --rebase origin main` con la directory di lavoro pulita.

**Se il workflow ReaPack non parte automaticamente:** in Actions apri `Publish LReaParams to ReaPack`, seleziona `Run workflow` su `main`, e immetti **`v0.0.67`** nel campo tag. Il workflow supporta questo avvio manuale per recuperare una release già pubblicata. **Non ricreare la release e non cancellare `index.xml`**.

**Nota sullo storico:** il job automatico può creare un nuovo commit `chore(reapack): update XML release index [skip ci]` su `main`. Questo non cancella i vecchi tag né le versioni precedenti; spiega perché una successiva copia locale potrebbe risultare indietro rispetto al repository remoto.
