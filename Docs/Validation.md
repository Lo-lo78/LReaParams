# Verifiche di questa consegna

Eseguiti soltanto controlli non compilanti:

- 15 suite Python: audit formati/sorgenti e regressioni TEST18–TEST30/TEST40. Tutte passate; output in StaticTestResults.txt.
- Oracolo indipendente Python: roundtrip di 52 fixture sintetiche, 48 FX e 4 Track; BOM, CRLF, sezioni future e rifiuto input malformati. Non equivale all'esecuzione del parser C++.
- SHA-256 SDK invariati; TrackNavigator.cpp identico alla base TEST30; entrambi i Lua di riferimento identici fra TEST30 e Scripts(3).
- Delimitatori lessicali C++ e presenza API nel relativo SDK; questi controlli NON provano compilazione, linking, correttezza dei tipi o semantica.
- YAML del workflow analizzato; workflow NON lanciato.
- Archivio finale verificato tramite CRC ZIP e manifest SHA-256 di ogni file.

Non eseguiti: CMake configure/build, compilatori, MSBuild, Visual Studio, CTest nativo, avvio REAPER, controlli NVDA/OSARA, MIDI reale, ascolto o benchmark. Nessun binario incluso.

Test C++ predisposti per il runner dell'utente:

- profile_tests: parsing, roundtrip, importazione non distruttiva, backup/conflitti, Unicode, dati ritirati ignorati, memorie Compare e CC nascosti persistenti.
- control_tests: decode MIDI, pickup crossing/tolleranza/riarmo/anti-jitter, codec chunk ReaEQ e invarianza dei byte non modificati.

I risultati runtime devono essere registrati dall'utente seguendo ManualTests.md. La lista delle funzioni ancora mancanti è in Status.md e FxCommandMatrix.csv. Nessuna prova statica consente di dichiarare conclusa la migrazione.
