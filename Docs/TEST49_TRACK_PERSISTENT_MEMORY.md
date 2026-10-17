# 0.0.49 / TEST49 — Track Params: memoria persistente per parametro

Progetto **solo sorgente**, derivato dalla 0.0.48. NON è stata eseguita
nessuna compilazione locale, CMake, MSBuild, Visual Studio o CTest nativo.
GitHub Actions compilerà MSVC x64 e avvierà `profile_tests`.

## Cosa è stato aggiunto

- L'attuale navigatore F1/F2/F3 viene conservato; le 14 righe verticali
  dei send/receive, il modello Grid/Value e le scorciatoie precedenti
  non sono stati ristrutturati.
- Step **separati per parametro**: F1 Volume, Pan, Width, ecc.; F2 e F3
  hanno preferenze indipendenti. Tutti i send della stessa pagina condividono
  l'impostazione di *tipo* parametro (es. `Sends.Volume`); non esistono
  ancora override specifici per singolo send.
- `Alt+Sinistra/Destra` modifica lo Step del parametro corrente da -10 a +10
  e lo salva immediatamente. `Ctrl+Backspace` azzera **solo** quello Step.
- `Ctrl+Maiusc+T` attiva/disattiva **gli annunci dopo l'editing** del
  singolo parametro (On per impostazione iniziale). Gli annunci di
  spostamento nella griglia, `NVDA+Su`, `Ctrl+R` e la lettura dei valori
  restano disponibili anche quando l'annuncio della modifica è Off.
- `Ctrl+T` memorizza la preferenza **Lua-compatible** per il parlato MIDI CC
  nelle sezioni `[CCSpeech.Track]`, `[CCSpeech.Sends]` e
  `[CCSpeech.Receives]`; il motore MIDI CC Track Params **non è ancora
  migrato**, quindi il gesto salva la preferenza ma non può ancora produrre
  annunci MIDI attivi. Eseguire una verifica dopo l'integrazione MIDI.
- `Ctrl+R` ripete il contesto completo, lo Step e i due stati di parlato.
- Ripristino all'apertura dell'ultima sezione F1/F2/F3 e del parametro
  relativo. La selezione corrente in REAPER ha sempre priorità sul track
  salvato. Su F2/F3 la colonna send/receive è ripristinata solo per lo
  **stesso GUID di traccia**; altrimenti inizia dalla prima.
- Salvataggio dell'ultima posizione anche in caso di chiusura indiretta
  del navigatore (conflitto di focus, cambio contesto o Action List).

## Dati e compatibilità

Percorso: `REAPER resource path/LReaParams/Tracks/Track CC Map.tp`.
Non viene generato un secondo file di memoria. Il `.tp` nativo è il
contenitore `LREAPARAMS_PROFILE_V1` esistente con payload Lua `Version=2`.
Le seguenti sezioni vengono aggiunte o aggiornate **senza ricostruire**
le sezioni CC esistenti:

```ini
[LReaParams.StepScales]
Track.Volume=-4
Track.Pan=2
Sends.Volume=-3

[LReaParams.ParameterSpeech]
Track.Pan=0
Sends.Volume=1

[LReaParams.NavigationMemory]
LastPage=F2
F1.Parameter=Track.Pan
F1.TrackGUID={...}
F2.Parameter=Sends.Volume
F2.TrackGUID={...}
F2.Column=1
```

`[CCSpeech.*]` mantiene le chiavi originali Volume, Pan, Mute,
PhaseInvert e valori `1` o vuoto. Non vengono mai registrati valori
Volume/Pan audio nei `.tp`, soltanto preferenze della UI e mapping.
L'output preserva tutte le sezioni sconosciute, CC originali, commenti e
terminazioni di riga esistenti; il nuovo file nativo è creato solo se
si salva una preferenza/posizione. Per ogni aggiornamento a un file
esistente viene conservato un backup SHA-256 in
`Backups/ProfileEdits/*.tp`. Se l’importazione del precedente `Track CC Map.txt` è ancora in corso,
il `.tp` non viene creato anticipatamente: le preferenze vengono salvate
soltanto dopo che l’importazione ha completato una copia identica.
Un profilo che cambia fuori dal navigatore
non viene sovrascritto: il salvataggio è rifiutato e la posizione
non può essere garantita.

## Prove suggerite in REAPER + NVDA/OSARA

1. Fare copia del proprio `Track CC Map.tp` e usare un progetto di prova.
   Aprire Track Params: su F1 impostare Volume Step -4, Pan Step +2,
   Width Step -6. Passare fra loro con le frecce; Ctrl+R deve leggere
   lo Step giusto, che va mantenuto anche riaprendo REAPER.
2. Su Pan usare Ctrl+Maiusc+T per spegnere Value speech, poi Alt+Su/Giù
   per modificarlo: non deve pronunciare la variazione. Le frecce di
   navigazione e NVDA+Su devono invece continuare a leggere il valore.
   Riattivare e verificare il comportamento inverso.
3. Provare F2: il campo Volume deve iniziare con uno Step indipendente
   da quello di F1. Impostare Step -3; provare F3 Volume Step +1.
   Cambiare colonna send/receive e uscire; riaprire sulla stessa
   traccia e controllare colonna, parametro e ultima sezione.
4. Cambiare traccia selezionata in REAPER: il navigatore **non** deve
   saltare automaticamente al track precedente; per send/receive il
   numero di colonna deve tornare al primo se il GUID non coincide.
5. Su Volume in F1 usare Ctrl+T (preferenza MIDI parlato); uscire e
   verificare `[CCSpeech.Track]` nel `.tp`. Non aspettarsi ancora una
   reazione MIDI: il runtime MIDI Track non fa parte di TEST49.
6. Usare Ctrl+Backspace per riportare lo Step del parametro corrente
   a 0; assicurarsi che gli altri Step restino invariati.
7. Verificare che il vecchio `[Track]` `Volume=canale,cc`, `[Sends]`,
   `[Receives]`, `[FXParams.Plugin]` e l'eventuale `[UnknownFuture]`
   siano identici, salvo la preferenza `[CCSpeech.*]` modificata
   intenzionalmente tramite Ctrl+T. Nessun `.pp` o Parameter Library.
8. Eseguire GitHub Actions e controllare compilazione e CTest. La
   verifica automatica comprende persistenza, backup, compatibilità
   CRLF, formato, conflitti di scrittura e indipendenza degli Step.

## Fuori scope

F4/F5/F6/F7/F8 del Lua, configurazione e funzionamento MIDI CC Track,
override step specifici di ciascun send, memoria per progetto completo,
editing avanzato routing. Saranno affrontati nelle release successive.
