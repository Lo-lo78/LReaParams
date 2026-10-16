# LReaParams 0.0.43 — ReaEQ (source only, not compiled)

Base: 0.0.42.1. Le due azioni FX Params/Track Params restano distinte; Parameter Library NON è stata reintrodotta. Questa versione non compila localmente e non dichiara parità integrale con il Lua.

## Funzioni migrate

- Controlli virtuali con gli ID originali Lua: `-100000 - band*2` (Enabled), `-100001 - band*2` (Type), `-99998` (Target Band) e `-99999` (Band Action). `Compare` mantiene `-300000`.
- Plugin Order ReaEQ: Enabled, Type, Frequency, Gain, Bandwidth per banda; poi Target/Action, Compare prima degli ultimi parametri wrapper. Il caricamento degli ordini `.fx` legge anche gli ID virtuali; alias, gruppi, CC e nascosti possono quindi contenere i controlli supportati.
- Type: 11 voci in ordine Lua, con conversione esplicita fra numeri utente e valori raw non consecutivi di ReaEQ.
- Enabled: Invio attiva/disattiva direttamente, con lettura On/Off. Type e Target sono controlli a scorrimento. Target 0 = Add band, 1..N = Band N. Invio su Band Action aggiunge o rimuove fisicamente una banda.
- Il chunk di ReaEQ usa lo stesso modello prudente del Lua: 8 byte intestazione, 33 per banda, 32 finali, record di banda aggiunto identico al Lua. Non altera le altre bande; dopo la scrittura verifica il numero reale di bande ed esegue Undo REAPER; se la verifica fallisce tenta di ripristinare il chunk originale.
- Refresh dei parametri e dell'ordine dopo cambi strutturali, CC learn/fixed/pickup per i virtuali in background, controllo d'azione MIDI sul fronte alto, lettura da F8 e reset singolo Enabled/Type tramite snapshot strutturale se il numero bande coincide.

## Test su REAPER indispensabili

1. Carica **ReaEQ su una normale traccia**, preferibilmente in un progetto duplicato. Apri FX Params e verifica la sequenza di ogni banda. Con NVDA+Freccia Su controlla `Band 1 Enabled, On` e `Band 1 Type, Band`.
2. Su Band 1 Enabled premi Invio due volte. Deve dire Off e poi On. Su Band 1 Type prova Alt+Su/Giù, incluso Band, Band alt e Band alt 2, e controlla il suono.
3. Raggiungi ReaEQ Target Band, scegli Add band e premi Invio su Add Band. La quantità delle bande deve incrementare realmente e la nuova banda deve comparire nella griglia. Poi seleziona Band N su Target e usa Remove Band N, controllando che l'ultima banda non possa essere rimossa.
4. Verifica che parametri wrapper, automazioni Auto, CC e F7/F8 non puntino a bande errate dopo l'aggiunta o rimozione. Usa Undo REAPER per controllare che un'operazione strutturale sia reversibile.
5. Chiudi e riapri FX Params con un vecchio profilo `.fx` ReaEQ contenente ID virtuali negativi; controlla Custom Order, alias e gruppi. Prova Ctrl+Maiusc+Backspace solo su un progetto di prova.
6. Prova CTRL+Q e CC Learn su Type/Enabled solo dopo aver verificato i controlli da tastiera, e verifica che non ci siano salti di valore.

## Limiti noti

- Il comportamento dipende dalla disponibilità di `vst_chunk`, `BANDTYPE#` e `BANDENABLED#` nell'installazione REAPER. Se le API non rispondono, questa versione non può garantire la modifica delle bande.
- Gli adattamenti non monotoni del Lua per Frequency/Q e altri tipi speciali e gli adattatori ReaComp/ReaGate rimangono fasi successive: la 0.0.43 **non è un porting integrale di ReaEQ**.
- Un'operazione strutturale cambia gli indici fisici successivi: i profili che contengono vecchi ID fisici per gruppi/CC vanno verificati attentamente dopo modifiche alle bande, senza presumere una rimappatura semantica.
- I 19 test statici non provano compilazione C++, compatibilità API REAPER né accessibilità NVDA: tutto ciò spetta alla compilazione GitHub Actions e al collaudo.

## Correzione 0.0.43.1: ordine delle Custom Order storiche

Nel Lua, `reaeq_build_default_param_indices()` colloca per ciascuna banda Enabled, Type e subito dopo i tre controlli reali (Frequency, Gain, Bandwidth). Nella prima DLL 0.0.43 tale ordine era già usato nella Plugin Order, ma i profili `.fx` con Custom Order storiche venivano normalizzati aggiungendo in fondo gli indici negativi ancora mancanti. Di conseguenza NVDA trovava tutti gli Enabled/Type **dopo Global Gain**.

La nuova migrazione runtime inserisce ciascuna coppia Enabled/Type immediatamente prima del primo parametro reale presente della stessa banda. Non risistema la sequenza fisica che l'utente aveva intenzionalmente personalizzato. Gestisce inoltre il caso di una Custom Order salvata dalla 0.0.43 con tutti i controlli virtuali in un blocco finale, riposizionando anche Target Band e Band Action davanti ai globali. Se un utente ha deliberatamente spostato singoli virtuali, li conserva nelle posizioni personalizzate. Non sovrascrive il file `.fx` al semplice caricamento.

**Prova NVDA:** alterna Plugin Order e Custom Order con Ctrl+L su ReaEQ e verifica che per Band 1 NVDA annunci Enabled, Type, Frequency, Gain, Bandwidth; ripeti per tutte le bande e verifica che Global Gain sia dopo i controlli di gestione bande. Carica anche un profilo Custom creato prima della 0.0.43 e uno salvato dalla 0.0.43. Dopo aver usato F7, chiudi e riapri il navigatore e verifica l'ordine persistente. Le operazioni su valori ed FX state non sono cambiate.

## Correzione 0.0.43.2: false segnalazioni di Band Enabled/Type

La scrittura delle proprietà `BANDENABLED#` e `BANDTYPE#` non deve essere dichiarata fallita basandosi unicamente sul valore booleano dell'API `SetNamedConfigParm`. Dopo aver scritto, l'estensione rilegge la proprietà; se il valore è quello richiesto, il risultato è un successo anche se l'API ha restituito `false`. In caso di mancata conferma, viene letto il chunk ReaEQ per confrontare il valore effettivo della banda. Il messaggio `ReaEQ band update failed` resta soltanto se nessuno dei controlli conferma la modifica e la chiamata API l'ha rifiutata. La modifica non interferisce con il comando Add/Remove Band, già operativo nel collaudo dell'utente.

Prova: alternare Band Enabled da On a Off più volte; scorrere almeno tre Band Type, incluse varianti alt; verificare che il valore letto corrisponda al controllo di ReaEQ e non appaiano errori falsi. Quindi passare alla 0.0.44 solo dopo la verifica pratica. Sono disponibili controlli statici e C++ nel workflow GitHub Actions ma nessuna prova REAPER è stata eseguita qui.
