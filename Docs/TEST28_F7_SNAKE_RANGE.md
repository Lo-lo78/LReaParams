# TEST28 — Intervalli del serpentone F7

Prima della compilazione si verificano staticamente le modifiche nel sorgente. Per collaudare in REAPER/NVDA:

1. Apri F7 su un FX con almeno 35 parametri e imposta Grid 10. Vai al quinto parametro della prima colonna.
2. Premi Maiusc+End: si selezionano **5–10**, non 1–10 e non soltanto 5 e 10. Tab legge il conteggio.
3. Deseleziona, torna al quinto parametro, premi Maiusc+Home: si selezionano **1–5**, non 1–10.
4. Su una colonna con almeno 10 elementi, partendo dal terzo premi Maiusc+Pagina Giù: ogni elemento attraversato va incluso (compresi tutti quelli tra partenza e arrivo). Premi Maiusc+Pagina Su per verificare la retrazione continua.
5. Ripeti da un parametro già selezionato per verificare la modalità «pennello che deseleziona» del Lua.
6. Dopo aver raggiunto l'inizio o la fine di una colonna, ripremi la relativa combinazione di selezione: **silenzio**, niente messaggi sul bordo e nessuna nuova selezione.
7. Ripeti su un gruppo con parametri duplicati e su un filtro di ricerca: le occorrenze selezionate restano indipendenti e i parametri esterni al filtro restano salvati.
8. Alt+Maiusc+Frecce continua a navigare solamente fra i selezionati; F12 da solo rimane riservato.

Nota: per le frecce con Maiusc resta la convenzione Lua della prima pressione che seleziona il parametro corrente. Per gli spostamenti lunghi Home/End e Pagina Su/Giù si includono immediatamente anche tutte le posizioni intermedie e il punto di arrivo.

Nessuna compilazione o avvio di REAPER eseguiti localmente.
