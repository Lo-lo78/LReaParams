# Validazione realmente eseguita

Preparazione del pacchetto, 14 ottobre 2026.

**Non è stata eseguita alcuna compilazione locale.** Nessun comando CMake,
Visual Studio, MSBuild, compilatore C++ o eseguibile di test nativo è stato
avviato. Il workflow non è stato eseguito da questa sessione. Non sono disponibili
prove REAPER, OSARA, NVDA, audio, hardware o GUI della DLL.

Controlli eseguiti con lettura sorgenti e Python:

- Specifica ricevuta letta integralmente; controllato il vincolo di consegna Fase 0.
- ZIP Lua: 3 file effettivi, versioni 0.346 / 0.184 / 0.102;
  righe 37.058 + 29.890 + 1.564 = 68.512.
- Copie in Legacy confrontate byte per byte con gli allegati; SHA-256 nel manifest.
- Censimento lessicale dell'intero codice: 2.478 definizioni di funzione,
  1.492 righe di evidenza delle scorciatoie, 46 chiamate dirette ExtState.
- Header SDK confrontati con gli originali ufficiali e bloccati con SHA-256;
  i nomi delle API richieste corrispondono a dichiarazioni effettive nel SDK.
- Verificata nel sorgente OSARA la firma degli export di parlato e Shortcut Help.
- Tutti i 55 TXT originali: riconoscimento e roundtrip byte per byte con
  l'**oracolo Python**, inclusi 48 FX, 4 Track, 3 PP. Non è un'esecuzione del parser C++.
- Tutte le 55 fixture sintetiche: medesimo controllo; ulteriori casi Python
  di header sconosciuti, handoff/return, Count errato, duplicati, BOM, CRLF
  e sezioni future.
- Workflow analizzato come YAML; trigger push/pull_request/workflow_dispatch
  e struttura dei sette step validi. Tag delle Actions risolti dai repository
  ufficiali; il risultato del futuro build resta da verificare.
- Revisione sorgenti per assenza di CreateWindow, hook tastiera globali,
  callback audio, SetExtState/SetProjExtState e azioni MIDI/transport involontarie.
- ZIP verificato per struttura alla radice, CRC, presenza `.github`, sorgenti,
  documentazione, assenza binari e assenza dei TXT personali originali.

L'oracolo Python è un secondo modello del formato, utile per scoprire differenze
nei dati; non dimostra che il C++ compili o si comporti allo stesso modo. Ha
evidenziato indici virtuali negativi e alias aggiuntivi, ora gestiti anche nel
sorgente C++. La verifica effettiva del C++ è responsabilità del job CI incluso.

## Test inclusi per GitHub Actions, non eseguiti qui

`profile_tests` usa lo stesso parser e storage linkato dalla DLL, senza REAPER.
Controlla tutti i 55 sintetici, roundtrip semantico e byte, SHA-256 con vettore noto,
contenuti non validi, PP NaN/Count, CC fuori range, BOM/CRLF/sezioni sconosciute,
cartelle vuote, import completo, conservazione originali, idempotenza con date,
modifica nativa dell'utente, conflitti, path Unicode, backup, rimozione del solo
TXT attivo, file estranei/handoff, collisioni di scrittura e annullamento.

L'eseguibile di test non è incluso nell'artifact di installazione. Accetta un
secondo percorso opzionale verso i 55 originali privati per una futura prova
controllata dal proprietario; il workflow pubblico usa solo i sintetici.

La revisione semantica di tutte le funzioni Lua e la matrice delle gesture
eseguibili complete restano da completare dopo il gate. L'inventario automatico
non viene presentato come prova della migrazione delle 68.512 righe.

## Aggiornamento per 0.0.2 Native Test

Il sorgente originale Phase 0 è stato esteso senza eseguire CMake/MSVC o
build locali. Aggiunti `Navigator.h`, `TrackNavigator.h/.cpp`, routing unificato
per input FX/Track e ricerca Ctrl+F in FX. Aggiornati CMake, action label,
documenti e workflow artifact. Eseguito solo `python Tools/audit.py`:
55 fixture sintetiche riconosciute e roundtrip corretto, SDK originale integro,
Lua in Legacy invariati. Questo NON verifica correttezza C++, ABI, UI o
comportamento in REAPER; tali verifiche spettano a GitHub Actions e all'utente.
