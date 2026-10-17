# LReaParams 0.0.54 — TEST54: MIDI CC, Ctrl+E, linking send/receive

Base: 0.0.53 TEST53.2 (inclusi tutti i fix TEST51-53). Solo sorgente, nessuna build locale.

## Funzioni aggiunte

- **Ctrl+Alt+C** F1/F2/F3 su Volume/Pan/Mute (anche Width/Solo/Phase invert in F1): apprende MIDI CC, memorizza `Channel,CC` nella sezione `[Track]`, `[Sends]` o `[Receives]` del file `Tracks/Track CC Map.tp`. Se il CC era assegnato a un'altra funzione viene spostato; il primo evento imparato non modifica il valore. Premere di nuovo la combinazione o Esc per annullare.
- **Maiusc+C** attiva/disattiva la mappa CC Fixed per la sessione. Deve esistere almeno una associazione salvata. Mappa inizialmente spenta. Non necessita di software esterno; REAPER deve ricevere il messaggio MIDI.
- **Ctrl+Maiusc+C** arma il CC Floating per la sessione, poi agisce sul parametro corrente e si aggancia al nuovo parametro tramite pickup senza salto.
- **Ctrl+Canc** in F2/F3 cancella solo l'associazione MIDI del parametro corrente, lasciando **Canc** per l'eliminazione del collegamento Send/Receive. In F1 Ctrl+Canc mantiene la deselezione delle tracce.
- **Ctrl+T** continua ad abilitare/disabilitare il parlato MIDI per singolo parametro; il cambiamento delle frecce usa **Ctrl+Maiusc+T**; **Tab** mostra le preferenze e anche la connessione CC salvata.
- **Pickup** sul valore corrente, con scarto temporaneo dei piccoli jitter, e annunci CC accorpati a ~180 ms; vengono ignorati i messaggi più vecchi dell'attivazione e gli editor text/numeric drenano i messaggi.
- **Ctrl+E** apre un vero campo di inserimento numerico in F1/F2/F3. Volume: dB [-150,+48], Pan/Width: percentuale [-100,+100], parametri binari: 0/1, routing e selettori MIDI: valori interi nei limiti della griglia. Invio applica; Esc annulla senza chiudere LReaParams. Non sovrascrive altre sezioni `.tp`.
- **Invio sull'intestazione Send/Receive** cerca la connessione corrispondente sulla traccia collegata, conservando l'ordinale delle connessioni duplicate; l'Invio su altri parametri rimane Value o interruttore. Se la cartella è chiusa o un filtro è attivo, avvisa senza cambiare un indice a caso.

## Manual test per REAPER / NVDA

1. F1 Volume: Ctrl+Alt+C, inviare MIDI CC 7 canale 1; verificare "CC learned" e `[Track] Volume=1,7` nel file `.tp` convertito (NON sovrascrivere manualmente il file nativo). Muovere ancora il controller: il valore non salta sino all'incrocio del pickup.
2. Maiusc+C off/on; Ctrl+T per attivare il parlato del Volume; muovere controller. Controllare che parlato delle frecce e del MIDI restino separati.
3. F1 Pan: Ctrl+Alt+C e apprendere lo stesso CC; verificare che la precedente associazione Volume venga svuotata e la nuova venga memorizzata. Riavviare REAPER e verificare connessioni; mappa off by default.
4. F2: associare un CC al Volume Send e un altro a F1 Volume; provare il CC cambiando parametro, colonna e traccia (pickup deve ripartire). F3 Receive analogamente.
5. F2/F3 con 3 collegamenti duplicati A->B: Home sulla riga dell'intestazione, Invio, verificare il Receive/Send corrispondente. Verificare anche chiusura folder e filtro attivo: non deve saltare su un'altra connessione.
6. Ctrl+E su Volume e digitare -6, Invio. Ctrl+E su Pan e digitare 30, Invio. Digitare un valore non valido e Esc: navigatore deve restare aperto; tab/arrow devono restare accessibili.
7. Prova di regressione: Shift+C non deve interferire con Ctrl+C/X/V delle tracce; frecce verticali Send/Receive devono dire solo parametro e valore; orizzontali nome peer solo al cambio traccia.

## Limiti e sicurezza

- Il MIDI Track opera mentre il **navigatore Track Params è attivo**. Il Ctrl+Q con MIDI in background, l'automazione avanzata Width/Send/Receive senza envelope, Ctrl+Maiusc+Alt+A, i range volume personalizzati Ctrl+Maiusc+I e le altre sezioni F4-F8 **non sono ancora migrati**.
- La prima TEST54 supporta il CC per i parametri del Lua in F1-F3 (Track Volume/Pan/Width/Mute/Solo/Phase e Send/Receive Volume/Pan/Mute). I parametri routing Audio/MIDI bus non hanno una mappa CC fissa; non viene inventato un target per essi.
- Il valore Volume da CC usa la curva -60..+12 dB; può differire dal mapping esatto del Lua, ancora da confrontare in test audio. NON dichiarare parità finale prima delle prove.
- Gli eventi MIDI vengono letti nel timer principale REAPER; nessun thread audio, hook globale o I/O per evento. Su edit profilo `.tp`, sono conservati header e sezioni storiche con backup e controllo hash. Le prove sul MIDI REALE e sulla compilazione MSVC sono ancora necessarie.
