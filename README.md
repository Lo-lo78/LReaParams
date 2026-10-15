# LReaParams — TEST30 (0.0.31)

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

## TEST19 — Contextual shortcuts for REAPER FX Chain

The command assigned to Track Params in REAPER Main Action List now opens FX Params while the native FX Chain list is focused; FX Params also uses the selected FX and its actual owner. A guarded SDK accelerator bridge attempts to recognize the shortcuts assigned to either action (including P and Ctrl+Shift+P when configured) without capturing ordinary typing elsewhere. This remains an uncompiled experiment requiring a Windows/REAPER/OSARA test. See `Docs/TEST19_FX_CHAIN_SHORTCUTS.md`.

## TEST20 — FX Chain shortcut clarification

The single letter **P is NOT hardcoded**. It is user-assigned to the FX Params action in REAPER Main Action List. The guarded SDK accelerator bridge tries to honor that current assignment from the focused FX selection list. **Ctrl+Shift+P IS hardcoded only for the focused native FX list**, where it opens FX Params, regardless of whether that shortcut is assigned to Track Params in the Main Action List. Outside the FX list, Ctrl+Shift+P is not intercepted and can run Track Params via the user's Main assignment. Other keys assigned to Track Params are no longer automatically redirected from FX Chain.

This is a source-only TEST20 revision requiring runtime validation in REAPER/OSARA, and does not verify hook ordering or accessibility behavior. See `Docs/TEST20_FX_CHAIN_KEY_ROUTING.md`.

## TEST21 — FX Params: controllo fuori F7

- Master FX: `FX Params - Master - <nome FX>`; Monitor FX: `FX Params - Monitor FX - <nome FX>`. I vecchi prefissi `Monitor: ` sono conservati **solo** nelle chiavi dei profili `.fx` per non romperne la compatibilità.
- Ctrl+B: bypass dell'istanza Track/Master/Monitor/Take; il titolo mostra `- Bypassed` se necessario.
- Ctrl+D: Delta Solo sull'FX corrente **solo quando REAPER espone il controllo wrapper Delta**; non si modifica un parametro generico in caso contrario.
- Ctrl+Shift+D: ricerca l'azione REAPER `FX: Clear delta solo for all project FX`; messaggio breve se le istanze analizzabili non hanno Delta Solo. Fallback sugli FX con wrapper Delta rilevabile; container non coperti dal fallback.
- Tab fuori F7: `Plugin Order` / `Custom Order`. In F7 conserva il conteggio dei selezionati.
- F3: `Grid N. Step N. Group slots` oppure `Memory slots`.
- Alt+G alterna Groups / Memory positions e conserva la scelta nel profilo. Ctrl+G / Ctrl+M restano invariati.
- F5, F6 e F9 chiamano le azioni native REAPER 40280, 40281, 40282 come il Lua.
- F10 senza modificatori è lasciato alla futura Parameter Library. Alt+F10/F11/F12 rimangono liberi per i watcher OSARA.

**Non compilare localmente:** revisione statica soltanto. La compatibilità esatta dei comandi e del wrapper Delta va verificata usando REAPER e GitHub Actions.

## TEST22 — Navigazione Home/End e stati FX

- In FX Params, Ctrl+Home va al **primo** parametro globale; Ctrl+End all'**ultimo**.
  Home/End agiscono analogamente sul primo/ultimo parametro della colonna corrente.
- Nella selezione Shift+Home/End in F7 e nelle colonne F8 vale la stessa direzione.
  In FX Memories Ctrl+Home/End sceglie la prima/ultima colonna non vuota.
- In FX Value e con Alt, Home continua a impostare il massimo ed End il minimo
  (comportamento Lua precedente); la correzione riguarda solo la navigazione nella griglia.
- Cambiando effetto vengono annunciati **prima** Monitor FX/Master/traccia,
  poi Bypassed e Delta Solo **solo se attivi**, quindi nome dell'FX, parametro e valore.
  Per esempio: `Monitor FX. Bypassed. Delta Solo. side JS: acendan_Center Control. Center Level (dB), -120.0`.
