# Verifiche di questa consegna

Eseguiti soltanto controlli non compilanti:

- 16 suite Python: audit formati/sorgenti e regressioni TEST18–TEST30/TEST40/TEST41. Tutte passate; output in StaticTestResults.txt.
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

TEST41: regressione statica `Auto` sugli annunci aggiunta; nessun test runtime o compilazione locale.

TEST42: 17 suite Python non compilanti passate; nuovo test42_static e workflow GitHub Actions aggiunti. Nessun MSVC/CMake/CTest locale o REAPER/NVDA/MIDI reale eseguito. La compatibilità runtime del motore background è ancora da verificare.

## Verifica delta 0.0.42.1

Correzione read-only di CC/Auto nella lettura parametri, senza build locale.
L'audit e i contratti statici vengono rieseguiti in `Tools/run_static.py`;
GitHub Actions eseguirà MSVC e CTest sul runner. NVDA e REAPER devono
essere collaudati con CC interno, CC nativo, envelope ACT e doppio suffisso.

## 0.0.43 ReaEQ source check

19 Python suites PASS (includes TEST43 virtual ID source contract). The bundled C++ ControlTests contain band add/remove and enum-mapping cases but have **not run locally**. GitHub Actions runs MSVC/CTest. ReaEQ FX host behavior and NVDA need physical REAPER tests; see TEST43_REAEQ_VIRTUALS.md.

## 0.0.43.1 — ordine ReaEQ Custom Order

Aggiunti controlli statici e test C++ (eseguiti solo dal workflow GitHub Actions) per ordini Lua precedenti ai virtuali, suffix generato dalla 0.0.43, idempotenza, preservazione dell’ordine personalizzato e caricamento non distruttivo dei profili `.fx`. Non è stata eseguita alcuna compilazione locale.

## 0.0.43.2 — Band property false-negative reports

Aggiunto test statico `Testing/test43_2_static.py` e casi in `Testing/ControlTests.cpp`, eseguibili in C++ soltanto tramite GitHub Actions. Verifica del valore letto dopo `BANDENABLED#` / `BANDTYPE#`, fallback chunk e mantenimento di messaggi per veri errori. Nessuna compilazione locale, nessun test REAPER/NVDA effettuato.
