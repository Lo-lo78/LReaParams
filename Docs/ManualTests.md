## 0.0.46.5 — Delta Solo globale e Monitor FX

- [ ] Aggiungere un FX Monitor e attivare Delta Solo con Ctrl+D nel browser Monitor; premere Ctrl+Maiusc+D: deve disattivarsi e non essere più annunciato.
- [ ] Attivare Delta Solo su due FX Monitor; Ctrl+Maiusc+D deve disattivarli entrambi.
- [ ] Attivare Delta Solo contemporaneamente su un normale Track FX e su un Monitor FX: Ctrl+Maiusc+D deve disattivare entrambi.
- [ ] Ripetere Ctrl+Maiusc+D senza Delta attivi: annuncio breve `No Delta Solo` quando il wrapper permette di verificarlo.
- [ ] Verificare che Ctrl+D agisca ancora solo sull'FX evidenziato, senza cambiare colonna e che Master/Monitor restino separati per la navigazione verticale.

## 0.0.46.4 — Master e Monitor: passaggio orizzontale

- [ ] Con 3 Master FX e 2 Monitor FX, aprire Ctrl+P da Master. Su/Giù deve leggere soltanto i 3 Master, totale 3.
- [ ] Premere Destra: deve annunciare Monitor FX e uno dei 2 effetti Monitor (totale 2). Su/Giù deve rimanere nei Monitor.
- [ ] Premere Sinistra: deve tornare al Master FX precedentemente evidenziato. Ripetere il passaggio e verificare la posizione ricordata nella colonna Monitor.
- [ ] Sinistra già su Master e Destra già su Monitor restano silenziose.
- [ ] Riordinare Ctrl+Maiusc+Su/Giù da entrambe le colonne: l'altra catena resta invariata. Provare anche ricerca ciclica, bypass, offline e Delta Solo.
- [ ] Con una colonna vuota, verificare l'annuncio `Master FX. No FX` o `Monitor FX. No FX` e la possibilità di tornare alla colonna piena.
- [ ] Invio/Ctrl+P dopo il cambio di colonna apre la griglia del plugin evidenziato nella colonna corrente; Ctrl+Su/Giù nella griglia non attraversa le catene.


## 0.0.46
Vedi `Docs/TEST46_FX_CONTEXT_BROWSER.md` per l'elenco delle prove manuali in REAPER e NVDA.
## 0.0.44.4 — Persistent FX position (post-build manual test)

Open ReaComp, select Detector Highpass, close FX Params, quit and restart REAPER. Reopen ReaComp: it should restore Detector Highpass. Repeat on ReaEQ with virtual parameters; verify an earlier FX remembers its own last position after visiting another plugin. Confirm that F7, CC links, defaults and Auto announcements remain unchanged.

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

## 0.0.43.3 — FX Play/Stop e Play/Pause

Vedere `Docs/TEST43_3_FX_TRANSPORT.md` per i controlli di ripresa da pausa, autorepeat, F7 e campi EDIT. Sono prove manuali per REAPER/NVDA dopo GitHub Actions.

## 0.0.43.4 — Ctrl+Spazio da pausa

- [ ] Da FX Params Ctrl+Spazio avvia, la seconda pressione mette in pausa e la terza riprende **dallo stesso punto di pausa**.
- [ ] Provare anche in Value/F7/F8, confrontando con l’azione 40073 eseguita dalla TCP.
- [ ] Spazio rimane Play/stop; Maiusc+Spazio F7 seleziona e negli EDIT la barra spaziatrice inserisce testo.

## 0.0.43.5 — Diagnostica del doppio Ctrl+Spazio

- [ ] Con FX Params **chiuso**, da TCP: Ctrl+Spazio tre volte avvia, mette in pausa, riprende dalla pausa. Serve a confermare la configurazione REAPER.
- [ ] Con FX Params **aperto**, in Grid: ripetere e verificare gli stati effettivi di REAPER/OSARA (playing → paused → playing), senza ritorno al cursore iniziale.
- [ ] Ripetere in Value, F7 e F8. Ogni singola pressione deve produrre **un solo** cambio di stato.
- [ ] Tenere premuto Ctrl+Spazio: una sola azione, niente autorepeat.
- [ ] Spazio singolo = Play/Stop; Maiusc+Spazio in F7 = selezione senza influire sul trasporto.
- [ ] Ctrl+Spazio dentro un campo EDIT di ricerca/rinomina/numeri non deve essere convertito dalla DLL in Play/Pause.
- [ ] Chiudere FX Params: Ctrl+Spazio torna interamente alla gestione dell'Action List REAPER. Track Params non deve perdere le proprie scorciatoie.
- [ ] Provare con NVDA e OSARA attivi, e confrontare backend finestra nativa (predefinito) / SDK nelle impostazioni.