- Titolo NVDA+T con entrambi gli stati: `FX Params. Bypassed - Delta Solo. Monitor FX - side JS: acendan_Center Control`.
  Senza stati resta l'ordine precedente: `FX Params - Monitor FX - plugin`.
- Resta il limite della TEST21: Delta Solo è riconosciuto solo quando il wrapper
  REAPER espone l'ultimo parametro col nome `Delta` o `Delta Solo`.

La TEST22 è solo sorgente e richiede verifica con GitHub Actions, REAPER e NVDA.

## TEST23 — F7, Windows EDIT, FX defaults (source only)

- **Alt+G** seleziona Groups, **Alt+M** seleziona Memory positions. Niente ciclo.
- **Tab** fuori da F7 pronuncia Plugin Order / Custom Order oppure il nome del Group
  corrente. F7 mantiene il conteggio dei selezionati e il contesto.
- **Backspace**: reset singolo dal Default Snapshot verificato.
- **Ctrl+Shift+Backspace**: reset dell'intero FX con unico blocco Undo REAPER.
- **Ctrl+Backspace**: ripristina Grid 10 e Step 0.
- All'apertura di un FX senza snapshot, i valori correnti vengono catturati
  automaticamente nello snapshot Lua v3 del profilo `.fx` (**solo plugin
  non-ReaEQ**). Salvare prima un preset iniziale se si desidera usarlo come
  riferimento. Un snapshot già presente non viene mai sovrascritto.
- In F8 la colonna Default Values espone lo snapshot e Invio applica il reset.
  Il reset strutturale di ReaEQ è esplicitamente bloccato fino alla
  migrazione del chunk; non si improvvisa un reset per indice.
- Group: caricamento e Tab pronunciano il nome salvato, se presente.
- Ctrl+Invio in F7 e Ctrl+F usano una **vera casella Windows EDIT Unicode**
  separata dal campo STATIC silenzioso della Grid e dalla trackbar Value.
  Invio accetta e Esc annulla. Ctrl+F in F7 filtra la lista mantenendo la
  selezione negli indici originali; Ctrl+F + Invio vuoto rimuove il filtro.
- F7 include Ctrl+Z / Ctrl+Y per annullare e ripristinare le modifiche
  strutturali eseguite nella sessione corrente dell'editor.

**Da verificare tramite GitHub Actions, REAPER, NVDA e OSARA:** messa a fuoco
casella EDIT, annuncio iniziale della rinomina, combinazioni Maiusc nella
selezione a serpente e differenze fra FX statici, plugin con parametri dinamici
(in particolare ReaEQ) e plugin in FX Chain. Il formato `.fx` e le schede
Lua non sono state intenzionalmente sostituite o eliminate.

## TEST24 — F7 selection, Custom Order creation and accessible rename

- **F7** is the only action that creates a previously absent Custom Order; the
  initial unmodified order is saved as a real `.fx` custom profile. Ctrl+L
  only switches between **existing** Plugin/Custom views. While a Group is open
  or inside F7, Ctrl+L cannot switch away from the current editing context.
- Within F7, moving to a selected occurrence speaks `Selected, <parameter>,
  <value>`; NVDA+Up also includes the selected state. Duplicated parameters
  are selected independently by occurrence, even after an F7 search filter.
- **Tab** outside F7: `Custom Order. 4 of 234` (or Plugin Order, or current
  Group name). Inside F7: `Edit: Custom Order. 5 selected. 4 of 234` (or
  `Edit: Group ...`); the denominator is the visible active list.
- **Alt+G** sets Group slot access; **Alt+M** sets Position slot access. Removed
  Ctrl+G / Ctrl+M aliases. Ctrl+Enter **in F7** renames the open Group only
  in Alt+G mode; in Alt+M mode it renames the current parameter. Ctrl+Enter
  outside F7 says `Press F7 to rename`. A Group must first be opened to name it.
