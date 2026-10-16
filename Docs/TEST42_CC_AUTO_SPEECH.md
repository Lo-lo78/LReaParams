# TEST42.1 — Annunci NVDA: CC prima di Auto

Obiettivo: correggere unicamente il parlato degli stati dei parametri FX.

## Esempi previsti

| Situazione | Testo pronunciato |
| --- | --- |
| Né CC né Auto | `Cutoff, 1200 Hz` |
| Solo CC interno | `Cutoff, 1200 Hz. CC channel 1 CC 74` |
| Solo envelope attivo | `Cutoff, 1200 Hz. Auto` |
| CC ed envelope attivo | `Cutoff, 1200 Hz. CC channel 1 CC 74. Auto` |
| Envelope esistente ma disabilitato | niente `Auto` |

Le associazioni salvate vengono annunciate anche se Shift+C (Fixed CC) è Off;
il suffisso indica che esiste un link, non lo stato on/off del runtime. Durante
Floating CC, come nella lettura ordinaria del Lua, i link fissi non sono
annunciati. Parametri virtuali con link proprio (es. Compare) possono leggere
il CC interno, ma non `Auto` perché non hanno envelope reali.

## Collaudo REAPER/NVDA indispensabile

1. Collegare Cutoff con Ctrl+Alt+C, verificare che F8 mostri il link.
2. Ritornare alla griglia e navigare sul parametro. Deve dire nome, valore e
   `CC channel N CC M`. Ripetere con NVDA+Freccia Su e dentro F7.
3. Attivare l'automazione: `Auto` deve comparire dopo il CC, non prima.
4. Disattivare l'automazione: `Auto` scompare, il CC rimane.
5. Eliminare il link CC tramite la gestione prevista: scompare il CC.
6. Verificare che Alt+Frecce annunci soltanto il nuovo valore.
7. Provare Ctrl+Q/background, poi rientrare nello stesso FX: il CC dev'essere
   ancora visibile nella lettura normale, senza duplicare gli annunci.
8. Provare Track FX e Take FX, quindi un parametro con native MIDI Learn di
   REAPER ma senza link LReaParams. Provare un CC 0 se disponibile.
9. Provare il Floating CC: i link fissi non devono creare annunci fuorvianti.

I test di testo/formato non verificano il funzionamento NVDA, il binario né
l'interpretazione del MIDI Learn nativo: richiedono la build GitHub Actions.
Nessuna compilazione locale effettuata.
