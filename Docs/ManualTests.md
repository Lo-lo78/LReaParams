# Collaudo richiesto in REAPER, NVDA e OSARA

Tutte le caselle sono da eseguire dall'utente DOPO la build GitHub Actions. Non sono risultati ottenuti dall'assistente. Usare un progetto di prova e una copia dei profili.

1. [ ] Caricare sorgenti alla radice GitHub, eseguire Actions: audit, regressioni Python, build x64, CTest profiles/controls. Conservare il log completo.
2. [ ] Installare DLL in UserPlugins, riavviare REAPER. Controllare ID invariati FX Params/Track Params/FX Memories; nessuna azione del terzo navigatore.
3. [ ] Avviare senza cartelle dati: sono create soltanto Plugins, Tracks, Settings, Backups. Lasciare vecchi file .pp/Params e verificare byte/data invariati.
4. [ ] Importare un .fx/.tp storico e un TXT attivo; verificare backup, conversione, conservazione storico, cancellazione attivo solo dopo verifica. Provare conflitto e ripetizione.
5. [ ] Aprire plugin con NVDA/OSARA. Grid annuncia nome/valore navigando, Value usa slider nativo. NVDA+T legge contesto, NVDA+Up la riga. I bordi tacciono.
6. [ ] Ripetere i casi TEST18–TEST30: Ctrl+L, F7, Custom Order, alias Unicode, copie, gruppi, selezioni serpente (anche ritorno), Shift+Home/End/Page, Ctrl+Home/End e Ctrl+Shift+Home/End.
7. [ ] Alt+Shift+frecce raggiunge i soli selezionati mantenendo righe/colonne. Ctrl+F con virgolette distingue slot 1 da slot 10; il filtro non cancella selezioni.
8. [ ] F8 azione autonoma e F8 da F7 condividono profilo/FX. Enter esce da Edit tranne Hidden; F7 ritorna in Edit. Gruppi e copie mantengono posizione corretta.
9. [ ] Ctrl+Alt+C su parametro: muovere un CC, verificare canale/numero nel profilo. Il valore non deve saltare alla cattura. Muovere fino a raggiungere/attraversare il valore software: ora deve seguire.
10. [ ] Chiudere/riaprire REAPER: Shift+C torna allo stato salvato, il pickup riparte. Due FX con stesso nome su tracce diverse: cambia soltanto l'istanza attiva.
11. [ ] Imparare lo stesso CC su altro parametro: viene riassegnato, non controlla entrambi. Learn→Delete rimuove soltanto il target; Esc non modifica il link. Verificare anche F8 MIDI CC Delete su parametro nascosto e Compare.
12. [ ] Modificare da tastiera/mouse/automation/preset dopo l'aggancio: la manopola deve riagganciare senza salto. Provare estremi 0/127, crossing in entrambe le direzioni e piccoli tremolii.
13. [ ] Floating segue il parametro corrente; cambio parametro richiede pickup; spegnimento recupera fixed salvato. F8/ricerca/numeri non devono muovere parametri. La chiusura ordinaria ferma il motore; **Ctrl+Q** mantiene il controllo MIDI sul solo FX parcheggiato (TEST42).
14. [ ] Ctrl+T abilita soltanto quel parametro; stesso valore formattato non viene ripetuto; movimenti rapidi producono parlato accorpato senza doppie letture.
15. [ ] Ctrl+Shift+A sul parametro fisico: ACT e VIS cambiano, punti e automation item restano. REAPER Undo ripristina. Ctrl+Shift+Alt+A riguarda soltanto l'FX aperto. Alt+F3/F4 usa la vista corrente.
15a. [ ] TEST41: creare un envelope sul parametro Cutoff, attivare ACT, raggiungerlo con Alt+F3/F4 o frecce; l’annuncio e NVDA+Freccia Su devono dire `Cutoff, valore. Auto`. Disattivare ACT conservando l’envelope: il suffisso Auto deve sparire. Con Alt+Frecce modificare il valore: si sente solo il nuovo valore. Ripetere su Track FX, Take FX, Master/Monitor e F7. Verificare che un parametro senza envelope e Compare non dicano Auto.
16. [ ] Alt+F1/F2 cambia preset restando sull'FX; provare preset con numero parametri variabile. Verificare riarmo pickup e titolo/riga.
17. [ ] Ctrl+E: EDIT focalizzato, testo selezionato, copia/incolla e cursore reali; Esc e secondo Ctrl+E annullano. Provare numeri fuori range, NaN, decimali e plugin con formatter non numerico: raw deve essere dichiarato.
18. [ ] Ctrl+R apre recenti, Delete rimuove, Enter filtra; secondo Ctrl+R/Esc ritorna senza cambiare recinto. Riavvio conserva lo storico; Ctrl+Shift+R legge contesto. Track Ctrl+R resta uguale.
19. [ ] Compare: primo movimento arma; cambiare parametri, passare a Original e Edited; nessuna contaminazione fra istanze o progetti. Backspace disarma. Cambiare layout e verificare rifiuto dello snapshot ordinario senza scritture.
20. [ ] ReaEQ Track FX: CC/tastiera/numeri su Gain oltre +12 fino a +36.1 dB e -inf. Verificare banda giusta, tipo invariato, audio e lettura uguali al Lua. Provare numeri Frequency/Bandwidth e documentare differenze per tipi particolari.
21. [ ] Default ReaEQ creato a N bande: cambiare N dal pannello nativo, riaprire navigatore e fare reset globale/F8. Devono tornare struttura, suono e Bypass/Wet/Delta. Singolo Backspace deve rifiutare strutture diverse senza applicare indici vecchi.
22. [ ] F8 Default Enter: No iniziale, Esc/N non cambiano nulla; Yes ripristina e ritorna Plugin Order. Delete→Enter/F8 salva nuovo default. Verificare backup e memorie cancellate correttamente.
23. [ ] Ripetere valori/preset/CC/envelope su Master, Monitor e Take FX, su Custom Order con copie e profili importati.
24. [ ] P assegnata nella Action List, Ctrl+Shift+P nella FX Chain, slot Ctrl+F12 e watcher Alt+F10/F11/F12. Testare tutte le funzioni Track Params TEST30.
25. [ ] Leggere le lacune in Status.md: nessun collaudo può concludere parità Lua finché quelle funzioni non sono migrate.

26. [ ] TEST42: seguire l'intera sequenza in `TEST42_BACKGROUND_MIDI.md` (Fixed/Pickup/Floating/Learn dopo Ctrl+Q, TCP libera, Track Params, cambio progetto, stop tramite nuova Action List).
