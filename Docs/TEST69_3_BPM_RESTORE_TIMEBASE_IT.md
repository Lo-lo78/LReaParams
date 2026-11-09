# TEST69.3 – Ripristino della timebase originale

L’azione memorizza `C_BEATATTACHMODE` (incluso -1, cioè eredita dal progetto/traccia) e `C_AUTOSTRETCH` dell’item selezionato, imposta temporaneamente **Time** prima di leggere l’audio, e li ripristina alla fine sia in caso di successo sia in caso di interruzione.

Se rileva un BPM attendibile, prima del ripristino aggiorna il tempo del progetto; conserva esplicitamente anche posizione, durata e playback rate dell’item. Un solo Undo copre il cambio BPM. Quando non rileva un BPM, il tempo non viene cambiato.

**Prove fondamentali in REAPER:** provare separatamente le timebase originali Time, Inherited (-1), Beats position-only, Beats position/length/rate e Beats auto-stretch; verificare impostazione originale, durata, posizione, rate e Ctrl+Z. Ripetere su item con rate diverso da 1. Provare un brano senza pulsazione e l’interruzione con cambio selezione/progetto.

Il ripristino della timebase **non neutralizza futuri cambi di tempo**: un item rimesso in Beats potrà ancora seguire modifiche successive del BPM, secondo la normale logica REAPER.
