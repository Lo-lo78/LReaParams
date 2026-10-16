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
