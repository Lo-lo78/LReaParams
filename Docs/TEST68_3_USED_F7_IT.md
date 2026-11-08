# TEST68.3 — Usati anche in F7

La versione pubblica resta 0.0.68. Queste funzioni non modificano il formato dei profili .fx o l’indice ReaPack.

1. Modifica alcuni parametri in FX Params: vengono aggiunti a **Used (Usati)**.
2. Apri F7 e premi **Ctrl+Shift+L**: compare «Edit: Used», con i parametri Usati. Ripremi la scorciatoia per tornare al contesto F7 originale con la selezione originale. **Ctrl+L** può anche uscire da Usati.
3. Con **Shift+Spazio** seleziona singoli parametri, con **Shift+frecce** seleziona intervalli, con **Ctrl+A** selezionali tutti. I comandi F7 mantengono il loro significato.
4. Seleziona 2–3 parametri in Usati, premi **Ctrl+C**, poi **Ctrl+F1** (un gruppo esistente o vuoto da modificare) e **Ctrl+V**. Il gruppo deve contenere gli stessi parametri, nell’ordine della selezione. Puoi anche selezionare e usare direttamente **Ctrl+Shift+F2** per salvare un gruppo nuovo, se lo slot è libero.
5. **Ctrl+Delete in F7/Used** non elimina un parametro da Usati né modifica gruppi sottostanti. Torna in un gruppo per usare Ctrl+Delete come già previsto da F7. Fuori da F7, Ctrl+Delete in Usati continua a rimuovere l’elemento dalla raccolta.
6. Le selezioni in Usati e nel contesto F7 di origine restano separate. **Escape** e **F7** non devono danneggiare la posizione, i gruppi o la memoria di Usati.
7. Verifica con NVDA/OSARA le scorciatoie e il ritorno del focus; il test statico non sostituisce questa prova reale.
