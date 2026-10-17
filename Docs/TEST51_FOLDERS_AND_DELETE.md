# TEST51 estesa — folder annidate, toggle e cancellazione F2/F3

**Base:** 0.0.51 TEST51 F1 Add Send/Receive, senza cambiare versione del progetto.
**Compilazione:** soltanto GitHub Actions; nessuna build locale eseguita.

## F1: annuncio delle folder

- La traccia che apre una folder annuncia `open folder Bass` oppure `closed folder Bass`.
- La traccia che chiude una folder annuncia anche il nome della folder stessa: `Sub Bass, end folder Bass`.
- Per folder annidate, un `I_FOLDERDEPTH` negativo può chiuderne più di una nello stesso punto: `Sub Bass, end folder Bass, end folder Instruments`, dalla più interna alla più esterna.
- I nomi si ricostruiscono dal vero stack del progetto REAPER, non da un semplice conteggio di profondità. Funziona anche se ci sono altre folder intermedie e nomi uguali.
- L'annuncio completo si sente cambiando traccia con le frecce in F1 e con Tab. La lettura breve NVDA+Su dei parametri resta invariata.

## Aprire/chiudere folder

- **Ctrl+Invio in F1** apre/chiude la folder corrente. Quando la riga corrente è un'end-folder, seleziona la folder interna che finisce lì; le successive invocazioni da quella riga possono ciclare tra le folder annidate.
- Dopo il toggle il cursore passa sempre sulla folder che è stata modificata, mantenendo la colonna F1. Le righe visibili vengono ricostruite prima del nuovo annuncio per evitare riferimenti a tracce nascoste.
- **Invio semplice** continua a essere Value su Volume/Pan/Width e pulsante su Mute/Solo/Phase: comportamento chiesto dall'utente, non sostituito dall'azione folder.
- **Ctrl+Alt+Freccia Su/Giù** continua a saltare tra folder visibili, senza variare la selezione reale.
- Un'operazione di folder è registrata nell'Undo del progetto; nessun dato viene aggiunto ai `.tp`.

## F2/F3: Delete reale del singolo collegamento

- **Canc** su un qualunque campo del send in F2 rimuove il send corrente con `RemoveTrackSend(source, 0, realIndex)`.
- **Canc** su un receive in F3 risolve la traccia sorgente e l'**istanza esatta** del send corrispondente, anche quando tra le stesse tracce esistono due o più collegamenti; non elimina i receive collegati ad altre tracce.
- Comando Undo singolo, aggiornamento numero di colonne e ricollocazione nella colonna più vicina. Se non rimangono elementi, torna a F1 e annuncia `No sends` / `No receives`.
- La creazione a due passaggi Ctrl+Maiusc+S/R della TEST51 precedente rimane invariata.

## MIDI Merge: semantica corretta del Lua

- La 14ª voce `MIDI merge` è uno **stato derivato dal routing**: `Off` quando MIDI source è `None` (31); `On` se MIDI source è `All` o un canale.
- **Non è un interruttore indipendente** nell'API; il Lua originale ne fornisce soltanto lettura. In TEST51 rimane read-only, ma **Invio** spiega come cambiare lo stato attraverso il campo `MIDI source`. Evitiamo così di sovrascrivere un routing MIDI specifico creando un finto flag `merge`.

## Prova manuale su REAPER / NVDA

1. Crea la traccia `Bass` folder seguita dall'ultima traccia `Sub Bass` (I_FOLDERDEPTH=-1). Vai su `Sub Bass` in F1: deve annunciare `Sub Bass, end folder Bass`.
2. Annida dentro `Instruments` una folder `Bass`; sull'ultima traccia che chiude entrambe verifica l'ordine `end folder Bass, end folder Instruments`.
3. Con il cursore su `Bass`, premi Ctrl+Invio per chiudere e riaprire: i figli spariscono e riappaiono dalla navigazione F1. Invio semplice su Volume deve entrare in Value.
4. Dall'ultima traccia usa Ctrl+Invio: deve intervenire sulla folder che finisce lì, e la nuova posizione deve essere la folder, senza uscire da Track Params.
5. Crea due send paralleli dalla stessa sorgente alla stessa destinazione e un terzo verso un'altra traccia. Canc su F3 del secondo receive deve rimuovere soltanto l'istanza scelta. Verifica con la matrice di routing e con Ctrl+Z di REAPER dopo l'uscita dal navigatore.
6. F2: su Audio/MIDI source cambiare canale. Quando MIDI source=None, MIDI merge dice Off; quando MIDI source=All/Channel, dice On. Invio su MIDI Merge spiega la relazione, senza cambiare il routing.
7. Ripeti la navigazione F1/F2/F3, Tab, Ctrl+Alt+Su/Giù e il salvataggio `.tp` per verificare le regressioni.

## Ancora da migrare prima di F4

Rimangono fra le funzioni più grandi del Lua: clipboard tracce con routing e spostamento fisico, filtri/ricerca dei send e receive, automazioni/envelope di track e send, MIDI CC runtime con learn/pickup e controllo di più tracce. Non dichiarare equivalenza completa del Lua.
