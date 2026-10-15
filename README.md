# LReaParams — TEST13 (0.0.14)

**Progetto sorgente C++ per REAPER. Nessuna compilazione locale:** la DLL viene
compilata esclusivamente tramite GitHub Actions (Windows x64 / Visual Studio).

La TEST13 parte da TEST12 e mantiene l'importazione dei vecchi profili,
la navigazione FX e Track, il controllo di tastiera e la memoria in RAM.

## FX Params

- Titolo NVDA+T: `FX Params - VST3: Pro-Q 4 (FabFilter), Track 1` (senza
  `LReaParams` e senza `Grid`). In Value il titolo aggiunge `- Value`.
- **Ctrl+Su/Giù:** FX precedente/successivo nella catena corrente.
- **Ctrl+Maiusc+Su/Giù:** traccia precedente/successiva contenente FX con
  parametri navigabili; salta quelle prive di FX e seleziona la traccia in
  REAPER. L'ultimo FX, parametro, altezza griglia e Step vengono recuperati
  distintamente per progetto, GUID traccia e GUID FX (e take dove previsto).
- Se non esistono altre tracce con FX compare un messaggio dedicato.
- **Alt+Sinistra/Destra:** `Step -10` … `Step 0` … `Step 10`.
  `0` applica i passi normali; lo Step usa fattori di 2.
- Le modifiche del parametro parlano **solo il valore**. I movimenti di
  griglia continuano ad annunciare nome del parametro e valore.
- **Invio** apre o chiude Value: uno slider Win32 `msctls_trackbar32` riceve
  il focus per offrire il ruolo nativo a NVDA; il valore reale resta gestito
  da REAPER. L'annuncio iniziale è `Value, parametro, valore`.

## Track Params

- Anche qui la variazione di un parametro parla solo il valore.
- Alt+Sinistra/Destra imposta Step da -10 a +10. Questa scala modifica
  esclusivamente volume, pan e width (traccia e send/receive); la gestione
  di controlli discreti, mute e solo, e del routing rimane quella di TEST12.
- Con Invio, volume/pan/width usano lo slider Win32 di Value. Per mute,
  solo, phase e altri interruttori Invio continua a commutare On/Off.
- F2 e F3, o Invio su Send count / Receive count, **non aprono pagine
  vuote**: annunciano `No sends` o `No receives`.

## Accessibilità e note di test

- L'interfaccia resta utilizzabile da tastiera. Il controllo STATIC di Grid
  non emette modifiche del nome; lo slider Value è nativo, con posizione
  aggiornata passivamente. Restano disponibili Ctrl+R e NVDA+T.
- La persistenza riguarda **la sessione corrente di REAPER**, non i progetti
  salvati o i file TXT; non viene scritto alcuno stato nel progetto RPP.
- I controlli Track Params avanzati ancora incompleti non sono stati riscritti.
- La sintesi vocale finale, il riconoscimento del controllo slider da parte
  di NVDA e il focus devono essere verificati realmente in REAPER con OSARA.

Vedere `Docs/TEST13_TRACK_SWITCH_VALUE.md` per la checklist dei test.
