# LReaParams 0.0.55 — TEST55.13

Questa versione completa soltanto due rifiniture di Track Params F1/F2/F3. **Non introduce Step per singola traccia**: gli Step restano condivisi per tipo di parametro (`Track.Pan`, `Sends.Volume`, ecc.) come nella TEST55.12.

## Ricerca ciclica per iniziale

- In F1, un carattere alfanumerico non modificato cerca la **prossima traccia visibile** il cui nome inizia con tale carattere. Una successiva pressione cicla tra le corrispondenze, ripartendo dall'inizio. Rimane selezionato lo stesso parametro (es.: Pan).
- In F2/F3, la ricerca scorre esclusivamente i **14 parametri verticali della colonna corrente**. La colonna del send/receive non cambia.
- Vengono usati i caratteri forniti dal layout di tastiera di Windows, inclusi caratteri Unicode semplici. Nessuna corrispondenza, nessun movimento, nessun annuncio; bordi silenziosi.
- Ctrl+F e i normali campi di testo non sono modificati. In modalità Value la ricerca per carattere non interviene.

## CC Fixed e routing duplicati

REAPER non fornisce un identificatore GUID persistente per il singolo send. Finora un CC Fixed ricordava GUID sorgente e destinazione più il numero progressivo del send; dopo cancellazioni o inserimenti quel numero poteva puntare a un collegamento diverso.

- Quando apprendi un CC Fixed per un send/receive, viene salvata nel **medesimo `.tp` del progetto** una firma della topologia dei send in uscita dalla sorgente.
- Prima di applicare un CC viene confrontata la firma. Se la struttura è cambiata, **il CC non modifica alcun send** e nella categoria MIDI CC di Track Memories compare `routing changed, relearn CC`.
- Le operazioni interne di aggiunta ed eliminazione di send invalidano anche la firma precedente: un successivo send nello stesso posto non eredita automaticamente l'associazione.
- Gli eventuali CC dei send salvati da versioni precedenti, senza firma, rimangono nel `.tp` e nella lista delle memorie ma sono inattivi **fino a nuovo apprendimento**. Le associazioni Fixed CC delle tracce (F1) restano operative.
- Non vengono cancellate associazioni storiche, Step o dati MIDI delle altre categorie.

**Limite tecnico:** due send assolutamente identici possono essere indistinguibili dalle API REAPER se scambiati senza alcun cambiamento osservabile della topologia. Per sicurezza, riapprendere i CC ogni volta che si riordina o ricostruisce il routing. La modifica NON crea un falso GUID per i send.

## Collaudo richiesto in REAPER

1. In F1 posizionati su Pan di una traccia: premi una lettera iniziale ripetutamente, controllando che cambino le tracce ma non Pan.
2. In F2/F3 scegli una colonna con più parametri che condividono l'iniziale, e cicla: la colonna non deve cambiare.
3. Apprendi due CC diversi per due send verso la stessa traccia, riapri il progetto, verifica la persistenza.
4. Elimina un send: il suo vecchio controller non deve agire sul send rimasto. In Track Memories deve essere segnalato che occorre riapprenderlo.
5. Verifica che gli Step siano gli stessi su Pan di tracce diverse, senza nuove categorie `.tp`.

Compilazione solo con GitHub Actions. Non eseguire build locali.