- **Ctrl+F** opens the same native Windows EDIT Unicode field both inside
  and outside F7. Enter outside F7 locates a parameter in the current list;
  inside F7 applies a filtered view without discarding F7 selections.

No local CMake, Visual Studio or native builds. Requires testing in GitHub Actions
then REAPER with NVDA/OSARA, especially the lifetime of the native text focus.


## TEST25 — F8 e ricerca tra virgolette (uscita gruppo superata da TEST26)

- **Nota storica TEST25:** ripetere Ctrl+Fn forzava Plugin Order.
  **TEST26 sostituisce questo comportamento:** tutti i dodici slot
  preservano vista di partenza e modalità F7 corrente.
- **F8, Invio**: su Memory positions, Groups, MIDI CC, Custom Order e
  Copied parameters torna alla griglia FX Params **fuori da F7**, sul
  parametro, sulla copia o nel gruppo scelto. In Hidden parameters Invio
  non ha alcun effetto: Canc resta l'operazione per ripristinare.
- **F8, Default values, Invio**: usa lo stesso reset dell'intero plugin
  di Ctrl+Maiusc+Backspace. Solo se riesce, esce da F8 e torna in
  **Plugin Order**. ReaEQ con snapshot strutturale non implementato è
  protetto: nessun reset fittizio né uscita dalla finestra.
- **Ctrl+F** in e fuori F7: fra virgolette, ricerca per parole consecutive.
  Le parole iniziali devono corrispondere completamente e l'ultima può
  essere un prefisso: `"slot 1 fil"` trova `Slot 1 Filter` ma non
  `Slot 10 Filter`. Un'unica parola fra virgolette, come `"kick"`,
  richiede l'intera parola. Senza virgolette resta la ricerca per sottostringa.
- Le selezioni F7 filtrate mantengono i riferimenti alle occorrenze originali.
  I profili `.fx` e la memoria della sessione rimangono compatibili.

Le prove di compilazione avvengono **solo tramite GitHub Actions**.
Le verifiche statiche non sostituiscono il test effettivo con REAPER/OSARA/NVDA.

## TEST26 — Gruppi, ricerca filtrata e selezioni (storico, corretto da TEST27)

- **Ctrl+F1–Ctrl+F12**: 12 slot disponibili, inclusi Ctrl+F12 e Ctrl+Shift+F12. F12 **senza modificatori** è ora riservato a LReaParams e non attiva comandi (TEST27).
- Riaprire **lo stesso** gruppo restituisce la vista di partenza: Plugin Order oppure Custom Order e, se era aperto, l'editor F7; un altro Ctrl+Fn passa direttamente a un altro gruppo senza perdere il contesto originario.
- **Ctrl+F** confermato con Invio crea una vera griglia di risultati sia dentro sia fuori da F7. Le virgolette richiedono una sequenza di parole intere (ultima parola come prefisso se la ricerca contiene più parole); ad esempio `"slot 1 fil"` trova `Slot 1 Filter` ma non `Slot 10 Filter`. Tab riporta il numero dei risultati correnti. Esc fuori F7 cancella dapprima il filtro.
- **Alt+Maiusc+Frecce in F7** (correzione TEST27): visita solo celle selezionate, rispettando colonne e righe reali. Alt+Maiusc+Su/Giù si muove nella colonna; Alt+Maiusc+Sinistra/Destra salta alla colonna successiva/precedente con selezioni, mantenendo per quanto possibile la riga. Le selezioni nascoste dal filtro non vengono perse.
- Un gruppo non altera automaticamente l'ordine originale o quello personalizzato salvato.

Questa versione contiene verifiche **statiche**; nessun compilatore locale è stato eseguito.

## TEST27 — Correzione combinazioni F7 e riserva F12

