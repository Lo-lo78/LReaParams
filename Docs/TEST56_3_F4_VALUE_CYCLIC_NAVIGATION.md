# LReaParams 0.0.56 — TEST56.3 — F4 TCP, ricerca e Value

**Base unica:** TEST56.2. **Solo sorgente C++:** non sono state effettuate compilazioni locali, né CMake/MSBuild/CTest. Compilazione e collaudo nativi sono riservati a GitHub Actions e REAPER/NVDA.

## Navigazione e funzioni

- **F6 libero:** non apre più né cambia una lista di parametri e non modifica il TCP. Viene riservato a un ambiente futuro.
- **Alt+Invio in F4:** apre la griglia globale dei parametri TCP già visibili, con gli stessi comandi di aggiunta/rimozione della TEST56.2. Invio dall'intestazione FX apre ancora la griglia di tutti i suoi parametri.
- I tasti funzione cambiano solo ambiente nella **griglia principale F4**. L'eccezione F1/F2 nella **griglia di selezione dei nomi** resta intenzionale e già concordata: ne diminuisce/aumenta l'altezza da 1 a 200.
- **Ricerca ciclica alfanumerica:** su F4 cerca fra i nomi dei parametri TCP visibili nella colonna FX corrente; nella griglia di selezione cerca fra i nomi dei parametri mostrati. Una lettera/cifra cerca la corrispondenza successiva, **Maiusc+lettera/cifra** la precedente. Ricerca Unicode della prima lettera del nome del parametro; nessun annuncio se non esiste una corrispondenza, senza modificare valori. Quando la griglia globale include diversi FX, il nome dell'FX anteposto per contesto non altera la ricerca per iniziale.

## Prima fase di modifica dei valori F4

- **Invio su un parametro TCP esposto:** alterna fra Grid e **Value**; Invio su intestazione FX continua ad aprire la griglia nomi.
- **Value:** Su/Giù modifica il valore con i passi normalizzati del plugin, PagSu/PagGiù usa i passi maggiori. **Home** imposta il massimo e **End** il minimo. Esc ritorna alla griglia F4; un secondo Esc torna a F1.
- **Grid:** i normali tasti di navigazione non cambiano il suono; **Alt+Su/Giù** può variare intenzionalmente il valore senza entrare in Value; **Alt+PagSu/PagGiù** usa passi maggiori.
- **Alt+Sinistra/Destra:** Step da -10 a +10, ricordato nel medesimo `.tp` del progetto per GUID FX + indice parametro. Nessuna nuova cartella e nessuna memoria Step specifica per Volume/Pan di ogni traccia.
- **Tab** annuncia FX, parametro, valore e Step; le frecce e NVDA+Su forniscono l'informazione concisa. In Value la finestra espone un controllo slider nativo per NVDA.
- Scrittura tramite `TrackFX_SetParamNormalized` e `TrackFX_EndParamEdit`, con blocco Undo, conferma del GUID FX e verifica che il parametro resti esposto nel TCP. Gli Step nativi discreti vengono utilizzati se forniti dal plugin.

Questa fase **non implementa ancora** MIDI CC F4, automazioni F4, alias, ordinamento, spostamento fisico degli FX, Ctrl+E numerico F4 o funzioni F5/F6. Questi interventi saranno aggiunti gradualmente, senza anticiparli a rischio delle parti funzionanti.

## Prove da fare dopo GitHub Actions

1. In F4 premi F6: nessuna apertura o modifica della lista; prova Alt+Invio, verifica che si apra la griglia dei controlli TCP visibili.
2. Cerca con una lettera e poi Maiusc+lettera in F4, verificando che cerchi nei parametri della colonna corrente; ripeti nella griglia nomi, con FX diversi e nomi accentati.
3. Nella griglia dei parametri usa F1/F2, Tab, Ctrl+Invio e Invio; verifica che la visualizzazione TCP cambi soltanto sull'FX corretto.
4. In F4 seleziona un parametro TCP, premi Invio (Value), verifica frecce, PagSu/PagGiù, Home/End, Tab, NVDA+Su e il ritorno con Esc senza uscire dall'intero navigatore.
5. In Grid prova Alt+Su/Giù e Alt+Sinistra/Destra; esci e rientra: Step individuale deve restare nello stesso `.tp`.
6. Ripeti su parametri discreti, FX duplicati, FX rinominati e dopo modifiche alla catena; nessuna scrittura deve raggiungere un parametro diverso.
7. Controlla F1/F2/F3, FX Params, memorie Ctrl+Maiusc+M e compatibilità dei profili esistenti.

**Verifiche svolte:** `Testing/test56_1_static.py`, `test56_2_static.py`, `test56_3_static.py`, test mirati TEST55.10/12/13, `Tools/audit.py`. Il test nativo C++, la compilazione MSVC e il collaudo REAPER/NVDA non sono stati eseguiti.
