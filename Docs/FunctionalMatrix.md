## 0.0.46 — Stato dei contesti FX (candidato sorgente)

| Comportamento | Implementazione attuale | Conferma runtime |
|---|---|---|
| FX Chain focalizzata (Track/Take/Master) | Identificazione focalizzata esistente preservata | Da verificare |
| Browser FX interno Ctrl+P | Navigazione, Master/Monitor, inizio nome, Bypass/Delta | Da verificare |
| Riordino FX nel browser | API REAPER native, Undo, controllo GUID dopo spostamento | Da verificare |
| Ctrl+Sinistra/Destra | Switch fra item con Take FX | Da verificare |
| Ctrl+W | Da Take FX a Track FX corrente | Da verificare |
| Ctrl+Pagina Su/Giù | Non intercettato da FX Params (riservato) | Verifica statica 0.0.46.1 |
| Ctrl+Maiusc+F | Catena FX nativa dopo rilascio focus | Da verificare |
| Alt+Maiusc+F | Browser FX nativo dopo rilascio focus | Da verificare |
| FX Container annidati | Non implementato il browser gerarchico | Aperto |

# Matrice funzionale

La matrice attuale è FxCommandMatrix.csv. Gli inventari Lua CSV conservano i riferimenti completi ai due script. Status.md distingue implementazione, parità parziale e funzioni mancanti; non esiste una dichiarazione di equivalenza completa.
