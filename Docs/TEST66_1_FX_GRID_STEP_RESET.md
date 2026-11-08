# TEST66.1 — FX Params: reset di Step e griglia separati (0.0.66 TEST)

Questa TEST non modifica numero di versione, About, installer né release pubblica.

## Nuove scorciatoie, solo FX Params

- Backspace: reset del parametro corrente come nella 0.0.66.
- Ctrl+Backspace: Step 0 del parametro corrente, senza cambiare la Grid o gli altri Step.
- Ctrl+Shift+Backspace una sola pressione: Grid 10 del contesto corrente, senza cambiare gli Step. Il reset si applica alla scadenza dell'intervallo di doppio clic configurato in Windows, per distinguere l'editazione.
- Ctrl+Shift+Backspace due pressioni rapide: apre il controllo EDIT nativo etichettato «Grid size, 1 to 400»; nessun reset si applica prima. Il valore è preselezionato; Invio accetta 1–400, Escape annulla; valore fuori intervallo lascia aperto il campo.
- Ctrl+Shift+Alt+Backspace: reset dei valori di tutto l'FX con la logica originale di Ctrl+Shift+Backspace (incluso il chunk ReaEQ).
- F1/F2: Grid 1–400; F3 annuncia Grid e Step.

## Compatibilità dati

- Le 14 griglie indipendenti continuano a essere salvate in `lrp_context_grids_v1` e nei record di sessione già usati (stesso formato e nomi). La lettura ora accetta 1–400 invece di 1–200.
- Gli Step personalizzati restano in `lrp_param_step_scales_v1`, con fallback legacy intatto.
- Track Params/F4 TCP e FX Memories non vengono rimappati.
- La compatibilità ReaPack/CI per la release 0.0.66 non viene alterata.

## Verifiche REAPER/NVDA da eseguire su Windows

1. Scegli uno Step non zero e Grid non 10: Ctrl+Backspace deve azzerare solo lo Step.
2. Cambia nuovamente Step, poi Ctrl+Shift+Backspace una sola volta: dopo il breve intervallo Grid torna 10 e lo Step resta invariato.
3. Imposta Grid 37, premi due volte Ctrl+Shift+Backspace rapidamente: deve aprirsi EDIT con 37 preselezionato; Grid deve ancora essere 37 finché non confermi. Escape annulla.
4. Ripeti l'edit: 1, 200, 201 e 400 devono essere accettati e sopravvivere a cambio contesto/riapertura. 0, 401, testo vuoto e non numerico devono essere rifiutati senza cambiare la griglia.
5. Conferma che Plugin Order, Custom Order e ognuno dei 12 gruppi conservino la propria Grid e che F7 non sostituisca la posizione di navigazione.
6. In Standard, Keyboard e Value ripeti reset e campo EDIT: NVDA deve leggere il controllo, avere selezione/caret e recuperare il focus della navigazione dopo Invio/Esc.
7. Ctrl+Shift+Alt+Backspace deve ripristinare i parametri dell'FX con la logica originale, senza alterare personalizzazioni di Step/Grid.
8. In Track Params Ctrl+Backspace e l'editor numerico Ctrl+E devono mantenere esattamente il comportamento preesistente.
9. Testa la doppia pressione mantenendo premuti Ctrl+Maiusc; la ripetizione automatica di Backspace non deve essere scambiata per il doppio gesto.

Test statici passati non equivalgono a compilazione Windows né a test reale NVDA/REAPER.
