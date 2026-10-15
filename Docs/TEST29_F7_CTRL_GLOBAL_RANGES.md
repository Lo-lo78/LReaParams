# TEST29 — Serpentone, aggiornato dalla TEST30

Nuova selezione nel solo editor F7 (non cambia la navigazione fuori F7).

- Dalla posizione 15 di 40: **Ctrl+Maiusc+Home** seleziona 1–15 e lascia 16–40 deselezionati.
- Dalla posizione 15 di 40: **Ctrl+Maiusc+End** seleziona 15–40 e lascia 1–14 deselezionati.
- Il bordo è quello dell'intera griglia, non della singola colonna.
- **Ctrl+Home/End senza Maiusc** si sposta soltanto; **Ctrl+A** rimane seleziona-tutto.
- Dentro una griglia filtrata, il tratto comprende solo le occorrenze visibili; le selezioni fuori filtro rimangono salvate.
- Nelle griglie non filtrate una nuova selezione Ctrl+Maiusc+Home/End sostituisce i selezionati precedenti, compresi quelli alle spalle.
- Controllare Tab e NVDA+Freccia Su: il conteggio e 'Selected' devono rispecchiare la nuova selezione.
- Al bordo, la pressione successiva non deve pronunciare nulla.
- Dentro e fuori F7, Ctrl+Home/End mantiene la normale navigazione, senza selezionare.
- Maiusc+Home/End rimane limitato alla colonna corrente (TEST28).

Verifica statica soltanto: nessuna build locale, da testare nella DLL compilata da GitHub Actions.

Nota: la TEST29 originariamente associava anche Ctrl+Home/End alla selezione. La TEST30 corregge questa mappatura.
