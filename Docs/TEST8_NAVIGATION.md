# TEST8 — navigazione, bordi e titoli NVDA

Non compilare localmente: fai push e usa soltanto GitHub Actions.

## FX Params

- Nessun browser FX e nessun Alt+B: si entra direttamente nei parametri dell'FX selezionato nella catena (se aperta), altrimenti il primo con parametri.
- Ctrl+Su / Ctrl+Giu: FX precedente o successivo. All'inizio/fine della lista niente suono e niente movimento. Gli FX privi di parametri vengono saltati.
- NVDA+T: titolo con nome FX, nome traccia (o Master / Take FX) e Grid/Value.
- NVDA+Freccia Su: **solo nome parametro e valore**.
- Frecce Su/Giu: spostamento nella colonna, Sinistra/Destra stessa riga della colonna accanto; su una cella inesistente silenzio.
- Page Up/Down: fino a cinque righe verticali, senza mai sconfinare nella colonna vicina; ai bordi nessun annuncio.
- Home/End: inizio/fine della colonna; Ctrl+Home/End: primo/ultimo parametro dell'intero FX.
- Alt+Su/Giu: valore piccolo; Alt+Page Up/Down: valore grande; Alt+Home/End: minimo/massimo. Alt+Sinistra/Destra: scala del passo. Ai limiti, silenzio.
- F1/F2: cambia altezza della griglia. Invio: Grid/Value. Escape: ritorno o uscita.
- Ctrl+F: ricerca parametro (funzione ancora sperimentale). Tab: libero, nessuna azione.

## Track Params

- F1: righe delle tracce; F2/F3: 14 campi verticali per send/receive, Sinistra/Destra cambia colonna.
- NVDA+Freccia Su resta **traccia + parametro + valore**.
- Home/End normali: primo/ultimo parametro della riga o colonna (in Grid).
- Alt+Home/End: valore minimo/massimo quando modificabile; in Value anche Home/End senza Alt. Limiti silenziosi.
- Alt+Su/Giu e Alt+Page Up/Down: modifica valore. Invio su On/Off: toggle.
- Tab libero in Track Params; non esegue alcuna azione.

## Collaudo

1. Prova due FX con valori indipendenti, passa con Ctrl+Su/Giu. Verifica che si muova anche con la GUI visibile.
2. Premi i tasti ai bordi e assicurati che NVDA/OSARA non ripetano il vecchio parametro.
3. Con F1/F2 modifica l'altezza della griglia e prova Page Up/Down nell'ultima colonna corta.
4. Controlla NVDA+T e NVDA+Su per FX; verifica i testi diversi per Track Params.
5. Verifica Alt+Home/End, poi i limiti di min/max e l'Undo.
6. Verifica Escape, F12 OSARA e che il mouse del collaboratore veda ancora il plugin.

La compilazione C++, le API native e il comportamento reale di NVDA devono essere verificati nella tua installazione.
