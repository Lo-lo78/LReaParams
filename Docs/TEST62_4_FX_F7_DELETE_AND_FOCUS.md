# LReaParams 0.0.62 — TEST62.4: tasti distinti e cursore stabile in F7

Base completa **TEST62.3**. Test sorgente per GitHub Actions: non è una DLL Windows già compilata. La versione pubblica rimane 0.0.62.

## Scorciatoie F7 (solo FX Params)

- **Ctrl+Canc nel gruppo**: rimuove dal gruppo soltanto le occorrenze selezionate. Senza selezione rimuove quella corrente. Non aggiunge ID agli invisibili e non modifica Custom Order o gli altri gruppi.
- **Ctrl+Canc nella Custom Order**: non modifica nulla; NVDA spiega che la rimozione è riservata ai gruppi e che per nascondere bisogna usare Ctrl+Maiusc+Canc.
- **Ctrl+Maiusc+Canc nella Custom Order oppure nel gruppo**: rende globalmente invisibile l'ID del parametro selezionato, comprese le sue copie. Sparisce da Custom Order e da tutti i gruppi ma **rimane in Plugin Order**. Le appartenenze e gli ordinamenti vengono conservati.
- **Per ripristinare un invisibile**: aprire **Ctrl+Maiusc+M** (FX Memories), raggiungere **Hidden Parameters**, scegliere il parametro e premere **Canc**. Non esiste più una scorciatoia che ripristina tutti gli invisibili in blocco.
- **Canc semplice in F7** continua a deselezionare tutto. Ctrl+Z/Ctrl+Y rimangono Undo/Redo dell'editor. Le scorciatoie di Track Params non cambiano.
- Le pressioni ripetute automaticamente del tasto (key repeat) sono ignorate per entrambe le operazioni distruttive.

## Cursore dopo Ctrl+Canc nel gruppo

- Se il parametro corrente viene eliminato, il cursore passa al **primo parametro rimasto successivo** secondo l'ordine del gruppo; se non ce n'è, passa al precedente.
- Se elimini altri parametri selezionati e quello sotto il cursore resta, mantiene **la stessa occorrenza** anche se la posizione numerica cambia.
- Le posizioni vengono calcolate sulla **lista visibile**, poi convertite nella lista reale: i parametri globalmente invisibili intercalati e le copie con identico ID non devono mandare al primo parametro o eliminare una copia errata.
- Dopo una ricerca filtrata, l'eventuale filtro viene chiuso (come prima); il punto di arrivo è calcolato nell'ordine completo del gruppo.
- Se rimuovi l'ultimo parametro, il gruppo rimane salvato e richiamabile anche vuoto. Il ripristino dell'ultima vista dopo il riavvio conserva anche i gruppi vuoti, già previsti dalla TEST62.2.

## Prove consigliate in REAPER + NVDA / OSARA

1. In Custom Order F7, posizionati su un parametro: **Ctrl+Canc non deve nasconderlo**; Ctrl+Maiusc+Canc sì. Da Plugin Order lo stesso parametro deve essere ancora presente.
2. Dal gruppo, posizionati sul parametro 5 di 10: Ctrl+Canc deve leggere il **successivo**, nella stessa posizione del gruppo; non tornare al primo.
3. Rimuovi l'ultimo parametro: il cursore passa al precedente. Rimuovi l'unico parametro: il gruppo rimane vuoto e utilizzabile.
4. Seleziona parametri sparsi con Maiusc+Spazio e cancella: il cursore deve rimanere sulla stessa occorrenza se non è stata selezionata; altrimenti su quella successiva sopravvissuta.
5. Ripeti con copie dello stesso parametro e alcuni parametri globalmente invisibili nel mezzo: Ctrl+Canc deve togliere soltanto le occorrenze selezionate.
6. In un gruppo usa Ctrl+Maiusc+Canc: deve sparire da tutti i gruppi e dalla Custom Order. In Ctrl+Maiusc+M / Hidden Parameters, premi Canc: deve riapparire negli ambienti che lo contenevano.
7. Verifica Undo e Redo, salvataggio `.fx`, cambio gruppo e riapertura di REAPER. Ripeti con le modifiche multiple agli Step della TEST62.3, senza regressioni.

Controllo statico: `python Testing/test62_4_fx_f7_delete_static.py`. La compilazione della DLL è affidata al workflow Windows GitHub Actions, non verificata localmente.
