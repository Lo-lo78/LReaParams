#!/usr/bin/env python3
"""Regenerate self-contained, keyboard-accessible localized HTML manuals.
English originals remain in Guide root. No JavaScript or online translation.
"""
from pathlib import Path
from html import escape
import re

ROOT = Path(__file__).resolve().parent.parent / 'Guide'
LANGS = [
  ('en', 'English'), ('it','Italiano'), ('es','Español'),
  ('fr','Français'), ('ru','Русский'), ('zh-CN','简体中文'), ('ja','日本語')
]
FX_KEYS = ['F1 / F2','F3 / Tab / \\', 'Enter / Esc','Alt+Up/Down','Alt+Page Up/Down','Alt+Left/Right','Ctrl+E','Ctrl+Up/Down','Ctrl+Shift+Up/Down','Ctrl+Page Up/Down','Ctrl+F','F7','F8','F10','F11','Ctrl+Shift+M','Ctrl+Alt+C','Shift+C','Ctrl+Shift+C','Ctrl+Shift+A','Ctrl+Shift+Alt+A','Ctrl+Q','Space / Ctrl+Space','Ctrl+I / Ctrl+O']
TR_KEYS = ['F1','F2 / F3','F4','Alt+Enter (F4)','F5','F6','F7','F8','Enter / Esc','Alt+Up/Down','Alt+Page Up/Down','Alt+Home/End','Ctrl+E','Ctrl+F','Ctrl+Tab','Ctrl+Shift+M','Ctrl+Alt+C','Shift+C','Ctrl+Shift+C','Ctrl+Shift+A','Ctrl+Shift+Alt+A','Ctrl+Q','Space / Ctrl+Space','Ctrl+I / Ctrl+O']

def lines(s): return [v.strip() for v in s.strip().splitlines() if v.strip()]

def sections(s):
    out=[]
    for line in lines(s):
        assert '|' in line, line
        title,body=line.split('|',1)
        out.append((title.strip(),body.strip()))
    return out

I18N = {'en': {'ui': ('LReaParams User Guide', 'Choose a language', 'Choose a guide', 'FX Params', 'Track Params', 'Contents', 'Shortcut', 'Action', 'Change language', 'Full reference', 'Native REAPER extension 0.0.67', 'Back to language selection')}}

def locale(tag, ui, fx, tr, fkeys, tkeys):
    if len(lines(fkeys)) != len(FX_KEYS) or len(lines(tkeys)) != len(TR_KEYS):
        raise ValueError(f'{tag}: FX {len(lines(fkeys))}/{len(FX_KEYS)}, Track {len(lines(tkeys))}/{len(TR_KEYS)}')
    I18N[tag] = {'ui':ui, 'fx':sections(fx), 'track':sections(tr),
                 'fxkeys':lines(fkeys),'trkeys':lines(tkeys)}

