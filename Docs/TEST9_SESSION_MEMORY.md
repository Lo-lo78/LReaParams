> Documento storico TEST30. Per stato attuale e limiti prevalgono Status.md e FxCommandMatrix.csv.

# TEST9 — Memoria FX per la sessione di REAPER

Non compilare localmente. Compilazione esclusiva su GitHub Actions.

## Obiettivo
- Apri FX Params, spostati sull'FX 3 con Ctrl+Giù, seleziona un parametro
  intermedio e chiudi con Escape. Riaprendo FX Params nello stesso contesto,
  rientri nell'FX 3 **e nello stesso parametro** (senza browser).
- La memoria rimane nella DLL per l'intera sessione di REAPER. Non usa ExtState,
  non scrive `.fx` o altri file, e non modifica il progetto RPP.
- La memoria è separata per progetto, GUID della traccia e take, quindi
  cambiare traccia non sovrascrive l'ultimo FX dell'altra.
- Ricorda anche F1/F2 (altezza griglia) e Alt+Sinistra/Destra (scala passi)
  separatamente per ogni FX visitato.
- Riconosce l'FX dal GUID reale: se gli FX sono riordinati, ritrova quello
  giusto. Se lo stesso FX è stato sostituito, cerca per nome/area/occorrenza,
  come nel Lua originale. Se non è più presente, usa la selezione visibile
  o il primo FX con parametri, senza inventare una posizione.
- Se, mentre LReaParams non è attiva, si seleziona esplicitamente un altro FX
  in una catena aperta, la nuova selezione ha priorità rispetto alla memoria.
- Resta invariata la lettura NVDA+Su (solo parametro + valore), NVDA+T
  (nome FX e traccia), Ctrl+Su/Giù (FX preced./succ.), bordi silenziosi.

## Prove in REAPER
1. Traccia A con 3 FX: visita FX 2, parametro 30; esci e rientra.
2. Passa alla traccia B, visita FX 1; torna ad A e verifica FX 2 / parametro 30.
3. Crea 2 istanze dello stesso plugin su A: prova che i due GUID distinguano
   le posizioni memorizzate.
4. Sposta un FX nella catena; verifica la selezione per GUID.
5. Chiudi e riapri REAPER: nessuna memoria di sessione deve sopravvivere.
6. Apri la catena FX e seleziona un altro effetto con il mouse mentre il
   navigatore è chiuso: LReaParams deve entrare nell'FX selezionato.
7. Riporta F1/F2 a un valore personalizzato, chiudi e riapri FX Params.

Nota: il Lua storico salva anche dati persistenti fra sessioni. TEST9 implementa
volutamente la memoria **della sola sessione**, secondo la nuova specifica.
