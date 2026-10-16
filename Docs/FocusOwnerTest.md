> Documento storico TEST30. Per stato attuale e limiti prevalgono Status.md e FxCommandMatrix.csv.

# Aggiornamento TEST27 (0.0.28): il F12 SENZA modificatori ora resta libero e riservato a LReaParams, senza inoltro a OSARA e senza chiusura della finestra di navigazione. Ctrl+F12 e Ctrl+Maiusc+F12 mantengono la memoria 12; Alt+Maiusc+Frecce naviga i selezionati in F7. Le istruzioni storiche su F12/Alt+Frecce riportate sotto descrivono versioni precedenti e sono superate. Per il collaudo attuale: Docs/TEST27_KEYS_F12.md.

# TEST6 — Focus della tastiera in LReaParams

Questa versione contiene soltanto codice sorgente. La DLL va compilata da
GitHub Actions. Usare un progetto REAPER di prova e salvare una copia della DLL
precedente prima della sostituzione. Riavviare REAPER dopo la sostituzione.

## Test prioritario (regressione segnalata in TEST5)

1. Seleziona una traccia con **un solo JSFX** e avvia FX Params dal menu.
   NVDA deve annunciare il parametro e rimanere nella finestra «LReaParams».
2. Senza aprire finestre diverse, premi **NVDA+T** più volte: deve annunciare
   `LReaParams - FX Params - Grid`, non il nome del progetto REAPER.
3. Premi Su/Giu, Sinistra/Destra e Tab: controlla che continuino a muovere il
   parametro senza ritornare nel TCP.
4. Premi F1 e F2: cambiano l'altezza della griglia. Premi Ctrl+Home e Ctrl+End:
   primo e ultimo parametro dell'effetto.
5. Premi Invio: passa a Value. Modifica un parametro: la GUI del plugin deve
   mostrare la modifica e **la tastiera deve restare in LReaParams**. Premi
   NVDA+T, poi Escape per Grid, poi ancora Escape per uscire.
6. Avvia FX Params con due effetti: il browser deve ricevere Su/Giu, Invio
   seleziona FX, Alt+B riapre il browser. NVDA+T annuncia il titolo aggiornato.
7. Avvia Track Params. Su/Giu cambia traccia; Sinistra/Destra cambia il campo
   orizzontale; F1/F2/F3 aprono Tracks/Sends/Receives. NVDA+T deve annunciare
   il titolo Track Params, senza riportarti nel TCP.
8. Durante un navigatore prova un tasto non assegnato: non deve chiudere la
   navigazione né eseguire accidentalmente azioni nel TCP.
9. Prova F12 di OSARA: il navigatore deve liberare la tastiera; verificare
   separatamente se Shortcut Help è stato attivato.
10. Prova Alt+Tab e un dialogo di REAPER: l'acquisizione tastiera non deve
    ostacolare l'altra applicazione né digitare dentro il dialogo.
11. Con la GUI del plugin aperta, controlla che resti visibile e che i suoi
    controlli grafici si aggiornino mentre usi LReaParams da tastiera.

## Se non funziona

Annota la **prima** azione che fa tornare nel TCP, il titolo letto da NVDA+T
subito prima e dopo, l'FX utilizzato e se il problema riguarda FX Params o
Track Params. Nel menu Extensions puoi disattivare «Lua-style keyboard window
(1px)» per confrontare con il backend della TEST4, ma ciò non conserva il
comportamento richiesto per la versione finale.

## Limiti della TEST6

- Non è stato eseguito nessun test di compilazione o runtime locale.
- OSARA, i VST3 con thread grafici diversi e la gestione di F12 richiedono
  prova su REAPER. Non è garantito che ogni scorciatoia NVDA raggiunga il
  navigatore: NVDA intercetta molti tasti prima della finestra attiva.
- I tre Lua originali non sono ancora stati migrati integralmente.
