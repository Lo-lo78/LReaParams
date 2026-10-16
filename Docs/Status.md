# Stato 0.0.44.1 — adattatori ReaComp/ReaGate

Aggiunti in C++ gli adattatori non audio dei parametri speciali di
ReaComp e ReaGate: detector, nomi, interruttori, filtro virtuale,
Custom Order e memorie. Non dichiarata equivalenza completa al Lua,
né eseguita una compilazione locale. Consulta TEST44_REACOMP_REAGATE.md.
Il trasporto Ctrl+Spazio della 0.0.43.5 è stato confermato funzionante
dall'utente; l'adattatore di 0.0.44 resta da collaudare.

# Correzione puntuale 0.0.42.1 — parlato CC e Auto

Questa revisione della 0.0.42 annuncia le associazioni MIDI sui parametri FX
anche fuori da F8, nell'ordine `parametro, valore. CC channel N CC M. Auto`.
L'informazione CC è letta in sola lettura dal profilo FX corrente o,
come fallback, dal learn MIDI nativo REAPER. Non indica se Fixed CC è
attualmente attivato: indica l'esistenza di una mappatura valida. Durante
Floating CC i link fissi sono taciuti come nella lettura del Lua.
`Auto` rimane visibile solo con envelope esistente e ACT=1.
Nessuna modifica alle associazioni o al MIDI in background.
Nessuna compilazione o prova REAPER/NVDA: per quelle usare GitHub Actions.

# Stato sorgente 0.0.42 — MIDI CC in background

La 0.0.42 mantiene l'annuncio `. Auto` della 0.0.41 e aggiunge **Ctrl+Q**: dopo il ritorno al focus di REAPER, il timer principale continua a elaborare i CC del contesto FX parcheggiato, anche quando il navigatore non è visibile. L'azione `_LREAPARAMSSTOPMIDIBACKGROUND` ferma esplicitamente il contesto. Consultare `TEST42_BACKGROUND_MIDI.md`. Il nuovo codice non è stato compilato o collaudato in REAPER.

Questo archivio amplia TEST30 su più fasi della roadmap. NON completa tutta la parità Lua. Non è stata eseguita alcuna compilazione locale, CMake configure, build o prova della DLL. I test C++ inclusi saranno eseguiti dal workflow GitHub Actions dell'utente. Le verifiche Python sono controlli di testo e formati, non provano la correttezza eseguibile del C++.

| Fase | Stato del sorgente | Limiti residui |
|---|---|---|
| 0: eliminazione terzo navigatore | Implementata: azione, dispatch, menu, formato e ramo importazione rimossi; enum per gli indici azione | File preesistenti ignorati, mai eliminati |
| 1: learn CC | Implementato per parametri fisici e Compare, primo CC nuovo, profilo, riassegnazione duplicati, rimozione learn nativo | Non copre i virtuali ReaEQ/ReaComp; colonna F8 legge e seleziona i link ma non è un editor MIDI completo |
| 2: fixed/pickup | Implementati Shift+C, persistenza flag, crossing/tolleranza 1/127, riarmo dopo modifica esterna, anti-jitter Lua; Gain ReaEQ esteso | Attivo anche dopo Ctrl+Q nel singolo contesto parcheggiato, con stop su cambio identità; nessuna polarità inventata (il link Lua salva canale e CC) |
| 3: Floating/parlato | Implementati Ctrl+Shift+C, capture, parametro corrente, pickup, ritorno fixed, Ctrl+T persistente per parametro, accorpamento parlato | Parlato limitato a un annuncio ogni 180 ms; sessione Floating conservata con Ctrl+Q, non ricostruita dopo una chiusura ordinaria o un riavvio |
| 4: automazione | Ctrl+Shift+A ACT/VIS, Ctrl+Shift+Alt+A solo FX corrente, Alt+F3/F4 nella griglia visibile, Undo | Griglia filtrata/gruppo limita la navigazione, mentre Lua può uscire verso la griglia completa; confermare Monitor FX nel runtime |
| 5: preset/numeri/ricerche | Alt+F1/F2; Ctrl+E vero EDIT con inversione dei formatter monotoni o unità raw dichiarate; storico 20 voci, import storico Lua in lettura, salvataggio Settings | Adattatori specifici non monotoni e unità variabili non coperti; i recenti si applicano al recinto corrente; alcuni gesti extra mancanti |
| 6: plugin speciali | ReaEQ: codec chunk, default strutturale, coda wrapper, Gain esteso, virtuali Enabled/Type/Target/Action, aggiunta/rimozione bande in sorgente (NON collaudate in REAPER) | Restano gli adattamenti completi per frequenze/Q e la verifica runtime dell’aggiunta/rimozione bande; ReaComp/ReaGate: adattatori del Lua introdotti in 0.0.44; collaudo runtime necessario |
| 7: Compare/default F8 | Compare virtuale -300000 prima dei tre wrapper, stato per progetto/traccia/take/FX GUID; snapshot normali o chunk ReaEQ; reset, F8 conferma No/Yes e rigenerazione default | ReaEQ Compare non include virtuali non ancora esposti; singolo reset rifiuta numero bande diverso; salvataggi concorrenti mantengono il controllo digest preesistente, non una transazione interprocesso completa |
| 8: F7/F8/contesti | Conservati i controller TEST30, selezioni, duplicati, filtri, gruppi, undo struttura; Compare accetta memorie/alias/CC senza mandare indici negativi al motore fisico | Non concluso audit semantico di tutte le 1109 funzioni Lua FX; persistono differenze rare da verificare |
| 9: consegna | Progetto completo, test statici, test C++ per Actions, matrice e guida | Compilazione Windows e collaudo REAPER/NVDA/OSARA NON eseguiti |

