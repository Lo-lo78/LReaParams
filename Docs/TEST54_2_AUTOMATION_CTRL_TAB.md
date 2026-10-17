# TEST54.2 — correzioni di Track Params

Sorgente basato su **0.0.54.1 (fix ProfileTests)**. Nessun codice di Parameter Library; nessuna build locale.

## Annunci Auto

Su Volume F1, Ctrl+Maiusc+A comunica `Auto. Volume, 0.0 dB` oppure `Auto off. Volume, 0.0 dB`, senza ripetere `Auto` in coda. Se il parametro possiede un CC, viene annunciato dopo il valore. NVDA+Su/Tab conservano gli annunci ordinari con `Auto` in coda.

## Envelope Send/Receive

Ctrl+Maiusc+A in F2/F3 lavora sugli envelope Volume, Pan e Mute effettivi. REAPER conserva il routing nella traccia **destinazione**, sotto `AUXRECV`; il codice trova l'istanza esatta anche in presenza di send duplicati. Per un envelope esistente usa `ACT`, `VIS` e (quando attivo) `ARM`, senza cancellare i punti o automation item. Le scritture vengono rifiutate su chunk mancanti o troppo grandi, e verificate prima dell'annuncio.

Quando l'envelope non esiste, si usa **SWS/BR** (`_BR_SHOW_SEND_ENV_*_SEL_TRACK`), come nel Lua. Queste azioni SWS possono creare envelope dello stesso tipo su **tutti i send della traccia sorgente**, non solamente quello corrente. La selezione delle tracce viene poi ripristinata. Se SWS non è installato, la DLL spiega che la creazione richiede SWS/BR anziché dichiarare falsamente l'automazione attiva.

## Ctrl+Tab

- In Track Params, Ctrl+Tab apre FX Params sulla traccia sotto il cursore (senza alterare la selezione fisica di REAPER).
- In FX Params, Ctrl+Tab apre Track Params usando il normale contesto di selezione di REAPER.
- I gesti non intervengono nei campi EDIT nativi o nel gestore FX Memories. Le posizioni persistenti vengono salvate dai normali metodi `end()`.

## Prove manuali obbligatorie

1. F1 Volume: Ctrl+Maiusc+A ON/OFF; non deve apparire due volte `Auto`; NVDA+Su legge comunque `Auto` quando attivo.
2. F2/F3 Volume/Pan/Mute senza envelope: con SWS presente, verifica che l'envelope REAPER venga creato, sia visibile e armato; senza SWS deve dichiarare la dipendenza, senza falso positivo.
3. Ripeti con due send dalla stessa sorgente alla stessa destinazione; verifica il secondo collegamento e Undo di REAPER.
4. Prova F2 e F3 sul medesimo collegamento, poi riapri REAPER e verifica che lo stato Auto sia salvato.
5. Ctrl+Tab in entrambe le direzioni, anche su una traccia diversa da quella selezionata in REAPER; verifica titolo, focus NVDA, posizione e memorie `.tp`.
6. Prova progetti grandi e routing complessi: chunk non leggibili devono produrre un messaggio di errore, mai una scrittura parziale.

I controlli statici **non** dimostrano la compilazione o il comportamento di REAPER in esecuzione.