# ui = (home, pick, choose, fx, track, contents, keys, action, change, full, intro, back)
locale('it', (
 'Guida di LReaParams', 'Seleziona una lingua', 'Scegli una guida',
 'FX Params', 'Track Params', 'Indice', 'Scorciatoia', 'Funzione',
 'Cambia lingua', 'Riferimento completo in inglese',
 'Estensione nativa REAPER 0.0.67. Guide accessibili con NVDA e OSARA.', 'Torna alla scelta della lingua'),
 '''
Installazione e accessibilità|Copia reaper_lreaparams.dll nella cartella UserPlugins delle risorse di REAPER e l’intera cartella Guide in LReaParams/Guide. Riavvia REAPER, cerca le azioni LReaParams: FX Params, Track Params e Open User Guide e assegna le scorciatoie preferite. I vecchi launcher Lua non servono più. OSARA gestisce gli annunci; NVDA legge titolo, griglia e campi di modifica. Tab legge il contesto esteso e NVDA+freccia su il controllo corrente.
Navigazione e modifica dei parametri|Le frecce percorrono la griglia. F1 e F2 modificano il numero di colonne; F3 riassume griglia e Step. Invio entra o esce dalla modalità Valore, dove le frecce verticali cambiano il valore. Alt+frecce verticali modifica direttamente dalla griglia; Alt+Pagina su/giù usa passi più grandi; Alt+Home/Fine imposta gli estremi. Alt+frecce orizzontali regola lo Step del singolo parametro da -10 a +10. Ctrl+E apre un campo numerico standard; Invio conferma ed Esc annulla. Ctrl+Backspace ripristina Grid 10 e Step 0.
Browser FX interno: F10|F10 apre il browser interno e permette di scegliere gli FX della traccia, del take, del Master o del Monitor secondo il contesto. Invio o F10 apre l’FX selezionato nella sua griglia. Ctrl+su/giù cambia FX; Ctrl+Pagina su/giù lo sposta realmente nella catena; Ctrl+B abilita o bypassa, Ctrl+Alt+B mette online/offline. Ctrl+P non è più il comando del browser. Ctrl+Shift+F e Alt+Shift+F aprono invece le finestre native di REAPER.
Audio Pin Connector: F11|Il Pin Connector è ora in FX Params, non più in Track Params. F11 apre la matrice dei pin audio dell’FX selezionato; funziona anche da browser F10 e dagli editor supportati. Sinistra/destra cambia pin, su/giù cambia canale, Invio o Spazio collega o scollega, Canc cancella il collegamento. Ctrl+frecce cerca celle collegate; Tab o F11 legge la cella. Sono gestiti fino a 128 canali tramite due banchi di pin, quando disponibili. “Attive” indica una cella collegata; una cella vuota viene letta senza il prefisso “Disconnected”. Esc ritorna al punto precedente.
Ordini, gruppi e F7|L’ordine Plugin è il riferimento originale. L’ordine Custom può rinominare, nascondere, duplicare e spostare le occorrenze visualizzate senza cambiare i numeri reali dei parametri. I gruppi sono indipendenti dall’ordine Custom. F7 apre la modifica strutturale: Shift+frecce seleziona, Ctrl+C/X/V copia/taglia/incolla le occorrenze consentite, Ctrl+Z/Y annulla/ripristina, Ctrl+Invio rinomina nel contesto adatto. Alt+Shift+frecce percorre le sole celle selezionate.
Confronto A/B e memorie|F8 confronta Original e Edited; due pressioni ravvicinate di F8 aggiornano Original. F8 NON è il gestore delle memorie. Ctrl+Shift+M apre le memorie FX; Ctrl+F1–F12 richiama e Ctrl+Shift+F1–F12 salva gli slot, in base alla modalità Gruppo/Memoria scelta. Ctrl+L alterna Plugin e Custom quando consentito.
MIDI CC e automazioni|Ctrl+Alt+C apprende un MIDI CC fisso per il parametro; Shift+C attiva o disattiva la mappatura; Ctrl+Shift+C gestisce il CC fluttuante con pickup. Ctrl+T commuta la lettura vocale dei cambiamenti MIDI. Ctrl+Shift+A attiva o disattiva l’inviluppo reale del parametro e può far annunciare “Auto”; Ctrl+Shift+Alt+A apre la conferma protetta per eliminare le automazioni. Ctrl+Q ritorna a REAPER lasciando attivo il controllo MIDI compatibile.
ReaEQ e altri FX|Sono gestiti i controlli specifici di ReaEQ, ReaComp e ReaGate, compresi i parametri virtuali quando supportati. Alt+F1/F2 cambia preset dell’host; Alt+F3/F4 passa ai parametri automatizzati. Ctrl+B bypassa e Ctrl+D gestisce Delta Solo. I parametri reali e quelli virtuali possono avere regole diverse: verifica sempre il nome e l’unità letti da NVDA.
Ricerca, appunti e ripristino|Lettere, numeri e punteggiatura cercano ciclicamente i nomi visibili; Maiusc inverte la direzione. Ctrl+F apre la ricerca, Ctrl+R richiama le ricerche recenti. Backspace ripristina il parametro, mentre Ctrl+Shift+Backspace ripristina il Default memorizzato dove disponibile. In F7 gli appunti modificano l’ordine visivo; nella normale modalità Valore le azioni dipendono dal contesto. Ctrl+E resta la scelta per inserire numeri precisi.
Trasporto, marcatori e ascolto|Spazio controlla Play/Stop; Ctrl+Spazio Play/Pausa. Ctrl+I/O percorre i marcatori precedenti/successivi e Ctrl+1–0 richiama i marcatori 1–10. Alt+F10/F11/F12 e Alt+Shift+F10/F11/F12 gestiscono i due misuratori Peak Watcher di OSARA. I tasti non devono interferire con campi EDIT o finestre REAPER esterne.
Profili e migrazione dal Lua|I profili specifici degli FX sono conservati nella cartella LReaParams/Plugins come file .fx. La DLL può importare dati TXT storici compatibili; non eseguire i vecchi navigatori Lua insieme alla DLL. Le impostazioni del Pin Connector si applicano tramite le API native di REAPER e non modificano automaticamente il numero di canali della traccia. Questa guida riguarda la versione 0.0.67 e non lo script Stretch Marker.
''',
 '''
Installazione e orientamento|Installa la DLL in UserPlugins e la cartella Guide sotto LReaParams/Guide nella directory delle risorse di REAPER. Le azioni Track Params e FX Params sono separate; Ctrl+Tab passa dall’una all’altra quando il contesto lo permette. OSARA annuncia i valori, NVDA legge il controllo corrente, Tab fornisce informazioni estese. Esc torna alla pagina precedente oppure chiude il navigatore.
Pagine disponibili F1–F7|F1 Tracce; F2 Send; F3 Receive; F4 parametri FX visibili nel TCP; F5 impostazioni MIDI della traccia; F6 uscite audio hardware fisiche; F7 ReaRoute. F8 non è utilizzato in Track Params. Il vecchio Pin Connector non è più in F5: ora si trova in FX Params con F11.
F1: tracce e cartelle|Le frecce su/giù cambiano traccia, sinistra/destra cambia campo: volume, pan, width, mute, solo, inversione di fase, numero di send, receive e FX. Invio cambia valore, attiva un interruttore o apre F2/F3/F4 dai contatori. Ctrl+Invio espande o chiude la cartella; Ctrl+Alt+su/giù cerca altre cartelle. Maiusc+Spazio seleziona una traccia, Ctrl+A seleziona le visibili, Ctrl+C/X/V copia/taglia/incolla le tracce.
F2 e F3: send e receive|Le pagine F2 e F3 mostrano le connessioni audio tra le tracce, con volumi, pan, canali e opzioni di invio. Si naviga con le frecce e si modificano i valori con Invio oppure Alt+frecce. Da F1, Ctrl+Shift+S avvia l’operazione in due passaggi per creare send: seleziona prima le sorgenti e poi le destinazioni. Ctrl+Shift+R fa l’inverso per i receive. Esc annulla una preparazione in corso.
F4: parametri FX nel TCP|F4 mostra esclusivamente i parametri FX esposti nel pannello della traccia. Ctrl+su/giù cambia FX, Ctrl+Shift+su/giù cambia traccia con FX e Ctrl+Pagina su/giù sposta l’FX nella catena. Invio apre la modalità Valore, Alt+su/giù modifica, Ctrl+E apre l’editazione numerica. Se mancano controlli TCP, premi Alt+Invio per aprire la griglia dei nomi; Invio aggiunge il parametro, Ctrl+Invio lo aggiunge o rimuove rimanendo nella lista. Canc elimina il controllo dal TCP, non l’FX.
F5: MIDI traccia|F5 comprende uscita hardware MIDI, relativo canale, mappa dei canali d’ingresso, canale di controllo e routing MIDI. Su/giù sceglie il campo; Alt+su/giù modifica la scelta, Alt+Pagina cambia più rapidamente e Alt+Home/Fine raggiunge gli estremi. Tab o F5 legge il campo corrente. Non richiede che in F4 sia presente alcun FX.
F6: uscite hardware audio|F6 mostra la colonna “Add hardware output” anche quando una traccia non ha ancora uscite. Nella colonna Aggiungi scegli una destinazione fisica con Alt+su/giù e premi Invio per crearla, senza aprire il menu routing di REAPER. Le uscite esistenti contengono volume, pan, mute, fase, mono, sorgente, destinazione e altre impostazioni. Sinistra/destra cambia uscita, su/giù cambia campo. Non confondere le uscite hardware con ReaRoute.
F7: ReaRoute|F7 contiene la colonna di ingresso ReaRoute, la gestione/Aggiunta delle uscite e le colonne per le uscite virtuali esistenti. Le frecce navigano, Alt+frecce modifica, Invio crea o attiva secondo il campo, Canc rimuove una singola uscita ReaRoute. Il driver o bridge ReaRoute deve già essere disponibile sul sistema: questa funzione non lo installa.
Valori e memorie|Invio alterna Griglia e Valore ove previsto; Alt+su/giù cambia il valore, Alt+Pagina usa passi grandi, Alt+sinistra/destra regola lo Step da -10 a +10. Ctrl+E apre un vero campo EDIT. Ctrl+Shift+M apre Track Memories, non F8; nelle posizioni supportate Ctrl+F1–F12 richiama gli slot e Ctrl+Shift+F1–F12 li salva. Ctrl+Shift+I modifica i limiti del volume dove previsto.
MIDI CC e automazione|Ctrl+Alt+C apprende il MIDI CC fisso, Shift+C commuta la mappa, Ctrl+Shift+C usa il CC fluttuante. Ctrl+T controlla la voce per MIDI e Ctrl+Shift+T quella dei valori modificati. Ctrl+Shift+A gestisce l’automazione reale dei campi supportati; Ctrl+Shift+Alt+A richiede conferma prima di cancellare le automazioni di traccia. La mappatura fissa è legata alla traccia/FX/connessione reale, non alla sola posizione visualizzata.
Filtro, trasporto e profili|Ctrl+F cerca nelle tracce, nei send/receive e nei nomi TCP; le iniziali percorrono i nomi visibili. Spazio e Ctrl+Spazio controllano il trasporto; Ctrl+I/O cerca i marcatori. I profili Track sono nel progetto come file .tp nella cartella LReaParams/Tracks; quelli FX sono .fx in Plugins. La DLL importa dati Lua compatibili ma non richiede launcher Lua. Questa guida non riguarda Stretch Marker.
''',
 '''
Diminuisce/aumenta le colonne della griglia
Legge griglia e Step / contesto completo / contesto breve
Entra/esce dalla modalità Valore o torna indietro
Modifica fine il parametro selezionato
Modifica più rapidamente il valore
Cambia lo Step memorizzato per il parametro
Apre la modifica numerica accessibile
FX precedente/successivo nella catena
Traccia precedente/successiva con FX
Sposta fisicamente l’FX nella catena
Cerca un parametro
Modifica strutturale di Custom e Gruppi
Confronto Original/Edited (non le memorie)
Browser FX interno
Audio Pin Connector fino a 128 canali
Apre FX Memories
Apprende un MIDI CC fisso
Attiva/disattiva la mappa MIDI CC fissa
Attiva il MIDI CC fluttuante
Attiva/disattiva l’automazione del parametro
Conferma protetta per eliminare automazioni
Ritorna a REAPER mantenendo il MIDI compatibile
Play/Stop / Play-Pausa
Marcatore precedente/successivo
''',
 '''
Griglia delle tracce
Send / Receive
Controlli FX visibili nel TCP
Apre il selettore dei parametri TCP
Impostazioni MIDI della traccia
Uscite audio hardware e comando Aggiungi
Ingressi/uscite virtuali ReaRoute
Nessuna pagina assegnata
Modifica un valore oppure torna indietro
Cambia il valore di un campo
Modifica a passi più grandi
Valore minimo/massimo
Campo accessibile per inserire un numero
Cerca o filtra gli elementi visibili
Passa fra Track Params e FX Params
Apre Track Memories
Apprendimento MIDI CC fisso
Attiva/disattiva la mappa dei CC fissi
Attiva il CC fluttuante
Attiva/disattiva l’automazione supportata
Conferma protetta per rimuovere automazioni
Ritorna a REAPER con MIDI compatibile attivo
Play/Stop / Play-Pausa
Marcatore precedente/successivo
''')
locale('es', (
 'Guía de LReaParams','Seleccionar idioma','Elegir una guía','FX Params','Track Params',
 'Índice','Atajo','Función','Cambiar idioma','Referencia completa en inglés',
 'Extensión nativa de REAPER 0.0.67. Guías accesibles para NVDA y OSARA.', 'Volver a la selección de idioma'),
 '''
Instalación y accesibilidad|Copia reaper_lreaparams.dll a UserPlugins y toda la carpeta Guide a LReaParams/Guide dentro de los recursos de REAPER. Reinicia REAPER y busca las acciones LReaParams: FX Params, Track Params y Open User Guide. Asigna los atajos que prefieras. Los lanzadores Lua antiguos ya no son necesarios. OSARA comunica los mensajes y NVDA lee la ventana de navegación. Tab lee el contexto completo; NVDA+flecha arriba permite revisar el control.
Navegación y valores|Las flechas recorren la cuadrícula. F1/F2 reducen o aumentan las columnas y F3 anuncia la cuadrícula y el paso. Intro cambia entre cuadrícula y modo Valor. Alt+arriba/abajo ajusta desde la cuadrícula y Alt+Re Pág/Av Pág cambia más deprisa. Alt+Inicio/Fin fija los extremos; Alt+izquierda/derecha ajusta el paso individual entre -10 y +10. Ctrl+E abre una edición numérica accesible; Intro confirma y Esc cancela. Ctrl+Retroceso restablece la cuadrícula a 10 y el paso a 0.
Explorador interno de FX: F10|F10 abre el explorador interno de efectos de pista, toma, Master o Monitor, según el contexto. Intro o F10 carga el efecto seleccionado. Ctrl+arriba/abajo cambia de efecto; Ctrl+Re Pág/Av Pág mueve físicamente el efecto en la cadena. Ctrl+B alterna bypass y Ctrl+Alt+B activa/desactiva el estado offline. Ctrl+P ya no abre el explorador. Ctrl+Mayús+F y Alt+Mayús+F abren ventanas nativas de REAPER.
Conector de pines de audio: F11|El Audio Pin Connector se encuentra en FX Params, no en Track Params. F11 abre la matriz de entradas y salidas del efecto. Izquierda/derecha cambia el pin, arriba/abajo cambia el canal, Intro o Espacio conecta o desconecta; Supr borra la conexión. Ctrl+flechas busca celdas conectadas y Tab/F11 anuncia la celda. Admite hasta 128 canales en dos bancos cuando el contexto lo permite. “Attive” indica conexión; una celda vacía no lleva el prefijo “Disconnected”. Esc vuelve a la vista anterior.
Órdenes, grupos y edición F7|Plugin conserva el orden real de parámetros. Custom puede reordenar, ocultar, duplicar o renombrar apariciones sin cambiar sus identificadores reales. Los grupos son independientes de Custom. F7 abre la edición estructural. Mayús+flechas selecciona; Ctrl+C/X/V copia, corta y pega los elementos permitidos; Ctrl+Z/Y deshace y rehace. Alt+Mayús+flechas recorre las celdas seleccionadas; Ctrl+Intro cambia nombres cuando la vista lo permite.
Comparación A/B y memorias|F8 alterna la comparación Original/Edited. Pulsar F8 dos veces rápidamente actualiza Original. F8 NO abre las memorias: Ctrl+Mayús+M abre FX Memories. Según el modo elegido, Ctrl+F1–F12 recupera una memoria y Ctrl+Mayús+F1–F12 guarda el estado. Ctrl+L alterna Plugin/Custom cuando está permitido.
MIDI CC y automatización|Ctrl+Alt+C inicia aprendizaje de CC fijo; Mayús+C habilita o deshabilita el mapa. Ctrl+Mayús+C administra el CC flotante con captura suave. Ctrl+T controla los anuncios de CC MIDI. Ctrl+Mayús+A activa o desactiva la envolvente real del parámetro y puede anunciar “Auto”. Ctrl+Mayús+Alt+A solicita confirmación antes de eliminar automatizaciones. Ctrl+Q devuelve el foco a REAPER manteniendo el MIDI compatible.
ReaEQ y otros efectos|Hay controles adaptados para ReaEQ, ReaComp y ReaGate, incluidos parámetros virtuales cuando existen. Alt+F1/F2 cambia preajustes del anfitrión y Alt+F3/F4 recorre parámetros automatizados. Ctrl+B activa bypass y Ctrl+D controla Delta Solo. Comprueba siempre las unidades anunciadas: un valor normalizado no necesariamente representa Hz o dB.
Búsqueda, portapapeles y restauración|Las letras y los números recorren nombres visibles; Mayús busca hacia atrás. Ctrl+F abre búsqueda y Ctrl+R revisa búsquedas recientes. Retroceso recupera el valor predeterminado del parámetro; Ctrl+Mayús+Retroceso ejecuta la restauración de Default guardado cuando está disponible. Los comandos de portapapeles en F7 modifican la disposición visual, no el orden real del plugin.
Reproducción y marcadores|Espacio inicia o detiene; Ctrl+Espacio alterna reproducción/pausa. Ctrl+I/O busca marcadores anteriores/siguientes y Ctrl+1–0 salta a los marcadores 1–10. Alt+F10/F11/F12 y Alt+Mayús+F10/F11/F12 controlan los dos Peak Watchers de OSARA. Las teclas no deben capturarse en campos de texto ordinarios.
Perfiles y migración Lua|Los perfiles FX se guardan como archivos .fx en LReaParams/Plugins. La DLL puede importar algunos perfiles TXT antiguos compatibles; no hace falta mantener los lanzadores Lua activos. La asignación de pines modifica REAPER mediante sus API pero no aumenta el número de canales de la pista. Esta guía cubre la versión 0.0.67 y no incluye Stretch Marker.
''',
 '''
Instalación y conceptos básicos|Instala la DLL en UserPlugins y la carpeta Guide dentro de LReaParams/Guide. Las acciones FX Params y Track Params son independientes; Ctrl+Tab cambia entre ellas cuando existe el contexto adecuado. OSARA pronuncia los mensajes; NVDA revisa los controles. Tab anuncia detalles; Esc sale de la edición o del navegador.
Páginas actuales F1–F7|F1 Pistas; F2 envíos (Sends); F3 recepciones (Receives); F4 controles FX visibles en TCP; F5 MIDI de pista; F6 salidas de hardware físicas; F7 ReaRoute. F8 queda libre en Track Params. El antiguo conector de pines de F5 se ha trasladado a FX Params con F11.
F1: pistas, carpetas y selección|Arriba/abajo cambia la pista y izquierda/derecha recorre Volumen, Pan, Anchura, Silencio, Solo, Fase y contadores de envíos, recepciones y FX. Intro edita o cambia un conmutador; en los contadores abre F2/F3/F4. Ctrl+Intro pliega o despliega carpetas y Ctrl+Alt+arriba/abajo cambia de carpeta. Mayús+Espacio selecciona una pista; Ctrl+A selecciona las visibles y Ctrl+C/X/V copia, corta y pega pistas.
F2 y F3: envíos y recepciones|Estas páginas muestran las conexiones y sus ajustes de volumen, panorámica y canales. Usa las flechas para navegar y Alt+arriba/abajo para editar. Desde F1, Ctrl+Mayús+S crea envíos en dos pasos: selecciona primero las pistas de origen y después las de destino. Ctrl+Mayús+R prepara las recepciones en el orden inverso. Esc cancela una preparación pendiente.
F4: parámetros FX del TCP|F4 muestra únicamente los controles de FX expuestos en el panel de pista. Ctrl+arriba/abajo cambia el efecto; Ctrl+Mayús+arriba/abajo cambia pistas con FX; Ctrl+Re Pág/Av Pág reordena el efecto. Intro cambia al modo Valor, Alt+arriba/abajo ajusta y Ctrl+E introduce números. Alt+Intro abre una lista accesible de nombres, aunque no haya controles TCP. Intro agrega el seleccionado y Ctrl+Intro lo agrega o quita sin cerrar la lista. Supr quita el control TCP, no el efecto.
F5: MIDI de pista|F5 incluye salida MIDI hardware, canal de salida, mapa de entrada, canal de control y enrutamiento MIDI. Arriba/abajo selecciona el campo; Alt+arriba/abajo cambia sus opciones; Alt+Re Pág/Av Pág acelera el cambio. Tab o F5 anuncia los detalles. No es necesario que haya efectos en F4.
F6: salidas de audio hardware|F6 mantiene una columna “Add hardware output” incluso cuando la pista no tiene salidas. Selecciona una salida física con Alt+arriba/abajo y pulsa Intro para crearla sin abrir el menú de REAPER. Las salidas existentes permiten cambiar volumen, pan, silencio, fase, mono, canales de origen y destino. Izquierda/derecha recorre las salidas y arriba/abajo sus campos. ReaRoute se gestiona por separado en F7.
F7: puente ReaRoute|F7 presenta una columna de entrada, otra para agregar salidas y las salidas virtuales existentes. Las flechas recorren los campos; Alt+flechas cambia valores; Intro crea o activa según el campo, y Supr elimina solamente una salida ReaRoute. La función no instala el controlador ReaRoute; depende de su disponibilidad en REAPER.
Valores, memoria y edición|Intro entra o sale del modo Valor según el campo; Alt+arriba/abajo cambia el valor; Alt+Re Pág/Av Pág ajusta más deprisa y Alt+izquierda/derecha cambia el paso entre -10 y +10. Ctrl+E abre un campo numérico estándar. Ctrl+Mayús+M abre Track Memories, no F8. Ctrl+F1–F12 recupera memorias y Ctrl+Mayús+F1–F12 las guarda donde está admitido.
MIDI CC y automatización|Ctrl+Alt+C aprende un CC fijo; Mayús+C activa/desactiva su mapa y Ctrl+Mayús+C controla el CC flotante. Ctrl+T regula la voz para cambios MIDI; Ctrl+Mayús+T regula los cambios normales. Ctrl+Mayús+A activa envolventes reales admitidas y Ctrl+Mayús+Alt+A solicita confirmación para borrar automatizaciones. Los CC fijos se identifican por la pista y el objeto real, no por su posición en la pantalla.
Filtros, transporte y almacenamiento|Ctrl+F busca pistas, rutas y nombres TCP; las letras recorren elementos visibles. Espacio y Ctrl+Espacio controlan el transporte; Ctrl+I/O recorre marcadores. Los perfiles de pista se guardan como .tp por proyecto en LReaParams/Tracks; los de efectos como .fx en Plugins. La DLL importa TXT Lua compatibles, pero no requiere lanzar los Lua antiguos. Esta guía no incluye Stretch Marker.
''',
 '''
Reduce/aumenta las columnas
Información de cuadrícula y paso / revisión completa / breve
Entra o sale de Valor; vuelve atrás
Ajuste fino del valor
Ajuste de valor con paso mayor
Cambia el paso individual del parámetro
Abre edición numérica accesible
Efecto anterior/siguiente de la cadena
Pista anterior/siguiente con efectos
Mueve el FX dentro de la cadena
Busca parámetros
Edición estructural de Custom y grupos
Compara Original/Edited; no abre memorias
Explorador interno de efectos
Conector de pines de audio hasta 128 canales
Abre FX Memories
Aprende un MIDI CC fijo
Activa/desactiva el mapa CC fijo
Activa el CC flotante
Activa/desactiva la automatización
Confirmación para borrar automatizaciones
Devuelve el foco a REAPER manteniendo MIDI compatible
Reproducir/detener / reproducir/pausa
Marcador anterior/siguiente
''',
 '''
Cuadrícula de pistas
Envíos / recepciones
Parámetros FX visibles en TCP
Selector para añadir controles TCP
Ajustes MIDI de pista
Salidas de audio hardware, con Añadir
Entradas y salidas virtuales ReaRoute
Página no asignada
Edita un valor o vuelve atrás
Cambia el valor actual
Cambio de valor más rápido
Valor mínimo/máximo
Introducción numérica accesible
Busca o filtra elementos visibles
Alterna FX Params y Track Params
Abre Track Memories
Aprende CC fijo
Activa/desactiva mapa fijo
Control CC flotante
Activa/desactiva la automatización admitida
Confirmación para borrar las automatizaciones
Vuelve a REAPER manteniendo MIDI compatible
Reproducir/detener / reproducir/pausa
Marcador anterior/siguiente
''')
locale('fr', (
 'Guide LReaParams','Choisir une langue','Choisir un guide','FX Params','Track Params',
 'Sommaire','Raccourci','Fonction','Changer de langue','Référence complète en anglais',
 'Extension native REAPER 0.0.67. Guides accessibles avec NVDA et OSARA.', 'Retour au choix de langue'),
 '''
Installation et accessibilité|Placez reaper_lreaparams.dll dans le dossier UserPlugins de REAPER, puis copiez l’intégralité du dossier Guide dans LReaParams/Guide sous le répertoire des ressources. Redémarrez REAPER et attribuez des raccourcis aux actions LReaParams: FX Params, Track Params et Open User Guide. Les anciens lanceurs Lua ne sont plus nécessaires. OSARA annonce les changements ; NVDA lit la fenêtre de navigation. Tab fournit une description complète et NVDA+flèche haut permet de relire le contrôle.
Navigation et réglage des valeurs|Les flèches parcourent la grille. F1/F2 modifient le nombre de colonnes ; F3 annonce la grille et le pas. Entrée alterne entre Grille et Valeur. Alt+haut/bas règle la valeur depuis la grille ; Alt+Page précédente/suivante effectue de plus grands changements. Alt+Début/Fin atteint les limites ; Alt+gauche/droite modifie le pas du paramètre entre -10 et +10. Ctrl+E ouvre un champ numérique accessible, validé par Entrée ou annulé par Échap. Ctrl+Retour arrière rétablit Grille 10 et Pas 0.
Navigateur d’effets interne : F10|F10 ouvre la liste interne des FX de piste, prise, Master ou Monitoring selon le contexte. Entrée ou F10 ouvre l’effet sélectionné. Ctrl+haut/bas passe d’un FX à l’autre, Ctrl+Page précédente/suivante déplace réellement l’effet dans sa chaîne. Ctrl+B bascule le bypass, Ctrl+Alt+B le statut hors ligne. Ctrl+P n’ouvre plus ce navigateur. Ctrl+Maj+F et Alt+Maj+F ouvrent les fenêtres REAPER natives.
Connecteur de broches audio : F11|Le connecteur audio est maintenant dans FX Params, et non dans Track Params. F11 ouvre la matrice des entrées et sorties de l’effet. Gauche/droite change de broche, haut/bas change de canal, Entrée ou Espace connecte/déconnecte et Suppr retire une connexion. Ctrl+flèches recherche des cellules connectées ; Tab ou F11 relit la cellule. Jusqu’à 128 canaux sont accessibles par deux banques lorsque le contexte le permet. « Attive » signifie connecté ; une cellule vide n’annonce pas « Disconnected ». Échap revient à l’écran précédent.
Ordres, groupes et édition F7|L’ordre Plugin correspond aux paramètres réels. L’ordre Custom peut réorganiser, masquer, dupliquer et renommer des occurrences sans modifier leurs identifiants réels. Les groupes restent indépendants de Custom. F7 ouvre l’édition structurelle. Maj+flèches sélectionne ; Ctrl+C/X/V copie, coupe et colle les occurrences autorisées ; Ctrl+Z/Y annule et rétablit. Alt+Maj+flèches parcourt les cellules sélectionnées. Ctrl+Entrée renomme selon le contexte.
Comparaison A/B et mémoires|F8 compare Original et Edited ; deux pressions rapides sur F8 actualisent Original. F8 ne gère PAS les mémoires. Ctrl+Maj+M ouvre FX Memories. Selon le mode choisi, Ctrl+F1–F12 rappelle un emplacement et Ctrl+Maj+F1–F12 enregistre son état. Ctrl+L alterne Plugin/Custom lorsque cela est permis.
MIDI CC et automation|Ctrl+Alt+C lance l’apprentissage d’un CC MIDI fixe ; Maj+C active/désactive sa correspondance. Ctrl+Maj+C active le CC flottant avec reprise progressive. Ctrl+T contrôle les annonces MIDI. Ctrl+Maj+A active ou désactive l’enveloppe réelle du paramètre, avec éventuellement l’annonce « Auto ». Ctrl+Maj+Alt+A demande confirmation avant toute suppression des automations. Ctrl+Q rend la main à REAPER tout en conservant le contrôle MIDI compatible.
ReaEQ et autres effets|Des adaptations existent pour ReaEQ, ReaComp et ReaGate, y compris leurs paramètres virtuels pris en charge. Alt+F1/F2 change les presets de l’hôte ; Alt+F3/F4 parcourt les paramètres automatisés. Ctrl+B gère le bypass et Ctrl+D le Delta Solo. Vérifiez l’unité annoncée : une valeur normalisée n’est pas forcément exprimée en Hz ou en dB.
Recherche, presse-papiers et défauts|Les lettres, chiffres et signes parcourent les noms visibles ; Maj inverse le sens. Ctrl+F recherche et Ctrl+R rappelle les recherches récentes. Retour arrière restaure le paramètre ; Ctrl+Maj+Retour arrière restaure les valeurs Default sauvegardées si possible. Les opérations du presse-papiers en F7 portent sur les occurrences visuelles, pas sur l’ordre réel du plugin.
Lecture, marqueurs et niveaux|Espace démarre/arrête ; Ctrl+Espace alterne lecture/pause. Ctrl+I/O parcourt les marqueurs et Ctrl+1–0 saute aux marqueurs 1–10. Alt+F10/F11/F12 et Alt+Maj+F10/F11/F12 commandent les deux Peak Watchers d’OSARA. Les raccourcis ne doivent pas perturber les champs de texte natifs.
Profils et migration Lua|Les profils FX résident dans LReaParams/Plugins sous forme .fx. La DLL sait importer certaines anciennes données TXT compatibles, sans exécuter les lanceurs Lua. Les broches sont modifiées par les API de REAPER mais le nombre de canaux de la piste n’augmente pas automatiquement. Ce guide couvre 0.0.67 ; le script Stretch Marker est exclu.
''',
 '''
Installation et principes|Installez la DLL dans UserPlugins et le dossier Guide sous LReaParams/Guide. FX Params et Track Params sont deux actions distinctes ; Ctrl+Tab passe de l’une à l’autre lorsque c’est possible. OSARA prononce les états, NVDA relit les contrôles, Tab donne les détails et Échap ferme l’édition ou la navigation.
Pages actuelles F1–F7|F1 Pistes ; F2 Sends (envois) ; F3 Receives (retours) ; F4 contrôles FX présents dans le TCP ; F5 MIDI de piste ; F6 sorties audio matérielles ; F7 ReaRoute. F8 est libre dans Track Params. L’ancien connecteur F5 a été déplacé dans FX Params sous F11.
F1 : pistes et dossiers|Haut/bas change de piste ; gauche/droite parcourt Volume, Pan, Width, Mute, Solo, Phase et les compteurs Send/Receive/FX. Entrée édite ou commute un état ; sur un compteur, elle ouvre F2/F3/F4. Ctrl+Entrée ouvre/ferme un dossier, Ctrl+Alt+haut/bas parcourt les dossiers. Maj+Espace sélectionne une piste ; Ctrl+A sélectionne les pistes visibles ; Ctrl+C/X/V copie, coupe et colle les pistes.
F2 et F3 : envois et retours|Les pages F2/F3 présentent les connexions, les niveaux, le panoramique et les canaux. Les flèches naviguent ; Alt+haut/bas modifie une valeur. Depuis F1, Ctrl+Maj+S crée des sends en deux étapes : sélectionnez d’abord les sources, puis les destinations. Ctrl+Maj+R effectue l’opération inverse pour les receives. Échap annule une opération en attente.
F4 : paramètres FX du TCP|F4 contient uniquement les paramètres FX affichés dans le panneau de piste. Ctrl+haut/bas change d’effet, Ctrl+Maj+haut/bas change de piste avec FX, Ctrl+Page précédente/suivante déplace l’effet dans la chaîne. Entrée passe en mode Valeur ; Alt+haut/bas règle ; Ctrl+E saisit un nombre. Alt+Entrée ouvre une liste des noms même si le TCP est vide. Entrée ajoute le paramètre ; Ctrl+Entrée ajoute ou retire sans quitter la liste. Suppr retire uniquement le contrôle du TCP.
F5 : MIDI de piste|F5 présente la sortie MIDI matérielle, son canal, la correspondance des entrées, le canal de contrôle et le routage MIDI. Haut/bas choisit la rubrique ; Alt+haut/bas change l’option ; Alt+Page précédente/suivante accélère. Tab ou F5 donne le contexte complet. Aucun FX n’est requis dans F4.
F6 : sorties audio matérielles|F6 affiche « Add hardware output » même sur une piste sans sortie. Dans cette colonne, choisissez une destination physique avec Alt+haut/bas et appuyez sur Entrée pour créer la sortie, sans menu natif de REAPER. Les colonnes existantes offrent Volume, Pan, Mute, Phase, Mono, source et destination. Gauche/droite change de sortie, haut/bas change de réglage. ReaRoute reste réservé à F7.
F7 : interface ReaRoute|F7 distingue l’entrée ReaRoute, la colonne d’ajout et les sorties virtuelles existantes. Les flèches naviguent, Alt+flèches modifie, Entrée ajoute ou active selon le champ et Suppr retire uniquement une sortie ReaRoute. Cette page n’installe pas le pilote ReaRoute.
Valeurs et mémoires|Entrée bascule Grille/Valeur si disponible, Alt+haut/bas ajuste, Alt+Page précédente/suivante accélère et Alt+gauche/droite modifie le pas de -10 à +10. Ctrl+E ouvre une zone numérique native. Ctrl+Maj+M ouvre Track Memories, et non F8. Ctrl+F1–F12 rappelle les mémoires ; Ctrl+Maj+F1–F12 les sauvegarde dans les contextes concernés.
CC MIDI et automation|Ctrl+Alt+C apprend un CC fixe, Maj+C active/désactive sa table et Ctrl+Maj+C gère le CC flottant. Ctrl+T règle la parole MIDI et Ctrl+Maj+T les changements de valeur ordinaires. Ctrl+Maj+A commande les véritables enveloppes disponibles ; Ctrl+Maj+Alt+A demande une confirmation avant de supprimer les automations. La correspondance fixe suit la piste ou la connexion réelle.
Filtres, transport et profils|Ctrl+F filtre les pistes, connexions ou noms TCP ; les lettres parcourent les éléments visibles. Espace et Ctrl+Espace commandent la lecture ; Ctrl+I/O parcourt les marqueurs. Les profils de piste .tp sont enregistrés par projet dans LReaParams/Tracks et les profils FX .fx dans Plugins. Les anciens lanceurs Lua ne sont plus nécessaires ; Stretch Marker est hors sujet.
''',
 '''
Diminue/augmente le nombre de colonnes
Informations grille/pas, contexte détaillé ou bref
Entre ou sort du mode Valeur, ou revient
Réglage fin du paramètre
Réglage avec de plus grands pas
Change le pas propre au paramètre
Ouvre un champ numérique accessible
FX précédent/suivant de la chaîne
Piste précédente/suivante avec FX
Déplace réellement le FX dans sa chaîne
Recherche des paramètres
Édition structurelle de Custom et Groupes
Compare Original/Edited, pas les mémoires
Navigateur interne des FX
Connecteur audio jusqu’à 128 canaux
Ouvre FX Memories
Apprend un CC MIDI fixe
Active/désactive la table CC fixe
Active le CC flottant
Active/désactive l’enveloppe du paramètre
Confirmation pour supprimer les automations
Retourne à REAPER en gardant le MIDI compatible
Lecture/arrêt ; lecture/pause
Marqueur précédent/suivant
''',
 '''
Grille des pistes
Envois / retours
Paramètres FX visibles dans le TCP
Sélecteur des contrôles TCP à ajouter
Réglages MIDI de piste
Sorties audio matérielles, avec ajout
Entrées et sorties virtuelles ReaRoute
Aucune page associée
Édite une valeur ou revient
Change la valeur du champ
Réglage plus rapide
Valeur minimale/maximale
Saisie numérique accessible
Recherche ou filtre les éléments
Bascule FX Params et Track Params
Ouvre Track Memories
Apprentissage d’un CC fixe
Active/désactive la table fixe
Active le CC flottant
Active/désactive l’automation prise en charge
Confirmation avant suppression des automations
Retour à REAPER en gardant le MIDI compatible
Lecture/arrêt ; lecture/pause
Marqueur précédent/suivant
''')
locale('ru', (
 'Руководство LReaParams','Выберите язык','Выберите руководство','FX Params','Track Params',
 'Содержание','Клавиши','Действие','Изменить язык','Полная справка на английском',
 'Нативное расширение REAPER 0.0.67. Доступные руководства для NVDA и OSARA.', 'Вернуться к выбору языка'),
 '''
Установка и доступность|Скопируйте reaper_lreaparams.dll в каталог UserPlugins ресурсов REAPER, а всю папку Guide — в LReaParams/Guide. Перезапустите REAPER и найдите в списке действий LReaParams: FX Params, Track Params и Open User Guide. Назначьте удобные горячие клавиши. Старые Lua-скрипты запуска больше не нужны. OSARA озвучивает сообщения, а NVDA читает элементы окна. Tab сообщает подробный контекст; NVDA+стрелка вверх повторяет текущий элемент.
Навигация и изменение значений|Стрелки перемещают курсор по таблице параметров. F1/F2 изменяют число столбцов; F3 сообщает настройки таблицы и шага. Enter переключает режимы Grid и Value. Alt+вверх/вниз меняет значение прямо в таблице, Alt+Page Up/Down — крупным шагом; Alt+Home/End устанавливает крайние значения. Alt+влево/вправо меняет индивидуальный шаг от -10 до +10. Ctrl+E открывает доступное числовое поле; Enter подтверждает, Esc отменяет. Ctrl+Backspace восстанавливает Grid 10 и Step 0.
Встроенный браузер эффектов: F10|F10 открывает внутренний список эффектов дорожки, тейка, мастера или мониторинга, в зависимости от текущего контекста. Enter либо F10 открывает выбранный эффект. Ctrl+вверх/вниз выбирает FX, Ctrl+Page Up/Down физически перемещает FX по цепочке. Ctrl+B переключает Bypass, Ctrl+Alt+B — Offline. Ctrl+P больше не открывает браузер. Ctrl+Shift+F и Alt+Shift+F открывают штатные окна REAPER.
Матрица аудиопинов: F11|Audio Pin Connector перенесён из Track Params в FX Params. F11 открывает матрицу входов и выходов выбранного FX. Влево/вправо выбирает пин, вверх/вниз — канал; Enter или пробел включает либо отключает связь, Delete удаляет её. Ctrl+стрелки ищут подключённые ячейки, Tab/F11 повторяет содержимое. Поддерживается до 128 каналов в двух банках, если они доступны. Слово «Attive» означает подключение; пустая ячейка читается без слова «Disconnected». Esc возвращает назад.
Порядок параметров, группы и F7|Представление Plugin отражает исходный порядок. Представление Custom позволяет перемещать, скрывать, дублировать и переименовывать отображаемые позиции, не меняя реальные номера параметров. Группы независимы от Custom. F7 открывает структурное редактирование: Shift+стрелки выделяют ячейки; Ctrl+C/X/V копируют, вырезают и вставляют допустимые позиции; Ctrl+Z/Y отменяют и повторяют изменения. Alt+Shift+стрелки перемещают курсор только по выделенным ячейкам.
Сравнение A/B и память|F8 сравнивает состояния Original и Edited; быстрое двойное F8 обновляет Original. F8 НЕ открывает менеджер памяти. Ctrl+Shift+M открывает FX Memories. Ctrl+F1–F12 вызывает сохранённые ячейки, Ctrl+Shift+F1–F12 сохраняет их в соответствующем режиме группы или памяти. Ctrl+L переключает Plugin/Custom, когда это разрешено.
MIDI CC и автоматизация|Ctrl+Alt+C запускает обучение постоянному MIDI CC, Shift+C включает/выключает его карту, Ctrl+Shift+C управляет плавающим CC с мягким подхватом. Ctrl+T переключает речевые сообщения для MIDI CC. Ctrl+Shift+A включает и выключает реальную огибающую параметра; активная огибающая может озвучиваться как «Auto». Ctrl+Shift+Alt+A требует подтверждения перед удалением автоматизации. Ctrl+Q возвращает фокус в REAPER, сохраняя совместимое MIDI-управление.
ReaEQ и другие плагины|Предусмотрена специальная поддержка ReaEQ, ReaComp и ReaGate, включая виртуальные параметры, если они доступны. Alt+F1/F2 переключает пресеты хоста; Alt+F3/F4 переходит между автоматизированными параметрами. Ctrl+B управляет обходом, Ctrl+D — Delta Solo. Проверяйте озвученные единицы измерения: нормализованное значение не обязательно означает дБ или Гц.
Поиск, буфер обмена и сброс|Буквы, цифры и символы ищут по видимым именам по кругу; Shift меняет направление. Ctrl+F открывает поиск, Ctrl+R — историю. Backspace сбрасывает отдельный параметр, Ctrl+Shift+Backspace восстанавливает сохранённый Default, если он есть. В F7 копирование и вставка изменяют отображаемые позиции, а не исходный порядок параметров плагина.
Воспроизведение и маркеры|Пробел запускает/останавливает, Ctrl+пробел переключает воспроизведение/паузу. Ctrl+I/O переходит к предыдущему/следующему маркеру; Ctrl+1–0 выбирает маркеры 1–10. Alt+F10/F11/F12 и Alt+Shift+F10/F11/F12 управляют двумя измерителями OSARA Peak Watcher. В стандартных текстовых полях эти сочетания не должны перехватываться.
Профили и переход с Lua|Профили FX сохраняются в LReaParams/Plugins с расширением .fx. DLL умеет импортировать совместимые старые TXT, но запускать прежние Lua-навигаторы больше не нужно. Матрица аудиопинов использует API REAPER и сама по себе не увеличивает число каналов дорожки. Руководство описывает версию 0.0.67 и не относится к скрипту Stretch Marker.
''',
 '''
Установка и начало работы|Установите DLL в UserPlugins, а всю папку Guide — в LReaParams/Guide ресурсов REAPER. Для FX Params и Track Params существуют разные действия; Ctrl+Tab переключает их, если контекст позволяет. OSARA произносит сообщения, NVDA читает элементы, Tab выводит подробности, Esc выходит из редактирования или навигатора.
Текущие страницы F1–F7|F1 — дорожки; F2 — Sends (посылы); F3 — Receives (приёмы); F4 — FX-параметры панели TCP; F5 — MIDI дорожки; F6 — физические аппаратные аудиовыходы; F7 — ReaRoute. Страница F8 в Track Params не назначена. Бывший коннектор F5 перенесён в FX Params на F11.
F1: дорожки и папки|Вверх/вниз меняет дорожку, влево/вправо выбирает Volume, Pan, Width, Mute, Solo, Phase и счётчики Sends, Receives, FX. Enter изменяет значение или переключатель; на счётчиках открывает F2/F3/F4. Ctrl+Enter раскрывает/сворачивает папку, Ctrl+Alt+вверх/вниз ищет другие папки. Shift+пробел выделяет дорожку, Ctrl+A выбирает все видимые; Ctrl+C/X/V копирует, вырезает и вставляет дорожки.
F2 и F3: посылы и приёмы|Страницы показывают маршруты, уровни, панораму и каналы. Стрелки перемещают курсор, Alt+вверх/вниз изменяет настройки. На F1 сочетание Ctrl+Shift+S создаёт посылы в два шага: сначала выбираются источники, затем получатели. Ctrl+Shift+R выполняет противоположный порядок для приёмов. Esc отменяет незавершённое действие.
F4: параметры FX в TCP|F4 показывает только элементы управления FX, выставленные на панели дорожки. Ctrl+вверх/вниз меняет FX; Ctrl+Shift+вверх/вниз меняет дорожку с эффектами; Ctrl+Page Up/Down передвигает FX по цепочке. Enter входит в режим Value, Alt+вверх/вниз меняет значение, Ctrl+E открывает числовое поле. Alt+Enter открывает список имён для добавления параметров даже при пустой TCP. Enter добавляет параметр, Ctrl+Enter добавляет/удаляет без закрытия списка. Delete удаляет элемент с TCP, а не сам FX.
F5: MIDI дорожки|В F5 доступны аппаратный MIDI-выход, его канал, карта входных каналов, управляющий канал и маршрутизация MIDI. Вверх/вниз выбирает поле, Alt+вверх/вниз меняет вариант, Alt+Page Up/Down ускоряет изменение. Tab или F5 озвучивает подробности. Наличие FX в F4 не требуется.
F6: аппаратные аудиовыходы|На F6 колонка «Add hardware output» есть даже у дорожки без выходов. Выберите физическое устройство сочетанием Alt+вверх/вниз и нажмите Enter — выход будет создан без штатного меню REAPER. Для существующих выходов доступны уровень, панорама, Mute, фаза, Mono, источник и назначение. Влево/вправо меняет выход, вверх/вниз — настройку. Виртуальный ReaRoute вынесен в F7.
F7: виртуальная маршрутизация ReaRoute|F7 разделяет вход ReaRoute, добавление выходов и существующие виртуальные выходы. Стрелки перемещаются по ячейкам, Alt+стрелки меняют параметры, Enter создаёт либо переключает соответствующий элемент, Delete удаляет только выбранный выход ReaRoute. Наличие драйвера/моста зависит от REAPER: эта страница его не устанавливает.
Значения и память|Enter переключает режим Grid/Value в подходящих ячейках. Alt+вверх/вниз меняет значение, Alt+Page Up/Down — крупным шагом, Alt+влево/вправо — сохранённый шаг от -10 до +10. Ctrl+E открывает стандартное числовое поле. Ctrl+Shift+M запускает Track Memories, а не F8; Ctrl+F1–F12 вызывает слоты, Ctrl+Shift+F1–F12 сохраняет их там, где это предусмотрено.
MIDI CC и автоматизация|Ctrl+Alt+C обучает постоянный CC; Shift+C переключает карту; Ctrl+Shift+C включает плавающий CC. Ctrl+T переключает произнесение MIDI-изменений, Ctrl+Shift+T — обычных значений. Ctrl+Shift+A управляет доступными огибающими, Ctrl+Shift+Alt+A требует подтверждения перед удалением автоматизации. Постоянные CC привязаны к реальным дорожкам и маршрутам, а не только к позиции курсора.
Фильтры, транспорт и хранение|Ctrl+F фильтрует дорожки, маршруты и названия TCP; ввод буквы перемещает по видимым именам. Пробел и Ctrl+пробел управляют воспроизведением, Ctrl+I/O — маркерами. Проектные профили Track сохраняются как .tp в LReaParams/Tracks, профили FX — как .fx в Plugins. Совместимые данные старых Lua могут импортироваться; старые скрипты запуска не нужны. Stretch Marker не рассматривается.
''',
 '''
Уменьшить/увеличить число столбцов
Сведения о сетке и шаге / полный / краткий контекст
Режим Value / возврат назад
Точная настройка значения
Более крупный шаг изменения
Изменить индивидуальный шаг параметра
Открыть доступное числовое поле
Предыдущий/следующий FX в цепочке
Предыдущая/следующая дорожка с FX
Передвинуть FX по цепочке
Найти параметр
Структурное редактирование Custom и групп
Сравнить Original/Edited, без менеджера памяти
Встроенный браузер FX
Матрица аудиопинов до 128 каналов
Открыть FX Memories
Обучить постоянный MIDI CC
Включить/выключить постоянную карту CC
Управлять плавающим CC
Включить/выключить автоматизацию параметра
Подтверждение удаления автоматизации
Вернуться в REAPER, сохранив совместимый MIDI
Пуск/стоп; воспроизведение/пауза
Предыдущий/следующий маркер
''',
 '''
Таблица дорожек
Посылы / приёмы
FX-параметры, показанные в TCP
Выбрать параметр для добавления в TCP
Настройки MIDI дорожки
Аппаратные аудиовыходы и Добавить
Входы и выходы ReaRoute
Страница не назначена
Редактировать значение либо вернуться
Изменить текущее значение
Более крупный шаг
Минимум/максимум
Доступный числовой ввод
Поиск и фильтр видимых элементов
Переключить FX Params и Track Params
Открыть Track Memories
Обучение постоянному CC
Включить/выключить карту CC
Включить плавающий CC
Управлять доступной автоматизацией
Подтвердить удаление автоматизации
Вернуться в REAPER с MIDI-управлением
Пуск/стоп; воспроизведение/пауза
Предыдущий/следующий маркер
''')
locale('zh-CN', (
 'LReaParams 使用指南','选择语言','选择指南','FX Params','Track Params',
 '目录','快捷键','功能','切换语言','完整英文参考指南',
 'REAPER 0.0.67 原生扩展。支持 NVDA 和 OSARA 的无障碍指南。','返回语言选择'),
 '''
安装与无障碍支持|将 reaper_lreaparams.dll 放入 REAPER 资源目录的 UserPlugins 文件夹，并将完整的 Guide 文件夹复制到 LReaParams/Guide。重启 REAPER，在动作列表中查找 LReaParams: FX Params、Track Params 和 Open User Guide，并设置快捷键。不需要再运行旧版 Lua 启动脚本。OSARA 提供语音提示，NVDA 读取导航窗口及编辑控件。Tab 朗读完整上下文，NVDA+上箭头复读当前控件。
参数网格与数值编辑|使用方向键浏览参数网格。F1/F2 减少或增加网格列数，F3 朗读网格和步进信息。Enter 在网格与数值模式之间切换；数值模式中上下箭头改变数值。Alt+上/下可直接在网格中调整，Alt+Page Up/Down 大幅调整，Alt+Home/End 设置最大或最小值。Alt+左/右调整当前参数的步进级别（-10 至 +10）。Ctrl+E 打开可访问的数字输入框；Enter 确认，Esc 取消。Ctrl+Backspace 恢复 Grid 10 和 Step 0。
内置效果浏览器：F10|F10 打开当前轨道、Take、Master 或监听效果链中的内部浏览器。Enter 或 F10 打开所选效果的参数网格。Ctrl+上/下切换效果，Ctrl+Page Up/Down 实际移动效果在链中的位置。Ctrl+B 切换旁通，Ctrl+Alt+B 切换离线状态。Ctrl+P 不再用于打开浏览器。Ctrl+Shift+F 和 Alt+Shift+F 打开 REAPER 原生效果窗口。
音频引脚连接器：F11|Audio Pin Connector 已从 Track Params 移至 FX Params。F11 打开当前效果的音频输入/输出引脚矩阵。左/右移动到相邻引脚，上/下选择轨道声道；Enter 或空格连接/断开，Delete 移除连接。Ctrl+方向键搜索已连接单元格，Tab 或 F11 朗读当前单元格。环境允许时，通过两个引脚组支持最多 128 声道。“Attive” 表示已连接；空单元格不朗读“Disconnected”。Esc 返回原来的编辑位置。
参数顺序、分组与 F7|Plugin 视图保持插件参数的原始顺序；Custom 视图可以重新排列、隐藏、复制或重命名显示项目，而不改变实际参数编号。分组与 Custom 顺序相互独立。F7 进入结构编辑：Shift+方向键选择单元格，Ctrl+C/X/V 复制、剪切、粘贴允许的项目，Ctrl+Z/Y 撤销和重做；Alt+Shift+方向键仅在已选项目中移动。Ctrl+Enter 可在支持的位置执行重命名。
A/B 对比与记忆|F8 对比 Original 与 Edited；快速连按两次 F8 更新 Original。F8 不是记忆管理器！Ctrl+Shift+M 打开 FX Memories。根据当前组/记忆模式，Ctrl+F1–F12 读取保存槽位，Ctrl+Shift+F1–F12 保存槽位。允许时 Ctrl+L 可切换 Plugin 和 Custom 顺序。
MIDI CC 与自动化|Ctrl+Alt+C 学习固定 MIDI CC；Shift+C 开关固定映射；Ctrl+Shift+C 使用带软接管的浮动 CC。Ctrl+T 切换 MIDI CC 数值语音提示。Ctrl+Shift+A 开关参数真正的 REAPER 自动化包络；开启后可能朗读“Auto”。Ctrl+Shift+Alt+A 在删除自动化前要求确认。Ctrl+Q 将焦点返回 REAPER，同时保留兼容的实时 MIDI 控制。
ReaEQ 等效果的特殊支持|ReaEQ、ReaComp、ReaGate 具有专用支持，在适当情况下包括虚拟参数。Alt+F1/F2 切换主机预设；Alt+F3/F4 浏览已自动化的参数。Ctrl+B 切换旁通，Ctrl+D 控制 Delta Solo。请检查 NVDA 朗读的单位，标准化数值并不一定代表 Hz 或 dB。
搜索、剪贴板与恢复默认值|输入字母、数字或标点可循环查找当前可见的参数名称；按住 Shift 反向搜索。Ctrl+F 打开搜索，Ctrl+R 查看最近搜索。Backspace 恢复单个参数的默认值；Ctrl+Shift+Backspace 在可用时恢复已保存的 Default。F7 中的复制与粘贴修改显示项目，不会改变插件的真实参数顺序。
播放、标记与电平监测|空格控制播放/停止；Ctrl+空格控制播放/暂停。Ctrl+I/O 跳转前一个/下一个标记，Ctrl+1–0 跳转标记 1–10。Alt+F10/F11/F12 和 Alt+Shift+F10/F11/F12 操作 OSARA 的两个 Peak Watcher。普通文本输入框中不应拦截这些快捷键。
配置文件与 Lua 迁移|FX 配置以 .fx 文件保存在 LReaParams/Plugins。DLL 能导入部分兼容的旧 TXT 配置，但不需要同时运行旧 Lua 导航脚本。引脚修改通过 REAPER 原生 API 执行，不会自动增加轨道声道数。本指南对应 0.0.67，不包括独立的 Stretch Marker 脚本。
''',
 '''
安装与基本操作|将 DLL 安装到 UserPlugins，并将完整 Guide 文件夹放到 REAPER 资源路径中的 LReaParams/Guide。FX Params 与 Track Params 有各自的动作；条件允许时使用 Ctrl+Tab 切换。OSARA 提供语音，NVDA 读取控件；Tab 朗读详细信息，Esc 取消编辑或退出导航。
当前页面 F1–F7|F1 轨道；F2 Sends（发送）；F3 Receives（接收）；F4 轨道控制面板 TCP 中显示的 FX 参数；F5 轨道 MIDI；F6 物理硬件音频输出；F7 ReaRoute。Track Params 的 F8 没有分配页面。旧版 F5 音频引脚连接器已经移动到 FX Params 的 F11。
F1：轨道、文件夹与选择|上/下切换轨道，左/右切换音量、声像、宽度、静音、独奏、反相以及发送、接收、FX 数量字段。Enter 调整数值、切换开关，或从数量字段打开 F2/F3/F4。Ctrl+Enter 展开或折叠文件夹；Ctrl+Alt+上/下查找文件夹。Shift+空格选中轨道，Ctrl+A 选中可见轨道，Ctrl+C/X/V 复制、剪切、粘贴轨道。
F2 与 F3：发送和接收|这些页面显示轨道之间的音频路由，包括电平、声像和声道。方向键浏览，Alt+上/下调整。F1 中 Ctrl+Shift+S 以两步创建发送：先选源轨道，再选目标轨道。Ctrl+Shift+R 以相反顺序创建接收。Esc 可取消尚未完成的操作。
F4：TCP 中的 FX 参数|F4 只显示已添加到轨道控制面板 TCP 的效果参数。Ctrl+上/下切换 FX，Ctrl+Shift+上/下切换含 FX 的轨道，Ctrl+Page Up/Down 移动效果顺序。Enter 进入数值模式，Alt+上/下调节，Ctrl+E 输入数值。即使 TCP 没有参数，Alt+Enter 也可打开仅显示名称的参数选择列表。Enter 添加选中参数，Ctrl+Enter 添加或移除且保持列表打开。Delete 仅移除 TCP 控件，不会删除效果。
F5：轨道 MIDI 设置|F5 提供硬件 MIDI 输出、输出通道、输入通道映射、控制通道及 MIDI 路由。上/下选择字段，Alt+上/下改变选项，Alt+Page Up/Down 更快切换。Tab 或 F5 朗读当前配置。不要求 F4 中存在 FX。
F6：物理硬件音频输出|即使当前轨道完全没有硬件输出，F6 仍提供“Add hardware output”列。在该列使用 Alt+上/下选择物理设备目标，再按 Enter 直接创建输出，无须进入 REAPER 路由菜单。已有输出提供音量、声像、静音、相位、单声道、源与目标等设置。左/右切换输出，上/下切换字段。ReaRoute 不属于 F6，需使用 F7。
F7：ReaRoute 虚拟路由|F7 分别列出 ReaRoute 输入、添加输出与已有虚拟输出。方向键浏览，Alt+方向键调整，Enter 按字段功能添加或切换，Delete 仅删除所选 ReaRoute 输出。驱动或桥接程序必须已在系统中提供；此功能不会安装 ReaRoute。
数值调整与记忆|在支持的字段按 Enter 切换网格/数值模式；Alt+上/下改变数值，Alt+Page Up/Down 大幅变化，Alt+左/右改变 -10 至 +10 的步进。Ctrl+E 打开标准数字输入框。Ctrl+Shift+M 打开 Track Memories，而不是 F8。Ctrl+F1–F12 读取槽位，Ctrl+Shift+F1–F12 在支持的位置保存槽位。
MIDI CC 与自动化|Ctrl+Alt+C 学习固定 CC，Shift+C 开关固定映射，Ctrl+Shift+C 管理浮动 CC。Ctrl+T 控制 MIDI 语音，Ctrl+Shift+T 控制普通数值变化语音。Ctrl+Shift+A 控制支持的真实自动化包络；Ctrl+Shift+Alt+A 删除自动化前要求确认。固定 CC 绑定真实轨道、FX 或路由，而不是显示列表中的行号。
过滤、传输与配置文件|Ctrl+F 过滤轨道、路由或 TCP 参数，输入首字母可寻找可见名称。空格和 Ctrl+空格控制播放，Ctrl+I/O 浏览标记。轨道配置按项目保存为 LReaParams/Tracks 中的 .tp 文件；FX 配置保存在 Plugins 中的 .fx 文件。可导入兼容的旧 Lua TXT 数据，但不需要旧版 Lua 启动脚本。本指南不包含 Stretch Marker。
''',
 '''
减少/增加网格列数
网格与步进信息 / 完整说明 / 简短说明
进入/退出数值模式或返回
精细调整参数
以较大步幅调整数值
调整单个参数的步进等级
打开无障碍数字输入框
当前链中的上一个/下一个 FX
含 FX 的上一个/下一个轨道
在效果链中实际移动 FX
搜索参数
编辑 Custom 与分组的结构
对比 Original/Edited，而不是记忆管理
内部 FX 浏览器
最多支持 128 声道的音频引脚连接器
打开 FX Memories
学习固定 MIDI CC
开关固定 CC 映射
启用浮动 MIDI CC
开关参数自动化
删除自动化前确认
返回 REAPER 并保留兼容 MIDI 控制
播放/停止；播放/暂停
前一个/下一个标记
''',
 '''
轨道网格
发送 / 接收路由
TCP 中可见的 FX 参数
选择要添加到 TCP 的参数
轨道 MIDI 设置
硬件音频输出，包括添加操作
ReaRoute 虚拟输入和输出
未分配页面
修改数值或返回
调整字段数值
以较大步幅调整
最小值/最大值
无障碍数字输入
搜索或过滤可见项目
在 FX Params 与 Track Params 间切换
打开 Track Memories
学习固定 CC
开关固定 CC 映射
启用浮动 CC
开关受支持的自动化
删除自动化前确认
返回 REAPER，保留兼容 MIDI
播放/停止；播放/暂停
前一个/下一个标记
''')
locale('ja', (
 'LReaParams ユーザーガイド','言語を選択','ガイドを選択','FX Params','Track Params',
 '目次','ショートカット','機能','言語を変更','英語版の詳細リファレンス',
 'REAPER 用ネイティブ拡張 0.0.67。NVDA と OSARA に対応したアクセシブルなガイドです。','言語選択に戻る'),
 '''
インストールとアクセシビリティ|reaper_lreaparams.dll を REAPER リソースフォルダー内の UserPlugins に配置し、Guide フォルダー全体を LReaParams/Guide にコピーしてください。REAPER を再起動し、アクション一覧から LReaParams: FX Params、Track Params、Open User Guide を見つけてキーを割り当てます。従来の Lua 起動スクリプトは不要です。OSARA が操作を読み上げ、NVDA はナビゲーション画面を読み取れます。Tab で詳細を確認し、NVDA+上矢印で現在の項目を再確認できます。
パラメーターの移動と編集|矢印キーでパラメーターのグリッドを移動します。F1/F2 は列数の減少・増加、F3 はグリッドとステップの確認です。Enter で Grid と Value モードを切り替えます。Alt+上/下でグリッドから値を変更し、Alt+Page Up/Down で大きく変更します。Alt+Home/End は最小・最大値、Alt+左/右は個別のステップを -10 ～ +10 で調整します。Ctrl+E はアクセシブルな数値入力欄です。Enter で確定、Esc でキャンセル。Ctrl+Backspace で Grid 10 と Step 0 に戻します。
内蔵 FX ブラウザー：F10|F10 はトラック、テイク、マスター、モニターの各 FX チェーンを状況に応じて表示します。Enter または F10 で選択中の FX のグリッドを開きます。Ctrl+上/下は FX の切り替え、Ctrl+Page Up/Down はチェーン内の FX の実際の移動です。Ctrl+B はバイパス、Ctrl+Alt+B はオフライン切り替え。Ctrl+P ではブラウザーを開けません。Ctrl+Shift+F と Alt+Shift+F は REAPER 標準のウィンドウを開きます。
オーディオピン接続：F11|Audio Pin Connector は Track Params から FX Params に移動しました。F11 で選択 FX の入出力ピンのマトリックスを開きます。左/右でピン、上/下でトラックチャンネルを移動し、Enter またはスペースで接続・解除、Delete で接続を削除します。Ctrl+矢印で接続済みセルを検索し、Tab または F11 でセルの内容を読み上げます。対応環境では 2 つのピンバンクで最大 128 チャンネルを扱えます。「Attive」は接続済みを示し、未接続セルでは「Disconnected」と読みません。Esc で元の画面に戻ります。
表示順・グループ・F7|Plugin 表示は実際のパラメーター順です。Custom 表示は実際の番号を変更せず、表示項目の並べ替え、非表示、複製、名前変更ができます。グループは Custom の順序とは独立しています。F7 で構造編集を開き、Shift+矢印で選択、Ctrl+C/X/V で許可された項目をコピー・切り取り・貼り付けます。Ctrl+Z/Y は元に戻す・やり直し。Alt+Shift+矢印で選択済みのセルのみを移動できます。
A/B 比較とメモリー|F8 は Original と Edited を比較します。F8 をすばやく 2 回押すと Original が更新されます。F8 はメモリーマネージャーではありません。Ctrl+Shift+M で FX Memories を開きます。モードに応じて Ctrl+F1～F12 で呼び出し、Ctrl+Shift+F1～F12 で保存します。可能な場合は Ctrl+L で Plugin/Custom を切り替えます。
MIDI CC とオートメーション|Ctrl+Alt+C は固定 MIDI CC の学習、Shift+C は固定マップのオン・オフ、Ctrl+Shift+C はソフトテイクオーバー対応のフローティング CC を扱います。Ctrl+T は MIDI CC の読み上げ切り替え。Ctrl+Shift+A は実際のパラメーターエンベロープを切り替え、有効な場合は「Auto」と通知されることがあります。Ctrl+Shift+Alt+A はオートメーション削除前に確認を求めます。Ctrl+Q で MIDI 操作を保持したまま REAPER に戻ります。
ReaEQ とその他の FX|ReaEQ、ReaComp、ReaGate には専用処理があり、対応する仮想パラメーターも扱えます。Alt+F1/F2 はホストプリセット、Alt+F3/F4 はオートメーション付きパラメーターの切り替え。Ctrl+B はバイパス、Ctrl+D は Delta Solo です。正規化された値は必ずしも dB や Hz ではないため、NVDA が読み上げる単位を確認してください。
検索・クリップボード・初期値|文字、数字、記号を押すと表示中のパラメーター名を循環検索します。Shift を押すと逆方向。Ctrl+F は検索、Ctrl+R は履歴です。Backspace は現在のパラメーターの初期値を復元し、Ctrl+Shift+Backspace は利用可能な場合に保存済み Default を復元します。F7 でのコピーと貼り付けは表示項目を変更し、プラグイン本来のパラメーター番号は変更しません。
再生・マーカー・ピーク監視|スペースは再生/停止、Ctrl+スペースは再生/一時停止です。Ctrl+I/O は前後のマーカー、Ctrl+1～0 はマーカー 1～10 にジャンプします。Alt+F10/F11/F12 と Alt+Shift+F10/F11/F12 は OSARA の 2 系統の Peak Watcher を操作します。通常の文字入力欄ではこれらのキーを奪いません。
プロファイルと Lua からの移行|FX プロファイルは LReaParams/Plugins に .fx ファイルとして保存されます。DLL は互換性のある古い TXT データの一部を読み込めますが、旧 Lua ナビゲーターの起動は不要です。ピンの割り当ては REAPER の API を通じて行われ、トラックのチャンネル数は自動的には増えません。このガイドは 0.0.67 が対象です。Stretch Marker スクリプトは含みません。
''',
 '''
インストールと基本操作|DLL を UserPlugins に、Guide フォルダー全体を REAPER リソースフォルダー内の LReaParams/Guide に配置します。FX Params と Track Params は別々のアクションです。利用可能な状況では Ctrl+Tab で切り替えます。OSARA が音声を出力し、NVDA がコントロールを読み上げます。Tab は詳細確認、Esc は編集の取り消しや終了です。
現在のページ F1～F7|F1 トラック、F2 Sends（センド）、F3 Receives（レシーブ）、F4 TCP に表示された FX パラメーター、F5 トラック MIDI、F6 物理ハードウェア音声出力、F7 ReaRoute です。Track Params の F8 は未使用です。旧 F5 の Pin Connector は FX Params の F11 に移動しました。
F1：トラックとフォルダー|上/下はトラック、左/右は Volume、Pan、Width、Mute、Solo、Phase、Send/Receive/FX 数のフィールドを移動します。Enter は値の変更や切り替えを行い、数のフィールドからは F2/F3/F4 に移動できます。Ctrl+Enter はフォルダーの開閉、Ctrl+Alt+上/下は別のフォルダーへの移動です。Shift+スペースでトラック選択、Ctrl+A ですべての表示トラックを選択。Ctrl+C/X/V はトラックのコピー・切り取り・貼り付けです。
F2 と F3：センドとレシーブ|これらのページには接続とその音量、パン、チャンネル設定が表示されます。矢印で移動し、Alt+上/下で調整できます。F1 で Ctrl+Shift+S を押すと、最初に送信元トラック、次に送信先トラックを選ぶ 2 段階のセンド作成が始まります。Ctrl+Shift+R はレシーブの逆順操作です。Esc は保留中の作成を取り消します。
F4：TCP の FX パラメーター|F4 はトラックコントロールパネル TCP に表示されている FX のパラメーターだけを扱います。Ctrl+上/下で FX を切り替え、Ctrl+Shift+上/下で FX のあるトラックを切り替え、Ctrl+Page Up/Down で FX を移動します。Enter は Value モード、Alt+上/下は値の変更、Ctrl+E は数値入力です。TCP にパラメーターがなくても Alt+Enter で名前だけの追加候補一覧を開けます。Enter で追加、Ctrl+Enter で一覧を閉じずに追加・削除。Delete は TCP 上の表示コントロールだけを削除します。
F5：トラック MIDI|F5 ではハードウェア MIDI 出力、出力チャンネル、入力チャンネルのマッピング、制御チャンネル、MIDI ルーティングを設定します。上/下は項目選択、Alt+上/下は値の変更、Alt+Page Up/Down は大きな変更です。Tab または F5 で詳細確認。F4 に FX がなくても利用できます。
F6：ハードウェア音声出力|トラックに出力が 1 つもなくても F6 には「Add hardware output」列があります。その列で Alt+上/下を使い物理出力先を選択し、Enter を押すと REAPER のルーティングメニューを開かずに作成できます。既存の出力では音量、パン、ミュート、位相、モノラル、入力元や出力先などを変更できます。左/右は出力の切り替え、上/下はフィールドの切り替え。ReaRoute は F7 で管理します。
F7：ReaRoute|F7 には ReaRoute 入力、出力追加、および既存の仮想出力を示す列があります。矢印で移動、Alt+矢印で編集、Enter で項目に応じて追加または切り替え、Delete で選択中の ReaRoute 出力だけを削除します。ReaRoute ドライバーのインストール機能ではありません。
数値編集とメモリー|対応するフィールドで Enter は Grid/Value を切り替えます。Alt+上/下は値の変更、Alt+Page Up/Down は大きな変更、Alt+左/右は -10 ～ +10 の個別ステップ変更。Ctrl+E は標準の数値入力欄です。Ctrl+Shift+M は Track Memories を開きます。F8 ではありません。Ctrl+F1～F12 は記憶の呼び出し、Ctrl+Shift+F1～F12 は対応する位置での保存です。
MIDI CC とオートメーション|Ctrl+Alt+C は固定 CC の学習、Shift+C は固定マップの切り替え、Ctrl+Shift+C はフローティング CC の操作です。Ctrl+T は MIDI の値の読み上げ、Ctrl+Shift+T は通常の値の読み上げを切り替えます。Ctrl+Shift+A は対応する本物のオートメーションを変更し、Ctrl+Shift+Alt+A はオートメーション削除前に確認します。固定 CC は実際のトラックや接続と関連付けられます。
フィルター・再生・保存|Ctrl+F はトラック、ルーティング、TCP 名のフィルターです。頭文字キーは表示されている名前を検索します。スペースと Ctrl+スペースで再生を制御し、Ctrl+I/O はマーカーを移動します。トラックごとのプロジェクト設定は LReaParams/Tracks の .tp ファイル、FX 設定は Plugins の .fx ファイルに保存されます。互換性のある旧 Lua TXT データを取り込めますが、旧ランチャーは不要です。Stretch Marker は対象外です。
''',
 '''
グリッド列数の減少・増加
グリッドとステップ情報／詳細／簡潔な説明
Value モードの切り替え／戻る
パラメーターを細かく調整
大きなステップで調整
個別のステップを変更
アクセシブルな数値入力を開く
チェーン内の前／次の FX
FX のある前／次のトラック
チェーン内で FX を実際に移動
パラメーターを検索
Custom とグループの構造編集
Original/Edited の比較（メモリーではない）
内蔵 FX ブラウザー
最大 128 チャンネルのオーディオピン接続
FX Memories を開く
固定 MIDI CC を学習
固定 CC マップをオン・オフ
フローティング CC を操作
パラメーターのオートメーションを切り替え
オートメーション削除の確認
対応する MIDI を保持して REAPER に戻る
再生／停止、再生／一時停止
前／次のマーカー
''',
 '''
トラック一覧
センド／レシーブ
TCP に表示された FX パラメーター
TCP に追加するパラメーターを選択
トラック MIDI 設定
ハードウェア音声出力と追加
ReaRoute 仮想入出力
割り当てなし
値の編集または戻る
現在の値を変更
大きなステップで変更
最小値／最大値
アクセシブルな数値入力
表示項目の検索とフィルター
FX Params と Track Params を切り替え
Track Memories を開く
固定 CC を学習
固定 CC マップを切り替え
フローティング CC を操作
対応するオートメーションを切り替え
オートメーション削除の確認
MIDI を保持して REAPER に戻る
再生／停止、再生／一時停止
前／次のマーカー
''')

