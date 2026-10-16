# TEST44.3 — Navigazione per iniziale, conforme al Lua

Riferimento originale: `Scripts/Speak FX Params - TrackTake Navigator.lua`,
`list_cycle_by_initial()` e `handle_letter_jump()`.

La griglia accetta lettere, numeri e punteggiatura senza Ctrl/Alt e
anche i caratteri digitati con AltGr (Alt destro, distinto da Ctrl+Alt
esplicito). Maiusc permette i caratteri della disposizione locale.
La pressione singola salta al prossimo match in `visible_`, partendo dalla
posizione successiva, con ritorno all'inizio. La base è il **nome visibile**
del parametro, compresi alias, nomi virtuali, gruppi e filtri.

Non fa una ricerca di sottostringa e non applica alcun filtro: `Ctrl+F`
rimane il comando per la ricerca testuale. Il tasto singolo non altera
la selezione F7 e non modifica valori o profili.

Il tasto prodotto da Windows è tradotto con `ToUnicodeEx` senza alterare lo
stato dei tasti morti. In F7 naviga, mentre nei veri campi EDIT rinomina,
ricerca e inserimento numerico si comporta come input testuale.
Il layout può richiedere Shift per caratteri quali `!`, `?`, `(`.

## Prove manuali NVDA/REAPER (dopo GitHub Actions)

1. Nel plugin con `Pan` e `Portamento`, premere P ripetutamente: cicla.
2. Da un parametro dopo gli elementi P: P deve ritornare al primo P.
3. Premere una lettera senza corrispondenze: silenzio, griglia aperta.
4. Cercare una cifra (es. 1) e un segno di punteggiatura iniziale.
5. Provare il layout italiano con Shift per un carattere di punteggiatura.
6. In Custom Order, gruppo e lista filtrata, il ciclo resta nella vista.
7. In F7 con parametri selezionati, il salto conserva le selezioni.
8. In Value, Ctrl+F e Rinomina, verificare che il tasto non faccia
   saltare la griglia; Ctrl/Alt e Space/Ctrl+Space restano invariati.
9. Uscire e rientrare in FX Params: la posizione di un salto è ricordata.

Nessuna compilazione locale eseguita.
