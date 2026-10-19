# LReaParams 0.0.58 — TEST58: F7 Hardware outputs

**Sorgente per GitHub Actions. Nessuna compilazione locale eseguita; non ancora collaudato con REAPER e NVDA.**

## Obiettivo e fonte

Migrazione della pagina F7 `HARDWARE_OUTPUT_SECTION_ID` dalla fonte `Legacy/Speak Track Params - TrackTake Navigator.lua`, sezione `3.5D - F7 HARDWARE OUTPUTS`. Si usa **solo** la categoria hardware di REAPER `GetTrackNumSends(track, 1)` (non `0` per sends e non `-1` per receives). Nessuna gestione ReaRoute F8 aggiunta in questa revisione. La struttura rimane **11 righe per ciascuna colonna di uscita**.

1. Hardware output: intestazione di colonna, destinazione e indice.
2. Volume: D_VOL in dB; segue il range volume Sends esistente nel `.tp`.
3. Pan: D_PAN (sinistra/centro/destra).
4. Mute: B_MUTE.
5. Phase invert: B_PHASE.
6. Mono: B_MONO.
7. Audio source mode: I_SRCCHAN bits 10+, da stereo/mono fino a 16 canali.
8. Audio source: I_SRCCHAN offset, da None ai canali 127/128, preservando il mode.
9. Hardware destination: I_DSTCHAN offset, coppie 1/2...127/128, senza espandere i canali della traccia; preserva il flag mono. Le destinazioni ReaRoute già presenti vengono identificate come tali e sono governate in F8 nella futura migrazione.
10. Send type: I_SENDMODE valori 0..3, incluso 2 legacy.
11. Pan law: D_PANLAW, Project default, -6 dB, -3 dB, 0 dB secondo i quattro valori del Lua.

La modifica del numero di canali **sorgente** può ampliare `I_NCHAN` fino a 128, come nel Lua. È vietato superare 128; non viene allargato `I_NCHAN` per la destinazione hardware. Su fallimento della scrittura routing si tenta il ripristino del numero di canali precedente. Tutte le scritture hanno Undo, lettura di conferma, e richiedono un oggetto traccia ancora valido. Delete usa `RemoveTrackSend(...,1,index)` e non tocca send/receive o FX.

## Tastiera

- **F7** da F1/F2/F3/F4/F5/F6 e selettore Alt+Invio F4: entra negli hardware output; se assenti dice «No hardware outputs» senza cambiare pagina. Premendo di nuovo F7 legge la cella corrente.
- **Su/Giù**: passa fra le 11 righe. **Sinistra/Destra**: uscita precedente/successiva tenendo la riga corrente. **Pagina Su/Giù**: salta 5 righe. **Home/End**: prima/ultima riga. Bordi silenziosi.
- **Ctrl+Home/End**: prima/ultima uscita alla riga corrente.
- **Alt+Su/Giù**: cambia valore in incremento piccolo. **Alt+Pagina Su/Giù**: incremento ampio. **Alt+Home/End**: valore massimo/minimo.
- **Invio** su Mute/Phase/Mono: commuta. Su campi numerici: attiva/disattiva Value. In Value, Su/Giù e Pagina modificano il valore; Esc torna alla griglia. Invio sull'intestazione legge contesto.
- **Canc**: cancella solo l'uscita hardware sotto il cursore, su qualsiasi riga. Se rimane zero uscite, torna a F1 dopo aver annunciato la cancellazione.
- **Tab**: contesto completo (traccia, numero uscita e riga). **NVDA+Su**: parametro e valore. **F1/F2/F3/F4/F6** cambia ambiente; **Esc** in griglia torna a F1.
- **Ctrl+Shift+M**: gestore memorie; **Ctrl+Tab/Ctrl+Q** restano gestiti dal router centrale.

## Memoria

Nella sezione di navigazione del `.tp` del progetto: `LastPage=F7`, `F7.TrackGUID`, `F7.Row`, `F7.Column`. Quando si apre una nuova traccia, la posizione viene ripristinata solo per GUID coincidente. Le memorie e i profili FX Params non sono alterati.

## Due rifiniture TEST57/F6 incluse

- `\` ripete la voce MIDI corrente (VK_OEM_5; può dipendere dalla tastiera utilizzata).
- I tentativi ripetuti di modifica al massimo/minimo non ripetono l'annuncio del valore.

## Collaudo con GitHub Actions + REAPER

1. Apri F7 su una traccia senza hardware outputs e verifica il messaggio e il focus sulla pagina precedente.
2. Aggiungi manualmente una o due uscite hardware in REAPER e torna in F7. Attraversa tutte le 11 righe; cambia colonna con Destra/Sinistra e conferma il contesto con Tab.
3. Prova Mute, Phase invert, Mono, Pan e Volume; verifica anche Undo/Redo in REAPER e che la lettura NVDA coincida con l'interfaccia nativa.
4. Prova audio source mode e source con la traccia a 2 canali, fino al limite di 128; verifica che `I_NCHAN` aumenti solo se necessario. Controlla il passaggio dal 63° al 64° stereo pair.
5. Prova destinazione hardware e pan law ai bordi, senza crescita di `I_NCHAN`. Se disponi di ReaRoute, verifica che venga indicato, senza modifiche automatiche.
6. Con due uscite, premi Delete sulla seconda: solo quella deve sparire; Ctrl+Z deve ripristinarla. Elimina l'ultima e controlla il ritorno a F1.
7. Entra ed esci via F1/F2/F3/F4/F5/F6; controlla FX Params, F5 a 128 canali, F6 MIDI e posizione ripristinata nel `.tp`.
8. Conferma la build MSVC x64 e CTest dal workflow: i controlli Python sono statici e **non** sostituiscono la DLL in REAPER.
