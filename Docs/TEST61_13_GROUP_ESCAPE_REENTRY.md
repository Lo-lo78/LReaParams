# TEST61.13 — FX Params: Esc e ripristino gruppo

- Esc nella griglia di un gruppo chiude direttamente FX Params, senza passare per Custom Order o Plugin Order.
- Alla successiva apertura dello stesso FX, la memoria della sessione ripristina il gruppo e la posizione esatta nel gruppo (oltre alla vista Custom/Plugin e agli altri valori preesistenti).
- F7 resta un editor: Esc da F7 chiude prima l'editor, come in precedenza; il suo stato non viene riaperto automaticamente.
- Il gruppo viene ripristinato soltanto se ancora esiste e non è vuoto; altrimenti si apre la griglia normale.
- Il richiamo Ctrl+numero-gruppo per chiudere volontariamente un gruppo continua a funzionare e a tornare alla vista di origine.

## Verifica su GitHub Actions / REAPER

1. Aprire FX Params, entrare in un gruppo e spostarsi su un parametro non iniziale.
2. Premere Esc: la finestra deve chiudersi subito.
3. Riaprire LReaParams: FX Params sul medesimo FX: gruppo e parametro devono essere invariati.
4. Ripetere con altri FX e con Ctrl+Tab, e controllare che ognuno mantenga la propria posizione.
5. Aprire F7 dal gruppo ed uscire da F7 con Esc; il successivo Esc deve chiudere FX Params.
6. Controllare che Ctrl+Fn sul gruppo aperto torni ancora a Custom Order o Plugin Order.

Nota: il numero del gruppo è mantenuto nella memoria della sessione, non scritto nel profilo .fx. Il parametro continua a usare il meccanismo di persistenza preesistente.
