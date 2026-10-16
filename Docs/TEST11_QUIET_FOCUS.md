> Documento storico TEST30. Per stato attuale e limiti prevalgono Status.md e FxCommandMatrix.csv.

# TEST11 — NVDA e bordi silenziosi (0.0.12)

## Perché la TEST10 parlava ai bordi

La griglia C++ già non chiamava OSARA quando il parametro non cambiava.
Tuttavia la finestra di navigazione possedeva un EDIT con cursore testuale:
NVDA poteva parlare a ogni pressione delle frecce perché le interpretava
come tentativi di muovere il cursore nel testo. Questo spiegava la lettura
di lettere isolate seguita dal nome del parametro.

## Soluzione TEST11

- Controllo focus: STATIC nativo Windows con testo accessibile, non EDIT.
- Nessun sistema caret, nessun EM_SETSEL, nessun evento di editazione.
- Il gestore di tastiera continua a consumare WM_KEYDOWN e WM_CHAR.
- OSARA resta responsabile di annunciare il parametro quando cambia.
- Nessun annuncio LReaParams/OSARA ai bordi invariati.
- NVDA+T: titolo LReaParams con FX e traccia / pagina.
- Ctrl+R: ripete manualmente 'parametro, valore' in FX oppure
  'traccia, parametro, valore' in Track Params.

## Limite conosciuto e compromesso deliberato

NVDA+Freccia Su legge normalmente la riga del *cursore di sistema*. In un
STATIC non c'è tale cursore. NVDA potrebbe quindi utilizzare il testo
accessibile dell'oggetto, oppure non avere una riga corrente da leggere.
La sua effettiva risposta è DA TESTARE con NVDA 2026.2. Non è corretto
promettere che il comando funzioni ancora senza un supporto UIA TextPattern
o un piccolo componente NVDA dedicato. Ctrl+R permette intanto una rilettura
volontaria senza riattivare il problema del cursore.

## Prove su REAPER

1. FX: vai al primo parametro e premi Su almeno tre volte: silenzio.
2. FX: vai all'ultimo parametro della colonna e ripeti Giù: silenzio.
3. Track F1: prima/ultima traccia e colonne estreme: silenzio.
4. Track F2/F3: prima/ultima mandata o ritorno e righe estreme: silenzio.
5. Cambia parametro: un solo annuncio da OSARA, SENZA lettere isolate.
6. Ctrl+R deve ripetere il parametro corrente; NVDA+T il titolo.
7. NVDA+Freccia Su: annota esattamente cosa pronuncia.
8. Escape torna a REAPER, F12 passa a Shortcut Help di OSARA.

Nessuna DLL o binario nel pacchetto. Compilare esclusivamente in Actions.
