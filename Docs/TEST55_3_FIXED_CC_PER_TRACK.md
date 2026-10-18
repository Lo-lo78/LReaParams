# TEST55.3 — MIDI CC Fixed specifici della traccia

Base: TEST55.2. **Non eseguire compilazioni locali**; usa GitHub Actions MSVC e poi REAPER/NVDA.

## Comportamento

- Ctrl+Alt+C registra un Fixed CC sull’esatto parametro e **GUID della traccia**.
- Per F2/F3 il binding usa `Sends|GUID sorgente|GUID destinataria|occorrenza|Parametro`; le due viste dello stesso collegamento condividono il binding. I duplicati sono distinti tramite l'ordinale all'interno di quel collegamento sorgente/destinazione.
- La ricezione di un Fixed CC modifica la traccia/il send salvato indipendentemente dalla traccia navigata. Floating CC (Ctrl+Maiusc+C) continua a seguire il parametro corrente.
- Il pickup è separato per identità, con range Volume personalizzato già salvato nel `.tp`.
- Ctrl+Canc elimina solo l’associazione specifica corrente. Alt+F8, categoria MIDI CC, mostra nome delle tracce, parametro, canale e controller; Canc elimina una sola associazione.
- I CC generici `[Track]`, `[Sends]`, `[Receives]` non sono eliminati ma diventano **legacy inattivi**. Possono essere rimossi da Track Memories, ma per ottenere un Fixed CC specifico bisogna apprendere nuovamente sulla traccia desiderata. Non esiste conversione sicura da un’associazione senza GUID a una traccia particolare.
- Il `.tp` del progetto conserva gli altri dati e aggiunge `[LReaParams.FixedCCByTarget]`. Nessuna cartella aggiuntiva.
- La modalità Fixed funziona mentre Track Params è aperto. Il MIDI globale dopo l’uscita da Track Params non è implementato da questa TEST.

## Casi da testare in REAPER

1. Bass, Pan: apprendi CC 10; Drums, Pan: apprendi CC 11. Torna a Bass o spostati su Piano: il CC 10 deve muovere **solo** Bass e CC 11 **solo** Drums.
2. Chiudi Track Params e riaprilo: entrambi i Fixed devono rimanere attivi; Tab deve indicare solo il CC specifico della traccia corrente.
3. Rinomina e riordina Bass: il CC deve rimanere associato al suo GUID.
4. Crea due send Bass→Drums; apprendi CC diversi sui due Volumi. Controlla separazione, e verifica la stessa identità entrando dal Receive corrispondente.
5. Elimina uno dei due CC con Ctrl+Canc oppure Alt+F8. Non deve sparire l'altro.
6. Prova Ctrl+Maiusc+C su un parametro Floating: deve continuare a seguire il cursore; ritorna alla mappa Fixed con Maiusc+C.
7. Dopo la cancellazione o il riordino di send duplicati, ricontrolla le associazioni: l'ordinale può cambiare. La TEST non promette identità persistente dopo riordinamenti di routing senza GUID.

Controlli statici e test C++ di persistenza **non sono collaudi audio/MIDI reali**.
