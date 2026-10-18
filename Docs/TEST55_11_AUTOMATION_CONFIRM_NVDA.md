# TEST55.11 — Conferma automazioni accessibile a NVDA

Partendo da TEST55.10, il messaggio pronunciato per **Ctrl+Maiusc+Alt+A** è ora anche il **testo di revisione effettivo** del controllo Windows che possiede il focus. In precedenza veniva pronunciata la domanda ma `NVDA+Freccia Su` continuava a leggere il parametro corrente.

Lo stesso flusso vale per FX Params e Track Params. Entrando nella conferma, la scelta predefinita è **No**, senza eseguire alcuna operazione. In modalità Value il focus viene trasferito dal vero slider al controllo statico di revisione, che espone la domanda mediante `WM_GETTEXT`, senza annunci nativi duplicati.

| Comando durante la conferma | Risultato |
|---|---|
| NVDA+Freccia Su | Legge la domanda, la scelta corrente (Yes/No) e le istruzioni |
| Freccia Sinistra | Seleziona Yes (annuncia solo se cambia) |
| Freccia Destra | Seleziona No (annuncia solo se cambia) |
| Tab | Ripete la domanda e la selezione |
| Invio | Esegue Yes o No secondo la selezione, con No iniziale |
| Y | Conferma immediatamente |
| N, Esc | Annulla |

Nessun punto o automation item viene cancellato: rimane la funzione di **disattivazione** degli envelope, con Undo unico, introdotta nella TEST55.10. I normali parametri, la memoria `.fx` / `.tp` e gli altri comandi rimangono invariati.

## Prova in REAPER

1. Entra in Track Params, su un parametro Volume; Ctrl+Maiusc+Alt+A. Prima di scegliere, premi NVDA+Freccia Su: deve leggere la domanda e `No selected`, non `Volume`.
2. Freccia Sinistra: `Yes`. NVDA+Freccia Su deve leggere `Yes selected`. Freccia Destra deve ripristinare `No selected`.
3. Invio con No selezionato deve annullare. Ripeti e scegli Yes, poi Invio: disattiva le automazioni e verifica Undo.
4. Ripeti in FX Params e dalla modalità Value, dove NVDA deve leggere la domanda invece del nome del vecchio slider.
5. Prova Y, N ed Esc: la conferma deve restare modale e non far muovere tracce/parametri sottostanti.

**Non compilare localmente:** le verifiche statiche non sostituiscono GitHub Actions MSVC né la prova reale di NVDA.
