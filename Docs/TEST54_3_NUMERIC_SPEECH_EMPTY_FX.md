# TEST54.3 — Ctrl+E e contesti FX vuoti

Base: TEST54.2. Le modifiche sono limitate alla lettura dei valori numerici e al rifiuto degli FX assenti. Nessuna modifica alla memoria `.tp`, al runtime MIDI, alla creazione degli envelope o alle scorciatoie.

## Ctrl+E, Invio

L’inserimento numerico aggiorna normalmente il valore REAPER e chiude il campo EDIT accessibile. Non viene più aggiunto il secondo messaggio `Set. Volume, ... CC ... Auto`, poiché il controllo nativo riporta già il valore. Gli errori di convalida (numero non valido, valore fuori intervallo, ecc.) continuano a essere annunciati e l’editor resta aperto per correggere.

## FX Params senza effetti

Quando il contesto richiesto è una traccia senza FX, annuncia soltanto `No track FX`. Quando è un item selezionato in contesto item e il take non ha FX, annuncia `No take FX`. FX Params non entra in un’altra catena solo perché contiene effetti. La lista FX nativa esplicitamente focalizzata mantiene la precedenza; le catene Master e Monitor con FX restano accessibili.

Se premi **Ctrl+Tab in Track Params** su una traccia senza FX, si sente `No track FX` e **rimani in Track Params**, mantenendo cursore e finestra di focus NVDA; nessuna chiusura/ripartenza del navigatore.

## Casi manuali da provare dopo GitHub Actions

1. In F1 Volume con CC e Auto, Ctrl+E, scrivi `-6`, Invio: una sola lettura del valore aggiornato, senza `Set.` aggiuntivo. Prova anche Pan e un valore non valido.
2. Ctrl+Tab da Track Params su una traccia vuota: `No track FX`, nessun cambio di contesto. Ripeti su una traccia con FX: FX Params si apre normalmente.
3. Dalla Action List, apri FX Params su traccia senza FX: `No track FX`, non navigare su un’altra traccia con FX. Apri su una traccia con FX e verifica che la navigazione normale funzioni.
4. Seleziona un item con take senza FX, usa il contesto item: `No take FX` senza aprire FX Params su un altro take o sulla traccia. Verifica il caso positivo con take FX reale.
5. Controlla Master/Monitor FX, catena nativa focalizzata, ritorno con Ctrl+Tab, e tasti di ricerca dopo il rifiuto: nessuna perdita del focus NVDA.

**Solo controlli statici locali.** Compilazione MSVC, test C++ e collaudo REAPER/NVDA tramite GitHub Actions e la DAW.
