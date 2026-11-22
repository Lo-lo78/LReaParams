# TEST75.3.7 – Solo Alt+S apre Cerca scorciatoia

Correzione puntuale rispetto alla TEST75.3.6: nelle Preferenze Ctrl+P, pagina Shortcuts (FX Params, Track Params, Render), **solo Alt+S** sposta il focus sul campo «Search by shortcut». Alt+D non è più un acceleratore della ricerca e non viene intercettato a questo scopo.

Dopo aver raggiunto il campo con Alt+S, rilasciare i tasti prima di interrogare un'altra combinazione. Dentro il campo, anche Alt+S e Alt+D sono soltanto dati da cercare, senza eseguire i comandi delle Preferenze. Fuori dal campo Alt+R continua ad aprire la conferma del ripristino; Alt+O e Alt+C continuano a funzionare come OK e Annulla.

L'eventuale Alt+D automatico della finestra **Render** non viene modificato: qui si parla soltanto del campo «Search by shortcut» delle Preferenze. Restano invariati Shift+F1, il comportamento di Esc, i tasti FX/Track e la logica di salvataggio OK/Annulla.

## Prova manuale

1. Aprire Ctrl+P > Shortcuts > Render. Premere Alt+S: il focus entra nella ricerca.
2. Rilasciare Alt+S, premere Alt+D: deve interrogare Alt+D, non spostare il focus e non attivare alcun pulsante.
3. Uscire dal campo e premere Alt+D: **non** deve rientrare nel campo ricerca.
4. Rientrare con Alt+S. Verificare Alt+1, Alt+2 e Alt+R e confermare che le ricerche valide non pronuncino «Shortcut not found».
5. Ripetere in Shortcuts > FX Params e Track Params; chiudere Ctrl+P con Esc e verificare il ritorno del focus.

Eseguire il controllo statico `python Testing/test75_3_7_only_alt_s_lookup_static.py`. La compilazione con MSVC e il collaudo NVDA/OSARA devono essere effettuati su Windows.
