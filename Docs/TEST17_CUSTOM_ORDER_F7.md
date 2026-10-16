> Documento storico TEST30. Per stato attuale e limiti prevalgono Status.md e FxCommandMatrix.csv.

# TEST17 — Custom Order e F7 (verifica richiesta in REAPER)

Il codice è migrato parzialmente dal Lua FX Params originale; nessuna
compilazione locale e nessuna verifica di comportamento di NVDA sono state
eseguite. Conservare una copia esterna dei profili importanti prima del test.

## Collaudo principale (su progetto e plugin di prova)

1. Avvia FX Params e premi Ctrl+L. Verifica annuncio Custom order e ordine
   inizialmente identico al Plugin order. Senza modifiche NON deve essere
   creato un file di memoria Custom per quel solo Ctrl+L.
2. In Custom premi F7; il titolo NVDA+T contiene F7 Edit. Muoviti con
   le frecce, prova Ctrl+A, Shift+Spazio, Tab, Shift+frecce, tornata indietro.
3. Seleziona due parametri, Ctrl+X, vai in un'altra cella, Ctrl+V.
   Controlla ordine e valore reale. L’Undo della Custom Order non è ancora
   implementato: Ctrl+Z riguarda soltanto eventuali azioni REAPER.
4. Prova Ctrl+C / Ctrl+V per creare una copia intenzionale; le due
   occorrenze devono controllare lo stesso indice REAPER.
5. Senza selezionare nulla usa Ctrl+Canc per nascondere il parametro corrente; verificane la
   presenza nel Plugin order (Ctrl+L) e l'assenza nel Custom order.
   In F7 Custom, Ctrl+Maiusc+Canc ripristina tutti gli hidden come
   soluzione temporanea in attesa del Memory Manager F8.
6. In F7 prova Ctrl+Invio per cambiare alias. Usa anche una parola
   accentata con tastiera italiana. Invio conferma, Esc annulla.
7. Premi Ctrl+G e salva con Ctrl+Maiusc+F1 un gruppo selezionato.
   Ctrl+F1 lo richiama. Ctrl+L esce dal gruppo senza cambiare il tipo
   d'ordine sottostante. Ctrl+M seleziona i memory positions.
8. Cambia FX e traccia e torna indietro: memoria FX e parametro per GUID,
   Custom Order per plugin, ordine e nomi dei parametri devono tornare.
9. Chiudi/reinserisci la DLL e verifica che il profilo `.fx` persista.
   Verifica `LReaParams/Backups/ProfileEdits` dopo un salvataggio su
   profilo esistente; l'importer non deve sovrascrivere file modificati.
10. Verifica che Track Params, Value slider, focus NVDA, Alt+frecce,
    Ctrl+Shift+Su/Giù e nome della finestra siano rimasti invariati.

## Limiti attuali

Questo non è ancora un port completo di F7 del Lua, perché F7 usa
sottosistemi Lua ancora assenti (F8, Search filtrata, gruppi avanzati,
parametri virtuali speciali, ecc.). I nomi vengono digitati da tastiera
nel focus owner già esistente e non in un nuovo controllo EDIT di Windows.
Perciò il test di NVDA per rinomina e campi testuali è particolarmente
importante. F12 è riservato alla Shortcut Help di OSARA: slot 12 non è
raggiungibile dalle scorciatoie in questa versione.

Nessun comando CMake, compilazione o eseguibile locale è stato utilizzato.
