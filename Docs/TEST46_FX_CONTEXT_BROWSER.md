# LReaParams 0.0.46.1 — FX Chain, Take FX e browser (solo sorgente)

Partenza: 0.0.45 già collaudata dall'utente. Lua di riferimento:
`Legacy/Speak FX Params - TrackTake Navigator.lua`, in particolare le funzioni
`handle_fx_browser_key`, `switch_item_context_by_direction`,
`switch_take_context_to_current_track_fx` e `open_current_context_fx_chain`.

## Tastiera FX Params

| Gesto | Funzione | Note |
|---|---|---|
| Ctrl+P | Passa alla lista FX interna e viceversa | Il cursore browser è indipendente dalla selezione della griglia fino a Invio |
| Browser Su/Giù o Ctrl+Su/Giù | FX precedente/successivo | Solo nella catena di apertura, limiti silenziosi |
| Browser PgSu/PgGiù | Avanza di cinque FX | Non attraversa Master ↔ Monitor |
| Browser Home/End | Primo/ultimo FX della colonna | Ctrl+Home/End equivalenti |
| Browser Sinistra/Destra | Nessun cambio Master/Monitor | Le catene sono due browser separati nella 0.0.46.3 |
| Browser lettera/cifra | Cerca ciclicamente per iniziale del nome FX | Maiusc inverte la direzione |
| Browser Invio | Apre la griglia dell'FX evidenziato | Resta nella stessa finestra LReaParams |
| Browser Ctrl+B | Bypass FX evidenziato | Non altera altri FX |
| Browser Ctrl+D | Delta Solo dell'FX evidenziato | Disponibile se host espone il wrapper Delta |
| Browser Ctrl+Maiusc+D | Disattiva tutti i Delta Solo del progetto | Azione globale |
| Browser Ctrl+Alt+B | FX evidenziato Offline/Online | Resta nello stesso browser |
| Browser Ctrl+Maiusc+Su/Giù | Sposta fisicamente l'FX nella stessa catena | Usa API REAPER e Undo; non supera il confine Master/Monitor |
| Ctrl+Sinistra/Destra | Item precedente/successivo con FX | Nella traccia corrente; dagli FX traccia preferisce item selezionato con FX |
| Ctrl+W | Da Take FX ritorna ai Track FX | Non passa a tracce di altre istanze |
| Ctrl+Maiusc+Su/Giù nella griglia | Traccia precedente/successiva con FX | Mantiene lo shortcut preesistente; salta tracce prive di FX |
| Ctrl+Pagina Su/Giù | Riservato / libero | LReaParams non intercetta questa combinazione, nemmeno nel browser |
| Ctrl+Maiusc+F | Apre la FX Chain nativa dell'FX corrente | Rilascia prima focus/tastiera di LReaParams |
| Alt+Maiusc+F | Apre il browser FX nativo REAPER (40271) | Rilascia prima focus/tastiera di LReaParams |
| Ctrl+Su/Giù nella griglia | FX precedente/successivo | Funzione esistente preservata |
| Ctrl+Maiusc+Su/Giù nella griglia | Traccia precedente/successiva | Funzione esistente preservata |

Il browser interno non modifica il plugin visitato prima di Invio, salvo comandi
espliciti di bypass/Delta e spostamento fisico. F7 viene chiuso entrando nel
browser e le ricerche filtrate vengono cancellate senza cancellare le selezioni
salvate nei profili. Master FX e Monitor FX vengono presentati come **due browser separati**: Ctrl+P rimane nella catena di ingresso, senza possibilità di passare all’altra premendo Sinistra/Destra.

## Sicurezza e memoria

- Validazione del progetto, traccia, take e GUID del plugin, prima di entrare in
  un contesto diverso. Cambio fallito: ripristino della navigazione precedente.
- Le posizioni di sessione per ciascun FX continuano a usare GUID e contesto.
  `LastParam` condiviso nel profilo `.fx` conserva la memoria dopo il riavvio.
- Dopo uno spostamento nella catena, risincronizzazione tramite GUID invece di
  indici obsoleti; un contesto non più riconoscibile chiude il navigatore.
- Finestra FX Chain e browser nativo aperti soltanto dopo che l'estensione ha
  disattivato il proprio controllo di focus, per l'accessibilità NVDA/OSARA.
- Nessuna modifica al motore dei parametri di Track Params, ReaEQ, ReaComp,
  ReaGate, Clipboard, automazioni, MIDI e trasporto.

## Prove manuali indispensabili (GitHub Actions + REAPER/NVDA)

1. Aprire FX Params su una traccia con tre FX. Ctrl+P: spostarsi col browser,
   verificare che la griglia non cambi prima di Invio; Invio seleziona l'FX.
2. Browser con plugin bypassato: ascoltare `Bypassed` e premere Ctrl+B.
3. Master con FX normali e Monitor FX: aprire Ctrl+P da Master e verificare
   che NON compaiano Monitor FX. Ripetere da Monitor e controllare il contrario.
   Spostare un FX con Ctrl+Maiusc+Su/Giù nella catena corrente; verificare
   GUID, assenza di passaggi all’altra catena e Undo di REAPER.
4. Aprire un Take FX dalla traccia con Ctrl+Destra; passare all'item successivo,
   poi Ctrl+W e Ctrl+Maiusc+Freccia Giù. Verificare titoli e posizioni salvate.
5. Da Take FX in Grid e dal browser, Ctrl+Maiusc+F apre la corretta catena.
   Alt+Maiusc+F deve dare focus al browser nativo REAPER.
6. Ripetere con Ctrl+Spazio, F7, F8, MIDI e Clipboard per scoprire regressioni.
7. Da FX Chain aperta su traccia diversa dalla selezionata, entrare con l'azione
   FX Params e verificare che la lista FX focalizzata determini il contesto.

## Limiti ancora da verificare

- REAPER/OSARA devono confermare in runtime i dettagli del focus nelle finestre
  native e lo spostamento degli FX su versioni/plugin differenti.
- Non è stato implementato un editor gerarchico per sottocatene FX Container.
- Il browser FX interno non è un editor di aggiunta/eliminazione dei plugin: per
  aggiungere FX si usa il browser nativo REAPER tramite Alt+Maiusc+F.
- Non è stata eseguita compilazione locale, CMake, MSBuild o Visual Studio.
  Le suite Python testano struttura e regressioni sorgenti, non il funzionamento
  con Windows/NVDA o il corretto comportamento delle API in REAPER.
