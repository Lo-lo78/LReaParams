# LReaParams 0.0.75 – TEST75.3.6, ricerca e ritorno del focus da Render

Questa TEST corregge due regressioni segnalate nella TEST75.3.5 senza cambiare la mappa automatica di Render o i comandi FX/Track Params.

## 1. Ricerca per scorciatoia

- `Alt+S`, quando viene premuto per entrare nel campo «Search by shortcut», deve SOLO mettere il focus nel campo. I messaggi di ripetizione e l'eventuale carattere Windows della stessa pressione sono ignorati fino al relativo rilascio fisico. **Non** devono produrre «Shortcut not found in this section».
- Dopo aver rilasciato il tasto, premere una combinazione nel campo deve avviare una singola interrogazione. Se esiste, il focus passa all'elemento trovato senza annunciare un fallimento; se non esiste, annuncia il fallimento e resta nel campo, conservando la selezione.
- Ripetere Alt+1, Alt+2, Alt+R, F1, F12, Ctrl+P e Shift+F1 secondo il contesto; provare anche uno shortcut davvero inesistente e le combinazioni Alt+O/Alt+C per verificare che non eseguano OK/Cancel.
- Alt+S e Alt+D possono essere interrogati come dati entrando nel campo e **rilasciando prima** i tasti dell'acceleratore usato per entrarci.

## 2. Focus dopo la chiusura di Render

- Nella chiusura normale di Ctrl+P (OK o Esc/Annulla), la finestra proprietaria viene riabilitata **prima** della distruzione del popup e riattivata dopo. Questo preserva il consueto ordine di attivazione Windows anche se l'owner è Render.
- Aprire Render dalla TCP di REAPER, premere Ctrl+P, poi Esc: si ritorna allo stesso controllo di Render. Premere di nuovo Esc: si deve tornare alla finestra principale di REAPER, senza finire in un'altra applicazione o sul desktop.
- Ripetere con OK, con le scorciatoie Alt+O/Alt+C e dopo una ricerca riuscita. Controllare anche apertura di Ctrl+P da FX Params e Track Params, e Alt+Tab con Ctrl+P aperto.

## Verifica

È disponibile `Testing/test75_3_6_lookup_focus_restoration_static.py`, un controllo solo statico che non sostituisce il test reale su Windows / REAPER / NVDA / OSARA. Nessuna build MSVC è stata eseguita qui.
