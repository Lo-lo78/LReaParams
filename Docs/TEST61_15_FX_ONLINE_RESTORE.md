# TEST61.15 — FX Ctrl+Alt+B: ritorno automatico a gruppo e parametro

## Problema corretto

Quando un plugin FX o strumento veniva messo offline e successivamente online
con Ctrl+Alt+B, REAPER ricreava l'elenco dei parametri, ma FX Params rimaneva
nella griglia **FX Browser**. Occorreva uscire e richiamare FX Params per
ritornare ai controlli del plugin.

## Nuovo comportamento

- **Online → Offline:** prima di scaricare il plugin si memorizzano gruppo,
  parametro e posizione esatta della griglia, come nella TEST61.14; FX Params
  mostra il browser, così Ctrl+Alt+B resta disponibile anche con zero parametri.
- **Offline → Online:** si rilegano immediatamente i parametri al *medesimo
  GUID* e si ritorna nella griglia, nel gruppo e sul parametro precedente.
  Nessun Enter, Esc o rilancio dell'azione FX Params.
- **Caricamento ritardato:** se il plugin non espone subito i parametri, il
  browser rimane accessibile mentre il timer REAPER verifica la loro comparsa
  ogni 250 ms per un massimo di 90 secondi. Appena disponibili avviene il
  ritorno automatico. Nessuna attesa bloccante né thread secondario.
- **Cambio FX volontario:** se si sceglie un altro FX, un'altra traccia/colonna
  o si richiede F10, il ritorno automatico si annulla per non sottrarre il
  focus all'utente. L'accesso con Enter e Ctrl+Alt+B resta operativo.
- **Parametri non disponibili:** allo scadere della verifica FX Browser
  continua a essere utilizzabile; non vengono inventati parametri.
- **Track FX, Take FX, Monitor FX:** rispettate le rispettive API native.
- La memoria persistente `.fx` e la memoria per GUID della sessione restano
  quelle della TEST61.14. F7 non viene riaperto automaticamente.

## Collaudo REAPER / OSARA

1. Entrare in un gruppo (es. Gruppo 2), selezionare il quinto parametro.
2. Premere Ctrl+Alt+B: **Offline**, accesso al browser.
3. Premere nuovamente Ctrl+Alt+B: **Online**, ritorno immediato al quinto
   parametro del Gruppo 2 senza Esc o riapertura.
4. Ripetere con due istanze uguali su due tracce; verificare indipendenza.
5. Ripetere con un VSTi lento e un JSFX; se lo strumento impiega tempo a
   caricare, verificare che la griglia torni quando i parametri sono pronti.
6. Ripetere con Take FX e Monitor FX (Master); controllare il GUID corretto.
7. Prima di tornare online, spostarsi nel browser su un altro FX: la griglia
   deve riferirsi solo al plugin che si è appena rimesso online.
8. Verificare F7 e Value: nessun ritorno accidentale a F7; accessibilità NVDA
   e OSARA e focus invariati.

Test statico: `python Testing/test61_15_fx_online_restore_static.py`.
Nessuna compilazione locale. Build MSVC e test reali delegati a GitHub Actions
ed alla prova in REAPER.
