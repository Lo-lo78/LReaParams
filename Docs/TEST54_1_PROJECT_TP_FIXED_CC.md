# LReaParams 0.0.54.1 — TEST54.1: progetto `.tp`, Fixed CC persistente e trasporto uniforme

**Solo sorgente.** Compilare esclusivamente tramite GitHub Actions, quindi provare in REAPER con NVDA/OSARA e un controller MIDI. Il progetto non è stato compilato localmente.

## Nuovo percorso delle memorie Track Params

- Profilo nuovo: `REAPER resource path/LReaParams/Tracks/Projects/<Nome progetto>/<Nome progetto>_<hash percorso>.tp`.
- L'hash a 12 caratteri del percorso `.rpp` distingue progetti omonimi salvati in cartelle differenti. Il nome rimane leggibile e la directory del progetto è quella prevista dal vecchio Lua.
- Per i progetti mai salvati: `Tracks/Projects/Default/Default_Default.tp`. Come nel vecchio Lua, più tab non salvate condividono `Default`: **salvare il progetto prima di insegnare CC importanti**.
- Il vecchio `Tracks/Track CC Map.tp` e gli eventuali `.txt` storici sono usati **solo alla prima apertura di un progetto**, come sorgente di importazione. NON vengono sovrascritti, cancellati o spostati. Le preferenze dei progetti diversi non si sovrascrivono a vicenda.
- Il `.tp` per progetto conserva `[Track]`, `[Sends]`, `[Receives]`, `[CCSpeech.*]`, `[LReaParams.StepScales]`, `[LReaParams.ParameterSpeech]`, `[LReaParams.NavigationMemory]`, `[LReaParams.MidiSettings]`, e le sezioni esistenti sconosciute. `[FXParams.ProjectTrack]` è riservata alla futura migrazione F4. **F4 non è ancora implementato**: non sono creati nuovi file nella sottocartella `F4`. File storici F4 eventualmente già presenti restano intatti e non vengono eliminati.
- Il profilo rimane nel contenitore binario nativo `LREAPARAMS_PROFILE_V1` (payload testuale Lua `Version=2`), **non modificarlo con un editor di testo**. Le scritture sono atomiche con backup e controllo hash in `Backups/ProfileEdits`.
- Salvare il progetto con un nuovo nome/percorso cambia identità e perciò il nome del profilo: le memorie del vecchio percorso restano salvate, ma il nuovo progetto sarà inizializzato come nuovo. Non sono effettuati spostamenti impliciti dei dati.

## Fixed CC e annunci NVDA

- `Ctrl+Alt+C`: learn Fixed CC sul parametro corrente, salva subito l'associazione e `FixedEnabled=1` nel `.tp` del progetto.
- `Maiusc+C`: spegne o riattiva il Fixed CC **e salva lo stato**. Dopo chiusura, nuova apertura del navigatore o riavvio REAPER, la scelta rimane quella salvata.
- `Ctrl+Maiusc+C`: Floating CC rimane volutamente **temporaneo**, non è salvato.
- `Ctrl+Canc` su F1/F2/F3: elimina **solo** il CC fisso del parametro corrente; `Canc` in F2/F3 continua a eliminare il collegamento send/receive corrente, mentre `Canc` in F1 deseleziona la traccia. Per deselezionare tutte le tracce F1 usare ora `Ctrl+Maiusc+Canc`.
- `Ctrl+T`: parlato MIDI per parametro, indipendente dal parlato degli spostamenti con tastiera (`Ctrl+Maiusc+T`).
- Nella navigazione e in NVDA+Su la sequenza è **Parametro, valore, CC channel X CC Y, Auto**. Il CC è annunciato se associato, anche con Fixed momentaneamente Off. In F2/F3, frecce verticali non ripetono il nome della traccia collegata; le frecce orizzontali conservano la regola del nome traccia e numerazione Send/Receive duplicati.
- `Tab` continua a leggere contesto completo e Step; la relazione CC viene già pronunciata dopo il valore, non duplicata dopo lo Step.

## Trasporto condiviso FX/Track

- `Spazio`: Play/Stop; da Pause riprende come FX Params.
- `Ctrl+Spazio`: azione nativa Transport Play/Pause (`40073`), senza riavviare dalla posizione di editing.
- `Maiusc+Spazio`: selezione della traccia corrente in F1. La tastiera degli EDIT numerici e del filtro conserva la gestione nativa dello Spazio.

## Prove manuali consigliate

1. Aprire `Bass.rpp` e F1 Volume. `Ctrl+Alt+C`, muovere CC 7 sul canale 1. Verificare `CC learned`, e sulla griglia `Volume, <valore>. CC channel 1 CC 7` (più `. Auto` se attivo).
2. Attivare `Ctrl+T` sul parametro; muovere il CC, verificare il valore pronunciato. Uscire completamente da Track Params, rientrare: il Fixed deve funzionare **senza premere Maiusc+C**. Riprovare dopo il riavvio di REAPER.
3. `Maiusc+C` per disattivare; uscire/rientrare: deve restare Off. Riattivare con `Maiusc+C`, uscire/rientrare: deve restare On e usare la stessa associazione.
4. `Ctrl+Canc` su F1 Volume: il CC sparisce, ma le tracce rimangono selezionate. F2 Volume: `Ctrl+Canc` elimina il CC senza cancellare il Send. `Canc` elimina invece il Send corrente.
5. Controllare nello storage che `Track CC Map.tp` storico sia **byte-per-byte invariato** e che il nuovo `.tp` sia in `Tracks/Projects/Bass/`. Controllare Backup se eseguita una seconda modifica.
6. Aprire un secondo progetto chiamato anch'esso `Bass.rpp` ma da altro percorso: CC e Step del primo progetto non devono essere applicati al secondo.
7. Provare Spazio e Ctrl+Spazio in F1/F2/F3 e in FX Params; nessun doppio avvio né doppio annuncio. Maiusc+Spazio continua a selezionare la traccia F1.

**Limiti:** il motore Track MIDI resta attivo solo con Track Params aperto: il Ctrl+Q/MIDI in background per Track non fa parte di questa revisione. F4–F8 e il gestore `Track Memories` sono ancora in sviluppo; rinominare l'azione nella lista REAPER non significa renderne operativo il gestore. La compilazione MSVC e le prove runtime restano da eseguire sul sistema dell'utente.
