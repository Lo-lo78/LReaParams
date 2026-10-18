# TEST55.6 — FX Params: F8 Compare A/B

## Comportamento

- All'ingresso in un effetto REAPER mantiene il proprio stato sonoro e la propria selezione/posizione. **Non viene applicato alcuno snapshot**. Si cattura esclusivamente una fotografia provvisoria del suono presente in REAPER (progetto salvato o modifiche correnti) per il confronto nella sessione.
- **F8 singolo**: alterna `Original` e `Compare`. Sul lato Compare si continua a modificare liberamente. Il primo F8, dopo aver lavorato, conserva le modifiche in Compare e applica Original. Il successivo riporta Compare.
- **F8 doppio**: copia lo stato sonoro *attualmente udibile* in Original, senza cambiare lato e senza eliminare la configurazione Compare. Annuncio: `Original updated`. Original viene rimpiazzato solo da questo gesto; la cattura iniziale è soltanto una base provvisoria.
- Un'eventuale modifica effettuata mentre si ascolta Original rimane temporanea: con una nuova pressione singola di F8 si torna a Compare senza sovrascrivere il riferimento; con la doppia pressione si conferma come nuovo Original.
- Per distinguere singolo e doppio il sistema ritarda il cambio singolo fino allo scadere dell'intervallo di doppio clic configurato in Windows (`GetDoubleClickTime`). La prima pressione del gesto doppio non produce un passaggio audio.
- Le due fotografie sono separate per progetto, GUID della traccia, take e GUID dell'FX durante la sessione aperta. Dalla TEST55.7, uscire da FX Params **non** cancella gli snapshot: rientrando nello stesso FX durante la sessione REAPER si conserva Original, senza applicarlo all’ingresso. Alla chiusura di REAPER gli snapshot temporanei scompaiono.
- ReaEQ: confronto tramite struttura `vst_chunk` e parametri wrapper, conservando il controllo di validità. Cambi di struttura incompatibili devono rifiutare il restore invece di applicare indici di parametri sbagliati.

## Compatibilità e scorciatoie

- Il vecchio controllo virtuale `Compare` non appare più in Griglia, F7, Custom Order o FX Memories e non può essere manovrato tramite vecchi CC. Gli `.fx` preesistenti restano leggibili: nessuna conversione forzata all'ingresso.
- **Ctrl+Maiusc+M** continua ad aprire FX Memories e Track Memories secondo il contesto.
- F7 resta l'editor, mentre F8 riguarda soltanto FX Params. Le funzioni F1/F2/F3 e il file `.tp` di Track Params non sono state modificate.
- Il confronto non salva snapshot su `.fx` o `.tp` e non aggiunge un nuovo parametro VST3.

## Prove obbligatorie in REAPER/NVDA dopo GitHub Actions

1. Caricare un FX in REAPER con suono/preset salvato e aprire FX Params: nessun cambiamento di suono, stessa posizione di navigazione.
2. Cambiare alcuni parametri, F8 singolo: `Original`, ripristino del suono iniziale; F8 singolo: `Compare`, recupero completo degli edit.
3. Modificare Compare e premere due volte F8 rapidamente: un solo annuncio `Original updated`, nessuno switch intermedio; poi modificare di nuovo e verificare il nuovo riferimento con F8.
4. Modificare Original mentre è attivo, passare a Compare senza doppio F8 e tornare a Original: gli edit provvisori non devono aver modificato il riferimento; ripetere con doppio F8 e verificare il commit.
5. Alternare tra due istanze dell'FX; verificare che durante la stessa sessione il riferimento resti distinto. Uscire e rientrare: nessuno snapshot temporaneo viene applicato automaticamente e Original deve rimanere quello catturato al primo ingresso.
6. Testare con ReaEQ, ReaComp, FX VST3 e Take FX; per ReaEQ provare una modifica strutturale, verificando sicurezza e Undo REAPER.
7. Controllare l'assenza del parametro virtuale Compare nella griglia e nelle memorie anche con un vecchio `.fx` che conteneva il controllo.

**Verifica eseguita:** controlli statici mirati e `Tools/audit.py`. Nessuna compilazione locale, nessun test runtime in REAPER: build e CTest restano a GitHub Actions.
