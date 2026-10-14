# Stato della consegna — 0.0.3 TEST2 Native Test

Progetto sorgente GitHub-ready, senza compilazioni, binari o test runtime locali.
Il workflow Windows x64 eseguirà la prima compilazione e i test C++.

## Migrazione effettivamente implementata

| Componente | Stato |
| --- | --- |
| DLL, menu Extensions, 8 azioni stabili | Presente, non testato in REAPER |
| OSARA outputMessage e Shortcut Help | Integrato, verifica in REAPER necessaria |
| Due backend tastiera senza finestra | Sperimentali, da collaudare |
| FX Params | Rilevamento FX da track/take selezionati; FX singolo diretto, browser multi-FX e Monitor FX master; griglia/Value, normalizzati reali e Undo, ricerca Ctrl+F, Home/End/Page |
| Track Params | Nuova navigazione nativa per otto controlli e sends/receives |
| Parameter Library | Solo importazione `.pp`; azione informa che non è migrata |
| Importer `.fx`, `.tp`, `.pp` | Conserva TXT storici, backup e conflitti, worker asincrono |
| Profilo FX applicato e preferenze ExtState | Non implementati |
| Test sorgente statici | Python audit eseguito, PASS |
| Build GitHub Actions per TEST1 FIX1 riuscita; TEST2 modificato solo sorgente, non compilato né testato in REAPER |

## Cosa manca prima di considerare LReaParams equivalente ai Lua

1. Verificare compilazione MSVC, OSARA e cattura tastiera in GUI FX flottanti,
   docked, custom, bridged, e durante cambiamenti di focus.
2. Portare navigazione avanzata FX: ordine e gruppi personalizzati, pin,
   preset e nomi, memoria di selezione, tasti originali, automazione,
   parametri virtuali, pulsanti ed editor.
3. Portare Track Params completo: pagine tracce, routing, tutte le operazioni
   avanzate, MIDI CC, scope progetto e associazioni a GUID.
4. Implementare Parameter Library (selezione, editing, richiamo sicuro dei
   valori e comunicazione interna). L'azione attuale non apre un navigatore.
5. Caricare e applicare i profili `.fx/.tp/.pp` dopo l'importazione, gestire
   salvataggio e migrazione delle preferenze REAPER ExtState.
6. Controllare Undo e automazione su più DAW/FX, threading, shutdown mentre
   il worker importa, possibili modifiche dinamiche di GUI/nome parametri.
7. Eseguire test di regressione per l'equivalenza delle scorciatoie documentate
   in `Docs/LuaShortcutEvidence.csv`; non inferire che la matrice sia completa.

**Non usare questa versione come sostituta definitiva dei Lua.** Le funzioni
non portate rimangono in `Legacy` e sono esplicitamente previste.
