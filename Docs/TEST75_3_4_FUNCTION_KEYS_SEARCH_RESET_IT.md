# TEST75.3.4 – Tasti funzione, ricerca e Reset nelle Preferenze

Questa prova deriva dalla TEST75.3.3. Versione ufficiale invariata: 0.0.75.

## Modifiche

- La cattura delle scorciatoie in Ctrl+P permette **F1–F12**, anche con Ctrl/Alt/Shift, inclusi F12 e Alt+F12. **Shift+F1** rimane dedicato all'aiuto di LReaParams. Restano protetti i comandi di sicurezza della finestra e i modificatori NVDA: Ctrl+P, Esc, Tab, Insert, Numpad Insert e altri gesti già riservati.
- In **Shortcuts > FX Params, Track Params o Render**, **Alt+S** porta il focus al campo `Search by shortcut`.
- Dentro il campo di ricerca, **Alt+S, Alt+R, Alt+O, Alt+C** (e gli altri tasti) sono **dati da cercare**, non comandi dei pulsanti Preferenze. Anche F1–F12 sono interrogabili; se la voce non esiste viene annunciata l'assenza, mantenendo la selezione corrente.
- Fuori dal campo di ricerca/cattura, **Alt+R** apre la conferma del pulsante **Reset section**; **Alt+O** salva e **Alt+C** annulla come prima.
- **Invio con focus su Reset section** apre soltanto la domanda di ripristino, senza eseguire OK. La domanda ha **No preselezionato**. Sì modifica le sole impostazioni in memoria della sezione corrente. **OK** successivo salva e **Annulla o Esc** nella finestra Preferenze scartano le modifiche non salvate.
- Per FX/Track, se F12 non è stato personalizzato, resta il precedente comportamento del navigatore. Se è stato personalizzato, la combinazione viene gestita dalla mappa di quella sezione. Render conserva il proprio motore automatico e le precedenze delle personalizzazioni.

## Test manuali su REAPER Windows, NVDA/OSARA

1. Ctrl+P, Shortcuts > FX Params. Scegli un comando e premi Invio. Assegna **F12**, poi OK. Rientra e verifica la persistenza e la ricerca di **F12**. Ripeti con F1 e una combinazione modificata (per esempio Ctrl+Alt+F10), verificando che il tasto venga annunciato correttamente.
2. Senza altre preferenze attive, prova il precedente comportamento di F12 nel navigatore. Dopo aver personalizzato F12, verifica che esegua solo l'azione LReaParams assegnata nel contesto corretto. Prova anche F12 dentro Shift+F1: deve **solo essere annunciato**.
3. In Shortcuts > Render premi **Alt+S** partendo dall'elenco: il focus deve andare al campo di ricerca. Interroga **Alt+S**, **Alt+R**, **Alt+O**, **Alt+C**: non devono spostarti al campo di ricerca, aprire Reset, salvare o chiudere le Preferenze.
4. Con il focus fuori dalla ricerca, premi **Alt+R**. La domanda deve apparire con No preselezionato. Premi Invio: non deve ripristinare né chiudere le Preferenze.
5. Con il focus sul pulsante Reset section, premi **Invio**: deve apparire la stessa domanda. Seleziona Sì e premi Invio: Ctrl+P deve restare aperto. Premi **Annulla** o **Esc**: nulla deve essere salvato.
6. Ripeti Reset e conferma Sì, poi **OK**: deve ripristinare soltanto la sezione attiva. Verifica dopo riapertura Ctrl+P.
7. Verifica anche Alt+R mentre sei nel campo di **assegnazione** di uno shortcut: dev'essere registrabile come nuova combinazione senza aprire Reset.
8. Prova gli stessi comportamenti nella sezione FX Params e Track Params, non soltanto in Render.

I test automatici forniti sono **statici**, non equivalgono a una compilazione MSVC o a prove reali con i lettori di schermo.

## Pubblicazione dei sorgenti

Dalla radice del clone Git esistente:

`Tools\push_lreaparams.cmd "Allow F1-F12 shortcuts and fix Preferences search/reset accelerators"`

Non utilizzare push forzati; non modificare index.xml o lo storico ReaPack.
