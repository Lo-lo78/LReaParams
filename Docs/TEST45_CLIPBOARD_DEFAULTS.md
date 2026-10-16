# 0.0.45 — FX Clipboard, valori e Default Snapshot

Base unica: sorgente 0.0.44.5. Nessuna compilazione locale eseguita.

## Cosa è stato aggiunto

* **Ctrl+C**, fuori da F7: copia il valore **normalizzato** (0–1) del parametro fisico corrente negli appunti Windows in formato `FXPARAM_VALUE_V1`. È una nuova comodità rispetto alla copia strutturale del Lua; funziona solo per parametri fisici, non per Compare/virtuali. Gli alias non influenzano il valore copiato.
* **Ctrl+V**, fuori da F7: riconosce prima i valori `FXPARAM_VALUE_V1` e poi gli snapshot completi Lua `FXPARAM_SNAPSHOT_V1`. Per un singolo valore usa l'attuale setter accessibile (adattatori detector/ReaEQ, Undo, annunci e pickup); per snapshot completi verifica plugin, conteggio e **nomi grezzi** dei parametri, prima di cambiare il progetto. Qualunque testo ordinario diverso dai formati FX viene ignorato.
* **Ctrl+Alt+Maiusc+C**: copia tutti i parametri FX nativi, con i nomi originali e precisione a 17 cifre, nello **stesso formato testuale e con le stesse sequenze di escape del Lua** (`PluginRaw`, `ParamCount`, righe `P`). Usa gli appunti di sistema (`CF_UNICODETEXT`). È disponibile nella griglia e anche in F7; non altera la Custom Order.
* **F7**: Ctrl+C/X/V rimangono operazioni strutturali; non sono reindirizzati al nuovo incolla dei valori. I controlli EDIT mantengono gli appunti Windows normali. F8 non riceve queste nuove scorciatoie.
* **Sicurezza**: niente snapshot su un plugin diverso, con conteggio diverso, con nomi diversi, indici duplicati, valori non numerici/non finiti o dati eccessivi. Paste completo con Undo REAPER, lettura dei valori originali e tentativo di rollback in caso di scrittura parziale. I valori virtuali negativi non vengono mai passati al setter fisico.
* **Default**: rafforzato il motore esistente di Ctrl+Maiusc+Backspace (usato anche da F8): verifica gli ID **0..N−1**, i limiti e la corrispondenza completa dei parametri prima di qualsiasi scrittura; prova a ripristinare i valori precedenti in caso di errore. ReaEQ mantiene il proprio ripristino strutturale tramite chunk. Backspace e Ctrl+Backspace mantengono il comportamento precedente.

## Prova manuale (da fare dopo GitHub Actions)

1. Copiare `Cutoff` con Ctrl+C, spostarsi su un altro parametro fisico, premere Ctrl+V. Confermare variazione e Undo.
2. Su un plugin di prova, premere Ctrl+Alt+Maiusc+C, modificare più parametri, quindi Ctrl+V: devono tornare i valori dello snapshot. Provare da Plugin Order e Custom Order.
3. Tentare di incollare lo snapshot su un plugin diverso: nessun valore deve cambiare.
4. Aprire F7, selezionare e usare Ctrl+C/V: devono essere copiate le **voci della griglia**, non i valori audio.
5. Aprire Ctrl+F e rinomina Ctrl+Invio: il normale copia/incolla di testo del campo EDIT deve restare operativo.
6. F8 Default: provare cancellazione e rigenerazione, conferma No iniziale e ripristino dopo aver modificato i parametri. Ctrl+Maiusc+Backspace deve seguire lo stesso motore di default e non deve toccare Grid/Step.
7. Verificare ReaEQ con una diversa struttura delle bande e con snapshot strutturale: non deve tentare un restore per semplici indici quando il numero di bande è cambiato.
8. Verificare i profili e le memorie persistent LastParam dopo riavvio REAPER, Midi CC e annunci CC/Auto.

## Limiti e avvertenze

* Il formato per un **singolo valore** `FXPARAM_VALUE_V1` è nuovo della DLL; lo snapshot completo `FXPARAM_SNAPSHOT_V1` è invece compatibile con il Lua. Si copiano i valori normalizzati, non necessariamente le stesse unità fisiche, perciò incollare su un parametro diverso è intenzionalmente un trasferimento proporzionale.
* Non è stato eseguito nessun test nativo Windows, nessuna compilazione C++, nessun collaudo REAPER/NVDA. I controlli Python sono **solo statici**. Il percorso di scrittura e il comportamento dei plugin richiedono una build GitHub Actions e una prova reale.
* Il rollback è un tentativo best-effort, non una transazione audio atomica. Se un plugin rifiuta una scrittura, usare Undo di REAPER e verificare il progetto.
* Il gestore F8 resta quello già presente nella 0.0.44.5. Il caso speciale dei Default strutturali ReaEQ non è stato riscritto.
