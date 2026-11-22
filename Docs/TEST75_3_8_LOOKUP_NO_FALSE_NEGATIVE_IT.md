# LReaParams TEST75.3.8 — ricerca senza falsi «non trovato»

- Derivata dalla TEST75.3.7.
- La ricerca su Alt+S continua a essere non esecutiva: non attiva i pulsanti delle Preferenze.
- La ricerca segnala «Shortcut not found in this section» soltanto per una pressione davvero non riconosciuta, una sola volta dopo il rilascio del tasto.
- Se un gesto viene riconosciuto, il focus passa alla voce e l'avviso di errore resta soppresso anche in presenza di ulteriori messaggi della stessa pressione.
- Per i messaggi di sistema WM_SYSKEYDOWN, il modificatore Alt viene ricavato anche dal bit di contesto del messaggio Windows, non solo dallo stato momentaneo della tastiera.

## Prova in REAPER con NVDA/OSARA

1. Aprire Render, Ctrl+P, Shortcuts > Render, Alt+S, Alt+1. Primary viene selezionato **senza** «Shortcut not found».
2. Tornare a Alt+S e cercare Alt+2: Secondary viene selezionato **senza** «Shortcut not found».
3. Cercare una combinazione inesistente. Il messaggio «Shortcut not found in this section» deve essere annunciato una volta e la selezione non deve cambiare.
4. Ripetere con Alt+R, Ctrl+P, Shift+F1, F3, Shift+F3 e una combinazione personalizzata.
5. Verificare che Alt+S sia l'unico ingresso alla ricerca, e che Alt+D sia sempre interrogabile senza attivare pulsanti.
6. Aprire Ctrl+P da Render, uscire dalle Preferenze e poi da Render con Esc. Il focus deve rimanere in REAPER.

**Validazione:** controlli statici locali; verifica MSVC/Windows e prova accessibile da eseguire sul dispositivo dell'utente.
