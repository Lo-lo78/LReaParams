# Provenienza

Il progetto LReaParams e il materiale Lua sono stati forniti/richiesti da Lo-lo.
I tre file in Legacy sono copie inalterate degli allegati, con autore dichiarato
nei loro header: **Lo-lo + GPT**. Non vengono eseguiti, modificati o redistribuiti
nell'artifact binario. Sono riferimenti per verificare il successivo porting.
Questo pacchetto non attribuisce una nuova licenza ai materiali dell'utente.

Gli header in third_party/reaper-sdk provengono da Cockos Incorporated;
mantengono integralmente i rispettivi avvisi e la licenza contenuta nei file.
Repository e commit esatti sono in third_party/reaper-sdk/manifest.json.

Il codice OSARA non è copiato né linkato staticamente. La DLL invoca soltanto
le API registrate da OSARA nell'host. OSARA rimane un'estensione distinta.
I riferimenti al suo sorgente servono a verificare il contratto delle API.

Le fixture pubblicabili sono sintetiche: nomi di plugin, parametri, celle,
progetti e GUID personali sono sostituiti. Gli originali di dati.zip non sono
inclusi. README e Docs distinguono implementazione, test e porting pendente.

TEST16 (0.0.17): Track Params passive NVDA+Up review reduced to parameter and value in Grid; contextual row announcements and Ctrl+R unchanged. No local compilation.
