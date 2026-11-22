# TEST75.4 – Messaggi personalizzabili, FX Params e Track Params

La TEST75.4 parte dalla TEST75.3.10. **Nessuna release nuova e nessun cambiamento al publisher ReaPack**.

## Come utilizzare l’interfaccia

Apri Ctrl+P, vai su **Messages > FX Params** oppure **Messages > Track Params**. La prima lista contiene come prima tutti i titoli: i quattro titoli FX o i dodici titoli Track. **Dopo i titoli** compaiono i messaggi ricavati dal codice dei rispettivi navigatori. Alcuni sono composti da parti variabili (parametri, valori, tracce, MIDI CC); sono presentati come messaggi dinamici.

Seleziona un messaggio e premi Tab per raggiungere la seconda lista. Sono disponibili due voci:
- **Enabled – Message**: premi Spazio (o Invio) per disattivare/riattivare quel messaggio.
- **Custom message**: premi Invio, scrivi il testo e conferma con Invio. Testo vuoto = messaggio originale.

Un testo personalizzato sostituisce il singolo annuncio. Puoi includere `{original}` per conservare anche le informazioni originali variabili, per esempio `Parametro selezionato: {original}`.

**OK** salva, **Annulla/Esc** scarta tutte le modifiche. L'archivio contiene i riferimenti dei messaggi (`Docs/MessageCatalog.tsv`) per ispezionare ciascuna voce. Sono individuati tramite espressione e file, non tramite numero di riga: aggiungere codice non deve spostare le associazioni precedenti.

## Prove di regressione
1. Verifica che i quattro titoli FX e i dodici titoli Track siano invariati (ordine, parti, editing).
2. Disattiva un messaggio univoco e prova a provocarlo. Non deve esserci annuncio.
3. Personalizza un messaggio con e senza `{original}` e verifica il risultato.
4. Annulla e controlla che il messaggio ritorni come prima. Conferma con OK, riapri REAPER e verifica la persistenza.
5. Controlla parametri, valore, ricerca, MIDI, F7, navigazione Track e pagine: senza personalizzazioni devono parlare come nella TEST75.3.10.
6. Controlla Shift+F1, i titoli e Render Shortcuts: nessun cambiamento.

La compilazione MSVC e il test reale con OSARA/NVDA sono ancora necessari.
