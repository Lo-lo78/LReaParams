# LReaParams 0.0.68 — TEST68.1: ripristino vista Usati dopo Escape

Versione di prova: non pubblicare come release `v0.0.68`, che e' gia' stabile su GitHub/ReaPack. About, versione e storico restano invariati.

- Entra in un FX con almeno due parametri Usati. Con Ctrl+Shift+L attiva Usati.
- Seleziona il secondo parametro, premi Escape, poi riapri FX Params sullo stesso FX: annunciato Used; secondo parametro ancora selezionato.
- Da Usati, premi Ctrl+Shift+L per tornare al contesto precedente. Escape e riapertura devono tornare al contesto originale, non a Usati.
- Usa due istanze diverse dello stesso plugin: lascia la prima in Usati, la seconda in un gruppo. Dopo Escape, ognuna deve ripristinare il proprio contesto.
- Mentre sei in Usati, cambia FX con Ctrl+Su/Giu e torna: deve tornare a Usati dell'FX precedente, non contaminare l'altro FX.
- Salva il progetto, chiudi e riapri REAPER. Riapri FX Params e verifica che Usati sia ancora attivo (solo se era l'ultima vista salvata).
- Verifica che le raccolte U1 della 0.0.68 siano ancora leggibili, anche tornando alla 0.0.68 stabile. Il primo ingresso in Usati da un progetto precedente continua a essere manuale.
- Controlla griglia, tema Keyboard, F3 e Ctrl+Delete; devono rimanere indipendenti dai 14 contesti standard.

Implementazione: il codec U1 resta IDENTICO. La preferenza sull'ultima vista viene salvata in una seconda chiave del progetto, collegata al GUID dell'FX. I 12 gruppi, le 14 griglie, i profili `.fx`, l'indice ReaPack e i tag esistenti non vengono modificati.
