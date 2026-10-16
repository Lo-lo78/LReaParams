# 0.0.43.4 — Ctrl+Spazio usa Transport: Play/pause (40073)

Correzione mirata della versione 0.0.43.3: anziché decidere manualmente tra `OnPauseButton` e `OnPlayButton`, la navigazione FX Params richiama **una sola volta** `Main_OnCommand(40073, 0)` per Ctrl+Spazio, come l'azione che l'utente ha impostato nell'Action List. In particolare evita di chiamare `OnPlayButton()` da pausa, condizione che nel collaudo ha provocato un ritorno alla posizione di partenza.

- **Ctrl+Spazio:** azione REAPER 40073, Play/pause. Da fermo avvia, durante la riproduzione mette in pausa, dalla pausa riprende da quel punto.
- **Spazio:** rimane 40044 Play/stop; quando già in pausa conserva l'eccezione preesistente per riprendere subito.
- **Maiusc+Spazio in F7:** selezione normale, non trasporto.
- Campi EDIT di ricerca, rinomina e modifica numerica: lo Spazio continua a essere testo.
- Eventi `repeat`: consumati; nessun doppio comando per singola pressione.

## Prova manuale dopo GitHub Actions

1. Posiziona il cursore a inizio progetto e avvia con Ctrl+Spazio nella griglia FX Params.
2. Dopo qualche secondo premi Ctrl+Spazio: REAPER deve essere **in pausa**, il cursore di riproduzione fermo sul punto raggiunto.
3. Premi ancora Ctrl+Spazio: deve **riprendere esattamente dal punto della pausa**, senza tornare all'inizio.
4. Ripeti in Value, F7 e F8, poi prova Spazio per verificare che conservi Play/stop.
5. Ripeti Ctrl+Spazio dall'Action List di REAPER senza FX Params, per confrontare il comportamento dell'azione nativa in caso di configurazioni di trasporto particolari.

Solo controlli statici: nessuna compilazione locale o test operativo con REAPER/NVDA.
