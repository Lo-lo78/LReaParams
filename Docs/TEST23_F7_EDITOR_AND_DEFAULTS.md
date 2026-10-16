> Documento storico TEST30. Per stato attuale e limiti prevalgono Status.md e FxCommandMatrix.csv.

# TEST23 — piano di prova NVDA (sorgente, non compilato)

1. In un progetto di prova caricare un VST senza profilo e verificarne l'istantanea Default Values in FX Memories. La cattura usa i valori presenti al primo accesso.
2. Cambiare un parametro; Backspace ripristina la sua istantanea. Ctrl+Maiusc+Backspace ripristina tutti; Ctrl+Backspace ripristina Grid 10, Step 0.
3. Alt+G -> Groups; Alt+M -> Memory positions, senza alternanza. Tab comunica Custom Order o nome del Group. Ctrl+F1 richiama Group, Ctrl+Maiusc+F1 salva in F7.
4. In F7 Ctrl+Invio entra in EDIT Unicode; provare accentate, NVDA+Freccia su, Home/End, selezione, incolla, Esc e Invio; nome del gruppo deve essere letto anche dopo caricamento.
5. In F7 Ctrl+F apre EDIT per la ricerca; digitare una stringa e Invio per filtrare; preservare la selezione di parametri esterni al filtro; Ctrl+F e Invio vuoto toglie il filtro.
6. Modificare la Custom Order, verificare Ctrl+Z e Ctrl+Y e il salvataggio dei profili.
7. Aprire F8 dall'editor, rientrare in F7 e verificare il ritorno del gruppo e della posizione; in F8 Default Values prova Invio.

**Limiti:** l'interazione reale con NVDA non è testabile in questo ambiente.
Reset strutturale ReaEQ non abilitato: richiede il ripristino di `vst_chunk` del Lua e rimappatura dinamica delle bande.
Undo/Redo è limitato all'editor F7 attualmente aperto, non è un comando Undo di REAPER.
Le altre funzioni avanzate F7/F8 (MIDI CC e Default rigenerabili da F8) restano per il prossimo ciclo.