STYLE = '''
:root{color-scheme:light dark}body{font:1.06rem/1.65 system-ui,'Segoe UI',sans-serif;max-width:72rem;margin:auto;padding:1.2rem}a:focus-visible{outline:3px solid orange;outline-offset:3px}nav{border:1px solid gray;border-radius:.4rem;padding:.6rem 1rem}nav ul{columns:2}nav li{break-inside:avoid;margin:.25rem 0}table{border-collapse:collapse;width:100%}td,th{border:1px solid gray;padding:.45rem;text-align:start;vertical-align:top}th{background:rgba(128,128,128,.15)}h2{margin-top:2rem;border-bottom:1px solid gray}code{word-break:break-word}.skip{position:absolute;left:-9999px}.skip:focus{position:static}footer{margin-top:3rem;border-top:1px solid gray;padding:1rem 0}@media(max-width:640px){nav ul{columns:1}}
'''

def html_page(tag,title,body):
    return ('<!doctype html>\n<html lang="'+escape(tag,quote=True)+'"><head><meta charset="utf-8">'
            '<meta name="viewport" content="width=device-width, initial-scale=1">'
            '<title>'+escape(title)+'</title><style>'+STYLE+'</style></head><body>'
            '<a class="skip" href="#main">'+escape(I18N[tag]['ui'][5])+'</a>'
            '<main id="main">'+body+'</main></body></html>\n')

