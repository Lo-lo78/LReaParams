# Stato TEST7 (0.0.8): solo sorgente; compilazione tramite GitHub Actions.

NVDA+Freccia Su usa EDIT Win32 di sola lettura; F2/F3 ora hanno 14 campi verticali per ogni colonna send/receive. Invio commuta immediatamente gli interruttori Track. Routing audio avanzato non editabile. Collaudo: `Docs/TEST7_NVDA_TRACK_COLUMNS.md`.

# Stato della consegna — 0.0.7 TEST6 Focus Owner

Progetto sorgente GitHub-ready, senza compilazioni, binari o test runtime locali.
Il workflow Windows x64 eseguirà la prima compilazione e i test C++.

## Migrazione effettivamente implementata

| Componente | Stato |
| --- | --- |
| DLL, menu Extensions e 9 azioni, 2 memorie riservate | Presente, non testato in REAPER |
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

## TEST4

- Annuncio vocale del titolo virtuale delle due navigazioni a fine attivazione,
  senza creare HWND né alterare il titolo di REAPER.
- Menu `Memories` dedicato con FX Memories e Track Memories ancora da
  implementare, e Parameter Library da migrare.
- Riserva F1–F11 in FX Params e F4–F11 in Track Params.
  F1–F3 di Track Params restano operativi per la navigazione delle pagine;
  F12 rimane a OSARA. Non sono ancora implementate funzioni di memoria.


TEST5 0.0.6: ripristinato FX F1/F2 per griglia; introdotta finestra Win32 titolata da un pixel fuori schermo per NVDA+T (attiva solo nella navigazione, disattivabile dal menu). Prova runtime non eseguita.


TEST6 0.0.7: la finestra Win32 da 1 px ora è proprietaria reale della tastiera (messaggi dalla WindowProc alla coda InputRouter). Corretto il rifiuto del contesto della finestra che in TEST5 provocava il ritorno al TCP. I tasti non gestiti non vengono mandati a REAPER; recupero del focus dopo un tasto di modifica, senza ricattura continua. Non compilato localmente.

## TEST9 — Memoria sessione FX (sorgente, non compilato)

FX Params ha una memoria C++ in RAM per contesto progetto/traccia/take.
Ripristina GUID dell’ultimo FX e posizione del parametro, più altezza della
griglia e scala dei passi. Rispetta una selezione FX esplicitamente cambiata
nella catena REAPER mentre il navigatore non è attivo. Nessun salvataggio
permanente e nessuna migrazione completa dei profili ancora. Verifica runtime
necessaria dopo la compilazione con GitHub Actions.

## TEST10 — limiti silenziosi, Alt+Home/End, titolo NVDA (sorgente)

In FX e Track, Alt+Home indica ora il valore massimo e Alt+End il minimo.
Le selezioni immutate ai limiti della griglia non provocano reinizializzazioni
del focus; lo stato del controllo EDIT viene aggiornato soltanto quando cambia.
La riga corrente NVDA viene impostata prima di dare il focus e il titolo FX
usa il prefisso LReaParams. I messaggi automatici di NVDA sul ruolo EDIT non
sono completamente controllabili dalla DLL. Non compilato né testato in REAPER.

## TEST11 — lettura NVDA senza cursore EDIT (solo sorgente)

Diagnosi TEST10: il campo EDIT focalizzato aveva un caret reale; NVDA
continuava a parlare anche quando le griglie si fermavano correttamente
al primo o ultimo elemento. TEST11 utilizza un controllo STATIC focalizzabile
privo di cursore di sistema. I movimenti reali sono annunciati da OSARA,
mentre quelli senza cambiamento restano silenziosi. Aggiunto Ctrl+R per
rileggere intenzionalmente il parametro tramite OSARA in FX e Track.

NVDA+T rimane gestito dal titolo della finestra. NVDA+Freccia Su è da
verificare: senza il caret dell'EDIT potrebbe non leggere la riga; una
futura integrazione UIA TextPattern sarebbe necessaria se ciò avviene.
Build/test runtime da eseguire SOLO su GitHub Actions e REAPER.
