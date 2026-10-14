# LReaParams 0.0.6 TEST5 — Primo collaudo NVDA/OSARA

**Usa un progetto di prova e salva prima il progetto.** La DLL modifica valori
reali di tracce, mandate ed FX. Compila esclusivamente con GitHub Actions;
nessuna prova runtime è stata eseguita da chi ha preparato questo ZIP.

## Verifiche iniziali

1. Avvia REAPER e apri la Action List.
2. Cerca `LReaParams`: devono esserci le azioni FX Params, Track Params,
   Parameter Library (ancora non migrata), Import, Open Data Folder,
   Settings e About. La DLL crea una finestra reale di 1 pixel FUORI DALLO SCHERMO durante la navigazione, per NVDA+T; non deve coprire la GUI FX.
3. Il menu Extensions deve contenere il sottomenu `LReaParams`.
4. `Open Data Folder` deve aprire `REAPER/LReaParams`.
5. Controlla che esistano `Plugins`, `Params`, `Tracks`, `Settings`, `Backups`.
   Se esistono i vecchi TXT, l'importazione avviene in background.

## FX Params

6. Inserisci un solo JSFX di prova su una traccia, seleziona la traccia SENZA
   toccare il plugin e avvia `LReaParams: FX Params (native test)` dalla Action List
   o con una scorciatoia assegnata da te. Deve aprire subito la griglia.
   Aggiungi un secondo FX alla stessa traccia: la stessa azione deve aprire
   il browser FX vocale. Su/Giù scorrono gli FX; Home/End e PageUp/Down
   spostano la scelta; Invio entra nella griglia del FX selezionato; Esc
   chiude. Alt+B dalla griglia riapre il browser. Verifica che sia possibile
   scegliere anche il SECONDO FX e controllare i suoi valori senza che
   LReaParams esca a causa del focus rimasto sul primo FX.
   Facoltativo: prova anche take FX su un item selezionato e Master/Monitor FX.
7. All'apertura OSARA deve annunciare un titolo virtuale come «LReaParams - FX Params - Grid», seguito dal plugin e dal primo parametro. Con il titolo proxy abilitato, NVDA+T deve leggere LReaParams, non REAPER; vedi Docs/TitleProxyTest.md. Tab deve leggere nome e valore. Su/Giù navigano nella colonna;
   Sinistra/Destra passano tra colonne. F1/F2 diminuiscono/aumentano l'altezza delle colonne (ripristino TEST3). F3-F11 non hanno ancora funzioni FX native.
8. Home/End vanno al primo/ultimo parametro della colonna; Ctrl+Home/Ctrl+End
   vanno al primo/ultimo parametro dell'intero FX. PageUp/PageDown
   saltano una colonna. Ctrl+F entra nella ricerca: digita lettere e numeri,
   Su/Giù scelgono il match precedente/successivo, Invio accetta, Esc annulla.
   È una ricerca ASCII di base, non ancora l'intero motore Lua.
9. Alt+Su/Giù modifica realmente il parametro. Alt+PageUp/PageDown usa
   passi maggiori; Invio entra/esce da Value (Su/Giù cambiano il valore).
10. Esc da Value torna a Grid; un altro Esc chiude la navigazione.
    La TEST5 usa un hook di thread dedicato a Escape per provare a sottrarre
    il tasto al comando Escape predefinito di REAPER: verificare che non
    chiuda per errore la FX chain o altri dialoghi.
    Esci e prova Ctrl+Z per il cambio effettuato. Verifica che un collaboratore
    vedente possa osservare il vero controllo nella GUI FX muoversi.

## Track Params TEST5 (matrice orizzontale dai Lua)

11. All'apertura OSARA deve annunciare «LReaParams - Track Params - Tracks» e la prima riga. Crea tre tracce, nominandole Piano, Bass, Drums. Seleziona Bass e apri
    `LReaParams: Track Params (basic native controls)`: deve leggere Bass,
    Volume. La traccia selezionata nel TCP rimane Bass anche quando la griglia
    passa a Piano o Drums; cambiare riga NON deve selezionare realmente la traccia.
12. Freccia Su/Giù cambia **traccia/riga** mantenendo la colonna. Freccia
    Sinistra/Destra cambia **parametro/colonna** restando sulla stessa traccia.
    I nove campi F1 sono: Volume, Pan, Width, Mute, Solo, Phase invert,
    Send count, Receive count e FX count. Gli ultimi tre sono sola lettura.
13. Home/End: primo/ultimo parametro della riga. Ctrl+Home/End:
    prima/ultima traccia (stessa colonna). PageUp/PageDown: cinque tracce.
14. Alt+Su/Giù modifica il campo corrente; Alt+PageUp/PageDown usa passi
    maggiori. Enter attiva Value (tranne sui contatori di send/receive,
    che aprono F2/F3, e FX count, per cui F4 è ancora da migrare).
15. F2 apre la pagina parziale Sends; F3 Receives: Su/Giù passa fra
    mandate o ritorni, Sinistra/Destra naviga i tre campi Volume/Pan/Mute.
    F1 ritorna alle tracce, conservando la traccia corrente. Queste pagine
    NON hanno ancora tutte le 14 colonne dei Lua originali.
16. Escape in Value torna alla griglia. Escape da F2/F3 torna a F1. Escape
    da F1 termina LReaParams, senza un'azione "Exit" da assegnare a REAPER.
    Fuori da LReaParams Escape deve mantenere il normale comportamento REAPER.
17. Verifica che modificando Volume/Pan su un'altra riga si modifichi la
    traccia giusta, e che Ctrl+Z annulli la modifica. Testa anche cartelle
    di tracce chiuse e tracce nascoste nel TCP.

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

## Menu Memories e tasti funzione riservati (TEST5)

- Verifica il sottomenu `Extensions → LReaParams → Memories` con le voci
  FX Memories, Track Memories e Parameter Library. In questa TEST5 le prime
  due annunciano che la gestione memorie non è ancora implementata; la terza
  rimane in attesa di migrazione. Nessuna di queste voci deve modificare file.
- In FX Params premi F1, F2 e F11: non deve cambiare la griglia e non deve
  avviarsi alcun comando di REAPER. F12 è sempre riservato a OSARA.
- In Track Params F1, F2 e F3 continuano a cambiare pagina, mentre F4/F11
  non hanno ancora funzione e non devono interrompere la navigazione.
- Verifica che il menu non abbia aggiunto finestre o pixel ausiliari.

## Test aggiuntivo TEST5

Leggere `Docs/TitleProxyTest.md` per NVDA+T, F12, focus e opzione di disattivazione del titolo reale.
