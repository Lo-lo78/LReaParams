# TEST50 — F1 Track Params / Tab

## Obiettivo e limiti

Base 0.0.49 senza modifiche al motore FX Params, al formato `.tp` né alle
14 righe verticali di F2 e F3. Nessuna Parameter Library. Nessuna build locale.
In TEST50 si migrano le funzioni di selezione F1 e la navigazione folder del Lua.
NON è dichiarato il completamento di tutte le funzionalità F1: mancano taglia/
copia/incolla tracce con routing, spostamento fisico, automazioni, filtro,
editor dei range volume, altre scorciatoie. La prosecuzione richiede una
ulteriore verifica contro il Lua prima di completare F2/F3.

## Nuove scorciatoie

- **Tab** ripete contesto, parametro, valore, Step, stato degli annunci e
  preferenza parlato MIDI, più conteggio dei selezionati in F1. Non usare più
  Ctrl+R come scorciatoia Track. NVDA+Su legge ancora solo parametro e valore.
- **Ctrl+A** seleziona le tracce della lista TCP visibile, lascia selezionate
  eventuali tracce invisibili che erano già selezionate.
- **Maiusc+Spazio** o **Ctrl+Maiusc+Spazio** seleziona/deseleziona la traccia
  logica corrente. **Canc** la deseleziona; **Ctrl+Canc** deseleziona tutto.
- **Maiusc+Su/Giù** selezione estesa a intervallo; alla PRIMA pressione
  seleziona l'ancora ma non si muove (comportamento Lua), poi si muove.
  **Maiusc+Pagina Su/Giù** estende di cinque tracce dopo la prima pressione.
  Cambiare direzione ricostruisce l'intervallo attorno alla stessa ancora,
  mantenendo le tracce selezionate all'inizio dello stroke.
- **Ctrl+Maiusc+Su/Giù** seleziona dal cursore fino alla prima/ultima traccia.
- **Ctrl+Alt+Pagina Su/Giù** scorre alla folder precedente/successiva visibile
  senza cambiare colonna né selezione reale.
- **Ctrl+Maiusc+V** entra/esce da Value su F1; Invio continua a funzionare
  sulla griglia e toggle Mute/Solo/Phase.

## Collaudo REAPER + NVDA/OSARA dopo GitHub Actions

1. Aprire Track Params da REAPER, premere Tab su Volume, Pan e Width: leggere
   Step salvato, parlato Value/CC e conteggio selezionati. Ctrl+R non deve
   pronunciare il vecchio riepilogo. NVDA+Su continua a leggere la riga.
2. Con tre tracce visibili non selezionate e cursore sulla seconda, Maiusc+Spazio
   seleziona la seconda senza cambiare cursore; ripetere per deselezionare.
3. Ctrl+A deve selezionare tutte le tracce visibili, non quelle nascoste.
   Canc deseleziona solo quella sotto il cursore; Ctrl+Canc tutte.
4. Con 8 tracce, Maiusc+Giù una volta seleziona l'ancora. Ripetere due volte:
   3 tracce selezionate. Maiusc+Su riduce a 2 senza perdere altre selezioni
   preesistenti. Provare Maiusc+Pagina/Giù e Ctrl+Maiusc+Su/Giù.
5. Premere freccia Su/Giù senza Maiusc e verificare che si cambi il cursore
   ma **non** la selezione reale delle tracce. Tab deve dire correttamente
   “Selected” sulla traccia che lo è.
6. Nel progetto con folder annidate, Ctrl+Alt+Pagina Su/Giù salta fra le folder
   visibili senza spostare i selezionati; la colonna Pan rimane Pan.
7. Ctrl+Maiusc+V in F1 Volume entra Value, frecce modificano i valori; ripetere
   torna a Grid. Tab continua a leggere; Esc torna dalla Value alla Grid.
8. Test di regressione F2/F3: 14 righe, navigazione verticale, Tab, step e
   parlato persistente della TEST49; FX Params con proprie scorciatoie
   invariato. Monitorare eventuale perdita del focus dopo i gesti di selezione.
9. Cambiare selezione esternamente da REAPER mentre la finestra Track è attiva:
   deve essere gestito come cambio contesto; dopo una selezione effettuata
   internamente il navigatore NON deve chiudersi inatteso.

Non eseguiti: CMake, MSVC, CTest, REAPER o NVDA. I soli controlli Python
sono verifiche statiche del sorgente, non provano i comportamenti dell'host.