def link(url, caption): return '<a href="'+escape(url,quote=True)+'">'+escape(caption)+'</a>'

def language_list(prefix):
    return '<ul>'+''.join('<li>'+link(prefix+(lang+'/index.html'), name)+'</li>' for lang,name in LANGS)+'</ul>'

def make_main_index():
    entries=language_list('')
    blurb='Choose a language, then open the FX Params or Track Params user guide. All links work with NVDA, Tab and Enter. / Scegli una lingua, poi la guida FX Params o Track Params.'
    # English is the default language: its full-length originals remain in Guide/.
    content='<h1>LReaParams 0.0.67 — User guide / Guida utente</h1><h2>Choose a language / Seleziona una lingua</h2><p>'+escape(blurb)+'</p><nav aria-label="Languages">'+entries+'</nav>'
    content+='<p>NVDA / OSARA · REAPER 0.0.67 · FX Params / Track Params.</p>'
    # Use explicit English: our canonical home page is bilingual by design.
    (ROOT/'index.html').write_text(html_page('en','LReaParams — Language selection',content),encoding='utf-8')

def english_index():
    path=ROOT/'en'
    path.mkdir(exist_ok=True)
    content='<h1>LReaParams — English user guides</h1><p>Complete English reference manuals.</p><ul>'
    content+='<li>'+link('../LReaParams%20-%20FX%20Params.html','FX Params — detailed reference')+'</li>'
    content+='<li>'+link('../LReaParams%20-%20Track%20Params.html','Track Params — detailed reference')+'</li></ul>'
    content+='<h2>Choose a language</h2>'+language_list('../')
    content+='<p>'+link('../index.html','Back to language selection')+'</p>'
    (path/'index.html').write_text(html_page('en','LReaParams — English guides',content),encoding='utf-8')

