# TEST53.2 — F2/F3: annunci direzionali Send/Receive

**Versione 0.0.53, correzione della TEST53.1.** Non modifica routing,
filtri, dati `.tp`, comportamento Value o scorciatoie. Parameter Library
resta fuori dal progetto.

## Freccia Su/Giu (14 parametri verticali)

Il parlato dice **solo parametro e valore**, per esempio:
`Volume, -6 dB`; `Pan, center`; `MIDI merge, on`.
Sull'intestazione (che non e un valore modificabile), dice solo `Send`
o `Receive`, senza nominare la traccia collegata. `NVDA+Su` usa la stessa
riga sintetica. La lettura con Tab mantiene il contesto completo.

## Freccia Sinistra/Destra (colonne Send/Receive)

Un nuovo collegamento parla sempre come `<nome traccia>, Send/Receive,
<parametro>, <valore>`. Se il collegamento appartiene alla stessa traccia
collegata della colonna **appena lasciata**, dal secondo in poi elimina
il nome ma mantiene il numero: `Send 2, Volume, -6 dB`; `Receive 3,
Pan, center`. Se la traccia cambia, il nome viene detto nuovamente,
anche quando il collegamento e il secondo/terzo verso quella traccia.
Il primo collegamento per ciascuna traccia usa `Send` / `Receive`
senza `1`, ma dichiara esplicitamente il tipo, a differenza della TEST53.1.

Gli ordinali sono riferiti a tutte le istanze reali che puntano alla stessa
traccia, non alle posizioni attualmente visibili dopo Ctrl+F. Si verifica
l'identita del peer tramite le API REAPER e si annuncia il contesto
solo in caso di movimento effettivo della colonna.

## Prove in REAPER/NVDA

1. In F2, posizionarsi su Volume e premere Su/Giu: solo parametro e valore.
2. Con Bass Send 1, Bass Send 2, Drums Send 1, Bass Send 3, navigare
   Sinistra/Destra: nome Bass sul primo, `Send 2` senza Bass sul secondo,
   nome Drums sul terzo e nome Bass sul quarto con `Send 3`.
3. Tornare da Bass Send 2 a Bass Send 1: `Bass, Send`, senza `Send 1`.
4. Ripetere in F3, quindi con un filtro che rende visibili solo due colonne
   non consecutive. Gli ordinali devono restare quelli reali.
5. Tab deve continuare a fornire il contesto esteso; Ctrl+F/Esc deve
   ancora dire `Search cleared. parametro, valore` e restare nel navigatore.

**Verifiche**: Python statico + esempi simulati soltanto. Nessuna compilazione
locale; MSVC, REAPER e NVDA vanno provati con GitHub Actions e manualmente.
