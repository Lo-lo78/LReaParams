> Aggiornamento 0.0.47: F8 Default Delete richiede conferma Yes/No, non
> cancella immediatamente lo snapshot. Per il comportamento corrente vedere
> `Docs/TEST47_F7_F8_COMPLETION.md`.

> Documento storico TEST30. Per stato attuale e limiti prevalgono Status.md e FxCommandMatrix.csv.

# TEST18 — FX Memories (azione indipendente + F8 del Lua)

Progetto sorgente **non compilato**. Il test deve essere eseguito dall'utente
con GitHub Actions su Windows/REAPER+OSARA+NVDA. **Usare un plugin e un
profilo di prova, dopo aver copiato gli `.fx` originali altrove.**

## REAPER Actions

- `LReaParams: FX Memories`
- ID stabile: `_LREAPARAMSFXMEMORIES`
- L'azione è separata da `LReaParams: FX Params` (`_LREAPARAMSFXPARAMS`).
  Non registrare `_LREAPARAMSFXMEMORIES_LREAPARAMSFXMEMORIES`: è un ID errato.
- Rimosso `(future)` dal nome e dal menu.
- Azione FX Memories apribile direttamente dall'Action List: naviga il
  plugin corrente (selezionato con le stesse regole di FX Params), senza dover
  essere già dentro F7. All'interno di FX Params, invece, F8 è disponibile in F7,
  come nel Lua; Esc/F8 da quella vista torna all'editor F7.

## Schermata FX Memories

Titolo NVDA+T: `FX Memories - traccia - plugin`. NVDA+Freccia Su rilegge
la colonna e la voce corrente. Le colonne seguono l'ordine del Lua:

1. Memory positions (solo slot salvati, numero reale 1–12).
2. Groups (nome, numero effettivo di slot e conteggio parametri).
3. Hidden parameters (nell'ordine originale del plugin).
4. MIDI CC (link letti dai campi `cc_link_v1::param::N`).
5. Custom order (singola voce, quando salvata).
6. Copied parameters (una voce per copia oltre la prima; identità della
   singola occorrenza, non soltanto del parametro).
7. Default values (snapshot già presente nel profilo).

Comandi: frecce SX/DX cambiano colonna (saltano quelle vuote), SU/GIÙ spostano
la selezione, Tab ripete la voce, Home va all'ultima voce della colonna,
End alla prima; Ctrl+Home va all'ultima voce dell'ultima colonna; Ctrl+End
alla prima della prima; PagSu/PagGiù scorrono della quantità influenzata
dallo Step; Alt+SX/DX varia Step -10..10; Invio carica; F7 carica e tenta
l'apertura dell'editor; Canc cancella; Esc/F8 torna indietro.

Quando si entra dall'azione autonoma, Esc/F8 chiude FX Memories e restituisce
il focus a REAPER; Invio su una voce caricabile passa a FX Params selezionando
quella memoria. Se nessuna memoria è presente, la vista annuncia
`Parameter Navigator. No memories`, resta chiudibile e non scrive file.

## Operazioni migrate

- **Memory positions**: Enter seleziona il parametro, Delete cancella lo slot.
- **Groups**: Enter carica il gruppo; Delete cancella gruppo e relativo nome.
- **Hidden parameters**: Enter o Delete rende nuovamente visibile il
  parametro; Enter lo seleziona nella griglia Custom.
- **MIDI CC**: lettura delle assegnazioni presenti; Delete rimuove il record
  del profilo e richiede a REAPER di azzerare il learn nativo, come Lua.
- **Custom order**: Enter la carica, F7 apre la modifica, Delete elimina
  soltanto la Custom order e torna a Plugin order, senza eliminare i gruppi.
- **Copied parameters**: Enter seleziona quella specifica occorrenza della
  Custom order; Delete rimuove soltanto quella copia.
- **Default values**: sono visibili, ma **il ripristino/la cancellazione NON
  sono migrati** (ReaEQ e altri plug-in richiedono i reset strutturali del Lua).
  Enter/Delete pronunciano un avviso e non applicano operazioni incomplete.

Le modifiche persistenti usano il medesimo `FxOrder::save()` della TEST17:
backup sotto `LReaParams/Backups/ProfileEdits`, verifiche di identità del plugin,
protezione in caso di modifica esterna del file, nessuna modifica dei vecchi TXT.
La memoria di posizione FX della sessione rimane indipendente dai profili.

## Verifica consigliata

1. Apri un plugin con 8 o più parametri, Ctrl+L, F7. Salva un Group 5 con
   più parametri, poi un Group 8: nella colonna Groups devono comparire
   **5 e 8**, mai 1 e 2 come falsi indici.
2. In Ctrl+M salva una posizione parametro usando Ctrl+Maiusc+F1.
3. Con Ctrl+C e Ctrl+V crea due occorrenze dello stesso parametro; nascondi
   un altro parametro con Ctrl+Canc.
4. Premi F8 dentro F7: verifica Memory positions, Groups, Hidden, Custom
   order e Copied parameters. Naviga e ricarica con Enter.
5. In Copied parameters usa Canc sulla **seconda** occorrenza; verifica
   che la prima e le altre copie non spariscano.
6. Con Canc in Hidden ripristina un parametro; con Invio su un altro Hidden
   verifica il ritorno alla griglia su quel parametro.
7. Da F8 usa Esc per tornare esattamente a F7 e prosegui con la selezione.
8. Esci da FX Params. Cerca nell'Action List `LReaParams: FX Memories` e
   avvia l'azione: si apre direttamente. F7 dalla Custom Order caricata
   riapre l'editor; Esc senza scelta riporta a REAPER.
9. Verifica `NVDA+T`, `NVDA+Freccia Su`, la sintesi di OSARA e il focus
   in cambio vista. Verifica che Track Params e slider Value siano invariati.
10. Controlla il `.fx` nativo e il backup; riavvia REAPER e verifica la
    persistenza di memorie/gruppi/copied/hidden.

## Limiti da affrontare dopo TEST18

- Default Snapshot completo: cancellazione con conferma, rigenerazione,
  restore dei valori e casi speciali ReaEQ.
- MIDI CC: il pannello rimuove la memoria e tenta la pulizia del learn REAPER,
  ma la gestione operativa in tempo reale del Lua CC non è migrata.
- Editor F7 del Lua: ricerca filtrata, gruppi speciali, editor completi
  e parametri virtuali rimangono parziali.
- Non è stata verificata la compilazione né la lettura reale da NVDA.
