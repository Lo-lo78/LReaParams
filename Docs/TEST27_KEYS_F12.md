# TEST27 — verifica tasti in REAPER/NVDA

1. Apri FX Params ed entra in F7; seleziona più parametri distribuiti su righe e colonne diverse.
2. **Alt+Maiusc+Freccia Su/Giù**: raggiunge soltanto i selezionati nella colonna.
3. **Alt+Maiusc+Freccia Sinistra/Destra**: raggiunge soltanto i selezionati delle altre colonne, privilegiando la stessa riga.
4. **Alt+Frecce senza Maiusc**: non viene più interpretato come navigazione fra selezionati. Verifica che non provochi effetti collaterali rispetto al comportamento di Step/Value.
5. **F12 da solo**: non succede nulla e il focus resta in LReaParams (sia Grid sia Value); non deve essere aperta la guida scorciatoie di OSARA. Verifica anche il campo EDIT quando attivo.
6. **Ctrl+F12 / Ctrl+Maiusc+F12**: slot gruppo/posizione n. 12, rispettando Alt+G e Alt+M.
7. **Alt+F10/F11/F12**: la gestione dei watcher OSARA resta separata dalla riserva di F12 semplice.

Solo controlli statici in questa consegna: nessuna build locale, verifica effettiva tramite GitHub Actions e REAPER.
