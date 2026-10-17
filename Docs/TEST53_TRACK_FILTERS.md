# LReaParams 0.0.53 — TEST53: Ctrl+F Track Params F1/F2/F3

## Campo testo accessibile e scorciatoie

Ctrl+F, con filtro disattivato, apre un vero controllo Windows EDIT etichettato "Filter tracks", "Filter sends" o "Filter receives". Il testo, selezione, caret, Unicode e clipboard sono gestiti da Windows/NVDA, riutilizzando `TitleProxy` di FX Params. Invio applica, Esc o Ctrl+F durante l'editing annullano senza modificare il filtro. Se il filtro è già attivo, Ctrl+F lo cancella (come il Lua). Tab nella griglia comunica query e numero di risultati; il titolo della finestra indica il filtro attivo. Non è stata assegnata di nuovo Ctrl+R.

Per digitare occorre mantenere abilitata la finestra tastiera nativa LReaParams (impostazione predefinita); senza di essa Ctrl+F spiega come riattivarla invece di aprire un editor non accessibile. Il filtro è solo temporaneo nella sessione Track Params: non scrive nel `.tp` e non modifica le selezioni TCP.

## Ambiti

- F1: la ricerca usa il nome della traccia e lo stato di folder; confronta una sottostringa senza distinzione tra maiuscole/minuscole, dopo normalizzazione degli spazi. Quando il filtro trova una traccia dentro folder chiuse, apre le folder genitrici come il Lua. La lista logica viene ricalcolata senza cambiare i GUID reali.
- F2: il filtro lavora sulle colonne dei send della traccia corrente, cercando tipo, destinazione e campi routing; F3 analogamente per i receive. Gli indici *REAPER* originali rimangono associati a ciascuna colonna filtrata, anche per peer ripetuti. Le 14 righe verticali restano inalterate. Ctrl+Su/Giù salta alle tracce che contengono collegamenti corrispondenti al filtro, non soltanto collegamenti generici.
- Un filtro che non produce risultati non sostituisce il precedente e lascia aperto il campo EDIT con il testo, così è possibile correggerlo. Esc annulla.
- Nel profilo `.tp` la memoria della colonna invia l'**indice REAPER reale**, anziché l'indice della colonna filtrata. Un filtro non cambia il routing da solo.

## Restrizioni di sicurezza del test

- Con filtro F1 attivo, Ctrl+Invio (collapse folder) e Alt+Maiusc+Su/Giù (reorder fisico) chiedono di togliere prima il filtro. Si evita che un'operazione cancelli l'unica riga visibile o muova un blocco rispetto a un indice filtrato.
- Non sono state introdotte manipolazioni distruttive di chunk automazioni o dei send. Ctrl+Maiusc+A per envelope già esistenti resta quello della TEST52; il MIDI CC runtime di Track Params e la creazione envelope mancanti restano da migrare.
- Le etichette testuali di alcuni valori di routing non sono ancora un clone perfetto del filtro Lua: la ricerca copre nome, peer, campo e valore grezzo in forma numerica. Va verificato e completato il filtro dei valori formattati (es. nomi bus e modalità) insieme al resto della migrazione.

## Test manuali necessari in REAPER e NVDA

1. Aprire F1, Ctrl+F, digitare `bass`, Invio; verificare la ricerca tra tracce incluse quelle annidate, titolo e Tab; Ctrl+F cancella. Provare `bAsS`, stringa impossibile, Esc e clipboard nel campo EDIT.
2. F2: due send verso `Bass` e un altro verso `Drums`, filtrare `Bass`, cambiare volume/pan della **seconda colonna** e verificare che il collegamento reale n. 3 (non n. 2) sia modificato. Verificare Canc e Ctrl+Z su una copia del progetto.
3. Ripetere in F3 con più receive dallo stesso peer; Canc deve eliminare l'istanza reale selezionata, senza incidere sulle altre.
4. Controllare la memoria `.tp`: navigare filtri, togliere il filtro, chiudere/riaprire Track Params e assicurarsi che i MIDI CC e gli Step non siano stati alterati.
5. Controllare Tab, Invio/Value, Step Alt+Sinistra/Destra, Ctrl+Alt+Su/Giù folder e la migrazione TEST52 con filtro spento. Provare ad aprire una folder e spostare tracce *mentre il filtro è attivo*: l'operazione deve essere rifiutata e annunciata.
6. Provare la modalità senza finestra NVDA nativa: Ctrl+F deve annunciare che occorre abilitarla, senza chiudere o catturare scorrettamente i tasti.

**Verifica disponibile:** solo controlli statici Python, nessuna compilazione C++, MSVC, CMake, CTest, REAPER o NVDA. GitHub Actions e il collaudo dell'utente restano obbligatori.
