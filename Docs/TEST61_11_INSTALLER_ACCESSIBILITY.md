# TEST61.11 — Installer accessibile per NVDA

Installer NSIS MUI2: sempre possibile scegliere la lingua all'avvio, quindi i
pulsanti del wizard seguono la lingua selezionata. In italiano: Avanti,
Indietro, Installa (i nomi esatti sono quelli di NSIS per la lingua italiana).

Flusso: scelta lingua, Benvenuto, cartella risorse di REAPER, installazione
con log visibile, chiusura automatica dopo il successo. Nessuna finestra OK
prima della copia e nessuna pagina finale vuota. Se reaper.ini non è nella
cartella, l'avviso di percorso potenzialmente errato resta attivo.

## Collaudo manuale Windows/NVDA
1. Lanciare l'installer con NVDA: l'elenco lingue deve essere accessibile.
2. Scegliere Italiano: cercare Avanti/Indietro e la descrizione corretta.
3. Selezionare la cartella delle risorse REAPER, con reaper.ini.
4. Chiudere REAPER e selezionare Installa: nessun OK intermedio.
5. A installazione completata la finestra deve chiudersi da sola, senza Invio.
6. Controllare DLL, 7 lingue, licenze, sorgente e conservazione dei profili.
7. Verificare la segnalazione di errore su destinazioni non scrivibili,
   senza cancellare i dati esistenti. Testare anche la disinstallazione.

Non sono state eseguite build locali o prove in REAPER: la compilazione è
esclusiva del workflow GitHub Actions.
