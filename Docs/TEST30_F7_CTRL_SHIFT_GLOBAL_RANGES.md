# TEST30 — Ctrl+Home/End muove, Ctrl+Maiusc+Home/End seleziona

Correzione della mappatura TEST29, **senza modifica del motore di selezione**.

- Ctrl+Home, Ctrl+End: prima e ultima cella dell'intera griglia, senza selezione anche in F7.
- Ctrl+Maiusc+Home, Ctrl+Maiusc+End: selezione dal parametro corrente al primo/ultimo dell'intera griglia, lasciando deselezionati i parametri alle spalle.
- Maiusc+Home/End: selezione fino al bordo della sola colonna.
- Ctrl+A: seleziona tutti, come prima.
- Quando il cursore è già sul bordo, non viene emesso un nuovo annuncio.
- La selezione per occorrenza e le selezioni esterne al filtro rimangono preservate.

Collaudo: su un FX con almeno 30 parametri, entra in F7 e posizionati a metà. Ctrl+Home non deve aggiungere alcuna selezione; Ctrl+Maiusc+End deve selezionare soltanto il tratto dal corrente all'ultimo. Ripeti sul bordo opposto. Verificare annunci NVDA e Tab.

Test statici soltanto: nessuna compilazione locale.
