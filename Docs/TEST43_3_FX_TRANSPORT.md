# 0.0.43.3 — Trasporto da FX Params

## Contratto

- `Space`: azione REAPER 40044 (Play/Stop); se `GetPlayState` indica pausa (bit 2), usa `OnPlayButton` per riprendere come il Lua.
- `Ctrl+Space`: riproduzione/registrazione attiva (bit 1 o 4) -> `OnPauseButton`; fermo o pausa -> `OnPlayButton`. Fallback 40073, come nel Lua.
- Solo FX Params, incluso editor F7, Value, navigatore FX Memories F8. Nessuna modifica alla gestione tastiera di Track Params.
- `Shift+Space` in F7 è riservato a selezionare/deselezionare il parametro.
- Non intercettare Space nei campi EDIT reali di ricerca, rinomina e modifica numerica.
- Un solo comando per pressione fisica: gli eventi repeat vengono consumati senza rispedire il comando. Nessun annuncio di navigazione/valore generato.

## Prova manuale dopo la compilazione GitHub Actions

1. Entra nella griglia FX, premi Space una volta: REAPER parte. Premi di nuovo: REAPER si ferma.
2. Premi Ctrl+Space da fermo: parte; ripremilo: va in pausa; ripremilo: riprende dalla pausa.
3. Da pausa, premi Space una volta: riprende immediatamente, non serve premere due volte.
4. Mantieni Space premuto: un solo comando anche con ripetizione tastiera.
5. Entra in Value, F7 e F8; verifica i due comandi. In F7, Shift+Space continua a cambiare la selezione senza avviare il trasporto.
6. In Ctrl+F, nella rinomina e nell'edit numerico verifica che gli spazi non facciano partire/fermare la riproduzione.
7. Verifica che Track Params, MIDI CC, ReaEQ e annunci NVDA non abbiano regressioni.

Solo audit Python eseguiti localmente. Verifica funzionale REAPER, NVDA e MSVC demandata al proprietario tramite GitHub Actions.

**Aggiornamento 0.0.43.4:** Ctrl+Spazio non usa più il ramo manuale OnPauseButton/OnPlayButton, ma richiama direttamente l’azione REAPER 40073. Vedi TEST43_4_NATIVE_PLAY_PAUSE.md.
