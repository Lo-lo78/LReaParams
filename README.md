# LReaParams — TEST12 (0.0.13)

**Solo codice sorgente C++.** Compilazione esclusivamente tramite GitHub Actions.

La TEST12 mantiene il controllo **STATIC** senza cursore della TEST11 e
corregge una possibile origine dei doppi annunci di NVDA: il testo del
controllo non viene più aggiornato tramite `SetWindowTextW`. Viene fornito
solo alle richieste esplicite (`WM_GETTEXT`), senza eventi di cambio nome
che possono sovrapporsi alla voce di OSARA. I bordi restano silenziosi.

**Ctrl+R**: ripete espressamente il parametro corrente con OSARA, in FX Params
e Track Params. È un metodo affidabile anche se NVDA+Freccia Su non dovesse
leggere il testo statico in assenza di cursore di sistema. **NVDA+T** conserva
il titolo di navigazione con nome dell'effetto/traccia.

I controlli per valori, F1–F3, Alt+Home/End, Ctrl+Su/Giù tra FX, memoria di
sessione e importazione dei profili sono invariati.

Leggere `Docs/TEST12_SINGLE_SPEECH.md`. Non è stata eseguita alcuna build locale.

## TEST12: remove duplicate NVDA / OSARA parameter announcements

The offscreen 1px focus owner remains, so REAPER plugin GUIs stay visible.
Its native STATIC control remains focused without a text caret, preserving
TEST11's silent boundaries. The parameter text is now updated **passively**:
`WM_GETTEXT` and `WM_GETTEXTLENGTH` return the current parameter/value, but
`SetWindowTextW` is never called on that focused control while navigating.
This avoids the native accessibility name-change event which can make NVDA
repeat the same parameter immediately after OSARA announces it.

The selected FX, session memory, shortcuts, and track parameter layout are
unchanged. To review explicitly, use **Ctrl+R** (OSARA). NVDA+T still reads
the full window title. NVDA+Up remains experimental with a STATIC control;
its ability to query the new text must be checked in REAPER.

**No local compilation performed.** Build and test only with GitHub Actions.

