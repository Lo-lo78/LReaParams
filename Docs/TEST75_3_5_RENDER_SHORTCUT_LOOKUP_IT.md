# LReaParams TEST75.3.5 – Ricerca completa scorciatoie

Questa modifica nasce dal mancato riconoscimento di Alt+1 e Alt+2 nella ricerca delle Preferenze Render. Non altera l'esecuzione dei tasti in Render.

## Correzione

- Primary e Secondary sono due voci reali rilevate nel controllo delle schede. A esse vengono associate, per la sola ricerca, Alt+1 e Alt+2, che Render già gestisce direttamente.
- La ricerca include ora anche i comandi di LReaParams Render che non corrispondono a un singolo controllo: Ctrl+P, Ctrl+F, F3, Shift+F3 e Shift+F1. Queste voci sono indicate come comandi interni, consultabili ma non personalizzabili direttamente dall'elenco dei controlli.
- Alt+R e tutte le altre lettere automatiche continuano a essere lette dalla mappa effettiva, non da un elenco predefinito.
- Se l'utente occupa Alt+M, la ricerca non propone più la vecchia Alt+Shift+M automatica: anche quel ciclo è disattivato nel navigatore.
- Alt+S è l’unico acceleratore per entrare nel campo di ricerca. Dentro il campo qualsiasi combinazione, inclusi Alt+S e Alt+D, è soltanto un dato da interrogare e non un acceleratore della finestra.
- Anche in FX Params e Track Params Ctrl+P e Shift+F1 sono ora consultabili come comandi interni non modificabili. Nessun indice delle scorciatoie salvate viene spostato.

## Prova manuale su Windows, REAPER, NVDA/OSARA

1. Apri Render con le schede Primary e Secondary rilevabili. Apri Ctrl+P > Shortcuts > Render e raggiungi Cerca scorciatoia (Alt+S).
2. Cerca Alt+1: deve selezionare Primary output format, senza attivarla. Cerca Alt+2: deve selezionare Secondary output format, senza attivarla.
3. Cerca Alt+R: deve selezionare il controllo che Render raggiunge attualmente con Alt+R, senza avviare un rendering.
4. Cerca Ctrl+P, Ctrl+F, F3, Shift+F3 e Shift+F1: devono essere individuate le voci interne. Invio su una voce interna deve annunciare che non è personalizzabile; non deve aprire la cattura.
5. Cerca una combinazione assente: la selezione dell'elenco deve restare invariata e il focus deve restare nel campo di ricerca.
6. Assegna Alt+M a un controllo. Con la stessa sessione delle Preferenze, cerca Alt+M e poi Alt+Shift+M: Alt+M deve trovare il controllo personalizzato e Alt+Shift+M non deve più offrire il vecchio gruppo automatico.
7. Ripeti la ricerca in FX Params e Track Params, incluse combinazioni con F1–F12, e verifica che nessun comando venga eseguito.
8. Prova Alt+R, Alt+O, Alt+C e Alt+S **dentro** Cerca scorciatoia: non devono essere attivati Reset, OK, Annulla o il cambio di focus.
9. Esci dal campo e verifica che Reset, OK e Annulla funzionino ancora normalmente.

Nota: l'elenco Render descrive la configurazione effettivamente rilevata all'apertura di Ctrl+P. I comandi che REAPER non espone nella configurazione corrente non vengono inventati. Non è stata eseguita una compilazione MSVC in questo ambiente.
