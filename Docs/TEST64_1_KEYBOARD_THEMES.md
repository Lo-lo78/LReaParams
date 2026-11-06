# LReaParams 0.0.64 TEST64.1 — Keyboard, modalità utente per FX Params

**Stato:** TEST, non release stabile. Richiede build GitHub Actions e prova pratica con REAPER/NVDA/OSARA. About: 0.0.64 TEST64.1.

## Contesti indipendenti

Ogni *definizione di plugin* conserva 14 preferenze `.fx` (`[Extra]`: `lrp_keyboard_themes_v1`): **Plugin Order**, **Custom Order**, **Group 1–12**. Default Standard. **F4 senza modificatori** alterna soltanto il tema dell'ambiente attivo e lo salva immediatamente. Non sposta il parametro, la posizione, lo Step e non modifica la scelta degli altri contesti. Entrando in un gruppo/ordine/FX si applica automaticamente il suo tema memorizzato.

L'editor **F7 è SEMPRE Standard**: editing, selezione, ordine, copiar/incollar ed eliminazione non cambiano. La Keyboard è solo un'interazione di lavoro in FX Params, non un sistema di assegnazione tasti. Il gestore Windows, Track Params, FX Browser, memorie, ricerca, i campi EDIT e la conferma dell'automazione mantengono le funzioni preesistenti.

## 36 tasti per pagina

Assegnazione **deterministica secondo la posizione visibile**, inclusi duplicati del gruppo:

- `1234567890` = posizioni 1–10
- `QWERTYUIOP` = posizioni 11–20
- `ASDFGHJKL` = posizioni 21–29
- `ZXCVBNM` = posizioni 30–36

I tasti si usano senza Ctrl/Alt/Maiusc. Nella seconda pagina il tasto `1` seleziona la posizione 37, nella terza la 73, ecc. Se la posizione non esiste, il programma annuncia `Empty` senza cambiare selezione. `Alt+Freccia Giù` e `Alt+Freccia Su` vanno al successivo/precedente blocco di 36, selezionando **il primo parametro** del nuovo blocco. Ai limiti restano silenziosi. Passando Standard → Keyboard con F4 si resta sul parametro corrente (e quindi sulla sua pagina); non viene selezionato il primo del blocco.

## Valori e scorciatoie

In Keyboard: Frecce Su/Giù e Pagina Su/Giù modificano i valori (Pagina usa lo Step ampio), Frecce Sinistra/Destra regolano lo Step, Home/End applicano gli estremi, esattamente come l'attuale Value. La stessa logica gestisce anche la lettura differita dei parametri iZotope RX.

**Tutto il resto è condiviso** e immutato: Ctrl+B Bypass, Ctrl+D e Ctrl+Maiusc+D Delta, Ctrl+Pagina Su/Giù per lo spostamento dell'FX, Ctrl+Su/Giù cambia FX, Ctrl+Fn gruppi, Ctrl+L Plugin/Custom, Ctrl+F ricerca, Ctrl+E editor numerico, F7 editor standard, F8 A/B, MIDI, automazione, trasporto e tutte le altre combinazioni non ridefinite.

## Prova manuale consigliata

1. In Plugin Order, seleziona un parametro in posizione 20 e premi F4: deve restare selezionato (NVDA: `Keyboard`). Premi `Q` e verifica che venga selezionato l'undicesimo parametro; Alt+Giù su un plugin con almeno 37 parametri deve annunciare il parametro 37, e `1` deve richiamarlo.
2. Modifica valore e Step usando frecce / Pagina / Home / End, e premi F4: il parametro non deve spostarsi; in Standard deve riprendere la griglia/Value precedente.
3. In Group 1 scegli Keyboard; in Group 2 lascia Standard. Passa da uno all'altro con Ctrl+F1/Ctrl+F2. Entrambi mantengono il loro tema. Prova Plugin Order, Custom Order e un altro FX: le preferenze non devono propagarsi.
4. Da Keyboard apri F7: deve essere l'editor di sempre; esci e controlla che Keyboard ritorni nel contesto corrente.
5. In Keyboard prova Ctrl+B, Ctrl+Maiusc+D, Ctrl+Pagina Su/Giù, Ctrl+Su/Giù, Ctrl+F, Ctrl+E, F8, e i comandi di automazione/MIDI, su un progetto di test; verifica anche RX 11.
6. Chiudi REAPER, riaprilo e accertati che i 14 temi siano conservati nel profilo `.fx`. Apri un vecchio `.fx` senza chiave: tutto deve risultare Standard.

**Nota:** non creare un tag `v0.0.65` né una release stabile prima della verifica pratica. Il numero di progetto resta 0.0.64 per questa build di prova.
