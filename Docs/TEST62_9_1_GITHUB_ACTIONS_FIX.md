# TEST62.9.1 — Correzione della pipeline GitHub Actions

**Base:** LReaParams 0.0.62 TEST62.9. La modifica è limitata ai test statici, alle istruzioni e al workflow CI; non altera la DLL o i dati dei profili.

## Errore riscontrato

Il log `logs_112626429407.zip` riporta `AssertionError` in `Testing/test55_13_static.py`, riga 15. Il test cercava la vecchia firma:

`void TrackNavigator::jumpByInitial(wchar_t letter)`

In TEST62.9 la funzione richiede inoltre `DWORD eventTime, bool repeated` per passare l'orario originario e la ripetizione a `TypeAhead::find`. Era cambiato anche il calcolo locale dell'indice dei campi F2/F3 (`+ i` nel lambda, non più `+ next`). Il job si interrompeva prima di `cmake`/MSVC.

## Modifica

- Aggiornato il vecchio test a controllare firma, inoltro di timestamp/repeat, ricerche F1 e F2/F3, e preservazione degli altri contratti di Track Params.
- Aggiunto un passaggio esplicito del nuovo test TEST62.9 al workflow GitHub Actions.
- Mantenuti intatti codice sorgente operativo, profili e formati.

## Risultato locale

- 104/104 test Python statici superati.
- `Tools/audit.py` passato.
- Test standalone `Testing/TypeAheadTests.cpp` compilato con `g++ -std=c++17` ed eseguito correttamente.
- La compilazione della DLL Windows MSVC, i CTest completi e la prova con REAPER/NVDA richiedono ancora GitHub Actions e Windows.

## Prova

Dopo `git push`, verifica che GitHub Actions superi `TEST55.13 incremental search and guarded sends` e arrivi a Configure, Build e CTest.
