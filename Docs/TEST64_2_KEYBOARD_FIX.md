# LReaParams 0.0.64 TEST64.2 — Keyboard: tasti vuoti silenziosi e Pagina Su/Giù

Build sperimentale, non creare una release né un tag. Basata su TEST64.1; le 14 scelte dei temi e il profilo `.fx` restano invariati.

## Correzioni

1. Quando una posizione dei 36 tasti non ha un parametro (ad esempio `M` in una pagina con 20 parametri), non viene pronunciata alcuna parola: nessun «Empty», nessun movimento e nessuna modifica del valore.
2. Nel tema Keyboard, **Pagina Su** aumenta e **Pagina Giù** diminuisce il valore corrente con lo **Step ampio** già usato da Value. Il controllo slider nativo Windows ora richiede esplicitamente la ricezione di questi tasti. Le frecce Su/Giù restano le regolazioni fini; Alt+Su/Giù cambia la pagina da 36, selezionando il primo parametro della nuova pagina.
3. Ctrl+Pagina Su/Giù conserva la funzione di spostamento FX, così come Ctrl+B, Ctrl+Shift+D, le memorie, F7 e tutte le altre scorciatoie non ridefinite.

## Prova pratica con NVDA/OSARA

- In un gruppo Keyboard con meno di 36 parametri, premere `M`: deve restare in completo silenzio e il parametro corrente deve restare selezionato.
- Su un parametro che abbia un intervallo ampio, premere Pagina Su e Pagina Giù senza modificatori: il valore deve cambiare in entrambe le direzioni, con lettura corretta; frecce Su/Giù devono ancora regolare finemente.
- Su un gruppo con almeno 37 parametri, Alt+Giù deve selezionare il primo della seconda pagina. Ctrl+Pagina Su/Giù deve continuare a spostare l'FX, non il valore.
- In Standard e F7, tutto deve funzionare come prima. Testare anche il caso RX 11.

Questi controlli statici non sostituiscono la verifica con una DLL compilata e REAPER su Windows.
