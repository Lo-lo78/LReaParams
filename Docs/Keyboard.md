## TEST51 estesa — folder e cancellazione routing

- F1: `Ctrl+Invio` = toggle folder, conservando `Invio` per Value. Su traccia finale, prima la folder più interna.
- F2/F3: `Canc` = elimina esattamente il send/receive corrente (senza conferma, come nel Lua).
- F2/F3 su `MIDI merge`: Invio spiega che il valore dipende da MIDI source; non è un toggle indipendente.

## Aggiornamento TEST51 — Crea send e receive in F1

- **Ctrl+Maiusc+S**: seleziona tracce sorgenti, premi una volta per memorizzarle, poi seleziona destinazioni e ripremi: crea i send.
- **Ctrl+Maiusc+R**: seleziona destinazioni, premi una volta, poi seleziona sorgenti e ripremi: crea i receive.
- **Esc** durante l'operazione a due passaggi: annulla solo l'operazione in sospeso; **Tab** ne legge lo stato.
- **Maiusc+Spazio** e le altre scorciatoie F1 selezionano le tracce su ciascuno dei due passaggi. Fuori F1 Ctrl+Maiusc+S/R non crea nulla.

## 0.0.51 — Track Params F1/F2/F3 (prevale sulle precedenti TEST)

- **Invio**: entra/esce da Value sui parametri continui (toggle sui booleani). **Ctrl+Maiusc+V non è più assegnato**.
- **Ctrl+Alt+Su/Giù**: folder precedente/successiva in F1; **Ctrl+Alt+Pagina Su/Giù** non è più assegnato.
- **F2/F3**: Su/Giù percorre 14 campi; Sinistra/Destra cambia send/receive. **Alt+Su/Giù** modifica source/destination audio, modalità, tipo di send e MIDI; **Invio** apre Value per campi modificabili. **Tab** legge gli stati di memoria.
- Step, parlato e posizioni `.tp` invariati. [Dettagli](TEST51_TRACK_ROUTING_AND_SHORTCUTS.md).

## 0.0.50 — Track Params: Tab e selezione F1 (prevale sui riferimenti storici)

- **Tab**: contesto, parametro e valore, Step, annunci delle modifiche e preferenza MIDI, numero tracce selezionate su F1; **Ctrl+R non è più assegnato in Track Params**. I comandi di FX Params restano invariati.
- **Ctrl+A**: seleziona tutte le tracce visibili; **Maiusc+Spazio** / **Ctrl+Maiusc+Spazio**: seleziona/deseleziona la traccia del cursore.
- **Canc**: deseleziona solo la traccia del cursore; **Ctrl+Canc**: deseleziona tutte le tracce.
- **Maiusc+Su/Giù, Maiusc+Pagina Su/Giù**: selezione dell'intervallo mantenendo la colonna F1 (primo gesto: seleziona l'ancora secondo Lua).
- **Ctrl+Maiusc+Su/Giù**: estende la selezione dal cursore fino al bordo della lista.
- **Ctrl+Alt+Pagina Su/Giù**: trova la folder visibile precedente/successiva senza modificare la selezione.
- **Ctrl+Maiusc+V**: attiva/disattiva la modalità Value in F1. Invio e tutte le scorciatoie preesistenti per i parametri restano valide.
- Ctrl+T / Ctrl+Maiusc+T e Alt+Sinistra/Destra mantengono la persistenza dei profili `.tp`.
- F2/F3 rimangono verticali con 14 campi per colonna e sono da completare in TEST51.

## 0.0.49 — Track Params F1/F2/F3

- Alt+Sinistra/Destra: Step -10..+10 separato per parametro (salvato nel `.tp`).
- Ctrl+Backspace: azzera lo Step del solo parametro corrente.
- Ctrl+Maiusc+T: annunci del valore dopo l'editing On/Off (non zittisce NVDA+Su e la navigazione).
- Ctrl+T: preferenza persistente annunci MIDI CC secondo Lua; runtime MIDI Track non ancora presente.
- Ctrl+R: rilegge contesto, Step e stati di parlato.
- Riapertura: ultima sezione/parametro; F2/F3 ricordano la colonna se la traccia GUID è la stessa.

## 0.0.48 — Steps individuali e parlato CC

**Alt+Sinistra/Destra**: cambia lo Step del parametro corrente da -10 a +10.
Quando passi a un altro parametro, il suo Step torna al valore personalizzato
oppure a Step 0; la preferenza si ritrova anche dopo il riavvio di REAPER.
**Ctrl+Backspace** ripristina Grid 10 e Step 0 del parametro corrente.
**F3** comunica lo Step corrente.

**Ctrl+T**: abilita/disabilita il parlato delle variazioni *ricevute via MIDI
CC* per il singolo parametro. Default disattivo. Non spegne la voce NVDA
quando ti sposti normalmente nella griglia. In risposta al MIDI, legge solo
il valore del parametro corrente e nome+valore per gli altri parametri.

## 0.0.46.4 — Browser Master/Monitor a colonne

- **Destra:** Master → Monitor FX. **Sinistra:** Monitor FX → Master.
- Ogni colonna mantiene il proprio cursore; non si attraversano catene con i comandi verticali, la ricerca per iniziale o il riordino.
- Browser e griglia rimangono separati; Invio/Ctrl+P dalla colonna corrente apre l'FX effettivamente evidenziato.
- La colonna vuota resta riconoscibile e il ritorno all'altra colonna è possibile.
- Verifica reale rimandata a GitHub Actions e REAPER/NVDA. Nessuna compilazione locale.

## 0.0.46.3 — Browser Master / Monitor FX