- **Alt+Maiusc+Frecce**, solo dentro F7: naviga tra i parametri selezionati mantenendo la geometria della griglia. **Alt+Frecce da sole** non effettuano più questa navigazione e conservano il comportamento originale su Step e valori.
- **F12 da solo** non esegue azioni e non esce dalla finestra LReaParams: resta riservato a una funzione futura dell'estensione, senza inoltro all'aiuto OSARA.
- **Ctrl+F12 / Ctrl+Maiusc+F12** continuano a usare lo slot 12. **Alt+F10/F11/F12** e le combinazioni Maiusc correlate restano destinate ai watcher OSARA.

Verifiche statiche soltanto. La compilazione viene eseguita dall'utente tramite GitHub Actions.


## TEST28 — Serpentone F7: intervalli continui e bordi silenziosi

- **Maiusc+Pagina Su/Giù:** include tutte le celle attraversate nella colonna, non soltanto il punto di partenza e quello di arrivo. Un comando produce un solo annuncio.
- **Maiusc+Home/End:** seleziona/deseleziona dalla posizione corrente fino all'inizio/fine della colonna, inclusi gli estremi; non seleziona la porzione precedente al punto di partenza.
- **Maiusc+Frecce:** mantiene il comportamento del Lua: la prima pressione sul parametro inizia il tratto, le successive lo estendono e il percorso contrario ritira progressivamente la selezione. Se il parametro iniziale era già selezionato, il tratto lo deseleziona.
- Ai confini della griglia, ulteriori pressioni di selezione non pronunciano messaggi. Anche Alt+Maiusc+Frecce non annuncia l'assenza di una cella selezionata nella direzione richiesta.
- Le selezioni sono memorizzate per *occorrenza*, anche con parametri duplicati e ricerca filtrata; le selezioni di filtri precedenti rimangono conservate.

La semantica di Home/End resta quella corretta in TEST22 (Home all'inizio, End alla fine). La revisione e i test automatici sono statici: **nessuna compilazione locale**. Verificare in REAPER la lettura NVDA e il passaggio da una direzione all'altra del serpente.

## TEST29 — Selezione Ctrl+Home / Ctrl+End in F7

In **Edit F7**, Ctrl+Home seleziona tutti i parametri dal corrente al primo
dell'intera griglia, **Ctrl+End** tutti quelli dal corrente all'ultimo.
Ctrl+Maiusc+Home/End usa lo stesso intervallo al posto del precedente
"seleziona tutto". I parametri nella direzione opposta rispetto al punto
di partenza rimangono deselezionati. La selezione in altri risultati di una
ricerca filtrata viene invece conservata. Una volta raggiunto il bordo,
ulteriori pressioni sono silenziose. **Ctrl+A** continua a selezionare tutto.

Fuori F7, Ctrl+Home/End continua a spostare il focus senza selezionare.
Maiusc+Home/End seleziona all'interno della colonna (TEST28).
Nessuna compilazione locale: verificare il comportamento con REAPER/NVDA.

## TEST30 — Separazione Ctrl+Home/End e Ctrl+Maiusc+Home/End

Correzione alla TEST29, valida **anche dentro F7**:

- **Ctrl+Home:** si sposta al primo parametro della griglia, senza cambiare la selezione.
- **Ctrl+End:** si sposta all'ultimo parametro della griglia, senza cambiare la selezione.
- **Ctrl+Maiusc+Home:** seleziona il tratto dal corrente al primo parametro.
- **Ctrl+Maiusc+End:** seleziona il tratto dal corrente all'ultimo parametro.
- **Ctrl+A** seleziona tutti i parametri. **Maiusc+Home/End** resta limitato alla colonna.

La selezione continua ignora i parametri dietro la posizione iniziale e rimane
silenziosa al bordo. I filtri e le selezioni non visibili seguono la TEST29.
La TEST30 sostituisce la mappatura errata dei tasti descritta nella TEST29.
Nessuna compilazione locale; il funzionamento in REAPER/NVDA va verificato.
