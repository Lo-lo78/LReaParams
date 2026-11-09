# LReaParams 0.0.69 — TEST69.5, tempo map sperimentale

Questa versione aggiunge una seconda azione nativa in **Main**:

`LReaParams: Create tempo map from selected audio item`

La precedente azione BPM fisso resta disponibile, ma ora conserva i decimali
(con precisione di visualizzazione di tre cifre):

`LReaParams: Detect BPM from selected audio item and set project tempo`

## Uso

1. Lavora su una **copia del progetto**; preferibilmente un progetto vuoto con un solo brano audio.
2. Seleziona un unico item audio non MIDI, lungo almeno 7 secondi.
3. Assegna una scorciatoia alla nuova azione dalla lista Main.
4. Eseguila; non vengono creati item MIDI né marker di progetto intermedi.
5. Quando il risultato è sufficientemente affidabile, l'estensione crea direttamente i marcatori del tempo mediante l'API nativa REAPER.
6. L'annuncio include il BPM di riferimento e il numero di marcatori creati. Per esempio: `128.152 BPM. Tempo map. 24 tempo markers`.

Il rilevamento legge tutto l'item tramite blocchi durante il timer dell'estensione, senza caricare un brano intero in un buffer PCM. Combina flusso spettrale in quattro bande, autocorrelazione locale, ricerca di fase, beat tracking con feedback e compressione dei marcatori. Una stima fissa usa un fit temporale su tutti i beat tracciati, invece di arrotondare il BPM a un intero.

Se il brano ha un'introduzione silenziosa, prova a correggere la fase del click con un tempo provvisorio nell'intro; il *primo movimento della battuta* (downbeat) non è però riconoscibile in modo affidabile da qualunque mix.

## Limiti e sicurezza

- **È un prototipo**, non una rete neurale né un sistema musicale infallibile.
- Può sbagliare su swing, terzine, battiti senza percussioni, musica fortemente sincopata o tempo libero. Salti di tempo ravvicinati possono causare piccoli disallineamenti.
- Se il progetto ha già più di un marcatore di tempo, non sovrascrive la mappa.
- Se REAPER riporta un tempo di marcatore diverso di oltre 12 millisecondi dalla posizione richiesta, viene eseguito Undo, anziché lasciare una mappa potenzialmente scorretta.
- La timebase e Auto-stretch dell'item sono memorizzati e ripristinati; posizione, durata e playback rate vengono protetti. **Gli altri item con timebase Beats possono comunque essere influenzati dalla tempo map**.
- Le variazioni nel click e l'allineamento delle battute vanno verificati all'ascolto. Creare marcatori in corrispondenza dei beat non garantisce automaticamente la corretta identificazione di battuta 1.
- I test portabili non verificano la gestione interna della tempo map di REAPER: è necessaria la compilazione MSVC e una prova reale in REAPER.

Nessun cambiamento ai profili, allo storico ReaPack, alle versioni pubbliche o all'installer 0.0.69.
