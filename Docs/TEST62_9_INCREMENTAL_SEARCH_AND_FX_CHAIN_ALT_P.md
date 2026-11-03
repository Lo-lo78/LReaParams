# TEST62.9 — Ricerca incrementale + Alt+P contestuale FX Chain

**Base:** TEST62.8. Solo sorgente, build MSVC/Windows tramite GitHub Actions.

## FX Chain

- Nella **lista FX nativa** (control ID `1076`), con focus e `GetTouchedOrFocusedFX(1)` valido, **Alt+P** apre LReaParams FX Params per il plugin evidenziato.
- **P non viene intercettato dal ponte di LReaParams** nella lista: resta disponibile per la ricerca dei plugin di REAPER.
- **Alt+P fuori dalla lista FX non viene intercettato**: la normale azione di REAPER/OSARA non cambia.
- AltGr+P non vale Alt+P. Esclusi campi EDIT, finestre modali, plugin UI, menu, OSARA Shortcut Help e navigazione LReaParams già attiva.
- Il vecchio ponte dedicato a Ctrl+Shift+P e agli shortcut di FX Params assegnati in Main **non viene più usato nella lista FX**. La normale Action List in Main non cambia.

## Ricerca incrementale (1000 ms tra tasti fisici)

- Griglia FX Params, F7, Custom/Plugin Order e gruppi: caratteri consecutivi formano un prefisso. Cerca prima dall'inizio del nome, poi dall'inizio di qualsiasi parola (`FRE` trova `1 Frequency (Hz)`). Nomi Rename Param rispettati. Sono supportati anche cifre e punteggiatura iniziale.
- Track Params: pagina F1 cerca tra i nomi delle tracce; pagine F2/F3 solo nei 14 campi della colonna send/receive corrente.
- FX Memories e Track Memories: cerca soltanto nelle righe della colonna corrente; la selezione multipla non viene modificata e NVDA continua ad annunciare `Selected` per prima.
- Ripetendo una stessa lettera veloce si scorrono le corrispondenze. Dopo un secondo parte una nuova ricerca; un prefisso senza risultati si riavvia dall'ultima lettera. Maiusc mantiene il verso inverso nella griglia FX e nei due gestori delle memorie.
- La ricerca NON modifica né profili .fx/.tp né parametri DSP. Ctrl+F conserva la ricerca completa. I tasti con scorciatoie, le frecce e il cambio pagina interrompono il prefisso.
- Il tempo è quello del messaggio tastiera originario (`MSG.time` in REAPER e `GetMessageTime()` nel controllo di accessibilità), non quello del messaggio NVDA.

## Collaudo Windows con NVDA/OSARA

1. Nella FX Chain seleziona due plugin i cui nomi iniziano con P. Premi P: deve navigare nella lista, senza aprire FX Params. Premi Alt+P: deve aprire FX Params del plugin evidenziato.
2. Fuori dalla FX Chain premi Alt+P: deve fare soltanto l'azione che REAPER/OSARA aveva assegnato, mai LReaParams FX Params.
3. FX Params: su nomi Filter Cutoff, Filter Resonance, Frequency digita rapidamente `FI` o `FRE`. Su `1 Frequency (Hz)` prova `FRE`. Ripeti P da sola per scorrere P; prova caratteri `#`, `1`, `(`.
4. F7 con selezioni: ricerca senza deselezionare. Gruppi e Custom Order: verifica alias e invisibili; Plugin Order rimane originale.
5. Track Params F1: prova il prefisso di un nome traccia; F2/F3 non devono cambiare colonna o routing.
6. In entrambe le memorie digita in rapida successione il nome di una riga e verifica che la ricerca resti nella colonna; gli elementi selezionati iniziano con `Selected`.
7. Prova una pausa superiore a un secondo, Backspace, Ctrl/Alt, un editor numerico e l'OSARA Shortcut Help (F12). Non devono verificarsi digitazioni involontarie o doppie azioni.

**Verifica automatica:** `Testing/TypeAheadTests.cpp` (CTEST `typeahead`, eseguibile anche con g++ per il solo algoritmo), `Testing/test62_9_typeahead_alt_p_static.py`. REAPER/NVDA e compilazione DLL devono essere testati su Windows.
