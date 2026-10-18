> Nota storica: in TEST55.5 **Ctrl+Maiusc+M** ha sostituito Alt+F8 (Track Memories) e F8 (FX Memories). Vedere [TEST55.5](TEST55_5_UNIFIED_MEMORY_SHORTCUT.md).

# TEST55.4 — Memorie uniformate con FX Params

Base: TEST55.3. Si lavora solo sul sorgente; la compilazione resta su GitHub Actions.

## MIDI CC

- Un CC Fixed e un Floating sono **silenziosi per impostazione predefinita**: muovere il controller non provoca messaggi di LReaParams. Tab e lettura manuale continuano a funzionare.
- **Ctrl+T** modifica il parlato MIDI del parametro **fisico** della traccia corrente o del Send/Receive selezionato. Questa preferenza è individuale e persistente nel `.tp` del progetto. Si identifica con gli stessi GUID dell'associazione CC Fixed.
- L'associazione Fixed continua a controllare la traccia originale anche quando ci si sposta su un'altra. Il Floating segue il cursore. Le preferenze generiche `[CCSpeech.*]` storiche non sono cancellate ma non vengono propagate automaticamente alle nuove associazioni fisiche.
- Le modifiche di valore fatte tramite tastiera non sono influenzate dall'impostazione del parlato MIDI. Ctrl+Maiusc+T conserva il significato distinto.

## Gestione delle memorie

- FX Params: **F8** apre sempre FX Memories, anche senza passare da F7; F7 mantiene il proprio editor. `LReaParams: FX Memories` usa lo stesso gestore.
- Track Params: **Alt+F8** apre Track Memories; F7 e F8 normali restano disponibili per le future sezioni hardware e ReaRoute. `LReaParams: Track Memories` usa lo stesso gestore.
- Track Memories mostra **solo le preferenze diverse dai default**: CC associati, Step diversi da 0, parlato di modifica disattivato, parlato MIDI attivato, slot di traccia occupati e range Volume personalizzati.
- I cursori F1/F2/F3 continuano a essere ricordati automaticamente per il ripristino, ma **non** sono presentati come memorie personalizzate. La quinta categoria del gestore è ora `Volume Ranges`.
- Un profilo nuovo può avere tutte le categorie vuote: il gestore annuncia `Track Memories. No memories`. Le frecce ai bordi restano silenziose.
- `Canc` su una memoria ripristina il default. Uno Step portato a 0 e il parlato MIDI portato a Off vengono rimossi dalle memorie e dal `.tp` senza creare chiavi vuote; le altre sezioni e il formato originale del progetto rimangono intatti.
- Gli slot vuoti non compaiono in Track Memories: usa **Ctrl+Maiusc+F1…F12** da F1 per salvarli, **Ctrl+F1…F12** per richiamarli, poi Canc nella memoria per svuotare uno slot occupato.

## Prove manuali in REAPER + NVDA

1. Aprire un progetto con un `.tp` senza personalizzazioni: Alt+F8 dovrebbe annunciare `Track Memories. No memories` e nessuna riga default.
2. Impostare Step +2 sul Pan di F1, rientrare in Alt+F8 e trovare soltanto questa voce; riportarlo a Step 0 e controllare che scompaia.
3. Associare CC 10 al Pan di Bass e CC 11 al Pan di Drums. Entrambi devono essere silenziosi, anche cambiando cursore. Attivare Ctrl+T su Bass e controllare che parli **solo Bass**.
4. Riavviare REAPER e verificare gli stati dei due CC. Disattivare il parlato di Bass da Track Memories e verificare che la riga sparisca senza togliere il CC Fixed.
5. Salvare uno slot traccia Ctrl+Maiusc+F1; verificare che la categoria mostra solo lo slot 1. Richiamarlo e poi eliminarlo dal gestore.
6. Provare FX Params F8 dalla griglia normale, dalla modalità Value e dall'editor F7, oltre all'azione autonoma; Esc deve ritornare al contesto corretto.

Non sono stati eseguiti CMake/MSVC, build, test C++ locali né verifiche REAPER/NVDA: le verifiche statiche non sostituiscono la prova reale.
