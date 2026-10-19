# LReaParams 0.0.57 — TEST57: F6 Track MIDI

**Sorgente per GitHub Actions. Non compilato localmente, non verificato in REAPER/NVDA o con dispositivi MIDI reali.**

## Ambito

F6 di **Track Params** è una pagina della **traccia corrente**, non del singolo FX. Segue il riferimento funzionale `Speak Track Params - TrackTake Navigator.lua`, sezione `3.5C - F6 TRACK MIDI PAGE`. Non tocca la matrice audio F5, i pin degli FX o la gestione dei CC Fixed/Floating di F4.

Una lista verticale di cinque voci:

1. **MIDI hardware output** — `I_MIDIHWOUT`: Disabled, Device 1–32; il nome MIDI fisico viene letto mediante `GetMIDIOutputName` se disponibile. Quando cambi dispositivo viene preservato il canale hardware attivo.
2. **MIDI hardware channel** — stesso valore `I_MIDIHWOUT`: Output disabled se il dispositivo è inattivo; altrimenti All, 1–16. La modifica non è consentita prima di attivare un dispositivo.
3. **MIDI input channel map** — `I_MIDI_INPUT_CHANMAP`: Source channel oppure 1–16.
4. **MIDI control channel** — `I_MIDI_CTL_CHAN`: None, 1–16, All channels (valori REAPER -1, 0–15, 16).
5. **MIDI routing** — sola lettura, comunica che routing MIDI vive in F2 Send / F3 Receive. Invio raggiunge F2 se esiste almeno un send, altrimenti F3 se esiste almeno un receive.

Nessun chunk viene riscritto: lettura `GetMediaTrackInfo_Value`, scrittura `SetMediaTrackInfo_Value`, verifica del valore letto, blocco Undo, `TrackList_AdjustWindows` e `UpdateArrange` per le scritture riuscite. Se il valore non cambia al limite, una prima lettura conferma lo stato; i tentativi ripetuti rimangono silenziosi.

## Tastiera

- **F6**: da F1, F2, F3, F4, griglia Alt+Invio di F4 oppure F5; richiama la pagina e annuncia contesto. F6 già aperto ripete il contesto.
- **Su/Giù**, **Pagina Su/Giù**: spostano il cursore tra le cinque voci, la pagina salta fino a cinque righe. **Home/End** o **Ctrl+Home/End**: prima/ultima voce. Bordi di navigazione silenziosi.
- **Alt+Su/Giù**: aumenta/diminuisce il valore di 1. **Alt+Pagina Su/Giù**: incrementi/decrementi di 4. **Alt+Home/End**: massimo/minimo. **Invio**: aumenta di 1 (o entra nel routing se sulla quinta voce).
- **Tab**: stato, nome traccia e indice della voce. **NVDA+Su**: sola voce e relativo valore. Titolo NVDA: `Track Params - Nome traccia - Track MIDI`.
- **F1, F2, F3, F4**: passa alle pagine corrispondenti. **F5 da F6**: richiede di selezionare prima un FX in F4, come nel Lua. **Esc** termina il navigatore da F6, come nel Lua.
- **Ctrl+Shift+M**: richiama il gestore memorie di Track Params. **Ctrl+Tab / Ctrl+Q**: conservati dal router centrale. **Spazio/Ctrl+Spazio**: trasporto comune, come già presente negli altri ambienti.

Lo stato della **posizione F6** usa `LastPage=F6`, `F6.TrackGUID`, `F6.Row` nel medesimo `.tp` del progetto; viene recuperato solo se appartiene alla stessa traccia. Non introduce nuovi file, modifica solo i campi di posizione, non l'audio o i CC.

## Prove da effettuare dopo la build GitHub Actions

1. Apri Track Params in F1 su una traccia senza FX e premi F6: dovresti ascoltare `MIDI hardware output, Disabled`. Poi Tab ripete anche nome traccia e posizione, senza dover selezionare un FX.
2. Verifica su una traccia con FX l'accesso F4→F6→F4: la posizione dell'FX e del parametro TCP rimane invariata. Verifica F4→Alt+Invio→F6 e F5→F6 e che F5 conservi 128 canali.
3. Hardware output: Disabled→Device 1→Device 32→Disabled, leggendo i nomi reali se presenti. Fai Undo/Redo e conferma il valore REAPER effettivo. Hardware channel disabilitato deve dire di attivare prima l'uscita.
4. Con hardware attivo, prova All, 1 e 16. Cambia device: il canale deve rimanere invariato. Prova Alt+Pagina Su/Giù (4) e Alt+Home/End agli estremi.
5. Input map: Source channel, 1, 16, poi di nuovo Source channel. Control channel: None, 1, 16 e All channels. Controlla i valori in Routing REAPER e l'Undo.
6. MIDI routing: Invio va ai Send se ce ne sono; altrimenti ai Receive; senza entrambi dice `No sends or receives`. Non deve mai creare o cancellare routing.
7. Cambia traccia e torna alla precedente: F6 non deve attribuire a un'altra traccia la sua posizione persistita. Esci/rientra: verifica la posizione F6 salvata nel `.tp`.
8. Con OSARA/NVDA, testa NVDA+Su, Tab, i bordi silenziosi, Esc, il gestore memorie e Ctrl+Tab; prova anche una traccia senza dispositivi MIDI connessi.
9. Esegui il workflow e controlla DLL e CTest; i controlli Python **non attestano** la compilazione C++ o la semantica hardware reale.

## Verifica locale eseguita

Controlli statici Python mirati a TEST57, valori limite modello, regressioni TEST55/TEST56; nessuna compilazione C++, configurazione CMake, MSBuild o avvio di REAPER eseguiti.
