# LReaParams 0.0.56 — TEST56.7

## F4 — mini FX Params, solo parametri TCP

- L’intestazione non è più un elemento navigabile. La finestra indica il nome dell’FX corrente.
- Ogni FX presenta soltanto i suoi parametri TCP e i rispettivi valori, con griglia di altezza 8.
- Invio passa fra Grid e Value sul parametro corrente.
- **Alt+Invio** da qualsiasi parametro, o da un FX privo di parametri TCP, apre la griglia dei nomi completi dell’FX per aggiungere controlli TCP.
- Nella griglia dei nomi: Invio aggiunge e torna a F4; Ctrl+Invio aggiunge/rimuove restando nell’elenco. F1/F2 modificano l’altezza della griglia dei nomi.
- Canc in F4 elimina soltanto il controllo TCP selezionato, non l’effetto.
- Ctrl+Home/End sceglie il primo/ultimo parametro; Alt+Home/End cambia il valore.

## Comandi per spostare gli FX, uguali nei due navigatori

| Ambiente | Comando | Azione |
|---|---|---|
| Track Params F4 | Ctrl+Pagina Su/Giù | Sposta l’FX corrente nella catena |
| FX Params, griglia | Ctrl+Pagina Su/Giù | Sposta l’FX corrente nella catena |
| FX Params, browser | Ctrl+Pagina Su/Giù | Sposta l’FX selezionato nella catena |
| FX Params, browser | Ctrl+Maiusc+Su/Giù | Cambia traccia e aggiorna gli FX del browser |
| FX Params, griglia | Ctrl+Maiusc+Su/Giù | Cambia traccia |
| Entrambi | Ctrl+Su/Giù | Cambia FX nella catena, senza spostarlo |

Lo spostamento usa l’identità GUID dell’effetto, mantiene l’Undo e non attraversa le catene Master/Monitor. Il browser cambia traccia anche se gli effetti della nuova traccia sono offline, mantenendo la propria modalità.

## Collaudo con NVDA / REAPER (GitHub Actions compila)

1. F4 su FX con 10 parametri TCP: si entra sul primo parametro, mai sull’intestazione. Ctrl+Home/End, cambio colonna e Alt+Home/End.
2. F4 su FX senza TCP: Alt+Invio apre il selettore nomi; Ctrl+Invio aggiunge un parametro; il ritorno da Invio lo rende selezionabile direttamente in F4.
3. Ctrl+Pagina Giù e poi Ctrl+Pagina Su spostano realmente l’FX selezionato, con ritorno alla stessa identità.
4. FX Params griglia: Ctrl+Pagina sposta l’FX corrente; Ctrl+Su/Giù cambia effetto senza spostarlo.
5. FX Params browser: Ctrl+Maiusc+Su/Giù cambia traccia senza uscire dal browser, compresi FX offline. Ctrl+Pagina sposta l’FX selezionato.
6. Verificare che F1/F2/F3, memorie `.tp`, MIDI CC, ricerca ed editor F7 non siano alterati.

**Non eseguire CMake, MSBuild, Visual Studio o compilazioni C++ locali.** Compilazione e test nativi esclusivamente GitHub Actions.
