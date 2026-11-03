# TEST62.8 — Import TXT Lua selettivo: FX Params e Track Params

Questa revisione parte dal sorgente completo TEST62.7. Mantiene tutte le funzioni precedenti.

## Nuova azione

- Action List: **LReaParams: Import selected legacy TXT files**.
- Menu REAPER: **Extensions > LReaParams > Import selected TXT files**.
- Si apre la normale finestra di selezione file di REAPER/Windows. È predisposta per scegliere uno o più file `.txt`, anche con Ctrl/Shift.
- La posizione iniziale è la cartella risorse REAPER `Scripts/Lo-lo - Scripts/Utility/Scripts`, dove sono disponibili le sottocartelle `Plugins` e `Tracks` dei vecchi Lua. Se la cartella non esiste, usa `LReaParams` o il percorso delle risorse REAPER.
- Con Windows Explorer apri `Plugins` per gli FX o `Tracks` per i Track; scegli uno o più TXT e conferma. Per importare TXT da entrambe le cartelle, ripeti l'azione una volta per cartella.
- Nessuna nuova finestra complessa: il dialogo nativo resta utilizzabile con NVDA.

## Conversione

Il tipo non è indovinato dal nome: è verificato dal parser C++.

- `Version=3`, profilo legacy FX → `LReaParams/Plugins/<nome>.fx`.
- `Version=2`, profilo legacy Track → `LReaParams/Tracks/<nome>.tp`.
- Se l'origine è in una sottocartella del ramo storico corrispondente, la sottocartella è preservata.
- TXT non valido: rifiutato, nessun profilo creato. Il tipo non viene dedotto dalla cartella.
- I profili convertiti usano `LREAPARAMS_PROFILE_V1` e conservano l'intero payload legacy, senza alterare valori o MIDI mapping.

## Protezioni

- I TXT scelti **non vengono modificati, spostati o cancellati** (anche se si trovano nella cartella LReaParams attiva).
- Una copia di sicurezza identificata dall'hash va in `LReaParams/Backups/`.
- Un `.fx` o `.tp` già esistente viene lasciato intatto; se diverso, il candidato convertito va in `LReaParams/Settings/ImportConflicts/` (non viene applicato automaticamente).
- Ripetere l'importazione di file invariati non duplica o riscrive i profili.
- Al termine NVDA riceve riepilogo: convertiti totali, FX, Track, invariati, conflitti, non riconosciuti, errori.
- L'importatore generale **LReaParams: Import legacy profiles** è mantenuto, con la vecchia richiesta di conferma e la conversione in blocco. Anche la scelta di importazione iniziale resta invariata.

## Attenzione al nuovo Track Params

La conversione a `.tp` **non equivale alla migrazione automatica di ogni informazione Track Lua nel progetto corrente**.

- `Tracks/Track CC Map.tp` è riconosciuto dalla TrackMemory attuale come sorgente *read-only* per la prima apertura di un progetto.
- I vecchi profili Track che contengono `TrackGUID` e assegnazioni di un progetto/traccia specifici sono convertiti e conservati, ma la struttura Track Params attuale usa `Tracks/Projects/<progetto>/<nome>_<hash>.tp`: l'import selettivo non associa automaticamente un vecchio GUID a un progetto corrente.
- Non modificare il nome o la collocazione dei profili di progetto creati da Track Params pensando di collegarli alla vecchia importazione.

## Prove consigliate in Windows

1. Apri l'azione nuova e premi Escape: nessuna modifica e messaggio di annullamento.
2. Nella sottocartella `Plugins`, seleziona 2–3 vecchi TXT con Ctrl+click. Verifica altrettanti `.fx` in `LReaParams/Plugins` e che la Custom Order venga letta dopo aver riaperto FX Params.
3. Seleziona `Tracks/Track CC Map.txt` e verifica `LReaParams/Tracks/Track CC Map.tp`. Per collegare il contenuto a un progetto nuovo, controlla la inizializzazione del profilo Track per quel progetto.
4. Ripeti l'azione e verifica il conteggio `unchanged`.
5. Modifica un profilo nativo e reimporta il TXT: il profilo modificato resta, il candidato va in `Settings/ImportConflicts`.
6. Controlla che la vecchia azione di importazione totale e la domanda iniziale Y/N continuino a funzionare.

Test C++ aggiunti in `Testing/ProfileTests.cpp`: selezione mista FX/Track, duplicati nella scelta, conversione/roundtrip, inviolabilità TXT, import ripetuto, conflitto, file non valido e cancellazione. Si eseguono con CTest su GitHub Actions Windows. I test statici non attestano la compilazione nativa.
