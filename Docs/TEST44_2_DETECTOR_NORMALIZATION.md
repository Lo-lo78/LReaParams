# LReaParams 0.0.44.2 — Detector Input di ReaComp e ReaGate

## Problema nella 0.0.44.1

Il parametro `SignIn` può essere esposto da REAPER come valore normalizzato da 0 a 1, anche se le otto modalità del Lua usano i codici discreti 0, 2, 1024, 1025, 1026, 1027, 999 e 1000. La 0.0.44.1 impediva il tentativo normalizzato quando il codice scelto superava il massimo grezzo dichiarato dal plugin. Inoltre interpretava il valore normalizzato restituito dall'host come se fosse il codice grezzo.

## Correzione

- Leggere sia `GetParam` sia `GetParamNormalized` e decodificare il valore con la scala specifica di `SignIn` (1084 passi), mantenendo la compatibilità con gli host che restituiscono direttamente i codici discreti.
- Eseguire `SetParam` soltanto per codici compresi nell'intervallo grezzo dichiarato.
- Se la modifica non è confermata, eseguire `SetParamNormalized(codice / 1084)` senza applicare il limite sbagliato dei valori grezzi.
- Confermare la modalità selezionata tramite nuova lettura: non annunciare mai una scelta che il plugin non conferma.
- Utilizzare la lettura corretta anche per Griglia, Value, i comandi di incremento/decremento e le associazioni MIDI, sia su ReaComp sia su ReaGate.

## Prova manuale in REAPER con NVDA

Con REAPER fermo, provare in ordine: Main inputs, Auxiliary inputs, Main input left, Main input right, Auxiliary input left, Auxiliary input right, Feedback pre-fader, Output feedback deprecated. Confrontare ogni scelta annunciata con la GUI nativa del plugin e ripercorrere l'elenco al contrario. Ripetere sia su ReaComp sia su ReaGate. Le modalità di feedback possono cambiare radicalmente la risposta audio: usare un progetto di prova e non riprodurre audio ad alto volume.

La correzione è verificata staticamente, ma nessuna compilazione C++ o prova runtime è stata eseguita localmente. La conferma deve arrivare da GitHub Actions e dal test REAPER/NVDA.
