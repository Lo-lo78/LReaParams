# LReaParams 0.0.47 — F7/F8: completamento prudente e compatibilità

Base: 0.0.46.5, preservata senza modifiche a Track Params, browser FX,
ReaEQ/ReaComp/ReaGate, MIDI CC, automazioni e Clipboard.

## Migrazioni/correzioni

1. **F8, Default, Canc**: segue ora la stessa richiesta di conferma Yes/No
   dell’Invio, come la versione finale del Lua. `No` è la scelta predefinita.
   La semplice pressione di Canc **non cancella** più lo snapshot e non
   avvia una rigenerazione implicita. Scegliendo `Yes`, il programma tenta
   il reset, pulisce gruppi, posizioni, ordine e link MIDI e torna in Plugin
   Order; se il reset fallisce, le memorie restano intatte e F8 rimane aperto.
2. **F8, F7**: solo Memory Positions, Groups, MIDI CC e Custom Order possono
   entrare nell'editor F7. Hidden Parameters, Copied Parameters e Default
   Values non possono creare una vista F7 impropria.
3. **F8, Hidden Parameters**: elenca anche i controlli virtuali ReaComp e
   ReaGate riconosciuti. Come richiesto dall’utente, **Invio rimane inattivo**
   sui parametri nascosti, mentre Canc ne ripristina uno e resta dentro F8.
4. **Focus e ritorno**: dopo uscita/conferma i flag modali non vengono
   ereditati dal prossimo F8. Restano conservati la posizione, il gruppo,
   le selezioni F7 e il filtro temporaneo.
5. **Test**: aggiunto `Testing/test47_static.py` nel workflow GitHub Actions;
   aggiornato il vecchio test della TEST18 che presupponeva una cancellazione
   Default immediata, non più coerente con il Lua finale.

## Prova REAPER/NVDA

- In F7 selezionare più parametri, applicare Ctrl+F e aprire F8. Premere Esc
  e verificare filtro, posizione, selezione e annuncio `Selected`.
- In F8 su Default premere Canc e poi Invio, scegliendo **No**: tutti i dati
  rimangono. Ripetere e scegliere **Yes** su un progetto di prova, quindi
  verificare l'ordine Plugin e il reset dei parametri.
- Entrare in F8 da azione separata `_LREAPARAMSFXMEMORIES`. Con F7 provare
  Groups e Custom Order; nelle colonne Hidden/Copied/Default F7 non deve
  modificare né caricare parametri.
- Nascondere un controllo virtuale ReaComp o ReaGate e verificarne la presenza
  in Hidden Parameters. Premere Canc per ripristinarlo.
- Controllare 12 slot, nomi dei gruppi, duplicati e associazioni CC con profili
  Lua importati, poi chiudere e riaprire REAPER.

## Limiti dichiarati

La parità completa dei rami F7/F8 con oltre mille funzioni del Lua non può
essere certificata dai soli controlli statici. Mancano ancora il collaudo
interattivo completo NVDA/OSARA e l'audit generale della 0.0.48. Non sono
state eseguite compilazioni locali. La build deve essere fatta con GitHub Actions.
