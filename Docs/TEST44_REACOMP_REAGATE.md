# LReaParams 0.0.44 — ReaComp e ReaGate (sorgente, senza build locale)

## Provenienza

- Base: 0.0.43.5 (Ctrl+Spazio riparato, funzionamento confermato dall'utente).
- Spec ufficiale di comportamento: le sezioni Lua 3.1A2 e 3.1A3 di
  `Legacy/Speak FX Params - TrackTake Navigator.lua`.
- Track Params, il Lua storico, l'SDK REAPER e il routing del trasporto non vengono modificati.

## Modifiche implementate

- Identificazione ReaComp/ReaGate dal nome FX corrente, usando sia Track FX sia Take FX;
  nessun riconoscimento per sola firma che possa intercettare plugin diversi.
- Alias Lua per nomi reali: Detector Highpass/Lowpass/Input, Lookahead,
  Dry/Wet mix, RMS size e parametri specifici Comp/Gate e MIDI.
- Plugin Order Lua su parametri reali (nessun parametro reale omesso),
  con Compare virtuale e nuova riga di sintesi subito dopo i due filtri.
- **Detector input**: otto valori raw discreti e relativi nomi Lua;
  Alt+Su/Giù, Page e il controllo Value usano soltanto i valori ammessi.
- MIDI CC associazione su Detector input: quantizzazione agli stessi otto
  valori raw; pickup e annunci sono ereditati dal motore 0.0.42.
- Toggle del Lua: parlato On/Off e Invio per cambiare stato nei veri parametri.
- ReaComp RMS size: 0 ms diventa `0 ms, peak detector`.
- `Detector filter range`: ID virtuale -200000 (ReaComp) o -210000 (ReaGate),
  riepiloga `Full range`, `Above`, `Below` oppure `Hz to Hz`.
  **Sola lettura**: non rappresenta un parametro audio, non dispone di setter
  e non apre Value con Invio.
- Custom Order, gruppi e memorie F8 riconoscono gli ID Lua negativi;
  gli .fx storici non sono riscritti automaticamente. La mancanza del riepilogo
  in una vecchia Custom Order viene riconciliata in memoria all'apertura.
- Niente nuove azioni REAPER; rimangono solamente FX Params e Track Params.

## Test da fare dopo build con GitHub Actions

1. In una traccia di prova, inserire **ReaComp**, aprire FX Params e premere
   Ctrl+L per verificare Plugin Order. Controllare con frecce e NVDA+Su
   `Threshold`, `Ratio`, `Attack`, `Release`, `Lookahead`, `RMS size`, `Knee`,
   `Detector input`, `Detector Highpass`, `Detector Lowpass`,
   `Detector filter range`, `Filter Preview` nell'ordine.
2. Su Detector input, cambiare con Alt+Su/Giù e leggere: Main inputs,
   Auxiliary inputs, Main input left/right, Auxiliary input left/right,
   Feedback pre-fader, Output feedback deprecated. Provare anche Invio/Value.
3. Toggle Filter Preview, Auto Make Up Gain e Auto Release con Invio;
   i messaggi devono essere On/Off. RMS 0 deve essere letto come peak detector.
4. Detector filter range: con HP e LP disattivati leggere Full range;
   variando HP o LP verificare Above, Below e l'intervallo. Invio non deve
   mutare il plugin, né creare un falso slider.
5. Ripetere su **ReaGate**: Threshold, Attack, Hold, Release, Hysteresis,
   Lookahead, detector e filtro, Invert gate, Send MIDI, MIDI note/channel/velocity.
6. Testare **entrambi** in F7 e F8, e su un profilo .fx esistente.
   Posizionare la riga virtuale in Custom Order e in un gruppo, uscire e rientrare.
7. Associare un CC a Detector input, scegliere tutte le sorgenti con la
   manopola MIDI: nessun valore intermedio non valido, pickup ancora attivo.
8. Test regressione: ReaEQ, Ctrl+Spazio per Play/Pause e Track Params;
   rimanere su parametri di prova e usare REAPER Undo dopo modifiche.

## Limiti da dichiarare

Non è stata eseguita compilazione locale, CMake, MSBuild, Visual Studio,
REAPER né NVDA. I test C++ puri sono nel workflow e devono ancora passare
su GitHub Actions. Le letture di frequenza usano l'output formattato del
plugin come nel Lua; variazioni del formatter di REAPER e dei parametri
aggiuntivi di nuove versioni ReaComp/ReaGate richiedono un collaudo reale.

La 0.0.44 non completa ancora tutte le funzionalità Lua non legate a
ReaComp/ReaGate (clipboard avanzata, browser FX e altre scorciatoie).
