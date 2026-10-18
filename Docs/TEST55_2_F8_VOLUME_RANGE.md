> Nota storica: in TEST55.5 **Ctrl+Maiusc+M** ha sostituito Alt+F8 (Track Memories) e F8 (FX Memories). Vedere [TEST55.5](TEST55_5_UNIFIED_MEMORY_SHORTCUT.md).

# TEST55.2 — Track Memories F8 e intervalli di Volume

Base: sorgente TEST55.1 con la correzione MSVC C3538. Nessuna compilazione locale.

## Track Memories — logica di FX Memories

- Alt+F8 da Track Params legge subito categoria e prima voce popolata. L'azione REAPER autonoma legge una sola volta l'intestazione tramite il lancio del navigatore, senza doppio annuncio.
- Sinistra/Destra attraversa le categorie, saltando quelle vuote; arrivati alla prima/ultima categoria popolata non viene ripetuta la voce.
- Su/Giù, Pagina Su/Giù e Home/End rimangono **silenziosi quando non cambiano riga**.
- Ctrl+Home/End raggiunge rispettivamente il primo/ultimo elemento delle categorie popolate; ai bordi è silenzioso.
- Tab legge il contesto completo, NVDA+Freccia Su ha nella riga di revisione categoria e voce, Esc torna a Track Params.
- I CC in memoria sono letti come `Channel 1, CC 7` anziché come `1,7`.
- Rimangono invariati Ctrl+Maiusc+F1…F12, Ctrl+F1…F12, le preferenze `.tp` e il focus Value/Grid.

## Ctrl+Maiusc+I — Volume range

- Su Volume F1/F2/F3, Ctrl+Maiusc+I apre l'EDIT nativo. Digitare per esempio `-60,0` e confermare con Invio.
- Il range è **per sezione** (Track/Sends/Receives) e viene salvato nel solo `.tp` del progetto, senza toccare il livello corrente.
- Tab sul Volume ora comunica anche i limiti memorizzati per verificarli dopo riapertura.
- I limiti si applicano a tutte le modifiche effettuate dall'estensione: Alt+Su/Giù, Alt+Home/End, modalità Value, MIDI CC Fixed/Floating e Ctrl+E. Per Ctrl+E un valore fuori range è rifiutato con messaggio, senza alterare il volume.
- Il pickup MIDI usa lo stesso intervallo personalizzato (in precedenza era fisso da -60 a +12 dB).
- Il range limita le modifiche di **LReaParams**; non impone un vincolo agli altri comandi di REAPER, all'automazione della DAW o alle superfici di controllo esterne che non passano dall'estensione.

## Collaudo REAPER/NVDA dopo GitHub Actions

1. Aprire Track Params e premere Alt+F8; ascoltare il primo elemento senza premere frecce.
2. Premere Su ripetutamente sulla prima riga, Giù sull'ultima, Sinistra sulla prima categoria popolata e Destra sull'ultima: i bordi devono essere silenziosi.
3. Provare Tab e NVDA+Su, poi Esc e verificare il ritorno a Track Params.
4. F1 Volume: Ctrl+Maiusc+I, inserire `-60,0`, Invio; Tab deve riportare `-60.0 to 0.0 dB`.
5. Provare Alt+Home/End, Ctrl+E con `+6` (deve rifiutare) e con `-12` (deve accettare), poi CC Fixed con pickup.
6. Ripetere su F2/F3 e dopo la riapertura del navigatore; verificare che lo stesso file `.tp` del progetto conservi i limiti.

Test statici Python non equivalgono a compilazione MSVC e test reali.
