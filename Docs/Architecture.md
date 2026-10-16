# Architettura attuale

Extension possiede lifecycle, azioni con enum stabile, timer REAPER, router e TitleProxy. Gli ID REAPER rimasti sono invariati. TrackNavigator.cpp è identico a TEST30. TitleProxy conserva STATIC passivo per Grid, TRACKBAR per Value ed EDIT reale per ricerca, alias e numeri.

FxNavigator.cpp gestisce contesti, navigazione e valori; FxNavigatorOrder.cpp conserva F7; FxNavigatorMemories.cpp conserva le sette colonne F8 e gestisce conferma/rigenerazione Default. FxNavigatorAdvanced.cpp aggiunge CC, preset, numeri, envelope, Compare, storico e adattatore chunk ReaEQ.

MIDI_GetRecentInputEvent viene letto esclusivamente dal timer GUI principale. Il batch è limitato a 256 eventi e applicato in ordine cronologico. Il learn ignora gli eventi anteriori all'armamento. La cattura non modifica immediatamente il parametro. Non esistono audio hook né chiamate API REAPER dal worker importazione. Uscita/perdita focus ferma l'elaborazione MIDI; i campi testuali e F8 drenano gli eventi senza applicarli. Nessun I/O di profilo per ogni movimento CC: si salva solo a learn/cambio preferenza/modifica struttura.

Pickup e anti-jitter sono nel componente puro MidiControl.h. Il contesto attivo (progetto, GUID traccia/FX, take) è verificato prima dei comandi; cambio FX cancella pickup. Compare usa un archivio di sessione in memoria separato per identità; non scrive RPP o ExtState. Uno snapshot ordinario con nomi/numero parametri diversi è rifiutato prima delle scritture.

ReaEqChunk.h riconosce solo la struttura Lua 8 + 33*N + 32 byte. Il reset globale ReaEQ usa il chunk, ricostruisce il numero parametri e ripristina Bypass/Wet/Delta separatamente. Un formato sconosciuto viene rifiutato. I virtuali delle bande non sono ancora migrati.

Storage conserva worker, backup, verifica, marker d'importazione e gestione dei conflitti. Sono attivi soltanto Plugins (.fx) e Tracks (.tp), oltre a Settings/Backups. File esterni ai due rami non vengono letti né modificati. FxOrder salva sezioni gestite conservando sezioni sconosciute e campi Extra; controlla il digest letto e crea backup delle modifiche. Rimane la finestra di concorrenza interprocesso del controllo/sostituzione preesistente.

Lo storico importa in sola lettura l'ExtState Lua OSARA_FX_Params_Param_Browse/recent_searches_v1 se manca il nuovo file, e salva fino a 20 ricerche in Settings/recent_searches.txt. Non viene modificato l'ExtState Lua.
