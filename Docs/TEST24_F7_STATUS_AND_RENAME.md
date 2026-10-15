# TEST24 — F7, selezione e Custom Order (solo sorgente)

## Collaudo con NVDA e REAPER

1. Aprire FX Params su un plugin senza Custom Order esistente. Ctrl+L deve annunciare `No Custom Order. Press F7` e non deve creare il profilo. F7 crea realmente la Custom Order identica alla Plugin Order, la salva nel `.fx` e apre l'editor. Uscire da F7, poi Ctrl+L alterna le due viste anche dopo la riapertura del plugin.
2. Nell'editor F7 premere Ctrl+A, muoversi con frecce. Ogni occorrenza selezionata deve iniziare con `Selected` seguito da parametro e valore. Deselezionare con Maiusc+Spazio e verificare che `Selected` scompaia dalla lettura ordinaria e da NVDA+Su. Provare le copie duplicate del medesimo parametro.
3. Tab fuori da F7: `Plugin Order. 4 of 234` oppure `Custom Order. 4 of 234`. In F7: `Edit: Custom Order. 5 selected. 4 of 234`. Dentro un gruppo deve comparire il nome del gruppo e il conteggio dei parametri della vista.
4. Da F7 con **Alt+M**, Ctrl+Invio apre la casella `Parameter name`; digitare e confermare. Creare o aprire un gruppo, **Alt+G**, Ctrl+Invio deve aprire `Group name`. Senza un gruppo aperto deve annunciare il requisito senza rinominare il parametro. Fuori F7 Ctrl+Invio annuncia solo `Press F7 to rename`.
5. Ctrl+G e Ctrl+M non devono più duplicare Alt+G e Alt+M. Ctrl+L, durante modifica F7 o dentro un gruppo, non deve cambiare la vista e perdere il contesto.
6. Ctrl+F fuori F7: il campo Windows EDIT riceve il focus; digitare un nome parziale, Invio trova il prossimo parametro e ripristina la griglia. Ctrl+F in F7 crea un filtro, conserva le selezioni preesistenti, inclusi i selezionati non visibili.
7. Controllare profili `.fx` preesistenti, nomi Unicode, Undo e le memorie FX F8. Il salvataggio fa backup e rifiuta conflitti, come nella TEST23.

## Limiti

Verifiche in sola lettura del codice e con script Python; nessuna build locale.
Le prove NVDA/UI, import profili reali e gli eventi focus richiedono GitHub Actions + REAPER.
