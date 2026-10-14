# LReaParams 0.0.8 — TEST7 NVDA review line / routing grid

## Regola di compilazione

**NON compilare localmente.** Caricare il sorgente su GitHub e usare esclusivamente
GitHub Actions. Nessuna DLL o build locale e' inclusa in questo ZIP.

## 1. NVDA+Freccia Su (prova principale)

- Avvia REAPER con OSARA e NVDA, su un progetto di prova.
- Seleziona una traccia con almeno un FX e avvia FX Params dal menu Extensions
  o dalla lista azioni.
- Con un solo FX entra nella griglia; con piu' FX usa il browser vocale.
- Su un parametro premi **NVDA+Freccia Su**: il risultato atteso e' il nome
  del plugin, nome del parametro e suo valore reale.
- Passa a un altro parametro con le frecce; ripeti NVDA+Freccia Su.
- Modifica il valore con Alt+Freccia Su/Giu'; ripeti NVDA+Freccia Su.
- Premi NVDA+T: il titolo atteso rimane "LReaParams - FX Params - ...".
- Prova anche Ctrl+Home/End, F1/F2 per griglia e il browser FX.

Come funziona: la finestra proprietaria da 1 pixel e' fuori dallo schermo,
con un **campo EDIT Win32 di sola lettura**, focalizzato e sempre a riga
singola. E' il controllo standard di Windows, non una finestra inventata per
NVDA. NVDA legge la riga con il proprio comando nativo; OSARA continua a
ricevere gli annunci tramite `osara_outputMessage`. Il testo si aggiorna
quando navighi o modifichi un parametro e non esce dai confini della DLL.
Non esiste un add-on NVDA richiesto. La lettura va verificata davvero: l'uso
di una finestra 1px fuori schermo puo' variare fra NVDA/Windows/configurazioni.

## 2. Track Params: F1

- Tre tracce nominate Piano, Bass, Drums; seleziona Bass.
- F1: Su/Giu' naviga la traccia, Sinistra/Destra il parametro sulla riga.
- Vai su Mute o Solo. **Invio deve cambiare immediatamente On in Off e
  viceversa**, senza aprire Value o altre finestre.
- Lo stesso per Phase Invert.
- Ripeti NVDA+Freccia Su: nome traccia, parametro, stato aggiornato.
- Se premi Invio su Send count / Receive count passi a F2 / F3.

## 3. Track Params: F2 Sends, F3 Receives

- Crea su Piano almeno due sends, verso Bass e Drums, poi seleziona Piano.
- F2 deve leggere il primo Send, con intestazione "to Bass" o equivalente.
- **Freccia Giu'**: scorre verticalmente i 14 campi dello stesso send.
- **Freccia Destra**: va alla colonna del secondo send, CONSERVANDO
  l'indice di parametro. Sinistra torna al primo.
- Le 14 righe sono: intestazione, Volume, Pan, Mute, Audio source mode,
  Audio source, Audio destination, Send type, MIDI source,
  MIDI destination, MIDI source bus, MIDI destination bus,
  MIDI follows fader, MIDI merge.
- Invio su Mute e MIDI follows fader cambia On/Off direttamente.
- Su Volume/Pan, Alt+Frecce cambia il valore.
- Su audio source/destination, i dati sono leggibili, ma la modifica dei
  canali audio non e' ancora migrata: serve verificare i limiti I_NCHAN.
- Seleziona Bass (che riceve il send) prima di avviare Track Params; prova F3
  con gli stessi 14 campi verticali su ogni colonna receive.
- NVDA+Freccia Su su una qualunque voce deve leggere traccia, send/receive,
  traccia collegata, parametro e valore.

## 4. Focus e protezioni

- Escape da F2/F3 torna a F1; un altro Escape esce dalla navigazione.
- NVDA+T, NVDA+Freccia Su e F12 Shortcut Help di OSARA non devono mandare
  i comandi a TCP/arrangement, ne' bloccare REAPER.
- La GUI dell'effetto deve rimanere visibile al vedente, senza overlay.
- Quando LReaParams termina, il controllo EDIT viene nascosto insieme alla
  finestra proprietaria e il focus torna alla finestra originaria.
- Se il test causa errori o crash, ripristina TEST6 e allega il log Actions
  o riferisci con precisione il tasto e il contesto che falliscono.

## Ancora non migrato

Libreria Parameter Library, memorie FX/Track, gruppi e ordini dei profili,
routing audio avanzato e MIDI CC di Track Params. Questa e' una versione
sperimentale, NON un sostituto completo dei Lua.
