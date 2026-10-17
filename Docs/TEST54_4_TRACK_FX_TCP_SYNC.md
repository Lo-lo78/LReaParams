# TEST54.4 — Sincronizzazione reale fra Track, FX e TCP

## Problema riprodotto

Entrando in Track Params dalla traccia 2, usando Ctrl+Tab verso FX Params e navigando fino a un FX della traccia 1, il successivo Ctrl+Tab riapriva Track Params sulla traccia 2. Esc riportava inoltre il TCP alla selezione vecchia perché la navigazione F1 era soltanto logica.

## Correzioni

- FX Params espone la traccia proprietaria dell'FX/take corrente; Track Params accetta una destinazione esplicita consumata una sola volta nel successivo begin(). La selezione del TCP non prevale sull'FX corrente.
- Le frecce normali in F1, Ctrl+Alt+Su/Giù fra folder, Ctrl+Su/Giù in F2/F3, Enter dall'intestazione verso il routing collegato, filtri che riposizionano il cursore e la chiusura di folder aggiornano la vera selezione REAPER.
- La selezione multipla con Maiusc, Ctrl+A e i comandi dedicati resta multi-selezione: non viene cancellata dai gesti di selezione.
- Eccezione necessaria: durante la seconda fase di Ctrl+Maiusc+S/R, la navigazione non preseleziona automaticamente le tracce, perché il Lua le lascia libere per la scelta esplicita dei destinatari/sorgenti.
- Su apertura riuscita di FX Params da TCP o da una catena FX nativa, il TCP seleziona la traccia proprietaria dell'FX, inclusi i Take FX.
- Ctrl+Tab che non riesce torna al navigatore precedente sulla stessa traccia, quando ripristinabile. Il comando non entra in FX Params quando la traccia corrente è senza FX.
- Nessuna modifica alla memoria persistente `.tp`, ai CC o alle scorciatoie di trasporto.

## Casi da testare su GitHub Actions e REAPER/NVDA

1. TCP traccia 2 -> Track Params -> Su fino a traccia 1. Verificare che anche TCP selezioni traccia 1. Esc: TCP ancora su traccia 1.
2. Track Params su traccia 1 con FX -> Ctrl+Tab -> FX Params traccia 1 -> Ctrl+Giù fino a FX della traccia 3 -> Ctrl+Tab: Track Params traccia 3; Esc: TCP traccia 3.
3. Aprire FX Params direttamente dalla FX Chain della traccia 4 mentre era selezionata traccia 2: Esc deve conservare selezionata la traccia 4.
4. Take FX su item della traccia 5: la selezione TCP deve seguire il proprietario del take. Ctrl+Tab deve tornare alla traccia 5.
5. In F1 con Maiusc+Su/Giù selezionare 3 tracce: devono rimanere selezionate tutte. Un successivo Su/Giù **senza** Maiusc deve selezionare solo la nuova traccia, come normale navigazione.
6. In F2/F3 spostarsi con Ctrl+Su/Giù tra proprietari di routing, e con Enter sull'intestazione verso il collegamento opposto: il TCP segue il proprietario attuale.
7. Ctrl+Tab verso una traccia senza FX: annuncia No track FX e resta in Track Params senza cambiare selezione né focus.
8. Controllare Master/Monitor FX, folder chiuse, memoria `.tp`, filtro Ctrl+F e ritorno da Value.

**Stato:** solo sorgente; non compilato localmente. Build MSVC esclusivamente tramite GitHub Actions e prove manuali in REAPER/NVDA.
