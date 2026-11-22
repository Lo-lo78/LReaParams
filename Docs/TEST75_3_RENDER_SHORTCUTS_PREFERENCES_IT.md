# TEST75.3 – Preferenze Render e scorciatoie personalizzate (sorgente sperimentale)

Deriva dalla TEST75.2. Non modifica il numero di versione ufficiale 0.0.75.
Compilazione prevista solo su Windows x64/MSVC (workflow GitHub esistente). Le verifiche statiche non sostituiscono il test con NVDA e OSARA.

## Funzioni

- Nella finestra Render originale di REAPER, **Ctrl+P** apre le Preferenze di LReaParams. Il focus viene riportato al controllo Render di partenza alla chiusura.
- In `Shortcuts > Render`, vengono elencati i controlli **visibili e identificabili** quando si apre Ctrl+P, inclusi quelli disabilitati. L'elenco si basa sulla scansione della configurazione corrente; non cambia formato, checkbox o pagina.
- La voce senza personalizzazione mostra **solo il nome del controllo** (campo scorciatoia vuoto, quindi automatico) e NON salva una lettera automatica. La voce già personalizzata rimane visibile anche quando non è attualmente disponibile.
- `Invio` su una voce: cattura una scorciatoia personale. Può essere F1, Ctrl+Alt+lettera, Ctrl+Alt+Shift+lettera ecc., salvo combinazioni riservate. Se la combinazione è già personalizzata, chiede conferma **No predefinito**. I tasti automatici non richiedono conferma.
- Gli Alt+lettera automatici **non vengono ricalcolati né redistribuiti**. Se personalizzi Alt+M, la sua intera sequenza automatica (anche Alt+Shift+M all'indietro) non viene più eseguita. Se personalizzi Ctrl+Alt+M, Alt+M resta invariato.
- `Canc` nell'elenco: rimuove solo la personalizzazione selezionata. FX/Track ripristinano la combinazione predefinita (rifiutando duplicati).
- Il campo `Search by shortcut`: premi una combinazione per raggiungere direttamente la voce associata. In Render comprende i tasti automatici ancora attivi, inclusi i cicli; ripetendo la combinazione, scorri le occorrenze. Se non trova nulla, annuncia e mantiene la selezione originale.
- Pulsante `Reset section...` prima di OK: domanda con **No preselezionato**. Sì ripristina soltanto la sezione scelta, senza chiudere Ctrl+P. Solo **OK salva** in Preferences.ini. **Cancel annulla** anche il reset confermato.
- Le personalizzazioni Render sono salvate separatamente in `[RenderShortcuts]`; il sistema di FX Params e Track Params conserva i suoi indici e le mappature già esistenti.
- Shift+F1 legge l'associazione reale, personalizzata o automatica. In modalità help non esegue nulla e non sposta il focus. All'esterno dei navigatori LReaParams, Shift+F1 resta all'azione REAPER.
- Una scorciatoia per un controllo di formato non presente avvisa dell'indisponibilità. Fuori dall'help può focalizzare la scheda Primary o Secondary pertinente, **senza cambiare automaticamente il codec**. Se il controllo esiste ma è disabilitato, non lo attiva.

## Prove manuali indispensabili

1. Apri Render con il comando 40015. Senza cambiare formato, usa Ctrl+P > Shortcuts > Render: verifica che i controlli attualmente presenti non mostrino alcuna scorciatoia personale, non una lettera automatica persistente.
2. Seleziona MP3, poi Secondary, riapri Ctrl+P: verifica che emergano i controlli MP3/Secondary **effettivamente esposti dalla tua versione di REAPER**.
3. Assegna Ctrl+Alt+M a un controllo, OK. Verifica che Ctrl+Alt+M sposti solo il focus; Alt+M e Alt+Shift+M rimangano ciclici come prima.
4. Assegna Alt+M a un controllo diverso, OK. Verifica che Alt+M sia esclusivo e non cambi tra gli elementi della vecchia sequenza. Alt+Shift+M non deve riprendere quella sequenza.
5. Entra in Shift+F1, interroga Alt+M e Ctrl+Alt+M, poi esci: nessun clic, rendering, modifica o movimento di focus; posizione identica all'inizio.
6. Riapri Ctrl+P e seleziona il campo di ricerca. Premi Ctrl+Alt+M, verifica la selezione della voce. Prova una combinazione inesistente: l'annuncio deve dire `Shortcut not found`, senza cambiare selezione. Per lettere automatiche cicliche non personalizzate, la ricerca ripetuta deve scorrere i controlli.
7. Premi Canc sulla personalizzazione Alt+M, OK: la sequenza automatica originaria Alt+M torna.
8. Ripristino sezione Render: prima premi No; nulla cambia. Poi conferma Sì ma premi Cancel: nulla cambia. Infine Sì e OK: tutte e sole le personalizzazioni Render scompaiono.
9. Ripeti Ripristino sezione su FX Params e Track Params: nessuna modifica all'altra sezione. Prova anche Canc su una sola scorciatoia.
10. Personalizza un controllo MP3/Secondary. Passa a WAV: deve rimanere modificabile nelle Preferenze anche se nascosto; il richiamo deve annunciare che non è disponibile ed eventualmente raggiungere la scheda pertinente, senza scegliere un codec.
11. Chiudi e riapri REAPER. Verifica la persistenza delle personalizzazioni e il reset.
12. Chiudi Render e torna nel TCP: Shift+F1 deve tornare all'azione REAPER; Ctrl+P e le combinazioni personali Render non devono essere catturate fuori Render.
13. Testa con formati diversi e controlli senza identificativi stabili: se non possono essere riconosciuti univocamente, il sistema deve evitare focus sul controllo sbagliato; segnala eventuali controlli assenti dall'elenco.

## Pubblicazione sorgente in clone Git esistente

Dalla **radice del clone**, dopo aver copiato i file modificati:

`Tools\push_lreaparams.cmd "Add Render shortcut customization, lookup and safe section reset"`

Non usare un push generico per questo progetto. Lo script preserva l'`index.xml` remoto, esegue rebase e non forza mai la pubblicazione. Non pubblicare una nuova release prima del test Windows/REAPER.
