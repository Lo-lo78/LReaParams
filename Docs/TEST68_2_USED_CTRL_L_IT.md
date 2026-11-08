# TEST68.2 — Ctrl+L in Usati (Used)

Correzione mirata rispetto alla TEST68.1, senza nuova release ReaPack.

1. Aprire FX Params in un FX **privo di Custom Order**.
2. Premere Ctrl+Shift+L per entrare in **Usati**.
3. Premere **Ctrl+L**: deve tornare direttamente a Plugin Order (o al contesto di origine) annunciando il parametro originale. **Non deve dire “No Custom Order. Press F7”.**
4. Rientrare in Usati con Ctrl+Shift+L; premere ancora Ctrl+Shift+L: deve avere lo stesso risultato del punto 3.
5. Entrare in Usati provenendo da Custom Order o da un gruppo: Ctrl+L deve tornare precisamente all'ambiente e alla posizione di partenza.
6. Fuori da Usati, Ctrl+L conserva esattamente il comportamento storico fra Plugin Order / Custom Order e nei gruppi.
7. Rientrare in Usati, poi premere Escape; riaprendo lo stesso FX deve restare in Usati, come nella TEST68.1.
8. Verificare con NVDA/OSARA che Ctrl+L non ripeta annunci quando si tiene premuto il tasto.

Le preferenze e la raccolta Usati nel progetto non cambiano formato. L'About resta 0.0.68: questo archivio è una TEST, non una pubblicazione ReaPack.