def localized_index(tag):
    ui=I18N[tag]['ui']
    content='<h1>'+escape(ui[0])+' — 0.0.67</h1><p>'+escape(ui[10])+'</p>'
    content+='<h2>'+escape(ui[2])+'</h2><nav aria-label="'+escape(ui[2],quote=True)+'"><ul>'
    content+='<li>'+link('fx.html',ui[3])+'</li><li>'+link('track.html',ui[4])+'</li></ul></nav>'
    content+='<h2>'+escape(ui[1])+'</h2>'+language_list('../')
    content+='<p>'+link('../index.html',ui[11])+'</p>'
    (ROOT/tag/'index.html').write_text(html_page(tag,ui[0],content),encoding='utf-8')

def localized_manual(tag,which):
    ui=I18N[tag]['ui']
    parts=I18N[tag][which]
    keyset=FX_KEYS if which=='fx' else TR_KEYS
    labels=I18N[tag]['fxkeys' if which=='fx' else 'trkeys']
    title=ui[3] if which=='fx' else ui[4]
    content='<header><p>'+link('index.html',ui[0])+' · '+link('../index.html',ui[8])+' · '+link('track.html' if which=='fx' else 'fx.html',ui[4] if which=='fx' else ui[3])+'</p></header>'
    content+='<h1>LReaParams — '+escape(title)+'</h1><p>'+escape(ui[10])+'</p>'
    content+='<nav aria-label="'+escape(ui[5],quote=True)+'"><h2>'+escape(ui[5])+'</h2><ol>'
    for i,(head,body) in enumerate(parts,1):
        content+='<li>'+link(f'#section-{i}',head)+'</li>'
    if which == 'fx': content+='<li>'+link('#fx-context-test61',FX_CONTEXT_UPDATES[tag][0])+'</li>'
    for i, (head,body) in enumerate(TEST62_UPDATES[tag][which], 1):
        content += '<li>'+link(f'#test62-{which}-{i}',head)+'</li>'
    if which == 'fx': content+='<li>'+link('#release-0-0-64-rx', FX_RX_064_LOCALIZED[tag][0])+'</li>'
    content+='<li>'+link('#shortcuts',ui[6])+'</li></ol></nav>'
    for i,(head,body) in enumerate(parts,1):
        content+=f'<section aria-labelledby="section-{i}"><h2 id="section-{i}">{i}. {escape(head)}</h2><p>{escape(body)}</p></section>'
    if which == 'fx':
        head, body = FX_CONTEXT_UPDATES[tag]
        content += '<section aria-labelledby="fx-context-test61"><h2 id="fx-context-test61">'+escape(head)+'</h2><p>'+escape(body)+'</p></section>'
    for i,(head,body) in enumerate(TEST62_UPDATES[tag][which],1):
        anchor=f'test62-{which}-{i}'
        content+='<section aria-labelledby="'+anchor+'"><h2 id="'+anchor+'">'+escape(head)+'</h2><p>'+escape(body)+'</p></section>'
    if which == 'fx':
        rx_title, rx_body = FX_RX_064_LOCALIZED[tag]
        content+='<section aria-labelledby="release-0-0-64-rx"><h2 id="release-0-0-64-rx">'+escape(rx_title)+'</h2><p>'+escape(rx_body)+'</p></section>'
    content+='<section aria-labelledby="shortcuts"><h2 id="shortcuts">'+escape(ui[6])+'</h2>'
    content+='<table><thead><tr><th scope="col">'+escape(ui[6])+'</th><th scope="col">'+escape(ui[7])+'</th></tr></thead><tbody>'
    for key,desc in zip(keyset,labels):
        content+='<tr><th scope="row">'+escape(key)+'</th><td>'+escape(desc)+'</td></tr>'
    content+='</tbody></table></section><footer><p>'+link('../'+('LReaParams%20-%20FX%20Params.html' if which=='fx' else 'LReaParams%20-%20Track%20Params.html'),ui[9])+'</p>'
    content+='<p>'+link('index.html',ui[0])+' · '+link('../index.html',ui[8])+'</p></footer>'
    (ROOT/tag/(which+'.html')).write_text(html_page(tag,'LReaParams — '+title,content),encoding='utf-8')




