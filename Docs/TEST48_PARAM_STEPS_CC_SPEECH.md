# 0.0.48 — collaudo Step per parametro e parlato CC

La 0.0.48 NON è dichiarata versione finale della migrazione FX Params.

## Step individuali

1. In FX Params su un plugin con almeno due parametri, selezionare il parametro
   A. Con Alt+Sinistra impostare Step -6 e leggere F3.
2. Spostarsi sul parametro B, verificare che sia Step 0; impostare Step +3.
3. Tornare ad A: Step -6. Tornare a B: Step +3.
4. Duplicare A in Custom Order e inserirlo in un gruppo F7: lo Step deve
   seguire A in qualunque vista, non la sua posizione nella griglia.
5. Ctrl+Backspace su A deve riportare Step 0 **soltanto per A**.
6. Cambiare FX e traccia, chiudere REAPER, riaprirlo e provare A e B.
7. Verificare la creazione del record `lrp_param_step_scales_v1` nel file `.fx`
   dell'effetto, senza alterare `LastParam`, alias, MIDI CC e vecchie memorie.
8. Provare un profilo Lua storico con `param_step_scales_v1` versione v3:
   lo Step va recuperato senza cancellare la chiave Lua. La scala esatta può
   differire perché i moltiplicatori Lua erano 18 e quelli della griglia C++ 21.

## Parlato CC (Ctrl+T)

1. Disporre di due parametri con associazioni MIDI CC valide.
2. Attivare Fixed CC e abilitare Ctrl+T soltanto sul parametro A. Un cambio
   MIDI di A deve essere letto, B deve rimanere silenzioso.
3. Su A, la variazione MIDI deve annunciare solo il valore; quando il valore di
   B è abilitato e A è focalizzato deve essere letto `B, valore`.
4. Ripetere CC 0 e CC 127, verificando pickup e assenza di ripetizioni identiche.
5. Chiudere FX Params con Ctrl+Q e provare il parlato nel background secondo
   le possibilità del focus/screen reader; fermare la sessione MIDI con
   l'azione `LReaParams: Stop background MIDI`.
6. Riaprire REAPER, verificare che Ctrl+T ricordi l'impostazione. La lettura
   manuale con frecce e NVDA+Su deve continuare anche con Ctrl+T su Off.

## Sicurezza

Nessuna compilazione locale effettuata: GitHub Actions compila MSVC e avvia
CTest. I test statici verificano la presenza dei percorsi, non il loro
comportamento runtime.
