# LReaParams 0.0.60 — TEST60: Marker e trasporto comune

La TEST60 aggiunge il navigatore condiviso `TransportMarkers.cpp` usato da FX Params (Grid, Value, FX Browser, F7, FX Memories) e da Track Params (F1–F8, Track Memories). I comandi sono attivi soltanto quando la finestra tastiera di LReaParams è focalizzata; non si applicano ai controlli EDIT nativi, alle finestre di conferma, a AltGr o ad altre finestre REAPER.

| Gesto | Azione |
| --- | --- |
| Ctrl+1 ... Ctrl+9 | Marker dal numero REAPER 1–9, con fallback al corrispondente marker ordinato nel tempo |
| Ctrl+0 | Marker numero REAPER 10, con fallback al decimo ordinato |
| Ctrl+I | Marker strettamente precedente, ignorando le regioni |
| Ctrl+O | Marker strettamente successivo, ignorando le regioni |
| Ctrl+Alt+Pagina Su/Giù | Beat indietro/avanti (REAPER 41045/41044) |
| Alt+Maiusc+Pagina Su/Giù | Misura indietro/avanti (REAPER 41043/41042) |
| Ctrl+Alt+Maiusc+Pagina Su/Giù | Inizio misura corrente/precedente o successiva (REAPER 41041/41040) |

I comandi REAPER sono eseguiti dalla DLL e la posizione viene annunciata come `Bar 12 beat 3 0%` tramite `TimeMap2_timeToBeats` (time map nativa, anche con cambi di metrica). `Ctrl+I` e `Ctrl+O` annunciano il marker con numero, nome se disponibile e posizione, o il bordo una volta sola. Con Ctrl+numero il numero visibile del marker ha priorità; se mancante, viene selezionato il marker in quella posizione nell'elenco temporale, preservando il comportamento del Lua Track. Le regioni non sono mai scelte. Lo spostamento del cursore verso un marker usa `SetEditCurPos2` con seek playback attivo, come il Lua.

**Non modificati:** Ctrl+freccia Sinistra/Destra per item/take; Ctrl+Pagina Su/Giù per gli FX; tutte le navigazioni delle pagine; alias e riordino di F4 esclusi; formati `.tp`, `.fx`, memoria e MIDI invariati.

## Collaudo manuale in REAPER/NVDA

1. Crea marker 1, 3, 9, 12 e due regioni intercalate. Ctrl+1 salta al marker 1; Ctrl+2 usa il secondo marker in ordine se manca marker reale 2. Ctrl+0 annuncia la mancanza se hai meno di 10 marker e nessun marker 10.
2. Ctrl+I/O navigano unicamente i marker, nei due versi, fino al bordo e poi restano silenziosi al secondo tentativo. Controlla nome UTF-8 e posizione.
3. Prova le tre coppie di gesti Pagina con un progetto contenente cambi di BPM e 3/4, 5/8, 4/4. Conferma Bar/beat/percentuale e corrette posizioni a schermo.
4. Ripeti da FX Grid, FX Value, FX browser, FX F7/F8, Track F1, F4, F5, F6, F7, F8. Verifica che la posizione del parametro rimanga inalterata e NVDA resti nella pagina.
5. Dentro Ctrl+F, Ctrl+E o rinomina conferma che Ctrl+I/O/digit e le combinazioni Pagina non spostino il cursore di REAPER e rimangano al campo. Prova AltGr su tastiera italiana.
6. Verifica Ctrl+Pagina Su/Giù (movimento FX), Ctrl+Sinistra/Destra (take/item) e Ctrl+Spazio (play/pause) invariati.
7. Cambio scheda progetto mentre un navigatore è aperto: la DLL deve rifiutare il gesto se non è più il progetto originario.

**Non sono state eseguite build MSVC o CMake locali.** La verifica Windows resta GitHub Actions; i test Python qui sono statici.
