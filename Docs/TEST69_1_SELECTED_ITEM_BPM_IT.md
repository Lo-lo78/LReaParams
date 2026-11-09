# TEST69.1 — Rilevamento BPM nativo (item audio selezionato)

Questa funzione è sperimentale e **non è parte della release pubblica 0.0.69**.

## Azione da assegnare alla tastiera

Nella lista azioni **Main** di REAPER cerca:

`LReaParams: Detect BPM from selected audio item and set project tempo`

ID stabile: `LREAPARAMSDETECTITEMBPM`.

Seleziona **un solo item audio** (non MIDI), poi richiama lo shortcut assegnato. Quando trova un BPM attendibile, LReaParams imposta automaticamente la timebase **Time** sull’item selezionato, disattiva l’auto-stretch e solo dopo cambia il tempo del progetto. Timebase e tempo costituiscono un’unica operazione Undo. Non sono richieste finestre o battiti da segnare manualmente. L'azione analizza fino a tre tratti dell'item con letture audio native a blocchi, quindi modifica il tempo corrente del progetto solo quando almeno due sezioni di un brano lungo danno risultati coerenti. All'esito positivo NVDA annuncia soltanto `120 BPM` (con il numero stimato). La modifica del tempo è annullabile tramite Undo.

## Limiti

- Intervallo: 55–210 BPM. Il rilevamento non è infallibile: half-time/double-time, tempo variabile, musica priva di impulsi ritmici e audio disturbato possono produrre risultati errati.
- Con incertezza, l'azione annuncia `BPM not reliable` e non cambia il progetto.
- Item inferiori a 7 secondi non vengono analizzati; la durata effettiva della lettura è al massimo 54 secondi, distribuiti nel brano.
- Legge il segnale pre-FX attraverso gli accessori audio di REAPER, non una stampa del mix master.
- **Attenzione:** l'azione modifica il tempo corrente di REAPER. Se la timebase di altri item è basata su beat, REAPER può spostare o stirare quegli item. L’item analizzato viene automaticamente protetto impostando **Time** prima del cambio BPM. Gli **altri item** non vengono modificati automaticamente: se seguono la timebase Beats, potrebbero spostarsi o stirarsi.
- La modifica dell'indice ReaPack e delle release storiche è esclusa.

## Prova di accettazione

1. Progetto vuoto; importa un brano a tempo costante (idealmente 120 BPM), anche con item inizialmente in timebase Beats. Seleziona l'item.
2. Richiama l'azione. Verifica annuncio `120 BPM` e che il campo BPM del progetto riporti 120.
3. Verifica che l’item selezionato resti alla stessa velocità, durata e posizione e abbia timebase Time; Ctrl+Z deve ripristinare insieme tempo e timebase.
4. Prova audio a 90, 100, 128, 150 BPM, silenzio e musica senza pulsazione, annotando gli errori.
5. Con due item selezionati deve annunciare `Select one audio item` senza modifiche.
6. Chiudi o cambia progetto durante il rilevamento: deve annullare senza impostare il BPM.
7. Verifica l'utilizzo di NVDA e OSARA senza blocco della finestra REAPER.

## Implementazione

Il rilevatore FFT e i test C++ sono standalone, senza dipendenze esterne. La registrazione dell'azione, il caricamento REAPER e la lettura sono completamente native. La parte di lettura viene distribuita nei callback timer del main thread, senza accedere alle API REAPER da un thread secondario.
