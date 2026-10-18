# TEST55.7 — Original catturato al primo ingresso nell'FX

## Modifica rispetto alla TEST55.6

- **Primo ingresso nell'istanza FX:** la DLL cattura automaticamente lo stato corrente dei parametri (incluso il chunk ReaEQ quando presente) come **Original**, con **Compare inizialmente identico**. Non viene applicato alcun valore, non cambia il suono e non viene annunciato uno snapshot.
- **Uscita, Ctrl+Tab e rientro:** Original e Compare restano in memoria finché REAPER resta aperto. Il semplice ritorno all'effetto non ricattura Original: viene identificato per progetto, GUID traccia, take e GUID FX. Anche lo stato di confronto attivo viene conservato.
- **F8 singolo:** alterna `Original` e `Compare`; il primo F8 dopo una modifica ascolta il riferimento salvato all'ingresso. La pressione singola non aggiorna mai Original.
- **F8 doppio:** aggiorna Original con lo stato audio attuale e annuncia `Original updated`; non provoca commutazioni audio durante il doppio gesto. Non cancella Compare.
- **Progetti chiusi:** la DLL scarta le memorie dei progetti non più aperti quando viene riaperto FX Params, ma conserva quelle dei progetti ancora aperti in altre schede.
- **Cambio di struttura dell'FX:** quando la DLL invalida il confronto (es. ReaEQ con bande cambiate), un nuovo ingresso ricrea un riferimento coerente con lo stato corrente anziché usare indici non più validi. Questo caso è una nuova inizializzazione di sicurezza, non un comando di aggiornamento intenzionale di Original.
- **Chiusura di REAPER:** gli snapshot A/B sono volatili e non vengono scritti nei profili `.fx`/`.tp`. Alla successiva sessione il primo ingresso riparte dal suono presente nel progetto.

## Gestione dei comandi

- `F8`: A/B (pressione singola o doppia nel tempo configurato in Windows).
- `Ctrl+Maiusc+M`: FX Memories da FX Params, Track Memories da Track Params.
- `F7`: editor FX Params.
- Il parametro virtuale Compare rimane escluso dalla griglia, dall'ordinamento e dalle memorie.

## Collaudo richiesto dopo GitHub Actions (REAPER + NVDA)

1. Salva un progetto con ReaEQ, entra in FX Params: il suono non cambia. Modifica Gain, premi F8 una volta (`Original`) e un'altra (`Compare`). Devono alternarsi stato salvato all'ingresso e modifiche.
2. Dopo una modifica di Compare, esci con Esc, rientra nell'FX e ripeti F8: Original deve essere ancora quello del primo ingresso, non quello del rientro.
3. Entra in un secondo FX, cattura il suo stato iniziale, torna al primo: gli Original devono restare indipendenti. Ripeti via Ctrl+Tab con Track Params.
4. Premi F8 due volte rapidamente da Compare: `Original updated`, senza cambi audio intermedi. Continua le modifiche e conferma che la nuova Original è quella fissata dal doppio F8.
5. Con più progetti aperti, passa a un'altra scheda e torna: il riferimento del primo progetto deve restare. Chiudendo quel progetto, la sua memoria deve essere scartata senza contaminare un eventuale nuovo progetto.
6. Prova anche Take FX e modifica strutturale ReaEQ. Se un confronto non è compatibile, non devono essere applicati parametri sbagliati.

## Limiti delle verifiche

Passano i test Python statici mirati e l'audit del sorgente. **Nessuna compilazione C++ locale**. La build MSVC, CTest e il comportamento reale in REAPER/NVDA sono da verificare esclusivamente su GitHub Actions e in REAPER.
