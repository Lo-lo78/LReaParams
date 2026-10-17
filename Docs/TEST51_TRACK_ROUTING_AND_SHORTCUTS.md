# TEST51 — Track Params: routing F2/F3 e scorciatoie F1

**Base:** `0.0.50 TEST50` (file sorgente); C++17/MSVC Windows x64 su GitHub Actions. NESSUNA compilazione locale. La TEST51 non modifica i file `.tp` né la logica MIDI CC di FX Params. Parameter Library resta esclusa.

## Correzioni immediate richieste

- **Ctrl+Maiusc+V non è più assegnato** a Track Params. **Invio** resta il modo normale di entrare/uscire da Value per i parametri continui. Sui toggle (Mute, Solo, Phase, MIDI follows fader), Invio cambia direttamente lo stato.
- **Ctrl+Alt+Freccia Su/Giù** raggiunge la folder precedente/successiva visibile in F1, mantenendo il parametro e senza cambiare la selezione REAPER. **Ctrl+Alt+Pagina Su/Giù è ora libero**.
- **Tab** continua a leggere contesto, parametro, valore, step e parlato come nella TEST50. `Ctrl+R` resta libero in Track Params.

## F2/F3: semantica originale, miglioramenti del routing

Ogni send/receive resta una COLONNA, con esattamente 14 parametri in verticale e navigazione sinistra/destra fra colonne. I 14 campi hanno nomi e ordine originali.

- **Audio source**: modificabile con Alt+Su/Giù oppure in Value con Su/Giù. Sequenza None, 1/2, 3/4, …, 127/128. Mantiene la modalità stereo/mono/multicanale quando applicabile. `I_SRCCHAN=-1` è la vera disattivazione audio, non la coppia 0.
- **Audio destination**: modificabile da 1/2 fino a 127/128; il bit `mix to mono` è preservato. Per entrambe, i valori mostrati ora descrivono davvero la coppia, non l'offset grezzo.
- **Audio source mode**: stereo, mono, 4, 6, …, 16 canali. La modifica preserva la coppia corrente. Con audio su `None`, il cambio modalità viene rifiutato finché non si riabilita la sorgente.
- **Espansione canali delle tracce**: ove necessario, `I_NCHAN` della sorgente o destinazione REALI viene aumentato automaticamente; F2 ed F3 identificano la traccia peer mediante l'API a puntatori tipizzati `GetSetTrackSendInfo(P_SRCTRACK/P_DESTTRACK)` e verificano il contesto. L'operazione è rifiutata se supera 128 canali. Se la scrittura del send fallisce, tenta di ripristinare il precedente `I_NCHAN` nel medesimo blocco Undo.
- **Send type**: in editing si percorrono 0 post-fader, 1 pre-FX, 2 post-FX deprecated, 3 post-FX, come nel Lua. Il valore pre-receive 8 esistente continua a essere riconosciuto a voce, ma non viene generato dai comandi di incremento.
- **MIDI source / destination**: valori e flag non pertinenti preservati. **MIDI source/destination bus**: step da 0 All a 1 Normal fino a 16; la codifica completa dei byte originali resta conservata, senza azzerare gli altri campi.
- **MIDI merge**: sola lettura, in linea con il Lua; 'Off' quando la sorgente MIDI è None, altrimenti 'On'.
- Step per tipo parametro, preferenze di annunci Value e preferenze CC del `.tp` della TEST49 restano operative.

## Cose importanti ancora NON migrate

Eliminazione send/receive in F2/F3 (la creazione in F1 è disponibile in TEST51 aggiornata) con gestione di routing, salto speculare su traccia peer all'Invio (comportamento Lua alternativo all'attuale Value), filtri di ricerca sui send, automazioni/envelope per send, MIDI CC runtime di Track Params, F4–F8, funzioni F1 avanzate (clipboard con routing, reorder). NON dichiarare parità completa del Lua.

## Piano di collaudo reale REAPER + NVDA

1. Compilare lo ZIP soltanto su GitHub Actions. Verificare sia il job MSVC x64, sia `ctest` e i controlli statici; nessuna compilazione locale eseguita in preparazione.
2. F1: posizionarsi su Volume, premere Invio, verificare Value e ritorno; Ctrl+Maiusc+V non deve commutare. Ctrl+Alt+Su/Giù deve saltare tra folder, MA non cambiare selezione, colonna o Step. Ctrl+Alt+Pagina Su/Giù non deve più richiamare la funzione folder.
3. Su F2 e F3: con più send/receive, frecce verticali percorrono 14 voci e quelle orizzontali cambiano colonna senza cambiare riga. Tab legge Step e parlato. Riavviare REAPER e verificare il ripristino `.tp` senza perdita dei CC preesistenti.
4. F2 Audio source: Alt+Giù da 1/2 diventa None; Alt+Su torna 1/2. Salire a 3/4, 5/6 e verificare che REAPER incrementi i canali `I_NCHAN` sulla vera sorgente, senza alterare la destinazione. Ripetere in F3 e controllare la traccia sorgente (peer).
5. Audio destination: 1/2 -> 3/4 -> 5/6. Controllare l'aumento canali sulla traccia destinataria e il mantenimento del flag mono. Su una traccia a 128 canali, provare il massimo; per source mode 16ch a coppia 127/128 deve dire che eccede 128 e rifiutare la modifica.
6. Cambiare Audio source mode tra stereo, mono, 4, 6 e 16 canali. La coppia non deve cambiare; riaprendo REAPER non deve essersi perso il routing audio precedente. Con sorgente None il cambio modalità deve rifiutarsi.
7. Send type: Alt+Su/Giù percorre 0–3 e restituisce l'etichetta corretta; un vecchio valore host 8 si legge Pre receive. MIDI source = All/1..16/None, destination Original/1..16, bus All/Normal/2..16; cambiare un sottocampo non deve toccare gli altri. Prova anche il bit MIDI follows fader e MIDI merge read-only.
8. Ripetere su receive F3 controllando il *send effettivo* di origine. Controllare Undo REAPER, NVDA+Su, speech off, Tab e cambio pagina; verificare che FX Params resti identico.

**Verifica eseguita qui:** `Tools/run_static.py` + test bitfield sintetici. Non sono equivalenti alla compilazione e al test operativo in REAPER.
