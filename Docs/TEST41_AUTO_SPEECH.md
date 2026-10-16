# TEST41 — Annuncio Auto in FX Params (0.0.41)

## Problema riscontrato

Alt+F3/F4 raggiunge parametri con envelope attivo ma la lettura ordinaria
pronunciava soltanto `nome, valore` e non lo stato `Auto` del Lua.

## Modifica

`FxNavigator::currentParameterSpeech()` aggiunge `. Auto` dopo il valore
esclusivamente per un indice parametro FX fisico (0 <= parametro < count_)
con envelope REAPER esistente e ACT=1. Usa `envelopeActive(parametro)` già
impiegato dalla navigazione Alt+F3/F4; nessuna creazione o scrittura di envelope.

Questo metodo è usato anche da editor F7, annuncio cambio FX, F8 al ritorno
e NVDA+Freccia Su. `formattedValue()` e `setValue()` restano invariati:
Alt+frecce continua a pronunciare solo il valore. Nessuna modifica a
Track Params, MIDI, profili, Lua o formato .fx/.tp.

Per limitare allocazioni in navigazione, `envelopeActive()` riutilizza sul
thread di chiamata il proprio buffer di lettura di 4 MiB. Nessun accesso
in background o cambio dei criteri di rilevamento ACT.

## Prove indispensabili in REAPER

1. Scegli un FX con Cutoff e senza automazione: `Cutoff, 2 kHz`, niente `Auto`.
2. Attiva Ctrl+Maiusc+A: leggi `Cutoff, 2 kHz. Auto` con frecce e NVDA+Su.
3. Con Alt+F3/F4 raggiungi un parametro attivo: deve dire `. Auto`.
4. Modifica il valore con Alt+frecce: deve dire solo il nuovo valore.
5. Disattiva l’envelope, lasciandolo creato: `. Auto` non deve apparire.
6. Prova più FX, Master/Monitor, Take FX, F7 e Value; controlla che i
   parametri virtuali come Compare non ricevano falsamente `Auto`.

Nessuna compilazione locale effettuata. Test statici non sostituiscono NVDA.
