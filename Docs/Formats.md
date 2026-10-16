# Formati attivi

Il wrapper nativo resta LREAPARAMS_PROFILE_V1, Kind=FX o Kind=TRACK, PayloadBytes, riga vuota e payload Lua originale. Estensioni .fx e .tp. L'importatore usa contenuto e ramo, non soltanto il nome del file. Il corpus sintetico contiene 48 FX e 4 Track.

I profili Lua FX Version=3 conservano PluginRaw, CustomOrder, DefaultValues, ParamSlots, GroupSlots, Extra e sezioni future. I profili Track Version=2 restano invariati. I virtuali negativi diversi da Compare restano opachi: vengono conservati nei profili ma non possono essere modificati dalla griglia.

Le associazioni MIDI usano le chiavi Lua cc_link_v1::param::<indice>, con valore canale<TAB>CC. Sono salvati canale 1..16 e CC 0..127. Il runtime valida anche record malformati prima dell'uso. Lo stato fixed usa cc_runtime_fixed_map_enabled_v1=1, il parlato cc_param_speech_v1::<indice>=1. Floating non crea un'associazione nel profilo.

Compare usa l'ID virtuale Lua -300000. Non è un parametro REAPER. DefaultValues esclude Compare. ReaEQ usa i metadati Lua REA_EQ_DEFAULT_MODE, REA_EQ_BAND_COUNT, REA_EQ_PARAM_COUNT, REA_EQ_VST_CHUNK e REA_EQ_WRAPPER_TAIL_1..3_NAME/NORM.

L'importazione dai due rami storici Scripts/Lo-lo - Scripts/Utility/Scripts conserva gli originali storici. Un TXT attivo viene eliminato soltanto dopo conversione valida, backup e verifica. I conflitti conservano l'originale e creano candidati separati. I dati del navigatore rimosso vengono ignorati senza cancellazioni.
