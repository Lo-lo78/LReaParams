# Aggiornamento TEST27 (0.0.28): il F12 SENZA modificatori ora resta libero e riservato a LReaParams, senza inoltro a OSARA e senza chiusura della finestra di navigazione. Ctrl+F12 e Ctrl+Maiusc+F12 mantengono la memoria 12; Alt+Maiusc+Frecce naviga i selezionati in F7. Le istruzioni storiche su F12/Alt+Frecce riportate sotto descrivono versioni precedenti e sono superate. Per il collaudo attuale: Docs/TEST27_KEYS_F12.md.

# TEST5 — Titolo reale per NVDA+T (sperimentale)

Versione: LReaParams 0.0.6 TEST5. Sorgente soltanto: compilare ESCLUSIVAMENTE su GitHub Actions.

## Obiettivo

Durante FX Params e Track Params, NVDA+T dovrebbe leggere il titolo della navigazione,
non il titolo standard di REAPER. La TEST5 crea, solo per la sessione di navigazione,
una piccola finestra Win32 **1 x 1 pixel fuori dal desktop** con un titolo reale.
La finestra e' un tool window, assente da Alt+Tab, non sovrapposta alla GUI del FX.
Quando l'utente esce, la finestra viene nascosta e il focus precedente viene ripristinato
solo se appartiene ancora a LReaParams (non viene sottratto a un collaboratore remoto).

La finestra NON cambia e NON sostituisce la GUI del plugin. Le modifiche avvengono
sempre attraverso le API REAPER; il collaboratore vedente continua a vedere il plugin.

**Attenzione:** perche' NVDA+T legga un titolo diverso, Windows deve portare davvero
questa finestra ausiliaria in primo piano. Questo cambia il focus, anche se la finestra
non e' visibile sul monitor. Cio' puo' modificare il comportamento di alcuni VST3,
del routing dei tasti e di OSARA. Non e' stato testato realmente in REAPER: e' una
verifica sperimentale, non una garanzia di funzionamento universale.

## Test da eseguire

1. Salva il progetto REAPER e crea una copia della DLL precedente prima di sostituirla.
2. Avvia FX Params su una traccia con un solo JSFX; premendo NVDA+T verifica che dica
   «LReaParams - FX Params - Grid», non il titolo del progetto REAPER.
3. Premi F1, F2: l'altezza della griglia deve diminuire/aumentare di una posizione.
   Prova Su/Giu', Sinistra/Destra, Ctrl+Home, Ctrl+End.
4. Premi Invio: NVDA+T dovrebbe leggere «LReaParams - FX Params - Value».
   Premi Escape: ritorna in Grid. Premi di nuovo Escape: chiude la navigazione.
5. Con due effetti, apri il browser e premi NVDA+T: «FX Browser»; Invio entra nel
   plugin selezionato; Alt+B torna alla scelta dell'FX.
6. Avvia Track Params: NVDA+T dovrebbe leggere «LReaParams - Track Params - Tracks - Grid».
   F1=Tracks; F2=Sends; F3=Receives. La disposizione orizzontale delle tracce resta invariata.
7. Premi F12 per OSARA Shortcut Help: la finestra ausiliaria viene chiusa e il tasto
   viene reindirizzato verso REAPER. **Verifica** che OSARA entri effettivamente in Help.
8. Testa NVDA+T piu' volte, Alt+Tab, un VST3 con GUI flottante e l'uso del mouse
   da parte di un collaboratore. Nessuna finestra/pixel deve coprire il plugin.
9. Fuori dai navigatori, NVDA+T deve leggere il titolo normale di REAPER.
10. Se la cattura o il focus non funzionano, nel menu Extensions > LReaParams
    disattiva «NVDA title window (1px)», quindi riavvia la navigazione.
    Il fallback usa l'intercettazione precedente e i titoli vocali OSARA.

## Limitazioni

- Il successo della compilazione GitHub Actions NON dimostra il comportamento di NVDA.
- Lo spostamento del focus in una finestra offscreen e' invasivo e potrebbe disturbare
  plugin con modalita' di input speciali.
- Se la finestra di titolo non puo' ricevere il focus, la DLL usa il vecchio
  comportamento (titolo parlato via OSARA ma NVDA+T legge il titolo della DAW).
- F12 e' passato al message loop di REAPER, ma il corretto attivarsi di Shortcut Help
  dipende dalle scorciatoie dell'installazione e va verificato in locale.
- I TXT e le memorie non sono stati modificati in TEST5.
