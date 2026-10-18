# LReaParams TEST56.2 — Griglia nomi dei parametri TCP F4

Base: TEST56.1, C++ 0.0.56. **Soltanto sorgente. Non eseguire build locali**;
compilazione e test C++ tramite GitHub Actions.

## Come si apre

In Track Params F4, portarsi sull'intestazione di un FX e premere **Invio**.
Si apre una griglia con *tutti i nomi* dei parametri di quell'FX (senza valori).
I parametri già esposti nel TCP sono distinguibili con **Tab**, che dichiara
"visible in TCP". NVDA+Su e frecce leggono il solo nome, senza valore.
Un FX senza parametri ha una griglia vuota accessibile e può essere chiuso con Esc.

## Tasti nella griglia

| Tasto | Azione |
|---|---|
| Su/Giù | Parametro precedente/successivo nella colonna |
| Sinistra/Destra | Colonna precedente/successiva, mantenendo l'indice relativo |
| F1/F2 | Diminuisce/aumenta l'altezza della griglia (1–200, default 10) |
| PagSu/PagGiù | Cinque parametri, nei limiti della colonna |
| Home/End | Inizio/fine colonna |
| Ctrl+Home/Ctrl+End | Primo/ultimo parametro complessivo |
| Tab | Nome, visibilità TCP, posizione e altezza griglia |
| Invio | Rende visibile il parametro TCP (se non lo era) e torna in F4 sul parametro |
| Ctrl+Invio | Alterna visibile/non visibile, restando nella griglia |
| F6 | Alterna griglia completa e griglia dei parametri già visibili |
| Esc / F4 | Torna alla griglia F4 senza cambiare il suono |

Da F4, **F6** apre direttamente la griglia globale dei parametri TCP già visibili
(come la relativa funzione Lua). Qui Invio rimuove quello corrente e ritorna
alla colonna FX corrispondente; Ctrl+Invio rimuove senza uscire. In caso di
rimozione, il cursore torna al parametro TCP vicino o all'intestazione.

## Integrità e compatibilità

Il gestore agisce solo sul collegamento fra parametro e TCP, **non sul valore
sonoro** del parametro. Usa `CountTCPFXParms` / `GetTCPFXParm` come verità per
la visibilità. Per applicare il collegamento prova l'API REAPER e, dove necessario,
una modifica mirata al solo `PARM_TCP` del plugin identificato dal suo `FXID`.
Rifiuta modifiche in caso di chunk sconosciuti, identificazione ambigua o catena
FX cambiata; verifica il risultato e tenta il rollback se l'applicazione fallisce.
Ogni modifica è annullabile con Undo.

Il formato `.tp` del progetto e FX Params rimangono invariati. F1/F2/F3
conservano tutti i comportamenti della 55.13. Questa TEST **non abilita ancora**
l'editing di valore da F4, il MIDI F4 e le automazioni F4.

## Collaudo con REAPER e NVDA

1. In una traccia inserire ReaEQ e ReaComp; inizialmente esporre pochi controlli nel TCP.
2. F4, sull'intestazione ReaEQ, Invio: verificare la griglia di **soli nomi**.
3. F1/F2 modificano la dimensione; verificare bordi silenziosi, Tab e NVDA+Su.
4. Ctrl+Invio su un parametro non visibile: controllare in REAPER che appaia nel TCP;
   Ctrl+Invio di nuovo: che sparisca, restando sempre nella griglia.
5. Invio: il parametro viene aggiunto se necessario e si torna in F4 su quello.
6. F4, F6: visualizza quelli già visibili; Invio ne rimuove uno e torna vicino.
7. Confermare che il suono e gli altri parametri TCP non siano cambiati.
8. Ripetere con un FX senza parametri, FX omonimi, due istanze dello stesso FX,
   e dopo lo spostamento di un FX nella catena: non modificare mai l'istanza sbagliata.
9. Verificare Undo e F1/F2/F3, Ctrl+Tab, FX Memories e `.tp` del progetto.

**Stato:** verifiche statiche eseguite. Build MSVC, native tests e prova REAPER/NVDA
rimangono da eseguire tramite GitHub Actions e test manuali dell'utente.
