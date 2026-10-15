# TEST16 — Track Params: NVDA+Freccia Su conciso (0.0.17)

**Solo sorgenti:** nessuna build locale. Compilazione via GitHub Actions.

## Modifica puntuale

- In Grid F1, F2 e F3, la lettura passiva con NVDA+Freccia Su restituisce solo `Parametro, valore`, esattamente come FX Params.
- Navigazione Sinistra/Destra in F1 (e navigazione dei controlli della stessa traccia) resta `Parametro, valore`.
- Cambiando traccia con Su/Giù in F1 l'annuncio vocale include ancora il nome della traccia.
- Ctrl+R continua a pronunciare il contesto completo (traccia, send/receive se presente, parametro, valore).
- NVDA+T continua a leggere il titolo completo, per esempio `Track Params - bass - Sends`.
- In Value, la lettura nativa continua a includere `Value, parametro, valore`. Inalterati slider Win32, Enter, tasti e modifiche ai parametri.

## Prova manuale NVDA / REAPER

1. Aprire Track Params F1 su `bass`; andare a Width.
2. NVDA+Su deve leggere `Width, 100 percent` (valore esemplificativo), senza `bass`.
3. Premere Su per cambiare traccia: l'annuncio deve includere il nome della nuova traccia.
4. NVDA+T deve leggere `Track Params - <nome traccia>`; Ctrl+R deve rileggere la traccia più il parametro e il valore.
5. Entrare in Value su Width, verificare il ruolo slider e la lettura con NVDA+Su.
6. Ripetere su F2/F3 quando presenti sends o receives.

## Raccomandazione per la prossima migrazione FX

Attivare **lettura e applicazione dei profili `.fx`** in FX Params, iniziando con due viste: Plugin Order (ordine REAPER, non modificabile) e Custom Order (ordine/alias/parametri nascosti secondo profilo). Il parser attuale conserva soltanto il payload dei profili e non li collega alla griglia. Implementare identità plugin e mapping stabile degli indici prima degli editor F7/Groups, F8/Memories e F10/Parameter Library. Nessuna di queste nuove funzionalità è implementata in TEST16.
