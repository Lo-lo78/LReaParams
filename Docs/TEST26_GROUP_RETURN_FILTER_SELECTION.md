> Documento storico TEST30. Per stato attuale e limiti prevalgono Status.md e FxCommandMatrix.csv.

# Aggiornamento TEST27 (0.0.28): il F12 SENZA modificatori ora resta libero e riservato a LReaParams, senza inoltro a OSARA e senza chiusura della finestra di navigazione. Ctrl+F12 e Ctrl+Maiusc+F12 mantengono la memoria 12; Alt+Maiusc+Frecce naviga i selezionati in F7. Le istruzioni storiche su F12/Alt+Frecce riportate sotto descrivono versioni precedenti e sono superate. Per il collaudo attuale: Docs/TEST27_KEYS_F12.md.

# TEST26 — Collaudo con REAPER, OSARA e NVDA

1. Da **Plugin Order**, aprire Ctrl+F1 (Gruppo 1), poi Ctrl+F2 (Gruppo 2), quindi ancora Ctrl+F2: ci si deve ritrovare in Plugin Order.
2. Da **Custom Order**, aprire Ctrl+F1 e ripetere Ctrl+F1: si deve tornare in Custom Order, NON forzatamente a Plugin Order.
3. Da **F7 Edit: Custom Order**, entrare in Gruppo 1, poi Gruppo 2, poi ripetere Ctrl+F2: si deve tornare in **Edit: Custom Order**, con selezioni ancora memorizzate.
4. Usare Ctrl+F12 e Ctrl+Maiusc+F12 in modalità Groups e Memory positions. **F12 senza Ctrl** deve continuare a essere inoltrato all'aiuto OSARA, non allo slot 12.
5. Da FX Params fuori F7, aprire Ctrl+F, scrivere `"slot 1 fil"` e confermare con Invio: Tab deve riportare il numero dei risultati; frecce/Home/End navigano **solo i risultati**. Non devono apparire Slot 10 e Slot 19. Usare Esc per ripristinare la griglia completa; dentro F7 il primo Esc rimuove il filtro senza uscire da F7. Ripetere con `"kick"` e con una ricerca senza virgolette.
6. Dentro F7, selezionare parametri in colonne diverse; usare Alt+Su, Giù, Sinistra, Destra: navigazione esclusivamente tra selezionati nella direzione della griglia. Ripetere con un filtro attivo: le selezioni fuori dai risultati rimangono selezionate quando si cancella il filtro.

**Limiti di verifica**: i controlli nel repository sono statici; UIA/NVDA e focus nella DAW possono essere accertati soltanto con la build GitHub Actions provata in REAPER. Nessuna build locale.
