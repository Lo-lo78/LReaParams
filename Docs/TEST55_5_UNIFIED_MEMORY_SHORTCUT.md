# TEST55.5 — Unica scorciatoia per FX Memories e Track Memories

Base: TEST55.4; progetto sorgente per la compilazione GitHub Actions, nessuna build locale.

## Nuovi gesti

- **Ctrl+Maiusc+M** in FX Params (Grid, Value o F7) apre **FX Memories**.
- **Ctrl+Maiusc+M** in Track Params (F1/F2/F3) apre **Track Memories**.
- Dentro uno dei due gestori, **Ctrl+Maiusc+M** lo chiude e ripristina il contesto di origine. **Esc** continua a tornare alla navigazione.
- **Alt+F8** non apre più Track Memories.
- **F8** è **senza funzione in FX Params**, incluso all'interno del gestore, e resta libero per funzionalità future. F7 di FX Params conserva l'editor.
- Le azioni REAPER `LReaParams: FX Memories` e `LReaParams: Track Memories` rimangono disponibili, con gli ID di comando invariati.
- Nei campi nativi EDIT (filtri e modifica numerica) il nuovo gesto non sottrae scorciatoie al campo: uscire dal campo prima di aprire il gestore.
- In Track Params F7/F8 rimangono riservati alle sezioni del Lua ancora da migrare.

## Convalida con NVDA/REAPER (ancora da eseguire)

1. Aprire FX Params dalla griglia, premere Ctrl+Maiusc+M: si apre FX Memories con il consueto annuncio.
2. Esc torna al parametro corrente. Ripetere dalla modalità Value e da F7 verificando focus, filtro e posizione.
3. Aprire Track Params F1, F2 e F3; Ctrl+Maiusc+M apre Track Memories; Esc torna alla sezione precedente.
4. Dall'interno dei due gestori, Ctrl+Maiusc+M torna al navigatore una sola volta; i tasti tenuti premuti non aprono/chiudono ripetutamente.
5. Controllare che F8 non apra più FX Memories e che Alt+F8 non apra Track Memories, anche se premuti dentro il gestore.
6. Provare entrambe le azioni REAPER autonome, verifica NVDA e nessun cambiamento ai `.fx`/`.tp` o alle associazioni CC.
7. Verificare che CTRL+Maiusc+M non rubi caratteri mentre il focus è nell'EDIT di ricerca o numerico.

Solo test statici locali; nessuna compilazione, nessuna prova runtime.
