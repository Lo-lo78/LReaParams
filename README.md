# LReaParams — TEST18 (0.0.19)

**Progetto sorgente C++ per REAPER. Nessuna compilazione locale:** la DLL viene
compilata esclusivamente tramite GitHub Actions (Windows x64 / Visual Studio).

La TEST18 continua dalla TEST17 e conserva importazione dei vecchi profili,
navigazione FX e Track, controllo di tastiera e memoria in RAM. Aggiunge
l'ordine personalizzato e le principali funzioni dell'editor F7 di FX Params.

## FX Params

- Titolo NVDA+T: `FX Params - bass - VST3: Pro-Q 4 (FabFilter)` (senza
  `LReaParams` e senza `Grid`). In Value il titolo aggiunge `- Value`.
- **Ctrl+Su/Giù:** FX precedente/successivo nella catena corrente.
- **Ctrl+Maiusc+Su/Giù:** traccia precedente/successiva contenente FX con
  parametri navigabili; salta quelle prive di FX e seleziona la traccia in
  REAPER. L'ultimo FX, parametro, altezza griglia e Step vengono recuperati
  distintamente per progetto, GUID traccia e GUID FX (e take dove previsto).
- Se non esistono altre tracce con FX compare un messaggio dedicato.
- **Alt+Sinistra/Destra:** `Step -10` … `Step 0` … `Step 10`.
  `0` applica i passi normali; lo Step usa fattori di 2.
- Le modifiche del parametro parlano **solo il valore**. I movimenti di
  griglia continuano ad annunciare nome del parametro e valore.
- **Invio** apre o chiude Value: uno slider Win32 `msctls_trackbar32` riceve
  il focus per offrire il ruolo nativo a NVDA; il valore reale resta gestito
  da REAPER. L'annuncio iniziale è `Value, parametro, valore`.

## Track Params

- Titolo NVDA+T: `Track Params - bass` in F1, `Track Params - bass - Sends`
  in F2 e `Track Params - bass - Receives` in F3. I nomi delle tracce
  vengono aggiornati durante la navigazione e convertiti da UTF-8 a Unicode.
- Lo stesso ordine finestra / traccia / FX è utilizzato negli annunci di
  apertura, senza il prefisso LReaParams e senza il suffisso Grid.

- Nella pagina F1, le frecce Sinistra/Destra pronunciano soltanto
  **parametro e valore**; Su/Giù cambia traccia e aggiunge il nome della
  traccia. Ctrl+R mantiene la rilettura del contesto completo; **NVDA+Su legge solo parametro e valore** come FX Params.
- Anche qui la variazione di un parametro parla solo il valore.
- Alt+Sinistra/Destra imposta Step da -10 a +10. Questa scala modifica
  esclusivamente volume, pan e width (traccia e send/receive); la gestione
  di controlli discreti, mute e solo, e del routing rimane quella di TEST12.
- Con Invio, volume/pan/width usano lo slider Win32 di Value. Per mute,
  solo, phase e altri interruttori Invio continua a commutare On/Off.
- F2 e F3, o Invio su Send count / Receive count, **non aprono pagine
  vuote**: annunciano `No sends` o `No receives`.

## Accessibilità e note di test

- L'interfaccia resta utilizzabile da tastiera. Il controllo STATIC di Grid
  non emette modifiche del nome; lo slider Value è nativo, con posizione
  aggiornata passivamente. Restano disponibili Ctrl+R e NVDA+T.
- La persistenza riguarda **la sessione corrente di REAPER**, non i progetti
  salvati o i file TXT; non viene scritto alcuno stato nel progetto RPP.
- I controlli Track Params avanzati ancora incompleti non sono stati riscritti.
- La sintesi vocale finale, il riconoscimento del controllo slider da parte
  di NVDA e il focus devono essere verificati realmente in REAPER con OSARA.

