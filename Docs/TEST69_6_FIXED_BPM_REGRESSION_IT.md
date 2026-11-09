# TEST69.6 – Recupero del rilevatore BPM fisso

La stima del tempo fisso è di nuovo indipendente dal tracciatore adattivo.
Il confronto dei tre segmenti audio usa la logica della TEST69.4, evitando
che una correzione di fase non affidabile alteri il risultato del BPM.

L’azione della tempo map rimane sperimentale e **non è stata corretta
né validata su brani reali** in questa TEST. Non usarla su progetti importanti.

## Prova

1. Importare un brano a tempo costante in una copia del progetto.
2. Assegnare l’azione «Detect BPM from selected audio item and set project tempo».
3. Confrontare il risultato con la TEST69.4.
4. Verificare che la timebase e la velocità dell’item siano ripristinate.

Il rilevatore fisso conserva la risoluzione interna di 0,1 BPM. Le tre cifre
nel messaggio non implicano una misura affidabile al millesimo.
