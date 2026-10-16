> Documento storico TEST30. Per stato attuale e limiti prevalgono Status.md e FxCommandMatrix.csv.

# TEST14 — Unified window titles (0.0.15)

Senza cambiare navigazione, gestione dei parametri, memoria, focus o Value.

## Formato dei titoli accessibili (NVDA+T)

- FX Params, Grid: `FX Params - bass - VST3: Pro-Q 4 (FabFilter)`
- FX Params, Value: `FX Params - bass - VST3: Pro-Q 4 (FabFilter) - Value`
- FX Params, ricerca: `FX Params - bass - VST3: Pro-Q 4 (FabFilter) - Find Parameter`
- Track Params, F1: `Track Params - bass`
- Track Params, F1/Value: `Track Params - bass - Value`
- Track Params, F2: `Track Params - bass - Sends`
- Track Params, F3: `Track Params - bass - Receives`

`bass` e il nome del plugin sono esempi: i titoli usano quelli reali.
F2/F3 mantengono l'indicazione della pagina per distinguerle da F1.
Gli annunci di ingresso e cambio pagina rispettano lo stesso ordine.
I titoli non contengono `LReaParams`, `Grid` o `Tracks` nella pagina F1.

## Test manuale in REAPER (non eseguito qui)

1. Aprire FX Params su una traccia rinominata 'bass'; leggere NVDA+T.
2. Cambiare FX e traccia; NVDA+T deve aggiornare il nome e conservarne
   l'ordine.
3. Aprire Track Params e scorrere le righe della pagina F1: NVDA+T
   deve riportare il nome della traccia correntemente navigata.
4. Aprire F2/F3, quando disponibili, e verificare i suffissi Sends/Receives.
5. Testare i nomi traccia con accenti e caratteri non ASCII.
6. Entrare/uscire dalla modalita Value e controllare i suffissi e il focus.

Questa e una modifica di sola presentazione del titolo; non modifica il DSP,
i profili o le operazioni di REAPER. Non e stata eseguita nessuna build.
