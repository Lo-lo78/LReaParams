# LReaParams 0.0.40 — candidato sorgente

Estensione nativa C++ per Windows x64, derivata da TEST30 (0.0.31). Restano FX Params, Track Params e le azioni ausiliarie esistenti. L'archivio contiene solo sorgenti, riferimenti Lua, SDK incluso e test: nessuna DLL o build locale.

Leggere prima **Docs/Status.md**: la migrazione è avanzata su tutta la roadmap, ma la parità completa Lua NON è raggiunta. Le lacune sono elencate senza placeholder di successo.

File principali:

- Docs/CHANGELOG.md: modifiche effettive e confronto degli allegati.
- Docs/FxCommandMatrix.csv: funzione Lua, gesto, contesto, codice C++, stato e prova.
- Docs/Keyboard.md: guida tastiera attuale.
- Docs/ManualTests.md: prove da svolgere dopo la compilazione.
- Docs/Validation.md: risultati e limiti delle verifiche.
- Docs/Specification.txt: handoff originale fornito per questa richiesta.

Per compilare, caricare il contenuto dello ZIP alla radice del repository, includendo .github/workflows. Eseguire il workflow Build LReaParams Windows x64 in GitHub Actions; l'artifact contiene reaper_lreaparams.dll. Installare in UserPlugins della resource path REAPER, a REAPER chiuso. I dati usati sono LReaParams/Plugins, Tracks, Settings, Backups. Nessuna scansione o pulizia delle vecchie cartelle del navigatore rimosso.

Controlli locali ammessi, senza compilazione:

    python Tools/run_static.py

Il workflow esegue poi build MSVC e CTest sul runner. Non è stato eseguito dall'assistente.

Comando Windows CMD da lanciare nella cartella del repository:

    git status && git add . && git commit -m "FX Params migration candidate: MIDI pickup, automation, presets, Compare and defaults; remove Parameter Library" && git push
