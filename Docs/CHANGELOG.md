# Modifiche rispetto a TEST30

- Rimozione completa del terzo navigatore dal codice attivo, azione e menu; rimozione Lua dedicato, parser/fixture .pp e ramo Params dall'importatore.
- ID REAPER conservati e indici azione sostituiti con enum.
- Motore MIDI timer main thread, batch cronologico limitato, learn persistente, disassociazione, fixed, pickup, anti-jitter e Floating.
- Parlato MIDI per parametro con chiavi Lua e accorpamento notifiche.
- Preset Track/Take, envelope ACT/VIS circoscritti all'FX e navigazione Auto.
- EDIT numerico, formatter monotoni e raw esplicito; storico persistente e import in sola lettura da Lua.
- Compare virtuale con snapshot per identità; default ReaEQ strutturale e Gain esteso.
- F8 conferma Default, cancellazione/rigenerazione, pulizia delle memorie; supporto Compare nei profili e nella rinomina F7.
- Test C++ pickup/codec e salvataggio profili, nuovi controlli statici e workflow aggiornato.

Non completati: vedere Status.md e FxCommandMatrix.csv. Nessuna compilazione locale. TrackNavigator.cpp resta byte per byte uguale a TEST30.

## Analisi degli allegati

La specifica è il TXT estratto da ISTRUZIONI_ASTRA_LREAPARAMS(1).zip, conservato come Specification.txt. La base è TEST30; i due Lua contenuti in Scripts(3).zip sono identici, byte per byte, a quelli in Legacy nella base. Il terzo Lua è stato letto soltanto per identificare cosa eliminare e non viene distribuito.

- SHA-256 ISTRUZIONI_ASTRA_LREAPARAMS(1).zip: `da15c5be70420e1f141e2bae8fae8932e2bc4a15c36ef1cf0b21785c41d94065`
- SHA-256 LReaParams_TEST30_F7_CTRL_SHIFT_HOME_END_GITHUB_READY_SOURCE(1).zip: `1bcbc4867004aa5bf3fb2a16cc1f4bb3da5665fa887cc10b4c2a8099ef6ded62`
- SHA-256 Scripts(3).zip: `44d7174608bde1dc5895d97d72ad30202e79997fa8cab578f5964cafc08dcbcc`
