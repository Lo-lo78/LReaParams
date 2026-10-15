# Aggiornamento TEST27 (0.0.28): il F12 SENZA modificatori ora resta libero e riservato a LReaParams, senza inoltro a OSARA e senza chiusura della finestra di navigazione. Ctrl+F12 e Ctrl+Maiusc+F12 mantengono la memoria 12; Alt+Maiusc+Frecce naviga i selezionati in F7. Le istruzioni storiche su F12/Alt+Frecce riportate sotto descrivono versioni precedenti e sono superate. Per il collaudo attuale: Docs/TEST27_KEYS_F12.md.

# Collaudo della Fase 0 in REAPER

Tutte le prove in questa pagina sono **DA ESEGUIRE dall'utente** dopo GitHub
Actions. Non sono state eseguite dall'assistente. Il build verde dimostra solo
compilazione e test nativi del formato/storage, non l'accessibilità della DLL.

## Primo giro, circa 5 minuti

1. Metti la DLL in UserPlugins e riavvia. Cerca le nove azioni LReaParams (l'azione Exit è stata rimossa: Escape è interno).
   Nessuna finestra di navigazione deve apparire né ricevere focus.
2. A navigazione spenta prova frecce, lettere, Spazio, Ctrl+Spazio e F12: REAPER
   e OSARA devono comportarsi come prima.
3. Su un progetto di test apri un JSFX, assegna una scorciatoia a FX Params e
   attivala dal plugin. Tab deve leggere un parametro. Su/Giù devono scorrerlo.
   Alt+Su deve cambiare il valore nella GUI reale; Ctrl+Z, dopo uscita, lo annulla.
4. Invio entra in Value; Su modifica; Esc torna in Grid; un altro Esc esce.
   In TEST3 prova anche Ctrl+Home/Ctrl+End per estremi assoluti FX.
   Per Track Params F1 prova frecce Su/Giù per tracce e Sinistra/Destra
   per i nove campi orizzontali della riga, senza cambiare la selezione TCP.
5. Riattiva e premi F12: la navigazione cessa e Shortcut Help deve funzionare.
   Esci da Shortcut Help con F12, poi riattiva FX Params esplicitamente.
6. Se le frecce non arrivano in una GUI, scegli Settings → Sì per l'hook del
   thread REAPER e ripeti. Annota quale backend funziona.

## Matrice input e focus

| Caso | Verifica attesa |
| --- | --- |
| FX chain docked | Lettura, nudge, mouse e selezione visibile coerenti |
| FX chain floating | Stesso comportamento, nessuna finestra sovrapposta |
| FX floating con GUI nativa | Ricezione dei tasti con ogni backend |
| Take FX | Modifica il take corretto; Undo riguarda l'item |
| FX master / input FX / container | Contesto restituito dal SDK corretto, nessun FX differente modificato |
| Due istanze dello stesso plugin | Nessuna confusione tra GUID |
| UI di plugin bridged / su altro thread | Registrare il limite, non aspettarsi copertura dal thread hook |
| Tasto tenuto premuto | Ripetizione dei nudge senza invocazioni doppie; Invio non rimbalza |
| Alt+frecce e rilascio in ordine diverso | Nessun Alt bloccato né beep/azione duplicata |
| F12 / Alt+F12 / altre combinazioni | Il tasto passa e LReaParams esce |
| Shortcut Help attivato da altra azione | Nessuna modifica dei valori mentre Help è attivo |
| Ctrl+Spazio / Spazio | La modalità esce e lascia il comando al normale routing, una sola volta |
| Menu Extensions | Cattura cessata, menu usabile da tastiera e mouse |
| Campo Edit, ComboBox, ricerca REAPER | Il primo carattere passa senza modifica dei parametri |
| Editor testo custom del plugin | Verificare separatamente: limite aperto; uscire prima con Esc |
| Passaggio a Firefox/NVDA/dialogo esterno | Nessuna intercettazione nel processo esterno |
| Chiusura GUI, eliminazione FX/traccia/take | Uscita o rifiuto del comando; nessun crash |
| Cambio progetto / riordino catena FX | Il target precedente non viene riutilizzato |
| Mouse del collaboratore | Plugin reale sempre visibile; nessun hook mouse |
| Scaricamento / chiusura REAPER | Nessun callback o hook pendente della DLL |

Provare anche tastierino, caratteri accentati, layout italiano, tasti funzione
non implementati, Ctrl/Shift/Alt e passaggio ad Action List. In questa fase i
tasti non mappati escono e passano: non costituiscono una simulazione delle
funzioni avanzate Lua. Le prove complete F7/F8/F10/Track/Library verranno eseguite
nelle fasi rispettive e non possono essere marcate PASS adesso.

## Dati e I/O

Il worker parte all'avvio. L'importazione esplicita annuncia il riepilogo quando
termina. All'avvio non interrompe il parlato con annunci. I riepiloghi diagnostici
sono disponibili tramite OutputDebugString, senza log con nomi personali.

1. Con cartelle storiche assenti: creazione cartelle vuote e avvio normale.
2. Con i dati storici: nuovi .fx/.pp/.tp nella stessa struttura; vecchi TXT tutti presenti.
3. Secondo import: nessun duplicato né modifica alle date dei file già convertiti.
4. Modifica un profilo nativo e reimporta: non sovrascriverlo.
5. Modifica un TXT storico: candidato in Settings/ImportConflicts; originale integro.
6. Copia un TXT valido nel nuovo ramo: backup identico, conversione, rimozione solo
   di quel TXT. Usa prima una copia di test, non l'unica copia dei tuoi dati.
7. TXT sconosciuto/malformato/Handoff/Return: resta invariato.
8. Negazione permessi, file aperto da altri, spazio disco insufficiente: originale integro.
9. Unicode, apostrofi, sottocartelle, percorsi lunghi, installazione portable.
10. Avvia un import durante il playback e chiudi REAPER durante un import.
    Verifica continuità audio e tempo di uscita; segnala eventuali ritardi del filesystem.

## Come riferire un problema

Indica versione REAPER/OSARA/NVDA, nome del plugin, track o take, docked/floating,
backend selezionato, tasto premuto e cosa viene pronunciato. Per un errore di
compilazione incolla il primo errore e le righe circostanti del job build-windows.
Non serve creare token, dare accesso al repository o eseguire build locali.

## TEST4: titoli virtuali e memorie

All'attivazione dei navigatori OSARA deve annunciare la modalità con un
singolo messaggio che include il titolo e il parametro/traccia iniziale.
NVDA+T deve continuare a leggere il titolo REAPER: un titolo finestra
separato richiederebbe un oggetto finestra accessibile, che non fa parte
architettura senza finestre della DLL.

Il menu Memories espone solo voci preparatorie, senza scrittura di dati.
Tasti funzione riservati: FX F1–F11, Track F4–F11; F12 restituito a OSARA.


### TEST5 NVDA title proxy

Verificare NVDA+T, F1/F2, F12, Esc, ritorno focus, Alt+Tab e nessun ostacolo grafico con un collaboratore vedente. Il proxy e' sperimentale e disattivabile dal menu. Vedere `Docs/TitleProxyTest.md`.
