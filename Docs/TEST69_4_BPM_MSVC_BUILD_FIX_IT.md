# TEST69.4 — Correzione compilazione MSVC del rilevatore BPM

Il log di GitHub Actions della TEST69.3 segnalava errori C2143, C4430,
C2065 e C3861 in TempoAction.h e TempoAction.cpp. Causa: con
REAPERAPI_MINIMAL, le API aggiunte dal nuovo rilevatore BPM non erano
abilitate nel file centralizzato include/lrp/ReaperApi.h.

Questa TEST aggiunge le nove API richieste e include l'header centralizzato
in TempoAction.h. Un controllo statico viene eseguito nel workflow prima
della compilazione Windows. La logica di analisi, il ripristino della
timebase e la pubblicazione ReaPack sono invariati.

La compilazione MSVC deve comunque essere verificata in GitHub Actions.
