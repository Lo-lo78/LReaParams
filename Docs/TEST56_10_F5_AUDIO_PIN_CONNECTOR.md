# LReaParams 0.0.56 — TEST56.10 — F5 Audio Pin Connector

## Ambito

Prima migrazione nativa di F5 dal Lua originale. F5 si apre **soltanto da F4** sulla traccia/FX corrente, anche se non sono esposti parametri TCP. Non modifica FX Params o F1/F2/F3. F6 resta riservato al connettore MIDI futuro. Niente file, memorie o cartelle F5 aggiuntivi.

- Ogni **colonna** rappresenta un pin audio di ingresso o di uscita dell'FX corrente.
- Ogni **riga** rappresenta un canale audio della traccia, da 1 al numero corrente (`I_NCHAN`, 2..64).
- Ingressi per primi, uscite dopo. La riga parla, ad esempio: `Selected. Input 1 left. Receives from track channel 1` oppure `Output 2 right. Sends to track channel 2`.
- Lo stato delle singole connessioni è letto da `TrackFX_GetPinMappings` con entrambe le maschere a 32 bit; i cambi vengono applicati tramite `TrackFX_SetPinMappings`, poi verificati con un nuovo readback. Non si riscrive il chunk della traccia.
- L'istanza FX viene risolta dal **GUID prima di ogni lettura/scrittura**. Se viene eliminata mentre F5 è aperto, il navigatore esce senza scrivere su un altro FX.

## Comandi

| Tasto | Azione |
| --- | --- |
| F5 da F4 | Entra nel connettore pin audio dell'FX corrente |
| Su/Giù | Canale precedente/successivo del pin corrente |
| Sinistra/Destra | Pin precedente/successivo, conservando il canale |
| PagSu/PagGiù | Salta cinque canali nella stessa colonna |
| Home/End | Primo/ultimo canale del pin |
| Ctrl+Home/End | Prima/ultima cella dell'intera matrice |
| Invio o Spazio | Alterna la connessione selezionata |
| Canc | Scollega la cella, se collegata |
| Ctrl+Su/Giù | Cerca la successiva connessione attiva nella colonna |
| Ctrl+Sinistra/Destra | Cerca una connessione attiva nella stessa riga |
| Ctrl+Alt+frecce | Cerca linearmente connessioni attive |
| Tab o F5 | Legge informazioni complete sulla cella |
| NVDA+Su | Legge cella e stato attuale |
| F4 o Esc | Torna alla posizione e all'FX precedenti in F4 |

**Bordi silenziosi**: non si annuncia una cella già selezionata se l'utente insiste nella stessa direzione. Le azioni che cercano collegamenti attivi annunciano quando non ce ne sono.

## Sicurezza / limiti

- Niente modifica automatica del numero di canali di una traccia.
- Solo i pin audio normali di FX di traccia: niente pin MIDI (F6 successivo), Monitor/Take FX o routing audio multicanale oltre 64 canali.
- Operazioni modificanti registrate in Undo; confermate soltanto dopo readback.
- Non si modifica il file `.tp`, le associazioni CC Fixed, i profili o le memorie di F4.
- F5 riguarda una sola istanza FX corrente; i tasti di cambio traccia/FX vanno usati dopo il ritorno a F4.

## Test manuali con REAPER / NVDA

1. Aprire F4 su ReaEQ (o un FX con ingresso e uscita audio) e premere F5: NVDA deve annunciare il contesto della matrice.
2. Con Su/Giù verificare i canali; con Sinistra/Destra navigare input e output senza perdere la riga.
3. Su input 1/channel 1 premere Invio due volte: l'entrata deve disconnettersi e riconnettersi. Verificare anche nella finestra routing pin di REAPER.
4. Su output 2/channel 2 premere Canc; REAPER deve mostrare il bit disconnesso; premere Invio per ripristinarlo.
5. Provare Ctrl+S: non deve avviare un collegamento in due passaggi né modificare il routing. Usare invece Invio o Canc sulla cella corrente.
6. Controllare Ctrl+Up/Down, Ctrl+Left/Right e Ctrl+Alt+freccia su vari collegamenti attivi.
7. Uscire con Esc: F4 deve ritornare allo stesso parametro e allo stesso FX; nessun salto al TCP.
8. Riordinare l'FX tramite Ctrl+Pagina Su/Giù in F4, riaprire F5 e verificare che il nuovo indice non abbia cambiato il destinatario.
9. Provare un FX senza pin audio: deve annunciare `No audio pins` senza abbandonare F4.
10. Controllare che F1/F2/F3, MIDI Fixed/Floating, Ctrl+Maiusc+M e FX Params continuino a funzionare.

## Compilazione

**Non eseguire CMake, MSBuild, Visual Studio, CTest o build locali.** Il sorgente deve essere compilato esclusivamente tramite GitHub Actions. La verifica statica Python non compila codice. La riuscita dei controlli statici non prova l'esito della build MSVC né il comportamento del pin mapping in REAPER.

## Aggiornamento TEST56.10.1

Il Ctrl+S sperimentale del vecchio Lua è stato eliminato: non ci sono più stati di origine/destinazione pendenti. L’unica operazione di collegamento avviene direttamente sulla cella tramite Invio o Spazio; Canc scollega. Tutti gli altri comandi sono invariati.
