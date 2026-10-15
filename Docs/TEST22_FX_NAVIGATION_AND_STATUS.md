# TEST22 — Home/End e stati FX: test manuali

1. Aprire FX Params con un FX che abbia più di 10 parametri: Ctrl+Home = primo parametro; Ctrl+End = ultimo parametro.
2. Su una colonna/gruppo di 10: Home = primo della colonna; End = ultimo della colonna; testare anche l'ultima colonna incompleta.
3. Su Custom Order, entrare in F7, provare Shift+Home ed Shift+End e verificare la selezione.
4. Aprire FX Memories (F8): Home/End = prima/ultima memoria nella colonna; Ctrl+Home/End = prima/ultima colonna non vuota.
5. Entrare in FX Value: Home = massimo, End = minimo, come nel Lua originale. La correzione Home/End riguarda la navigazione nella griglia, non le regolazioni Alt/Value o Track Params.
6. In Master e Monitor FX, scegliere un plugin bypassato e con Delta Solo attivo. Con Ctrl+Su/Giù la voce deve cominciare: `Monitor FX. Bypassed. Delta Solo. ...` e poi nome/parametro/valore.
7. NVDA+T nello stesso caso: `FX Params. Bypassed - Delta Solo. Monitor FX - nome FX`. Con uno o entrambi spenti le relative parole devono scomparire sia dal titolo sia dagli annunci.
8. Cambiare Ctrl+B e Ctrl+D a turno e verificare che lo stato della finestra venga aggiornato. Provare anche un plugin con il nome che termina con punto: evitare `..`.

## Limiti
- Nessuna compilazione locale. Lo stato Delta Solo è letto dal wrapper REAPER se il suo ultimo parametro è riconoscibile (in inglese).
- Il controllo di focus, il riconoscimento dello slider nativo e gli annunci NVDA/OSARA devono essere testati nell'host reale.