**Ctrl+P** apre soltanto gli FX della catena da cui stai navigando: Master FX oppure Monitor FX. Nel browser **Su/Giù e Ctrl+Su/Giù** navigano nella catena, **Pagina Su/Giù** salta cinque FX, **Ctrl+Maiusc+Su/Giù** sposta realmente un FX nella stessa catena. **Sinistra/Destra nella 0.0.46.3 non cambiava tra Master e Monitor; dalla 0.0.46.4 cambia colonna**. Nella griglia, Ctrl+Su/Giù percorre soltanto la catena attiva. Per cambiare colonna nel browser, usa Destra da Master o Sinistra da Monitor. Ctrl+Maiusc+D continua ad agire globalmente sui Delta Solo.

## 0.0.46.1 — Browser FX e navigazione Take

- Ctrl+P: passa dal browser FX interno alla griglia e viceversa.
- Browser: Su/Giù, Pagina, Home/End, iniziali, Tab, Invio; sul Master
  Sinistra/Destra passa fra Master FX e Monitor FX.
- Browser: Ctrl+B bypass; Ctrl+Alt+B Offline On/Off; Ctrl+D Delta Solo On/Off dell’FX evidenziato; Ctrl+Maiusc+D disattiva tutti i Delta Solo del progetto; Ctrl+Maiusc+Su/Giù riordina.
- Ctrl+Sinistra/Destra: item con Take FX precedente/successivo.
- Ctrl+W: da Take FX ai Track FX della stessa traccia.
- Ctrl+Pagina Su/Giù: non intercettato da LReaParams, libero per uso futuro. Per cambiare traccia con FX usare Ctrl+Maiusc+Su/Giù.
- Ctrl+Maiusc+F: mostra FX Chain nativa. Alt+Maiusc+F: browser nativo FX.
- Le scorciatoie precedenti (Ctrl+Su/Giù, Ctrl+Maiusc+Su/Giù,
  Ctrl+Spazio e F7/F8) rimangono invariate fuori dal browser.

## 0.0.45 — Appunti dei valori FX

- Ctrl+C: copia valore corrente (fuori F7).
- Ctrl+V: incolla valore FX o snapshot completo valido (fuori F7).
- Ctrl+Alt+Maiusc+C: copia snapshot completo dello stesso FX, formato Lua.
- F7 Ctrl+C/X/V: modifica strutturale invariata.
- EDIT: appunti di testo normali.

## 0.0.44.5 — Lettere, numeri e punteggiatura

Carattere stampabile senza Maiusc: prossimo parametro con quella iniziale (wrap in avanti).
Maiusc+carattere stampabile: precedente parametro con quella iniziale (wrap all’indietro).
Restano disponibili le combinazioni di selezione F7 e tutte le scorciatoie degli editor.

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

F8: Left/Right cambia fra colonne non vuote; Up/Down sceglie voce; Enter carica fuori Edit; F7 carica in Edit dove consentito; Delete elimina. Hidden non ha Enter attivo. Default Enter apre una conferma con No iniziale: frecce selezionano, Y/N confermano, Esc annulla, F8 esce. Default Delete apre la stessa conferma Yes/No di Enter: No non modifica niente; Yes ripristina il Default e azzera le memorie di navigazione, conservando lo snapshot. Il reset Default F8 cancella anche le memorie di navigazione gestite, mantenendo lo snapshot.

I campi nativi permettono Ctrl+A/C/X/V, cursore e selezione Windows. L'editor numerico dichiara unità raw quando non dispone di formatter numerici monotoni; non digitare dB/Hz se viene annunciato Host raw units. Le unità ReaEQ specifiche sono disponibili sui Track FX; Take FX conserva il percorso generico come Lua.

F10 non ha funzione; F12 singolo riservato, Ctrl+F12 slot 12; Alt+F10/F11/F12 ai watcher OSARA. Track Params conserva la tastiera TEST30. Le funzionalità mancanti sono in Status.md.

0.0.43.4: Ctrl+Spazio invoca direttamente l’azione REAPER 40073 (Transport: Play/pause) e riprende dal punto di pausa.


## 0.0.44.3 — Navigazione rapida per iniziale (prima di 0.0.45)

Nella griglia FX Params (Plugin Order, Custom Order, gruppi, risultati filtrati
e editor F7), premere un carattere stampabile porta al **prossimo parametro
visibile che inizia con quel carattere**, seguendo la lista circolarmente.
Premendo `P` più volte si cicla per esempio tra `Pan`, `Portamento`, e
qualsiasi altro parametro che inizi con P; analogamente `1`, `#`, `(`,
`-` e altri caratteri di punteggiatura, dove presenti nelle etichette.
Le lettere sono confrontate senza distinzione tra maiuscole/minuscole.
Se non c'è corrispondenza, nessun annuncio e nessun cambiamento della posizione.
Il caso di un'unica corrispondenza rilegge il parametro anche se è già corrente.

La conversione usa `ToUnicodeEx` e la disposizione tastiera Windows corrente:
non si confondono i codici VK_OEM della punteggiatura con i caratteri digitati.
Le scorciatoie con Ctrl/Alt, il trasporto, gli editor di testo Windows,
Value, F8 e la navigazione Track Params non sono modificati.
La posizione raggiunta usa la stessa memoria di sessione della navigazione
ordinaria; in F7 le selezioni esistenti vengono conservate.

**Solo sorgenti:** compilazione esclusivamente con GitHub Actions.
Per il collaudo, provare una P ripetuta, numeri e punteggiatura su un plugin
con etichette corrispondenti; controllare anche F7 e un gruppo salvato.