Vedere `Docs/TEST13_TRACK_SWITCH_VALUE.md` per la checklist TEST13 e
`Docs/TEST14_WINDOW_TITLES.md` per il controllo dei titoli.
`Docs/TEST15_TRACK_SPEECH_FX_VALUE.md` per le nuove prove su annunci e Value.

## TEST16 — Modifica di accessibilità mirata

In Grid, la lettura passiva con NVDA+Freccia Su espone soltanto parametro e valore, senza ripetere la traccia o la pagina. L’annuncio di cambio traccia, Ctrl+R, il titolo NVDA+T e gli slider Value rimangono invariati. Vedere `Docs/TEST16_TRACK_NVDA_REVIEW.md`.

## TEST17 — FX Custom Order / F7 (sorgente, senza build)

- **Ctrl+L**: Plugin order / Custom order. L'accesso a una Custom Order
  virtuale, ancora identica all'ordine originale, non crea alcun profilo.
  L'ordine dei parametri usa sempre gli indici nativi REAPER per l'audio.
- Importazione *applicata* dei profili `.fx` già migrati, identificati
  con `PluginRaw`. L'ordine salvato conserva duplicati, alias e hidden.
  Le nuove modifiche sono scritte nel `.fx` nativo con backup e verifica
  preventiva che nessun altro processo abbia modificato lo stesso file.
- F7: modifica strutturale solo in Custom Order o dentro un Group; selezione
  Ctrl+A / Shift+Spazio, serpente Shift+frecce, Tab per il conteggio; Cut/Copy/Paste
  strutturale con Ctrl+X/C/V; Ctrl+Canc nasconde anche senza selezione; Canc deseleziona;
  Ctrl+Invio permette un alias Unicode o il nome del gruppo.
- Ctrl+G / Ctrl+M sceglie Group / Memory positions per gli slot;
  Ctrl+F1…F11 richiama, Ctrl+Maiusc+F1…F11 salva nello scope corrente.
  Gli slot di gruppo e i memory positions vengono conservati nel profilo.
- In F7 Ctrl+Maiusc+Canc ripristina *tutti* i parametri nascosti: è una
  misura di recupero temporanea aggiunta perché il pannello completo F8
  per gestire i parametri nascosti non è ancora disponibile.
- **Non ancora equivalenti al Lua**: Default Snapshot completo in F8,
  esecuzione dei MIDI CC, le viste Search filtrate di F7, la gestione completa dei Group
  con selezioni per occorrenza e percorsi indipendenti, gli editor avanzati
  dei nomi e i parametri virtuali ReaEQ/ReaComp/ReaGate/Compare.
  In questa TEST17 è migrato il nucleo operativo di F7, non l'intera
  matrice di tutte le scorciatoie del Lua da oltre 37.000 righe.

Vedere `Docs/TEST17_CUSTOM_ORDER_F7.md` per collaudo e limiti. I test in REAPER
sono necessari prima di usare la DLL per modificare profili importanti.

## TEST18 — FX Memories, azione separata e vista F8

- REAPER Action List: **LReaParams: FX Memories**, comando
  `_LREAPARAMSFXMEMORIES` (senza `(future)`): apre la vista autonoma.
- La vista F8 integrata in FX Params si apre **dall'editor F7**.
  La modalità autonoma e F7 condividono la stessa implementazione e gli stessi
  profili `.fx`, quindi non esistono due memorie separate.
- Sette colonne come nel Lua: Memory positions, Groups, Hidden parameters,
  MIDI CC, Custom order, Copied parameters, Default values.
- Caricamento e cancellazione delle posizioni, dei gruppi, degli hidden,
  della Custom order e delle singole copie. MIDI CC può essere cancellato
  insieme ai campi di learn REAPER; Default Snapshot è **solo consultabile**
  finché non viene migrato il reset completo del Lua.
- Navigazione e ritorno a griglia/editor seguono il Lua; i tasti e la
  procedura di test sono in `Docs/TEST18_FX_MEMORIES.md`.

**Non compilato localmente; build prevista soltanto tramite GitHub Actions.**
