# TEST61.12 — Percorso dinamico e pulsante Fine

### Percorso predefinito

L'installer utilizza `InstallDir "$APPDATA\REAPER"`: NSIS calcola `$APPDATA`
a runtime, sul PC di chi lo esegue, secondo il profilo dell'utente Windows
attuale. Non c'è alcun nome utente nel sorgente. L'eventuale percorso già
memorizzato in `HKCU\Software\Lo-lo78\LReaParams` ha precedenza per gli
aggiornamenti, così da preservare una scelta personalizzata o portatile.

### Interfaccia NVDA

Schermate: lingua, benvenuto, cartella REAPER, copia file, completamento.
Dopo l'installazione viene mostrata la pagina di successo con pulsante
**Fine** (oppure **Finish** in inglese). Premendolo il setup si chiude.
Nessuna istruzione nel wizard cita messaggi intermedi ridondanti.

### Prove manuali dopo build GitHub Actions

1. Installare su Windows con due account diversi e verificare che la cartella
   proposta sia relativa all'account che lancia il setup.
2. Con una precedente installazione, verificare il recupero della cartella
   personalizzata da HKCU, incluso REAPER portatile.
3. Controllare che il campo della destinazione si possa modificare da NVDA.
4. Verificare la presenza della pagina Fine e che Invio su Fine chiuda il setup.
5. Verificare che i profili e i file non gestiti dall'installer rimangano intatti.

Non sono state eseguite compilazioni locali o prove runtime.
