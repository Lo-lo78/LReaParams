# TEST75.2 – Shift+F1: help delle scorciatoie interne (prototipo)

Build basata su LReaParams 0.0.75 Build Fix 75.1. Non è una nuova release.
Nessuna modifica a `index.xml`, al publisher ReaPack, alle azioni REAPER o ai file di preferenze persistenti. Le vecchie associazioni Shift+F1 eventualmente salvate vengono ignorate; la combinazione è riservata all'help nei contesti gestiti.

## Test manuali necessari (Windows 11, REAPER, OSARA/NVDA)

1. Nel TCP/Arrange, premere Shift+F1. Deve eseguire la **propria** azione REAPER (es. aggiornamenti OSARA). LReaParams non deve intervenire.
2. Entrare in FX Params. Memorizzare la posizione del parametro e il valore. Shift+F1 deve annunciare l'help acceso senza muovere il focus. Ctrl+B, Ctrl+F, F1, frecce, Backspace, Ctrl+P, Esc, lettere nella griglia devono essere descritti, senza cambiare bypass, valori, griglia, selezione, ricerca, progetto o modalità.
3. Premere nuovamente Shift+F1. Verificare che focus, posizione e valore siano **identici** e che i tasti tornino a funzionare normalmente.
4. Ripetere in Track Params F1–F7, Memories, FX Browser, F7 Edit, Keyboard e Pin Connector, dove disponibili. I tasti che non hanno ancora una descrizione specifica devono essere segnalati, mai eseguiti o inventati.
5. Nelle Preferenze Ctrl+P, riassegnare una scorciatoia, salvare e tornare allo stesso punto. Shift+F1 deve descrivere la nuova combinazione; la precedente non deve restare collegata al vecchio comando. Shift+F1 è riservato e non assegnabile.
6. Aprire Render con l'azione REAPER 40015, usando il proprio Ctrl+Alt+R. Su un controllo nativo premere Shift+F1, poi Alt+R, Alt+Z, Alt+S, Alt+1, Alt+2, Ctrl+F, F3 e Shift+F3. Nessun comando deve attivare un controllo o spostare il focus. Alt+lettera deve leggere i nomi attuali dalla mappa dei controlli visibili e abilitati.
7. Durante l'help in Render, variare **solo dopo esserne usciti** le opzioni che fanno apparire/scomparire controlli, poi riattivarlo. L'associazione Alt+lettera deve riflettere la situazione aggiornata.
8. Chiudere Render, tornare al TCP. Shift+F1 deve tornare alla sua azione REAPER; nessun help LReaParams deve restare attivo.
9. Verificare che NVDA+combinazione non sia intercettata indebitamente (la politica preesistente del router lascia passare il modificatore Insert/Numpad Insert).

## Architettura e limiti

- InputRouter intercetta Shift+F1 sul thread UI soltanto mentre è attivo il navigatore FX/Track. Durante l'ispezione tutti i tasti non-NVDA sono consumati prima della coda `handle()`; nessun valore/focus viene modificato e il timer di navigazione rimane sospeso. La modalità è cancellata automaticamente a `stop()` o alla perdita del contesto.
- Le associazioni personalizzate si leggono *al momento della pressione* da `Preferences::shortcuts`, usando `mapPreferredShortcut`, e si confrontano con `Navigator::accepts`. La risoluzione di pagina può correggere la descrizione tramite `shortcutDescription()`, senza eseguire la funzione.
- Render usa il proprio `WH_GETMESSAGE` contestuale e `refreshControls()/accelerators_`, non le Preferences e non REAPER Action List. Le associazioni cambiano con i controlli effettivamente disponibili.
- L'help è **di sola interrogazione per i tre grandi navigatori** (FX, Track, Render) e relative pagine. Le finestre native modali separate (Preferenze, editor range, file picker, Metadata e dialogo cerca Render) non sono ancora integrate con un loro help Shift+F1; non forzarne l'intercettazione dalla finestra madre. In alcuni sottocontesti speciali le descrizioni vanno ancora completate: una funzione sconosciuta viene segnalata e non inventata.
- Non è stata effettuata la compilazione MSVC né un collaudo reale con OSARA/NVDA in questa sessione. Il sorgente contiene test statici, non una DLL già compilata.