# TEST62.1–62.9.2: localized release notes generated with the manuals.
TEST62_UPDATES = {'it': {'fx': [('TEST62: ordini, gruppi, invisibilità e F7',
                'Plugin Order mostra sempre tutti i parametri nell’ordine nativo, anche quelli nascosti altrove. Custom Order e i 12 gruppi mantengono '
                'occorrenze e griglie indipendenti; si possono salvare anche gruppi vuoti. In F7 Ctrl+C copia anche in gruppi diversi; Ctrl+X sposta tra '
                'gruppi o riordina nello stesso ambiente, ma non taglia tra Custom e gruppi. Ctrl+Canc elimina soltanto le occorrenze selezionate dal gruppo '
                'corrente; Ctrl+Maiusc+Canc nasconde globalmente i parametri in Custom e nei gruppi, senza modificarne la presenza in Plugin Order. Recupera i '
                'nascosti dalla colonna Hidden Parameters di Ctrl+Maiusc+M. Canc semplice in F7 deseleziona. Da un gruppo Ctrl+L torna sempre a Custom Order, '
                'anche se F7 è aperto; un secondo Ctrl+L passa a Plugin Order.'),
               ('TEST62: modifica multipla, Step e memorie FX',
                'In F7 seleziona i parametri con Maiusc+Spazio, Ctrl+A o Maiusc+frecce. Alt+sinistra/destra imposta lo Step dei parametri selezionati; Alt+su/giù '
                'modifica tutti i valori usando lo Step individuale; Ctrl+E permette l’inserimento numerico multiplo solo tra parametri compatibili. Le sette '
                'colonne di FX Memories (Ctrl+Maiusc+M) comprendono Hidden Parameters, Copied Parameters con gruppo e posizione esatti e Parameter Steps. '
                'Alt+sinistra/destra cambia lo Step direttamente nella riga della memoria; Canc lo azzera. In entrambe le memorie Maiusc+Spazio seleziona una '
                'riga, Ctrl+A seleziona la colonna, Alt+Maiusc+su/giù salta tra le righe selezionate, Canc agisce sulla selezione corrente. Le operazioni '
                'Default pericolose mantengono la richiesta di conferma.'),
               ('TEST62: ricerca incrementale, FX Chain e importazione TXT',
                'Digita in rapida sequenza lettere, cifre o punteggiatura: entro un secondo si compone un prefisso, cercato anche all’inizio delle parole '
                'successive. Ripetere una lettera percorre le corrispondenze. Con Maiusc la ricerca avviene all’indietro, e Maiusc+numero usa la cifra del '
                'tasto fisico anche sulla tastiera italiana. La ricerca non modifica la selezione. Nella lista nativa FX Chain, Alt+P apre FX Params sull’FX '
                'evidenziato; P resta a REAPER. Per convertire uno o più vecchi TXT Lua usa LReaParams: Import selected legacy TXT files dall’Action List o '
                'dal menu Extensions; gli originali non vengono modificati e i conflitti non sovrascrivono i profili esistenti.')],
        'track': [('TEST62: selezione nelle memorie Track',
                   'Apri Track Memories con Ctrl+Maiusc+M. Maiusc+Spazio (Shift+Space) seleziona o deseleziona la riga corrente; Ctrl+A seleziona le righe della sola '
                   'colonna attiva. Le frecce non eliminano la selezione. Alt+Maiusc+freccia su/giù (Alt+Shift+Up/Down) passa tra le memorie selezionate nella stessa colonna; '
                   'Alt+Maiusc+sinistra/destra non cambia colonna. Canc agisce sulle righe selezionate oppure, se nessuna è selezionata, solo su quella '
                   'corrente. La selezione temporanea non viene salvata.'),
                  ('TEST62: ricerca Track e importazione TXT selettiva',
                   'Digitando caratteri entro un secondo, F1 cerca prefissi nei nomi delle tracce e F2/F3 cerca soltanto nei campi della colonna send/receive '
                   'attiva. Maiusc inverte la ricerca, anche con le cifre della riga numerica. Per importare uno o più vecchi file TXT Lua usa l’azione '
                   'LReaParams: Import selected legacy TXT files. Seleziona i TXT nella cartella Plugins o Tracks; i file originari non vengono cancellati e '
                   'un profilo Track con un vecchio GUID non viene collegato automaticamente al progetto corrente.')]},
 'es': {'fx': [('TEST62: órdenes, grupos, ocultación y F7',
                'Plugin Order muestra siempre todos los parámetros originales, incluso los ocultos en otras vistas. Custom Order y los 12 grupos conservan '
                'listas, duplicados y cuadrículas independientes, incluidos los grupos vacíos guardados. En F7, Ctrl+C copia entre grupos; Ctrl+X reordena o '
                'mueve entre grupos, pero no corta entre Custom y un grupo. Ctrl+Supr elimina solo las ocurrencias seleccionadas del grupo; Ctrl+Mayús+Supr '
                'oculta globalmente en Custom y todos los grupos, nunca en Plugin Order. Recupera los parámetros ocultos desde Hidden Parameters en '
                'Ctrl+Shift+M. Supr solo deselecciona en F7. Ctrl+L desde un grupo vuelve siempre a Custom Order, también dentro de F7.'),
               ('TEST62: edición múltiple, pasos y memorias FX',
                'En F7, Shift+Space, Ctrl+A y Shift+flechas seleccionan parámetros. Alt+izquierda/derecha cambia los Steps seleccionados; Alt+arriba/abajo '
                'cambia sus valores con el Step individual. Ctrl+E permite valores exactos múltiples únicamente para controles compatibles. Las siete columnas '
                'de FX Memories incluyen Hidden Parameters, Copied Parameters (grupo y posición exacta) y Parameter Steps. Alt+izquierda/derecha edita un Step '
                'de memoria y Supr lo restablece. En las memorias FX y Track: Shift+Space selecciona, Ctrl+A selecciona la columna, Alt+Shift+Up/Down recorre '
                'lo seleccionado y Supr opera sobre la selección. Los Defaults peligrosos siguen requiriendo confirmación.'),
               ('TEST62: búsqueda incremental, Alt+P e importación TXT',
                'Teclea letras, dígitos o signos en menos de un segundo para formar un prefijo, incluso al inicio de otras palabras del nombre. Repetir una '
                'letra recorre coincidencias; con Shift se busca hacia atrás y Shift+dígito usa la tecla numérica física. La selección no cambia. Solo en la '
                'lista nativa FX Chain, Alt+P abre FX Params sobre el efecto seleccionado; P conserva su función de búsqueda en REAPER. La acción LReaParams: '
                'Import selected legacy TXT files convierte uno o varios archivos Lua antiguos sin borrar originales ni sobrescribir perfiles existentes en '
                'caso de conflicto.')],
        'track': [('TEST62: selección de memorias Track',
                   'Abre Track Memories con Ctrl+Shift+M. Shift+Space selecciona la fila; Ctrl+A selecciona solo la columna actual; las flechas mantienen la '
                   'selección. Alt+Shift+Up/Down salta entre filas seleccionadas de la misma columna; Alt+Shift+izquierda/derecha no cambia columna. Supr '
                   'actúa sobre las filas seleccionadas, o solo sobre la fila actual si no hay selección. La selección temporal no se almacena.'),
                  ('TEST62: búsqueda e importación TXT en Track',
                   'Las pulsaciones consecutivas en menos de un segundo buscan por prefijo: F1 entre nombres de pistas y F2/F3 únicamente en campos de la '
                   'columna send/receive actual. Shift invierte la dirección también con números físicos. LReaParams: Import selected legacy TXT files permite '
                   'escoger varios TXT antiguos en Plugins o Tracks; conserva los originales y los GUID de Track históricos no se asocian automáticamente al '
                   'proyecto actual.')]},
 'fr': {'fx': [('TEST62 : ordres, groupes, masquage et F7',
                'Plugin Order affiche toujours tous les paramètres natifs, même ceux masqués dans les autres vues. Custom Order et les 12 groupes possèdent '
                'leurs propres occurrences et grilles; les groupes vides enregistrés sont conservés. Dans F7, Ctrl+C copie entre groupes; Ctrl+X réordonne ou '
                'déplace entre groupes, mais pas entre Custom et un groupe. Ctrl+Suppr retire uniquement les occurrences choisies du groupe; Ctrl+Maj+Suppr '
                'masque globalement dans Custom et tous les groupes, jamais dans Plugin Order. Restaurez-les avec Hidden Parameters dans Ctrl+Shift+M. Suppr '
                'simple désélectionne dans F7. Depuis un groupe, Ctrl+L revient toujours à Custom Order, même dans F7.'),
               ('TEST62 : édition multiple, Steps et mémoires FX',
                'Dans F7, Shift+Space, Ctrl+A et Shift+flèches sélectionnent plusieurs paramètres. Alt+gauche/droite modifie leur Step, Alt+haut/bas applique '
                'la valeur selon le Step individuel et Ctrl+E permet une saisie groupée seulement pour des paramètres compatibles. Les sept colonnes de FX '
                'Memories incluent Hidden Parameters, Copied Parameters avec groupe/position exacte et Parameter Steps. Alt+gauche/droite change un Step '
                'mémorisé; Suppr le réinitialise. Dans les mémoires FX et Track, Shift+Space sélectionne, Ctrl+A sélectionne la colonne, Alt+Shift+Up/Down '
                'parcourt les lignes sélectionnées et Suppr les traite. Les opérations dangereuses sur Default demandent toujours confirmation.'),
               ('TEST62 : recherche progressive, Alt+P et import TXT',
                'Tapez lettres, chiffres ou ponctuation à moins d’une seconde d’intervalle pour rechercher un préfixe, y compris au début des mots suivants du '
                'nom. Répéter une lettre parcourt les résultats; Shift inverse la direction, y compris pour les chiffres de la rangée physique. La sélection '
                'reste intacte. Dans la liste FX Chain native uniquement, Alt+P ouvre FX Params sur l’effet sélectionné et P reste à REAPER. L’action '
                'LReaParams: Import selected legacy TXT files convertit un ou plusieurs anciens TXT Lua sans modifier les originaux ni écraser les profils '
                'existants en cas de conflit.')],
        'track': [('TEST62 : sélection dans Track Memories',
                   'Ouvrez Track Memories avec Ctrl+Shift+M. Shift+Space sélectionne la ligne, Ctrl+A sélectionne seulement la colonne active et les flèches '
                   'conservent la sélection. Alt+Shift+Up/Down parcourt les lignes sélectionnées dans la même colonne; Alt+Shift+gauche/droite ne change pas '
                   'de colonne. Suppr agit sur les lignes sélectionnées, ou sur la ligne courante s’il n’y a pas de sélection. Ces sélections temporaires ne '
                   'sont pas mémorisées.'),
                  ('TEST62 : recherche Track et import TXT',
                   'Les caractères tapés en moins d’une seconde forment un préfixe : F1 cherche parmi les noms de pistes et F2/F3 uniquement dans les champs '
                   'de la colonne send/receive active. Shift inverse la direction, même avec les touches numériques physiques. L’action LReaParams: Import '
                   'selected legacy TXT files permet de choisir plusieurs TXT anciens dans Plugins ou Tracks; les fichiers restent intacts et les anciens GUID '
                   'Track ne sont pas reliés automatiquement au projet actuel.')]},
 'ru': {'fx': [('TEST62: порядок, группы, скрытие и F7',
                'Plugin Order всегда показывает все исходные параметры, включая скрытые в других представлениях. Custom Order и 12 групп имеют отдельные '
                'списки, копии и сетки; сохранённые пустые группы остаются доступны. В F7 Ctrl+C копирует между группами; Ctrl+X переставляет или переносит '
                'между группами, но не между Custom и группой. Ctrl+Delete удаляет только выбранные в текущей группе вхождения; Ctrl+Shift+Delete скрывает '
                'параметр глобально в Custom и группах, но не в Plugin Order. Восстановление — столбец Hidden Parameters в Ctrl+Shift+M. Обычный Delete в F7 '
                'снимает выделение. Ctrl+L из любой группы возвращает в Custom Order даже из F7.'),
               ('TEST62: групповое редактирование, Step и память FX',
                'В F7 Shift+Space, Ctrl+A и Shift+стрелки выделяют параметры. Alt+влево/вправо изменяет Step выделенных; Alt+вверх/вниз меняет значения с '
                'индивидуальным Step; Ctrl+E вводит общее значение только для совместимых параметров. Семь столбцов FX Memories включают Hidden Parameters, '
                'Copied Parameters с точными группой и позицией и Parameter Steps. Alt+влево/вправо изменяет Step записи памяти; Delete сбрасывает его. В '
                'обеих памятях: Shift+Space выделяет, Ctrl+A выделяет текущий столбец, Alt+Shift+Up/Down перемещается по выделенным, Delete обрабатывает '
                'выделение. Опасное восстановление Default по-прежнему требует подтверждения.'),
               ('TEST62: быстрый поиск, Alt+P и импорт TXT',
                'Символы, цифры и знаки, введённые с интервалом менее секунды, образуют поисковый префикс, в том числе в начале слов внутри названия. Повтор '
                'буквы перебирает совпадения; Shift ищет назад, включая физические цифровые клавиши. Выделение не меняется. Alt+P открывает FX Params для '
                'выбранного эффекта только в стандартном списке FX Chain; клавиша P остаётся REAPER. Команда LReaParams: Import selected legacy TXT files '
                'преобразует один или несколько старых Lua TXT, сохраняя исходники и не перезаписывая существующие профили при конфликте.')],
        'track': [('TEST62: выделение в Track Memories',
                   'Откройте Track Memories через Ctrl+Shift+M. Shift+Space выделяет строку, Ctrl+A выделяет лишь текущий столбец, стрелки сохраняют '
                   'выделение. Alt+Shift+Up/Down переходит между выделенными строками того же столбца; Alt+Shift+влево/вправо столбец не меняет. Delete '
                   'применяется ко всем выбранным строкам, а без выделения — только к текущей. Временное выделение не сохраняется.'),
                  ('TEST62: поиск Track и выборочный импорт TXT',
                   'Последовательные символы за одну секунду ищут префикс: F1 — в названиях дорожек, F2/F3 — только среди полей текущего столбца send/receive. '
                   'Shift меняет направление, включая физические цифровые клавиши. Команда LReaParams: Import selected legacy TXT files позволяет выбрать '
                   'несколько старых TXT в Plugins или Tracks; исходники остаются нетронутыми, а старые GUID дорожек не связываются автоматически с текущим '
                   'проектом.')]},
 'zh-CN': {'fx': [('TEST62：顺序、分组、隐藏及 F7',
                   'Plugin Order 始终显示全部原始参数，包括在其他视图中隐藏的参数。Custom Order 与 12 个分组分别保存条目、副本和网格；已保存的空分组仍可使用。在 F7 中，Ctrl+C 可跨组复制，Ctrl+X 可在组间移动或在同一视图内排序，但不能在 Custom '
                   '与组之间剪切。Ctrl+Delete 仅删除当前组中选中的条目；Ctrl+Shift+Delete 在 Custom 和所有组中全局隐藏参数，但不影响 Plugin Order。通过 Ctrl+Shift+M 的 Hidden Parameters 列恢复。F7 中单独按 '
                   'Delete 只取消选择。从任何组按 Ctrl+L 始终返回 Custom Order，即使 F7 已打开。'),
                  ('TEST62：批量编辑、Step 与 FX 记忆',
                   '在 F7 中用 Shift+Space、Ctrl+A 或 Shift+方向键选中多个参数。Alt+左右改变所选参数的 Step，Alt+上下按各自 Step 修改参数值，Ctrl+E 仅对兼容参数执行批量精确输入。FX Memories 的七列包括 Hidden '
                   'Parameters、带准确组名及位置的 Copied Parameters 和 Parameter Steps。Alt+左右可调整记忆项的 Step；Delete 将其复位。FX 与 Track 两种记忆中，Shift+Space 选择行，Ctrl+A '
                   '选择当前列，Alt+Shift+Up/Down 在已选行间移动，Delete 作用于选中项。危险的 Default 恢复操作仍需确认。'),
                  ('TEST62：增量搜索、Alt+P 和 TXT 导入',
                   '在一秒内连续输入字母、数字或标点可构成搜索前缀，也可匹配名称内部单词的开头。重复一个字母可浏览匹配项；按住 Shift 反向搜索，包括物理数字键。搜索不会改变现有选择。仅在原生 FX Chain 列表中，Alt+P 对选中效果打开 FX Params；字母 P 仍由 '
                   'REAPER 使用。LReaParams: Import selected legacy TXT files 操作可选择一个或多个旧 Lua TXT 文件进行转换，不更改原件，也不会在冲突时覆盖现有配置。')],
           'track': [('TEST62：Track Memories 多选',
                      '用 Ctrl+Shift+M 打开 Track Memories。Shift+Space 选择或取消选择当前行，Ctrl+A 只选择当前列；方向键不会清除选择。Alt+Shift+Up/Down 在同列已选行间移动，Alt+Shift+左右不会切换列。Delete '
                      '删除或重置选中行；未选择时仅作用于当前行。临时选择不会被保存。'),
                     ('TEST62：Track 搜索和选择性 TXT 导入',
                      '一秒内连续输入字符即可按前缀搜索：F1 搜索轨道名称，F2/F3 只搜索当前 send/receive 列中的字段。Shift 可反向搜索，包括物理数字键。LReaParams: Import selected legacy TXT files 可在 Plugins 或 '
                      'Tracks 文件夹中选择多个旧 TXT；原文件保持不变，旧 Track GUID 不会自动绑定至当前工程。')]},
 'ja': {'fx': [('TEST62：表示順、グループ、非表示、F7',
                'Plugin Order は、他のビューで非表示にしたものを含め、元のパラメータを常にすべて表示します。Custom Order と 12 のグループは、重複項目やグリッドを個別に保存します。保存した空のグループも残ります。F7 の Ctrl+C '
                'はグループ間でコピーでき、Ctrl+X は同じビュー内の並べ替えやグループ間の移動に使えますが、Custom とグループの間での切り取りはできません。Ctrl+Delete は現在のグループで選択した項目だけを削除し、Ctrl+Shift+Delete は Custom '
                'とすべてのグループで一括非表示にします。Plugin Order には影響しません。Ctrl+Shift+M の Hidden Parameters 列で戻せます。F7 の Delete 単独は選択解除です。グループからの Ctrl+L は F7 内でも必ず Custom '
                'Order に戻ります。'),
               ('TEST62：複数編集、Step、FX メモリー',
                'F7 では Shift+Space、Ctrl+A、Shift+矢印で複数のパラメータを選択します。Alt+左右は選択項目の Step を変更し、Alt+上下は個別の Step で値を調整します。Ctrl+E の一括数値入力は互換パラメータだけに使えます。FX Memories の '
                '7 列には Hidden Parameters、正確なグループと位置を示す Copied Parameters、Parameter Steps が含まれます。Alt+左右で記憶項目の Step を編集し、Delete でリセットします。FX/Track のメモリーでは '
                'Shift+Space で選択、Ctrl+A で現在の列を全選択、Alt+Shift+Up/Down で選択行間を移動、Delete で選択項目を処理します。Default の危険な復元操作には確認が必要です。'),
               ('TEST62：インクリメンタル検索、Alt+P、TXT 取込',
                '1 秒以内に続けて入力した文字・数字・記号で接頭辞検索します。名前の途中にある単語の先頭にも一致します。同じ文字の繰り返しで候補を巡回し、Shift を押すと逆方向に検索します。数字キーも物理キー番号を使います。選択は変更しません。REAPER 標準の FX Chain 一覧でのみ '
                'Alt+P が選択中の FX を FX Params で開き、P キーは REAPER の検索に残ります。LReaParams: Import selected legacy TXT files では複数の旧 Lua TXT '
                'を選択して変換でき、元ファイルを変更せず、競合時も既存プロファイルを上書きしません。')],
        'track': [('TEST62：Track Memories の複数選択',
                   'Ctrl+Shift+M で Track Memories を開きます。Shift+Space で現在行を選択、Ctrl+A で現在の列だけを全選択します。矢印移動では選択が維持されます。Alt+Shift+Up/Down '
                   'は同じ列の選択行間を移動し、Alt+Shift+左右は列を変更しません。Delete は選択行を削除またはリセットし、選択がない場合は現在行だけに作用します。一時的な選択は保存されません。'),
                  ('TEST62：Track 検索と TXT の選択取込',
                   '1 秒以内に連続して入力した文字で接頭辞検索できます。F1 はトラック名、F2/F3 は現在の send/receive 列の項目だけを検索します。Shift は数字の物理キーも含め逆方向検索になります。LReaParams: Import selected legacy '
                   'TXT files から Plugins または Tracks 内の複数の旧 TXT を選択できます。元ファイルは変更されず、旧 Track GUID は現在のプロジェクトへ自動的には関連付けられません。')]}}

# TEST61.14–61.16.1: generated appendix, retained across guide regeneration.
FX_CONTEXT_UPDATES = {
 'it': ('Novità TEST61: griglie, gruppi e ripristino', 'Plugin Order, Custom Order e ciascuno dei 12 gruppi hanno una griglia indipendente: F1/F2 ne regolano la larghezza, e ciascuna vista ricorda parametro e occorrenza selezionata, anche senza usare F7. Ctrl+L cambia tra Plugin Order e Custom Order; Ctrl+F1–Ctrl+F12 entra nei gruppi nella modalità Gruppo e ripremendo lo stesso comando ne esce. Esc dalla griglia di un gruppo chiude direttamente FX Params, mentre Esc dentro F7 chiude prima l’editor. La posizione e il gruppo sono conservati nella sessione per la singola istanza dell’FX; alla chiusura o al cambio di vista si salvano anche nel profilo .fx. Dopo il riavvio, il profilo è un riferimento condiviso fra istanze dello stesso tipo di plugin, non una memoria separata per GUID. Le griglie sono memorizzate in [Extra] come lrp_context_grids_v1, la vista attiva in lrp_last_navigation_v1 e il parametro in LastParam. Profili precedenti restano compatibili. Ctrl+Alt+B mette l’FX offline e mostra il browser; premendolo nuovamente, quando l’FX torna online, FX Params riprende automaticamente gruppo, griglia e parametro, senza riaprire il navigatore. Se i parametri non sono subito disponibili, il recupero viene tentato senza bloccare l’interfaccia (fino a 90 secondi); un cambio volontario di FX annulla il recupero. F7 non viene riaperto automaticamente.'),
 'es': ('Novedades TEST61: cuadrículas, grupos y restauración', 'Plugin Order, Custom Order y los 12 grupos recuerdan por separado el ancho de la cuadrícula (F1/F2) y la posición exacta del parámetro, incluso sin editar con F7. Ctrl+L cambia entre Plugin y Custom; Ctrl+F1–Ctrl+F12 accede a los grupos en modo Grupo. Esc desde un grupo cierra FX Params directamente; en F7, Esc primero cierra el editor. La memoria es individual por instancia durante la sesión y también se guarda en el perfil .fx, compartido entre instancias del mismo tipo de plugin tras reiniciar REAPER. Se conservan los perfiles anteriores. Ctrl+Alt+B pone el FX fuera de línea y abre el navegador; al volver a ponerlo en línea, se recuperan automáticamente grupo, cuadrícula y parámetro, incluso si tardan en aparecer (hasta 90 segundos). Cambiar de FX cancela esta recuperación. F7 no se reabre automáticamente.'),
 'fr': ('Nouveautés TEST61 : grilles, groupes et restauration', 'Plugin Order, Custom Order et les 12 groupes mémorisent chacun leur largeur de grille (F1/F2) et la position exacte du paramètre, même sans utiliser F7. Ctrl+L bascule entre Plugin et Custom ; Ctrl+F1–Ctrl+F12 ouvre les groupes en mode Groupe. Échap depuis une grille de groupe ferme directement FX Params ; dans F7, Échap ferme d’abord l’éditeur. Chaque instance conserve son état pendant la session ; le profil .fx partagé par type de plug-in sert de restauration après redémarrage. Les anciens profils restent compatibles. Ctrl+Alt+B met le FX hors ligne et affiche le navigateur ; lors du retour en ligne, groupe, grille et paramètre sont automatiquement restaurés, avec une vérification non bloquante jusqu’à 90 secondes si nécessaire. Changer volontairement de FX annule cette restauration. F7 ne se rouvre pas automatiquement.'),
 'ru': ('Новое в TEST61: сетки, группы и восстановление', 'Plugin Order, Custom Order и все 12 групп независимо сохраняют ширину сетки (F1/F2) и точную позицию параметра, даже без редактирования F7. Ctrl+L переключает Plugin/Custom; Ctrl+F1–Ctrl+F12 открывают группы в режиме групп. Esc в сетке группы сразу закрывает FX Params; в F7 сначала закрывается редактор. Во время сеанса память отдельная для каждого экземпляра FX; после перезапуска используется общий профиль .fx для данного типа плагина. Старые профили поддерживаются. Ctrl+Alt+B переводит FX в offline и показывает браузер; при возврате online группа, сетка и параметр восстанавливаются автоматически. Для медленно загружаемых параметров выполняется неблокирующая проверка до 90 секунд. Смена FX отменяет восстановление; F7 автоматически не открывается.'),
 'zh-CN': ('TEST61 新功能：独立网格、分组和恢复', 'Plugin Order、Custom Order 和 12 个分组分别记住自己的网格列数（F1/F2）以及准确的参数位置，无须进入 F7 编辑器。Ctrl+L 在 Plugin 和 Custom 间切换；在分组模式下使用 Ctrl+F1–Ctrl+F12 进入分组。在分组网格中按 Esc 会直接关闭 FX Params；在 F7 中则先关闭编辑器。当前会话按 FX 实例分别保存状态，重启 REAPER 后从同类型插件共享的 .fx 配置文件恢复。旧配置仍兼容。Ctrl+Alt+B 将 FX 设为离线并显示浏览器；重新上线后自动恢复分组、网格和参数。参数加载缓慢时最多进行 90 秒非阻塞检查。主动切换 FX 将取消恢复，F7 不会自动重新打开。'),
 'ja': ('TEST61 の新機能：独立グリッド、グループ、復元', 'Plugin Order、Custom Order、12 個のグループが、それぞれグリッド幅（F1/F2）と正確なパラメータ位置を記憶します。F7 で編集する必要はありません。Ctrl+L で Plugin/Custom を切り替え、グループモードでは Ctrl+F1～Ctrl+F12 でグループを開きます。グループのグリッドで Esc を押すと FX Params を直接閉じます。F7 内では先にエディターを閉じます。セッション中は FX インスタンスごとに記憶し、REAPER 再起動後は同種プラグインで共有する .fx プロファイルから復元します。旧プロファイルも利用できます。Ctrl+Alt+B で FX をオフラインにするとブラウザーへ移動し、オンラインに戻すとグループ、グリッド、パラメータが自動復元されます。読み込みが遅い場合は最大 90 秒間、操作を妨げず確認します。別の FX に切り替えると復元は中止され、F7 は自動的に開きません。')
}

