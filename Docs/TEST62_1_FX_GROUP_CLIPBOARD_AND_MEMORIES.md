# TEST62.1 — FX Params: gruppi, appunti F7 e memorie per ambiente (sorgente)

Base: **LReaParams 0.0.62**, senza incremento del numero pubblico. È una prova
sperimentale da compilare tramite GitHub Actions su Windows x64 (MSVC).
**Non è una DLL compilata, né una prova eseguita in REAPER/NVDA/OSARA.**
Usare un plugin e una copia di sicurezza dei profili `.fx` prima di provare.

## Ambienti

- **Plugin Order**: mostra sempre tutti i parametri nativi in ordine originale.
  Mai applicare `hidden`, copie, riordino o rimozione; restano indipendenti
  griglia, Step e altre impostazioni di navigazione già previste.
- **Custom Order**: elenco di partenza con tutti i parametri originali, più
  eventuali duplicati. **Ctrl+Maiusc+Canc** nasconde globalmente l'ID selezionato.
- **Group 1..12**: ciascuno mantiene un elenco *di occorrenze* autonomo.
  **Ctrl+Canc** elimina dal solo gruppo le occorrenze selezionate, senza
  nasconderle nella Custom Order né negli altri gruppi.
- `hidden` è una sola memoria comune a Custom Order e ai 12 gruppi. Le
  appartenenze dei parametri nascosti ai gruppi NON vengono cancellate:
  riappaiono quando si toglie il parametro da Hidden Parameters.
- **Ctrl+Maiusc+Canc** nasconde globalmente sia dalla Custom Order sia dai gruppi;
  il recupero avviene dalla colonna Hidden Parameters di Ctrl+Maiusc+M.
  **Ctrl+Canc** dalla Custom Order non nasconde e non rimuove nulla.

## Ctrl+C, Ctrl+X, Ctrl+V in F7

- **Ctrl+C** non cambia la sorgente e permette di incollare ripetutamente
  in gruppi diversi e/o nella Custom Order dello stesso plugin.
- **Ctrl+X** all'interno dello stesso ambiente consente di riordinare.
- **Ctrl+X** da Group 1 a Group 5 sposta le occorrenze: la sorgente non cambia
  fino a Ctrl+V riuscito. Alla riuscita si salva atomicamente un'unica
  modifica con Undo, togliendo dalla sorgente e inserendo nella destinazione.
- **Ctrl+X** da Custom Order a gruppo o viceversa non è consentito;
  utilizzare **Ctrl+C**, per non alterare l'elenco di partenza.
- Per tagli la DLL controlla l'identità GUID dell'istanza e le posizioni
  originali, per non cancellare una copia sbagliata. Per copie mantiene il
  controllo del tipo di plugin, come prima.
- Gli appunti di un taglio si svuotano *solo dopo* un incollaggio riuscito;
  quelli di una copia rimangono disponibili per più incollaggi.
- In F7 si può raggiungere anche un **gruppo vuoto** con Ctrl+F1..F12,
  per incollarvi i primi parametri. Fuori da F7 la navigazione nei gruppi
  vuoti continua a dare l'avviso «Group N empty».

## FX Memories — Ctrl+Shift+M

Le **sette colonne rimangono sette**. Cambia la sesta, «Copied parameters»:

- Le copie aggiuntive della Custom Order: `Cutoff. Custom Order. Copy 2`.
- Ogni occorrenza conservata in un gruppo, anche la prima:
  `Cutoff. Group Bass. Occurrence 1. Position 4`.
- Se il gruppo non ha nome: `Resonance. Group 2. Occurrence 1. Position 1`.
- Nome personalizzato: sempre **Group + nome**, senza numero; è la regola
  anche per il resto degli annunci dei gruppi in FX Params.
- Le posizioni sono quelle persistenti dell'elenco del gruppo, a base 1;
  «Hidden» viene letto quando un'occorrenza è temporaneamente invisibile.
- **Invio** su un'occorrenza visibile del gruppo apre quel gruppo esattamente
  su quella specifica copia. Su un elemento Hidden viene richiesto prima di
  recuperarlo nella terza colonna.
- **Canc** elimina soltanto l'occorrenza selezionata dal gruppo corretto;
  nell'ordine Custom cancella soltanto una copia *oltre la prima*.
- La colonna «Groups» continua a descrivere ogni gruppo con il nome e il
  conteggio degli elementi *visibili*; la terza resta la memoria globale
  degli invisibili.
- Il formato `.fx` conserva i gruppi già distinti. Non viene introdotta
  una nuova serializzazione di copie per 12 contesti.

## Prove importanti su REAPER + NVDA

1. Plugin con 8+ parametri: in Custom F7 seleziona Cutoff, Ctrl+C, entra in
   Group 1 con Ctrl+F1, Ctrl+V; passa in Group 5 e Ctrl+V, poi Group 7 e
   Ctrl+V. Verifica che tutte e tre le copie esistano e che Custom sia intatta.
2. In Group 1 F7, seleziona una copia, Ctrl+X, entra in Group 5, Ctrl+V:
   sparisce SOLO da Group 1. Ctrl+Z deve ripristinare entrambi i gruppi;
   Ctrl+Y deve rieseguire lo spostamento.
3. Ripeti Ctrl+X senza Ctrl+V: cambia gruppo e torna indietro; l'origine
   non deve aver perso nulla. Ctrl+X da Custom a Group 1 NON deve tagliare.
4. In Group 5 premi Ctrl+Canc su un parametro: scompare solo dal Group 5,
   ma resta in Custom e in Group 7. Provare anche con duplicati dello stesso
   parametro presenti e con altri parametri nascosti in mezzo.
5. In Custom F7 Ctrl+Maiusc+Canc su Cutoff: scompare da Custom e da tutti i gruppi,
   resta visibile in **Plugin Order**. Ripristina Cutoff da Hidden Parameters:
   deve tornare automaticamente nei gruppi che lo contenevano.
6. In Ctrl+Shift+M, sesta colonna, controlla `Group Bass` (nome
   personalizzato) e `Group 2` (default), posizione e occorrenza. Invio
   deve aprire la copia selezionata, Canc deve eliminare solo quella.
7. Crea un gruppo vuoto rimuovendo l'ultimo parametro. In F7 Ctrl+Fn
   deve poterlo riaprire come destinazione di Ctrl+V.
8. Salva, riapri FX Params, chiudi e riavvia REAPER: nomi, gruppi,
   invisibilità, ordine, duplicati e griglie devono persistere.
9. Verifica il file `.fx` e Track Params F1..F8, Pin Connector, profili
   precedenti e i tasti F7/F8: nessuna regressione.

Verifica automatica: `python Testing/test62_1_fx_group_memories_static.py`;
aggiunta ai test del workflow GitHub Actions.
