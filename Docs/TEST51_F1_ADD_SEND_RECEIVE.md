# TEST51 aggiornata — Creazione di send e receive da F1

## Logica del Lua mantenuta

Le operazioni avvengono in due passaggi e usano la **selezione REAPER reale**, non il cursore logico F1.

- **Add send, Ctrl+Maiusc+S:** seleziona una o più tracce sorgenti in F1; premi il comando: la selezione viene memorizzata e cancellata. Seleziona una o più tracce destinatarie; ripremi Ctrl+Maiusc+S. Ogni sorgente viene collegata a ogni destinazione.
- **Add receive, Ctrl+Maiusc+R:** seleziona una o più destinazioni; premi il comando. Seleziona una o più sorgenti; ripremi Ctrl+Maiusc+R. Il C++ chiama `CreateTrackSend(sorgente, destinatario)` per ogni coppia.
- **Esc durante il primo/secondo passaggio:** annulla il collegamento in sospeso senza uscire dal navigatore. **Tab:** annuncia cosa è stato memorizzato e cosa selezionare.
- Se il primo gruppo è vuoto, non inizia l'operazione. Se il secondo gruppo è vuoto, la prima selezione resta memorizzata.
- Un comando di tipo diverso durante l'operazione in sospeso viene rifiutato con un messaggio; il collegamento non viene eseguito accidentalmente.
- Nessuna autoconnessione: una coppia sorgente=destinazione è contata come **skipped**. Una coppia con traccia non più esistente è contata come **failed**. Al termine si annunciano **added / skipped / failed**.
- La nuova creazione dei send è un'azione con Undo (non viene salvata nei `.tp`, è modificata direttamente nel progetto REAPER). Nessun cambio delle scorciatoie degli step, parlato o memoria.

## Come provarla dopo la compilazione GitHub Actions

1. In un progetto nuovo crea quattro tracce A, B, C e D. Apri Track Params in F1.
2. Seleziona A e B con Maiusc+Spazio (o selezione multipla F1); premi Ctrl+Maiusc+S. Devi sentire che sono memorizzate **due sorgenti**, poi la selezione REAPER deve azzerarsi.
3. Premi Tab: deve dire che Add send è in sospeso. Seleziona C e D. Premi Ctrl+Maiusc+S: devono risultare **quattro send**: A→C, A→D, B→C, B→D. Controlla nella matrice di routing REAPER.
4. Elimina quelle connessioni nella DAW. Seleziona C e D, premi Ctrl+Maiusc+R. Seleziona A e B, premi di nuovo Ctrl+Maiusc+R: anche qui devono crearsi le stesse quattro connessioni e devono apparire come receive sulle destinazioni.
5. Ripeti con la stessa traccia nei due insiemi: l'autoconnessione deve essere saltata. Scegli un solo gruppo, premi Esc: deve dire **Add send cancelled** / **Add receive cancelled**, senza creare nulla e senza chiudere Track Params.
6. Dopo aver memorizzato il primo gruppo, premi il comando opposto: deve chiedere di completare o annullare l'operazione originaria. Premi il gesto originario con il secondo gruppo vuoto: deve annunciare la mancanza di selezione senza perdere l'operazione in corso.
7. Verifica Ctrl+Maiusc+S/R in F2/F3: deve comunicare **Only in Tracks**; nessuna nuova connessione. Con Ctrl+Z di REAPER dopo aver lasciato il navigatore, verifica l'annullamento delle connessioni create in blocco.
8. Verifica che F1, F2, F3, Tab, Invio/Value, Ctrl+Alt+Su/Giù, Step e la memoria `.tp` restino invariati.

**Limiti noti:** la cancellazione dei singoli send/receive e altre funzioni F2/F3 avanzate del Lua non fanno ancora parte di questa TEST. Nessuna compilazione locale e nessun collaudo REAPER/NVDA sono stati eseguiti per la consegna.
