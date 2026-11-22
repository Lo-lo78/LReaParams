# TEST75.3.3 – Protezione Alt+lettera nella ricerca e cattura delle scorciatoie

Correzione sulla TEST75.3.2, senza aggiornare la versione ufficiale di LReaParams.

## Correzione

- In Ctrl+P > Shortcuts, con il focus sul campo «Search by shortcut», **Alt+S**, **Alt+O** e **Alt+C** vengono interrogati come combinazioni, non attivano rispettivamente Reset section, OK e Cancel.
- Prima che Win32 possa interpretare gli acceleratori della finestra, la coda messaggi invia i tasti ai campi di ricerca o cattura direttamente, senza tradurli in caratteri di sistema. È protetta così anche l'assegnazione di Alt+lettera a un controllo, senza che il pulsante corrispondente venga premuto per errore.
- Se la combinazione è presente, la ricerca seleziona la voce nell'elenco. Se non è presente, annuncia «Shortcut not found in this section» e non sposta la selezione.
- Al di fuori dei campi di ricerca/cattura, gli acceleratori dei pulsanti rimangono invariati.
- Tab/Shift+Tab continuano a spostare il focus. Alt+Tab rimane di sistema. Escape nel campo di ricerca mantiene il precedente comportamento di Annulla.
- Nessun cambiamento a script push, workflow GitHub, indice ReaPack e precedenti release.

## Prove manuali Windows / NVDA / OSARA

1. Apri Ctrl+P, scegli Shortcuts > Render e focalizza «Search by shortcut». Interroga Alt+S, Alt+O e Alt+C, anche se non trovate. La finestra non deve chiudersi e non deve comparire il dialogo di ripristino.
2. Verifica una scorciatoia esistente: deve selezionare soltanto la relativa voce.
3. Quando la scorciatoia non è presente, selezione dell'elenco e focus devono rimanere invariati.
4. Entra nella cattura con Invio su una voce e prova una delle combinazioni Alt+S / Alt+O / Alt+C per assegnarla. Non devono attivarsi pulsanti.
5. Fuori dai campi di ricerca/cattura, verifica che Alt+S apra la conferma Reset, Alt+O confermi e Alt+C annulli, come prima.
6. Ripeti la ricerca in Shortcuts > FX Params e Shortcuts > Track Params; verifica Ctrl+Alt+Shift+lettera, Tab/Shift+Tab e il ritorno alla finestra Render dopo la chiusura.

La compilazione MSVC e le prove reali di focus e comportamento Windows vanno eseguite nel workflow GitHub/REAPER.

## Push sorgenti

Dalla radice del clone Git esistente:

`Tools\push_lreaparams.cmd "Fix shortcut lookup Alt mnemonics in Preferences"`
