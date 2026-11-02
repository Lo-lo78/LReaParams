# TEST62.7 — Ctrl+L esce dal gruppo e torna sempre a Custom Order

Partenza: **TEST62.6 completa**. Rimangono tutte le modifiche ai gruppi, alle memorie FX/Track, alla selezione multipla e agli Step.

## Comportamento di Ctrl+L (FX Params)

- **Da un gruppo, anche in F7:** Ctrl+L lascia il gruppo e apre **sempre Custom Order**, mai Plugin Order. L'eventuale editor F7 viene chiuso contestualmente, così il successivo Ctrl+L è subito utilizzabile.
- **Da Custom Order fuori F7:** Ctrl+L passa a Plugin Order, come già avveniva.
- **Da Plugin Order fuori F7:** Ctrl+L torna a Custom Order, come già avveniva.
- **Da Custom Order mentre F7 è aperto:** rimane la protezione esistente: «Exit F7 first». Il nuovo comportamento riguarda l'uscita da un gruppo.
- **Ctrl+F1–Ctrl+F12, ripremuto sul gruppo attivo:** mantiene il comportamento originale, tornando al contesto di provenienza (Plugin/Custom, stato F7, selezione e filtro); è distinto dal nuovo Ctrl+L.
- Sono conservate le griglie separate, i cursori e le impostazioni del gruppo; Ctrl+L non elimina né altera i suoi parametri. Se il gruppo viene ripristinato dal profilo dopo il riavvio, senza uno snapshot di provenienza, Ctrl+L funziona comunque.
- Ctrl+L da un gruppo fa creare una Custom Order integra **solo quando realmente assente**: la richiesta esplicita di tornare a Custom non deve fallire su un vecchio profilo che contenga gruppi ma non una Custom inizializzata.
- La pressione prolungata di Ctrl+L non deve alternare ripetutamente le viste.

## Prova REAPER + OSARA/NVDA

1. Scegli Alt+G, apri un plugin in **Plugin Order**, poi Ctrl+F2 per entrare in Group 2. Ctrl+L deve dire «Custom order» senza passare alla Plugin Order. Un secondo Ctrl+L deve dire «Plugin order».
2. Da Plugin Order, Ctrl+L torna a Custom Order. Da qui Ctrl+F5 entra in Group 5; Ctrl+L ritorna a Custom Order; un secondo Ctrl+L passa a Plugin Order.
3. Da Custom Order apri F7, poi entra in Group 2 con Ctrl+F2. Ctrl+L deve uscire sia dal gruppo sia da F7, e annunciare Custom Order. Un altro Ctrl+L passa a Plugin Order senza richiedere F7 o altri tasti.
4. Rientra in un gruppo e ripremi il suo **stesso Ctrl+Fn**: deve ancora tornare alla vista originaria (anche se era Plugin Order), senza cambiare la funzione preesistente.
5. Ripeti da gruppo vuoto salvato e da gruppo ripristinato dopo il riavvio. Controlla le griglie F1/F2 e l'ultimo parametro visitato in ogni vista.

Test automatico: `python Testing/test62_7_ctrl_l_group_exit_static.py` (solo controllo sorgente). La compilazione Windows e la verifica NVDA vanno eseguite tramite GitHub Actions e REAPER.
