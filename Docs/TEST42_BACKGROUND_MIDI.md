# TEST42 — MIDI CC in background (0.0.42)

## Scopo

Questa versione conserva il motore MIDI del Lua durante **Ctrl+Q**: la finestra FX Params rilascia completamente focus e tastiera a REAPER, ma il polling MIDI continua dal **timer main-thread dell'estensione**, senza usare un thread audio, hook globale della tastiera o un loop che richieda la finestra aperta.

Non cambia la gestione Track Params, Grid/Value, F7, memorie di sessione, prefissi NVDA `Auto`, shortcut FX Chain e formato dei profili `.fx`.

## Uso

1. Aprire `LReaParams: FX Params` su una traccia con FX.
2. Impostare i link usando **Ctrl+Alt+C** (Learn), **Shift+C** (Fixed on/off) oppure **Ctrl+Shift+C** (Floating; attendere il primo CC).
3. Premere **Ctrl+Q**: torna il focus alla finestra principale REAPER. Se una modalità MIDI è attiva, si sente `Back to REAPER. MIDI active`; altrimenti solo `Back to REAPER`.
4. Muovere il controller MIDI: il plugin lasciato in background continua a ricevere i CC, con il **pickup** e il filtro anti-jitter già presenti nella 0.0.41. L'aggancio non provoca salti durante il Learn o il primo movimento.
5. Per fermare esplicitamente la modalità in background, eseguire dall'Action List **`LReaParams: Stop background MIDI`** (`_LREAPARAMSSTOPMIDIBACKGROUND`). Non serve assegnarle una scorciatoia.
6. Riaprendo FX Params sul **medesimo FX**, il controllo MIDI viene riassorbito dal navigatore in primo piano per impedire doppie applicazioni dei CC. Il pickup viene riarmato.

È supportato **un solo contesto MIDI parcheggiato per volta**. Un nuovo Ctrl+Q sostituisce il precedente. Il contesto è associato a progetto, GUID della traccia, take eventuale, GUID dell'effetto, indice e layout dei parametri. Se il progetto o l'FX cambia/non è più valido il contesto si ferma automaticamente senza inviare CC a un altro plugin. Un diverso FX aperto in primo piano può coesistere con un contesto parcheggiato: sono applicati controlli alle rispettive identità.

## Funzioni preservate / aggiunte

- Mappa fixed e stato Shift+C persistono nel profilo FX, senza introdurre nuovi file dati.
- Floating CC conserva il parametro e l'aggancio durante Ctrl+Q; poiché la griglia non è più focalizzata segue il parametro lasciato selezionato. Un nuovo ingresso in FX Params ripristina la navigazione normale.
- Ctrl+T continua a delimitare il parlato MIDI per parametro, con un annuncio accorpato al massimo ogni 180 ms.
- F8 visualizza ora i collegamenti con `Channel N. CC M` al posto delle due cifre separate da TAB. Canc continua a eliminare la singola associazione e il native learn collegato.
- Disarm Learn con Esc o cancellazione F8: comportamento invariato in primo piano. In background non viene intercettata la tastiera; usare l'azione Stop background MIDI per fermare l'apprendimento parcheggiato.

## Prove obbligatorie tramite GitHub Actions + REAPER/NVDA

- [ ] Windows MSVC x64: compilazione DLL e CTest del workflow eseguiti **dall'utente**, non localmente.
- [ ] Un FX su Track 1, Fixed on, Ctrl+Q, REAPER TCP con focus: CC aggiorna l'FX; i tasti REAPER non vengono catturati.
- [ ] Il controller parte lontano dal valore: non salta, si aggancia solo dopo crossing/tolleranza; modificare parametro con mouse/automazione, poi verificare riarmo.
- [ ] Ctrl+Shift+C attiva Floating, selezionare parametro, Ctrl+Q, CC segue quel parametro. L'apprendimento iniziale avviene senza salto.
- [ ] Learn Ctrl+Alt+C, Ctrl+Q, inviare primo CC: il link viene salvato; controllare F8 e rientrare in griglia.
- [ ] Dalla TCP aprire Track Params: continua a funzionare senza interrompere il CC parcheggiato. Tornare a FX Params dello stesso FX: un solo motore MIDI attivo.
- [ ] Provare Track FX, Take FX, Master e Monitor FX. Su ogni tipo controllare che la mappa usi il GUID giusto.
- [ ] Cambiare progetto attivo o rimuovere l'FX mentre il MIDI è parcheggiato: deve arrestarsi in modo sicuro senza controllare un altro effetto.
- [ ] Aprire un altro FX con lo stesso nome in un'altra traccia: non deve avere il valore alterato dal background destinato al primo.
- [ ] Abilitare Ctrl+T su un solo parametro; controllare che il parlato resti sintetico e non duplichi gli annunci della griglia.
- [ ] Verificare F8 colonna MIDI: nome parametro, `Channel`, `CC`, Canc singolo, ritorno a FX Params e modifica corretta dei link.
- [ ] Eseguire l'azione `Stop background MIDI`, poi verificare che i CC non modifichino più l'FX parcheggiato.
- [ ] Riavviare REAPER: non deve esserci un contesto parcheggiato; la mappa fixed persistente è ricaricabile dal profilo.

## Limiti e cautela

Non c'è verifica locale del binario né una prova con dispositivo MIDI. I test Python controllano soltanto il testo del sorgente e la compatibilità del formato. La modalità non permette di controllare contemporaneamente ogni FX di tutte le tracce: il Ctrl+Q del Lua riguarda il **contesto FX lasciato in background**. Lo stato Floating in background è temporaneo e non viene ripristinato dopo il riavvio di REAPER. Il MIDI Learn nativo REAPER e l'elaborazione sul thread audio non sono modificati.

Rimangono le lacune funzionali di `Docs/Status.md`: virtuali ReaEQ/ReaComp/ReaGate, editing MIDI avanzato della colonna F8, snapshot clipboard completo, browser FX e operazioni su item/take. Non considerare questa versione una migrazione integrale del Lua.
