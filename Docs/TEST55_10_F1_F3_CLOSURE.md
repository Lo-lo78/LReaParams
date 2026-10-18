# LReaParams TEST55.9 + TEST55.10 — chiusura F1/F2/F3

## Novità

| Comando | FX Params | Track Params |
|---|---|---|
| Ctrl+Q | Torna al TCP, mantenendo MIDI FX operativo | Torna al TCP, mantenendo i MIDI CC Track Fixed e Floating attivi in background |
| Ctrl+Maiusc+Alt+A | Chiede conferma per disattivare tutti gli envelope del FX corrente | Chiede conferma per disattivare gli envelope della traccia corrente, compresi FX e send in uscita |
| Ctrl+Maiusc+A | Singolo parametro FX | In F1 anche Width, con creazione se mancante; in F2/F3 continua a usare il routing identificato |

- **Conferma automation:** NVDA/OSARA legge la domanda. **Y oppure Invio** conferma; **N o Esc** annulla. Le variazioni vengono raggruppate in un singolo Undo REAPER. I punti, automation item e dati audio non vengono cancellati: si disattiva ACT/VIS. Se qualche envelope fallisce, viene dichiarato il fallimento parziale.
- **Ambito FX:** istanza FX attuale, inclusi Take FX, non l'intera traccia. **Ambito Track:** traccia sotto il cursore Track Params, con envelope propri/FX, più outgoing send in altre tracce. Tutti i link sono controllati, senza riordinare routing o tracce.
- **Ctrl+Q:** selezione TCP e navigazione sono restituite a REAPER; soltanto la logica MIDI continua nel main thread tramite timer. Floating mantiene il parametro al momento dell'uscita, Fixed risolve il GUID per ogni CC. L'azione esistente `LReaParams: Stop background MIDI` ferma sia Track sia FX.
- **Width:** viene prima verificata l'esistenza dell'envelope. Se manca, si aggiunge `WIDTHENV2` al solo chunk della traccia con protezione contro i chunk troncati. Il risultato viene controllato, con ripristino del chunk precedente se la creazione non viene riconosciuta. In questi casi la funzione comunica l'insuccesso, non finge di avere armato l'envelope.

## Collaudo suggerito dopo GitHub Actions

1. In F1 assegna un Fixed CC al Pan di una traccia, quindi Ctrl+Q: da TCP muovi il controller mentre selezioni un'altra traccia. Deve continuare a muoversi soltanto la traccia originaria. Prova anche un Floating CC, senza riapertura del navigatore.
2. Lancia l'azione **Stop background MIDI**. I CC parcheggiati devono smettere di agire. Prova il passaggio fra Ctrl+Q FX e Ctrl+Q Track per verificare che non avvengano applicazioni doppie.
3. In F1, su **Width** senza envelope, premi Ctrl+Maiusc+A e controlla che l'envelope sia presente, attivo, visibile e armato. Con lo stesso comando verifica la disattivazione individuale.
4. Con una traccia contenente Width, envelope di volume, FX e un send, premi Ctrl+Maiusc+Alt+A, poi **N** per annullare. Ripeti e premi **Y**. Controlla che i punti non siano spariti e che **Undo** annulli l'operazione. Ripeti in FX Params: deve disattivare i soli envelope dell'FX corrente.
5. Verifica Ctrl+Tab, Ctrl+Maiusc+M e F8 Compare: nessuna regressione rispetto a TEST55.8.

## Limiti e compatibilità

- Non sono state effettuate compilazioni locali. In GitHub Actions il workflow esegue build e test C++ su MSVC. La verifica audio reale e quella delle API REAPER/SWS richiedono REAPER.
- Le associazioni dei send duplicati seguono ancora l'indice d'occorrenza; riordini/eliminazioni dei send possono cambiare l'identità di un link. È una limitazione nota e non è stata nascosta.
- F4 e le sezioni successive non sono migrate in questa versione. **Parameter Library rimane esclusa**.
