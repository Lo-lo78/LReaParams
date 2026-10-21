# TEST61.16 — Memorie indipendenti per tutte le griglie FX

- **Plugin Order** e **Custom Order** hanno ciascuno la propria larghezza di griglia (F1/F2), il proprio parametro e la propria occorrenza selezionata.
- Ogni **Group 1–12** ricorda separatamente gli stessi dati, anche senza eseguire F7, modificare l’ordine o toccare i valori del plugin.
- Con **Ctrl+F1…Ctrl+F12** si entra nel gruppo e si ritrovano la griglia e il parametro lasciati. Premendo lo stesso Ctrl+Fn si recupera il contesto di provenienza. **Ctrl+L** alterna Custom/Plugin Order con griglie separate.
- I dati vengono conservati nell’array della singola istanza durante la sessione; su uscita/cambio di gruppo sono salvati anche nel `.fx` condiviso, con una voce opzionale `lrp_context_grids_v1` in `[Extra]`. L’ultima vista attiva continua a essere indicata da `lrp_last_navigation_v1` e `LastParam`.
- I vecchi valori Lua `grid_size_v1`, `custom_order_grid_size_v1`, `group_grid_size_v1::slot::N` e `group_last_position_v1::slot::N` rimangono leggibili. Non si modificano l’ordine dei parametri, i gruppi, i MIDI CC o i default per ricordare una griglia.
- F7 rimane un editor temporaneo, non una griglia distinta da ripristinare alla riapertura. I parametri duplicati conservano l’occorrenza esatta quando valida.
- TEST61.15: tornare online con Ctrl+Alt+B ripristina il contesto attivo, compresa la griglia indipendente.

## Test manuale consigliato

1. In Plugin Order imposta Grid 6 con F1/F2 e lascia il cursore a un parametro intermedio.
2. In Custom Order imposta Grid 3, spostandoti in un altro punto.
3. In Group 1 imposta Grid 5 e un parametro; nel Group 2 imposta Grid 2 e un altro parametro.
4. Passa fra viste e gruppi: ciascuno deve recuperare **la propria** larghezza e occorrenza, senza intervenire in F7.
5. Premi Esc, richiama FX Params e verifica i dati; chiudi/reapri REAPER e verifica la memoria persistente.
6. Inserisci due istanze identiche dello stesso FX, con posizioni diverse: le due posizioni restano indipendenti durante la sessione; il `.fx` dopo il riavvio resta il fallback comune.
7. Metti offline/online un VSTi con Ctrl+Alt+B e verifica il ritorno al gruppo e alla sua griglia.

**Validazione:** solo test statici. Non eseguire build locali; compilare esclusivamente con GitHub Actions, poi provare con REAPER + OSARA/NVDA.