I controlli automatici **non eseguono** REAPER né simulano un evento Win32 reale; il risultato non va dichiarato verificato fino alla build GitHub Actions e al test manuale.

## 0.0.44 ReaComp/ReaGate

See `Docs/TEST44_REACOMP_REAGATE.md` for the eight manual keyboard/NVDA test cases. All require GitHub Actions and an installed REAPER DLL.

## 0.0.44.3 — Test rapidi iniziali
Vedere `Docs/TEST44_3_INITIAL_NAVIGATION.md` per il piano dettagliato di test di lettere, numeri, punteggiatura, AltGr, ripetizione, F7, filtri e gruppi. La verifica deve essere eseguita con la DLL compilata dall’utente.

## 0.0.46.2 — Browser: Delta Solo e Offline

- [ ] Da Ctrl+P, evidenziare un FX diverso da quello aperto prima. Ctrl+D deve cambiare Delta Solo **solo sull’FX evidenziato**, senza selezionare un altro profilo FX. Il browser deve annunciare `Delta Solo` quando acceso.
- [ ] Ctrl+Maiusc+D dal browser disattiva i Delta Solo di tutti gli FX del progetto, come dalla griglia. Con nessun Delta attivo, controllare il messaggio breve.
- [ ] Ctrl+Alt+B su Track FX e Take FX nel browser mette l’effetto Offline e riporta Online alla seconda pressione. L’annuncio segue lo stato reale di REAPER.
- [ ] Ctrl+Alt+B nella griglia salva prima la posizione del parametro, mette offline ed entra nel browser. Ctrl+Alt+B riporta online; Invio torna alla griglia sul parametro ricordato.
- [ ] Ripetere su Master/Monitor FX e su catena con più effetti. Non alterare l’FX limitrofo, i profili `.fx` né la memoria persistente.
- [ ] Ripetere Ctrl+B (Bypass), Ctrl+Maiusc+Su/Giù (riordino), Ctrl+P, Spazio e Ctrl+Spazio per rilevare regressioni. Ctrl+Pagina Su/Giù resta libero.

- [ ] Mettere offline **tutti** gli FX, uscire da FX Params e riaprirlo: deve aprire il browser e permettere Ctrl+Alt+B per riportarli online.

## 0.0.46.3 — Master e Monitor FX isolati nel browser

- [ ] Mettere 3 effetti Master e 2 Monitor, con nomi distinguibili. Aprire FX Params su Master, Ctrl+P. Tab/NVDA+Su deve leggere solo gli FX Master e il totale 3. Provare Su/Giù, Ctrl+Su/Giù, Pagina, Home/End, lettere ripetute e Maiusc+lettera: mai Monitor.
- [ ] Dal browser Master, premere Destra: passa alla colonna Monitor; Sinistra torna al Master. Ctrl+Maiusc+Su/Giù riordina soltanto FX Master; verificare la catena REAPER, Undo e il GUID dell'effetto evidenziato.
- [ ] Ripetere da Monitor FX: totale 2; solo Monitor. Fuori dal browser, Ctrl+Su/Giù si ferma al bordo della catena corrente (silenzioso), senza attraversare Master/Monitor.
- [ ] Verificare da ciascuna catena Ctrl+B, Ctrl+D, Ctrl+Alt+B offline/online, Invio, Ctrl+P e titoli NVDA+T. Gli stati e il profilo `.fx` devono rimanere collegati all'FX corretto.
- [ ] Con tutte le istanze di una sola catena offline, riaprire FX Params su quella catena; il browser deve consentire Ctrl+Alt+B per riattivarle senza attraversare l'altra.
- [ ] Ctrl+Maiusc+D rimane globale: cancella Delta Solo su tutto il progetto, inclusi FX dell'altra catena.

Tutti questi test richiedono la DLL compilata dall'utente tramite GitHub Actions; nessuna compilazione locale.
