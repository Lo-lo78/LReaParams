# TEST66.2 — FX Params: assegnazione Backspace definitiva (0.0.66 TEST)

Questa TEST cambia solo le scorciatoie del navigatore FX Params, senza modificare About, installer, versione pubblica, guide della release, file .fx o dati ReaPack.

- **Backspace:** ripristina il parametro selezionato (come prima).
- **Ctrl+Backspace:** ripristina soltanto lo Step del parametro selezionato a 0.
- **Shift+Backspace (una pressione):** ripristina soltanto la Grid del contesto corrente a 10. Il reset si esegue alla scadenza del tempo di doppio clic di Windows.
- **Shift+Backspace (due pressioni rapide):** apre l'editor numerico Win32, valore precompilato, da 1 a 400, Invio per confermare, Escape per annullare; senza prima eseguire il reset. Non rileva il key repeat come doppia pressione.
- **Ctrl+Shift+Backspace:** reset completo dei valori dell'FX (comportamento originale della release 0.0.66). Si esegue immediatamente e annulla un eventuale reset Grid in attesa.
- **Ctrl+Shift+Alt+Backspace:** non è più una scorciatoia gestita da FX Params.

Tutte le 14 Grid indipendenti (Plugin Order, Custom Order e Gruppi 1–12), il loro formato `lrp_context_grids_v1`, gli Step `lrp_param_step_scales_v1` e il limite 1–400 rimangono quelli della TEST66.1. Nessuna modifica ai comandi di Track Params, FX Memories o F7.

## Prova con REAPER, NVDA e OSARA

1. Imposta un parametro diverso dal default, Step 3 e Grid 37. Backspace ripristina solo il parametro.
2. Ctrl+Backspace ripristina soltanto Step 0, mantenendo Grid 37.
3. Shift+Backspace una volta ripristina Grid 10 senza modificare Step.
4. Con Grid 37, premi Shift+Backspace due volte rapidamente mantenendo Shift premuto: si apre il campo numerico accessibile, già impostato a 37, senza reset preventivo. Invio accetta 1–400, Escape annulla.
5. Ctrl+Shift+Backspace ripristina tutti i valori dell'FX con il comportamento originale.
6. Da Grid 37, premi Shift+Backspace una volta, poi Ctrl+Shift+Backspace senza aspettare: il reset globale deve sostituire quello Grid ancora in attesa.
7. Prova in Plugin Order, Custom Order, gruppi, Value e Keyboard: nessun cambio involontario di altre griglie o step; F7, Track Params e FX Memories restano invariati.
8. Controlla che un Backspace tenuto premuto non sia riconosciuto come doppia pressione.

Le verifiche statiche non sostituiscono compilazione Windows e test reali di NVDA/focus.
