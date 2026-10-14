# Formati e importazione

La conversione non riscrive il payload storico. Lo incapsula in un header ASCII:

```text
LREAPARAMS_PROFILE_V1
Kind=FX
PayloadBytes=1234

<esattamente 1234 byte originali>
```

Kind è `FX`, `TRACK` o `PP`; estensione rispettiva `.fx`, `.tp`, `.pp`.
Le tre righe header terminano con LF; una riga vuota separa il payload.
PayloadBytes conta byte, non caratteri. Il payload conserva UTF-8, eventuale BOM,
CRLF/LF, commenti, alias, sezioni sconosciute e numeri senza riformattazione.
Per tornare al TXT, `parseNative(...).payload` restituisce i byte originali.
Modificando manualmente il payload occorre aggiornare PayloadBytes.

Il parser distingue contenuto e ramo. Un PP valido messo in Plugins è rifiutato,
non spostato automaticamente in Params. Version=2/3 da solo non basta.
Sono richiesti identità e sezioni, e validati i record noti: indici interi,
parametri normalizzati finiti 0–1, slot 1–12, canale 1–16, CC 0–127, GUID e Count.
Gli indici virtuali FX negativi e il terzo campo alias sono ammessi perché
presenti nei Lua e negli originali. Le sezioni future sono conservate opache.
I campi opzionali sconosciuti non sono interpretati come comandi.

Il formato PP accetta solo Mode=cell. I nomi Handoff e Return sono sempre
esclusi dall'importazione, anche se contengono una cella apparentemente valida.
Nessun file di trasferimento temporaneo viene generato dalla DLL.

Sono rifiutati NUL, file vuoti, payload oltre 32 MiB, header duplicati,
sezioni duplicate, record noti non validi e lunghezze incoerenti.
La validazione è conservativa: un futuro dialetto sconosciuto resta TXT e
richiede un aggiornamento del parser. Questo è preferibile a perderne informazioni.

## Transazione

1. Il worker scansiona soltanto i tre rami previsti, all'avvio o su comando.
2. Blocca il singolo sorgente contro scrittura e rinomina per la durata della
   transazione. Sui TXT attivi richiede anche il diritto DELETE: se negato non
   forza permessi e segnala errore.
3. Esegue parsing, validazione e SHA-256 con Windows CNG.
4. Verifica o crea `Backups/<SHA256>.txt`, esattamente uguale al sorgente.
5. Scrive un temporaneo con CREATE_NEW, FlushFileBuffers e confronto byte;
   rinomina senza sostituire un destinatario esistente e rilegge il risultato.
6. Verifica nuovamente parser e payload; scrive un record d'importazione.
7. Solo per un TXT delle cartelle nuove, marca per cancellazione lo stesso
   handle sorgente ancora bloccato. I TXT sotto Scripts non sono mai cancellati.

Una destinazione esistente con byte diversi non viene mai sovrascritta.
Il candidato va in `Settings/ImportConflicts/<ramo>/<percorso>.<SHA256>.<tipo>`.
Il TXT attivo in conflitto rimane presente. Nessun candidato viene applicato.
Il registro `Settings/Imports` associa hash della path sorgente e hash del
contenuto. Un sorgente già importato, invariato, non riscrive una destinazione
che l'utente abbia poi modificato. Le reimportazioni identiche non cambiano date
o contenuto dei file; viene comunque letto il ramo su ogni scansione richiesta.

Il registro e i backup contengono fingerprint di provenienza, non versioni
di preferenze attive. L'applicazione dei profili e l'importazione ExtState sono
passaggi distinti non ancora implementati.

I rami relativi, compreso Projects/<progetto>/F4, sono mantenuti usando
std::filesystem::path e Win32 Unicode. Junction e symlink vengono rifiutati,
anche lungo gli antenati, per evitare scansioni fuori dai rami previsti.
Una resource path che usa intenzionalmente junction richiede una futura policy
esplicita. Path molto lunghe dipendono anche dal supporto del processo REAPER;
gli errori mantengono i sorgenti, senza abbreviare o cambiare i nomi.

Un errore di flush può lasciare un temporaneo `.tmp-*`, mai interpretato come
profilo. Il backup originale resta recuperabile; non viene effettuata pulizia
indiscriminata. La resistenza a interruzioni di corrente non può essere garantita
oltre ai contratti del filesystem e di FlushFileBuffers/MoveFileEx.
