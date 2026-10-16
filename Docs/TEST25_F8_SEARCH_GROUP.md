> Documento storico TEST30. Per stato attuale e limiti prevalgono Status.md e FxCommandMatrix.csv.

# TEST25 — Gruppi, FX Memories e ricerca letterale (sorgente)

**Nota:** per il comportamento dei gruppi e dei filtri vale la successiva TEST26; la prova di ritorno obbligatorio a Plugin Order qui sotto è storica e superata.

## Collaudo REAPER con NVDA

1. Aprire una Custom Order e Alt+G, poi Ctrl+F1 su un gruppo salvato.
   Ripremere Ctrl+F1: l'annuncio deve essere `Plugin Order`.
   Tab deve confermare la vista e non ci si deve trovare in F7.
2. Aprire F7, poi F8: scegliere il gruppo o la Custom Order e premere Invio.
   Deve uscire da F8 e da F7, mantenendo il gruppo o la Custom Order caricata.
   Provare allo stesso modo Memory positions, MIDI CC e Copied parameters.
3. In F8 selezionare Hidden parameters e premere Invio: nessun cambiamento.
   La voce resta nascosta; usare Canc se si vuole davvero ripristinarla.
4. In F8 scegliere Default values, Invio: se esiste uno snapshot normalizzato
   e il reset riesce, deve essere pronunciato `Default restored. Plugin Order`;
   Tab deve annunciare Plugin Order. Con Default mancante o snapshot strutturale
   ReaEQ non supportato, non abbandonare F8 e non modificare il plugin.
5. Su parametri chiamati `Slot 1 Filter`, `Slot 10 Filter`, `Slot 19 LFO1`,
   `Kick`, `Kickoff`, cercare tramite campo EDIT nativo Ctrl+F:
   `"slot 1 fil"` corrisponde solo a `Slot 1 Filter`;
   `"slot 1 lfo1"` non deve trovare slot 10/19;
   `"kick"` trova Kick ma non Kickoff;
   la ricerca **senza virgolette** resta per sottostringa.
6. Ripetere la ricerca dentro F7 con alcune selezioni già presenti:
   la selezione va conservata anche quando l'elemento esce dal filtro.

## Protezioni

Non compila localmente; nessun comando CMake, MSVC o build in questi test.
Default strutturale ReaEQ e reset avanzati Lua restano da migrare.
