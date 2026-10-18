# LReaParams 0.0.56 — TEST56.1: F4, griglia FX TCP

**Base:** TEST55.13 confermata funzionante in REAPER. **Consegna:** solo codice sorgente per GitHub Actions; niente compilazioni locali.

## Implementato

- `F4` da Track Params apre la griglia degli FX della traccia corrente, senza cambiare il suono.
- API ufficiali REAPER `CountTCPFXParms(project, track)` e `GetTCPFXParm(project, track, index, ...)`: si visualizzano **solo** i parametri esposti nei Track Controls (TCP), nell'ordine restituito da REAPER. Nessun parsing/chunk e nessuna esposizione arbitraria di tutti i parametri del plugin.
- Ogni FX possiede sempre l'intestazione, anche quando non esistono parametri TCP.
- `Sinistra/Destra` cambia colonna FX, conservando la riga finché esiste nel nuovo FX (altrimenti la limita).
- `Su/Giù`, `PagSu/PagGiù`, `Home/End`: navigazione verticale nella colonna FX corrente; bordi silenziosi.
- `Ctrl+Home/End`: primo/ultimo FX; `Ctrl+Su/Giù`: traccia visibile precedente/successiva con FX, mantenendo coerente il TCP di REAPER.
- `Tab`: nome FX, parametro TCP, valore formattato e posizione. `NVDA+Su`: solo intestazione oppure parametro/valore, senza ripetere il contesto.
- `Ctrl+Tab` verso FX Params, `Ctrl+Q` verso REAPER, `Ctrl+Maiusc+M` per Track Memories, `Spazio` e `Ctrl+Spazio` per trasporto: compatibilità con il dispatcher consolidato.
- `F1/F2/F3` o `Esc` ritornano alle altre sezioni senza terminare LReaParams. `Invio` in F1 sul campo `FX count` apre F4.
- Memoria della posizione F4 nel `.tp` del progetto (GUID della traccia, GUID FX e riga); nessuna sottocartella F4.
- La lista è aggiornata dalle API REAPER prima dei movimenti: modifiche esterne alla FX chain e ai controlli TCP non lasciano puntatori a vecchi parametri.

## Differimento volontario (TEST successive)

**TEST56.1 è intenzionalmente SOLO di lettura/navigazione**. Invio su intestazione o parametro lo segnala; non apre ancora lista completa, Value o editor.

La gestione della lista di tutti i parametri, l'aggiunta/rimozione dei controlli TCP, il valore/Step, alias, ordine personalizzato, FX bypass/move, MIDI e automazioni verranno nelle successive TEST56. Non devono essere dati per implementati.

F1/F2/F3, FX Params, MIDI e file `.tp` preesistenti non sono stati riprogettati. Nessuna nuova funzione Parameter Library.

## Prove REAPER/NVDA consigliate

1. Traccia con due FX, per esempio ReaEQ e ReaComp. Esporre 2 parametri del primo e 3 del secondo nei Track Controls.
2. Da Track Params, F4: deve annunciare l'intestazione del primo FX.
3. Giù: soltanto i parametri TCP di quel FX, nell'ordine reale, con valori formattati.
4. Destra: raggiunge il secondo FX senza reimpostare la riga se valida, altrimenti la limita.
5. Su/Giù alla prima e ultima riga: silenzio al bordo.
6. Tab e NVDA+Su: contesto completo contro riga breve.
7. Rimuovere esternamente tutti i TCP knobs da un FX: la sua intestazione rimane.
8. Aggiungere esternamente un parametro TCP: nella prossima navigazione deve essere leggibile.
9. Ctrl+Su/Giù fra due tracce con FX: la selezione REAPER TCP segue la traccia raggiunta.
10. Ctrl+Tab verso FX Params e ritorno: resta sulla stessa traccia, senza catena di un'altra traccia.
11. Esc torna a F1; Ctrl+Maiusc+M apre/chiude Track Memories. Nessuna modifica sonora.
12. Uscire da REAPER e rientrare nel progetto: verificare ripristino F4 e nessuna regressione F1/F2/F3.

I test di GitHub Actions sono **source-only** fino alla fase di compilazione MSVC; nessuna prova audio o accessibilità è stata eseguita localmente.
