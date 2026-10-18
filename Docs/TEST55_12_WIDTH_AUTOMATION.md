# TEST55.12 — F1 Track Width automation

Questa revisione parte dalla **TEST55.11**. Non riguarda F4 o Parameter Library.

## Correzione

La creazione precedente di `<WIDTHENV2` era incompleta: mancavano un `EGUID` nativo e un punto `PT 0` al valore `D_WIDTH` corrente; il controllo dopo la modifica si basava inoltre su un puntatore envelope che può essere assente o non aggiornato. Di conseguenza, anche quando Width è automatizzabile, Ctrl+Maiusc+A poteva dire `Automation change not confirmed`.

- Width è trattato come **track envelope** nativo, non come parametro FX.
- Cerca il blocco Width top-level nel chunk completo della traccia, accettando **WIDTHENV2** e il formato storico **WIDTHENV**. Non modifica sezioni interne FX/routing.
- Se manca, inserisce un `WIDTHENV2` con GUID generato tramite `genGuid`, `ACT`, `VIS`, `ARM`, `DEFSHAPE` e un punto a tempo zero con il valore attuale.
- Se esiste già, aggiorna soltanto `ACT`, `VIS` e `ARM` per attivarlo, oppure `ACT` e `VIS` per disattivarlo, conservando GUID, punti, automation item e configurazione.
- Verifica il chunk realmente salvato, inclusi stato visibile/attivo e armamento; in caso di verifica negativa ripristina il chunk precedente. Una sola operazione Undo.
- Nessuna nuova scorciatoia: **Ctrl+Maiusc+A** continua a alternare l'automazione e ad annunciare `Auto. Width, valore` oppure `Auto off. Width, valore`.

## Collaudo REAPER + NVDA

1. Nuovo progetto, una traccia con Width 100%, entra in Track Params F1, posizionati su Width.
2. Ctrl+Maiusc+A: deve essere creato, mostrato e armato l'envelope Width. NVDA annuncia `Auto. Width...`. Tab deve includere Auto.
3. Ctrl+Maiusc+A di nuovo: annuncio `Auto off. Width...`; il contenuto dell'envelope non viene cancellato.
4. Riattiva con Ctrl+Maiusc+A: eventuali punti e automation item già presenti devono rimanere identici.
5. Salva, chiudi e riapri il progetto. Controlla che l'envelope Width esista, abbia gli stessi punti e venga riconosciuto da LReaParams.
6. Prova Width su una traccia folder e in un progetto con molti send, senza alterare routing, FX e selezioni.
7. Se REAPER rifiuta il chunk, l'annuncio deve essere `Width automation change not confirmed. No changes` e la traccia deve restare invariata.

## Verifiche effettuate

Verifiche **solo statiche** del sorgente e della struttura di creazione/revisione envelope. Non è stata eseguita compilazione C++, né REAPER. La compilazione MSVC e i test nativi sono riservati a GitHub Actions.
