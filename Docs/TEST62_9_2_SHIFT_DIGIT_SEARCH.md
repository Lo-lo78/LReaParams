# TEST62.9.2 — Maiusc + numeri nella ricerca incrementale

Base: TEST62.9.1. Modifica solo la ricerca da tastiera, senza alterare il DSP, i profili o le scorciatoie di FX Chain.

## Problema

Con tastiera italiana, Maiusc+1 produce `!`, Maiusc+2 produce `"` e Maiusc+7 produce `/`. La ricerca all’indietro interpretava il simbolo anziché il numero del tasto.

## Soluzione

La ricerca incrementale usa la cifra del tasto fisico (`VK_0`–`VK_9`) quando Maiusc è premuto, conservando il verso all’indietro. La conversione vale soltanto nella ricerca, non in editor di testo, pulsanti o parametri DSP. La ricerca in avanti e il tempo di accumulo di 1 secondo rimangono invariati.

## Prove manuali in REAPER e NVDA

1. In FX Params, usa un plugin con nomi `1 Mode`, `2 Gain`, `7 Frequency`, `16 Detector Source`. Da `1 Mode`, premi Maiusc+7: deve cercare la banda 7 all’indietro, non il simbolo `/`.
2. Da `1 Mode`, digita rapidamente Maiusc+1 e Maiusc+6: deve cercare `16` all’indietro. Ripeti la prova in F7 e nei gruppi.
3. In FX Memories e Track Memories, prova Maiusc+numero nella colonna corrente: la ricerca deve andare all’indietro e non cambiare colonna o selezione.
4. In Track Params F1, F2 e F3, Maiusc+lettere e Maiusc+numeri cercano indietro nella lista del contesto, senza modificare la selezione.
5. Senza Maiusc, digita `16` e `FRE` velocemente: la ricerca in avanti deve rimanere identica a TEST62.9.1.
6. In un editor Rename Param, Maiusc+1 deve continuare a digitare il simbolo del layout, come in Windows; non un numero.

Windows/OSARA/NVDA e compilazione DLL devono essere verificati tramite GitHub Actions e test locale. I controlli C++ del solo algoritmo possono essere eseguiti indipendentemente.