FX_RELEASE_063_HTML = '<h2 id="release-0-0-63-fx">LReaParams 0.0.63: TEST62 FX updates</h2>\n<p><strong>Plugin Order, Custom Order and 12 Groups:</strong> Plugin Order always lists the complete original native parameters, unaffected by global hiding, copies and group editing. Custom Order and each group have separate occurrences and navigation grids. You can save and recall an empty group. From any group, Ctrl+L returns directly to Custom Order, including when F7 was open (which is closed); Ctrl+L again switches to Plugin Order. Repeating a group\'s Ctrl+F1–F12 shortcut returns to the originating context instead.</p>\n<p><strong>F7 structural commands:</strong> Ctrl+C copies occurrences to Custom or other groups; Ctrl+X moves within or between groups and reorders within the same context. Cutting between Custom and groups is blocked. Ctrl+Delete removes only selected occurrences from the current group; it does nothing in Custom. Ctrl+Shift+Delete hides selected parameter IDs globally in Custom and all groups, never Plugin Order, without erasing group membership. Restore individual IDs from Hidden Parameters in FX Memories. Plain Delete deselects in F7. Ctrl+Z/Y undo and redo structural edits.</p>\n<p><strong>F7 bulk parameter edits:</strong> Shift+Space, Ctrl+A and Shift+arrows select parameters. Alt+Left/Right sets their shared Step adjustment (-10 to +10); Alt+Up/Down and Alt+Page Up/Down update unique selected parameters using each parameter\'s own Step. Ctrl+E applies an exact numeric value to multiple selected parameters only when types, ranges, and formatting are compatible; incompatible sets are rejected without a partial intentional edit. ReaEQ multi-band editing requires the same band property. The normal single-parameter operations remain available.</p>\n<p><strong>FX Memories seven columns:</strong> Ctrl+Shift+M opens the separate manager. Copied Parameters identifies the exact group, occurrence and position, or additional Custom Order copy. Hidden Parameters holds the shared invisibility list; restoring one ID makes its preserved group entries visible again. Parameter Steps lists nonzero FX Steps; Alt+Left/Right edits the selected memory\'s Step and Delete resets it to zero. Shift+Space toggles selection, Ctrl+A selects the current column, Alt+Shift+Up/Down navigates selected entries in that column and Delete acts on selected entries (or current row if nothing selected). Default snapshot restore still requires explicit confirmation.</p>\n<p><strong>Incremental search:</strong> Quickly type letters, digits or punctuation within 1000 ms to find a prefix at the start of a parameter name or any subsequent word; repeated letters cycle matches. Shift searches backward. Shift+number searches by the physical digit key even on Italian keyboard layouts, rather than the shifted symbol. Selection is preserved. Ctrl+F still opens explicit search.</p>\n<p><strong>Native FX Chain:</strong> With focus on the FX Chain\'s own FX list, Alt+P opens FX Params for the selected plugin; plain P remains REAPER\'s list search, and Alt+P is untouched outside that list. <strong>Selective TXT import:</strong> From REAPER\'s Action List choose “LReaParams: Import selected legacy TXT files” (also in Extensions &gt; LReaParams). Choose one or multiple compatible legacy Lua TXT files under Plugins or Tracks. Originals and existing native profiles remain intact; a differing existing destination produces an import-conflict copy instead of an overwrite.</p>'
TRACK_RELEASE_063_HTML = '<h2 id="release-0-0-63-track">LReaParams 0.0.63: TEST62 Track updates</h2>\n<p><strong>Track Memories:</strong> Ctrl+Shift+M opens the memory manager. Shift+Space selects or deselects the current row; Ctrl+A selects all rows in the current column only. Arrow and page navigation preserves selected entries. Alt+Shift+Up/Down goes to the previous/next selected row in that column; Alt+Shift+Left/Right leaves the column unchanged. Delete acts on selected rows or the current row when none are selected. Selection is temporary and clears when the manager closes.</p>\n<p><strong>Incremental search:</strong> Typing consecutive printable characters within 1000 ms searches track names on F1, and only fields of the current send/receive column on F2/F3. Shift searches backward, including number-row keys on keyboard layouts where Shift produces symbols. Search does not change track selection or routing; Ctrl+F remains the explicit search control.</p>\n<p><strong>Selective legacy TXT import:</strong> Choose “LReaParams: Import selected legacy TXT files” from REAPER\'s actions or Extensions &gt; LReaParams. Select one or multiple original Lua TXT files inside the old Plugins or Tracks folders. Original files are never modified, existing .fx/.tp files are not overwritten, and historic track GUID settings are not automatically attached to the current project.</p>'

# Version 0.0.64: the TEST63.1 fix was confirmed in REAPER by the user with RX 11.
FX_RELEASE_064_HTML = (
    '<h2 id="release-0-0-64-fx">LReaParams 0.0.64: iZotope RX 11 parameter readback</h2>'
    '<p>In the iZotope RX family, a formatted parameter value can be updated after the host accepts a change. '
    'FX Params now waits briefly for a stable readback before announcing changed sliders or combo-box choices, '
    'so NVDA/OSARA does not speak the previous value. This applies to Alt+arrows, Alt+Page Up/Down, '
    'Alt+Home/End, Value mode, parameter default reset, selected parameters in F7, and direct numeric editing. '
    'Rapid changes replace old pending speech; changing parameter, FX or context cancels it. '
    'A small speech delay is expected with RX, while other plugins keep their immediate readback. '
    'Profiles, keyboard shortcuts and parameter ranges are unchanged.</p>'
)
FX_RX_064_LOCALIZED = {
    'it': ('0.0.64: lettura aggiornata con iZotope RX 11',
           'Nei plugin iZotope RX 11, il valore formattato di slider e caselle combinate puo aggiornarsi dopo la modifica. '
           'LReaParams attende brevemente il nuovo valore prima di annunciarlo, evitando di leggere quello precedente. '
           'La correzione riguarda Alt+frecce, Alt+Pagina su/giu, Alt+Home/Fine, modalita Valore, ripristino dei valori, '
           'modifiche multiple in F7 e inserimento numerico. Le modifiche rapide annullano gli annunci superati. '
           'Solo gli RX hanno questa piccola latenza vocale; gli altri plugin restano immediati.'),
    'es': ('0.0.64: lectura actualizada en iZotope RX 11',
           'En los plugins iZotope RX 11, el texto de un control puede actualizarse despues del cambio. '
           'LReaParams espera brevemente al nuevo valor antes de anunciarlo, en lugar de leer el anterior. '
           'Funciona con Alt+flechas, Alt+Re Pag/Av Pag, Alt+Inicio/Fin, modo Valor, restablecimiento, F7 y entrada numerica. '
           'Los cambios rapidos cancelan mensajes antiguos. El pequeno retraso solo afecta a RX.'),
    'fr': ('0.0.64 : lecture mise a jour pour iZotope RX 11',
           'Dans les plugins iZotope RX 11, le texte du parametre peut etre mis a jour apres sa modification. '
           'LReaParams attend brievement la nouvelle valeur avant de la prononcer. '
           'Cela concerne Alt+fleches, Alt+Page precedente/suivante, Alt+Debut/Fin, mode Valeur, reinitialisation, F7 et saisie numerique. '
           'Les annonces obsoletes sont annulees. Les autres plugins restent immediats.'),
    'ru': ('0.0.64: корректное чтение параметров iZotope RX 11',
           'В плагинах iZotope RX 11 отображаемое значение может обновляться с задержкой. '
           'LReaParams ждёт нового значения перед озвучиванием, чтобы не читать прежнее. '
           'Работает при Alt+стрелках, Alt+Page Up/Down, Alt+Home/End, в режиме значения, сбросе, F7 и числовом вводе. '
           'Устаревшие сообщения отменяются, остальные плагины работают без задержки.'),
    'zh-CN': ('0.0.64：iZotope RX 11 参数朗读修正',
           'iZotope RX 11 有时会在参数修改后才更新显示文本。LReaParams 会稍等新的数值稳定，再交给 NVDA/OSARA 朗读，避免读出旧值。'
           '此功能适用于 Alt+方向键、Alt+Page Up/Down、Alt+Home/End、数值模式、重置、F7 多参数编辑和数字输入。'
           '快速连续修改会取消过时的朗读；其他插件不增加延迟。'),
    'ja': ('0.0.64：iZotope RX 11 のパラメーター読み上げ改善',
           'iZotope RX 11 では値を変更した後に表示が更新される場合があります。LReaParams は新しい値を確認してから読み上げ、'
           '古い値を誤って案内しないようにしました。Alt+矢印、Alt+Page Up/Down、Alt+Home/End、値モード、リセット、F7、数値入力に対応します。'
           '連続操作時の古い案内は取り消されます。RX 以外のプラグインは従来どおり即時読み上げです。'),
}

def patch_originals():
    for filename in ('LReaParams - FX Params.html','LReaParams - Track Params.html'):
        file=ROOT/filename
        s=file.read_text(encoding='utf-8')
        # Keep detailed English guides versioned too, without replacing historical
        # "introduced in 0.0.61" descriptions or stable 0-0-61 anchors.
        s=s.replace('<title>LReaParams 0.0.61', '<title>LReaParams 0.0.67')
        s=s.replace('<title>LReaParams 0.0.62', '<title>LReaParams 0.0.67')
        s=s.replace('<title>LReaParams 0.0.63', '<title>LReaParams 0.0.67')
        s=s.replace('<title>LReaParams 0.0.64', '<title>LReaParams 0.0.67')
        s=s.replace('<title>LReaParams 0.0.65', '<title>LReaParams 0.0.67')
        s=s.replace('<title>LReaParams 0.0.66', '<title>LReaParams 0.0.67')
        s=s.replace('<strong>Version 0.0.61', '<strong>Version 0.0.67')
        s=s.replace('<strong>Version 0.0.62', '<strong>Version 0.0.67')
        s=s.replace('<strong>Version 0.0.63', '<strong>Version 0.0.67')
        s=s.replace('<strong>Version 0.0.64', '<strong>Version 0.0.67')
        s=s.replace('<strong>Version 0.0.65', '<strong>Version 0.0.67')
        s=s.replace('<strong>Version 0.0.66', '<strong>Version 0.0.67')
        s=s.replace('<footer><p>LReaParams 0.0.61', '<footer><p>LReaParams 0.0.67')
        s=s.replace('<footer><p>LReaParams 0.0.62', '<footer><p>LReaParams 0.0.67')
        s=s.replace('<footer><p>LReaParams 0.0.63', '<footer><p>LReaParams 0.0.67')
        s=s.replace('<footer><p>LReaParams 0.0.64', '<footer><p>LReaParams 0.0.67')
        s=s.replace('<footer><p>LReaParams 0.0.65', '<footer><p>LReaParams 0.0.67')
        s=s.replace('<footer><p>LReaParams 0.0.66', '<footer><p>LReaParams 0.0.67')
        s=s.replace('aligned to the <strong>0.0.61 TEST61.4 source</strong>',
                    'updated for the <strong>0.0.67 release (TEST62.9.2 source)</strong>')
        s=s.replace('reflects <strong>0.0.61 TEST61.4 source code</strong>',
                    'reflects the <strong>0.0.67 release (TEST62.9.2 source code)</strong>')
        s=s.replace('0.0.62 release (TEST61.16.1 source)', '0.0.67 release (TEST62.9.2 source)')
        s=s.replace('0.0.62 release (TEST61.16.1 source code)', '0.0.67 release (TEST62.9.2 source code)')
        s=s.replace('0.0.63 release (TEST62.9.2 source code)', '0.0.67 release (TEST64.3 source code)')
        s=s.replace('0.0.63 release (TEST62.9.2 source)', '0.0.67 release (TEST64.3 source)')
        s=s.replace('0.0.64 release (TEST63.1 source code)', '0.0.67 release (TEST64.3 source code)')
        s=s.replace('0.0.64 release (TEST63.1 source)', '0.0.67 release (TEST64.3 source)')
        # The stable guide must not present itself as a TEST build.
        s=s.replace('0.0.67 release (TEST65.1.1 source code)', '0.0.67 release')
        s=s.replace('0.0.67 release (TEST65.1.1 source)', '0.0.67 release')
        # Keep the original English shortcut table and paragraph in sync with 0.0.67.
        if filename == 'LReaParams - FX Params.html':
            s=s.replace('<strong>Ctrl+Backspace</strong> restores Grid 10 and Step 0.',
                        '<strong>Ctrl+Backspace</strong> resets only the current parameter\'s Step 0; <strong>Shift+Backspace</strong> resets only the current Grid to 10, or twice quickly opens numeric Grid size 1–400.')
            s=s.replace('<td>Ctrl+Backspace</td>\n<td>Reset Grid 10 and the parameter\'s Step 0</td>',
                        '<td>Ctrl+Backspace</td>\n<td>Reset only the parameter\'s Step 0</td>\n</tr>\n<tr>\n<td>Shift+Backspace; press twice quickly</td>\n<td>Reset current Grid to 10; double press opens numeric Grid size 1–400</td>')
            s=s.replace('<strong>F3</strong> reviews grid/step information.',
                        '<strong>F3</strong> reviews Grid, Step and active Group slots or Memory slots mode.')
        # Do not rewrite the detailed original guide; add a language selector link.
        if 'Select language</a>' not in s:
            s=s.replace('<header><p>', '<header><p><a href="index.html">Select language</a> · ', 1)
        if filename == 'LReaParams - FX Params.html' and 'id="test61-independent-context-grids"' not in s:
            detail = ("<h2 id=\"test61-independent-context-grids\">TEST61.14–61.16: independent FX grids and restoration</h2>"
              "<p><strong>Fourteen independent grids:</strong> Plugin Order, Custom Order, and all 12 groups independently remember their F1/F2 column count, selected parameter and precise occurrence, including duplicate entries. You do not need to enter F7 or change a parameter to save a grid position. Ctrl+L toggles Plugin/Custom; in Group mode Ctrl+F1–Ctrl+F12 selects a group, and repeating the same shortcut exits it back to its originating view.</p>"
              "<p><strong>Escape:</strong> Esc from a group grid closes FX Params immediately, retaining that group. Esc in F7 first exits its editor; F7 itself is not reopened automatically. Invalid, empty or removed groups fall back to the main grid.</p>"
              "<p><strong>Persistence:</strong> Each FX GUID keeps its own context during the REAPER session. On exit or context switch, the shared per-plugin <code>.fx</code> profile stores <code>LastParam</code>, <code>lrp_last_navigation_v1</code> (active group and zero-based grid position) and <code>lrp_context_grids_v1</code> (independent grid settings) in the optional <code>[Extra]</code> section. Older Lua keys and older profiles remain readable. After restarting REAPER the shared per-plugin profile is a fallback, not a per-GUID history of instances.</p>"
              "<p><strong>Offline/online:</strong> Ctrl+Alt+B sends the FX offline and shows FX Browser; repeating it to bring the same FX online automatically returns to its group, grid and parameter without reopening FX Params. Parameter loading is checked non-blockingly every 250 ms for up to 90 seconds. Voluntarily selecting another FX cancels that return. If no parameters appear, the browser remains usable.</p>"
              "<p>Documentation: <a href=\"../Docs/TEST61_16_INDEPENDENT_FX_GRIDS.md\">TEST61.16 test details</a> (available in the source repository); see also README and CHANGELOG. Release TEST61.16.1 only corrects a source-only static test; it does not change the C++ runtime behavior.</p>")
            # source guide may be distributed without Docs, so avoid broken offline link
            detail = detail.replace('<a href=\"../Docs/TEST61_16_INDEPENDENT_FX_GRIDS.md\">TEST61.16 test details</a> (available in the source repository)', 'See Docs/TEST61_16_INDEPENDENT_FX_GRIDS.md in the source repository')
            s=s.replace('</main>',detail+'</main>',1)
            s=s.replace('</ul></nav>', '<li><a href=\"#test61-independent-context-grids\">TEST61 independent grids and restoration</a></li></ul></nav>',1)
        if filename == 'LReaParams - FX Params.html':
            if 'id="release-0-0-63-fx"' not in s:
                s=s.replace('</main>', FX_RELEASE_063_HTML+'</main>',1)
                s=s.replace('</ul></nav>', '<li><a href="#release-0-0-63-fx">0.0.63 new FX features</a></li></ul></nav>',1)
            if 'id="release-0-0-64-fx"' not in s:
                s=s.replace('</main>', FX_RELEASE_064_HTML+'</main>',1)
                s=s.replace('</ul></nav>', '<li><a href="#release-0-0-64-fx">0.0.64 RX 11 parameter readback</a></li></ul></nav>',1)
        else:
            if 'id="release-0-0-63-track"' not in s:
                s=s.replace('</main>', TRACK_RELEASE_063_HTML+'</main>',1)
                s=s.replace('</ul></nav>', '<li><a href="#release-0-0-63-track">0.0.63 new Track features</a></li></ul></nav>',1)
        file.write_text(s,encoding='utf-8')


