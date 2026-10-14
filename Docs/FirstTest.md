# LReaParams 0.0.2 — Primo collaudo NVDA/OSARA

**Usa un progetto di prova e salva prima il progetto.** La DLL modifica valori
reali di tracce, mandate ed FX. Compila esclusivamente con GitHub Actions;
nessuna prova runtime è stata eseguita da chi ha preparato questo ZIP.

## Verifiche iniziali

1. Avvia REAPER e apri la Action List.
2. Cerca `LReaParams`: devono esserci le azioni FX Params, Track Params,
   Parameter Library (ancora non migrata), Exit, Import, Open Data Folder,
   Settings e About. La DLL NON deve far comparire una finestra di un pixel.
3. Il menu Extensions deve contenere il sottomenu `LReaParams`.
4. `Open Data Folder` deve aprire `REAPER/LReaParams`.
5. Controlla che esistano `Plugins`, `Params`, `Tracks`, `Settings`, `Backups`.
   Se esistono i vecchi TXT, l'importazione avviene in background.

## FX Params

6. Inserisci un JSFX di prova su una traccia, apri la sua GUI, seleziona un
   parametro e avvia `LReaParams: FX Params (native test)` dalla Action List
   o con una scorciatoia assegnata da te.
7. Tab deve leggere nome e valore. Su/Giù navigano nella colonna;
   Sinistra/Destra passano tra colonne. F1/F2 cambiano l'altezza colonne.
8. Home/End vanno rispettivamente al primo/ultimo parametro; PageUp/PageDown
   saltano una colonna. Ctrl+F entra nella ricerca: digita lettere e numeri,
   Su/Giù scelgono il match precedente/successivo, Invio accetta, Esc annulla.
   È una ricerca ASCII di base, non ancora l'intero motore Lua.
9. Alt+Su/Giù modifica realmente il parametro. Alt+PageUp/PageDown usa
   passi maggiori; Invio entra/esce da Value (Su/Giù cambiano il valore).
10. Esc da Value torna a Grid; un altro Esc chiude la navigazione.
    Esci e prova Ctrl+Z per il cambio effettuato. Verifica che un collaboratore
    vedente possa osservare il vero controllo nella GUI FX muoversi.

## Track Params (nuovo)

11. Seleziona una normale traccia nel TCP; avvia
    `LReaParams: Track Params (basic native controls)`.
12. Tab legge il valore corrente. Scorri con Su/Giù i primi otto controlli:
    Volume, Pan, Width, Mute, Solo, Record arm, Phase invert, FX enabled.
13. Alt+Su aumenta e Alt+Giù diminuisce; Alt+PageUp/PageDown cambia più
    rapidamente. Il volume procede a passi di 0,5 dB / 3 dB, il pan a 1% / 10%.
14. Se la traccia ha mandate o ritorni, prosegui con Giù per trovare
    `Send N volume`, `Send N pan`, `Send N mute`, quindi `Receive ...`.
    Verifica le modifiche nella GUI routing di REAPER.
15. Invio attiva Value; Esc torna a Grid e poi esce. Home/End nella griglia
    saltano al primo/ultimo controllo; PageUp/PageDown e Sinistra/Destra saltano
    di 10 parametri.
16. Cambia traccia durante la navigazione: la cattura deve interrompersi,
    SENZA modificare accidentalmente la nuova traccia. Verifica Undo.

## Comportamento della tastiera e compatibilità

17. Prova F12 con OSARA: deve uscire dalla navigazione lasciando il tasto
    all'help di OSARA; non deve rimanere una cattura nascosta.
18. Prova la GUI di FX flottanti, docked e, se presenti, plugin su thread
    diversi. Settings permette di scegliere tra `accelerator` e
    `WH_GETMESSAGE` **solo per questa sessione**.
19. Fuori da LReaParams i tasti di REAPER, OSARA e dei plugin devono
    funzionare normalmente. Il mouse non deve essere bloccato o sovrapposto.
20. Non tentare di modificare testo in un editor custom del plugin mentre la
    navigazione è attiva: premi prima Esc. La rilevazione universale degli
    editor disegnati dai plugin non è ancora possibile.

## Da comunicare per le correzioni

Annota: stato di GitHub Actions, numero di errore/riga se il build fallisce;
se parte, versione di REAPER, plugin usato, azione eseguita, nome dei tasti
che non arrivano, annunci OSARA, eventuale perdita focus/crash. Non testare
sulla sessione di lavoro prima di aver salvato una copia del progetto.
