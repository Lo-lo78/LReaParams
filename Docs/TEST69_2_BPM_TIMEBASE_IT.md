# TEST69.2 — Protezione timebase automatica nell’azione BPM

La nuova azione `LReaParams: Detect BPM from selected audio item and set project tempo` non richiede impostazioni manuali della timebase. Dopo una stima BPM affidabile e immediatamente prima del cambio del tempo, forza sull’item analizzato la timebase **Time** (`C_BEATATTACHMODE=0`) e disabilita auto-stretch. Modifica timebase e BPM in un unico blocco Undo e annuncia soltanto `120 BPM`, sostituendo 120 con il valore misurato.

Se l’analisi non produce un BPM affidabile, non modifica né la timebase né il progetto. Gli altri item non vengono cambiati automaticamente. La timebase Time impedisce lo stretching dell’item, ma non corregge da sola un’eventuale fase iniziale sfasata rispetto alla griglia: questa funzione stima il tempo, non riconosce il primo downbeat.

Verificare in REAPER con un item inizialmente in Beats (position, length, rate), con tempo del progetto differente dal BPM reale del file. Dopo l’azione, confrontare posizione, durata e velocità e fare Ctrl+Z per verificare il ripristino. Non pubblicare questa versione TEST su ReaPack.
