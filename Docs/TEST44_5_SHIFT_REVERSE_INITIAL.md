# 0.0.44.5 — Shift + iniziale: navigazione indietro

Nella griglia FX Params, premere una lettera, cifra o un segno di punteggiatura
senza modificatori cerca ciclicamente **in avanti** il parametro il cui nome
visibile inizia con quel carattere. Con **Maiusc** la ricerca procede invece
**all’indietro**, iniziando dalla voce precedente e tornando dall’inizio alla
fine dell’elenco. Per esempio, su `Pan`, premendo `P` si passa a `Portamento`,
poi `Pitch`; con `Maiusc+P` si torna verso `Pan`. Il confronto ignora le
differenze fra maiuscole e minuscole.

La stessa regola vale in Plugin Order, Custom Order, gruppi, filtri e F7;
le selezioni F7 restano intatte. Si usa il carattere effettivo letto con
`ToUnicodeEx` per rispettare il layout italiano: se Maiusc produce un simbolo
invece della cifra, si cerca quel simbolo all'indietro. Anche AltGr+Maiusc
usa la direzione inversa se produce un carattere stampabile.

Un tasto senza corrispondenze è silenzioso; se l'unica corrispondenza è il
parametro corrente, questo viene riletto. Nei controlli Value, F8, SEARCH,
rinomina e nei campi EDIT, i caratteri non provocano salti nella griglia.
Restano invariati Maiusc+Spazio e le selezioni Maiusc+Frecce/Home/End in F7,
la memoria FX persistente LastParam e il precedente fix MSVC del codice '0'.

## Collaudo REAPER/NVDA (dopo build GitHub Actions)

1. Su Pan, Portamento e Pitch, ripetere `P` e poi `Maiusc+P`: avanti e indietro.
2. Provare ritorno circolare in entrambe le direzioni e caso senza risultati.
3. Provare in gruppi, Custom Order, filtri e F7 senza perdere le selezioni.
4. Provare numeri e punteggiatura sul layout italiano, anche con AltGr.
5. Verificare che non interferisca con Value, ricerca, rinomina e trasporto.

Nessuna compilazione locale eseguita.
