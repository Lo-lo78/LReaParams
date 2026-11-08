# LReaParams TEST67.1 — vista virtuale Usati / Used

**Documento storico della TEST67.1**, successivamente integrata nella release stabile **0.0.67**. La descrizione originale dei test è conservata per permettere regressioni e verifiche; per pubblicare usa `Docs/REAPACK_SETUP_IT.md`.

## Comandi

- **Ctrl+Shift+L**: passa dal contesto attuale (Plugin Order, Custom Order oppure uno dei 12 gruppi) alla vista **Usati / Used**. Premendolo nuovamente ripristina esattamente il contesto precedente, con il suo cursore, la griglia e il tema.
- **Ctrl+Delete** soltanto in Usati: rimuove il parametro selezionato dalla raccolta. **Non** ripristina né cancella il valore reale del plugin, le automazioni o i gruppi.
- **F4** in Usati: alterna Standard/Keyboard per la sola vista Usati. Gli altri 14 temi restano indipendenti.
- **F1/F2** e **Shift+Backspace**: regolano/ripristinano la griglia autonoma di Usati, senza alterare le altre 14.
- **F3**: continua ad annunciare Grid, Step e Group slots / Memory slots; quando sei in Usati aggiunge il nome della vista.
- La vista e i messaggi NVDA sono denominati **Used** nell'attuale motore inglese dell'interfaccia; il nome funzionale italiano è **Usati**.

## Cosa entra in Usati

Un parametro entra **una sola volta**, nella posizione del primo intervento, dopo una **modifica effettiva e riuscita del valore tramite LReaParams**. Se lo regoli nuovamente, non cambia posizione. Se lo rimuovi con Ctrl+Delete e in seguito lo cambi ancora, torna in fondo all'elenco. Il reset del singolo parametro, se ne cambia effettivamente il valore, è considerato un intervento e lo aggiunge.

**Non** vengono aggiunti parametri solo perché un preset ha valori diversi dal default, per l'automazione durante Play o per cambiamenti compiuti fuori dai comandi dell'interfaccia LReaParams. Alcuni controlli virtuali sintetici di ReaEQ sono esclusi dalla raccolta; la raccolta riguarda i parametri fisici del plugin.

La raccolta appartiene al GUID dell'istanza FX ed è salvata nei dati del **progetto REAPER**, non nel profilo globale `.fx`. Salva il progetto per rendere persistenti i cambiamenti. Due istanze dello stesso VST possono avere liste diverse. Se la struttura/quantità dei parametri cambia, un elenco incompatibile viene ignorato per prudenza.

## Prova consigliata

1. Apri FX Params nel Gruppo 3 e scegli un parametro riconoscibile, annotando griglia e tema.
2. Modifica due parametri reali tramite LReaParams; ripeti una modifica sul primo.
3. Premi Ctrl+Shift+L: la vista Used deve avere soltanto due parametri nell'ordine di primo uso.
4. Premi F4 e cambia la griglia; torna al Gruppo 3 con Ctrl+Shift+L: tema e griglia del Gruppo 3 non devono cambiare.
5. Torna in Used, premi Ctrl+Delete su un parametro: sparisce soltanto dall'elenco, mentre il suo valore reale rimane.
6. Torna al gruppo e modifica ancora quel parametro: ora viene aggiunto in fondo a Used.
7. Salva progetto, chiudi e riapri REAPER; verifica la lista dell'istanza FX e che un'altra istanza identica non condivida la lista.
8. Prova l'elenco vuoto, il cambio FX e la navigazione standard. Con Ctrl+Shift+M si deve uscire dalla vista Usati per aprire FX Memories.

**Stato verifiche:** test C++ portabili e test statici del codice; compilazione native MSVC e prova NVDA/OSARA reali affidate a GitHub Actions e al test manuale in REAPER. Il formato storico `.fx` e la configurazione di pubblicazione ReaPack non sono modificati.