def write_install():
    (ROOT/'INSTALL.txt').write_text('''LReaParams 0.0.67 — multilingual user guides

Install the DLL and ALL Guide files into the REAPER resource directory:

  REAPER resource path\\UserPlugins\\reaper_lreaparams.dll
  REAPER resource path\\LReaParams\\Guide\\index.html
  REAPER resource path\\LReaParams\\Guide\\LReaParams - FX Params.html
  REAPER resource path\\LReaParams\\Guide\\LReaParams - Track Params.html
  REAPER resource path\\LReaParams\\Guide\\it\\index.html
  REAPER resource path\\LReaParams\\Guide\\es\\index.html
  REAPER resource path\\LReaParams\\Guide\\fr\\index.html
  REAPER resource path\\LReaParams\\Guide\\ru\\index.html
  REAPER resource path\\LReaParams\\Guide\\zh-CN\\index.html
  REAPER resource path\\LReaParams\\Guide\\ja\\index.html

In REAPER's Main Action List, run:
  LReaParams: Open User Guide
You can assign it a custom keyboard shortcut.
It opens index.html in the default browser, presenting the language list first.
The same command is in Extensions > LReaParams > Open User Guide.

If Guide/index.html is missing, the DLL shows a clear installation message.
The original detailed English guides remain available alongside the
translated functional references, which cover the main pages and key controls.
Translations are concise functional references; for expanded explanations,
use the 'Full English reference' link in each translated manual.

INSTALLAZIONE IN ITALIANO:
  Copia reaper_lreaparams.dll in UserPlugins e tutta la cartella Guide
  in LReaParams\\Guide all'interno della directory delle risorse di REAPER.
  Nell'elenco azioni esegui LReaParams: Open User Guide.
  La prima pagina offre la scelta della lingua, poi FX Params o Track Params.
''',encoding='utf-8')



# New in 0.0.66: a working-mode alternative in FX Params, not a new F7 mode.
FX_KEYBOARD_066_LOCALIZED = {
    'it': ('0.0.66: tema Keyboard per FX Params',
           'Ogni plugin conserva 14 temi indipendenti: Plugin Order, Custom Order e gruppi 1–12. '
           'F4 passa istantaneamente fra Standard e Keyboard solo nel contesto corrente, senza spostare parametro o Step. '
           'In Keyboard i 36 tasti 1–0, Q–P, A–L, Z–M selezionano i parametri nell’ordine corrente; un tasto senza parametro resta silenzioso. '
           'Alt+Freccia su/giù passa al blocco precedente/successivo di 36 e seleziona il primo parametro. '
           'Freccia su/giù, Pagina su/giù, Home/Fine modificano il valore; sinistra/destra regolano lo Step. '
           'Pagina su/giù usa un incremento ampio calibrato rispetto alle frecce. '
           'Ctrl+B, Ctrl+Maiusc+D, Ctrl+Pagina su/giù, Ctrl+Freccia su/giù e tutte le altre scorciatoie restano invariate. '
           'L’editor F7 è sempre Standard. Le preferenze vengono salvate nel profilo .fx.'),
    'es': ('0.0.66: tema Keyboard en FX Params',
           'Cada plugin guarda 14 temas independientes para Plugin Order, Custom Order y los 12 grupos. '
           'F4 cambia instantáneamente entre Standard y Keyboard solo en el contexto actual, sin mover el parámetro ni su Step. '
           'Las 36 teclas 1–0, Q–P, A–L, Z–M seleccionan parámetros en orden; las posiciones vacías no anuncian nada. '
           'Alt+Arriba/Abajo cambia de bloque de 36 y selecciona el primer parámetro. '
           'Arriba/Abajo, Re Pág/Av Pág e Inicio/Fin cambian el valor; Izquierda/Derecha cambia Step. '
           'Re Pág/Av Pág usan incrementos grandes calibrados. Los atajos existentes, como Ctrl+B y Ctrl+Shift+D, se conservan. '
           'F7 permanece siempre en Standard. Las preferencias se guardan en el perfil .fx.'),
    'fr': ('0.0.66 : thème Keyboard dans FX Params',
           'Chaque plug-in mémorise 14 thèmes indépendants : Plugin Order, Custom Order et 12 groupes. '
           'F4 bascule instantanément entre Standard et Keyboard seulement dans le contexte actif, sans déplacer le paramètre ni le Step. '
           'Les 36 touches 1–0, Q–P, A–L, Z–M sélectionnent les paramètres dans leur ordre ; les positions libres restent silencieuses. '
           'Alt+Haut/Bas change de bloc de 36 paramètres et sélectionne le premier. '
           'Haut/Bas, Page précédente/suivante et Début/Fin modifient la valeur ; Gauche/Droite règle le Step. '
           'Les grands pas Page sont calibrés ; les autres raccourcis, notamment Ctrl+B et Ctrl+Maj+D, restent actifs. '
           'F7 reste toujours Standard. Les choix sont enregistrés dans le profil .fx.'),
    'ru': ('0.0.66: тема Keyboard для FX Params',
           'Для каждого плагина отдельно сохраняются 14 тем: Plugin Order, Custom Order и 12 групп. '
           'F4 мгновенно переключает Standard/Keyboard только в текущем контексте, не меняя параметр и Step. '
           'Клавиши 1–0, Q–P, A–L, Z–M выбирают параметры по порядку; пустые позиции не озвучиваются. '
           'Alt+Вверх/Вниз переключает блоки по 36, выбирая первый параметр нового блока. '
           'Вверх/Вниз, Page Up/Down и Home/End изменяют значение; Влево/Вправо — Step. '
           'Большой шаг Page откалиброван. Прежние сочетания Ctrl+B, Ctrl+Shift+D и остальные сохраняются. '
           'F7 всегда работает в Standard. Выбор тем хранится в профиле .fx.'),
    'zh-CN': ('0.0.66：FX Params 的 Keyboard 主题',
              '每个插件分别保存 14 个主题选择：Plugin Order、Custom Order 和 12 个分组。'
              'F4 仅切换当前上下文的 Standard/Keyboard，不改变当前参数或步长。'
              '1–0、Q–P、A–L、Z–M 这 36 个键按当前顺序直接选择参数；空位置保持静默。'
              'Alt+上/下切换每 36 个参数一组的页面，并选中该页第一个参数。'
              '上/下、Page Up/Down、Home/End 调整数值；左/右调整步长。Page 的较大增量已校准。'
              'Ctrl+B、Ctrl+Shift+D 等其他快捷键保持不变。F7 始终使用 Standard。主题设置保存在 .fx 配置文件中。'),
    'ja': ('0.0.66：FX Params の Keyboard テーマ',
           'プラグインごとに Plugin Order、Custom Order、12 グループの計 14 テーマ設定を独立して保存します。'
           'F4 で現在の環境だけ Standard と Keyboard を瞬時に切り替え、パラメータや Step は変更しません。'
           '1～0、Q～P、A～L、Z～M の 36 キーで順番にパラメータを直接選択し、空のキーは無音です。'
           'Alt+上/下で 36 個ずつのページを移動し、新ページの先頭を選択します。'
           '上/下、Page Up/Down、Home/End で値を調整し、左右で Step を変更します。Page の大きな増分は調整済みです。'
           'Ctrl+B、Ctrl+Shift+D などその他のショートカットは従来どおりです。F7 は常に Standard で、テーマは .fx に保存されます。'),
}

# 0.0.66 maintains the 0.0.65 Keyboard theme and fixes Page key parity.
FX_RELEASE_066_HTML = (
    '<h2 id="release-0-0-66-keyboard">LReaParams 0.0.66: Keyboard Page key parity</h2>'
    '<p><strong>Keyboard now uses the exact same Page Up/Down value-adjustment handler as Standard Value.</strong> The separate Keyboard interception has been removed, preserving the same selected Step, coarse Page increments, arrow behavior and value limits. This is not a new mapping or a different calibration.</p>'
    '<p><strong>Keyboard settings are unchanged:</strong> F4 switches only the current of 14 saved FX contexts. Direct numeric/letter shortcuts still select one of 36 parameters in the current block; Alt+Up/Down changes blocks, unused slots are silent and F7 stays Standard. Every other existing shortcut remains active. No profile migration is required.</p>'
    '<p>GitHub Actions and ReaPack source validation now accept an existing generated index.xml as well as an archive without it; a stable GitHub release continues to publish the standalone DLL and refresh the ReaPack index automatically.</p>'
)

# Short, purpose-specific 0.0.66 additions in each accessible language.
PAGE_PARITY_066 = {
    'it': 'Pagina su e giù in Keyboard utilizzano ora esattamente lo stesso gestore di Value standard: identici Step, incrementi ampi e limiti; nessun percorso separato. F4, i 14 contesti e tutte le altre scorciatoie restano invariati.',
    'es': 'Av Pág/Re Pág en Keyboard usan ahora exactamente el mismo controlador que Value estándar: mismos pasos, incrementos amplios y límites. No hay ruta separada; F4, los 14 contextos y los demás atajos no cambian.',
    'fr': 'Page précédente/suivante dans Keyboard utilise désormais exactement le même traitement que Value standard : mêmes pas, grands incréments et limites. Aucune voie séparée ; F4, les 14 contextes et les autres raccourcis sont inchangés.',
    'ru': 'Page Up/Down в Keyboard теперь используют тот же обработчик, что и стандартный Value: те же шаги, крупные приращения и ограничения. Отдельной обработки нет; F4, 14 контекстов и прочие сочетания не изменены.',
    'zh-CN': 'Keyboard 的 Page Up/Down 现在与 Standard Value 使用完全相同的数值调整处理：相同的步长、较大增量及边界。不存在单独处理路径；F4、14 个上下文和其他快捷键保持不变。',
    'ja': 'Keyboard の Page Up/Down は Standard Value と完全に同じ値変更処理を使用します。Step、粗い増分、上下限は共通で、別の処理経路はありません。F4、14 コンテキスト、その他のショートカットは変更されません。',
}
FX_KEYBOARD_066_LOCALIZED = {lang:(heading, PAGE_PARITY_066[lang]) for lang,(heading,_old) in FX_KEYBOARD_066_LOCALIZED.items()}

def append_release_066():
    english=ROOT/'LReaParams - FX Params.html'
    s=english.read_text(encoding='utf-8')
    if 'id="release-0-0-66-keyboard"' not in s:
        s=s.replace('</main>', FX_RELEASE_066_HTML+'</main>',1)
        s=s.replace('</ul></nav>', '<li><a href="#release-0-0-66-keyboard">0.0.66 Keyboard Page key parity</a></li></ul></nav>',1)
        english.write_text(s,encoding='utf-8')
    for lang,(heading,body) in FX_KEYBOARD_066_LOCALIZED.items():
        file=ROOT/lang/'fx.html'
        s=file.read_text(encoding='utf-8')
        if 'id="release-0-0-66-keyboard"' not in s:
            from html import escape
            section='<section id="release-0-0-66-keyboard"><h2>'+escape(heading)+'</h2><p>'+escape(body)+'</p></section>'
            s=s.replace('</main>',section+'</main>',1)
            s=s.replace('</ol></nav>','<li><a href="#release-0-0-66-keyboard">'+escape(heading)+'</a></li></ol></nav>',1)
            file.write_text(s,encoding='utf-8')



# 0.0.67 adds independent Grid and Step reset commands without modifying F3 speech.
FX_RELEASE_067_HTML = (
    '<section id="release-0-0-67-grid"><h2>LReaParams 0.0.67: independent Grid and Step resets</h2>'
    '<p>In FX Params, <strong>Backspace</strong> restores the current parameter default; <strong>Ctrl+Backspace</strong> resets only the current Step; <strong>Shift+Backspace</strong> pressed once resets only the current Grid to 10 columns. Quickly pressing <strong>Shift+Backspace twice</strong> opens an accessible numeric edit field for the current Grid size (1 to 400 columns); Enter confirms and Escape cancels. <strong>Ctrl+Shift+Backspace</strong> resets all plugin parameter values, as in the earlier stable release.</p>'
    '<p>Each of the 14 FX contexts retains its independent Grid and memory. <strong>F3 keeps announcing Grid, Step and Group slots / Memory slots</strong>; Alt+G and Alt+M control that last mode. Existing FX profiles and ReaPack package identifiers remain compatible.</p></section>'
)

FX_RELEASE_067_LOCALIZED = {
    'it': ('0.0.67: griglia e Step indipendenti', 'In FX Params: Backspace ripristina il parametro corrente; Ctrl+Backspace ripristina soltanto lo Step; Maiusc+Backspace singolo ripristina soltanto la griglia a 10 colonne. Due pressioni rapide di Maiusc+Backspace aprono il campo numerico per scegliere da 1 a 400 colonne; Invio conferma ed Esc annulla. Ctrl+Maiusc+Backspace ripristina tutti i valori del plugin. Le griglie dei 14 contesti restano indipendenti; F3 continua ad annunciare Grid, Step e Group slots oppure Memory slots secondo la modalità scelta con Alt+G o Alt+M.'),
    'es': ('0.0.67: cuadrícula y Step independientes', 'En FX Params: Retroceso restablece el parámetro; Ctrl+Retroceso restablece solo Step; Mayús+Retroceso una vez restablece solo la cuadrícula a 10 columnas. Si se pulsa Mayús+Retroceso rápidamente dos veces, se abre la edición numérica de la cuadrícula (de 1 a 400); Intro confirma y Esc cancela. Ctrl+Mayús+Retroceso restablece todos los valores del plugin. Las 14 cuadrículas siguen siendo independientes y F3 sigue anunciando Grid, Step y Group slots o Memory slots.'),
    'fr': ('0.0.67 : grille et Step indépendants', 'Dans FX Params : Retour arrière réinitialise le paramètre ; Ctrl+Retour arrière réinitialise seulement Step ; Maj+Retour arrière une fois remet seulement la grille à 10 colonnes. Une double pression rapide sur Maj+Retour arrière ouvre la saisie numérique de 1 à 400 colonnes ; Entrée confirme et Échap annule. Ctrl+Maj+Retour arrière réinitialise toutes les valeurs du plug-in. Les 14 grilles demeurent indépendantes et F3 continue d’annoncer Grid, Step et Group slots ou Memory slots.'),
    'ru': ('0.0.67: отдельный сброс сетки и шага', 'В FX Params Backspace сбрасывает текущий параметр, Ctrl+Backspace — только Step, однократное Shift+Backspace — только сетку до 10 столбцов. Двойное быстрое Shift+Backspace открывает поле числового ввода размера сетки от 1 до 400; Enter подтверждает, Esc отменяет. Ctrl+Shift+Backspace сбрасывает все значения плагина. Все 14 сеток независимы, а F3 по-прежнему сообщает Grid, Step и Group slots или Memory slots.'),
    'zh-CN': ('0.0.67：独立重置网格和步长', '在 FX Params 中，Backspace 重置当前参数，Ctrl+Backspace 仅重置 Step，单次 Shift+Backspace 仅将当前网格重置为 10 列。快速连续按两次 Shift+Backspace 打开网格大小输入框（1 到 400）；Enter 确认、Esc 取消。Ctrl+Shift+Backspace 重置插件所有参数值。14 个网格仍独立保存，F3 仍报告 Grid、Step，以及 Group slots 或 Memory slots。'),
    'ja': ('0.0.67：グリッドと Step を個別にリセット', 'FX Params では Backspace で現在のパラメーター、Ctrl+Backspace で Step のみ、Shift+Backspace 1 回で現在のグリッドのみを 10 列にリセットします。Shift+Backspace を素早く 2 回押すとグリッド幅 1～400 の数値入力が開き、Enter で確定、Esc で中止します。Ctrl+Shift+Backspace でプラグイン全体のパラメーター値をリセットします。14 グリッドは独立して記憶され、F3 は Grid、Step、および Group slots または Memory slots の案内を続けます。'),
}

def append_release_067():
    english=ROOT/'LReaParams - FX Params.html'
    s=english.read_text(encoding='utf-8')
    if 'id="release-0-0-67-grid"' not in s:
        s=s.replace('</main>',FX_RELEASE_067_HTML+'</main>',1)
        s=s.replace('</ul></nav>', '<li><a href="#release-0-0-67-grid">0.0.67 Grid and Step resets</a></li></ul></nav>',1)
        english.write_text(s,encoding='utf-8')
    for lang,(heading,body) in FX_RELEASE_067_LOCALIZED.items():
        file=ROOT/lang/'fx.html'
        s=file.read_text(encoding='utf-8')
        if 'id="release-0-0-67-grid"' not in s:
            from html import escape
            section='<section id="release-0-0-67-grid"><h2>'+escape(heading)+'</h2><p>'+escape(body)+'</p></section>'
            s=s.replace('</main>',section+'</main>',1)
            s=s.replace('</ol></nav>', '<li><a href="#release-0-0-67-grid">'+escape(heading)+'</a></li></ol></nav>',1)
            file.write_text(s,encoding='utf-8')

if __name__ == '__main__':
    ROOT.mkdir(parents=True,exist_ok=True)
    for tag in (t for t in I18N if t != 'en'):
        (ROOT/tag).mkdir(exist_ok=True)
        localized_index(tag)
        for what in ('fx','track'): localized_manual(tag,what)
    make_main_index()
    english_index()
    patch_originals()
    write_install()
    append_release_066()
    append_release_067()
    print('Generated',len(LANGS),'languages and',len(list(ROOT.rglob('*.html'))),'HTML pages')
