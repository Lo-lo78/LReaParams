# LReaParams 0.0.53 — TEST53.1: correzioni incolla, annunci routing, ricerca

Questa è una correzione della TEST53: nessun cambio del formato `.tp`, delle azioni SWS/S&M, della griglia verticale e nessun ritorno di Parameter Library.

## F1 — Ctrl+V dopo il cursore corrente

- Ctrl+C e Ctrl+X restano su SWS/S&M con routing.
- Ctrl+V invoca la medesima azione SWS. Prima acquisisce i GUID delle tracce esistenti, quindi individua le tracce **nuove** aggiunte da SWS, senza dipendere dalla selezione che SWS lascia nel TCP.
- Verifica la loro posizione rispetto alla traccia corrente F1 e, se non è subito successiva, usa `ReorderSelectedTracks` per collocare il gruppo completo **subito dopo** il cursore corrente, mantenendo l'ordine delle tracce incollate. Segue il primo nuovo GUID con il cursore.
- Se SWS non crea nuove tracce, non annuncia falsamente un incolla riuscito. Se non riesce a identificare/spostare il gruppo, avvisa. Il riposizionamento, quando necessario, può aggiungere un passaggio Undo distinto dall'azione SWS.
- Con filtro F1 attivo, incollare è temporaneamente disabilitato per evitare di alterare la posizione relativa di tracce non visibili.
- **Verifica REAPER obbligatoria**, specialmente con folder annidate: le API SWS e ReorderSelectedTracks vengono provate realmente solo dal collaudo dell'utente.

## F2/F3 — annunci dei send e receive

Ogni freccia, sia per cambiare campo verticale che per passare a un'altra colonna, annuncia *traccia collegata, parametro, valore* (ed eventuale `Auto`). La prima connessione alla traccia Bass: `Bass, Volume, -6 dB`; la seconda verso la stessa Bass: `Bass, Send 2, Volume, -6 dB`. Con F3 è `Receive 2`, `Receive 3` e così via. Il numero è calcolato **fra i collegamenti alla stessa traccia** e usando gli indici REAPER reali; il filtro non lo modifica. La prima istanza non ha mai il suffisso `Send 1` / `Receive 1`.

## Ctrl+F — ritorno alla griglia

- Ctrl+F su un filtro già applicato lo azzera e dice `Search cleared. <parametro>, <valore>` (su F2/F3 include il nome del peer).
- Ctrl+F seguito da Esc, nel campo di ricerca, annulla il campo e pronuncia esattamente la stessa forma `Search cleared. ...`.
- La finestra LReaParams **rimane attiva** e il controllo Win32 torna dal campo EDIT alla griglia; la logica del focus esistente è preservata.

## Controlli e prove manuali

Eseguiti esclusivamente test Python statici del sorgente e scenari sintetici; **nessuna compilazione C++, CMake, Visual Studio, MSBuild, CTest, REAPER o NVDA** in locale.

1. Copia due tracce collegate fra loro, vai su una traccia centrale, premi Ctrl+V: devono comparire immediatamente dopo di essa e avere i send intatti. Ripeti sulla traccia finale e in un progetto con folder.
2. Verifica che con un filtro F1 attivo Ctrl+V dia un avviso anziché spostare tracce fuori contesto.
3. Crea Bass send, Drums send, Bass send. In F2 scorri verso destra e verticalmente: Bass senza numero alla prima istanza, `Send 2` alla seconda; ripeti con F3 per i receive.
4. F1, F2 e F3: Ctrl+F, ricerca, Invio, poi Ctrl+F. Verifica `Search cleared` e che le frecce funzionino. Ripeti Ctrl+F ed Esc senza immettere testo, poi con una ricerca senza risultati.
5. Conferma con NVDA che il focus non esce da LReaParams al ritorno dal campo di testo. Verifica Undo e folder in un progetto di prova.