## Funzioni che rimangono esplicitamente non migrate

- Collaudare i nuovi virtuali ReaEQ e aggiunta/rimozione bande (0.0.43); completare i controlli speciali Frequency/Q e gli adattatori non monotoni del Lua.
- Adattatori ReaComp/ReaGate implementati in 0.0.44, ma richiedono collaudo REAPER e verifica con plugin/versioni reali.
- Clipboard snapshot completo Ctrl+Alt+Shift+C/Ctrl+V; copia/incolla valore fuori da F7.
- Browser FX interno completo, riposizionamento fisico FX in catena, navigazione item/take Ctrl+Left/Right, ritorno Take→Track Ctrl+W, Ctrl+PageUp/Down, apertura FX Chain/browser.
- Background MIDI Ctrl+Q implementato per un singolo contesto FX parcheggiato (richiede collaudo hardware); il trasporto Space/Ctrl+Space è presente nel navigatore FX; Ctrl+Space ora invoca 40073 in 0.0.43.4 (da collaudare), ma restano i marker globali e lo switch Ctrl+Tab verso Track Params.
- Compatibilità semantica totale con virtuali negativi dei vecchi profili: le voci non supportate sono conservate come record opachi in ordine, slot, gruppi e associazioni, senza esporle come controlli. Non è possibile modificarle finché manca il relativo adattatore; i backup conservano il precedente .fx.
- La persistenza dei profili preserva sezioni sconosciute, campi Extra e commenti; le sezioni gestite vengono riserializzate, quindi non conserva il posizionamento originale dei commenti ; le voci dinamiche non supportate sono conservate come record opachi.

## Differenze deliberate o conservate da TEST30

Ctrl+R ora apre lo storico Lua; la rilettura completa è su Ctrl+Shift+R. Track Params conserva Ctrl+R e il suo codice non è stato modificato. Alt+G/Alt+M, Ctrl+Shift+Up/Down e Ctrl+D mantengono il comportamento TEST30 autorizzato dall'handoff anche dove il vecchio Lua differisce. F12 singolo resta riservato, Ctrl+F12 conserva slot 12, Alt+F10/F11/F12 resta a OSARA. F10 e Ctrl+Tab non aprono una libreria. Il tasto P rimane assegnabile dall'utente.

Il pacchetto è un candidato sorgente da compilare e verificare: non va descritto come migrazione completa o DLL già funzionante.

- 0.0.43.1: correzione posizione di Enabled/Type nelle Custom Order esistenti di ReaEQ; richiede test NVDA sul vecchio profilo.

- 0.0.43.2: verifica scrittura ReaEQ Enabled/Type dopo il setter per evitare false segnalazioni `ReaEQ band update failed`; collaudo REAPER necessario.

## 0.0.44.1 source fix
Position recovery now accepts Lua aliases as well as original REAPER parameter names. The detector setter tries exact raw values first, then normalized writing only within a verified host range; debug readback captures unconfirmed high-value modes. Physical REAPER testing pending.
