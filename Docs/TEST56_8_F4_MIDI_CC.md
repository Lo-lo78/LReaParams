# LReaParams 0.0.56 — TEST56.8: MIDI CC F4

## Ambito

MIDI CC operativo per i parametri **già esposti nel TCP** nella griglia F4. Si riutilizzano TrackNavigatorMidi, TrackMemory, le preferenze e il poller esistenti; la griglia dei **soli nomi** aperta con Alt+Invio non modifica MIDI né apprende CC. Nessun cambiamento ai valori di default, agli step delle sezioni F1/F2/F3 o a FX Params.

## Comandi

- `Ctrl+Alt+C`: avvia/annulla il MIDI CC learn Fixed sul parametro F4 corrente.
- `Maiusc+C`: disattiva/riattiva la mappa Fixed del progetto. Lo stato viene salvato.
- `Ctrl+Maiusc+C`: abilita/apprende o disabilita il Floating CC; il controller segue il parametro navigato nella griglia.
- `Ctrl+T`: alterna il parlato MIDI soltanto per il bersaglio esatto (inizialmente **Off**).
- `Ctrl+Maiusc+T`: alterna il parlato delle modifiche manuali del parametro, seguendo il profilo Step esistente.
- `Ctrl+Canc`: cancella il Fixed CC del parametro e istanza FX corrente; `Canc` senza Ctrl continua a rimuovere il controllo TCP.
- `Ctrl+Maiusc+M`: Track Memories visualizza le associazioni F4 con nomi leggibili e permette di cancellarle.
- `Ctrl+Q`: continua il controllo MIDI Fixed/Floating dopo il ritorno al TCP, come nelle sezioni già migrate.

## Persistenza e sicurezza

I nuovi bersagli sono salvati nella sezione già esistente `[LReaParams.FixedCCByTarget]` del `.tp` del **progetto** con identità `FxTcp|{TrackGUID}|{FxGUID}|{ParameterIndex}`. La sola posizione dell'FX nella catena, la sua posizione F4 e il nome visualizzato **non** sono identificatori. A ogni MIDI ricevuto viene nuovamente cercata la traccia per GUID, l'istanza FX per GUID e controllato l'indice del parametro; plugin o tracce eliminate restano inattivi, senza passare a un bersaglio differente. Il Fixed non segue il cursore; il Floating lo segue. Il CC appreso non viene applicato come primo movimento involontario. Il pickup dei parametri continui usa valori normalizzati e i toggle ricevono la soglia 64.

**Limite di sicurezza:** se un plugin cambia il significato dei parametri mantenendo il medesimo indice, la DLL non può riconoscere con certezza il cambiamento. Occorre riapprendere il CC per quel nuovo layout. Non viene aggiunta una nuova cartella o un secondo file F4.

## Verifiche in REAPER dopo GitHub Actions

1. Track 1 con ReaEQ: esponi un parametro TCP, apri F4, Ctrl+Alt+C, muovi un CC. Il primo movimento deve apprendere, non modificare.
2. Muovi lo stesso CC e verifica il pickup; il parametro non deve parlare finché Ctrl+T non abilita la preferenza.
3. Muovi l'FX tramite Ctrl+Pagina Su/Giù; il CC deve controllare sempre la stessa istanza.
4. Seconda traccia con un altro ReaEQ: il Fixed del primo non deve controllare il secondo.
5. Ctrl+Maiusc+C, muovi un altro controllo e cambia parametro F4: il Floating deve seguire il parametro selezionato.
6. Ctrl+Q e muovi il CC: controlla il MIDI in background. Ferma con l'azione Stop background MIDI.
7. Chiudi e riapri Track Params/REAPER: i Fixed devono rimanere nel `.tp` del progetto.
8. Tab/NVDA+Su sul parametro: `Parametro, valore. CC channel X CC Y. Auto` nell'ordine corretto.
9. Apri Track Memories e verifica nome traccia, nome FX e nome parametro; Canc deve rimuovere solo il CC scelto.
10. In F4, `Ctrl+Canc` elimina solo l'associazione, lasciando il parametro TCP; `Canc` semplice rimuove solo la visualizzazione TCP.

**NON compilare localmente.** Compilazione MSVC e CTest esclusivamente tramite GitHub Actions. I test Python sono verifiche del sorgente, non simulano audio, eventi Windows o REAPER.
