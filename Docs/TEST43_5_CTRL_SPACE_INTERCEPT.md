# 0.0.43.5: Ctrl+Spazio Play/Pause senza doppio invio

## Origine del problema
La sola chiamata a `Main_OnCommand(40073, 0)` non esclude che la stessa
pressione di Ctrl+Spazio venga gestita anche dall'Action List nativa di
REAPER. Il Lua originale protegge esplicitamente lo spazio con
`JS_VKeys_Intercept` quando Ctrl è premuto. Questa revisione applica
l'equivalente al messaggio Windows prima della traduzione dell'acceleratore.

## Meccanismo nel sorgente
- `InputRouter::start` registra `WH_GETMESSAGE` sul solo thread di REAPER
  mentre il navigatore è aperto, anche nel backend con finestra Win32 per NVDA.
- `InputRouter::hook` riconosce soltanto Ctrl+Spazio (senza Maiusc o Alt),
  prima dell'Action List. Converte il messaggio in `WM_NULL` soltanto quando
  `interceptTransport()` lo ha già accodato con successo.
- Il rilascio corrispondente viene consumato anche se Ctrl è stato già
  rilasciato; le ripetizioni conservano `Key.repeat` e non rieseguono 40073.
- La gestione del trasporto avviene poi nella consueta coda, sul thread UI:
  l'hook non richiama direttamente nessuna API del trasporto.
- Sono esclusi Track Params, controlli EDIT nativi, scorciatoie con Alt o
  Maiusc, gesture NVDA e finestre estranee. Il hook viene disinstallato con
  la chiusura del navigatore.

## Collaudo indispensabile su REAPER con NVDA/OSARA
1. Con FX Params chiuso, provare Ctrl+Spazio 3 volte: Play, Pause e Resume.
2. Aprire FX Params, premere Ctrl+Spazio 3 volte: Play, Pause e Resume.
   Controllare che la ripresa avvenga dal punto di pausa, non dal cursore.
3. Ripetere nei modi Grid, Value, F7 e F8 e tenendo premuto Ctrl+Spazio.
4. Verificare Spazio Play/Stop e Maiusc+Spazio selezione F7.
5. Chiudere FX Params: Ctrl+Spazio deve tornare interamente all'Action List.
6. Verificare che Track Params, ricerca, rinomina e modifica numerica siano
   invariati. Nessun hook deve rimanere dopo l'uscita.

Questa consegna comprende solo sorgenti e test statici, senza build locale.
Il comportamento con REAPER reale non è stato ancora confermato.
