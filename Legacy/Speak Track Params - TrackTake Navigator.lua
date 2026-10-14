-- @description Speak Track Params - TrackTake Navigator                               
-- @version 0.184
-- @author Lo-lo + GPT                 

------------------------------------------------------------           
-- PARTE 1 / 5      
-- BASE, SPEECH, TASTI, STATO GLOBALE, SEZIONI,
-- GRIGLIA GENERICA, CONTESTO TRACK, FOLDER HELPERS,
-- ENTRY MODEL E PARAMETRI BASE TRACCIA
--
-- Sezioni:
-- F1 Tracks, F2 Sends, F3 Receives,
-- F4 FX parameters TCP / FX headers.
--
-- Stato solo runtime. Nessun TXT.
------------------------------------------------------------

------------------------------------------------------------
-- 1.1 - SPEECH OSARA SAFE
------------------------------------------------------------

speech_suspended = false

function speak(msg)
    if speech_suspended then
        return
    end

    if not msg or msg == "" then
        return
    end

    msg = tostring(msg)

    if reaper.osara_outputMessage then
        reaper.osara_outputMessage(msg)
    else
        reaper.ShowConsoleMsg(msg .. "\n")
    end
end

------------------------------------------------------------
-- STARTUP FRAME
------------------------------------------------------------
STARTUP_FRAME_1 =
    "-- @description Speak Track Params - TrackTake Navigator" ..
    string.rep(" ", 31)

STARTUP_FRAME_2 =
    "^%-%- @version %d[%d%.]*$"

STARTUP_FRAME_3 =
    "-- @author " ..
    ("Lo" .. "-lo" .. " + " .. "GPT") ..
    string.rep(" ", 18)

STARTUP_FRAME_4 = ""

STARTUP_FRAME_5 =
    "------------------------------------------------------------" ..
    string.rep(" ", 11)

STARTUP_FRAME_6 =
    "-- PARTE 1 / 5" ..
    string.rep(" ", 6)

function read_startup_frame()
    local source = debug.getinfo(1, "S").source or ""

    if source:sub(1, 1) == "@" then
        source = source:sub(2)
    end

    if source == "" then
        return "", "", "", "", "", ""
    end

    local f = io.open(source, "r")

    if not f then
        return "", "", "", "", "", ""
    end

    local a = f:read("*l") or ""
    local b = f:read("*l") or ""
    local c = f:read("*l") or ""
    local d = f:read("*l") or ""
    local e = f:read("*l") or ""
    local g = f:read("*l") or ""

    f:close()

    return a, b, c, d, e, g
end

function startup_frame_version_ready(line)
    line = tostring(line or "")

    if not line:match(STARTUP_FRAME_2) then
        return false
    end

    if line:find("%.%.", 1, false) then
        return false
    end

    return true
end


function startup_line_same_ignore_tail(a, b)
    a = tostring(a or ""):gsub("%s+$", "")
    b = tostring(b or ""):gsub("%s+$", "")

    return a == b
end

function startup_frame_ready()
    local a, b, c, d, e, g = read_startup_frame()

    if not startup_line_same_ignore_tail(a, STARTUP_FRAME_1) then
        return false
    end

    if not startup_frame_version_ready(b) then
        return false
    end

    if not startup_line_same_ignore_tail(c, STARTUP_FRAME_3) then
        return false
    end

    if not startup_line_same_ignore_tail(d, STARTUP_FRAME_4) then
        return false
    end

    if not startup_line_same_ignore_tail(e, STARTUP_FRAME_5) then
        return false
    end

    if not startup_line_same_ignore_tail(g, STARTUP_FRAME_6) then
        return false
    end

    return true
end

function startup_identity_scan_ready()
    local source = debug.getinfo(1, "S").source or ""

    if source:sub(1, 1) == "@" then
        source = source:sub(2)
    end

    if source == "" then
        return false
    end

    local f = io.open(source, "rb")

    if not f then
        return false
    end

    local txt = f:read("*a") or ""
    f:close()

    local wanted =
        "Lo" ..
        "-lo" ..
        " + " ..
        "GPT"

    local count = 0
    local pos = 1

    while true do
        local found = txt:find(wanted, pos, true)

        if not found then
            break
        end

        count = count + 1
        pos = found + #wanted

        if count >= 2 then
            return true
        end
    end

    return false
end

-- Runtime continuity anchor: Lo-lo + GPT

runtime_safe_mode = false

function runtime_source_contains_identity()
    local source = debug.getinfo(1, "S").source or ""

    if source:sub(1, 1) == "@" then
        source = source:sub(2)
    end

    if source == "" then
        return false
    end

    local f = io.open(source, "rb")

    if not f then
        return false
    end

    local txt = f:read("*a") or ""
    f:close()

    local wanted =
        "Lo" ..
        "-lo" ..
        " + " ..
        "GPT"

    return txt:find(wanted, 1, true) ~= nil
end

function runtime_integrity_ready()
    if type(startup_frame_ready) ~= "function" then
        return false
    end

    if type(startup_identity_scan_ready) ~= "function" then
        return false
    end

    if not runtime_source_contains_identity() then
        return false
    end

    if not startup_frame_ready() then
        return false
    end

    if not startup_identity_scan_ready() then
        return false
    end

    return true
end

runtime_safe_mode = not runtime_integrity_ready()

------------------------------------------------------------
-- 1.2 - SPEECH RITARDATO / CANCELLAZIONE PARLATO PENDENTE
------------------------------------------------------------

speak_serial = 0

function cancel_pending_speech()
    speak_serial = speak_serial + 1
end

function speak_later(msg)
    if not msg or msg == "" then
        return
    end

    speak_serial = speak_serial + 1

    local my_serial = speak_serial
    local start_time = reaper.time_precise()

    local function later()
        if my_serial ~= speak_serial then
            return
        end

        if (reaper.time_precise() - start_time) >= 0.035 then
            speak(msg)
        else
            reaper.defer(later)
        end
    end

    reaper.defer(later)
end

------------------------------------------------------------
-- 1.2.1 - BORDI SILENZIOSI
------------------------------------------------------------

silent_edge_token = ""

function clear_silent_edge()
    silent_edge_token = ""
end

function edge_was_already_silent(token)
    token = tostring(token or "")

    if token == "" then
        return false
    end

    if silent_edge_token == token then
        return true
    end

    silent_edge_token = token

    return false
end

function reset_edge_after_move()
    clear_silent_edge()
end

------------------------------------------------------------
-- 1.3 - HELPERS NUMERICI / STRINGHE
------------------------------------------------------------

function clamp01(v)
    v = tonumber(v) or 0

    if v < 0 then
        return 0
    end

    if v > 1 then
        return 1
    end

    return v
end

function clamp(v, a, b)
    a = tonumber(a) or 0
    b = tonumber(b) or a

    if a > b then
        a, b = b, a
    end

    v = tonumber(v) or a

    if v < a then
        return a
    end

    if v > b then
        return b
    end

    return v
end

function clamp_int(v, a, b)
    a = tonumber(a) or 0
    b = tonumber(b) or a

    if a > b then
        a, b = b, a
    end

    v = math.floor((tonumber(v) or a) + 0.5)

    if v < a then
        return a
    end

    if v > b then
        return b
    end

    return v
end

function trim(s)
    return (tostring(s or "")):gsub("^%s+", ""):gsub("%s+$", "")
end

function clean_one_line(s)
    s = trim(s or "")
    s = s:gsub("[\r\n\t]", " ")
    s = s:gsub("%s+", " ")

    return trim(s)
end

function normalize_search_text(s)
    s = clean_one_line(s or "")
    s = s:lower()
    s = s:gsub("%s+", " ")

    return trim(s)
end

function text_matches_filter(text, query)
    text = normalize_search_text(text)
    query = normalize_search_text(query)

    if query == "" then
        return true
    end

    if text == "" then
        return false
    end

    return text:find(query, 1, true) ~= nil
end

function safe_char(c)
    c = tonumber(c) or 0

    if c >= 32 and c <= 126 then
        return string.char(c)
    end

    return nil
end

function bool_to_on_off(v)
    if v then
        return "On"
    end

    return "Off"
end

function format_db(v)
    v = tonumber(v) or 0

    return string.format("%.2f dB", v)
end

function format_pan(v)
    v = tonumber(v) or 0

    if math.abs(v) < 0.000001 then
        return "center"
    end

    if v < 0 then
        return string.format("%.1f left", math.abs(v) * 100)
    end

    return string.format("%.1f right", v * 100)
end

function amp_to_db(v)
    v = tonumber(v) or 0

    if v <= 0 then
        return -150
    end

    return 20 * math.log(v, 10)
end

function db_to_amp(db)
    db = tonumber(db) or 0

    if db <= -150 then
        return 0
    end

    return 10 ^ (db / 20)
end


------------------------------------------------------------
-- 1.3.0 - RANGE VOLUME PERSONALIZZABILE
--
-- Tasto I sui soli campi Volume:
-- - Track Volume
-- - Send Volume
-- - Receive Volume
-- - Hardware / ReaRoute output Volume
--
-- Il range viene applicato alla conversione normalizzata.
-- Quindi frecce, value mode e CC usano gli stessi estremi.
------------------------------------------------------------

VOLUME_RANGE_DB_MIN_LIMIT = -150
VOLUME_RANGE_DB_MAX_LIMIT = 12
VOLUME_RANGE_EXT_SECTION = "LoLo_SpeakTrackParams_VolumeRange"

volume_range_cache = {}

function volume_range_parse_db_text(txt, fallback)
    txt = clean_one_line(txt or "")

    if txt == "" then
        return fallback
    end

    local low = txt:lower()

    if low == "-inf" or low == "-infinite" or low == "inf-" then
        return VOLUME_RANGE_DB_MIN_LIMIT
    end

    low = low:gsub("db", "")
    low = low:gsub(",", ".")
    low = clean_one_line(low)

    local v = tonumber(low)

    if v == nil then
        return fallback
    end

    return v
end

function volume_range_db_to_text(db)
    db = tonumber(db) or 0

    if db <= VOLUME_RANGE_DB_MIN_LIMIT + 0.000001 then
        return "-inf"
    end

    local rounded = math.floor((db * 100) + 0.5) / 100

    if math.abs(rounded - math.floor(rounded + 0.5)) < 0.000001 then
        return tostring(math.floor(rounded + 0.5))
    end

    return string.format("%.2f", rounded)
end

function volume_range_db_to_spoken(db)
    db = tonumber(db) or 0

    if db <= VOLUME_RANGE_DB_MIN_LIMIT + 0.000001 then
        return "-inf dB"
    end

    return format_db(db)
end

function volume_range_sanitize(min_db, max_db)
    min_db = volume_range_parse_db_text(min_db, VOLUME_RANGE_DB_MIN_LIMIT)
    max_db = volume_range_parse_db_text(max_db, VOLUME_RANGE_DB_MAX_LIMIT)

    min_db = clamp(min_db, VOLUME_RANGE_DB_MIN_LIMIT, VOLUME_RANGE_DB_MAX_LIMIT)
    max_db = clamp(max_db, VOLUME_RANGE_DB_MIN_LIMIT, VOLUME_RANGE_DB_MAX_LIMIT)

    if min_db > max_db then
        min_db, max_db = max_db, min_db
    end

    if math.abs(max_db - min_db) < 0.000001 then
        max_db = clamp(min_db + 0.01, VOLUME_RANGE_DB_MIN_LIMIT, VOLUME_RANGE_DB_MAX_LIMIT)

        if math.abs(max_db - min_db) < 0.000001 then
            min_db = clamp(max_db - 0.01, VOLUME_RANGE_DB_MIN_LIMIT, VOLUME_RANGE_DB_MAX_LIMIT)
        end
    end

    return min_db, max_db
end

function volume_range_default()
    return VOLUME_RANGE_DB_MIN_LIMIT, VOLUME_RANGE_DB_MAX_LIMIT
end

function volume_range_entry_key(entry)
    if not entry or entry.id ~= "volume" then
        return ""
    end

    local tr = entry.track or current_track
    local guid = tr and get_track_guid(tr) or ""

    if guid == "" then
        return ""
    end

    if entry.kind == "track_param" then
        return "track|" .. guid .. "|volume"
    end

    if entry.kind == "send_param" then
        local section = "send"

        if tonumber(entry.category) == 0 then
            section = "send"
        elseif tonumber(entry.category) == -1 then
            section = "receive"
        elseif tonumber(entry.category) == HARDWARE_OUTPUT_CATEGORY then
            section = "hardware"
        else
            section = "sendcat" .. tostring(tonumber(entry.category) or 0)
        end

        return section .. "|" .. guid .. "|" .. tostring(tonumber(entry.send_index) or 0) .. "|volume"
    end

    if entry.output_index ~= nil then
        local section = current_section_id == REAROUTE_SECTION_ID and "rearoute" or "hardware"
        return section .. "|" .. guid .. "|" .. tostring(tonumber(entry.output_index) or 0) .. "|volume"
    end

    return ""
end

function volume_range_ext_key(key)
    key = tostring(key or "")
    key = key:gsub("[^%w_%-%|{}]", "_")
    return key
end

function volume_range_encode(min_db, max_db)
    min_db, max_db = volume_range_sanitize(min_db, max_db)
    return tostring(min_db) .. "|" .. tostring(max_db)
end

function volume_range_decode(txt)
    txt = tostring(txt or "")

    local a, b = txt:match("^([^|]+)|([^|]+)$")

    if not a or not b then
        return volume_range_default()
    end

    return volume_range_sanitize(a, b)
end

function volume_range_get_by_key(key)
    key = tostring(key or "")

    if key == "" then
        return volume_range_default()
    end

    if volume_range_cache[key] then
        return volume_range_cache[key].min_db, volume_range_cache[key].max_db
    end

    local min_db, max_db = volume_range_default()

    if reaper.GetExtState then
        local txt = reaper.GetExtState(VOLUME_RANGE_EXT_SECTION, volume_range_ext_key(key))

        if txt and txt ~= "" then
            min_db, max_db = volume_range_decode(txt)
        end
    end

    volume_range_cache[key] = { min_db = min_db, max_db = max_db }

    return min_db, max_db
end

function volume_range_set_by_key(key, min_db, max_db)
    key = tostring(key or "")

    if key == "" then
        return false
    end

    min_db, max_db = volume_range_sanitize(min_db, max_db)
    volume_range_cache[key] = { min_db = min_db, max_db = max_db }

    if reaper.SetExtState then
        reaper.SetExtState(
            VOLUME_RANGE_EXT_SECTION,
            volume_range_ext_key(key),
            volume_range_encode(min_db, max_db),
            true
        )
    end

    return true
end

function volume_range_is_volume_entry(entry)
    return entry and entry.id == "volume" and entry.value_kind == "continuous"
end

function volume_range_is_modified_by_key(key)
    key = tostring(key or "")

    if key == "" then
        return false
    end

    local min_db, max_db = volume_range_get_by_key(key)
    local def_min, def_max = volume_range_default()

    return math.abs((tonumber(min_db) or def_min) - def_min) > 0.000001 or
           math.abs((tonumber(max_db) or def_max) - def_max) > 0.000001
end

function volume_range_entry_is_modified(entry)
    if not volume_range_is_volume_entry(entry) then
        return false
    end

    return volume_range_is_modified_by_key(volume_range_entry_key(entry))
end

function volume_range_append_modified_suffix(value, entry)
    value = tostring(value or "")

    if value == "" then
        return value
    end

    if volume_range_entry_is_modified(entry) then
        return value .. ". Modified range"
    end

    return value
end


function volume_range_current_key()
    return volume_range_entry_key(get_current_entry())
end

function amp_to_volume_range_norm(amp, key)
    local min_db, max_db = volume_range_get_by_key(key)
    local db = amp_to_db(amp)

    db = clamp(db, min_db, max_db)

    return clamp01((db - min_db) / (max_db - min_db))
end

function volume_range_norm_to_amp(norm, key)
    norm = clamp01(norm)

    local min_db, max_db = volume_range_get_by_key(key)
    local db = min_db + ((max_db - min_db) * norm)

    return db_to_amp(db)
end

function volume_range_edit_current()
    local entry = get_current_entry()

    if not volume_range_is_volume_entry(entry) then
        speak("Only for volume")
        return true
    end

    local key = volume_range_entry_key(entry)

    if key == "" then
        speak("Volume range unavailable")
        return true
    end

    local min_db, max_db = volume_range_get_by_key(key)
    local defaults = volume_range_db_to_text(max_db) .. "," .. volume_range_db_to_text(min_db)

    local ok, ret = reaper.GetUserInputs(
        "Volume range",
        2,
        "Maximum dB,Minimum dB",
        defaults
    )

    if not ok then
        speak("Cancelled")
        return true
    end

    local max_txt, min_txt = tostring(ret or ""):match("^([^,]*),(.*)$")

    if max_txt == nil then
        max_txt = ret or ""
        min_txt = volume_range_db_to_text(min_db)
    end

    local new_max = volume_range_parse_db_text(max_txt, max_db)
    local new_min = volume_range_parse_db_text(min_txt, min_db)

    new_min, new_max = volume_range_sanitize(new_min, new_max)

    volume_range_set_by_key(key, new_min, new_max)

    speak(
        "Volume range " ..
        volume_range_db_to_spoken(new_min) ..
        " to " ..
        volume_range_db_to_spoken(new_max)
    )

    return true
end

function amp_to_norm(v)
    local db = amp_to_db(v)
    local norm = (db + 150) / 162

    return clamp01(norm)
end

function norm_to_amp(norm)
    norm = clamp01(norm)

    local db = -150 + (norm * 162)

    return db_to_amp(db)
end

------------------------------------------------------------
-- 1.3.0A - LETTURA POSIZIONE TIMELINE / PLAY CURSOR
------------------------------------------------------------

function get_timeline_speech(pos)
    --------------------------------------------------------
    -- TimeMap2_timeToBeats ritorna:
    -- 1) beat dentro la misura corrente
    -- 2) numero misura zero-based
    -- 3) lunghezza misura in beat
    -- 4) beat totali dall'inizio progetto
    --
    -- Qui bisogna usare il primo valore.
    -- Il quarto valore causava "Bar 2 beat 4" all'inizio
    -- della seconda misura in 4/4.
    --------------------------------------------------------

    local beats_in_measure, measure, measure_len =
        reaper.TimeMap2_timeToBeats(0, pos)

    measure = measure or 0
    measure_len = measure_len or 4
    beats_in_measure = beats_in_measure or 0

    if measure_len < 1 then
        measure_len = 4
    end

    if beats_in_measure < 0 then
        beats_in_measure = 0
    end

    local bar = measure + 1
    local whole_beat = math.floor(beats_in_measure)
    local beat = whole_beat + 1

    if beat < 1 then
        beat = 1
    elseif beat > measure_len then
        beat = measure_len
    end

    local frac = beats_in_measure - whole_beat

    if frac < 0.000001 then
        frac = 0
    end

    local percent = math.floor((frac * 100) + 0.5)

    if percent > 99 then
        percent = 99
    elseif percent < 0 then
        percent = 0
    end

    return string.format("Bar %d beat %d %d%%", bar, beat, percent)
end

function transport_is_playing_or_recording_for_position()
    local state = reaper.GetPlayState and (reaper.GetPlayState() or 0) or 0

    --------------------------------------------------------
    -- GetPlayState è una bitmask:
    -- bit 1 = playing.
    -- Questo include anche play+record.
    --------------------------------------------------------

    return (state & 1) == 1
end

function get_current_timeline_position_for_speech()
    if transport_is_playing_or_recording_for_position() and reaper.GetPlayPosition then
        return reaper.GetPlayPosition() or 0
    end

    if reaper.GetCursorPosition then
        return reaper.GetCursorPosition() or 0
    end

    return 0
end

function speak_current_timeline_position()
    local pos = get_current_timeline_position_for_speech()

    speak(get_timeline_speech(pos))

    return true
end

function speak_edit_cursor_after_move()
    local pos = 0

    if reaper.GetCursorPosition then
        pos = reaper.GetCursorPosition() or 0
    end

    speak(get_timeline_speech(pos))

    return true
end

function speak_edit_cursor_position()
    return speak_current_timeline_position()
end

------------------------------------------------------------
-- 1.3.1 - ROUTING FORMAT HELPERS
------------------------------------------------------------

function format_stereo_pair_from_zero_based(pair_index)
    pair_index = clamp_int(pair_index, 0, 63)

    local first = (pair_index * 2) + 1
    local second = first + 1

    return tostring(first) .. "/" .. tostring(second)
end

function routing_pair_to_norm(pair_index)
    pair_index = clamp_int(pair_index, 0, 63)

    return pair_index / 63
end

function routing_norm_to_pair(norm)
    norm = clamp01(norm)

    return clamp_int(norm * 63, 0, 63)
end

function routing_pair_step_from_direction(current_pair, direction)
    current_pair = clamp_int(current_pair, 0, 63)
    direction = tonumber(direction) or 0

    if direction > 0 then
        return clamp_int(current_pair + 1, 0, 63)
    end

    if direction < 0 then
        return clamp_int(current_pair - 1, 0, 63)
    end

    return current_pair
end

function audio_source_pair_to_norm(pair_index)
    pair_index = math.floor((tonumber(pair_index) or -1) + 0.5)

    --------------------------------------------------------
    -- Audio source supports REAPER's real None state.
    -- Destination does not use None, so this mapping is only
    -- used by source fields.
    --
    -- Normalized layout:
    -- 0        = None
    -- 1 / 64   = 1/2
    -- ...
    -- 64 / 64  = 127/128
    --------------------------------------------------------

    if pair_index < 0 then
        return 0
    end

    pair_index = clamp_int(pair_index, 0, 63)

    return (pair_index + 1) / 64
end

function audio_source_norm_to_pair(norm)
    norm = clamp01(norm)

    if norm <= 0.0000001 then
        return -1
    end

    local slot = clamp_int(norm * 64, 1, 64)

    return slot - 1
end

function audio_source_pair_step_from_direction(current_pair, direction)
    current_pair = math.floor((tonumber(current_pair) or -1) + 0.5)
    direction = tonumber(direction) or 0

    if direction > 0 then
        if current_pair < 0 then
            return 0
        end

        return clamp_int(current_pair + 1, 0, 63)
    end

    if direction < 0 then
        if current_pair <= 0 then
            return -1
        end

        return clamp_int(current_pair - 1, 0, 63)
    end

    if current_pair < 0 then
        return -1
    end

    return clamp_int(current_pair, 0, 63)
end

------------------------------------------------------------
-- Audio source / destination helpers
------------------------------------------------------------

function audio_src_offset(value)
    value = math.floor((tonumber(value) or 0) + 0.5)

    if value < 0 then
        return -1
    end

    return value & 1023
end

function audio_src_mode(value)
    value = math.floor((tonumber(value) or 0) + 0.5)

    if value < 0 then
        return 0
    end

    return value >> 10
end

function audio_dst_offset(value)
    value = math.floor((tonumber(value) or 0) + 0.5)

    return value & 1023
end

function audio_dst_mono(value)
    value = math.floor((tonumber(value) or 0) + 0.5)

    return (value & 1024) ~= 0
end

function audio_src_pair_index(value)
    local off = audio_src_offset(value)

    if off < 0 then
        return -1
    end

    return clamp_int(off / 2, 0, 63)
end

function audio_dst_pair_index(value)
    local off = audio_dst_offset(value)

    return clamp_int(off / 2, 0, 63)
end

function make_audio_src_value(pair_index, mode)
    pair_index = clamp_int(pair_index, 0, 63)
    mode = clamp_int(mode, 0, 8)

    return (pair_index * 2) | (mode << 10)
end

function make_audio_dst_value(pair_index, mono)
    pair_index = clamp_int(pair_index, 0, 63)

    local value = pair_index * 2

    if mono then
        value = value | 1024
    end

    return value
end

function format_audio_source(value)
    value = math.floor((tonumber(value) or 0) + 0.5)

    if value < 0 then
        return "None"
    end

    local pair = audio_src_pair_index(value)
    local mode = audio_src_mode(value)
    local pair_text = format_stereo_pair_from_zero_based(pair)

    if mode == 0 then
        return pair_text
    end

    if mode == 1 then
        return pair_text .. " mono"
    end

    return pair_text .. " " .. tostring(mode * 2) .. " channels"
end

function format_audio_destination(value)
    value = math.floor((tonumber(value) or 0) + 0.5)

    local pair = audio_dst_pair_index(value)
    local text = format_stereo_pair_from_zero_based(pair)

    if audio_dst_mono(value) then
        return text .. " mono"
    end

    return text
end

------------------------------------------------------------
-- MIDI flags helpers
------------------------------------------------------------

MIDI_SRC_CH_MASK  = 31
MIDI_DST_CH_MASK  = 31 << 5
MIDI_FADER_MASK   = 1024
MIDI_SRC_BUS_MASK = 255 << 14
MIDI_DST_BUS_MASK = 255 << 22

function midi_flags_int(v)
    return math.floor((tonumber(v) or 0) + 0.5)
end

function midi_flags_get_source_channel(flags)
    flags = midi_flags_int(flags)

    return flags & 31
end

function midi_flags_set_source_channel(flags, ch)
    flags = midi_flags_int(flags)
    ch = clamp_int(ch, 0, 31)

    flags = flags & (~MIDI_SRC_CH_MASK)
    flags = flags | ch

    return flags
end

function midi_flags_get_dest_channel(flags)
    flags = midi_flags_int(flags)

    return (flags >> 5) & 31
end

function midi_flags_set_dest_channel(flags, ch)
    flags = midi_flags_int(flags)
    ch = clamp_int(ch, 0, 16)

    flags = flags & (~MIDI_DST_CH_MASK)
    flags = flags | (ch << 5)

    return flags
end

function midi_flags_get_source_bus(flags)
    flags = midi_flags_int(flags)

    return (flags >> 14) & 255
end

function midi_flags_set_source_bus(flags, bus)
    flags = midi_flags_int(flags)
    bus = clamp_int(bus, 0, 255)

    flags = flags & (~MIDI_SRC_BUS_MASK)
    flags = flags | (bus << 14)

    return flags
end

function midi_flags_get_dest_bus(flags)
    flags = midi_flags_int(flags)

    return (flags >> 22) & 255
end

function midi_flags_set_dest_bus(flags, bus)
    flags = midi_flags_int(flags)
    bus = clamp_int(bus, 0, 255)

    flags = flags & (~MIDI_DST_BUS_MASK)
    flags = flags | (bus << 22)

    return flags
end

function midi_flags_get_fader_send(flags)
    flags = midi_flags_int(flags)

    return (flags & MIDI_FADER_MASK) ~= 0
end

function midi_flags_set_fader_send(flags, enabled)
    flags = midi_flags_int(flags)

    if enabled then
        return flags | MIDI_FADER_MASK
    end

    return flags & (~MIDI_FADER_MASK)
end

function midi_source_channel_to_name(ch)
    ch = clamp_int(ch, 0, 31)

    if ch == 31 then
        return "None"
    end

    if ch == 0 then
        return "All"
    end

    if ch >= 1 and ch <= 16 then
        return tostring(ch)
    end

    return tostring(ch)
end

function midi_destination_channel_to_name(ch)
    ch = clamp_int(ch, 0, 16)

    if ch == 0 then
        return "Original"
    end

    return tostring(ch)
end

function midi_bus_to_name(bus)
    bus = clamp_int(bus, 0, 255)

    if bus == 0 then
        return "All"
    end

    if bus == 1 then
        return "Normal"
    end

    return tostring(bus)
end

function midi_source_channel_to_norm(ch)
    ch = clamp_int(ch, 0, 31)

    if ch == 31 then
        return 1
    end

    ch = clamp_int(ch, 0, 16)

    return ch / 17
end

function midi_norm_to_source_channel(norm)
    norm = clamp01(norm)

    local v = clamp_int(norm * 17, 0, 17)

    if v >= 17 then
        return 31
    end

    return v
end

function midi_destination_channel_to_norm(ch)
    ch = clamp_int(ch, 0, 16)

    return ch / 16
end

function midi_norm_to_destination_channel(norm)
    norm = clamp01(norm)

    return clamp_int(norm * 16, 0, 16)
end

function midi_bus_to_norm(bus)
    bus = clamp_int(bus, 0, 16)

    return bus / 16
end

function midi_norm_to_bus(norm)
    norm = clamp01(norm)

    return clamp_int(norm * 16, 0, 16)
end

function midi_source_channel_step(ch, direction)
    ch = clamp_int(ch, 0, 31)
    direction = tonumber(direction) or 0

    local pos = ch

    if ch == 31 then
        pos = 17
    else
        pos = clamp_int(ch, 0, 16)
    end

    if direction > 0 then
        pos = pos + 1
    elseif direction < 0 then
        pos = pos - 1
    end

    pos = clamp_int(pos, 0, 17)

    if pos == 17 then
        return 31
    end

    return pos
end

function midi_destination_channel_step(ch, direction)
    ch = clamp_int(ch, 0, 16)
    direction = tonumber(direction) or 0

    if direction > 0 then
        ch = ch + 1
    elseif direction < 0 then
        ch = ch - 1
    end

    return clamp_int(ch, 0, 16)
end

function midi_bus_step(bus, direction)
    bus = clamp_int(bus, 0, 16)
    direction = tonumber(direction) or 0

    if direction > 0 then
        bus = bus + 1
    elseif direction < 0 then
        bus = bus - 1
    end

    return clamp_int(bus, 0, 16)
end

------------------------------------------------------------
-- Send type helpers
------------------------------------------------------------

function send_mode_to_name(mode)
    mode = clamp_int(mode, 0, 3)

    if mode == 0 then
        return "Post fader"
    end

    if mode == 1 then
        return "Pre FX"
    end

    if mode == 2 then
        return "Post FX deprecated"
    end

    if mode == 3 then
        return "Post FX"
    end

    return tostring(mode)
end

function send_mode_to_norm(mode)
    mode = clamp_int(mode, 0, 3)

    return mode / 3
end

function send_norm_to_mode(norm)
    norm = clamp01(norm)

    return clamp_int(norm * 3, 0, 3)
end

function send_mode_step(mode, direction)
    mode = clamp_int(mode, 0, 3)
    direction = tonumber(direction) or 0

    if direction > 0 then
        mode = mode + 1
    elseif direction < 0 then
        mode = mode - 1
    end

    return clamp_int(mode, 0, 3)
end


------------------------------------------------------------
-- 1.AUTO - HELPERS REALI ENVELOPE / AUTO
--
-- Auto significa envelope realmente attivo (ACT 1).
-- Quando spegniamo Auto, spegniamo anche VIS per liberare
-- il controllo e non lasciare un envelope nascosto che governa
-- il parametro.
------------------------------------------------------------

function auto_line_first_number(line_key, line)
    line_key = clean_one_line(line_key or "")
    line = tostring(line or "")

    if line_key == "" then
        return nil
    end

    local v = line:match("^%s*" .. line_key .. "%s+([^%s]+)")

    return tonumber(v)
end

function auto_chunk_block_first_number(block, key)
    block = tostring(block or "")
    key = clean_one_line(key or "")

    if block == "" or key == "" then
        return nil
    end

    for line in block:gmatch("[^\r\n]+") do
        local v = auto_line_first_number(key, line)

        if v ~= nil then
            return v
        end
    end

    return nil
end

function auto_chunk_block_is_active(block)
    local act = auto_chunk_block_first_number(block, "ACT")

    if act ~= nil then
        return act ~= 0
    end

    local vis = auto_chunk_block_first_number(block, "VIS")

    if vis ~= nil then
        return vis ~= 0
    end

    return false
end

function auto_chunk_lines_set_first_number(lines, start_i, end_i, key, value, default_tail)
    if start_i <= 0 or end_i <= 0 then
        return false
    end

    key = clean_one_line(key or "")
    value = tostring(value or "0")
    default_tail = clean_one_line(default_tail or "")

    if key == "" then
        return false
    end

    local found = false
    local changed = false
    local pattern = "^(%s*" .. key .. "%s+)(.*)$"

    for i = start_i + 1, end_i - 1 do
        local line = tostring(lines[i] or "")
        local prefix, rest = line:match(pattern)

        if prefix then
            local values = {}

            for token in tostring(rest or ""):gmatch("%S+") do
                values[#values + 1] = token
            end

            values[1] = value

            if #values == 1 and default_tail ~= "" then
                for token in default_tail:gmatch("%S+") do
                    values[#values + 1] = token
                end
            end

            local new_line = key .. " " .. table.concat(values, " ")

            if new_line ~= line then
                lines[i] = new_line
                changed = true
            end

            found = true
            break
        end
    end

    if not found then
        local line = key .. " " .. value

        if default_tail ~= "" then
            line = line .. " " .. default_tail
        end

        table.insert(lines, start_i + 1, line)
        changed = true
    end

    return changed
end

function auto_chunk_lines_set_active_visible(lines, start_i, end_i, active)
    active = active == true

    local changed = false

    if active then
        changed = auto_chunk_lines_set_first_number(lines, start_i, end_i, "ACT", "1", "-1") or changed
        changed = auto_chunk_lines_set_first_number(lines, start_i, end_i, "VIS", "1", "1 1") or changed
    else
        changed = auto_chunk_lines_set_first_number(lines, start_i, end_i, "VIS", "0", "1 1") or changed
        changed = auto_chunk_lines_set_first_number(lines, start_i, end_i, "ACT", "0", "-1") or changed
    end

    return changed
end

function auto_envelope_get_state(env)
    if not env then
        return nil
    end

    if reaper.GetSetEnvelopeState2 then
        local ok, retval, state =
            pcall(reaper.GetSetEnvelopeState2, 0, env, "", false)

        if ok then
            if type(retval) == "string" then
                return retval
            end

            if type(state) == "string" then
                return state
            end
        end
    end

    if reaper.GetSetEnvelopeState then
        local ok, retval, state =
            pcall(reaper.GetSetEnvelopeState, env, "", false)

        if ok then
            if type(retval) == "string" then
                return retval
            end

            if type(state) == "string" then
                return state
            end
        end
    end

    if reaper.GetEnvelopeStateChunk then
        local ok, state = pcall(reaper.GetEnvelopeStateChunk, env, "", false)

        if ok and type(state) == "string" then
            return state
        end
    end

    return nil
end

function auto_envelope_set_state(env, state)
    if not env or state == nil then
        return false
    end

    state = tostring(state or "")

    if reaper.GetSetEnvelopeState2 then
        local ok, retval =
            pcall(reaper.GetSetEnvelopeState2, 0, env, state, true)

        if ok and retval ~= false then
            return true
        end
    end

    if reaper.GetSetEnvelopeState then
        local ok, retval =
            pcall(reaper.GetSetEnvelopeState, env, state, true)

        if ok and retval ~= false then
            return true
        end
    end

    if reaper.SetEnvelopeStateChunk then
        local ok, retval =
            pcall(reaper.SetEnvelopeStateChunk, env, state, false)

        if ok and retval ~= false then
            return true
        end
    end

    return false
end

function auto_state_set_first_number(state, key, value, default_tail)
    state = tostring(state or "")
    key = clean_one_line(key or "")
    value = tostring(value or "0")
    default_tail = clean_one_line(default_tail or "")

    local lines = {}
    local found = false
    local pattern = "^%s*" .. key .. "%s+"

    for line in (state .. "\n"):gmatch("([^\n]*)\n") do
        line = line:gsub("\r$", "")

        if line:match(pattern) then
            local values = {}
            local rest = line:match(pattern .. "(.+)$") or ""

            for token in rest:gmatch("%S+") do
                values[#values + 1] = token
            end

            values[1] = value

            if #values == 1 and default_tail ~= "" then
                for token in default_tail:gmatch("%S+") do
                    values[#values + 1] = token
                end
            end

            lines[#lines + 1] = key .. " " .. table.concat(values, " ")
            found = true
        else
            lines[#lines + 1] = line
        end
    end

    if not found then
        local line = key .. " " .. value

        if default_tail ~= "" then
            line = line .. " " .. default_tail
        end

        lines[#lines + 1] = line
    end

    return table.concat(lines, "\n")
end

function auto_envelope_is_active(env)
    if not env then
        return false
    end

    local state = auto_envelope_get_state(env)

    if state ~= nil then
        return auto_chunk_block_is_active(state)
    end

    if reaper.GetEnvelopeInfo_Value then
        local ok, value = pcall(reaper.GetEnvelopeInfo_Value, env, "B_ACTIVE")

        if ok then
            return tonumber(value) == 1
        end
    end

    return false
end

function auto_envelope_set_active_visible(env, active)
    if not env then
        return false
    end

    active = active == true

    local state = auto_envelope_get_state(env)

    if state ~= nil then
        local new_state = state

        if active then
            new_state = auto_state_set_first_number(new_state, "ACT", "1", "-1")
            new_state = auto_state_set_first_number(new_state, "VIS", "1", "1 1")
        else
            new_state = auto_state_set_first_number(new_state, "VIS", "0", "1 1")
            new_state = auto_state_set_first_number(new_state, "ACT", "0", "-1")
        end

        if auto_envelope_set_state(env, new_state) then
            return true
        end
    end

    local ok_any = false

    if reaper.SetEnvelopeInfo_Value then
        local ok_visible =
            pcall(reaper.SetEnvelopeInfo_Value, env, "B_VISIBLE", active and 1 or 0)

        local ok_active =
            pcall(reaper.SetEnvelopeInfo_Value, env, "B_ACTIVE", active and 1 or 0)

        ok_any = ok_visible or ok_active
    end

    return ok_any == true
end


------------------------------------------------------------
-- 1.4 - KEYCODES
------------------------------------------------------------

KEY_ESC = 27

KEY_BACKSPACE   = 8
KEY_BACKSPACE_2 = 127

KEY_UP        = 30064
KEY_DOWN      = 1685026670
KEY_LEFT      = 1818584692
KEY_RIGHT     = 1919379572
KEY_HOME      = 1752132965
KEY_END       = 6647396
KEY_PAGE_UP   = 1885828464
KEY_PAGE_DOWN = 1885824110
KEY_ENTER     = 13
KEY_TAB       = 9
KEY_DELETE    = 6579564
KEY_BACKSLASH = 92
KEY_SPACE     = 32
KEY_A         = 65
KEY_C         = 67
KEY_CTRL_ALT_A  = 257
KEY_CTRL_ALT_C  = 259
KEY_ALT_I       = 329

KEY_CTRL_A = 1
KEY_CTRL_B = 2
KEY_CTRL_C = 3
KEY_CTRL_D = 4
KEY_CTRL_E = 5
KEY_CTRL_F = 6
KEY_CTRL_H = 8
KEY_CTRL_I = 9
KEY_CTRL_J = 10
KEY_CTRL_O = 15
KEY_CTRL_M = 13
KEY_CTRL_R = 18
KEY_CTRL_S = 19
KEY_CTRL_V = 22
KEY_CTRL_X = 24
KEY_CTRL_P = 16
KEY_CTRL_Q = 17
KEY_CTRL_Z = 26

KEY_F1  = 26161
KEY_F2  = 26162
KEY_F3  = 26163
KEY_F4  = 26164
KEY_F5  = 26165
KEY_F6  = 26166
KEY_F7  = 26167
KEY_F8  = 26168
KEY_F9  = 26169
KEY_F10 = 6697264
KEY_F11 = 6697265
KEY_F12 = 6697266

MOD_CTRL  = 4
MOD_SHIFT = 8
MOD_ALT   = 16

function ctrl_down()
    return (gfx.mouse_cap & MOD_CTRL) == MOD_CTRL
end

function shift_down()
    return (gfx.mouse_cap & MOD_SHIFT) == MOD_SHIFT
end

function alt_down()
    return (gfx.mouse_cap & MOD_ALT) == MOD_ALT
end

------------------------------------------------------------
-- 1.4.1 - MODIFIER DA GFX + JS_ReaScriptAPI
--
-- Alcuni tasti, soprattutto Shift+Spazio e Ctrl+numero,
-- possono non arrivare in modo affidabile da gfx.getchar().
-- Quando JS_ReaScriptAPI è disponibile, leggiamo anche lo
-- stato reale dei virtual keys. Se non c'è, resta il metodo gfx.
------------------------------------------------------------

function js_vkeys_state_now()
    if type(reaper.JS_VKeys_GetState) ~= "function" then
        return ""
    end

    return reaper.JS_VKeys_GetState(-2) or ""
end

function js_vkey_down_now(vk)
    local state = js_vkeys_state_now()

    if state == "" then
        return false
    end

    return (state:byte(tonumber(vk) or 0) or 0) ~= 0
end

function ctrl_down_any()
    return ctrl_down() or js_vkey_down_now(0x11)
end

function shift_down_any()
    return shift_down() or js_vkey_down_now(0x10)
end

function alt_down_any()
    return alt_down() or js_vkey_down_now(0x12)
end

VK_TAB   = 0x09
VK_SPACE = 0x20
VK_I     = 0x49

------------------------------------------------------------
-- Ctrl+M reale distinto da Enter / Ctrl+Enter.
--
-- In gfx.getchar, Ctrl+M e Enter possono arrivare entrambi
-- come codice 13. Per la memoria di posizione usiamo quindi
-- anche JS_VKeys_GetState e controlliamo il tasto fisico M.
--
-- Nel nostro ambiente JS_VKeys_GetState viene letto come nello
-- script funzionante dei marker: state:byte(VK), non VK + 1.
------------------------------------------------------------

VK_PHYSICAL_ENTER = 0x0D
VK_PHYSICAL_M     = 0x4D

function js_physical_m_down()
    return js_vkey_down_now(VK_PHYSICAL_M)
end

function js_physical_enter_down()
    return js_vkey_down_now(VK_PHYSICAL_ENTER)
end

function real_ctrl_m_key(char)
    return char == KEY_CTRL_M and
           ctrl_down_any() and
           not shift_down_any() and
           not alt_down_any() and
           js_physical_m_down() and
           not js_physical_enter_down()
end

function ctrl_a_key(char)
    return char == KEY_CTRL_A or char == KEY_A
end

function ctrl_alt_a_key(char)
    return char == KEY_CTRL_ALT_A
end

function automation_clear_shortcut_key(char)
    local is_ctrl = ctrl_down_any()
    local is_shift = shift_down_any()
    local is_alt = alt_down_any()

    --------------------------------------------------------
    -- Ctrl+Shift+Alt+A.
    -- Accettiamo sia Ctrl+A con i modifier reali, sia il codice
    -- 257 quando Shift risulta premuto. Non usiamo più
    -- Ctrl+Alt+A, perché quella combinazione resta libera.
    --------------------------------------------------------

    if is_ctrl and is_shift and is_alt then
        if ctrl_a_key(char) or ctrl_alt_a_key(char) then
            return true
        end
    end

    return false
end

------------------------------------------------------------
-- 1.5 - COMANDI REAPER UTILI
------------------------------------------------------------

CMD_PLAY_STOP  = 40044
CMD_PLAY_PAUSE = 40073

CMD_UNDO = 40029
CMD_REDO = 40030

CMD_ITEM_NEXT = 40417
CMD_ITEM_PREVIOUS = 40416

CMD_SHOW_HIDE_ENV_LAST_TOUCHED_PARAM = 41142
CMD_SELECT_TRACK_WIDTH_ENVELOPE = 41870
CMD_TOGGLE_SELECTED_ENVELOPE_VISIBLE = 40884

CMD_CURSOR_FORWARD_MEASURE = 41042
CMD_CURSOR_BACK_MEASURE    = 41043
CMD_CURSOR_FORWARD_BEAT    = 41044
CMD_CURSOR_BACK_BEAT       = 41045
CMD_CURSOR_NEXT_MEASURE_START = 41040
CMD_CURSOR_CURRENT_PREVIOUS_MEASURE_START = 41041

------------------------------------------------------------
-- 1.6 - STATO GLOBALE PRINCIPALE
------------------------------------------------------------

SCRIPT_NAME = "Speak Track Params - TrackTake Navigator"
SCRIPT_VERSION = "0.184"

title = SCRIPT_NAME
mode = "grid"

current_section_id = "tracks"
current_section_key = KEY_F1

track_index = 0
track_count = 0
current_track = nil
current_track_guid = ""

grid_pos = 1
grid_size = 9
grid_entries = {}

------------------------------------------------------------
-- 1.6.0 - SESSION TRACK MEMORIES
--
-- Memorie temporanee di traccia:
-- - vivono per tutta la sessione di REAPER;
-- - restano disponibili anche se lo script viene chiuso e riaperto;
-- - spariscono quando REAPER viene chiuso;
-- - usano ExtState non persistente: persist=false;
-- - non scrivono TXT, non scrivono file, non scrivono nel progetto;
-- - sono attive solo in F1 Tracks e F4 FX parameters griglia.
--
-- Ctrl+F1 ... Ctrl+F12:
--   richiama una memoria traccia.
--
-- Ctrl+Shift+F1 ... Ctrl+Shift+F12:
--   salva la traccia corrente nello slot.
--
-- Delete subito dopo una memoria:
--   cancella quello slot.
------------------------------------------------------------

track_memory_slots = {}
track_memory_delete_armed_slot = nil

TRACK_MEMORY_EXT_SECTION = "LoLo_SpeakTrackParams_Runtime"
TRACK_MEMORY_EXT_PREFIX  = "track_memory_slot_"

function track_memory_ext_key(slot)
    slot = clamp_int(slot, 1, 12)
    return TRACK_MEMORY_EXT_PREFIX .. tostring(slot)
end

function track_memory_escape(s)
    s = tostring(s or "")
    s = s:gsub("%%", "%%%%")
    s = s:gsub("|", "%%p")
    s = s:gsub("\r", "%%r")
    s = s:gsub("\n", "%%n")
    return s
end

function track_memory_unescape(s)
    s = tostring(s or "")
    s = s:gsub("%%n", "\n")
    s = s:gsub("%%r", "\r")
    s = s:gsub("%%p", "|")
    s = s:gsub("%%%%", "%%")
    return s
end

function track_memory_encode(mem)
    if not mem or clean_one_line(mem.guid or "") == "" then
        return ""
    end

    return table.concat({
        track_memory_escape(mem.guid or ""),
        track_memory_escape(mem.name or ""),
        tostring(tonumber(mem.number) or 0)
    }, "|")
end

function track_memory_decode(txt)
    txt = tostring(txt or "")

    if txt == "" then
        return nil
    end

    local guid, name, number = txt:match("^([^|]*)|([^|]*)|(.*)$")

    guid = track_memory_unescape(guid or "")
    name = track_memory_unescape(name or "")
    number = tonumber(number) or 0

    if clean_one_line(guid) == "" then
        return nil
    end

    return {
        guid = clean_one_line(guid),
        name = clean_one_line(name),
        number = number
    }
end

function track_memory_save_session_slot(slot)
    if not reaper.SetExtState then
        return false
    end

    slot = clamp_int(slot, 1, 12)

    local txt = track_memory_encode(track_memory_slots[slot])

    reaper.SetExtState(
        TRACK_MEMORY_EXT_SECTION,
        track_memory_ext_key(slot),
        txt,
        false -- sessione REAPER soltanto: niente salvataggio su disco
    )

    return true
end

function track_memory_load_session()
    track_memory_slots = {}

    if not reaper.GetExtState then
        return false
    end

    for slot = 1, 12 do
        local txt = reaper.GetExtState(
            TRACK_MEMORY_EXT_SECTION,
            track_memory_ext_key(slot)
        )

        local mem = track_memory_decode(txt)

        if mem then
            track_memory_slots[slot] = mem
        end
    end

    track_memory_delete_armed_slot = nil

    return true
end

function track_memory_clear_session_slot(slot)
    if not reaper.SetExtState then
        return false
    end

    slot = clamp_int(slot, 1, 12)

    reaper.SetExtState(
        TRACK_MEMORY_EXT_SECTION,
        track_memory_ext_key(slot),
        "",
        false
    )

    return true
end


------------------------------------------------------------
-- 1.6.0B - SESSION CURSOR MEMORY
--
-- Memoria temporanea della posizione logica del cursore:
-- - vive solo per la sessione di REAPER;
-- - usa ExtState non persistente: persist=false;
-- - non scrive TXT, file o progetto;
-- - è disattivata di default;
-- - si attiva / disattiva con Ctrl+M;
-- - ricorda la sezione e il campo logico dove eri;
-- - se la traccia cambia, prova a mantenere lo stesso campo
--   equivalente: per esempio Pan resta Pan sulla nuova traccia.
------------------------------------------------------------

cursor_memory_slots = {}
cursor_memory_last_section_id = SECTION_TRACKS or "tracks"
cursor_memory_enabled = false

CURSOR_MEMORY_EXT_SECTION = "LoLo_SpeakTrackParams_Runtime"
CURSOR_MEMORY_EXT_PREFIX  = "cursor_memory_"
CURSOR_MEMORY_LAST_KEY    = "cursor_memory_last_section"
CURSOR_MEMORY_ENABLED_KEY = "cursor_memory_enabled"

function cursor_memory_section_key(section_id)
    section_id = clean_one_line(section_id or "")

    if section_id == "" then
        section_id = SECTION_TRACKS or "tracks"
    end

    return CURSOR_MEMORY_EXT_PREFIX .. section_id
end

function cursor_memory_is_enabled()
    return cursor_memory_enabled == true
end

function cursor_memory_write_enabled()
    if not reaper.SetExtState then
        return false
    end

    reaper.SetExtState(
        CURSOR_MEMORY_EXT_SECTION,
        CURSOR_MEMORY_ENABLED_KEY,
        cursor_memory_enabled and "1" or "0",
        false
    )

    return true
end

function cursor_memory_toggle_enabled()
    cursor_memory_enabled = not cursor_memory_enabled
    cursor_memory_write_enabled()

    if cursor_memory_enabled then
        cursor_memory_save_current()
        speak("Position memory on")
    else
        speak("Position memory off")
    end

    return true
end

function cursor_memory_encode(mem)
    if not mem then
        return ""
    end

    return table.concat({
        track_memory_escape(mem.section_id or ""),
        track_memory_escape(mem.track_guid or ""),
        tostring(tonumber(mem.grid_pos) or 1),
        tostring(tonumber(mem.row) or 1),
        tostring(tonumber(mem.col) or 1),
        track_memory_escape(mem.kind or ""),
        tostring(tonumber(mem.category) or 999),
        tostring(tonumber(mem.send_index) or -1),
        tostring(tonumber(mem.fx_index) or -1),
        tostring(tonumber(mem.param_index) or -1),
        track_memory_escape(mem.entry_id or "")
    }, "|")
end

function cursor_memory_decode(txt)
    txt = tostring(txt or "")

    if txt == "" then
        return nil
    end

    local parts = {}

    for part in (txt .. "|"):gmatch("(.-)|") do
        parts[#parts + 1] = part
    end

    if #parts < 11 then
        return nil
    end

    local section_id = clean_one_line(track_memory_unescape(parts[1] or ""))

    if section_id == "" then
        return nil
    end

    return {
        section_id = section_id,
        track_guid = clean_one_line(track_memory_unescape(parts[2] or "")),
        grid_pos = clamp_int(parts[3], 1, 1000000),
        row = clamp_int(parts[4], 1, 1000000),
        col = clamp_int(parts[5], 1, 1000000),
        kind = clean_one_line(track_memory_unescape(parts[6] or "")),
        category = tonumber(parts[7]) or 999,
        send_index = tonumber(parts[8]) or -1,
        fx_index = tonumber(parts[9]) or -1,
        param_index = tonumber(parts[10]) or -1,
        entry_id = clean_one_line(track_memory_unescape(parts[11] or ""))
    }
end

function cursor_memory_load_session()
    cursor_memory_slots = {}
    cursor_memory_last_section_id = SECTION_TRACKS
    cursor_memory_enabled = false

    if not reaper.GetExtState then
        return false
    end

    local enabled_txt = clean_one_line(
        reaper.GetExtState(CURSOR_MEMORY_EXT_SECTION, CURSOR_MEMORY_ENABLED_KEY)
    )

    cursor_memory_enabled = enabled_txt == "1"

    local last = clean_one_line(
        reaper.GetExtState(CURSOR_MEMORY_EXT_SECTION, CURSOR_MEMORY_LAST_KEY)
    )

    if last ~= "" then
        cursor_memory_last_section_id = last
    end

    local ids = {
        SECTION_TRACKS,
        SECTION_SENDS,
        SECTION_RECEIVES,
        SECTION_FX_PARAMS,
        PIN_AUDIO_SECTION_ID,
        PIN_MIDI_SECTION_ID,
        HARDWARE_OUTPUT_SECTION_ID,
        REAROUTE_SECTION_ID
    }

    for i = 1, #ids do
        local section_id = ids[i]
        local txt = reaper.GetExtState(
            CURSOR_MEMORY_EXT_SECTION,
            cursor_memory_section_key(section_id)
        )

        local mem = cursor_memory_decode(txt)

        if mem then
            cursor_memory_slots[section_id] = mem
        end
    end

    return true
end

function cursor_memory_write_section(section_id)
    if not reaper.SetExtState then
        return false
    end

    section_id = clean_one_line(section_id or "")

    if section_id == "" then
        return false
    end

    local txt = cursor_memory_encode(cursor_memory_slots[section_id])

    reaper.SetExtState(
        CURSOR_MEMORY_EXT_SECTION,
        cursor_memory_section_key(section_id),
        txt,
        false
    )

    return true
end

function cursor_memory_write_last_section(section_id)
    if not reaper.SetExtState then
        return false
    end

    section_id = clean_one_line(section_id or "")

    if section_id == "" then
        return false
    end

    cursor_memory_last_section_id = section_id

    reaper.SetExtState(
        CURSOR_MEMORY_EXT_SECTION,
        CURSOR_MEMORY_LAST_KEY,
        section_id,
        false
    )

    return true
end

function cursor_memory_make_current()
    if mode ~= "grid" and
       mode ~= "pin_audio" and
       mode ~= "pin_midi" then
        return nil
    end

    if current_section_id == FX_PARAM_LIST_SECTION_ID then
        return nil
    end

    local e = get_current_entry()
    local row, col = grid_current_row_col()
    local tr = nil

    if e and e.track then
        tr = e.track
    else
        tr = current_track
    end

    local guid = ""

    if tr then
        guid = get_track_guid(tr)
    end

    return {
        section_id = current_section_id,
        track_guid = guid,
        grid_pos = grid_pos,
        row = row,
        col = col,
        kind = e and clean_one_line(e.kind or e.id or "") or "",
        category = e and tonumber(e.category) or 999,
        send_index = e and tonumber(e.send_index) or -1,
        fx_index = e and tonumber(e.fx_index) or -1,
        param_index = e and tonumber(e.param_index) or -1,
        entry_id = e and clean_one_line(e.id or "") or ""
    }
end

function cursor_memory_save_current()
    if not cursor_memory_is_enabled() then
        return false
    end

    local mem = cursor_memory_make_current()

    if not mem then
        return false
    end

    cursor_memory_slots[mem.section_id] = mem
    cursor_memory_write_section(mem.section_id)
    cursor_memory_write_last_section(mem.section_id)

    return true
end

function cursor_memory_find_track_by_guid(guid)
    guid = clean_one_line(guid or "")

    if guid == "" then
        return nil
    end

    local count = get_project_track_count()

    for i = 0, count - 1 do
        local tr = get_track_by_index(i)

        if tr and get_track_guid(tr) == guid then
            return tr
        end
    end

    return nil
end

function cursor_memory_prepare_section_before_build(section_id, prefer_current_track)
    if not cursor_memory_is_enabled() then
        return false
    end

    section_id = clean_one_line(section_id or current_section_id)

    local mem = cursor_memory_slots[section_id]

    if not mem then
        return false
    end

    if section_id == SECTION_TRACKS then
        local wanted_col = clamp_int(mem.col, 1, TRACK_BASE_GRID_SIZE)
        grid_pos = wanted_col

        if not prefer_current_track then
            local tr = cursor_memory_find_track_by_guid(mem.track_guid)

            if tr and track_is_tcp_visible(tr) then
                open_parent_folders_for_track(tr)
                set_current_track_pointer_only(tr)
            end
        end

        return true
    end

    if section_id == SECTION_SENDS then
        ----------------------------------------------------
        -- In F2 ogni send è un blocco verticale da 12 voci.
        -- La posizione logica del campo è la colonna interna
        -- della griglia, non la riga assoluta del blocco.
        ----------------------------------------------------
        local field = clamp_int(mem.col, 1, SEND_GRID_SIZE)
        local send_index = math.max(0, tonumber(mem.send_index) or 0)
        grid_pos = (send_index * SEND_GRID_SIZE) + field
        return true
    end

    if section_id == SECTION_RECEIVES then
        ----------------------------------------------------
        -- Stessa logica di F2: resta sullo stesso campo
        -- interno, per esempio Pan, Audio destination, ecc.
        ----------------------------------------------------
        local field = clamp_int(mem.col, 1, RECEIVE_GRID_SIZE)
        local receive_index = math.max(0, tonumber(mem.send_index) or 0)
        grid_pos = (receive_index * RECEIVE_GRID_SIZE) + field
        return true
    end

    if section_id == HARDWARE_OUTPUT_SECTION_ID then
        local field = clamp_int(mem.col, 1, HARDWARE_OUTPUT_GRID_SIZE)
        local output_index = math.max(0, tonumber(mem.send_index) or 0)
        grid_pos = (output_index * HARDWARE_OUTPUT_GRID_SIZE) + field
        return true
    end

    if section_id == REAROUTE_SECTION_ID then
        local field = clamp_int(mem.col, 1, REAROUTE_GRID_SIZE)
        local output_index = math.max(0, tonumber(mem.send_index) or 0)
        grid_pos = (output_index * REAROUTE_GRID_SIZE) + field
        return true
    end

    if section_id == SECTION_FX_PARAMS then
        grid_pos = clamp_int(mem.grid_pos, 1, 1000000)
        return true
    end

    if section_id == PIN_AUDIO_SECTION_ID or
       section_id == PIN_MIDI_SECTION_ID then
        grid_pos = clamp_int(mem.grid_pos, 1, 1000000)
        return true
    end

    return false
end

function cursor_memory_restore_f1(mem, prefer_current_track)
    if not mem then
        return false
    end

    local wanted_col = clamp_int(mem.col, 1, TRACK_BASE_GRID_SIZE)
    local tr = nil

    if not prefer_current_track then
        tr = cursor_memory_find_track_by_guid(mem.track_guid)
    end

    if tr then
        open_parent_folders_for_track(tr)
        set_current_track_pointer_only(tr)
    else
        tr = current_track
    end

    if tr then
        local row = get_row_for_track_in_current_grid(tr)

        if row > 0 then
            grid_pos = grid_pos_from_row_col(row, wanted_col)
            set_current_track_pointer_only(tr)
            return true
        end
    end

    grid_pos = grid_pos_from_row_col(grid_current_row_col(), wanted_col)
    grid_pos = clamp_int(grid_pos, 1, math.max(1, #grid_entries))

    local e = get_current_entry()

    if e and e.track then
        set_current_track_pointer_only(e.track)
    end

    return true
end

function cursor_memory_restore_send_receive(mem, grid_block_size)
    if not mem then
        return false
    end

    --------------------------------------------------------
    -- F2/F3 non devono ripartire sempre dall'header.
    -- Con grid_size 12, la posizione del campo dentro il
    -- send/receive è la colonna calcolata dalla griglia.
    -- La riga invece indica quale blocco/send era visibile.
    --------------------------------------------------------
    local field = clamp_int(mem.col, 1, grid_block_size)
    local index = 0

    if mem.track_guid ~= "" and mem.track_guid == current_track_guid then
        index = math.max(0, tonumber(mem.send_index) or 0)
    end

    local pos = (index * grid_block_size) + field

    if pos > #grid_entries then
        pos = field
    end

    grid_pos = clamp_int(pos, 1, math.max(1, #grid_entries))

    return true
end

function cursor_memory_find_f4_entry(mem)
    if not mem then
        return 0
    end

    local same_track = mem.track_guid ~= "" and mem.track_guid == current_track_guid

    if same_track then
        for pos = 1, #grid_entries do
            local e = grid_entries[pos]

            if e and tonumber(e.fx_index) == tonumber(mem.fx_index) then
                if mem.kind == "fx_param" and
                   e.kind == "fx_param" and
                   tonumber(e.param_index) == tonumber(mem.param_index) then
                    return pos
                end

                if mem.kind == "fx_header" and e.kind == "fx_header" then
                    return pos
                end
            end
        end
    end

    local wanted_pos = clamp_int(mem.grid_pos, 1, math.max(1, #grid_entries))
    return wanted_pos
end

function cursor_memory_restore_after_build(section_id, prefer_current_track)
    if not cursor_memory_is_enabled() then
        grid_pos = clamp_int(grid_pos, 1, math.max(1, #grid_entries))
        return false
    end

    section_id = clean_one_line(section_id or current_section_id)

    local mem = cursor_memory_slots[section_id]

    if not mem or #grid_entries <= 0 then
        grid_pos = clamp_int(grid_pos, 1, math.max(1, #grid_entries))
        return false
    end

    if section_id == SECTION_TRACKS then
        return cursor_memory_restore_f1(mem, prefer_current_track)
    end

    if section_id == SECTION_SENDS then
        return cursor_memory_restore_send_receive(mem, SEND_GRID_SIZE)
    end

    if section_id == SECTION_RECEIVES then
        return cursor_memory_restore_send_receive(mem, RECEIVE_GRID_SIZE)
    end

    if section_id == HARDWARE_OUTPUT_SECTION_ID then
        return cursor_memory_restore_send_receive(mem, HARDWARE_OUTPUT_GRID_SIZE)
    end

    if section_id == REAROUTE_SECTION_ID then
        return cursor_memory_restore_send_receive(mem, REAROUTE_GRID_SIZE)
    end

    if section_id == SECTION_FX_PARAMS then
        grid_pos = cursor_memory_find_f4_entry(mem)
        grid_pos = clamp_int(grid_pos, 1, math.max(1, #grid_entries))
        return true
    end

    if section_id == PIN_AUDIO_SECTION_ID or
       section_id == PIN_MIDI_SECTION_ID then
        grid_pos = clamp_int(mem.grid_pos, 1, math.max(1, #grid_entries))
        return true
    end

    grid_pos = clamp_int(grid_pos, 1, math.max(1, #grid_entries))

    return false
end

function cursor_memory_section_id_to_key(section_id)
    if section_id == SECTION_SENDS then
        return KEY_F2
    end

    if section_id == SECTION_RECEIVES then
        return KEY_F3
    end

    if section_id == SECTION_FX_PARAMS then
        return KEY_F4
    end

    if section_id == PIN_AUDIO_SECTION_ID then
        return KEY_F5
    end

    if section_id == PIN_MIDI_SECTION_ID then
        return KEY_F6
    end

    if section_id == HARDWARE_OUTPUT_SECTION_ID then
        return KEY_F7
    end

    if section_id == REAROUTE_SECTION_ID then
        return KEY_F8
    end

    return KEY_F1
end


------------------------------------------------------------
-- 1.6.0C - TITOLI INVISIBILI OPZIONALI
--
-- Ctrl+Shift+M:
--   attiva / disattiva i titoli dettagliati della piccola
--   finestra gfx.
--
-- Quando sono attivi, il titolo contiene script e sezione.
-- Quando sono disattivati, il titolo resta stabile e corto:
-- solo il nome dello script. Così lo screen reader tende a
-- leggere solo i messaggi utili dello script, senza sovrapporre
-- il titolo invisibile.
--
-- Stato solo sessione REAPER: ExtState persist=false.
------------------------------------------------------------

title_detail_enabled = true

TITLE_DETAIL_EXT_SECTION = "LoLo_SpeakTrackParams_Runtime"
TITLE_DETAIL_ENABLED_KEY = "title_detail_enabled"

function title_detail_is_enabled()
    return title_detail_enabled == true
end

function title_detail_write_enabled()
    if not reaper.SetExtState then
        return false
    end

    reaper.SetExtState(
        TITLE_DETAIL_EXT_SECTION,
        TITLE_DETAIL_ENABLED_KEY,
        title_detail_enabled and "1" or "0",
        false
    )

    return true
end

function title_detail_load_session()
    title_detail_enabled = true

    if not reaper.GetExtState then
        return false
    end

    local txt = clean_one_line(
        reaper.GetExtState(TITLE_DETAIL_EXT_SECTION, TITLE_DETAIL_ENABLED_KEY)
    )

    if txt == "0" then
        title_detail_enabled = false
    end

    return true
end

function title_detail_toggle_enabled()
    title_detail_enabled = not title_detail_enabled
    title_detail_write_enabled()
    refresh_window_title()

    if title_detail_enabled then
        speak("Titles on")
    else
        speak("Titles off")
    end

    return true
end

------------------------------------------------------------
-- 1.6.0A - STATO RUNTIME PER PARLATO SEND / RECEIVE
--
-- Serve solo per capire da quale colonna arrivava il cursore.
-- Non viene salvato su disco.
------------------------------------------------------------

last_grid_move_old_pos = 0
last_grid_move_new_pos = 0
last_grid_move_kind = ""

------------------------------------------------------------
-- 1.6.0 - STATO RUNTIME ADD SEND / ADD RECEIVE
------------------------------------------------------------

routing_pending_active = false
routing_pending_kind = ""
routing_pending_tracks = {}
routing_pending_guids = {}

function routing_pending_reset()
    routing_pending_active = false
    routing_pending_kind = ""
    routing_pending_tracks = {}
    routing_pending_guids = {}
end

function routing_pending_is_active()
    return routing_pending_active == true
end

function routing_pending_count()
    return #routing_pending_tracks
end

function routing_pending_kind_name()
    if routing_pending_kind == "send" then
        return "Add send"
    end

    if routing_pending_kind == "receive" then
        return "Add receive"
    end

    return "Routing"
end

function routing_pending_stored_role_name()
    if routing_pending_kind == "send" then
        return "source tracks"
    end

    if routing_pending_kind == "receive" then
        return "destination tracks"
    end

    return "tracks"
end

function routing_pending_waiting_role_name()
    if routing_pending_kind == "send" then
        return "destination tracks"
    end

    if routing_pending_kind == "receive" then
        return "source tracks"
    end

    return "tracks"
end

function routing_pending_confirm_shortcut_name()
    if routing_pending_kind == "send" then
        return "Ctrl Shift S"
    end

    if routing_pending_kind == "receive" then
        return "Ctrl Shift R"
    end

    return "shortcut"
end

function routing_pending_status_message()
    if not routing_pending_is_active() then
        return ""
    end

    return
        routing_pending_kind_name() ..
        " pending. " ..
        tostring(routing_pending_count()) ..
        " " ..
        routing_pending_stored_role_name() ..
        " stored. Select " ..
        routing_pending_waiting_role_name() ..
        ", then press " ..
        routing_pending_confirm_shortcut_name() ..
        "."
end

function speak_routing_pending_status()
    local msg = routing_pending_status_message()

    if msg ~= "" then
        speak(msg)
        return true
    end

    return false
end

function routing_pending_cancel()
    if not routing_pending_is_active() then
        return false
    end

    local name = routing_pending_kind_name()

    routing_pending_reset()

    speak(name .. " cancelled")

    return true
end

------------------------------------------------------------
-- 1.6.1 - SELEZIONE TRACCE F1
------------------------------------------------------------

track_selection_stroke_active = false
track_selection_anchor_row = 0
track_selection_base_guids = {}
track_selection_mode = "add"

------------------------------------------------------------
-- Ciclo Ctrl+Enter sulle tracce che chiudono una o più folder.
------------------------------------------------------------

end_folder_cycle_track_guid = ""
end_folder_cycle_index = 1

function track_selection_reset_stroke()
    track_selection_stroke_active = false
    track_selection_anchor_row = 0
    track_selection_base_guids = {}
    track_selection_mode = "add"
end

function track_guid_selected_map()
    local map = {}
    local count = reaper.CountSelectedTracks(0) or 0

    for i = 0, count - 1 do
        local tr = reaper.GetSelectedTrack(0, i)

        if tr then
            local guid = get_track_guid(tr)

            if guid ~= "" then
                map[guid] = true
            end
        end
    end

    return map
end

function apply_track_guid_selection_map(map)
    map = map or {}

    local count = get_project_track_count()

    for i = 0, count - 1 do
        local tr = get_track_by_index(i)

        if tr then
            local guid = get_track_guid(tr)
            reaper.SetTrackSelected(tr, guid ~= "" and map[guid] == true)
        end
    end

    reaper.TrackList_AdjustWindows(false)
    reaper.UpdateArrange()
end

function get_visible_track_by_row(row)
    row = tonumber(row) or 1

    local visible_tracks = build_folder_aware_visible_track_list()

    if row < 1 or row > #visible_tracks then
        return nil
    end

    local item = visible_tracks[row]

    if item then
        return item.track
    end

    return nil
end

function get_row_for_track_in_current_grid(track)
    if not track then
        return 0
    end

    local wanted_guid = get_track_guid(track)

    if wanted_guid == "" then
        return 0
    end

    local rows = grid_row_count()

    for row = 1, rows do
        local pos = grid_pos_from_row_col(row, 1)
        local e = grid_entries[pos]

        if e and e.track and get_track_guid(e.track) == wanted_guid then
            return row
        end
    end

    return 0
end

function selected_track_count()
    return reaper.CountSelectedTracks(0) or 0
end

function selected_track_prefix()
    local count = selected_track_count()

    if count > 0 then
        return tostring(count) .. " Selected. "
    end

    return ""
end

function track_is_selected(track)
    if not track then
        return false
    end

    if reaper.IsTrackSelected then
        return reaper.IsTrackSelected(track) == true
    end

    local wanted_guid = get_track_guid(track)

    if wanted_guid == "" then
        return false
    end

    local count = reaper.CountSelectedTracks(0) or 0

    for i = 0, count - 1 do
        local tr = reaper.GetSelectedTrack(0, i)

        if tr and get_track_guid(tr) == wanted_guid then
            return true
        end
    end

    return false
end

function current_row_track_is_selected()
    local e = get_current_entry()

    if e and e.track then
        return track_is_selected(e.track)
    end

    return false
end

function current_track_selection_prefix(entry)
    if current_section_id ~= SECTION_TRACKS then
        return ""
    end

    entry = entry or get_current_entry()

    if entry and entry.track and track_is_selected(entry.track) then
        return "Selected. "
    end

    return ""
end

function entry_track_selected_prefix(entry)
    if current_section_id ~= SECTION_TRACKS then
        return ""
    end

    if not entry or not entry.track then
        return ""
    end

    if track_is_selected(entry.track) then
        return "Selected. "
    end

    return ""
end

function current_entry_track_selected_prefix()
    return entry_track_selected_prefix(get_current_entry())
end

function speak_track_selection_count_with_current_entry()
    speak(
        tostring(selected_track_count()) ..
        " Selected. " ..
        current_track_selection_prefix(get_current_entry()) ..
        get_entry_spoken_label(get_current_entry())
    )
end

function set_current_track_pointer_only(track)
    if not track then
        return false
    end

    current_track = track
    current_track_guid = get_track_guid(track)

    local n = get_track_number(track)

    if n > 0 then
        track_index = n - 1
    end

    return true
end

function select_current_track_if_no_selection()
    if selected_track_count() > 0 then
        return true
    end

    local e = get_current_entry()
    local tr = e and e.track or current_track

    if not tr then
        return false
    end

    reaper.SetOnlyTrackSelected(tr)
    return true
end

function clear_track_selection()
    track_selection_reset_stroke()

    local count = get_project_track_count()

    for i = 0, count - 1 do
        local tr = get_track_by_index(i)

        if tr then
            reaper.SetTrackSelected(tr, false)
        end
    end

    reaper.TrackList_AdjustWindows(false)
    reaper.UpdateArrange()

    speak("0 Selected")

    return true
end

function clear_track_selection_silent()
    track_selection_reset_stroke()

    local count = get_project_track_count()

    for i = 0, count - 1 do
        local tr = get_track_by_index(i)

        if tr then
            reaper.SetTrackSelected(tr, false)
        end
    end

    reaper.TrackList_AdjustWindows(false)
    reaper.UpdateArrange()

    return true
end

function select_all_visible_tracks_f1()
    if current_section_id ~= SECTION_TRACKS then
        return false
    end

    track_selection_reset_stroke()

    local visible_tracks = build_folder_aware_visible_track_list()

    for i = 1, #visible_tracks do
        local item = visible_tracks[i]

        if item and item.track then
            reaper.SetTrackSelected(item.track, true)
        end
    end

    reaper.TrackList_AdjustWindows(false)
    reaper.UpdateArrange()

    speak(tostring(selected_track_count()) .. " Selected")

    return true
end

function select_current_cursor_track_f1()
    if current_section_id ~= SECTION_TRACKS then
        return false
    end

    track_selection_reset_stroke()

    local e = get_current_entry()
    local tr = e and e.track or current_track

    if not tr then
        speak("No track")
        return true
    end

    reaper.SetTrackSelected(tr, true)
    set_current_track_pointer_only(tr)

    reaper.TrackList_AdjustWindows(false)
    reaper.UpdateArrange()

    speak(
        tostring(selected_track_count()) ..
        " Selected. " ..
        get_track_folder_spoken_label(tr)
    )

    return true
end

function toggle_current_cursor_track_selection_f1()
    if current_section_id ~= SECTION_TRACKS then
        return false
    end

    track_selection_reset_stroke()

    local e = get_current_entry()
    local tr = e and e.track or current_track

    if not tr then
        speak("No track")
        return true
    end

    local selected = track_is_selected(tr)

    reaper.SetTrackSelected(tr, not selected)
    set_current_track_pointer_only(tr)

    reaper.TrackList_AdjustWindows(false)
    reaper.UpdateArrange()

    speak(
        tostring(selected_track_count()) ..
        " Selected. " ..
        get_track_folder_spoken_label(tr) ..
        (selected and ". Deselected" or ". Selected")
    )

    return true
end

function select_track_range_rows(row_a, row_b)
    if current_section_id ~= SECTION_TRACKS then
        return false
    end

    local rows = grid_row_count()

    if rows <= 0 then
        return false
    end

    row_a = clamp_int(row_a, 1, rows)
    row_b = clamp_int(row_b, 1, rows)

    local first = math.min(row_a, row_b)
    local last = math.max(row_a, row_b)

    local map = {}

    for guid, selected in pairs(track_selection_base_guids or {}) do
        if selected then
            map[guid] = true
        end
    end

    for row = first, last do
        local tr = get_visible_track_by_row(row)

        if tr then
            local guid = get_track_guid(tr)

            if guid ~= "" then
                if track_selection_mode == "remove" then
                    map[guid] = nil
                else
                    map[guid] = true
                end
            end
        end
    end

    apply_track_guid_selection_map(map)

    return true
end

function track_shift_select_move(direction)
    if current_section_id ~= SECTION_TRACKS then
        return false
    end

    direction = tonumber(direction) or 0

    if direction == 0 then
        return false
    end

    local rows = grid_row_count()

    if rows <= 0 then
        return false
    end

    local current_row, col = grid_current_row_col()

    --------------------------------------------------------
    -- Nuova logica:
    -- Shift+Freccia in F1 deve sempre creare / estendere una
    -- selezione di range.
    --
    -- Non usiamo più la modalità "remove", perché può portare
    -- a 0 Selected quando si ritorna sull'anchor e poi si supera
    -- l'anchor nella direzione opposta.
    --
    -- L'anchor resta sempre incluso.
    --------------------------------------------------------

    if not track_selection_stroke_active then
        track_selection_stroke_active = true
        track_selection_anchor_row = current_row

        ----------------------------------------------------
        -- Mantiene eventuali selezioni già presenti come base,
        -- ma la nuova selezione con Shift aggiunge sempre il
        -- range corrente.
        ----------------------------------------------------

        track_selection_base_guids = track_guid_selected_map()
        track_selection_mode = "add"

        select_track_range_rows(current_row, current_row)
        speak_track_selection_count_with_current_entry()

        return true
    end

    local new_row = current_row + direction

    if new_row < 1 then
        return grid_edge("track-select-top:" .. tostring(col))
    end

    if new_row > rows then
        return grid_edge("track-select-bottom:" .. tostring(col))
    end

    --------------------------------------------------------
    -- Se si torna sull'anchor: resta selezionata 1 traccia.
    -- Se si supera l'anchor: il range si ricostruisce dall'altra
    -- parte, quindi diventa 2, 3, 4 ecc.
    --------------------------------------------------------

    select_track_range_rows(track_selection_anchor_row, new_row)

    local new_pos = grid_pos_from_row_col(new_row, col)
    grid_move_to_pos(new_pos, false, "track")

    speak_track_selection_count_with_current_entry()

    return true
end

function track_shift_select_page(direction)
    if current_section_id ~= SECTION_TRACKS then
        return false
    end

    direction = tonumber(direction) or 0

    if direction == 0 then
        return false
    end

    if not track_selection_stroke_active then
        return track_shift_select_move(direction)
    end

    local rows = grid_row_count()

    if rows <= 0 then
        return false
    end

    local current_row, col = grid_current_row_col()
    local amount = get_page_nav_amount()
    local new_row = current_row + (amount * direction)

    new_row = clamp_int(new_row, 1, rows)

    if new_row == current_row then
        if direction < 0 then
            return grid_edge("track-select-page-top:" .. tostring(col))
        end

        return grid_edge("track-select-page-bottom:" .. tostring(col))
    end

    select_track_range_rows(track_selection_anchor_row, new_row)

    local new_pos = grid_pos_from_row_col(new_row, col)
    grid_move_to_pos(new_pos, false, "track")

    speak_track_selection_count_with_current_entry()

    return true
end

function track_ctrl_shift_select_to_edge(direction)
    if current_section_id ~= SECTION_TRACKS then
        return false
    end

    direction = tonumber(direction) or 0

    if direction == 0 then
        return false
    end

    local rows = grid_row_count()

    if rows <= 0 then
        return false
    end

    local current_row, col = grid_current_row_col()
    local target_row = direction < 0 and 1 or rows

    track_selection_reset_stroke()

    local current_selection = track_guid_selected_map()

    for row = math.min(current_row, target_row), math.max(current_row, target_row) do
        local tr = get_visible_track_by_row(row)

        if tr then
            local guid = get_track_guid(tr)

            if guid ~= "" then
                current_selection[guid] = true
            end
        end
    end

    apply_track_guid_selection_map(current_selection)

    local new_pos = grid_pos_from_row_col(target_row, col)
    grid_move_to_pos(new_pos, false, "track")

    speak(
        tostring(selected_track_count()) ..
        " Selected. " ..
        get_entry_spoken_label(get_current_entry())
    )

    return true
end

------------------------------------------------------------
-- 1.6.2 - STATO FILTRO RUNTIME
------------------------------------------------------------

filter_active = false
filter_query = ""

function filter_is_active()
    return filter_active and normalize_search_text(filter_query) ~= ""
end

function get_filter_query()
    return normalize_search_text(filter_query)
end

function set_filter_query(query)
    query = clean_one_line(query or "")

    filter_query = query
    filter_active = normalize_search_text(query) ~= ""

    return true
end

function clear_filter_query()
    filter_query = ""
    filter_active = false

    return true
end

------------------------------------------------------------
-- 1.6.3 - STATO RUNTIME LISTA PARAMETRI FX
------------------------------------------------------------

fx_param_list_fx_index = -1
fx_param_list_fx_name = ""

fx_param_list_filter_active = false
fx_param_list_filter_query = ""

fx_param_list_return_section_key = KEY_F4
fx_param_list_return_section_id = "fx_params"
fx_param_list_return_grid_pos = 1

------------------------------------------------------------
-- 1.6.3A - EDIT ALIAS PARAMETRO FX F4
--
-- Ctrl+Enter su un parametro FX visibile in F4 apre un campo
-- di editazione per rinominare l'alias REAPER del parametro.
-- Non usa TXT: scrive nel progetto REAPER come normale alias
-- parametro.
------------------------------------------------------------

fx_alias_edit_mode = false
fx_alias_edit_buffer = ""
fx_alias_edit_cursor = 1
fx_alias_edit_return_mode = "grid"
fx_alias_edit_track = nil
fx_alias_edit_fx_index = -1
fx_alias_edit_param_index = -1
fx_alias_edit_original_name = ""

------------------------------------------------------------
-- 1.6.3B - STATO RUNTIME AUTOMATION F4
--
-- REAPER può lasciare l'envelope esistente anche quando
-- l'azione nativa lo nasconde. Per il parlato, quindi,
-- Ctrl+A mantiene una piccola memoria runtime della visibilità
-- richiesta dallo script. Non scrive TXT e non scrive file.
------------------------------------------------------------

f4_auto_visible_override = {}

------------------------------------------------------------
-- 1.6.3B2 - STATO RUNTIME AUTOMATION TRACCE F1
--
-- Ctrl+Shift+A in F1 usa gli envelope nativi di REAPER per
-- Volume, Pan, Track Width e Mute. La tabella serve solo per
-- stabilizzare il parlato "Auto" durante la sessione.
------------------------------------------------------------

f1_track_auto_visible_override = {}

------------------------------------------------------------
-- 1.6.3C - STATO RUNTIME AUTOMATION SEND / RECEIVE
--
-- Come per F4, la visibilità parlata di Auto viene mantenuta
-- in runtime. Però per F2/F3 il vero envelope viene creato o
-- nascosto nel chunk della traccia destinazione, perché i send
-- envelope non diventano affidabilmente "last touched" come i
-- parametri FX.
------------------------------------------------------------

send_receive_auto_visible_override = {}


------------------------------------------------------------
-- 1.7 - STEP SCALE RUNTIME
------------------------------------------------------------

STEP_SCALES = {
    { mult = 0.0005, name = "Step 0.0005x" },
    { mult = 0.002,  name = "Step 0.002x"  },
    { mult = 0.01,   name = "Step 0.01x"   },
    { mult = 0.02,   name = "Step 0.02x"   },
    { mult = 0.05,   name = "Step 0.05x"   },
    { mult = 0.10,   name = "Step 0.1x"    },
    { mult = 0.25,   name = "Step 0.25x"   },
    { mult = 0.50,   name = "Step 0.5x"    },
    { mult = 1.00,   name = "Step normal"  },
    { mult = 2.00,   name = "Step 2x"      },
    { mult = 5.00,   name = "Step 5x"      },
    { mult = 10.0,   name = "Step 10x"     },
    { mult = 20.0,   name = "Step 20x"     },
    { mult = 50.0,   name = "Step 50x"     },
    { mult = 100.0,  name = "Step 100x"    },
    { mult = 500.0,  name = "Step 500x"    },
}

STEP_NORMAL_INDEX = 9
step_scale_index = STEP_NORMAL_INDEX

function get_step_scale()
    local entry = STEP_SCALES[step_scale_index] or STEP_SCALES[STEP_NORMAL_INDEX]

    return entry.mult
end

function get_step_name()
    local entry = STEP_SCALES[step_scale_index] or STEP_SCALES[STEP_NORMAL_INDEX]

    return entry.name
end

function announce_step_scale()
    speak(get_step_name())
end

function change_step_scale(direction)
    direction = tonumber(direction) or 0

    if direction == 0 then
        return false
    end

    local old = step_scale_index

    step_scale_index = step_scale_index + direction
    step_scale_index = clamp_int(step_scale_index, 1, #STEP_SCALES)

    if step_scale_index == old then
        return false
    end

    announce_step_scale()

    return true
end

function get_page_nav_amount()
    local scale = get_step_scale()
    local amount = math.floor(scale * 5 + 0.5)

    if amount < 2 then
        amount = 2
    end

    return amount
end

------------------------------------------------------------
-- 1.8 - DEFINIZIONE SEZIONI
------------------------------------------------------------

SECTION_TRACKS    = "tracks"
SECTION_SENDS     = "sends"
SECTION_RECEIVES  = "receives"
SECTION_FX_PARAMS = "fx_params"

FX_PARAM_LIST_SECTION_ID = "fx_param_list"
PIN_AUDIO_SECTION_ID = "pin_audio"
PIN_MIDI_SECTION_ID  = "pin_midi"
HARDWARE_OUTPUT_SECTION_ID = "hardware_outputs"
REAROUTE_SECTION_ID = "rearoute"

TRACK_BASE_GRID_SIZE = 9
SEND_GRID_SIZE       = 14
RECEIVE_GRID_SIZE    = 14
FX_PARAM_GRID_SIZE   = 1
HARDWARE_OUTPUT_GRID_SIZE = 11
REAROUTE_GRID_SIZE = 11

fx_param_list_return_section_id = SECTION_FX_PARAMS

SECTIONS = {
    [KEY_F1] = {
        id = SECTION_TRACKS,
        name = "Tracks",
        title = "Project Tracks",
        grid_size = TRACK_BASE_GRID_SIZE
    },

    [KEY_F2] = {
        id = SECTION_SENDS,
        name = "Sends",
        title = "Sends",
        grid_size = SEND_GRID_SIZE
    },

    [KEY_F3] = {
        id = SECTION_RECEIVES,
        name = "Receives",
        title = "Receives",
        grid_size = RECEIVE_GRID_SIZE
    },

    [KEY_F4] = {
        id = SECTION_FX_PARAMS,
        name = "FX parameters",
        title = "FX parameters",
        grid_size = FX_PARAM_GRID_SIZE
    },

    [KEY_F6] = {
        id = PIN_MIDI_SECTION_ID,
        name = "Track MIDI",
        title = "Track MIDI",
        grid_size = 1
    },

    [KEY_F7] = {
        id = HARDWARE_OUTPUT_SECTION_ID,
        name = "Hardware outputs",
        title = "Hardware outputs",
        grid_size = HARDWARE_OUTPUT_GRID_SIZE
    },

    [KEY_F8] = {
        id = REAROUTE_SECTION_ID,
        name = "ReaRoute",
        title = "ReaRoute",
        grid_size = REAROUTE_GRID_SIZE
    },
}

function section_key_to_config(char)
    return SECTIONS[char]
end

function runtime_safe_blocks_function_key(char)
    if runtime_safe_mode ~= true then
        return false
    end

    if char == KEY_F1 or
       char == KEY_F2 or
       char == KEY_F3 or
       char == KEY_F4 or
       char == KEY_F5 or
       char == KEY_F6 or
       char == KEY_F7 or
       char == KEY_F8 or
       char == KEY_F9 or
       char == KEY_F10 or
       char == KEY_F11 or
       char == KEY_F12 then
        return true
    end

    return false
end

function get_section_name()
    if current_section_id == PIN_AUDIO_SECTION_ID then
        return "Audio pin connector"
    end

    if current_section_id == PIN_MIDI_SECTION_ID then
        return "Track MIDI"
    end

    if current_section_id == HARDWARE_OUTPUT_SECTION_ID then
        return "Hardware outputs"
    end

    if current_section_id == REAROUTE_SECTION_ID then
        return "ReaRoute"
    end

    if current_section_id == FX_PARAM_LIST_SECTION_ID then
        return "FX parameter list"
    end

    local cfg = SECTIONS[current_section_key]

    if cfg and cfg.name then
        return cfg.name
    end

    return "Section"
end

function get_section_title()
    if current_section_id == PIN_AUDIO_SECTION_ID then
        return "Audio pin connector"
    end

    if current_section_id == PIN_MIDI_SECTION_ID then
        return "Track MIDI"
    end

    if current_section_id == HARDWARE_OUTPUT_SECTION_ID then
        return "Hardware outputs"
    end

    if current_section_id == REAROUTE_SECTION_ID then
        return "ReaRoute"
    end

    if current_section_id == FX_PARAM_LIST_SECTION_ID then
        return "FX parameter list"
    end

    local cfg = SECTIONS[current_section_key]

    if cfg and cfg.title then
        return cfg.title
    end

    return get_section_name()
end

------------------------------------------------------------
-- 1.8.1 - HELPERS GENERICI DI RIGA / COLONNA
------------------------------------------------------------

function grid_safe_size()
    return clamp_int(grid_size, 1, 200)
end

function grid_total_count()
    return #grid_entries
end

function grid_row_from_pos(pos)
    local safe_grid = grid_safe_size()

    pos = clamp_int(pos, 1, math.max(1, grid_total_count()))

    return math.floor((pos - 1) / safe_grid) + 1
end

function grid_col_from_pos(pos)
    local safe_grid = grid_safe_size()

    pos = clamp_int(pos, 1, math.max(1, grid_total_count()))

    return ((pos - 1) % safe_grid) + 1
end

function grid_pos_from_row_col(row, col)
    local safe_grid = grid_safe_size()
    local count = grid_total_count()

    if count <= 0 then
        return 1
    end

    row = clamp_int(row, 1, math.max(1, math.ceil(count / safe_grid)))
    col = clamp_int(col, 1, safe_grid)

    local pos = ((row - 1) * safe_grid) + col

    if pos > count then
        pos = count
    end

    return pos
end

function grid_current_row_col()
    return grid_row_from_pos(grid_pos), grid_col_from_pos(grid_pos)
end

function grid_row_count()
    local count = grid_total_count()
    local safe_grid = grid_safe_size()

    if count <= 0 then
        return 0
    end

    return math.ceil(count / safe_grid)
end

function grid_row_bounds(row)
    local count = grid_total_count()
    local safe_grid = grid_safe_size()

    if count <= 0 then
        return 1, 1
    end

    row = clamp_int(row, 1, grid_row_count())

    local row_start = ((row - 1) * safe_grid) + 1
    local row_end = row_start + safe_grid - 1

    if row_end > count then
        row_end = count
    end

    return row_start, row_end
end

function grid_current_row_bounds()
    local row = grid_row_from_pos(grid_pos)

    return grid_row_bounds(row)
end

------------------------------------------------------------
-- 1.9 - TRACK HELPERS
------------------------------------------------------------

function get_project_track_count()
    return reaper.CountTracks(0) or 0
end

function get_track_by_index(index)
    index = tonumber(index) or 0

    if index < 0 then
        return nil
    end

    return reaper.GetTrack(0, index)
end

function get_track_index(track)
    if not track then
        return -1
    end

    local count = get_project_track_count()

    for i = 0, count - 1 do
        local tr = get_track_by_index(i)

        if tr == track then
            return i
        end
    end

    return -1
end

function track_is_tcp_visible(track)
    if not track then
        return false
    end

    if reaper.IsTrackVisible then
        return reaper.IsTrackVisible(track, false)
    end

    return true
end

function get_track_guid(track)
    if not track then
        return ""
    end

    if not reaper.GetTrackGUID then
        return ""
    end

    --------------------------------------------------------
    -- Protezione importante:
    -- dopo Cut / Delete / Undo una variabile MediaTrack può
    -- contenere ancora un puntatore non più valido.
    -- In quel caso GetTrackGUID genera errore.
    --------------------------------------------------------

    local ok, guid = pcall(reaper.GetTrackGUID, track)

    if not ok then
        return ""
    end

    return clean_one_line(guid or "")
end

function get_track_number(track)
    if not track then
        return 0
    end

    local n = reaper.GetMediaTrackInfo_Value(track, "IP_TRACKNUMBER")

    return math.floor(tonumber(n) or 0)
end

function get_track_name(track)
    if not track then
        return ""
    end

    local _, name = reaper.GetTrackName(track)

    return clean_one_line(name or "")
end

function get_track_plain_short_label(track)
    if not track then
        return "No track"
    end

    local name = get_track_name(track)

    if name ~= "" then
        return name
    end

    return "Track " .. tostring(get_track_number(track))
end

function get_track_short_label(track)
    return get_track_plain_short_label(track)
end

function get_track_spoken_label(track)
    if not track then
        return "No track"
    end

    local number = get_track_number(track)
    local name = get_track_name(track)

    if name ~= "" then
        return "Track " .. tostring(number) .. " " .. name
    end

    return "Track " .. tostring(number)
end

function get_current_track_label()
    return get_track_short_label(current_track)
end

function get_current_track_context_label()
    if current_track and track_is_folder(current_track) then
        return "Folder " .. get_current_track_label()
    end

    return get_current_track_label()
end

function set_current_track(track, speak_it)
    if not track then
        return false
    end

    current_track = track
    current_track_guid = get_track_guid(track)

    local n = get_track_number(track)

    if n > 0 then
        track_index = n - 1
    end

    if reaper.SetOnlyTrackSelected then
        reaper.SetOnlyTrackSelected(track)
    else
        local count = get_project_track_count()

        for i = 0, count - 1 do
            local tr = get_track_by_index(i)

            if tr then
                reaper.SetTrackSelected(tr, tr == track)
            end
        end
    end

    reaper.TrackList_AdjustWindows(false)
    reaper.UpdateArrange()

    if speak_it then
        speak(get_track_folder_spoken_label(track))
    end

    return true
end

function select_first_track()
    track_count = get_project_track_count()

    if track_count <= 0 then
        current_track = nil
        current_track_guid = ""
        track_index = 0

        return false
    end

    local selected_count = reaper.CountSelectedTracks(0) or 0

    if selected_count > 0 then
        local selected = reaper.GetSelectedTrack(0, 0)

        if selected and track_is_tcp_visible(selected) then
            return set_current_track_pointer_only(selected)
        end
    end

    if reaper.GetLastTouchedTrack then
        local touched = reaper.GetLastTouchedTrack()

        if touched and track_is_tcp_visible(touched) then
            return set_current_track_pointer_only(touched)
        end
    end

    local visible_tracks = build_folder_aware_visible_track_list()

    for i = 1, #visible_tracks do
        local item = visible_tracks[i]

        if item and item.track then
            return set_current_track_pointer_only(item.track)
        end
    end

    return false
end

function current_track_still_exists()
    if not current_track then
        return false
    end

    local count = get_project_track_count()

    for i = 0, count - 1 do
        local tr = get_track_by_index(i)

        if tr == current_track then
            return track_is_folder_aware_visible(tr)
        end
    end

    return false
end

------------------------------------------------------------
-- 1.9.1 - FOLDER HELPERS
------------------------------------------------------------

function track_is_folder(track)
    if not track then
        return false
    end

    local depth = reaper.GetMediaTrackInfo_Value(track, "I_FOLDERDEPTH")
    depth = tonumber(depth) or 0

    return depth > 0
end

function track_get_folder_compact(track)
    if not track then
        return 0
    end

    local compact = reaper.GetMediaTrackInfo_Value(track, "I_FOLDERCOMPACT")
    compact = math.floor((tonumber(compact) or 0) + 0.5)

    return compact
end

function track_folder_is_closed(track)
    if not track_is_folder(track) then
        return false
    end

    return track_get_folder_compact(track) > 0
end

function track_get_folder_state_name(track)
    if not track_is_folder(track) then
        return ""
    end

    if track_folder_is_closed(track) then
        return "closed"
    end

    return "open"
end

function toggle_track_folder_collapsed(track)
    if not track then
        speak("No track")
        return false
    end

    if not track_is_folder(track) then
        speak("Not a folder")
        return false
    end

    local old_closed = track_folder_is_closed(track)

    if old_closed then
        reaper.SetMediaTrackInfo_Value(track, "I_FOLDERCOMPACT", 0)
    else
        reaper.SetMediaTrackInfo_Value(track, "I_FOLDERCOMPACT", 2)
    end

    reaper.TrackList_AdjustWindows(false)
    reaper.UpdateArrange()

    return true
end

function open_track_folder(track)
    if not track then
        return false
    end

    if not track_is_folder(track) then
        return false
    end

    if not track_folder_is_closed(track) then
        return false
    end

    reaper.SetMediaTrackInfo_Value(track, "I_FOLDERCOMPACT", 0)

    return true
end

function track_folder_state_name(track)
    return track_get_folder_state_name(track)
end

function track_folder_depth_delta(track)
    if not track then
        return 0
    end

    local depth = reaper.GetMediaTrackInfo_Value(track, "I_FOLDERDEPTH")
    return math.floor((tonumber(depth) or 0) + 0.5)
end

function get_track_end_folder_tracks(track)
    local result = {}

    if not track then
        return result
    end

    local wanted_index = get_track_index(track)

    if wanted_index < 0 then
        return result
    end

    local stack = {}
    local count = get_project_track_count()

    for i = 0, math.min(wanted_index, count - 1) do
        local tr = get_track_by_index(i)

        if tr then
            local depth = track_folder_depth_delta(tr)

            ------------------------------------------------
            -- Prima di applicare il delta della traccia
            -- corrente, lo stack contiene le folder aperte
            -- dentro cui questa traccia si trova.
            ------------------------------------------------

            if i == wanted_index then
                if depth < 0 then
                    local close_count = math.min(-depth, #stack)

                    ------------------------------------------------
                    -- Ordine:
                    -- prima la folder più interna,
                    -- poi quella principale.
                    ------------------------------------------------

                    for n = 0, close_count - 1 do
                        local folder_track = stack[#stack - n]

                        if folder_track then
                            result[#result + 1] = folder_track
                        end
                    end
                end

                return result
            end

            if depth > 0 then
                stack[#stack + 1] = tr
            elseif depth < 0 then
                local close_count = math.min(-depth, #stack)

                for n = 1, close_count do
                    stack[#stack] = nil
                end
            end
        end
    end

    return result
end

function track_ends_folder(track)
    local folders = get_track_end_folder_tracks(track)

    return #folders > 0
end

function get_track_end_folder_spoken_suffix(track)
    local folders = get_track_end_folder_tracks(track)

    if #folders <= 0 then
        return ""
    end

    local parts = {}

    for i = 1, #folders do
        local folder = folders[i]
        local name = get_track_plain_short_label(folder)

        if name ~= "" then
            parts[#parts + 1] = "End of folder " .. name
        end
    end

    if #parts <= 0 then
        return ""
    end

    return ". " .. table.concat(parts, ". ")
end

function end_folder_cycle_reset_if_needed(track)
    local guid = get_track_guid(track)

    if guid ~= end_folder_cycle_track_guid then
        end_folder_cycle_track_guid = guid
        end_folder_cycle_index = 1
    end
end

function get_next_end_folder_target_for_track(track)
    if not track then
        return nil
    end

    local folders = get_track_end_folder_tracks(track)

    if #folders <= 0 then
        return nil
    end

    end_folder_cycle_reset_if_needed(track)

    if end_folder_cycle_index < 1 then
        end_folder_cycle_index = 1
    end

    if end_folder_cycle_index > #folders then
        end_folder_cycle_index = 1
    end

    local target = folders[end_folder_cycle_index]

    end_folder_cycle_index = end_folder_cycle_index + 1

    if end_folder_cycle_index > #folders then
        end_folder_cycle_index = 1
    end

    return target
end

function get_track_folder_spoken_label(track)
    if not track then
        return "No track"
    end

    local base = get_track_plain_short_label(track)
    local end_suffix = get_track_end_folder_spoken_suffix(track)

    if track_is_folder(track) then
        local state = track_get_folder_state_name(track)

        if state ~= "" then
            return
                state ..
                ". Folder " ..
                base ..
                end_suffix
        end

        return "Folder " .. base .. end_suffix
    end

    return base .. end_suffix
end

function join_track_context_and_entry_label(track_label, entry_label)
    track_label = clean_one_line(track_label or "")
    entry_label = clean_one_line(entry_label or "")

    if track_label == "" then
        return entry_label
    end

    if entry_label == "" then
        return track_label
    end

    --------------------------------------------------------
    -- Le folder parlano già lo stato con il proprio punto:
    -- "open. Folder Drums" / "closed. Folder Drums".
    -- Quando segue un parametro F1, non aggiungiamo un altro
    -- punto tra nome traccia e parametro.
    --------------------------------------------------------
    local lower = track_label:lower()

    if lower:match("^open%. folder ") or
       lower:match("^closed%. folder ") then

        return track_label .. " " .. entry_label
    end

    return track_label .. ". " .. entry_label
end

function get_track_filter_text(track)
    if not track then
        return ""
    end

    local parts = {}

    parts[#parts + 1] = get_track_plain_short_label(track)
    parts[#parts + 1] = get_track_spoken_label(track)

    if track_is_folder(track) then
        parts[#parts + 1] = "folder"
        parts[#parts + 1] = track_get_folder_state_name(track)
    end

    return table.concat(parts, " ")
end

function track_matches_current_filter(track)
    if not filter_is_active() then
        return true
    end

    return text_matches_filter(get_track_filter_text(track), get_filter_query())
end

function open_parent_folders_for_track(track)
    if not track then
        return false
    end

    local wanted_index = get_track_index(track)

    if wanted_index < 0 then
        return false
    end

    local changed = false
    local level = 0
    local parents = {}

    for i = 0, wanted_index do
        local tr = get_track_by_index(i)

        if tr then
            if i == wanted_index then
                for l, parent in pairs(parents) do
                    if parent and track_folder_is_closed(parent) then
                        if open_track_folder(parent) then
                            changed = true
                        end
                    end
                end

                break
            end

            local depth = reaper.GetMediaTrackInfo_Value(tr, "I_FOLDERDEPTH")
            depth = math.floor((tonumber(depth) or 0) + 0.5)

            if track_is_folder(tr) then
                parents[level] = tr
            end

            level = level + depth

            if level < 0 then
                level = 0
            end

            for l, parent in pairs(parents) do
                if l >= level then
                    parents[l] = nil
                end
            end
        end
    end

    if changed then
        reaper.TrackList_AdjustWindows(false)
        reaper.UpdateArrange()
    end

    return changed
end

function open_parent_folders_for_matching_tracks(query)
    query = normalize_search_text(query)

    if query == "" then
        return false
    end

    local changed = false
    local count = get_project_track_count()

    for i = 0, count - 1 do
        local tr = get_track_by_index(i)

        if tr and track_is_tcp_visible(tr) then
            if text_matches_filter(get_track_filter_text(tr), query) then
                if open_parent_folders_for_track(tr) then
                    changed = true
                end
            end
        end
    end

    if changed then
        reaper.TrackList_AdjustWindows(false)
        reaper.UpdateArrange()
    end

    return changed
end

function build_folder_aware_visible_track_list()
    local list = {}
    local count = get_project_track_count()

    local level = 0
    local hidden_parent_level = nil

    for i = 0, count - 1 do
        local tr = get_track_by_index(i)

        if tr then
            local depth = reaper.GetMediaTrackInfo_Value(tr, "I_FOLDERDEPTH")
            depth = math.floor((tonumber(depth) or 0) + 0.5)

            local hidden_by_closed_folder = false

            if hidden_parent_level ~= nil and level > hidden_parent_level then
                hidden_by_closed_folder = true
            end

            if not hidden_by_closed_folder and track_is_tcp_visible(tr) then
                list[#list + 1] = {
                    track = tr,
                    index = i
                }

                if track_is_folder(tr) and track_folder_is_closed(tr) then
                    hidden_parent_level = level
                end
            end

            level = level + depth

            if level < 0 then
                level = 0
            end

            if hidden_parent_level ~= nil and level <= hidden_parent_level then
                hidden_parent_level = nil
            end
        end
    end

    return list
end

function track_is_folder_aware_visible(track)
    if not track then
        return false
    end

    local wanted_guid = get_track_guid(track)

    if wanted_guid == "" then
        return false
    end

    local list = build_folder_aware_visible_track_list()

    for i = 1, #list do
        local item = list[i]

        if item and item.track and get_track_guid(item.track) == wanted_guid then
            return true
        end
    end

    return false
end

------------------------------------------------------------
-- 1.10 - TRACK BASE PARAM GET / SET
------------------------------------------------------------

function track_volume_range_key(track)
    if not track then
        return ""
    end

    local guid = get_track_guid(track)

    if guid == "" then
        return ""
    end

    return "track|" .. guid .. "|volume"
end

function track_get_volume_norm(track)
    if not track then
        return 0
    end

    local vol = reaper.GetMediaTrackInfo_Value(track, "D_VOL")

    vol = tonumber(vol) or 1

    return amp_to_volume_range_norm(vol, track_volume_range_key(track))
end

function track_set_volume_norm(track, norm)
    if not track then
        return false
    end

    norm = clamp01(norm)

    local vol = volume_range_norm_to_amp(norm, track_volume_range_key(track))

    reaper.SetMediaTrackInfo_Value(track, "D_VOL", vol)
    reaper.TrackList_AdjustWindows(false)
    reaper.UpdateArrange()

    return true
end

function track_get_volume_formatted(track)
    if not track then
        return ""
    end

    local vol = reaper.GetMediaTrackInfo_Value(track, "D_VOL")

    vol = tonumber(vol) or 1

    if vol <= 0 then
        return "-inf dB"
    end

    return format_db(amp_to_db(vol))
end

function track_get_pan_norm(track)
    if not track then
        return 0.5
    end

    local pan = reaper.GetMediaTrackInfo_Value(track, "D_PAN")

    pan = tonumber(pan) or 0

    return clamp01((pan + 1) / 2)
end

function track_set_pan_norm(track, norm)
    if not track then
        return false
    end

    norm = clamp01(norm)

    local pan = (norm * 2) - 1

    reaper.SetMediaTrackInfo_Value(track, "D_PAN", pan)
    reaper.TrackList_AdjustWindows(false)
    reaper.UpdateArrange()

    return true
end

function track_get_pan_formatted(track)
    if not track then
        return ""
    end

    local pan = reaper.GetMediaTrackInfo_Value(track, "D_PAN")

    return format_pan(pan)
end

function track_get_width_norm(track)
    if not track then
        return 1
    end

    local width = reaper.GetMediaTrackInfo_Value(track, "D_WIDTH")

    width = tonumber(width) or 1

    return clamp01((width + 1) / 2)
end

function track_set_width_norm(track, norm)
    if not track then
        return false
    end

    norm = clamp01(norm)

    local width = (norm * 2) - 1

    reaper.SetMediaTrackInfo_Value(track, "D_WIDTH", width)
    reaper.TrackList_AdjustWindows(false)
    reaper.UpdateArrange()

    return true
end

function track_get_width_formatted(track)
    if not track then
        return ""
    end

    local width = reaper.GetMediaTrackInfo_Value(track, "D_WIDTH")

    width = tonumber(width) or 1

    return string.format("%.1f percent", width * 100)
end

function track_get_bool(track, parm)
    if not track then
        return false
    end

    local v = reaper.GetMediaTrackInfo_Value(track, parm)

    return tonumber(v) == 1
end

function track_set_bool(track, parm, enabled)
    if not track then
        return false
    end

    reaper.SetMediaTrackInfo_Value(track, parm, enabled and 1 or 0)
    reaper.TrackList_AdjustWindows(false)
    reaper.UpdateArrange()

    return true
end

function track_get_solo_bool(track)
    if not track then
        return false
    end

    local solo = reaper.GetMediaTrackInfo_Value(track, "I_SOLO")
    solo = tonumber(solo) or 0

    return solo ~= 0
end

function track_set_solo_bool(track, enabled)
    if not track then
        return false
    end

    reaper.SetMediaTrackInfo_Value(track, "I_SOLO", enabled and 1 or 0)
    reaper.TrackList_AdjustWindows(false)
    reaper.UpdateArrange()

    return true
end


------------------------------------------------------------
-- 1.10A - TRACK TXT / FIXED CC MAP
--
-- Un solo file TXT per le funzioni base di Track Params.
-- Il TXT non salva valori e non salva numeri/GUID di traccia:
-- salva solo quale CC controlla Volume, Pan, Width, Mute,
-- Solo e Phase invert. Il valore viene sempre letto/scritto
-- sulle tracce realmente selezionate in quel momento.
--
-- Salvataggio copiato nello spirito da FX Params:
-- - dirty flag;
-- - save immediato quando si impara/rimuove un CC;
-- - save differito solo se resta dirty e l'utente è fermo.
------------------------------------------------------------

TRACK_TXT_FOLDER_NAME = "Tracks"
TRACK_CC_TXT_FILENAME = "Track CC Map.txt"
TRACK_CC_TXT_VERSION = "1"

track_txt_loaded = false
track_txt_dirty = false
track_txt_loading = false
track_txt_path = ""
track_txt_dirty_since = 0
track_txt_last_save_time = 0
track_txt_last_user_action_time = 0

TRACK_TXT_DEFERRED_SAVE_SECONDS = 8.0
TRACK_TXT_IDLE_SAVE_SECONDS = 1.25

track_txt_data = {
    version = TRACK_CC_TXT_VERSION,
    fixed_cc = {}
}

TRACK_FIXED_CC_IDS = {
    volume = true,
    pan = true,
    width = true,
    mute = true,
    solo = true,
    phase = true
}

TRACK_FIXED_CC_ORDER = {
    "volume",
    "pan",
    "width",
    "mute",
    "solo",
    "phase"
}

TRACK_FIXED_CC_LABELS = {
    volume = "Volume",
    pan = "Pan",
    width = "Width",
    mute = "Mute",
    solo = "Solo",
    phase = "Phase invert"
}

TRACK_FIXED_CC_FILE_KEYS = {
    volume = "Volume",
    pan = "Pan",
    width = "Width",
    mute = "Mute",
    solo = "Solo",
    phase = "PhaseInvert"
}

TRACK_FIXED_CC_KEY_TO_ID = {
    volume = "volume",
    pan = "pan",
    width = "width",
    mute = "mute",
    solo = "solo",
    phase = "phase",
    phaseinvert = "phase"
}

function track_txt_now()
    if reaper and reaper.time_precise then
        return reaper.time_precise()
    end

    return os.clock()
end

function track_txt_join_path(a, b)
    a = tostring(a or "")
    b = tostring(b or "")

    if a == "" then return b end
    if b == "" then return a end

    local last = a:sub(-1)

    if last == "/" or last == "\\" then
        return a .. b
    end

    return a .. "/" .. b
end

function track_txt_get_script_folder()
    if type(get_current_script_folder) == "function" then
        return get_current_script_folder()
    end

    local source = debug.getinfo(1, "S").source or ""

    if source:sub(1, 1) == "@" then
        source = source:sub(2)
    end

    return source:match("^(.*)[/\\][^/\\]+$") or ""
end

function track_txt_get_folder()
    return track_txt_join_path(
        track_txt_get_script_folder(),
        TRACK_TXT_FOLDER_NAME
    )
end

function track_txt_get_path()
    return track_txt_join_path(
        track_txt_get_folder(),
        TRACK_CC_TXT_FILENAME
    )
end

function track_txt_ensure_folder()
    local folder = track_txt_get_folder()

    if folder == "" then
        return false
    end

    if reaper.RecursiveCreateDirectory then
        reaper.RecursiveCreateDirectory(folder, 0)
        return true
    end

    os.execute('mkdir "' .. folder .. '"')

    return true
end

function track_txt_escape_value(s)
    s = tostring(s or "")
    s = s:gsub("\\", "\\\\")
    s = s:gsub("\r", "\\r")
    s = s:gsub("\n", "\\n")

    return s
end

function track_txt_unescape_value(s)
    s = tostring(s or "")

    local out = ""
    local i = 1

    while i <= #s do
        local c = s:sub(i, i)

        if c == "\\" and i < #s then
            local n = s:sub(i + 1, i + 1)

            if n == "n" then
                out = out .. "\n"
                i = i + 2
            elseif n == "r" then
                out = out .. "\r"
                i = i + 2
            elseif n == "\\" then
                out = out .. "\\"
                i = i + 2
            else
                out = out .. c
                i = i + 1
            end
        else
            out = out .. c
            i = i + 1
        end
    end

    return out
end

function track_txt_make_kv(key, value)
    key = clean_one_line(key or "")

    if key == "" then
        return ""
    end

    return key .. "=" .. track_txt_escape_value(value or "")
end

function track_txt_parse_kv(line)
    line = tostring(line or "")

    local key, value = line:match("^([^=]+)=(.*)$")

    if not key then
        return nil, ""
    end

    return trim(key or ""), track_txt_unescape_value(value or "")
end

function track_txt_reset_data()
    track_txt_data = {
        version = TRACK_CC_TXT_VERSION,
        fixed_cc = {}
    }
end

function track_fixed_cc_normalize_file_key(key)
    key = clean_one_line(key or "")
    key = key:gsub("%s+", "")
    key = key:gsub("_", "")
    key = key:gsub("%-", "")
    key = key:lower()

    return TRACK_FIXED_CC_KEY_TO_ID[key] or ""
end

function track_fixed_cc_make_text(channel, cc)
    channel = clamp_int(channel, 1, 16)
    cc = clamp_int(cc, 0, 127)

    return tostring(channel) .. "," .. tostring(cc)
end

function track_fixed_cc_parse_text(text)
    text = clean_one_line(text or "")

    local ch, cc = text:match("^(%d+)%s*,%s*(%d+)$")

    if not ch then
        ch, cc = text:match("^(%d+)%s*:%s*(%d+)$")
    end

    ch = tonumber(ch)
    cc = tonumber(cc)

    if not ch or not cc then
        return nil, nil
    end

    ch = clamp_int(ch, 1, 16)
    cc = clamp_int(cc, 0, 127)

    return ch, cc
end

function track_txt_read_file(path)
    if not path or path == "" then
        return nil
    end

    local f = io.open(path, "rb")

    if not f then
        return nil
    end

    local txt = f:read("*a") or ""
    f:close()

    return txt
end

function track_txt_load_from_text(txt)
    track_txt_reset_data()

    txt = tostring(txt or "")

    local section = ""

    for line in txt:gmatch("[^\r\n]+") do
        line = trim(line)

        if line ~= "" then
            if line:sub(1, 1) == "#" then
                -- commento
            elseif line:sub(1, 1) == "[" and line:sub(-1) == "]" then
                section = clean_one_line(line:sub(2, -2))
            else
                local key, value = track_txt_parse_kv(line)

                if key and key ~= "" then
                    if section == "FixedCC" then
                        local id = track_fixed_cc_normalize_file_key(key)

                        if id ~= "" then
                            local ch, cc = track_fixed_cc_parse_text(value)

                            if ch and cc then
                                track_txt_data.fixed_cc[id] = track_fixed_cc_make_text(ch, cc)
                            end
                        end
                    elseif key == "Version" then
                        track_txt_data.version = clean_one_line(value or "")
                    end
                end
            end
        end
    end
end

function track_txt_build_text()
    local lines = {}

    lines[#lines + 1] = "# Speak Track Params - TrackTake Navigator"
    lines[#lines + 1] = "# Fixed CC map for selected track parameters"
    lines[#lines + 1] = "# Storage: one TXT for Track Params. No track values are saved."
    lines[#lines + 1] = ""
    lines[#lines + 1] = track_txt_make_kv("Version", TRACK_CC_TXT_VERSION)
    lines[#lines + 1] = ""
    lines[#lines + 1] = "[FixedCC]"

    for _, id in ipairs(TRACK_FIXED_CC_ORDER) do
        local key = TRACK_FIXED_CC_FILE_KEYS[id] or id
        local value = track_txt_data.fixed_cc[id] or ""

        if trim(value) ~= "" then
            lines[#lines + 1] = track_txt_make_kv(key, value)
        else
            lines[#lines + 1] = key .. "="
        end
    end

    lines[#lines + 1] = ""

    return table.concat(lines, "\n")
end

function track_txt_write_file(path, txt)
    if not path or path == "" then
        return false
    end

    track_txt_ensure_folder()

    local tmp_path = path .. ".tmp"
    local f = io.open(tmp_path, "wb")

    if not f then
        return false
    end

    f:write(txt or "")
    f:close()

    os.remove(path)

    local ok = os.rename(tmp_path, path)

    if not ok then
        local f2 = io.open(path, "wb")

        if not f2 then
            return false
        end

        f2:write(txt or "")
        f2:close()
        os.remove(tmp_path)
    end

    return true
end

function track_txt_save_now()
    if not track_txt_loaded then
        return false
    end

    if track_txt_path == "" then
        return false
    end

    track_txt_data.version = TRACK_CC_TXT_VERSION

    local ok = track_txt_write_file(
        track_txt_path,
        track_txt_build_text()
    )

    if ok then
        track_txt_dirty = false
        track_txt_dirty_since = 0
        track_txt_last_save_time = track_txt_now()
    end

    return ok
end

function track_txt_mark_dirty()
    if track_txt_loading then
        return
    end

    if not track_txt_dirty then
        track_txt_dirty_since = track_txt_now()
    end

    track_txt_dirty = true
end

function track_txt_note_user_activity()
    track_txt_last_user_action_time = track_txt_now()
end

function track_txt_save_deferred_if_idle()
    if not track_txt_loaded or not track_txt_dirty then
        return false
    end

    local now = track_txt_now()

    if track_txt_dirty_since <= 0 then
        track_txt_dirty_since = now
        return false
    end

    if (now - track_txt_dirty_since) < TRACK_TXT_DEFERRED_SAVE_SECONDS then
        return false
    end

    if track_txt_last_user_action_time > 0 and
       (now - track_txt_last_user_action_time) < TRACK_TXT_IDLE_SAVE_SECONDS then

        return false
    end

    return track_txt_save_now()
end

function track_txt_save_if_dirty(force)
    if not track_txt_dirty then
        return true
    end

    if force == false then
        return true
    end

    return track_txt_save_now()
end

function track_txt_load()
    track_txt_loaded = false
    track_txt_dirty = false
    track_txt_loading = true
    track_txt_path = track_txt_get_path()

    track_txt_reset_data()

    if not track_txt_ensure_folder() then
        track_txt_loading = false
        return false
    end

    local txt = track_txt_read_file(track_txt_path)

    if txt ~= nil then
        track_txt_load_from_text(txt)
    else
        track_txt_reset_data()
        track_txt_dirty = true
    end

    track_txt_loaded = true
    track_txt_loading = false

    if track_txt_dirty then
        track_txt_save_if_dirty(true)
    end

    return true
end

function track_fixed_cc_storage_available()
    return track_txt_loaded == true and track_txt_data ~= nil
end

function track_fixed_cc_get_link(id)
    id = clean_one_line(id or "")

    if not TRACK_FIXED_CC_IDS[id] then
        return nil, nil
    end

    if not track_fixed_cc_storage_available() then
        return nil, nil
    end

    return track_fixed_cc_parse_text(track_txt_data.fixed_cc[id] or "")
end

function track_fixed_cc_set_link(id, channel, cc)
    id = clean_one_line(id or "")

    if not TRACK_FIXED_CC_IDS[id] then
        return false
    end

    if not track_fixed_cc_storage_available() then
        return false
    end

    channel = clamp_int(channel, 1, 16)
    cc = clamp_int(cc, 0, 127)

    --------------------------------------------------------
    -- Un CC fisso deve puntare a una sola funzione.
    -- Se lo stesso CC era già assegnato a un altro parametro,
    -- lo spostiamo sul parametro appena imparato.
    --------------------------------------------------------
    for _, other_id in ipairs(TRACK_FIXED_CC_ORDER) do
        if other_id ~= id then
            local other_ch, other_cc = track_fixed_cc_get_link(other_id)

            if other_ch == channel and other_cc == cc then
                track_txt_data.fixed_cc[other_id] = ""
            end
        end
    end

    track_txt_data.fixed_cc[id] = track_fixed_cc_make_text(channel, cc)
    track_txt_mark_dirty()
    track_txt_save_if_dirty(true)

    return true
end

function track_fixed_cc_remove_link(id)
    id = clean_one_line(id or "")

    if not TRACK_FIXED_CC_IDS[id] then
        return false
    end

    if not track_fixed_cc_storage_available() then
        return false
    end

    track_txt_data.fixed_cc[id] = ""
    track_txt_mark_dirty()
    track_txt_save_if_dirty(true)

    return true
end

function track_fixed_cc_count_links()
    if not track_fixed_cc_storage_available() then
        return 0
    end

    local count = 0

    for _, id in ipairs(TRACK_FIXED_CC_ORDER) do
        local ch, cc = track_fixed_cc_get_link(id)

        if ch and cc then
            count = count + 1
        end
    end

    return count
end

function track_fixed_cc_clear_all_links(speak_it)
    if not track_fixed_cc_storage_available() then
        track_txt_load()
    end

    if not track_fixed_cc_storage_available() then
        if speak_it then
            speak("Track CC map not available")
        end

        return false
    end

    local had = false

    for _, id in ipairs(TRACK_FIXED_CC_ORDER) do
        local ch, cc = track_fixed_cc_get_link(id)

        if ch and cc then
            had = true
        end

        track_txt_data.fixed_cc[id] = ""
    end

    track_fixed_cc_map_enabled = false
    track_fixed_cc_clear_pickup()
    track_fixed_cc_save_enabled_session()
    track_fixed_cc_learn_armed = false
    track_fixed_cc_learn_target_id = ""
    track_fixed_cc_learn_target_label = ""
    track_fixed_cc_last_seq = 0

    track_txt_mark_dirty()
    track_txt_save_if_dirty(true)

    if speak_it then
        if had then
            speak("Fixed CC map cleared")
        else
            speak("No fixed CC map")
        end
    end

    return true
end

function track_fixed_cc_set_map_enabled(enabled, speak_it)
    enabled = enabled == true

    if enabled then
        if not track_fixed_cc_storage_available() then
            track_txt_load()
        end

        if not track_fixed_cc_storage_available() then
            track_fixed_cc_map_enabled = false

            if speak_it then
                speak("Track CC map not available")
            end

            return false
        end

        local count = track_fixed_cc_count_links()

        if count <= 0 then
            track_fixed_cc_map_enabled = false
            track_fixed_cc_clear_pickup()
            track_fixed_cc_save_enabled_session()

            if speak_it then
                speak("No fixed CC map")
            end

            return false
        end

        if type(floating_cc_clear_session) == "function" then
            floating_cc_clear_session()
        end

        track_fixed_cc_map_enabled = true
        track_fixed_cc_clear_pickup()
        track_fixed_cc_last_seq = select(1, floating_cc_read_recent_event()) or 0
        track_fixed_cc_save_enabled_session()

        if speak_it then
            if count == 1 then
                speak("Fixed CC map on. 1 parameter")
            else
                speak("Fixed CC map on. " .. tostring(count) .. " parameters")
            end
        end

        return true
    end

    track_fixed_cc_map_enabled = false
    track_fixed_cc_clear_pickup()
    track_fixed_cc_last_seq = select(1, floating_cc_read_recent_event()) or 0
    track_fixed_cc_save_enabled_session()

    if speak_it then
        speak("Fixed CC map off")
    end

    return true
end

function track_fixed_cc_toggle_map()
    return track_fixed_cc_set_map_enabled(
        not track_fixed_cc_map_enabled,
        true
    )
end

------------------------------------------------------------
-- 1.11 - GRID ENTRY MODEL
------------------------------------------------------------

function make_entry_label(entry)
    if not entry then
        return "No entry"
    end

    if type(entry.label) == "function" then
        return clean_one_line(entry.label(entry) or "")
    end

    return clean_one_line(entry.label or "")
end

function make_entry_value(entry)
    if not entry then
        return ""
    end

    if type(entry.value) == "function" then
        return clean_one_line(entry.value(entry) or "")
    end

    return clean_one_line(entry.value or "")
end

function get_current_entry()
    if #grid_entries <= 0 then
        return nil
    end

    grid_pos = clamp_int(grid_pos, 1, #grid_entries)

    return grid_entries[grid_pos]
end

------------------------------------------------------------
-- 1.11.1 - GRID SPEECH CONTEXT BASE
------------------------------------------------------------

function entry_is_send_receive(entry)
    if not entry then
        return false
    end

    return entry.category == 0 or entry.category == -1
end

function entry_is_fx_header(entry)
    return entry and entry.kind == "fx_header"
end

function send_receive_peer_label(entry)
    if not entry then
        return ""
    end

    if not entry_is_send_receive(entry) then
        return ""
    end

    if entry.peer_track then
        return get_track_short_label(entry.peer_track)
    end

    if not current_track then
        return ""
    end

    local peer = nil

    if entry.category == 0 then
        peer = get_send_dest_track(current_track, entry.send_index or 0)
    else
        peer = get_receive_source_track(current_track, entry.send_index or 0)
    end

    if peer then
        return get_track_short_label(peer)
    end

    if entry.category == 0 then
        return "No destination track"
    end

    return "No source track"
end

function send_receive_entry_peer_key(entry)
    if not entry or not entry_is_send_receive(entry) then
        return ""
    end

    local guid = ""

    if entry.category == 0 then
        guid = clean_one_line(entry.destination_guid or "")

        if guid ~= "" then
            return "send-dst:" .. guid
        end
    elseif entry.category == -1 then
        guid = clean_one_line(entry.source_guid or "")

        if guid ~= "" then
            return "receive-src:" .. guid
        end
    end

    if entry.peer_track then
        guid = get_track_guid(entry.peer_track)

        if guid ~= "" then
            return tostring(entry.category or 0) .. ":peer:" .. guid
        end

        return tostring(entry.category or 0) ..
            ":peer-name:" ..
            get_track_short_label(entry.peer_track)
    end

    return tostring(entry.category or 0) ..
        ":peer-label:" ..
        send_receive_peer_label(entry)
end

function send_receive_hide_repeated_peer_for_move(entry, move_kind)
    if move_kind ~= "horizontal" then
        return false
    end

    if not entry_is_send_receive(entry) then
        return false
    end

    local old_pos = tonumber(last_grid_move_old_pos) or 0

    if old_pos < 1 or old_pos > #grid_entries then
        return false
    end

    local old_entry = grid_entries[old_pos]

    if not entry_is_send_receive(old_entry) then
        return false
    end

    if old_entry.category ~= entry.category then
        return false
    end

    local old_key = send_receive_entry_peer_key(old_entry)
    local new_key = send_receive_entry_peer_key(entry)

    if old_key == "" or new_key == "" then
        return false
    end

    return old_key == new_key
end

function send_receive_mode_short_name(mode_name)
    mode_name = clean_one_line(mode_name or "")

    if mode_name == "Post fader" then
        return "Post"
    end

    if mode_name == "Pre FX" then
        return "PreFX"
    end

    if mode_name == "Post FX" then
        return "PostFX"
    end

    if mode_name == "Post FX deprecated" then
        return "PostFX old"
    end

    return mode_name
end

function send_receive_midi_short_label(entry)
    if not entry or not entry_is_send_receive(entry) then
        return ""
    end

    local track = current_track

    if not track then
        return ""
    end

    local category = entry.category
    local index = entry.send_index or 0
    local source_ch = send_get_midi_source_channel(track, category, index)

    if source_ch == 31 then
        return "M none"
    end

    return "M on"
end

function send_receive_routing_short_label(entry)
    if not entry or not entry_is_send_receive(entry) then
        return ""
    end

    local track = current_track

    if not track then
        return ""
    end

    local category = entry.category
    local index = entry.send_index or 0

    local audio_src = send_get_audio_source_formatted(track, category, index)
    local audio_dst = send_get_audio_destination_formatted(track, category, index)
    local midi_text = send_receive_midi_short_label(entry)
    local send_type = send_receive_mode_short_name(
        send_get_mode_formatted(track, category, index)
    )

    local parts = {}

    if audio_src ~= "" and audio_dst ~= "" then
        parts[#parts + 1] = "A " .. audio_src .. ">" .. audio_dst
    end

    if midi_text ~= "" then
        parts[#parts + 1] = midi_text
    end

    if send_type ~= "" then
        parts[#parts + 1] = send_type
    end

    return table.concat(parts, ". ")
end

function send_receive_context_label(entry, hide_peer)
    if not entry then
        return ""
    end

    if not entry_is_send_receive(entry) then
        return ""
    end

    local number = tostring(entry.display_index or ((entry.send_index or 0) + 1))

    if hide_peer then
        if entry.category == 0 then
            return "Send " .. number
        end

        if entry.category == -1 then
            return "Receive " .. number
        end
    end

    local peer_label = send_receive_peer_label(entry)

    if peer_label == "" then
        if entry.category == 0 then
            peer_label = "No destination track"
        elseif entry.category == -1 then
            peer_label = "No source track"
        else
            peer_label = "No track"
        end
    end

    if entry.category == 0 then
        return "Send " .. number .. " " .. peer_label
    end

    if entry.category == -1 then
        return "Receive " .. number .. " " .. peer_label
    end

    return ""
end

function get_entry_spoken_label(entry)
    if not entry then
        return "No entry"
    end

    if entry_is_send_receive(entry) and entry.kind == "send_header" then
        local context = send_receive_context_label(entry)

        if context ~= "" then
            return context
        end
    end

    if entry_is_fx_header(entry) then
        local label = make_entry_label(entry)

        if label ~= "" then
            return label
        end
    end

    local label = make_entry_label(entry)
    local value = make_entry_value(entry)

    if label == "" then
        label = "Entry"
    end

    if current_section_id == SECTION_TRACKS and
       entry.kind == "track_param" and
       entry.track then

        value = append_f1_track_auto_suffix(value, entry.track, entry.id)
    end

    value = volume_range_append_modified_suffix(value, entry)

    local cc_part = ""

    if type(track_fixed_cc_spoken_part_for_entry) == "function" then
        cc_part = track_fixed_cc_spoken_part_for_entry(entry)
    end

    if value ~= "" then
        return label .. " " .. value .. cc_part
    end

    return label .. cc_part
end

function speak_current_entry(prefix, move_kind)
    local entry = get_current_entry()
    local msg = ""

    prefix = clean_one_line(prefix or "")

    if entry then
        msg = get_entry_spoken_label_for_move(entry, move_kind)
    else
        msg = "Empty"
    end

    if prefix ~= "" then
        msg = prefix .. ". " .. msg
    end

    speak(msg)
end

function logical_position_info()
    local entry = get_current_entry()

    if not entry then
        return 0, 0
    end

    if current_section_id == SECTION_TRACKS then
        return grid_row_from_pos(grid_pos), grid_row_count()
    end

    if current_section_id == SECTION_SENDS or
       current_section_id == SECTION_RECEIVES then

        local safe_grid = grid_safe_size()
        local block_index = math.floor((grid_pos - 1) / safe_grid) + 1
        local block_count = math.ceil(#grid_entries / safe_grid)

        return block_index, block_count
    end

    return grid_pos, #grid_entries
end

------------------------------------------------------------
-- 1.12 - WINDOW TITLE
------------------------------------------------------------

function build_window_title()
    --------------------------------------------------------
    -- Titoli invisibili opzionali.
    --
    -- Modalità normale:
    --   titolo = nome script + sezione + eventuale filtro.
    --
    -- Modalità rapida, Ctrl+Shift+M:
    --   titolo stabile e corto, solo nome script.
    --   Così, quando la finestra gfx viene ricreata, resta più
    --   probabile che lo screen reader legga solo il parlato utile
    --   generato dallo script.
    --------------------------------------------------------

    if not title_detail_is_enabled() then
        title = SCRIPT_NAME
        return title
    end

    local filter_part = ""

    if filter_is_active() then
        filter_part = " - Filter " .. filter_query
    end

    local section_label = get_section_title()

    if current_section_id == FX_PARAM_LIST_SECTION_ID or mode == "fx_param_list" then
        section_label = "FX parameter list"
    end

    title = SCRIPT_NAME .. " - " .. section_label .. filter_part

    return title
end

function refresh_window_title()
    build_window_title()

    gfx.init(title, 1, 1, 0, -32000, -32000)
end

function refresh_window_title_for_startup()
    --------------------------------------------------------
    -- All'avvio la finestra gfx prende il focus e alcuni
    -- screen reader leggono il titolo prima del primo messaggio
    -- OSARA. Per evitare che il titolo vinca sul parlato utile,
    -- all'apertura usiamo sempre un titolo minimo e stabile.
    --
    -- Dopo l'avvio, i normali refresh_window_title() continuano
    -- a funzionare come prima, rispettando Ctrl+Shift+M.
    --------------------------------------------------------

    title = SCRIPT_NAME
    gfx.init(title, 1, 1, 0, -32000, -32000)
end

function speak_after_startup_window_opens(msg)
    msg = clean_one_line(msg or "")

    if msg == "" then
        return false
    end

    cancel_pending_speech()

    local start_time = reaper.time_precise and reaper.time_precise() or 0

    local function later()
        local now = reaper.time_precise and reaper.time_precise() or start_time

        if now - start_time >= 0.09 then
            speak(msg)
            return
        end

        reaper.defer(later)
    end

    reaper.defer(later)

    return true
end

function startup_current_entry_message()
    local prefix = ""

    if current_section_id == SECTION_TRACKS then
        prefix = "Tracks"
    else
        prefix = get_current_track_label() .. ". " .. get_section_name()
    end

    local entry = get_current_entry()
    local msg = ""

    if entry then
        if current_section_id == SECTION_TRACKS then
            msg = get_entry_spoken_label_for_move(entry, "track")
        else
            msg = get_entry_spoken_label_for_move(entry, nil)
        end
    else
        msg = "Empty"
    end

    prefix = clean_one_line(prefix or "")

    if prefix ~= "" then
        return prefix .. ". " .. msg
    end

    return msg
end

------------------------------------------------------------
-- 1.13 - TRACK BASE PARAM BLOCK
------------------------------------------------------------

function add_track_base_param_block(track, index_zero)
    if not track then
        return false
    end

    grid_entries[#grid_entries + 1] = {
        kind = "track_param",
        id = "volume",
        value_kind = "continuous",
        track = track,
        track_index = index_zero,

        label = "Volume",

        value = function(e)
            return track_get_volume_formatted(e.track)
        end,

        get_norm = function(e)
            return track_get_volume_norm(e.track)
        end,

        set_norm = function(e, norm)
            return track_set_volume_norm(e.track, norm)
        end
    }

    grid_entries[#grid_entries + 1] = {
        kind = "track_param",
        id = "pan",
        value_kind = "continuous",
        track = track,
        track_index = index_zero,

        label = "Pan",

        value = function(e)
            return track_get_pan_formatted(e.track)
        end,

        get_norm = function(e)
            return track_get_pan_norm(e.track)
        end,

        set_norm = function(e, norm)
            return track_set_pan_norm(e.track, norm)
        end
    }

    grid_entries[#grid_entries + 1] = {
        kind = "track_param",
        id = "width",
        value_kind = "continuous",
        track = track,
        track_index = index_zero,

        label = "Width",

        value = function(e)
            return track_get_width_formatted(e.track)
        end,

        get_norm = function(e)
            return track_get_width_norm(e.track)
        end,

        set_norm = function(e, norm)
            return track_set_width_norm(e.track, norm)
        end
    }

    grid_entries[#grid_entries + 1] = {
        kind = "track_param",
        id = "mute",
        value_kind = "bool",
        track = track,
        track_index = index_zero,

        label = "Mute",

        value = function(e)
            return bool_to_on_off(track_get_bool(e.track, "B_MUTE"))
        end,

        get_norm = function(e)
            return track_get_bool(e.track, "B_MUTE") and 1 or 0
        end,

        set_norm = function(e, norm)
            local enabled = clamp01(norm) >= 0.5
            return track_set_bool(e.track, "B_MUTE", enabled)
        end
    }

    grid_entries[#grid_entries + 1] = {
        kind = "track_param",
        id = "solo",
        value_kind = "bool",
        track = track,
        track_index = index_zero,

        label = "Solo",

        value = function(e)
            return bool_to_on_off(track_get_solo_bool(e.track))
        end,

        get_norm = function(e)
            return track_get_solo_bool(e.track) and 1 or 0
        end,

        set_norm = function(e, norm)
            local enabled = clamp01(norm) >= 0.5
            return track_set_solo_bool(e.track, enabled)
        end
    }

    grid_entries[#grid_entries + 1] = {
        kind = "track_param",
        id = "phase",
        value_kind = "bool",
        track = track,
        track_index = index_zero,

        label = "Phase invert",

        value = function(e)
            return bool_to_on_off(track_get_bool(e.track, "B_PHASE"))
        end,

        get_norm = function(e)
            return track_get_bool(e.track, "B_PHASE") and 1 or 0
        end,

        set_norm = function(e, norm)
            local enabled = clamp01(norm) >= 0.5
            return track_set_bool(e.track, "B_PHASE", enabled)
        end
    }

    grid_entries[#grid_entries + 1] = {
        kind = "track_info",
        id = "send_count",
        track = track,
        track_index = index_zero,

        label = "Send count",

        value = function(e)
            local count = reaper.GetTrackNumSends(e.track, 0) or 0
            return tostring(count)
        end,

        enter = function(e)
            set_current_track(e.track, false)
            return switch_section_by_key(KEY_F2, true)
        end
    }

    grid_entries[#grid_entries + 1] = {
        kind = "track_info",
        id = "receive_count",
        track = track,
        track_index = index_zero,

        label = "Receive count",

        value = function(e)
            local count = reaper.GetTrackNumSends(e.track, -1) or 0
            return tostring(count)
        end,

        enter = function(e)
            set_current_track(e.track, false)
            return switch_section_by_key(KEY_F3, true)
        end
    }

    grid_entries[#grid_entries + 1] = {
        kind = "track_info",
        id = "fx_count",
        track = track,
        track_index = index_zero,

        label = "FX count",

        value = function(e)
            local count = reaper.TrackFX_GetCount(e.track) or 0
            return tostring(count)
        end,

        enter = function(e)
            set_current_track(e.track, false)
            return switch_section_by_key(KEY_F4, true)
        end
    }

    return true
end

------------------------------------------------------------
-- 1.14 - BUILD F1 TRACKS GRID
------------------------------------------------------------

function build_tracks_grid()
    grid_entries = {}

    if filter_is_active() then
        open_parent_folders_for_matching_tracks(get_filter_query())
    end

    local visible_tracks = build_folder_aware_visible_track_list()

    track_count = get_project_track_count()

    for i = 1, #visible_tracks do
        local item = visible_tracks[i]

        if item and item.track then
            if not filter_is_active() or track_matches_current_filter(item.track) then
                add_track_base_param_block(item.track, item.index or 0)
            end
        end
    end

    grid_size = TRACK_BASE_GRID_SIZE

    if current_track then
        local wanted_guid = get_track_guid(current_track)
        local wanted_col = grid_col_from_pos(grid_pos)

        for pos = 1, #grid_entries do
            local e = grid_entries[pos]

            if e.track and get_track_guid(e.track) == wanted_guid then
                local row = grid_row_from_pos(pos)

                grid_pos = grid_pos_from_row_col(row, wanted_col)

                if grid_pos > #grid_entries then
                    grid_pos = #grid_entries
                end

                return true
            end
        end
    end

    grid_pos = clamp_int(grid_pos, 1, math.max(1, #grid_entries))

local e = get_current_entry()

if e and e.track then
    --------------------------------------------------------
    -- Importante:
    -- in F1 il cursore dello script deve restare invisibile.
    -- Non dobbiamo selezionare davvero la traccia nel TCP,
    -- altrimenti dopo Cut/Paste appare "Selected" senza motivo.
    --------------------------------------------------------

    set_current_track_pointer_only(e.track)
end

return #grid_entries > 0
end

------------------------------------------------------------
-- FINE PARTE 1 / 5
------------------------------------------------------------

------------------------------------------------------------
-- PARTE 2 / 5
-- ENTER HELPERS, SEND / RECEIVE GRID CON ROUTING AUDIO/MIDI,
-- ADD SEND / ADD RECEIVE, DELETE DI SINGOLA ISTANZA SEND,
-- BUILD GRID SEND / RECEIVE
------------------------------------------------------------

------------------------------------------------------------
-- 2.1 - ENTER HELPERS
------------------------------------------------------------

function enter_target_track_and_close(track)
    if not track then
        speak("No track")
        return false
    end

    cancel_pending_speech()
    clear_silent_edge()

    set_current_track(track, false)
    speak(get_track_folder_spoken_label(track))

    gfx.quit()

    return true
end

function send_receive_opposite_section_for_entry(entry)
    if not entry or not entry_is_send_receive(entry) then
        return "", nil
    end

    if entry.category == 0 then
        return SECTION_RECEIVES, KEY_F3
    end

    if entry.category == -1 then
        return SECTION_SENDS, KEY_F2
    end

    return "", nil
end

function send_receive_entry_matches_route(entry, source_guid, destination_guid, real_send_index)
    if not entry or not entry_is_send_receive(entry) then
        return false
    end

    source_guid = clean_one_line(source_guid or "")
    destination_guid = clean_one_line(destination_guid or "")
    real_send_index = tonumber(real_send_index)

    if source_guid ~= "" and
       clean_one_line(entry.source_guid or "") ~= source_guid then
        return false
    end

    if destination_guid ~= "" and
       clean_one_line(entry.destination_guid or "") ~= destination_guid then
        return false
    end

    if real_send_index ~= nil and
       tonumber(entry.real_send_index) ~= nil and
       tonumber(entry.real_send_index) ~= real_send_index then
        return false
    end

    return true
end

function send_receive_find_matching_block_pos(source_guid, destination_guid, real_send_index, wanted_col)
    wanted_col = clamp_int(wanted_col, 1, grid_safe_size())

    --------------------------------------------------------
    -- Primo passaggio: match forte, includendo l'indice reale
    -- del send. Serve quando esistono più send tra le stesse
    -- due tracce.
    --------------------------------------------------------
    for pos = 1, #grid_entries do
        local e = grid_entries[pos]

        if send_receive_entry_matches_route(
            e,
            source_guid,
            destination_guid,
            real_send_index
        ) then
            local row = grid_row_from_pos(pos)
            return grid_pos_from_row_col(row, wanted_col)
        end
    end

    --------------------------------------------------------
    -- Secondo passaggio: match più morbido, solo sorgente e
    -- destinazione. È utile se REAPER/SWS non restituisce un
    -- indice reale stabile per quella receive.
    --------------------------------------------------------
    for pos = 1, #grid_entries do
        local e = grid_entries[pos]

        if send_receive_entry_matches_route(
            e,
            source_guid,
            destination_guid,
            nil
        ) then
            local row = grid_row_from_pos(pos)
            return grid_pos_from_row_col(row, wanted_col)
        end
    end

    return 0
end

function enter_send_receive_peer_track(entry)
    if not entry then
        speak("No track")
        return false
    end

    if not entry_is_send_receive(entry) then
        speak_current_entry()
        return true
    end

    local peer = entry.peer_track

    if not peer then
        if entry.category == 0 then
            peer = get_send_dest_track(current_track, entry.send_index or 0)
        else
            peer = get_receive_source_track(current_track, entry.send_index or 0)
        end
    end

    if not peer then
        if entry.category == 0 then
            speak("No destination track")
        else
            speak("No source track")
        end

        return false
    end

    local target_section_id, target_section_key =
        send_receive_opposite_section_for_entry(entry)

    if target_section_id == "" or target_section_key == nil then
        return enter_target_track_and_close(peer)
    end

    cancel_pending_speech()
    clear_silent_edge()
    cursor_memory_save_current()

    local wanted_col = grid_col_from_pos(grid_pos)
    local source_guid = clean_one_line(entry.source_guid or "")
    local destination_guid = clean_one_line(entry.destination_guid or "")
    local real_send_index = tonumber(entry.real_send_index)

    set_current_track_pointer_only(peer)
    current_section_id = target_section_id
    current_section_key = target_section_key
    grid_pos = 1

    local ok = build_current_grid()

    if not ok or #grid_entries <= 0 then
        refresh_window_title()

        if target_section_id == SECTION_RECEIVES then
            speak(get_current_track_context_label() .. ". No receives")
        else
            speak(get_current_track_context_label() .. ". No sends")
        end

        return true
    end

    local match_pos = send_receive_find_matching_block_pos(
        source_guid,
        destination_guid,
        real_send_index,
        wanted_col
    )

    if match_pos > 0 then
        grid_pos = match_pos
    else
        grid_pos = clamp_int(wanted_col, 1, #grid_entries)
    end

    refresh_window_title()
    speak_current_entry(get_current_track_context_label() .. ". " .. get_section_name())

    return true
end

------------------------------------------------------------
-- 2.2 - SEND / RECEIVE HELPERS
--
-- category:
--  0  = sends
-- -1  = receives
--  1  = hardware outputs
------------------------------------------------------------

function get_track_send_count(track)
    if not track then
        return 0
    end

    return reaper.GetTrackNumSends(track, 0) or 0
end

function get_track_receive_count(track)
    if not track then
        return 0
    end

    return reaper.GetTrackNumSends(track, -1) or 0
end

function get_track_hwout_count(track)
    if not track then
        return 0
    end

    return reaper.GetTrackNumSends(track, 1) or 0
end

function get_send_dest_track(track, send_index)
    if not track then
        return nil
    end

    send_index = tonumber(send_index) or -1

    if send_index < 0 then
        return nil
    end

    if reaper.BR_GetMediaTrackSendInfo_Track then
        return reaper.BR_GetMediaTrackSendInfo_Track(
            track,
            0,
            send_index,
            1
        )
    end

    return nil
end

function get_receive_source_track(track, receive_index)
    if not track then
        return nil
    end

    receive_index = tonumber(receive_index) or -1

    if receive_index < 0 then
        return nil
    end

    if reaper.BR_GetMediaTrackSendInfo_Track then
        return reaper.BR_GetMediaTrackSendInfo_Track(
            track,
            -1,
            receive_index,
            0
        )
    end

    return nil
end

function get_track_send_target_label(track, category, index)
    local other = nil

    if category == 0 then
        other = get_send_dest_track(track, index)
    else
        other = get_receive_source_track(track, index)
    end

    if other then
        return get_track_short_label(other)
    end

    if category == 0 then
        return "Send " .. tostring((tonumber(index) or 0) + 1)
    end

    return "Receive " .. tostring((tonumber(index) or 0) + 1)
end

function send_get_value(track, category, index, parm)
    if not track then
        return 0
    end

    category = tonumber(category) or 0
    index = tonumber(index) or -1

    if index < 0 then
        return 0
    end

    return reaper.GetTrackSendInfo_Value(track, category, index, parm)
end

function send_set_value(track, category, index, parm, value)
    if not track then
        return false
    end

    category = tonumber(category) or 0
    index = tonumber(index) or -1

    if index < 0 then
        return false
    end

    reaper.SetTrackSendInfo_Value(track, category, index, parm, value)
    reaper.TrackList_AdjustWindows(false)
    reaper.UpdateArrange()

    return true
end

------------------------------------------------------------
-- 2.2A - AUTO TRACK CHANNEL COUNT FOR SEND / RECEIVE ROUTING
--
-- REAPER can store I_SRCCHAN and I_DSTCHAN values that point to
-- channels 3/4, 5/6, etc., but the routing will not really work
-- unless the source or destination track has enough channels.
--
-- These helpers silently add the needed track channels under the
-- hood when the user changes Audio source, Audio destination, or
-- Audio source mode from the script.
------------------------------------------------------------

function track_get_channel_count(track)
    if not track then
        return 2
    end

    local n = reaper.GetMediaTrackInfo_Value(track, "I_NCHAN")
    n = math.floor((tonumber(n) or 2) + 0.5)

    if n < 2 then
        n = 2
    end

    if (n % 2) ~= 0 then
        n = n + 1
    end

    return n
end

function track_ensure_channel_count(track, needed_channels)
    if not track then
        return false
    end

    needed_channels = math.floor((tonumber(needed_channels) or 2) + 0.5)

    if needed_channels < 2 then
        needed_channels = 2
    end

    if (needed_channels % 2) ~= 0 then
        needed_channels = needed_channels + 1
    end

    if needed_channels > 128 then
        needed_channels = 128
    end

    local current = track_get_channel_count(track)

    if current >= needed_channels then
        return true
    end

    reaper.SetMediaTrackInfo_Value(track, "I_NCHAN", needed_channels)

    return true
end

function send_get_source_track_for_routing(track, category, index)
    category = tonumber(category) or 0

    if category == 0 then
        return track
    end

    return get_receive_source_track(track, index)
end

function send_get_destination_track_for_routing(track, category, index)
    category = tonumber(category) or 0

    if category == 0 then
        return get_send_dest_track(track, index)
    end

    return track
end

function audio_source_required_channels(value)
    value = math.floor((tonumber(value) or 0) + 0.5)

    if value < 0 then
        return 0
    end

    local off = audio_src_offset(value)

    if off < 0 then
        return 0
    end

    local mode = audio_src_mode(value)
    local channels = 2

    if mode == 1 then
        channels = 1
    elseif mode > 1 then
        channels = mode * 2
    end

    return off + channels
end

function audio_destination_required_channels(value)
    value = math.floor((tonumber(value) or 0) + 0.5)

    local off = audio_dst_offset(value)
    local channels = audio_dst_mono(value) and 1 or 2

    return off + channels
end

function send_ensure_audio_source_channels(track, category, index, value)
    local source_track = send_get_source_track_for_routing(track, category, index)
    local needed = audio_source_required_channels(value)

    if needed <= 0 then
        return true
    end

    return track_ensure_channel_count(source_track, needed)
end

function send_ensure_audio_destination_channels(track, category, index, value)
    local destination_track = send_get_destination_track_for_routing(track, category, index)
    local needed = audio_destination_required_channels(value)

    return track_ensure_channel_count(destination_track, needed)
end

------------------------------------------------------------
-- 2.2.1 - ADD / DELETE SEND RECEIVE LOW LEVEL
------------------------------------------------------------

function create_track_send_instance(source_track, destination_track)
    if not source_track or not destination_track then
        return false, "missing"
    end

    if source_track == destination_track then
        return false, "self"
    end

    if not reaper.CreateTrackSend then
        return false, "not_available"
    end

    local send_index = reaper.CreateTrackSend(source_track, destination_track)

    if send_index == nil or send_index < 0 then
        return false, "failed"
    end

    reaper.TrackList_AdjustWindows(false)
    reaper.UpdateArrange()

    return true, send_index
end

function remove_track_send_instance(track, category, send_index)
    if not track then
        return false, "missing_track"
    end

    if not reaper.RemoveTrackSend then
        return false, "not_available"
    end

    category = tonumber(category) or 0
    send_index = tonumber(send_index) or -1

    if send_index < 0 then
        return false, "bad_index"
    end

    local ok = reaper.RemoveTrackSend(track, category, send_index)

    reaper.TrackList_AdjustWindows(false)
    reaper.UpdateArrange()

    if ok then
        return true, "ok"
    end

    return false, "failed"
end

------------------------------------------------------------
-- 2.2.2 - DELETE SAFE PER F2 / F3
--
-- F2:
-- - current_track è la sorgente.
-- - category 0.
-- - send_index è l'indice reale del send.
--
-- F3:
-- - current_track è la destinazione.
-- - entry.source_track è la sorgente reale.
-- - entry.real_send_index è l'indice reale del send sulla
--   sorgente.
------------------------------------------------------------

function get_send_source_track_for_entry(entry)
    if not entry then
        return nil
    end

    if entry.source_track then
        return entry.source_track
    end

    if entry.category == 0 then
        return current_track
    end

    if entry.category == -1 then
        return get_receive_source_track(current_track, entry.send_index or 0)
    end

    return nil
end

function get_send_destination_track_for_entry(entry)
    if not entry then
        return nil
    end

    if entry.destination_track then
        return entry.destination_track
    end

    if entry.category == 0 then
        return get_send_dest_track(current_track, entry.send_index or 0)
    end

    if entry.category == -1 then
        return current_track
    end

    return nil
end

function find_send_index_between_tracks_by_instance(source_track, destination_track, wanted_peer_occurrence)
    if not source_track or not destination_track then
        return -1
    end

    wanted_peer_occurrence = clamp_int(wanted_peer_occurrence, 1, 999999)

    local send_count = get_track_send_count(source_track)
    local occurrence = 0

    for i = 0, send_count - 1 do
        local dest = get_send_dest_track(source_track, i)

        if dest == destination_track then
            occurrence = occurrence + 1

            if occurrence == wanted_peer_occurrence then
                return i
            end
        end
    end

    return -1
end

function resolve_real_send_index_for_entry(entry)
    if not entry or not entry_is_send_receive(entry) then
        return -1
    end

    if entry.real_send_index ~= nil then
        local idx = tonumber(entry.real_send_index)

        if idx and idx >= 0 then
            return math.floor(idx + 0.5)
        end
    end

    if entry.category == 0 then
        local idx = tonumber(entry.send_index) or -1

        if idx >= 0 then
            return math.floor(idx + 0.5)
        end

        return -1
    end

    if entry.category == -1 then
        local source_track = get_send_source_track_for_entry(entry)
        local destination_track = get_send_destination_track_for_entry(entry)
        local occurrence = entry.display_index or 1

        return find_send_index_between_tracks_by_instance(
            source_track,
            destination_track,
            occurrence
        )
    end

    return -1
end

function delete_current_send_receive_low_level(entry)
    entry = entry or get_current_entry()

    if not entry or not entry_is_send_receive(entry) then
        return false, "not_send_receive"
    end

    if entry.kind ~= "send_header" and entry.kind ~= "send_param" then
        return false, "not_send_receive"
    end

    if entry.category == 0 then
        if not current_track then
            return false, "missing_track"
        end

        return remove_track_send_instance(
            current_track,
            0,
            entry.send_index
        )
    end

    if entry.category == -1 then
        local source_track = get_send_source_track_for_entry(entry)
        local real_send_index = resolve_real_send_index_for_entry(entry)

        if not source_track then
            return false, "missing_source_track"
        end

        if real_send_index < 0 then
            return false, "bad_real_send_index"
        end

        return remove_track_send_instance(
            source_track,
            0,
            real_send_index
        )
    end

    return false, "not_send_receive"
end

function send_receive_delete_message(entry)
    if not entry or not entry_is_send_receive(entry) then
        return "Deleted"
    end

    local context = send_receive_context_label(entry)

    if context == "" then
        if entry.category == 0 then
            context = "Send"
        else
            context = "Receive"
        end
    end

    return "Deleted " .. context
end

function rebuild_send_receive_after_delete(message, old_pos)
    old_pos = tonumber(old_pos) or grid_pos

    local ok = build_current_grid()

    grid_pos = clamp_int(old_pos, 1, math.max(1, #grid_entries))

    if not ok or #grid_entries <= 0 then
        refresh_window_title()

        if current_section_id == SECTION_SENDS then
            speak("Deleted. No sends")
            return true
        end

        if current_section_id == SECTION_RECEIVES then
            speak("Deleted. No receives")
            return true
        end

        speak("Deleted. Empty")
        return true
    end

    refresh_window_title()

    if message and message ~= "" then
        speak(message)
    else
        speak_current_entry()
    end

    return true
end

function delete_current_send_or_receive()
    if current_section_id ~= SECTION_SENDS and
       current_section_id ~= SECTION_RECEIVES then
        return false
    end

    local entry = get_current_entry()

    if not entry or not entry_is_send_receive(entry) then
        speak("No send or receive")
        return true
    end

    local old_pos = grid_pos
    local message = send_receive_delete_message(entry)
    local ok, reason = delete_current_send_receive_low_level(entry)

    if not ok then
        if reason == "not_available" then
            speak("Delete send not available")
        elseif reason == "missing_source_track" then
            speak("Source track not found")
        elseif reason == "bad_real_send_index" then
            speak("Send instance not found")
        else
            speak("Delete failed")
        end

        return true
    end

    return rebuild_send_receive_after_delete(message, old_pos)
end

------------------------------------------------------------
-- 2.2.3 - ADD SEND / RECEIVE A DUE PASSAGGI
------------------------------------------------------------

function collect_selected_tracks_ordered()
    local result = {}
    local selected = {}

    local selected_count = reaper.CountSelectedTracks(0) or 0

    for i = 0, selected_count - 1 do
        local tr = reaper.GetSelectedTrack(0, i)

        if tr then
            local guid = get_track_guid(tr)

            if guid ~= "" then
                selected[guid] = true
            end
        end
    end

    if selected_count <= 0 then
        return result
    end

    local project_count = get_project_track_count()

    for i = 0, project_count - 1 do
        local tr = get_track_by_index(i)

        if tr then
            local guid = get_track_guid(tr)

            if guid ~= "" and selected[guid] == true then
                result[#result + 1] = tr
            end
        end
    end

    return result
end

function store_selected_tracks_for_routing(kind)
    kind = tostring(kind or "")

    if kind ~= "send" and kind ~= "receive" then
        return false
    end

    local tracks = collect_selected_tracks_ordered()

    if #tracks <= 0 then
        if kind == "send" then
            speak("No source tracks selected")
        else
            speak("No destination tracks selected")
        end

        return true
    end

    routing_pending_reset()

    routing_pending_active = true
    routing_pending_kind = kind
    routing_pending_tracks = {}
    routing_pending_guids = {}

    for i = 1, #tracks do
        local tr = tracks[i]
        local guid = get_track_guid(tr)

        if guid ~= "" then
            routing_pending_tracks[#routing_pending_tracks + 1] = tr
            routing_pending_guids[guid] = true
        end
    end

    clear_track_selection_silent()

    if kind == "send" then
        speak(
            "Add send. " ..
            tostring(#routing_pending_tracks) ..
            " source tracks stored. Select destination tracks, then press Ctrl Shift S."
        )
    else
        speak(
            "Add receive. " ..
            tostring(#routing_pending_tracks) ..
            " destination tracks stored. Select source tracks, then press Ctrl Shift R."
        )
    end

    return true
end

function complete_pending_routing_with_selected_tracks()
    if not routing_pending_is_active() then
        return false
    end

    local selected_now = collect_selected_tracks_ordered()

    if #selected_now <= 0 then
        if routing_pending_kind == "send" then
            speak("No destination tracks selected")
        else
            speak("No source tracks selected")
        end

        return true
    end

    local sources = {}
    local destinations = {}

    if routing_pending_kind == "send" then
        sources = routing_pending_tracks
        destinations = selected_now

    elseif routing_pending_kind == "receive" then
        sources = selected_now
        destinations = routing_pending_tracks

    else
        speak("Routing failed")
        routing_pending_reset()
        return true
    end

    local added = 0
    local skipped = 0
    local failed = 0

    for s = 1, #sources do
        local source_track = sources[s]

        for d = 1, #destinations do
            local destination_track = destinations[d]

            if source_track == destination_track then
                skipped = skipped + 1
            else
                local ok = create_track_send_instance(
                    source_track,
                    destination_track
                )

                if ok then
                    added = added + 1
                else
                    failed = failed + 1
                end
            end
        end
    end

    local kind = routing_pending_kind
    routing_pending_reset()

    build_current_grid()
    refresh_window_title()

    local word = kind == "receive" and "receives" or "sends"
    local msg = "Added " .. tostring(added) .. " " .. word .. "."

    if skipped > 0 then
        msg = msg .. " " .. tostring(skipped) .. " skipped."
    end

    if failed > 0 then
        msg = msg .. " " .. tostring(failed) .. " failed."
    end

    speak(msg)

    return true
end

function handle_add_send_shortcut()
    if current_section_id ~= SECTION_TRACKS then
        speak("Only in Tracks")
        return true
    end

    if routing_pending_is_active() then
        if routing_pending_kind ~= "send" then
            speak("Finish or cancel Add receive first")
            return true
        end

        return complete_pending_routing_with_selected_tracks()
    end

    return store_selected_tracks_for_routing("send")
end

function handle_add_receive_shortcut()
    if current_section_id ~= SECTION_TRACKS then
        speak("Only in Tracks")
        return true
    end

    if routing_pending_is_active() then
        if routing_pending_kind ~= "receive" then
            speak("Finish or cancel Add send first")
            return true
        end

        return complete_pending_routing_with_selected_tracks()
    end

    return store_selected_tracks_for_routing("receive")
end

------------------------------------------------------------
-- 2.3 - VALORI SEND / RECEIVE: VOLUME, PAN, MUTE
------------------------------------------------------------

function send_volume_range_key(track, category, index)
    if not track then
        return ""
    end

    local guid = get_track_guid(track)

    if guid == "" then
        return ""
    end

    local section = "send"

    if tonumber(category) == 0 then
        section = "send"
    elseif tonumber(category) == -1 then
        section = "receive"
    elseif tonumber(category) == HARDWARE_OUTPUT_CATEGORY then
        section = "hardware"
    else
        section = "sendcat" .. tostring(tonumber(category) or 0)
    end

    return section .. "|" .. guid .. "|" .. tostring(tonumber(index) or 0) .. "|volume"
end

function send_get_volume_norm(track, category, index)
    local vol = send_get_value(track, category, index, "D_VOL")

    vol = tonumber(vol) or 1

    return amp_to_volume_range_norm(vol, send_volume_range_key(track, category, index))
end

function send_set_volume_norm(track, category, index, norm)
    norm = clamp01(norm)

    local vol = volume_range_norm_to_amp(norm, send_volume_range_key(track, category, index))

    return send_set_value(track, category, index, "D_VOL", vol)
end

function send_get_volume_formatted(track, category, index)
    local vol = send_get_value(track, category, index, "D_VOL")

    vol = tonumber(vol) or 1

    local value = ""

    if vol <= 0 then
        value = "-inf dB"
    else
        value = format_db(amp_to_db(vol))
    end

    return append_send_receive_auto_suffix(
        value,
        track,
        category,
        index,
        "volume"
    )
end

function send_get_pan_norm(track, category, index)
    local pan = send_get_value(track, category, index, "D_PAN")

    pan = tonumber(pan) or 0

    return clamp01((pan + 1) / 2)
end

function send_set_pan_norm(track, category, index, norm)
    norm = clamp01(norm)

    local pan = (norm * 2) - 1

    return send_set_value(track, category, index, "D_PAN", pan)
end

function send_get_pan_formatted(track, category, index)
    local pan = send_get_value(track, category, index, "D_PAN")

    return append_send_receive_auto_suffix(
        format_pan(pan),
        track,
        category,
        index,
        "pan"
    )
end

function send_get_mute(track, category, index)
    local mute = send_get_value(track, category, index, "B_MUTE")

    return tonumber(mute) == 1
end

function send_set_mute(track, category, index, enabled)
    return send_set_value(track, category, index, "B_MUTE", enabled and 1 or 0)
end

------------------------------------------------------------
-- 2.3A - AUTOMATION ENVELOPE SEND / RECEIVE
--
-- REAPER espone i send/receive envelope via P_ENV:<VOLENV,
-- P_ENV:<PANENV, P_ENV:<MUTEENV in sola lettura. Per creare o
-- mostrare/nascondere veramente l'envelope usiamo il chunk della
-- traccia destinazione, dove i routing sono salvati come AUXRECV.
------------------------------------------------------------

function send_receive_auto_id_is_supported(id)
    id = clean_one_line(id or "")

    return id == "volume" or id == "pan" or id == "mute"
end

function send_receive_auto_chunk_tag_for_id(id)
    id = clean_one_line(id or "")

    if id == "volume" then
        return "AUXVOLENV"
    end

    if id == "pan" then
        return "AUXPANENV"
    end

    if id == "mute" then
        return "AUXMUTEENV"
    end

    return ""
end

function send_receive_auto_penv_name_for_id(id)
    id = clean_one_line(id or "")

    if id == "volume" then
        return "P_ENV:<VOLENV"
    end

    if id == "pan" then
        return "P_ENV:<PANENV"
    end

    if id == "mute" then
        return "P_ENV:<MUTEENV"
    end

    return ""
end

function send_receive_auto_make_key(track, receive_index, id)
    local guid = ""

    if track and reaper.GetTrackGUID then
        local ok, value = pcall(reaper.GetTrackGUID, track)

        if ok then
            guid = clean_one_line(value or "")
        end
    end

    if guid == "" then
        guid = tostring(track or "track")
    end

    return guid .. "::recv::" .. tostring(tonumber(receive_index) or -1) .. "::" .. clean_one_line(id or "")
end

function send_receive_auto_get_visible_override(track, receive_index, id)
    return nil
end


function send_receive_auto_set_visible_override(track, receive_index, id, visible)
    return true
end


function send_receive_send_occurrence(source_track, destination_track, send_index)
    if not source_track or not destination_track then
        return 0
    end

    send_index = tonumber(send_index) or -1

    if send_index < 0 then
        return 0
    end

    local occurrence = 0

    for i = 0, send_index do
        local dest = get_send_dest_track(source_track, i)

        if dest == destination_track then
            occurrence = occurrence + 1
        end
    end

    return occurrence
end

function find_receive_index_between_tracks_by_instance(source_track, destination_track, wanted_occurrence)
    if not source_track or not destination_track then
        return -1
    end

    wanted_occurrence = clamp_int(wanted_occurrence, 1, 999999)

    local count = get_track_receive_count(destination_track)
    local occurrence = 0

    for r = 0, count - 1 do
        local src = get_receive_source_track(destination_track, r)

        if src == source_track then
            occurrence = occurrence + 1

            if occurrence == wanted_occurrence then
                return r
            end
        end
    end

    return -1
end

function send_receive_resolve_chunk_target(track, category, index)
    category = tonumber(category) or 0
    index = tonumber(index) or -1

    if not track or index < 0 then
        return nil, -1
    end

    --------------------------------------------------------
    -- I send envelope sono salvati nel chunk della traccia
    -- destinazione, sotto l'AUXRECV corrispondente.
    --------------------------------------------------------
    if category == -1 then
        return track, index
    end

    local source_track = track
    local destination_track = get_send_dest_track(track, index)

    if not destination_track then
        return nil, -1
    end

    local occurrence = send_receive_send_occurrence(
        source_track,
        destination_track,
        index
    )

    if occurrence <= 0 then
        return nil, -1
    end

    local receive_index = find_receive_index_between_tracks_by_instance(
        source_track,
        destination_track,
        occurrence
    )

    if receive_index < 0 then
        return nil, -1
    end

    return destination_track, receive_index
end

function chunk_split_lines(chunk)
    local lines = {}

    chunk = tostring(chunk or "")

    for line in chunk:gmatch("[^\r\n]+") do
        lines[#lines + 1] = line
    end

    return lines
end

function send_receive_chunk_find_auxrecv_line(lines, receive_index)
    receive_index = tonumber(receive_index) or -1

    if receive_index < 0 then
        return 0
    end

    local count = -1

    for i = 1, #lines do
        if tostring(lines[i] or ""):match("^%s*AUXRECV%s") then
            count = count + 1

            if count == receive_index then
                return i
            end
        end
    end

    return 0
end

function send_receive_chunk_find_matching_env(lines, aux_line, tag)
    aux_line = tonumber(aux_line) or 0
    tag = clean_one_line(tag or "")

    if aux_line <= 0 or tag == "" then
        return 0, 0, aux_line
    end

    local insert_after = aux_line
    local i = aux_line + 1

    while i <= #lines do
        local line = tostring(lines[i] or "")

        if line:match("^%s*AUXRECV%s") then
            break
        end

        local block_tag = line:match("^%s*<([A-Z0-9_]+)")

        if block_tag then
            local start_i = i
            local end_i = i
            local depth = 1
            i = i + 1

            while i <= #lines do
                local l = tostring(lines[i] or "")

                if l:match("^%s*<") then
                    depth = depth + 1
                elseif l:match("^%s*>") then
                    depth = depth - 1

                    if depth <= 0 then
                        end_i = i
                        break
                    end
                end

                i = i + 1
            end

            ------------------------------------------------
            -- Le envelope dei send possono non essere sempre
            -- il primo blocco subito dopo AUXRECV. Pan spesso
            -- veniva trovato, mentre Volume e Mute potevano
            -- stare dopo altre righe/blocchi. Quindi si scansiona
            -- tutto il blocco del receive fino al prossimo AUXRECV.
            ------------------------------------------------
            insert_after = math.max(insert_after, end_i)

            if block_tag == tag then
                return start_i, end_i, insert_after
            end
        end

        i = i + 1
    end

    return 0, 0, insert_after
end

function send_receive_make_env_block(tag, id)
    local guid = ""

    if reaper.genGuid then
        guid = clean_one_line(reaper.genGuid(""))
    end

    if guid == "" then
        guid = "{" .. tostring(math.floor((reaper.time_precise() or os.clock()) * 1000000)) .. "}"
    end

    local current_value = 0
    id = clean_one_line(id or "")

    if id == "volume" then
        current_value = 1
    elseif id == "pan" then
        current_value = 0
    elseif id == "mute" then
        current_value = 0
    end

    return {
        "<" .. tag,
        "EGUID " .. guid,
        "ACT 1 -1",
        "VIS 1 1 1",
        "LANEHEIGHT 0 0",
        "ARM 1",
        "DEFSHAPE 0 -1 -1",
        ">"
    }
end

function send_receive_chunk_env_visible(lines, start_i, end_i)
    if start_i <= 0 or end_i <= 0 then
        return false
    end

    local act_value = nil
    local vis_value = nil

    for i = start_i + 1, end_i - 1 do
        local line = tostring(lines[i] or "")

        if act_value == nil then
            act_value = auto_line_first_number("ACT", line)
        end

        if vis_value == nil then
            vis_value = auto_line_first_number("VIS", line)
        end
    end

    if act_value ~= nil then
        return act_value ~= 0
    end

    if vis_value ~= nil then
        return vis_value ~= 0
    end

    return false
end


function send_receive_chunk_set_env_visible(lines, start_i, end_i, visible)
    if start_i <= 0 or end_i <= 0 then
        return false
    end

    return auto_chunk_lines_set_active_visible(lines, start_i, end_i, visible == true)
end


function send_receive_get_actual_envelope(track, category, index, id)
    local parm = send_receive_auto_penv_name_for_id(id)

    if parm == "" or not track or not reaper.GetTrackSendInfo_Value then
        return nil
    end

    local ok, env = pcall(
        reaper.GetTrackSendInfo_Value,
        track,
        category,
        index,
        parm
    )

    if ok and env then
        return env
    end

    return nil
end



function send_receive_automation_suffix(track, category, index, id)
    if send_receive_envelope_is_visible(track, category, index, id) then
        return "Auto"
    end

    return ""
end

function append_send_receive_auto_suffix(value, track, category, index, id)
    value = clean_one_line(value or "")

    local suffix = send_receive_automation_suffix(track, category, index, id)

    if suffix ~= "" then
        if value ~= "" then
            return value .. ". " .. suffix
        end

        return suffix
    end

    return value
end


------------------------------------------------------------
-- 2.4 - AUDIO SOURCE / DESTINATION
------------------------------------------------------------

function send_get_audio_source_value(track, category, index)
    return math.floor(
        (tonumber(send_get_value(track, category, index, "I_SRCCHAN")) or 0) + 0.5
    )
end

function send_set_audio_source_value(track, category, index, value)
    value = math.floor((tonumber(value) or 0) + 0.5)

    send_ensure_audio_source_channels(track, category, index, value)

    return send_set_value(track, category, index, "I_SRCCHAN", value)
end

function send_get_audio_destination_value(track, category, index)
    return math.floor(
        (tonumber(send_get_value(track, category, index, "I_DSTCHAN")) or 0) + 0.5
    )
end

function send_set_audio_destination_value(track, category, index, value)
    value = math.floor((tonumber(value) or 0) + 0.5)

    send_ensure_audio_destination_channels(track, category, index, value)

    return send_set_value(track, category, index, "I_DSTCHAN", value)
end

function send_get_audio_source_pair(track, category, index)
    local value = send_get_audio_source_value(track, category, index)

    return audio_src_pair_index(value)
end

function send_set_audio_source_pair(track, category, index, pair_index)
    pair_index = math.floor((tonumber(pair_index) or -1) + 0.5)

    if pair_index < 0 then
        return send_set_audio_source_value(track, category, index, -1)
    end

    pair_index = clamp_int(pair_index, 0, 63)

    local old_value = send_get_audio_source_value(track, category, index)
    local mode = audio_src_mode(old_value)
    local new_value = make_audio_src_value(pair_index, mode)

    return send_set_audio_source_value(track, category, index, new_value)
end

function send_get_audio_destination_pair(track, category, index)
    local value = send_get_audio_destination_value(track, category, index)

    return audio_dst_pair_index(value)
end

function send_set_audio_destination_pair(track, category, index, pair_index)
    pair_index = clamp_int(pair_index, 0, 63)

    local old_value = send_get_audio_destination_value(track, category, index)
    local mono = audio_dst_mono(old_value)
    local new_value = make_audio_dst_value(pair_index, mono)

    return send_set_audio_destination_value(track, category, index, new_value)
end

function send_get_audio_source_norm(track, category, index)
    return audio_source_pair_to_norm(
        send_get_audio_source_pair(track, category, index)
    )
end

function send_set_audio_source_norm(track, category, index, norm)
    return send_set_audio_source_pair(
        track,
        category,
        index,
        audio_source_norm_to_pair(norm)
    )
end

function send_get_audio_destination_norm(track, category, index)
    return routing_pair_to_norm(
        send_get_audio_destination_pair(track, category, index)
    )
end

function send_set_audio_destination_norm(track, category, index, norm)
    return send_set_audio_destination_pair(
        track,
        category,
        index,
        routing_norm_to_pair(norm)
    )
end

function send_get_audio_source_formatted(track, category, index)
    local value = send_get_audio_source_value(track, category, index)

    return format_audio_source(value)
end

function send_get_audio_destination_formatted(track, category, index)
    local value = send_get_audio_destination_value(track, category, index)

    return format_audio_destination(value)
end

function send_get_audio_source_mode(track, category, index)
    local value = send_get_audio_source_value(track, category, index)

    return audio_src_mode(value)
end

function send_set_audio_source_mode(track, category, index, mode)
    mode = clamp_int(mode, 0, 8)

    local old_value = send_get_audio_source_value(track, category, index)

    if old_value < 0 then
        return send_set_audio_source_value(track, category, index, -1)
    end

    local pair = audio_src_pair_index(old_value)
    local new_value = make_audio_src_value(pair, mode)

    return send_set_audio_source_value(track, category, index, new_value)
end

function send_get_audio_source_mode_norm(track, category, index)
    return clamp01(send_get_audio_source_mode(track, category, index) / 8)
end

function send_set_audio_source_mode_norm(track, category, index, norm)
    norm = clamp01(norm)

    return send_set_audio_source_mode(
        track,
        category,
        index,
        clamp_int(norm * 8, 0, 8)
    )
end

function send_get_audio_source_mode_formatted(track, category, index)
    local value = send_get_audio_source_value(track, category, index)

    if value < 0 then
        return "None"
    end

    local mode = audio_src_mode(value)

    if mode == 0 then
        return "Stereo"
    end

    if mode == 1 then
        return "Mono"
    end

    return tostring(mode * 2) .. " channels"
end

------------------------------------------------------------
-- 2.5 - MIDI FLAGS PER SEND / RECEIVE
------------------------------------------------------------

function send_get_midi_flags(track, category, index)
    return midi_flags_int(send_get_value(track, category, index, "I_MIDIFLAGS"))
end

function send_set_midi_flags(track, category, index, flags)
    flags = midi_flags_int(flags)

    return send_set_value(track, category, index, "I_MIDIFLAGS", flags)
end

function send_get_midi_source_channel(track, category, index)
    return midi_flags_get_source_channel(
        send_get_midi_flags(track, category, index)
    )
end

function send_set_midi_source_channel(track, category, index, ch)
    local flags = send_get_midi_flags(track, category, index)

    flags = midi_flags_set_source_channel(flags, ch)

    return send_set_midi_flags(track, category, index, flags)
end

function send_get_midi_destination_channel(track, category, index)
    return midi_flags_get_dest_channel(
        send_get_midi_flags(track, category, index)
    )
end

function send_set_midi_destination_channel(track, category, index, ch)
    local flags = send_get_midi_flags(track, category, index)

    flags = midi_flags_set_dest_channel(flags, ch)

    return send_set_midi_flags(track, category, index, flags)
end

function send_get_midi_source_bus(track, category, index)
    return midi_flags_get_source_bus(
        send_get_midi_flags(track, category, index)
    )
end

function send_set_midi_source_bus(track, category, index, bus)
    local flags = send_get_midi_flags(track, category, index)

    flags = midi_flags_set_source_bus(flags, bus)

    return send_set_midi_flags(track, category, index, flags)
end

function send_get_midi_destination_bus(track, category, index)
    return midi_flags_get_dest_bus(
        send_get_midi_flags(track, category, index)
    )
end

function send_set_midi_destination_bus(track, category, index, bus)
    local flags = send_get_midi_flags(track, category, index)

    flags = midi_flags_set_dest_bus(flags, bus)

    return send_set_midi_flags(track, category, index, flags)
end

function send_get_midi_fader_send(track, category, index)
    return midi_flags_get_fader_send(
        send_get_midi_flags(track, category, index)
    )
end

function send_set_midi_fader_send(track, category, index, enabled)
    local flags = send_get_midi_flags(track, category, index)

    flags = midi_flags_set_fader_send(flags, enabled)

    return send_set_midi_flags(track, category, index, flags)
end

function send_get_midi_source_channel_norm(track, category, index)
    return midi_source_channel_to_norm(
        send_get_midi_source_channel(track, category, index)
    )
end

function send_set_midi_source_channel_norm(track, category, index, norm)
    return send_set_midi_source_channel(
        track,
        category,
        index,
        midi_norm_to_source_channel(norm)
    )
end

function send_get_midi_destination_channel_norm(track, category, index)
    return midi_destination_channel_to_norm(
        send_get_midi_destination_channel(track, category, index)
    )
end

function send_set_midi_destination_channel_norm(track, category, index, norm)
    return send_set_midi_destination_channel(
        track,
        category,
        index,
        midi_norm_to_destination_channel(norm)
    )
end

function send_get_midi_source_bus_norm(track, category, index)
    return midi_bus_to_norm(
        send_get_midi_source_bus(track, category, index)
    )
end

function send_set_midi_source_bus_norm(track, category, index, norm)
    return send_set_midi_source_bus(
        track,
        category,
        index,
        midi_norm_to_bus(norm)
    )
end

function send_get_midi_destination_bus_norm(track, category, index)
    return midi_bus_to_norm(
        send_get_midi_destination_bus(track, category, index)
    )
end

function send_set_midi_destination_bus_norm(track, category, index, norm)
    return send_set_midi_destination_bus(
        track,
        category,
        index,
        midi_norm_to_bus(norm)
    )
end

function send_get_midi_source_channel_formatted(track, category, index)
    return midi_source_channel_to_name(
        send_get_midi_source_channel(track, category, index)
    )
end

function send_get_midi_destination_channel_formatted(track, category, index)
    return midi_destination_channel_to_name(
        send_get_midi_destination_channel(track, category, index)
    )
end

function send_get_midi_source_bus_formatted(track, category, index)
    return midi_bus_to_name(
        send_get_midi_source_bus(track, category, index)
    )
end

function send_get_midi_destination_bus_formatted(track, category, index)
    return midi_bus_to_name(
        send_get_midi_destination_bus(track, category, index)
    )
end

function send_get_midi_follows_fader_norm(track, category, index)
    return send_get_midi_fader_send(track, category, index) and 1 or 0
end

function send_set_midi_follows_fader_norm(track, category, index, norm)
    return send_set_midi_fader_send(
        track,
        category,
        index,
        clamp01(norm) >= 0.5
    )
end

function send_get_midi_follows_fader_formatted(track, category, index)
    return bool_to_on_off(send_get_midi_fader_send(track, category, index))
end

function send_get_midi_merge_formatted(track, category, index)
    --------------------------------------------------------
    -- In REAPER il MIDI ricevuto attraverso send/receive entra
    -- nel flusso MIDI della traccia di destinazione. Non e' un
    -- pin del singolo FX: e' comportamento del routing.
    -- Se la sorgente MIDI e' None, per l'utente il merge e' off.
    --------------------------------------------------------
    local src = send_get_midi_source_channel(track, category, index)

    if src == 31 then
        return "Off"
    end

    return "On"
end

------------------------------------------------------------
-- 2.6 - SEND TYPE
------------------------------------------------------------

function send_get_mode(track, category, index)
    local mode = send_get_value(track, category, index, "I_SENDMODE")

    return clamp_int(mode, 0, 3)
end

function send_set_mode(track, category, index, mode)
    mode = clamp_int(mode, 0, 3)

    return send_set_value(track, category, index, "I_SENDMODE", mode)
end

function send_get_mode_norm(track, category, index)
    return send_mode_to_norm(send_get_mode(track, category, index))
end

function send_set_mode_norm(track, category, index, norm)
    return send_set_mode(track, category, index, send_norm_to_mode(norm))
end

function send_get_mode_formatted(track, category, index)
    return send_mode_to_name(send_get_mode(track, category, index))
end

------------------------------------------------------------
-- 2.7 - FILTRO SEND / RECEIVE
------------------------------------------------------------

function send_receive_filter_text(track, category, index)
    local parts = {}

    local direction_label = category == 0 and "Send" or "Receive"
    local number = (tonumber(index) or 0) + 1
    local peer_label = get_track_send_target_label(track, category, index)

    parts[#parts + 1] = direction_label
    parts[#parts + 1] = direction_label .. " " .. tostring(number)
    parts[#parts + 1] = peer_label

    if category == 0 then
        parts[#parts + 1] = "Send to " .. peer_label
    else
        parts[#parts + 1] = "Receive from " .. peer_label
    end

    parts[#parts + 1] = "Volume"
    parts[#parts + 1] = send_get_volume_formatted(track, category, index)

    parts[#parts + 1] = "Pan"
    parts[#parts + 1] = send_get_pan_formatted(track, category, index)

    parts[#parts + 1] = "Mute"
    parts[#parts + 1] = bool_to_on_off(send_get_mute(track, category, index))

    parts[#parts + 1] = "Audio source mode"
    parts[#parts + 1] = send_get_audio_source_mode_formatted(track, category, index)

    parts[#parts + 1] = "Audio source"
    parts[#parts + 1] = send_get_audio_source_formatted(track, category, index)

    parts[#parts + 1] = "Audio destination"
    parts[#parts + 1] = send_get_audio_destination_formatted(track, category, index)

    parts[#parts + 1] = "Send type"
    parts[#parts + 1] = send_get_mode_formatted(track, category, index)

    parts[#parts + 1] = "MIDI source"
    parts[#parts + 1] = send_get_midi_source_channel_formatted(track, category, index)

    parts[#parts + 1] = "MIDI destination"
    parts[#parts + 1] = send_get_midi_destination_channel_formatted(track, category, index)

    parts[#parts + 1] = "MIDI source bus"
    parts[#parts + 1] = send_get_midi_source_bus_formatted(track, category, index)

    parts[#parts + 1] = "MIDI destination bus"
    parts[#parts + 1] = send_get_midi_destination_bus_formatted(track, category, index)

    parts[#parts + 1] = "MIDI follows fader"
    parts[#parts + 1] = send_get_midi_follows_fader_formatted(track, category, index)

    parts[#parts + 1] = "MIDI merge"
    parts[#parts + 1] = send_get_midi_merge_formatted(track, category, index)

    return table.concat(parts, " ")
end

function send_receive_matches_current_filter(track, category, index)
    if not filter_is_active() then
        return true
    end

    return text_matches_filter(
        send_receive_filter_text(track, category, index),
        get_filter_query()
    )
end

function send_receive_peer_key(track, category, index)
    local peer = nil

    if category == 0 then
        peer = get_send_dest_track(track, index)
    else
        peer = get_receive_source_track(track, index)
    end

    if peer then
        local guid = get_track_guid(peer)

        if guid ~= "" then
            return guid
        end

        return get_track_short_label(peer)
    end

    if category == 0 then
        return "no-destination"
    end

    return "no-source"
end

------------------------------------------------------------
-- 2.8 - INDICE SEND REALE PER RECEIVE
------------------------------------------------------------

function get_receive_real_send_index(destination_track, receive_index)
    if not destination_track then
        return -1
    end

    receive_index = tonumber(receive_index) or -1

    if receive_index < 0 then
        return -1
    end

    local source_track = get_receive_source_track(destination_track, receive_index)

    if not source_track then
        return -1
    end

    local occurrence = 0

    for r = 0, receive_index do
        local src = get_receive_source_track(destination_track, r)

        if src == source_track then
            occurrence = occurrence + 1
        end
    end

    if occurrence <= 0 then
        return -1
    end

    return find_send_index_between_tracks_by_instance(
        source_track,
        destination_track,
        occurrence
    )
end

------------------------------------------------------------
-- 2.9 - BUILD SEND / RECEIVE GRID
--
-- Ogni send / receive è una colonna.
--
-- 1  Send/Receive header + traccia collegata
-- 2  Volume
-- 3  Pan
-- 4  Mute
-- 5  Audio source mode
-- 6  Audio source
-- 7  Audio destination
-- 8  Send type
-- 9  MIDI source
-- 10 MIDI destination
-- 11 MIDI source bus
-- 12 MIDI destination bus
-- 13 MIDI follows fader
-- 14 MIDI merge
------------------------------------------------------------

function add_send_block_to_grid(track, category, index, display_index)
    if not track then
        return false
    end

    category = tonumber(category) or 0
    index = tonumber(index) or 0

    local direction_label = category == 0 and "Send" or "Receive"
    local peer_track = nil
    local source_track = nil
    local destination_track = nil
    local real_send_index = index

    if category == 0 then
        source_track = track
        destination_track = get_send_dest_track(track, index)
        peer_track = destination_track
        real_send_index = index
    else
        destination_track = track
        source_track = get_receive_source_track(track, index)
        peer_track = source_track
        real_send_index = get_receive_real_send_index(track, index)
    end

    local peer_label = get_track_send_target_label(track, category, index)

    local source_guid = get_track_guid(source_track)
    local destination_guid = get_track_guid(destination_track)

    local number = tonumber(display_index) or (index + 1)

    local function apply_common_fields(t)
        t.category = category
        t.send_index = index
        t.display_index = number
        t.peer_track = peer_track
        t.source_track = source_track
        t.destination_track = destination_track
        t.source_guid = source_guid
        t.destination_guid = destination_guid
        t.real_send_index = real_send_index

        ----------------------------------------------------
        -- Enter su qualunque voce della colonna Send/Receive
        -- apre la routing gemella sulla traccia collegata:
        -- Send -> Receive della destinazione,
        -- Receive -> Send della sorgente.
        -- L'editing resta su Alt+frecce, Ctrl+E, Ctrl+V.
        ----------------------------------------------------
        if t.enter == nil then
            t.enter = function(e)
                return enter_send_receive_peer_track(e)
            end
        end

        return t
    end

    grid_entries[#grid_entries + 1] = apply_common_fields({
        kind = "send_header",

        label = direction_label .. " " .. tostring(number),
        value = (category == 0 and "to " or "from ") .. peer_label,

        enter = function(e)
            return enter_send_receive_peer_track(e)
        end
    })

    grid_entries[#grid_entries + 1] = apply_common_fields({
        kind = "send_param",
        id = "volume",
        value_kind = "continuous",

        label = "Volume",

        value = function(e)
            return send_get_volume_formatted(track, e.category, e.send_index)
        end,

        get_norm = function(e)
            return send_get_volume_norm(track, e.category, e.send_index)
        end,

        set_norm = function(e, norm)
            return send_set_volume_norm(track, e.category, e.send_index, norm)
        end
    })

    grid_entries[#grid_entries + 1] = apply_common_fields({
        kind = "send_param",
        id = "pan",
        value_kind = "continuous",

        label = "Pan",

        value = function(e)
            return send_get_pan_formatted(track, e.category, e.send_index)
        end,

        get_norm = function(e)
            return send_get_pan_norm(track, e.category, e.send_index)
        end,

        set_norm = function(e, norm)
            return send_set_pan_norm(track, e.category, e.send_index, norm)
        end
    })

    grid_entries[#grid_entries + 1] = apply_common_fields({
        kind = "send_param",
        id = "mute",
        value_kind = "bool",

        label = "Mute",

        value = function(e)
            return append_send_receive_auto_suffix(
                bool_to_on_off(send_get_mute(track, e.category, e.send_index)),
                track,
                e.category,
                e.send_index,
                "mute"
            )
        end,

        get_norm = function(e)
            return send_get_mute(track, e.category, e.send_index) and 1 or 0
        end,

        set_norm = function(e, norm)
            local enabled = clamp01(norm) >= 0.5

            return send_set_mute(track, e.category, e.send_index, enabled)
        end
    })

    grid_entries[#grid_entries + 1] = apply_common_fields({
        kind = "send_param",
        id = "audio_source_mode",
        value_kind = "stepped",

        label = "Audio source mode",

        value = function(e)
            return send_get_audio_source_mode_formatted(track, e.category, e.send_index)
        end,

        get_norm = function(e)
            return send_get_audio_source_mode_norm(track, e.category, e.send_index)
        end,

        set_norm = function(e, norm)
            return send_set_audio_source_mode_norm(track, e.category, e.send_index, norm)
        end,

        step = function(e, direction)
            local old_mode = send_get_audio_source_mode(track, e.category, e.send_index)
            local new_mode = old_mode

            if direction > 0 then
                new_mode = old_mode + 1
            elseif direction < 0 then
                new_mode = old_mode - 1
            end

            new_mode = clamp_int(new_mode, 0, 8)

            return send_set_audio_source_mode(track, e.category, e.send_index, new_mode)
        end
    })

    grid_entries[#grid_entries + 1] = apply_common_fields({
        kind = "send_param",
        id = "audio_source",
        value_kind = "routing_pair",

        label = "Audio source",

        value = function(e)
            return send_get_audio_source_formatted(track, e.category, e.send_index)
        end,

        get_norm = function(e)
            return send_get_audio_source_norm(track, e.category, e.send_index)
        end,

        set_norm = function(e, norm)
            return send_set_audio_source_norm(track, e.category, e.send_index, norm)
        end,

        step = function(e, direction)
            local old_pair = send_get_audio_source_pair(track, e.category, e.send_index)
            local new_pair = audio_source_pair_step_from_direction(old_pair, direction)

            return send_set_audio_source_pair(track, e.category, e.send_index, new_pair)
        end
    })

    grid_entries[#grid_entries + 1] = apply_common_fields({
        kind = "send_param",
        id = "audio_destination",
        value_kind = "routing_pair",

        label = "Audio destination",

        value = function(e)
            return send_get_audio_destination_formatted(track, e.category, e.send_index)
        end,

        get_norm = function(e)
            return send_get_audio_destination_norm(track, e.category, e.send_index)
        end,

        set_norm = function(e, norm)
            return send_set_audio_destination_norm(track, e.category, e.send_index, norm)
        end,

        step = function(e, direction)
            local old_pair = send_get_audio_destination_pair(track, e.category, e.send_index)
            local new_pair = routing_pair_step_from_direction(old_pair, direction)

            return send_set_audio_destination_pair(track, e.category, e.send_index, new_pair)
        end
    })

    grid_entries[#grid_entries + 1] = apply_common_fields({
        kind = "send_param",
        id = "send_type",
        value_kind = "stepped",

        label = "Send type",

        value = function(e)
            return send_get_mode_formatted(track, e.category, e.send_index)
        end,

        get_norm = function(e)
            return send_get_mode_norm(track, e.category, e.send_index)
        end,

        set_norm = function(e, norm)
            return send_set_mode_norm(track, e.category, e.send_index, norm)
        end,

        step = function(e, direction)
            local old_mode = send_get_mode(track, e.category, e.send_index)
            local new_mode = send_mode_step(old_mode, direction)

            return send_set_mode(track, e.category, e.send_index, new_mode)
        end
    })

    grid_entries[#grid_entries + 1] = apply_common_fields({
        kind = "send_param",
        id = "midi_source",
        value_kind = "stepped",

        label = "MIDI source",

        value = function(e)
            return send_get_midi_source_channel_formatted(track, e.category, e.send_index)
        end,

        get_norm = function(e)
            return send_get_midi_source_channel_norm(track, e.category, e.send_index)
        end,

        set_norm = function(e, norm)
            return send_set_midi_source_channel_norm(track, e.category, e.send_index, norm)
        end,

        step = function(e, direction)
            local old_ch = send_get_midi_source_channel(track, e.category, e.send_index)
            local new_ch = midi_source_channel_step(old_ch, direction)

            return send_set_midi_source_channel(track, e.category, e.send_index, new_ch)
        end
    })

    grid_entries[#grid_entries + 1] = apply_common_fields({
        kind = "send_param",
        id = "midi_destination",
        value_kind = "stepped",

        label = "MIDI destination",

        value = function(e)
            return send_get_midi_destination_channel_formatted(track, e.category, e.send_index)
        end,

        get_norm = function(e)
            return send_get_midi_destination_channel_norm(track, e.category, e.send_index)
        end,

        set_norm = function(e, norm)
            return send_set_midi_destination_channel_norm(track, e.category, e.send_index, norm)
        end,

        step = function(e, direction)
            local old_ch = send_get_midi_destination_channel(track, e.category, e.send_index)
            local new_ch = midi_destination_channel_step(old_ch, direction)

            return send_set_midi_destination_channel(track, e.category, e.send_index, new_ch)
        end
    })

    grid_entries[#grid_entries + 1] = apply_common_fields({
        kind = "send_param",
        id = "midi_source_bus",
        value_kind = "stepped",

        label = "MIDI source bus",

        value = function(e)
            return send_get_midi_source_bus_formatted(track, e.category, e.send_index)
        end,

        get_norm = function(e)
            return send_get_midi_source_bus_norm(track, e.category, e.send_index)
        end,

        set_norm = function(e, norm)
            return send_set_midi_source_bus_norm(track, e.category, e.send_index, norm)
        end,

        step = function(e, direction)
            local old_bus = send_get_midi_source_bus(track, e.category, e.send_index)
            local new_bus = midi_bus_step(old_bus, direction)

            return send_set_midi_source_bus(track, e.category, e.send_index, new_bus)
        end
    })

    grid_entries[#grid_entries + 1] = apply_common_fields({
        kind = "send_param",
        id = "midi_destination_bus",
        value_kind = "stepped",

        label = "MIDI destination bus",

        value = function(e)
            return send_get_midi_destination_bus_formatted(track, e.category, e.send_index)
        end,

        get_norm = function(e)
            return send_get_midi_destination_bus_norm(track, e.category, e.send_index)
        end,

        set_norm = function(e, norm)
            return send_set_midi_destination_bus_norm(track, e.category, e.send_index, norm)
        end,

        step = function(e, direction)
            local old_bus = send_get_midi_destination_bus(track, e.category, e.send_index)
            local new_bus = midi_bus_step(old_bus, direction)

            return send_set_midi_destination_bus(track, e.category, e.send_index, new_bus)
        end
    })

    grid_entries[#grid_entries + 1] = apply_common_fields({
        kind = "send_param",
        id = "midi_follows_fader",
        value_kind = "bool",

        label = "MIDI follows fader",

        value = function(e)
            return send_get_midi_follows_fader_formatted(track, e.category, e.send_index)
        end,

        get_norm = function(e)
            return send_get_midi_follows_fader_norm(track, e.category, e.send_index)
        end,

        set_norm = function(e, norm)
            return send_set_midi_follows_fader_norm(track, e.category, e.send_index, norm)
        end
    })

    grid_entries[#grid_entries + 1] = apply_common_fields({
        kind = "send_param",
        id = "midi_merge",

        label = "MIDI merge",

        value = function(e)
            return send_get_midi_merge_formatted(track, e.category, e.send_index)
        end,

        enter = function(e)
            speak("MIDI merge belongs to send and receive routing")
            return true
        end
    })

    return true
end

function build_sends_grid()
    grid_entries = {}

    if not current_track then
        grid_size = SEND_GRID_SIZE
        grid_pos = 1
        return false
    end

    local count = get_track_send_count(current_track)
    local peer_counters = {}

    for i = 0, count - 1 do
        if send_receive_matches_current_filter(current_track, 0, i) then
            local key = send_receive_peer_key(current_track, 0, i)

            peer_counters[key] = (peer_counters[key] or 0) + 1

            add_send_block_to_grid(
                current_track,
                0,
                i,
                peer_counters[key]
            )
        end
    end

    grid_size = SEND_GRID_SIZE
    grid_pos = clamp_int(grid_pos, 1, math.max(1, #grid_entries))

    return #grid_entries > 0
end

function build_receives_grid()
    grid_entries = {}

    if not current_track then
        grid_size = RECEIVE_GRID_SIZE
        grid_pos = 1
        return false
    end

    local count = get_track_receive_count(current_track)
    local peer_counters = {}

    for i = 0, count - 1 do
        if send_receive_matches_current_filter(current_track, -1, i) then
            local key = send_receive_peer_key(current_track, -1, i)

            peer_counters[key] = (peer_counters[key] or 0) + 1

            add_send_block_to_grid(
                current_track,
                -1,
                i,
                peer_counters[key]
            )
        end
    end

    grid_size = RECEIVE_GRID_SIZE
    grid_pos = clamp_int(grid_pos, 1, math.max(1, #grid_entries))

    return #grid_entries > 0
end

------------------------------------------------------------
-- FINE PARTE 2 / 5
------------------------------------------------------------

------------------------------------------------------------
-- PARTE 3 / 5
-- FX PARAMS TCP VISIBILI, TRACK CONTROLS,
-- BUILD GRID DISPATCH, NAVIGAZIONE GRIGLIA, LETTER JUMP
------------------------------------------------------------

------------------------------------------------------------
-- 3.1 - FX PARAM HELPERS
------------------------------------------------------------

function fx_get_name(track, fx_index)
    if not track then
        return ""
    end

    fx_index = tonumber(fx_index) or 0

    local ok, name = reaper.TrackFX_GetFXName(track, fx_index, "")

    if ok then
        name = clean_one_line(name or "")

        if name ~= "" then
            return name
        end
    end

    return "FX " .. tostring(fx_index + 1)
end


function fx_alias_escape_chunk_string(s)
    s = tostring(s or "")
    s = s:gsub("\\", "\\\\")
    s = s:gsub("\"", "\\\"")
    return "\"" .. s .. "\""
end

function fx_alias_unescape_chunk_string(s)
    s = tostring(s or "")
    s = s:gsub("\\\"", "\"")
    s = s:gsub("\\\\", "\\")
    return s
end

function fx_get_param_alias(track, fx_index, param_index)
    if not track then
        return ""
    end

    fx_index = tonumber(fx_index) or -1
    param_index = tonumber(param_index) or -1

    if fx_index < 0 or param_index < 0 then
        return ""
    end

    if not reaper.GetTrackStateChunk then
        return ""
    end

    local ok, chunk = reaper.GetTrackStateChunk(track, "", false)

    if not ok or not chunk or chunk == "" then
        return ""
    end

    local lines = fx_chunk_split_lines(chunk)
    local fx_start, fx_end = fx_chunk_find_fx_block(lines, fx_index)

    if fx_start <= 0 or fx_end <= 0 then
        return ""
    end

    for i = fx_start + 1, fx_end do
        local line = tostring(lines[i] or "")
        local idx, quoted = line:match("^%s*PARMALIAS%s+(%-?%d+)%s+\"(.*)\"%s*$")

        if tonumber(idx) == param_index then
            return clean_one_line(fx_alias_unescape_chunk_string(quoted or ""))
        end
    end

    return ""
end

function fx_set_param_alias(track, fx_index, param_index, alias)
    if not track then
        return false
    end

    fx_index = tonumber(fx_index) or -1
    param_index = tonumber(param_index) or -1
    alias = clean_one_line(alias or "")

    if fx_index < 0 or param_index < 0 then
        return false
    end

    if not reaper.GetTrackStateChunk or not reaper.SetTrackStateChunk then
        return false
    end

    local ok, chunk = reaper.GetTrackStateChunk(track, "", false)

    if not ok or not chunk or chunk == "" then
        return false
    end

    local lines = fx_chunk_split_lines(chunk)

    if #lines <= 0 then
        return false
    end

    local fx_start, fx_end = fx_chunk_find_fx_block(lines, fx_index)

    if fx_start <= 0 or fx_end <= 0 then
        return false
    end

    --------------------------------------------------------
    -- Elimina eventuale alias precedente per lo stesso
    -- parametro. PARMALIAS usa l'indice parametro REAPER.
    --------------------------------------------------------
    local changed = false
    local removed_count = 0

    for i = fx_end, fx_start + 1, -1 do
        local line = tostring(lines[i] or "")
        local idx = line:match("^%s*PARMALIAS%s+(%-?%d+)%s+")

        if tonumber(idx) == param_index then
            table.remove(lines, i)
            removed_count = removed_count + 1
            changed = true
        end
    end

    fx_end = math.max(fx_start, fx_end - removed_count)

    if alias ~= "" then
        local insert_pos = fx_chunk_insert_pos_for_parm_tcp(
            lines,
            fx_start,
            fx_end
        )

        if insert_pos > #lines then
            insert_pos = #lines
        end

        table.insert(
            lines,
            insert_pos + 1,
            "PARMALIAS " ..
            tostring(param_index) ..
            " " ..
            fx_alias_escape_chunk_string(alias)
        )

        changed = true
    end

    if not changed then
        return true
    end

    local new_chunk = table.concat(lines, "\n") .. "\n"
    local set_ok = reaper.SetTrackStateChunk(track, new_chunk, false)

    if not set_ok then
        return false
    end

    if reaper.MarkProjectDirty then
        reaper.MarkProjectDirty(0)
    end

    reaper.TrackList_AdjustWindows(false)
    reaper.UpdateArrange()

    return true
end

function f4_auto_make_key(track, fx_index, param_index)
    local guid = ""

    if track and reaper.GetTrackGUID then
        local ok, value = pcall(reaper.GetTrackGUID, track)

        if ok then
            guid = clean_one_line(value or "")
        end
    end

    if guid == "" then
        guid = tostring(track or "track")
    end

    return
        guid ..
        "::" ..
        tostring(tonumber(fx_index) or -1) ..
        "::" ..
        tostring(tonumber(param_index) or -1)
end

function f4_auto_get_visible_override(track, fx_index, param_index)
    return nil
end


function f4_auto_set_visible_override(track, fx_index, param_index, visible)
    return true
end


function fx_param_envelope_exists(track, fx_index, param_index)
    if not track or not reaper.GetFXEnvelope then
        return false
    end

    fx_index = tonumber(fx_index) or -1
    param_index = tonumber(param_index) or -1

    if fx_index < 0 or param_index < 0 then
        return false
    end

    local env = reaper.GetFXEnvelope(
        track,
        fx_index,
        param_index,
        false
    )

    return env ~= nil
end


function fx_param_envelope_is_visible(track, fx_index, param_index)
    if not track or not reaper.GetFXEnvelope then
        return false
    end

    fx_index = tonumber(fx_index) or -1
    param_index = tonumber(param_index) or -1

    if fx_index < 0 or param_index < 0 then
        return false
    end

    local env = reaper.GetFXEnvelope(
        track,
        fx_index,
        param_index,
        false
    )

    if not env then
        return false
    end

    return auto_envelope_is_active(env)
end


function fx_param_automation_suffix(track, fx_index, param_index)
    if fx_param_envelope_is_visible(track, fx_index, param_index) then
        return "Auto"
    end

    return ""
end

function fx_touch_param_for_reaper(track, fx_index, param_index)
    if not track or
       not reaper.TrackFX_GetParamNormalized or
       not reaper.TrackFX_SetParamNormalized then

        return false
    end

    fx_index = tonumber(fx_index) or -1
    param_index = tonumber(param_index) or -1

    if fx_index < 0 or param_index < 0 then
        return false
    end

    local old_v = reaper.TrackFX_GetParamNormalized(
        track,
        fx_index,
        param_index
    )

    old_v = clamp01(old_v)

    local touch_v

    if old_v < 0.999999 then
        touch_v = old_v + 0.000001
    else
        touch_v = old_v - 0.000001
    end

    touch_v = clamp01(touch_v)

    reaper.TrackFX_SetParamNormalized(
        track,
        fx_index,
        param_index,
        touch_v
    )

    reaper.TrackFX_SetParamNormalized(
        track,
        fx_index,
        param_index,
        old_v
    )

    return true
end


function fx_set_param_envelope_auto(track, fx_index, param_index, active, create)
    if not track or not reaper.GetFXEnvelope then
        return false
    end

    fx_index = tonumber(fx_index) or -1
    param_index = tonumber(param_index) or -1

    if fx_index < 0 or param_index < 0 then
        return false
    end

    local env = reaper.GetFXEnvelope(
        track,
        fx_index,
        param_index,
        create == true
    )

    if not env then
        return false
    end

    return auto_envelope_set_active_visible(env, active == true)
end

function fx_show_or_hide_param_envelope(track, fx_index, param_index)
    if not track then
        return false
    end

    local before_active = fx_param_envelope_is_visible(
        track,
        fx_index,
        param_index
    )

    local target_active = not before_active

    return fx_set_param_envelope_auto(
        track,
        fx_index,
        param_index,
        target_active,
        true
    )
end


function fx_get_param_name(track, fx_index, param_index)
    if not track then
        return ""
    end

    fx_index = tonumber(fx_index) or 0
    param_index = tonumber(param_index) or 0

    local alias = ""

    if type(fx_get_param_alias) == "function" then
        alias = fx_get_param_alias(track, fx_index, param_index)
    end

    if alias ~= "" then
        return alias
    end

    local ok, name = reaper.TrackFX_GetParamName(
        track,
        fx_index,
        param_index,
        ""
    )

    if ok then
        name = clean_one_line(name or "")

        if name ~= "" then
            return name
        end
    end

    return "Param " .. tostring(param_index + 1)
end

function fx_get_param_value(track, fx_index, param_index)
    if not track then
        return ""
    end

    fx_index = tonumber(fx_index) or 0
    param_index = tonumber(param_index) or 0

    local ok, value = reaper.TrackFX_GetFormattedParamValue(
        track,
        fx_index,
        param_index,
        ""
    )

    local suffix = ""

    if type(fx_param_automation_suffix) == "function" then
        suffix = fx_param_automation_suffix(track, fx_index, param_index)
    end

    if ok then
        value = clean_one_line(value or "")

        if value ~= "" then
            if suffix ~= "" then
                return value .. ". " .. suffix
            end

            return value
        end
    end

    local norm = reaper.TrackFX_GetParamNormalized(
        track,
        fx_index,
        param_index
    )

    value = tostring(norm or 0)

    if suffix ~= "" then
        return value .. ". " .. suffix
    end

    return value
end

function fx_get_param_norm(track, fx_index, param_index)
    if not track then
        return 0
    end

    fx_index = tonumber(fx_index) or 0
    param_index = tonumber(param_index) or 0

    local value = reaper.TrackFX_GetParamNormalized(
        track,
        fx_index,
        param_index
    )

    return clamp01(value)
end

function fx_set_param_norm(track, fx_index, param_index, norm)
    if not track then
        return false
    end

    fx_index = tonumber(fx_index) or 0
    param_index = tonumber(param_index) or 0
    norm = clamp01(norm)

    reaper.TrackFX_SetParamNormalized(
        track,
        fx_index,
        param_index,
        norm
    )

    reaper.TrackList_AdjustWindows(false)
    reaper.UpdateArrange()

    return true
end

function fx_get_param_count(track, fx_index)
    if not track then
        return 0
    end

    fx_index = tonumber(fx_index) or 0

    return reaper.TrackFX_GetNumParams(track, fx_index) or 0
end

------------------------------------------------------------
-- 3.1.1 - FX BYPASS / DELTA SOLO HELPERS
--
-- Regola parlato:
-- - se Bypass / Delta Solo non sono attivi, non si aggiunge
--   nulla al messaggio normale.
-- - se Delta Solo è attivo: "Enabled Delta Solo."
-- - se Bypass è attivo: "Bypassed."
-- - se entrambi: "Enabled Delta Solo. Bypassed."
------------------------------------------------------------

function fx_is_bypassed(track, fx_index)
    if not track then
        return false
    end

    fx_index = tonumber(fx_index) or -1

    if fx_index < 0 then
        return false
    end

    if not reaper.TrackFX_GetEnabled then
        return false
    end

    return reaper.TrackFX_GetEnabled(track, fx_index) ~= true
end

function fx_set_bypassed(track, fx_index, bypassed)
    if not track then
        return false
    end

    fx_index = tonumber(fx_index) or -1

    if fx_index < 0 then
        return false
    end

    if not reaper.TrackFX_SetEnabled then
        return false
    end

    reaper.TrackFX_SetEnabled(track, fx_index, not bypassed)

    reaper.TrackList_AdjustWindows(false)
    reaper.UpdateArrange()

    return true
end

function fx_toggle_bypass(track, fx_index)
    if not track then
        return false, false
    end

    local new_bypassed = not fx_is_bypassed(track, fx_index)

    if fx_set_bypassed(track, fx_index, new_bypassed) then
        return true, new_bypassed
    end

    return false, false
end

function fx_get_delta_param_index(track, fx_index)
    if not track then
        return -1
    end

    fx_index = tonumber(fx_index) or -1

    if fx_index < 0 then
        return -1
    end

    if not reaper.TrackFX_GetParamFromIdent then
        return -1
    end

    local ok, param_index = pcall(
        reaper.TrackFX_GetParamFromIdent,
        track,
        fx_index,
        ":delta"
    )

    if not ok then
        return -1
    end

    param_index = tonumber(param_index) or -1

    return param_index
end

function fx_delta_solo_available(track, fx_index)
    return fx_get_delta_param_index(track, fx_index) >= 0
end

function fx_delta_solo_enabled(track, fx_index)
    if not track then
        return false
    end

    local param_index = fx_get_delta_param_index(track, fx_index)

    if param_index < 0 then
        return false
    end

    local value = reaper.TrackFX_GetParamNormalized(
        track,
        fx_index,
        param_index
    )

    return (tonumber(value) or 0) >= 0.5
end

function fx_set_delta_solo(track, fx_index, enabled)
    if not track then
        return false
    end

    local param_index = fx_get_delta_param_index(track, fx_index)

    if param_index < 0 then
        return false
    end

    reaper.TrackFX_SetParamNormalized(
        track,
        fx_index,
        param_index,
        enabled and 1 or 0
    )

    reaper.TrackList_AdjustWindows(false)
    reaper.UpdateArrange()

    return true
end

function fx_toggle_delta_solo(track, fx_index)
    if not fx_delta_solo_available(track, fx_index) then
        return false, false
    end

    local new_enabled = not fx_delta_solo_enabled(track, fx_index)

    if fx_set_delta_solo(track, fx_index, new_enabled) then
        return true, new_enabled
    end

    return false, false
end

function fx_status_prefix(track, fx_index)
    if not track then
        return ""
    end

    fx_index = tonumber(fx_index) or -1

    if fx_index < 0 then
        return ""
    end

    local parts = {}

    --------------------------------------------------------
    -- Ordine richiesto:
    -- Enabled Delta Solo. Bypassed.
    --------------------------------------------------------

    if fx_delta_solo_enabled(track, fx_index) then
        parts[#parts + 1] = "Enabled Delta Solo"
    end

    if fx_is_bypassed(track, fx_index) then
        parts[#parts + 1] = "Bypassed"
    end

    --------------------------------------------------------
    -- Se non è attivo nulla, non aggiungiamo nulla:
    -- il messaggio resta identico a prima.
    --------------------------------------------------------

    if #parts <= 0 then
        return ""
    end

    return table.concat(parts, ". ") .. ". "
end

function fx_status_label_for_entry(entry)
    if not entry then
        return ""
    end

    if current_section_id ~= SECTION_FX_PARAMS then
        return ""
    end

    if entry.fx_index == nil then
        return ""
    end

    return fx_status_prefix(entry.track or current_track, entry.fx_index)
end

function current_f4_entry_fx_track_and_index()
    if current_section_id ~= SECTION_FX_PARAMS then
        return nil, -1
    end

    local e = get_current_entry()

    if not e then
        return nil, -1
    end

    if e.fx_index == nil then
        return nil, -1
    end

    local track = e.track or current_track
    local fx_index = tonumber(e.fx_index) or -1

    if not track or fx_index < 0 then
        return nil, -1
    end

    return track, fx_index
end

function speak_fx_current_status_action(action_text, track, fx_index)
    action_text = clean_one_line(action_text or "")

    local fx_name = fx_get_name(track, fx_index)
    local status = fx_status_prefix(track, fx_index)

    if status ~= "" then
        speak(action_text .. ". " .. status .. fx_name)
    else
        speak(action_text .. ". " .. fx_name)
    end

    return true
end

function toggle_current_f4_fx_bypass()
    local track, fx_index = current_f4_entry_fx_track_and_index()

    if not track or fx_index < 0 then
        speak("No FX")
        return true
    end

    local ok, bypassed = fx_toggle_bypass(track, fx_index)

    if not ok then
        speak("Bypass not available")
        return true
    end

    refresh_window_title()

    if bypassed then
        return speak_fx_current_status_action("Bypass on", track, fx_index)
    end

    return speak_fx_current_status_action("Bypass off", track, fx_index)
end

function toggle_current_f4_fx_delta_solo()
    local track, fx_index = current_f4_entry_fx_track_and_index()

    if not track or fx_index < 0 then
        speak("No FX")
        return true
    end

    local ok, enabled = fx_toggle_delta_solo(track, fx_index)

    if not ok then
        speak("Delta Solo not available")
        return true
    end

    refresh_window_title()

    if enabled then
        return speak_fx_current_status_action("Delta Solo on", track, fx_index)
    end

    return speak_fx_current_status_action("Delta Solo off", track, fx_index)
end

function f4_find_entry_pos_for_fx_after_move(fx_index, old_kind, old_param_index)
    fx_index = tonumber(fx_index) or -1
    old_kind = tostring(old_kind or "")
    old_param_index = tonumber(old_param_index)

    if fx_index < 0 then
        return 0
    end

    --------------------------------------------------------
    -- Se prima eri su un parametro visibile, prova a tornare
    -- sullo stesso parametro dopo lo spostamento dell'FX.
    --------------------------------------------------------

    if old_kind == "fx_param" and old_param_index ~= nil then
        for pos = 1, #grid_entries do
            local e = grid_entries[pos]

            if e and
               e.kind == "fx_param" and
               tonumber(e.fx_index) == fx_index and
               tonumber(e.param_index) == old_param_index then

                return pos
            end
        end
    end

    --------------------------------------------------------
    -- Altrimenti torna sull'intestazione del plugin spostato.
    --------------------------------------------------------

    return f4_find_header_pos_for_fx(fx_index)
end

function move_current_f4_fx_in_chain(direction)
    if current_section_id ~= SECTION_FX_PARAMS then
        return false
    end

    direction = tonumber(direction) or 0

    if direction == 0 then
        return false
    end

    local e = get_current_entry()

    if not e or e.fx_index == nil then
        speak("No FX")
        return true
    end

    local track = e.track or current_track
    local fx_index = tonumber(e.fx_index) or -1

    if not track or fx_index < 0 then
        speak("No FX")
        return true
    end

    local fx_count = reaper.TrackFX_GetCount(track) or 0

    if fx_count <= 0 then
        speak("No FX")
        return true
    end

    if direction < 0 and fx_index <= 0 then
        return grid_edge("f4-move-fx-top")
    end

    if direction > 0 and fx_index >= fx_count - 1 then
        return grid_edge("f4-move-fx-bottom")
    end

    if not reaper.TrackFX_CopyToTrack then
        speak("Move FX not available")
        return true
    end

    local old_kind = e.kind
    local old_param_index = e.param_index
    local old_fx_name = fx_get_name(track, fx_index)

    local new_fx_index = fx_index

    --------------------------------------------------------
    -- Dentro la stessa FX chain:
    -- - per salire: destinazione = fx_index - 1
    -- - per scendere: destinazione = fx_index + 2
    --
    -- Questo perché quando si sposta in basso, REAPER rimuove
    -- prima l'FX dalla sua posizione originale e gli indici
    -- cambiano.
    --------------------------------------------------------

    local destination_index = fx_index

    if direction < 0 then
        destination_index = fx_index - 1
        new_fx_index = fx_index - 1
    else
        destination_index = fx_index + 2
        new_fx_index = fx_index + 1
    end

    --------------------------------------------------------
    -- Non controlliamo il valore di ritorno, perché questa API
    -- può non restituire true in modo affidabile in Lua.
    -- Usiamo pcall solo per intercettare un errore reale.
    --------------------------------------------------------

    local call_ok = pcall(
        reaper.TrackFX_CopyToTrack,
        track,
        fx_index,
        track,
        destination_index,
        true
    )

    if not call_ok then
        speak("Move FX failed")
        return true
    end

    reaper.TrackList_AdjustWindows(false)
    reaper.UpdateArrange()

    build_current_grid()

    local wanted_pos = f4_find_entry_pos_for_fx_after_move(
        new_fx_index,
        old_kind,
        old_param_index
    )

    if wanted_pos > 0 then
        grid_pos = wanted_pos
    else
        local header_pos = f4_find_header_pos_for_fx(new_fx_index)

        if header_pos > 0 then
            grid_pos = header_pos
        else
            grid_pos = clamp_int(grid_pos, 1, math.max(1, #grid_entries))
        end
    end

    refresh_window_title()

    if direction < 0 then
        speak("Moved FX up. " .. old_fx_name)
    else
        speak("Moved FX down. " .. old_fx_name)
    end

    return true
end

------------------------------------------------------------
-- 3.2 - LETTURA PARAMETRI TCP VISIBILI
--
-- F4 mostra:
-- - sempre l'intestazione di ogni FX;
-- - sotto, solo i parametri FX esposti nei Track Controls.
--
-- Lettura primaria:
-- - API CountTCPFXParms / GetTCPFXParm.
--
-- Fallback:
-- - chunk della traccia, solo se l'API TCP non è disponibile.
--
-- Niente envelope:
-- - gli envelope possono creare falsi positivi.
------------------------------------------------------------

function line_is_fx_header(line)
    line = tostring(line or "")

    if line:match("^%s*<VST") then return true end
    if line:match("^%s*<JS") then return true end
    if line:match("^%s*<AU") then return true end
    if line:match("^%s*<CLAP") then return true end
    if line:match("^%s*<DX") then return true end
    if line:match("^%s*<VIDEO_EFFECT") then return true end

    return false
end

function line_is_tcp_fx_param_line(line)
    line = tostring(line or "")

    if line:match("^%s*PARM_TCP%s+") then return true end
    if line:match("^%s*PARM_TCP_EXT%s+") then return true end
    if line:match("^%s*TCPFXPARM%s+") then return true end
    if line:match("^%s*FXPARM%s+") then return true end

    return false
end

function add_visible_fx_param_index(out_list, out_seen, param_index, max_param)
    param_index = tonumber(param_index)
    max_param = tonumber(max_param) or 0

    if not param_index then
        return false
    end

    if param_index < 0 or param_index >= max_param then
        return false
    end

    if out_seen[param_index] then
        return false
    end

    out_seen[param_index] = true
    out_list[#out_list + 1] = param_index

    return true
end

function parse_tcp_fx_param_line(line, out_list, out_seen, max_param)
    line = tostring(line or "")

    if not line_is_tcp_fx_param_line(line) then
        return false
    end

    for token in line:gmatch("%S+") do
        if token ~= "PARM_TCP" and
           token ~= "PARM_TCP_EXT" and
           token ~= "TCPFXPARM" and
           token ~= "FXPARM" then

            local param_index = nil
            local plain = tonumber(token)

            if plain ~= nil then
                param_index = plain
            else
                local left, right = token:match("^(%-?%d+):(%-?%d+)$")

                if right then
                    param_index = tonumber(right)
                end
            end

            if param_index ~= nil then
                add_visible_fx_param_index(
                    out_list,
                    out_seen,
                    param_index,
                    max_param
                )
            end
        end
    end

    return true
end

function get_fx_tcp_visible_param_indices_from_chunk(track, wanted_fx_index)
    local result = {}

    if not track then
        return result
    end

    wanted_fx_index = tonumber(wanted_fx_index) or 0

    local param_count = fx_get_param_count(track, wanted_fx_index)

    if param_count <= 0 then
        return result
    end

    if not reaper.GetTrackStateChunk then
        return result
    end

    local ok, chunk = reaper.GetTrackStateChunk(track, "", false)

    if not ok or not chunk or chunk == "" then
        return result
    end

    local current_fx = -1
    local collect_this_fx = false
    local seen = {}

    for line in chunk:gmatch("[^\r\n]+") do
        if line_is_fx_header(line) then
            current_fx = current_fx + 1
            collect_this_fx = current_fx == wanted_fx_index

            if current_fx > wanted_fx_index then
                break
            end

        elseif collect_this_fx and line_is_tcp_fx_param_line(line) then
            parse_tcp_fx_param_line(
                line,
                result,
                seen,
                param_count
            )
        end
    end

    table.sort(result)

    return result
end

function fx_track_has_tcp_param(track, fx_index, param_index)
    if not track then
        return false
    end

    if not reaper.CountTCPFXParms or not reaper.GetTCPFXParm then
        return false
    end

    fx_index = tonumber(fx_index) or -1
    param_index = tonumber(param_index) or -1

    if fx_index < 0 or param_index < 0 then
        return false
    end

    local count = reaper.CountTCPFXParms(0, track) or 0

    for i = 0, count - 1 do
        local ok, tcp_fx, tcp_param = reaper.GetTCPFXParm(0, track, i)

        tcp_fx = tonumber(tcp_fx) or -1
        tcp_param = tonumber(tcp_param) or -1

        if ok and tcp_fx == fx_index and tcp_param == param_index then
            return true
        end
    end

    return false
end

function fx_get_tcp_visible_param_indices_from_api(track, wanted_fx_index)
    local result = {}

    if not track then
        return result
    end

    if not reaper.CountTCPFXParms or not reaper.GetTCPFXParm then
        return result
    end

    wanted_fx_index = tonumber(wanted_fx_index) or -1

    if wanted_fx_index < 0 then
        return result
    end

    local seen = {}
    local count = reaper.CountTCPFXParms(0, track) or 0

    for i = 0, count - 1 do
        local ok, fx_index, param_index =
            reaper.GetTCPFXParm(0, track, i)

        fx_index = tonumber(fx_index) or -1
        param_index = tonumber(param_index) or -1

        if ok and fx_index == wanted_fx_index and param_index >= 0 then
            if not seen[param_index] then
                seen[param_index] = true
                result[#result + 1] = param_index
            end
        end
    end

    table.sort(result)

    return result
end

function get_fx_tcp_visible_param_indices(track, wanted_fx_index)
    local from_api = fx_get_tcp_visible_param_indices_from_api(
        track,
        wanted_fx_index
    )

    if #from_api > 0 then
        return from_api
    end

    if not reaper.CountTCPFXParms or not reaper.GetTCPFXParm then
        return get_fx_tcp_visible_param_indices_from_chunk(
            track,
            wanted_fx_index
        )
    end

    return {}
end

function fx_param_is_tcp_visible(track, fx_index, param_index)
    local visible = get_fx_tcp_visible_param_indices(track, fx_index)

    param_index = tonumber(param_index) or -1

    if param_index < 0 then
        return false
    end

    for i = 1, #visible do
        if tonumber(visible[i]) == param_index then
            return true
        end
    end

    return false
end

------------------------------------------------------------
-- 3.3 - TRACK CONTROLS: ADD / REMOVE PARAMETRO FX
--
-- Add:
-- - scrive PARM_TCP nel chunk.
--
-- Remove:
-- - legge tutti i TCP dall'API;
-- - pulisce tutte le righe TCP dal chunk;
-- - ricostruisce tutto tranne il parametro rimosso.
------------------------------------------------------------

function fx_chunk_split_lines(chunk)
    local lines = {}

    chunk = tostring(chunk or "")

    for line in chunk:gmatch("[^\r\n]+") do
        lines[#lines + 1] = line
    end

    return lines
end

function fx_chunk_find_fx_block(lines, wanted_fx_index)
    wanted_fx_index = tonumber(wanted_fx_index) or -1

    if wanted_fx_index < 0 then
        return 0, 0
    end

    local current_fx = -1
    local fx_start = 0
    local fx_end = 0

    for i = 1, #lines do
        if line_is_fx_header(lines[i]) then
            current_fx = current_fx + 1

            if current_fx == wanted_fx_index then
                fx_start = i

            elseif current_fx > wanted_fx_index and fx_start > 0 then
                fx_end = i - 1
                break
            end
        end
    end

    if fx_start <= 0 then
        return 0, 0
    end

    if fx_end <= 0 then
        fx_end = #lines
    end

    return fx_start, fx_end
end

function fx_chunk_find_parm_tcp_line(lines, fx_start, fx_end)
    fx_start = tonumber(fx_start) or 0
    fx_end = tonumber(fx_end) or 0

    if fx_start <= 0 or fx_end <= 0 then
        return 0
    end

    for i = fx_start + 1, fx_end do
        local line = tostring(lines[i] or "")

        if line:match("^%s*PARM_TCP%s*") then
            return i
        end
    end

    return 0
end

function fx_chunk_parm_tcp_token_matches_param(token, param_index)
    token = tostring(token or "")
    param_index = tonumber(param_index) or -1

    if param_index < 0 then
        return false
    end

    local plain = tonumber(token)

    if plain ~= nil then
        return plain == param_index
    end

    local left, right = token:match("^(%-?%d+):(%-?%d+)$")

    if right then
        return tonumber(right) == param_index
    end

    return false
end

function fx_chunk_parm_tcp_has_param(line, param_index)
    line = tostring(line or "")

    for token in line:gmatch("%S+") do
        if token ~= "PARM_TCP" and
           token ~= "PARM_TCP_EXT" and
           token ~= "TCPFXPARM" and
           token ~= "FXPARM" then

            if fx_chunk_parm_tcp_token_matches_param(token, param_index) then
                return true
            end
        end
    end

    return false
end

function fx_chunk_insert_pos_for_parm_tcp(lines, fx_start, fx_end)
    fx_start = tonumber(fx_start) or 0
    fx_end = tonumber(fx_end) or 0

    if fx_start <= 0 or fx_end <= 0 then
        return fx_end
    end

    for i = fx_start + 1, fx_end do
        if tostring(lines[i] or ""):match("^%s*WAK%s+") then
            return i - 1
        end
    end

    return fx_end
end

function fx_add_param_to_tcp(track, fx_index, param_index)
    if not track then
        return false
    end

    fx_index = tonumber(fx_index) or -1
    param_index = tonumber(param_index) or -1

    if fx_index < 0 or param_index < 0 then
        return false
    end

    local param_count = fx_get_param_count(track, fx_index)

    if param_count <= 0 or param_index >= param_count then
        return false
    end

    if fx_track_has_tcp_param(track, fx_index, param_index) then
        return true
    end

    if not reaper.GetTrackStateChunk or not reaper.SetTrackStateChunk then
        return false
    end

    local ok, chunk = reaper.GetTrackStateChunk(track, "", false)

    if not ok or not chunk or chunk == "" then
        return false
    end

    local lines = fx_chunk_split_lines(chunk)

    if #lines <= 0 then
        return false
    end

    local fx_start, fx_end = fx_chunk_find_fx_block(lines, fx_index)

    if fx_start <= 0 or fx_end <= 0 then
        return false
    end

    local parm_tcp_line = fx_chunk_find_parm_tcp_line(lines, fx_start, fx_end)
    local token = tostring(param_index)

    if parm_tcp_line > 0 then
        local old_line = tostring(lines[parm_tcp_line] or "")

        if fx_chunk_parm_tcp_has_param(old_line, param_index) then
            return true
        end

        lines[parm_tcp_line] = old_line .. " " .. token
    else
        local insert_pos = fx_chunk_insert_pos_for_parm_tcp(
            lines,
            fx_start,
            fx_end
        )

        table.insert(lines, insert_pos + 1, "PARM_TCP " .. token)
    end

    local new_chunk = table.concat(lines, "\n") .. "\n"
    local set_ok = reaper.SetTrackStateChunk(track, new_chunk, false)

    if not set_ok then
        return false
    end

    if reaper.MarkProjectDirty then
        reaper.MarkProjectDirty(0)
    end

    reaper.TrackList_AdjustWindows(false)
    reaper.UpdateArrange()

    return true
end

function fx_collect_tcp_params_from_api(track)
    local result = {}

    if not track then
        return result
    end

    if not reaper.CountTCPFXParms or not reaper.GetTCPFXParm then
        return result
    end

    local count = reaper.CountTCPFXParms(0, track) or 0

    for i = 0, count - 1 do
        local ok, fx_index, param_index =
            reaper.GetTCPFXParm(0, track, i)

        fx_index = tonumber(fx_index) or -1
        param_index = tonumber(param_index) or -1

        if ok and fx_index >= 0 and param_index >= 0 then
            result[#result + 1] = {
                fx_index = fx_index,
                param_index = param_index
            }
        end
    end

    return result
end

function fx_clear_all_tcp_params_from_track(track)
    if not track then
        return false
    end

    if not reaper.GetTrackStateChunk or not reaper.SetTrackStateChunk then
        return false
    end

    local ok, chunk = reaper.GetTrackStateChunk(track, "", false)

    if not ok or not chunk or chunk == "" then
        return false
    end

    local lines = fx_chunk_split_lines(chunk)

    if #lines <= 0 then
        return false
    end

    local changed = false

    for i = #lines, 1, -1 do
        local line = tostring(lines[i] or "")
        local head = line:match("^%s*(%S+)")

        if head == "PARM_TCP" or
           head == "PARM_TCP_EXT" or
           head == "TCPFXPARM" or
           head == "FXPARM" then

            table.remove(lines, i)
            changed = true
        end
    end

    if not changed then
        return true
    end

    local new_chunk = table.concat(lines, "\n") .. "\n"
    local set_ok = reaper.SetTrackStateChunk(track, new_chunk, false)

    if not set_ok then
        return false
    end

    if reaper.MarkProjectDirty then
        reaper.MarkProjectDirty(0)
    end

    reaper.TrackList_AdjustWindows(false)
    reaper.UpdateArrange()

    return true
end

function fx_remove_param_from_tcp(track, fx_index, param_index)
    if not track then
        return false
    end

    fx_index = tonumber(fx_index) or -1
    param_index = tonumber(param_index) or -1

    if fx_index < 0 or param_index < 0 then
        return false
    end

    local old_tcp = fx_collect_tcp_params_from_api(track)

    if #old_tcp <= 0 then
        return false
    end

    local found_target = false
    local to_restore = {}
    local seen = {}

    for i = 1, #old_tcp do
        local item = old_tcp[i]
        local item_fx = tonumber(item.fx_index) or -1
        local item_param = tonumber(item.param_index) or -1

        if item_fx == fx_index and item_param == param_index then
            found_target = true
        else
            local key = tostring(item_fx) .. ":" .. tostring(item_param)

            if not seen[key] then
                seen[key] = true

                to_restore[#to_restore + 1] = {
                    fx_index = item_fx,
                    param_index = item_param
                }
            end
        end
    end

    if not found_target then
        return false
    end

    if reaper.TrackFX_SetNamedConfigParm then
        local key = "param." .. tostring(param_index) .. ".tcp"

        pcall(
            reaper.TrackFX_SetNamedConfigParm,
            track,
            fx_index,
            key,
            "0"
        )
    end

    if not fx_clear_all_tcp_params_from_track(track) then
        return false
    end

    for i = 1, #to_restore do
        local item = to_restore[i]

        fx_add_param_to_tcp(
            track,
            item.fx_index,
            item.param_index
        )
    end

    reaper.TrackList_AdjustWindows(false)
    reaper.UpdateArrange()

    if fx_track_has_tcp_param(track, fx_index, param_index) then
        return false
    end

    return true
end

------------------------------------------------------------
-- 3.4 - FILTRO FX / PARAMETRI FX VISIBILI
------------------------------------------------------------

function fx_header_filter_text(track, fx_index)
    local parts = {}

    fx_index = tonumber(fx_index) or 0

    parts[#parts + 1] = "FX"
    parts[#parts + 1] = "FX " .. tostring(fx_index + 1)
    parts[#parts + 1] = fx_get_name(track, fx_index)

    return table.concat(parts, " ")
end

function fx_param_filter_text(track, fx_index, param_index)
    local parts = {}

    fx_index = tonumber(fx_index) or 0
    param_index = tonumber(param_index) or 0

    parts[#parts + 1] = fx_get_name(track, fx_index)
    parts[#parts + 1] = "Param"
    parts[#parts + 1] = "Param " .. tostring(param_index + 1)
    parts[#parts + 1] = fx_get_param_name(track, fx_index, param_index)
    parts[#parts + 1] = fx_get_param_value(track, fx_index, param_index)

    return table.concat(parts, " ")
end

function fx_header_matches_current_filter(track, fx_index)
    if not filter_is_active() then
        return true
    end

    return text_matches_filter(
        fx_header_filter_text(track, fx_index),
        get_filter_query()
    )
end

function fx_param_matches_current_filter(track, fx_index, param_index)
    if not filter_is_active() then
        return true
    end

    return text_matches_filter(
        fx_param_filter_text(track, fx_index, param_index),
        get_filter_query()
    )
end

function collect_filtered_fx_visible_params(track, fx_index, visible_params)
    local result = {}

    visible_params = visible_params or {}

    if not filter_is_active() then
        for i = 1, #visible_params do
            result[#result + 1] = visible_params[i]
        end

        return result
    end

    if fx_header_matches_current_filter(track, fx_index) then
        for i = 1, #visible_params do
            result[#result + 1] = visible_params[i]
        end

        return result
    end

    for i = 1, #visible_params do
        local p = visible_params[i]

        if fx_param_matches_current_filter(track, fx_index, p) then
            result[#result + 1] = p
        end
    end

    return result
end

function fx_block_matches_current_filter(track, fx_index, visible_params)
    visible_params = visible_params or {}

    if not filter_is_active() then
        return true
    end

    if fx_header_matches_current_filter(track, fx_index) then
        return true
    end

    for i = 1, #visible_params do
        if fx_param_matches_current_filter(track, fx_index, visible_params[i]) then
            return true
        end
    end

    return false
end

------------------------------------------------------------
-- 3.5 - ENTRIES F4
------------------------------------------------------------

-- F4 grid layout:
-- every FX is a column; row 1 is the FX header, rows below
-- are the visible TCP parameters for that FX. Columns can have
-- different lengths; navigation uses f4_grid_columns instead of
-- adding silent placeholder cells.
f4_grid_columns = {}
f4_build_col = 0
f4_build_row = 1

function f4_grid_register_last_entry()
    local pos = #grid_entries
    local e = grid_entries[pos]

    if not e then
        return false
    end

    local col = clamp_int(f4_build_col, 1, 1000000)
    local row = clamp_int(f4_build_row, 1, 1000000)

    e.f4_col = col
    e.f4_row = row

    if not f4_grid_columns[col] then
        f4_grid_columns[col] = {}
    end

    f4_grid_columns[col][row] = pos
    f4_build_row = row + 1

    return true
end

function f4_grid_column_count()
    return #(f4_grid_columns or {})
end

function f4_grid_current_col_row()
    local e = get_current_entry()

    if not e then
        return 0, 0
    end

    return tonumber(e.f4_col) or 0, tonumber(e.f4_row) or 0
end

function f4_grid_pos_for_col_row(col, row)
    col = tonumber(col) or 0
    row = tonumber(row) or 0

    local column = f4_grid_columns[col]

    if type(column) ~= "table" or #column <= 0 then
        return 0
    end

    row = clamp_int(row, 1, #column)

    return tonumber(column[row]) or 0
end

function f4_grid_max_rows()
    local max_rows = 1

    for col = 1, #(f4_grid_columns or {}) do
        local column = f4_grid_columns[col]

        if type(column) == "table" and #column > max_rows then
            max_rows = #column
        end
    end

    return max_rows
end

function add_fx_header_entry_to_grid(track, fx_index)
    if not track then
        return false
    end

    fx_index = tonumber(fx_index) or 0

    grid_entries[#grid_entries + 1] = {
        kind = "fx_header",
        id = "fx_header",
        track = track,
        fx_index = fx_index,

        label = fx_get_name(track, fx_index),
        value = ""
    }

    if current_section_id == SECTION_FX_PARAMS then
        f4_grid_register_last_entry()
    end

    return true
end

function add_fx_param_entry_to_grid(track, fx_index, param_index)
    if not track then
        return false
    end

    fx_index = tonumber(fx_index) or 0
    param_index = tonumber(param_index) or 0

    grid_entries[#grid_entries + 1] = {
        kind = "fx_param",
        id = "fx_param",
        value_kind = "continuous",
        track = track,
        fx_index = fx_index,
        param_index = param_index,

        label = function(e)
            return fx_get_param_name(e.track, e.fx_index, e.param_index)
        end,

        value = function(e)
            return fx_get_param_value(e.track, e.fx_index, e.param_index)
        end,

        get_norm = function(e)
            return fx_get_param_norm(e.track, e.fx_index, e.param_index)
        end,

        set_norm = function(e, norm)
            return fx_set_param_norm(e.track, e.fx_index, e.param_index, norm)
        end
    }

    if current_section_id == SECTION_FX_PARAMS then
        f4_grid_register_last_entry()
    end

    return true
end

function add_fx_param_block_to_grid(track, fx_index)
    if not track then
        return false
    end

    fx_index = tonumber(fx_index) or 0

    local visible_params = get_fx_tcp_visible_param_indices(track, fx_index)

    if type(f4_order_apply_to_visible_params) == "function" then
        visible_params = f4_order_apply_to_visible_params(track, fx_index, visible_params)
    end

    if filter_is_active() and
       not fx_block_matches_current_filter(track, fx_index, visible_params) then
        return false
    end

    local filtered_params = collect_filtered_fx_visible_params(
        track,
        fx_index,
        visible_params
    )

    f4_build_col = (tonumber(f4_build_col) or 0) + 1
    f4_build_row = 1

    add_fx_header_entry_to_grid(track, fx_index)

    for i = 1, #filtered_params do
        add_fx_param_entry_to_grid(track, fx_index, filtered_params[i])
    end

    return true
end

function build_fx_params_grid()
    grid_entries = {}
    f4_grid_columns = {}
    f4_build_col = 0
    f4_build_row = 1

    if not current_track then
        grid_size = FX_PARAM_GRID_SIZE
        grid_pos = 1
        return false
    end

    local fx_count = reaper.TrackFX_GetCount(current_track) or 0

    if fx_count <= 0 then
        grid_size = FX_PARAM_GRID_SIZE
        grid_pos = 1
        return false
    end

    for fx = 0, fx_count - 1 do
        add_fx_param_block_to_grid(current_track, fx)
    end

    grid_size = f4_grid_max_rows()
    grid_pos = clamp_int(grid_pos, 1, math.max(1, #grid_entries))

    return #grid_entries > 0
end

------------------------------------------------------------
-- 3.5A - F5 AUDIO PIN CONNECTOR
--
-- F5 si apre solo da F4, su un FX header o su un parametro
-- appartenente a quell'FX. La griglia mostra tutte le
-- connessioni possibili fra pin audio del plugin e canali
-- interni della traccia corrente.
--
-- Ogni cella è una connessione possibile:
-- - input:  track channel -> plugin input pin
-- - output: plugin output pin -> track channel
--
-- Enter: attiva/disattiva la cella corrente.
-- Page Up/Down: si muove nella colonna usando lo step corrente.
-- Home/End: inizio/fine colonna.
-- Ctrl+Home/Ctrl+End: primo/ultimo elemento della griglia.
------------------------------------------------------------

pin_audio_track = nil
pin_audio_fx_index = -1
pin_audio_fx_name = ""
pin_audio_return_grid_pos = 1
pin_audio_pending_active = false
pin_audio_pending_kind = ""
pin_audio_pending_origin = -1
pin_audio_last_active_pos = 0

function pin_audio_reset_pending()
    pin_audio_pending_active = false
    pin_audio_pending_kind = ""
    pin_audio_pending_origin = -1
end

function pin_audio_fx_label()
    local fxn = tonumber(pin_audio_fx_index) or -1
    local name = clean_one_line(pin_audio_fx_name or "")

    if name == "" and pin_audio_track and fxn >= 0 then
        name = fx_get_name(pin_audio_track, fxn)
    end

    if name == "" then
        name = "FX"
    end

    return "FX " .. tostring(fxn + 1) .. " " .. name
end

function pin_audio_get_track_channel_count(track)
    local n = 2

    if track and reaper.GetMediaTrackInfo_Value then
        n = math.floor((tonumber(reaper.GetMediaTrackInfo_Value(track, "I_NCHAN")) or 2) + 0.5)
    end

    if n < 2 then
        n = 2
    end

    if n > 64 then
        n = 64
    end

    return n
end

function pin_audio_get_io_size(track, fx_index)
    if not track or not reaper.TrackFX_GetIOSize then
        return 0, 0
    end

    local ok, a, b, c = pcall(reaper.TrackFX_GetIOSize, track, fx_index)

    if not ok then
        return 0, 0
    end

    --------------------------------------------------------
    -- A seconda del binding, può arrivare:
    -- retval, inputs, outputs
    -- oppure inputs, outputs.
    --------------------------------------------------------
    if c ~= nil then
        return tonumber(b) or 0, tonumber(c) or 0
    end

    return tonumber(a) or 0, tonumber(b) or 0
end

function pin_audio_channel_bit(channel_index)
    channel_index = clamp_int(channel_index, 0, 63)

    if channel_index < 32 then
        return 1 << channel_index, 0
    end

    return 0, 1 << (channel_index - 32)
end

function pin_audio_get_mapping(track, fx_index, is_output, pin_index)
    if not track or not reaper.TrackFX_GetPinMappings then
        return 0, 0
    end

    local ok, low, high = pcall(
        reaper.TrackFX_GetPinMappings,
        track,
        fx_index,
        is_output and 1 or 0,
        pin_index,
        0
    )

    if not ok then
        return 0, 0
    end

    return math.floor((tonumber(low) or 0) + 0.5),
           math.floor((tonumber(high) or 0) + 0.5)
end

function pin_audio_set_mapping(track, fx_index, is_output, pin_index, low, high)
    if not track or not reaper.TrackFX_SetPinMappings then
        return false
    end

    local ok, rv = pcall(
        reaper.TrackFX_SetPinMappings,
        track,
        fx_index,
        is_output and 1 or 0,
        pin_index,
        low or 0,
        high or 0
    )

    return ok and rv ~= false
end

function pin_audio_connection_is_active(entry)
    if not entry or not entry.track then
        return false
    end

    local low, high = pin_audio_get_mapping(
        entry.track,
        entry.fx_index,
        entry.is_output == true,
        entry.pin_index
    )

    local bit_low, bit_high = pin_audio_channel_bit(entry.channel_index)

    if bit_low ~= 0 then
        return (low & bit_low) ~= 0
    end

    return (high & bit_high) ~= 0
end

function pin_audio_set_connection(entry, active)
    if not entry or not entry.track then
        return false
    end

    local low, high = pin_audio_get_mapping(
        entry.track,
        entry.fx_index,
        entry.is_output == true,
        entry.pin_index
    )

    local bit_low, bit_high = pin_audio_channel_bit(entry.channel_index)

    if bit_low ~= 0 then
        if active then
            low = low | bit_low
        else
            low = low & (~bit_low)
        end
    else
        if active then
            high = high | bit_high
        else
            high = high & (~bit_high)
        end
    end

    return pin_audio_set_mapping(
        entry.track,
        entry.fx_index,
        entry.is_output == true,
        entry.pin_index,
        low,
        high
    )
end

function pin_audio_pin_side_name(pin_index)
    pin_index = tonumber(pin_index) or 0

    if pin_index == 0 then
        return "left"
    end

    if pin_index == 1 then
        return "right"
    end

    return "pin " .. tostring(pin_index + 1)
end

function pin_audio_entry_origin_text(entry)
    if not entry then
        return ""
    end

    if entry.is_output then
        return "output " .. tostring(entry.pin_index + 1) .. " " .. pin_audio_pin_side_name(entry.pin_index)
    end

    return "track channel " .. tostring(entry.channel_index + 1)
end

function pin_audio_entry_destination_text(entry)
    if not entry then
        return ""
    end

    if entry.is_output then
        return "track channel " .. tostring(entry.channel_index + 1)
    end

    return "input " .. tostring(entry.pin_index + 1) .. " " .. pin_audio_pin_side_name(entry.pin_index)
end

function pin_audio_entry_label(entry)
    if not entry then
        return "Empty"
    end

    local selected = ""

    if pin_audio_connection_is_active(entry) then
        selected = "Selected. "
    end

    if entry.is_output then
        return selected ..
            "Output " .. tostring(entry.pin_index + 1) .. " " ..
            pin_audio_pin_side_name(entry.pin_index) ..
            ". Sends to channel " .. tostring(entry.channel_index + 1)
    end

    return selected ..
        "Input " .. tostring(entry.pin_index + 1) .. " " ..
        pin_audio_pin_side_name(entry.pin_index) ..
        ". Receives from channel " .. tostring(entry.channel_index + 1)
end

function pin_audio_entry_action_label(entry)
    if not entry then
        return "Empty"
    end

    if entry.is_output then
        return "Output " .. tostring(entry.pin_index + 1) .. " " ..
            pin_audio_pin_side_name(entry.pin_index) ..
            " sends to channel " .. tostring(entry.channel_index + 1)
    end

    return "Input " .. tostring(entry.pin_index + 1) .. " " ..
        pin_audio_pin_side_name(entry.pin_index) ..
        " receives from channel " .. tostring(entry.channel_index + 1)
end

function pin_audio_make_entry(track, fx_index, is_output, pin_index, channel_index)
    return {
        kind = "pin_audio",
        id = is_output and "pin_audio_output" or "pin_audio_input",
        track = track,
        fx_index = fx_index,
        fx_name = pin_audio_fx_name,
        is_output = is_output == true,
        pin_index = tonumber(pin_index) or 0,
        channel_index = tonumber(channel_index) or 0,
        label = function(e)
            return pin_audio_entry_label(e)
        end,
        value = ""
    }
end

function build_pin_audio_grid()
    grid_entries = {}

    if not pin_audio_track or (tonumber(pin_audio_fx_index) or -1) < 0 then
        grid_size = 1
        grid_pos = 1
        return false
    end

    local fx_count = reaper.TrackFX_GetCount(pin_audio_track) or 0

    if pin_audio_fx_index < 0 or pin_audio_fx_index >= fx_count then
        grid_size = 1
        grid_pos = 1
        return false
    end

    local input_pins, output_pins = pin_audio_get_io_size(pin_audio_track, pin_audio_fx_index)
    local channels = pin_audio_get_track_channel_count(pin_audio_track)

    grid_size = channels

    for pin = 0, math.max(0, input_pins) - 1 do
        for ch = 0, channels - 1 do
            grid_entries[#grid_entries + 1] = pin_audio_make_entry(
                pin_audio_track,
                pin_audio_fx_index,
                false,
                pin,
                ch
            )
        end
    end

    for pin = 0, math.max(0, output_pins) - 1 do
        for ch = 0, channels - 1 do
            grid_entries[#grid_entries + 1] = pin_audio_make_entry(
                pin_audio_track,
                pin_audio_fx_index,
                true,
                pin,
                ch
            )
        end
    end

    if #grid_entries <= 0 then
        grid_size = 1
        grid_pos = 1
        return false
    end

    grid_pos = clamp_int(grid_pos, 1, #grid_entries)

    return true
end

function pin_audio_current_fx_from_f4()
    if current_section_id ~= SECTION_FX_PARAMS then
        return nil, -1
    end

    local e = get_current_entry()

    if not e then
        return nil, -1
    end

    if e.kind ~= "fx_header" and e.kind ~= "fx_param" then
        return nil, -1
    end

    local tr = e.track or current_track
    local fx_index = tonumber(e.fx_index) or -1

    if not tr or fx_index < 0 then
        return nil, -1
    end

    return tr, fx_index
end

function enter_pin_audio_from_f4()
    local tr, fx_index = pin_audio_current_fx_from_f4()

    if not tr or fx_index < 0 then
        speak("Select an FX in F4 first")
        return true
    end

    local input_pins, output_pins = pin_audio_get_io_size(tr, fx_index)

    if input_pins <= 0 and output_pins <= 0 then
        speak("No audio pins")
        return true
    end

    cursor_memory_save_current()

    pin_audio_track = tr
    pin_audio_fx_index = fx_index
    pin_audio_fx_name = fx_get_name(tr, fx_index)
    pin_audio_return_grid_pos = grid_pos
    pin_audio_reset_pending()

    current_section_key = KEY_F5
    current_section_id = PIN_AUDIO_SECTION_ID
    mode = "pin_audio"
    grid_pos = 1

    cursor_memory_prepare_section_before_build(PIN_AUDIO_SECTION_ID, false)
    build_pin_audio_grid()
    cursor_memory_restore_after_build(PIN_AUDIO_SECTION_ID, false)
    refresh_window_title()

    speak(
        "Audio pin connector. " ..
        get_track_short_label(tr) .. ". " ..
        pin_audio_fx_label() .. ". " ..
        get_entry_spoken_label(get_current_entry())
    )

    return true
end

function exit_pin_audio_to_f4(speak_it)
    local wanted_fx = tonumber(pin_audio_fx_index) or -1
    local wanted_pos = tonumber(pin_audio_return_grid_pos) or 1

    pin_audio_reset_pending()

    current_section_key = KEY_F4
    current_section_id = SECTION_FX_PARAMS
    mode = "grid"

    build_current_grid()

    if wanted_pos >= 1 and wanted_pos <= #grid_entries then
        local e = grid_entries[wanted_pos]

        if e and tonumber(e.fx_index) == wanted_fx then
            grid_pos = wanted_pos
        else
            local header_pos = f4_find_header_pos_for_fx(wanted_fx)

            if header_pos > 0 then
                grid_pos = header_pos
            else
                grid_pos = clamp_int(wanted_pos, 1, math.max(1, #grid_entries))
            end
        end
    else
        local header_pos = f4_find_header_pos_for_fx(wanted_fx)

        if header_pos > 0 then
            grid_pos = header_pos
        else
            grid_pos = clamp_int(wanted_pos, 1, math.max(1, #grid_entries))
        end
    end

    refresh_window_title()

    if speak_it ~= false then
        speak("FX parameters. " .. get_entry_spoken_label(get_current_entry()))
    end

    return true
end

function pin_audio_toggle_current_connection()
    local e = get_current_entry()

    if not e or e.kind ~= "pin_audio" then
        speak("No pin connection")
        return true
    end

    local active = pin_audio_connection_is_active(e)
    local ok = pin_audio_set_connection(e, not active)

    if not ok then
        speak("Could not change pin connection")
        return true
    end

    if active then
        speak("Disconnected. " .. pin_audio_entry_action_label(e))
    else
        pin_audio_last_active_pos = grid_pos
        speak("Connected. " .. pin_audio_entry_action_label(e))
    end

    return true
end

function pin_audio_delete_current_connection()
    local e = get_current_entry()

    if not e or e.kind ~= "pin_audio" then
        speak("No pin connection")
        return true
    end

    if not pin_audio_connection_is_active(e) then
        speak("Not connected")
        return true
    end

    local ok = pin_audio_set_connection(e, false)

    if ok then
        speak("Disconnected. " .. pin_audio_entry_action_label(e))
    else
        speak("Could not disconnect")
    end

    return true
end

function pin_audio_ctrl_s_current()
    local e = get_current_entry()

    if not e or e.kind ~= "pin_audio" then
        speak("No pin connection")
        return true
    end

    --------------------------------------------------------
    -- Prima pressione:
    -- memorizza la sorgente logica della cella corrente.
    --
    -- Input mapping:  sorgente = track channel.
    -- Output mapping: sorgente = plugin output pin.
    --------------------------------------------------------
    if not pin_audio_pending_active then
        pin_audio_pending_active = true
        pin_audio_pending_kind = e.is_output and "output" or "input"
        pin_audio_pending_origin = e.is_output and e.pin_index or e.channel_index

        speak("Origin " .. pin_audio_entry_origin_text(e) .. " selected. Choose destination")
        return true
    end

    local current_kind = e.is_output and "output" or "input"

    if current_kind ~= pin_audio_pending_kind then
        pin_audio_pending_active = true
        pin_audio_pending_kind = current_kind
        pin_audio_pending_origin = e.is_output and e.pin_index or e.channel_index

        speak("Origin " .. pin_audio_entry_origin_text(e) .. " selected. Choose destination")
        return true
    end

    local target_entry = e

    if current_kind == "input" then
        target_entry = pin_audio_make_entry(
            e.track,
            e.fx_index,
            false,
            e.pin_index,
            pin_audio_pending_origin
        )
    else
        target_entry = pin_audio_make_entry(
            e.track,
            e.fx_index,
            true,
            pin_audio_pending_origin,
            e.channel_index
        )
    end

    local ok = pin_audio_set_connection(target_entry, true)

    if not ok then
        speak("Could not connect")
        pin_audio_reset_pending()
        return true
    end

    pin_audio_reset_pending()
    build_pin_audio_grid()
    refresh_window_title()

    --------------------------------------------------------
    -- Porta il cursore sulla cella appena collegata.
    --------------------------------------------------------
    for pos = 1, #grid_entries do
        local ge = grid_entries[pos]

        if ge and ge.kind == "pin_audio" and
           ge.is_output == target_entry.is_output and
           tonumber(ge.pin_index) == tonumber(target_entry.pin_index) and
           tonumber(ge.channel_index) == tonumber(target_entry.channel_index) then
            grid_pos = pos
            break
        end
    end

    pin_audio_last_active_pos = grid_pos
    speak("Connected. " .. pin_audio_entry_action_label(get_current_entry()))

    return true
end

function pin_audio_find_active_from(start_pos, direction, same_origin, same_destination)
    local count = #grid_entries

    if count <= 0 then
        return 0
    end

    direction = tonumber(direction) or 1

    if direction == 0 then
        direction = 1
    end

    local current = grid_entries[clamp_int(start_pos, 1, count)]

    for step = 1, count do
        local pos = ((start_pos - 1 + (step * direction)) % count) + 1
        local e = grid_entries[pos]

        if e and e.kind == "pin_audio" and pin_audio_connection_is_active(e) then
            local ok = true

            if same_origin and current then
                if e.is_output ~= current.is_output then
                    ok = false
                elseif e.is_output then
                    ok = tonumber(e.pin_index) == tonumber(current.pin_index)
                else
                    ok = tonumber(e.channel_index) == tonumber(current.channel_index)
                end
            end

            if same_destination and current then
                if e.is_output ~= current.is_output then
                    ok = false
                elseif e.is_output then
                    ok = tonumber(e.channel_index) == tonumber(current.channel_index)
                else
                    ok = tonumber(e.pin_index) == tonumber(current.pin_index)
                end
            end

            if ok then
                return pos
            end
        end
    end

    return 0
end

function pin_audio_jump_active(direction, same_origin, same_destination)
    local pos = pin_audio_find_active_from(grid_pos, direction, same_origin, same_destination)

    if pos <= 0 then
        speak("No active pin connections")
        return true
    end

    grid_move_to_pos(pos, true, "pin")
    pin_audio_last_active_pos = pos
    return true
end


function pin_audio_selected_direction_message(axis, direction)
    axis = clean_one_line(axis or "")
    direction = tonumber(direction) or 0

    if axis == "row" then
        if direction < 0 then
            return "No selected connection to the left"
        end

        return "No selected connection to the right"
    end

    if direction < 0 then
        return "No selected connection above"
    end

    return "No selected connection below"
end

function pin_audio_jump_selected_in_row(direction)
    --------------------------------------------------------
    -- Ctrl+Left / Ctrl+Right:
    -- cerca una cella Selected sulla stessa riga logica
    -- della griglia dettagliata.
    --
    -- Qui "stessa riga" significa stesso indice dentro la
    -- colonna: per F5 audio, normalmente lo stesso canale.
    -- Quindi il salto avviene fra colonne/pin diversi mantenendo
    -- la stessa riga, come la navigazione orizzontale normale.
    --------------------------------------------------------
    local count = grid_count()

    if count <= 0 then
        return true
    end

    direction = tonumber(direction) or 0

    if direction == 0 then
        return true
    end

    local safe_grid = grid_safe_size()
    local row_offset = (grid_pos - 1) % safe_grid
    local current_col_start =
        math.floor((grid_pos - 1) / safe_grid) * safe_grid + 1

    local col_start = current_col_start + (safe_grid * direction)

    while col_start >= 1 and col_start <= count do
        local pos = col_start + row_offset

        if pos <= count then
            local e = grid_entries[pos]

            if e and e.kind == "pin_audio" and pin_audio_connection_is_active(e) then
                grid_move_to_pos(pos, true, "horizontal")
                pin_audio_last_active_pos = pos
                return true
            end
        end

        col_start = col_start + (safe_grid * direction)
    end

    speak(pin_audio_selected_direction_message("row", direction))
    return true
end

function pin_audio_jump_selected_in_column(direction)
    --------------------------------------------------------
    -- Ctrl+Up / Ctrl+Down:
    -- cerca una cella Selected nella stessa colonna logica,
    -- cioè dentro lo stesso blocco/pin, muovendosi su o giù.
    --------------------------------------------------------
    local count = grid_count()

    if count <= 0 then
        return true
    end

    direction = tonumber(direction) or 0

    if direction == 0 then
        return true
    end

    local col_start, col_end = grid_column_bounds(grid_pos)
    local pos = grid_pos + direction

    while pos >= col_start and pos <= col_end do
        local e = grid_entries[pos]

        if e and e.kind == "pin_audio" and pin_audio_connection_is_active(e) then
            grid_move_to_pos(pos, true, "vertical")
            pin_audio_last_active_pos = pos
            return true
        end

        pos = pos + direction
    end

    speak(pin_audio_selected_direction_message("column", direction))
    return true
end

function pin_audio_selected_linear_message(direction)
    direction = tonumber(direction) or 0

    if direction < 0 then
        return "No previous selected pin connection"
    end

    return "No next selected pin connection"
end

function pin_audio_jump_selected_linear(direction)
    --------------------------------------------------------
    -- Ctrl+Alt+frecce in F5:
    -- navigazione lineare fra tutte le celle Selected,
    -- dal primo collegamento selezionato all'ultimo.
    --
    -- Right/Down = avanti.
    -- Left/Up    = indietro.
    --------------------------------------------------------
    local count = grid_count()

    if count <= 0 then
        return true
    end

    direction = tonumber(direction) or 0

    if direction == 0 then
        return true
    end

    direction = direction < 0 and -1 or 1

    local pos = grid_pos + direction

    while pos >= 1 and pos <= count do
        local e = grid_entries[pos]

        if e and e.kind == "pin_audio" and pin_audio_connection_is_active(e) then
            grid_move_to_pos(pos, true, "pin")
            pin_audio_last_active_pos = pos
            return true
        end

        pos = pos + direction
    end

    speak(pin_audio_selected_linear_message(direction))
    return true
end

function handle_pin_audio_key(char)
    local is_ctrl = ctrl_down()
    local is_shift = shift_down()
    local is_alt = alt_down()

    if char == KEY_ESC then
        exit_script()
        return true
    end

    if not is_ctrl and not is_shift and not is_alt and char == KEY_F4 then
        return exit_pin_audio_to_f4(true)
    end

    if section_key_to_config(char) then
        pin_audio_reset_pending()
        mode = "grid"
        return switch_section_by_key(char, true)
    end

    if not is_ctrl and not is_shift and not is_alt and char == KEY_F5 then
        speak(
            pin_audio_fx_label() .. ". " ..
            get_entry_spoken_label(get_current_entry())
        )
        return true
    end

    if not is_ctrl and not is_shift and not is_alt and char == KEY_F6 then
        pin_midi_track = pin_audio_track
        pin_midi_fx_index = pin_audio_fx_index
        pin_midi_fx_name = pin_audio_fx_name
        pin_midi_return_grid_pos = pin_audio_return_grid_pos

        current_section_key = KEY_F6
        current_section_id = PIN_MIDI_SECTION_ID
        mode = "pin_midi"
        grid_pos = 1

        cursor_memory_prepare_section_before_build(PIN_MIDI_SECTION_ID, false)
        build_pin_midi_grid()
        cursor_memory_restore_after_build(PIN_MIDI_SECTION_ID, false)
        refresh_window_title()

        speak(
            "MIDI connector. " ..
            pin_midi_fx_label() .. ". " ..
            get_entry_spoken_label(get_current_entry())
        )

        return true
    end

    --------------------------------------------------------
    -- F5 pin audio:
    -- Ctrl+S non serve qui. La cella contiene già il rapporto
    -- pin/canale, quindi Enter collega o scollega direttamente.
    --------------------------------------------------------

    if not is_ctrl and not is_shift and not is_alt and char == KEY_ENTER then
        return pin_audio_toggle_current_connection()
    end

    if not is_ctrl and not is_shift and not is_alt and char == KEY_DELETE then
        return pin_audio_delete_current_connection()
    end

    if not is_ctrl and not is_shift and not is_alt and char == KEY_PAGE_DOWN then
        return grid_move_page(1)
    end

    if not is_ctrl and not is_shift and not is_alt and char == KEY_PAGE_UP then
        return grid_move_page(-1)
    end

    if not is_ctrl and not is_shift and not is_alt and char == KEY_TAB then
        speak(
            pin_audio_fx_label() .. ". " ..
            get_entry_spoken_label(get_current_entry())
        )
        return true
    end

    if not is_ctrl and not is_shift and not is_alt and char == KEY_BACKSLASH then
        speak(get_entry_spoken_label(get_current_entry()))
        return true
    end

    --------------------------------------------------------
    -- Ctrl+frecce in F5:
    -- salta solo fra le celle Selected nella stessa riga
    -- o nella stessa colonna. Le frecce normali restano
    -- navigazione libera della matrice.
    --------------------------------------------------------

    --------------------------------------------------------
    -- Ctrl+Alt+frecce in F5:
    -- scorre linearmente tutti i collegamenti Selected.
    -- Destra/Giù = avanti, Sinistra/Su = indietro.
    --------------------------------------------------------

    if is_ctrl and not is_shift and is_alt and char == KEY_RIGHT then
        return pin_audio_jump_selected_linear(1)
    end

    if is_ctrl and not is_shift and is_alt and char == KEY_DOWN then
        return pin_audio_jump_selected_linear(1)
    end

    if is_ctrl and not is_shift and is_alt and char == KEY_LEFT then
        return pin_audio_jump_selected_linear(-1)
    end

    if is_ctrl and not is_shift and is_alt and char == KEY_UP then
        return pin_audio_jump_selected_linear(-1)
    end

    if is_ctrl and not is_shift and not is_alt and char == KEY_LEFT then
        return pin_audio_jump_selected_in_row(-1)
    end

    if is_ctrl and not is_shift and not is_alt and char == KEY_RIGHT then
        return pin_audio_jump_selected_in_row(1)
    end

    if is_ctrl and not is_shift and not is_alt and char == KEY_UP then
        return pin_audio_jump_selected_in_column(-1)
    end

    if is_ctrl and not is_shift and not is_alt and char == KEY_DOWN then
        return pin_audio_jump_selected_in_column(1)
    end

    if not is_ctrl and not is_shift and not is_alt and char == KEY_UP then
        grid_move_vertical(-1)
        return true
    end

    if not is_ctrl and not is_shift and not is_alt and char == KEY_DOWN then
        grid_move_vertical(1)
        return true
    end

    if not is_ctrl and not is_shift and not is_alt and char == KEY_LEFT then
        grid_move_horizontal(-1)
        return true
    end

    if not is_ctrl and not is_shift and not is_alt and char == KEY_RIGHT then
        grid_move_horizontal(1)
        return true
    end

    if char == KEY_HOME then
        if is_ctrl and not is_shift and not is_alt then
            grid_move_to_pos(1, true, "horizontal")
        elseif not is_ctrl and not is_shift and not is_alt then
            grid_home()
        end
        return true
    end

    if char == KEY_END then
        if is_ctrl and not is_shift and not is_alt then
            grid_move_to_pos(grid_count(), true, "horizontal")
        elseif not is_ctrl and not is_shift and not is_alt then
            grid_end()
        end
        return true
    end

    return true
end

------------------------------------------------------------
-- 3.5B - F6 MIDI CONNECTOR / FX MIDI STATUS
--
-- F6 resta legato al plugin/synth selezionato da F4.
-- Non contiene bus o merge: quelli stanno in F2/F3, cioe'
-- nel routing tra tracce. Qui diamo solo orientamento MIDI
-- del plugin nella catena FX.
------------------------------------------------------------

pin_midi_track = nil
pin_midi_fx_index = -1
pin_midi_fx_name = ""
pin_midi_return_grid_pos = 1

function pin_midi_fx_label()
    local fxn = tonumber(pin_midi_fx_index) or -1
    local name = clean_one_line(pin_midi_fx_name or "")

    if name == "" and pin_midi_track and fxn >= 0 then
        name = fx_get_name(pin_midi_track, fxn)
    end

    if name == "" then
        name = "FX"
    end

    return "FX " .. tostring(fxn + 1) .. " " .. name
end

function pin_midi_named_config_get(track, fx_index, keys)
    if not track or not reaper.TrackFX_GetNamedConfigParm then
        return false, "", ""
    end

    keys = keys or {}

    for i = 1, #keys do
        local key = clean_one_line(keys[i] or "")

        if key ~= "" then
            local ok, rv, value = pcall(
                reaper.TrackFX_GetNamedConfigParm,
                track,
                fx_index,
                key
            )

            if ok and rv ~= false then
                return true, key, tostring(value or "")
            end
        end
    end

    return false, "", ""
end

function pin_midi_named_config_set(track, fx_index, key, value)
    if not track or not reaper.TrackFX_SetNamedConfigParm then
        return false
    end

    key = clean_one_line(key or "")

    if key == "" then
        return false
    end

    local ok, rv = pcall(
        reaper.TrackFX_SetNamedConfigParm,
        track,
        fx_index,
        key,
        tostring(value or "")
    )

    return ok and rv ~= false
end

function pin_midi_binary_text(v)
    v = clean_one_line(v or "")

    if v == "1" or v:lower() == "on" or v:lower() == "enabled" or v:lower() == "true" then
        return "Enabled"
    end

    if v == "0" or v:lower() == "off" or v:lower() == "disabled" or v:lower() == "false" then
        return "Disabled"
    end

    if v == "" then
        return "Not available"
    end

    return v
end








function pin_midi_make_entry(kind, label, fallback_value, read_only)
    local e = {
        kind = "pin_midi",
        id = kind or "midi",
        midi_kind = kind or "midi",
        label_text = label or "MIDI",
        fallback_value = fallback_value or "",
        read_only = read_only == true,
        label = function(entry)
            return clean_one_line(entry.label_text or "MIDI")
        end,
        value = function(entry)
            local value_text, ro = pin_midi_get_value_for_kind(entry.midi_kind)

            if value_text == "" then
                value_text = clean_one_line(entry.fallback_value or "")
            end

            return clean_one_line(value_text or "")
        end,
        enter = function(entry)
            return pin_midi_adjust_current_entry(1)
        end
    }

    return e
end

function pin_midi_refresh_after_change()
    local old_pos = grid_pos
    build_pin_midi_grid()
    grid_pos = clamp_int(old_pos, 1, math.max(1, #grid_entries))
    refresh_window_title()
end


function pin_midi_adjust_current_entry(direction, big_step, to_edge)
    return pin_midi_adjust_entry(get_current_entry(), direction, big_step, to_edge)
end


function pin_midi_control_edge(token, msg)
    token = clean_one_line(token or "")

    if token == "" then
        token = "pin-midi-control-edge"
    end

    --------------------------------------------------------
    -- Bordi controllo F6:
    -- come nel resto dello script, al limite non si parla.
    -- La prima pressione marca solo il bordo; le ripetizioni
    -- restano mute finché non cambia posizione o valore.
    --------------------------------------------------------
    edge_was_already_silent(token)

    return true
end









------------------------------------------------------------
-- 3.5C - F6 TRACK MIDI PAGE
--
-- F6 ora e' una pagina reale della traccia corrente.
-- Non dipende piu' da F4 o dal singolo FX.
-- F5 resta il pin connector audio del plugin selezionato.
--
-- Campi iniziali:
-- - MIDI hardware output
-- - MIDI hardware channel
-- - MIDI input channel map
-- - MIDI control channel
------------------------------------------------------------

function pin_midi_current_track()
    if current_track then
        return current_track
    end

    local e = get_current_entry()

    if e and e.track then
        return e.track
    end

    if pin_midi_track then
        return pin_midi_track
    end

    return nil
end

function pin_midi_track_label()
    local tr = pin_midi_current_track()

    if tr then
        return get_track_short_label(tr)
    end

    return "No track"
end

function pin_midi_hwout_raw(track)
    if not track or not reaper.GetMediaTrackInfo_Value then
        return -1
    end

    return math.floor((tonumber(reaper.GetMediaTrackInfo_Value(track, "I_MIDIHWOUT")) or -1) + 0.5)
end

function pin_midi_hwout_parts(track)
    local raw = pin_midi_hwout_raw(track)

    if raw < 0 then
        return -1, 0, raw
    end

    local channel = raw & 31
    local device = (raw >> 5) & 31

    channel = clamp_int(channel, 0, 16)
    device = clamp_int(device, 0, 31)

    return device, channel, raw
end

function pin_midi_make_hwout_value(device, channel)
    device = clamp_int(device, 0, 31)
    channel = clamp_int(channel, 0, 16)

    return (device << 5) | channel
end

function pin_midi_set_hwout_raw(track, value)
    if not track or not reaper.SetMediaTrackInfo_Value then
        return false
    end

    local ok = pcall(reaper.SetMediaTrackInfo_Value, track, "I_MIDIHWOUT", tonumber(value) or -1)

    if ok then
        if reaper.TrackList_AdjustWindows then
            reaper.TrackList_AdjustWindows(false)
        end

        if reaper.UpdateArrange then
            reaper.UpdateArrange()
        end
    end

    return ok == true
end

function pin_midi_output_device_name(device)
    device = clamp_int(device, 0, 31)

    local shown = "Device " .. tostring(device + 1)

    if reaper.GetMIDIOutputName then
        local ok, name = reaper.GetMIDIOutputName(device, "")

        name = clean_one_line(name or "")

        if ok and name ~= "" then
            return shown .. " " .. name
        end
    end

    return shown
end

function pin_midi_hwout_text(track)
    local device, _, raw = pin_midi_hwout_parts(track)

    if raw < 0 or device < 0 then
        return "Disabled"
    end

    return pin_midi_output_device_name(device)
end

function pin_midi_hwchannel_text(track)
    local device, channel, raw = pin_midi_hwout_parts(track)

    if raw < 0 or device < 0 then
        return "Output disabled"
    end

    if channel == 0 then
        return "All"
    end

    return tostring(channel)
end

function pin_midi_input_chanmap_raw(track)
    if not track or not reaper.GetMediaTrackInfo_Value then
        return -1
    end

    local v = math.floor((tonumber(reaper.GetMediaTrackInfo_Value(track, "I_MIDI_INPUT_CHANMAP")) or -1) + 0.5)

    if v < 0 then
        return -1
    end

    return clamp_int(v, 1, 16)
end

function pin_midi_input_chanmap_text(track)
    local v = pin_midi_input_chanmap_raw(track)

    if v < 0 then
        return "Source channel"
    end

    return tostring(v)
end

function pin_midi_set_input_chanmap(track, value)
    if not track or not reaper.SetMediaTrackInfo_Value then
        return false
    end

    value = tonumber(value) or -1

    if value >= 0 then
        value = clamp_int(value, 1, 16)
    else
        value = -1
    end

    local ok = pcall(reaper.SetMediaTrackInfo_Value, track, "I_MIDI_INPUT_CHANMAP", value)

    if ok then
        if reaper.TrackList_AdjustWindows then
            reaper.TrackList_AdjustWindows(false)
        end

        if reaper.UpdateArrange then
            reaper.UpdateArrange()
        end
    end

    return ok == true
end

function pin_midi_ctl_chan_raw(track)
    if not track or not reaper.GetMediaTrackInfo_Value then
        return -1
    end

    local v = math.floor((tonumber(reaper.GetMediaTrackInfo_Value(track, "I_MIDI_CTL_CHAN")) or -1) + 0.5)

    if v < 0 then
        return -1
    end

    return clamp_int(v, 0, 16)
end

function pin_midi_ctl_chan_text(track)
    local v = pin_midi_ctl_chan_raw(track)

    if v < 0 then
        return "None"
    end

    if v == 16 then
        return "All channels"
    end

    return tostring(v + 1)
end

function pin_midi_set_ctl_chan(track, value)
    if not track or not reaper.SetMediaTrackInfo_Value then
        return false
    end

    value = tonumber(value) or -1

    if value >= 0 then
        value = clamp_int(value, 0, 16)
    else
        value = -1
    end

    local ok = pcall(reaper.SetMediaTrackInfo_Value, track, "I_MIDI_CTL_CHAN", value)

    if ok then
        if reaper.TrackList_AdjustWindows then
            reaper.TrackList_AdjustWindows(false)
        end

        if reaper.UpdateArrange then
            reaper.UpdateArrange()
        end
    end

    return ok == true
end

function pin_midi_get_value_for_kind(kind)
    kind = clean_one_line(kind or "")

    local tr = pin_midi_current_track()

    if not tr then
        return "No track", true, "", ""
    end

    if kind == "midi_hardware_output" then
        return pin_midi_hwout_text(tr), false, "I_MIDIHWOUT", tostring(pin_midi_hwout_raw(tr))
    end

    if kind == "midi_hardware_channel" then
        return pin_midi_hwchannel_text(tr), false, "I_MIDIHWOUT", tostring(pin_midi_hwout_raw(tr))
    end

    if kind == "midi_input_chanmap" then
        return pin_midi_input_chanmap_text(tr), false, "I_MIDI_INPUT_CHANMAP", tostring(pin_midi_input_chanmap_raw(tr))
    end

    if kind == "midi_control_channel" then
        return pin_midi_ctl_chan_text(tr), false, "I_MIDI_CTL_CHAN", tostring(pin_midi_ctl_chan_raw(tr))
    end

    if kind == "midi_routing_note" then
        return "Sends and receives use F2 and F3", true, "", ""
    end

    return "", true, "", ""
end

function pin_midi_adjust_entry(entry, direction, big_step, to_edge)
    if not entry or entry.kind ~= "pin_midi" then
        return false
    end

    local midi_kind = clean_one_line(entry.midi_kind or "")
    local tr = pin_midi_current_track()

    if not tr then
        return pin_midi_control_edge("track-midi-no-track", "No track")
    end

    direction = tonumber(direction) or 0
    local step = big_step and 4 or 1

    if midi_kind == "midi_hardware_output" then
        local device, channel, raw = pin_midi_hwout_parts(tr)
        local current_pos = raw < 0 and -1 or device
        local new_pos = current_pos

        if to_edge == "first" then
            new_pos = -1
        elseif to_edge == "last" then
            new_pos = 31
        else
            new_pos = new_pos + ((direction >= 0) and step or -step)
            new_pos = clamp_int(new_pos, -1, 31)
        end

        if new_pos == current_pos then
            return pin_midi_control_edge("track-midi-hwout-edge:" .. tostring(current_pos), get_entry_spoken_label(entry))
        end

        local new_value = -1

        if new_pos >= 0 then
            new_value = pin_midi_make_hwout_value(new_pos, channel)
        end

        if pin_midi_set_hwout_raw(tr, new_value) then
            clear_silent_edge()
            pin_midi_refresh_after_change()
            speak(get_entry_spoken_label(get_current_entry()))
            return true
        end

        return pin_midi_control_edge("track-midi-hwout-failed", "MIDI hardware output could not be changed")
    end

    if midi_kind == "midi_hardware_channel" then
        local device, channel, raw = pin_midi_hwout_parts(tr)

        if raw < 0 or device < 0 then
            return pin_midi_control_edge("track-midi-hwchan-disabled", "Enable MIDI hardware output first")
        end

        local new_ch = channel

        if to_edge == "first" then
            new_ch = 0
        elseif to_edge == "last" then
            new_ch = 16
        else
            new_ch = new_ch + ((direction >= 0) and step or -step)
            new_ch = clamp_int(new_ch, 0, 16)
        end

        if new_ch == channel then
            return pin_midi_control_edge("track-midi-hwchan-edge:" .. tostring(channel), get_entry_spoken_label(entry))
        end

        if pin_midi_set_hwout_raw(tr, pin_midi_make_hwout_value(device, new_ch)) then
            clear_silent_edge()
            pin_midi_refresh_after_change()
            speak(get_entry_spoken_label(get_current_entry()))
            return true
        end

        return pin_midi_control_edge("track-midi-hwchan-failed", "MIDI hardware channel could not be changed")
    end

    if midi_kind == "midi_input_chanmap" then
        local old = pin_midi_input_chanmap_raw(tr)
        local pos = old < 0 and 0 or old
        local new_pos = pos

        if to_edge == "first" then
            new_pos = 0
        elseif to_edge == "last" then
            new_pos = 16
        else
            new_pos = new_pos + ((direction >= 0) and step or -step)
            new_pos = clamp_int(new_pos, 0, 16)
        end

        local new_value = new_pos == 0 and -1 or new_pos

        if new_value == old then
            return pin_midi_control_edge("track-midi-input-map-edge:" .. tostring(old), get_entry_spoken_label(entry))
        end

        if pin_midi_set_input_chanmap(tr, new_value) then
            clear_silent_edge()
            pin_midi_refresh_after_change()
            speak(get_entry_spoken_label(get_current_entry()))
            return true
        end

        return pin_midi_control_edge("track-midi-input-map-failed", "MIDI input channel map could not be changed")
    end

    if midi_kind == "midi_control_channel" then
        local old = pin_midi_ctl_chan_raw(tr)
        local pos = old < 0 and 0 or old + 1
        local new_pos = pos

        if to_edge == "first" then
            new_pos = 0
        elseif to_edge == "last" then
            new_pos = 17
        else
            new_pos = new_pos + ((direction >= 0) and step or -step)
            new_pos = clamp_int(new_pos, 0, 17)
        end

        local new_value = -1

        if new_pos == 0 then
            new_value = -1
        elseif new_pos == 17 then
            new_value = 16
        else
            new_value = new_pos - 1
        end

        if new_value == old then
            return pin_midi_control_edge("track-midi-ctl-edge:" .. tostring(old), get_entry_spoken_label(entry))
        end

        if pin_midi_set_ctl_chan(tr, new_value) then
            clear_silent_edge()
            pin_midi_refresh_after_change()
            speak(get_entry_spoken_label(get_current_entry()))
            return true
        end

        return pin_midi_control_edge("track-midi-ctl-failed", "MIDI control channel could not be changed")
    end

    return pin_midi_control_edge("track-midi-read-only:" .. midi_kind, make_entry_label(entry) .. " read only")
end

function build_pin_midi_grid()
    grid_entries = {}

    pin_midi_track = pin_midi_current_track()
    pin_midi_fx_index = -1
    pin_midi_fx_name = ""

    if not pin_midi_track then
        grid_size = 1
        grid_pos = 1
        return false
    end

    grid_entries[#grid_entries + 1] = pin_midi_make_entry(
        "midi_hardware_output",
        "MIDI hardware output",
        "Disabled",
        false
    )

    grid_entries[#grid_entries + 1] = pin_midi_make_entry(
        "midi_hardware_channel",
        "MIDI hardware channel",
        "All",
        false
    )

    grid_entries[#grid_entries + 1] = pin_midi_make_entry(
        "midi_input_chanmap",
        "MIDI input channel map",
        "Source channel",
        false
    )

    grid_entries[#grid_entries + 1] = pin_midi_make_entry(
        "midi_control_channel",
        "MIDI control channel",
        "None",
        false
    )

    grid_entries[#grid_entries + 1] = pin_midi_make_entry(
        "midi_routing_note",
        "MIDI routing",
        "Sends and receives use F2 and F3",
        true
    )

    grid_size = math.max(1, #grid_entries)
    grid_pos = clamp_int(grid_pos, 1, math.max(1, #grid_entries))
    return #grid_entries > 0
end

function enter_pin_midi_from_f4()
    return switch_section_by_key(KEY_F6, true)
end

function exit_pin_midi_to_f4(speak_it)
    mode = "grid"
    return switch_section_by_key(KEY_F4, speak_it ~= false)
end

function pin_midi_current_entry_is_routing_note()
    local e = get_current_entry()

    return e and
           e.kind == "pin_midi" and
           clean_one_line(e.midi_kind or "") == "midi_routing_note"
end

function pin_midi_enter_routing_page()
    local tr = pin_midi_current_track()

    if not tr then
        speak("No track")
        return true
    end

    set_current_track(tr, false)

    local send_count = get_track_send_count(tr)

    if send_count > 0 then
        mode = "grid"
        return switch_section_by_key(KEY_F2, true)
    end

    local receive_count = get_track_receive_count(tr)

    if receive_count > 0 then
        mode = "grid"
        return switch_section_by_key(KEY_F3, true)
    end

    speak("No sends or receives")
    return true
end

function handle_pin_midi_key(char)
    local is_ctrl = ctrl_down()
    local is_shift = shift_down()
    local is_alt = alt_down()

    if char == KEY_ESC then
        exit_script()
        return true
    end

    if section_key_to_config(char) then
        mode = "grid"
        return switch_section_by_key(char, true)
    end

    if not is_ctrl and not is_shift and not is_alt and char == KEY_F5 then
        speak("Select an FX in F4 first")
        return true
    end

    if not is_ctrl and not is_shift and not is_alt and char == KEY_F6 then
        speak(
            pin_midi_track_label() .. ". Track MIDI. " ..
            get_entry_spoken_label(get_current_entry())
        )
        return true
    end

    if not is_ctrl and not is_shift and not is_alt and char == KEY_TAB then
        speak(
            pin_midi_track_label() .. ". Track MIDI. " ..
            get_entry_spoken_label(get_current_entry())
        )
        return true
    end

    if not is_ctrl and not is_shift and not is_alt and char == KEY_BACKSLASH then
        speak(get_entry_spoken_label(get_current_entry()))
        return true
    end

    if not is_ctrl and not is_shift and not is_alt and char == KEY_ENTER then
        if pin_midi_current_entry_is_routing_note() then
            return pin_midi_enter_routing_page()
        end

        return pin_midi_adjust_current_entry(1)
    end

    if not is_ctrl and not is_shift and is_alt and char == KEY_UP then
        return pin_midi_adjust_current_entry(1)
    end

    if not is_ctrl and not is_shift and is_alt and char == KEY_DOWN then
        return pin_midi_adjust_current_entry(-1)
    end

    if not is_ctrl and not is_shift and is_alt and char == KEY_PAGE_UP then
        return pin_midi_adjust_current_entry(1, true)
    end

    if not is_ctrl and not is_shift and is_alt and char == KEY_PAGE_DOWN then
        return pin_midi_adjust_current_entry(-1, true)
    end

    --------------------------------------------------------
    -- Coerente con il resto dello script:
    -- Alt+Home = ultimo/massimo valore.
    -- Alt+End  = primo/minimo valore.
    --------------------------------------------------------
    if not is_ctrl and not is_shift and is_alt and char == KEY_HOME then
        return pin_midi_adjust_current_entry(1, false, "last")
    end

    if not is_ctrl and not is_shift and is_alt and char == KEY_END then
        return pin_midi_adjust_current_entry(-1, false, "first")
    end

    if not is_ctrl and not is_shift and not is_alt and char == KEY_UP then
        grid_move_vertical(-1)
        return true
    end

    if not is_ctrl and not is_shift and not is_alt and char == KEY_DOWN then
        grid_move_vertical(1)
        return true
    end

    if not is_ctrl and not is_shift and not is_alt and char == KEY_PAGE_UP then
        return grid_move_page(-1)
    end

    if not is_ctrl and not is_shift and not is_alt and char == KEY_PAGE_DOWN then
        return grid_move_page(1)
    end

    if char == KEY_HOME then
        if is_ctrl and not is_shift and not is_alt then
            grid_move_to_pos(1, true, "vertical")
        elseif not is_ctrl and not is_shift and not is_alt then
            grid_home()
        end

        return true
    end

    if char == KEY_END then
        if is_ctrl and not is_shift and not is_alt then
            grid_move_to_pos(grid_count(), true, "vertical")
        elseif not is_ctrl and not is_shift and not is_alt then
            grid_end()
        end

        return true
    end

    return true
end


------------------------------------------------------------
-- 3.5D - F7 HARDWARE OUTPUTS
--
-- F7 gestisce gli hardware audio outputs della traccia corrente.
-- Sono simili a direct out fisici: category 1 di REAPER.
------------------------------------------------------------

HARDWARE_OUTPUT_CATEGORY = 1

function hardware_output_count(track)
    if not track or not reaper.GetTrackNumSends then
        return 0
    end

    return reaper.GetTrackNumSends(track, HARDWARE_OUTPUT_CATEGORY) or 0
end

function hardware_output_current_track()
    local e = get_current_entry()

    if e and e.track then
        return e.track
    end

    return current_track
end

function hardware_output_track_label()
    local tr = hardware_output_current_track()

    if tr then
        return get_track_short_label(tr)
    end

    return "No track"
end

function hardware_output_get_value(track, index, parm)
    return send_get_value(track, HARDWARE_OUTPUT_CATEGORY, index, parm)
end

function hardware_output_set_value(track, index, parm, value)
    return send_set_value(track, HARDWARE_OUTPUT_CATEGORY, index, parm, value)
end

function hardware_output_destination_value(track, index)
    return math.floor((tonumber(hardware_output_get_value(track, index, "I_DSTCHAN")) or 0) + 0.5)
end

function hardware_output_set_destination_value(track, index, value)
    value = math.floor((tonumber(value) or 0) + 0.5)

    --------------------------------------------------------
    -- Per gli hardware output non allarghiamo i canali della
    -- traccia: qui la destinazione e' una uscita fisica.
    --------------------------------------------------------

    return hardware_output_set_value(track, index, "I_DSTCHAN", value)
end

function hardware_output_destination_pair(track, index)
    return audio_dst_pair_index(hardware_output_destination_value(track, index))
end

function hardware_output_set_destination_pair(track, index, pair_index)
    pair_index = clamp_int(pair_index, 0, 63)

    local old_value = hardware_output_destination_value(track, index)
    local mono = audio_dst_mono(old_value)
    local new_value = make_audio_dst_value(pair_index, mono)

    return hardware_output_set_destination_value(track, index, new_value)
end

function hardware_output_destination_norm(track, index)
    return routing_pair_to_norm(hardware_output_destination_pair(track, index))
end

function hardware_output_set_destination_norm(track, index, norm)
    return hardware_output_set_destination_pair(track, index, routing_norm_to_pair(norm))
end

function hardware_output_destination_formatted(track, index)
    return format_audio_destination(hardware_output_destination_value(track, index))
end

function hardware_output_get_bool(track, index, parm)
    return tonumber(hardware_output_get_value(track, index, parm)) == 1
end

function hardware_output_set_bool(track, index, parm, enabled)
    return hardware_output_set_value(track, index, parm, enabled and 1 or 0)
end

function hardware_output_pan_law_value(track, index)
    local v = tonumber(hardware_output_get_value(track, index, "D_PANLAW"))

    if v == nil then
        return -1
    end

    return v
end

HARDWARE_OUTPUT_PAN_LAW_VALUES = {
    -1,
    0.5,
    0.7079457843841379,
    1.0
}

function hardware_output_pan_law_index_from_value(value)
    value = tonumber(value) or -1

    if value < 0 then
        return 1
    end

    local best_i = 1
    local best_d = math.huge

    for i = 1, #HARDWARE_OUTPUT_PAN_LAW_VALUES do
        local candidate = HARDWARE_OUTPUT_PAN_LAW_VALUES[i]
        local d = math.abs(candidate - value)

        if d < best_d then
            best_d = d
            best_i = i
        end
    end

    return best_i
end

function hardware_output_pan_law_norm(track, index)
    local i = hardware_output_pan_law_index_from_value(
        hardware_output_pan_law_value(track, index)
    )

    return (i - 1) / math.max(1, (#HARDWARE_OUTPUT_PAN_LAW_VALUES - 1))
end

function hardware_output_set_pan_law_index(track, index, law_index)
    law_index = clamp_int(law_index, 1, #HARDWARE_OUTPUT_PAN_LAW_VALUES)

    return hardware_output_set_value(
        track,
        index,
        "D_PANLAW",
        HARDWARE_OUTPUT_PAN_LAW_VALUES[law_index]
    )
end

function hardware_output_set_pan_law_norm(track, index, norm)
    norm = clamp01(norm)

    local i = clamp_int(
        1 + (norm * (#HARDWARE_OUTPUT_PAN_LAW_VALUES - 1)),
        1,
        #HARDWARE_OUTPUT_PAN_LAW_VALUES
    )

    return hardware_output_set_pan_law_index(track, index, i)
end

function hardware_output_pan_law_step(track, index, direction)
    local old_i = hardware_output_pan_law_index_from_value(
        hardware_output_pan_law_value(track, index)
    )

    local new_i = old_i

    if direction > 0 then
        new_i = old_i + 1
    elseif direction < 0 then
        new_i = old_i - 1
    end

    new_i = clamp_int(new_i, 1, #HARDWARE_OUTPUT_PAN_LAW_VALUES)

    return hardware_output_set_pan_law_index(track, index, new_i)
end

function hardware_output_pan_law_formatted(track, index)
    local v = hardware_output_pan_law_value(track, index)

    if v < 0 then
        return "Project default"
    end

    if v <= 0 then
        return "-inf dB"
    end

    return format_db(amp_to_db(v))
end

function hardware_output_context_label(entry)
    if not entry or entry.kind ~= "hardware_output" then
        return "Hardware output"
    end

    local number = tostring(entry.display_index or ((entry.output_index or 0) + 1))
    local dest = hardware_output_destination_formatted(entry.track, entry.output_index)

    return "Hardware output " .. number .. " to " .. dest
end

function hardware_output_apply_common_fields(t, track, index, display_index)
    t.kind = "hardware_output"
    t.category = HARDWARE_OUTPUT_CATEGORY
    t.track = track
    t.send_index = index
    t.output_index = index
    t.display_index = display_index

    if t.enter == nil then
        t.enter = function(e)
            speak(hardware_output_context_label(e))
            return true
        end
    end

    return t
end

function add_hardware_output_block_to_grid(track, index, display_index)
    if not track then
        return false
    end

    index = tonumber(index) or 0
    display_index = tonumber(display_index) or (index + 1)

    grid_entries[#grid_entries + 1] = hardware_output_apply_common_fields({
        id = "hardware_header",
        label = "Hardware output " .. tostring(display_index),
        value = function(e)
            return "to " .. hardware_output_destination_formatted(e.track, e.output_index)
        end
    }, track, index, display_index)

    grid_entries[#grid_entries + 1] = hardware_output_apply_common_fields({
        id = "volume",
        value_kind = "continuous",
        label = "Volume",
        value = function(e)
            return send_get_volume_formatted(e.track, HARDWARE_OUTPUT_CATEGORY, e.output_index)
        end,
        get_norm = function(e)
            return send_get_volume_norm(e.track, HARDWARE_OUTPUT_CATEGORY, e.output_index)
        end,
        set_norm = function(e, norm)
            return send_set_volume_norm(e.track, HARDWARE_OUTPUT_CATEGORY, e.output_index, norm)
        end
    }, track, index, display_index)

    grid_entries[#grid_entries + 1] = hardware_output_apply_common_fields({
        id = "pan",
        value_kind = "continuous",
        label = "Pan",
        value = function(e)
            return send_get_pan_formatted(e.track, HARDWARE_OUTPUT_CATEGORY, e.output_index)
        end,
        get_norm = function(e)
            return send_get_pan_norm(e.track, HARDWARE_OUTPUT_CATEGORY, e.output_index)
        end,
        set_norm = function(e, norm)
            return send_set_pan_norm(e.track, HARDWARE_OUTPUT_CATEGORY, e.output_index, norm)
        end
    }, track, index, display_index)

    grid_entries[#grid_entries + 1] = hardware_output_apply_common_fields({
        id = "mute",
        value_kind = "bool",
        label = "Mute",
        value = function(e)
            return bool_to_on_off(send_get_mute(e.track, HARDWARE_OUTPUT_CATEGORY, e.output_index))
        end,
        get_norm = function(e)
            return send_get_mute(e.track, HARDWARE_OUTPUT_CATEGORY, e.output_index) and 1 or 0
        end,
        set_norm = function(e, norm)
            return send_set_mute(e.track, HARDWARE_OUTPUT_CATEGORY, e.output_index, clamp01(norm) >= 0.5)
        end
    }, track, index, display_index)

    grid_entries[#grid_entries + 1] = hardware_output_apply_common_fields({
        id = "phase",
        value_kind = "bool",
        label = "Phase invert",
        value = function(e)
            return bool_to_on_off(hardware_output_get_bool(e.track, e.output_index, "B_PHASE"))
        end,
        get_norm = function(e)
            return hardware_output_get_bool(e.track, e.output_index, "B_PHASE") and 1 or 0
        end,
        set_norm = function(e, norm)
            return hardware_output_set_bool(e.track, e.output_index, "B_PHASE", clamp01(norm) >= 0.5)
        end
    }, track, index, display_index)

    grid_entries[#grid_entries + 1] = hardware_output_apply_common_fields({
        id = "mono",
        value_kind = "bool",
        label = "Mono",
        value = function(e)
            return bool_to_on_off(hardware_output_get_bool(e.track, e.output_index, "B_MONO"))
        end,
        get_norm = function(e)
            return hardware_output_get_bool(e.track, e.output_index, "B_MONO") and 1 or 0
        end,
        set_norm = function(e, norm)
            return hardware_output_set_bool(e.track, e.output_index, "B_MONO", clamp01(norm) >= 0.5)
        end
    }, track, index, display_index)

    grid_entries[#grid_entries + 1] = hardware_output_apply_common_fields({
        id = "audio_source_mode",
        value_kind = "stepped",
        label = "Audio source mode",
        value = function(e)
            return send_get_audio_source_mode_formatted(e.track, HARDWARE_OUTPUT_CATEGORY, e.output_index)
        end,
        get_norm = function(e)
            return send_get_audio_source_mode_norm(e.track, HARDWARE_OUTPUT_CATEGORY, e.output_index)
        end,
        set_norm = function(e, norm)
            return send_set_audio_source_mode_norm(e.track, HARDWARE_OUTPUT_CATEGORY, e.output_index, norm)
        end,
        step = function(e, direction)
            local old_mode = send_get_audio_source_mode(e.track, HARDWARE_OUTPUT_CATEGORY, e.output_index)
            local new_mode = old_mode

            if direction > 0 then
                new_mode = old_mode + 1
            elseif direction < 0 then
                new_mode = old_mode - 1
            end

            new_mode = clamp_int(new_mode, 0, 8)

            return send_set_audio_source_mode(e.track, HARDWARE_OUTPUT_CATEGORY, e.output_index, new_mode)
        end
    }, track, index, display_index)

    grid_entries[#grid_entries + 1] = hardware_output_apply_common_fields({
        id = "audio_source",
        value_kind = "routing_pair",
        label = "Audio source",
        value = function(e)
            return send_get_audio_source_formatted(e.track, HARDWARE_OUTPUT_CATEGORY, e.output_index)
        end,
        get_norm = function(e)
            return send_get_audio_source_norm(e.track, HARDWARE_OUTPUT_CATEGORY, e.output_index)
        end,
        set_norm = function(e, norm)
            return send_set_audio_source_norm(e.track, HARDWARE_OUTPUT_CATEGORY, e.output_index, norm)
        end,
        step = function(e, direction)
            local old_pair = send_get_audio_source_pair(e.track, HARDWARE_OUTPUT_CATEGORY, e.output_index)

            if old_pair < 0 then
                old_pair = 0
            end

            local new_pair = routing_pair_step_from_direction(old_pair, direction)

            return send_set_audio_source_pair(e.track, HARDWARE_OUTPUT_CATEGORY, e.output_index, new_pair)
        end
    }, track, index, display_index)

    grid_entries[#grid_entries + 1] = hardware_output_apply_common_fields({
        id = "hardware_destination",
        value_kind = "routing_pair",
        label = "Hardware destination",
        value = function(e)
            return hardware_output_destination_formatted(e.track, e.output_index)
        end,
        get_norm = function(e)
            return hardware_output_destination_norm(e.track, e.output_index)
        end,
        set_norm = function(e, norm)
            return hardware_output_set_destination_norm(e.track, e.output_index, norm)
        end,
        step = function(e, direction)
            local old_pair = hardware_output_destination_pair(e.track, e.output_index)
            local new_pair = routing_pair_step_from_direction(old_pair, direction)

            return hardware_output_set_destination_pair(e.track, e.output_index, new_pair)
        end
    }, track, index, display_index)

    grid_entries[#grid_entries + 1] = hardware_output_apply_common_fields({
        id = "send_type",
        value_kind = "stepped",
        label = "Send type",
        value = function(e)
            return send_get_mode_formatted(e.track, HARDWARE_OUTPUT_CATEGORY, e.output_index)
        end,
        get_norm = function(e)
            return send_get_mode_norm(e.track, HARDWARE_OUTPUT_CATEGORY, e.output_index)
        end,
        set_norm = function(e, norm)
            return send_set_mode_norm(e.track, HARDWARE_OUTPUT_CATEGORY, e.output_index, norm)
        end,
        step = function(e, direction)
            local old_mode = send_get_mode(e.track, HARDWARE_OUTPUT_CATEGORY, e.output_index)
            local new_mode = send_mode_step(old_mode, direction)

            return send_set_mode(e.track, HARDWARE_OUTPUT_CATEGORY, e.output_index, new_mode)
        end
    }, track, index, display_index)

    grid_entries[#grid_entries + 1] = hardware_output_apply_common_fields({
        id = "pan_law",
        value_kind = "stepped",
        label = "Pan law",
        value = function(e)
            return hardware_output_pan_law_formatted(e.track, e.output_index)
        end,
        get_norm = function(e)
            return hardware_output_pan_law_norm(e.track, e.output_index)
        end,
        set_norm = function(e, norm)
            return hardware_output_set_pan_law_norm(e.track, e.output_index, norm)
        end,
        step = function(e, direction)
            return hardware_output_pan_law_step(e.track, e.output_index, direction)
        end
    }, track, index, display_index)

    return true
end

function build_hardware_outputs_grid()
    grid_entries = {}

    if not current_track then
        grid_size = HARDWARE_OUTPUT_GRID_SIZE
        grid_pos = 1
        return false
    end

    local count = hardware_output_count(current_track)

    if count <= 0 then
        grid_size = HARDWARE_OUTPUT_GRID_SIZE
        grid_pos = 1
        return false
    end

    for i = 0, count - 1 do
        add_hardware_output_block_to_grid(current_track, i, i + 1)
    end

    grid_size = HARDWARE_OUTPUT_GRID_SIZE
    grid_pos = clamp_int(grid_pos, 1, math.max(1, #grid_entries))

    return #grid_entries > 0
end

function current_entry_is_hardware_output(entry)
    return entry and entry.kind == "hardware_output"
end

function delete_current_hardware_output()
    local e = get_current_entry()

    if not current_entry_is_hardware_output(e) then
        speak("No hardware output")
        return true
    end

    local old_pos = grid_pos
    local ok, reason = remove_track_send_instance(e.track, HARDWARE_OUTPUT_CATEGORY, e.output_index)

    if not ok then
        speak("Hardware output delete failed")
        return true
    end

    local built = build_hardware_outputs_grid()
    grid_pos = clamp_int(old_pos, 1, math.max(1, #grid_entries))
    refresh_window_title()

    if not built or #grid_entries <= 0 then
        speak("Deleted. No hardware outputs")
        return true
    end

    speak("Deleted hardware output")
    return true
end


------------------------------------------------------------
-- 3.5E - F8 REAROUTE BRIDGE
--
-- F8 gestisce il ponte audio virtuale ReaRoute della traccia:
-- - input ReaRoute tramite I_RECINPUT;
-- - output ReaRoute tramite hardware outputs filtrati su base 512.
------------------------------------------------------------

REAROUTE_BASE_CHANNEL = 512
REAROUTE_MAX_CHANNEL = 16

function rearoute_current_track()
    local e = get_current_entry()

    if e and e.track then
        return e.track
    end

    return current_track
end

function rearoute_raw_input(track)
    if not track or not reaper.GetMediaTrackInfo_Value then
        return -1
    end

    local v = reaper.GetMediaTrackInfo_Value(track, "I_RECINPUT")

    return math.floor((tonumber(v) or -1) + 0.5)
end

function rearoute_input_base(raw)
    raw = math.floor((tonumber(raw) or -1) + 0.5)

    if raw < 0 then
        return -1
    end

    return raw & 1023
end

function rearoute_input_is_stereo(raw)
    raw = math.floor((tonumber(raw) or -1) + 0.5)

    return raw >= 0 and (raw & 1024) ~= 0
end

function rearoute_input_is_multichannel(raw)
    raw = math.floor((tonumber(raw) or -1) + 0.5)

    return raw >= 0 and (raw & 2048) ~= 0
end

function rearoute_input_is_rearoute(track)
    local base = rearoute_input_base(rearoute_raw_input(track))

    return base >= REAROUTE_BASE_CHANNEL and
           base < (REAROUTE_BASE_CHANNEL + REAROUTE_MAX_CHANNEL)
end

function rearoute_input_start_channel(track)
    local base = rearoute_input_base(rearoute_raw_input(track))

    if base < REAROUTE_BASE_CHANNEL then
        return 1
    end

    return clamp_int((base - REAROUTE_BASE_CHANNEL) + 1, 1, REAROUTE_MAX_CHANNEL)
end

function rearoute_input_type_index(track)
    local raw = rearoute_raw_input(track)

    if not rearoute_input_is_rearoute(track) then
        return 0
    end

    if rearoute_input_is_multichannel(raw) then
        return 3
    end

    if rearoute_input_is_stereo(raw) then
        return 2
    end

    return 1
end

function rearoute_input_type_name(track)
    local t = rearoute_input_type_index(track)

    if t == 0 then
        return "Disabled"
    end

    if t == 1 then
        return "Mono"
    end

    if t == 2 then
        return "Stereo"
    end

    if t == 3 then
        return "Multichannel"
    end

    return "Disabled"
end

function rearoute_make_input_value(type_index, start_channel)
    type_index = clamp_int(type_index, 0, 3)
    start_channel = clamp_int(start_channel, 1, REAROUTE_MAX_CHANNEL)

    if type_index <= 0 then
        return -1
    end

    local value = REAROUTE_BASE_CHANNEL + (start_channel - 1)

    if type_index == 2 then
        value = value | 1024
    elseif type_index == 3 then
        value = value | 2048
    end

    return value
end

function rearoute_set_input(track, type_index, start_channel)
    if not track or not reaper.SetMediaTrackInfo_Value then
        return false
    end

    local value = rearoute_make_input_value(type_index, start_channel)

    reaper.SetMediaTrackInfo_Value(track, "I_RECINPUT", value)
    reaper.TrackList_AdjustWindows(false)
    reaper.UpdateArrange()

    return true
end

function rearoute_set_input_enabled(track, enabled)
    if enabled then
        local t = rearoute_input_type_index(track)

        if t <= 0 then
            t = 2
        end

        return rearoute_set_input(track, t, rearoute_input_start_channel(track))
    end

    return rearoute_set_input(track, 0, 1)
end

function rearoute_set_input_type(track, type_index)
    type_index = clamp_int(type_index, 0, 3)

    local start_channel = rearoute_input_start_channel(track)
    start_channel = clamp_int(start_channel, 1, rearoute_input_max_start_channel_for_type(type_index))

    return rearoute_set_input(track, type_index, start_channel)
end

function rearoute_input_max_start_channel_for_type(type_index)
    type_index = clamp_int(type_index, 0, 3)

    if type_index == 2 then
        return REAROUTE_MAX_CHANNEL - 1
    end

    return REAROUTE_MAX_CHANNEL
end

function rearoute_set_input_start_channel(track, start_channel)
    local t = rearoute_input_type_index(track)

    if t <= 0 then
        t = 2
    end

    start_channel = clamp_int(start_channel, 1, rearoute_input_max_start_channel_for_type(t))

    return rearoute_set_input(track, t, start_channel)
end

function rearoute_input_status_text(track)
    if rearoute_input_is_rearoute(track) then
        return "Enabled"
    end

    return "Disabled"
end

function rearoute_input_channel_text(track)
    local start = rearoute_input_start_channel(track)
    local t = rearoute_input_type_index(track)

    if t <= 0 then
        return "Disabled"
    end

    if t == 1 then
        return "ReaRoute " .. tostring(start)
    end

    return "ReaRoute " .. tostring(start) .. "/" .. tostring(start + 1)
end

function rearoute_input_start_text(track)
    local t = rearoute_input_type_index(track)

    if t <= 0 then
        return "Disabled"
    end

    return "ReaRoute " .. tostring(rearoute_input_start_channel(track))
end

function rearoute_input_width_text(track)
    local t = rearoute_input_type_index(track)

    if t <= 0 then
        return "Disabled"
    end

    if t == 1 then
        return "1 channel"
    end

    if t == 2 then
        return "2 channels"
    end

    return tostring(track_get_channel_count(track)) .. " track channels"
end

function rearoute_track_channels_norm(track)
    local ch = track_get_channel_count(track)

    return clamp01((ch - 2) / 126)
end

function rearoute_set_track_channels_norm(track, norm)
    norm = clamp01(norm)

    local ch = clamp_int(2 + (norm * 126), 2, 128)

    if (ch % 2) ~= 0 then
        ch = ch + 1
    end

    return track_ensure_channel_count(track, ch)
end

function rearoute_track_channels_step(track, direction)
    local ch = track_get_channel_count(track)

    if direction > 0 then
        ch = ch + 2
    elseif direction < 0 then
        ch = ch - 2
    end

    ch = clamp_int(ch, 2, 128)

    if (ch % 2) ~= 0 then
        ch = ch + 1
    end

    return track_ensure_channel_count(track, ch)
end

function rearoute_destination_offset(value)
    value = math.floor((tonumber(value) or 0) + 0.5)

    return value & 1023
end

function rearoute_output_is_rearoute(track, index)
    local off = rearoute_destination_offset(hardware_output_destination_value(track, index))

    return off >= REAROUTE_BASE_CHANNEL and
           off < (REAROUTE_BASE_CHANNEL + REAROUTE_MAX_CHANNEL)
end

function rearoute_output_count(track)
    local total = hardware_output_count(track)
    local count = 0

    for i = 0, total - 1 do
        if rearoute_output_is_rearoute(track, i) then
            count = count + 1
        end
    end

    return count
end

function rearoute_output_start_channel(track, index)
    local off = rearoute_destination_offset(hardware_output_destination_value(track, index))

    if off < REAROUTE_BASE_CHANNEL then
        return 1
    end

    return clamp_int((off - REAROUTE_BASE_CHANNEL) + 1, 1, REAROUTE_MAX_CHANNEL)
end

function rearoute_make_destination_value(start_channel, mono)
    start_channel = clamp_int(start_channel, 1, REAROUTE_MAX_CHANNEL)

    local value = REAROUTE_BASE_CHANNEL + (start_channel - 1)

    if mono then
        value = value | 1024
    end

    return value
end

function rearoute_output_max_start_channel(track, index)
    local raw = hardware_output_destination_value(track, index)

    if audio_dst_mono(raw) then
        return REAROUTE_MAX_CHANNEL
    end

    return REAROUTE_MAX_CHANNEL - 1
end

function rearoute_set_destination_channel(track, index, start_channel)
    local old_value = hardware_output_destination_value(track, index)
    local mono = audio_dst_mono(old_value)

    start_channel = clamp_int(start_channel, 1, rearoute_output_max_start_channel(track, index))

    return hardware_output_set_destination_value(
        track,
        index,
        rearoute_make_destination_value(start_channel, mono)
    )
end

function rearoute_destination_norm(track, index)
    return (rearoute_output_start_channel(track, index) - 1) / (REAROUTE_MAX_CHANNEL - 1)
end

function rearoute_set_destination_norm(track, index, norm)
    norm = clamp01(norm)

    local ch = clamp_int(1 + (norm * (REAROUTE_MAX_CHANNEL - 1)), 1, rearoute_output_max_start_channel(track, index))

    return rearoute_set_destination_channel(track, index, ch)
end

function rearoute_destination_step(track, index, direction)
    local ch = rearoute_output_start_channel(track, index)

    if direction > 0 then
        ch = ch + 1
    elseif direction < 0 then
        ch = ch - 1
    end

    ch = clamp_int(ch, 1, rearoute_output_max_start_channel(track, index))

    return rearoute_set_destination_channel(track, index, ch)
end

function rearoute_destination_formatted(track, index)
    local ch = rearoute_output_start_channel(track, index)
    local raw = hardware_output_destination_value(track, index)

    if audio_dst_mono(raw) then
        return "ReaRoute " .. tostring(ch) .. " mono"
    end

    return "ReaRoute " .. tostring(ch) .. "/" .. tostring(ch + 1)
end

function rearoute_output_context_label(entry)
    if not entry or entry.kind ~= "rearoute" or entry.direction ~= "output" then
        return "ReaRoute output"
    end

    return "ReaRoute output " ..
        tostring(entry.display_index or 1) ..
        " to " ..
        rearoute_destination_formatted(entry.track, entry.output_index)
end

function rearoute_apply_common_fields(t, track, direction, index, display_index)
    t.kind = "rearoute"
    t.track = track
    t.direction = direction
    t.category = HARDWARE_OUTPUT_CATEGORY
    t.send_index = index or 0
    t.output_index = index or 0
    t.display_index = display_index or 1

    return t
end

function rearoute_create_output(track)
    if not track or not reaper.CreateTrackSend then
        speak("Could not create ReaRoute output")
        return true
    end

    local ok, index = pcall(reaper.CreateTrackSend, track, nil)

    if not ok or (tonumber(index) or -1) < 0 then
        speak("Could not create ReaRoute output")
        return true
    end

    index = tonumber(index) or 0

    hardware_output_set_destination_value(track, index, rearoute_make_destination_value(1, false))
    build_rearoute_grid()

    for pos = 1, #grid_entries do
        local e = grid_entries[pos]

        if e and e.kind == "rearoute" and e.direction == "output" and
           tonumber(e.output_index) == index and e.id == "rearoute_output_header" then
            grid_pos = pos
            break
        end
    end

    refresh_window_title()
    speak("Added ReaRoute output")

    return true
end

function rearoute_add_input_block_to_grid(track)
    --------------------------------------------------------
    -- Colonna 1: ReaRoute input.
    -- Questa colonna contiene solo l'ingresso ReaRoute della
    -- traccia. Gli output ReaRoute stanno nella colonna
    -- successiva, così F8 resta leggibile come ponte input/output.
    --------------------------------------------------------

    grid_entries[#grid_entries + 1] = rearoute_apply_common_fields({
        id = "rearoute_input_header",
        label = "ReaRoute input",
        value = function(e)
            return rearoute_input_channel_text(e.track)
        end,
        enter = function(e)
            speak("ReaRoute input. " .. rearoute_input_channel_text(e.track))
            return true
        end
    }, track, "input", -1, 1)

    grid_entries[#grid_entries + 1] = rearoute_apply_common_fields({
        id = "rearoute_input_enabled",
        value_kind = "bool",
        label = "Input enabled",
        value = function(e)
            return rearoute_input_status_text(e.track)
        end,
        get_norm = function(e)
            return rearoute_input_is_rearoute(e.track) and 1 or 0
        end,
        set_norm = function(e, norm)
            return rearoute_set_input_enabled(e.track, clamp01(norm) >= 0.5)
        end
    }, track, "input", -1, 1)

    grid_entries[#grid_entries + 1] = rearoute_apply_common_fields({
        id = "rearoute_input_type",
        value_kind = "stepped",
        label = "Input type",
        value = function(e)
            return rearoute_input_type_name(e.track)
        end,
        get_norm = function(e)
            return rearoute_input_type_index(e.track) / 3
        end,
        set_norm = function(e, norm)
            return rearoute_set_input_type(e.track, clamp_int(clamp01(norm) * 3, 0, 3))
        end,
        step = function(e, direction)
            local t = rearoute_input_type_index(e.track)

            if direction > 0 then
                t = t + 1
            elseif direction < 0 then
                t = t - 1
            end

            t = clamp_int(t, 0, 3)

            return rearoute_set_input_type(e.track, t)
        end
    }, track, "input", -1, 1)

    grid_entries[#grid_entries + 1] = rearoute_apply_common_fields({
        id = "rearoute_input_channel",
        value_kind = "stepped",
        label = "Input channel or pair",
        value = function(e)
            return rearoute_input_channel_text(e.track)
        end,
        get_norm = function(e)
            return (rearoute_input_start_channel(e.track) - 1) / (REAROUTE_MAX_CHANNEL - 1)
        end,
        set_norm = function(e, norm)
            local ch = clamp_int(1 + (clamp01(norm) * (REAROUTE_MAX_CHANNEL - 1)), 1, REAROUTE_MAX_CHANNEL)
            return rearoute_set_input_start_channel(e.track, ch)
        end,
        step = function(e, direction)
            local ch = rearoute_input_start_channel(e.track)

            if direction > 0 then
                ch = ch + 1
            elseif direction < 0 then
                ch = ch - 1
            end

            ch = clamp_int(ch, 1, REAROUTE_MAX_CHANNEL)

            return rearoute_set_input_start_channel(e.track, ch)
        end
    }, track, "input", -1, 1)

    grid_entries[#grid_entries + 1] = rearoute_apply_common_fields({
        id = "rearoute_input_start",
        value_kind = "stepped",
        label = "Input start",
        value = function(e)
            return rearoute_input_start_text(e.track)
        end,
        get_norm = function(e)
            return (rearoute_input_start_channel(e.track) - 1) / (REAROUTE_MAX_CHANNEL - 1)
        end,
        set_norm = function(e, norm)
            local ch = clamp_int(1 + (clamp01(norm) * (REAROUTE_MAX_CHANNEL - 1)), 1, REAROUTE_MAX_CHANNEL)
            return rearoute_set_input_start_channel(e.track, ch)
        end,
        step = function(e, direction)
            local ch = rearoute_input_start_channel(e.track)

            if direction > 0 then
                ch = ch + 1
            elseif direction < 0 then
                ch = ch - 1
            end

            return rearoute_set_input_start_channel(e.track, clamp_int(ch, 1, REAROUTE_MAX_CHANNEL))
        end
    }, track, "input", -1, 1)

    grid_entries[#grid_entries + 1] = rearoute_apply_common_fields({
        id = "rearoute_input_width",
        label = "Input width",
        value = function(e)
            return rearoute_input_width_text(e.track)
        end,
        enter = function(e)
            speak("Input width " .. rearoute_input_width_text(e.track))
            return true
        end
    }, track, "input", -1, 1)

    grid_entries[#grid_entries + 1] = rearoute_apply_common_fields({
        id = "rearoute_track_channels",
        value_kind = "stepped",
        label = "Track channels",
        value = function(e)
            return tostring(track_get_channel_count(e.track))
        end,
        get_norm = function(e)
            return rearoute_track_channels_norm(e.track)
        end,
        set_norm = function(e, norm)
            return rearoute_set_track_channels_norm(e.track, norm)
        end,
        step = function(e, direction)
            return rearoute_track_channels_step(e.track, direction)
        end
    }, track, "input", -1, 1)

    grid_entries[#grid_entries + 1] = rearoute_apply_common_fields({
        id = "rearoute_input_raw",
        label = "Input raw value",
        value = function(e)
            return tostring(rearoute_raw_input(e.track))
        end,
        enter = function(e)
            speak("Input raw value " .. tostring(rearoute_raw_input(e.track)))
            return true
        end
    }, track, "input", -1, 1)

    grid_entries[#grid_entries + 1] = rearoute_apply_common_fields({
        id = "rearoute_input_note",
        label = "Input note",
        value = function(e)
            return "Track input only"
        end,
        enter = function(e)
            speak("ReaRoute input belongs to the current track input. It does not change record arm or monitoring.")
            return true
        end
    }, track, "input", -1, 1)

    grid_entries[#grid_entries + 1] = rearoute_apply_common_fields({
        id = "rearoute_input_to_output_note",
        label = "Output side",
        value = function(e)
            return "Next column"
        end,
        enter = function(e)
            speak("ReaRoute outputs are in the next column")
            return true
        end
    }, track, "input", -1, 1)

    grid_entries[#grid_entries + 1] = rearoute_apply_common_fields({
        id = "rearoute_note",
        label = "ReaRoute note",
        value = function(e)
            return "Input and output bridge"
        end,
        enter = function(e)
            speak("ReaRoute input and output bridge")
            return true
        end
    }, track, "input", -1, 1)

    return true
end

function rearoute_add_output_control_block_to_grid(track)
    --------------------------------------------------------
    -- Colonna 2: controllo generale degli output ReaRoute.
    -- Se non esistono output, questa è comunque la colonna
    -- Output e permette di crearne uno con Enter.
    --------------------------------------------------------

    grid_entries[#grid_entries + 1] = rearoute_apply_common_fields({
        id = "rearoute_output_section_header",
        label = "ReaRoute output",
        value = function(e)
            local count = rearoute_output_count(e.track)
            if count == 1 then
                return "1 output"
            end
            return tostring(count) .. " outputs"
        end,
        enter = function(e)
            local count = rearoute_output_count(e.track)
            if count == 1 then
                speak("1 ReaRoute output")
            else
                speak(tostring(count) .. " ReaRoute outputs")
            end
            return true
        end
    }, track, "output_control", -1, 1)

    grid_entries[#grid_entries + 1] = rearoute_apply_common_fields({
        id = "rearoute_output_count",
        label = "ReaRoute output count",
        value = function(e)
            return tostring(rearoute_output_count(e.track))
        end,
        enter = function(e)
            speak(tostring(rearoute_output_count(e.track)) .. " ReaRoute outputs")
            return true
        end
    }, track, "output_control", -1, 1)

    grid_entries[#grid_entries + 1] = rearoute_apply_common_fields({
        id = "rearoute_add_output",
        label = "Add ReaRoute output",
        value = function(e)
            return "Enter"
        end,
        enter = function(e)
            return rearoute_create_output(e.track)
        end
    }, track, "output_control", -1, 1)

    grid_entries[#grid_entries + 1] = rearoute_apply_common_fields({
        id = "rearoute_output_hint",
        label = "Output hint",
        value = function(e)
            if rearoute_output_count(e.track) > 0 then
                return "Output columns follow"
            end
            return "No output yet"
        end,
        enter = function(e)
            if rearoute_output_count(e.track) > 0 then
                speak("ReaRoute output columns follow")
            else
                speak("No ReaRoute output yet. Press Enter on Add ReaRoute output")
            end
            return true
        end
    }, track, "output_control", -1, 1)

    local rows = {
        {"Output volume", "Use output column"},
        {"Output pan", "Use output column"},
        {"Output mute", "Use output column"},
        {"Output phase", "Use output column"},
        {"Output mono", "Use output column"},
        {"Output source", "Use output column"},
        {"Output destination", "Use output column"}
    }

    for i = 1, #rows do
        local label = rows[i][1]
        local val = rows[i][2]

        grid_entries[#grid_entries + 1] = rearoute_apply_common_fields({
            id = "rearoute_output_info_" .. tostring(i),
            label = label,
            value = function(e)
                if rearoute_output_count(e.track) > 0 then
                    return val
                end
                return "No output"
            end,
            enter = function(e)
                if rearoute_output_count(e.track) > 0 then
                    speak(label .. ". Use the ReaRoute output columns")
                else
                    speak("No ReaRoute output")
                end
                return true
            end
        }, track, "output_control", -1, 1)
    end

    return true
end

function rearoute_add_output_block_to_grid(track, index, display_index)
    index = tonumber(index) or 0
    display_index = tonumber(display_index) or (index + 1)

    grid_entries[#grid_entries + 1] = rearoute_apply_common_fields({
        id = "rearoute_output_header",
        label = "ReaRoute output " .. tostring(display_index),
        value = function(e)
            return "to " .. rearoute_destination_formatted(e.track, e.output_index)
        end,
        enter = function(e)
            speak(rearoute_output_context_label(e))
            return true
        end
    }, track, "output", index, display_index)

    grid_entries[#grid_entries + 1] = rearoute_apply_common_fields({
        id = "volume",
        value_kind = "continuous",
        label = "Volume",
        value = function(e)
            return send_get_volume_formatted(e.track, HARDWARE_OUTPUT_CATEGORY, e.output_index)
        end,
        get_norm = function(e)
            return send_get_volume_norm(e.track, HARDWARE_OUTPUT_CATEGORY, e.output_index)
        end,
        set_norm = function(e, norm)
            return send_set_volume_norm(e.track, HARDWARE_OUTPUT_CATEGORY, e.output_index, norm)
        end
    }, track, "output", index, display_index)

    grid_entries[#grid_entries + 1] = rearoute_apply_common_fields({
        id = "pan",
        value_kind = "continuous",
        label = "Pan",
        value = function(e)
            return send_get_pan_formatted(e.track, HARDWARE_OUTPUT_CATEGORY, e.output_index)
        end,
        get_norm = function(e)
            return send_get_pan_norm(e.track, HARDWARE_OUTPUT_CATEGORY, e.output_index)
        end,
        set_norm = function(e, norm)
            return send_set_pan_norm(e.track, HARDWARE_OUTPUT_CATEGORY, e.output_index, norm)
        end
    }, track, "output", index, display_index)

    grid_entries[#grid_entries + 1] = rearoute_apply_common_fields({
        id = "mute",
        value_kind = "bool",
        label = "Mute",
        value = function(e)
            return bool_to_on_off(send_get_mute(e.track, HARDWARE_OUTPUT_CATEGORY, e.output_index))
        end,
        get_norm = function(e)
            return send_get_mute(e.track, HARDWARE_OUTPUT_CATEGORY, e.output_index) and 1 or 0
        end,
        set_norm = function(e, norm)
            return send_set_mute(e.track, HARDWARE_OUTPUT_CATEGORY, e.output_index, clamp01(norm) >= 0.5)
        end
    }, track, "output", index, display_index)

    grid_entries[#grid_entries + 1] = rearoute_apply_common_fields({
        id = "phase",
        value_kind = "bool",
        label = "Phase invert",
        value = function(e)
            return bool_to_on_off(hardware_output_get_bool(e.track, e.output_index, "B_PHASE"))
        end,
        get_norm = function(e)
            return hardware_output_get_bool(e.track, e.output_index, "B_PHASE") and 1 or 0
        end,
        set_norm = function(e, norm)
            return hardware_output_set_bool(e.track, e.output_index, "B_PHASE", clamp01(norm) >= 0.5)
        end
    }, track, "output", index, display_index)

    grid_entries[#grid_entries + 1] = rearoute_apply_common_fields({
        id = "mono",
        value_kind = "bool",
        label = "Mono",
        value = function(e)
            return bool_to_on_off(hardware_output_get_bool(e.track, e.output_index, "B_MONO"))
        end,
        get_norm = function(e)
            return hardware_output_get_bool(e.track, e.output_index, "B_MONO") and 1 or 0
        end,
        set_norm = function(e, norm)
            return hardware_output_set_bool(e.track, e.output_index, "B_MONO", clamp01(norm) >= 0.5)
        end
    }, track, "output", index, display_index)

    grid_entries[#grid_entries + 1] = rearoute_apply_common_fields({
        id = "audio_source_mode",
        value_kind = "stepped",
        label = "Audio source mode",
        value = function(e)
            return send_get_audio_source_mode_formatted(e.track, HARDWARE_OUTPUT_CATEGORY, e.output_index)
        end,
        get_norm = function(e)
            return send_get_audio_source_mode_norm(e.track, HARDWARE_OUTPUT_CATEGORY, e.output_index)
        end,
        set_norm = function(e, norm)
            return send_set_audio_source_mode_norm(e.track, HARDWARE_OUTPUT_CATEGORY, e.output_index, norm)
        end,
        step = function(e, direction)
            local old_mode = send_get_audio_source_mode(e.track, HARDWARE_OUTPUT_CATEGORY, e.output_index)
            local new_mode = old_mode

            if direction > 0 then
                new_mode = old_mode + 1
            elseif direction < 0 then
                new_mode = old_mode - 1
            end

            new_mode = clamp_int(new_mode, 0, 8)

            return send_set_audio_source_mode(e.track, HARDWARE_OUTPUT_CATEGORY, e.output_index, new_mode)
        end
    }, track, "output", index, display_index)

    grid_entries[#grid_entries + 1] = rearoute_apply_common_fields({
        id = "audio_source",
        value_kind = "routing_pair",
        label = "Audio source",
        value = function(e)
            return send_get_audio_source_formatted(e.track, HARDWARE_OUTPUT_CATEGORY, e.output_index)
        end,
        get_norm = function(e)
            return send_get_audio_source_norm(e.track, HARDWARE_OUTPUT_CATEGORY, e.output_index)
        end,
        set_norm = function(e, norm)
            return send_set_audio_source_norm(e.track, HARDWARE_OUTPUT_CATEGORY, e.output_index, norm)
        end,
        step = function(e, direction)
            local old_pair = send_get_audio_source_pair(e.track, HARDWARE_OUTPUT_CATEGORY, e.output_index)

            if old_pair < 0 then
                old_pair = 0
            end

            return send_set_audio_source_pair(
                e.track,
                HARDWARE_OUTPUT_CATEGORY,
                e.output_index,
                routing_pair_step_from_direction(old_pair, direction)
            )
        end
    }, track, "output", index, display_index)

    grid_entries[#grid_entries + 1] = rearoute_apply_common_fields({
        id = "rearoute_destination",
        value_kind = "routing_pair",
        label = "ReaRoute destination",
        value = function(e)
            return rearoute_destination_formatted(e.track, e.output_index)
        end,
        get_norm = function(e)
            return rearoute_destination_norm(e.track, e.output_index)
        end,
        set_norm = function(e, norm)
            return rearoute_set_destination_norm(e.track, e.output_index, norm)
        end,
        step = function(e, direction)
            return rearoute_destination_step(e.track, e.output_index, direction)
        end
    }, track, "output", index, display_index)

    grid_entries[#grid_entries + 1] = rearoute_apply_common_fields({
        id = "send_type",
        value_kind = "stepped",
        label = "Send type",
        value = function(e)
            return send_get_mode_formatted(e.track, HARDWARE_OUTPUT_CATEGORY, e.output_index)
        end,
        get_norm = function(e)
            return send_get_mode_norm(e.track, HARDWARE_OUTPUT_CATEGORY, e.output_index)
        end,
        set_norm = function(e, norm)
            return send_set_mode_norm(e.track, HARDWARE_OUTPUT_CATEGORY, e.output_index, norm)
        end,
        step = function(e, direction)
            return send_set_mode(e.track, HARDWARE_OUTPUT_CATEGORY, e.output_index, send_mode_step(send_get_mode(e.track, HARDWARE_OUTPUT_CATEGORY, e.output_index), direction))
        end
    }, track, "output", index, display_index)

    grid_entries[#grid_entries + 1] = rearoute_apply_common_fields({
        id = "pan_law",
        value_kind = "stepped",
        label = "Pan law",
        value = function(e)
            return hardware_output_pan_law_formatted(e.track, e.output_index)
        end,
        get_norm = function(e)
            return hardware_output_pan_law_norm(e.track, e.output_index)
        end,
        set_norm = function(e, norm)
            return hardware_output_set_pan_law_norm(e.track, e.output_index, norm)
        end,
        step = function(e, direction)
            return hardware_output_pan_law_step(e.track, e.output_index, direction)
        end
    }, track, "output", index, display_index)

    return true
end

function build_rearoute_grid()
    grid_entries = {}
    grid_size = REAROUTE_GRID_SIZE

    if not current_track then
        grid_pos = 1
        return false
    end

    rearoute_add_input_block_to_grid(current_track)
    rearoute_add_output_control_block_to_grid(current_track)

    local display_index = 1
    local total = hardware_output_count(current_track)

    for i = 0, total - 1 do
        if rearoute_output_is_rearoute(current_track, i) then
            rearoute_add_output_block_to_grid(current_track, i, display_index)
            display_index = display_index + 1
        end
    end

    grid_pos = clamp_int(grid_pos, 1, math.max(1, #grid_entries))

    return #grid_entries > 0
end

function current_entry_is_rearoute(entry)
    return entry and entry.kind == "rearoute"
end

function delete_current_rearoute_output()
    local e = get_current_entry()

    if not e or e.kind ~= "rearoute" or e.direction ~= "output" then
        speak("No ReaRoute output")
        return true
    end

    local old_pos = grid_pos
    local ok, reason = remove_track_send_instance(e.track, HARDWARE_OUTPUT_CATEGORY, e.output_index)

    if not ok then
        speak("ReaRoute output delete failed")
        return true
    end

    build_rearoute_grid()
    grid_pos = clamp_int(old_pos, 1, math.max(1, #grid_entries))
    refresh_window_title()

    speak("Deleted ReaRoute output")
    return true
end


------------------------------------------------------------
-- 3.6 - F4 HELPERS DI POSIZIONE FX
--
-- In F4:
-- - Home = intestazione FX precedente.
-- - End = intestazione FX successiva.
-- - Page Up = primo parametro visibile dell'FX corrente.
-- - Page Down = ultimo parametro visibile dell'FX corrente.
------------------------------------------------------------

function current_entry_fx_index()
    local e = get_current_entry()

    if not e then
        return -1
    end

    if e.fx_index == nil then
        return -1
    end

    return tonumber(e.fx_index) or -1
end

function f4_current_fx_index()
    return current_entry_fx_index()
end

function f4_find_header_pos_for_fx(fx_index)
    fx_index = tonumber(fx_index) or -1

    if fx_index < 0 then
        return 0
    end

    for pos = 1, #grid_entries do
        local e = grid_entries[pos]

        if e and
           e.kind == "fx_header" and
           tonumber(e.fx_index) == fx_index then
            return pos
        end
    end

    return 0
end

function f4_find_param_pos_for_fx_param(fx_index, param_index)
    fx_index = tonumber(fx_index) or -1
    param_index = tonumber(param_index)

    if fx_index < 0 or param_index == nil then
        return 0
    end

    for pos = 1, #grid_entries do
        local e = grid_entries[pos]

        if e and
           e.kind == "fx_param" and
           tonumber(e.fx_index) == fx_index and
           tonumber(e.param_index) == param_index then

            return pos
        end
    end

    return 0
end

function f4_find_previous_fx_header_pos()
    if current_section_id ~= SECTION_FX_PARAMS then
        return 0
    end

    local current_fx = f4_current_fx_index()

    if current_fx < 0 then
        return 0
    end

    local current_header_pos = f4_find_header_pos_for_fx(current_fx)

    if current_header_pos <= 0 then
        return 0
    end

    local e = get_current_entry()

    --------------------------------------------------------
    -- F4 Home:
    --
    -- Se siamo dentro un parametro, Home va
    -- all'intestazione dell'FX corrente.
    --
    -- Se siamo già sull'intestazione, Home va
    -- all'intestazione dell'FX precedente, se esiste.
    --------------------------------------------------------

    if e and e.kind ~= "fx_header" then
        return current_header_pos
    end

    for pos = current_header_pos - 1, 1, -1 do
        local ge = grid_entries[pos]

        if ge and ge.kind == "fx_header" then
            return pos
        end
    end

    return 0
end

function f4_find_next_fx_header_pos()
    if current_section_id ~= SECTION_FX_PARAMS then
        return 0
    end

    local current_fx = f4_current_fx_index()

    if current_fx < 0 then
        return 0
    end

    local current_header_pos = f4_find_header_pos_for_fx(current_fx)

    if current_header_pos <= 0 then
        return 0
    end

    local e = get_current_entry()

    --------------------------------------------------------
    -- F4 End:
    --
    -- Se siamo dentro un parametro:
    -- - cerca l'intestazione dell'FX successivo;
    -- - se non esiste, torna all'intestazione dell'FX corrente,
    --   cioè l'ultimo FX disponibile.
    --
    -- Se siamo già su un'intestazione:
    -- - cerca l'intestazione dell'FX successivo;
    -- - se non esiste, non fa nulla.
    --
    -- Importante:
    -- non usare #grid_entries come fallback, perché quello può
    -- essere un parametro, non un nome FX.
    --------------------------------------------------------

    for pos = current_header_pos + 1, #grid_entries do
        local ge = grid_entries[pos]

        if ge and ge.kind == "fx_header" then
            return pos
        end
    end

    if e and e.kind ~= "fx_header" then
        return current_header_pos
    end

    return 0
end

function f4_find_first_param_pos_for_current_fx()
    if current_section_id ~= SECTION_FX_PARAMS then
        return 0
    end

    local current_fx = f4_current_fx_index()

    if current_fx < 0 then
        return 0
    end

    local header_pos = f4_find_header_pos_for_fx(current_fx)

    if header_pos <= 0 then
        return 0
    end

    for pos = header_pos + 1, #grid_entries do
        local e = grid_entries[pos]

        if e and e.kind == "fx_header" then
            break
        end

        if e and
           e.kind == "fx_param" and
           tonumber(e.fx_index) == current_fx then
            return pos
        end
    end

    return 0
end

function f4_find_last_param_pos_for_current_fx()
    if current_section_id ~= SECTION_FX_PARAMS then
        return 0
    end

    local current_fx = f4_current_fx_index()

    if current_fx < 0 then
        return 0
    end

    local header_pos = f4_find_header_pos_for_fx(current_fx)

    if header_pos <= 0 then
        return 0
    end

    local last_param_pos = 0

    for pos = header_pos + 1, #grid_entries do
        local e = grid_entries[pos]

        if e and e.kind == "fx_header" then
            break
        end

        if e and
           e.kind == "fx_param" and
           tonumber(e.fx_index) == current_fx then
            last_param_pos = pos
        end
    end

    return last_param_pos
end

function f4_move_previous_fx_header()
    local pos = f4_find_previous_fx_header_pos()

    if pos <= 0 then
        return grid_edge("f4-prev-fx")
    end

    return grid_move_to_pos(pos, true, "vertical")
end

function f4_move_next_fx_header()
    local pos = f4_find_next_fx_header_pos()

    if pos <= 0 then
        return grid_edge("f4-next-fx")
    end

    return grid_move_to_pos(pos, true, "vertical")
end

function f4_move_first_param_current_fx()
    local pos = f4_find_first_param_pos_for_current_fx()

    if pos <= 0 then
        return grid_edge("f4-first-param")
    end

    return grid_move_to_pos(pos, true, "vertical")
end

function f4_move_last_param_current_fx()
    local pos = f4_find_last_param_pos_for_current_fx()

    if pos <= 0 then
        return grid_edge("f4-last-param")
    end

    return grid_move_to_pos(pos, true, "vertical")
end

------------------------------------------------------------
-- 3.7 - BUILD GRID DISPATCH
------------------------------------------------------------

function build_current_grid_core()
    if current_section_id == SECTION_TRACKS then
        return build_tracks_grid()
    end

    if current_section_id == SECTION_SENDS then
        return build_sends_grid()
    end

    if current_section_id == SECTION_RECEIVES then
        return build_receives_grid()
    end

    if current_section_id == SECTION_FX_PARAMS then
        return build_fx_params_grid()
    end

    if current_section_id == PIN_AUDIO_SECTION_ID then
        return build_pin_audio_grid()
    end

    if current_section_id == PIN_MIDI_SECTION_ID then
        return build_pin_midi_grid()
    end

    if current_section_id == HARDWARE_OUTPUT_SECTION_ID then
        return build_hardware_outputs_grid()
    end

    if current_section_id == REAROUTE_SECTION_ID then
        return build_rearoute_grid()
    end

    grid_entries = {}
    grid_pos = 1

    return false
end

function runtime_safe_apply_grid_limit()
    if runtime_safe_mode ~= true then
        return false
    end

    while #grid_entries > 20 do
        table.remove(grid_entries)
    end

    grid_size = clamp_int(grid_size, 1, 20)
    grid_pos = clamp_int(grid_pos, 1, math.max(1, #grid_entries))

    return true
end

function build_current_grid()
    local ok = build_current_grid_core()

    runtime_safe_apply_grid_limit()

    return ok
end

------------------------------------------------------------
-- 3.7A - SESSION TRACK MEMORIES
------------------------------------------------------------

TRACK_MEMORY_KEYS = {
    [KEY_F1]  = 1,
    [KEY_F2]  = 2,
    [KEY_F3]  = 3,
    [KEY_F4]  = 4,
    [KEY_F5]  = 5,
    [KEY_F6]  = 6,
    [KEY_F7]  = 7,
    [KEY_F8]  = 8,
    [KEY_F9]  = 9,
    [KEY_F10] = 10,
    [KEY_F11] = 11,
    [KEY_F12] = 12
}

function track_memory_key_to_slot(char)
    return TRACK_MEMORY_KEYS[char]
end

function track_memory_clear_delete_arm()
    track_memory_delete_armed_slot = nil
end

function track_memory_arm_delete(slot)
    track_memory_delete_armed_slot = clamp_int(slot, 1, 12)
end

function track_memory_is_context_allowed()
    if mode ~= "grid" then
        return false
    end

    if current_section_id == SECTION_TRACKS then
        return true
    end

    if current_section_id == SECTION_FX_PARAMS then
        return true
    end

    return false
end

function track_memory_find_track_by_guid(guid)
    guid = clean_one_line(guid or "")

    if guid == "" then
        return nil
    end

    local count = get_project_track_count()

    for i = 0, count - 1 do
        local tr = get_track_by_index(i)

        if tr and get_track_guid(tr) == guid then
            return tr
        end
    end

    return nil
end

function track_memory_slot_label(slot)
    slot = clamp_int(slot, 1, 12)

    local mem = track_memory_slots[slot]

    if not mem then
        return ""
    end

    local tr = track_memory_find_track_by_guid(mem.guid)

    if tr then
        return get_track_folder_spoken_label(tr)
    end

    local name = clean_one_line(mem.name or "")

    if name ~= "" then
        return name
    end

    local number = tonumber(mem.number) or 0

    if number > 0 then
        return "Track " .. tostring(number)
    end

    return "Track"
end

function track_memory_current_track_for_save()
    local e = get_current_entry()

    if current_section_id == SECTION_TRACKS and e and e.track then
        return e.track
    end

    return current_track
end

function track_memory_save_slot(slot)
    slot = clamp_int(slot, 1, 12)

    if not track_memory_is_context_allowed() then
        return false
    end

    --------------------------------------------------------
    -- Protezione memoria:
    -- Alt+Shift+F-slot salva SOLO se lo slot è vuoto.
    -- Se lo slot è occupato, non sovrascrive mai.
    -- Delete, subito dopo, resta l'unico modo per liberarlo.
    --------------------------------------------------------
    if track_memory_slots[slot] ~= nil then
        track_memory_arm_delete(slot)

        speak(
            tostring(slot) ..
            " occupied. " ..
            track_memory_slot_label(slot)
        )

        return true
    end

    local tr = track_memory_current_track_for_save()

    if not tr then
        speak("No track")
        return true
    end

    local guid = get_track_guid(tr)

    if guid == "" then
        speak("Cannot save track memory")
        return true
    end

    track_memory_slots[slot] = {
        guid = guid,
        name = get_track_plain_short_label(tr),
        number = get_track_number(tr)
    }

    track_memory_save_session_slot(slot)
    track_memory_arm_delete(slot)

    speak(
        tostring(slot) ..
        " saved. " ..
        get_track_folder_spoken_label(tr)
    )

    return true
end

function track_memory_delete_slot(slot)
    slot = clamp_int(slot, 1, 12)

    if track_memory_slots[slot] == nil then
        speak("No track memory " .. tostring(slot))
        track_memory_clear_delete_arm()
        return true
    end

    track_memory_slots[slot] = nil
    track_memory_clear_session_slot(slot)
    track_memory_clear_delete_arm()

    speak(tostring(slot) .. " deleted")

    return true
end

function track_memory_go_to_f1(track, slot, reason)
    local wanted_col = grid_col_from_pos(grid_pos)

    current_section_key = KEY_F1
    current_section_id = SECTION_TRACKS
    mode = "grid"

    clear_track_selection_silent()

    if track then
        open_parent_folders_for_track(track)
        set_current_track_pointer_only(track)
    end

    build_current_grid()

    if track then
        local row = get_row_for_track_in_current_grid(track)

        ----------------------------------------------------
        -- Se un filtro attivo impedisce alla traccia di
        -- comparire, lo togliamo: una memoria deve sempre
        -- portare alla traccia salvata.
        ----------------------------------------------------

        if row <= 0 and filter_is_active() then
            clear_filter_query()
            build_current_grid()
            row = get_row_for_track_in_current_grid(track)
        end

        if row > 0 then
            grid_pos = grid_pos_from_row_col(row, wanted_col)
        end
    end

    grid_pos = clamp_int(grid_pos, 1, math.max(1, #grid_entries))
    refresh_window_title()

    local msg =
        tostring(slot) ..
        ". " ..
        track_memory_slot_label(slot)

    reason = clean_one_line(reason or "")

    if reason ~= "" then
        msg = msg .. ". " .. reason
    end

    speak(msg)

    return true
end

function track_memory_go_to_f4(track, slot)
    current_section_key = KEY_F4
    current_section_id = SECTION_FX_PARAMS
    mode = "grid"
    grid_pos = 1

    if track then
        set_current_track_pointer_only(track)
    end

    local fx_count = 0

    if track and reaper.TrackFX_GetCount then
        fx_count = reaper.TrackFX_GetCount(track) or 0
    end

    if fx_count <= 0 then
        return track_memory_go_to_f1(track, slot, "No FX")
    end

    local ok = build_current_grid()

    if not ok or #grid_entries <= 0 then
        if filter_is_active() then
            clear_filter_query()
            ok = build_current_grid()
        end
    end

    if not ok or #grid_entries <= 0 then
        return track_memory_go_to_f1(track, slot, "No FX parameters")
    end

    grid_pos = clamp_int(grid_pos, 1, math.max(1, #grid_entries))
    refresh_window_title()

    speak(
        tostring(slot) ..
        ". " ..
        get_track_folder_spoken_label(track) ..
        ". " ..
        current_entry_contextual_label()
    )

    return true
end

function track_memory_recall_slot(slot)
    slot = clamp_int(slot, 1, 12)

    if not track_memory_is_context_allowed() then
        return false
    end

    local mem = track_memory_slots[slot]

    if not mem then
        speak("No track memory " .. tostring(slot))
        return true
    end

    local tr = track_memory_find_track_by_guid(mem.guid)

    track_memory_arm_delete(slot)

    if not tr then
        speak("Track memory " .. tostring(slot) .. " not found")
        return true
    end

    open_parent_folders_for_track(tr)

    if current_section_id == SECTION_FX_PARAMS then
        return track_memory_go_to_f4(tr, slot)
    end

    return track_memory_go_to_f1(tr, slot, "")
end

function track_memory_handle_key(char)
    local slot = track_memory_key_to_slot(char)

    if ctrl_down() and not alt_down() and slot ~= nil then
        if not track_memory_is_context_allowed() then
            return false
        end

        if shift_down() then
            return track_memory_save_slot(slot)
        end

        return track_memory_recall_slot(slot)
    end

    if char == KEY_DELETE and
       track_memory_delete_armed_slot ~= nil and
       track_memory_is_context_allowed() then

        return track_memory_delete_slot(track_memory_delete_armed_slot)
    end

    return false
end

------------------------------------------------------------
-- 3.8 - GRID NAVIGATION
--
-- F1:
-- - sinistra/destra = parametro precedente/successivo
--   nella stessa traccia.
-- - su/giù = traccia precedente/successiva mantenendo
--   lo stesso parametro.
-- - Page Up/Page Down = salta fra tracce mantenendo
--   lo stesso parametro.
-- - Home = primo parametro della traccia corrente.
-- - End  = ultimo parametro della traccia corrente.
-- - Ctrl+Home = prima traccia mantenendo lo stesso parametro.
-- - Ctrl+End  = ultima traccia mantenendo lo stesso parametro.
--
-- F2 / F3:
-- - su/giù = parametro precedente/successivo nella colonna.
-- - sinistra/destra = send/receive precedente/successivo
--   mantenendo la stessa riga.
-- - Page Up/Page Down = dentro la colonna, senza uscire.
-- - Home = inizio colonna.
-- - End  = fine colonna.
-- - Ctrl+Home = prima colonna mantenendo la stessa riga.
-- - Ctrl+End  = ultima colonna mantenendo la stessa riga.
--
-- F4:
-- - lista verticale.
-- - su/giù = elemento precedente/successivo.
-- - Home = intestazione FX precedente.
-- - End = intestazione FX successiva.
-- - Page Up = primo parametro dell'FX corrente.
-- - Page Down = ultimo parametro dell'FX corrente.
--
-- Tutti i bordi sono silenziosi.
------------------------------------------------------------

function grid_count()
    return #grid_entries
end

function grid_column_bounds(pos)
    local count = grid_count()

    if count <= 0 then
        return 1, 1
    end

    local safe_grid = grid_safe_size()

    pos = clamp_int(pos, 1, count)

    local col_start =
        math.floor((pos - 1) / safe_grid) * safe_grid + 1

    local col_end = col_start + safe_grid - 1

    if col_end > count then
        col_end = count
    end

    return col_start, col_end
end

function grid_column_row_index(pos)
    local safe_grid = grid_safe_size()

    pos = clamp_int(pos, 1, math.max(1, grid_count()))

    return ((pos - 1) % safe_grid) + 1
end

function grid_last_column_start()
    local count = grid_count()
    local safe_grid = grid_safe_size()

    if count <= 0 then
        return 1
    end

    return math.floor((count - 1) / safe_grid) * safe_grid + 1
end

function grid_edge(token)
    edge_was_already_silent(token)
    return false
end

function grid_move_to_pos(new_pos, speak_it, move_kind)
    local count = grid_count()

    if count <= 0 then
        return grid_edge("empty:" .. tostring(current_section_id))
    end

    new_pos = clamp_int(new_pos, 1, count)

    local old_pos = grid_pos

    if new_pos == grid_pos then
        return grid_edge(
            "same:" ..
            tostring(current_section_id) ..
            ":" ..
            tostring(new_pos)
        )
    end

    last_grid_move_old_pos = old_pos
    last_grid_move_new_pos = new_pos
    last_grid_move_kind = clean_one_line(move_kind or "")

    grid_pos = new_pos
    reset_edge_after_move()

    if current_section_id == SECTION_TRACKS then
        local e = get_current_entry()

        if e and e.track then
            set_current_track_pointer_only(e.track)
        end
    end

    if speak_it ~= false then
        speak_current_entry(nil, move_kind)
    end

    cursor_memory_save_current()

    return true
end

------------------------------------------------------------
-- 3.8.1 - NAVIGAZIONE F1: RIGHE = TRACCE VISIBILI
------------------------------------------------------------

function grid_tracks_move_param(direction)
    direction = tonumber(direction) or 0

    if direction == 0 then
        return false
    end

    local count = grid_count()

    if count <= 0 then
        return grid_edge("tracks-empty")
    end

    local row_start, row_end = grid_current_row_bounds()
    local new_pos = grid_pos + direction

    if new_pos < row_start then
        return grid_edge("tracks-param-left:" .. tostring(row_start))
    end

    if new_pos > row_end then
        return grid_edge("tracks-param-right:" .. tostring(row_end))
    end

    return grid_move_to_pos(new_pos, true, "param")
end

function grid_tracks_move_track(direction)
    direction = tonumber(direction) or 0

    if direction == 0 then
        return false
    end

    local count = grid_count()

    if count <= 0 then
        return grid_edge("tracks-empty")
    end

    local row, col = grid_current_row_col()
    local new_row = row + direction
    local row_count = grid_row_count()

    if new_row < 1 then
        return grid_edge("tracks-top:" .. tostring(col))
    end

    if new_row > row_count then
        return grid_edge("tracks-bottom:" .. tostring(col))
    end

    local new_pos = grid_pos_from_row_col(new_row, col)

    return grid_move_to_pos(new_pos, true, "track")
end

function grid_tracks_move_page(direction)
    direction = tonumber(direction) or 0

    if direction == 0 then
        return false
    end

    local count = grid_count()

    if count <= 0 then
        return grid_edge("tracks-empty")
    end

    local row, col = grid_current_row_col()
    local amount = get_page_nav_amount()
    local row_count = grid_row_count()
    local new_row = row + (amount * direction)

    new_row = clamp_int(new_row, 1, row_count)

    if new_row == row then
        if direction < 0 then
            return grid_edge("tracks-page-top:" .. tostring(col))
        end

        return grid_edge("tracks-page-bottom:" .. tostring(col))
    end

    local new_pos = grid_pos_from_row_col(new_row, col)

    return grid_move_to_pos(new_pos, true, "track")
end

function grid_tracks_row_home()
    local count = grid_count()

    if count <= 0 then
        return grid_edge("tracks-empty")
    end

    local row_start = grid_current_row_bounds()

    return grid_move_to_pos(row_start, true, "param")
end

function grid_tracks_row_end()
    local count = grid_count()

    if count <= 0 then
        return grid_edge("tracks-empty")
    end

    local _, row_end = grid_current_row_bounds()

    return grid_move_to_pos(row_end, true, "param")
end

function grid_tracks_first_track()
    local count = grid_count()

    if count <= 0 then
        return grid_edge("tracks-empty")
    end

    local row, col = grid_current_row_col()

    if row <= 1 then
        return grid_edge("tracks-first:" .. tostring(col))
    end

    local new_pos = grid_pos_from_row_col(1, col)

    return grid_move_to_pos(new_pos, true, "track")
end

function grid_tracks_last_track()
    local count = grid_count()

    if count <= 0 then
        return grid_edge("tracks-empty")
    end

    local row, col = grid_current_row_col()
    local row_count = grid_row_count()

    if row >= row_count then
        return grid_edge("tracks-last:" .. tostring(col))
    end

    local new_pos = grid_pos_from_row_col(row_count, col)

    return grid_move_to_pos(new_pos, true, "track")
end

------------------------------------------------------------
-- 3.8.2 - NAVIGAZIONE F2 / F3: COLONNE = BLOCCHI
------------------------------------------------------------

function grid_detail_move_vertical(direction)
    direction = tonumber(direction) or 0

    if direction == 0 then
        return false
    end

    local count = grid_count()

    if count <= 0 then
        return grid_edge("detail-empty")
    end

    local col_start, col_end = grid_column_bounds(grid_pos)
    local new_pos = grid_pos + direction

    if new_pos < col_start then
        return grid_edge("detail-column-top:" .. tostring(col_start))
    end

    if new_pos > col_end then
        return grid_edge("detail-column-bottom:" .. tostring(col_end))
    end

    return grid_move_to_pos(new_pos, true, "vertical")
end

function grid_detail_move_horizontal(direction)
    direction = tonumber(direction) or 0

    if direction == 0 then
        return false
    end

    local count = grid_count()

    if count <= 0 then
        return grid_edge("detail-empty")
    end

    local safe_grid = grid_safe_size()
    local row = (grid_pos - 1) % safe_grid
    local col_start =
        math.floor((grid_pos - 1) / safe_grid) * safe_grid + 1

    local new_col_start = col_start + (safe_grid * direction)

    if new_col_start < 1 then
        return grid_edge("detail-left:" .. tostring(row + 1))
    end

    if new_col_start > count then
        return grid_edge("detail-right:" .. tostring(row + 1))
    end

    local new_pos = new_col_start + row

    if new_pos > count then
        new_pos = count
    end

    return grid_move_to_pos(new_pos, true, "horizontal")
end

function grid_detail_move_page(direction)
    direction = tonumber(direction) or 0

    if direction == 0 then
        return false
    end

    local count = grid_count()

    if count <= 0 then
        return grid_edge("detail-empty")
    end

    local col_start, col_end = grid_column_bounds(grid_pos)
    local amount = get_page_nav_amount()
    local new_pos = grid_pos + (amount * direction)

    new_pos = clamp_int(new_pos, col_start, col_end)

    if new_pos == grid_pos then
        if direction < 0 then
            return grid_edge("detail-page-top:" .. tostring(col_start))
        end

        return grid_edge("detail-page-bottom:" .. tostring(col_end))
    end

    return grid_move_to_pos(new_pos, true, "vertical")
end

function grid_detail_column_home()
    local count = grid_count()

    if count <= 0 then
        return grid_edge("detail-empty")
    end

    local col_start = grid_column_bounds(grid_pos)

    return grid_move_to_pos(col_start, true, "vertical")
end

function grid_detail_column_end()
    local count = grid_count()

    if count <= 0 then
        return grid_edge("detail-empty")
    end

    local _, col_end = grid_column_bounds(grid_pos)

    return grid_move_to_pos(col_end, true, "vertical")
end

function grid_detail_first_column_same_row()
    local count = grid_count()

    if count <= 0 then
        return grid_edge("detail-empty")
    end

    local safe_grid = grid_safe_size()
    local row = (grid_pos - 1) % safe_grid
    local new_pos = 1 + row

    if new_pos > count then
        new_pos = count
    end

    return grid_move_to_pos(new_pos, true, "horizontal")
end

function grid_detail_last_column_same_row()
    local count = grid_count()

    if count <= 0 then
        return grid_edge("detail-empty")
    end

    local safe_grid = grid_safe_size()
    local row = (grid_pos - 1) % safe_grid
    local last_start = grid_last_column_start()
    local new_pos = last_start + row

    if new_pos > count then
        new_pos = count
    end

    return grid_move_to_pos(new_pos, true, "horizontal")
end

function grid_switch_visible_track_with_content(direction)
    direction = tonumber(direction) or 0

    if direction == 0 then
        return false
    end

    if current_section_id ~= SECTION_SENDS and
       current_section_id ~= SECTION_RECEIVES and
       current_section_id ~= SECTION_FX_PARAMS then
        return false
    end

    if not current_track then
        speak("No track")
        return true
    end

    local current_guid = get_track_guid(current_track)
    local visible_tracks = build_folder_aware_visible_track_list()
    local current_visible_index = 0

    for i = 1, #visible_tracks do
        local item = visible_tracks[i]

        if item and item.track and
           get_track_guid(item.track) == current_guid then
            current_visible_index = i
            break
        end
    end

    if current_visible_index <= 0 then
        local index = get_track_index(current_track)

        for i = 1, #visible_tracks do
            local item = visible_tracks[i]

            if item and tonumber(item.index) == index then
                current_visible_index = i
                break
            end
        end
    end

    if current_visible_index <= 0 then
        speak("Track not visible")
        return true
    end

    local old_track = current_track
    local old_track_guid = current_track_guid
    local old_track_index = track_index
    local old_grid_pos = grid_pos
    local old_grid_entries = grid_entries
    local old_grid_size = grid_size

    local old_safe_grid = grid_safe_size()
    local old_field = ((grid_pos - 1) % old_safe_grid) + 1
    local old_block_index = math.floor((grid_pos - 1) / old_safe_grid)

    local target_visible_index = current_visible_index
    local found = false

    while true do
        target_visible_index = target_visible_index + direction

        if target_visible_index < 1 or target_visible_index > #visible_tracks then
            current_track = old_track
            current_track_guid = old_track_guid
            track_index = old_track_index
            grid_pos = old_grid_pos
            grid_entries = old_grid_entries
            grid_size = old_grid_size

            refresh_window_title()

            local edge_name = "track-with-content"

            if current_section_id == SECTION_SENDS then
                edge_name = "track-with-send"
            elseif current_section_id == SECTION_RECEIVES then
                edge_name = "track-with-receive"
            elseif current_section_id == SECTION_FX_PARAMS then
                edge_name = "track-with-fx"
            end

            if direction < 0 then
                return grid_edge(edge_name .. "-top")
            end

            return grid_edge(edge_name .. "-bottom")
        end

        local item = visible_tracks[target_visible_index]
        local target_track = item and item.track or nil

        if target_track then
            set_current_track_pointer_only(target_track)
            grid_pos = 1

            local ok = build_current_grid()

            if ok and #grid_entries > 0 then
                found = true
                break
            end
        end
    end

    if not found then
        current_track = old_track
        current_track_guid = old_track_guid
        track_index = old_track_index
        grid_pos = old_grid_pos
        grid_entries = old_grid_entries
        grid_size = old_grid_size

        refresh_window_title()
        speak("No track")
        return true
    end

    if current_section_id == SECTION_SENDS or
       current_section_id == SECTION_RECEIVES then
        local wanted_pos = (old_block_index * grid_safe_size()) + old_field

        if wanted_pos > #grid_entries then
            wanted_pos = old_field
        end

        grid_pos = clamp_int(wanted_pos, 1, math.max(1, #grid_entries))
    elseif current_section_id == SECTION_FX_PARAMS then
        grid_pos = clamp_int(old_grid_pos, 1, math.max(1, #grid_entries))
    end

    refresh_window_title()

    speak_current_entry(
        get_current_track_context_label() ..
        ". " ..
        get_section_name(),
        "track"
    )

    cursor_memory_save_current()

    return true
end

function grid_detail_switch_visible_track(direction)
    return grid_switch_visible_track_with_content(direction)
end

------------------------------------------------------------
-- 3.8.3 - NAVIGAZIONE F4: LISTA VERTICALE FX
------------------------------------------------------------

function grid_fx_move_vertical(direction)
    direction = tonumber(direction) or 0

    if direction == 0 then
        return false
    end

    local count = grid_count()

    if count <= 0 then
        return grid_edge("fx-empty")
    end

    local col, row = f4_grid_current_col_row()
    local column = f4_grid_columns[col]

    if type(column) ~= "table" or #column <= 0 then
        return grid_edge("fx-empty")
    end

    local new_row = row + direction

    if new_row < 1 then
        return grid_edge("fx-top")
    end

    if new_row > #column then
        return grid_edge("fx-bottom")
    end

    return grid_move_to_pos(column[new_row], true, "vertical")
end

function grid_fx_move_horizontal(direction)
    direction = tonumber(direction) or 0

    if direction == 0 then
        return false
    end

    local count = grid_count()

    if count <= 0 then
        return grid_edge("fx-empty")
    end

    local col, row = f4_grid_current_col_row()
    local target_col = col + direction
    local col_count = f4_grid_column_count()

    if target_col < 1 then
        return grid_edge("fx-left")
    end

    if target_col > col_count then
        return grid_edge("fx-right")
    end

    local target_pos = f4_grid_pos_for_col_row(target_col, row)

    if target_pos <= 0 then
        return grid_edge("fx-empty")
    end

    return grid_move_to_pos(target_pos, true, "horizontal")
end

function grid_fx_move_page(direction)
    direction = tonumber(direction) or 0

    if direction == 0 then
        return false
    end

    local count = grid_count()

    if count <= 0 then
        return grid_edge("fx-empty")
    end

    local col, row = f4_grid_current_col_row()
    local column = f4_grid_columns[col]

    if type(column) ~= "table" or #column <= 0 then
        return grid_edge("fx-empty")
    end

    --------------------------------------------------------
    -- F4 segue la stessa logica di F1/F2/F3:
    -- Page Up / Page Down non hanno più un salto fisso, ma
    -- usano la quantità derivata dallo step scale corrente.
    --------------------------------------------------------
    local amount = get_page_nav_amount()
    local new_row = row + (amount * direction)

    new_row = clamp_int(new_row, 1, #column)

    if new_row == row then
        if direction < 0 then
            return grid_edge("fx-page-top:" .. tostring(col))
        end

        return grid_edge("fx-page-bottom:" .. tostring(col))
    end

    return grid_move_to_pos(column[new_row], true, "vertical")
end

function grid_fx_home()
    local count = grid_count()

    if count <= 0 then
        return grid_edge("fx-empty")
    end

    local col = f4_grid_current_col_row()
    local column = f4_grid_columns[col]

    if type(column) ~= "table" or #column <= 0 then
        return grid_edge("fx-empty")
    end

    return grid_move_to_pos(column[1], true, "vertical")
end

function grid_fx_end()
    local count = grid_count()

    if count <= 0 then
        return grid_edge("fx-empty")
    end

    local col = f4_grid_current_col_row()
    local column = f4_grid_columns[col]

    if type(column) ~= "table" or #column <= 0 then
        return grid_edge("fx-empty")
    end

    return grid_move_to_pos(column[#column], true, "vertical")
end

function grid_fx_first()
    local count = grid_count()

    if count <= 0 then
        return grid_edge("fx-empty")
    end

    local column = f4_grid_columns[1]

    if type(column) ~= "table" or #column <= 0 then
        return grid_edge("fx-empty")
    end

    return grid_move_to_pos(column[1], true, "vertical")
end

function grid_fx_last()
    local count = grid_count()

    if count <= 0 then
        return grid_edge("fx-empty")
    end

    local last_col = f4_grid_column_count()
    local column = f4_grid_columns[last_col]

    if type(column) ~= "table" or #column <= 0 then
        return grid_edge("fx-empty")
    end

    return grid_move_to_pos(column[#column], true, "vertical")
end

------------------------------------------------------------
-- 3.8.4 - DISPATCH NAVIGAZIONE GENERICA
------------------------------------------------------------

function grid_move_vertical(direction)
    if current_section_id == SECTION_TRACKS then
        return grid_tracks_move_track(direction)
    end

    if current_section_id == SECTION_FX_PARAMS then
        return grid_fx_move_vertical(direction)
    end

    return grid_detail_move_vertical(direction)
end

function grid_move_horizontal(direction)
    if current_section_id == SECTION_TRACKS then
        return grid_tracks_move_param(direction)
    end

    if current_section_id == SECTION_FX_PARAMS then
        return grid_fx_move_horizontal(direction)
    end

    return grid_detail_move_horizontal(direction)
end

function grid_move_page(direction)
    if current_section_id == SECTION_TRACKS then
        return grid_tracks_move_page(direction)
    end

    if current_section_id == SECTION_FX_PARAMS then
        return grid_fx_move_page(direction)
    end

    return grid_detail_move_page(direction)
end

function grid_home()
    if current_section_id == SECTION_TRACKS then
        return grid_tracks_row_home()
    end

    if current_section_id == SECTION_FX_PARAMS then
        return grid_fx_home()
    end

    return grid_detail_column_home()
end

function grid_end()
    if current_section_id == SECTION_TRACKS then
        return grid_tracks_row_end()
    end

    if current_section_id == SECTION_FX_PARAMS then
        return grid_fx_end()
    end

    return grid_detail_column_end()
end

function grid_ctrl_home()
    if current_section_id == SECTION_TRACKS then
        return grid_tracks_first_track()
    end

    if current_section_id == SECTION_FX_PARAMS then
        return grid_fx_first()
    end

    return grid_detail_first_column_same_row()
end

function grid_ctrl_end()
    if current_section_id == SECTION_TRACKS then
        return grid_tracks_last_track()
    end

    if current_section_id == SECTION_FX_PARAMS then
        return grid_fx_last()
    end

    return grid_detail_last_column_same_row()
end

------------------------------------------------------------
-- Compatibilità con nomi vecchi.
------------------------------------------------------------

function grid_column_home()
    return grid_home()
end

function grid_column_end()
    return grid_end()
end

function grid_first()
    return grid_ctrl_home()
end

function grid_last()
    return grid_ctrl_end()
end

------------------------------------------------------------
-- 3.9 - LETTER JUMP
--
-- F1:
-- - cerca nella riga corrente, quindi fra i parametri della
--   traccia corrente.
--
-- F2 / F3:
-- - cerca nella colonna corrente.
--
-- F4:
-- - cerca in tutta la lista verticale.
------------------------------------------------------------

function grid_jump_by_initial_in_tracks_row(letter)
    letter = clean_one_line(letter or ""):lower()

    if letter == "" then
        return false
    end

    if current_section_id ~= SECTION_TRACKS then
        return false
    end

    local count = grid_count()

    if count <= 0 then
        return false
    end

    local current_row, current_col = grid_current_row_col()
    local rows = grid_row_count()

    if rows <= 0 then
        return false
    end

    --------------------------------------------------------
    -- F1:
    -- la lettera non cerca più tra Volume, Pan, Mute, ecc.
    -- Cerca invece tra i nomi delle tracce.
    --
    -- Mantiene la stessa colonna parametro.
    -- Esempio:
    -- se sei su Pan della traccia corrente e premi B,
    -- va su Pan della prossima traccia che inizia con B.
    --------------------------------------------------------

    local start_row = current_row + 1

    if start_row > rows then
        start_row = 1
    end

    for n = 0, rows - 1 do
        local row = start_row + n

        if row > rows then
            row = row - rows
        end

        local pos = grid_pos_from_row_col(row, current_col)
        local e = grid_entries[pos]

        if e and e.track then
            local track_name = get_track_plain_short_label(e.track)
            local search_name = clean_one_line(track_name):lower()

            if search_name ~= "" and search_name:sub(1, 1) == letter then
                return grid_move_to_pos(pos, true, "track")
            end
        end
    end

    return true
end

function grid_jump_by_initial_in_fx_list(letter)
    letter = clean_one_line(letter or ""):lower()

    if letter == "" then
        return false
    end

    local count = grid_count()

    if count <= 0 then
        return false
    end

    local start_pos = grid_pos + 1

    if start_pos > count then
        start_pos = 1
    end

    for n = 0, count - 1 do
        local pos = start_pos + n

        if pos > count then
            pos = pos - count
        end

        local e = grid_entries[pos]
        local label = make_entry_label(e):lower()

        if label ~= "" and label:sub(1, 1) == letter then
            return grid_move_to_pos(pos, true, "vertical")
        end
    end
  
    return true
end

function grid_jump_by_initial_in_current_column(letter)
    letter = clean_one_line(letter or ""):lower()

    if letter == "" then
        return false
    end

    if current_section_id == SECTION_TRACKS then
        return grid_jump_by_initial_in_tracks_row(letter)
    end

    if current_section_id == SECTION_FX_PARAMS then
        return grid_jump_by_initial_in_fx_list(letter)
    end

    local count = grid_count()

    if count <= 0 then
        return false
    end

    local col_start, col_end = grid_column_bounds(grid_pos)

    if col_end < col_start then
        return false
    end

    local start_pos = grid_pos + 1

    if start_pos > col_end or start_pos < col_start then
        start_pos = col_start
    end

    local span = col_end - col_start + 1

    for n = 0, span - 1 do
        local pos = start_pos + n

        if pos > col_end then
            pos = col_start + (pos - col_end - 1)
        end

        local e = grid_entries[pos]
        local label = make_entry_label(e):lower()

        if label ~= "" and label:sub(1, 1) == letter then
            return grid_move_to_pos(pos, true, "vertical")
        end
    end

    return true
end

function grid_cycle_by_initial(letter)
    return grid_jump_by_initial_in_current_column(letter)
end

------------------------------------------------------------
-- FINE PARTE 3 / 5
------------------------------------------------------------

------------------------------------------------------------
-- PARTE 4 / 5
-- VALUE CONTROL, ENTER, READ, INIT, VALUE MODE,
-- EDIT NUMERICO, FILTRO CTRL+F, VERSIONE, TRACK EDIT,
-- LISTA PARAMETRI FX, HANDLER TASTI GRIGLIA
------------------------------------------------------------

------------------------------------------------------------
-- 4.0 - STATO LISTA PARAMETRI FX
------------------------------------------------------------

fx_param_list_return_section_key = KEY_F4
fx_param_list_return_section_id = SECTION_FX_PARAMS
fx_param_list_return_grid_pos = 1

fx_param_list_fx_index = -1
fx_param_list_fx_name = ""

fx_param_list_filter_active = false
fx_param_list_filter_query = ""

------------------------------------------------------------
-- Vista interna della lista parametri FX.
--
-- "all":
--   lista completa dei parametri del plugin corrente.
--
-- "visible_group":
--   lista mista di tutti i parametri resi visibili in F4,
--   raccolti da tutti gli FX della traccia corrente.
------------------------------------------------------------

fx_param_list_view_mode = "all"

------------------------------------------------------------
-- 4.1 - SPEECH OVERRIDE F1 / F2 / F3 / F4
------------------------------------------------------------

function get_entry_spoken_label_for_move(entry, move_kind)
    if not entry then
        return "No entry"
    end

    if mode == "fx_param_list" or
       current_section_id == FX_PARAM_LIST_SECTION_ID then
        return fx_param_list_entry_spoken_label(entry)
    end

    if current_section_id == SECTION_TRACKS then
        local base = get_entry_spoken_label(entry)

        ----------------------------------------------------
        -- In F1:
        -- - movimento verticale tra tracce: dice Selected.
        -- - movimento orizzontale tra parametri: non dice
        --   Selected, così il parlato resta pulito mentre si
        --   modificano Volume, Pan, Width, ecc.
        ----------------------------------------------------

        if move_kind == "track" then
            local selected_prefix = current_track_selection_prefix(entry)
            local tr = entry.track or current_track
            local track_label = get_track_folder_spoken_label(tr)

            return selected_prefix ..
                   join_track_context_and_entry_label(track_label, base)
        end

        return base
    end

    if entry_is_send_receive(entry) then
        local hide_peer =
            send_receive_hide_repeated_peer_for_move(entry, move_kind)

        local context = send_receive_context_label(entry, hide_peer)

        if entry.kind == "send_header" then
            local routing = send_receive_routing_short_label(entry)

            if context ~= "" and routing ~= "" then
                return context .. ". " .. routing
            end

            if context ~= "" then
                return context
            end

            return get_entry_spoken_label(entry)
        end

        ----------------------------------------------------
        -- F2 / F3:
        -- con freccia sinistra / destra sui parametri deve
        -- sempre dire Send N / Receive N.
        -- Se la traccia collegata è uguale alla colonna
        -- precedente, non ripete il nome della traccia.
        ----------------------------------------------------

        if move_kind == "horizontal" and context ~= "" then
            return context .. ". " .. get_entry_spoken_label(entry)
        end

        return get_entry_spoken_label(entry)
    end

    if current_section_id == SECTION_FX_PARAMS and
       entry.kind == "fx_header" then

        return fx_status_label_for_entry(entry) .. make_entry_label(entry)
    end

    if current_section_id == SECTION_FX_PARAMS and
       entry.fx_index ~= nil then

        return fx_status_label_for_entry(entry) .. get_entry_spoken_label(entry)
    end

    return get_entry_spoken_label(entry)
end

function current_entry_contextual_label()
    local e = get_current_entry()

    if not e then
        return "Empty"
    end

    if mode == "fx_param_list" or
       current_section_id == FX_PARAM_LIST_SECTION_ID then
        return fx_param_list_entry_spoken_label(e)
    end

    if entry_is_send_receive(e) then
        if e.kind == "send_header" then
            local context = send_receive_context_label(e)

            if context ~= "" then
                return context
            end
        end

        return get_entry_spoken_label(e)
    end

if current_section_id == SECTION_FX_PARAMS and
   e.kind == "fx_header" then
    return fx_status_label_for_entry(e) .. make_entry_label(e)
end

if current_section_id == SECTION_FX_PARAMS and
   e.fx_index ~= nil then

    return fx_status_label_for_entry(e) .. get_entry_spoken_label(e)
end

if current_section_id == SECTION_TRACKS and e.track then
        return
            entry_track_selected_prefix(e) ..
            join_track_context_and_entry_label(
                get_track_folder_spoken_label(e.track),
                get_entry_spoken_label(e)
            )
    end

    return get_entry_spoken_label(e)
end

function current_entry_clean_value_label()
    local e = get_current_entry()

    if not e then
        return "Empty"
    end

    if current_section_id == SECTION_TRACKS then
        return get_entry_spoken_label(e)
    end

    return current_entry_contextual_label()
end

function speak_grid_position()
    local entry = get_current_entry()

    if not entry then
        speak(get_section_name() .. ". Empty")
        return
    end

    local entry_part = ""

    if mode == "fx_param_list" or
       current_section_id == FX_PARAM_LIST_SECTION_ID then

        entry_part = fx_param_list_entry_spoken_label(entry)

    elseif entry_is_send_receive(entry) then

        if entry.kind == "send_header" then
            local context = send_receive_context_label(entry)

            if context ~= "" then
                entry_part = context
            else
                entry_part = get_entry_spoken_label(entry)
            end
        else
            entry_part = get_entry_spoken_label(entry)
        end

elseif current_section_id == SECTION_FX_PARAMS and
       entry.kind == "fx_header" then

    entry_part = fx_status_label_for_entry(entry) .. make_entry_label(entry)

elseif current_section_id == SECTION_FX_PARAMS and
       entry.fx_index ~= nil then

    entry_part = fx_status_label_for_entry(entry) .. get_entry_spoken_label(entry)

elseif current_section_id == SECTION_TRACKS and entry.track then

        entry_part =
            entry_track_selected_prefix(entry) ..
            join_track_context_and_entry_label(
                get_track_folder_spoken_label(entry.track),
                get_entry_spoken_label(entry)
            )

    elseif current_track then

        entry_part =
            get_current_track_label() ..
            ". " ..
            get_entry_spoken_label(entry)

    else
        entry_part = get_entry_spoken_label(entry)
    end

    local filter_part = ""

    if filter_is_active() then
        filter_part = " Filter " .. filter_query .. "."
    elseif current_section_id == FX_PARAM_LIST_SECTION_ID and
           fx_param_list_filter_is_active() then
        filter_part = " Filter " .. fx_param_list_filter_query .. "."
    end

    local position_part = ""

    if current_section_id == SECTION_FX_PARAMS then
        position_part = f4_logical_position_text(entry)
    else
        local logical_pos, logical_count = logical_position_info()

        position_part =
            tostring(logical_pos) ..
            " of " ..
            tostring(logical_count) ..
            ". "
    end

    speak(
        selected_track_prefix() ..
        get_section_name() ..
        filter_part ..
        ". " ..
        position_part ..
        entry_part
    )
end

------------------------------------------------------------
-- 4.1.1 - CONTEGGIO RISULTATI FILTRO LOGICO
------------------------------------------------------------

function current_logical_result_count()
    if mode == "fx_param_list" or
       current_section_id == FX_PARAM_LIST_SECTION_ID then
        return #grid_entries
    end

    if current_section_id == SECTION_TRACKS then
        return grid_row_count()
    end

    if current_section_id == SECTION_SENDS or
       current_section_id == SECTION_RECEIVES then

        local safe_grid = grid_safe_size()

        if safe_grid <= 0 then
            return 0
        end

        return math.ceil(#grid_entries / safe_grid)
    end

    if current_section_id == SECTION_FX_PARAMS then
        local count = 0

        for i = 1, #grid_entries do
            local e = grid_entries[i]

            if e and e.kind == "fx_header" then
                count = count + 1
            end
        end

        return count
    end

    return #grid_entries
end

------------------------------------------------------------
-- 4.1.2 - POSIZIONE LOGICA F4
--
-- In F4 la griglia contiene:
-- - intestazioni FX;
-- - parametri visibili TCP sotto ogni FX.
--
-- Per Tab non vogliamo contare tutto come lista piatta.
-- Quindi:
-- - sull'intestazione: FX X of Y. N visible parameters.
-- - su un parametro: FX X of Y. Param P of N.
------------------------------------------------------------

function f4_fx_count_in_grid()
    local count = 0

    for i = 1, #grid_entries do
        local e = grid_entries[i]

        if e and e.kind == "fx_header" then
            count = count + 1
        end
    end

    return count
end

function f4_fx_order_in_grid(fx_index)
    fx_index = tonumber(fx_index) or -1

    if fx_index < 0 then
        return 0
    end

    local order = 0

    for i = 1, #grid_entries do
        local e = grid_entries[i]

        if e and e.kind == "fx_header" then
            order = order + 1

            if tonumber(e.fx_index) == fx_index then
                return order
            end
        end
    end

    return 0
end

function f4_visible_param_count_for_fx(fx_index)
    fx_index = tonumber(fx_index) or -1

    if fx_index < 0 then
        return 0
    end

    local count = 0

    for i = 1, #grid_entries do
        local e = grid_entries[i]

        if e and
           e.kind == "fx_param" and
           tonumber(e.fx_index) == fx_index then

            count = count + 1
        end
    end

    return count
end

function f4_param_order_for_entry(entry)
    if not entry or entry.kind ~= "fx_param" then
        return 0
    end

    local fx_index = tonumber(entry.fx_index) or -1
    local param_index = tonumber(entry.param_index) or -1

    if fx_index < 0 or param_index < 0 then
        return 0
    end

    local order = 0

    for i = 1, #grid_entries do
        local e = grid_entries[i]

        if e and
           e.kind == "fx_param" and
           tonumber(e.fx_index) == fx_index then

            order = order + 1

            if tonumber(e.param_index) == param_index then
                return order
            end
        end
    end

    return 0
end

function f4_logical_position_text(entry)
    entry = entry or get_current_entry()

    if not entry or entry.fx_index == nil then
        return ""
    end

    local fx_index = tonumber(entry.fx_index) or -1
    local fx_order = f4_fx_order_in_grid(fx_index)
    local fx_count = f4_fx_count_in_grid()
    local param_count = f4_visible_param_count_for_fx(fx_index)

    if fx_order <= 0 or fx_count <= 0 then
        return ""
    end

    if entry.kind == "fx_header" then
        if param_count == 1 then
            return
                "FX " ..
                tostring(fx_order) ..
                " of " ..
                tostring(fx_count) ..
                ". 1 visible parameter. "
        end

        return
            "FX " ..
            tostring(fx_order) ..
            " of " ..
            tostring(fx_count) ..
            ". " ..
            tostring(param_count) ..
            " visible parameters. "
    end

    if entry.kind == "fx_param" then
        local param_order = f4_param_order_for_entry(entry)

        if param_order <= 0 then
            return
                "FX " ..
                tostring(fx_order) ..
                " of " ..
                tostring(fx_count) ..
                ". "
        end

        return
            "FX " ..
            tostring(fx_order) ..
            " of " ..
            tostring(fx_count) ..
            ". Param " ..
            tostring(param_order) ..
            " of " ..
            tostring(param_count) ..
            ". "
    end

    return
        "FX " ..
        tostring(fx_order) ..
        " of " ..
        tostring(fx_count) ..
        ". "
end

------------------------------------------------------------
-- 4.2 - VALUE CONTROL GENERICO
------------------------------------------------------------

function current_entry_supports_value()
    local e = get_current_entry()

    if not e then
        return false
    end

    return type(e.get_norm) == "function" and
           type(e.set_norm) == "function"
end

function current_entry_get_norm()
    local e = get_current_entry()

    if not e or type(e.get_norm) ~= "function" then
        return nil
    end

    local ok, value = pcall(e.get_norm, e)

    if ok then
        return clamp01(value)
    end

    return nil
end

function current_entry_set_norm(norm)
    local e = get_current_entry()

    if not e or type(e.set_norm) ~= "function" then
        return false
    end

    norm = clamp01(norm)

    local ok, result = pcall(e.set_norm, e, norm)

    if ok then
        return result ~= false
    end

    return false
end

------------------------------------------------------------
-- 4.2.1 - CC FLUTTUANTE SOLO SESSIONE REAPER
--
-- Ctrl+Shift+C:
-- - se spento: arma il learn del prossimo CC.
-- - se armato: annulla.
-- - se attivo: spegne il CC fluttuante.
--
-- Stato:
-- - nessun TXT;
-- - nessun file;
-- - ExtState non persistente: resta solo fino alla chiusura
--   di REAPER.
--
-- Pickup:
-- - ogni volta che cambia parametro, il CC deve passare dal
--   valore corrente del parametro prima di modificarlo.
------------------------------------------------------------

FLOAT_CC_EXT_SECTION = "LoLo_SpeakTrackParams_Runtime"
FLOAT_CC_EXT_ACTIVE  = "floating_cc_active"
FLOAT_CC_EXT_CH      = "floating_cc_channel"
FLOAT_CC_EXT_CC      = "floating_cc_number"

floating_cc_enabled = false
floating_cc_learn_armed = false

floating_cc_channel = -1
floating_cc_number = -1

floating_cc_last_seq = 0
floating_cc_last_value = nil

floating_cc_target_key = ""
floating_cc_target_value = nil
floating_cc_picked_up = false

floating_cc_pickup_tolerance = 1.0 / 127.0

track_cc_value_speak_serial = track_cc_value_speak_serial or 0
TRACK_CC_VALUE_SPEAK_DELAY_SECONDS = 0.02 -- low-latency CC speech, keeps value-write path untouched

function track_cc_value_strip_positive_plus(msg)
    msg = clean_one_line(msg or "")

    --------------------------------------------------------
    -- Parlato CC essenziale:
    -- i valori positivi non hanno bisogno del segno +.
    -- I negativi restano invariati.
    --------------------------------------------------------
    msg = msg:gsub("^%+(%d)", "%1")
    msg = msg:gsub("(%s)%+(%d)", "%1%2")

    return clean_one_line(msg)
end

function track_cc_value_speak_send(msg)
    msg = track_cc_value_strip_positive_plus(msg or "")

    if msg == "" then
        return false
    end

    --------------------------------------------------------
    -- Parlato valori da CC:
    -- quando il controller manda molti valori consecutivi,
    -- ogni nuovo valore sostituisce quello precedente ancora
    -- in attesa. Così OSARA riceve solo l'ultimo valore utile
    -- e non una frase lunga accumulata.
    --------------------------------------------------------
    track_cc_value_speak_serial = track_cc_value_speak_serial + 1

    local my_serial = track_cc_value_speak_serial
    local start_time = reaper.time_precise and reaper.time_precise() or os.clock()

    local function later()
        if my_serial ~= track_cc_value_speak_serial then
            return
        end

        local now = reaper.time_precise and reaper.time_precise() or os.clock()

        if (now - start_time) >= TRACK_CC_VALUE_SPEAK_DELAY_SECONDS then
            if type(cancel_pending_speech) == "function" then
                cancel_pending_speech()
            end

            speak(msg)
        else
            reaper.defer(later)
        end
    end

    reaper.defer(later)

    return true
end

function floating_cc_save_session()
    if not reaper.SetExtState then
        return false
    end

    reaper.SetExtState(
        FLOAT_CC_EXT_SECTION,
        FLOAT_CC_EXT_ACTIVE,
        floating_cc_enabled and "1" or "0",
        false
    )

    reaper.SetExtState(
        FLOAT_CC_EXT_SECTION,
        FLOAT_CC_EXT_CH,
        tostring(floating_cc_channel or -1),
        false
    )

    reaper.SetExtState(
        FLOAT_CC_EXT_SECTION,
        FLOAT_CC_EXT_CC,
        tostring(floating_cc_number or -1),
        false
    )

    return true
end

function floating_cc_load_session()
    if not reaper.GetExtState then
        return false
    end

    local active = reaper.GetExtState(
        FLOAT_CC_EXT_SECTION,
        FLOAT_CC_EXT_ACTIVE
    )

    local ch = tonumber(
        reaper.GetExtState(
            FLOAT_CC_EXT_SECTION,
            FLOAT_CC_EXT_CH
        )
    ) or -1

    local cc = tonumber(
        reaper.GetExtState(
            FLOAT_CC_EXT_SECTION,
            FLOAT_CC_EXT_CC
        )
    ) or -1

    floating_cc_enabled = active == "1" and ch >= 1 and ch <= 16 and cc >= 0 and cc <= 127
    floating_cc_channel = ch
    floating_cc_number = cc

    floating_cc_learn_armed = false
    floating_cc_last_value = nil
    floating_cc_target_key = ""
    floating_cc_target_value = nil
    floating_cc_picked_up = false

    return floating_cc_enabled
end

function floating_cc_clear_session()
    floating_cc_enabled = false
    floating_cc_learn_armed = false

    floating_cc_channel = -1
    floating_cc_number = -1

    floating_cc_last_value = nil
    floating_cc_target_key = ""
    floating_cc_target_value = nil
    floating_cc_picked_up = false

    floating_cc_save_session()

    return true
end

function floating_cc_current_entry_key()
    local e = get_current_entry()

    if not e then
        return ""
    end

    if not current_entry_supports_value() then
        return ""
    end

    local track_guid = ""

    if e.track then
        track_guid = get_track_guid(e.track)
    elseif current_track then
        track_guid = get_track_guid(current_track)
    end

    return
        tostring(current_section_id or "") ..
        "|" .. tostring(mode or "") ..
        "|" .. tostring(e.kind or "") ..
        "|" .. tostring(e.id or "") ..
        "|" .. tostring(track_guid or "") ..
        "|" .. tostring(e.track_index or "") ..
        "|" .. tostring(e.category or "") ..
        "|" .. tostring(e.send_index or "") ..
        "|" .. tostring(e.real_send_index or "") ..
        "|" .. tostring(e.display_index or "") ..
        "|" .. tostring(e.fx_index or "") ..
        "|" .. tostring(e.param_index or "")
end

function floating_cc_reset_pickup_if_target_changed()
    local key = floating_cc_current_entry_key()

    if key == "" then
        floating_cc_target_key = ""
        floating_cc_target_value = nil
        floating_cc_picked_up = false
        return false
    end

    if key ~= floating_cc_target_key then
        floating_cc_target_key = key
        floating_cc_target_value = current_entry_get_norm()
        floating_cc_picked_up = false
    end

    return true
end

function floating_cc_value_crossed_target(last_value, new_value, target)
    if target == nil then
        return false
    end

    new_value = clamp01(new_value)

    if math.abs(new_value - target) <= floating_cc_pickup_tolerance then
        return true
    end

    if last_value == nil then
        return false
    end

    last_value = clamp01(last_value)

    if last_value <= target and new_value >= target then
        return true
    end

    if last_value >= target and new_value <= target then
        return true
    end

    return false
end

function floating_cc_parse_cc_from_buffer(buf)
    buf = tostring(buf or "")

    if #buf < 3 then
        return nil, nil, nil
    end

    local status = string.byte(buf, 1) or 0
    local data1  = string.byte(buf, 2) or 0
    local data2  = string.byte(buf, 3) or 0

    local message_type = status & 0xF0

    if message_type ~= 0xB0 then
        return nil, nil, nil
    end

    local channel = (status & 0x0F) + 1
    local cc_number = data1
    local cc_value = clamp01(data2 / 127.0)

    return channel, cc_number, cc_value
end

function floating_cc_read_recent_event()
    if not reaper.MIDI_GetRecentInputEvent then
        return 0, ""
    end

    local ok, seq, buf = pcall(reaper.MIDI_GetRecentInputEvent, 0)

    if not ok then
        return 0, ""
    end

    return tonumber(seq) or 0, tostring(buf or "")
end


------------------------------------------------------------
-- CC RAW STABILIZER
--
-- Stabilizza il valore MIDI grezzo prima di scrivere il
-- parametro. I 128 valori restano raggiungibili: un cambio
-- di un solo step viene accettato solo quando lo stesso valore
-- arriva due volte di seguito. Questo evita che un potenziometro
-- fermo faccia oscillare il parametro tra due valori adiacenti.
------------------------------------------------------------
track_cc_raw_stabilizer_state = track_cc_raw_stabilizer_state or {}

function track_cc_raw_stabilizer_accept(scope, channel, cc, norm_value)
    scope = clean_one_line(scope or "cc")
    channel = clamp_int(channel, 1, 16)
    cc = clamp_int(cc, 0, 127)

    local raw_value = clamp_int((clamp01(norm_value) * 127), 0, 127)
    local key = scope .. "::" .. tostring(channel) .. "::" .. tostring(cc)
    local st = track_cc_raw_stabilizer_state[key]

    if not st then
        track_cc_raw_stabilizer_state[key] = {
            accepted = raw_value,
            candidate = nil,
            candidate_count = 0
        }
        return true, raw_value / 127.0
    end

    local accepted = clamp_int(st.accepted, 0, 127)

    if raw_value == accepted then
        st.candidate = nil
        st.candidate_count = 0
        return false, accepted / 127.0
    end

    local diff = math.abs(raw_value - accepted)

    --------------------------------------------------------
    -- Anti-ballamento più fermo:
    -- - salti veri da 3 step o più passano subito;
    -- - 2 step devono confermarsi due volte;
    -- - 1 step deve confermarsi tre volte.
    -- Così un potenziometro fermo non scatta facilmente al
    -- valore MIDI vicino, ma il movimento intenzionale resta
    -- raggiungibile.
    --------------------------------------------------------
    if diff >= 3 then
        st.accepted = raw_value
        st.candidate = nil
        st.candidate_count = 0
        return true, raw_value / 127.0
    end

    if st.candidate == raw_value then
        st.candidate_count = (tonumber(st.candidate_count) or 0) + 1
    else
        st.candidate = raw_value
        st.candidate_count = 1
    end

    local needed = diff <= 1 and 3 or 2

    if st.candidate_count >= needed then
        st.accepted = raw_value
        st.candidate = nil
        st.candidate_count = 0
        return true, raw_value / 127.0
    end

    return false, accepted / 127.0
end

function floating_cc_arm_learn()
    cancel_pending_speech()
    clear_silent_edge()

    local seq = 0

    seq = select(1, floating_cc_read_recent_event())

    floating_cc_last_seq = seq
    floating_cc_learn_armed = true

    speak("Floating CC learn. Move a MIDI CC")

    return true
end

function floating_cc_cancel_learn()
    floating_cc_learn_armed = false
    speak("Floating CC learn cancelled")
    return true
end

function floating_cc_assign(channel, cc_number, cc_value)
    channel = tonumber(channel) or -1
    cc_number = tonumber(cc_number) or -1
    cc_value = clamp01(cc_value)

    if channel < 1 or channel > 16 or cc_number < 0 or cc_number > 127 then
        speak("Invalid CC")
        return true
    end

    floating_cc_channel = channel
    floating_cc_number = cc_number
    floating_cc_enabled = true
    floating_cc_learn_armed = false

    floating_cc_last_value = cc_value

    floating_cc_target_key = ""
    floating_cc_target_value = nil
    floating_cc_picked_up = false

    floating_cc_save_session()

    floating_cc_reset_pickup_if_target_changed()

    speak(
        "Floating CC on. Channel " ..
        tostring(channel) ..
        ". CC " ..
        tostring(cc_number)
    )

    return true
end

function floating_cc_toggle_or_arm()
    cancel_pending_speech()
    clear_silent_edge()

    if floating_cc_learn_armed then
        return floating_cc_cancel_learn()
    end

    if floating_cc_enabled then
        floating_cc_clear_session()
        speak("Floating CC off")
        return true
    end

    return floating_cc_arm_learn()
end

function floating_cc_apply_value(cc_value)
    cc_value = clamp01(cc_value)

    if not current_entry_supports_value() then
        floating_cc_last_value = cc_value
        return true
    end

    floating_cc_reset_pickup_if_target_changed()

    if floating_cc_target_key == "" then
        floating_cc_last_value = cc_value
        return true
    end

    if not floating_cc_picked_up then
        if floating_cc_value_crossed_target(
            floating_cc_last_value,
            cc_value,
            floating_cc_target_value
        ) then
            floating_cc_picked_up = true
        else
            floating_cc_last_value = cc_value
            return true
        end
    end

    floating_cc_last_value = cc_value

    if current_entry_set_norm(cc_value) then
        clear_silent_edge()

        ----------------------------------------------------
        -- Ctrl+Shift+M / titoli corti:
        -- in questa modalità il CC fluttuante deve continuare
        -- a muovere il parametro, ma senza parlare i valori.
        -- Quando i titoli dettagliati sono riattivati, il
        -- comportamento torna quello normale.
        ----------------------------------------------------
        if title_detail_is_enabled() then
            track_cc_value_speak_send(make_entry_value(get_current_entry()))
        else
            cancel_pending_speech()
        end

        return true
    end

    return true
end

function floating_cc_poll_recent_input()
    if not floating_cc_enabled and not floating_cc_learn_armed then
        return false
    end

    local seq, buf = floating_cc_read_recent_event()

    if seq == 0 then
        return false
    end

    if seq == floating_cc_last_seq then
        return false
    end

    floating_cc_last_seq = seq

    local channel, cc_number, cc_value = floating_cc_parse_cc_from_buffer(buf)

    if not channel then
        return false
    end

    if floating_cc_learn_armed then
        floating_cc_assign(channel, cc_number, cc_value)
        return true
    end

    if not floating_cc_enabled then
        return false
    end

    if channel ~= floating_cc_channel then
        return false
    end

    if cc_number ~= floating_cc_number then
        return false
    end

    local ok_stable, stable_value =
        track_cc_raw_stabilizer_accept(
            "floating",
            channel,
            cc_number,
            cc_value
        )

    if not ok_stable then
        return false
    end

    return floating_cc_apply_value(stable_value)
end



------------------------------------------------------------
-- 4.2.2 - FIXED CC MAP PER PARAMETRI TRACCIA
--
-- Ctrl+Alt+C sul parametro supportato:
--   arma il learn del prossimo CC e lo salva nel TXT Tracks.
--
-- Shift+C:
--   attiva/disattiva la mappa fissa. Di default è Off.
--
-- Runtime:
--   il CC salvato muove le tracce selezionate in REAPER.
--   Se nessuna traccia è selezionata, usa la traccia corrente
--   del navigatore come fallback.
--
-- Pickup:
--   Volume, Pan e Width usano soft takeover come FX Params.
--   Mute, Solo e Phase invert sono booleani: >= 64 On, < 64 Off.
------------------------------------------------------------

track_fixed_cc_map_enabled = false
track_fixed_cc_learn_armed = false
track_fixed_cc_learn_target_id = ""
track_fixed_cc_learn_target_label = ""
track_fixed_cc_last_seq = 0
track_fixed_cc_last_value_by_id = {}
track_fixed_cc_pickup = {}
track_fixed_cc_pickup_target = {}
track_fixed_cc_selected_signature = ""
track_fixed_cc_pickup_tolerance = 1.0 / 127.0

TRACK_FIXED_CC_EXT_SECTION = "LoLo_SpeakTrackParams_Runtime"
TRACK_FIXED_CC_EXT_ENABLED = "fixed_cc_map_enabled"

function track_fixed_cc_track_is_valid(track)
    if not track then
        return false
    end

    if reaper.ValidatePtr2 then
        local ok, valid = pcall(reaper.ValidatePtr2, 0, track, "MediaTrack*")

        if ok then
            return valid == true
        end
    end

    if type(current_track_exists_anywhere) == "function" then
        local ok, valid = pcall(current_track_exists_anywhere, track)

        if ok then
            return valid == true
        end
    end

    return false
end

function track_fixed_cc_save_enabled_session()
    if not reaper.SetExtState then
        return false
    end

    reaper.SetExtState(
        TRACK_FIXED_CC_EXT_SECTION,
        TRACK_FIXED_CC_EXT_ENABLED,
        track_fixed_cc_map_enabled and "1" or "0",
        false
    )

    return true
end

function track_fixed_cc_load_enabled_session()
    if not reaper.GetExtState then
        return false
    end

    local enabled_txt = clean_one_line(
        reaper.GetExtState(TRACK_FIXED_CC_EXT_SECTION, TRACK_FIXED_CC_EXT_ENABLED)
    )

    if enabled_txt ~= "1" then
        track_fixed_cc_map_enabled = false
        track_fixed_cc_clear_pickup()
        return true
    end

    if not track_fixed_cc_storage_available() then
        track_txt_load()
    end

    if track_fixed_cc_storage_available() and track_fixed_cc_count_links() > 0 then
        track_fixed_cc_map_enabled = true
        track_fixed_cc_clear_pickup()
        track_fixed_cc_last_seq = select(1, floating_cc_read_recent_event()) or 0
    else
        track_fixed_cc_map_enabled = false
        track_fixed_cc_clear_pickup()
    end

    return true
end

function track_fixed_cc_supported_entry_id_from_entry(e)
    if not e then
        return ""
    end

    if e.kind ~= "track_param" then
        return ""
    end

    local id = clean_one_line(e.id or "")

    if TRACK_FIXED_CC_IDS[id] then
        return id
    end

    return ""
end

function track_fixed_cc_current_entry_id()
    return track_fixed_cc_supported_entry_id_from_entry(get_current_entry())
end

function track_fixed_cc_label(id)
    return TRACK_FIXED_CC_LABELS[id] or clean_one_line(id or "")
end

function track_fixed_cc_spoken_part_for_entry(entry)
    if track_fixed_cc_map_enabled ~= true then
        return ""
    end

    local id = track_fixed_cc_supported_entry_id_from_entry(entry)

    if id == "" then
        return ""
    end

    local channel, cc = track_fixed_cc_get_link(id)

    if channel == nil or cc == nil then
        return ""
    end

    return
        ". CC channel " ..
        tostring(channel) ..
        " CC " ..
        tostring(cc)
end

function track_fixed_cc_get_target_tracks()
    local tracks = {}
    local seen = {}

    if reaper.CountSelectedTracks and reaper.GetSelectedTrack then
        local count = reaper.CountSelectedTracks(0) or 0

        for i = 0, count - 1 do
            local tr = reaper.GetSelectedTrack(0, i)

            if track_fixed_cc_track_is_valid(tr) then
                local guid = get_track_guid(tr)

                if guid == "" then
                    guid = tostring(tr)
                end

                if not seen[guid] then
                    seen[guid] = true
                    tracks[#tracks + 1] = tr
                end
            end
        end
    end

    if #tracks <= 0 then
        local e = get_current_entry()
        local tr = nil

        if e and e.track then
            tr = e.track
        elseif current_track then
            tr = current_track
        end

        if track_fixed_cc_track_is_valid(tr) then
            tracks[#tracks + 1] = tr
        end
    end

    return tracks
end

function track_fixed_cc_make_selected_signature(tracks)
    tracks = tracks or track_fixed_cc_get_target_tracks()

    local guids = {}

    for i = 1, #tracks do
        if track_fixed_cc_track_is_valid(tracks[i]) then
            local guid = get_track_guid(tracks[i])

            if guid == "" then
                guid = tostring(tracks[i])
            end

            guids[#guids + 1] = guid
        end
    end

    table.sort(guids)

    return table.concat(guids, "|")
end

function track_fixed_cc_clear_pickup()
    track_fixed_cc_pickup = {}
    track_fixed_cc_pickup_target = {}
    track_fixed_cc_last_value_by_id = {}
end

function track_fixed_cc_reset_pickup_if_selection_changed(tracks)
    local sig = track_fixed_cc_make_selected_signature(tracks)

    if sig ~= track_fixed_cc_selected_signature then
        track_fixed_cc_selected_signature = sig
        track_fixed_cc_clear_pickup()
    end

    return true
end

function track_fixed_cc_get_norm_for_track(id, track)
    if not track_fixed_cc_track_is_valid(track) then
        return nil
    end

    if id == "volume" then
        return track_get_volume_norm(track)
    elseif id == "pan" then
        return track_get_pan_norm(track)
    elseif id == "width" then
        return track_get_width_norm(track)
    elseif id == "mute" then
        return track_get_bool(track, "B_MUTE") and 1 or 0
    elseif id == "solo" then
        return track_get_solo_bool(track) and 1 or 0
    elseif id == "phase" then
        return track_get_bool(track, "B_PHASE") and 1 or 0
    end

    return nil
end

function track_fixed_cc_set_norm_for_track(id, track, norm)
    if not track_fixed_cc_track_is_valid(track) then
        return false
    end

    norm = clamp01(norm)

    if id == "volume" then
        return track_set_volume_norm(track, norm)
    elseif id == "pan" then
        return track_set_pan_norm(track, norm)
    elseif id == "width" then
        return track_set_width_norm(track, norm)
    elseif id == "mute" then
        return track_set_bool(track, "B_MUTE", norm >= 0.5)
    elseif id == "solo" then
        return track_set_solo_bool(track, norm >= 0.5)
    elseif id == "phase" then
        return track_set_bool(track, "B_PHASE", norm >= 0.5)
    end

    return false
end

function track_fixed_cc_format_value(id, track)
    if not track_fixed_cc_track_is_valid(track) then
        return ""
    end

    if id == "volume" then
        return track_get_volume_formatted(track)
    elseif id == "pan" then
        return track_get_pan_formatted(track)
    elseif id == "width" then
        return track_get_width_formatted(track)
    elseif id == "mute" then
        return bool_to_on_off(track_get_bool(track, "B_MUTE"))
    elseif id == "solo" then
        return bool_to_on_off(track_get_solo_bool(track))
    elseif id == "phase" then
        return bool_to_on_off(track_get_bool(track, "B_PHASE"))
    end

    return ""
end

function track_fixed_cc_is_bool(id)
    return id == "mute" or id == "solo" or id == "phase"
end

function track_fixed_cc_current_average_norm(id, tracks)
    tracks = tracks or track_fixed_cc_get_target_tracks()

    if #tracks <= 0 then
        return nil
    end

    local sum = 0
    local count = 0

    for i = 1, #tracks do
        local v = track_fixed_cc_get_norm_for_track(id, tracks[i])

        if v ~= nil then
            sum = sum + clamp01(v)
            count = count + 1
        end
    end

    if count <= 0 then
        return nil
    end

    return clamp01(sum / count)
end

function track_fixed_cc_value_crossed_target(id, last_value, new_value, target)
    if target == nil then
        return false
    end

    new_value = clamp01(new_value)

    if math.abs(new_value - target) <= track_fixed_cc_pickup_tolerance then
        return true
    end

    if last_value == nil then
        return false
    end

    last_value = clamp01(last_value)

    if last_value <= target and new_value >= target then
        return true
    end

    if last_value >= target and new_value <= target then
        return true
    end

    return false
end

function track_fixed_cc_apply_value_to_id(id, cc_value)
    id = clean_one_line(id or "")
    cc_value = clamp01(cc_value)

    if not TRACK_FIXED_CC_IDS[id] then
        return false
    end

    local tracks = track_fixed_cc_get_target_tracks()

    if #tracks <= 0 then
        track_fixed_cc_clear_pickup()
        return true
    end

    track_fixed_cc_reset_pickup_if_selection_changed(tracks)

    if not track_fixed_cc_is_bool(id) then
        if track_fixed_cc_pickup_target[id] == nil then
            track_fixed_cc_pickup_target[id] = track_fixed_cc_current_average_norm(id, tracks)
            track_fixed_cc_pickup[id] = false
        end

        if not track_fixed_cc_pickup[id] then
            if track_fixed_cc_value_crossed_target(
                id,
                track_fixed_cc_last_value_by_id[id],
                cc_value,
                track_fixed_cc_pickup_target[id]
            ) then
                track_fixed_cc_pickup[id] = true
            else
                track_fixed_cc_last_value_by_id[id] = cc_value
                return true
            end
        end
    end

    track_fixed_cc_last_value_by_id[id] = cc_value

    local changed = false
    local before = nil

    if #tracks > 0 then
        before = track_fixed_cc_format_value(id, tracks[1])
    end

    for i = 1, #tracks do
        if track_fixed_cc_set_norm_for_track(id, tracks[i], cc_value) then
            changed = true
        end
    end

    if changed then
        clear_silent_edge()

        local after = ""

        if #tracks > 0 then
            after = track_fixed_cc_format_value(id, tracks[1])
        end

        if after ~= "" and after ~= before then
            if title_detail_is_enabled() then
                if #tracks > 1 then
                    track_cc_value_speak_send(
                        track_fixed_cc_label(id) ..
                        " selected tracks " ..
                        after
                    )
                else
                    track_cc_value_speak_send(track_fixed_cc_label(id) .. " " .. after)
                end
            else
                cancel_pending_speech()
            end
        end
    end

    return true
end

function track_fixed_cc_assign(channel, cc_number, cc_value)
    channel = tonumber(channel) or -1
    cc_number = tonumber(cc_number) or -1
    cc_value = clamp01(cc_value)

    if channel < 1 or channel > 16 or cc_number < 0 or cc_number > 127 then
        speak("Invalid CC")
        return true
    end

    local id = track_fixed_cc_learn_target_id

    if not TRACK_FIXED_CC_IDS[id] then
        speak("No track parameter")
        track_fixed_cc_learn_armed = false
        return true
    end

    track_fixed_cc_set_link(id, channel, cc_number)

    track_fixed_cc_learn_armed = false
    track_fixed_cc_learn_target_id = ""
    track_fixed_cc_learn_target_label = ""
    track_fixed_cc_last_seq = 0
    track_fixed_cc_clear_pickup()

    if type(floating_cc_clear_session) == "function" then
        floating_cc_clear_session()
    end

    speak(
        "Fixed CC saved. " ..
        track_fixed_cc_label(id) ..
        ". Channel " ..
        tostring(channel) ..
        ". CC " ..
        tostring(cc_number)
    )

    return true
end

function track_fixed_cc_arm_learn_for_current_entry()
    cancel_pending_speech()
    clear_silent_edge()

    local id = track_fixed_cc_current_entry_id()

    if id == "" then
        return false
    end

    if not track_fixed_cc_storage_available() then
        track_txt_load()
    end

    track_fixed_cc_learn_target_id = id
    track_fixed_cc_learn_target_label = track_fixed_cc_label(id)
    track_fixed_cc_learn_armed = true
    track_fixed_cc_last_seq = select(1, floating_cc_read_recent_event()) or 0

    speak("CC learn. Move a MIDI control")

    return true
end

function track_fixed_cc_cancel_learn()
    if not track_fixed_cc_learn_armed then
        return false
    end

    track_fixed_cc_learn_armed = false
    track_fixed_cc_learn_target_id = ""
    track_fixed_cc_learn_target_label = ""

    speak("CC learn disarmed")

    return true
end

function track_fixed_cc_cancel_learn(return_message)
    if track_fixed_cc_learn_armed ~= true then
        return false
    end

    local label = clean_one_line(track_fixed_cc_learn_target_label or "")

    if label == "" and track_fixed_cc_learn_target_info then
        label = clean_one_line(track_fixed_cc_learn_target_info.label or "")
    end

    track_fixed_cc_learn_armed = false
    track_fixed_cc_learn_target_info = nil
    track_fixed_cc_learn_target_id = ""
    track_fixed_cc_learn_target_label = ""

    if return_message ~= false then
        if label ~= "" then
            speak("CC learn disarmed. " .. label)
        else
            speak("CC learn disarmed")
        end
    end

    return true
end

function track_fixed_cc_ctrl_alt_c()
    if track_fixed_cc_learn_armed then
        return track_fixed_cc_cancel_learn()
    end

    return track_fixed_cc_arm_learn_for_current_entry()
end

function track_fixed_cc_find_id_by_cc(channel, cc_number)
    channel = clamp_int(channel, 1, 16)
    cc_number = clamp_int(cc_number, 0, 127)

    for _, id in ipairs(TRACK_FIXED_CC_ORDER) do
        local ch, cc = track_fixed_cc_get_link(id)

        if ch == channel and cc == cc_number then
            return id
        end
    end

    return ""
end

function track_fixed_cc_poll_recent_input()
    if not track_fixed_cc_learn_armed then
        if track_fixed_cc_map_enabled ~= true then
            return false
        end

        if track_fixed_cc_count_links() <= 0 then
            return false
        end
    end

    local seq, buf = floating_cc_read_recent_event()

    if seq == 0 then
        return false
    end

    if seq == track_fixed_cc_last_seq then
        return false
    end

    track_fixed_cc_last_seq = seq

    local channel, cc_number, cc_value = floating_cc_parse_cc_from_buffer(buf)

    if not channel then
        return false
    end

    if track_fixed_cc_learn_armed then
        track_fixed_cc_assign(channel, cc_number, cc_value)
        return true
    end

    local id = track_fixed_cc_find_id_by_cc(channel, cc_number)

    if id == "" then
        return false
    end

    return track_fixed_cc_apply_value_to_id(id, cc_value)
end


------------------------------------------------------------
-- 4.2.0A - F4 FX PARAM COMBO INTELLIGENTI
--
-- Solo F4 FX parameters:
-- - combo testuali: salta direttamente alla prossima label,
--   invece di trattarli come slider continui;
-- - combo sparsi: ricerca esponenziale + binaria, più veloce
--   della scansione lineare;
-- - pulsanti momentanei binari 0/1: parla la label di arrivo
--   prima del set, così il JSFX può tornare indietro senza
--   lasciare OSARA muto.
------------------------------------------------------------

function f4_entry_is_fx_param_value(entry)
    entry = entry or get_current_entry()

    return current_section_id == SECTION_FX_PARAMS and
           entry and
           entry.kind == "fx_param" and
           entry.track ~= nil and
           entry.fx_index ~= nil and
           entry.param_index ~= nil
end

function f4_fx_format_param_value_at_norm(track, fx_index, param_index, norm)
    if not track then
        return ""
    end

    if not reaper.TrackFX_FormatParamValueNormalized then
        return ""
    end

    fx_index = tonumber(fx_index) or 0
    param_index = tonumber(param_index) or 0
    norm = clamp01(norm)

    local ok, retval, value =
        pcall(
            reaper.TrackFX_FormatParamValueNormalized,
            track,
            fx_index,
            param_index,
            norm,
            ""
        )

    if ok and retval then
        return clean_one_line(value or "")
    end

    return ""
end

function f4_fx_get_param_value_raw(track, fx_index, param_index)
    if not track then
        return ""
    end

    fx_index = tonumber(fx_index) or 0
    param_index = tonumber(param_index) or 0

    if reaper.TrackFX_GetFormattedParamValue then
        local ok, retval, value =
            pcall(
                reaper.TrackFX_GetFormattedParamValue,
                track,
                fx_index,
                param_index,
                ""
            )

        if ok and retval then
            return clean_one_line(value or "")
        end
    end

    return ""
end

function f4_combo_label_looks_numeric(txt)
    txt = clean_one_line(txt or "")

    if txt == "" then
        return true
    end

    local lower = txt:lower()

    lower = lower:gsub("%%", "")
    lower = lower:gsub("db", "")
    lower = lower:gsub("khz", "")
    lower = lower:gsub("hz", "")
    lower = lower:gsub("ms", "")
    lower = lower:gsub("sec", "")
    lower = lower:gsub("s", "")
    lower = lower:gsub("x", "")
    lower = trim(lower)

    return lower:match("^[%+%-]?%d+[%.%,]?%d*$") ~= nil
end

f4_binary_text_label_cache = f4_binary_text_label_cache or {}

function f4_binary_text_label_cache_key(entry)
    entry = entry or get_current_entry()

    if not entry then
        return ""
    end

    local guid = ""

    if entry.track then
        guid = get_track_guid(entry.track)
    end

    return tostring(guid or "") .. ":" .. tostring(entry.fx_index or "") .. ":" .. tostring(entry.param_index or "")
end

function f4_entry_has_binary_text_labels(entry)
    entry = entry or get_current_entry()

    if not f4_entry_is_fx_param_value(entry) then
        return false
    end

    local cache_key = f4_binary_text_label_cache_key(entry)
    local cached = f4_binary_text_label_cache[cache_key]

    if cached ~= nil then
        return cached == true
    end

    local label0 = f4_fx_format_param_value_at_norm(
        entry.track,
        entry.fx_index,
        entry.param_index,
        0
    )

    local label1 = f4_fx_format_param_value_at_norm(
        entry.track,
        entry.fx_index,
        entry.param_index,
        1
    )

    if label0 == "" or label1 == "" or label0 == label1 then
        f4_binary_text_label_cache[cache_key] = false
        return false
    end

    --------------------------------------------------------
    -- Non basta che 0 e 1 abbiano due label diverse.
    -- Anche molti combo multipli hanno estremità diverse.
    -- Il percorso diretto binario va usato solo quando,
    -- campionando il parametro, le label testuali distinte
    -- risultano davvero esattamente due.
    --------------------------------------------------------
    local labels = {}
    local count = 0

    for n = 0, 16 do
        local label = f4_fx_format_param_value_at_norm(
            entry.track,
            entry.fx_index,
            entry.param_index,
            n / 16
        )

        label = clean_one_line(label or "")

        if label ~= "" then
            if labels[label] ~= true then
                labels[label] = true
                count = count + 1

                if count > 2 then
                    f4_binary_text_label_cache[cache_key] = false
                    return false
                end
            end
        end
    end

    if count ~= 2 then
        f4_binary_text_label_cache[cache_key] = false
        return false
    end

    if f4_combo_label_looks_numeric(label0) and
       f4_combo_label_looks_numeric(label1) then

        f4_binary_text_label_cache[cache_key] = false
        return false
    end

    f4_binary_text_label_cache[cache_key] = true
    return true
end


------------------------------------------------------------
-- F4 JSFX integer/raw combo nudge
--
-- Per i JSFX le combo degli slider sono spesso valori raw interi.
-- Se usiamo solo il normalizzato, alcune combo grandi non riescono
-- a tornare allo stato precedente. Qui, solo in F4 e solo su JSFX
-- con range intero ragionevole, muoviamo direttamente il raw.
------------------------------------------------------------
function f4_entry_fx_is_jsfx(entry)
    entry = entry or get_current_entry()

    if not f4_entry_is_fx_param_value(entry) then
        return false
    end

    local name = fx_get_name(entry.track, entry.fx_index)
    name = clean_one_line(name or ""):lower()

    return name:match("^js:%s*") ~= nil or
           name:match("^jsfx%s*:%s*") ~= nil
end

function f4_nudge_jsfx_raw_integer_combo_direct(entry, direction, big_step)
    entry = entry or get_current_entry()

    if not f4_entry_is_fx_param_value(entry) then
        return false
    end

    if not f4_entry_fx_is_jsfx(entry) then
        return false
    end

    direction = tonumber(direction) or 0

    if direction == 0 then
        return false
    end

    local value, minval, maxval = reaper.TrackFX_GetParam(
        entry.track,
        tonumber(entry.fx_index) or 0,
        tonumber(entry.param_index) or 0
    )

    value = tonumber(value)
    minval = tonumber(minval)
    maxval = tonumber(maxval)

    if value == nil or minval == nil or maxval == nil then
        return false
    end

    if maxval < minval then
        minval, maxval = maxval, minval
    end

    local min_i = math.floor(minval + 0.5)
    local max_i = math.floor(maxval + 0.5)
    local current_i = math.floor(value + 0.5)

    if max_i <= min_i then
        return false
    end

    if (max_i - min_i) > 8192 then
        return false
    end

    if math.abs(minval - min_i) > 0.000001 or
       math.abs(maxval - max_i) > 0.000001 or
       math.abs(value - current_i) > 0.000001 then

        return false
    end

    current_i = clamp_int(current_i, min_i, max_i)

    local amount = big_step and 10 or 1
    amount = clamp_int(amount, 1, 8192)

    local target_i = clamp_int(
        current_i + (amount * direction),
        min_i,
        max_i
    )

    if target_i == current_i then
        if direction > 0 then
            value_edge_silent("f4-jsfx-raw-max")
        else
            value_edge_silent("f4-jsfx-raw-min")
        end

        return true
    end

    reaper.TrackFX_SetParam(
        entry.track,
        tonumber(entry.fx_index) or 0,
        tonumber(entry.param_index) or 0,
        target_i
    )

    reaper.TrackList_AdjustWindows(false)
    reaper.UpdateArrange()

    clear_silent_edge()

    local spoken = f4_fx_get_param_value_raw(
        entry.track,
        entry.fx_index,
        entry.param_index
    )

    spoken = clean_one_line(spoken or "")

    if spoken == "" then
        spoken = tostring(target_i)
    end

    cancel_pending_speech()
    speak(spoken)

    return true
end


------------------------------------------------------------
-- F4 text combo map cache
--
-- Track Param F4 has to be faster than the generic scan.
-- For true multi-label combo controls, we build a per-parameter
-- map with FormatParamValueNormalized only. That does not move
-- the real parameter while scanning. After the map is cached,
-- Up/Down can jump to the next label directly.
------------------------------------------------------------
f4_text_combo_map_cache = f4_text_combo_map_cache or {}

function f4_text_combo_map_cache_key(entry)
    return f4_binary_text_label_cache_key(entry)
end

function f4_text_combo_map_build(entry)
    entry = entry or get_current_entry()

    if not f4_entry_is_fx_param_value(entry) then
        return nil
    end

    local cache_key = f4_text_combo_map_cache_key(entry)
    local cached = f4_text_combo_map_cache[cache_key]

    if cached ~= nil then
        if cached == false then
            return nil
        end

        return cached
    end

    --------------------------------------------------------
    -- 512 divisions are enough for normal plugin enumerations
    -- and much cheaper than setting the real parameter many
    -- times on every key press. If a strange plugin is not
    -- mapped correctly, the caller still falls back to the old
    -- scan path.
    --------------------------------------------------------
    local scan_steps = 512
    local items = {}
    local last_label = nil
    local last_start_i = 0
    local text_label_count = 0
    local too_many = false

    local function add_segment(label, start_i, end_i)
        label = clean_one_line(label or "")

        if label == "" then
            return
        end

        items[#items + 1] = {
            label = label,
            start_i = clamp_int(start_i, 0, scan_steps),
            end_i = clamp_int(end_i, 0, scan_steps),
            center_i = clamp_int((start_i + end_i) / 2, 0, scan_steps)
        }
    end

    for i = 0, scan_steps do
        local label = f4_fx_format_param_value_at_norm(
            entry.track,
            entry.fx_index,
            entry.param_index,
            i / scan_steps
        )

        label = clean_one_line(label or "")

        if label == "" then
            label = last_label or ""
        end

        if i == 0 then
            last_label = label
            last_start_i = 0

            if label ~= "" and not f4_combo_label_looks_numeric(label) then
                text_label_count = text_label_count + 1
            end
        elseif label ~= last_label then
            add_segment(last_label, last_start_i, i - 1)

            if label ~= "" and not f4_combo_label_looks_numeric(label) then
                text_label_count = text_label_count + 1
            end

            if #items > 256 then
                too_many = true
                break
            end

            last_label = label
            last_start_i = i
        end
    end

    if not too_many then
        add_segment(last_label, last_start_i, scan_steps)
    end

    --------------------------------------------------------
    -- Do not use the map for binary controls. Those have the
    -- special direct path because momentary buttons may jump
    -- back immediately. Do not use it for numeric sliders.
    --------------------------------------------------------
    if too_many or #items <= 2 or text_label_count <= 0 then
        f4_text_combo_map_cache[cache_key] = false
        return nil
    end

    local map = {
        scan_steps = scan_steps,
        items = items
    }

    f4_text_combo_map_cache[cache_key] = map

    return map
end

function f4_text_combo_map_find_index(map, base_v, base_fmt)
    if not map or not map.items then
        return 0
    end

    base_v = clamp01(base_v)
    base_fmt = clean_one_line(base_fmt or "")

    local items = map.items
    local base_i = clamp_int(base_v * (tonumber(map.scan_steps) or 512), 0, tonumber(map.scan_steps) or 512)
    local best_i = 0
    local best_distance = 1000000000

    for i = 1, #items do
        local it = items[i]

        if it then
            if base_fmt ~= "" and clean_one_line(it.label or "") == base_fmt then
                local center_i = tonumber(it.center_i) or 0
                local d = math.abs(center_i - base_i)

                if d < best_distance then
                    best_i = i
                    best_distance = d
                end
            end
        end
    end

    if best_i > 0 then
        return best_i
    end

    for i = 1, #items do
        local it = items[i]

        if it and base_i >= (tonumber(it.start_i) or 0) and base_i <= (tonumber(it.end_i) or 0) then
            return i
        end
    end

    return 0
end

function f4_nudge_text_combo_cached(direction, big_step)
    local e = get_current_entry()

    if not f4_entry_is_fx_param_value(e) then
        return false
    end

    direction = tonumber(direction) or 0

    if direction == 0 then
        return false
    end

    local base_v = current_entry_get_norm()

    if base_v == nil then
        return false
    end

    local base_fmt = f4_fx_get_param_value_raw(
        e.track,
        e.fx_index,
        e.param_index
    )

    if base_fmt == "" then
        return false
    end

    local map = f4_text_combo_map_build(e)

    if not map or not map.items or #map.items <= 2 then
        return false
    end

    local current_i = f4_text_combo_map_find_index(map, base_v, base_fmt)

    if current_i <= 0 then
        return false
    end

    local amount = big_step and 10 or 1
    local target_i = clamp_int(current_i + (amount * direction), 1, #map.items)

    if target_i == current_i then
        if direction > 0 then
            value_edge_silent("f4-combo-cache-max:" .. f4_text_combo_map_cache_key(e))
        else
            value_edge_silent("f4-combo-cache-min:" .. f4_text_combo_map_cache_key(e))
        end

        return true
    end

    local target = map.items[target_i]

    if not target then
        return false
    end

    local norm = clamp01((tonumber(target.center_i) or 0) / (tonumber(map.scan_steps) or 512))

    if current_entry_set_norm(norm) then
        clear_silent_edge()
        cancel_pending_speech()
        speak(clean_one_line(target.label or ""))
        return true
    end

    current_entry_set_norm(base_v)
    return false
end

function f4_binary_combo_target_label(entry, target_v)
    entry = entry or get_current_entry()
    target_v = clamp01(target_v)

    if not f4_entry_is_fx_param_value(entry) then
        return ""
    end

    local msg = f4_fx_format_param_value_at_norm(
        entry.track,
        entry.fx_index,
        entry.param_index,
        target_v
    )

    if msg ~= "" then
        return msg
    end

    msg = f4_fx_get_param_value_raw(
        entry.track,
        entry.fx_index,
        entry.param_index
    )

    if msg ~= "" then
        return msg
    end

    return target_v >= 0.5 and "On" or "Off"
end

function f4_set_binary_combo_direct(target_v, force_speak)
    local e = get_current_entry()

    if not f4_entry_is_fx_param_value(e) then
        return false
    end

    if not f4_entry_has_binary_text_labels(e) then
        return false
    end

    target_v = clamp01(target_v)
    target_v = target_v >= 0.5 and 1 or 0
    force_speak = force_speak == true

    local old_v = current_entry_get_norm()

    if old_v ~= nil and
       not force_speak and
       math.abs(old_v - target_v) <= 0.0000001 then

        if target_v >= 0.5 then
            value_edge_silent("f4-binary-on")
        else
            value_edge_silent("f4-binary-off")
        end

        return true
    end

    --------------------------------------------------------
    -- Prende la label prima del set: fondamentale per
    -- pulsanti momentanei JSFX che tornano subito a 0.
    --------------------------------------------------------
    local msg = f4_binary_combo_target_label(e, target_v)

    if current_entry_set_norm(target_v) then
        clear_silent_edge()

        if msg == "" then
            msg = target_v >= 0.5 and "On" or "Off"
        end

        cancel_pending_speech()
        speak(msg)

        return true
    end

    speak("Value failed")
    return true
end

function f4_nudge_binary_combo_direct(direction)
    direction = tonumber(direction) or 0

    if direction == 0 then
        return false
    end

    return f4_set_binary_combo_direct(direction > 0 and 1 or 0, false)
end

function f4_entry_current_label_is_text_combo(entry)
    entry = entry or get_current_entry()

    if not f4_entry_is_fx_param_value(entry) then
        return false
    end

    local current_label = f4_fx_get_param_value_raw(
        entry.track,
        entry.fx_index,
        entry.param_index
    )

    if current_label == "" then
        current_label = make_entry_value(entry)
    end

    if current_label == "" then
        return false
    end

    if not f4_combo_label_looks_numeric(current_label) then
        return true
    end

    local here = current_entry_get_norm()

    if here == nil then
        return false
    end

    local near_low = f4_fx_format_param_value_at_norm(
        entry.track,
        entry.fx_index,
        entry.param_index,
        clamp01(here - 0.01)
    )

    local near_high = f4_fx_format_param_value_at_norm(
        entry.track,
        entry.fx_index,
        entry.param_index,
        clamp01(here + 0.01)
    )

    if near_low ~= "" and
       near_high ~= "" and
       near_low ~= near_high and
       (
           not f4_combo_label_looks_numeric(near_low) or
           not f4_combo_label_looks_numeric(near_high)
       ) then

        return true
    end

    return false
end

function f4_find_next_distinct_combo_value_linear(entry, direction, base_v, base_fmt, fine_scan)
    if not f4_entry_is_fx_param_value(entry) then
        return false, ""
    end

    direction = tonumber(direction) or 0

    if direction == 0 then
        return false, ""
    end

    local scan_steps = tonumber(fine_scan) or 4096

    if scan_steps < 128 then
        scan_steps = 128
    end

    base_v = clamp01(base_v)
    base_fmt = clean_one_line(base_fmt or "")

    local start_i
    local end_i
    local step_i

    if direction > 0 then
        start_i = math.floor(base_v * scan_steps) + 1
        end_i = scan_steps
        step_i = 1
    else
        start_i = math.ceil(base_v * scan_steps) - 1
        end_i = 0
        step_i = -1
    end

    local i = start_i

    while (direction > 0 and i <= end_i) or
          (direction < 0 and i >= end_i) do

        local try_v = clamp01(i / scan_steps)

        if math.abs(try_v - base_v) > 0.0000001 then
            current_entry_set_norm(try_v)

            local try_fmt = f4_fx_get_param_value_raw(
                entry.track,
                entry.fx_index,
                entry.param_index
            )

            if try_fmt ~= "" and try_fmt ~= base_fmt then
                return true, try_fmt
            end
        end

        i = i + step_i
    end

    current_entry_set_norm(base_v)

    return false, ""
end

function f4_find_next_distinct_combo_value(entry, direction, base_v, base_fmt, fine_scan)
    if not f4_entry_is_fx_param_value(entry) then
        return false, ""
    end

    direction = tonumber(direction) or 0

    if direction == 0 then
        return false, ""
    end

    local scan_steps = tonumber(fine_scan) or 4096

    if scan_steps < 128 then
        scan_steps = 128
    end

    base_v = clamp01(base_v)
    base_fmt = clean_one_line(base_fmt or "")

    local base_i = math.floor((base_v * scan_steps) + 0.5)
    base_i = clamp_int(base_i, 0, scan_steps)

    local limit_i = direction > 0 and scan_steps or 0
    local distance = 1
    local last_same_i = base_i
    local found_i = nil

    while true do
        local probe_i = base_i + (distance * direction)

        if direction > 0 then
            if probe_i > limit_i then
                probe_i = limit_i
            end
        else
            if probe_i < limit_i then
                probe_i = limit_i
            end
        end

        if probe_i == last_same_i then
            break
        end

        current_entry_set_norm(clamp01(probe_i / scan_steps))

        local try_fmt = f4_fx_get_param_value_raw(
            entry.track,
            entry.fx_index,
            entry.param_index
        )

        if try_fmt ~= "" and try_fmt ~= base_fmt then
            found_i = probe_i
            break
        end

        last_same_i = probe_i

        if probe_i == limit_i then
            break
        end

        distance = distance * 2

        if distance > scan_steps then
            distance = scan_steps
        end
    end

    if found_i == nil then
        current_entry_set_norm(base_v)
        return false, ""
    end

    local target_i = found_i

    if direction > 0 then
        local low_i = last_same_i
        local high_i = found_i

        while (high_i - low_i) > 1 do
            local mid_i = math.floor((low_i + high_i) / 2)

            current_entry_set_norm(clamp01(mid_i / scan_steps))

            local try_fmt = f4_fx_get_param_value_raw(
                entry.track,
                entry.fx_index,
                entry.param_index
            )

            if try_fmt ~= "" and try_fmt ~= base_fmt then
                high_i = mid_i
            else
                low_i = mid_i
            end
        end

        target_i = high_i
    else
        local low_i = found_i
        local high_i = last_same_i

        while (high_i - low_i) > 1 do
            local mid_i = math.floor((low_i + high_i) / 2)

            current_entry_set_norm(clamp01(mid_i / scan_steps))

            local try_fmt = f4_fx_get_param_value_raw(
                entry.track,
                entry.fx_index,
                entry.param_index
            )

            if try_fmt ~= "" and try_fmt ~= base_fmt then
                low_i = mid_i
            else
                high_i = mid_i
            end
        end

        target_i = low_i
    end

    current_entry_set_norm(clamp01(target_i / scan_steps))

    local final_fmt = f4_fx_get_param_value_raw(
        entry.track,
        entry.fx_index,
        entry.param_index
    )

    if final_fmt ~= "" and final_fmt ~= base_fmt then
        return true, final_fmt
    end

    current_entry_set_norm(base_v)

    return f4_find_next_distinct_combo_value_linear(
        entry,
        direction,
        base_v,
        base_fmt,
        fine_scan
    )
end

function f4_nudge_text_combo(direction, big_step)
    local e = get_current_entry()

    if not f4_entry_is_fx_param_value(e) then
        return false
    end

    if f4_entry_has_binary_text_labels(e) then
        return f4_nudge_binary_combo_direct(direction)
    end

    if type(f4_nudge_jsfx_raw_integer_combo_direct) == "function" and
       f4_nudge_jsfx_raw_integer_combo_direct(e, direction, big_step == true) then

        return true
    end

    if not f4_entry_current_label_is_text_combo(e) then
        return false
    end

    if f4_nudge_text_combo_cached and f4_nudge_text_combo_cached(direction, big_step == true) then
        return true
    end

    local base_v = current_entry_get_norm()

    if base_v == nil then
        return false
    end

    local base_fmt = f4_fx_get_param_value_raw(
        e.track,
        e.fx_index,
        e.param_index
    )

    if base_fmt == "" then
        return false
    end

    local steps_to_move = big_step and 10 or 1
    local moved = false
    local final_fmt = base_fmt

    for _ = 1, steps_to_move do
        local before_v = current_entry_get_norm()
        local before_fmt = f4_fx_get_param_value_raw(
            e.track,
            e.fx_index,
            e.param_index
        )

        local ok, label = f4_find_next_distinct_combo_value(
            e,
            direction,
            before_v,
            before_fmt,
            4096
        )

        if ok then
            moved = true
            final_fmt = label
        else
            current_entry_set_norm(before_v)
            break
        end
    end

    if moved then
        clear_silent_edge()
        speak_later(final_fmt)
        return true
    end

    current_entry_set_norm(base_v)

    if direction > 0 then
        value_edge_silent("f4-combo-max")
    else
        value_edge_silent("f4-combo-min")
    end

    return true
end


function current_entry_is_bool_value()
    local e = get_current_entry()

    if not e then
        return false
    end

    return e.value_kind == "bool"
end

function current_entry_has_step()
    local e = get_current_entry()

    if not e then
        return false
    end

    return type(e.step) == "function"
end

function value_edge_token(suffix)
    local e = get_current_entry()
    local id = ""

    if e then
        id =
            tostring(e.kind or "") ..
            ":" ..
            tostring(e.id or "") ..
            ":" ..
            tostring(e.track_index or "") ..
            ":" ..
            tostring(e.category or "") ..
            ":" ..
            tostring(e.send_index or "") ..
            ":" ..
            tostring(e.real_send_index or "") ..
            ":" ..
            tostring(e.display_index or "") ..
            ":" ..
            tostring(e.fx_index or "") ..
            ":" ..
            tostring(e.param_index or "")
    end

    return "value-edge:" .. id .. ":" .. tostring(suffix or "")
end

function value_edge_silent(suffix)
    edge_was_already_silent(value_edge_token(suffix))
    return false
end

function current_entry_run_step(direction)
    local e = get_current_entry()

    if not e or type(e.step) ~= "function" then
        return false
    end

    direction = tonumber(direction) or 0

    if direction == 0 then
        return false
    end

    local before = current_entry_get_norm()
    local ok, result = pcall(e.step, e, direction)
    local after = current_entry_get_norm()

    if ok and result ~= false then
        if before ~= nil and
           after ~= nil and
           math.abs(after - before) <= 0.0000001 then

            if direction > 0 then
                return value_edge_silent("step-max")
            end

            return value_edge_silent("step-min")
        end

        clear_silent_edge()
        speak_later(make_entry_value(get_current_entry()))
        return true
    end

    speak("Value failed")
    return false
end

function current_entry_set_bool_by_direction(direction)
    direction = tonumber(direction) or 0

    if direction == 0 then
        return false
    end

    if not current_entry_supports_value() then
        speak("No value")
        return false
    end

    local old = current_entry_get_norm()
    local new_value = direction > 0 and 1 or 0

    if old ~= nil and math.abs(new_value - old) <= 0.0000001 then
        if direction > 0 then
            return value_edge_silent("bool-on")
        end

        return value_edge_silent("bool-off")
    end

    if current_entry_set_norm(new_value) then
        clear_silent_edge()
        speak_later(make_entry_value(get_current_entry()))
        return true
    end

    speak("Value failed")
    return false
end

function current_entry_nudge_value(direction, big_step)
    direction = tonumber(direction) or 0

    if direction == 0 then
        return false
    end

    if not current_entry_supports_value() then
        speak("No value")
        return false
    end

    if f4_nudge_text_combo and f4_nudge_text_combo(direction, big_step == true) then
        return true
    end

    if current_entry_has_step() then
        return current_entry_run_step(direction)
    end

    if current_entry_is_bool_value() then
        return current_entry_set_bool_by_direction(direction)
    end

    local old = current_entry_get_norm()

    if old == nil then
        speak("No value")
        return false
    end

    local step = big_step and 0.08 or 0.01

    step = step * get_step_scale()

    if step > 1 then
        step = 1
    end

    local new_value = clamp01(old + (step * direction))

    if math.abs(new_value - old) <= 0.0000001 then
        if direction > 0 then
            return value_edge_silent("max")
        end

        return value_edge_silent("min")
    end

    if current_entry_set_norm(new_value) then
        clear_silent_edge()
        speak_later(make_entry_value(get_current_entry()))
        return true
    end

    speak("Value failed")
    return false
end

function current_entry_set_min()
    if not current_entry_supports_value() then
        speak("No value")
        return false
    end

    if f4_set_binary_combo_direct and f4_set_binary_combo_direct(0, true) then
        return true
    end

    local old = current_entry_get_norm()

    if old ~= nil and old <= 0.0000001 then
        return value_edge_silent("min")
    end

    if current_entry_set_norm(0) then
        clear_silent_edge()
        speak_later(make_entry_value(get_current_entry()))
        return true
    end

    speak("Value failed")
    return false
end

function current_entry_set_max()
    if not current_entry_supports_value() then
        speak("No value")
        return false
    end

    if f4_set_binary_combo_direct and f4_set_binary_combo_direct(1, true) then
        return true
    end

    local old = current_entry_get_norm()

    if old ~= nil and old >= 0.9999999 then
        return value_edge_silent("max")
    end

    if current_entry_set_norm(1) then
        clear_silent_edge()
        speak_later(make_entry_value(get_current_entry()))
        return true
    end

    speak("Value failed")
    return false
end

------------------------------------------------------------
-- 4.3 - FOLDER TOGGLE
--
-- Solo F1:
-- Ctrl+Enter apre/chiude la folder della traccia corrente.
------------------------------------------------------------

function current_entry_toggle_folder()
    local e = get_current_entry()

    if not e or not e.track then
        speak("No track")
        return false
    end

    if current_section_id ~= SECTION_TRACKS then
        speak("Only in Tracks")
        return false
    end

    local track = e.track
    local target_folder = nil

    --------------------------------------------------------
    -- Caso 1:
    -- siamo direttamente su una folder.
    --------------------------------------------------------

    if track_is_folder(track) then
        target_folder = track

    else
        ----------------------------------------------------
        -- Caso 2:
        -- siamo sull'ultima traccia di una o più folder.
        -- Ctrl+Enter cicla tra le folder chiuse da questa
        -- traccia, dalla più interna alla principale.
        ----------------------------------------------------

        target_folder = get_next_end_folder_target_for_track(track)
    end

    if not target_folder then
        speak("Not folder")
        return false
    end

    cancel_pending_speech()
    clear_silent_edge()

    local wanted_col = grid_col_from_pos(grid_pos)
    local wanted_target_guid = get_track_guid(target_folder)

    set_current_track_pointer_only(target_folder)

    if toggle_track_folder_collapsed(target_folder) then
        build_current_grid()

        ----------------------------------------------------
        -- Dopo la chiusura, la traccia finale può sparire
        -- perché è dentro la folder. Quindi ci posizioniamo
        -- sulla folder che abbiamo aperto / chiuso.
        ----------------------------------------------------

        if wanted_target_guid ~= "" then
            for pos = 1, #grid_entries do
                local ge = grid_entries[pos]

                if ge and
                   ge.track and
                   get_track_guid(ge.track) == wanted_target_guid then

                    local row = grid_row_from_pos(pos)
                    grid_pos = grid_pos_from_row_col(row, wanted_col)
                    break
                end
            end
        end

        local here = get_current_entry()

        if here and here.track then
            set_current_track_pointer_only(here.track)
        end

        refresh_window_title()

        speak(
            get_track_plain_short_label(target_folder) ..
            " " ..
            track_folder_state_name(target_folder)
        )

        return true
    end

    speak("Folder failed")
    return false
end

------------------------------------------------------------
-- 4.4 - LISTA PARAMETRI FX
------------------------------------------------------------

function fx_param_list_filter_is_active()
    return fx_param_list_filter_active and
           normalize_search_text(fx_param_list_filter_query) ~= ""
end

function fx_param_list_get_filter_query()
    return normalize_search_text(fx_param_list_filter_query)
end

function fx_param_list_set_filter_query(query)
    query = clean_one_line(query or "")

    fx_param_list_filter_query = query
    fx_param_list_filter_active = normalize_search_text(query) ~= ""

    return true
end

function fx_param_list_clear_filter()
    fx_param_list_filter_query = ""
    fx_param_list_filter_active = false

    return true
end

function fx_param_list_param_filter_text(track, fx_index, param_index)
    local parts = {}

    fx_index = tonumber(fx_index) or 0
    param_index = tonumber(param_index) or 0

    parts[#parts + 1] = fx_get_name(track, fx_index)
    parts[#parts + 1] = "Param"
    parts[#parts + 1] = "Param " .. tostring(param_index + 1)
    parts[#parts + 1] = fx_get_param_name(track, fx_index, param_index)
    parts[#parts + 1] = fx_get_param_value(track, fx_index, param_index)

    return table.concat(parts, " ")
end

function fx_param_list_param_matches_filter(track, fx_index, param_index)
    if not fx_param_list_filter_is_active() then
        return true
    end

    return text_matches_filter(
        fx_param_list_param_filter_text(track, fx_index, param_index),
        fx_param_list_get_filter_query()
    )
end

function fx_param_list_entry_spoken_label(entry)
    if not entry then
        return "No parameter"
    end

    local label = make_entry_label(entry)
    local value = make_entry_value(entry)
    local prefix = ""

    if fx_param_list_view_mode == "visible_group" then
        prefix = ""
    else
        if entry.tcp_visible then
            prefix = "Visible. "
        end
    end

    if label == "" then
        label = "Param " .. tostring((tonumber(entry.param_index) or 0) + 1)
    end

    if value ~= "" then
        return prefix .. label .. " " .. value
    end

    return prefix .. label
end

function build_fx_param_list_all_grid()
    grid_entries = {}

    if not current_track then
        return false
    end

    if fx_param_list_fx_index < 0 then
        return false
    end

    local fx_index = fx_param_list_fx_index
    local param_count = fx_get_param_count(current_track, fx_index)

    if param_count <= 0 then
        return false
    end

    grid_size = 200

    for p = 0, param_count - 1 do
        if fx_param_list_param_matches_filter(current_track, fx_index, p) then
            local tcp_visible = fx_param_is_tcp_visible(
                current_track,
                fx_index,
                p
            )

            grid_entries[#grid_entries + 1] = {
                kind = "fx_param_list_param",
                id = "fx_param_list_param",
                value_kind = "continuous",
                track = current_track,
                fx_index = fx_index,
                param_index = p,
                tcp_visible = tcp_visible,

                label = function(e)
                    return fx_get_param_name(e.track, e.fx_index, e.param_index)
                end,

                value = function(e)
                    return fx_get_param_value(e.track, e.fx_index, e.param_index)
                end,

                get_norm = function(e)
                    return fx_get_param_norm(e.track, e.fx_index, e.param_index)
                end,

                set_norm = function(e, norm)
                    return fx_set_param_norm(e.track, e.fx_index, e.param_index, norm)
                end
            }
        end
    end

    grid_pos = clamp_int(grid_pos, 1, math.max(1, #grid_entries))

    return #grid_entries > 0
end

function build_fx_param_visible_group_grid()
    grid_entries = {}

    if not current_track then
        return false
    end

    grid_size = 200

    local fx_count = 0

    if reaper.TrackFX_GetCount then
        fx_count = reaper.TrackFX_GetCount(current_track) or 0
    end

    if fx_count <= 0 then
        return false
    end

    for fx = 0, fx_count - 1 do
        local fx_name = fx_get_name(current_track, fx)
        local visible_params = get_fx_tcp_visible_param_indices(current_track, fx)

        for i = 1, #visible_params do
            local p = visible_params[i]

            if fx_param_list_param_matches_filter(current_track, fx, p) then
                grid_entries[#grid_entries + 1] = {
                    kind = "fx_param_list_param",
                    id = "fx_param_list_visible_group_param",
                    value_kind = "continuous",
                    track = current_track,
                    fx_index = fx,
                    param_index = p,
                    tcp_visible = true,
                    visible_group = true,

                    label = function(e)
                        return
                            fx_get_name(e.track, e.fx_index) ..
                            ". " ..
                            fx_get_param_name(e.track, e.fx_index, e.param_index)
                    end,

                    value = function(e)
                        return fx_get_param_value(e.track, e.fx_index, e.param_index)
                    end,

                    get_norm = function(e)
                        return fx_get_param_norm(e.track, e.fx_index, e.param_index)
                    end,

                    set_norm = function(e, norm)
                        return fx_set_param_norm(e.track, e.fx_index, e.param_index, norm)
                    end
                }
            end
        end
    end

    grid_pos = clamp_int(grid_pos, 1, math.max(1, #grid_entries))

    return #grid_entries > 0
end

function build_fx_param_list_grid()
    if fx_param_list_view_mode == "visible_group" then
        return build_fx_param_visible_group_grid()
    end

    return build_fx_param_list_all_grid()
end

function enter_fx_param_list_from_header(entry)
    if not entry or entry.kind ~= "fx_header" then
        return false
    end

    if not entry.track then
        speak("No track")
        return false
    end

    fx_param_list_return_section_key = current_section_key
    fx_param_list_return_section_id = current_section_id
    fx_param_list_return_grid_pos = grid_pos

    fx_param_list_fx_index = tonumber(entry.fx_index) or -1
    fx_param_list_fx_name = fx_get_name(entry.track, fx_param_list_fx_index)

    fx_param_list_clear_filter()

fx_param_list_view_mode = "all"

    current_section_key = KEY_F4
    current_section_id = FX_PARAM_LIST_SECTION_ID
    mode = "fx_param_list"

    grid_pos = 1

    local ok = build_fx_param_list_grid()

    refresh_window_title()

    if not ok then
        speak(fx_param_list_fx_name .. ". No parameters")
        return true
    end

    speak(
        fx_param_list_fx_name ..
        ". Parameter list. " ..
        tostring(#grid_entries) ..
        " parameters. " ..
        fx_param_list_entry_spoken_label(get_current_entry())
    )

    return true
end

function exit_fx_param_list(rebuild_f4, speak_it)
    local old_fx_index = fx_param_list_fx_index

    mode = "grid"
    current_section_key = fx_param_list_return_section_key or KEY_F4
    current_section_id = fx_param_list_return_section_id or SECTION_FX_PARAMS
    grid_pos = fx_param_list_return_grid_pos or 1

fx_param_list_clear_filter()
fx_param_list_view_mode = "all"
fx_param_list_fx_index = -1
fx_param_list_fx_name = ""

    if rebuild_f4 ~= false then
        build_current_grid()

        local header_pos = f4_find_header_pos_for_fx(old_fx_index)

        if header_pos > 0 then
            grid_pos = header_pos
        else
            grid_pos = clamp_int(grid_pos, 1, math.max(1, #grid_entries))
        end
    end

    refresh_window_title()

    if speak_it ~= false then
        speak_current_entry()
    end

    return true
end

function fx_param_list_toggle_current_tcp()
    local e = get_current_entry()

    if not e or e.kind ~= "fx_param_list_param" then
        speak("No parameter")
        return true
    end

    local was_visible = fx_param_is_tcp_visible(
        current_track,
        e.fx_index,
        e.param_index
    )

    local param_name = make_entry_label(e)
    local ok = false

    if was_visible then
        ok = fx_remove_param_from_tcp(
            current_track,
            e.fx_index,
            e.param_index
        )
    else
        ok = fx_add_param_to_tcp(
            current_track,
            e.fx_index,
            e.param_index
        )
    end

    if not ok then
        speak("Could not change parameter")
        return true
    end

    local old_pos = grid_pos

    build_fx_param_list_grid()

    grid_pos = clamp_int(old_pos, 1, math.max(1, #grid_entries))

    refresh_window_title()

    local new_entry = get_current_entry()

    if was_visible then
        if fx_param_list_view_mode == "visible_group" then
            if new_entry then
                speak(
                    "Removed " ..
                    param_name ..
                    ". " ..
                    fx_param_list_entry_spoken_label(new_entry)
                )
            else
                speak("Removed " .. param_name .. ". Visible parameters empty")
            end
        else
            speak("Removed. " .. fx_param_list_entry_spoken_label(new_entry))
        end

        return true
    end

    speak("Added. " .. fx_param_list_entry_spoken_label(new_entry))

    return true
end

function fx_param_list_view_title()
    if fx_param_list_view_mode == "visible_group" then
        return "Visible parameters"
    end

    if fx_param_list_fx_name ~= "" then
        return fx_param_list_fx_name .. ". Parameter list"
    end

    return "Parameter list"
end

function fx_param_list_toggle_view()
    cancel_pending_speech()
    clear_silent_edge()

    if fx_param_list_view_mode == "visible_group" then
        fx_param_list_view_mode = "all"
        grid_pos = 1

        local ok = build_fx_param_list_grid()

        refresh_window_title()

        if ok then
            speak(
                fx_param_list_view_title() ..
                ". " ..
                tostring(#grid_entries) ..
                " parameters. " ..
                fx_param_list_entry_spoken_label(get_current_entry())
            )
        else
            speak(fx_param_list_view_title() .. ". Empty")
        end

        return true
    end

    fx_param_list_view_mode = "visible_group"
    grid_pos = 1

    local ok = build_fx_param_list_grid()

    refresh_window_title()

    if ok then
        speak(
            "Visible parameters. " ..
            tostring(#grid_entries) ..
            " parameters. " ..
            fx_param_list_entry_spoken_label(get_current_entry())
        )
    else
        speak("Visible parameters. Empty")
    end

    return true
end

function enter_fx_visible_params_list_from_f4()
    cancel_pending_speech()
    clear_silent_edge()

    if current_section_id ~= SECTION_FX_PARAMS then
        return false
    end

    if not current_track then
        speak("No track")
        return true
    end

    fx_param_list_return_section_key = current_section_key
    fx_param_list_return_section_id = current_section_id
    fx_param_list_return_grid_pos = grid_pos

    fx_param_list_fx_index = -1
    fx_param_list_fx_name = ""
    fx_param_list_clear_filter()
    fx_param_list_view_mode = "visible_group"

    current_section_key = KEY_F4
    current_section_id = FX_PARAM_LIST_SECTION_ID
    mode = "fx_param_list"
    grid_pos = 1

    local ok = build_fx_param_list_grid()

    refresh_window_title()

    if ok then
        speak(
            "Visible parameters. " ..
            tostring(#grid_entries) ..
            " parameters. " ..
            fx_param_list_entry_spoken_label(get_current_entry())
        )
    else
        speak("Visible parameters. Empty")
    end

    return true
end

function fx_param_list_switch_fx(direction)
    direction = tonumber(direction) or 0

    if direction == 0 then
        return false
    end

    if not current_track then
        speak("No track")
        return true
    end

    local fx_count = 0

    if reaper.TrackFX_GetCount then
        fx_count = reaper.TrackFX_GetCount(current_track) or 0
    end

    if fx_count <= 0 then
        speak("No FX")
        return true
    end

    local old_fx = tonumber(fx_param_list_fx_index) or -1

    if old_fx < 0 then
        old_fx = 0
    end

    local new_fx = old_fx + direction

    if new_fx < 0 then
        return grid_edge("fx-param-list-prev-fx")
    end

    if new_fx >= fx_count then
        return grid_edge("fx-param-list-next-fx")
    end

    fx_param_list_view_mode = "all"
    fx_param_list_fx_index = new_fx
    fx_param_list_fx_name = fx_get_name(current_track, new_fx)
    grid_pos = 1

    local ok = build_fx_param_list_grid()

    refresh_window_title()

    if ok then
        speak(
            fx_param_list_fx_name ..
            ". Parameter list. " ..
            tostring(#grid_entries) ..
            " parameters. " ..
            fx_param_list_entry_spoken_label(get_current_entry())
        )
    else
        speak(fx_param_list_fx_name .. ". No parameters")
    end

    return true
end

function fx_param_list_count_visible_group_params()
    if not current_track then
        return 0
    end

    local total = 0
    local fx_count = 0

    if reaper.TrackFX_GetCount then
        fx_count = reaper.TrackFX_GetCount(current_track) or 0
    end

    for fx = 0, fx_count - 1 do
        local visible_params = get_fx_tcp_visible_param_indices(current_track, fx)
        total = total + #visible_params
    end

    return total
end


function fx_param_list_visible_group_confirm_remove_and_exit()
    local e = get_current_entry()

    if not e or e.kind ~= "fx_param_list_param" then
        exit_fx_param_list(true, true)
        return true
    end

    local target_track = e.track or current_track
    local target_fx_index = tonumber(e.fx_index) or -1
    local target_param_index = tonumber(e.param_index)
    local param_name = make_entry_label(e)

    if param_name == "" then
        param_name = "Parameter"
    end

    if not target_track or target_fx_index < 0 or target_param_index == nil then
        exit_fx_param_list(true, true)
        return true
    end

    --------------------------------------------------------
    -- Prima della rimozione ricordiamo la posizione del
    -- parametro dentro il blocco visibile del suo FX.
    -- Dopo la rimozione useremo questa posizione invisibile
    -- per tornare al parametro più vicino; se non resta nessun
    -- parametro visibile per quell'FX, torniamo all'intestazione.
    --------------------------------------------------------

    local before_visible = get_fx_tcp_visible_param_indices(
        target_track,
        target_fx_index
    )

    local local_pos = 1

    for i = 1, #before_visible do
        if tonumber(before_visible[i]) == target_param_index then
            local_pos = i
            break
        end
    end

    local ok = fx_remove_param_from_tcp(
        target_track,
        target_fx_index,
        target_param_index
    )

    if not ok then
        speak("Could not remove parameter")
        return true
    end

    local after_visible = get_fx_tcp_visible_param_indices(
        target_track,
        target_fx_index
    )

    local wanted_param_index = nil

    if #after_visible > 0 then
        if local_pos > #after_visible then
            local_pos = #after_visible
        end

        wanted_param_index = after_visible[local_pos]
    end

    exit_fx_param_list(true, false)

    local target_pos = 0

    if wanted_param_index ~= nil then
        target_pos = f4_find_param_pos_for_fx_param(
            target_fx_index,
            wanted_param_index
        )
    end

    if target_pos <= 0 then
        target_pos = f4_find_header_pos_for_fx(target_fx_index)
    end

    if target_pos > 0 then
        grid_pos = target_pos
        refresh_window_title()
    end

    speak("Removed " .. param_name .. ". " .. get_entry_spoken_label(get_current_entry()))

    return true
end

function fx_param_list_confirm()
    local e = get_current_entry()

    --------------------------------------------------------
    -- Enter nella lista parametri completa:
    -- conferma aggiungendo almeno il parametro corrente ai
    -- Track Controls, poi torna a F4 sul parametro confermato.
    --
    -- Enter nella lista parametri visibili F6:
    -- rimuove il parametro corrente dai Track Controls e chiude
    -- la lista, tornando al parametro o all'intestazione più vicina.
    --
    -- Ctrl+Enter continua a modificare il parametro senza uscire.
    --------------------------------------------------------

    if fx_param_list_view_mode == "visible_group" then
        return fx_param_list_visible_group_confirm_remove_and_exit()
    end

    if not e or e.kind ~= "fx_param_list_param" then
        exit_fx_param_list(true, false)
        speak("Confirmed. No parameter")
        return true
    end

    local target_track = e.track or current_track
    local target_fx_index = tonumber(e.fx_index) or -1
    local target_param_index = tonumber(e.param_index)

    local param_name = make_entry_label(e)

    if param_name == "" then
        param_name = "Parameter"
    end

    local was_visible = fx_param_is_tcp_visible(
        target_track,
        target_fx_index,
        target_param_index
    )

    if not was_visible then
        local ok = fx_add_param_to_tcp(
            target_track,
            target_fx_index,
            target_param_index
        )

        if not ok then
            speak("Could not add parameter")
            return true
        end
    end

    local count = fx_param_list_count_visible_group_params()

    exit_fx_param_list(true, false)

    local target_pos = f4_find_param_pos_for_fx_param(
        target_fx_index,
        target_param_index
    )

    if target_pos > 0 then
        grid_pos = target_pos
        refresh_window_title()
    end

    if count == 1 then
        speak("Added 1 visible parameter. " .. get_entry_spoken_label(get_current_entry()))
    else
        speak(
            "Added " ..
            tostring(count) ..
            " visible parameters. " ..
            get_entry_spoken_label(get_current_entry())
        )
    end

    return true
end

function fx_param_list_read_position()
    local e = get_current_entry()

    if not e then
        speak(fx_param_list_view_title() .. ". Empty")
        return true
    end

    local filter_part = ""

    if fx_param_list_filter_is_active() then
        filter_part = " Filter " .. fx_param_list_filter_query .. "."
    end

    speak(
        fx_param_list_view_title() ..
        "." ..
        filter_part ..
        " " ..
        tostring(grid_pos) ..
        " of " ..
        tostring(#grid_entries) ..
        ". " ..
        fx_param_list_entry_spoken_label(e)
    )

    return true
end

function fx_param_list_read_short()
    local e = get_current_entry()

    if not e then
        speak("Empty")
        return true
    end

    speak(fx_param_list_entry_spoken_label(e))

    return true
end

function fx_param_list_move_vertical(direction)
    direction = tonumber(direction) or 0

    if direction == 0 then
        return false
    end

    local count = grid_count()

    if count <= 0 then
        return grid_edge("fx-param-list-empty")
    end

    local new_pos = grid_pos + direction

    if new_pos < 1 then
        return grid_edge("fx-param-list-top")
    end

    if new_pos > count then
        return grid_edge("fx-param-list-bottom")
    end

    return grid_move_to_pos(new_pos, true, "vertical")
end

function fx_param_list_home()
    if grid_count() <= 0 then
        return grid_edge("fx-param-list-empty")
    end

    return grid_move_to_pos(1, true, "vertical")
end

function fx_param_list_end()
    if grid_count() <= 0 then
        return grid_edge("fx-param-list-empty")
    end

    return grid_move_to_pos(grid_count(), true, "vertical")
end

function fx_param_list_start_filter()
    cancel_pending_speech()
    clear_silent_edge()

    filter_return_mode = mode or "fx_param_list"
    filter_edit_buffer = tostring(fx_param_list_filter_query or "")
    filter_edit_cursor = #filter_edit_buffer + 1
    filter_edit_mode = true
    mode = "filter_edit"

    if filter_edit_buffer ~= "" then
        speak("Filter FX parameters. " .. filter_edit_buffer)
    else
        speak("Filter FX parameters")
    end

    return true
end

function fx_param_list_clear_filter_now()
    if not fx_param_list_filter_is_active() then
        speak("No filter")
        return true
    end

    fx_param_list_clear_filter()

    grid_pos = 1

    local ok = build_fx_param_list_grid()

    refresh_window_title()

    if ok then
        speak(
            "Filter cleared. " ..
            fx_param_list_entry_spoken_label(get_current_entry())
        )
    else
        speak("Filter cleared. Empty")
    end

    return true
end

function fx_param_list_toggle_filter()
    if fx_param_list_filter_is_active() then
        return fx_param_list_clear_filter_now()
    end

    return fx_param_list_start_filter()
end

function handle_fx_param_list_key(char)
    local is_ctrl = ctrl_down()
    local is_shift = shift_down()
    local is_alt = alt_down()

    if char == KEY_ESC then
        exit_fx_param_list(true, true)
        return true
    end

    if is_ctrl and is_shift and is_alt and char == KEY_F1 then
        speak_script_version()
        return true
    end

    if is_ctrl and not is_shift and not is_alt and char == KEY_UP then
        fx_param_list_switch_fx(-1)
        return true
    end

    if is_ctrl and not is_shift and not is_alt and char == KEY_DOWN then
        fx_param_list_switch_fx(1)
        return true
    end

    if not is_ctrl and not is_shift and not is_alt and char == KEY_F6 then
        ----------------------------------------------------
        -- Se siamo entrati in questa lista con F6 da F4,
        -- F6 deve tornare direttamente alla griglia F4.
        -- Dentro una normale lista parametri aperta da un
        -- FX header, F6 mantiene invece il vecchio toggle
        -- All parameters / Visible parameters.
        ----------------------------------------------------
        if fx_param_list_view_mode == "visible_group" and
           fx_param_list_fx_index < 0 and
           fx_param_list_return_section_id == SECTION_FX_PARAMS then
            exit_fx_param_list(true, true)
            return true
        end

        fx_param_list_toggle_view()
        return true
    end

    if is_ctrl and not is_shift and not is_alt and char == KEY_CTRL_F then
        fx_param_list_toggle_filter()
        return true
    end

    if char == KEY_TAB then
        fx_param_list_read_position()
        return true
    end

    if char == KEY_BACKSLASH then
        fx_param_list_read_short()
        return true
    end

    if is_ctrl and not is_shift and not is_alt and char == KEY_ENTER then
        fx_param_list_toggle_current_tcp()
        return true
    end

    if not is_ctrl and not is_shift and not is_alt and char == KEY_ENTER then
        fx_param_list_confirm()
        return true
    end

    if not is_ctrl and not is_shift and not is_alt and char == KEY_UP then
        fx_param_list_move_vertical(-1)
        return true
    end

    if not is_ctrl and not is_shift and not is_alt and char == KEY_DOWN then
        fx_param_list_move_vertical(1)
        return true
    end

    if not is_ctrl and not is_shift and not is_alt and char == KEY_PAGE_UP then
        fx_param_list_move_vertical(-10)
        return true
    end

    if not is_ctrl and not is_shift and not is_alt and char == KEY_PAGE_DOWN then
        fx_param_list_move_vertical(10)
        return true
    end

    if not is_ctrl and not is_shift and not is_alt and char == KEY_HOME then
        fx_param_list_home()
        return true
    end

    if not is_ctrl and not is_shift and not is_alt and char == KEY_END then
        fx_param_list_end()
        return true
    end

    if is_alt and not is_ctrl and not is_shift then
        if char == KEY_UP then
            current_entry_nudge_value(1, false)
            return true
        end

        if char == KEY_DOWN then
            current_entry_nudge_value(-1, false)
            return true
        end

        if char == KEY_PAGE_UP then
            current_entry_nudge_value(1, true)
            return true
        end

        if char == KEY_PAGE_DOWN then
            current_entry_nudge_value(-1, true)
            return true
        end

        if char == KEY_HOME then
            current_entry_set_max()
            return true
        end

        if char == KEY_END then
            current_entry_set_min()
            return true
        end
    end

    local c = safe_char(char)

    if c and not is_ctrl and not is_alt then
        c = c:lower()

        if c:match("[%w]") then
            clear_silent_edge()
            grid_jump_by_initial_in_fx_list(c)
            return true
        end
    end

    return true
end

------------------------------------------------------------
-- 4.5 - ENTER CORRENTE
------------------------------------------------------------


function f1_enter_column_is_folder_toggle(entry)
    if not entry or current_section_id ~= SECTION_TRACKS then
        return false
    end

    return entry.kind == "track_param" and
           (
               entry.id == "volume" or
               entry.id == "pan" or
               entry.id == "width"
           )
end

function f1_enter_column_is_button(entry)
    if not entry or current_section_id ~= SECTION_TRACKS then
        return false
    end

    return entry.kind == "track_param" and
           (
               entry.id == "mute" or
               entry.id == "solo" or
               entry.id == "phase"
           )
end

function f1_enter_toggle_own_folder(entry)
    entry = entry or get_current_entry()

    if not entry or not entry.track then
        return true
    end

    --------------------------------------------------------
    -- Legacy helper conservato per compatibilità interna.
    -- Enter su Volume / Pan / Width ora usa Value mode
    -- direttamente da current_entry_enter().
    --------------------------------------------------------

    if not track_is_folder(entry.track) then
        return true
    end

    cancel_pending_speech()
    clear_silent_edge()

    local wanted_col = grid_col_from_pos(grid_pos)
    local wanted_guid = get_track_guid(entry.track)

    set_current_track_pointer_only(entry.track)

    if toggle_track_folder_collapsed(entry.track) then
        build_current_grid()

        if wanted_guid ~= "" then
            for pos = 1, #grid_entries do
                local ge = grid_entries[pos]

                if ge and
                   ge.track and
                   get_track_guid(ge.track) == wanted_guid then

                    local row = grid_row_from_pos(pos)
                    grid_pos = grid_pos_from_row_col(row, wanted_col)
                    break
                end
            end
        end

        local here = get_current_entry()

        if here and here.track then
            set_current_track_pointer_only(here.track)
        end

        refresh_window_title()

        speak(
            get_track_plain_short_label(entry.track) ..
            " " ..
            track_folder_state_name(entry.track)
        )

        return true
    end

    speak("Folder failed")
    return true
end

function f1_enter_toggle_button(entry)
    entry = entry or get_current_entry()

    if not entry or not entry.track then
        return true
    end

    local old = current_entry_get_norm()

    if old == nil then
        speak("No value")
        return true
    end

    local new_value = old >= 0.5 and 0 or 1

    if current_entry_set_norm(new_value) then
        clear_silent_edge()
        speak_later(current_entry_clean_value_label())
        return true
    end

    speak("Value failed")
    return true
end

function current_entry_enter()
    local e = get_current_entry()

    if not e then
        speak("Empty")
        return false
    end

    --------------------------------------------------------
    -- F4:
    -- Enter su header FX apre la lista completa dei parametri.
    --------------------------------------------------------

    if current_section_id == SECTION_FX_PARAMS and
       e.kind == "fx_header" then

        return enter_fx_param_list_from_header(e)
    end

    --------------------------------------------------------
    -- F1:
    -- Enter è contestuale.
    -- - Volume / Pan / Track Width: entra direttamente in
    --   Value mode, come Ctrl+Shift+V in F1.
    -- - Mute / Solo / Phase invert: toggle diretto On / Off.
    -- - Le altre colonne F1 continuano con la loro logica enter
    --   specifica, per esempio Send count / Receive count / FX count.
    --------------------------------------------------------

    if current_section_id == SECTION_TRACKS and
       e.kind == "track_param" and
       e.track then

        if f1_enter_column_is_folder_toggle(e) then
            return enter_value_mode()
        end

        if f1_enter_column_is_button(e) then
            return f1_enter_toggle_button(e)
        end

        return true
    end

    --------------------------------------------------------
    -- F2 / F3:
    -- Enter su qualunque voce della colonna Send/Receive
    -- apre la routing gemella sulla traccia collegata:
    -- Send -> Receive della destinazione,
    -- Receive -> Send della sorgente.
    --
    -- La modifica del valore resta sui comandi dedicati:
    -- Alt+frecce, Ctrl+E, Ctrl+V / Value mode.
    --------------------------------------------------------

    if entry_is_send_receive(e) then
        return enter_send_receive_peer_track(e)
    end

    if current_entry_is_hardware_output(e) and e.id == "hardware_header" then
        speak(hardware_output_context_label(e))
        return true
    end

    if current_entry_is_rearoute(e) then
        if e.enter then
            return e.enter(e)
        end
    end

    --------------------------------------------------------
    -- Enter sui valori modificabili.
    --
    -- Regola:
    -- - bool = toggle diretto On / Off.
    -- - continuous / stepped / routing_pair / altri valori
    --   modificabili = entra in Value mode.
    --
    -- Così una combo non viene trattata come toggle.
    --------------------------------------------------------

    if current_entry_supports_value() then
        if current_entry_is_bool_value() then
            local old = current_entry_get_norm()

            if old == nil then
                speak("No value")
                return true
            end

            local new_value = old >= 0.5 and 0 or 1

            if current_entry_set_norm(new_value) then
                clear_silent_edge()
                speak_later(current_entry_clean_value_label())
                return true
            end

            speak("Value failed")
            return true
        end

        return enter_value_mode()
    end

    --------------------------------------------------------
    -- F2 / F3:
    -- Se sei su un parametro non modificabile di send/receive,
    -- legge semplicemente la voce corrente.
    --------------------------------------------------------

    if entry_is_send_receive(e) and e.kind ~= "send_header" then
        speak_current_entry()
        return true
    end

    --------------------------------------------------------
    -- Entry con azione specifica:
    -- Send count, Receive count, FX count, header send/receive,
    -- ecc.
    --------------------------------------------------------

    if type(e.enter) == "function" then
        local ok, result = pcall(e.enter, e)

        if ok then
            return result ~= false
        end

        speak("Action failed")
        return false
    end

    speak_current_entry()

    return true
end

function current_entry_activate()
    return current_entry_enter()
end

------------------------------------------------------------
-- 4.6 - READ CURRENT LINE
------------------------------------------------------------

function read_current_line()
    cancel_pending_speech()
    clear_silent_edge()

    if routing_pending_is_active() then
        speak_routing_pending_status()
        return true
    end

    if mode == "fx_param_list" or
       current_section_id == FX_PARAM_LIST_SECTION_ID then
        return fx_param_list_read_position()
    end

    speak_grid_position()

    return true
end

function read_current_short()
    cancel_pending_speech()
    clear_silent_edge()

    if routing_pending_is_active() then
        speak_routing_pending_status()
        return true
    end

    if mode == "fx_param_list" or
       current_section_id == FX_PARAM_LIST_SECTION_ID then
        return fx_param_list_read_short()
    end

    local e = get_current_entry()

    if not e then
        speak("Empty")
        return true
    end

    if current_section_id == SECTION_TRACKS then
        speak(get_entry_spoken_label(e))
        return true
    end

if entry_is_send_receive(e) then
    speak(current_entry_contextual_label())
    return true
end

if current_section_id == SECTION_FX_PARAMS and
   e.fx_index ~= nil then

    speak(fx_status_label_for_entry(e) .. get_entry_spoken_label(e))
    return true
end

speak(get_entry_spoken_label(e))

return true
end

------------------------------------------------------------
-- 4.7 - VERSIONE SCRIPT
--
-- Ctrl+Alt+Shift+F1:
-- shortcut globale interno allo script.
------------------------------------------------------------

function read_script_header_field(field_name)
    local info = debug.getinfo(1, "S")
    local source = info and info.source or ""

    if source:sub(1, 1) == "@" then
        source = source:sub(2)
    end

    if source == "" then
        return ""
    end

    local file = io.open(source, "r")

    if not file then
        return ""
    end

    local wanted = "^%s*%-%-%s*@" .. field_name .. "%s+(.+)%s*$"
    local result = ""

    for i = 1, 20 do
        local line = file:read("*l")

        if not line then
            break
        end

        local value = line:match(wanted)

        if value then
            result = clean_one_line(value)
            break
        end
    end

    file:close()

    return result
end

function speak_script_version()
    cancel_pending_speech()
    clear_silent_edge()

    local description = read_script_header_field("description")
    local version = read_script_header_field("version")
    local author = read_script_header_field("author")

    local parts = {}

    if description ~= "" then
        parts[#parts + 1] = description
    end

    if version ~= "" then
        parts[#parts + 1] = version
    end

    if author ~= "" then
        parts[#parts + 1] = author
    end

    if #parts <= 0 then
        speak("Script information not found")
        return true
    end

    speak(table.concat(parts, ". "))

    return true
end

------------------------------------------------------------
-- 4.8 - INIT
------------------------------------------------------------

function init_script()
    track_memory_load_session()
    cursor_memory_load_session()
    title_detail_load_session()
    floating_cc_load_session()
    track_txt_load()

    if type(track_fixed_cc_load_enabled_session) == "function" then
        track_fixed_cc_load_enabled_session()
    end

    if not select_first_track() then
        speak("No tracks")
        return false
    end

    --------------------------------------------------------
    -- All'ingresso dello script:
    -- - usiamo la traccia selezionata / last touched solo come
    --   posizione iniziale del cursore interno;
    -- - poi puliamo la selezione reale delle tracce;
    -- - la memoria cursore ripristina il campo logico dove
    --   possibile. Se la traccia è diversa, mantiene la
    --   colonna / riga equivalente, per esempio Pan resta Pan.
    --------------------------------------------------------

    clear_track_selection_silent()

    local wanted_section = SECTION_TRACKS

    if cursor_memory_is_enabled() then
        wanted_section = clean_one_line(cursor_memory_last_section_id or "")

        if wanted_section == "" then
            wanted_section = SECTION_TRACKS
        end
    end

    current_section_id = wanted_section
    current_section_key = cursor_memory_section_id_to_key(wanted_section)
    mode = "grid"

    cursor_memory_prepare_section_before_build(current_section_id, true)

    local ok = build_current_grid()

    if ok then
        cursor_memory_restore_after_build(current_section_id, true)
    end

    if not ok or #grid_entries <= 0 then
        current_section_key = KEY_F1
        current_section_id = SECTION_TRACKS
        mode = "grid"
        cursor_memory_prepare_section_before_build(current_section_id, true)

        if not build_current_grid() then
            speak("No tracks")
            return false
        end

        cursor_memory_restore_after_build(current_section_id, true)
    end

    refresh_window_title_for_startup()
    speak_after_startup_window_opens(startup_current_entry_message())

    cursor_memory_save_current()

    if reaper.atexit then
        reaper.atexit(transport_space_release_intercept)
    end

    return true
end

------------------------------------------------------------
-- 4.9 - STATO VALUE MODE / NUMERIC EDIT / FILTRO
------------------------------------------------------------

value_return_mode = "grid"

edit_mode = false
edit_buffer = ""
edit_cursor = 1
edit_started = false
numeric_edit_fresh = false
numeric_return_mode = "grid"

filter_edit_mode = false
filter_edit_buffer = ""
filter_edit_cursor = 1
filter_return_mode = "grid"

------------------------------------------------------------
-- 4.10 - TEXT / NUMERIC EDIT HELPERS
------------------------------------------------------------

function text_speak_char_at_cursor(buffer, cursor)
    buffer = tostring(buffer or "")
    cursor = tonumber(cursor) or 1

    local len = #buffer

    if len <= 0 then
        speak("Empty")
        return
    end

    cursor = clamp_int(cursor, 1, len)

    speak(buffer:sub(cursor, cursor))
end

function text_move_cursor_left_char(buffer, cursor)
    buffer = tostring(buffer or "")
    cursor = tonumber(cursor) or 1

    local len = #buffer

    if len <= 0 then
        return 1, false
    end

    if cursor > len then
        return len, true
    end

    cursor = clamp_int(cursor, 1, len)

    if cursor <= 1 then
        return 1, false
    end

    return cursor - 1, true
end

function text_move_cursor_right_char(buffer, cursor)
    buffer = tostring(buffer or "")
    cursor = tonumber(cursor) or 1

    local len = #buffer

    if len <= 0 then
        return 1, false
    end

    cursor = clamp_int(cursor, 1, len)

    if cursor >= len then
        return len, false
    end

    return cursor + 1, true
end

function numeric_buffer_can_accept_char_at(c, buffer, cursor)
    c = tostring(c or "")
    buffer = tostring(buffer or "")
    cursor = tonumber(cursor) or 1

    if c:match("%d") then
        return true
    end

    if c == "." then
        return not buffer:find("%.", 1, false)
    end

    if c == "-" then
        return cursor <= 1 and not buffer:find("%-", 1, false)
    end

    return false
end

function insert_numeric_char_at_cursor(c)
    if not edit_started then
        edit_buffer = ""
        edit_cursor = 1
        edit_started = true
    end

    local left = edit_buffer:sub(1, edit_cursor - 1)
    local right = edit_buffer:sub(edit_cursor)

    edit_buffer = left .. c .. right
    edit_cursor = edit_cursor + 1
end

function delete_numeric_char_before_cursor()
    if edit_cursor <= 1 or #edit_buffer == 0 then
        speak("Empty")
        return
    end

    edit_started = true

    local removed = edit_buffer:sub(edit_cursor - 1, edit_cursor - 1)
    local left = edit_buffer:sub(1, edit_cursor - 2)
    local right = edit_buffer:sub(edit_cursor)

    edit_buffer = left .. right
    edit_cursor = edit_cursor - 1

    speak(removed)
end

function delete_numeric_char_at_cursor()
    if edit_cursor > #edit_buffer or #edit_buffer == 0 then
        speak("Empty")
        return
    end

    edit_started = true

    local removed = edit_buffer:sub(edit_cursor, edit_cursor)
    local left = edit_buffer:sub(1, edit_cursor - 1)
    local right = edit_buffer:sub(edit_cursor + 1)

    edit_buffer = left .. right

    speak(removed)
end

------------------------------------------------------------
-- 4.10.1 - TEXT EDIT HELPERS PER FILTRO
------------------------------------------------------------

function text_buffer_insert_char(buffer, cursor, c)
    buffer = tostring(buffer or "")
    cursor = tonumber(cursor) or 1
    c = tostring(c or "")

    cursor = clamp_int(cursor, 1, #buffer + 1)

    local left = buffer:sub(1, cursor - 1)
    local right = buffer:sub(cursor)

    buffer = left .. c .. right
    cursor = cursor + 1

    return buffer, cursor
end

function text_buffer_delete_before_cursor(buffer, cursor)
    buffer = tostring(buffer or "")
    cursor = tonumber(cursor) or 1

    if cursor <= 1 or #buffer == 0 then
        return buffer, cursor, ""
    end

    cursor = clamp_int(cursor, 1, #buffer + 1)

    local removed = buffer:sub(cursor - 1, cursor - 1)
    local left = buffer:sub(1, cursor - 2)
    local right = buffer:sub(cursor)

    buffer = left .. right
    cursor = cursor - 1

    return buffer, cursor, removed
end

function text_buffer_delete_at_cursor(buffer, cursor)
    buffer = tostring(buffer or "")
    cursor = tonumber(cursor) or 1

    if #buffer == 0 or cursor > #buffer then
        return buffer, cursor, ""
    end

    cursor = clamp_int(cursor, 1, #buffer)

    local removed = buffer:sub(cursor, cursor)
    local left = buffer:sub(1, cursor - 1)
    local right = buffer:sub(cursor + 1)

    buffer = left .. right

    return buffer, cursor, removed
end

------------------------------------------------------------
-- 4.11 - VALUE MODE
------------------------------------------------------------

function announce_value_mode()
    local e = get_current_entry()

    if not e then
        speak("Value. Empty")
        return
    end

    speak("Value. " .. current_entry_clean_value_label())
end

function enter_value_mode()
    cancel_pending_speech()
    clear_silent_edge()

    if edit_mode then
        speak("Close numeric edit first")
        return false
    end

    if filter_edit_mode then
        speak("Close filter first")
        return false
    end

    if not current_entry_supports_value() then
        speak("No value")
        return false
    end

    value_return_mode = mode or "grid"
    mode = "value"

    announce_value_mode()

    return true
end

function exit_value_mode()
    mode = value_return_mode or "grid"
    value_return_mode = "grid"

    clear_silent_edge()

    speak(current_entry_clean_value_label())

    return true
end

function toggle_value_mode()
    if mode == "value" then
        return exit_value_mode()
    end

    return enter_value_mode()
end

function handle_value_mode_key(char)
    local is_ctrl = ctrl_down()
    local is_shift = shift_down()
    local is_alt = alt_down()

    if char == KEY_ESC then
        exit_script()
        return true
    end

    if is_ctrl and is_shift and is_alt and char == KEY_F1 then
        speak_script_version()
        return true
    end

--------------------------------------------------------
-- Uscita da Value mode.
--
-- Regola:
-- - in F1, Ctrl+V è riservato a Paste tracks with routing,
--   quindi Value mode si chiude con Ctrl+Shift+V.
-- - fuori da F1, Ctrl+V resta il comando normale per uscire
--   da Value mode.
--------------------------------------------------------

if is_ctrl and not is_alt and char == KEY_CTRL_V then
    if current_section_id == SECTION_TRACKS then
        if is_shift then
            exit_value_mode()
            return true
        end

        return true
    end

    if not is_shift then
        exit_value_mode()
        return true
    end
end    

    if is_ctrl and not is_shift and not is_alt and char == KEY_CTRL_E then
        exit_value_mode()
        start_numeric_edit()
        return true
    end

    --------------------------------------------------------
    -- Step scale in Value mode.
    -- Alt+Left  = step più fine.
    -- Alt+Right = step più grande.
    --
    -- F11 / F12 non sono più usati qui:
    -- restano liberi per funzioni future.
    --------------------------------------------------------

    if is_alt and not is_ctrl and not is_shift and char == KEY_LEFT then
        change_step_scale(-1)
        return true
    end

    if is_alt and not is_ctrl and not is_shift and char == KEY_RIGHT then
        change_step_scale(1)
        return true
    end    

    if char == KEY_ENTER then
        exit_value_mode()
        return true
    end

    if char == KEY_TAB or char == KEY_BACKSLASH then
        announce_value_mode()
        return true
    end

    if char == KEY_UP then
        current_entry_nudge_value(1, false)
        return true
    end

    if char == KEY_DOWN then
        current_entry_nudge_value(-1, false)
        return true
    end

    if char == KEY_PAGE_UP then
        current_entry_nudge_value(1, true)
        return true
    end

    if char == KEY_PAGE_DOWN then
        current_entry_nudge_value(-1, true)
        return true
    end

    if char == KEY_HOME then
        current_entry_set_min()
        return true
    end

    if char == KEY_END then
        current_entry_set_max()
        return true
    end

    return true
end

------------------------------------------------------------
-- 4.12 - EDIT NUMERICO GENERICO
------------------------------------------------------------

function start_numeric_edit()
    cancel_pending_speech()
    clear_silent_edge()

    if filter_edit_mode then
        speak("Close filter first")
        return false
    end

    if not current_entry_supports_value() then
        speak("No value")
        return false
    end

    local value = current_entry_get_norm()

    if value == nil then
        speak("No value")
        return false
    end

    numeric_return_mode = mode or "grid"

    edit_buffer = tostring(value)
    edit_cursor = #edit_buffer + 1
    edit_started = false
    numeric_edit_fresh = true
    edit_mode = true
    mode = "numeric_edit"

    local e = get_current_entry()
    local name = make_entry_label(e)

    if name == "" then
        name = "Value"
    end

    if current_section_id == SECTION_TRACKS and e and e.track then
        speak(
            "Edit " ..
            get_track_folder_spoken_label(e.track) ..
            ". " ..
            name ..
            " " ..
            edit_buffer
        )
    else
        speak("Edit " .. name .. " " .. edit_buffer)
    end

    return true
end

function finish_numeric_edit()
    local typed = tonumber(edit_buffer)

    if typed == nil then
        speak("Invalid value")
        return false
    end

    typed = clamp01(typed)

    local ok = current_entry_set_norm(typed)

    edit_mode = false
    edit_buffer = ""
    edit_cursor = 1
    edit_started = false
    numeric_edit_fresh = false

    mode = numeric_return_mode or "grid"
    numeric_return_mode = "grid"

    clear_silent_edge()

    if ok then
        speak(current_entry_clean_value_label())
        return true
    end

    speak("Value failed")
    return false
end

function cancel_numeric_edit()
    edit_mode = false
    edit_buffer = ""
    edit_cursor = 1
    edit_started = false
    numeric_edit_fresh = false

    mode = numeric_return_mode or "grid"
    numeric_return_mode = "grid"

    clear_silent_edge()

    speak(current_entry_clean_value_label())

    return true
end

function speak_numeric_buffer()
    local e = get_current_entry()
    local name = make_entry_label(e)
    local content = edit_buffer ~= "" and edit_buffer or "Empty"

    if name == "" then
        name = "Value"
    end

    if current_section_id == SECTION_TRACKS and e and e.track then
        speak(
            "Edit " ..
            get_track_folder_spoken_label(e.track) ..
            ". " ..
            name ..
            " " ..
            content
        )
        return
    end

    speak("Edit " .. name .. " " .. content)
end


------------------------------------------------------------
-- 4.10A - EDIT ALIAS PARAMETRO FX F4
------------------------------------------------------------

function current_entry_is_f4_fx_param(entry)
    entry = entry or get_current_entry()

    return current_section_id == SECTION_FX_PARAMS and
           entry ~= nil and
           entry.kind == "fx_param" and
           entry.track ~= nil and
           tonumber(entry.fx_index) ~= nil and
           tonumber(entry.param_index) ~= nil
end

function start_fx_alias_edit()
    local entry = get_current_entry()

    if not current_entry_is_f4_fx_param(entry) then
        speak("No FX parameter")
        return true
    end

    cancel_pending_speech()
    clear_silent_edge()

    fx_alias_edit_track = entry.track
    fx_alias_edit_fx_index = tonumber(entry.fx_index) or -1
    fx_alias_edit_param_index = tonumber(entry.param_index) or -1

    local alias = ""

    if type(fx_get_param_alias) == "function" then
        alias = fx_get_param_alias(
            fx_alias_edit_track,
            fx_alias_edit_fx_index,
            fx_alias_edit_param_index
        )
    end

    local original_name = ""

    if reaper.TrackFX_GetParamName then
        local ok, name = reaper.TrackFX_GetParamName(
            fx_alias_edit_track,
            fx_alias_edit_fx_index,
            fx_alias_edit_param_index,
            ""
        )

        if ok then
            original_name = clean_one_line(name or "")
        end
    end

    if original_name == "" then
        original_name = fx_get_param_name(
            fx_alias_edit_track,
            fx_alias_edit_fx_index,
            fx_alias_edit_param_index
        )
    end

    fx_alias_edit_original_name = original_name
    fx_alias_edit_buffer = alias
    fx_alias_edit_cursor = #fx_alias_edit_buffer + 1
    fx_alias_edit_return_mode = mode or "grid"
    fx_alias_edit_mode = true
    mode = "fx_alias_edit"

    if fx_alias_edit_buffer ~= "" then
        speak("Alias. " .. fx_alias_edit_buffer)
    else
        speak("Alias. " .. fx_alias_edit_original_name)
    end

    return true
end

function apply_fx_alias_edit()
    if not fx_alias_edit_mode then
        return false
    end

    local alias = clean_one_line(fx_alias_edit_buffer or "")

    local ok = fx_set_param_alias(
        fx_alias_edit_track,
        fx_alias_edit_fx_index,
        fx_alias_edit_param_index,
        alias
    )

    fx_alias_edit_mode = false
    fx_alias_edit_buffer = ""
    fx_alias_edit_cursor = 1
    mode = fx_alias_edit_return_mode or "grid"
    fx_alias_edit_return_mode = "grid"

    if current_section_id == SECTION_FX_PARAMS then
        build_current_grid()

        for pos = 1, #grid_entries do
            local e = grid_entries[pos]

            if e and
               e.kind == "fx_param" and
               e.track == fx_alias_edit_track and
               tonumber(e.fx_index) == tonumber(fx_alias_edit_fx_index) and
               tonumber(e.param_index) == tonumber(fx_alias_edit_param_index) then

                grid_pos = pos
                break
            end
        end
    end

    refresh_window_title()
    clear_silent_edge()

    if not ok then
        speak("Alias failed")
        return true
    end

    if alias == "" then
        speak("Alias cleared. " .. fx_alias_edit_original_name)
    else
        speak("Alias saved. " .. alias)
    end

    return true
end

function cancel_fx_alias_edit()
    fx_alias_edit_mode = false
    fx_alias_edit_buffer = ""
    fx_alias_edit_cursor = 1
    mode = fx_alias_edit_return_mode or "grid"
    fx_alias_edit_return_mode = "grid"

    clear_silent_edge()
    speak("Alias cancelled")

    return true
end

function speak_fx_alias_buffer()
    local content = clean_one_line(fx_alias_edit_buffer or "")

    if content == "" then
        speak("Alias empty")
    else
        speak("Alias " .. content)
    end
end

function handle_fx_alias_edit_key(char)
    local is_ctrl = ctrl_down()
    local is_shift = shift_down()
    local is_alt = alt_down()

    if char == KEY_ESC then
        return cancel_fx_alias_edit()
    end

    if not is_ctrl and not is_shift and not is_alt and char == KEY_ENTER then
        return apply_fx_alias_edit()
    end

    if char == KEY_BACKSPACE or char == KEY_BACKSPACE_2 then
        local removed = ""

        fx_alias_edit_buffer, fx_alias_edit_cursor, removed =
            text_buffer_delete_before_cursor(
                fx_alias_edit_buffer,
                fx_alias_edit_cursor
            )

        if removed ~= "" then
            speak(removed)
        else
            speak("Empty")
        end

        return true
    end

    if char == KEY_DELETE then
        if fx_alias_edit_buffer == "" then
            speak("Empty")
            return true
        end

        local removed = ""

        fx_alias_edit_buffer, fx_alias_edit_cursor, removed =
            text_buffer_delete_at_cursor(
                fx_alias_edit_buffer,
                fx_alias_edit_cursor
            )

        if removed ~= "" then
            speak(removed)
        else
            speak("Empty")
        end

        return true
    end

    if is_ctrl and not is_shift and not is_alt and char == KEY_LEFT then
        if #fx_alias_edit_buffer == 0 then
            speak("Empty")
            return true
        end

        local changed = false

        fx_alias_edit_cursor, changed =
            text_move_cursor_left_char(
                fx_alias_edit_buffer,
                fx_alias_edit_cursor
            )

        if changed then
            text_speak_char_at_cursor(
                fx_alias_edit_buffer,
                fx_alias_edit_cursor
            )
        end

        return true
    end

    if not is_ctrl and not is_shift and not is_alt and char == KEY_LEFT then
        if #fx_alias_edit_buffer == 0 then
            speak("Empty")
            return true
        end

        local changed = false

        fx_alias_edit_cursor, changed =
            text_move_cursor_left_char(
                fx_alias_edit_buffer,
                fx_alias_edit_cursor
            )

        if changed then
            text_speak_char_at_cursor(
                fx_alias_edit_buffer,
                fx_alias_edit_cursor
            )
        end

        return true
    end

    if is_ctrl and not is_shift and not is_alt and char == KEY_RIGHT then
        if #fx_alias_edit_buffer == 0 then
            speak("Empty")
            return true
        end

        local changed = false

        fx_alias_edit_cursor, changed =
            text_move_cursor_right_char(
                fx_alias_edit_buffer,
                fx_alias_edit_cursor
            )

        if changed then
            text_speak_char_at_cursor(
                fx_alias_edit_buffer,
                fx_alias_edit_cursor
            )
        end

        return true
    end

    if not is_ctrl and not is_shift and not is_alt and char == KEY_RIGHT then
        if #fx_alias_edit_buffer == 0 then
            speak("Empty")
            return true
        end

        local changed = false

        fx_alias_edit_cursor, changed =
            text_move_cursor_right_char(
                fx_alias_edit_buffer,
                fx_alias_edit_cursor
            )

        if changed then
            text_speak_char_at_cursor(
                fx_alias_edit_buffer,
                fx_alias_edit_cursor
            )
        end

        return true
    end

    if char == KEY_HOME then
        if #fx_alias_edit_buffer == 0 then
            fx_alias_edit_cursor = 1
            speak("Empty")
            return true
        end

        fx_alias_edit_cursor = 1
        text_speak_char_at_cursor(
            fx_alias_edit_buffer,
            fx_alias_edit_cursor
        )
        return true
    end

    if char == KEY_END then
        if #fx_alias_edit_buffer == 0 then
            fx_alias_edit_cursor = 1
            speak("Empty")
            return true
        end

        fx_alias_edit_cursor = #fx_alias_edit_buffer
        text_speak_char_at_cursor(
            fx_alias_edit_buffer,
            fx_alias_edit_cursor
        )
        return true
    end

    if char == KEY_TAB then
        speak_fx_alias_buffer()
        return true
    end

    local c = safe_char(char)

    if not is_ctrl and not is_alt and c then
        fx_alias_edit_buffer, fx_alias_edit_cursor =
            text_buffer_insert_char(
                fx_alias_edit_buffer,
                fx_alias_edit_cursor,
                c
            )

        speak(c)
        return true
    end

    return true
end


------------------------------------------------------------
-- 4.W - TRACK AUTOMATION F1
--
-- Ctrl+Shift+A in F1:
-- - Volume  -> action nativa 40406.
-- - Pan     -> action nativa 40407.
-- - Mute    -> action nativa 40867.
-- - Width   -> gestione diretta del chunk WIDTHENV2, senza azioni
--              REAPER che possono spostare il focus fuori dallo script.
--
-- Gli altri parametri F1 rispondono "No automation".
------------------------------------------------------------

TRACK_AUTO_ACTIONS = {
    volume = 40406,
    pan    = 40407,
    mute   = 40867
}

TRACK_AUTO_ENV_NAMES = {
    volume = "Volume",
    pan    = "Pan",
    width  = "Width",
    mute   = "Mute"
}

TRACK_AUTO_CHUNK_TAGS = {
    volume = {"<VOLENV2", "<VOLENV"},
    pan    = {"<PANENV2", "<PANENV"},
    width  = {"<WIDTHENV2", "<WIDTHENV"},
    mute   = {"<MUTEENV2", "<MUTEENV"}
}

function f1_track_auto_id_is_supported(id)
    id = clean_one_line(id or "")

    return id == "volume" or
           id == "pan" or
           id == "width" or
           id == "mute"
end

function f1_track_auto_make_key(track, id)
    local guid = get_track_guid(track)
    id = clean_one_line(id or "")

    if guid == "" or id == "" then
        return ""
    end

    return guid .. ":" .. id
end

function f1_track_auto_get_visible_override(track, id)
    return nil
end


function f1_track_auto_set_visible_override(track, id, visible)
    return true
end


function f1_track_auto_get_envelope(track, id)
    if not track or not reaper.GetTrackEnvelopeByName then
        return nil
    end

    local name = TRACK_AUTO_ENV_NAMES[clean_one_line(id or "")]

    if not name then
        return nil
    end

    return reaper.GetTrackEnvelopeByName(track, name)
end

function f1_track_auto_lua_pattern_escape(text)
    text = tostring(text or "")
    return text:gsub("([%(%)%%%.%+%-%*%?%[%]%^%$])", "%%%1")
end

function f1_track_auto_get_track_chunk(track)
    if not track or not reaper.GetTrackStateChunk then
        return ""
    end

    local ok, chunk = reaper.GetTrackStateChunk(track, "", false)

    if not ok or not chunk then
        return ""
    end

    return tostring(chunk or "")
end

function f1_track_auto_chunk_block(track, id)
    if not f1_track_auto_id_is_supported(id) then
        return ""
    end

    local chunk = f1_track_auto_get_track_chunk(track)

    if chunk == "" then
        return ""
    end

    local tags = TRACK_AUTO_CHUNK_TAGS[clean_one_line(id or "")]

    if type(tags) ~= "table" then
        return ""
    end

    for i = 1, #tags do
        local tag = tags[i]
        local pat = "(" .. f1_track_auto_lua_pattern_escape(tag) .. "[^\n]*\n.-\n>)"
        local block = chunk:match(pat)

        if block and block ~= "" then
            return block
        end
    end

    return ""
end

function f1_track_auto_chunk_envelope_is_visible(track, id)
    local block = f1_track_auto_chunk_block(track, id)

    if block == "" then
        return nil
    end

    return auto_chunk_block_is_active(block)
end


function f1_track_auto_envelope_is_visible(track, id)
    if not f1_track_auto_id_is_supported(id) then
        return false
    end

    local chunk_active = f1_track_auto_chunk_envelope_is_visible(track, id)

    if chunk_active ~= nil then
        return chunk_active == true
    end

    local env = f1_track_auto_get_envelope(track, id)

    if env then
        return auto_envelope_is_active(env)
    end

    return false
end


function f1_track_auto_suffix(track, id)
    if f1_track_auto_envelope_is_visible(track, id) then
        return "Auto"
    end

    return ""
end

function append_f1_track_auto_suffix(value, track, id)
    value = clean_one_line(value or "")

    local suffix = f1_track_auto_suffix(track, id)

    if suffix ~= "" then
        if value ~= "" then
            return value .. ". " .. suffix
        end

        return suffix
    end

    return value
end

function f1_track_auto_make_guid()
    if reaper.genGuid then
        local ok, guid = pcall(reaper.genGuid, "")

        if ok and guid and guid ~= "" then
            return clean_one_line(guid)
        end
    end

    local seed = tostring(reaper.time_precise and reaper.time_precise() or os.time()) .. tostring(math.random())
    local hex = ""

    for i = 1, 32 do
        local n = (seed:byte(((i - 1) % #seed) + 1) or i) + i * 17
        hex = hex .. string.format("%x", n % 16)
    end

    return "{" ..
        hex:sub(1, 8) .. "-" ..
        hex:sub(9, 12) .. "-" ..
        hex:sub(13, 16) .. "-" ..
        hex:sub(17, 20) .. "-" ..
        hex:sub(21, 32) .. "}"
end

function f1_track_auto_replace_width_block_visibility(block, visible)
    if not block or block == "" then
        return "", false
    end

    visible = visible == true

    local lines = chunk_split_lines(block)

    if #lines <= 0 then
        return block, false
    end

    local changed = auto_chunk_lines_set_active_visible(lines, 1, #lines, visible)

    if not changed then
        return block, false
    end

    return table.concat(lines, "\n"), true
end


function f1_track_auto_find_width_block_in_chunk(chunk)
    chunk = tostring(chunk or "")

    if chunk == "" then
        return nil, nil, ""
    end

    local tags = {"<WIDTHENV2", "<WIDTHENV"}

    for i = 1, #tags do
        local tag = tags[i]
        local escaped = f1_track_auto_lua_pattern_escape(tag)
        local block_start, block_end, block =
            chunk:find("(" .. escaped .. "[^\n]*\n.-\n>)")

        if block and block ~= "" then
            return block_start, block_end, block
        end
    end

    return nil, nil, ""
end

function f1_track_auto_insert_env_before_track_end(chunk, env_chunk)
    chunk = tostring(chunk or "")
    env_chunk = tostring(env_chunk or "")

    if chunk == "" or env_chunk == "" then
        return chunk, false
    end

    --------------------------------------------------------
    -- La chiusura vera del track chunk è l'ultima riga ">".
    -- La vecchia versione cercava "\n>" in modo troppo fragile
    -- e poteva appendere l'envelope fuori dal blocco TRACK.
    -- Qui invece inseriamo WIDTHENV2 subito prima dell'ultimo
    -- delimitatore del track chunk.
    --------------------------------------------------------

    local new_chunk, n = chunk:gsub("\n>%s*$", "\n" .. env_chunk .. ">", 1)

    if n and n > 0 and new_chunk ~= chunk then
        return new_chunk, true
    end

    return chunk .. "\n" .. env_chunk, true
end


function f1_track_auto_primary_chunk_tag(id)
    id = clean_one_line(id or "")

    if id == "volume" then
        return "<VOLENV2"
    end

    if id == "pan" then
        return "<PANENV2"
    end

    if id == "width" then
        return "<WIDTHENV2"
    end

    if id == "mute" then
        return "<MUTEENV2"
    end

    return ""
end

function f1_track_auto_current_value_for_point(track, id)
    id = clean_one_line(id or "")

    if not track or not reaper.GetMediaTrackInfo_Value then
        return 0
    end

    if id == "volume" then
        return tonumber(reaper.GetMediaTrackInfo_Value(track, "D_VOL")) or 1
    end

    if id == "pan" then
        return tonumber(reaper.GetMediaTrackInfo_Value(track, "D_PAN")) or 0
    end

    if id == "width" then
        return tonumber(reaper.GetMediaTrackInfo_Value(track, "D_WIDTH")) or 1
    end

    if id == "mute" then
        return tonumber(reaper.GetMediaTrackInfo_Value(track, "B_MUTE")) or 0
    end

    return 0
end

function f1_track_auto_make_env_chunk(track, id, active)
    local tag = f1_track_auto_primary_chunk_tag(id)

    if tag == "" then
        return ""
    end

    local point_value = f1_track_auto_current_value_for_point(track, id)

    return table.concat({
        tag,
        "EGUID " .. f1_track_auto_make_guid(),
        active and "ACT 1 -1" or "ACT 0 -1",
        active and "VIS 1 1 1.0" or "VIS 0 1 1.0",
        "LANEHEIGHT 0 0",
        "ARM 0",
        "DEFSHAPE 0 -1 -1",
        string.format("PT 0 %.12f 0", point_value),
        ">"
    }, "\n") .. "\n"
end

function f1_track_auto_find_block_in_chunk(chunk, id)
    chunk = tostring(chunk or "")

    if chunk == "" then
        return nil, nil, ""
    end

    local tags = TRACK_AUTO_CHUNK_TAGS[clean_one_line(id or "")]

    if type(tags) ~= "table" then
        return nil, nil, ""
    end

    for i = 1, #tags do
        local tag = tags[i]
        local escaped = f1_track_auto_lua_pattern_escape(tag)
        local block_start, block_end, block =
            chunk:find("(" .. escaped .. "[^\n]*\n.-\n>)")

        if block and block ~= "" then
            return block_start, block_end, block
        end
    end

    return nil, nil, ""
end

function f1_track_auto_set_env_auto_in_chunk(track, id, active)
    if not track or
       not f1_track_auto_id_is_supported(id) or
       not reaper.GetTrackStateChunk or
       not reaper.SetTrackStateChunk then
        return false
    end

    local ok, chunk = reaper.GetTrackStateChunk(track, "", false)

    if not ok or not chunk or chunk == "" then
        return false
    end

    active = active == true

    local block_start, block_end, block =
        f1_track_auto_find_block_in_chunk(chunk, id)

    local changed = false

    if block and block ~= "" then
        local lines = chunk_split_lines(block)
        changed = auto_chunk_lines_set_active_visible(lines, 1, #lines, active)

        if changed then
            local new_block = table.concat(lines, "\n")
            chunk = chunk:sub(1, block_start - 1) .. new_block .. chunk:sub(block_end + 1)
        end
    else
        local env_chunk = f1_track_auto_make_env_chunk(track, id, active)
        chunk, changed = f1_track_auto_insert_env_before_track_end(chunk, env_chunk)
    end

    if not changed then
        return true
    end

    local set_ok = reaper.SetTrackStateChunk(track, chunk, false)

    if not set_ok then
        return false
    end

    if reaper.TrackList_AdjustWindows then
        reaper.TrackList_AdjustWindows(false)
    end

    if reaper.UpdateTimeline then
        reaper.UpdateTimeline()
    end

    if reaper.UpdateArrange then
        reaper.UpdateArrange()
    end

    if reaper.MarkProjectDirty then
        reaper.MarkProjectDirty(0)
    end

    return true
end


function f1_track_auto_set_width_env_visible_in_chunk(track, visible)
    return f1_track_auto_set_env_auto_in_chunk(track, "width", visible == true)
end


function f1_track_auto_touch_width_for_last_touched(track)
    if not track or
       not reaper.GetMediaTrackInfo_Value or
       not reaper.SetMediaTrackInfo_Value then
        return false
    end

    local old_width = tonumber(reaper.GetMediaTrackInfo_Value(track, "D_WIDTH")) or 1
    local touch_width = old_width + 0.000001

    if touch_width > 2 then
        touch_width = old_width - 0.000001
    end

    if touch_width < 0 then
        touch_width = old_width + 0.000001
    end

    --------------------------------------------------------
    -- Tentativo stile "last touched": tocchiamo il controllo
    -- Track Width con un micro-movimento e poi lo rimettiamo
    -- subito al valore originale. L'obiettivo è farlo diventare
    -- il controllo/parametro più recente per l'azione 41142.
    --------------------------------------------------------

    reaper.SetMediaTrackInfo_Value(track, "D_WIDTH", touch_width)
    reaper.SetMediaTrackInfo_Value(track, "D_WIDTH", old_width)

    return true
end

function f1_track_auto_read_real_visibility(track, id)
    local chunk_active = f1_track_auto_chunk_envelope_is_visible(track, id)

    if chunk_active ~= nil then
        return chunk_active == true
    end

    local env = f1_track_auto_get_envelope(track, id)

    if env then
        return auto_envelope_is_active(env)
    end

    return false
end


function f1_track_auto_envelope_pointer_is_visible(env)
    if not env then
        return nil
    end

    return auto_envelope_is_active(env)
end


function f1_track_auto_set_envelope_pointer_visible(env, visible)
    return auto_envelope_set_active_visible(env, visible == true)
end


function f1_track_auto_select_width_envelope(track)
    if not track or not reaper.Main_OnCommand then
        return nil
    end

    local snapshot = track_selection_snapshot()

    reaper.SetOnlyTrackSelected(track)

    if reaper.SetCursorContext then
        reaper.SetCursorContext(0, nil)
    end

    --------------------------------------------------------
    -- 41870: Track: Select width envelope.
    -- Questa è la strada corretta per Width: non è un FX
    -- parameter last-touched, quindi 41142 non lo aggancia.
    --------------------------------------------------------

    reaper.Main_OnCommand(CMD_SELECT_TRACK_WIDTH_ENVELOPE, 0)

    local env = nil

    if reaper.GetSelectedEnvelope then
        env = reaper.GetSelectedEnvelope(0)
    end

    track_selection_restore(snapshot)

    return env
end

function f1_track_auto_toggle_width(track)
    if not track then
        return false, false
    end

    local before_active = f1_track_auto_read_real_visibility(track, "width")
    local target_active = not before_active

    reaper.Undo_BeginBlock()

    local ok = f1_track_auto_set_env_auto_in_chunk(track, "width", target_active)

    reaper.Undo_EndBlock("Toggle track width automation envelope", -1)

    f1_track_auto_visible_override[f1_track_auto_make_key(track, "width")] = nil

    local after_active = f1_track_auto_read_real_visibility(track, "width")

    if ok and after_active == target_active then
        return true, after_active == true
    end

    return false, after_active == true
end


function f1_track_auto_toggle_native(track, id)
    if not track or not f1_track_auto_id_is_supported(id) then
        return false, false
    end

    local before_active = f1_track_auto_read_real_visibility(track, id)
    local target_active = not before_active

    reaper.Undo_BeginBlock()

    local ok = f1_track_auto_set_env_auto_in_chunk(track, id, target_active)

    reaper.Undo_EndBlock("Toggle track automation envelope", -1)

    f1_track_auto_visible_override[f1_track_auto_make_key(track, id)] = nil

    local after_active = f1_track_auto_read_real_visibility(track, id)

    if ok and after_active == target_active then
        return true, after_active == true
    end

    return false, after_active == true
end


function toggle_f1_current_track_automation()
    local entry = get_current_entry()

    if not entry or
       current_section_id ~= SECTION_TRACKS or
       entry.kind ~= "track_param" or
       not entry.track or
       not f1_track_auto_id_is_supported(entry.id) then

        speak("No automation")
        return true
    end

    local ok = false
    local visible = false

    if entry.id == "width" then
        ok, visible = f1_track_auto_toggle_width(entry.track)
    else
        ok, visible = f1_track_auto_toggle_native(entry.track, entry.id)
    end

    if ok then
        clear_silent_edge()

        if visible then
            speak("Auto. " .. get_entry_spoken_label(entry))
        else
            speak("Auto off. " .. get_entry_spoken_label(entry))
        end

        return true
    end

    speak("Automation failed")
    return true
end


------------------------------------------------------------
-- 4.W2 - CLEAR ALL TRACK AUTOMATION
--
-- Ctrl+Shift+Alt+A globale:
-- - pulisce tutte le automation envelope della traccia corrente;
-- - rimuove envelope native traccia, send/receive e parametri FX;
-- - non usa azioni REAPER, così non ruba il focus alla finestra gfx.
------------------------------------------------------------

function track_automation_clear_runtime_overrides(track)
    local guid = get_track_guid(track)

    if guid == "" then
        return false
    end

    local f1_prefix = guid .. ":"
    local sr_prefix = guid .. "::recv::"
    local f4_prefix = guid .. "::"

    for key, _ in pairs(f1_track_auto_visible_override or {}) do
        if tostring(key):sub(1, #f1_prefix) == f1_prefix then
            f1_track_auto_visible_override[key] = nil
        end
    end

    for key, _ in pairs(send_receive_auto_visible_override or {}) do
        if tostring(key):sub(1, #sr_prefix) == sr_prefix then
            send_receive_auto_visible_override[key] = nil
        end
    end

    for key, _ in pairs(f4_auto_visible_override or {}) do
        if tostring(key):sub(1, #f4_prefix) == f4_prefix then
            f4_auto_visible_override[key] = nil
        end
    end

    return true
end

function track_automation_is_envelope_open_line(line)
    line = tostring(line or "")

    local tag = line:match("^%s*<([%w_]+)")

    if not tag then
        return false
    end

    tag = tag:upper()

    if tag == "TRACK" or tag == "FXCHAIN" then
        return false
    end

    if tag == "PARMENV" then
        return true
    end

    if tag:match("ENV%d*$") then
        return true
    end

    return false
end

function track_automation_remove_envelope_blocks_from_chunk(chunk)
    chunk = tostring(chunk or "")

    if chunk == "" then
        return chunk, 0
    end

    local out = {}
    local removed = 0
    local skipping = false
    local depth = 0

    for line in (chunk .. "\n"):gmatch("([^\n]*\n)") do
        local plain = line:gsub("\n$", "")

        if not skipping and track_automation_is_envelope_open_line(plain) then
            skipping = true
            depth = 1
            removed = removed + 1
        elseif skipping then
            if plain:match("^%s*<") then
                depth = depth + 1
            end

            if plain:match("^%s*>") then
                depth = depth - 1

                if depth <= 0 then
                    skipping = false
                    depth = 0
                end
            end
        else
            out[#out + 1] = line
        end
    end

    local new_chunk = table.concat(out)

    if chunk:sub(-1) ~= "\n" and new_chunk:sub(-1) == "\n" then
        new_chunk = new_chunk:sub(1, -2)
    end

    return new_chunk, removed
end

function track_automation_is_aux_send_env_tag(tag)
    tag = clean_one_line(tag or ""):upper()

    --------------------------------------------------------
    -- SWS/BR e REAPER possono usare tag AUX...ENV per gli
    -- envelope dei send/receive. Restiamo nel blocco AUXRECV
    -- esatto, quindi qui è sicuro rimuovere tutti gli envelope
    -- AUX del receive corrispondente.
    --------------------------------------------------------

    return tag:match("^AUX.*ENV%d*$") ~= nil
end

function track_automation_remove_aux_env_blocks_for_receive_index(chunk, receive_index)
    chunk = tostring(chunk or "")

    if chunk == "" then
        return chunk, 0
    end

    if type(chunk_split_lines) ~= "function" or
       type(send_receive_chunk_find_auxrecv_line) ~= "function" then
        return chunk, 0
    end

    local lines = chunk_split_lines(chunk)
    local aux_line = send_receive_chunk_find_auxrecv_line(lines, receive_index)

    if aux_line <= 0 then
        return chunk, 0
    end

    local ranges = {}
    local i = aux_line + 1

    while i <= #lines do
        local line = tostring(lines[i] or "")

        if line:match("^%s*AUXRECV%s") then
            break
        end

        local tag = line:match("^%s*<([%w_]+)")

        if tag then
            local start_i = i
            local end_i = i
            local depth = 1
            i = i + 1

            while i <= #lines do
                local l = tostring(lines[i] or "")

                if l:match("^%s*<") then
                    depth = depth + 1
                elseif l:match("^%s*>") then
                    depth = depth - 1

                    if depth <= 0 then
                        end_i = i
                        break
                    end
                end

                i = i + 1
            end

            if track_automation_is_aux_send_env_tag(tag) then
                ranges[#ranges + 1] = { start_i, end_i }
            end
        end

        i = i + 1
    end

    if #ranges <= 0 then
        return chunk, 0
    end

    for r = #ranges, 1, -1 do
        local a = ranges[r][1]
        local b = ranges[r][2]

        for idx = b, a, -1 do
            table.remove(lines, idx)
        end
    end

    local new_chunk = table.concat(lines, "\n")

    if chunk:sub(-1) == "\n" then
        new_chunk = new_chunk .. "\n"
    end

    return new_chunk, #ranges
end

function track_automation_clear_send_envs_from_source_track(source_track)
    if not source_track or
       not reaper.GetTrackStateChunk or
       not reaper.SetTrackStateChunk then
        return 0
    end

    local send_count = get_track_send_count(source_track)
    local removed_total = 0
    local processed = {}

    for send_index = 0, send_count - 1 do
        local chunk_track, receive_index = send_receive_resolve_chunk_target(
            source_track,
            0,
            send_index
        )

        if chunk_track and receive_index >= 0 then
            local key = get_track_guid(chunk_track) .. "::" .. tostring(receive_index)

            if not processed[key] then
                processed[key] = true

                local ok, chunk = reaper.GetTrackStateChunk(chunk_track, "", false)

                if ok and chunk and chunk ~= "" then
                    local new_chunk, removed =
                        track_automation_remove_aux_env_blocks_for_receive_index(
                            chunk,
                            receive_index
                        )

                    if removed > 0 and new_chunk ~= chunk then
                        if reaper.SetTrackStateChunk(chunk_track, new_chunk, false) then
                            removed_total = removed_total + removed
                        end
                    end
                end

                send_receive_auto_visible_override[send_receive_auto_make_key(chunk_track, receive_index, "volume")] = nil
                send_receive_auto_visible_override[send_receive_auto_make_key(chunk_track, receive_index, "pan")] = nil
                send_receive_auto_visible_override[send_receive_auto_make_key(chunk_track, receive_index, "mute")] = nil
            end
        end
    end

    return removed_total
end

function current_track_for_global_track_command()
    local entry = nil

    if type(get_current_entry) == "function" then
        entry = get_current_entry()
    end

    if entry and entry.track then
        return entry.track
    end

    return current_track
end

function clear_all_automation_for_current_track()
    local track = current_track_for_global_track_command()

    if not track then
        speak("No track")
        return true
    end

    if not reaper.GetTrackStateChunk or not reaper.SetTrackStateChunk then
        speak("Automation clear failed")
        return true
    end

    local label = get_track_spoken_label(track)
    local ok, chunk = reaper.GetTrackStateChunk(track, "", false)

    if not ok or not chunk or chunk == "" then
        speak("Automation clear failed. " .. label)
        return true
    end

    local new_chunk, removed = track_automation_remove_envelope_blocks_from_chunk(chunk)
    local set_ok = true
    local send_removed = 0

    reaper.Undo_BeginBlock()

    if removed > 0 and new_chunk ~= chunk then
        set_ok = reaper.SetTrackStateChunk(track, new_chunk, false)
    end

    if set_ok then
        ----------------------------------------------------
        -- Le automazioni dei send della traccia sorgente non
        -- vivono nel chunk della sorgente: REAPER le salva
        -- nelle tracce destinazione, sotto AUXRECV. Perciò
        -- dopo avere pulito la traccia corrente seguiamo anche
        -- ogni suo send e rimuoviamo AUXVOLENV/AUXPANENV/
        -- AUXMUTEENV dal receive corrispondente.
        ----------------------------------------------------
        send_removed = track_automation_clear_send_envs_from_source_track(track)

        track_automation_clear_runtime_overrides(track)
        reaper.TrackList_AdjustWindows(false)
        reaper.UpdateArrange()
    end

    reaper.Undo_EndBlock("Clear all track automation", -1)

    if not set_ok then
        speak("Automation clear failed. " .. label)
        return true
    end

    build_current_grid()
    refresh_window_title()

    if (removed + send_removed) <= 0 then
        speak("No automation. " .. label)
    else
        speak("Automation cleared. " .. label)
    end

    return true
end

------------------------------------------------------------
-- 4.X - SEND / RECEIVE AUTOMATION VIA SWS/BR
--
-- Per Volume, Pan e Mute di Send/Receive, REAPER non espone
-- una creazione affidabile dell'envelope tramite GetTrackSendInfo.
-- Qui usiamo le azioni SWS/BR, che creano/mostrano davvero gli
-- envelope dei send della traccia sorgente selezionata.
-- Nota: le azioni SWS lavorano su tutti i send della traccia
-- selezionata per quel tipo di parametro.
------------------------------------------------------------

SWS_SHOW_SEND_ENV_ACTIONS = {
    volume = "_BR_SHOW_SEND_ENV_VOL_SEL_TRACK",
    pan    = "_BR_SHOW_SEND_ENV_PAN_SEL_TRACK",
    mute   = "_BR_SHOW_SEND_ENV_MUTE_SEL_TRACK"
}

function sws_send_env_command_for_id(id)
    id = clean_one_line(id or "")
    return SWS_SHOW_SEND_ENV_ACTIONS[id] or ""
end

function sws_command_id(name)
    name = clean_one_line(name or "")

    if name == "" or not reaper.NamedCommandLookup then
        return 0
    end

    return tonumber(reaper.NamedCommandLookup(name)) or 0
end

function track_selection_snapshot()
    local snapshot = {}
    local count = get_project_track_count()

    for i = 0, count - 1 do
        local tr = get_track_by_index(i)

        if tr then
            snapshot[#snapshot + 1] = {
                track = tr,
                selected = track_is_selected(tr)
            }
        end
    end

    return snapshot
end

function track_selection_restore(snapshot)
    snapshot = snapshot or {}

    for i = 1, #snapshot do
        local item = snapshot[i]

        if item and item.track then
            pcall(reaper.SetTrackSelected, item.track, item.selected == true)
        end
    end

    reaper.TrackList_AdjustWindows(false)
    reaper.UpdateArrange()

    return true
end

function send_receive_source_track_for_entry(track, category, index)
    category = tonumber(category) or 0
    index = tonumber(index) or -1

    if not track or index < 0 then
        return nil
    end

    if category == 0 then
        return track
    end

    return get_receive_source_track(track, index)
end

function send_receive_show_envelope_via_sws(source_track, id)
    if not source_track then
        return false, "no_source"
    end

    local action_name = sws_send_env_command_for_id(id)
    local cmd = sws_command_id(action_name)

    if cmd == 0 then
        return false, "sws_missing"
    end

    local snapshot = track_selection_snapshot()

    reaper.Undo_BeginBlock()
    reaper.SetOnlyTrackSelected(source_track)
    reaper.Main_OnCommand(cmd, 0)
    reaper.Undo_EndBlock("Show send automation envelope", -1)

    track_selection_restore(snapshot)

    if reaper.MarkProjectDirty then
        reaper.MarkProjectDirty(0)
    end

    return true, "shown"
end

function send_receive_br_get_envelope_properties(env)
    if not env or
       not reaper.BR_EnvAlloc or
       not reaper.BR_EnvGetProperties or
       not reaper.BR_EnvFree then

        return nil
    end

    local br_env = reaper.BR_EnvAlloc(env, false)

    if not br_env then
        return nil
    end

    local ok, active, visible, armed, in_lane, lane_height, default_shape,
        min_value, max_value, center_value, env_type, fader_scaling =
        pcall(
            reaper.BR_EnvGetProperties,
            br_env,
            true, true, true, true,
            0, 0, 0, 0, 0, 0, true
        )

    reaper.BR_EnvFree(br_env, false)

    if not ok then
        return nil
    end

    return {
        active = active == true,
        visible = visible == true,
        armed = armed == true,
        in_lane = in_lane == true,
        lane_height = tonumber(lane_height) or 0,
        default_shape = tonumber(default_shape) or 0,
        fader_scaling = fader_scaling == true
    }
end

function send_receive_br_set_envelope_visible(env, visible)
    return auto_envelope_set_active_visible(env, visible == true)
end


function send_receive_set_actual_envelope_visible(track, category, index, id, visible)
    local env = send_receive_get_actual_envelope(track, category, index, id)

    if not env then
        return false
    end

    return auto_envelope_set_active_visible(env, visible == true)
end


function send_receive_envelope_is_visible(track, category, index, id)
    if not send_receive_auto_id_is_supported(id) then
        return false
    end

    local chunk_track, receive_index = send_receive_resolve_chunk_target(
        track,
        category,
        index
    )

    if not chunk_track or receive_index < 0 then
        return false
    end

    if reaper.GetTrackStateChunk then
        local ok, chunk = reaper.GetTrackStateChunk(chunk_track, "", false)

        if ok and chunk and chunk ~= "" then
            local lines = chunk_split_lines(chunk)
            local aux_line = send_receive_chunk_find_auxrecv_line(lines, receive_index)
            local tag = send_receive_auto_chunk_tag_for_id(id)

            if aux_line > 0 and tag ~= "" then
                local start_i, end_i =
                    send_receive_chunk_find_matching_env(lines, aux_line, tag)

                if start_i > 0 and end_i > 0 then
                    return send_receive_chunk_env_visible(lines, start_i, end_i)
                end
            end
        end
    end

    local env = send_receive_get_actual_envelope(track, category, index, id)

    if env then
        return auto_envelope_is_active(env)
    end

    return false
end


function send_receive_toggle_existing_env_visibility_in_chunk(track, category, index, id)
    if not send_receive_auto_id_is_supported(id) then
        return false, false, "unsupported"
    end

    local chunk_track, receive_index = send_receive_resolve_chunk_target(
        track,
        category,
        index
    )

    if not chunk_track or receive_index < 0 then
        return false, false, "no_chunk_target"
    end

    if not reaper.GetTrackStateChunk or not reaper.SetTrackStateChunk then
        return false, false, "no_chunk_api"
    end

    local tag = send_receive_auto_chunk_tag_for_id(id)

    if tag == "" then
        return false, false, "no_tag"
    end

    local ok, chunk = reaper.GetTrackStateChunk(chunk_track, "", false)

    if not ok or not chunk or chunk == "" then
        return false, false, "no_chunk"
    end

    local lines = chunk_split_lines(chunk)
    local aux_line = send_receive_chunk_find_auxrecv_line(lines, receive_index)

    if aux_line <= 0 then
        return false, false, "no_auxrecv"
    end

    local start_i, end_i = send_receive_chunk_find_matching_env(
        lines,
        aux_line,
        tag
    )

    if start_i <= 0 or end_i <= 0 then
        return false, false, "env_not_found"
    end

    local was_visible = send_receive_chunk_env_visible(lines, start_i, end_i)
    local want_visible = not was_visible

    send_receive_chunk_set_env_visible(lines, start_i, end_i, want_visible)

    local new_chunk = table.concat(lines, "\n") .. "\n"
    local set_ok = reaper.SetTrackStateChunk(chunk_track, new_chunk, false)

    if not set_ok then
        return false, false, "set_chunk_failed"
    end

    send_receive_auto_set_visible_override(
        chunk_track,
        receive_index,
        id,
        want_visible
    )

    if reaper.MarkProjectDirty then
        reaper.MarkProjectDirty(0)
    end

    if reaper.TrackList_AdjustWindows then
        reaper.TrackList_AdjustWindows(false)
    end

    if reaper.UpdateArrange then
        reaper.UpdateArrange()
    end

    return true, want_visible, want_visible and "shown_chunk" or "hidden_chunk"
end

function send_receive_toggle_envelope_visibility(track, category, index, id)
    if not send_receive_auto_id_is_supported(id) then
        return false, false, "unsupported"
    end

    local source_track = send_receive_source_track_for_entry(
        track,
        category,
        index
    )

    if not source_track then
        return false, false, "no_source"
    end

    --------------------------------------------------------
    -- Prima prova: se l'envelope esiste già nel chunk del
    -- receive, lo si mostra/nasconde direttamente lì. Questo
    -- evita il problema per cui P_ENV torna valido sul Pan ma
    -- non sempre su Volume e Mute.
    --------------------------------------------------------
    local chunk_ok, chunk_visible, chunk_reason =
        send_receive_toggle_existing_env_visibility_in_chunk(
            track,
            category,
            index,
            id
        )

    if chunk_ok then
        return true, chunk_visible, chunk_reason
    end

    --------------------------------------------------------
    -- Se non esiste ancora, SWS/BR lo crea/mostra davvero.
    -- Le azioni SWS mostrano tutti gli envelope di quel tipo
    -- per i send della traccia sorgente selezionata.
    --------------------------------------------------------
    local ok, reason = send_receive_show_envelope_via_sws(source_track, id)

    if not ok then
        return false, false, reason
    end

    --------------------------------------------------------
    -- Dopo SWS marchiamo il parametro corrente come visibile.
    -- Non ci fidiamo solo di P_ENV, perché su Volume/Mute può
    -- non tornare subito l'handle, anche se l'envelope è stato
    -- creato correttamente.
    --------------------------------------------------------
    local chunk_track, receive_index = send_receive_resolve_chunk_target(
        track,
        category,
        index
    )

    if chunk_track and receive_index >= 0 then
        send_receive_auto_set_visible_override(
            chunk_track,
            receive_index,
            id,
            true
        )
    end

    return true, true, "shown_sws"
end
function toggle_current_send_receive_automation()
    local entry = get_current_entry()

    if not entry_is_send_receive(entry) or
       entry.kind ~= "send_param" or
       not send_receive_auto_id_is_supported(entry.id) then

        speak("No automation")
        return true
    end

    local ok, visible = send_receive_toggle_envelope_visibility(
        current_track,
        entry.category,
        entry.send_index,
        entry.id
    )

    if ok then
        clear_silent_edge()

        if visible then
            speak("Auto. " .. get_entry_spoken_label(entry))
        else
            speak("Auto off. " .. get_entry_spoken_label(entry))
        end

        return true
    end

    speak("Automation failed")
    return true
end

function toggle_f4_current_param_automation()
    local entry = get_current_entry()

    if not current_entry_is_f4_fx_param(entry) then
        speak("No FX parameter")
        return true
    end

    if not reaper.GetFXEnvelope then
        speak("Automation not available")
        return true
    end

    local before_active = fx_param_envelope_is_visible(
        entry.track,
        entry.fx_index,
        entry.param_index
    )

    local target_active = not before_active

    local ok = fx_set_param_envelope_auto(
        entry.track,
        entry.fx_index,
        entry.param_index,
        target_active,
        true
    )

    if ok then
        clear_silent_edge()

        if type(refocus_script_window_now) == "function" then
            refocus_script_window_now()
        end

        if type(refocus_script_window_deferred) == "function" then
            refocus_script_window_deferred()
        end

        build_current_grid()
        refresh_window_title()

        local entry_after = get_current_entry() or entry

        if target_active then
            speak("Auto. " .. get_entry_spoken_label(entry_after))
        else
            speak("Auto off. " .. get_entry_spoken_label(entry_after))
        end

        return true
    end

    speak("Automation failed")
    return true
end

function handle_numeric_edit_key(char)
    local is_ctrl = ctrl_down()
    local is_shift = shift_down()
    local is_alt = alt_down()

    if char == KEY_ESC then
        cancel_numeric_edit()
        return true
    end

    if is_ctrl and is_shift and is_alt and char == KEY_F1 then
        speak_script_version()
        return true
    end

    if char == KEY_ENTER then
        finish_numeric_edit()
        return true
    end

    if char == KEY_TAB or char == KEY_BACKSLASH then
        speak_numeric_buffer()
        return true
    end

    if is_ctrl and not is_shift and not is_alt and char == KEY_CTRL_E then
        finish_numeric_edit()
        return true
    end

    if char == KEY_BACKSPACE or char == KEY_BACKSPACE_2 then
        numeric_edit_fresh = false
        delete_numeric_char_before_cursor()
        return true
    end

    if char == KEY_DELETE then
        if numeric_edit_fresh then
            numeric_edit_fresh = false
            edit_started = true

            if edit_buffer ~= "" then
                edit_buffer = ""
                edit_cursor = 1
                speak("Cleared")
            else
                speak("Empty")
            end

            return true
        end

        delete_numeric_char_at_cursor()
        return true
    end

    if not is_ctrl and not is_shift and not is_alt and char == KEY_LEFT then
        numeric_edit_fresh = false

        if #edit_buffer == 0 then
            speak("Empty")
            return true
        end

        local changed = false

        edit_cursor, changed =
            text_move_cursor_left_char(edit_buffer, edit_cursor)

        if changed then
            text_speak_char_at_cursor(edit_buffer, edit_cursor)
        end

        return true
    end

    if not is_ctrl and not is_shift and not is_alt and char == KEY_RIGHT then
        numeric_edit_fresh = false

        if #edit_buffer == 0 then
            speak("Empty")
            return true
        end

        local changed = false

        edit_cursor, changed =
            text_move_cursor_right_char(edit_buffer, edit_cursor)

        if changed then
            text_speak_char_at_cursor(edit_buffer, edit_cursor)
        end

        return true
    end

    if char == KEY_HOME then
        numeric_edit_fresh = false

        if #edit_buffer == 0 then
            edit_cursor = 1
            speak("Empty")
            return true
        end

        edit_cursor = 1
        text_speak_char_at_cursor(edit_buffer, edit_cursor)
        return true
    end

    if char == KEY_END then
        numeric_edit_fresh = false

        if #edit_buffer == 0 then
            edit_cursor = 1
            speak("Empty")
            return true
        end

        edit_cursor = #edit_buffer
        text_speak_char_at_cursor(edit_buffer, edit_cursor)
        return true
    end

    local c = safe_char(char)
    local test_buffer = edit_started and edit_buffer or ""
    local test_cursor = edit_started and edit_cursor or 1

    if not is_ctrl and not is_alt and
       c and
       numeric_buffer_can_accept_char_at(c, test_buffer, test_cursor) then

        numeric_edit_fresh = false

        insert_numeric_char_at_cursor(c)

        speak(c)
        return true
    end

    return true
end

------------------------------------------------------------
-- 4.13 - FILTRO CTRL+F
------------------------------------------------------------

function current_filter_scope_name()
    if mode == "fx_param_list" or
       current_section_id == FX_PARAM_LIST_SECTION_ID then
        return "FX parameters list"
    end

    if current_section_id == SECTION_TRACKS then
        return "Tracks"
    end

    if current_section_id == SECTION_SENDS then
        return "Sends"
    end

    if current_section_id == SECTION_RECEIVES then
        return "Receives"
    end

    if current_section_id == SECTION_FX_PARAMS then
        return "FX parameters"
    end

    return "Section"
end

function start_filter_edit()
    cancel_pending_speech()
    clear_silent_edge()

    if edit_mode then
        speak("Close numeric edit first")
        return false
    end

    if mode == "value" then
        exit_value_mode()
    end

    filter_return_mode = mode or "grid"

    if current_section_id == FX_PARAM_LIST_SECTION_ID then
        filter_edit_buffer = tostring(fx_param_list_filter_query or "")
    else
        filter_edit_buffer = tostring(filter_query or "")
    end

    filter_edit_cursor = #filter_edit_buffer + 1
    filter_edit_mode = true
    mode = "filter_edit"

    if filter_edit_buffer ~= "" then
        speak(
            "Filter " ..
            current_filter_scope_name() ..
            ". " ..
            filter_edit_buffer
        )
    else
        speak("Filter " .. current_filter_scope_name())
    end

    return true
end

function rebuild_after_filter_change()
    if current_section_id == FX_PARAM_LIST_SECTION_ID then
        local ok = build_fx_param_list_grid()

        grid_pos = clamp_int(grid_pos, 1, math.max(1, #grid_entries))

        refresh_window_title()

        return ok
    end

    local wanted_guid = ""

    if current_track then
        wanted_guid = get_track_guid(current_track)
    end

    local wanted_pos = grid_pos
    local ok = build_current_grid()

    if ok and wanted_guid ~= "" then
        for pos = 1, #grid_entries do
            local e = grid_entries[pos]

            if e and e.track and get_track_guid(e.track) == wanted_guid then
                grid_pos = pos
                break
            end
        end
    end

    grid_pos = clamp_int(grid_pos, 1, math.max(1, #grid_entries))

    if grid_pos == wanted_pos and grid_pos > #grid_entries then
        grid_pos = #grid_entries
    end

    refresh_window_title()

    return ok
end

function apply_filter_from_edit()
    local query = clean_one_line(filter_edit_buffer or "")

    if current_section_id == FX_PARAM_LIST_SECTION_ID then
        fx_param_list_set_filter_query(query)

        mode = filter_return_mode or "fx_param_list"
        grid_pos = 1

        local ok = rebuild_after_filter_change()

        if not ok and query ~= "" then
            mode = "filter_edit"
            filter_edit_mode = true
            filter_edit_buffer = query
            filter_edit_cursor = #filter_edit_buffer + 1
            speak("No results for " .. query)
            return true
        end

        filter_edit_mode = false
        filter_edit_buffer = ""
        filter_edit_cursor = 1

        mode = filter_return_mode or "fx_param_list"
        filter_return_mode = "grid"

        if query == "" then
            if ok then
                speak(
                    "Filter cleared. " ..
                    fx_param_list_entry_spoken_label(get_current_entry())
                )
            else
                speak("Filter cleared. Empty")
            end

            return true
        end

        speak(
            "Filter " ..
            query ..
            ". " ..
            tostring(current_logical_result_count()) ..
            " results. " ..
            fx_param_list_entry_spoken_label(get_current_entry())
        )

        return true
    end

    set_filter_query(query)

    mode = filter_return_mode or "grid"

    local ok = rebuild_after_filter_change()

    if not ok and query ~= "" then
        mode = "filter_edit"
        filter_edit_mode = true
        filter_edit_buffer = query
        filter_edit_cursor = #filter_edit_buffer + 1
        speak("No results for " .. query)
        return true
    end

    filter_edit_mode = false
    filter_edit_buffer = ""
    filter_edit_cursor = 1

    mode = filter_return_mode or "grid"
    filter_return_mode = "grid"

    if query == "" then
        if ok then
            speak("Filter cleared. " .. current_entry_contextual_label())
        else
            speak("Filter cleared. Empty")
        end

        return true
    end

    speak(
        "Filter " ..
        query ..
        ". " ..
        tostring(current_logical_result_count()) ..
        " results. " ..
        current_entry_contextual_label()
    )

    return true
end

function cancel_filter_edit()
    filter_edit_mode = false
    filter_edit_buffer = ""
    filter_edit_cursor = 1

    mode = filter_return_mode or "grid"
    filter_return_mode = "grid"

    clear_silent_edge()

    if current_section_id == FX_PARAM_LIST_SECTION_ID then
        if fx_param_list_filter_is_active() then
            speak(
                "Filter " ..
                fx_param_list_filter_query ..
                ". " ..
                fx_param_list_entry_spoken_label(get_current_entry())
            )
        else
            fx_param_list_read_short()
        end

        return true
    end

    if filter_is_active() then
        speak("Filter " .. filter_query .. ". " .. current_entry_contextual_label())
    else
        speak_current_entry()
    end

    return true
end

function clear_filter_now()
    cancel_pending_speech()
    clear_silent_edge()

    if current_section_id == FX_PARAM_LIST_SECTION_ID then
        return fx_param_list_clear_filter_now()
    end

    if not filter_is_active() then
        speak("No filter")
        return true
    end

    clear_filter_query()

    local ok = rebuild_after_filter_change()

    if ok then
        speak("Filter cleared. " .. current_entry_contextual_label())
    else
        speak("Filter cleared. Empty")
    end

    return true
end

function toggle_filter_edit_or_clear()
    if filter_edit_mode then
        cancel_filter_edit()
        return true
    end

    if current_section_id == FX_PARAM_LIST_SECTION_ID then
        return fx_param_list_toggle_filter()
    end

    if filter_is_active() then
        return clear_filter_now()
    end

    return start_filter_edit()
end

function speak_filter_buffer()
    local content = clean_one_line(filter_edit_buffer or "")

    if content == "" then
        speak("Filter empty")
    else
        speak("Filter " .. content)
    end
end

function handle_filter_edit_key(char)
    local is_ctrl = ctrl_down()
    local is_shift = shift_down()
    local is_alt = alt_down()

    if char == KEY_ESC then
        cancel_filter_edit()
        return true
    end

    if is_ctrl and is_shift and is_alt and char == KEY_F1 then
        speak_script_version()
        return true
    end

    if is_ctrl and not is_shift and not is_alt and char == KEY_CTRL_F then
        cancel_filter_edit()
        return true
    end

    if char == KEY_ENTER then
        apply_filter_from_edit()
        return true
    end

    if char == KEY_TAB or char == KEY_BACKSLASH then
        speak_filter_buffer()
        return true
    end

    if char == KEY_BACKSPACE or char == KEY_BACKSPACE_2 then
        local removed = ""

        filter_edit_buffer, filter_edit_cursor, removed =
            text_buffer_delete_before_cursor(filter_edit_buffer, filter_edit_cursor)

        if removed ~= "" then
            speak(removed)
        else
            speak("Empty")
        end

        return true
    end

    if char == KEY_DELETE then
        if filter_edit_buffer == "" then
            if current_section_id == FX_PARAM_LIST_SECTION_ID then
                fx_param_list_clear_filter()
            else
                clear_filter_query()
            end

            speak("Filter cleared")
            return true
        end

        local removed = ""

        filter_edit_buffer, filter_edit_cursor, removed =
            text_buffer_delete_at_cursor(filter_edit_buffer, filter_edit_cursor)

        if removed ~= "" then
            speak(removed)
        else
            speak("Empty")
        end

        return true
    end

    if not is_ctrl and not is_shift and not is_alt and char == KEY_LEFT then
        if #filter_edit_buffer == 0 then
            speak("Empty")
            return true
        end

        local changed = false

        filter_edit_cursor, changed =
            text_move_cursor_left_char(filter_edit_buffer, filter_edit_cursor)

        if changed then
            text_speak_char_at_cursor(filter_edit_buffer, filter_edit_cursor)
        end

        return true
    end

    if not is_ctrl and not is_shift and not is_alt and char == KEY_RIGHT then
        if #filter_edit_buffer == 0 then
            speak("Empty")
            return true
        end

        local changed = false

        filter_edit_cursor, changed =
            text_move_cursor_right_char(filter_edit_buffer, filter_edit_cursor)

        if changed then
            text_speak_char_at_cursor(filter_edit_buffer, filter_edit_cursor)
        end

        return true
    end

    if char == KEY_HOME then
        if #filter_edit_buffer == 0 then
            filter_edit_cursor = 1
            speak("Empty")
            return true
        end

        filter_edit_cursor = 1
        text_speak_char_at_cursor(filter_edit_buffer, filter_edit_cursor)
        return true
    end

    if char == KEY_END then
        if #filter_edit_buffer == 0 then
            filter_edit_cursor = 1
            speak("Empty")
            return true
        end

        filter_edit_cursor = #filter_edit_buffer
        text_speak_char_at_cursor(filter_edit_buffer, filter_edit_cursor)
        return true
    end

    local c = safe_char(char)

    if not is_ctrl and not is_alt and c then
        filter_edit_buffer, filter_edit_cursor =
            text_buffer_insert_char(filter_edit_buffer, filter_edit_cursor, c)

        speak(c)
        return true
    end

    return true
end

------------------------------------------------------------
-- 4.14 - TRACK CUT / COPY / PASTE / MOVE
--
-- Solo F1.
-- Cut/Copy/Paste usano SWS/S&M con routing.
------------------------------------------------------------

SWS_CMD_CUT_TRACKS_WITH_ROUTING   = "_S&M_CUTSNDRCV1"
SWS_CMD_COPY_TRACKS_WITH_ROUTING  = "_S&M_COPYSNDRCV1"
SWS_CMD_PASTE_TRACKS_WITH_ROUTING = "_S&M_PASTSNDRCV1"

function run_named_command(command_id)
    if not reaper.NamedCommandLookup or not reaper.Main_OnCommand then
        speak("Command not available")
        return false
    end

    local cmd = reaper.NamedCommandLookup(command_id)

    if not cmd or cmd == 0 then
        speak("SWS command not found")
        return false
    end

    reaper.Main_OnCommand(cmd, 0)

    return true
end

function get_current_cursor_track_f1()
    if current_section_id ~= SECTION_TRACKS then
        return nil
    end

    local e = get_current_entry()

    if e and e.track then
        return e.track
    end

    if current_track and current_track_exists_anywhere(current_track) then
        return current_track
    end

    return nil
end

function select_only_track_for_reaper_action(track)
    if not track then
        return false
    end

    if reaper.SetOnlyTrackSelected then
        reaper.SetOnlyTrackSelected(track)
    else
        local count = get_project_track_count()

        for i = 0, count - 1 do
            local tr = get_track_by_index(i)

            if tr then
                reaper.SetTrackSelected(tr, tr == track)
            end
        end
    end

    reaper.TrackList_AdjustWindows(false)
    reaper.UpdateArrange()

    return true
end

function get_first_selected_track_guid_ordered()
    local tracks = collect_selected_tracks_ordered()

    if #tracks <= 0 then
        return ""
    end

    return get_track_guid(tracks[1])
end

function rebuild_tracks_after_edit(message, wanted_guid_override, wanted_col_override)
    --------------------------------------------------------
    -- Dopo Cut / Paste / Move la vecchia current_track può
    -- essere sparita. Usiamo un GUID esplicito se disponibile.
    --------------------------------------------------------

    local wanted_guid = clean_one_line(wanted_guid_override or "")

    if wanted_guid == "" and current_track then
        wanted_guid = get_track_guid(current_track)
    end

    local wanted_col = tonumber(wanted_col_override) or grid_col_from_pos(grid_pos)

    build_current_grid()

    local found = false

    if wanted_guid ~= "" then
        for pos = 1, #grid_entries do
            local e = grid_entries[pos]

            if e and e.track and get_track_guid(e.track) == wanted_guid then
                local row = grid_row_from_pos(pos)
                grid_pos = grid_pos_from_row_col(row, wanted_col)
                found = true
                break
            end
        end
    end

    if not found then
        grid_pos = clamp_int(grid_pos, 1, math.max(1, #grid_entries))
    end

    local e = get_current_entry()

    if e and e.track then
        set_current_track_pointer_only(e.track)
    else
        current_track = nil
        current_track_guid = ""
        track_index = 0

        select_first_track()
        build_current_grid()
        grid_pos = clamp_int(grid_pos, 1, math.max(1, #grid_entries))
    end

    refresh_window_title()

if message and message ~= "" then
    speak(message)
end

    return true
end

function track_cut_selected_with_routing()
    if current_section_id ~= SECTION_TRACKS then
        return false
    end

    local old_row, old_col = grid_current_row_col()

    select_current_track_if_no_selection()

    if run_named_command(SWS_CMD_CUT_TRACKS_WITH_ROUTING) then
        ----------------------------------------------------
        -- Dopo il cut SWS/Reaper può lasciare selezionata
        -- la traccia successiva. Per lo script non deve
        -- risultare nessuna traccia selezionata.
        ----------------------------------------------------

        track_selection_reset_stroke()
        clear_track_selection_silent()

        ----------------------------------------------------
        -- La current_track precedente può essere stata tagliata,
        -- quindi non dobbiamo più usarla per cercare il GUID.
        ----------------------------------------------------

        current_track = nil
        current_track_guid = ""

        build_current_grid()

        if #grid_entries > 0 then
            local rows = grid_row_count()

            if rows > 0 then
                old_row = clamp_int(old_row, 1, rows)
                grid_pos = grid_pos_from_row_col(old_row, old_col)
            else
                grid_pos = 1
            end

            local e = get_current_entry()

            if e and e.track then
                set_current_track_pointer_only(e.track)
            end
        else
            grid_pos = 1
        end

        ----------------------------------------------------
        -- Pulizia finale: anche se build/reaper hanno mosso
        -- qualcosa, nessuna traccia deve restare selected.
        ----------------------------------------------------

        clear_track_selection_silent()
        refresh_window_title()

        return true
    end

    clear_track_selection_silent()
    return true
end

function track_copy_selected_with_routing()
    if current_section_id ~= SECTION_TRACKS then
        return false
    end

    select_current_track_if_no_selection()

    if run_named_command(SWS_CMD_COPY_TRACKS_WITH_ROUTING) then
        ----------------------------------------------------
        -- Dopo copy lasciamo il TCP pulito, così il paste non
        -- dipende da una vecchia selezione reale.
        ----------------------------------------------------

        clear_track_selection_silent()
        speak("Copied tracks")
        return true
    end

    return true
end

function track_paste_with_routing()
    if current_section_id ~= SECTION_TRACKS then
        return false
    end

    --------------------------------------------------------
    -- Punto chiave:
    -- SWS incolla rispetto alla selezione reale del TCP.
    -- Il nostro cursore è interno/invisibile, quindi prima
    -- selezioniamo davvero nel TCP la traccia corrente.
    --------------------------------------------------------

    local anchor_track = get_current_cursor_track_f1()

    if not anchor_track then
        speak("No track")
        return true
    end

    local wanted_col = grid_col_from_pos(grid_pos)

    select_only_track_for_reaper_action(anchor_track)

    if run_named_command(SWS_CMD_PASTE_TRACKS_WITH_ROUTING) then
        ----------------------------------------------------
        -- Dopo il paste, SWS di solito seleziona le tracce
        -- appena incollate. Prendiamo la prima come nuova
        -- posizione del cursore invisibile.
        ----------------------------------------------------

        local pasted_guid = get_first_selected_track_guid_ordered()

        track_selection_reset_stroke()
        clear_track_selection_silent()

        rebuild_tracks_after_edit("", pasted_guid, wanted_col)
        return true
    end

    clear_track_selection_silent()

    return true
end

function get_selected_track_index_bounds()
    local count = reaper.CountSelectedTracks(0) or 0

    if count <= 0 then
        return -1, -1
    end

    local min_i = 999999
    local max_i = -1

    for i = 0, count - 1 do
        local tr = reaper.GetSelectedTrack(0, i)
        local idx = get_track_index(tr)

        if idx >= 0 then
            if idx < min_i then min_i = idx end
            if idx > max_i then max_i = idx end
        end
    end

    if max_i < 0 then
        return -1, -1
    end

    return min_i, max_i
end

function get_track_label_by_project_index(index)
    index = tonumber(index) or -1

    local tr = get_track_by_index(index)

    if tr then
        return get_track_spoken_label(tr)
    end

    return ""
end


------------------------------------------------------------
-- 4.14A - SPOSTAMENTO TRACCE FOLDER-AWARE
--
-- Lo spostamento reale usa sempre ReorderSelectedTracks.
-- Prima però la selezione viene normalizzata logicamente:
-- - una folder selezionata rappresenta tutto il suo blocco;
-- - i figli di una folder già selezionata non vengono trattati
--   come blocchi separati;
-- - tracce e sottofolder fuori dal blocco restano selezioni
--   valide;
-- - dopo lo spostamento torna la selezione logica originale,
--   non tutti i figli espansi.
------------------------------------------------------------

function track_block_end_index(track)
    local start_i = get_track_index(track)

    if start_i < 0 then
        return -1
    end

    if not track_is_folder(track) then
        return start_i
    end

    local count = get_project_track_count()
    local depth = 1
    local i = start_i + 1

    while i < count do
        local tr = get_track_by_index(i)
        local delta = track_folder_depth_delta(tr)

        depth = depth + delta

        if depth <= 0 then
            return i
        end

        i = i + 1
    end

    return count - 1
end

function track_index_is_inside_block(index, start_i, end_i)
    index = tonumber(index) or -1
    start_i = tonumber(start_i) or -1
    end_i = tonumber(end_i) or -1

    return index >= start_i and index <= end_i
end

function collect_selected_track_roots_folder_aware()
    local roots = {}
    local selected_count = reaper.CountSelectedTracks(0) or 0

    for i = 0, selected_count - 1 do
        local tr = reaper.GetSelectedTrack(0, i)
        local idx = get_track_index(tr)

        if tr and idx >= 0 then
            roots[#roots + 1] = {
                track = tr,
                index = idx,
                end_index = track_block_end_index(tr),
                guid = get_track_guid(tr)
            }
        end
    end

    table.sort(roots, function(a, b)
        return (a.index or 0) < (b.index or 0)
    end)

    local logical = {}

    for i = 1, #roots do
        local item = roots[i]
        local inside_previous_folder = false

        for j = 1, #logical do
            local root = logical[j]

            if root and root.is_folder and
               track_index_is_inside_block(
                   item.index,
                   root.index + 1,
                   root.end_index
               ) then

                inside_previous_folder = true
                break
            end
        end

        if not inside_previous_folder then
            item.is_folder = track_is_folder(item.track)
            logical[#logical + 1] = item
        end
    end

    return logical
end

function make_track_guid_map_from_roots(roots, expand_folders)
    local map = {}

    roots = roots or {}

    for i = 1, #roots do
        local item = roots[i]
        local start_i = tonumber(item and item.index) or -1
        local end_i = start_i

        if expand_folders and item and item.is_folder then
            end_i = tonumber(item.end_index) or start_i
        end

        for idx = start_i, end_i do
            local tr = get_track_by_index(idx)

            if tr then
                local guid = get_track_guid(tr)

                if guid ~= "" then
                    map[guid] = true
                end
            end
        end
    end

    return map
end

function apply_track_guid_map_silent(map)
    map = map or {}

    local count = get_project_track_count()

    for i = 0, count - 1 do
        local tr = get_track_by_index(i)

        if tr then
            local guid = get_track_guid(tr)
            reaper.SetTrackSelected(tr, guid ~= "" and map[guid] == true)
        end
    end

    reaper.TrackList_AdjustWindows(false)
    reaper.UpdateArrange()
end

function selected_track_index_bounds_from_roots(roots, expand_folders)
    roots = roots or {}

    if #roots <= 0 then
        return -1, -1
    end

    local min_i = 999999
    local max_i = -1

    for i = 1, #roots do
        local item = roots[i]
        local start_i = tonumber(item and item.index) or -1
        local end_i = start_i

        if expand_folders and item and item.is_folder then
            end_i = tonumber(item.end_index) or start_i
        end

        if start_i >= 0 then
            if start_i < min_i then min_i = start_i end
            if end_i > max_i then max_i = end_i end
        end
    end

    if max_i < 0 then
        return -1, -1
    end

    return min_i, max_i
end

function get_track_by_guid(guid)
    guid = clean_one_line(guid or "")

    if guid == "" then
        return nil
    end

    local count = get_project_track_count()

    for i = 0, count - 1 do
        local tr = get_track_by_index(i)

        if tr and get_track_guid(tr) == guid then
            return tr
        end
    end

    return nil
end

function refresh_roots_after_reorder(roots)
    local out = {}

    roots = roots or {}

    for i = 1, #roots do
        local tr = get_track_by_guid(roots[i].guid)
        local idx = get_track_index(tr)

        if tr and idx >= 0 then
            out[#out + 1] = {
                track = tr,
                index = idx,
                end_index = track_block_end_index(tr),
                guid = get_track_guid(tr),
                is_folder = track_is_folder(tr)
            }
        end
    end

    table.sort(out, function(a, b)
        return (a.index or 0) < (b.index or 0)
    end)

    return out
end

function moved_tracks_relation_message(direction, moved_min_i, moved_max_i)
    direction = tonumber(direction) or 0
    moved_min_i = tonumber(moved_min_i) or -1
    moved_max_i = tonumber(moved_max_i) or -1

    if direction < 0 then
        local below_label = get_track_label_by_project_index(moved_max_i + 1)

        if below_label ~= "" then
            return "Tracks moved. Below " .. below_label
        end

        return "Tracks moved"
    end

    if direction > 0 then
        local above_label = get_track_label_by_project_index(moved_min_i - 1)

        if above_label ~= "" then
            return "Tracks moved. Above " .. above_label
        end

        return "Tracks moved"
    end

    return "Tracks moved"
end

function move_selected_tracks_one_step(direction)
    if current_section_id ~= SECTION_TRACKS then
        return false
    end

    direction = tonumber(direction) or 0

    if direction == 0 then
        return false
    end

    if not reaper.ReorderSelectedTracks then
        speak("Move tracks not available")
        return true
    end

    select_current_track_if_no_selection()

    local logical_roots = collect_selected_track_roots_folder_aware()
    local count = get_project_track_count()

    if #logical_roots <= 0 or count <= 0 then
        speak("No selected tracks")
        return true
    end

    local min_i, max_i = selected_track_index_bounds_from_roots(logical_roots, true)

    if min_i < 0 or max_i < 0 then
        speak("No selected tracks")
        return true
    end

    local before_index = nil

    if direction < 0 then
        if min_i <= 0 then
            return grid_edge("move-track-top")
        end

        before_index = min_i - 1
    else
        if max_i >= count - 1 then
            return grid_edge("move-track-bottom")
        end

        before_index = max_i + 2

        if before_index > count then
            before_index = count
        end
    end

    local current_guid = ""
    local e = get_current_entry()

    if e and e.track then
        current_guid = get_track_guid(e.track)
    elseif current_track then
        current_guid = get_track_guid(current_track)
    end

    local _, old_col = grid_current_row_col()
    local expanded_selection = make_track_guid_map_from_roots(logical_roots, true)
    local logical_selection = make_track_guid_map_from_roots(logical_roots, false)

    --------------------------------------------------------
    -- Per il solo ReorderSelectedTracks selezioniamo anche i
    -- figli delle folder selezionate. Subito dopo ripristiniamo
    -- la selezione logica dell'utente.
    --------------------------------------------------------

    apply_track_guid_map_silent(expanded_selection)

    reaper.ReorderSelectedTracks(before_index, 0)

    local moved_roots = refresh_roots_after_reorder(logical_roots)
    local moved_min_i, moved_max_i = selected_track_index_bounds_from_roots(moved_roots, true)

    apply_track_guid_map_silent(logical_selection)

    build_current_grid()
    refresh_window_title()

    local wanted_track = get_track_by_guid(current_guid)

    if not wanted_track and moved_roots[1] then
        wanted_track = moved_roots[1].track
    end

    if wanted_track then
        set_current_track_pointer_only(wanted_track)

        local wanted_row = get_row_for_track_in_current_grid(wanted_track)

        if wanted_row > 0 then
            grid_pos = grid_pos_from_row_col(wanted_row, old_col)
        else
            grid_pos = clamp_int(grid_pos, 1, math.max(1, #grid_entries))
        end
    else
        grid_pos = clamp_int(grid_pos, 1, math.max(1, #grid_entries))
    end

    speak(
        moved_tracks_relation_message(
            direction,
            moved_min_i,
            moved_max_i
        )
    )

    return true
end

------------------------------------------------------------
-- 4.15 - DESELEZIONE TRACCE
--
-- Delete:
-- - deseleziona solo la traccia dove si trova il cursore
--   invisibile.
--
-- Ctrl+Delete:
-- - deseleziona tutte le tracce.
------------------------------------------------------------

function deselect_current_cursor_track_f1()
    if current_section_id ~= SECTION_TRACKS then
        return false
    end

    track_selection_reset_stroke()

    local e = get_current_entry()

    if not e or not e.track then
        speak("No track")
        return true
    end

    if not track_is_selected(e.track) then
        speak(
            tostring(selected_track_count()) ..
            " Selected. " ..
            get_track_folder_spoken_label(e.track) ..
            ". Not selected"
        )
        return true
    end

    reaper.SetTrackSelected(e.track, false)
    reaper.TrackList_AdjustWindows(false)
    reaper.UpdateArrange()

    speak(
        tostring(selected_track_count()) ..
        " Selected. " ..
        get_track_folder_spoken_label(e.track) ..
        ". Deselected"
    )

    return true
end

------------------------------------------------------------
-- 4.15.1 - NAVIGAZIONE FOLDER F1
--
-- Ctrl+Page Up   = folder precedente
-- Ctrl+Page Down = folder successiva
--
-- Navigazione interna normale:
-- - non usa azioni SWS;
-- - non seleziona realmente tracce;
-- - mantiene la stessa colonna parametro;
-- - parla tramite la normale logica dello script,
--   come frecce, Page Up, Home, End.
------------------------------------------------------------

function find_nearest_folder_row_f1(direction)
    if current_section_id ~= SECTION_TRACKS then
        return 0
    end

    direction = tonumber(direction) or 0

    if direction == 0 then
        return 0
    end

    local rows = grid_row_count()

    if rows <= 0 then
        return 0
    end

    local current_row, current_col = grid_current_row_col()
    local row = current_row + direction

    while row >= 1 and row <= rows do
        local pos = grid_pos_from_row_col(row, current_col)
        local e = grid_entries[pos]

        if e and e.track and track_is_folder(e.track) then
            return row
        end

        row = row + direction
    end

    return 0
end

function navigate_nearest_folder_f1(direction)
    if current_section_id ~= SECTION_TRACKS then
        return false
    end

    direction = tonumber(direction) or 0

    if direction == 0 then
        return false
    end

    local current_row, current_col = grid_current_row_col()
    local target_row = find_nearest_folder_row_f1(direction)

    if target_row <= 0 then
        if direction < 0 then
            return grid_edge("folder-prev:" .. tostring(current_col))
        end

        return grid_edge("folder-next:" .. tostring(current_col))
    end

    local new_pos = grid_pos_from_row_col(target_row, current_col)

    --------------------------------------------------------
    -- Punto importante:
    -- usiamo la navigazione normale della griglia.
    -- Così parla get_entry_spoken_label_for_move(..., "track"),
    -- esattamente come quando ci si muove su/giù tra tracce.
    --------------------------------------------------------

    return grid_move_to_pos(new_pos, true, "track")
end

------------------------------------------------------------
-- 4.16 - GRID KEY HANDLER
------------------------------------------------------------

function handle_grid_key(char)
    local is_ctrl = ctrl_down()
    local is_shift = shift_down()
    local is_alt = alt_down()

    if mode == "fx_param_list" or
       current_section_id == FX_PARAM_LIST_SECTION_ID then
        return handle_fx_param_list_key(char)
    end

    if char == KEY_ESC then
        if type(track_fixed_cc_cancel_learn) == "function" and
           track_fixed_cc_cancel_learn(true) then

            return true
        end

        if routing_pending_is_active() then
            routing_pending_cancel()
            return true
        end

        exit_script()
        return true
    end

    if is_ctrl and is_shift and is_alt and char == KEY_F1 then
        speak_script_version()
        return true
    end

    --------------------------------------------------------
    -- F2 / F3:
    -- Ctrl+Shift+A = show/hide automation envelope for useful
    -- send/receive parameters: Volume, Pan, Mute.
    --------------------------------------------------------

    if current_section_id == SECTION_SENDS or
       current_section_id == SECTION_RECEIVES then

        if is_ctrl and not is_shift and not is_alt and char == KEY_UP then
            grid_detail_switch_visible_track(-1)
            return true
        end

        if is_ctrl and not is_shift and not is_alt and char == KEY_DOWN then
            grid_detail_switch_visible_track(1)
            return true
        end

        if is_ctrl and is_shift and not is_alt and ctrl_a_key(char) then
            toggle_current_send_receive_automation()
            return true
        end
    end

    --------------------------------------------------------
    -- F4:
    -- Ctrl+Shift+Freccia su/giù sposta fisicamente l'FX
    -- corrente nella FX chain.
    -- Solo nella griglia F4 normale, non nella lista parametri.
    --------------------------------------------------------

    if current_section_id == SECTION_FX_PARAMS then
        if is_ctrl and not is_shift and not is_alt and char == KEY_UP then
            grid_switch_visible_track_with_content(-1)
            return true
        end

        if is_ctrl and not is_shift and not is_alt and char == KEY_DOWN then
            grid_switch_visible_track_with_content(1)
            return true
        end

        if is_shift and not is_ctrl and not is_alt and char == KEY_UP then
            f4_order_move_current_param(-1)
            return true
        end

        if is_shift and not is_ctrl and not is_alt and char == KEY_DOWN then
            f4_order_move_current_param(1)
            return true
        end

        if is_ctrl and is_shift and not is_alt and char == KEY_UP then
            move_current_f4_fx_in_chain(-1)
            return true
        end

        if is_ctrl and is_shift and not is_alt and char == KEY_DOWN then
            move_current_f4_fx_in_chain(1)
            return true
        end
    end

--------------------------------------------------------
-- F4:
-- Ctrl+B = toggle bypass FX corrente.
-- Ctrl+D = toggle Delta Solo FX corrente.
--------------------------------------------------------

if current_section_id == SECTION_FX_PARAMS then
    if is_ctrl and not is_shift and not is_alt and char == KEY_CTRL_B then
        toggle_current_f4_fx_bypass()
        return true
    end

    if is_ctrl and not is_shift and not is_alt and char == KEY_CTRL_D then
        toggle_current_f4_fx_delta_solo()
        return true
    end

    if not is_ctrl and not is_shift and not is_alt and char == KEY_F5 then
        enter_pin_audio_from_f4()
        return true
    end

    if not is_ctrl and not is_shift and not is_alt and char == KEY_F6 then
        enter_pin_midi_from_f4()
        return true
    end

    if is_ctrl and is_shift and not is_alt and ctrl_a_key(char) then
        toggle_f4_current_param_automation()
        return true
    end

    if is_ctrl and not is_shift and not is_alt and char == KEY_ENTER then
        start_fx_alias_edit()
        return true
    end
end

    if is_ctrl and is_shift and not is_alt and char == KEY_CTRL_S then
        handle_add_send_shortcut()
        return true
    end

    if is_ctrl and is_shift and not is_alt and char == KEY_CTRL_R then
        handle_add_receive_shortcut()
        return true
    end

    --------------------------------------------------------
    -- F1 track selection / editing.
    --------------------------------------------------------

    if current_section_id == SECTION_TRACKS then
        if is_ctrl and is_shift and not is_alt and ctrl_a_key(char) then
            toggle_f1_current_track_automation()
            return true
        end

        if is_ctrl and not is_shift and not is_alt and ctrl_a_key(char) then
            select_all_visible_tracks_f1()
            return true
        end

        if not is_ctrl and is_shift and not is_alt and char == KEY_SPACE then
            toggle_current_cursor_track_selection_f1()
            return true
        end

        if is_ctrl and is_shift and not is_alt and char == KEY_SPACE then
            toggle_current_cursor_track_selection_f1()
            return true
        end

        if not is_ctrl and not is_shift and not is_alt and char == KEY_DELETE then
            deselect_current_cursor_track_f1()
            return true
        end

        if is_ctrl and not is_shift and not is_alt and char == KEY_DELETE then
            clear_track_selection()

            if type(track_fixed_cc_clear_all_links) == "function" then
                track_fixed_cc_clear_all_links(true)
            end

            return true
        end

        if is_shift and not is_ctrl and not is_alt and char == KEY_UP then
            track_shift_select_move(-1)
            return true
        end

        if is_shift and not is_ctrl and not is_alt and char == KEY_DOWN then
            track_shift_select_move(1)
            return true
        end

        if is_shift and not is_ctrl and not is_alt and char == KEY_PAGE_UP then
            track_shift_select_page(-1)
            return true
        end

        if is_shift and not is_ctrl and not is_alt and char == KEY_PAGE_DOWN then
            track_shift_select_page(1)
            return true
        end

        if is_ctrl and is_shift and not is_alt and char == KEY_UP then
            track_ctrl_shift_select_to_edge(-1)
            return true
        end

        if is_ctrl and is_shift and not is_alt and char == KEY_DOWN then
            track_ctrl_shift_select_to_edge(1)
            return true
        end

        if is_ctrl and not is_shift and not is_alt and char == KEY_CTRL_X then
            track_cut_selected_with_routing()
            return true
        end

        if is_ctrl and not is_shift and not is_alt and char == KEY_CTRL_C then
            track_copy_selected_with_routing()
            return true
        end

        ----------------------------------------------------
        -- F1:
        -- Ctrl+V resta Paste tracks with routing.
        -- Ctrl+Shift+V entra / esce da Value mode.
        ----------------------------------------------------

        ----------------------------------------------------
        -- F1:
        -- Ctrl+Alt+Page Up/Down: navigazione tra folder.
        -- Mantiene la stessa colonna parametro.
        ----------------------------------------------------

        if is_ctrl and not is_shift and is_alt and char == KEY_PAGE_UP then
            navigate_nearest_folder_f1(-1)
            return true
        end

        if is_ctrl and not is_shift and is_alt and char == KEY_PAGE_DOWN then
            navigate_nearest_folder_f1(1)
            return true
        end

        if is_ctrl and is_shift and not is_alt and char == KEY_CTRL_V then
            toggle_value_mode()
            return true
        end

        if is_ctrl and not is_shift and not is_alt and char == KEY_CTRL_V then
            track_paste_with_routing()
            return true
        end

        if is_alt and is_shift and not is_ctrl and char == KEY_UP then
            move_selected_tracks_one_step(-1)
            return true
        end

        if is_alt and is_shift and not is_ctrl and char == KEY_DOWN then
            move_selected_tracks_one_step(1)
            return true
        end
    end

    --------------------------------------------------------
    -- F2/F3:
    -- Delete cancella solo il send / receive corrente.
    --------------------------------------------------------

    if (current_section_id == SECTION_SENDS or
        current_section_id == SECTION_RECEIVES) and
       not is_ctrl and not is_shift and not is_alt and
       char == KEY_DELETE then

        delete_current_send_or_receive()
        return true
    end

    if current_section_id == HARDWARE_OUTPUT_SECTION_ID and
       not is_ctrl and not is_shift and not is_alt and
       char == KEY_DELETE then

        delete_current_hardware_output()
        return true
    end

    if current_section_id == REAROUTE_SECTION_ID and
       not is_ctrl and not is_shift and not is_alt and
       char == KEY_DELETE then

        delete_current_rearoute_output()
        return true
    end

    --------------------------------------------------------
    -- F4:
    -- Delete rimuove dai Track Controls solo il parametro FX
    -- selezionato. Sull'intestazione FX non cancella nulla.
    --------------------------------------------------------

    if current_section_id == SECTION_FX_PARAMS and
       not is_ctrl and not is_shift and not is_alt and
       char == KEY_DELETE then

        local e = get_current_entry()

        if not e then
            speak("Empty")
            return true
        end

        if e.kind == "fx_header" then
            speak("FX header")
            return true
        end

        if e.kind ~= "fx_param" then
            speak("No FX parameter")
            return true
        end

        local param_name = make_entry_label(e)
        local old_fx_index = tonumber(e.fx_index) or -1
        local old_pos = grid_pos

        local ok = fx_remove_param_from_tcp(
            e.track,
            e.fx_index,
            e.param_index
        )

        if not ok then
            speak("Could not remove parameter")
            return true
        end

        build_current_grid()

        local header_pos = f4_find_header_pos_for_fx(old_fx_index)
        local first_param_pos = 0

        if header_pos > 0 then
            for pos = header_pos + 1, #grid_entries do
                local ge = grid_entries[pos]

                if ge and ge.kind == "fx_header" then
                    break
                end

                if ge and
                   ge.kind == "fx_param" and
                   tonumber(ge.fx_index) == old_fx_index then

                    first_param_pos = pos
                    break
                end
            end
        end

        if old_pos <= #grid_entries then
            local candidate = grid_entries[old_pos]

            if candidate and
               candidate.kind == "fx_param" and
               tonumber(candidate.fx_index) == old_fx_index then

                grid_pos = old_pos

            else
                candidate = grid_entries[old_pos - 1]

                if candidate and
                   candidate.kind == "fx_param" and
                   tonumber(candidate.fx_index) == old_fx_index then

                    grid_pos = old_pos - 1

                elseif first_param_pos > 0 then
                    grid_pos = first_param_pos

                elseif header_pos > 0 then
                    grid_pos = header_pos

                else
                    grid_pos = clamp_int(old_pos, 1, math.max(1, #grid_entries))
                end
            end

        elseif first_param_pos > 0 then
            grid_pos = first_param_pos

        elseif header_pos > 0 then
            grid_pos = header_pos

        else
            grid_pos = clamp_int(old_pos, 1, math.max(1, #grid_entries))
        end

        refresh_window_title()

        local here = get_current_entry()
        local where = ""

        if here and here.kind == "fx_param" then
            where = ". Now " .. get_entry_spoken_label(here)
        elseif here and here.kind == "fx_header" then
            where = ". " .. make_entry_label(here)
        end

        if param_name == "" then
            speak("Removed" .. where)
        else
            speak("Removed " .. param_name .. where)
        end

        return true
    end

    --------------------------------------------------------
    -- Ctrl+Shift+I sui soli campi Volume: imposta il range del parametro.
    -- I normale resta libero per il richiamo traccia.
    -- Ctrl+I resta libero per il marker precedente.
    -- Alt+I non viene più usato.
    --------------------------------------------------------

    if is_ctrl and is_shift and not is_alt and char == KEY_CTRL_I then
        if volume_range_is_volume_entry(get_current_entry()) then
            return volume_range_edit_current()
        end
    end

    --------------------------------------------------------
    -- Ctrl+F:
    -- filtro coerente per F1, F2, F3, F4.
    --------------------------------------------------------

    if is_ctrl and not is_shift and not is_alt and char == KEY_CTRL_F then
        toggle_filter_edit_or_clear()
        return true
    end

    --------------------------------------------------------
    -- Sezioni:
    -- F1 = Tracks.
    -- F2 = Sends.
    -- F3 = Receives.
    -- F4 = FX parameters.
    --------------------------------------------------------

    if section_key_to_config(char) then
        switch_section_by_key(char, true)
        return true
    end

    --------------------------------------------------------
    -- Step scale in grid mode.
    -- Alt+Left  = step più fine.
    -- Alt+Right = step più grande.
    --
    -- F11 / F12 non sono più usati qui:
    -- restano liberi per funzioni future.
    --------------------------------------------------------

    if is_alt and not is_ctrl and not is_shift and char == KEY_LEFT then
        change_step_scale(-1)
        return true
    end

    if is_alt and not is_ctrl and not is_shift and char == KEY_RIGHT then
        change_step_scale(1)
        return true
    end    

    if is_ctrl and not is_shift and not is_alt and char == KEY_CTRL_V then
        toggle_value_mode()
        return true
    end

    if is_ctrl and not is_shift and not is_alt and char == KEY_CTRL_E then
        start_numeric_edit()
        return true
    end

    if char == KEY_TAB then
        read_current_line()
        return true
    end

    if char == KEY_BACKSLASH then
        read_current_short()
        return true
    end

    --------------------------------------------------------
    -- Ctrl+Enter:
    -- resta solo per F4, dove apre la lista parametri se sei
    -- su un header FX. In F1 la gestione folder è stata spostata
    -- su Enter semplice, solo sulle colonne Volume/Pan/Track Width.
    --------------------------------------------------------

    if is_ctrl and not is_shift and not is_alt and char == KEY_ENTER then
        if current_section_id == SECTION_FX_PARAMS then
            current_entry_enter()
            return true
        end

        return true
    end

    if not is_ctrl and not is_shift and not is_alt and char == KEY_ENTER then
        clear_silent_edge()
        current_entry_enter()
        return true
    end

    --------------------------------------------------------
    -- Controllo valori.
    --------------------------------------------------------

    if is_alt and not is_ctrl and not is_shift then
        if char == KEY_UP then
            current_entry_nudge_value(1, false)
            return true
        end

        if char == KEY_DOWN then
            current_entry_nudge_value(-1, false)
            return true
        end

        if char == KEY_PAGE_UP then
            current_entry_nudge_value(1, true)
            return true
        end

        if char == KEY_PAGE_DOWN then
            current_entry_nudge_value(-1, true)
            return true
        end

        ----------------------------------------------------
        -- Alt+Home / Alt+End sui valori.
        --
        -- Coerente in tutte le sezioni:
        -- Alt+Home = massimo.
        -- Alt+End  = minimo.
        ----------------------------------------------------

        if char == KEY_HOME then
            current_entry_set_max()
            return true
        end

        if char == KEY_END then
            current_entry_set_min()
            return true
        end
    end

    if current_section_id == SECTION_TRACKS and not is_shift then
        track_selection_reset_stroke()
    end

    --------------------------------------------------------
    -- Navigazione campo.
    --------------------------------------------------------

    if not is_ctrl and not is_shift and not is_alt and char == KEY_UP then
        grid_move_vertical(-1)
        return true
    end

    if not is_ctrl and not is_shift and not is_alt and char == KEY_DOWN then
        grid_move_vertical(1)
        return true
    end

    if not is_ctrl and not is_shift and not is_alt and char == KEY_LEFT then
        grid_move_horizontal(-1)
        return true
    end

    if not is_ctrl and not is_shift and not is_alt and char == KEY_RIGHT then
        grid_move_horizontal(1)
        return true
    end

    if not is_ctrl and not is_shift and not is_alt and char == KEY_PAGE_UP then
        grid_move_page(-1)
        return true
    end

    if not is_ctrl and not is_shift and not is_alt and char == KEY_PAGE_DOWN then
        grid_move_page(1)
        return true
    end

    if char == KEY_HOME then
        if current_section_id == SECTION_TRACKS and
           is_ctrl and is_shift and not is_alt then

            track_ctrl_shift_select_to_edge(-1)

        elseif is_ctrl and not is_shift and not is_alt then
            grid_ctrl_home()

        elseif not is_ctrl and not is_shift and not is_alt then
            grid_home()
        end

        return true
    end

    if char == KEY_END then
        if current_section_id == SECTION_TRACKS and
           is_ctrl and is_shift and not is_alt then

            track_ctrl_shift_select_to_edge(1)

        elseif is_ctrl and not is_shift and not is_alt then
            grid_ctrl_end()

        elseif not is_ctrl and not is_shift and not is_alt then
            grid_end()
        end

        return true
    end

    local c = safe_char(char)

    if c and not is_ctrl and not is_alt then
        c = c:lower()

        if c:match("[%w]") then
            clear_silent_edge()
            grid_cycle_by_initial(c)
            return true
        end
    end

    return true
end

------------------------------------------------------------
-- FINE PARTE 4 / 5
------------------------------------------------------------

------------------------------------------------------------
-- PARTE 5 / 5
-- HANDLER PRINCIPALE, VALIDAZIONE, USCITA, MAIN LOOP, START
-- Lo-lo + GPT per funzionalità
------------------------------------------------------------

------------------------------------------------------------
-- 5.0 - PLAY / STOP / PAUSE HELPERS
--
-- Spazio semplice:
-- - resta Play / Stop, come prima.
--
-- Ctrl+Spazio:
-- - viene letto via JS_VKeys_GetState, perché gfx.getchar()
--   può restituire 0 su questa combinazione;
-- - non usa più Main_OnCommand(40073);
-- - usa GetPlayState + OnPlayButton / OnPauseButton, cioè i
--   pulsanti reali del transport;
-- - quando Ctrl è premuto, prova a intercettare Space con
--   JS_VKeys_Intercept, così la combinazione non passa anche
--   alle scorciatoie native di REAPER.
--
-- Ctrl+P:
-- - non cambia più la modalità dello Spazio; viene assorbito
--   silenziosamente per non toccare parametri.
--
-- Nota:
-- - nello stato filtro lo Spazio semplice resta un carattere digitabile;
-- - nell'edit numerico lo Spazio semplice non comanda il transport.
------------------------------------------------------------

function transport_run_command(command_id, error_message)
    cancel_pending_speech()
    clear_silent_edge()

    if reaper.Main_OnCommand then
        reaper.Main_OnCommand(command_id, 0)
        return true
    end

    speak(error_message or "Transport command not available")
    return true
end

function transport_play_stop_from_script()
    return transport_run_command(
        CMD_PLAY_STOP,
        "Play stop command not available"
    )
end

function transport_play_pause_from_script()
    cancel_pending_speech()
    clear_silent_edge()

    local state = 0

    if reaper.GetPlayState then
        state = reaper.GetPlayState() or 0
    end

    --------------------------------------------------------
    -- GetPlayState:
    -- bit 1 = playing, bit 2 = paused, bit 4 = recording.
    -- Se sta suonando o registrando, Ctrl+Spazio deve mettere
    -- in pausa. Se è fermo o già in pausa, deve ripartire da
    -- dove si trova il cursore / dalla pausa, senza fare stop.
    --------------------------------------------------------

    local is_playing_or_recording = ((state & 1) == 1) or ((state & 4) == 4)

    if is_playing_or_recording then
        if reaper.OnPauseButton then
            reaper.OnPauseButton()
            return true
        end

        return transport_run_command(
            CMD_PLAY_PAUSE,
            "Pause command not available"
        )
    end

    if reaper.OnPlayButton then
        reaper.OnPlayButton()
        return true
    end

    return transport_run_command(
        CMD_PLAY_PAUSE,
        "Play pause command not available"
    )
end

function transport_space_from_script()
    local state = 0

    if reaper.GetPlayState then
        state = reaper.GetPlayState() or 0
    end

    --------------------------------------------------------
    -- Spazio normale deve restare Play / Stop, ma dopo una
    -- pausa fatta con Ctrl+Spazio REAPER può restare nello
    -- stato paused. In quello stato il comportamento musicale
    -- richiesto è: Spazio riparte subito, non serve una seconda
    -- pressione. Quindi paused -> OnPlayButton.
    --------------------------------------------------------

    local is_paused = (state & 2) == 2

    if is_paused and reaper.OnPlayButton then
        cancel_pending_speech()
        clear_silent_edge()
        reaper.OnPlayButton()
        return true
    end

    return transport_play_stop_from_script()
end

function ctrl_p_transport_noop()
    return true
end

------------------------------------------------------------
-- 5.0.1 - POLLING CTRL+SPAZIO VIA JS_VKeys_GetState
--
-- Ctrl+Spazio non arriva in modo affidabile da gfx.getchar():
-- nel test MK X arriva char 0, con Ctrl nei modifier e Space
-- come VK fisico 0x20.
--
-- In più, mentre Ctrl è premuto, blocchiamo Space verso REAPER
-- con JS_VKeys_Intercept. Questo evita il doppio effetto: lo
-- script fa Play/Pause e REAPER riceve anche una shortcut sua.
------------------------------------------------------------

space_transport_was_down = false
space_transport_swallow_queue = false
space_transport_intercept_active = false

function transport_space_set_intercept(want_intercept)
    if type(reaper.JS_VKeys_Intercept) ~= "function" then
        space_transport_intercept_active = false
        return false
    end

    want_intercept = want_intercept == true

    if want_intercept and not space_transport_intercept_active then
        local ok = pcall(reaper.JS_VKeys_Intercept, VK_SPACE, 1)

        if ok then
            space_transport_intercept_active = true
        end

        return ok
    end

    if not want_intercept and space_transport_intercept_active then
        pcall(reaper.JS_VKeys_Intercept, VK_SPACE, -1)
        space_transport_intercept_active = false
        return true
    end

    return true
end

function transport_space_release_intercept()
    --------------------------------------------------------
    -- Rilascio forte dello Space.
    --
    -- Con Ctrl+Space usiamo JS_VKeys_Intercept per impedire
    -- che lo spazio passi anche a REAPER.
    -- Se poi usciamo con Ctrl+Tab o la finestra viene chiusa,
    -- bisogna liberare sempre l'intercept, altrimenti lo Space
    -- può restare "rubato" anche fuori dallo script.
    --------------------------------------------------------

    if type(reaper.JS_VKeys_Intercept) == "function" then
        pcall(reaper.JS_VKeys_Intercept, VK_SPACE, -1)
    end

    space_transport_intercept_active = false
    space_transport_swallow_queue = false
    space_transport_was_down = false
end

function poll_transport_space_shortcuts()
    if type(reaper.JS_VKeys_GetState) ~= "function" then
        transport_space_release_intercept()
        space_transport_was_down = false
        return false
    end

    local state = js_vkeys_state_now()

    if state == "" then
        transport_space_release_intercept()
        space_transport_was_down = false
        return false
    end

    local space_down = (state:byte(VK_SPACE) or 0) ~= 0
    local ctrl_is_down = ((state:byte(0x11) or 0) ~= 0) or ctrl_down()
    local shift_is_down = ((state:byte(0x10) or 0) ~= 0) or shift_down()
    local alt_is_down = ((state:byte(0x12) or 0) ~= 0) or alt_down()

    local ctrl_clean_down =
        ctrl_is_down and
        not shift_is_down and
        not alt_is_down

    transport_space_set_intercept(ctrl_clean_down)

    local ctrl_space_down = space_down and ctrl_clean_down

    if ctrl_space_down and not space_transport_was_down then
        space_transport_was_down = true
        space_transport_swallow_queue = true
        return transport_play_pause_from_script()
    end

    if not ctrl_space_down then
        space_transport_was_down = false

        if not space_down then
            space_transport_swallow_queue = false
        end
    end

    return false
end

function should_swallow_space_queue_char(char)
    if not space_transport_swallow_queue then
        return false
    end

    if char ~= KEY_SPACE then
        return false
    end

    --------------------------------------------------------
    -- La coda serve solo per evitare un eventuale doppio
    -- evento della stessa pressione Ctrl+Spazio. Non deve mai
    -- mangiare il primo Spazio normale successivo.
    --------------------------------------------------------

    local space_ctrl = ctrl_down_any()
    local space_shift = shift_down_any()
    local space_alt = alt_down_any()

    space_transport_swallow_queue = false

    if space_ctrl and not space_shift and not space_alt then
        return true
    end

    return false
end

-- 5.1 - SWITCH SECTION DEFINITIVO
--
-- F1:
-- - Tracks.
--
-- F2/F3:
-- - se non ci sono send / receive, non entra.
--
-- F4:
-- - se non ci sono plugin, non entra.
-- - se ci sono plugin, entra anche senza parametri TCP visibili,
--   perché mostra comunque gli header FX.
------------------------------------------------------------

function switch_section_by_key(char, speak_it)
    if runtime_safe_blocks_function_key(char) then
        return true
    end

    local cfg = section_key_to_config(char)

    if not cfg then
        return false
    end

    cancel_pending_speech()
    clear_silent_edge()

    cursor_memory_save_current()

    if mode == "fx_param_list" or
       current_section_id == FX_PARAM_LIST_SECTION_ID then
        exit_fx_param_list(true, false)
    end

    local previous_section_key = current_section_key
    local previous_section_id = current_section_id
    local previous_grid_pos = grid_pos

    current_section_key = char
    current_section_id = cfg.id

    --------------------------------------------------------
    -- Quando si entra in F1, la griglia delle tracce parte
    -- sempre senza tracce selezionate.
    -- Il cursore interno resta sulla current_track.
    --------------------------------------------------------

    if current_section_id == SECTION_TRACKS then
        clear_track_selection_silent()
    end

    if current_section_id ~= SECTION_TRACKS and not current_track then
        current_section_key = previous_section_key
        current_section_id = previous_section_id
        grid_pos = previous_grid_pos

        build_current_grid()
        refresh_window_title()

        speak("No track")
        return true
    end

    if current_section_id == SECTION_FX_PARAMS then
        local fx_count = 0

        if current_track and reaper.TrackFX_GetCount then
            fx_count = reaper.TrackFX_GetCount(current_track) or 0
        end

        if fx_count <= 0 then
            current_section_key = previous_section_key
            current_section_id = previous_section_id
            grid_pos = previous_grid_pos

            build_current_grid()
            refresh_window_title()

            speak(get_current_track_context_label() .. ". No FX")
            return true
        end
    end

    grid_pos = 1
    cursor_memory_prepare_section_before_build(current_section_id, false)

    local ok = build_current_grid()

    if ok then
        cursor_memory_restore_after_build(current_section_id, false)
    end

    --------------------------------------------------------
    -- F2 / F3:
    -- se non ci sono send / receive, resta nella sezione
    -- precedente.
    --------------------------------------------------------

    if not ok and
       (current_section_id == SECTION_SENDS or
        current_section_id == SECTION_RECEIVES or
        current_section_id == HARDWARE_OUTPUT_SECTION_ID) then

        local failed_section_id = current_section_id
        local filter_part = ""

        if filter_is_active() then
            filter_part = " for " .. filter_query
        end

        current_section_key = previous_section_key
        current_section_id = previous_section_id
        grid_pos = previous_grid_pos

        build_current_grid()
        refresh_window_title()

        if failed_section_id == SECTION_SENDS then
            speak(get_current_track_context_label() .. ". No sends" .. filter_part)
            return true
        end

        if failed_section_id == SECTION_RECEIVES then
            speak(get_current_track_context_label() .. ". No receives" .. filter_part)
            return true
        end

        if failed_section_id == HARDWARE_OUTPUT_SECTION_ID then
            speak(get_current_track_context_label() .. ". No hardware outputs" .. filter_part)
            return true
        end
    end

    refresh_window_title()

    --------------------------------------------------------
    -- F4:
    -- normalmente ok è true se ci sono FX, perché almeno gli
    -- header FX vengono aggiunti. Questo blocco resta come
    -- protezione.
    --------------------------------------------------------

    if not ok then
        local filter_part = ""

        if filter_is_active() then
            filter_part = " for " .. filter_query
        end

        if current_section_id == SECTION_FX_PARAMS then
            speak(get_current_track_context_label() .. ". No FX parameters" .. filter_part)
            return true
        end

        current_section_key = previous_section_key
        current_section_id = previous_section_id
        grid_pos = previous_grid_pos

        build_current_grid()
        refresh_window_title()

        speak("Empty" .. filter_part)
        return true
    end

    if speak_it ~= false then
        if current_section_id == SECTION_TRACKS then
            speak_current_entry("Tracks", "track")
        else
            speak_current_entry(
                get_current_track_context_label() ..
                ". " ..
                get_section_name()
            )
        end
    end

    return true
end

------------------------------------------------------------
-- 5.2 - CHIUSURA FILTRO QUANDO SI CAMBIA SEZIONE
--
-- Se l'utente è dentro l'edit del filtro e preme F1/F2/F3/F4,
-- il filtro edit viene chiuso e poi la sezione cambia.
------------------------------------------------------------

function close_filter_edit_for_section_change()
    if not filter_edit_mode and mode ~= "filter_edit" then
        return false
    end

    --------------------------------------------------------
    -- Cambio sezione da F1/F2/F3/F4:
    -- si comporta come Esc sul campo filtro, quindi non
    -- applica il testo che si stava scrivendo. Non parla qui,
    -- perché parlerà direttamente la nuova sezione.
    --------------------------------------------------------
    filter_edit_mode = false
    filter_edit_buffer = ""
    filter_edit_cursor = 1

    mode = filter_return_mode or "grid"
    filter_return_mode = "grid"

    clear_silent_edge()

    return true
end

------------------------------------------------------------
-- 5.2A - USCITA SICURA GLOBALE PER CAMBIO SEZIONE
--
-- F1/F2/F3/F4 devono sempre liberare lo script da qualunque
-- recinto temporaneo e poi andare nella sezione richiesta.
-- La logica è: come Esc, ma in più cambia sezione.
-- Non conferma Value mode, edit numerico, alias o lista FX.
------------------------------------------------------------

function close_temporary_mode_for_section_change()
    cancel_pending_speech()
    clear_silent_edge()

    --------------------------------------------------------
    -- Filtro Ctrl+F: cancella solo l'edit in corso, non
    -- applica il testo scritto.
    --------------------------------------------------------
    if mode == "filter_edit" or filter_edit_mode then
        filter_edit_mode = false
        filter_edit_buffer = ""
        filter_edit_cursor = 1

        mode = filter_return_mode or "grid"
        filter_return_mode = "grid"
    end

    --------------------------------------------------------
    -- Alias parametro FX: annulla senza salvare.
    --------------------------------------------------------
    if mode == "fx_alias_edit" or fx_alias_edit_mode then
        fx_alias_edit_mode = false
        fx_alias_edit_buffer = ""
        fx_alias_edit_cursor = 1

        mode = fx_alias_edit_return_mode or "grid"
        fx_alias_edit_return_mode = "grid"
    end

    --------------------------------------------------------
    -- Edit numerico: annulla senza scrivere il valore.
    --------------------------------------------------------
    if mode == "numeric_edit" or edit_mode then
        edit_mode = false
        edit_buffer = ""
        edit_cursor = 1
        edit_started = false
        numeric_edit_fresh = false

        mode = numeric_return_mode or "grid"
        numeric_return_mode = "grid"
    end

    --------------------------------------------------------
    -- Value mode: esce senza fare ulteriori azioni.
    --------------------------------------------------------
    if mode == "value" then
        mode = value_return_mode or "grid"
        value_return_mode = "grid"
    end

    --------------------------------------------------------
    -- Lista parametri FX / lista visibili F6:
    -- esce come Esc, senza confermare il parametro corrente.
    --------------------------------------------------------
    if mode == "fx_param_list" or
       current_section_id == FX_PARAM_LIST_SECTION_ID then
        exit_fx_param_list(true, false)
    end

    return true
end

function section_switch_key_is_plain(char)
    return section_key_to_config(char) ~= nil and
           not ctrl_down() and
           not shift_down() and
           not alt_down()
end

function switch_section_from_anywhere(char)
    if runtime_safe_blocks_function_key(char) then
        return true
    end

    if not section_switch_key_is_plain(char) then
        return false
    end

    close_temporary_mode_for_section_change()
    switch_section_by_key(char, true)

    return true
end

------------------------------------------------------------
-- 5.2.1 - UNDO / REDO DA SCRIPT
--
-- Ctrl+Z:
-- - Undo REAPER.
--
-- Ctrl+Shift+Z:
-- - Redo REAPER.
--
-- Nessun messaggio speak qui:
-- OSARA parla già Undo / Redo.
------------------------------------------------------------

function undo_from_script()
    cancel_pending_speech()
    clear_silent_edge()

    if not reaper.Main_OnCommand then
        return true
    end

    reaper.Main_OnCommand(CMD_UNDO, 0)

    if mode ~= "filter_edit" and
       mode ~= "numeric_edit" and
       mode ~= "value" and
       not filter_edit_mode and
       not edit_mode then

        build_current_grid()
        grid_pos = clamp_int(grid_pos, 1, math.max(1, #grid_entries))
        refresh_window_title()
    end

    return true
end

function redo_from_script()
    cancel_pending_speech()
    clear_silent_edge()

    if not reaper.Main_OnCommand then
        return true
    end

    reaper.Main_OnCommand(CMD_REDO, 0)

    if mode ~= "filter_edit" and
       mode ~= "numeric_edit" and
       mode ~= "value" and
       not filter_edit_mode and
       not edit_mode then

        build_current_grid()
        grid_pos = clamp_int(grid_pos, 1, math.max(1, #grid_entries))
        refresh_window_title()
    end

    return true
end

------------------------------------------------------------
-- 5.2.2 - AZIONI REAPER DA SCRIPT
--
-- Le azioni vengono richiamate senza speech forzato:
-- quando possibile, OSARA / REAPER parlano già il risultato.
--
-- Nota importante:
-- nella 0.66 la navigazione item usava le azioni native
-- 40417 / 40416 e poi ricostruiva la finestra gfx per
-- recuperare il focus. Funzionava, ma alcuni screen reader
-- potevano leggere il titolo della finestra.
--
-- Da questa versione la navigazione item è interna allo script:
-- seleziona l'item precedente / successivo, sposta l'edit cursor,
-- aggiorna il puntatore di traccia dello script e non ricrea la
-- finestra. Ai bordi resta completamente silenziosa.
------------------------------------------------------------

function refocus_script_window_now()
    --------------------------------------------------------
    -- Solo JS_ReaScriptAPI: non usiamo più gfx.init come
    -- fallback, perché reinizializzare la finestra può far
    -- leggere il titolo allo screen reader.
    --------------------------------------------------------

    if reaper.JS_Window_Find and reaper.JS_Window_SetFocus then
        local hwnd = reaper.JS_Window_Find(title or SCRIPT_NAME, true)

        if hwnd then
            reaper.JS_Window_SetFocus(hwnd)
            return true
        end
    end

    return false
end

function refocus_script_window_deferred()
    local count = 0

    local function later()
        count = count + 1

        if count <= 3 then
            refocus_script_window_now()
            reaper.defer(later)
        end
    end

    reaper.defer(later)
end

function run_reaper_action_from_script(command_id, rebuild_grid_after, restore_focus_after)
    cancel_pending_speech()
    clear_silent_edge()

    if not reaper.Main_OnCommand then
        speak("REAPER command not available")
        return true
    end

    reaper.Main_OnCommand(command_id, 0)

    if rebuild_grid_after and
       mode ~= "filter_edit" and
       mode ~= "numeric_edit" and
       mode ~= "value" and
       not filter_edit_mode and
       not edit_mode then

        build_current_grid()
        grid_pos = clamp_int(grid_pos, 1, math.max(1, #grid_entries))
        refresh_window_title()
    end

    if restore_focus_after then
        refocus_script_window_now()
        refocus_script_window_deferred()
    end

    return true
end

function run_cursor_navigation_action_from_script(command_id)
    run_reaper_action_from_script(command_id, false, false)
    return speak_edit_cursor_after_move()
end

function get_item_track_index_on_track(item)
    if not item then
        return 0
    end

    local tr = reaper.GetMediaItem_Track(item)

    if not tr then
        return 0
    end

    local count = reaper.CountTrackMediaItems(tr) or 0

    for i = 0, count - 1 do
        local it = reaper.GetTrackMediaItem(tr, i)

        if it == item then
            return i + 1
        end
    end

    return 0
end

function get_item_name_for_speech(item)
    if not item then
        return ""
    end

    local take = reaper.GetActiveTake(item)

    if take then
        if reaper.GetTakeName then
            local name = reaper.GetTakeName(take)
            name = clean_one_line(name or "")

            if name ~= "" then
                return name
            end
        end

        if reaper.GetMediaItemTake_Source then
            local src = reaper.GetMediaItemTake_Source(take)

            if src then
                if reaper.GetMediaSourceFileName then
                    local filename = reaper.GetMediaSourceFileName(src, "")
                    filename = clean_one_line(filename or "")

                    if filename ~= "" then
                        filename = filename:gsub("^.*[\\/]", "")

                        if filename ~= "" then
                            return filename
                        end
                    end
                end

                if reaper.GetMediaSourceType then
                    local src_type = reaper.GetMediaSourceType(src, "")
                    src_type = clean_one_line(src_type or "")

                    if src_type ~= "" then
                        return src_type
                    end
                end
            end
        end
    end

    return ""
end

function speak_item_navigation_result(item)
    if not item then
        return false
    end

    local item_number = get_item_track_index_on_track(item)
    local item_name = get_item_name_for_speech(item)
    local msg = ""

    if item_number > 0 then
        msg = tostring(item_number)
    end

    if item_name ~= "" then
        if msg ~= "" then
            msg = msg .. " " .. item_name
        else
            msg = item_name
        end
    end

    if msg ~= "" then
        speak(msg)
    end

    return true
end

function sync_current_track_from_selected_item()
    if not reaper.GetSelectedMediaItem or
       not reaper.GetMediaItem_Track then
        return false
    end

    local item = reaper.GetSelectedMediaItem(0, 0)

    if not item then
        return false
    end

    local tr = reaper.GetMediaItem_Track(item)

    if not tr then
        return false
    end

    return set_current_track_pointer_only(tr)
end

function get_item_navigation_track()
    local tr = nil

    --------------------------------------------------------
    -- La navigazione item deve seguire la traccia corrente
    -- dello script, come fanno F2, F3 e F4.
    --
    -- Importante:
    -- non dare priorità alla traccia selezionata in REAPER
    -- né all'item selezionato, perché possono essere rimasti
    -- dalla navigazione precedente.
    --
    -- Se in F1 il cursore interno è su una traccia diversa,
    -- current_track contiene già quella traccia anche se REAPER
    -- non l'ha selezionata nel TCP.
    --------------------------------------------------------

    local entry = get_current_entry()

    if entry and entry.track then
        tr = entry.track
    end

    if not tr then
        tr = current_track
    end

    --------------------------------------------------------
    -- Fallback solo se lo script non ha ancora una traccia
    -- corrente valida.
    --------------------------------------------------------

    if not tr and reaper.CountSelectedTracks and reaper.GetSelectedTrack then
        local selected_count = reaper.CountSelectedTracks(0) or 0

        if selected_count > 0 then
            tr = reaper.GetSelectedTrack(0, 0)
        end
    end

    if not tr and reaper.GetSelectedMediaItem and reaper.GetMediaItem_Track then
        local selected_item = reaper.GetSelectedMediaItem(0, 0)

        if selected_item then
            tr = reaper.GetMediaItem_Track(selected_item)
        end
    end

    --------------------------------------------------------
    -- Appena parte la navigazione item, seleziona in REAPER
    -- la traccia corrente dello script. Da qui in poi gli item
    -- vengono costruiti solo da questa traccia.
    --------------------------------------------------------

    if tr and reaper.SetOnlyTrackSelected then
        reaper.SetOnlyTrackSelected(tr)
        set_current_track_pointer_only(tr)

        if reaper.TrackList_AdjustWindows then
            reaper.TrackList_AdjustWindows(false)
        end
    end

    return tr
end

function build_track_item_navigation_list(track)
    local list = {}

    if not track or
       not reaper.CountTrackMediaItems or
       not reaper.GetTrackMediaItem or
       not reaper.GetMediaItemInfo_Value then
        return list
    end

    local track_idx = get_track_index(track)
    local count = reaper.CountTrackMediaItems(track) or 0

    for i = 0, count - 1 do
        local item = reaper.GetTrackMediaItem(track, i)

        if item then
            local pos = reaper.GetMediaItemInfo_Value(item, "D_POSITION") or 0

            list[#list + 1] = {
                item = item,
                pos = tonumber(pos) or 0,
                track = track,
                track_idx = track_idx,
                project_index = i,
                selected = reaper.IsMediaItemSelected and
                           reaper.IsMediaItemSelected(item) == true
            }
        end
    end

    table.sort(
        list,
        function(a, b)
            if a.pos ~= b.pos then
                return a.pos < b.pos
            end

            return a.project_index < b.project_index
        end
    )

    return list
end

function get_item_navigation_target_index(list, direction)
    direction = tonumber(direction) or 0

    if not list or #list <= 0 or direction == 0 then
        return 0
    end

    local first_selected = 0
    local last_selected = 0

    for i = 1, #list do
        if list[i].selected then
            if first_selected == 0 then
                first_selected = i
            end

            last_selected = i
        end
    end

    if first_selected > 0 then
        if direction > 0 then
            return last_selected + 1
        end

        return first_selected - 1
    end

    --------------------------------------------------------
    -- Se nessun item è selezionato, usiamo l'edit cursor.
    --------------------------------------------------------

    local cursor = 0

    if reaper.GetCursorPosition then
        cursor = reaper.GetCursorPosition() or 0
    end

    local eps = 0.000000001

    if direction > 0 then
        for i = 1, #list do
            if list[i].pos > cursor + eps then
                return i
            end
        end
    else
        for i = #list, 1, -1 do
            if list[i].pos < cursor - eps then
                return i
            end
        end
    end

    return 0
end

function select_only_media_item_silent(item)
    if not item then
        return false
    end

    if reaper.CountMediaItems and
       reaper.GetMediaItem and
       reaper.SetMediaItemSelected then

        local count = reaper.CountMediaItems(0) or 0

        for i = 0, count - 1 do
            local it = reaper.GetMediaItem(0, i)

            if it then
                reaper.SetMediaItemSelected(it, it == item)
            end
        end
    end

    return true
end

function update_script_track_and_grid_after_item_navigation(target)
    if not target or not target.item then
        return false
    end

    if target.track then
        set_current_track_pointer_only(target.track)
    else
        sync_current_track_from_selected_item()
    end

    if mode ~= "filter_edit" and
       mode ~= "numeric_edit" and
       mode ~= "value" and
       not filter_edit_mode and
       not edit_mode then

        build_current_grid()

        if current_section_id == SECTION_TRACKS and current_track then
            local row = get_row_for_track_in_current_grid(current_track)

            if row > 0 then
                local _, col = grid_current_row_col()
                grid_pos = grid_pos_from_row_col(row, col)
            else
                grid_pos = clamp_int(grid_pos, 1, math.max(1, #grid_entries))
            end
        else
            grid_pos = clamp_int(grid_pos, 1, math.max(1, #grid_entries))
        end

        ----------------------------------------------------
        -- Non chiamiamo refresh_window_title(): la finestra
        -- non deve essere ricreata e il titolo non deve essere
        -- annunciato dallo screen reader.
        ----------------------------------------------------

        -- Lasciamo invariato anche il titolo interno, così
        -- un eventuale refocus successivo cerca ancora la
        -- finestra esistente con il suo titolo reale.
    end

    return true
end

function navigate_item_inside_script(direction)
    cancel_pending_speech()
    clear_silent_edge()

    local navigation_track = get_item_navigation_track()

    if not navigation_track then
        return true
    end

    local list = build_track_item_navigation_list(navigation_track)
    local target_index = get_item_navigation_target_index(list, direction)

    --------------------------------------------------------
    -- Bordo: nessun messaggio, nessuna ricostruzione finestra.
    --------------------------------------------------------

    if target_index < 1 or target_index > #list then
        return true
    end

    local target = list[target_index]

    if not target or not target.item then
        return true
    end

    if reaper.PreventUIRefresh then
        reaper.PreventUIRefresh(1)
    end

    if target.track and reaper.SetOnlyTrackSelected then
        reaper.SetOnlyTrackSelected(target.track)
        set_current_track_pointer_only(target.track)
    end

    select_only_media_item_silent(target.item)

if reaper.SetEditCurPos then
    reaper.SetEditCurPos(target.pos or 0, true, true)
end    

    update_script_track_and_grid_after_item_navigation(target)

    if reaper.PreventUIRefresh then
        reaper.PreventUIRefresh(-1)
    end

if reaper.UpdateArrange then
    reaper.UpdateArrange()
end

speak_item_navigation_result(target.item)

return true
end

function collect_project_markers_sorted()
    local markers = {}

    if not reaper.CountProjectMarkers or not reaper.EnumProjectMarkers then
        return markers
    end

    local _, marker_count, region_count = reaper.CountProjectMarkers(0)
    local total = (tonumber(marker_count) or 0) + (tonumber(region_count) or 0)

    for i = 0, total - 1 do
        local ok, is_region, pos, rgn_end, name, marker_index =
            reaper.EnumProjectMarkers(i)

        if ok and not is_region then
            markers[#markers + 1] = {
                pos = tonumber(pos) or 0,
                name = clean_one_line(name or ""),
                index = tonumber(marker_index) or 0
            }
        end
    end

    table.sort(markers, function(a, b)
        if a.pos == b.pos then
            return (a.index or 0) < (b.index or 0)
        end

        return (a.pos or 0) < (b.pos or 0)
    end)

    return markers
end

function marker_spoken_label(marker, ordinal)
    if not marker then
        return "No marker"
    end

    local number = tonumber(marker.index) or ordinal or 0
    local name = clean_one_line(marker.name or "")
    local text = "Marker " .. tostring(number)

    if name ~= "" then
        text = text .. " " .. name
    end

    text = text .. ". " .. get_timeline_speech(marker.pos or 0)

    return text
end

function move_edit_cursor_to_marker(marker, ordinal)
    if not marker then
        speak("No marker")
        return true
    end

    if reaper.SetEditCurPos then
        reaper.SetEditCurPos(marker.pos or 0, true, true)
    end

    speak(marker_spoken_label(marker, ordinal))

    return true
end

function go_to_marker_ordinal_from_script(ordinal)
    ordinal = clamp_int(ordinal, 1, 10)

    local markers = collect_project_markers_sorted()

    if #markers <= 0 then
        speak("No markers")
        return true
    end

    --------------------------------------------------------
    -- Prima cerca il numero reale del marker REAPER.
    -- Se non esiste, usa la posizione ordinata come fallback,
    -- così Ctrl+1..0 resta utile anche con marker rinumerati.
    --------------------------------------------------------
    for i = 1, #markers do
        if tonumber(markers[i].index) == ordinal then
            return move_edit_cursor_to_marker(markers[i], i)
        end
    end

    if ordinal <= #markers then
        return move_edit_cursor_to_marker(markers[ordinal], ordinal)
    end

    speak("No marker " .. tostring(ordinal))
    return true
end

function go_to_relative_marker_from_script(direction)
    direction = tonumber(direction) or 0

    if direction == 0 then
        return false
    end

    local markers = collect_project_markers_sorted()

    if #markers <= 0 then
        speak("No markers")
        return true
    end

    local pos = get_current_timeline_position_for_speech()
    local epsilon = 0.000001
    local target = nil
    local ordinal = 0

    if direction > 0 then
        for i = 1, #markers do
            if (markers[i].pos or 0) > pos + epsilon then
                target = markers[i]
                ordinal = i
                break
            end
        end
    else
        for i = #markers, 1, -1 do
            if (markers[i].pos or 0) < pos - epsilon then
                target = markers[i]
                ordinal = i
                break
            end
        end
    end

    if not target then
        if direction > 0 then
            target = markers[#markers]
            ordinal = #markers
        else
            target = markers[1]
            ordinal = 1
        end
    end

    return move_edit_cursor_to_marker(target, ordinal)
end

ctrl_number_marker_poll_last = {}
ctrl_number_marker_last_ordinal = 0
ctrl_number_marker_last_time = 0

function js_vkey_state_byte(state, vk)
    if not state or state == "" then
        return 0
    end

    return state:byte(tonumber(vk) or 0) or 0
end

function js_vkey_down_from_state(state, vk)
    return js_vkey_state_byte(state, vk) ~= 0
end

function poll_ctrl_number_markers_js()
    if type(reaper.JS_VKeys_GetState) ~= "function" then
        return false
    end

    if mode == "filter_edit" or
       mode == "numeric_edit" or
       mode == "fx_alias_edit" or
       filter_edit_mode or
       edit_mode or
       fx_alias_edit_mode then
        return false
    end

    local state = reaper.JS_VKeys_GetState(-2)

    if not state or state == "" then
        return false
    end

    local ctrl = js_vkey_down_from_state(state, 0x11) or ctrl_down_any()
    local shift = js_vkey_down_from_state(state, 0x10) or shift_down_any()
    local alt = js_vkey_down_from_state(state, 0x12) or alt_down_any()

    if not ctrl or shift or alt then
        ctrl_number_marker_poll_last = {}
        return false
    end

    local fired = false

    for ordinal = 1, 10 do
        local vk_main = ordinal == 10 and 0x30 or (0x30 + ordinal)
        local vk_num = ordinal == 10 and 0x60 or (0x60 + ordinal)
        local down = js_vkey_down_from_state(state, vk_main) or
                     js_vkey_down_from_state(state, vk_num)

        if down and not ctrl_number_marker_poll_last[ordinal] then
            ctrl_number_marker_poll_last[ordinal] = true
            ctrl_number_marker_last_ordinal = ordinal
            ctrl_number_marker_last_time = reaper.time_precise and reaper.time_precise() or 0
            go_to_marker_ordinal_from_script(ordinal)
            fired = true
        elseif not down then
            ctrl_number_marker_poll_last[ordinal] = false
        end
    end

    return fired
end

function handle_marker_navigation_key(char)
    local is_ctrl = ctrl_down()
    local is_shift = shift_down()
    local is_alt = alt_down()

    if not is_ctrl or is_shift or is_alt then
        return false
    end

    if char == KEY_CTRL_I then
        return go_to_relative_marker_from_script(-1)
    end

    if char == KEY_CTRL_O then
        return go_to_relative_marker_from_script(1)
    end

    local c = safe_char(char)

    if c then
        local ordinal = nil

        if c >= "1" and c <= "9" then
            ordinal = tonumber(c)
        elseif c == "0" then
            ordinal = 10
        end

        if ordinal then
            local now = reaper.time_precise and reaper.time_precise() or 0

            if ctrl_number_marker_last_ordinal == ordinal and
               now - (ctrl_number_marker_last_time or 0) < 0.12 then
                return true
            end

            return go_to_marker_ordinal_from_script(ordinal)
        end
    end

    return false
end

function handle_global_reaper_navigation_action(char)
    local is_ctrl = ctrl_down()
    local is_shift = shift_down()
    local is_alt = alt_down()

    --------------------------------------------------------
    -- Marker navigation.
    -- Ctrl+1..0 = marker 1..10 ordinati per posizione.
    -- Ctrl+I / Ctrl+O = marker precedente / successivo.
    --------------------------------------------------------

    if handle_marker_navigation_key(char) then
        return true
    end

    --------------------------------------------------------
    -- Item navigation.
    --------------------------------------------------------

    if is_ctrl and not is_shift and not is_alt and char == KEY_RIGHT then
        return navigate_item_inside_script(1)
    end

    if is_ctrl and not is_shift and not is_alt and char == KEY_LEFT then
        return navigate_item_inside_script(-1)
    end

    --------------------------------------------------------
    -- Edit cursor by measure / beat.
    -- Dopo il comando leggiamo sempre la posizione completa:
    -- Bar, beat e percentuale dentro il beat.
    --------------------------------------------------------

    if is_shift and is_alt and not is_ctrl and char == KEY_PAGE_DOWN then
        return run_cursor_navigation_action_from_script(CMD_CURSOR_FORWARD_MEASURE)
    end

    if is_shift and is_alt and not is_ctrl and char == KEY_PAGE_UP then
        return run_cursor_navigation_action_from_script(CMD_CURSOR_BACK_MEASURE)
    end

    if is_ctrl and not is_shift and not is_alt and char == KEY_PAGE_DOWN then
        return run_cursor_navigation_action_from_script(CMD_CURSOR_FORWARD_BEAT)
    end

    if is_ctrl and not is_shift and not is_alt and char == KEY_PAGE_UP then
        return run_cursor_navigation_action_from_script(CMD_CURSOR_BACK_BEAT)
    end

    if is_ctrl and is_shift and is_alt and char == KEY_PAGE_DOWN then
        return run_cursor_navigation_action_from_script(CMD_CURSOR_NEXT_MEASURE_START)
    end

    if is_ctrl and is_shift and is_alt and char == KEY_PAGE_UP then
        return run_cursor_navigation_action_from_script(CMD_CURSOR_CURRENT_PREVIOUS_MEASURE_START)
    end

    return false
end

------------------------------------------------------------
-- 5.3 - HANDLER PRINCIPALE TASTI
------------------------------------------------------------


------------------------------------------------------------
-- 4.Z - PASSAGGIO AL FRATELLO FX PARAMS
--
-- Ctrl+Tab:
--   salva/chiude silenziosamente questo script e apre
--   Speak FX Params - TrackTake Navigator.lua.
------------------------------------------------------------

function get_current_script_path()
    local source = debug.getinfo(1, "S").source or ""

    if source:sub(1, 1) == "@" then
        source = source:sub(2)
    end

    return source
end

function get_current_script_folder()
    local path = get_current_script_path()

    if path == "" then
        return ""
    end

    local folder = path:match("^(.*)[/\\][^/\\]+$")

    return folder or ""
end

function file_exists(path)
    path = tostring(path or "")

    if path == "" then
        return false
    end

    local f = io.open(path, "rb")

    if f then
        f:close()
        return true
    end

    return false
end

function join_system_path(a, b)
    a = tostring(a or "")
    b = tostring(b or "")

    if a == "" then
        return b
    end

    if b == "" then
        return a
    end

    local sep = package.config:sub(1, 1)

    if a:sub(-1) == "/" or a:sub(-1) == "\\" then
        return a .. b
    end

    return a .. sep .. b
end

function get_sibling_script_path(filename)
    filename = clean_one_line(filename or "")

    if filename == "" then
        return ""
    end

    local folder = get_current_script_folder()

    if folder == "" then
        return ""
    end

    return join_system_path(folder, filename)
end

function get_reaper_utility_folder_for_script_switch()
    local resource = ""

    if reaper.GetResourcePath then
        resource = reaper.GetResourcePath() or ""
    end

    if resource == "" then
        return ""
    end

    return join_system_path(
        join_system_path(
            join_system_path(resource, "Scripts"),
            "Lo-lo - Scripts"
        ),
        "Utility"
    )
end

function get_utility_script_path(filename)
    filename = clean_one_line(filename or "")

    if filename == "" then
        return ""
    end

    local utility = get_reaper_utility_folder_for_script_switch()

    if utility == "" then
        return ""
    end

    return join_system_path(utility, filename)
end

function get_utility_scripts_folder_path(filename)
    filename = clean_one_line(filename or "")

    if filename == "" then
        return ""
    end

    local utility = get_reaper_utility_folder_for_script_switch()

    if utility == "" then
        return ""
    end

    return join_system_path(
        join_system_path(utility, "Scripts"),
        filename
    )
end

function get_legacy_fx_subfolder_script_path(filename)
    filename = clean_one_line(filename or "")

    if filename == "" then
        return ""
    end

    local utility = get_reaper_utility_folder_for_script_switch()

    if utility == "" then
        return ""
    end

    return join_system_path(
        join_system_path(utility, "Speak FX Params - TrackTake Navigator"),
        filename
    )
end

function recursive_find_script_file(root, filename, depth)
    root = tostring(root or "")
    filename = clean_one_line(filename or "")
    depth = tonumber(depth) or 0

    if root == "" or filename == "" then
        return ""
    end

    if depth > 5 then
        return ""
    end

    local direct = join_system_path(root, filename)

    if file_exists(direct) then
        return direct
    end

    if type(reaper.EnumerateSubdirectories) ~= "function" then
        return ""
    end

    local i = 0

    while true do
        local sub = reaper.EnumerateSubdirectories(root, i)

        if not sub then
            break
        end

        local found = recursive_find_script_file(
            join_system_path(root, sub),
            filename,
            depth + 1
        )

        if found ~= "" and file_exists(found) then
            return found
        end

        i = i + 1
    end

    return ""
end

function get_fx_params_script_path()
    local filename = "Speak FX Params - TrackTake Navigator.lua"

    --------------------------------------------------------
    -- 1) Fratello nella stessa cartella del Track Params.
    -- Questa è la soluzione più robusta quando la suite viene
    -- spostata tutta insieme.
    --------------------------------------------------------
    local sibling_path = get_sibling_script_path(filename)

    if file_exists(sibling_path) then
        return sibling_path
    end

    --------------------------------------------------------
    -- 2) Nuova cartella comune:
    -- Scripts/Lo-lo - Scripts/Utility/Scripts/
    --------------------------------------------------------
    local utility_scripts_path = get_utility_scripts_folder_path(filename)

    if file_exists(utility_scripts_path) then
        return utility_scripts_path
    end

    --------------------------------------------------------
    -- 3) Vecchio percorso con sottocartella FX Params.
    --------------------------------------------------------
    local legacy_subfolder_path = get_legacy_fx_subfolder_script_path(filename)

    if file_exists(legacy_subfolder_path) then
        return legacy_subfolder_path
    end

    --------------------------------------------------------
    -- 4) Vecchio percorso piatto dentro Utility.
    --------------------------------------------------------
    local utility_path = get_utility_script_path(filename)

    if file_exists(utility_path) then
        return utility_path
    end

    --------------------------------------------------------
    -- 5) Ricerca ricorsiva dentro Utility.
    -- Così se sposti FX Params in una sottocartella diversa,
    -- Track Params può ancora trovarlo.
    --------------------------------------------------------
    local utility = get_reaper_utility_folder_for_script_switch()
    local recursive_path = recursive_find_script_file(utility, filename, 0)

    if recursive_path ~= "" and file_exists(recursive_path) then
        return recursive_path
    end

    --------------------------------------------------------
    -- Se non esiste nulla, restituiamo il percorso più probabile
    -- per avere un errore coerente.
    --------------------------------------------------------
    if utility_scripts_path ~= "" then
        return utility_scripts_path
    end

    if sibling_path ~= "" then
        return sibling_path
    end

    return utility_path
end


------------------------------------------------------------
-- BACKGROUND LIVE CC MODE
--
-- Ctrl+Q:
--   esce dal focus della finestra gfx,
--   riporta il focus verso REAPER/TCP,
--   ma NON chiude il defer dello script.
--
-- Scopo:
--   replicare il comportamento naturale di quando la finestra
--   perde focus ma lo script continua a vivere: i CC devono
--   continuare a muovere il parametro.
------------------------------------------------------------

background_focus_mode = false

function release_keyboard_intercepts_before_background()
    if type(transport_space_release_intercept) == "function" then
        transport_space_release_intercept()
    end

    return true
end

function focus_reaper_tcp_from_script()
    if type(reaper.SetCursorContext) == "function" then
        pcall(reaper.SetCursorContext, 0, nil)
    end

    if type(reaper.JS_Window_GetMainHwnd) == "function" then
        local hwnd = reaper.JS_Window_GetMainHwnd()

        if hwnd and hwnd ~= 0 then
            if type(reaper.JS_Window_SetForeground) == "function" then
                pcall(reaper.JS_Window_SetForeground, hwnd)
            end

            if type(reaper.JS_Window_SetFocus) == "function" then
                pcall(reaper.JS_Window_SetFocus, hwnd)
            end

            return true
        end
    end

    return true
end


function background_live_poll_tick()
    --------------------------------------------------------
    -- Script senza focus, ma ancora vivo:
    -- non leggiamo più i tasti da gfx, però continuiamo
    -- a leggere il Floating CC.
    --------------------------------------------------------

    if type(transport_space_release_intercept) == "function" then
        transport_space_release_intercept()
    end

    local fixed_handled = false

    if type(track_fixed_cc_poll_recent_input) == "function" then
        fixed_handled = track_fixed_cc_poll_recent_input() == true
    end

    if not fixed_handled and type(floating_cc_poll_recent_input) == "function" then
        floating_cc_poll_recent_input()
    end

    return true
end

function leave_script_focus_to_tcp_background()
    background_focus_mode = true

    release_keyboard_intercepts_before_background()

    if type(cancel_pending_speech) == "function" then
        cancel_pending_speech()
    end

    if type(speak) == "function" then
        speak("Back to REAPER")
    end

    focus_reaper_tcp_from_script()

    return true
end

function background_defer_loop_tick()
    background_live_poll_tick()
    reaper.defer(main_loop)
    return true
end


function close_script_silent_for_external_window()
    if type(transport_space_release_intercept) == "function" then
        transport_space_release_intercept()
    end

    if type(cursor_memory_save_current) == "function" then
        cursor_memory_save_current()
    end

    if type(track_memory_save_session_slot) == "function" then
        -- No-op intenzionale: le memorie traccia vengono già
        -- salvate quando cambiano. Qui lasciamo solo il gancio.
    end

    gfx.quit()
end

function run_reascript_by_path_silent(path)
    path = tostring(path or "")

    if path == "" or not file_exists(path) then
        speak("Script not found")
        return false
    end

    if type(reaper.AddRemoveReaScript) ~= "function" then
        speak("Script switch not available")
        return false
    end

    local cmd = reaper.AddRemoveReaScript(true, 0, path, true)

    if not cmd or tonumber(cmd) == 0 then
        speak("Script action not found")
        return false
    end

    close_script_silent_for_external_window()
    reaper.Main_OnCommand(cmd, 0)

    return true
end

function get_current_track_for_ctrl_tab_fx_switch()
    local tr = nil

    if type(get_current_entry) == "function" then
        local e = get_current_entry()

        if e and e.track then
            tr = e.track
        end
    end

    if not tr then
        tr = current_track
    end

    if not tr then
        tr = reaper.GetSelectedTrack(0, 0)
    end

    return tr
end

function current_track_has_fx_for_ctrl_tab_fx_switch()
    local tr = get_current_track_for_ctrl_tab_fx_switch()

    if not tr then
        speak("No track")
        return false
    end

    local count = 0

    if reaper.TrackFX_GetCount then
        count = reaper.TrackFX_GetCount(tr) or 0
    end

    if count <= 0 then
        speak("No FX found for track")
        return false
    end

    return true
end

function prepare_track_for_ctrl_tab_fx_switch(track)
    if not track then
        return false
    end

    --------------------------------------------------------
    -- Ctrl+Tab deve consegnare a FX Params una traccia reale
    -- e chiara. Durante la normale navigazione F1 il cursore
    -- resta virtuale; solo al momento del passaggio al fratello
    -- FX Params sincronizziamo REAPER selezionando la traccia
    -- sotto il cursore.
    --------------------------------------------------------

    set_current_track_pointer_only(track)

    if reaper.SetOnlyTrackSelected then
        reaper.SetOnlyTrackSelected(track)
    else
        local count = get_project_track_count()

        for i = 0, count - 1 do
            local tr = get_track_by_index(i)

            if tr then
                reaper.SetTrackSelected(tr, tr == track)
            end
        end
    end

    if reaper.TrackList_AdjustWindows then
        reaper.TrackList_AdjustWindows(false)
    end

    if reaper.UpdateArrange then
        reaper.UpdateArrange()
    end

    return true
end

function switch_to_fx_params_script()
    --------------------------------------------------------
    -- Importante:
    -- non chiudere Track Params se FX Params non potrà aprire
    -- nulla. In caso di traccia senza FX restiamo qui, così
    -- Ctrl+Tab non lascia l'utente senza nessuno dei due script.
    --
    -- Se la traccia sotto il cursore ha FX, prima la rendiamo
    -- la traccia realmente selezionata in REAPER. Così FX Params
    -- parte sempre dal contesto corretto, anche se l'utente non
    -- ha selezionato manualmente la traccia con Shift+Space.
    --------------------------------------------------------

    local tr = get_current_track_for_ctrl_tab_fx_switch()

    if not tr then
        speak("No track")
        return true
    end

    local count = 0

    if reaper.TrackFX_GetCount then
        count = reaper.TrackFX_GetCount(tr) or 0
    end

    if count <= 0 then
        speak("No FX found for track")
        return true
    end

    prepare_track_for_ctrl_tab_fx_switch(tr)

    return run_reascript_by_path_silent(get_fx_params_script_path())
end

function ctrl_tab_to_fx_params_key(char)
    local is_ctrl = ctrl_down_any()
    local is_shift = shift_down_any()
    local is_alt = alt_down_any()

    if not is_ctrl or is_shift or is_alt or char ~= KEY_TAB then
        return false
    end

    if type(reaper.JS_VKeys_GetState) == "function" then
        return js_vkey_down_now(VK_TAB) and not js_vkey_down_now(VK_I)
    end

    return true
end


function handle_key(char)
    if char == 0 or char == nil then
        return false
    end

    if runtime_safe_blocks_function_key(char) then
        return true
    end

    --------------------------------------------------------
    -- ESC durante Ctrl+Alt+C / Fixed CC learn:
    -- disarma il learn e ritorna allo script, senza uscire.
    --------------------------------------------------------

    if char == KEY_ESC and
       type(track_fixed_cc_cancel_learn) == "function" and
       track_fixed_cc_cancel_learn(true) then

        return true
    end

    --------------------------------------------------------
    -- Delete cancella una memoria traccia solo se è il tasto
    -- immediatamente successivo. Qualunque altro tasto disarma.
    --------------------------------------------------------

    if char ~= KEY_DELETE then
        track_memory_clear_delete_arm()
    end

    --------------------------------------------------------
    -- Ctrl+Alt+Shift+F1 globale.
    --------------------------------------------------------

    if ctrl_down() and shift_down() and alt_down() and char == KEY_F1 then
        speak_script_version()
        return true
    end

    --------------------------------------------------------
    -- Ctrl+Q globale:
    -- lascia Track Params vivo in background, con CC attivi,
    -- e torna a REAPER/TCP.
    --------------------------------------------------------

    if char == KEY_CTRL_Q then
        leave_script_focus_to_tcp_background()
        return true
    end

    --------------------------------------------------------
    -- Ctrl+Tab globale: passa al fratello FX Params.
    --------------------------------------------------------

    if ctrl_tab_to_fx_params_key(char) then
        return switch_to_fx_params_script()
    end

    --------------------------------------------------------
    -- Ctrl+Shift+J globale:
    -- legge la posizione reale di ascolto.
    -- Se REAPER è in play, usa il play cursor in movimento.
    -- Se REAPER è fermo, usa il cursore di modifica.
    --------------------------------------------------------

    if ctrl_down() and shift_down() and not alt_down() and char == KEY_CTRL_J then
        return speak_current_timeline_position()
    end

    --------------------------------------------------------
    -- Shift+C globale:
    -- attiva/disattiva la mappa dei CC fissi salvati nel TXT.
    -- Di default la mappa resta spenta, come in FX Params.
    --------------------------------------------------------

    if not ctrl_down() and shift_down() and not alt_down() and char == KEY_C then
        return track_fixed_cc_toggle_map()
    end

    --------------------------------------------------------
    -- Ctrl+Alt+C globale sui parametri traccia supportati:
    -- impara un CC fisso salvato nel TXT Tracks.
    -- Ctrl+C resta libero per la copia tracce.
    --------------------------------------------------------

    if ctrl_down() and not shift_down() and alt_down() and
       (char == KEY_CTRL_C or char == KEY_CTRL_ALT_C) then

        if track_fixed_cc_ctrl_alt_c() then
            return true
        end
    end

    --------------------------------------------------------
    -- Ctrl+Delete globale fuori da F1:
    -- cancella tutta la piccola mappa dei CC fissi Track.
    -- In F1 mantiene anche il comportamento storico più sotto.
    --------------------------------------------------------

    if ctrl_down() and not shift_down() and not alt_down() and
       char == KEY_DELETE and current_section_id ~= SECTION_TRACKS then

        if type(track_fixed_cc_clear_all_links) == "function" then
            return track_fixed_cc_clear_all_links(true)
        end
    end

    --------------------------------------------------------
    -- Ctrl+Shift+C globale:
    -- CC fluttuante solo sessione REAPER.
    --------------------------------------------------------

    if ctrl_down() and shift_down() and not alt_down() and char == KEY_CTRL_C then
        floating_cc_toggle_or_arm()
        return true
    end

    --------------------------------------------------------
    -- Ctrl+T globale:
    -- abilita/disabilita il parlato CC solo per il parametro corrente.
    -- In gfx.getchar(), Ctrl+T arriva come 20.
    --------------------------------------------------------

    if ctrl_down() and not shift_down() and not alt_down() and char == 20 then
        return track_cc_param_speech_toggle_current()
    end

    --------------------------------------------------------
    -- Ctrl+Shift+M: attiva / disattiva i titoli dettagliati
    -- della finestra invisibile.
    --
    -- Nota: in gfx Ctrl+M usa lo stesso codice di Enter.
    -- Ctrl+Shift+M può quindi coincidere con Ctrl+Shift+Enter;
    -- lo usiamo come comando globale perché Ctrl+Shift+Enter
    -- non è una funzione operativa dello script.
    --------------------------------------------------------

    if ctrl_down() and
       shift_down() and
       not alt_down() and
       char == KEY_CTRL_M then

        return title_detail_toggle_enabled()
    end

    --------------------------------------------------------
    -- Ctrl+M reale globale:
    -- abilita / disabilita la memoria automatica delle
    -- posizioni logiche del cursore in qualunque sezione griglia,
    -- compresa F4 FX parameters.
    --
    -- Ctrl+M viene distinto da Enter / Ctrl+Enter usando
    -- JS_VKeys_GetState: il comando scatta solo se il tasto
    -- fisico M è realmente premuto. Quindi Ctrl+Enter in F4
    -- resta libero per le sue funzioni e non attiva la memoria.
    --------------------------------------------------------

    if real_ctrl_m_key(char) then
        ----------------------------------------------------
        -- Dentro la lista parametri FX Ctrl+M deve essere
        -- assorbito e basta. Senza questo blocco, siccome
        -- gfx.getchar vede Ctrl+M come codice 13, la lista lo
        -- può trattare come Ctrl+Enter e aggiungere/togliere
        -- il parametro dai Track Controls.
        ----------------------------------------------------
        if mode == "fx_param_list" or
           current_section_id == FX_PARAM_LIST_SECTION_ID then
            return true
        end

        if mode == "grid" or
           mode == "pin_audio" or
           mode == "pin_midi" then
            return cursor_memory_toggle_enabled()
        end

        return true
    end

    --------------------------------------------------------
    -- Undo / Redo globali dentro lo script.
    --
    -- Ctrl+Z = Undo.
    -- Ctrl+Shift+Z = Redo.
    --
    -- Li lasciamo prima delle modalità filtro / edit numerico
    -- solo se vogliamo intercettarli sempre.
    -- OSARA parla già il risultato.
    --------------------------------------------------------

    if ctrl_down() and not alt_down() and char == KEY_CTRL_Z then
        if shift_down() then
            return redo_from_script()
        end

        return undo_from_script()
    end

    --------------------------------------------------------
    -- F5 Audio Pin Connector.
    -- Va gestito prima del cambio sezione globale, così F4/Esc
    -- possono tornare ordinatamente alla lista FX.
    --------------------------------------------------------

    if mode == "pin_audio" or current_section_id == PIN_AUDIO_SECTION_ID then
        return handle_pin_audio_key(char)
    end

    if mode == "pin_midi" or current_section_id == PIN_MIDI_SECTION_ID then
        return handle_pin_midi_key(char)
    end

    --------------------------------------------------------
    -- Cambio sezione globale da qualunque recinto interno.
    -- F1/F2/F3/F4 fanno sempre: Esc silenzioso + sezione.
    --------------------------------------------------------

    if switch_section_from_anywhere(char) then
        return true
    end

    --------------------------------------------------------
    -- Edit alias parametro FX F4.
    --------------------------------------------------------

    if mode == "fx_alias_edit" or fx_alias_edit_mode then
        return handle_fx_alias_edit_key(char)
    end

    --------------------------------------------------------
    -- Modalità filtro.
    --
    -- Qui lo Spazio deve restare disponibile come carattere
    -- del filtro. Il transport non viene intercettato.
    --------------------------------------------------------

    if mode == "filter_edit" or filter_edit_mode then
        return handle_filter_edit_key(char)
    end

    --------------------------------------------------------
    -- Edit numerico.
    --
    -- Qui lo Spazio non comanda il transport.
    --------------------------------------------------------

    if mode == "numeric_edit" or edit_mode then
        return handle_numeric_edit_key(char)
    end

    --------------------------------------------------------
    -- Ctrl+Shift+Alt+A globale:
    -- pulisce tutte le automazioni della traccia corrente.
    -- Ctrl+Shift+A resta libero per l'automazione del
    -- singolo controllo in F1/F2/F3/F4.
    --------------------------------------------------------

    if automation_clear_shortcut_key(char) then
        return clear_all_automation_for_current_track()
    end

    --------------------------------------------------------
    -- Trasporto globale interno allo script.
    --------------------------------------------------------

    if ctrl_down() and
       not shift_down() and
       not alt_down() and
       char == KEY_CTRL_P then

        return ctrl_p_transport_noop()
    end

    if char == KEY_SPACE then
        local space_ctrl = ctrl_down_any()
        local space_shift = shift_down_any()
        local space_alt = alt_down_any()

        if space_ctrl and not space_shift and not space_alt then
            return transport_play_pause_from_script()
        end

        ----------------------------------------------------
        -- F1: Shift+Spazio seleziona / deseleziona la traccia
        -- corrente sotto il cursore logico dello script.
        -- Lasciamo anche Ctrl+Shift+Spazio come compatibilità,
        -- ma il comando principale richiesto è Shift+Spazio.
        ----------------------------------------------------

        if current_section_id == SECTION_TRACKS and
           mode == "grid" and
           space_shift and
           not space_alt then

            return toggle_current_cursor_track_selection_f1()
        end

        if not space_ctrl and not space_shift and not space_alt then
            return transport_space_from_script()
        end
    end

    --------------------------------------------------------
    -- Azioni REAPER globali di navigazione.
    --
    -- Sono dopo filtro / edit numerico, così non disturbano
    -- la scrittura, ma prima di Value mode e delle griglie.
    --------------------------------------------------------

    if handle_global_reaper_navigation_action(char) then
        return true
    end

    --------------------------------------------------------
    -- Value mode.
    --------------------------------------------------------

    if mode == "value" then
        return handle_value_mode_key(char)
    end


    --------------------------------------------------------
    -- F6 Track MIDI.
    --
    -- F6 ora appartiene alla traccia corrente, non a un FX.
    -- Non deve quindi controllare pin_midi_fx_index né cercare
    -- un plug-in. Se siamo nella pagina F6, passa direttamente
    -- al gestore Track MIDI.
    --------------------------------------------------------

    if mode == "pin_midi" or current_section_id == PIN_MIDI_SECTION_ID then
        return handle_pin_midi_key(char)
    end

    --------------------------------------------------------
    -- Lista parametri FX.
    --------------------------------------------------------

    if mode == "fx_param_list" or
       current_section_id == FX_PARAM_LIST_SECTION_ID then
        return handle_fx_param_list_key(char)
    end

    --------------------------------------------------------
    -- Session Track Memories.
    --
    -- Attive solo nella griglia F1 e F4.
    -- F2, F3 e lista parametri FX non hanno accesso.
    --------------------------------------------------------

    if track_memory_handle_key(char) then
        return true
    end

    --------------------------------------------------------
    -- Griglia normale.
    --------------------------------------------------------

    return handle_grid_key(char)
end

------------------------------------------------------------
-- 5.4 - ESISTENZA TRACCIA SENZA FILTRO FOLDER-AWARE
--
-- Serve a F2/F3/F4:
-- una traccia dentro una folder chiusa può essere ancora valida
-- come traccia corrente.
------------------------------------------------------------

function current_track_exists_anywhere(track)
    if not track then
        return false
    end

    local count = get_project_track_count()

    for i = 0, count - 1 do
        local tr = get_track_by_index(i)

        if tr == track then
            return true
        end
    end

    return false
end

------------------------------------------------------------
-- 5.5 - VALIDAZIONE CONTESTO RUNTIME
------------------------------------------------------------

function validate_runtime_context()
    --------------------------------------------------------
    -- Non ricostruire mentre l'utente scrive o modifica valori.
    --------------------------------------------------------

    if mode == "filter_edit" or filter_edit_mode then
        return true
    end

    if mode == "numeric_edit" or edit_mode then
        return true
    end

    if mode == "value" then
        return true
    end

    --------------------------------------------------------
    -- F5 Audio Pin Connector.
    --------------------------------------------------------

    if mode == "pin_audio" or current_section_id == PIN_AUDIO_SECTION_ID then
        if not current_track_exists_anywhere(pin_audio_track) then
            exit_pin_audio_to_f4(false)
            speak("Track not found")
            return true
        end

        local fx_count = 0

        if pin_audio_track and reaper.TrackFX_GetCount then
            fx_count = reaper.TrackFX_GetCount(pin_audio_track) or 0
        end

        if pin_audio_fx_index < 0 or pin_audio_fx_index >= fx_count then
            exit_pin_audio_to_f4(false)
            speak("FX not found")
            return true
        end

        return true
    end


    --------------------------------------------------------
    -- F6 Track MIDI.
    --
    -- F6 riguarda la traccia corrente. Non dipende da un FX,
    -- quindi qui controlliamo solo che la traccia sia ancora
    -- valida nel progetto.
    --------------------------------------------------------

    if mode == "pin_midi" or current_section_id == PIN_MIDI_SECTION_ID then
        pin_midi_track = pin_midi_current_track()

        if not current_track_exists_anywhere(pin_midi_track) then
            mode = "grid"
            current_section_key = KEY_F1
            current_section_id = SECTION_TRACKS
            grid_pos = 1

            if select_first_track() then
                build_current_grid()
                refresh_window_title()
                speak("Track changed. Tracks")
                return true
            end

            speak("No tracks")
            gfx.quit()
            return false
        end

        return true
    end

    --------------------------------------------------------
    -- Lista parametri FX.
    --------------------------------------------------------

    if mode == "fx_param_list" or
       current_section_id == FX_PARAM_LIST_SECTION_ID then

        if not current_track_exists_anywhere(current_track) then
            mode = "grid"
            current_section_key = KEY_F1
            current_section_id = SECTION_TRACKS
            grid_pos = 1

            if select_first_track() then
                build_current_grid()
                refresh_window_title()
                speak("Track changed. Tracks")
                return true
            end

            speak("No tracks")
            gfx.quit()
            return false
        end

        local fx_count = 0

        if current_track and reaper.TrackFX_GetCount then
            fx_count = reaper.TrackFX_GetCount(current_track) or 0
        end

        ----------------------------------------------------
        -- La lista "Visible parameters" aperta da F4 con F6
        -- non appartiene a un singolo FX: usa
        -- fx_param_list_fx_index = -1 apposta.
        -- Quindi non deve passare dal controllo "FX not found".
        ----------------------------------------------------
        local is_f4_visible_group_list =
            fx_param_list_view_mode == "visible_group" and
            (tonumber(fx_param_list_fx_index) or -1) < 0 and
            fx_param_list_return_section_id == SECTION_FX_PARAMS

        if not is_f4_visible_group_list then
            if fx_param_list_fx_index < 0 or
               fx_param_list_fx_index >= fx_count then

                exit_fx_param_list(true, false)

                if current_section_id == SECTION_FX_PARAMS then
                    build_current_grid()
                    refresh_window_title()
                    speak("FX not found")
                    return true
                end

                switch_section_by_key(KEY_F1, true)
                return true
            end
        end

        return true
    end

    --------------------------------------------------------
    -- F1 Tracks.
    --------------------------------------------------------

    if current_section_id == SECTION_TRACKS then
        if #grid_entries > 0 then
            local e = get_current_entry()

            if e and e.track then
                if current_track ~= e.track then
                    set_current_track_pointer_only(e.track)
                end

                return true
            end
        end

        if current_track and current_track_still_exists() then
            return true
        end

        if select_first_track() then
            build_current_grid()
            refresh_window_title()
            clear_silent_edge()

            return true
        end

        speak("No tracks")
        gfx.quit()

        return false
    end

    --------------------------------------------------------
    -- F2 / F3 / F4.
    --------------------------------------------------------

    if current_track_exists_anywhere(current_track) then
        return true
    end

    if select_first_track() then
        switch_section_by_key(KEY_F1, true)
        return true
    end

    speak("No tracks")
    gfx.quit()

    return false
end

------------------------------------------------------------
-- 5.6 - USCITA SCRIPT
------------------------------------------------------------

function select_script_track_on_exit()
    local tr = nil
    local entry = get_current_entry()

    if entry and entry.track then
        tr = entry.track
    else
        tr = current_track
    end

    if not tr then
        return false
    end

    if not current_track_exists_anywhere(tr) then
        return false
    end

    if reaper.SetOnlyTrackSelected then
        reaper.SetOnlyTrackSelected(tr)
    else
        local count = get_project_track_count()

        for i = 0, count - 1 do
            local candidate = get_track_by_index(i)

            if candidate then
                reaper.SetTrackSelected(candidate, candidate == tr)
            end
        end
    end

    current_track = tr
    current_track_guid = get_track_guid(tr)

    local n = get_track_number(tr)

    if n > 0 then
        track_index = n - 1
    end

    reaper.TrackList_AdjustWindows(false)
    reaper.UpdateArrange()

    return true
end

function get_exit_track_spoken_label(track)
    if not track then
        return "No track"
    end

    local number = get_track_number(track)
    local name = get_track_name(track)

    if name ~= "" then
        return tostring(number) .. ". " .. name
    end

    if number > 0 then
        return "Track " .. tostring(number)
    end

    return "No track"
end

function speak_after_exit_window_closes(msg)
    msg = clean_one_line(msg or "")

    if msg == "" then
        return false
    end

    --------------------------------------------------------
    -- Dopo gfx.quit REAPER riprende il focus e può parlare
    -- il titolo/finestra corrente. Un messaggio breve come
    -- "Exit" spesso riusciva a passare; un nome traccia più
    -- lungo poteva essere interrotto.
    -- Qui parliamo subito dopo il ritorno del focus a REAPER.
    --------------------------------------------------------

    local start_time = reaper.time_precise and reaper.time_precise() or 0

    local function later()
        local now = reaper.time_precise and reaper.time_precise() or start_time

        if now - start_time >= 0.06 then
            speak(msg)
            return
        end

        reaper.defer(later)
    end

    reaper.defer(later)

    return true
end

function exit_script()
    cancel_pending_speech()
    clear_silent_edge()

    cursor_memory_save_current()

    local selected_on_exit = select_script_track_on_exit()
    local exit_track_message = "No track"

    if selected_on_exit and current_track then
        exit_track_message = get_exit_track_spoken_label(current_track)
    end

    if routing_pending_reset then
        routing_pending_reset()
    end

    if fx_param_list_clear_filter then
        fx_param_list_clear_filter()
    end

    fx_param_list_return_section_key = KEY_F4
    fx_param_list_return_section_id = SECTION_FX_PARAMS
    fx_param_list_return_grid_pos = 1

    fx_param_list_fx_index = -1
    fx_param_list_fx_name = ""

    edit_mode = false
    edit_buffer = ""
    edit_cursor = 1
    edit_started = false
    numeric_edit_fresh = false
    numeric_return_mode = "grid"

    filter_edit_mode = false
    filter_edit_buffer = ""
    filter_edit_cursor = 1
    filter_return_mode = "grid"

    value_return_mode = "grid"

    mode = "grid"

    track_selection_reset_stroke()

    if type(track_txt_save_if_dirty) == "function" then
        track_txt_save_if_dirty(true)
    end

    gfx.quit()
    speak_after_exit_window_closes(exit_track_message)
end



------------------------------------------------------------
-- 5.6A - FIXED CC MAP ESTESA / OVERRIDE
--
-- Mappa libera 0..127.
-- F1/F2/F3 restano funzioni deterministiche, ma non hanno
-- CC obbligati. F4 può usare mappa Plugin oppure ProjectTrack.
-- ProjectTrack crea anche Tracks/Projects/Default/F4 quando il
-- progetto non è ancora salvato.
------------------------------------------------------------

TRACK_CC_TXT_VERSION = "2"
TRACK_FIXED_CC_CHANNEL_DEFAULT = 1
TRACK_FIXED_CC_FIRST = 0
TRACK_FIXED_CC_LAST = 127

TRACK_FIXED_CC_MAIN_SECTIONS = {
    Track = true,
    Sends = true,
    Receives = true,
    ["FXParams.Plugin"] = true
}

TRACK_FIXED_CC_SIMPLE_FILE_KEYS = {
    volume = "Volume",
    pan = "Pan",
    width = "Width",
    mute = "Mute",
    solo = "Solo",
    phase = "PhaseInvert"
}

TRACK_FIXED_CC_SIMPLE_LABELS = {
    Track = {
        volume = "Track Volume",
        pan = "Track Pan",
        width = "Track Width",
        mute = "Track Mute",
        solo = "Track Solo",
        phase = "Track Phase invert"
    },
    Sends = {
        volume = "Send Volume",
        pan = "Send Pan",
        mute = "Send Mute"
    },
    Receives = {
        volume = "Receive Volume",
        pan = "Receive Pan",
        mute = "Receive Mute"
    }
}

function track_fixed_cc_sanitize_filename(name)
    name = clean_one_line(name or "")

    if name == "" then
        name = "Track"
    end

    name = name:gsub(":", " - ")
    name = name:gsub("[/\\%*%?\"<>|]", " - ")
    name = name:gsub("[%c]", " ")
    name = name:gsub("%s+", " ")
    name = name:gsub("^%s+", "")
    name = name:gsub("%s+$", "")
    name = name:gsub("^%.*", "")
    name = name:gsub("%.*$", "")

    if name == "" then
        name = "Track"
    end

    if #name > 140 then
        name = trim(name:sub(1, 140))
    end

    return name
end

function track_fixed_cc_get_project_name()
    local path = ""

    if reaper.EnumProjects then
        local ok, _, proj_path = pcall(reaper.EnumProjects, -1, "")

        if ok then
            path = tostring(proj_path or "")
        end
    end

    if path == "" then
        return "Default"
    end

    local name = path:match("([^/\\]+)$") or path
    name = name:gsub("%.rpp$", "")
    name = name:gsub("%.RPP$", "")
    name = track_fixed_cc_sanitize_filename(name)

    if name == "" then
        name = "Default"
    end

    return name
end

function track_fixed_cc_get_projects_folder()
    return track_txt_join_path(track_txt_get_folder(), "Projects")
end

function track_fixed_cc_get_project_folder(project_name)
    project_name = track_fixed_cc_sanitize_filename(project_name or track_fixed_cc_get_project_name())

    if project_name == "" then
        project_name = "Default"
    end

    return track_txt_join_path(track_fixed_cc_get_projects_folder(), project_name)
end

function track_fixed_cc_get_project_f4_folder(project_name)
    return track_txt_join_path(track_fixed_cc_get_project_folder(project_name), "F4")
end

function track_fixed_cc_ensure_dir(path)
    path = tostring(path or "")

    if path == "" then
        return false
    end

    if reaper.RecursiveCreateDirectory then
        reaper.RecursiveCreateDirectory(path, 0)
        return true
    end

    os.execute('mkdir "' .. path .. '"')
    return true
end

function track_txt_ensure_folder()
    local root = track_txt_get_folder()

    if root == "" then
        return false
    end

    track_fixed_cc_ensure_dir(root)
    track_fixed_cc_ensure_dir(track_fixed_cc_get_projects_folder())
    track_fixed_cc_ensure_dir(track_fixed_cc_get_project_folder("Default"))
    track_fixed_cc_ensure_dir(track_fixed_cc_get_project_f4_folder("Default"))
    track_fixed_cc_ensure_dir(track_fixed_cc_get_project_folder(track_fixed_cc_get_project_name()))
    track_fixed_cc_ensure_dir(track_fixed_cc_get_project_f4_folder(track_fixed_cc_get_project_name()))

    return true
end

function track_fixed_cc_track_file_label(track)
    local number = 0

    if track and reaper.GetMediaTrackInfo_Value then
        local ok, v = pcall(reaper.GetMediaTrackInfo_Value, track, "IP_TRACKNUMBER")

        if ok then
            number = math.floor((tonumber(v) or 0) + 0.5)
        end
    end

    if number < 1 then
        number = 0
    end

    local name = "Track"

    if track and reaper.GetTrackName then
        local ok, _, tr_name = pcall(reaper.GetTrackName, track)

        if ok then
            tr_name = clean_one_line(tr_name or "")

            if tr_name ~= "" then
                name = tr_name
            end
        end
    end

    name = track_fixed_cc_sanitize_filename(name)

    if number > 0 then
        return string.format("%02d - %s.txt", number, name)
    end

    return name .. ".txt"
end

function track_fixed_cc_get_project_track_f4_path(track)
    local project_name = track_fixed_cc_get_project_name()
    local folder = track_fixed_cc_get_project_f4_folder(project_name)

    track_fixed_cc_ensure_dir(folder)

    return track_txt_join_path(folder, track_fixed_cc_track_file_label(track))
end

function track_fixed_cc_reset_main_data()
    track_txt_data = {
        version = TRACK_CC_TXT_VERSION,
        f4_scope = "ProjectTrack",
        sections = {
            Track = {},
            Sends = {},
            Receives = {},
            ["FXParams.Plugin"] = {}
        },
        fixed_cc = {}
    }
end

function track_txt_reset_data()
    track_fixed_cc_reset_main_data()
end

function track_fixed_cc_normalize_simple_key(section, key)
    section = clean_one_line(section or "")
    key = clean_one_line(key or "")
    key = key:gsub("%s+", "")
    key = key:gsub("_", "")
    key = key:gsub("%-", "")
    key = key:lower()

    if section == "Track" then
        return TRACK_FIXED_CC_KEY_TO_ID[key] or ""
    end

    if section == "Sends" or section == "Receives" then
        if key == "volume" then return "volume" end
        if key == "pan" then return "pan" end
        if key == "mute" then return "mute" end
    end

    return clean_one_line(key or "")
end

function track_txt_load_from_text(txt)
    track_fixed_cc_reset_main_data()

    txt = tostring(txt or "")

    local section = ""

    for line in txt:gmatch("[^\r\n]+") do
        line = trim(line)

        if line ~= "" then
            if line:sub(1, 1) == "#" then
                -- commento
            elseif line:sub(1, 1) == "[" and line:sub(-1) == "]" then
                section = clean_one_line(line:sub(2, -2))
            else
                local key, value = track_txt_parse_kv(line)

                if key and key ~= "" then
                    if section == "Settings" then
                        if key == "F4CCScope" then
                            value = clean_one_line(value or "")

                            if value ~= "Plugin" and value ~= "ProjectTrack" then
                                value = "ProjectTrack"
                            end

                            track_txt_data.f4_scope = value
                        end
                    elseif key == "Version" then
                        track_txt_data.version = clean_one_line(value or "")
                    elseif key == "F4CCScope" then
                        value = clean_one_line(value or "")

                        if value == "Plugin" or value == "ProjectTrack" then
                            track_txt_data.f4_scope = value
                        end
                    elseif TRACK_FIXED_CC_MAIN_SECTIONS[section] then
                        local ch, cc = track_fixed_cc_parse_text(value)

                        if ch and cc then
                            local id = key

                            if section ~= "FXParams.Plugin" then
                                id = track_fixed_cc_normalize_simple_key(section, key)
                            end

                            if id ~= "" then
                                track_txt_data.sections[section][id] = track_fixed_cc_make_text(ch, cc)
                            end
                        end
                    elseif section == "FixedCC" then
                        ----------------------------------------------------
                        -- Compatibilità vecchio TXT: lo leggiamo come [Track].
                        ----------------------------------------------------
                        local id = track_fixed_cc_normalize_simple_key("Track", key)
                        local ch, cc = track_fixed_cc_parse_text(value)

                        if id ~= "" and ch and cc then
                            track_txt_data.sections.Track[id] = track_fixed_cc_make_text(ch, cc)
                        end
                    end
                end
            end
        end
    end

    track_txt_data.fixed_cc = track_txt_data.sections.Track
end

function track_fixed_cc_line_for_simple_section(lines, section, order)
    lines[#lines + 1] = ""
    lines[#lines + 1] = "[" .. section .. "]"

    local map = track_txt_data.sections[section] or {}

    for _, id in ipairs(order) do
        local key = TRACK_FIXED_CC_SIMPLE_FILE_KEYS[id] or id
        local value = map[id] or ""

        if trim(value) ~= "" then
            lines[#lines + 1] = track_txt_make_kv(key, value)
        else
            lines[#lines + 1] = key .. "="
        end
    end
end

function track_txt_build_text()
    local lines = {}

    lines[#lines + 1] = "# Speak Track Params - TrackTake Navigator"
    lines[#lines + 1] = "# Fixed CC map. Values are Channel,CC. No parameter values are stored here."
    lines[#lines + 1] = "# F4CCScope can be Plugin or ProjectTrack."
    lines[#lines + 1] = ""
    lines[#lines + 1] = track_txt_make_kv("Version", TRACK_CC_TXT_VERSION)
    lines[#lines + 1] = track_txt_make_kv("F4CCScope", track_txt_data.f4_scope or "ProjectTrack")

    track_fixed_cc_line_for_simple_section(lines, "Track", {
        "volume", "pan", "width", "mute", "solo", "phase"
    })

    track_fixed_cc_line_for_simple_section(lines, "Sends", {
        "volume", "pan", "mute"
    })

    track_fixed_cc_line_for_simple_section(lines, "Receives", {
        "volume", "pan", "mute"
    })

    lines[#lines + 1] = ""
    lines[#lines + 1] = "[FXParams.Plugin]"

    local fxmap = track_txt_data.sections["FXParams.Plugin"] or {}
    local keys = {}

    for key, value in pairs(fxmap) do
        if trim(value or "") ~= "" then
            keys[#keys + 1] = key
        end
    end

    table.sort(keys)

    for _, key in ipairs(keys) do
        lines[#lines + 1] = track_txt_make_kv(key, fxmap[key])
    end

    lines[#lines + 1] = ""

    return table.concat(lines, "\n")
end

function track_fixed_cc_project_f4_read_map(track)
    local state = track_project_f4_read_state(track)
    return state.cc or {}
end

function track_fixed_cc_project_f4_write_map(track, map)
    local state = track_project_f4_read_state(track)
    state.cc = map or {}
    return track_project_f4_write_state(track, state)
end

------------------------------------------------------------
-- 5.6B - F4 PARAMETER ORDER PER PROJECT / TRACK
--
-- Shift+Up / Shift+Down in F4 moves only the selected FX
-- parameter inside the current track's F4 list.
-- The order is saved in the same project/track TXT used by
-- ProjectTrack F4 CCs:
-- Tracks/Projects/<Project>/F4/<track>.txt
------------------------------------------------------------

function track_project_f4_safe_key_part(s)
    s = clean_one_line(s or "")
    s = s:gsub("=", " - ")
    s = s:gsub("|", " - ")
    s = s:gsub("%s+", " ")
    s = trim(s)

    if s == "" then
        s = "FX"
    end

    if #s > 120 then
        s = trim(s:sub(1, 120))
    end

    return s
end

function f4_order_fx_key(track, fx_index)
    fx_index = tonumber(fx_index) or 0
    local name = ""

    if track then
        name = fx_get_name(track, fx_index)
    end

    name = track_project_f4_safe_key_part(name)

    return tostring(fx_index) .. " - " .. name
end

function f4_order_encode_list(list)
    local out = {}

    for i = 1, #(list or {}) do
        local v = tonumber(list[i])

        if v ~= nil and v >= 0 then
            out[#out + 1] = tostring(math.floor(v + 0.5))
        end
    end

    return table.concat(out, ",")
end

function f4_order_decode_list(txt)
    local out = {}
    local seen = {}

    for token in tostring(txt or ""):gmatch("[^,%s]+") do
        local v = tonumber(token)

        if v ~= nil then
            v = math.floor(v + 0.5)

            if v >= 0 and not seen[v] then
                seen[v] = true
                out[#out + 1] = v
            end
        end
    end

    return out
end

function track_project_f4_read_state(track)
    local path = track_fixed_cc_get_project_track_f4_path(track)
    local txt = track_txt_read_file(path)
    local state = {
        cc = {},
        order = {}
    }

    if txt ~= nil then
        local section = ""

        for line in tostring(txt or ""):gmatch("[^\r\n]+") do
            line = trim(line)

            if line ~= "" then
                if line:sub(1, 1) == "#" then
                    -- commento
                elseif line:sub(1, 1) == "[" and line:sub(-1) == "]" then
                    section = clean_one_line(line:sub(2, -2))
                else
                    local key, value = track_txt_parse_kv(line)

                    if key and key ~= "" then
                        if section == "FXParams" then
                            local ch, cc = track_fixed_cc_parse_text(value)

                            if ch and cc then
                                state.cc[key] = track_fixed_cc_make_text(ch, cc)
                            end
                        elseif section == "F4Order" then
                            local list = f4_order_decode_list(value)

                            if #list > 0 then
                                state.order[key] = list
                            end
                        end
                    end
                end
            end
        end
    end

    return state
end

function track_project_f4_write_state(track, state)
    state = state or {}

    local path = track_fixed_cc_get_project_track_f4_path(track)
    local cc_map = state.cc or {}
    local order_map = state.order or {}
    local lines = {}

    lines[#lines + 1] = "# Speak Track Params - TrackTake Navigator"
    lines[#lines + 1] = "# ProjectTrack F4 storage. CC values are Channel,CC. F4Order stores visible FX parameter order."
    lines[#lines + 1] = ""
    lines[#lines + 1] = track_txt_make_kv("Version", TRACK_CC_TXT_VERSION)
    lines[#lines + 1] = track_txt_make_kv("Project", track_fixed_cc_get_project_name())
    lines[#lines + 1] = track_txt_make_kv("TrackName", get_track_short_label(track))
    lines[#lines + 1] = track_txt_make_kv("TrackGUID", get_track_guid(track))
    lines[#lines + 1] = ""
    lines[#lines + 1] = "[FXParams]"

    local cc_keys = {}

    for key, value in pairs(cc_map or {}) do
        if trim(value or "") ~= "" then
            cc_keys[#cc_keys + 1] = key
        end
    end

    table.sort(cc_keys)

    for _, key in ipairs(cc_keys) do
        lines[#lines + 1] = track_txt_make_kv(key, cc_map[key])
    end

    lines[#lines + 1] = ""
    lines[#lines + 1] = "[F4Order]"

    local order_keys = {}

    for key, list in pairs(order_map or {}) do
        if type(list) == "table" and #list > 0 then
            order_keys[#order_keys + 1] = key
        end
    end

    table.sort(order_keys)

    for _, key in ipairs(order_keys) do
        lines[#lines + 1] = track_txt_make_kv(key, f4_order_encode_list(order_map[key]))
    end

    lines[#lines + 1] = ""

    return track_txt_write_file(path, table.concat(lines, "\n"))
end

function f4_order_get_saved_list(track, fx_index)
    if not track then
        return {}
    end

    local state = track_project_f4_read_state(track)
    local key = f4_order_fx_key(track, fx_index)

    return state.order[key] or {}
end

function f4_order_save_list(track, fx_index, list)
    if not track then
        return false
    end

    local state = track_project_f4_read_state(track)
    local key = f4_order_fx_key(track, fx_index)

    if type(list) == "table" and #list > 0 then
        state.order[key] = list
    else
        state.order[key] = nil
    end

    return track_project_f4_write_state(track, state)
end

function f4_order_apply_to_visible_params(track, fx_index, visible_params)
    visible_params = visible_params or {}

    if not track or #visible_params <= 1 then
        return visible_params
    end

    local saved = f4_order_get_saved_list(track, fx_index)

    if #saved <= 0 then
        return visible_params
    end

    local available = {}
    local result = {}
    local used = {}

    for i = 1, #visible_params do
        local p = tonumber(visible_params[i])

        if p ~= nil then
            p = math.floor(p + 0.5)
            available[p] = true
        end
    end

    for i = 1, #saved do
        local p = tonumber(saved[i])

        if p ~= nil then
            p = math.floor(p + 0.5)

            if available[p] and not used[p] then
                used[p] = true
                result[#result + 1] = p
            end
        end
    end

    for i = 1, #visible_params do
        local p = tonumber(visible_params[i])

        if p ~= nil then
            p = math.floor(p + 0.5)

            if not used[p] then
                used[p] = true
                result[#result + 1] = p
            end
        end
    end

    return result
end

function f4_order_current_param_pos(list, param_index)
    param_index = tonumber(param_index) or -1

    for i = 1, #(list or {}) do
        if tonumber(list[i]) == param_index then
            return i
        end
    end

    return 0
end

function f4_order_find_grid_pos(track, fx_index, param_index)
    for pos = 1, #grid_entries do
        local e = grid_entries[pos]

        if e and
           e.kind == "fx_param" and
           e.track == track and
           tonumber(e.fx_index) == tonumber(fx_index) and
           tonumber(e.param_index) == tonumber(param_index) then

            return pos
        end
    end

    return 0
end

function f4_order_move_current_param(direction)
    if current_section_id ~= SECTION_FX_PARAMS or mode ~= "grid" then
        return false
    end

    direction = tonumber(direction) or 0

    if direction == 0 then
        return false
    end

    local e = get_current_entry()

    if not e or e.kind ~= "fx_param" then
        speak("Only FX parameters can be moved")
        return true
    end

    local track = e.track or current_track
    local fx_index = tonumber(e.fx_index) or -1
    local param_index = tonumber(e.param_index) or -1

    if not track or fx_index < 0 or param_index < 0 then
        speak("No FX parameter")
        return true
    end

    local visible = get_fx_tcp_visible_param_indices(track, fx_index)
    visible = f4_order_apply_to_visible_params(track, fx_index, visible)

    local pos = f4_order_current_param_pos(visible, param_index)

    if pos <= 0 then
        speak("Parameter order not available")
        return true
    end

    local new_pos = pos + (direction > 0 and 1 or -1)

    if new_pos < 1 then
        return grid_edge("f4-param-order-top")
    end

    if new_pos > #visible then
        return grid_edge("f4-param-order-bottom")
    end

    visible[pos], visible[new_pos] = visible[new_pos], visible[pos]

    if not f4_order_save_list(track, fx_index, visible) then
        speak("Parameter order save failed")
        return true
    end

    build_current_grid()

    local wanted_pos = f4_order_find_grid_pos(track, fx_index, param_index)

    if wanted_pos > 0 then
        grid_pos = wanted_pos
    else
        grid_pos = clamp_int(grid_pos, 1, math.max(1, #grid_entries))
    end

    clear_silent_edge()
    refresh_window_title()

    if direction < 0 then
        speak("Moved up. " .. current_entry_contextual_label())
    else
        speak("Moved down. " .. current_entry_contextual_label())
    end

    return true
end

function track_fixed_cc_get_f4_scope()
    local scope = clean_one_line(track_txt_data and track_txt_data.f4_scope or "")

    if scope ~= "Plugin" and scope ~= "ProjectTrack" then
        scope = "ProjectTrack"
    end

    return scope
end

function track_fixed_cc_fx_key_for_entry(e)
    if not e or e.kind ~= "fx_param" then
        return ""
    end

    local fx_name = ""

    if e.track and e.fx_index ~= nil then
        fx_name = fx_get_name(e.track, e.fx_index)
    end

    fx_name = clean_one_line(fx_name or "")

    if fx_name == "" then
        fx_name = "Unknown FX"
    end

    local param_index = tonumber(e.param_index) or 0
    local param_name = make_entry_label(e)

    if param_name == "" then
        param_name = "Param " .. tostring(param_index + 1)
    end

    return fx_name .. "|" .. tostring(param_index) .. ":" .. param_name
end

function track_fixed_cc_info_for_entry(e)
    if not e then
        return nil
    end

    if e.kind == "track_param" then
        local id = clean_one_line(e.id or "")

        if TRACK_FIXED_CC_SIMPLE_LABELS.Track[id] then
            return {
                storage = "main",
                section = "Track",
                key = id,
                label = TRACK_FIXED_CC_SIMPLE_LABELS.Track[id],
                entry = e,
                simple_id = id
            }
        end
    end

    if e.kind == "send_param" then
        local id = clean_one_line(e.id or "")

        if id == "volume" or id == "pan" or id == "mute" then
            if e.category == 0 then
                return {
                    storage = "main",
                    section = "Sends",
                    key = id,
                    label = TRACK_FIXED_CC_SIMPLE_LABELS.Sends[id],
                    entry = e,
                    simple_id = id
                }
            elseif e.category == -1 then
                return {
                    storage = "main",
                    section = "Receives",
                    key = id,
                    label = TRACK_FIXED_CC_SIMPLE_LABELS.Receives[id],
                    entry = e,
                    simple_id = id
                }
            end
        end
    end

    if e.kind == "fx_param" then
        local key = track_fixed_cc_fx_key_for_entry(e)

        if key ~= "" then
            local scope = track_fixed_cc_get_f4_scope()

            if scope == "Plugin" then
                return {
                    storage = "main",
                    section = "FXParams.Plugin",
                    key = key,
                    label = make_entry_label(e),
                    entry = e,
                    simple_id = "fx"
                }
            end

            return {
                storage = "project_f4",
                section = "FXParams",
                key = key,
                label = make_entry_label(e),
                entry = e,
                simple_id = "fx"
            }
        end
    end

    return nil
end

function track_fixed_cc_current_info()
    return track_fixed_cc_info_for_entry(get_current_entry())
end

function track_fixed_cc_get_link_info(info)
    if not info then
        return nil, nil
    end

    if info.storage == "project_f4" then
        local map = track_fixed_cc_project_f4_read_map(info.entry and info.entry.track or current_track)
        return track_fixed_cc_parse_text(map[info.key] or "")
    end

    local section_map = track_txt_data.sections and track_txt_data.sections[info.section] or nil

    if not section_map then
        return nil, nil
    end

    return track_fixed_cc_parse_text(section_map[info.key] or "")
end

function track_fixed_cc_set_link_info(info, channel, cc)
    if not info then
        return false
    end

    if not track_fixed_cc_storage_available() then
        track_txt_load()
    end

    channel = clamp_int(channel, 1, 16)
    cc = clamp_int(cc, 0, 127)

    if info.storage == "project_f4" then
        local track = info.entry and info.entry.track or current_track
        local map = track_fixed_cc_project_f4_read_map(track)
        map[info.key] = track_fixed_cc_make_text(channel, cc)
        track_fixed_cc_project_f4_write_map(track, map)
        return true
    end

    if not track_txt_data.sections then
        track_fixed_cc_reset_main_data()
    end

    if not track_txt_data.sections[info.section] then
        track_txt_data.sections[info.section] = {}
    end

    track_txt_data.sections[info.section][info.key] = track_fixed_cc_make_text(channel, cc)
    track_txt_data.fixed_cc = track_txt_data.sections.Track
    track_txt_mark_dirty()
    track_txt_save_if_dirty(true)

    return true
end

function track_fixed_cc_remove_link_info(info)
    if not info then
        return false
    end

    if info.storage == "project_f4" then
        local track = info.entry and info.entry.track or current_track
        local map = track_fixed_cc_project_f4_read_map(track)

        if trim(map[info.key] or "") == "" then
            return false
        end

        map[info.key] = ""
        track_fixed_cc_project_f4_write_map(track, map)
        return true
    end

    local section_map = track_txt_data.sections and track_txt_data.sections[info.section] or nil

    if not section_map or trim(section_map[info.key] or "") == "" then
        return false
    end

    section_map[info.key] = ""
    track_txt_data.fixed_cc = track_txt_data.sections.Track
    track_txt_mark_dirty()
    track_txt_save_if_dirty(true)

    return true
end

function track_fixed_cc_all_main_maps_for_current_context()
    local maps = {}

    if not track_txt_data.sections then
        return maps
    end

    maps[#maps + 1] = track_txt_data.sections.Track or {}

    if current_section_id == SECTION_SENDS then
        maps[#maps + 1] = track_txt_data.sections.Sends or {}
    elseif current_section_id == SECTION_RECEIVES then
        maps[#maps + 1] = track_txt_data.sections.Receives or {}
    elseif current_section_id == SECTION_FX_PARAMS then
        maps[#maps + 1] = track_txt_data.sections["FXParams.Plugin"] or {}
    end

    return maps
end

function track_fixed_cc_cc_is_used_in_current_context(channel, cc)
    channel = clamp_int(channel, 1, 16)
    cc = clamp_int(cc, 0, 127)

    for _, map in ipairs(track_fixed_cc_all_main_maps_for_current_context()) do
        for _, txt in pairs(map or {}) do
            local ch2, cc2 = track_fixed_cc_parse_text(txt)

            if ch2 == channel and cc2 == cc then
                return true
            end
        end
    end

    if current_section_id == SECTION_FX_PARAMS and track_fixed_cc_get_f4_scope() == "ProjectTrack" then
        local map = track_fixed_cc_project_f4_read_map(current_track)

        for _, txt in pairs(map or {}) do
            local ch2, cc2 = track_fixed_cc_parse_text(txt)

            if ch2 == channel and cc2 == cc then
                return true
            end
        end
    end

    return false
end

function track_fixed_cc_label_for_duplicate(section, key)
    section = clean_one_line(section or "")
    key = clean_one_line(key or "")

    if key == "" then
        return ""
    end

    if section == "Track" then
        return TRACK_FIXED_CC_SIMPLE_LABELS.Track[key] or track_fixed_cc_label(key)
    end

    if section == "Sends" then
        return TRACK_FIXED_CC_SIMPLE_LABELS.Sends[key] or clean_one_line(key)
    end

    if section == "Receives" then
        return TRACK_FIXED_CC_SIMPLE_LABELS.Receives[key] or clean_one_line(key)
    end

    --------------------------------------------------------
    -- F4 FX params:
    -- la chiave contiene anche FX e indice, per esempio:
    -- Pro-Q|12:Band 1 Gain
    -- Nel parlato del trasferimento serve solo il nome parametro.
    --------------------------------------------------------
    if section == "FXParams.Plugin" or section == "FXParams" then
        local label = key:match("^[^:]*:(.+)$")
        label = clean_one_line(label or "")

        if label ~= "" then
            return label
        end
    end

    return key
end

function track_fixed_cc_clear_duplicate_cc_in_context(info, channel, cc)
    if not info then
        return 0, {}
    end

    channel = clamp_int(channel, 1, 16)
    cc = clamp_int(cc, 0, 127)

    local changed_main = false
    local removed_count = 0
    local removed_labels = {}

    if track_txt_data.sections then
        for section, map in pairs(track_txt_data.sections) do
            for key, txt in pairs(map or {}) do
                local ch2, cc2 = track_fixed_cc_parse_text(txt)

                if ch2 == channel and cc2 == cc then
                    local same =
                        info.storage == "main" and
                        info.section == section and
                        info.key == key

                    if not same then
                        local old_label = track_fixed_cc_label_for_duplicate(section, key)

                        if old_label ~= "" then
                            removed_labels[#removed_labels + 1] = old_label
                        end

                        map[key] = ""
                        changed_main = true
                        removed_count = removed_count + 1
                    end
                end
            end
        end
    end

    if changed_main then
        track_txt_mark_dirty()
        track_txt_save_if_dirty(true)
    end

    if current_track and track_fixed_cc_get_f4_scope() == "ProjectTrack" then
        local map = track_fixed_cc_project_f4_read_map(current_track)
        local changed_project = false

        for key, txt in pairs(map or {}) do
            local ch2, cc2 = track_fixed_cc_parse_text(txt)

            if ch2 == channel and cc2 == cc then
                local same =
                    info.storage == "project_f4" and
                    info.key == key

                if not same then
                    local old_label = track_fixed_cc_label_for_duplicate("FXParams", key)

                    if old_label ~= "" then
                        removed_labels[#removed_labels + 1] = old_label
                    end

                    map[key] = ""
                    changed_project = true
                    removed_count = removed_count + 1
                end
            end
        end

        if changed_project then
            track_fixed_cc_project_f4_write_map(current_track, map)
        end
    end

    return removed_count, removed_labels
end

function track_fixed_cc_finish_learn(channel, cc_number, cc_value)
    channel = tonumber(channel) or -1
    cc_number = tonumber(cc_number) or -1
    cc_value = clamp01(cc_value)

    if channel < 1 or channel > 16 or cc_number < 0 or cc_number > 127 then
        speak("Invalid CC")
        return true
    end

    local info = track_fixed_cc_learn_target_info

    if not info then
        info = track_fixed_cc_current_info()
    end

    if not info then
        track_fixed_cc_learn_armed = false
        track_fixed_cc_learn_target_info = nil
        speak("No parameter")
        return true
    end

    local removed_duplicates, duplicate_labels =
        track_fixed_cc_clear_duplicate_cc_in_context(
            info,
            channel,
            cc_number
        )

    track_fixed_cc_set_link_info(info, channel, cc_number)

    track_fixed_cc_learn_armed = false
    track_fixed_cc_learn_target_info = nil
    track_fixed_cc_learn_target_id = ""
    track_fixed_cc_learn_target_label = ""
    track_fixed_cc_last_seq = select(1, floating_cc_read_recent_event()) or 0
    track_fixed_cc_clear_pickup()

    if type(floating_cc_clear_session) == "function" then
        floating_cc_clear_session()
    end

    local msg =
        "Learned. Channel " ..
        tostring(channel) ..
        " CC " ..
        tostring(cc_number) ..
        ". "

    removed_duplicates = tonumber(removed_duplicates) or 0

    if removed_duplicates > 0 then
        if removed_duplicates == 1 then
            local old_label = ""

            if type(duplicate_labels) == "table" then
                old_label = clean_one_line(duplicate_labels[1] or "")
            end

            if old_label ~= "" then
                msg = msg .. "Moved from " .. old_label .. ". "
            else
                msg = msg .. "Removed from one other parameter. "
            end
        else
            msg =
                msg ..
                "Removed from " ..
                tostring(removed_duplicates) ..
                " other parameters. "
        end
    end

    msg = msg .. clean_one_line(info.label or "")

    speak(msg)

    return true
end

function track_fixed_cc_ctrl_alt_c()
    cancel_pending_speech()
    clear_silent_edge()

    if track_fixed_cc_cancel_learn(true) then
        return true
    end

    if not track_fixed_cc_storage_available() then
        track_txt_load()
    end

    local info = track_fixed_cc_current_info()

    if not info then
        speak("No parameter")
        return true
    end

    track_fixed_cc_learn_target_info = info
    track_fixed_cc_learn_target_id = tostring(info.key or "")
    track_fixed_cc_learn_target_label = info.label or ""
    track_fixed_cc_learn_armed = true
    track_fixed_cc_last_seq = select(1, floating_cc_read_recent_event()) or 0

    speak("CC learn. Move a MIDI control")

    return true
end

function track_fixed_cc_clear_all_links(speak_it)
    --------------------------------------------------------
    -- Ora Ctrl+Delete lavora sul parametro corrente in F1/F2/F3/F4.
    -- Se non c'è un target mappabile, pulisce tutta la mappa principale.
    --------------------------------------------------------
    if not track_fixed_cc_storage_available() then
        track_txt_load()
    end

    local info = track_fixed_cc_current_info()

    if info then
        local ch, cc = track_fixed_cc_get_link_info(info)

        if ch and cc then
            track_fixed_cc_remove_link_info(info)
            track_fixed_cc_clear_pickup()

            if speak_it then
                speak("Fixed CC removed. " .. info.label)
            end

            return true
        end

        if speak_it then
            speak("No fixed CC on " .. info.label)
        end

        return true
    end

    local had = false

    if track_txt_data.sections then
        for section, map in pairs(track_txt_data.sections) do
            for key, value in pairs(map or {}) do
                if trim(value or "") ~= "" then
                    had = true
                end

                map[key] = ""
            end
        end
    end

    track_txt_mark_dirty()
    track_txt_save_if_dirty(true)
    track_fixed_cc_clear_pickup()

    if speak_it then
        speak(had and "Fixed CC map cleared" or "No fixed CC map")
    end

    return true
end

function track_fixed_cc_count_links()
    if not track_fixed_cc_storage_available() then
        return 0
    end

    local count = 0

    if track_txt_data.sections then
        for _, map in pairs(track_txt_data.sections) do
            for _, value in pairs(map or {}) do
                local ch, cc = track_fixed_cc_parse_text(value)

                if ch and cc then
                    count = count + 1
                end
            end
        end
    end

    if current_track and track_fixed_cc_get_f4_scope() == "ProjectTrack" then
        local map = track_fixed_cc_project_f4_read_map(current_track)

        for _, value in pairs(map or {}) do
            local ch, cc = track_fixed_cc_parse_text(value)

            if ch and cc then
                count = count + 1
            end
        end
    end

    return count
end

function track_fixed_cc_spoken_part_for_entry(entry)
    if track_fixed_cc_map_enabled ~= true then
        return ""
    end

    local info = track_fixed_cc_info_for_entry(entry)

    if not info then
        return ""
    end

    local channel, cc = track_fixed_cc_get_link_info(info)

    if channel == nil or cc == nil then
        return ""
    end

    return ". CC channel " .. tostring(channel) .. " CC " .. tostring(cc)
end

function track_fixed_cc_is_bool_info(info)
    if not info then
        return false
    end

    return info.simple_id == "mute" or
           info.simple_id == "solo" or
           info.simple_id == "phase"
end

function track_fixed_cc_target_id_for_info(info)
    if not info then
        return ""
    end

    return tostring(info.storage or "") ..
        ":" .. tostring(info.section or "") ..
        ":" .. tostring(info.key or "")
end

function track_fixed_cc_apply_info_to_entry(info, target_entry, cc_value)
    if not info or not target_entry then
        return false
    end

    if type(target_entry.get_norm) ~= "function" or type(target_entry.set_norm) ~= "function" then
        return false
    end

    cc_value = clamp01(cc_value)

    local id = track_fixed_cc_target_id_for_info(info)

    if not track_fixed_cc_is_bool_info(info) then
        if track_fixed_cc_pickup_target[id] == nil then
            local ok, v = pcall(target_entry.get_norm, target_entry)

            if ok then
                track_fixed_cc_pickup_target[id] = clamp01(v)
                track_fixed_cc_pickup[id] = false
            end
        end

        if not track_fixed_cc_pickup[id] then
            if track_fixed_cc_value_crossed_target(
                id,
                track_fixed_cc_last_value_by_id[id],
                cc_value,
                track_fixed_cc_pickup_target[id]
            ) then
                track_fixed_cc_pickup[id] = true
            else
                track_fixed_cc_last_value_by_id[id] = cc_value
                return true
            end
        end
    end

    track_fixed_cc_last_value_by_id[id] = cc_value

    local before = make_entry_value(target_entry)
    local ok, result = pcall(target_entry.set_norm, target_entry, cc_value)

    if ok and result ~= false then
        clear_silent_edge()

        local after = make_entry_value(target_entry)

        if after ~= "" and after ~= before then
            if title_detail_is_enabled() then
                ------------------------------------------------
                -- In F4 la navigazione FX TCP è già sul parametro:
                -- durante il movimento CC serve solo il valore.
                ------------------------------------------------
                if target_entry.kind == "fx_param" then
                    track_cc_value_speak_send(after)
                else
                    track_cc_value_speak_send(info.label .. " " .. after)
                end
            else
                cancel_pending_speech()
            end
        end

        return true
    end

    return false
end

function track_fixed_cc_apply_track_info(info, cc_value)
    if not info or info.section ~= "Track" then
        return false
    end

    return track_fixed_cc_apply_value_to_id(info.key, cc_value)
end

function track_fixed_cc_current_send_anchor()
    local e = get_current_entry()

    if e and e.kind == "send_param" then
        return e.category, e.send_index, e.real_send_index
    end

    if e and e.kind == "send_header" then
        return e.category, e.send_index, e.real_send_index
    end

    return nil, nil, nil
end

function track_fixed_cc_find_send_entry(section, key)
    local category = nil

    if section == "Sends" then
        category = 0
    elseif section == "Receives" then
        category = -1
    else
        return nil
    end

    local cur_category, cur_send_index, cur_real_send_index = track_fixed_cc_current_send_anchor()

    for _, e in ipairs(grid_entries or {}) do
        if e.kind == "send_param" and
           e.category == category and
           e.id == key then

            if cur_category == nil or e.category == cur_category then
                if cur_send_index == nil or e.send_index == cur_send_index then
                    return e
                end

                if cur_real_send_index ~= nil and e.real_send_index == cur_real_send_index then
                    return e
                end
            end
        end
    end

    return nil
end

function track_fixed_cc_find_fx_entry_by_key(key)
    key = clean_one_line(key or "")

    if key == "" then
        return nil
    end

    for _, e in ipairs(grid_entries or {}) do
        if e.kind == "fx_param" and track_fixed_cc_fx_key_for_entry(e) == key then
            return e
        end
    end

    return nil
end

function track_fixed_cc_infos_for_current_context()
    local out = {}

    if not track_txt_data.sections then
        return out
    end

    if current_section_id == SECTION_TRACKS then
        for key, value in pairs(track_txt_data.sections.Track or {}) do
            local ch, cc = track_fixed_cc_parse_text(value)

            if ch and cc then
                out[#out + 1] = {
                    storage = "main",
                    section = "Track",
                    key = key,
                    label = TRACK_FIXED_CC_SIMPLE_LABELS.Track[key] or key,
                    simple_id = key,
                    channel = ch,
                    cc = cc
                }
            end
        end
    elseif current_section_id == SECTION_SENDS then
        for key, value in pairs(track_txt_data.sections.Sends or {}) do
            local ch, cc = track_fixed_cc_parse_text(value)

            if ch and cc then
                out[#out + 1] = {
                    storage = "main",
                    section = "Sends",
                    key = key,
                    label = TRACK_FIXED_CC_SIMPLE_LABELS.Sends[key] or key,
                    simple_id = key,
                    channel = ch,
                    cc = cc,
                    entry = track_fixed_cc_find_send_entry("Sends", key)
                }
            end
        end
    elseif current_section_id == SECTION_RECEIVES then
        for key, value in pairs(track_txt_data.sections.Receives or {}) do
            local ch, cc = track_fixed_cc_parse_text(value)

            if ch and cc then
                out[#out + 1] = {
                    storage = "main",
                    section = "Receives",
                    key = key,
                    label = TRACK_FIXED_CC_SIMPLE_LABELS.Receives[key] or key,
                    simple_id = key,
                    channel = ch,
                    cc = cc,
                    entry = track_fixed_cc_find_send_entry("Receives", key)
                }
            end
        end
    elseif current_section_id == SECTION_FX_PARAMS then
        if track_fixed_cc_get_f4_scope() == "Plugin" then
            for key, value in pairs(track_txt_data.sections["FXParams.Plugin"] or {}) do
                local ch, cc = track_fixed_cc_parse_text(value)

                if ch and cc then
                    local entry = track_fixed_cc_find_fx_entry_by_key(key)
                    local label = key

                    if entry then
                        label = make_entry_label(entry)
                    end

                    out[#out + 1] = {
                        storage = "main",
                        section = "FXParams.Plugin",
                        key = key,
                        label = label,
                        simple_id = "fx",
                        channel = ch,
                        cc = cc,
                        entry = entry
                    }
                end
            end
        else
            local map = track_fixed_cc_project_f4_read_map(current_track)

            for key, value in pairs(map or {}) do
                local ch, cc = track_fixed_cc_parse_text(value)

                if ch and cc then
                    local entry = track_fixed_cc_find_fx_entry_by_key(key)
                    local label = key

                    if entry then
                        label = make_entry_label(entry)
                    end

                    out[#out + 1] = {
                        storage = "project_f4",
                        section = "FXParams",
                        key = key,
                        label = label,
                        simple_id = "fx",
                        channel = ch,
                        cc = cc,
                        entry = entry
                    }
                end
            end
        end
    end

    return out
end

function track_fixed_cc_poll_recent_input()
    if track_fixed_cc_learn_armed ~= true then
        if not track_fixed_cc_map_enabled then
            return false
        end

        if track_fixed_cc_count_links() <= 0 then
            return false
        end
    end

    local seq, buf = floating_cc_read_recent_event()

    if seq == 0 then
        return false
    end

    if seq == track_fixed_cc_last_seq then
        return false
    end

    track_fixed_cc_last_seq = seq

    local channel, cc_number, cc_value = floating_cc_parse_cc_from_buffer(buf)

    if not channel then
        return false
    end

    channel = clamp_int(channel, 1, 16)
    cc_number = clamp_int(cc_number, 0, 127)
    cc_value = clamp01(cc_value)

    if track_fixed_cc_learn_armed == true then
        return track_fixed_cc_finish_learn(channel, cc_number, cc_value)
    end

    local ok_stable, stable_value =
        track_cc_raw_stabilizer_accept(
            "fixed",
            channel,
            cc_number,
            cc_value
        )

    if not ok_stable then
        return false
    end

    cc_value = stable_value

    local infos = track_fixed_cc_infos_for_current_context()

    for _, info in ipairs(infos) do
        if info.channel == channel and info.cc == cc_number then
            if info.section == "Track" then
                return track_fixed_cc_apply_track_info(info, cc_value)
            elseif info.entry then
                return track_fixed_cc_apply_info_to_entry(info, info.entry, cc_value)
            else
                return true
            end
        end
    end

    return false
end



------------------------------------------------------------
-- 5.6B - CTRL+T CC SPEECH PER PARAMETRO / OVERRIDE
--
-- Come in Speak FX Params:
-- Ctrl+T non è globale. Abilita/disabilita il parlato dei
-- valori mossi da CC solo per il parametro corrente.
--
-- F1/F2/F3: stato salvato nel TXT principale Tracks/Track CC Map.txt.
-- F4 Plugin scope: stato salvato nello stesso TXT principale.
-- F4 ProjectTrack scope: stato salvato nel TXT F4 del progetto/traccia,
-- compreso Default quando il progetto non è ancora salvato.
------------------------------------------------------------

TRACK_CC_SPEECH_SECTIONS = {
    Track = true,
    Sends = true,
    Receives = true,
    ["FXParams.Plugin"] = true
}

function track_cc_speech_reset_maps()
    if not track_txt_data then
        return false
    end

    track_txt_data.cc_speech = {
        Track = {},
        Sends = {},
        Receives = {},
        ["FXParams.Plugin"] = {}
    }

    return true
end

function track_fixed_cc_reset_main_data()
    track_txt_data = {
        version = TRACK_CC_TXT_VERSION,
        f4_scope = "ProjectTrack",
        sections = {
            Track = {},
            Sends = {},
            Receives = {},
            ["FXParams.Plugin"] = {}
        },
        cc_speech = {
            Track = {},
            Sends = {},
            Receives = {},
            ["FXParams.Plugin"] = {}
        },
        fixed_cc = {}
    }
end

function track_txt_reset_data()
    track_fixed_cc_reset_main_data()
end

function track_cc_speech_section_from_txt_section(section)
    section = clean_one_line(section or "")

    local name = section:match("^CCSpeech%.(.+)$")

    if name and TRACK_CC_SPEECH_SECTIONS[name] then
        return name
    end

    return ""
end

function track_txt_load_from_text(txt)
    track_fixed_cc_reset_main_data()

    txt = tostring(txt or "")

    local section = ""

    for line in txt:gmatch("[^\r\n]+") do
        line = trim(line)

        if line ~= "" then
            if line:sub(1, 1) == "#" then
                -- commento
            elseif line:sub(1, 1) == "[" and line:sub(-1) == "]" then
                section = clean_one_line(line:sub(2, -2))
            else
                local key, value = track_txt_parse_kv(line)

                if key and key ~= "" then
                    local speech_section = track_cc_speech_section_from_txt_section(section)

                    if section == "Settings" then
                        if key == "F4CCScope" then
                            value = clean_one_line(value or "")

                            if value ~= "Plugin" and value ~= "ProjectTrack" then
                                value = "ProjectTrack"
                            end

                            track_txt_data.f4_scope = value
                        end
                    elseif key == "Version" then
                        track_txt_data.version = clean_one_line(value or "")
                    elseif key == "F4CCScope" then
                        value = clean_one_line(value or "")

                        if value == "Plugin" or value == "ProjectTrack" then
                            track_txt_data.f4_scope = value
                        end
                    elseif speech_section ~= "" then
                        local id = key

                        if speech_section ~= "FXParams.Plugin" then
                            id = track_fixed_cc_normalize_simple_key(speech_section, key)
                        end

                        if id ~= "" then
                            track_txt_data.cc_speech[speech_section][id] =
                                clean_one_line(value or "") == "1" and "1" or ""
                        end
                    elseif TRACK_FIXED_CC_MAIN_SECTIONS[section] then
                        local ch, cc = track_fixed_cc_parse_text(value)

                        if ch and cc then
                            local id = key

                            if section ~= "FXParams.Plugin" then
                                id = track_fixed_cc_normalize_simple_key(section, key)
                            end

                            if id ~= "" then
                                track_txt_data.sections[section][id] = track_fixed_cc_make_text(ch, cc)
                            end
                        end
                    elseif section == "FixedCC" then
                        local id = track_fixed_cc_normalize_simple_key("Track", key)
                        local ch, cc = track_fixed_cc_parse_text(value)

                        if id ~= "" and ch and cc then
                            track_txt_data.sections.Track[id] = track_fixed_cc_make_text(ch, cc)
                        end
                    end
                end
            end
        end
    end

    track_txt_data.fixed_cc = track_txt_data.sections.Track

    if not track_txt_data.cc_speech then
        track_cc_speech_reset_maps()
    end
end

function track_cc_speech_line_for_simple_section(lines, section, order)
    lines[#lines + 1] = ""
    lines[#lines + 1] = "[CCSpeech." .. section .. "]"

    local map = track_txt_data.cc_speech and track_txt_data.cc_speech[section] or {}

    for _, id in ipairs(order) do
        local key = TRACK_FIXED_CC_SIMPLE_FILE_KEYS[id] or id
        local value = map[id] == "1" and "1" or ""

        if value ~= "" then
            lines[#lines + 1] = track_txt_make_kv(key, value)
        else
            lines[#lines + 1] = key .. "="
        end
    end
end

function track_txt_build_text()
    local lines = {}

    lines[#lines + 1] = "# Speak Track Params - TrackTake Navigator"
    lines[#lines + 1] = "# Fixed CC map. Values are Channel,CC. No parameter values are stored here."
    lines[#lines + 1] = "# CCSpeech sections store Ctrl+T per-parameter CC speech: 1 = speak, empty = silent."
    lines[#lines + 1] = "# F4CCScope can be Plugin or ProjectTrack."
    lines[#lines + 1] = ""
    lines[#lines + 1] = track_txt_make_kv("Version", TRACK_CC_TXT_VERSION)
    lines[#lines + 1] = track_txt_make_kv("F4CCScope", track_txt_data.f4_scope or "ProjectTrack")

    track_fixed_cc_line_for_simple_section(lines, "Track", {
        "volume", "pan", "width", "mute", "solo", "phase"
    })

    track_fixed_cc_line_for_simple_section(lines, "Sends", {
        "volume", "pan", "mute"
    })

    track_fixed_cc_line_for_simple_section(lines, "Receives", {
        "volume", "pan", "mute"
    })

    lines[#lines + 1] = ""
    lines[#lines + 1] = "[FXParams.Plugin]"

    local fxmap = track_txt_data.sections and track_txt_data.sections["FXParams.Plugin"] or {}
    local keys = {}

    for key, value in pairs(fxmap or {}) do
        if trim(value or "") ~= "" then
            keys[#keys + 1] = key
        end
    end

    table.sort(keys)

    for _, key in ipairs(keys) do
        lines[#lines + 1] = track_txt_make_kv(key, fxmap[key])
    end

    track_cc_speech_line_for_simple_section(lines, "Track", {
        "volume", "pan", "width", "mute", "solo", "phase"
    })

    track_cc_speech_line_for_simple_section(lines, "Sends", {
        "volume", "pan", "mute"
    })

    track_cc_speech_line_for_simple_section(lines, "Receives", {
        "volume", "pan", "mute"
    })

    lines[#lines + 1] = ""
    lines[#lines + 1] = "[CCSpeech.FXParams.Plugin]"

    local speech_fx = track_txt_data.cc_speech and track_txt_data.cc_speech["FXParams.Plugin"] or {}
    local speech_keys = {}

    for key, value in pairs(speech_fx or {}) do
        if clean_one_line(value or "") == "1" then
            speech_keys[#speech_keys + 1] = key
        end
    end

    table.sort(speech_keys)

    for _, key in ipairs(speech_keys) do
        lines[#lines + 1] = track_txt_make_kv(key, "1")
    end

    lines[#lines + 1] = ""

    return table.concat(lines, "\n")
end

function track_fixed_cc_project_f4_read_speech_map(track)
    local path = track_fixed_cc_get_project_track_f4_path(track)
    local txt = track_txt_read_file(path)
    local map = {}

    if txt ~= nil then
        local section = ""

        for line in tostring(txt or ""):gmatch("[^\r\n]+") do
            line = trim(line)

            if line ~= "" then
                if line:sub(1, 1) == "#" then
                    -- commento
                elseif line:sub(1, 1) == "[" and line:sub(-1) == "]" then
                    section = clean_one_line(line:sub(2, -2))
                elseif section == "CCSpeech" then
                    local key, value = track_txt_parse_kv(line)

                    if key and key ~= "" then
                        map[key] = clean_one_line(value or "") == "1" and "1" or ""
                    end
                end
            end
        end
    end

    return map
end

function track_fixed_cc_project_f4_write_maps(track, cc_map, speech_map)
    local path = track_fixed_cc_get_project_track_f4_path(track)
    local lines = {}

    lines[#lines + 1] = "# Speak Track Params - TrackTake Navigator"
    lines[#lines + 1] = "# ProjectTrack F4 fixed CC map. Values are Channel,CC."
    lines[#lines + 1] = "# CCSpeech stores Ctrl+T per-parameter CC speech: 1 = speak, empty = silent."
    lines[#lines + 1] = ""
    lines[#lines + 1] = track_txt_make_kv("Version", TRACK_CC_TXT_VERSION)
    lines[#lines + 1] = track_txt_make_kv("Project", track_fixed_cc_get_project_name())
    lines[#lines + 1] = track_txt_make_kv("TrackName", get_track_short_label(track))
    lines[#lines + 1] = track_txt_make_kv("TrackGUID", get_track_guid(track))
    lines[#lines + 1] = ""
    lines[#lines + 1] = "[FXParams]"

    local keys = {}

    for key, value in pairs(cc_map or {}) do
        if trim(value or "") ~= "" then
            keys[#keys + 1] = key
        end
    end

    table.sort(keys)

    for _, key in ipairs(keys) do
        lines[#lines + 1] = track_txt_make_kv(key, cc_map[key])
    end

    lines[#lines + 1] = ""
    lines[#lines + 1] = "[CCSpeech]"

    local skeys = {}

    for key, value in pairs(speech_map or {}) do
        if clean_one_line(value or "") == "1" then
            skeys[#skeys + 1] = key
        end
    end

    table.sort(skeys)

    for _, key in ipairs(skeys) do
        lines[#lines + 1] = track_txt_make_kv(key, "1")
    end

    lines[#lines + 1] = ""

    return track_txt_write_file(path, table.concat(lines, "\n"))
end

function track_fixed_cc_project_f4_write_map(track, map)
    local speech_map = track_fixed_cc_project_f4_read_speech_map(track)
    return track_fixed_cc_project_f4_write_maps(track, map, speech_map)
end

function track_cc_param_speech_is_supported_info(info)
    if not info then
        return false
    end

    if info.storage == "main" then
        return TRACK_CC_SPEECH_SECTIONS[info.section] == true
    end

    if info.storage == "project_f4" then
        return true
    end

    return false
end

function track_cc_param_speech_is_enabled_info(info)
    if not track_cc_param_speech_is_supported_info(info) then
        return false
    end

    if info.storage == "project_f4" then
        local track = info.entry and info.entry.track or current_track
        local map = track_fixed_cc_project_f4_read_speech_map(track)
        return clean_one_line(map[info.key] or "") == "1"
    end

    if not track_fixed_cc_storage_available() then
        track_txt_load()
    end

    if not track_txt_data.cc_speech then
        track_cc_speech_reset_maps()
    end

    local section_map = track_txt_data.cc_speech and track_txt_data.cc_speech[info.section] or nil

    if not section_map then
        return false
    end

    return clean_one_line(section_map[info.key] or "") == "1"
end

function track_cc_param_speech_set_enabled_info(info, enabled)
    if not track_cc_param_speech_is_supported_info(info) then
        return false
    end

    enabled = enabled == true

    if info.storage == "project_f4" then
        local track = info.entry and info.entry.track or current_track
        local cc_map = track_fixed_cc_project_f4_read_map(track)
        local speech_map = track_fixed_cc_project_f4_read_speech_map(track)

        speech_map[info.key] = enabled and "1" or ""

        return track_fixed_cc_project_f4_write_maps(track, cc_map, speech_map)
    end

    if not track_fixed_cc_storage_available() then
        track_txt_load()
    end

    if not track_fixed_cc_storage_available() then
        return false
    end

    if not track_txt_data.cc_speech then
        track_cc_speech_reset_maps()
    end

    if not track_txt_data.cc_speech[info.section] then
        track_txt_data.cc_speech[info.section] = {}
    end

    track_txt_data.cc_speech[info.section][info.key] = enabled and "1" or ""
    track_txt_mark_dirty()
    track_txt_save_if_dirty(true)

    return true
end

function track_cc_param_speech_info_for_current_entry()
    local e = get_current_entry()

    if not e then
        return nil
    end

    local info = track_fixed_cc_info_for_entry(e)

    if not info then
        return nil
    end

    if type(current_entry_supports_value) == "function" and not current_entry_supports_value() then
        return nil
    end

    return info
end

function track_cc_param_speech_toggle_current()
    cancel_pending_speech()
    clear_silent_edge()

    local info = track_cc_param_speech_info_for_current_entry()

    if not info then
        speak("CC speech not available")
        return true
    end

    local new_enabled = not track_cc_param_speech_is_enabled_info(info)

    if not track_cc_param_speech_set_enabled_info(info, new_enabled) then
        speak("CC speech not saved")
        return true
    end

    if new_enabled then
        speak("CC speech on. " .. clean_one_line(info.label or "Parameter"))
    else
        speak("CC speech off. " .. clean_one_line(info.label or "Parameter"))
    end

    return true
end

function track_cc_param_speech_is_enabled_for_entry(entry)
    local info = track_fixed_cc_info_for_entry(entry)
    return track_cc_param_speech_is_enabled_info(info)
end

function floating_cc_apply_value(cc_value)
    cc_value = clamp01(cc_value)

    if not current_entry_supports_value() then
        floating_cc_last_value = cc_value
        return true
    end

    floating_cc_reset_pickup_if_target_changed()

    if floating_cc_target_key == "" then
        floating_cc_last_value = cc_value
        return true
    end

    if not floating_cc_picked_up then
        if floating_cc_value_crossed_target(
            floating_cc_last_value,
            cc_value,
            floating_cc_target_value
        ) then
            floating_cc_picked_up = true
        else
            floating_cc_last_value = cc_value
            return true
        end
    end

    floating_cc_last_value = cc_value

    local e = get_current_entry()
    local before = make_entry_value(e)

    if current_entry_set_norm(cc_value) then
        clear_silent_edge()

        if title_detail_is_enabled() and
           track_cc_param_speech_is_enabled_for_entry(e) then

            local after = make_entry_value(get_current_entry())

            if after ~= "" and after ~= before then
                track_cc_value_speak_send(after)
            end
        else
            cancel_pending_speech()
        end

        return true
    end

    return true
end

function track_fixed_cc_apply_info_to_entry(info, target_entry, cc_value)
    if not info or not target_entry then
        return false
    end

    if type(target_entry.get_norm) ~= "function" or type(target_entry.set_norm) ~= "function" then
        return false
    end

    cc_value = clamp01(cc_value)

    local id = track_fixed_cc_target_id_for_info(info)

    if not track_fixed_cc_is_bool_info(info) then
        if track_fixed_cc_pickup_target[id] == nil then
            local ok, v = pcall(target_entry.get_norm, target_entry)

            if ok then
                track_fixed_cc_pickup_target[id] = clamp01(v)
                track_fixed_cc_pickup[id] = false
            end
        end

        if not track_fixed_cc_pickup[id] then
            if track_fixed_cc_value_crossed_target(
                id,
                track_fixed_cc_last_value_by_id[id],
                cc_value,
                track_fixed_cc_pickup_target[id]
            ) then
                track_fixed_cc_pickup[id] = true
            else
                track_fixed_cc_last_value_by_id[id] = cc_value
                return true
            end
        end
    end

    track_fixed_cc_last_value_by_id[id] = cc_value

    local before = make_entry_value(target_entry)
    local ok, result = pcall(target_entry.set_norm, target_entry, cc_value)

    if ok and result ~= false then
        clear_silent_edge()

        local after = make_entry_value(target_entry)

        if after ~= "" and after ~= before then
            if title_detail_is_enabled() and
               track_cc_param_speech_is_enabled_info(info) then

                if target_entry.kind == "fx_param" then
                    track_cc_value_speak_send(after)
                else
                    track_cc_value_speak_send(info.label .. " " .. after)
                end
            else
                cancel_pending_speech()
            end
        end

        return true
    end

    return false
end

function track_fixed_cc_apply_value_to_id(id, cc_value)
    id = clean_one_line(id or "")
    cc_value = clamp01(cc_value)

    if not TRACK_FIXED_CC_IDS[id] then
        return false
    end

    local tracks = track_fixed_cc_get_target_tracks()

    if #tracks <= 0 then
        track_fixed_cc_clear_pickup()
        return true
    end

    track_fixed_cc_reset_pickup_if_selection_changed(tracks)

    if not track_fixed_cc_is_bool(id) then
        if track_fixed_cc_pickup_target[id] == nil then
            track_fixed_cc_pickup_target[id] = track_fixed_cc_current_average_norm(id, tracks)
            track_fixed_cc_pickup[id] = false
        end

        if not track_fixed_cc_pickup[id] then
            if track_fixed_cc_value_crossed_target(
                id,
                track_fixed_cc_last_value_by_id[id],
                cc_value,
                track_fixed_cc_pickup_target[id]
            ) then
                track_fixed_cc_pickup[id] = true
            else
                track_fixed_cc_last_value_by_id[id] = cc_value
                return true
            end
        end
    end

    track_fixed_cc_last_value_by_id[id] = cc_value

    local changed = false
    local before = nil

    if #tracks > 0 then
        before = track_fixed_cc_format_value(id, tracks[1])
    end

    for i = 1, #tracks do
        if track_fixed_cc_set_norm_for_track(id, tracks[i], cc_value) then
            changed = true
        end
    end

    if changed then
        clear_silent_edge()

        local after = ""

        if #tracks > 0 then
            after = track_fixed_cc_format_value(id, tracks[1])
        end

        local info = {
            storage = "main",
            section = "Track",
            key = id,
            label = TRACK_FIXED_CC_SIMPLE_LABELS.Track[id] or track_fixed_cc_label(id),
            simple_id = id
        }

        if after ~= "" and after ~= before then
            if title_detail_is_enabled() and
               track_cc_param_speech_is_enabled_info(info) then

                if #tracks > 1 then
                    track_cc_value_speak_send(
                        track_fixed_cc_label(id) ..
                        " selected tracks " ..
                        after
                    )
                else
                    track_cc_value_speak_send(track_fixed_cc_label(id) .. " " .. after)
                end
            else
                cancel_pending_speech()
            end
        end
    end

    return true
end

------------------------------------------------------------
-- 5.7 - MAIN LOOP
------------------------------------------------------------

function main_loop()
    if background_focus_mode == true then
        background_defer_loop_tick()
        return
    end

    if not validate_runtime_context() then
        return
    end

    --------------------------------------------------------
    -- Compatibilità neutra:
    -- non intercetta più lo Spazio, ma lasciamo la chiamata
    -- innocua per sicurezza.
    --------------------------------------------------------

    poll_transport_space_shortcuts()

    local fixed_handled = false

    if type(track_fixed_cc_poll_recent_input) == "function" then
        fixed_handled = track_fixed_cc_poll_recent_input() == true
    end

    if not fixed_handled then
        floating_cc_poll_recent_input()
    end

    if type(track_txt_save_deferred_if_idle) == "function" then
        track_txt_save_deferred_if_idle()
    end

    poll_ctrl_number_markers_js()

    local char = gfx.getchar()

    if char < 0 then
        return
    end

    if char ~= 0 then
        if not should_swallow_space_queue_char(char) then
            handle_key(char)
        end
    end

    reaper.defer(main_loop)
end

------------------------------------------------------------
-- 5.8 - START
------------------------------------------------------------

if init_script() then
    main_loop()
end

------------------------------------------------------------
-- FINE PARTE 5 / 5
------------------------------------------------------------