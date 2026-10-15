# Aggiornamento TEST27 (0.0.28): il F12 SENZA modificatori ora resta libero e riservato a LReaParams, senza inoltro a OSARA e senza chiusura della finestra di navigazione. Ctrl+F12 e Ctrl+Maiusc+F12 mantengono la memoria 12; Alt+Maiusc+Frecce naviga i selezionati in F7. Le istruzioni storiche su F12/Alt+Frecce riportate sotto descrivono versioni precedenti e sono superate. Per il collaudo attuale: Docs/TEST27_KEYS_F12.md.

# Architettura — 0.0.2 Native Test (estensione della Fase 0)

`Extension.cpp` è il proprietario del lifecycle. Copia reaper_plugin_info_t,
carica soltanto le API effettivamente richieste dagli header ufficiali, registra
azioni senza binding, toggle state, menu e timer. Inizializzazioni parziali sono
smontate dal distruttore. L'entry point esportato è ReaperPluginEntry; nessuna
elaborazione viene avviata in DllMain.

`InputRouter` registra un solo backend per volta, solo mentre uno dei navigatori nativi è attivo.
L'accelerator ha isLocal=true e segue i codici di ritorno del SDK. Il secondo
backend WH_GETMESSAGE è limitato al thread della main window. Processa solo
messaggi rimossi dalla coda (PM_REMOVE), passa gli altri hook e neutralizza il
messaggio catturato prima di TranslateMessage. Non usa SendInput, PostMessage
per riprodurre il comando, WH_KEYBOARD_LL, polling di tutti i virtual key o
finestre ausiliarie. Una coda fissa di 128 elementi trasferisce i key-down al
timer principale; il riempimento provoca uscita, non accumulo illimitato.

Il router non chiama API REAPER dal callback di cattura: verifica solo segnali
Win32 e lo stato del controller. Il timer ricontrolla Shortcut Help prima di
svuotare la coda. F12 provoca immediatamente richiesta di uscita e passa intatto.
I key-up catturati sono assorbiti nel contesto attivo per evitare doppie azioni;
in uscita la cattura viene rimossa e non si simulano pressioni/rilasci.

`FxNavigator` mantiene un target di test fissato all'attivazione. Prima di ogni
azione e a ogni timer attivo convalida progetto corrente, track/take pointer,
GUID traccia e FX, numero e nome del parametro. Un riordino inatteso termina la
sessione; non usa indici esistenti come prova di identità. Le modifiche avvengono
attraverso TrackFX/TakeFX_SetParamNormalized, seguite da EndParamEdit e Undo.
Non c'è callback audio, registrazione audio hook, applicazione automatica di
preset o copia di routing. Non vengono scritti extstate o blocchi RPP privati.
Le modifiche reali ai parametri restano naturalmente stato del progetto REAPER.

`Navigator` è una piccola interfaccia comune per i due controller, con
`InputRouter` come unico proprietario dell'acquisizione dei tasti. La selezione
FX/Track ferma il router precedente prima di attivare il nuovo. Il nuovo
`TrackNavigator` conserva progetto e GUID della traccia selezionata, verifica
che la selezione e il numero di mandate/ricezioni non cambino e utilizza le
API native di volume, pan, flags e routing con Undo. È un sottoinsieme reale
(non la navigazione Track Lua completa), senza finestre o editor dedicati.

Il menu FX ora offre ricerca ASCII con Ctrl+F e salti Home/End/PageUp/PageDown.
Non vengono applicati automaticamente i profili `.fx` importati. Non ci sono
pagine F1–F4 di Track Params né richiamo `.pp`.

`Profile.cpp` è indipendente da REAPER/Win32. `Storage.cpp` gestisce filesystem
Unicode, SHA-256 CNG, transazioni e worker. Il worker riceve soltanto la path
risorse, non pointer REAPER. Il timer recupera un piccolo riepilogo completato,
senza attendere lavoro ancora in corso. Non viene avviata una scansione a ogni
tasto. All'unload il worker viene annullato e raggiunto prima di scaricare il codice.

OSARA viene risolto con GetFunc a richiesta: `void (*)(const char*)` per
osara_outputMessage e `bool (*)()` per osara_isShortcutHelpEnabled. Entrambe
sono richieste per avviare la cattura. L'assenza non causa un crash e viene
spiegata all'avvio manuale del navigatore. Non si assume che la funzione
ReaScript vararg abbia lo stesso ABI della funzione C++.

La gestione avanzata SpeechService (ritardo/cancellazione/coalescing),
ContextResolver con restore, SettingsStore/ExtState e i tre controller completi
saranno separati nella migrazione. Qui non sono sostituiti da classi vuote.

## ID stabili

Per NamedCommandLookup REAPER aggiunge il prefisso underscore agli ID:

| ID registrato | Azione |
| --- | --- |
| LREAPARAMSFXPARAMS | FX Params |
| LREAPARAMSTRACKPARAMS | Track Params, controlli base implementati |
| LREAPARAMSPARAMETERLIBRARY | Parameter Library, porting pendente |
| LREAPARAMSEXIT | Exit current navigation |
| LREAPARAMSIMPORTLEGACY | Import legacy profiles |
| LREAPARAMSOPENDATAFOLDER | Open Data Folder |
| LREAPARAMSSETTINGS | Settings |
| LREAPARAMSABOUT | About |

Il menu è aggiunto esclusivamente dal callback per `Main extensions`, come
richiede il SDK. Non si memorizzano handle di sottomenu. Nessuna assunzione sul
binding Alt+X dell'installazione dell'utente.
