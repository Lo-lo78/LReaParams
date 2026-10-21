# TEST61.14 — FX Params: gruppo e posizione persistenti nel profilo .fx

Questa TEST estende TEST61.13: la posizione del gruppo non e' piu' limitata
alla memoria di processo. Al normale Esc che chiude FX Params, o quando si
passa a un altro FX, si salvano **insieme** nel file di profilo del plugin:

- Il parametro visitato in `LastParam` (formato Lua v3 gia' utilizzato).
- Il gruppo corrente (0 = normale Plugin Order / Custom Order).
- L'indice esatto, a base zero, nella griglia corrente: utile per parametri
  ripetuti nella Custom Order o all'interno di un gruppo.

Il nuovo campo facoltativo e' scritto soltanto in `[Extra]`:

    lrp_last_navigation_v1=2,4

L'esempio significa: gruppo 2, quinto elemento. I vecchi file `.fx`, anche
quelli senza il campo o senza `[Extra]`, restano validi e vengono integrati
solo al primo salvataggio della posizione. Non si modificano GroupSlots,
CustomOrder, alias, assegnazioni MIDI, snapshot o preferenze degli utenti.
Vengono conservati il controllo sui cambiamenti esterni, la scrittura
atomica e il backup del profilo originario.

All'apertura, se REAPER e' ancora nella stessa sessione, prevale la memoria
della singola istanza dell'FX (identificata dal GUID); in assenza di essa si
usa il profilo `.fx`. Il profilo `.fx` e' **condiviso dalle istanze dello
stesso tipo di plugin**, come nel vecchio sistema Lua; la persistenza
inter-sessione riguarda quindi l'ultima posizione salvata per quel plugin,
non posizioni separate per ciascun GUID fra riavvii di REAPER.

La modalita' F7 e l'eventuale filtro non vengono riaperti automaticamente.
Un gruppo cancellato, vuoto o non valido viene ignorato; FX Params rientra
in Plugin Order/Custom Order. Il tasto Esc dalla griglia del gruppo continua
a chiudere direttamente FX Params come in TEST61.13. Ctrl+Fn del gruppo
corrente continua a tornare deliberatamente alla vista di origine.

## Verifiche consigliate in REAPER con NVDA e OSARA

1. Aprire un FX con almeno due gruppi; entrare nel gruppo 2 e spostarsi
   al quinto parametro. Premere Esc una sola volta: FX Params si chiude.
2. Riaprire FX Params: devono ricomparire gruppo 2 e quinto parametro.
3. Chiudere completamente REAPER, riavviarlo, aprire lo stesso progetto e
   l'FX. Devono ricomparire gruppo 2 e quinto parametro.
4. Aprire un gruppo con una ripetizione dello stesso parametro e verificare
   che riaprendo venga selezionata la stessa **occorrenza**, non la prima.
5. Uscire volontariamente dal gruppo con Ctrl+Fn; chiudere e riavviare
   REAPER: all'apertura deve esserci la griglia principale, non il gruppo.
6. Con F7 e senza F7, verificare che Esc dall'editor esca dall'editor,
   mentre Esc dalla griglia del gruppo esca da FX Params.
7. Verificare un FX differente, i plugin senza gruppi e un profilo vecchio.

Non si esegue alcuna compilazione locale. Il test nativo in
`Testing/ProfileTests.cpp` e' eseguito dal workflow GitHub Actions;
`Testing/test61_14_fx_group_persistence_static.py` controlla la presenza dei
percorsi di salvataggio e ripristino anche senza compilatore.
