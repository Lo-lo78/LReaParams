# TEST75.3.9 — Alt+1/Alt+2, ricerca nelle Preferenze Render

Derivata dalla TEST75.3.8. Correzione specifica per il falso annuncio «Shortcut not found in this section» dopo la selezione corretta di Primary/Secondary.

- Alt+1 e Alt+2 nella ricerca Render vengono risolti direttamente alle voci `tab|0` (Primary) e `tab|1` (Secondary), senza dipendere dagli acceleratori ciclici Alt+lettera.
- Una personalizzazione effettiva di Alt+1/Alt+2, se presente, ha la stessa precedenza della normale navigazione Render.
- Il risultato trovato chiude immediatamente la transazione di ricerca; eventuali messaggi ripetuti fino al rilascio del tasto non possono produrre un esito negativo per la stessa pressione.
- Soltanto Alt+S porta il focus su Cerca scorciatoia. L'interrogazione non esegue azioni o modifica valori.
- Il comportamento di ricerca degli altri tasti rimane invariato; una scorciatoia veramente sconosciuta produce ancora «Shortcut not found in this section».

## Test manuale indispensabile in Windows / REAPER / NVDA

1. Da Render premere Ctrl+P, selezionare Render Shortcuts, Alt+S, poi Alt+1. Deve selezionare Primary e non annunciare «not found».
2. Rientrare con Alt+S, premere Alt+2: stessa verifica per Secondary.
3. Cercare due volte ciascuna combinazione, sia dopo aver aperto Preferenze da Primary sia da Secondary.
4. Cercare una combinazione sicuramente inesistente: deve annunciare «Shortcut not found in this section» una sola volta, lasciando immutata la selezione.
5. Verificare anche Alt+R, Ctrl+P, Shift+F1 e le scorciatoie personali.
6. Chiudere Preferenze con Esc, Render con Esc: il focus deve rimanere in REAPER.

Audit e test statici non sostituiscono la compilazione Windows e la prova con NVDA.
