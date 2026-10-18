# LReaParams 0.0.56 — TEST56.4 — F4 TCP

Base: TEST56.3. Consegnato soltanto il sorgente per GitHub Actions. NON eseguire build locali.

## F4 principale

- In modalità Value, Su/Giù, PagSu/PagGiù e Home/End, oppure Alt+Su/Giù in Grid: quando cambia il valore, l'annuncio contiene **solo il nuovo valore formattato**, come FX Params. Tab e NVDA+Su mantengono nome e contesto.
- Alt+Home / Alt+End in Grid: primo / ultimo parametro visibile della colonna FX corrente, senza spostarsi fra FX; i bordi non annunciano niente.
- Ctrl+F: campo EDIT nativo accessibile a NVDA. Testo libero = sottostringa senza distinzione maiuscole/minuscole; tra virgolette = parole/frase esatta, con prefisso consentito sull'ultima parola di una frase di più parole, come in FX Params. Invio applica il filtro, Esc nel campo annulla l'editing, Ctrl+F con filtro attivo lo cancella. Esc nella griglia filtrata prima pulisce la ricerca, senza uscire da F4.
- La ricerca riguarda i nomi dei parametri TCP effettivamente esposti, senza modificare REAPER. Le intestazioni FX restano presenti anche quando un FX non ha risultati.

## Griglia dei parametri per aggiunta (Invio sull'intestazione FX)

- Rimane la griglia FX Params a nomi soltanto. F1/F2 riducono/aumentano l'altezza.
- Ctrl+F filtra i nomi secondo le stesse regole; Invio aggiunge al TCP e torna a F4; Ctrl+Invio alterna presenza TCP restando nella griglia.
- Esc con ricerca attiva la cancella, poi Esc torna a F4.

## Griglia dei parametri visibili per rimozione (Alt+Invio da F4)

- Titolo Windows: **Track Params - [traccia] - Visible TCP parameters - Remove**. Non più il generico FX parameter grid.
- Colonne distinte per ogni FX della traccia, nello stesso ordine di F4; ogni colonna comprende un'intestazione e soltanto i nomi dei parametri TCP esposti, senza valori.
- Alt+Invio da un parametro di F4 apre la sua colonna e cerca di selezionare il medesimo parametro.
- Frecce Su/Giù = parametri della colonna (annunciano solo il nome); Sinistra/Destra = FX precedente/successivo (annuncia anche il nuovo FX per orientarsi).
- Home/End, PagSu/PagGiù per la colonna corrente; Ctrl+Home/End prima/ultima colonna; Alt+Home/End primo/ultimo parametro della colonna.
- Invio rimuove il parametro dal TCP e torna a F4; Ctrl+Invio lo rimuove e rimane nella griglia. Non si può eliminare l'intestazione FX.
- Ctrl+F filtra per nome, preservando gli indici reali dei parametri e l'identità GUID dell'FX prima dell'operazione.
- Bordi silenziosi. Tab annuncia anche il nome FX e la posizione.

## Verifiche da eseguire in REAPER dopo GitHub Actions

1. ReaEQ e ReaComp sulla stessa traccia; almeno due controlli TCP per entrambi.
2. F4, Alt+Su sul parametro: deve parlare solo il nuovo valore. Tab deve leggere contesto completo.
3. Ctrl+F nella griglia dei parametri e ricerca `gain`; Ctrl+F per cancellare; testare poi `"gain"` (parola precisa) e `"band 1 fr"` (frase con ultima parola prefisso).
4. Alt+Home/End in F4: primo e ultimo parametro della colonna, non il primo/ultimo FX.
5. Alt+Invio dal secondo FX: deve aprire la colonna del secondo FX; Sinistra/Destra cambia FX e Su/Giù non ripete il suo nome.
6. Ctrl+Invio su un controllo del secondo FX deve rimuovere soltanto quello; Undo di REAPER lo ripristina.
7. Esc con filtro, poi Esc senza filtro; verificare ritorno del focus al contesto precedente.

Nessun test C++/MSVC o runtime REAPER eseguito localmente.
