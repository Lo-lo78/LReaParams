# TEST75.3.10 — Ricerca Render senza forzature Alt+1/Alt+2

La TEST75.3.9 aveva introdotto due percorsi speciali per trovare Primary e Secondary con Alt+1/Alt+2 nella ricerca Ctrl+P. Dopo il collaudo sono stati ritirati: potevano selezionare la voce anche quando la scorciatoia non compariva nella mappa effettiva, generando annunci contraddittori.

- Primary e Secondary rimangono voci dell’elenco Render Shortcuts, personalizzabili normalmente.
- Nella ricerca non vengono più inventate associazioni Alt+1/Alt+2 per quelle voci. Si cerca in base alle associazioni personali o alle normali associazioni automatiche.
- Alt+1 e Alt+2 **restano funzionanti nella finestra Render** per mettere a fuoco Primary e Secondary. La modalità Shift+F1 continua a descrivere questi comandi reali.
- Se l’utente assegna F1 (o un’altra combinazione permessa) a Primary, cerca F1 e trova Primary. Analogo per Secondary.
- Senza un’associazione personale, cercare Alt+1 o Alt+2 in Ctrl+P può correttamente dire che non sono presenti nell’elenco cercabile e **non deve spostare la selezione**.
- Alt+S è il solo acceleratore per raggiungere la ricerca; OK/Annulla/Reset e lo storico ReaPack non sono modificati.

## Prova manuale

1. Aprire Render, poi Ctrl+P > Shortcuts > Render > Alt+S; scegliere una voce diversa da Primary/Secondary e cercare Alt+1, poi Alt+2. Senza personalizzazioni, non devono saltare alle schede.
2. Uscire dalla ricerca e assegnare una scorciatoia personale (per esempio F1) a Primary. Tornare alla ricerca e premere F1: deve selezionare Primary senza messaggio di errore.
3. Assegnare un altro tasto a Secondary, verificare allo stesso modo, poi cancellare le personalizzazioni e verificare il ritorno al default.
4. Uscire da Ctrl+P: in Render Alt+1/Alt+2 devono ancora spostare il focus alle due schede.
5. Verificare Alt+R, Ctrl+P, Shift+F1, lettere automatiche e Alt+S; nessun effetto collaterale nella ricerca.
6. Verificare che Esc da Preferences e poi da Render riporti correttamente il focus in REAPER.

Nota: comportamento REAPER/NVDA da verificare dopo compilazione Windows.
