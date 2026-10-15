# LReaParams — TEST11 (0.0.12)

**Solo codice sorgente C++.** Compilazione esclusivamente tramite GitHub Actions.

Questa versione affronta la lettura involontaria delle lettere da parte di NVDA:
la finestra da un pixel ora mette il focus su un controllo **STATIC**, non più
su un campo `EDIT`. Lo spostamento dei parametri è annunciato soltanto dalle
chiamate intenzionali a OSARA. La griglia non invia annunci quando non cambia
posizione; non esiste un cursore di editazione per leggere caratteri ai bordi.

**Ctrl+R**: ripete espressamente il parametro corrente con OSARA, in FX Params
e Track Params. È un metodo affidabile anche se NVDA+Freccia Su non dovesse
leggere il testo statico in assenza di cursore di sistema. **NVDA+T** conserva
il titolo di navigazione con nome dell'effetto/traccia.

I controlli per valori, F1–F3, Alt+Home/End, Ctrl+Su/Giù tra FX, memoria di
sessione e importazione dei profili sono invariati.

Leggere `Docs/TEST11_QUIET_FOCUS.md`. Non è stata eseguita alcuna build locale.
