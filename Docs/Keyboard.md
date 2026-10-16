# Tastiera attuale

Le azioni FX Params, Track Params e FX Memories si assegnano nella Action List. P non è fissato nel codice. Nella lista FX Chain resta Ctrl+Shift+P contestuale.

| Gesto | Funzione FX Params |
|---|---|
| Frecce, Home/End, Page Up/Down | Griglia TEST30, bordi silenziosi |
| Enter, Esc | Grid/Value e ritorni contestuali |
| Space | REAPER Play/Stop; da pausa riprende subito (FX Params, F7, F8) |
| Ctrl+Space | REAPER Play/Pause (FX Params, F7, F8) |
| Shift+Space in F7 | Seleziona/deseleziona; non comanda il transport |
| Ctrl+Home/End | Primo/ultimo parametro, senza selezione |
| F1/F2, F3 | Altezza griglia, lettura Grid/Step |
| Alt+Left/Right | Step -10..10 |
| Ctrl+Up/Down | Cambio FX |
| Ctrl+Shift+Up/Down | Cambio traccia con memoria TEST30 |
| Ctrl+B, Ctrl+D | Bypass, Delta Solo TEST30 |
| Ctrl+Shift+D | Pulisce Delta Solo progetto, come TEST30 |
| F5/F6/F9 | Azioni REAPER preesistenti TEST30 |
| Ctrl+L | Plugin/Custom Order TEST30 |
| F7 | Editor struttura esistente |
| Shift+frecce/Home/End/Page | Selezione a serpente |
| Ctrl+Shift+Home/End in F7 | Selezione fino al bordo globale |
| Alt+Shift+frecce in F7 | Solo selezionati, geometria griglia |
| Ctrl+A/C/X/V/Z/Y in F7 | Selezione, copia/taglia/incolla, undo/redo struttura |
| Ctrl+Delete in F7 | Nasconde/rimuove secondo il recinto |
| Alt+G / Alt+M | Groups / Memory Positions |
| Ctrl+F1..F12 | Richiamo gruppo/posizione; stesso gruppo ritorna |
| Ctrl+Shift+F1..F12 | Salva gruppo/posizione |
| Ctrl+Enter in F7 | Rinomina gruppo o parametro, anche Compare |
| F8 / azione FX Memories | Gestore a sette colonne |
| Ctrl+Alt+C | Learn del primo CC nuovo; Esc o stesso gesto annulla |
| Tab / Delete durante Learn | Legge stato / rimuove associazione |
| Shift+C | Fixed CC on/off, pickup |
| Ctrl+Shift+C | Floating CC capture/off; al ritorno riprende fixed salvato |
| Ctrl+T | Parlato MIDI del parametro corrente |
| Ctrl+Shift+A | Attiva/mostra o disattiva/nasconde envelope corrente |
| Ctrl+Shift+Alt+A | Disattiva/nasconde envelope solo FX corrente |
| Alt+F3/F4 | Parametro con automazione precedente/successivo nella vista |
| Alt+F1/F2 | Preset precedente/successivo |
| Ctrl+E | EDIT numerico; Enter conferma, Esc o Ctrl+E annulla |
| Ctrl+F | Ricerca; Enter filtra, Esc ritorna |
| Ctrl+Up/Down nel campo ricerca | Richiama una ricerca recente |
| Ctrl+R | Storico: frecce, Enter applica, Delete elimina, Esc/Ctrl+R ritorna |
| Ctrl+Shift+R | Rilettura completa FX; NVDA+Up continua a leggere la riga |
| Backspace | Default del solo parametro; Compare si disarma |
| Ctrl+Backspace | Grid 10, Step 0 |
| Ctrl+Shift+Backspace | Ripristino valori default (chunk per ReaEQ) |

Compare appare prima dei tre wrapper REAPER. Il primo movimento lo arma; movimento verso il basso passa a Original, verso l'alto a Edited. I bordi non ciclano. Le modifiche a Edited vengono catturate prima del ritorno a Original.

F8: Left/Right cambia fra colonne non vuote; Up/Down sceglie voce; Enter carica fuori Edit; F7 carica in Edit dove consentito; Delete elimina. Hidden non ha Enter attivo. Default Enter apre una conferma con No iniziale: frecce selezionano, Y/N confermano, Esc annulla, F8 esce. Default Delete cancella la fotografia; Enter/F8 la rigenera dal suono corrente. Il reset Default F8 cancella anche le memorie di navigazione gestite, mantenendo lo snapshot.

I campi nativi permettono Ctrl+A/C/X/V, cursore e selezione Windows. L'editor numerico dichiara unità raw quando non dispone di formatter numerici monotoni; non digitare dB/Hz se viene annunciato Host raw units. Le unità ReaEQ specifiche sono disponibili sui Track FX; Take FX conserva il percorso generico come Lua.

F10 non ha funzione; F12 singolo riservato, Ctrl+F12 slot 12; Alt+F10/F11/F12 ai watcher OSARA. Track Params conserva la tastiera TEST30. Le funzionalità mancanti sono in Status.md.

0.0.43.4: Ctrl+Spazio invoca direttamente l’azione REAPER 40073 (Transport: Play/pause) e riprende dal punto di pausa.
