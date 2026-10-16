# LReaParams 0.0.44.1 — prova manuale con REAPER e NVDA

## Memoria posizione
1. Aprire FX Params su ReaComp; raggiungere Ratio, poi Detector Highpass e un parametro della coda. Chiudere FX Params e riaprirlo; verificare il ritorno allo stesso parametro ogni volta.
2. Ripetere su ReaGate (Lookahead e Detector Lowpass), su un normale VST3 e passando da un FX all'altro. Memoria valida solo nella sessione REAPER, senza riscrivere i profili.
3. Controllare la posizione dopo Ctrl+L fra Plugin/Custom Order, e la separazione delle memorie tra FX distinti.

## Detector input
1. Con REAPER fermo e progetto di prova (attenzione alle sorgenti Feedback), selezionare una alla volta tutte le 8 modalità tramite Alt+Frecce e verificare il nome letto e quello che mostra REAPER nella GUI del plugin.
2. Se una modalità non viene applicata, NVDA dice `Detector input unchanged`. Per la diagnosi, il debug Windows (`OutputDebugStringA`) riporta il valore raw e l'intervallo accettato dall'API, senza disturbare la lettura.
3. Ripetere su ReaGate e, se disponibile, Take FX. Provare anche Invio/Value e controllo MIDI CC.
4. Se REAPER espone un intervallo che non include 999..1027, il codice non prova ad aggirare i limiti usando numeri inventati; confrontare la GUI reale e il Lua nella stessa installazione.

Nessuna build locale eseguita. Test C++ in GitHub Actions dopo caricamento dei sorgenti.
