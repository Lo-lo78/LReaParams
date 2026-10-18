# LReaParams 0.0.56 — TEST56.6 — F4 compatto in stile FX Params

## Obiettivo
La finestra F4 di Track Params presenta un **solo FX alla volta**, e soltanto i parametri effettivamente esposti nei controlli TCP di REAPER. Non cambia i parametri della catena FX in modalità di sola navigazione. Preservata l'API TCP nativa, GUID, undo, `.tp` per progetto, NVDA, filtri, Value e memorie.

## Layout virtuale fisso (8 righe)
Gli otto primi parametri TCP formano la prima colonna, i parametri 9–16 la seconda, 17–24 la terza e così via. L'intestazione FX è separata e non occupa una delle otto righe. Su/Giù attraversa i parametri nella stessa colonna, Sinistra/Destra si sposta tra colonne della **stessa istanza FX**. Home/End primo/ultimo della colonna attiva; PagSu/PagGiù saltano fino a 5 parametri all'interno di quella colonna. Ctrl+Home/End raggiunge il primo/ultimo parametro TCP dell'FX attuale. Ai bordi nessun annuncio. Tab legge il contesto, compreso numero FX, colonna e riga. Il cambio FX annuncia l'effetto attivato.

## Shortcut F4

| Gesto | Effetto |
|---|---|
| Ctrl+Su/Giù | FX precedente/successivo (non sposta nulla) |
| Ctrl+Maiusc+Su/Giù | Traccia con FX precedente/successiva, sincronizzando TCP |
| Alt+Maiusc+Su/Giù | Sposta fisicamente l'FX nella catena (era Ctrl+Maiusc) |
| Frecce | Griglia corrente, alto/basso o colonna dello stesso FX |
| Home/End | Prima/ultima riga dell'attuale colonna di 8 |
| Ctrl+Home/End | Primo/ultimo parametro TCP dell'FX corrente |
| Alt+Home/End | Massimo/minimo del valore corrente, anche in Grid |
| Invio sull'intestazione FX | Griglia dei nomi di tutti i parametri dello stesso FX |
| Invio su un parametro TCP | Grid / Value |
| Canc | Rimuove il parametro corrente dal TCP, non l'FX |
| Ctrl+B / Ctrl+D | Bypass / Delta Solo |
| Ctrl+Maiusc+A | Automation del parametro TCP corrente |
| Ctrl+F | Filtro esistente, ricerca anche tra virgolette |
| Ctrl+Maiusc+M | Track Memories |
| Esc | Esce da Value, annulla filtro o torna a F1 |

**Alt+Invio non ha più una funzione in F4.** F6 rimane libero. I tasti funzione cambiano ambiente e non attivano funzioni di modifica. La griglia dei nomi conserva F1/F2 per cambiarne l'altezza, Invio per aggiungere e tornare e Ctrl+Invio per aggiungere/rimuovere senza uscire.

## Piano di collaudo REAPER/NVDA

1. Traccia con ReaEQ (10+ parametri TCP) e ReaComp: F4, riga 1, Destra raggiunge parametro 9 di **ReaEQ**, non ReaComp.
2. Ctrl+Giù annuncia ReaComp e la vista mostra solo parametri ReaComp; Ctrl+Su torna a ReaEQ.
3. Ctrl+Maiusc+Giù cambia traccia con FX; Alt+Maiusc+Giù sposta **l'FX** (Undo possibile).
4. Ctrl+Home/End naviga primo/ultimo parametro, Alt+Home/End modifica soltanto valore e legge il valore modificato.
5. Canc rimuove il controllo TCP corrente. Invio sull'intestazione apre la griglia dei nomi, Ctrl+Invio lo riaggiunge.
6. Alt+Invio non apre nessuna griglia; Ctrl+F, filtri tra virgolette, Value e Tab rimangono operativi.
7. Confermare assenza di regressioni in Track F1/F2/F3, FX Params e memoria `.tp`.

Nessuna build locale; compilazione MSVC e runtime esclusivamente con GitHub Actions e REAPER/NVDA.
