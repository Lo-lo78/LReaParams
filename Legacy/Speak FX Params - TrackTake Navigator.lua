-- @description Speak FX Params - TrackTake Navigator                   
-- @version 0.346
-- @author Lo-lo + GPT       

------------------------------------------------------------                 
-- PARTE 1 / 8         
-- BASE, STORAGE TXT PLUGIN, TASTI, STATO GLOBALE
--
-- Stato persistente:
-- - niente salvataggio nel progetto RPP;
-- - lo stato del plugin vive nel TXT del plugin;
-- - ExtState globale resta solo per dati non legati al progetto:
--   ricerche recenti, ultimo FX del contesto, memoria anti item stale.
------------------------------------------------------------

------------------------------------------------------------
-- 1.1 - SPEECH OSARA SAFE
------------------------------------------------------------
------------------------------------------------------------
-- 1.1 - SPEECH OSARA SAFE
------------------------------------------------------------
speech_suspended = false

function speak(msg)
    if speech_suspended then
        return
    end

    if not msg or msg == "" then return end

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
local function startup_frame_gap(n)
    return string.rep(" ", n)
end

local startup_frame_reference = {
    ("-- @" .. "description " ..
     "Speak FX Params - TrackTake Navigator") ..
        startup_frame_gap(19),

    "^%-%- @version %d[%d%.]*$",

    ("-- @" .. "author " ..
     "Lo-" .. "lo + " .. "GPT") ..
        startup_frame_gap(7),

    "",

    string.rep("-", 60) ..
        startup_frame_gap(17),

    ("-- PARTE " .. "1 / 8") ..
        startup_frame_gap(9)
}

local function startup_frame_read()
    local source = debug.getinfo(1, "S").source or ""

    if source:sub(1, 1) == "@" then
        source = source:sub(2)
    end

    if source == "" then
        return {}
    end

    local f = io.open(source, "r")

    if not f then
        return {}
    end

    local lines = {}

    for i = 1, 6 do
        lines[i] = f:read("*l") or ""
    end

    f:close()

    return lines
end

local function startup_frame_ready()
    local lines = startup_frame_read()

    if (lines[1] or "") ~= startup_frame_reference[1] then
        return false
    end

    if not (lines[2] or ""):match(startup_frame_reference[2]) then
        return false
    end

    if (lines[3] or "") ~= startup_frame_reference[3] then
        return false
    end

    if (lines[4] or "") ~= startup_frame_reference[4] then
        return false
    end

    if (lines[5] or "") ~= startup_frame_reference[5] then
        return false
    end

    if (lines[6] or "") ~= startup_frame_reference[6] then
        return false
    end

    return true
end

runtime_safe_mode = false

local function startup_identity_source_path()
    local source = debug.getinfo(1, "S").source or ""

    if source:sub(1, 1) == "@" then
        source = source:sub(2)
    end

    return source
end

local function startup_identity_phrase()
    return "Lo-" .. "lo + " .. "GPT"
end

local function startup_identity_ready()
    local source = startup_identity_source_path()

    if source == "" then
        return false
    end

    local f = io.open(source, "rb")

    if not f then
        return false
    end

    local txt = f:read("*a") or ""
    f:close()

    local phrase = startup_identity_phrase()
    local count = 0
    local pos = 1

    while true do
        local found = txt:find(phrase, pos, true)

        if not found then
            break
        end

        count = count + 1
        pos = found + #phrase

        if count >= 2 then
            return true
        end
    end

    return false
end

function runtime_source_contains_identity()
    if type(startup_identity_source_path) ~= "function" or
       type(startup_identity_phrase) ~= "function" then

        return false
    end

    local source = startup_identity_source_path()

    if source == "" then
        return false
    end

    local f = io.open(source, "rb")

    if not f then
        return false
    end

    local txt = f:read("*a") or ""
    f:close()

    local phrase = startup_identity_phrase()

    return txt:find(phrase, 1, true) ~= nil
end

function runtime_integrity_ready()
    if type(startup_frame_ready) ~= "function" then
        return false
    end

    if type(startup_identity_ready) ~= "function" then
        return false
    end

    if not startup_frame_ready() then
        return false
    end

    if not startup_identity_ready() then
        return false
    end

    if not runtime_source_contains_identity() then
        return false
    end

    return true
end

if not runtime_integrity_ready() then
    runtime_safe_mode = true
end

function run_without_speech(fn)
    if type(fn) ~= "function" then
        return nil
    end

    local old_state = speech_suspended
    speech_suspended = true

    local ok, result = pcall(fn)

    speech_suspended = old_state

    if ok then
        return result
    end

    return nil
end

------------------------------------------------------------
-- 1.2 - SPEECH RITARDATO / CANCELLAZIONE PARLATO PENDENTE
------------------------------------------------------------
speak_serial = 0

function cancel_pending_speech()
    speak_serial = speak_serial + 1
end

function speak_later(msg)
    if not msg or msg == "" then return end

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

function fx_value_edge_token(suffix)
    local ctx = ""

    if type(current_context_key) == "function" then
        ctx = current_context_key() or ""
    end

    return
        "fx-value-edge:" ..
        tostring(ctx or "") ..
        ":" ..
        tostring(fx_index or "") ..
        ":" ..
        tostring(param_index or "") ..
        ":" ..
        tostring(suffix or "")
end

function value_edge_silent(suffix)
    edge_was_already_silent(fx_value_edge_token(suffix))
    return true
end

------------------------------------------------------------
-- VERSIONE SCRIPT DA HEADER FILE
--
-- Ctrl+Shift+Alt+F1 leggerà direttamente le prime righe:
-- -- @description ...
-- -- @version ...
-- -- @author ...
--
-- Così basta aggiornare l'header del file Lua.
------------------------------------------------------------
function get_script_header_info()
    local source = debug.getinfo(1, "S").source or ""

    --------------------------------------------------------
    -- In ReaScript di solito source è:
    -- @C:\...\Speak FX Params - TrackTake Navigator.lua
    --------------------------------------------------------
    if source:sub(1, 1) == "@" then
        source = source:sub(2)
    end

    if source == "" then
        return ""
    end

    local f = io.open(source, "r")

    if not f then
        return ""
    end

    local wanted = {
        ["@description"] = true,
        ["@version"] = true,
        ["@author"] = true
    }

    local out = {}
    local max_lines = 20

    for _ = 1, max_lines do
        local line = f:read("*l")

        if not line then
            break
        end

        line = tostring(line or "")

        ----------------------------------------------------
        -- Cerca solo le righe metadata fondamentali.
        ----------------------------------------------------
        local tag, value = line:match("^%s*%-%-%s*(@%S+)%s*(.*)$")

        if tag and wanted[tag] then
            value = clean_one_line(value or "")

            if tag == "@description" then
                out[#out + 1] = value

            elseif tag == "@version" then
                out[#out + 1] = value

            elseif tag == "@author" then
                out[#out + 1] = value
            end
        end

        if #out >= 3 then
            break
        end
    end

    f:close()

    return clean_one_line(table.concat(out, ". "))
end

function speak_script_version()
    cancel_pending_speech()

    local msg = get_script_header_info()

    if msg == "" then
        msg = "Script version not available"
    end

    speak(msg)

    return true
end

------------------------------------------------------------
-- 1.3 - HELPERS NUMERICI / STRINGHE
------------------------------------------------------------
function clamp01(v)
    v = tonumber(v) or 0

    if v < 0 then return 0 end
    if v > 1 then return 1 end

    return v
end

function clamp_int(v, a, b)
    a = tonumber(a) or 0
    b = tonumber(b) or a

    if a > b then
        a, b = b, a
    end

    v = math.floor((tonumber(v) or a) + 0.5)

    if v < a then return a end
    if v > b then return b end

    return v
end

function clamp(v, a, b)
    a = tonumber(a) or 0
    b = tonumber(b) or a

    if a > b then
        a, b = b, a
    end

    v = tonumber(v) or a

    if v < a then return a end
    if v > b then return b end

    return v
end

function safe_char(c)
    c = tonumber(c) or 0

    if c >= 32 and c <= 126 then
        return string.char(c)
    end

    return nil
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

function strip_fx_prefix(name)
    name = clean_one_line(name or "")

    name = name:gsub("^JS:%s*", "")
    name = name:gsub("^VST:%s*", "")
    name = name:gsub("^VSTi:%s*", "")
    name = name:gsub("^VST2:%s*", "")
    name = name:gsub("^VST2i:%s*", "")
    name = name:gsub("^VST3:%s*", "")
    name = name:gsub("^VST3i:%s*", "")
    name = name:gsub("^CLAP:%s*", "")
    name = name:gsub("^CLAPi:%s*", "")
    name = name:gsub("^AU:%s*", "")
    name = name:gsub("^AUi:%s*", "")
    name = name:gsub("^DX:%s*", "")
    name = name:gsub("^DXi:%s*", "")

    return clean_one_line(name)
end

------------------------------------------------------------
-- 1.4 - STORAGE KEYS
------------------------------------------------------------
EXT_SECTION = "OSARA_FX_Params_Param_Browse"

EXT_RECENT_SEARCHES = "recent_searches_v1"

EXT_STALE_ITEM_GUID_KEY  = "stale_item_guid_v1"
EXT_STALE_ITEM_TRACK_KEY = "stale_item_track_v1"


EXT_LAST_PARAM_PREFIX = "last_param_v1"
EXT_LAST_FX_PREFIX    = "last_fx_v1"
EXT_LAST_ENTRY_PREFIX = "last_entry_v1"
EXT_LAST_AREA_PREFIX  = "last_area_v1"

------------------------------------------------------------
-- 1.4A - CHIAVI LEGACY
--
-- Restano solo per compatibilità con vecchie funzioni/wrapper.
-- Lo script non salva più dati specifici del plugin nel progetto RPP.
------------------------------------------------------------
PROJ_SECTION = "OSARA_FX_Params_Param_Browse"

PROJ_GROUP_PREFIX      = "param_group_v1"
PROJ_GROUP_SLOT_PREFIX = "param_group_slot_v1"
PROJ_PARAM_SLOT_PREFIX = "param_memory_slot_v1"

PROJ_STEP_SCALE_KEY = "project_step_scale_index_v1"
PROJ_GRID_SIZE_KEY  = "project_grid_size_v1"

------------------------------------------------------------
-- 1.5 - LEGACY STATE BRIDGE
--
-- Non scrive più nel progetto.
-- Reindirizza eventuali chiavi vecchie verso il TXT del plugin.
------------------------------------------------------------
function legacy_project_key_to_plugin_key(key)
    key = clean_one_line(key or "")

    if key == "" then
        return ""
    end

    return "legacy::" .. key
end

function set_project_state(key, value)
    key = legacy_project_key_to_plugin_key(key)

    if key == "" then
        return
    end

    if type(set_plugin_state) == "function" then
        set_plugin_state(key, tostring(value or ""))
    end
end

function get_project_state(key)
    key = legacy_project_key_to_plugin_key(key)

    if key == "" then
        return ""
    end

    if type(get_plugin_state) == "function" then
        return get_plugin_state(key) or ""
    end

    return ""
end

------------------------------------------------------------
-- 1.6 - ARCHIVIO TXT PER PLUGIN
------------------------------------------------------------
------------------------------------------------------------
-- Cartella profili plugin TXT
--
-- La vecchia cartella:
-- Scripts/Lo-lo - Scripts/Utility/Speak FX Params - TrackTake Navigator/
-- non viene più usata.
--
-- Ora i profili stanno accanto allo scriptone FX:
-- Scripts/Lo-lo - Scripts/Utility/Scripts/Plugins/
------------------------------------------------------------

PLUGIN_TXT_FOLDER_NAME = "Plugins"

PLUGIN_TXT_VERSION = "3"

plugin_txt_loaded = false
plugin_txt_dirty = false
plugin_txt_loading = false
plugin_txt_path = ""
plugin_txt_raw_fx_name = ""

plugin_txt_data = {
    version = PLUGIN_TXT_VERSION,
    raw_fx_name = "",
    last_param = "",
    last_entry = "",
    last_area = "",
    slot_access_mode = "param",
    custom_order_view = "plugin",
    quick_group = "",
    custom_order = "",
    default_values = "",
    param_slots = {},
    group_slots = {},
    extra = {}
}

------------------------------------------------------------
-- 1.6A - PATH / CARTELLA PLUGINS
------------------------------------------------------------
function get_reaper_resource_path()
    if reaper.GetResourcePath then
        return reaper.GetResourcePath() or ""
    end

    return ""
end

function join_path(a, b)
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

function get_plugin_txt_folder()
    --------------------------------------------------------
    -- Usa sempre la cartella reale dello script FX corrente.
    -- Così se la suite viene spostata, i TXT seguono lo
    -- scriptone e non ricreano più la vecchia cartella.
    --------------------------------------------------------

    local folder = ""

    if type(get_current_script_folder) == "function" then
        folder = get_current_script_folder()
    end

    if folder == "" then
        folder = join_path(
            join_path(
                join_path(
                    join_path(get_reaper_resource_path(), "Scripts"),
                    "Lo-lo - Scripts"
                ),
                "Utility"
            ),
            "Scripts"
        )
    end

    return join_path(folder, PLUGIN_TXT_FOLDER_NAME)
end

function ensure_plugin_txt_folder()
    local folder = get_plugin_txt_folder()

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

------------------------------------------------------------
-- 1.6B - NOME FILE SICURO PER IL PLUGIN
------------------------------------------------------------
function sanitize_plugin_filename(name)
    name = clean_one_line(name or "")

    if name == "" then
        name = "Unknown FX"
    end

    name = name:gsub(":", " - ")
    name = name:gsub("[/\\%*%?\"<>|]", " - ")
    name = name:gsub("[%c]", " ")
    name = name:gsub("%s+", " ")
    name = name:gsub("%s*%-%s*", " - ")
    name = name:gsub("%- %-", "-")
    name = name:gsub("^%s+", "")
    name = name:gsub("%s+$", "")
    name = name:gsub("^%.*", "")
    name = name:gsub("%.*$", "")

    if name == "" then
        name = "Unknown FX"
    end

    if #name > 160 then
        name = trim(name:sub(1, 160))
    end

    return name .. ".txt"
end

function get_plugin_txt_path_for_fx_name(raw_fx_name)
    local folder = get_plugin_txt_folder()
    local filename = sanitize_plugin_filename(raw_fx_name)

    return join_path(folder, filename)
end

------------------------------------------------------------
-- 1.6C - TXT ENCODE / DECODE
------------------------------------------------------------
function plugin_txt_reset_data(raw_fx_name)
    plugin_txt_data = {
        version = PLUGIN_TXT_VERSION,
        raw_fx_name = clean_one_line(raw_fx_name or ""),
        last_param = "",
        last_entry = "",
        last_area = "",
        slot_access_mode = "param",
        custom_order_view = "plugin",
        quick_group = "",
        custom_order = "",
        default_values = "",
        param_slots = {},
        group_slots = {},
        extra = {}
    }
end

function plugin_txt_escape_value(s)
    s = tostring(s or "")

    s = s:gsub("\\", "\\\\")
    s = s:gsub("\r", "\\r")
    s = s:gsub("\n", "\\n")

    return s
end

function plugin_txt_unescape_value(s)
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

function plugin_txt_make_kv(key, value)
    key = clean_one_line(key or "")

    if key == "" then
        return ""
    end

    return key .. "=" .. plugin_txt_escape_value(value or "")
end

function plugin_txt_parse_kv(line)
    line = tostring(line or "")

    local key, value = line:match("^([^=]+)=(.*)$")

    if not key then
        return nil, ""
    end

    key = trim(key or "")
    value = plugin_txt_unescape_value(value or "")

    return key, value
end

------------------------------------------------------------
-- 1.6D - LETTURA FILE TXT PLUGIN
------------------------------------------------------------
function plugin_txt_read_file(path)
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

function plugin_txt_load_from_text(txt, raw_fx_name)
    plugin_txt_reset_data(raw_fx_name)

    txt = tostring(txt or "")

    local section = ""
    local custom_lines = {}
    local default_lines = {}

    for line in txt:gmatch("[^\r\n]+") do
        line = trim(line)

        if line ~= "" then
            if line:sub(1, 1) == "#" then
                -- commento

            elseif line:sub(1, 1) == "[" and line:sub(-1) == "]" then
                section = clean_one_line(line:sub(2, -2))

            elseif section == "CustomOrder" then
                custom_lines[#custom_lines + 1] = line

            elseif section == "DefaultValues" then
                default_lines[#default_lines + 1] = line

            elseif section == "ParamSlots" then
                local key, value = plugin_txt_parse_kv(line)
                local slot = tonumber(key)

                if slot then
                    slot = clamp_int(slot, 1, 12)
                    plugin_txt_data.param_slots[slot] = value or ""
                end

            elseif section == "GroupSlots" then
                local key, value = plugin_txt_parse_kv(line)
                local slot = tonumber(key)

                if slot then
                    slot = clamp_int(slot, 1, 12)
                    plugin_txt_data.group_slots[slot] = value or ""
                end

            elseif section == "Extra" then
                local key, value = plugin_txt_parse_kv(line)

                if key and key ~= "" then
                    plugin_txt_data.extra[key] = value or ""
                end

            else
                local key, value = plugin_txt_parse_kv(line)

                if key == "Version" then
                    plugin_txt_data.version = clean_one_line(value)

                elseif key == "PluginRaw" then
                    plugin_txt_data.raw_fx_name = clean_one_line(value)

                elseif key == "LastParam" then
                    plugin_txt_data.last_param = value or ""

                elseif key == "LastEntry" then
                    plugin_txt_data.last_entry = value or ""

                elseif key == "LastArea" then
                    value = clean_one_line(value)

                    if value ~= "browser" and value ~= "grid" then
                        value = ""
                    end

                    plugin_txt_data.last_area = value

                elseif key == "SlotAccessMode" then
                    value = clean_one_line(value)

                    if value ~= "group" and value ~= "param" then
                        value = "group"
                    end

                    plugin_txt_data.slot_access_mode = value

                elseif key == "CustomOrderView" then
                    value = clean_one_line(value)

                    if value ~= "custom" and value ~= "plugin" then
                        value = "plugin"
                    end

                    plugin_txt_data.custom_order_view = value

                elseif key == "QuickGroup" then
                    plugin_txt_data.quick_group = value or ""
                end
            end
        end
    end

    if #custom_lines > 0 then
        plugin_txt_data.custom_order = table.concat(custom_lines, "\n")
    end

    if #default_lines > 0 then
        plugin_txt_data.default_values = table.concat(default_lines, "\n")
    end

    if plugin_txt_data.raw_fx_name == "" then
        plugin_txt_data.raw_fx_name = clean_one_line(raw_fx_name or "")
    end

    if plugin_txt_data.slot_access_mode == "" then
        plugin_txt_data.slot_access_mode = "param"
    end

    if plugin_txt_data.custom_order_view == "" then
        plugin_txt_data.custom_order_view = "plugin"
    end
end

function plugin_txt_load_for_current_fx()
    local raw_fx_name = get_fx_raw_label()

    plugin_txt_loaded = false
    plugin_txt_dirty = false
    plugin_txt_loading = true
    plugin_txt_path = ""
    plugin_txt_raw_fx_name = clean_one_line(raw_fx_name or "")

    plugin_txt_reset_data(plugin_txt_raw_fx_name)

    if plugin_txt_raw_fx_name == "" then
        plugin_txt_loading = false
        return false
    end

    if not ensure_plugin_txt_folder() then
        plugin_txt_loading = false
        return false
    end

    plugin_txt_path = get_plugin_txt_path_for_fx_name(plugin_txt_raw_fx_name)

    local txt = plugin_txt_read_file(plugin_txt_path)

    if txt ~= nil then
        plugin_txt_load_from_text(txt, plugin_txt_raw_fx_name)
    else
        plugin_txt_reset_data(plugin_txt_raw_fx_name)
        plugin_txt_dirty = true
    end

    plugin_txt_loaded = true
    plugin_txt_loading = false

if plugin_txt_dirty then
    plugin_txt_save_if_dirty(true)
end

plugin_txt_last_saved_param_position = plugin_txt_get_last_param()

if type(restore_cc_combo_speech_from_txt) == "function" then
    restore_cc_combo_speech_from_txt()
end

if type(cc_runtime_restore_fixed_map_state_from_txt) == "function" then
    cc_runtime_restore_fixed_map_state_from_txt()
end

    return true
end

function plugin_txt_unload()
    plugin_txt_save_if_dirty(true)

    plugin_txt_loaded = false
    plugin_txt_dirty = false
    plugin_txt_dirty_since = 0
    plugin_txt_loading = false
    plugin_txt_path = ""
    plugin_txt_raw_fx_name = ""
plugin_txt_last_saved_param_position = ""


    plugin_txt_reset_data("")
end

------------------------------------------------------------
-- 1.6E - SCRITTURA FILE TXT PLUGIN
------------------------------------------------------------
function plugin_txt_build_text()
    local lines = {}

    lines[#lines + 1] = "# Speak FX Params - TrackTake Navigator"
    lines[#lines + 1] = "# One txt profile per plugin"
    lines[#lines + 1] = "# Storage: plugin TXT only. No project RPP state."
    lines[#lines + 1] = "# Plugin: " .. clean_one_line(plugin_txt_data.raw_fx_name or "")
    lines[#lines + 1] = ""

    lines[#lines + 1] = plugin_txt_make_kv("Version", PLUGIN_TXT_VERSION)
    lines[#lines + 1] = plugin_txt_make_kv("PluginRaw", plugin_txt_data.raw_fx_name)
    lines[#lines + 1] = plugin_txt_make_kv("LastParam", plugin_txt_data.last_param)
    lines[#lines + 1] = plugin_txt_make_kv("LastEntry", plugin_txt_data.last_entry)
    lines[#lines + 1] = plugin_txt_make_kv("LastArea", plugin_txt_data.last_area)
    lines[#lines + 1] = plugin_txt_make_kv("SlotAccessMode", plugin_txt_data.slot_access_mode)
    lines[#lines + 1] = plugin_txt_make_kv("CustomOrderView", plugin_txt_data.custom_order_view)
    lines[#lines + 1] = plugin_txt_make_kv("QuickGroup", plugin_txt_data.quick_group)

    lines[#lines + 1] = ""
    lines[#lines + 1] = "[CustomOrder]"

    local custom_order = trim(plugin_txt_data.custom_order or "")

    if custom_order ~= "" then
        for line in custom_order:gmatch("[^\r\n]+") do
            line = trim(line)

            if line ~= "" then
                lines[#lines + 1] = line
            end
        end
    end

    lines[#lines + 1] = ""
    lines[#lines + 1] = "[DefaultValues]"

    local default_values = trim(plugin_txt_data.default_values or "")

    if default_values ~= "" then
        for line in default_values:gmatch("[^\r\n]+") do
            line = trim(line)

            if line ~= "" then
                lines[#lines + 1] = line
            end
        end
    end

    lines[#lines + 1] = ""
    lines[#lines + 1] = "[ParamSlots]"

    for slot = 1, 12 do
        local value = plugin_txt_data.param_slots[slot] or ""

        if trim(value) ~= "" then
            lines[#lines + 1] = plugin_txt_make_kv(tostring(slot), value)
        end
    end

    lines[#lines + 1] = ""
    lines[#lines + 1] = "[GroupSlots]"

    for slot = 1, 12 do
        local value = plugin_txt_data.group_slots[slot] or ""

        if trim(value) ~= "" then
            lines[#lines + 1] = plugin_txt_make_kv(tostring(slot), value)
        end
    end

    lines[#lines + 1] = ""
    lines[#lines + 1] = "[Extra]"

    local extra_keys = {}

    for key, _ in pairs(plugin_txt_data.extra or {}) do
        key = clean_one_line(key or "")

        if key ~= "" then
            extra_keys[#extra_keys + 1] = key
        end
    end

    table.sort(extra_keys)

    for _, key in ipairs(extra_keys) do
        local value = plugin_txt_data.extra[key] or ""

        if trim(value) ~= "" then
            lines[#lines + 1] = plugin_txt_make_kv(key, value)
        end
    end

    lines[#lines + 1] = ""

    return table.concat(lines, "\n")
end

function plugin_txt_write_file(path, txt)
    if not path or path == "" then
        return false
    end

    ensure_plugin_txt_folder()

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

------------------------------------------------------------
-- 1.6E1 - SALVATAGGIO TXT INTELLIGENTE / SENZA AUTOSAVE A TEMPO
--
-- Nuova logica:
-- - il TXT viene marcato dirty quando cambia uno stato;
-- - non viene scritto periodicamente;
-- - plugin_txt_save_if_dirty(false) NON scrive, lascia solo dirty;
-- - plugin_txt_save_if_dirty() oppure plugin_txt_save_if_dirty(true)
--   scrivono subito se c'è qualcosa da salvare.
--
-- Questo evita scritture continue mentre si lavora in realtime.
------------------------------------------------------------

plugin_txt_last_save_time = 0
plugin_txt_dirty_since = 0
plugin_txt_last_user_action_time = 0

PLUGIN_TXT_DEFERRED_SAVE_SECONDS = 8.0
PLUGIN_TXT_IDLE_SAVE_SECONDS = 1.25

-- Ultima posizione parametro già realmente scritta su disco.
-- Serve per salvare quando si cambia parametro, non a ogni colpo di valore.
plugin_txt_last_saved_param_position = ""

function plugin_txt_save_now()
    if not plugin_txt_loaded then
        return false
    end

    if plugin_txt_path == "" then
        return false
    end

    plugin_txt_data.version = PLUGIN_TXT_VERSION

    if plugin_txt_data.raw_fx_name == "" then
        plugin_txt_data.raw_fx_name = plugin_txt_raw_fx_name
    end

    local ok = plugin_txt_write_file(
        plugin_txt_path,
        plugin_txt_build_text()
    )

    if ok then
        plugin_txt_dirty = false
        plugin_txt_dirty_since = 0

        if reaper and reaper.time_precise then
            plugin_txt_last_save_time = reaper.time_precise()
        else
            plugin_txt_last_save_time = os.clock()
        end
    end

    return ok
end

function plugin_txt_now()
    if reaper and reaper.time_precise then
        return reaper.time_precise()
    end

    return os.clock()
end

function plugin_txt_mark_dirty()
    if plugin_txt_loading then
        return
    end

    if not plugin_txt_dirty then
        plugin_txt_dirty_since = plugin_txt_now()
    end

    plugin_txt_dirty = true
end

function plugin_txt_note_user_activity()
    plugin_txt_last_user_action_time = plugin_txt_now()
end

function plugin_txt_save_deferred_if_idle()
    if not plugin_txt_loaded or not plugin_txt_dirty then
        return false
    end

    local now = plugin_txt_now()

    if plugin_txt_dirty_since <= 0 then
        plugin_txt_dirty_since = now
        return false
    end

    if (now - plugin_txt_dirty_since) < PLUGIN_TXT_DEFERRED_SAVE_SECONDS then
        return false
    end

    if plugin_txt_last_user_action_time > 0 and
       (now - plugin_txt_last_user_action_time) < PLUGIN_TXT_IDLE_SAVE_SECONDS then

        return false
    end

    return plugin_txt_save_now()
end

function plugin_txt_save_if_dirty(force)
    if not plugin_txt_dirty then
        return true
    end

    --------------------------------------------------------
    -- force == false:
    -- non scrive su disco.
    -- Serve quando vogliamo solo lasciare il TXT dirty,
    -- per esempio durante aggiornamenti interni ravvicinati.
    --------------------------------------------------------
    if force == false then
        return true
    end

    --------------------------------------------------------
    -- force == true oppure nil:
    -- salva subito se dirty.
    --------------------------------------------------------
    return plugin_txt_save_now()
end

------------------------------------------------------------
-- 1.6F - ACCESSO DIRETTO DATI TXT
------------------------------------------------------------
function plugin_txt_set_last_param(txt)
    txt = tostring(txt or "")

    if plugin_txt_data.last_param == txt then
        return
    end

    plugin_txt_data.last_param = txt
    plugin_txt_mark_dirty()
end

function plugin_txt_get_last_param()
    return plugin_txt_data.last_param or ""
end

function plugin_txt_set_last_entry(txt)
    txt = tostring(txt or "")

    if plugin_txt_data.last_entry == txt then
        return
    end

    plugin_txt_data.last_entry = txt
    plugin_txt_mark_dirty()
end

function plugin_txt_get_last_entry()
    return plugin_txt_data.last_entry or ""
end

function plugin_txt_set_last_area(txt)
    txt = clean_one_line(txt or "")

    if txt ~= "browser" and txt ~= "grid" then
        txt = "grid"
    end

    if plugin_txt_data.last_area == txt then
        return
    end

    plugin_txt_data.last_area = txt
    plugin_txt_mark_dirty()
end

function plugin_txt_get_last_area()
    return plugin_txt_data.last_area or ""
end

function plugin_txt_set_slot_access_mode(txt)
    txt = clean_one_line(txt or "")

    if txt ~= "group" and txt ~= "param" then
        txt = "group"
    end

    if plugin_txt_data.slot_access_mode == txt then
        return
    end

    plugin_txt_data.slot_access_mode = txt
    plugin_txt_mark_dirty()
end

function plugin_txt_get_slot_access_mode()
    local txt = clean_one_line(plugin_txt_data.slot_access_mode or "")

    if txt ~= "group" and txt ~= "param" then
        txt = "group"
    end

    return txt
end

function plugin_txt_set_custom_order_view(txt)
    txt = clean_one_line(txt or "")

    if txt ~= "custom" and txt ~= "plugin" then
        txt = "plugin"
    end

    if plugin_txt_data.custom_order_view == txt then
        return
    end

    plugin_txt_data.custom_order_view = txt
    plugin_txt_mark_dirty()
end

function plugin_txt_get_custom_order_view()
    local txt = clean_one_line(plugin_txt_data.custom_order_view or "")

    if txt ~= "custom" and txt ~= "plugin" then
        txt = "plugin"
    end

    return txt
end

function plugin_txt_set_custom_order(txt)
    txt = tostring(txt or "")

    if plugin_txt_data.custom_order == txt then
        return
    end

    plugin_txt_data.custom_order = txt
    plugin_txt_mark_dirty()
end

function plugin_txt_get_custom_order()
    return plugin_txt_data.custom_order or ""
end

function plugin_txt_set_default_values(txt)
    txt = tostring(txt or "")

    if plugin_txt_data.default_values == txt then
        return
    end

    plugin_txt_data.default_values = txt
    plugin_txt_mark_dirty()
end

function plugin_txt_get_default_values()
    return plugin_txt_data.default_values or ""
end

function plugin_txt_clear_default_values()
    if trim(plugin_txt_data.default_values or "") ~= "" then
        plugin_txt_data.default_values = ""
        plugin_txt_mark_dirty()
    end
end

function plugin_txt_default_values_has_content()
    return trim(plugin_txt_data.default_values or "") ~= ""
end


function plugin_txt_set_quick_group(txt)
    txt = tostring(txt or "")

    if plugin_txt_data.quick_group == txt then
        return
    end

    plugin_txt_data.quick_group = txt
    plugin_txt_mark_dirty()
end

function plugin_txt_get_quick_group()
    return plugin_txt_data.quick_group or ""
end

function plugin_txt_set_param_slot(slot, txt)
    slot = clamp_int(slot, 1, 12)
    txt = tostring(txt or "")

    if plugin_txt_data.param_slots[slot] == txt then
        return
    end

    plugin_txt_data.param_slots[slot] = txt
    plugin_txt_mark_dirty()
end

function plugin_txt_get_param_slot(slot)
    slot = clamp_int(slot, 1, 12)

    return plugin_txt_data.param_slots[slot] or ""
end

function plugin_txt_set_group_slot(slot, txt)
    slot = clamp_int(slot, 1, 12)
    txt = tostring(txt or "")

    if plugin_txt_data.group_slots[slot] == txt then
        return
    end

    plugin_txt_data.group_slots[slot] = txt
    plugin_txt_mark_dirty()
end

function plugin_txt_get_group_slot(slot)
    slot = clamp_int(slot, 1, 12)

    return plugin_txt_data.group_slots[slot] or ""
end

------------------------------------------------------------
-- 1.6G - PONTE GENERICO PER TXT PLUGIN
------------------------------------------------------------
function normalize_plugin_state_key(key)
    key = clean_one_line(key or "")

    if key == "last_param_v1" then
        return "last_param"
    end

    if key == "last_entry_v1" then
        return "last_entry"
    end

    if key == "last_area_v1" then
        return "last_area"
    end

    if key == "custom_order_view_v1" then
        return "custom_order_view"
    end

    if key == "custom_order_v1" then
        return "custom_order"
    end

    if key == "temporary_group_v1" then
        return "quick_group"
    end

    local slot = key:match("^group_slot_v1::slot::(%d+)$")

    if slot then
        return "group_slot", clamp_int(tonumber(slot), 1, 12)
    end

    slot = key:match("^param_memory_slot_v1::slot::(%d+)$")

    if slot then
        return "param_slot", clamp_int(tonumber(slot), 1, 12)
    end

    return "extra", key
end

function get_plugin_state(key)
    if not plugin_txt_loaded then
        return ""
    end

    local kind, arg = normalize_plugin_state_key(key)

    if kind == "last_param" then
        return plugin_txt_get_last_param()
    end

    if kind == "last_entry" then
        return plugin_txt_get_last_entry()
    end

    if kind == "last_area" then
        return plugin_txt_get_last_area()
    end

    if kind == "custom_order_view" then
        return plugin_txt_get_custom_order_view()
    end

    if kind == "custom_order" then
        return plugin_txt_get_custom_order()
    end

    if kind == "quick_group" then
        return plugin_txt_get_quick_group()
    end

    if kind == "group_slot" then
        return plugin_txt_get_group_slot(arg)
    end

    if kind == "param_slot" then
        return plugin_txt_get_param_slot(arg)
    end

    if kind == "extra" and arg ~= "" then
        return plugin_txt_data.extra[arg] or ""
    end

    return ""
end

function set_plugin_state(key, value)
    if not plugin_txt_loaded then
        return
    end

    local kind, arg = normalize_plugin_state_key(key)
    value = tostring(value or "")

    if kind == "last_param" then
        plugin_txt_set_last_param(value)

    elseif kind == "last_entry" then
        plugin_txt_set_last_entry(value)

    elseif kind == "last_area" then
        plugin_txt_set_last_area(value)

    elseif kind == "custom_order_view" then
        plugin_txt_set_custom_order_view(value)

    elseif kind == "custom_order" then
        plugin_txt_set_custom_order(value)

    elseif kind == "quick_group" then
        plugin_txt_set_quick_group(value)

    elseif kind == "group_slot" then
        plugin_txt_set_group_slot(arg, value)

    elseif kind == "param_slot" then
        plugin_txt_set_param_slot(arg, value)

    elseif kind == "extra" and arg ~= "" then
        if plugin_txt_data.extra[arg] ~= value then
            plugin_txt_data.extra[arg] = value
            plugin_txt_mark_dirty()
        end
    end

    --------------------------------------------------------
    -- Importante:
    -- qui NON si salva più su disco.
    -- set_plugin_state() aggiorna solo il profilo in memoria
    -- e marca dirty se qualcosa è cambiato.
    --
    -- Il salvataggio vero viene fatto dai punti importanti:
    -- cambio parametro, cambio FX, uscita, memorie, custom order,
    -- grid/step, nomi, ecc.
    --------------------------------------------------------
end

------------------------------------------------------------
-- 1.7 - COSTANTI REAPER / COMANDI
------------------------------------------------------------
MONITOR_FX_OFFSET = 0x1000000

CMD_UNSELECT_ALL_ITEMS = 40289

CMD_PLAY       = 1007
CMD_PLAY_STOP  = 40044
CMD_PLAY_PAUSE = 40073
CMD_UNDO       = 40029

CMD_SHOW_HIDE_ENV_LAST_TOUCHED_PARAM = 41142

CMD_F5_ACTION = 40280
CMD_F6_ACTION = 40281
CMD_F9_ACTION = 40282
CMD_SHOW_FX_BROWSER = 40271
CMD_DELTA_SOLO_LAST_FOCUSED_FX = 42455

------------------------------------------------------------
-- 1.8 - KEYCODES
------------------------------------------------------------
KEY_ESC = 27

KEY_BACKSPACE   = 8
KEY_BACKSPACE_2 = 127
KEY_BACKSPACE_3 = 6579564

KEY_UP        = 30064
KEY_DOWN      = 1685026670
KEY_LEFT      = 1818584692
KEY_RIGHT     = 1919379572
KEY_HOME      = 6647396
KEY_END       = 1752132965
KEY_PAGE_UP   = 1885828464
KEY_PAGE_DOWN = 1885824110
KEY_ENTER     = 13
KEY_TAB       = 9
KEY_DELETE    = 6579564
KEY_BACKSLASH = 92
KEY_SHIFT_BACKSLASH = 124
KEY_SPACE     = 32
KEY_A         = 65
KEY_C         = 67
KEY_CTRL_ALT_A = 257
KEY_CTRL_ALT_C = 259

KEY_PLUS       = 43
KEY_MINUS      = 45
KEY_EQUAL      = 61
KEY_CTRL_MINUS = 31

KEY_CTRL_A = 1
KEY_CTRL_B = 2
KEY_CTRL_ALT_B = 258
KEY_CTRL_D = 4
KEY_CTRL_E = 5
KEY_CTRL_F = 6
KEY_CTRL_G = 7
KEY_CTRL_I = 9
KEY_CTRL_L = 12
KEY_CTRL_O = 15
KEY_CTRL_P = 16
KEY_CTRL_Q = 17
KEY_CTRL_R = 18
KEY_CTRL_V = 22
KEY_CTRL_W = 23
KEY_CTRL_X = 24
KEY_CTRL_C = 3
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
-- 1.8A - JS_ReaScriptAPI KEY STATE HELPERS
--
-- Alcuni tasti globali non arrivano sempre da gfx.getchar().
-- In particolare:
-- - Ctrl+1 ... Ctrl+0 possono arrivare con char == 0.
-- Ctrl+Space è stato provato ma resta disattivato: in questo contesto non è affidabile.
--
-- Qui leggiamo JS_VKeys_GetState come nello script Track Params:
-- state:byte(VK), non VK + 1.
------------------------------------------------------------

VK_SPACE = 0x20
VK_ENTER = 0x0D
VK_TAB = 0x09
VK_I = 0x49
VK_M = 0x4D
VK_C = 0x43
VK_0 = 0x30
VK_1 = 0x31
VK_2 = 0x32
VK_3 = 0x33
VK_4 = 0x34
VK_5 = 0x35
VK_6 = 0x36
VK_7 = 0x37
VK_8 = 0x38
VK_9 = 0x39
VK_CTRL  = 0x11
VK_SHIFT = 0x10
VK_ALT   = 0x12

js_key_edge_state = {}

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

function js_ctrl_down_now()
    return ctrl_down() or js_vkey_down_now(VK_CTRL)
end

function js_shift_down_now()
    return shift_down() or js_vkey_down_now(VK_SHIFT)
end

function js_alt_down_now()
    return alt_down() or js_vkey_down_now(VK_ALT)
end

------------------------------------------------------------
-- CTRL+M DISAMBIGUATION
--
-- In gfx.getchar() Ctrl+M arriva come char 13, lo stesso
-- codice di Enter. Il report MK X conferma il metodo sicuro:
-- - Ctrl premuto;
-- - JS physical M down;
-- - JS physical Enter non down.
--
-- Manteniamo l'indicizzazione già usata dallo script:
-- state:byte(VK), non VK + 1.
------------------------------------------------------------
function char13_is_ctrl_m(char)
    if char ~= KEY_ENTER then
        return false
    end

    if not ctrl_down() or shift_down() or alt_down() then
        return false
    end

    local state = js_vkeys_state_now()

    if state == "" then
        return false
    end

    local m_down = (state:byte(VK_M) or 0) ~= 0
    local enter_down = (state:byte(VK_ENTER) or 0) ~= 0

    return m_down and not enter_down
end

space_transport_was_down = false
space_transport_swallow_queue = false
space_transport_intercept_active = false

function transport_run_command(command_id, error_message)
    cancel_pending_speech()

    if type(clear_silent_edge) == "function" then
        clear_silent_edge()
    end

    if reaper.Main_OnCommand then
        reaper.Main_OnCommand(command_id, 0)
        return true
    end

    speak(error_message or "Transport command not available")
    return true
end

function transport_play_stop_manual()
    local state = 0

    if reaper.GetPlayState then
        state = reaper.GetPlayState() or 0
    end

    --------------------------------------------------------
    -- Spazio normale deve restare Play / Stop.
    -- Se il transport è in pausa per Ctrl+Spazio, però,
    -- Spazio deve ripartire subito senza richiedere una
    -- seconda pressione.
    --------------------------------------------------------

    if (state & 2) == 2 and reaper.OnPlayButton then
        cancel_pending_speech()

        if type(clear_silent_edge) == "function" then
            clear_silent_edge()
        end

        reaper.OnPlayButton()
        return true
    end

    return transport_run_command(
        CMD_PLAY_STOP,
        "Play stop command not available"
    )
end

function transport_play_pause_manual()
    cancel_pending_speech()

    if type(clear_silent_edge) == "function" then
        clear_silent_edge()
    end

    local state = 0

    if reaper.GetPlayState then
        state = reaper.GetPlayState() or 0
    end

    --------------------------------------------------------
    -- GetPlayState:
    -- bit 1 = playing, bit 2 = paused, bit 4 = recording.
    -- Ctrl+Spazio mentre suona/rec registra deve mettere in
    -- pausa. Da fermo o da pausa deve ripartire con Play.
    --------------------------------------------------------

    local is_playing_or_recording =
        ((state & 1) == 1) or
        ((state & 4) == 4)

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

if reaper.atexit then
    reaper.atexit(transport_space_release_intercept)
end


function transport_should_swallow_space_char(char)
    if not space_transport_swallow_queue then
        return false
    end

    if char ~= KEY_SPACE then
        return false
    end

    local space_ctrl = js_ctrl_down_now()
    local space_shift = js_shift_down_now()
    local space_alt = js_alt_down_now()

    space_transport_swallow_queue = false

    if space_ctrl and not space_shift and not space_alt then
        return true
    end

    return false
end

function js_key_edge(name, down)
    name = clean_one_line(name or "")

    if name == "" then
        return false
    end

    down = down == true

    local was_down = js_key_edge_state[name] == true
    js_key_edge_state[name] = down

    return down and not was_down
end

function js_clear_key_edge(name)
    name = clean_one_line(name or "")

    if name ~= "" then
        js_key_edge_state[name] = false
    end
end

function mode_is_text_edit()
    return
        mode == "search_edit" or
        mode == "name_edit" or
        mode == "group_name_edit" or
        edit_mode == true
end

function js_digit_vk_to_marker_number(vk)
    vk = tonumber(vk) or -1

    if vk == VK_0 then
        return 10
    end

    if vk >= VK_1 and vk <= VK_9 then
        return vk - VK_0
    end

    return nil
end

------------------------------------------------------------
-- 1.9 - FUNZIONI PER SLOT F1 ... F12
------------------------------------------------------------
FUNCTION_KEY_SLOTS = {
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

function function_key_to_slot(char)
    return FUNCTION_KEY_SLOTS[char]
end

------------------------------------------------------------
-- 1.10 - STATO GLOBALE: CONTESTO TRACK / TAKE / MASTER
------------------------------------------------------------
ctx = {
    kind = nil,
    track = nil,
    take = nil,
    item = nil,
    is_master = false
}

-- Contesto usato solo quando l'apertura fallisce.
-- Serve per distinguere il messaggio:
-- "No FX found for item" / "No FX found for track".
start_context_no_fx_kind = ""

------------------------------------------------------------
-- 1.11 - STATO GLOBALE: FX CORRENTE
------------------------------------------------------------
fx_count = 0
fx_names = {}
fx_real_indices = {}
fx_is_monitor = {}

fx_index = 0
selected_fx_label = ""
selected_fx_is_monitor = false

initial_fx_restored_by_memory = false

param_count = 0

------------------------------------------------------------
-- 1.11A - STATO GRIGLIA FX OFFLINE
--
-- Quando un FX è offline, REAPER può esporre solo i controlli
-- generici dell'FX oppure nessun parametro utile del plugin.
-- In quel caso la griglia resta intenzionalmente vuota e parla
-- solo un messaggio fisso: "Offline <nome FX>".
------------------------------------------------------------
fx_offline_grid_active = false
fx_offline_grid_label = ""

------------------------------------------------------------
-- 1.12 - STATO GLOBALE: BROWSER FX INTERNO
------------------------------------------------------------
fx_browser_pos = 1
fx_browser_col = "fx"

fx_browser_all = {}
fx_browser_master = {}
fx_browser_monitor = {}

------------------------------------------------------------
-- 1.13 - STATO GLOBALE: PARAMETRO / GRIGLIA ATTIVA
------------------------------------------------------------
param_index = 0
active_pos = 1

all_param_indices = {}
active_param_indices = {}

custom_order_active = false
custom_order_indices = {}
custom_order_dirty = false
custom_param_aliases = {}

mode = "list"
value_return_mode = "list"
numeric_return_mode = "list"

last_letter_key = nil

------------------------------------------------------------
-- 1.14 - STATO GLOBALE: EDIT NUMERICO
------------------------------------------------------------
edit_mode = false
edit_buffer = ""
edit_cursor = 1
edit_started = false

------------------------------------------------------------
-- 1.15 - STATO GLOBALE: RICERCA E RINOMINA PARAMETRO
------------------------------------------------------------
search_results = {}
search_active = false
search_query = ""
search_buffer = ""
search_cursor = 1
search_edge = nil

name_edit_buffer = ""
name_edit_cursor = 1
name_edit_edge = nil
name_edit_return_mode = "list"
name_edit_param_index = nil

group_name_edit_buffer = ""
group_name_edit_cursor = 1
group_name_edit_edge = nil
group_name_edit_return_mode = "list"
group_name_edit_slot = nil

search_edit_fresh = false
name_edit_fresh = false
group_name_edit_fresh = false
numeric_edit_fresh = false

------------------------------------------------------------
-- 1.15A - RITORNO DALLA RICERCA
--
-- Ctrl+F può essere rilanciato più volte senza perdere il
-- contesto da cui è partita la prima ricerca. Esc è l'unico
-- comando che chiude la sessione Search e torna all'origine.
------------------------------------------------------------
search_return_valid = false
search_return_mode = "list"
search_return_param_index = nil
search_return_active_pos = 1
search_return_custom_order_active = false
search_return_group_active = false
search_return_group_slot = nil
search_return_group_edit_is_temporary = false
search_return_group_results = {}
search_return_group_selected = {}
search_return_group_select_anchor_pos = 1
search_return_group_select_path = {}
search_return_group_select_dir_path = {}
search_return_group_select_path_action = "select"
search_return_group_select_base_selected = {}
search_return_group_edit_loaded_slot = nil
search_return_group_edit_show_all_params = false
search_return_group_edit_occurrence_selected = {}
search_return_group_edit_occurrence_base_selected = {}
search_return_group_edit_search_positions = {}

------------------------------------------------------------
-- 1.16 - STATO GLOBALE: GRUPPI PARAMETRI
------------------------------------------------------------
group_results = {}
group_active = false
group_selected = {}

current_group_slot = nil
last_toggle_group_slot = nil
group_edit_is_temporary = false

------------------------------------------------------------
-- 1.16G - GROUP AUTONOMO / OCCORRENZE
--
-- group_results è la lista autoritativa del Group caricato.
-- Conserva ordine e duplicati ed è indipendente da Custom order.
--
-- Quando F7 viene aperto da un Group reale, la selezione deve
-- distinguere le OCCORRENZE, non soltanto il param_index.
------------------------------------------------------------
group_edit_loaded_slot = nil
group_edit_show_all_params = false
group_edit_occurrence_selected = {}
group_edit_occurrence_base_selected = {}
group_edit_search_positions = {}

------------------------------------------------------------
-- Clipboard Group separata dalla Custom order.
-- Gli indici possono arrivare anche da Plugin/Custom/F7, ma
-- incollare dentro un Group modifica esclusivamente quel Group.
------------------------------------------------------------
group_clipboard_source_slot = nil
group_clipboard_source_positions = {}

------------------------------------------------------------
-- 1.16A - F7 GROUP EDIT: SERPENTE / SELEZIONE CONTINUA
------------------------------------------------------------
group_select_anchor_pos = 1
group_select_path = {}
group_select_dir_path = {}
group_select_path_lookup = {}

-- Selezione già esistente prima del tratto corrente del serpente.
-- Serve per continuare la selezione dopo una pausa senza ripartire da zero.
group_select_base_selected = {}

-- Azione del tratto corrente del serpente:
-- "select"   = aggiunge selezione
-- "unselect" = toglie selezione
group_select_path_action = "select"

------------------------------------------------------------
-- 1.16B - RITORNO DA F7 GROUP EDIT
------------------------------------------------------------
panel_return_mode = "all"
panel_return_group_slot = nil
panel_return_param_index = nil

------------------------------------------------------------
-- 1.20B - SNAPSHOT COMPLETO CONTESTO GRIGLIA
--
-- Usato dai pannelli temporanei (Recent / F8) per tornare
-- ESATTAMENTE al punto di partenza senza appiattire il contesto:
-- Plugin order, Custom order, Search results, Group ed Edit F7.
------------------------------------------------------------
recent_return_snapshot = nil
memory_manager_grid_return_snapshot = nil
f7_grid_return_snapshot = nil

function navigation_snapshot_copy_table(src)
    local out = {}
    src = src or {}

    for k, v in pairs(src) do
        out[k] = v
    end

    return out
end

function capture_navigation_return_snapshot()
    return {
        valid = true,
        mode = mode or "list",
        param_index = param_index,
        active_pos = tonumber(active_pos) or 1,
        custom_order_active = custom_order_active == true,

        search_active = search_active == true,
        search_results = navigation_snapshot_copy_table(search_results),
        search_query = tostring(search_query or ""),

        group_active = group_active == true,
        group_slot = current_group_slot,
        group_edit_is_temporary = group_edit_is_temporary == true,
        group_results = navigation_snapshot_copy_table(group_results),
        group_selected = navigation_snapshot_copy_table(group_selected),
        group_edit_loaded_slot = group_edit_loaded_slot,
        group_edit_show_all_params = group_edit_show_all_params == true,
        group_edit_occurrence_selected =
            navigation_snapshot_copy_table(group_edit_occurrence_selected),
        group_edit_occurrence_base_selected =
            navigation_snapshot_copy_table(group_edit_occurrence_base_selected),
        group_edit_search_positions =
            navigation_snapshot_copy_table(group_edit_search_positions),

        group_select_anchor_pos = tonumber(group_select_anchor_pos) or 1,
        group_select_path = navigation_snapshot_copy_table(group_select_path),
        group_select_dir_path = navigation_snapshot_copy_table(group_select_dir_path),
        group_select_path_action = tostring(group_select_path_action or "select"),
        group_select_base_selected = navigation_snapshot_copy_table(group_select_base_selected),

        f7_return_mode = f7_return_mode,
        f7_return_group_slot = f7_return_group_slot,
        f7_return_param_index = f7_return_param_index
    }
end

function restore_navigation_return_snapshot(snapshot, announce_it)
    clear_param_memory_arm()
    disarm_slot_deletes()

    if type(snapshot) ~= "table" or snapshot.valid ~= true then
        return_to_all_parameters(nil)
        return true
    end

    local wanted_mode = snapshot.mode or "list"
    local wanted_param = snapshot.param_index
    local wanted_pos = tonumber(snapshot.active_pos) or 1

    custom_order_active = snapshot.custom_order_active == true
    build_all_param_indices()

    --------------------------------------------------------
    -- Edit F7: ripristina anche selezione, percorso Shift e
    -- destinazione originale del successivo F7/Esc.
    --------------------------------------------------------
    if wanted_mode == "group_edit" then
        ----------------------------------------------------
        -- F7 può contenere anche un filtro Search attivo.
        -- Il filtro è solo una vista: selezione e contesto
        -- F7 restano indipendenti.
        ----------------------------------------------------
        search_active = snapshot.search_active == true
        search_results =
            navigation_snapshot_copy_table(snapshot.search_results)
        search_query = tostring(snapshot.search_query or "")

        group_selected =
            navigation_snapshot_copy_table(snapshot.group_selected)

        group_results =
            navigation_snapshot_copy_table(snapshot.group_results)

        group_edit_occurrence_selected =
            navigation_snapshot_copy_table(snapshot.group_edit_occurrence_selected)
        group_edit_occurrence_base_selected =
            navigation_snapshot_copy_table(snapshot.group_edit_occurrence_base_selected)
        group_edit_search_positions =
            navigation_snapshot_copy_table(snapshot.group_edit_search_positions)

        group_active = false
        set_f7_group_edit_context(snapshot.group_edit_loaded_slot)
        group_edit_show_all_params = snapshot.group_edit_show_all_params == true

        mode = "group_edit"
        value_return_mode = "group_edit"
        numeric_return_mode = "group_edit"

        group_select_anchor_pos =
            tonumber(snapshot.group_select_anchor_pos) or 1

        group_select_path =
            navigation_snapshot_copy_table(snapshot.group_select_path)

        group_select_dir_path =
            navigation_snapshot_copy_table(snapshot.group_select_dir_path)

        group_select_path_action =
            tostring(snapshot.group_select_path_action or "select")

        group_select_base_selected =
            navigation_snapshot_copy_table(snapshot.group_select_base_selected)

        if type(group_edit_rebuild_path_lookup) == "function" then
            group_edit_rebuild_path_lookup()
        end

        f7_return_mode = snapshot.f7_return_mode or f7_return_mode
        f7_return_group_slot = snapshot.f7_return_group_slot
        f7_return_param_index = snapshot.f7_return_param_index

    elseif snapshot.search_active == true then
        ----------------------------------------------------
        -- Risultati Search già applicati: Recent/F8 devono
        -- poter tornare anche dentro quel recinto.
        ----------------------------------------------------
        group_active = false
        group_results = {}
        clear_group_context()

        search_active = true
        search_results =
            navigation_snapshot_copy_table(snapshot.search_results)
        search_query = tostring(snapshot.search_query or "")

        mode = "list"
        value_return_mode = "list"
        numeric_return_mode = "list"

    elseif snapshot.group_active == true then
        ----------------------------------------------------
        -- Group caricato.
        ----------------------------------------------------
        search_active = false
        search_results = {}
        search_query = ""

        group_selected =
            navigation_snapshot_copy_table(snapshot.group_selected)

        group_results =
            navigation_snapshot_copy_table(snapshot.group_results)

        group_active = true

        if snapshot.group_slot ~= nil then
            set_loaded_group_context(snapshot.group_slot)
        elseif snapshot.group_edit_is_temporary == true then
            set_f7_group_edit_context()
        else
            clear_group_context()
        end

        mode = "list"
        value_return_mode = "list"
        numeric_return_mode = "list"

    else
        ----------------------------------------------------
        -- Plugin order / Custom order normale.
        ----------------------------------------------------
        search_active = false
        search_results = {}
        search_query = ""

        group_active = false
        group_results = {}
        clear_group_context()

        mode = "list"
        value_return_mode = "list"
        numeric_return_mode = "list"
    end

    active_pos = wanted_pos

    --------------------------------------------------------
    -- Nei Group l'occorrenza è identificata anche dalla sua
    -- posizione. Con duplicati non dobbiamo saltare alla prima
    -- occorrenza dello stesso param_index.
    --------------------------------------------------------
    if (wanted_mode == "group_edit" and
        snapshot.group_edit_loaded_slot ~= nil) or
       snapshot.group_active == true then

        active_pos = clamp_int(
            wanted_pos,
            1,
            math.max(1, get_active_count())
        )
        sync_param_from_active_pos()

    elseif wanted_param ~= nil and
           not set_param_index_absolute(wanted_param, false) then

        active_pos = clamp_int(
            wanted_pos,
            1,
            math.max(1, get_active_count())
        )
        sync_param_from_active_pos()
    end

    save_current_param_position()
    save_current_entry_state()

    if announce_it ~= false then
        announce_grid_context(nil)
    end

    return true
end

f7_return_mode = "all"
f7_return_group_slot = nil
f7_return_param_index = nil

group_edit_return_mode = "all"
group_edit_return_group_slot = nil
group_edit_return_param_index = nil

------------------------------------------------------------
-- 1.16C - RITORNO DA F8 Parameter Navigator.
------------------------------------------------------------
memory_manager_return_mode = "all"
memory_manager_return_group_slot = nil
memory_manager_return_param_index = nil

------------------------------------------------------------
-- 1.16D - F7 GROUP EDIT: MEMORIA RUNTIME PER FX
--
-- Non viene salvata nel TXT.
-- Vive solo finché lo script resta aperto.
-- Ogni istanza FX ha la sua selezione F7 separata.
------------------------------------------------------------
f7_runtime_selected_by_fx = {}

------------------------------------------------------------
-- 1.16E - CUSTOM ORDER CUT / PASTE CLIPBOARD
--
-- Ctrl+X:
--   fuori da F7 taglia il parametro corrente;
--   dentro F7 taglia i parametri selezionati.
--
-- Ctrl+V:
--   incolla/sposta il blocco tagliato nella Custom order,
--   prima del parametro corrente.
------------------------------------------------------------
custom_cut_clipboard_indices = {}
custom_cut_clipboard_order_positions = {}
custom_cut_clipboard_group_positions = {}
custom_clipboard_group_origin = false
custom_clipboard_group_signature = ""
custom_clipboard_mode = "" -- "cut" or "copy"


------------------------------------------------------------
-- 1.16F - CUSTOM ORDER HIDDEN PARAMETERS
--
-- Parametri nascosti nella Custom order.
-- Salvati nel TXT plugin in [Extra] con chiave hidden_params_v1.
-- Quando Custom order è attivo, questi parametri vengono esclusi
-- dalla griglia e quindi anche dai gruppi.
------------------------------------------------------------
hidden_param_selected = {}

------------------------------------------------------------
-- 1.17 - STATO GLOBALE: RICERCHE RECENTI
------------------------------------------------------------
recent_searches = {}
recent_pos = 1
RECENT_MAX = 20

------------------------------------------------------------
-- 1.18 - STATO GLOBALE: FUNZIONI GLOBALI
------------------------------------------------------------
last_function_touched = nil

title = ""

------------------------------------------------------------
-- 1.19 - MEMORIA PARAMETRO ARMATA
------------------------------------------------------------
param_memory_armed_index = nil
param_memory_armed_name = ""

------------------------------------------------------------
-- 1.19A - CC LEARN MODE
--
-- Ctrl+Alt+C:
-- Durante CC Learn:
--   - muovi un controller MIDI CC;
--   - il primo CC nuovo viene imparato automaticamente;
--   - Tab legge lo stato del learn;
--   - Enter non fa nulla;
--   - Delete rimuove il learn dal parametro;
--   - Esc resta uscita globale dello script.
------------------------------------------------------------
cc_learn_return_mode = "list"
cc_learn_target_param_index = nil
cc_learn_target_param_name = ""

cc_learn_last_seq = 0

cc_learn_captured = false
cc_learn_channel = nil
cc_learn_cc = nil
cc_learn_value = nil
cc_learn_status_byte = nil

------------------------------------------------------------
-- CC RUNTIME LINK
--
-- Dopo il learn, lo script controlla i CC in ingresso anche
-- fuori dalla modalità CC Learn.
--
-- Il valore MIDI 0..127 viene convertito in valore normalizzato:
--   norm = value / 127
--
-- Per ReaEQ band Gain il norm del CC viene rimappato sul
-- range esteso -inf / +36.1 dB, non sul limite API +12 dB.
-- Quindi il parametro cambia realmente valore mentre muovi
-- il controller.
------------------------------------------------------------
CC_LINK_PREFIX = "cc_link_v1::param::"

CC_COMBO_SPEECH_ENABLED_KEY = "cc_combo_speech_enabled_v1"
CC_RUNTIME_FIXED_MAP_ENABLED_KEY = "cc_runtime_fixed_map_enabled_v1"

cc_runtime_last_seq = 0
cc_runtime_busy = false

-- Shift+C:
-- interruttore runtime per la mappa dei CC fissi salvati nel TXT.
-- Ctrl+Alt+C resta dedicato al CC Learn del parametro corrente.
cc_runtime_fixed_map_enabled = false

------------------------------------------------------------
-- FIXED CC PICKUP / SOFT TAKEOVER
--
-- Vale per i CC salvati nel TXT plugin.
-- Il parametro non viene mosso finché il valore fisico del CC
-- non raggiunge o attraversa il valore reale corrente dello slider.
------------------------------------------------------------


------------------------------------------------------------
-- CC PARAM VALUE PATH / REAEQ EXTENDED GAIN
--
-- Normalmente un CC MIDI 0..127 viene convertito in norm 0..1
-- e scritto con SetParamNormalized.
--
-- Per il Gain delle bande ReaEQ questo non basta: la manopola
-- normalizzata/API si ferma circa a +12 dB, mentre ReaEQ accetta
-- il valore reale fino a +36.1 dB tramite il percorso numerico/chunk.
-- Qui diamo ai CC lo stesso range esteso usato dalla tastiera.
------------------------------------------------------------

function reaeq_gain_cc_is_extended_param(i)
    i = tonumber(i)

    if i == nil then
        return false
    end

    return
        type(is_current_fx_reaeq) == "function" and
        is_current_fx_reaeq() and
        type(reaeq_param_is_gain) == "function" and
        reaeq_param_is_gain(i) == true
end

function reaeq_gain_cc_db_to_norm(db)
    db = tonumber(db)

    if db == nil then
        return 0
    end

    if type(reaeq_clamp_gain_db) == "function" then
        db = reaeq_clamp_gain_db(db)
    else
        db = clamp(db, -150, 36.1)
    end

    local min_db = tonumber(REAEQ_GAIN_REAL_MIN_DB) or -150
    local max_db = tonumber(REAEQ_GAIN_REAL_MAX_DB) or 36.1
    local span = max_db - min_db

    if span <= 0 then
        return 0
    end

    return clamp01((db - min_db) / span)
end

function reaeq_gain_cc_norm_to_db(norm)
    norm = clamp01(norm)

    local min_db = tonumber(REAEQ_GAIN_REAL_MIN_DB) or -150
    local max_db = tonumber(REAEQ_GAIN_REAL_MAX_DB) or 36.1

    if norm <= 0 then
        return min_db
    end

    return min_db + ((max_db - min_db) * norm)
end

function reaeq_gain_cc_get_current_norm(i)
    if not reaeq_gain_cc_is_extended_param(i) then
        return get_param_value_norm(i)
    end

    local db = nil

    if type(reaeq_get_gain_db_for_nudge) == "function" then
        db = reaeq_get_gain_db_for_nudge(i)
    end

    if db == nil then
        local raw = get_param_raw(i)
        raw = tonumber(raw)

        if raw ~= nil and type(reaeq_gain_raw_to_db) == "function" then
            db = reaeq_gain_raw_to_db(raw)
        end
    end

    if db == nil then
        return get_param_value_norm(i)
    end

    return reaeq_gain_cc_db_to_norm(db)
end

function reaeq_gain_cc_apply_norm(i, norm)
    if not reaeq_gain_cc_is_extended_param(i) then
        return false
    end

    local db = reaeq_gain_cc_norm_to_db(norm)

    if type(reaeq_set_gain_db_by_feedback) == "function" then
        return reaeq_set_gain_db_by_feedback(i, db)
    end

    return false
end

function cc_control_get_param_norm_for_pickup(i)
    if type(reaeq_gain_cc_is_extended_param) == "function" and
       reaeq_gain_cc_is_extended_param(i) and
       type(reaeq_gain_cc_get_current_norm) == "function" then

        return reaeq_gain_cc_get_current_norm(i)
    end

    return get_param_value_norm(i)
end

function cc_control_set_param_norm(i, norm)
    if type(reaeq_gain_cc_is_extended_param) == "function" and
       reaeq_gain_cc_is_extended_param(i) and
       type(reaeq_gain_cc_apply_norm) == "function" then

        return reaeq_gain_cc_apply_norm(i, norm)
    end

    set_param_value_norm(i, norm)
    return true
end


cc_runtime_pickup_by_param = {}

------------------------------------------------------------
-- FIXED CC ANTI-JITTER / RAW STABILIZER
--
-- Stessa logica usata in Track Params:
-- - 1 step MIDI deve confermarsi 3 volte;
-- - 2 step MIDI deve confermarsi 2 volte;
-- - 3 step o più passa subito.
--
-- Così i valori restano tutti raggiungibili, ma il potenziometro
-- fermo non fa ballare il parametro sul valore vicino.
------------------------------------------------------------
cc_runtime_last_applied_midi_by_param = {}

function cc_runtime_should_ignore_jitter_for_param(i, midi_value)
    i = tonumber(i)
    midi_value = tonumber(midi_value)

    if i == nil or midi_value == nil then
        return false
    end

    midi_value = clamp_int(midi_value, 0, 127)

    local key = cc_runtime_pickup_make_key(i)
    local st = cc_runtime_last_applied_midi_by_param[key]

    if type(st) ~= "table" then
        cc_runtime_last_applied_midi_by_param[key] = {
            accepted = midi_value,
            candidate = nil,
            candidate_count = 0
        }
        return false
    end

    local accepted = clamp_int(st.accepted, 0, 127)

    if midi_value == accepted then
        st.candidate = nil
        st.candidate_count = 0
        return true
    end

    local diff = math.abs(midi_value - accepted)

    if diff >= 3 then
        st.accepted = midi_value
        st.candidate = nil
        st.candidate_count = 0
        return false
    end

    if st.candidate == midi_value then
        st.candidate_count = (tonumber(st.candidate_count) or 0) + 1
    else
        st.candidate = midi_value
        st.candidate_count = 1
    end

    local needed = diff <= 1 and 3 or 2

    if st.candidate_count >= needed then
        st.accepted = midi_value
        st.candidate = nil
        st.candidate_count = 0
        return false
    end

    return true
end

function cc_runtime_clear_anti_jitter_for_param(i)
    i = tonumber(i)

    if i == nil then
        return false
    end

    cc_runtime_last_applied_midi_by_param[
        cc_runtime_pickup_make_key(i)
    ] = nil

    return true
end

function cc_runtime_pickup_make_key(i)
    local real_fx = nil

    if type(get_current_real_fx_index) == "function" then
        real_fx = get_current_real_fx_index()
    end

    return
        tostring(real_fx or fx_index or 0) ..
        "::" ..
        tostring(i)
end

function cc_runtime_clear_pickup_for_param(i)
    i = tonumber(i)

    if i == nil then
        return false
    end

    cc_runtime_pickup_by_param[
        cc_runtime_pickup_make_key(i)
    ] = nil

    if type(cc_runtime_clear_anti_jitter_for_param) == "function" then
        cc_runtime_clear_anti_jitter_for_param(i)
    end

    return true
end

function cc_runtime_clear_all_pickup()
    cc_runtime_pickup_by_param = {}
    cc_runtime_last_applied_midi_by_param = {}
end

function cc_runtime_pickup_crossed_target(old_norm, new_norm, target_norm)
    old_norm = tonumber(old_norm)
    new_norm = tonumber(new_norm)
    target_norm = tonumber(target_norm)

    if new_norm == nil or target_norm == nil then
        return false
    end

    local eps = 1 / 127

    if math.abs(new_norm - target_norm) <= eps then
        return true
    end

    if old_norm == nil then
        return false
    end

    if old_norm < target_norm and new_norm >= target_norm then
        return true
    end

    if old_norm > target_norm and new_norm <= target_norm then
        return true
    end

    return false
end

function cc_runtime_arm_pickup_for_param(i)
    i = tonumber(i)

    if i == nil then
        return false
    end

    if not param_index_is_valid or
       not param_index_is_valid(i) then

        return false
    end

    local key = cc_runtime_pickup_make_key(i)
    local current_norm = cc_control_get_param_norm_for_pickup(i)

    cc_runtime_pickup_by_param[key] = {
        active = true,
        target_norm = current_norm,
        last_norm = nil,
        last_param_norm = current_norm
    }

    return true
end

function cc_runtime_pickup_allows_value(i, norm)
    i = tonumber(i)

    if i == nil then
        return false
    end

    if not param_index_is_valid or
       not param_index_is_valid(i) then

        return false
    end

    norm = clamp01(norm)

    local key = cc_runtime_pickup_make_key(i)
    local state = cc_runtime_pickup_by_param[key]

    local current_param_norm = cc_control_get_param_norm_for_pickup(i)

    --------------------------------------------------------
    -- Primo movimento del CC:
    -- arma il pickup sul valore reale attuale del parametro.
    --------------------------------------------------------
    if state == nil then
        state = {
            active = true,
            target_norm = current_param_norm,
            last_norm = nil,
            last_param_norm = current_param_norm
        }

        cc_runtime_pickup_by_param[key] = state
    end

    --------------------------------------------------------
    -- Se il parametro è stato cambiato da tastiera, mouse,
    -- preset, reset, automation o altro, riarma il pickup.
    -- Così il controller fisico deve tornare al nuovo valore
    -- nominale prima di controllare di nuovo.
    --------------------------------------------------------
    if state.active ~= true and
       state.last_param_norm ~= nil and
       math.abs(current_param_norm - state.last_param_norm) > 0.0005 then

        state.active = true
        state.target_norm = current_param_norm
        state.last_norm = nil
        state.last_param_norm = current_param_norm
    end

    local old_norm = state.last_norm
    local target_norm = state.target_norm

    state.last_norm = norm

    if state.active then
        if not cc_runtime_pickup_crossed_target(
            old_norm,
            norm,
            target_norm
        ) then
            return false
        end

        state.active = false
    end

    return true
end

function cc_runtime_pickup_mark_param_applied(i, controller_norm)
    i = tonumber(i)

    if i == nil then
        return false
    end

    local key = cc_runtime_pickup_make_key(i)
    local state = cc_runtime_pickup_by_param[key]

    if state == nil then
        state = {}
        cc_runtime_pickup_by_param[key] = state
    end

    state.active = false
    state.last_norm = clamp01(controller_norm)
    state.last_param_norm = cc_control_get_param_norm_for_pickup(i)

    return true
end

------------------------------------------------------------
-- CC COMBO SPEECH
--
-- Alt+T:
--   attiva/disattiva il parlato dei valori combo/discreti
--   mossi tramite CC normale o Floating CC.
--
-- Logica:
-- - se la label formattata resta uguale, non parla;
-- - se la label cambia, parla;
-- - la cache è per FX + parametro, quindi due parametri
--   diversi con la stessa label non si bloccano tra loro.
------------------------------------------------------------
cc_combo_speak_enabled = false
cc_combo_speak_last_value_by_param = {}

------------------------------------------------------------
-- FLOATING CC MODE
--
-- Ctrl+Shift+C:
--   - mette temporaneamente da parte i CC salvati nel TXT;
--   - cattura il primo CC MIDI nuovo;
--   - quel CC controlla sempre il parametro corrente;
--   - non salva nulla nel TXT;
--   - premendo di nuovo Ctrl+Shift+C torna ai CC normali.
------------------------------------------------------------
cc_focus_active = false
cc_focus_waiting = false

cc_focus_channel = nil
cc_focus_cc = nil
cc_focus_value = nil
cc_focus_status_byte = nil

cc_focus_last_seq = 0

------------------------------------------------------------
-- FLOATING CC PICKUP / SOFT TAKEOVER
--
-- Il CC volante non muove subito il parametro.
-- Prima deve raggiungere o attraversare il valore reale
-- del parametro corrente.
--
-- Questo evita salti bruschi quando il valore fisico
-- del controller è lontano dal valore del parametro.
------------------------------------------------------------
cc_focus_pickup_active = false
cc_focus_pickup_target_norm = nil
cc_focus_pickup_last_norm = nil
cc_focus_pickup_param_index = nil

function cc_focus_clear_pickup()
    cc_focus_pickup_active = false
    cc_focus_pickup_target_norm = nil
    cc_focus_pickup_last_norm = nil
    cc_focus_pickup_param_index = nil
end

------------------------------------------------------------
-- FLOATING CC SESSION MEMORY
--
-- Memoria volatile di sessione:
-- - resta viva finché REAPER resta aperto;
-- - non viene scritta in reaper.ini;
-- - non viene scritta nel progetto RPP;
-- - non viene scritta nel TXT del plugin.
------------------------------------------------------------

CC_FOCUS_SESSION_ACTIVE_KEY  = "cc_focus_session_active_v1"
CC_FOCUS_SESSION_CHANNEL_KEY = "cc_focus_session_channel_v1"
CC_FOCUS_SESSION_CC_KEY      = "cc_focus_session_cc_v1"
CC_FOCUS_SESSION_STATUS_KEY  = "cc_focus_session_status_v1"

function cc_focus_clear_session_memory()
    reaper.SetExtState(
        EXT_SECTION,
        CC_FOCUS_SESSION_ACTIVE_KEY,
        "",
        false
    )

    reaper.SetExtState(
        EXT_SECTION,
        CC_FOCUS_SESSION_CHANNEL_KEY,
        "",
        false
    )

    reaper.SetExtState(
        EXT_SECTION,
        CC_FOCUS_SESSION_CC_KEY,
        "",
        false
    )

    reaper.SetExtState(
        EXT_SECTION,
        CC_FOCUS_SESSION_STATUS_KEY,
        "",
        false
    )
end

function cc_focus_save_session_memory()
    if not cc_focus_active or
       cc_focus_channel == nil or
       cc_focus_cc == nil then

        cc_focus_clear_session_memory()
        return false
    end

    reaper.SetExtState(
        EXT_SECTION,
        CC_FOCUS_SESSION_ACTIVE_KEY,
        "1",
        false
    )

    reaper.SetExtState(
        EXT_SECTION,
        CC_FOCUS_SESSION_CHANNEL_KEY,
        tostring(cc_focus_channel),
        false
    )

    reaper.SetExtState(
        EXT_SECTION,
        CC_FOCUS_SESSION_CC_KEY,
        tostring(cc_focus_cc),
        false
    )

    reaper.SetExtState(
        EXT_SECTION,
        CC_FOCUS_SESSION_STATUS_KEY,
        tostring(cc_focus_status_byte or 0),
        false
    )

    return true
end

function cc_focus_restore_session_memory()
    local active =
        reaper.GetExtState(
            EXT_SECTION,
            CC_FOCUS_SESSION_ACTIVE_KEY
        ) or ""

    if active ~= "1" then
        return false
    end

    local channel =
        tonumber(
            reaper.GetExtState(
                EXT_SECTION,
                CC_FOCUS_SESSION_CHANNEL_KEY
            ) or ""
        )

    local cc =
        tonumber(
            reaper.GetExtState(
                EXT_SECTION,
                CC_FOCUS_SESSION_CC_KEY
            ) or ""
        )

    local status =
        tonumber(
            reaper.GetExtState(
                EXT_SECTION,
                CC_FOCUS_SESSION_STATUS_KEY
            ) or ""
        )

    if channel == nil or cc == nil then
        cc_focus_clear_session_memory()
        return false
    end

    channel = clamp_int(channel, 1, 16)
    cc = clamp_int(cc, 0, 127)

    if status == nil or status <= 0 then
        status = 0xB0 + (channel - 1)
    end

    cc_focus_active = true
    cc_focus_waiting = false

    cc_focus_channel = channel
    cc_focus_cc = cc
    cc_focus_value = nil
    cc_focus_status_byte = status

    --------------------------------------------------------
    -- Evita che alla riapertura dello script venga preso
    -- subito un vecchio evento MIDI già presente nella history.
    --------------------------------------------------------
    cc_focus_last_seq = cc_focus_get_current_recent_seq()
    cc_runtime_last_seq = cc_focus_last_seq

    --------------------------------------------------------
    -- Al ripristino della sessione non conosciamo ancora
    -- il valore fisico reale del controller.
    -- Quindi il pickup verrà armato al primo movimento CC.
    --------------------------------------------------------
    cc_focus_pickup_active = true
    cc_focus_pickup_target_norm = nil
    cc_focus_pickup_last_norm = nil
    cc_focus_pickup_param_index = nil

    return true
end



------------------------------------------------------------
-- FX OFFLINE / ONLINE
--
-- Ctrl+Alt+B:
--   passa l'FX corrente da online a offline e viceversa.
--
-- Se l'FX è offline, la griglia parametri non mostra i tre
-- controlli generici REAPER come se fossero il plugin:
-- resta vuota e parla solo "Offline <nome FX>".
------------------------------------------------------------

function fx_offline_make_label(name)
    name = clean_one_line(name or get_fx_raw_label())

    if name == "" then
        name = "FX"
    end

    if name:lower():sub(1, 8) == "offline " then
        return name
    end

    return "Offline " .. name
end

function fx_get_offline_for_real_fx(real_fx)
    real_fx = tonumber(real_fx)

    if real_fx == nil then
        return nil
    end

    if ctx.kind == "take" then
        if not ctx.take or not reaper.TakeFX_GetOffline then
            return nil
        end

        local ok, value =
            pcall(reaper.TakeFX_GetOffline, ctx.take, real_fx)

        if ok then
            return value == true or tonumber(value) == 1
        end

        return nil
    end

    if not ctx.track or not reaper.TrackFX_GetOffline then
        return nil
    end

    local ok, value =
        pcall(reaper.TrackFX_GetOffline, ctx.track, real_fx)

    if ok then
        return value == true or tonumber(value) == 1
    end

    return nil
end

function fx_set_offline_for_real_fx(real_fx, offline)
    real_fx = tonumber(real_fx)

    if real_fx == nil then
        return false
    end

    offline = offline == true

    if ctx.kind == "take" then
        if not ctx.take or not reaper.TakeFX_SetOffline then
            return false
        end

        local ok =
            pcall(reaper.TakeFX_SetOffline, ctx.take, real_fx, offline)

        return ok == true
    end

    if not ctx.track or not reaper.TrackFX_SetOffline then
        return false
    end

    local ok =
        pcall(reaper.TrackFX_SetOffline, ctx.track, real_fx, offline)

    return ok == true
end

function current_fx_is_offline()
    local real_fx = get_current_real_fx_index()

    if real_fx == nil then
        return false
    end

    return fx_get_offline_for_real_fx(real_fx) == true
end

function clear_fx_offline_grid_state()
    fx_offline_grid_active = false
    fx_offline_grid_label = ""
end

function set_fx_offline_grid_state(name)
    fx_offline_grid_active = true
    fx_offline_grid_label = fx_offline_make_label(name)
end

function get_fx_offline_grid_label()
    if fx_offline_grid_label ~= "" then
        return fx_offline_grid_label
    end

    return fx_offline_make_label(get_fx_raw_label())
end

function enter_offline_fx_grid(speak_it)
    reset_param_browser_runtime_state()

    set_fx_offline_grid_state(get_fx_raw_label())

    param_count = 0
    param_index = 0
    active_pos = 1

    all_param_indices = {}
    active_param_indices = {}
    search_results = {}
    group_results = {}
    group_selected = {}

    search_active = false
    group_active = false
    custom_order_active = false

    mode = "list"
    value_return_mode = "list"
    numeric_return_mode = "list"

    refresh_window_title()
    save_current_area_state("grid")

    if speak_it then
        speak(get_fx_offline_grid_label())
    end

    return true
end

function toggle_current_fx_offline()
    clear_param_memory_arm()
    disarm_slot_deletes()
    cancel_pending_speech()

    local browser_entry = nil

    if mode == "fx_browser" then
        browser_entry = get_fx_browser_current_entry()

        if not browser_entry then
            speak("No FX")
            return false
        end
    end

    local list_index = nil

    if browser_entry then
        list_index = browser_entry.list_index
    else
        list_index = (tonumber(fx_index) or 0) + 1
    end

    local real_fx = fx_real_indices[list_index]

    if real_fx == nil then
        speak("No FX")
        return false
    end

    local was_offline = fx_get_offline_for_real_fx(real_fx)

    if was_offline == nil then
        speak("Offline not supported")
        return false
    end

    local want_offline = not was_offline

    if not fx_set_offline_for_real_fx(real_fx, want_offline) then
        speak("Offline not supported")
        return false
    end

    --------------------------------------------------------
    -- Ricostruisce la lista FX: alcuni nomi possono cambiare
    -- dopo il passaggio online/offline.
    --------------------------------------------------------
    local keep_index = (tonumber(list_index) or 1) - 1
    build_fx_list_for_current_context()
    set_selected_fx_by_index(keep_index)
    save_current_fx_position()

    if mode == "fx_browser" then
        build_fx_browser_lists()
        sync_fx_browser_to_current_fx()
        speak_fx_browser_current()
        return true
    end

    if want_offline then
        return enter_offline_fx_grid(true)
    end

    clear_fx_offline_grid_state()

    if not prepare_selected_fx_for_param_browser() then
        speak("Plugin has no parameters")
        return false
    end

    announce_fx_param_short()

    return true
end

------------------------------------------------------------
-- COMPARE VIRTUALE SESSIONE FX
--
-- Compare è un parametro virtuale dello script:
-- - una sola voce nella griglia;
-- - dopo l'arm alterna Original / Edited;
-- - vive nella sessione REAPER con ExtState persist=false;
-- - non scrive nel TXT del plugin;
-- - è separato per istanza FX, non per nome plugin.
------------------------------------------------------------
FX_COMPARE_PARAM_INDEX = -300000
FX_COMPARE_SESSION_PREFIX = "fx_compare_session_v1::"

function fx_compare_param_is_valid(i)
    return tonumber(i) == FX_COMPARE_PARAM_INDEX
end

function fx_compare_state_is_armed(state)
    return state ~= nil and trim(state.original or "") ~= ""
end

function fx_compare_make_session_key()
    local context_id = ""

    if type(get_context_storage_id) == "function" then
        context_id = get_context_storage_id()
    end

    context_id = clean_one_line(context_id or "")

    if context_id == "" then
        context_id = clean_one_line(tostring(ctx and ctx.kind or "context"))
    end

    local real_fx = get_current_real_fx_index()
    local fx_guid = ""

    if type(get_current_fx_guid) == "function" then
        fx_guid = clean_one_line(get_current_fx_guid() or "")
    end

    local fx_id = ""

    if fx_guid ~= "" then
        fx_id = "guid::" .. fx_guid
    else
        fx_id =
            "index::" ..
            tostring(real_fx or fx_index or 0) ..
            "::" ..
            clean_one_line(get_fx_raw_label())
    end

    return FX_COMPARE_SESSION_PREFIX .. context_id .. "::" .. fx_id
end

function fx_compare_snapshot_serialize_snapshot(snapshot)
    local lines = {}

    snapshot = snapshot or {}

    for pos = 1, #snapshot do
        local entry = snapshot[pos]
        local i = tonumber(entry and entry.index)
        local norm = tonumber(entry and entry.norm)

        if i ~= nil and
           norm ~= nil and
           not fx_compare_param_is_valid(i) and
           param_index_is_valid(i) then

            lines[#lines + 1] =
                tostring(math.floor(i + 0.5)) ..
                "\t" ..
                string.format("%.17g", clamp01(norm))
        end
    end

    return table.concat(lines, "\n")
end

function fx_compare_snapshot_parse_snapshot(txt)
    local snapshot = {}

    for line in tostring(txt or ""):gmatch("[^\r\n]+") do
        line = trim(line)

        if line ~= "" then
            local index_s, norm_s = line:match("^(%-?%d+)%s*\t%s*(.*)$")
            local i = tonumber(index_s)
            local norm = tonumber(norm_s)

            if i ~= nil and norm ~= nil then
                snapshot[#snapshot + 1] = {
                    index = math.floor(i + 0.5),
                    norm = clamp01(norm)
                }
            end
        end
    end

    return snapshot
end

function fx_compare_capture_snapshot()
    local snapshot = {}
    local base = {}

    if type(custom_order_make_plugin_order) == "function" then
        base = custom_order_make_plugin_order()
    elseif type(get_full_grid_indices) == "function" then
        base = get_full_grid_indices()
    end

    for pos = 1, #base do
        local i = tonumber(base[pos])

        if i ~= nil and
           not fx_compare_param_is_valid(i) and
           param_index_is_valid(i) then

            snapshot[#snapshot + 1] = {
                index = math.floor(i + 0.5),
                norm = get_param_value_norm(i)
            }
        end
    end

    return fx_compare_snapshot_serialize_snapshot(snapshot)
end

function fx_compare_apply_snapshot(txt)
    local snapshot = fx_compare_snapshot_parse_snapshot(txt)
    local count = 0

    for pos = 1, #snapshot do
        local entry = snapshot[pos]
        local i = tonumber(entry.index)
        local norm = tonumber(entry.norm)

        if i ~= nil and
           norm ~= nil and
           not fx_compare_param_is_valid(i) and
           param_index_is_valid(i) then

            set_param_value_norm(i, norm)
            count = count + 1
        end
    end

    return count
end

function fx_compare_encode_state(state)
    state = state or {}

    local parts = {}

    parts[#parts + 1] = "State=" .. clean_one_line(state.current or "not_armed")
    parts[#parts + 1] = "[Original]"

    if trim(state.original or "") ~= "" then
        parts[#parts + 1] = state.original
    end

    parts[#parts + 1] = "[Edited]"

    if trim(state.edited or "") ~= "" then
        parts[#parts + 1] = state.edited
    end

    return table.concat(parts, "\n")
end

function fx_compare_decode_state(txt)
    txt = tostring(txt or "")

    local state = {
        current = "not_armed",
        original = "",
        edited = ""
    }

    local section = ""
    local original_lines = {}
    local edited_lines = {}

    for line in txt:gmatch("[^\r\n]+") do
        line = tostring(line or "")

        local current = line:match("^State=(.*)$")

        if current ~= nil then
            current = clean_one_line(current)

            if current == "original" or current == "edited" then
                state.current = current
            else
                state.current = "not_armed"
            end

        elseif line == "[Original]" then
            section = "original"

        elseif line == "[Edited]" then
            section = "edited"

        elseif section == "original" then
            original_lines[#original_lines + 1] = line

        elseif section == "edited" then
            edited_lines[#edited_lines + 1] = line
        end
    end

    state.original = table.concat(original_lines, "\n")
    state.edited = table.concat(edited_lines, "\n")

    if not fx_compare_state_is_armed(state) then
        state.current = "not_armed"
        state.original = ""
        state.edited = ""
    elseif state.current ~= "original" and state.current ~= "edited" then
        state.current = "edited"
    end

    return state
end

function fx_compare_load_state()
    if not reaper.GetExtState then
        return {
            current = "not_armed",
            original = "",
            edited = ""
        }
    end

    local txt = reaper.GetExtState(
        EXT_SECTION,
        fx_compare_make_session_key()
    ) or ""

    return fx_compare_decode_state(txt)
end

function fx_compare_save_state(state)
    if not reaper.SetExtState then
        return false
    end

    reaper.SetExtState(
        EXT_SECTION,
        fx_compare_make_session_key(),
        fx_compare_encode_state(state),
        false
    )

    return true
end

function fx_compare_clear_state()
    if not reaper.SetExtState then
        return false
    end

    reaper.SetExtState(
        EXT_SECTION,
        fx_compare_make_session_key(),
        "",
        false
    )

    return true
end

function fx_compare_get_formatted()
    local state = fx_compare_load_state()

    if not fx_compare_state_is_armed(state) then
        return "Not armed"
    end

    if state.current == "original" then
        return "Original"
    end

    return "Edited"
end

function fx_compare_get_norm()
    local state = fx_compare_load_state()

    if state.current == "original" then
        return 0
    end

    return 1
end

function fx_compare_set_norm(v)
    local state = fx_compare_load_state()
    local target = clamp01(v) < 0.5 and "original" or "edited"

    --------------------------------------------------------
    -- Primo movimento: arma Compare. Original è lo stato
    -- attuale; Edited resta lo stato corrente in cui si lavora.
    --------------------------------------------------------
    if not fx_compare_state_is_armed(state) then
        state.original = fx_compare_capture_snapshot()
        state.edited = ""
        state.current = "edited"
        fx_compare_save_state(state)
        return true
    end

    if target == "original" then
        if state.current ~= "original" then
            ------------------------------------------------
            -- Prima di tornare all'Original, salva l'Edited
            -- corrente. Così B segue sempre il lavoro reale.
            ------------------------------------------------
            state.edited = fx_compare_capture_snapshot()
            fx_compare_apply_snapshot(state.original)
            state.current = "original"
            fx_compare_save_state(state)
        end

        return true
    end

    --------------------------------------------------------
    -- Target Edited.
    --------------------------------------------------------
    if state.current == "original" then
        if trim(state.edited or "") ~= "" then
            fx_compare_apply_snapshot(state.edited)
        end

        state.current = "edited"
        fx_compare_save_state(state)
        return true
    end

    state.current = "edited"
    fx_compare_save_state(state)

    return true
end

function fx_compare_nudge(direction)
    direction = tonumber(direction) or 0

    if direction == 0 then
        return false
    end

    local state = fx_compare_load_state()

    --------------------------------------------------------
    -- Compare si comporta come una combo a bordi reali:
    -- - Not armed: il primo movimento arma Compare;
    -- - Original è il bordo sinistro;
    -- - Edited è il bordo destro;
    -- - premere ancora verso il bordo non parla e non cicla.
    --------------------------------------------------------
    if not fx_compare_state_is_armed(state) then
        fx_compare_set_norm(1)
        save_current_param_position()
        announce_value_only()
        return true
    end

    if state.current == "original" then
        if direction < 0 then
            return false
        end

        fx_compare_set_norm(1)
        save_current_param_position()
        announce_value_only()
        return true
    end

    --------------------------------------------------------
    -- Stato Edited: il bordo destro è silenzioso.
    --------------------------------------------------------
    if direction > 0 then
        return false
    end

    fx_compare_set_norm(0)
    save_current_param_position()
    announce_value_only()

    return true
end

function fx_compare_insert_into_param_list(list)
    local out = {}

    list = list or {}

    --------------------------------------------------------
    -- Non cercare il nome "Bypass": molti plugin possono
    -- avere un proprio parametro chiamato Bypass.
    -- REAPER espone sempre gli ultimi tre controlli generici
    -- dell'FX in fondo alla lista: Bypass, Wet, Delta.
    -- Compare deve stare prima di questi ultimi tre, quindi
    -- la posizione è calcolata solo contando dalla fine.
    --------------------------------------------------------

    for pos = 1, #list do
        local i = list[pos]

        if not fx_compare_param_is_valid(i) then
            out[#out + 1] = i
        end
    end

    local insert_pos = #out + 1

    if #out >= 3 then
        insert_pos = #out - 2
    end

    table.insert(out, insert_pos, FX_COMPARE_PARAM_INDEX)

    return out
end

function clear_param_memory_arm()
    param_memory_armed_index = nil
    param_memory_armed_name = ""
end

------------------------------------------------------------
-- 1.20 - CONTESTO GRUPPO ATTIVO
------------------------------------------------------------
function clear_group_context()
    current_group_slot = nil
    group_edit_is_temporary = false
    group_edit_loaded_slot = nil
    group_edit_show_all_params = false
    group_edit_occurrence_selected = {}
    group_edit_occurrence_base_selected = {}
    group_edit_search_positions = {}
end

function set_loaded_group_context(slot)
    current_group_slot = clamp_int(slot, 1, 12)
    last_toggle_group_slot = current_group_slot
    group_edit_is_temporary = false
    group_edit_loaded_slot = nil
    group_edit_show_all_params = false
    group_edit_occurrence_selected = {}
    group_edit_occurrence_base_selected = {}
    group_edit_search_positions = {}
end

function set_f7_group_edit_context(loaded_slot)
    current_group_slot = nil
    group_edit_is_temporary = true

    if loaded_slot ~= nil then
        group_edit_loaded_slot = clamp_int(loaded_slot, 1, 12)
    else
        group_edit_loaded_slot = nil
    end
end

function group_edit_is_loaded_group()
    return mode == "group_edit" and group_edit_loaded_slot ~= nil
end

function group_edit_uses_group_occurrences()
    return
        group_edit_loaded_slot ~= nil and
        group_edit_show_all_params ~= true
end

------------------------------------------------------------
-- 1.20A - SNAPSHOT / RITORNO PANNELLI
--
-- In questa parte inizializziamo solo le variabili globali.
-- Le funzioni definitive per salvare e ripristinare il ritorno
-- da F7 / F8 / pannelli vengono definite più avanti, nella Parte 3.
--
-- Questo evita doppioni di funzioni come:
-- save_memory_manager_return_snapshot()
------------------------------------------------------------
panel_return_mode = "all"
panel_return_group_slot = nil
panel_return_param_index = nil

f7_return_mode = "all"
f7_return_group_slot = nil
f7_return_param_index = nil

group_edit_return_mode = "all"
group_edit_return_group_slot = nil
group_edit_return_param_index = nil

memory_manager_return_mode = "all"
memory_manager_return_group_slot = nil
memory_manager_return_param_index = nil

------------------------------------------------------------
-- 1.21 - COMPATIBILITÀ VECCHIO ARM DELETE
------------------------------------------------------------
last_group_slot_touched = nil
group_slot_delete_armed = false

last_param_slot_touched = nil
param_slot_delete_armed = false

function disarm_group_slot_delete()
    group_slot_delete_armed = false
end

function disarm_param_slot_delete()
    param_slot_delete_armed = false
end

function disarm_slot_deletes()
    group_slot_delete_armed = false
    param_slot_delete_armed = false
end

function arm_group_slot_delete(slot)
    last_group_slot_touched = slot
    group_slot_delete_armed = false
    param_slot_delete_armed = false
end

function arm_param_slot_delete(slot)
    last_param_slot_touched = slot
    param_slot_delete_armed = false
    group_slot_delete_armed = false
end

------------------------------------------------------------
-- 1.22 - SLOT ACCESS MODE
--
-- Selettori separati e persistenti per plugin:
--   Ctrl+G = Groups
--   Ctrl+M = Memory positions
--
-- La scelta NON cambia entrando/uscendo da F7.
-- Viene salvata nel TXT del plugin come SlotAccessMode e
-- ripristinata quando quel plugin viene caricato di nuovo.
------------------------------------------------------------
slot_access_mode = "param"

function announce_slot_access_mode()
    if slot_access_mode == "group" then
        speak("groups")
    else
        speak("Memory positions")
    end
end

function set_slot_access_mode(new_mode, speak_it)
    new_mode = clean_one_line(new_mode or "")

    if new_mode ~= "group" and new_mode ~= "param" then
        return false
    end

    slot_access_mode = new_mode

    --------------------------------------------------------
    -- Persistenza per plugin:
    -- salva subito il recinto scelto nel TXT corrente.
    -- Così Ctrl+G / Ctrl+M sopravvivono sia alla chiusura
    -- del Lua sia alla chiusura e riapertura di REAPER.
    --------------------------------------------------------
    if plugin_txt_loaded and type(plugin_txt_set_slot_access_mode) == "function" then
        plugin_txt_set_slot_access_mode(slot_access_mode)

        if type(plugin_txt_save_if_dirty) == "function" then
            plugin_txt_save_if_dirty(true)
        end
    end

    if speak_it then
        announce_slot_access_mode()
    end

    return true
end

function restore_slot_access_mode_from_plugin_txt()
    --------------------------------------------------------
    -- Ogni plugin ricorda il proprio recinto.
    -- TXT vecchi o senza SlotAccessMode partono da param.
    --------------------------------------------------------
    local saved_mode = "param"

    if plugin_txt_loaded and type(plugin_txt_get_slot_access_mode) == "function" then
        saved_mode = clean_one_line(plugin_txt_get_slot_access_mode() or "")
    end

    if saved_mode ~= "group" and saved_mode ~= "param" then
        saved_mode = "param"
    end

    slot_access_mode = saved_mode
    return true
end

function set_slot_access_mode_for_context(new_mode)
    --------------------------------------------------------
    -- Legacy bridge: non esiste più un cambio "per contesto".
    -- Se qualche vecchio punto lo richiama, mantiene comunque
    -- la scelta esplicita corrente.
    --------------------------------------------------------
    return slot_access_mode == "group" or slot_access_mode == "param"
end

function sync_slot_access_mode_for_current_context()
    return slot_access_mode == "group" or slot_access_mode == "param"
end

function select_group_slot_access_mode()
    disarm_slot_deletes()
    clear_param_memory_arm()

    return set_slot_access_mode("group", true)
end

function select_param_slot_access_mode()
    disarm_slot_deletes()
    clear_param_memory_arm()

    return set_slot_access_mode("param", true)
end

------------------------------------------------------------
-- 1.23 - NAVIGAZIONE CONTESTO: COMPATIBILITÀ
--
-- La navigazione principale attuale viene gestita più avanti:
-- - Ctrl + Page Up / Ctrl + Page Down = traccia precedente/successiva;
-- - Ctrl + Left / Ctrl + Right = item/take FX precedente/successivo.
--
-- Questo blocco resta come compatibilità per eventuali funzioni
-- vecchie ancora presenti nelle parti successive.
------------------------------------------------------------
CONTEXT_NAV_PREVIOUS = -1
CONTEXT_NAV_NEXT     = 1

CONTEXT_NAV_KIND_TRACK = "track"
CONTEXT_NAV_KIND_ITEM  = "item"

context_nav_last_kind = ""
context_nav_last_direction = 0

function is_ctrl_alt_no_shift()
    return ctrl_down() and alt_down() and not shift_down()
end

function is_context_track_nav_key(char)
    if not is_ctrl_alt_no_shift() then
        return false
    end

    return char == KEY_UP or char == KEY_DOWN
end

function is_context_item_nav_key(char)
    if not is_ctrl_alt_no_shift() then
        return false
    end

    return char == KEY_LEFT or char == KEY_RIGHT
end

function get_context_track_nav_direction(char)
    if char == KEY_UP then
        return CONTEXT_NAV_PREVIOUS
    end

    if char == KEY_DOWN then
        return CONTEXT_NAV_NEXT
    end

    return 0
end

function get_context_item_nav_direction(char)
    if char == KEY_LEFT then
        return CONTEXT_NAV_PREVIOUS
    end

    if char == KEY_RIGHT then
        return CONTEXT_NAV_NEXT
    end

    return 0
end

function remember_context_navigation(kind, direction)
    context_nav_last_kind = clean_one_line(kind or "")
    context_nav_last_direction = tonumber(direction) or 0
end

function clear_context_navigation_memory()
    context_nav_last_kind = ""
    context_nav_last_direction = 0
end

------------------------------------------------------------
-- FINE PARTE 1 / 8
------------------------------------------------------------

------------------------------------------------------------
-- PARTE 2 / 8
-- Parameter Navigator., STEP/GRID, CONTESTO REAPER E LISTA FX
--
-- Stato:
-- - nessun salvataggio nel progetto RPP;
-- - Step scale e Grid size vengono salvati nel TXT del plugin;
-- - ExtState resta solo per dati globali/non legati al progetto.
--
-- Parameter Navigator.:
-- - colonna sinistra  = Memory positions;
-- - colonna centrale  = Groups;
-- - colonna destra    = Custom order.
--
-- La Custom order è una sola memoria per plugin.
-- Si cancella da F8 con Delete.
------------------------------------------------------------

------------------------------------------------------------
-- 2.1 - Parameter Navigator. MODE: F8
------------------------------------------------------------
memory_manager_col = "group" -- "param", "group", "hidden", "cc", "custom", "copies", "default"

memory_param_slots = {}
memory_group_slots = {}
memory_hidden_slots = {}
memory_cc_slots = {}
memory_custom_slots = {}
memory_copied_slots = {}
memory_default_slots = {}

------------------------------------------------------------
-- F8 Default confirmation
--
-- Enter sulla colonna Default non deve più eseguire subito
-- un reset globale: prima apre una piccola conferma Yes/No.
-- F8 resta invece il ritorno rapido come prima.
------------------------------------------------------------
default_snapshot_confirm_active = false
default_snapshot_confirm_yes = false
default_snapshot_confirm_ignore_char = nil

function get_memory_manager_current_list()
    if memory_manager_col == "param" then
        return memory_param_slots
    end

    if memory_manager_col == "hidden" then
        return memory_hidden_slots
    end

    if memory_manager_col == "cc" then
        return memory_cc_slots
    end

    if memory_manager_col == "custom" then
        return memory_custom_slots
    end

    if memory_manager_col == "copies" then
        return memory_copied_slots
    end

    if memory_manager_col == "default" then
        return memory_default_slots
    end

    return memory_group_slots
end

function get_memory_manager_col_name()
    if memory_manager_col == "param" then
        return "Memory positions"
    end

    if memory_manager_col == "hidden" then
        return "Hidden parameters"
    end

    if memory_manager_col == "cc" then
        return "MIDI CC"
    end

    if memory_manager_col == "custom" then
        return "Custom order"
    end

    if memory_manager_col == "copies" then
        return "Copied parameters"
    end

    if memory_manager_col == "default" then
        return "Default"
    end

    return "Groups"
end

function memory_manager_col_to_index(col)
    if col == "param" then return 1 end
    if col == "group" then return 2 end
    if col == "hidden" then return 3 end
    if col == "cc" then return 4 end
    if col == "custom" then return 5 end
    if col == "copies" then return 6 end
    if col == "default" then return 7 end

    return 2
end

function memory_manager_index_to_col(index)
    index = tonumber(index) or 2

    if index <= 1 then return "param" end
    if index == 2 then return "group" end
    if index == 3 then return "hidden" end
    if index == 4 then return "cc" end
    if index == 5 then return "custom" end
    if index == 6 then return "copies" end

    return "default"
end

function memory_manager_col_has_items(col)
    if col == "param" then
        return #memory_param_slots > 0
    end

    if col == "group" then
        return #memory_group_slots > 0
    end

    if col == "hidden" then
        return #memory_hidden_slots > 0
    end

    if col == "cc" then
        return #memory_cc_slots > 0
    end

    if col == "custom" then
        return #memory_custom_slots > 0
    end

    if col == "copies" then
        return #memory_copied_slots > 0
    end

    if col == "default" then
        return #memory_default_slots > 0
    end

    return false
end

function memory_manager_has_anything()
    return
        #memory_param_slots > 0 or
        #memory_group_slots > 0 or
        #memory_hidden_slots > 0 or
        #memory_cc_slots > 0 or
        #memory_custom_slots > 0 or
        #memory_copied_slots > 0 or
        #memory_default_slots > 0
end

function clamp_memory_manager_pos()
    local list = get_memory_manager_current_list()
    local count = #list

    if count <= 0 then
        memory_manager_pos = 1
        return
    end

    memory_manager_pos = clamp_int(memory_manager_pos, 1, count)
end

------------------------------------------------------------
-- 2.2 - Parameter Navigator.: COSTRUZIONE LISTE
------------------------------------------------------------
function rebuild_memory_manager_lists()
    memory_param_slots = {}
    memory_group_slots = {}
    memory_hidden_slots = {}
    memory_cc_slots = {}
    memory_custom_slots = {}
    memory_copied_slots = {}
    memory_default_slots = {}

    --------------------------------------------------------
    -- Memory positions.
    --------------------------------------------------------
    if type(get_saved_param_slot_label) == "function" then
        for slot = 1, 12 do
            local label = get_saved_param_slot_label(slot)

            if label ~= nil then
                memory_param_slots[#memory_param_slots + 1] = {
                    kind = "param",
                    slot = slot,
                    label = label
                }
            end
        end
    end

    --------------------------------------------------------
    -- Groups.
    --------------------------------------------------------
    if type(get_saved_group_slot_label) == "function" then
        for slot = 1, 12 do
            local label = get_saved_group_slot_label(slot)

            if label ~= nil then
                memory_group_slots[#memory_group_slots + 1] = {
                    kind = "group",
                    slot = slot,
                    label = label
                }
            end
        end
    end

    --------------------------------------------------------
    -- Hidden parameters.
    --------------------------------------------------------
    if type(load_hidden_params_from_txt) == "function" then
        load_hidden_params_from_txt()

        local base = custom_order_make_plugin_order()

        for pos = 1, #base do
            local param_i = base[pos]

            if hidden_param_selected[param_i] then
                memory_hidden_slots[#memory_hidden_slots + 1] = {
                    kind = "hidden",
                    param_index = param_i,
                    label = get_param_label_for_index(param_i)
                }
            end
        end
    end

    --------------------------------------------------------
    -- MIDI CC links.
    -- Ordine: segue la griglia completa corrente.
    --------------------------------------------------------
    if plugin_storage_available() and
       plugin_txt_data and
       plugin_txt_data.extra and
       type(cc_link_get_param_key) == "function" and
       type(cc_link_parse_text) == "function" then

        local base = get_full_grid_indices()

        for pos = 1, #base do
            local param_i = tonumber(base[pos])

            if param_i ~= nil and
               type(cc_learn_param_is_supported) == "function" and
               cc_learn_param_is_supported(param_i) then

                local txt =
                    get_plugin_state_safe(
                        cc_link_get_param_key(param_i)
                    )

                local channel, cc = cc_link_parse_text(txt)

                if channel ~= nil and cc ~= nil then
                    memory_cc_slots[#memory_cc_slots + 1] = {
                        kind = "cc",
                        param_index = param_i,
                        channel = channel,
                        cc = cc,
                        label = get_param_label_for_index(param_i)
                    }
                end
            end
        end
    end

    --------------------------------------------------------
    -- Custom order.
    -- Una sola memoria per plugin.
    --------------------------------------------------------
    if type(get_custom_order_memory_label) == "function" then
        local label = get_custom_order_memory_label()

        if label ~= nil then
            memory_custom_slots[#memory_custom_slots + 1] = {
                kind = "custom",
                slot = 1,
                label = label
            }
        end

    elseif plugin_txt_loaded and
           type(plugin_txt_custom_order_has_content) == "function" and
           plugin_txt_custom_order_has_content() then

        memory_custom_slots[#memory_custom_slots + 1] = {
            kind = "custom",
            slot = 1,
            label = "Custom order"
        }
    end

    --------------------------------------------------------
    -- Copied parameters in Custom order.
    -- Mostra solo le occorrenze extra create con Ctrl+C.
    --------------------------------------------------------
    if type(custom_order_build_copied_slots) == "function" then
        memory_copied_slots = custom_order_build_copied_slots()
    end

    --------------------------------------------------------
    -- Default snapshot.
    -- Una sola voce per plugin.
    --------------------------------------------------------
    if type(plugin_default_snapshot_has_content) == "function" and
       plugin_default_snapshot_has_content() then

        local count = plugin_default_snapshot_count()

        if count > 0 then
            memory_default_slots[#memory_default_slots + 1] = {
                kind = "default",
                slot = 1,
                label = tostring(count) .. " parameters"
            }
        end
    end
end

------------------------------------------------------------
-- 2.3 - Parameter Navigator.: SPEECH / ENTRATA / USCITA
------------------------------------------------------------
function speak_memory_manager_current(prefix)
    local list = get_memory_manager_current_list()

    if #list <= 0 then
        local msg = get_memory_manager_col_name() .. ". Empty"

        if prefix and prefix ~= "" then
            msg = prefix .. ". " .. msg
        end

        speak(msg)
        return
    end

    clamp_memory_manager_pos()

    local entry = list[memory_manager_pos]
    local label = clean_one_line(entry.label or "")
    local msg = ""

    if memory_manager_col == "param" then
        label = label:gsub("^Memory position%s+%d+%.%s*", "")

        msg =
            "Memory positions. " ..
            clean_one_line(label)

    elseif memory_manager_col == "group" then
        ----------------------------------------------------
        -- F8 deve parlare lo slot reale del gruppo salvato,
        -- non la posizione progressiva nella lista visibile.
        -- Esempio:
        -- se sono salvati solo i gruppi 5, 8 e 12,
        -- la prima voce deve parlare "Groups. 5 ...",
        -- non "Groups. 1 ...".
        ----------------------------------------------------
        local real_slot = tonumber(entry.slot) or memory_manager_pos
        local count_s =
            label:match("^Group%s+%d+%.%s+(%d+)%s+parameters$")
        local custom_name, custom_count =
            label:match("^(.-)%.%s+(%d+)%s+parameters$")

        if count_s then
            msg =
                "Groups. " ..
                tostring(real_slot) ..
                " " ..
                tostring(count_s) ..
                " parameters"

        elseif custom_name and custom_count then
            custom_name = clean_one_line(custom_name)

            msg =
                "Groups. " ..
                tostring(real_slot) ..
                " " ..
                custom_name ..
                ". " ..
                tostring(custom_count) ..
                " parameters"

        else
            msg =
                "Groups. " ..
                tostring(real_slot) ..
                " " ..
                label
        end

    elseif memory_manager_col == "hidden" then
        msg =
            "Hidden parameters. " ..
            label

    elseif memory_manager_col == "cc" then
        msg =
            "MIDI CC. " ..
            label

    elseif memory_manager_col == "custom" then
        msg =
            "Custom order. " ..
            label

    elseif memory_manager_col == "copies" then
        msg =
            "Copied parameters. " ..
            label

    else
        msg =
            get_memory_manager_col_name() ..
            ". " ..
            label
    end

    if prefix and prefix ~= "" then
        msg = prefix .. ". " .. msg
    end

    speak(msg)
end

function restore_memory_manager_return_context()
    clear_param_memory_arm()
    disarm_slot_deletes()

    --------------------------------------------------------
    -- Nuovo ritorno completo: F8 può essere stato aperto da
    -- Plugin order, Custom order, Search results, Group o F7.
    --------------------------------------------------------
    if type(memory_manager_grid_return_snapshot) == "table" then
        local snapshot = memory_manager_grid_return_snapshot
        memory_manager_grid_return_snapshot = nil

        return restore_navigation_return_snapshot(snapshot, true)
    end

    --------------------------------------------------------
    -- Fallback legacy: se manca lo snapshot completo, conserva
    -- il vecchio comportamento Group / All parameters.
    --------------------------------------------------------
    --------------------------------------------------------
    -- Se F8 era stato aperto da un gruppo reale, prova a
    -- tornare a quel gruppo. Se il gruppo non esiste più,
    -- torna ad All parameters.
    --------------------------------------------------------
    if memory_manager_return_mode == "group" and
       memory_manager_return_group_slot ~= nil and
       type(load_group_slot) == "function" then

        local slot = memory_manager_return_group_slot
        local wanted_param = memory_manager_return_param_index

        if load_group_slot(slot) then
            if wanted_param ~= nil and
               type(set_param_index_absolute) == "function" then

                set_param_index_absolute(wanted_param, false)
                save_current_param_position()

                if type(announce_grid_context) == "function" then
                    announce_grid_context(nil)
                end
            end

            return true
        end
    end

    --------------------------------------------------------
    -- Fallback stabile: All parameters.
    --------------------------------------------------------
    local wanted_param = memory_manager_return_param_index

    if type(return_to_all_parameters) == "function" then
        return_to_all_parameters(nil)
    else
        mode = "list"
    end

    if wanted_param ~= nil and
       type(set_param_index_in_full_grid) == "function" then

        set_param_index_in_full_grid(wanted_param, false)

        if type(announce_grid_context) == "function" then
            announce_grid_context(nil)
        end
    end

    return true
end

function enter_memory_manager_mode()
    clear_param_memory_arm()
    disarm_slot_deletes()

    if mode == "memory_manager" then
        restore_memory_manager_return_context()
        return true
    end

    --------------------------------------------------------
    -- F8 è uno strumento gestionale: per la nuova filosofia
    -- si apre soltanto dopo essere entrati intenzionalmente in F7.
    -- In Plugin order F7 stesso non è disponibile.
    --------------------------------------------------------
    if mode ~= "group_edit" then
        if plugin_order_structure_is_read_only() then
            speak("F8 not available in Plugin order")
        else
            speak("F8 available in F7")
        end
        return false
    end

    save_memory_manager_return_snapshot()
    rebuild_memory_manager_lists()

    if not memory_manager_has_anything() then
        memory_manager_grid_return_snapshot = nil
        speak("Parameter Navigator. No memories")
        return false
    end

    --------------------------------------------------------
    -- Ordine di entrata:
    -- 1. Memory positions;
    -- 2. Groups;
    -- 3. MIDI CC;
    -- 4. Custom order.
    --------------------------------------------------------
    if #memory_param_slots > 0 then
        memory_manager_col = "param"

    elseif #memory_group_slots > 0 then
        memory_manager_col = "group"

    elseif #memory_hidden_slots > 0 then
        memory_manager_col = "hidden"

    elseif #memory_cc_slots > 0 then
        memory_manager_col = "cc"

    elseif #memory_custom_slots > 0 then
        memory_manager_col = "custom"

    else
        memory_manager_col = "default"
    end

    memory_manager_pos = 1
    mode = "memory_manager"

    speak_memory_manager_current("Parameter Navigator")

    return true
end
function memory_manager_switch_col(direction)
    direction = tonumber(direction) or 0

    if direction == 0 then
        return
    end

    local old_col = memory_manager_col
    local old_pos = memory_manager_pos
    local new_index = memory_manager_col_to_index(old_col) + direction

    -- Colonne visive F8:
    -- 1 Memory positions
    -- 2 Groups
    -- 3 Hidden parameters
    -- 4 MIDI CC
    -- 5 Custom order
    -- 6 Copied parameters
    -- 7 Default values
    --
    -- La colonna Default deve restare raggiungibile come ultima
    -- colonna anche quando esiste la colonna Copied parameters.
    while new_index >= 1 and new_index <= 7 do
        local new_col = memory_manager_index_to_col(new_index)

        if memory_manager_col_has_items(new_col) then
            memory_manager_col = new_col

            local list = get_memory_manager_current_list()

            if #list > 0 then
                memory_manager_pos = clamp_int(old_pos, 1, #list)
            else
                memory_manager_pos = 1
            end

            speak_memory_manager_current()
            return
        end

        new_index = new_index + direction
    end

    memory_manager_col = old_col
    memory_manager_pos = old_pos
end

function memory_manager_move_vertical(direction)
    direction = tonumber(direction) or 0

    if direction == 0 then
        return
    end

    local list = get_memory_manager_current_list()

    if #list <= 0 then
        speak_memory_manager_current()
        return
    end

    local new_pos = memory_manager_pos + direction
    new_pos = clamp_int(new_pos, 1, #list)

    if new_pos ~= memory_manager_pos then
        memory_manager_pos = new_pos
        speak_memory_manager_current()
    end
end

function memory_manager_move_by_step(direction)
    direction = tonumber(direction) or 0

    if direction == 0 then
        return
    end

    local list = get_memory_manager_current_list()

    if #list <= 0 then
        speak_memory_manager_current()
        return
    end

    local amount = 1

    if type(get_page_nav_amount) == "function" then
        amount = get_page_nav_amount()
    end

    amount = clamp_int(amount, 1, 1000000)

    local new_pos = memory_manager_pos + (amount * direction)
    new_pos = clamp_int(new_pos, 1, #list)

    if new_pos ~= memory_manager_pos then
        memory_manager_pos = new_pos
    end

    speak_memory_manager_current()
end

function memory_manager_column_home()
    local list = get_memory_manager_current_list()

    if #list <= 0 then
        speak_memory_manager_current()
        return
    end

    memory_manager_pos = 1
    speak_memory_manager_current()
end

function memory_manager_column_end()
    local list = get_memory_manager_current_list()

    if #list <= 0 then
        speak_memory_manager_current()
        return
    end

    memory_manager_pos = #list
    speak_memory_manager_current()
end

function memory_manager_first_available_col()
    for idx = 1, 7 do
        local col = memory_manager_index_to_col(idx)

        if memory_manager_col_has_items(col) then
            return col
        end
    end

    return memory_manager_col or "group"
end

function memory_manager_last_available_col()
    for idx = 7, 1, -1 do
        local col = memory_manager_index_to_col(idx)

        if memory_manager_col_has_items(col) then
            return col
        end
    end

    return memory_manager_col or "group"
end

function memory_manager_global_home()
    memory_manager_col = memory_manager_first_available_col()
    memory_manager_pos = 1
    clamp_memory_manager_pos()
    speak_memory_manager_current()
end

function memory_manager_global_end()
    memory_manager_col = memory_manager_last_available_col()

    local list = get_memory_manager_current_list()

    if #list > 0 then
        memory_manager_pos = #list
    else
        memory_manager_pos = 1
    end

    speak_memory_manager_current()
end

------------------------------------------------------------
-- 2.4 - Parameter Navigator.: CARICA / CANCELLA / TASTI
------------------------------------------------------------
function memory_manager_delete_current()
    local list = get_memory_manager_current_list()

    if #list <= 0 then
        speak_memory_manager_current()
        return
    end

    clamp_memory_manager_pos()

    local old_col = memory_manager_col
    local old_pos = memory_manager_pos

    local entry = list[memory_manager_pos]
    local deleted_label = clean_one_line(entry.label or "")

    if deleted_label == "" then
        deleted_label = get_memory_manager_col_name()
    end

    --------------------------------------------------------
    -- Groups.
    --------------------------------------------------------
    if memory_manager_col == "group" then
        if type(delete_group_slot) == "function" then
            delete_group_slot(entry.slot, true)
        end

    --------------------------------------------------------
    -- Memory positions.
    --------------------------------------------------------
    elseif memory_manager_col == "param" then
        if type(delete_param_memory_slot) == "function" then
            delete_param_memory_slot(entry.slot, true)
        end

    --------------------------------------------------------
    -- Hidden parameters.
    --
    -- Qui Delete non cancella il parametro dal plugin:
    -- lo rimuove solo dalla lista dei parametri nascosti,
    -- quindi il parametro torna visibile nella Custom order.
    --------------------------------------------------------
    elseif memory_manager_col == "hidden" then
        if type(unhide_custom_order_param) == "function" and
           entry.param_index ~= nil then

            unhide_custom_order_param(entry.param_index, true)

        elseif type(custom_order_unhide_param) == "function" and
               entry.param_index ~= nil then

            custom_order_unhide_param(entry.param_index, true)

        elseif type(set_custom_order_param_hidden) == "function" and
               entry.param_index ~= nil then

            set_custom_order_param_hidden(entry.param_index, false, true)
        end

    --------------------------------------------------------
    -- MIDI CC links.
    --------------------------------------------------------
    elseif memory_manager_col == "cc" then
        if type(cc_link_remove_for_param) == "function" and
           entry.param_index ~= nil then

            cc_link_remove_for_param(entry.param_index)

            ------------------------------------------------
            -- Prova anche a rimuovere il learn nativo REAPER.
            ------------------------------------------------
            if type(cc_learn_get_param_key) == "function" and
               type(fx_set_named_config_parm) == "function" then

                fx_set_named_config_parm(
                    cc_learn_get_param_key(entry.param_index, "midi1"),
                    ""
                )

                fx_set_named_config_parm(
                    cc_learn_get_param_key(entry.param_index, "midi2"),
                    ""
                )

                fx_set_named_config_parm(
                    cc_learn_get_param_key(entry.param_index, "osc"),
                    ""
                )
            end
        end

    --------------------------------------------------------
    -- Custom order.
    --------------------------------------------------------
    elseif memory_manager_col == "custom" then
        if type(delete_custom_order_memory) == "function" then
            delete_custom_order_memory(true)

        elseif type(plugin_txt_clear_custom_order) == "function" then
            plugin_txt_clear_custom_order()
            plugin_txt_save_if_dirty(true)

            custom_order_active = false
            custom_order_indices = {}
            custom_order_dirty = false
            custom_param_aliases = {}
        end

    --------------------------------------------------------
    -- Copied parameters.
    --------------------------------------------------------
    elseif memory_manager_col == "copies" then
        if type(custom_order_delete_copied_occurrence) == "function" and
           entry.order_pos ~= nil then

            custom_order_delete_copied_occurrence(entry.order_pos, false)
        end

    --------------------------------------------------------
    -- Default snapshot.
    --------------------------------------------------------
    elseif memory_manager_col == "default" then
        ----------------------------------------------------
        -- Default snapshot:
        -- Delete usa la stessa conferma sicura di Enter.
        -- Non entra più nella vecchia modalità pending, perché
        -- qui l'utente vuole cancellare le memorie del navigatore,
        -- ripristinare il default e uscire in Plugin order.
        ----------------------------------------------------
        if type(default_snapshot_confirm_start) == "function" then
            default_snapshot_confirm_start(KEY_DELETE)
        else
            speak_memory_manager_current()
        end

        return
    end

    --------------------------------------------------------
    -- FIX PRINCIPALE:
    -- dopo qualunque cancellazione reale, F8 deve ricostruire
    -- subito tutte le colonne, altrimenti continua a leggere
    -- la vecchia lista rimasta in memoria.
    --------------------------------------------------------
    rebuild_memory_manager_lists()

    --------------------------------------------------------
    -- Prova a restare nella stessa colonna.
    -- Se quella colonna ora è vuota, passa alla prima colonna
    -- disponibile nell'ordine visivo di F8.
    --------------------------------------------------------
    if memory_manager_col_has_items(old_col) then
        memory_manager_col = old_col
    elseif #memory_param_slots > 0 then
        memory_manager_col = "param"
    elseif #memory_group_slots > 0 then
        memory_manager_col = "group"
    elseif #memory_hidden_slots > 0 then
        memory_manager_col = "hidden"
    elseif #memory_cc_slots > 0 then
        memory_manager_col = "cc"
    elseif #memory_custom_slots > 0 then
        memory_manager_col = "custom"
    elseif #memory_copied_slots > 0 then
        memory_manager_col = "copies"
    elseif #memory_default_slots > 0 then
        memory_manager_col = "default"
    else
        memory_manager_col = "group"
        memory_manager_pos = 1

        speak(
            "Deleted " ..
            deleted_label ..
            ". Parameter Navigator. No memories"
        )

        return
    end

    --------------------------------------------------------
    -- Mantiene una posizione sensata nella nuova lista.
    -- Esempio:
    -- se cancelli la voce 3 di 5, resta sulla nuova voce 3;
    -- se cancelli l'ultima, va sulla nuova ultima.
    --------------------------------------------------------
    local new_list = get_memory_manager_current_list()

    if #new_list > 0 then
        memory_manager_pos = clamp_int(old_pos, 1, #new_list)
    else
        memory_manager_pos = 1
    end

    speak(
        "Deleted " ..
        deleted_label ..
        ". " ..
        get_memory_manager_col_name()
    )
end

function memory_manager_load_current()
    local list = get_memory_manager_current_list()

    if #list <= 0 then
        speak_memory_manager_current()
        return
    end

    clamp_memory_manager_pos()

    local entry = list[memory_manager_pos]

    if memory_manager_col == "group" then
        ----------------------------------------------------
        -- Groups:
        -- carica il gruppo scelto.
        ----------------------------------------------------
        if type(load_group_slot) == "function" then
            load_group_slot(entry.slot)
        end

        return

    elseif memory_manager_col == "param" then
        ----------------------------------------------------
        -- Memory positions:
        -- carica la posizione parametro scelta.
        ----------------------------------------------------
        if type(load_param_memory_slot) == "function" then
            load_param_memory_slot(entry.slot)
        end

        return

    elseif memory_manager_col == "hidden" then
        ----------------------------------------------------
        -- Hidden parameters:
        -- Enter ripristina il parametro nascosto e torna subito
        -- alla griglia sul parametro appena reso visibile.
        -- Delete resta invece utile per ripristinare più voci
        -- restando dentro F8.
        ----------------------------------------------------
        if entry.param_index == nil then
            speak("No parameter")
            return
        end

        local target_param = entry.param_index
        local restored = false

        if type(unhide_custom_order_param) == "function" then
            restored = unhide_custom_order_param(target_param, false)

        elseif type(custom_order_unhide_param) == "function" then
            restored = custom_order_unhide_param(target_param, false)

        elseif type(set_custom_order_param_hidden) == "function" then
            set_custom_order_param_hidden(target_param, false, true)
            restored = true
        end

        if not restored then
            speak("No hidden parameter")
            rebuild_memory_manager_lists()
            clamp_memory_manager_pos()
            return
        end

        ----------------------------------------------------
        -- I parametri nascosti appartengono alla Custom order.
        -- Quindi, dopo il ripristino, torniamo nella Custom order
        -- e posizioniamo il cursore sul parametro riattivato.
        ----------------------------------------------------
        clear_filtered_param_context()

        if type(set_custom_order_active) == "function" then
            set_custom_order_active(true, false)
        else
            custom_order_active = true

            if type(ensure_custom_order_runtime) == "function" then
                ensure_custom_order_runtime()
            end

            if type(build_all_param_indices) == "function" then
                build_all_param_indices()
            end
        end

        mode = "list"
        value_return_mode = "list"
        numeric_return_mode = "list"

        local ok = false

        if type(set_param_index_absolute) == "function" then
            ok = set_param_index_absolute(target_param, false)
        end

        if not ok and type(set_param_index_in_full_grid) == "function" then
            ok = set_param_index_in_full_grid(target_param, false)
        end

        if ok then
            save_current_entry_state()
            save_current_area_state("grid")

            if type(announce_current_param) == "function" then
                announce_current_param()
            else
                speak(get_param_label_for_index(target_param))
            end
        else
            speak("Restored. " .. get_param_label_for_index(target_param))
        end

        return

    elseif memory_manager_col == "cc" then
        ----------------------------------------------------
        -- MIDI CC:
        -- va al parametro associato e torna alla griglia.
        ----------------------------------------------------
        if entry.param_index ~= nil then
            set_param_index_in_full_grid(entry.param_index, false)

            mode = "list"
            value_return_mode = "list"
            numeric_return_mode = "list"

            speak(get_param_label())
        else
            speak("No parameter")
        end

        return

    elseif memory_manager_col == "copies" then
        ----------------------------------------------------
        -- Copied parameters:
        -- Enter va alla copia scelta dentro la Custom order.
        ----------------------------------------------------
        if entry.param_index ~= nil then
            if type(custom_order_go_to_copied_occurrence) == "function" then
                custom_order_go_to_copied_occurrence(entry.order_pos)
            else
                set_param_index_in_full_grid(entry.param_index, false)
                mode = "list"
                value_return_mode = "list"
                numeric_return_mode = "list"
                speak(get_param_label())
            end
        else
            speak("No copied parameter")
        end

        return

    elseif memory_manager_col == "default" then
        ----------------------------------------------------
        -- Default snapshot:
        -- Enter APPLICA il Default, come Ctrl+Shift+Backspace.
        --
        -- Se il default era stato cancellato con Delete dentro F8,
        -- Enter salva prima il nuovo snapshot e poi torna alla
        -- griglia/lista da cui F8 era stato aperto.
        ----------------------------------------------------
        if default_snapshot_pending_regenerate and
           type(plugin_default_snapshot_regenerate_and_return_from_f8) == "function" then

            plugin_default_snapshot_regenerate_and_return_from_f8()
            return
        end

        ----------------------------------------------------
        -- Default già presente:
        -- usa ESATTAMENTE il motore del reset globale richiamato da
        -- Ctrl+Shift+Backspace, quindi comprende anche gli eventuali
        -- reset strutturali speciali (per esempio ReaEQ).
        --
        -- Dopo il reset torna al contesto da cui F8 era stato aperto.
        -- Il restore viene eseguito senza parlato intermedio, così
        -- l'utente riceve un unico messaggio chiaro di conferma.
        ----------------------------------------------------
        if type(reset_all_params_to_plugin_default_snapshot) == "function" then
            local ok = false

            if type(run_without_speech) == "function" then
                run_without_speech(function()
                    ok = reset_all_params_to_plugin_default_snapshot() == true
                end)
            else
                ok = reset_all_params_to_plugin_default_snapshot() == true
            end

            if ok then
                if type(run_without_speech) == "function" then
                    run_without_speech(function()
                        restore_memory_manager_return_context()
                    end)
                else
                    restore_memory_manager_return_context()
                end

                cancel_pending_speech()

                local label = ""
                if param_index_is_valid(param_index) then
                    label = clean_one_line(get_param_label() or "")
                end

                if label ~= "" then
                    speak("Default restored. " .. label)
                else
                    speak("Default restored")
                end
            end

            return
        end

        speak("No default snapshot")
        return

    elseif memory_manager_col == "custom" then
        ----------------------------------------------------
        -- Custom order:
        -- carica la Custom order, poi esce davvero da F8
        -- e torna alla griglia/lista da cui F8 era stato aperto.
        ----------------------------------------------------
        local loaded = false

        if type(load_custom_order_from_memory) == "function" then
            loaded = load_custom_order_from_memory(false)

        elseif type(plugin_txt_custom_order_has_content) == "function" and
               plugin_txt_custom_order_has_content() then

            custom_order_active = true
            loaded = true
        end

        if not loaded then
            speak("No custom order")
            return
        end

        restore_memory_manager_return_context()

        return
    end
end

function memory_manager_load_current_for_f7()
    local list = get_memory_manager_current_list()

    if #list <= 0 then
        speak_memory_manager_current()
        return false
    end

    clamp_memory_manager_pos()

    local entry = list[memory_manager_pos]

    --------------------------------------------------------
    -- Groups:
    -- carica il gruppo, poi F7 entrerà in edit.
    --------------------------------------------------------
    if memory_manager_col == "group" then
        if type(load_group_slot) == "function" then
            return load_group_slot(entry.slot)
        end

        return false
    end

    --------------------------------------------------------
    -- Memory positions:
    -- va al parametro salvato, poi F7 entra in edit.
    --------------------------------------------------------
    if memory_manager_col == "param" then
        if type(load_param_memory_slot) == "function" then
            return load_param_memory_slot(entry.slot)
        end

        return false
    end

    --------------------------------------------------------
    -- MIDI CC:
    -- va al parametro associato.
    --------------------------------------------------------
    if memory_manager_col == "cc" then
        if entry.param_index ~= nil then
            set_param_index_in_full_grid(entry.param_index, false)

            mode = "list"
            value_return_mode = "list"
            numeric_return_mode = "list"

            return true
        end

        speak("No parameter")
        return false
    end

    --------------------------------------------------------
    -- Custom order:
    -- carica la Custom order SENZA parlare Custom order.
    -- Poi F7 entrerà subito in edit group / Navigation Manager.
    --------------------------------------------------------
    if memory_manager_col == "custom" then
        local loaded = false

        if type(load_custom_order_from_memory) == "function" then
            loaded = load_custom_order_from_memory(false)

        elseif type(plugin_txt_custom_order_has_content) == "function" and
               plugin_txt_custom_order_has_content() then

            custom_order_active = true
            loaded = true
        end

        if not loaded then
            speak("No custom order")
            return false
        end

        mode = "list"
        value_return_mode = "list"
        numeric_return_mode = "list"

        search_active = false
        group_active = false
        search_results = {}
        group_results = {}

        clear_group_context()

        if not set_param_index_absolute(param_index, false) then
            active_pos = 1
            sync_param_from_active_pos()
        end

        save_current_param_position()
        save_current_entry_state()
        save_current_area_state("grid")

        return true
    end

    return false
end

function default_snapshot_confirm_message()
    if default_snapshot_confirm_yes then
        return "Clear memories and restore default? Yes"
    end

    return "Clear memories and restore default? No"
end

function default_snapshot_confirm_start(trigger_char)
    default_snapshot_confirm_active = true
    default_snapshot_confirm_yes = false
    default_snapshot_confirm_ignore_char = trigger_char or KEY_ENTER
    speak(default_snapshot_confirm_message())
    return true
end

function default_snapshot_confirm_cancel()
    default_snapshot_confirm_active = false
    default_snapshot_confirm_yes = false
    default_snapshot_confirm_ignore_char = nil
    speak_memory_manager_current("No")
    return true
end

function default_snapshot_confirm_set_yes(yes)
    local new_yes = yes == true

    if default_snapshot_confirm_yes == new_yes then
        return true
    end

    default_snapshot_confirm_yes = new_yes
    speak(default_snapshot_confirm_message())
    return true
end

function default_snapshot_clear_navigation_memories_after_default()
    ------------------------------------------------------------
    -- Default in F8 deve riportare il profilo del navigatore
    -- a Plugin order pulito, ma deve preservare lo snapshot
    -- DefaultValues appena usato per ripristinare i parametri.
    ------------------------------------------------------------

    if not plugin_txt_loaded or not plugin_txt_data then
        return false
    end

    plugin_txt_data.param_slots = {}
    plugin_txt_data.group_slots = {}
    plugin_txt_data.quick_group = ""
    plugin_txt_data.custom_order = ""
    plugin_txt_data.custom_order_view = "plugin"
    --------------------------------------------------------
    -- Il Default non deve cambiare il recinto Ctrl+G/Ctrl+M:
    -- conserva nel TXT la scelta corrente del plugin.
    --------------------------------------------------------
    if slot_access_mode == "group" then
        plugin_txt_data.slot_access_mode = "group"
    else
        plugin_txt_data.slot_access_mode = "param"
    end

    if type(plugin_txt_data.extra) ~= "table" then
        plugin_txt_data.extra = {}
    end

    local cc_prefix = tostring(CC_LINK_PREFIX or "cc_link_v1::param::")

    for key, _ in pairs(plugin_txt_data.extra) do
        key = tostring(key or "")

        if key == "hidden_params_v1" or
           key == "temporary_group_v1" or
           key == "cc_runtime_fixed_map_enabled_v1" or
           key:match("^group_slot_name_v1::slot::%d+$") or
           key:sub(1, #cc_prefix) == cc_prefix then

            plugin_txt_data.extra[key] = ""
        end
    end

    custom_order_active = false
    custom_order_indices = {}
    custom_order_dirty = false
    custom_param_aliases = {}
    hidden_param_selected = {}

    if type(cc_runtime_set_fixed_map_enabled) == "function" then
        cc_runtime_set_fixed_map_enabled(false, false, false)
    else
        cc_runtime_fixed_map_enabled = false
    end

    if type(cc_runtime_clear_link_cache) == "function" then
        cc_runtime_clear_link_cache()
    elseif type(cc_runtime_mark_link_cache_dirty) == "function" then
        cc_runtime_mark_link_cache_dirty()
    end

    if type(cc_runtime_clear_all_pickup) == "function" then
        cc_runtime_clear_all_pickup()
    end

    if type(clear_group_context) == "function" then
        clear_group_context()
    end

    if type(clear_param_memory_arm) == "function" then
        clear_param_memory_arm()
    end

    if type(disarm_slot_deletes) == "function" then
        disarm_slot_deletes()
    end

    plugin_txt_mark_dirty()
    plugin_txt_save_if_dirty(true)

    return true
end

function default_snapshot_return_to_plugin_order_after_yes()
    ------------------------------------------------------------
    -- Non deve tornare alla vecchia Custom order: dopo Default
    -- si esce da F8 direttamente in Plugin order.
    ------------------------------------------------------------

    custom_order_active = false
    custom_order_dirty = false

    if type(build_all_param_indices) == "function" then
        build_all_param_indices()
    end

    if type(rebuild_group_results_from_selected) == "function" then
        rebuild_group_results_from_selected()
    end

    if not set_param_index_absolute(param_index, false) then
        active_pos = clamp_int(active_pos, 1, math.max(1, #active_param_indices))
        if type(sync_param_from_active_pos) == "function" then
            sync_param_from_active_pos()
        end
    end

    mode = "list"
    value_return_mode = "list"
    numeric_return_mode = "list"
    search_active = false
    group_active = false
    search_results = {}
    group_results = {}

    save_current_param_position()
    save_current_entry_state()
    save_current_area_state("grid")

    if type(refresh_window_title) == "function" then
        refresh_window_title()
    end
end

function default_snapshot_confirm_commit_yes()
    default_snapshot_confirm_active = false
    default_snapshot_confirm_yes = false
    default_snapshot_confirm_ignore_char = nil

    local ok = false

    if type(reset_all_params_to_plugin_default_snapshot) == "function" then
        ok = reset_all_params_to_plugin_default_snapshot() == true
    end

    if ok then
        default_snapshot_clear_navigation_memories_after_default()

        run_without_speech(function()
            default_snapshot_return_to_plugin_order_after_yes()
        end)

        cancel_pending_speech()
        speak("Default restored. Plugin order")
        return true
    end

    --------------------------------------------------------
    -- Se non esiste uno snapshot default, resta in F8 e non
    -- distruggere memorie o Custom order.
    --------------------------------------------------------
    rebuild_memory_manager_lists()
    memory_manager_col = "default"
    memory_manager_pos = 1
    clamp_memory_manager_pos()

    return false
end

function handle_default_snapshot_confirm_key(char)
    local is_ctrl = ctrl_down()
    local is_shift = shift_down()
    local is_alt = alt_down()

    --------------------------------------------------------
    -- Evita il loop OSARA: quando Enter/Delete apre la domanda,
    -- lo stesso tasto può restare ripetuto per alcuni cicli.
    -- Lo ignoriamo fino al rilascio. Anche char == 0 non deve
    -- ripetere la domanda a ogni defer.
    --------------------------------------------------------
    if default_snapshot_confirm_ignore_char ~= nil then
        if char == default_snapshot_confirm_ignore_char then
            return true
        end

        if char == 0 then
            default_snapshot_confirm_ignore_char = nil
            return true
        end

        default_snapshot_confirm_ignore_char = nil
    end

    if char == 0 then
        return true
    end

    --------------------------------------------------------
    -- F8 uguale a prima: esce da F8 senza eseguire il reset.
    --------------------------------------------------------
    if char == KEY_F8 then
        default_snapshot_confirm_active = false
        default_snapshot_confirm_yes = false
        default_snapshot_confirm_ignore_char = nil
        restore_memory_manager_return_context()
        return true
    end

    --------------------------------------------------------
    -- Esc nella domanda non esce dallo script: annulla e resta
    -- dentro F8 sulla colonna Default.
    --------------------------------------------------------
    if char == KEY_ESC then
        return default_snapshot_confirm_cancel()
    end

    if not is_ctrl and not is_shift and not is_alt then
        if char == KEY_LEFT or char == KEY_UP then
            return default_snapshot_confirm_set_yes(false)
        end

        if char == KEY_RIGHT or char == KEY_DOWN then
            return default_snapshot_confirm_set_yes(true)
        end

        ----------------------------------------------------
        -- Y/N selezionano e confermano subito.
        ----------------------------------------------------
        if char == 89 or char == 121 then
            default_snapshot_confirm_yes = true
            return default_snapshot_confirm_commit_yes()
        end

        if char == 78 or char == 110 then
            return default_snapshot_confirm_cancel()
        end

        ----------------------------------------------------
        -- Enter conferma la scelta corrente. No è il default.
        ----------------------------------------------------
        if char == KEY_ENTER then
            if default_snapshot_confirm_yes then
                return default_snapshot_confirm_commit_yes()
            end

            return default_snapshot_confirm_cancel()
        end
    end

    return true
end

function handle_memory_manager_key(char)
    local is_ctrl = ctrl_down()
    local is_shift = shift_down()
    local is_alt = alt_down()

    if default_snapshot_confirm_active then
        return handle_default_snapshot_confirm_key(char)
    end

    --------------------------------------------------------
    -- Default snapshot cancellato da F8:
    --
    -- Enter:
    --   salva il nuovo default e torna alla griglia.
    --
    -- F8:
    --   salva il nuovo default e torna alla griglia.
    --
    -- Esc:
    --   salva il nuovo default e torna al contesto precedente.
    --------------------------------------------------------
    if default_snapshot_pending_regenerate then
        if char == KEY_ENTER or char == KEY_F8 then
            if type(plugin_default_snapshot_regenerate_and_return_from_f8) == "function" then
                plugin_default_snapshot_regenerate_and_return_from_f8()
            else
                plugin_default_snapshot_regenerate_pending_core()
                restore_memory_manager_return_context()
            end

            return true
        end

        if char == KEY_ESC then
            if type(plugin_default_snapshot_regenerate_and_return_from_f8) == "function" then
                plugin_default_snapshot_regenerate_and_return_from_f8()
            else
                plugin_default_snapshot_regenerate_pending_core()
                restore_memory_manager_return_context()
            end

            return true
        end
    end

    if char == KEY_ESC then
        restore_memory_manager_return_context()
        return true
    end

    if char == KEY_F8 then
        restore_memory_manager_return_context()
        return true
    end

    --------------------------------------------------------
    -- F7 dentro F8:
    -- carica la memoria evidenziata e apre l'editor/selettore.
    --------------------------------------------------------
    if char == KEY_F7 then
        local ok = memory_manager_load_current_for_f7()

        if ok then
            enter_group_edit_mode()
        end

        return true
    end

    --------------------------------------------------------
    -- Alt+Freccia sinistra/destra dentro F8:
    -- solo Step scale. La Grid non serve nella finestra
    -- gestionale, ma Page Up / Page Down usano comunque Step.
    --------------------------------------------------------
    if not is_ctrl and not is_shift and is_alt then
        if char == KEY_LEFT then
            last_function_touched = "step"
            change_step_scale(-1)
            return true

        elseif char == KEY_RIGHT then
            last_function_touched = "step"
            change_step_scale(1)
            return true
        end
    end

    --------------------------------------------------------
    -- In F8 solo TAB legge la colonna corrente.
    --------------------------------------------------------
    if char == KEY_TAB then
        speak_memory_manager_current()
        return true
    end

    --------------------------------------------------------
    -- Navigazione F8:
    -- Home/End sono coerenti con il resto dello script.
    -- Sulla tastiera dell'utente i codici sono invertiti:
    -- Home va alla fine della colonna, End all'inizio.
    -- Ctrl+Home va all'ultimo elemento dell'ultima colonna,
    -- Ctrl+End va al primo elemento della prima colonna.
    --------------------------------------------------------
    if is_ctrl and not is_shift and not is_alt and char == KEY_HOME then
        memory_manager_global_end()
        return true
    end

    if is_ctrl and not is_shift and not is_alt and char == KEY_END then
        memory_manager_global_home()
        return true
    end

    if not is_ctrl and not is_shift and not is_alt and char == KEY_HOME then
        memory_manager_column_end()
        return true
    end

    if not is_ctrl and not is_shift and not is_alt and char == KEY_END then
        memory_manager_column_home()
        return true
    end

    if not is_ctrl and not is_shift and not is_alt and char == KEY_PAGE_UP then
        memory_manager_move_by_step(-1)
        return true
    end

    if not is_ctrl and not is_shift and not is_alt and char == KEY_PAGE_DOWN then
        memory_manager_move_by_step(1)
        return true
    end

    if not is_ctrl and not is_shift and not is_alt and char == KEY_LEFT then
        memory_manager_switch_col(-1)
        return true
    end

    if not is_ctrl and not is_shift and not is_alt and char == KEY_RIGHT then
        memory_manager_switch_col(1)
        return true
    end

    if not is_ctrl and not is_shift and not is_alt and char == KEY_UP then
        memory_manager_move_vertical(-1)
        return true
    end

    if not is_ctrl and not is_shift and not is_alt and char == KEY_DOWN then
        memory_manager_move_vertical(1)
        return true
    end

    if char == KEY_ENTER then
        memory_manager_load_current()
        return true
    end

    if char == KEY_DELETE then
        memory_manager_delete_current()
        return true
    end

    return true
end

------------------------------------------------------------
-- 2.5 - GRID SIZE
------------------------------------------------------------
GRID_DEFAULT = 10
GRID_MIN = 1
GRID_MAX = 200

grid_size = GRID_DEFAULT

------------------------------------------------------------
-- Grid runtime flags.
--
-- Servono per ReaEQ:
-- - ReaEQ vergine può partire con Grid 5;
-- - Grid 5 non viene salvata nel TXT finché l'utente non
--   cambia davvero la griglia con F3/F4 o reset.
------------------------------------------------------------
grid_size_user_changed = false
grid_size_auto_default = false

function get_plugin_grid_size_key()
    return "grid_size_v1"
end

function get_plugin_custom_order_grid_size_key()
    return "custom_order_grid_size_v1"
end

function get_plugin_group_grid_size_key(slot)
    slot = clamp_int(slot, 1, 12)

    return "group_grid_size_v1::slot::" .. tostring(slot)
end

function get_active_grid_size_key()
    --------------------------------------------------------
    -- Priorità:
    -- 1. Gruppo reale caricato da slot.
    -- 2. Custom order.
    -- 3. Griglia generale del plugin.
    --------------------------------------------------------
    if group_active and current_group_slot ~= nil then
        return get_plugin_group_grid_size_key(current_group_slot)
    end

    if custom_order_active then
        return get_plugin_custom_order_grid_size_key()
    end

    return get_plugin_grid_size_key()
end

function save_grid_size_to_key(key)
    if not plugin_storage_available() then
        return false
    end

    key = clean_one_line(key or "")

    if key == "" then
        return false
    end

    grid_size = clamp_int(grid_size, GRID_MIN, GRID_MAX)

    set_plugin_state_safe(
        key,
        tostring(grid_size)
    )

    plugin_txt_save_if_dirty(true)

    return true
end

function restore_grid_size_from_key(key)
    if not plugin_storage_available() then
        return false
    end

    key = clean_one_line(key or "")

    if key == "" then
        return false
    end

    local saved = get_plugin_state_safe(key)
    local n = tonumber(saved)

    if n == nil then
        return false
    end

    grid_size = clamp_int(n, GRID_MIN, GRID_MAX)

    return true
end

function save_active_grid_size_to_txt()
    local key = get_active_grid_size_key()

    return save_grid_size_to_key(key)
end

function restore_active_grid_size_from_txt()
    local key = get_active_grid_size_key()

    --------------------------------------------------------
    -- Prima prova la griglia specifica:
    -- Custom Order oppure Group slot.
    --------------------------------------------------------
    if restore_grid_size_from_key(key) then
        return true
    end

    --------------------------------------------------------
    -- Se non esiste, fallback alla vecchia griglia generale.
    -- Questo protegge tutti i TXT già esistenti.
    --------------------------------------------------------
    if key ~= get_plugin_grid_size_key() then
        return restore_grid_size_from_key(get_plugin_grid_size_key())
    end

    return false
end

function announce_grid_size()
    speak("Grid " .. tostring(grid_size))
end

function reset_grid_size()
    grid_size = GRID_DEFAULT
end


function reset_grid_size_and_speak()
    grid_size_user_changed = true
    grid_size_auto_default = false

    reset_grid_size()
    save_plugin_grid_size_to_txt()

    speak("Grid 10")
end

function change_grid_size(direction)
    direction = tonumber(direction) or 0

    if direction == 0 then
        return
    end

    local old_grid_size = grid_size
    local amount = get_integer_step_amount()

    grid_size = grid_size + (amount * direction)
    grid_size = clamp_int(grid_size, GRID_MIN, GRID_MAX)

    if grid_size == old_grid_size then
        return
    end

    grid_size_user_changed = true
    grid_size_auto_default = false

    save_plugin_grid_size_to_txt()
    announce_grid_size()
end

------------------------------------------------------------
-- 2.6 - STEP SCALE
------------------------------------------------------------
STEP_SCALES = {
    { mult = 0.0001, name = "Step 0.0001x" },
    { mult = 0.0002, name = "Step 0.0002x" },
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

STEP_SCALE_SAVE_VERSION = "v3"
STEP_NORMAL_INDEX = 11

step_scale_index = STEP_NORMAL_INDEX

function get_plugin_step_scale_key()
    return "step_scale_index_v1"
end

function encode_step_scale_index_for_txt()
    step_scale_index = clamp_int(step_scale_index, 1, #STEP_SCALES)

    return STEP_SCALE_SAVE_VERSION .. ":" .. tostring(step_scale_index)
end

function decode_step_scale_index_from_txt(saved)
    saved = clean_one_line(saved or "")

    --------------------------------------------------------
    -- Nuovo formato: v3:11
    --------------------------------------------------------
    local version, index_s = saved:match("^(v%d+)%s*:%s*(%d+)$")

    if version == STEP_SCALE_SAVE_VERSION then
        return clamp_int(tonumber(index_s), 1, #STEP_SCALES)
    end

    --------------------------------------------------------
    -- Formato v2:
    -- era già indicizzato sulla tabella con 0.0005x come primo step.
    -- In v3 sono state aggiunte due voci prima,
    -- quindi gli indici v2 vengono spostati di +2.
    --------------------------------------------------------
    if version == "v2" then
        return clamp_int((tonumber(index_s) or STEP_NORMAL_INDEX) + 2, 1, #STEP_SCALES)
    end

    --------------------------------------------------------
    -- Vecchio formato:
    -- era solo un numero.
    -- Nella tabella più vecchia:
    -- 1 = Step 0.002x
    -- 8 = Step normal
    --
    -- In v3 sono presenti tre voci prima di 0.002x:
    -- 0.0001x, 0.0002x e 0.0005x.
    -- Quindi i vecchi indici validi vengono spostati di +3.
    --------------------------------------------------------
    local old_index = tonumber(saved)

    if old_index ~= nil then
        old_index = clamp_int(old_index, 1, #STEP_SCALES - 3)

        return clamp_int(old_index + 3, 1, #STEP_SCALES)
    end

    return STEP_NORMAL_INDEX
end

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

function reset_step_scale()
    step_scale_index = STEP_NORMAL_INDEX
end


function reset_step_scale_and_speak()
    reset_step_scale()

    if type(param_step_scale_mark_dirty_for_current_param) == "function" then
        param_step_scale_mark_dirty_for_current_param()
    end

    speak("Step normal")
end

function change_step_scale(direction)
    direction = tonumber(direction) or 0

    if direction == 0 then
        return
    end

    local old_step_scale_index = step_scale_index

    step_scale_index = step_scale_index + direction
    step_scale_index = clamp_int(step_scale_index, 1, #STEP_SCALES)

    if step_scale_index == old_step_scale_index then
        return
    end

    if type(param_step_scale_mark_dirty_for_current_param) == "function" then
        param_step_scale_mark_dirty_for_current_param()
    end

    announce_step_scale()
end

------------------------------------------------------------
-- 2.6A - STEP SCALE PER PARAMETRO NEL TXT PLUGIN
--
-- Default: Step normal.
-- Se un parametro non ha una voce salvata nel TXT, torna sempre
-- a Step normal quando ci arrivi.
-- Alt+Freccia sinistra/destra marca solo il parametro come dirty:
-- il TXT viene scritto quando cambi parametro, cambi FX o esci.
------------------------------------------------------------
PARAM_STEP_SCALES_KEY = "param_step_scales_v1"

param_step_scale_active_param_index = nil
param_step_scale_active_param_name = ""
param_step_scale_dirty = false
param_step_scale_restoring = false

function get_plugin_param_step_scales_key()
    return PARAM_STEP_SCALES_KEY
end

function param_step_scale_param_name(i)
    i = tonumber(i)

    if i == nil then
        return ""
    end

    if not param_index_is_valid or not param_index_is_valid(i) then
        return ""
    end

    local name = ""

    if type(get_param_name) == "function" then
        name = clean_one_line(get_param_name(i))
    end

    if name == "" then
        name = "Parameter " .. tostring(i + 1)
    end

    return name
end

function param_step_scale_encode_entry(index)
    index = clamp_int(index, 1, #STEP_SCALES)
    return STEP_SCALE_SAVE_VERSION .. ":" .. tostring(index)
end

function param_step_scale_decode_entry(saved)
    return decode_step_scale_index_from_txt(saved)
end

function param_step_scale_load_map()
    local map = {}

    if not plugin_storage_available() then
        return map
    end

    local txt = get_plugin_state_safe(get_plugin_param_step_scales_key()) or ""

    for line in tostring(txt or ""):gmatch("[^\r\n]+") do
        line = trim(line)

        if line ~= "" then
            local index_s, name, encoded =
                line:match("^(%-?%d+)%s*\t%s*([^\t]*)%s*\t%s*(.*)$")

            local i = tonumber(index_s)

            if i ~= nil then
                i = math.floor(i + 0.5)

                local decoded = param_step_scale_decode_entry(encoded)

                if decoded ~= STEP_NORMAL_INDEX then
                    map[tostring(i)] = {
                        index = i,
                        name = clean_one_line(name or ""),
                        step_index = decoded
                    }
                end
            end
        end
    end

    return map
end

function param_step_scale_map_to_text(map)
    map = map or {}

    local keys = {}

    for key, entry in pairs(map) do
        local i = tonumber(key)

        if i ~= nil and entry and tonumber(entry.step_index) ~= nil then
            keys[#keys + 1] = math.floor(i + 0.5)
        end
    end

    table.sort(keys)

    local lines = {}

    for pos = 1, #keys do
        local i = keys[pos]
        local entry = map[tostring(i)]
        local step_index = clamp_int(entry and entry.step_index, 1, #STEP_SCALES)

        if step_index ~= STEP_NORMAL_INDEX then
            lines[#lines + 1] =
                tostring(i) ..
                "\t" ..
                clean_one_line(entry and entry.name or "") ..
                "\t" ..
                param_step_scale_encode_entry(step_index)
        end
    end

    return table.concat(lines, "\n")
end

function param_step_scale_write_map(map, force_write)
    if not plugin_storage_available() then
        return false
    end

    local txt = param_step_scale_map_to_text(map)
    local old = get_plugin_state_safe(get_plugin_param_step_scales_key()) or ""

    if txt == old then
        return true
    end

    set_plugin_state_safe(get_plugin_param_step_scales_key(), txt)

    if force_write then
        plugin_txt_save_if_dirty(true)
    else
        plugin_txt_save_if_dirty(false)
    end

    return true
end

function param_step_scale_mark_dirty_for_current_param()
    if param_step_scale_restoring then
        return false
    end

    if not param_index_is_valid or not param_index_is_valid(param_index) then
        return false
    end

    param_step_scale_active_param_index = math.floor((tonumber(param_index) or 0) + 0.5)
    param_step_scale_active_param_name = param_step_scale_param_name(param_step_scale_active_param_index)
    param_step_scale_dirty = true

    return true
end

function param_step_scale_save_active(force_write)
    if not param_step_scale_dirty then
        return true
    end

    if not plugin_storage_available() then
        param_step_scale_dirty = false
        return false
    end

    local i = tonumber(param_step_scale_active_param_index)

    if i == nil then
        param_step_scale_dirty = false
        return false
    end

    i = math.floor(i + 0.5)

    local map = param_step_scale_load_map()
    local key = tostring(i)

    if step_scale_index == STEP_NORMAL_INDEX then
        map[key] = nil
    else
        map[key] = {
            index = i,
            name = clean_one_line(param_step_scale_active_param_name),
            step_index = clamp_int(step_scale_index, 1, #STEP_SCALES)
        }
    end

    param_step_scale_dirty = false

    return param_step_scale_write_map(map, force_write == true)
end

function param_step_scale_find_saved_for_param(i)
    i = tonumber(i)

    if i == nil or not plugin_storage_available() then
        return nil
    end

    i = math.floor(i + 0.5)

    local map = param_step_scale_load_map()
    local current_name = param_step_scale_param_name(i)
    local entry = map[tostring(i)]

    if entry then
        if entry.name == "" or current_name == "" or
           clean_one_line(entry.name):lower() == current_name:lower() then

            return entry.step_index
        end
    end

    --------------------------------------------------------
    -- Fallback per vecchi TXT o plugin riordinati:
    -- se l'indice non combacia più con il nome, prova il nome.
    --------------------------------------------------------
    if current_name ~= "" then
        local wanted = current_name:lower()

        for _, e in pairs(map) do
            if e and clean_one_line(e.name or ""):lower() == wanted then
                return e.step_index
            end
        end
    end

    return nil
end

function param_step_scale_restore_for_param(i)
    i = tonumber(i)

    if i == nil then
        return false
    end

    i = math.floor(i + 0.5)

    param_step_scale_restoring = true

    local saved_step = param_step_scale_find_saved_for_param(i)

    if saved_step ~= nil then
        step_scale_index = clamp_int(saved_step, 1, #STEP_SCALES)
    else
        step_scale_index = STEP_NORMAL_INDEX
    end

    param_step_scale_restoring = false

    param_step_scale_active_param_index = i
    param_step_scale_active_param_name = param_step_scale_param_name(i)
    param_step_scale_dirty = false

    return true
end

function param_step_scale_sync_for_current_param()
    if not param_index_is_valid or not param_index_is_valid(param_index) then
        param_step_scale_active_param_index = nil
        param_step_scale_active_param_name = ""
        param_step_scale_dirty = false
        step_scale_index = STEP_NORMAL_INDEX
        return false
    end

    local new_i = math.floor((tonumber(param_index) or 0) + 0.5)
    local old_i = tonumber(param_step_scale_active_param_index)

    if old_i ~= nil and math.floor(old_i + 0.5) ~= new_i then
        param_step_scale_save_active(true)
    end

    if old_i == nil or math.floor(old_i + 0.5) ~= new_i then
        param_step_scale_restore_for_param(new_i)
    end

    return true
end

function param_step_scale_flush_current()
    return param_step_scale_save_active(true)
end

------------------------------------------------------------
-- 2.7 - STEP LOGIC CONDIVISA
------------------------------------------------------------
function get_integer_step_amount()
    local amount = math.floor(get_step_scale() + 0.5)

    if amount < 1 then
        amount = 1
    end

    return amount
end

function get_page_nav_amount()
    local scale = get_step_scale()
    local amount = math.floor(scale * 5 + 0.5)

    if amount < 2 then
        amount = 2
    end

    return amount
end

function get_discrete_step_amount(big_step)
    local amount = get_integer_step_amount()

    if big_step then
        amount = amount * 8
    end

    if amount < 1 then
        amount = 1
    end

    return amount
end

------------------------------------------------------------
-- 2.7A - ANNUNCIO STATO STEP / GRID
------------------------------------------------------------
function get_slot_access_status_label()
    if slot_access_mode == "param" then
        return "Memory slots"
    end

    return "Group slots"
end

function announce_step_grid_status()
    cancel_pending_speech()

    local step_name = get_step_name()
    local status_prefix = get_current_fx_status_spoken_prefix()
    local slot_status = get_slot_access_status_label()
    local cc_status = get_current_param_cc_spoken_part()

    local msg =
        status_prefix ..
        step_name ..
        ". Grid " ..
        tostring(grid_size) ..
        ". " ..
        slot_status ..
        cc_status

    speak(msg)
end

------------------------------------------------------------
-- 2.8 - SALVATAGGIO / RIPRISTINO STEP E GRID
------------------------------------------------------------
function save_project_browser_state()
    save_plugin_step_scale_to_txt()
    save_plugin_grid_size_to_txt()
end

function load_project_browser_state()
    restore_plugin_step_scale_from_txt()
    restore_plugin_grid_size_from_txt()
end


function reset_all_defaults()
    reset_step_scale()
    reset_grid_size()

    grid_size_user_changed = true
    grid_size_auto_default = false

    save_plugin_step_grid_to_txt()

    last_function_touched = nil

    speak("Step normal. Grid 10")
end

function reset_last_function()
    if last_function_touched == "step" then
        reset_step_scale_and_speak()
        return
    end

    if last_function_touched == "grid" then
        reset_grid_size_and_speak()
        return
    end

    reset_all_defaults()
end

------------------------------------------------------------
-- 2.8A - RESET CON BACKSPACE
--
-- Backspace:              parametro corrente al default.
-- Ctrl+Backspace:         ultimo controllo Step / Grid.
-- Ctrl+Shift+Backspace:   tutti i parametri al default.
--
-- Questa funzione non viene chiamata dagli editor testuali
-- o dall'edit numerico, dove Backspace continua a cancellare.
------------------------------------------------------------
function handle_backspace_reset_shortcut(char)
    if char ~= KEY_BACKSPACE and
       char ~= KEY_BACKSPACE_2 then

        return false
    end

    local is_ctrl = ctrl_down()
    local is_shift = shift_down()
    local is_alt = alt_down()

    clear_param_memory_arm()
    disarm_slot_deletes()

    if is_ctrl and is_shift and not is_alt then
        reset_all_params_to_plugin_default_snapshot()
        return true
    end

    if is_ctrl and not is_shift and not is_alt then
        reset_last_function()
        return true
    end

    if not is_ctrl and not is_alt then
        reset_current_param_to_plugin_default_snapshot()
        return true
    end

    return true
end

------------------------------------------------------------
-- 2.9 - CONTESTO MASTER / TRACK / TAKE
------------------------------------------------------------
function get_master_track()
    if reaper.GetMasterTrack then
        return reaper.GetMasterTrack(0)
    end

    return nil
end

function master_is_selected()
    local master = get_master_track()

    if not master then
        return false
    end

    if reaper.IsTrackSelected then
        return reaper.IsTrackSelected(master)
    end

    return false
end

function selected_track_is_master(track)
    if not track then
        return false
    end

    local n = reaper.GetMediaTrackInfo_Value(track, "IP_TRACKNUMBER")

    return math.floor(tonumber(n) or -1) == 0
end

function get_preferred_source_track()
    local master = get_master_track()

    --------------------------------------------------------
    -- Traccia normale selezionata:
    -- valida solo se ha FX.
    --------------------------------------------------------
    local selected_track_count = reaper.CountSelectedTracks(0)

    if selected_track_count > 0 then
        for i = 0, selected_track_count - 1 do
            local selected = reaper.GetSelectedTrack(0, i)

            if selected and
               not selected_track_is_master(selected) and
               get_track_fx_count(selected) > 0 then

                return selected, false
            end
        end
    end

    --------------------------------------------------------
    -- Master / Monitor:
    -- valido solo se il Master è selezionato davvero.
    --------------------------------------------------------
    if master and master_is_selected() then
        if get_track_fx_count(master) > 0 or
           get_monitor_fx_count(master) > 0 then

            return master, true
        end
    end

    --------------------------------------------------------
    -- Nessun fallback.
    -- Non prende last touched.
    -- Non prende tracce precedenti.
    -- Non prende il monitor se il Master non è selezionato.
    --------------------------------------------------------
    return nil, false
end

------------------------------------------------------------
-- 2.10 - CONTEGGIO FX TRACK / TAKE / MONITOR
------------------------------------------------------------
function get_track_fx_count(track)
    if not track then
        return 0
    end

    return reaper.TrackFX_GetCount(track) or 0
end

function get_take_fx_count(take)
    if not take then
        return 0
    end

    return reaper.TakeFX_GetCount(take) or 0
end

function get_monitor_fx_count(master_track)
    master_track = master_track or get_master_track()

    if not master_track then
        return 0
    end

    if reaper.TrackFX_GetRecCount then
        return reaper.TrackFX_GetRecCount(master_track) or 0
    end

    return 0
end

------------------------------------------------------------
-- 2.10A - LISTA FX DEL CONTESTO CORRENTE
--
-- Costruisce:
-- - fx_count
-- - fx_names
-- - fx_real_indices
-- - fx_is_monitor
--
-- Supporta:
-- - Track FX
-- - Take FX
-- - Master FX
-- - Monitor FX del Master
------------------------------------------------------------

function clear_fx_list()
    fx_count = 0
    fx_names = {}
    fx_real_indices = {}
    fx_is_monitor = {}

    fx_index = 0
    selected_fx_label = ""
    selected_fx_is_monitor = false
end

function get_track_fx_name_safe(track, real_fx)
    if not track then
        return ""
    end

    local ok, retval, name =
        pcall(
            reaper.TrackFX_GetFXName,
            track,
            real_fx,
            ""
        )

    if ok and retval then
        return clean_one_line(name or "")
    end

    return ""
end

function get_take_fx_name_safe(take, real_fx)
    if not take then
        return ""
    end

    local ok, retval, name =
        pcall(
            reaper.TakeFX_GetFXName,
            take,
            real_fx,
            ""
        )

    if ok and retval then
        return clean_one_line(name or "")
    end

    return ""
end

function add_fx_to_current_list(name, real_fx, is_monitor)
    name = clean_one_line(name or "")

    if name == "" then
        name = "FX " .. tostring(#fx_names + 1)
    end

    fx_names[#fx_names + 1] = name
    fx_real_indices[#fx_real_indices + 1] = real_fx
    fx_is_monitor[#fx_is_monitor + 1] = is_monitor == true

    fx_count = #fx_names
end

function build_fx_list_for_current_context()
    clear_fx_list()

    --------------------------------------------------------
    -- TAKE FX
    --------------------------------------------------------
    if ctx.kind == "take" then
        if not ctx.take then
            return false
        end

        local count = get_take_fx_count(ctx.take)

        for i = 0, count - 1 do
            local name = get_take_fx_name_safe(ctx.take, i)

            add_fx_to_current_list(
                name,
                i,
                false
            )
        end

        if fx_count > 0 then
            fx_index = clamp_int(fx_index, 0, fx_count - 1)
            selected_fx_label = fx_names[fx_index + 1] or ""
            selected_fx_is_monitor = false
        end

        return fx_count > 0
    end

    --------------------------------------------------------
    -- TRACK / MASTER FX
    --------------------------------------------------------
    if not ctx.track then
        return false
    end

    local normal_count = get_track_fx_count(ctx.track)

    for i = 0, normal_count - 1 do
        local name = get_track_fx_name_safe(ctx.track, i)

        add_fx_to_current_list(
            name,
            i,
            false
        )
    end

    --------------------------------------------------------
    -- MONITOR FX
    --
    -- Solo sul Master.
    -- REAPER usa MONITOR_FX_OFFSET + indice monitor.
    --------------------------------------------------------
    if ctx.is_master then
        local monitor_count = get_monitor_fx_count(ctx.track)

        for i = 0, monitor_count - 1 do
            local real_fx = MONITOR_FX_OFFSET + i
            local name = get_track_fx_name_safe(ctx.track, real_fx)

            add_fx_to_current_list(
                name,
                real_fx,
                true
            )
        end
    end

    if fx_count > 0 then
        fx_index = clamp_int(fx_index, 0, fx_count - 1)
        selected_fx_label = fx_names[fx_index + 1] or ""
        selected_fx_is_monitor = fx_is_monitor[fx_index + 1] == true
    end

    return fx_count > 0
end

function get_current_real_fx_index()
    if fx_count <= 0 then
        return nil
    end

    local list_index = (tonumber(fx_index) or 0) + 1
    local real_fx = fx_real_indices[list_index]

    if real_fx == nil then
        return nil
    end

    return real_fx
end


------------------------------------------------------------
-- 2.10B - FX CHAIN VISIBLE: SELEZIONE DIRETTA DA CATENA FX
--
-- Quando lo script viene aperto mentre l'utente è dentro la
-- FX chain, REAPER espone l'FX selezionato con:
-- - TrackFX_GetChainVisible(track)
-- - TakeFX_GetChainVisible(take)
-- - TrackFX_GetRecChainVisible(track) per Monitor/Input FX,
--   quando disponibile.
--
-- Questa memoria deve vincere sulla memoria TXT dell'ultimo FX,
-- ma solo se la catena FX è realmente aperta/visibile.
------------------------------------------------------------
function fx_chain_visible_real_fx_for_current_context()
    local real_fx = nil

    if ctx.kind == "take" then
        if ctx.take and type(reaper.TakeFX_GetChainVisible) == "function" then
            local ok, v = pcall(reaper.TakeFX_GetChainVisible, ctx.take)

            if ok then
                real_fx = tonumber(v)
            end
        end

        if real_fx ~= nil and real_fx >= 0 then
            return math.floor(real_fx + 0.5), false
        end

        return nil, false
    end

    if not ctx.track then
        return nil, false
    end

    --------------------------------------------------------
    -- Master/Monitor: se è aperta la catena Monitor/Input FX,
    -- preferiscila alla catena Master normale.
    --------------------------------------------------------
    if ctx.is_master and type(reaper.TrackFX_GetRecChainVisible) == "function" then
        local ok, v = pcall(reaper.TrackFX_GetRecChainVisible, ctx.track)

        if ok then
            real_fx = tonumber(v)
        end

        if real_fx ~= nil and real_fx >= 0 then
            return MONITOR_FX_OFFSET + math.floor(real_fx + 0.5), true
        end
    end

    if type(reaper.TrackFX_GetChainVisible) == "function" then
        local ok, v = pcall(reaper.TrackFX_GetChainVisible, ctx.track)

        if ok then
            real_fx = tonumber(v)
        end
    end

    if real_fx ~= nil and real_fx >= 0 then
        return math.floor(real_fx + 0.5), false
    end

    return nil, false
end

function fx_chain_visible_select_current_fx()
    local wanted_real_fx, wanted_monitor = fx_chain_visible_real_fx_for_current_context()

    if wanted_real_fx == nil then
        return false
    end

    wanted_monitor = wanted_monitor == true

    for list_index = 1, #fx_real_indices do
        if fx_real_indices[list_index] == wanted_real_fx and
           (fx_is_monitor[list_index] == true) == wanted_monitor then

            fx_index = list_index - 1
            selected_fx_label = fx_names[list_index] or ""
            selected_fx_is_monitor = fx_is_monitor[list_index] == true

            return selected_fx_label ~= ""
        end
    end

    return false
end

------------------------------------------------------------
-- 2.11 - ITEM SELEZIONATI SULLA TRACCIA
------------------------------------------------------------
function count_selected_items_on_track(track)
    if not track then
        return 0
    end

    local count = 0
    local sel_count = reaper.CountSelectedMediaItems(0)

    for i = 0, sel_count - 1 do
        local item = reaper.GetSelectedMediaItem(0, i)

        if item and reaper.GetMediaItemTrack(item) == track then
            count = count + 1
        end
    end

    return count
end

function get_first_selected_item_on_track(track)
    if not track then
        return nil
    end

    local sel_count = reaper.CountSelectedMediaItems(0)

    for i = 0, sel_count - 1 do
        local item = reaper.GetSelectedMediaItem(0, i)

        if item and reaper.GetMediaItemTrack(item) == track then
            return item
        end
    end

    return nil
end

function clear_real_item_selection()
    reaper.Main_OnCommand(CMD_UNSELECT_ALL_ITEMS, 0)
    reaper.UpdateArrange()
end

------------------------------------------------------------
-- 2.12 - IMPOSTAZIONE CONTESTO SCRIPT
------------------------------------------------------------
function set_context_track(track, is_master)
    if not track then
        return false
    end

    ctx.kind = "track"
    ctx.track = track
    ctx.take = nil
    ctx.item = nil
    ctx.is_master = is_master == true

    return true
end

function set_context_item(item)
    if not item then
        return false
    end

    local take = reaper.GetActiveTake(item)

    if not take then
        return false
    end

    ctx.kind = "take"
    ctx.track = reaper.GetMediaItem_Track(item)
    ctx.take = take
    ctx.item = item
    ctx.is_master = false

    return true
end

------------------------------------------------------------
-- 2.13 - MEMORIA TEMPORANEA ITEM APERTO DALLO SCRIPT
--
-- Serve a evitare che, dopo l'uscita dallo script, un item
-- selezionato dallo script venga riaperto per errore come
-- contesto iniziale stale.
------------------------------------------------------------
function get_item_guid(item)
    if not item then
        return ""
    end

    local ok, _, guid = pcall(
        reaper.GetSetMediaItemInfo_String,
        item,
        "GUID",
        "",
        false
    )

    if ok then
        return clean_one_line(guid or "")
    end

    return ""
end

function get_track_memory_id(track, is_master)
    if not track then
        return ""
    end

    if is_master then
        return "track::MASTER"
    end

    local guid = ""

    if reaper.GetTrackGUID then
        guid = clean_one_line(reaper.GetTrackGUID(track) or "")
    end

    if guid ~= "" then
        return "track::" .. guid
    end

    local track_num = reaper.GetMediaTrackInfo_Value(
        track,
        "IP_TRACKNUMBER"
    )

    local _, track_name = reaper.GetTrackName(track)

    return
        "tracknum_" ..
        tostring(math.floor(tonumber(track_num) or 0)) ..
        "::" ..
        clean_one_line(track_name or "")
end

function clear_stale_item_memory()
    reaper.SetExtState(
        EXT_SECTION,
        EXT_STALE_ITEM_GUID_KEY,
        "",
        false
    )

    reaper.SetExtState(
        EXT_SECTION,
        EXT_STALE_ITEM_TRACK_KEY,
        "",
        false
    )
end

function save_exit_context_memory()
    if ctx.kind ~= "take" or not ctx.item or not ctx.track then
        clear_stale_item_memory()
        return
    end

    local item_guid = get_item_guid(ctx.item)
    local track_id = get_track_memory_id(ctx.track, false)

    if item_guid == "" or track_id == "" then
        clear_stale_item_memory()
        return
    end

    reaper.SetExtState(
        EXT_SECTION,
        EXT_STALE_ITEM_GUID_KEY,
        item_guid,
        false
    )

    reaper.SetExtState(
        EXT_SECTION,
        EXT_STALE_ITEM_TRACK_KEY,
        track_id,
        false
    )
end

function selected_item_is_stale_from_previous_script(item, track)
    if not item or not track then
        return false
    end

    local saved_item_guid =
        reaper.GetExtState(EXT_SECTION, EXT_STALE_ITEM_GUID_KEY) or ""

    local saved_track_id =
        reaper.GetExtState(EXT_SECTION, EXT_STALE_ITEM_TRACK_KEY) or ""

    saved_item_guid = clean_one_line(saved_item_guid)
    saved_track_id = clean_one_line(saved_track_id)

    if saved_item_guid == "" or saved_track_id == "" then
        return false
    end

    local current_item_guid = get_item_guid(item)
    local current_track_id = get_track_memory_id(track, false)

    return
        current_item_guid ~= "" and
        current_track_id ~= "" and
        current_item_guid == saved_item_guid and
        current_track_id == saved_track_id
end

function suppress_stale_selected_item_if_needed(source_track)
    if not source_track then
        return false
    end

    local item = get_first_selected_item_on_track(source_track)

    if not item then
        return false
    end

    if not selected_item_is_stale_from_previous_script(item, source_track) then
        return false
    end

    clear_real_item_selection()
    clear_stale_item_memory()

    return true
end

function get_reaper_cursor_context_kind()
    --------------------------------------------------------
    -- REAPER:
    -- 0 = track / TCP / mixer context
    -- 1 = item / arrange item context
    -- 2 = envelope context
    --
    -- GetCursorContext2(true) è preferibile perché restituisce
    -- l'ultimo contesto valido anche quando il focus è passato
    -- temporaneamente altrove.
    --------------------------------------------------------
    local ctx_id = nil

    if reaper.GetCursorContext2 then
        local ok, value = pcall(reaper.GetCursorContext2, true)

        if ok then
            ctx_id = tonumber(value)
        end
    end

    if ctx_id == nil and reaper.GetCursorContext then
        local ok, value = pcall(reaper.GetCursorContext)

        if ok then
            ctx_id = tonumber(value)
        end
    end

    if ctx_id == 1 then
        return "item"
    end

    if ctx_id == 0 then
        return "track"
    end

    return ""
end

function get_first_selected_normal_track()
    local selected_track_count = reaper.CountSelectedTracks(0)

    if selected_track_count <= 0 then
        return nil
    end

    for i = 0, selected_track_count - 1 do
        local tr = reaper.GetSelectedTrack(0, i)

        if tr and not selected_track_is_master(tr) then
            return tr
        end
    end

    return nil
end

function get_first_selected_item_with_take_fx(preferred_track)
    local selected_item_count = reaper.CountSelectedMediaItems(0)

    if selected_item_count <= 0 then
        return nil
    end

    --------------------------------------------------------
    -- Prima prova l'item sulla traccia preferita.
    -- Serve quando traccia e item sono entrambi selezionati.
    --------------------------------------------------------
    if preferred_track then
        for i = 0, selected_item_count - 1 do
            local item = reaper.GetSelectedMediaItem(0, i)

            if item and reaper.GetMediaItemTrack(item) == preferred_track then
                local take = reaper.GetActiveTake(item)

                if take and get_take_fx_count(take) > 0 then
                    return item
                end
            end
        end
    end

    --------------------------------------------------------
    -- Poi qualunque item selezionato con Take FX.
    --------------------------------------------------------
    for i = 0, selected_item_count - 1 do
        local item = reaper.GetSelectedMediaItem(0, i)

        if item then
            local take = reaper.GetActiveTake(item)

            if take and get_take_fx_count(take) > 0 then
                return item
            end
        end
    end

    return nil
end

function selected_items_have_item_on_track(track)
    if not track then
        return false
    end

    return get_first_selected_item_on_track(track) ~= nil
end

------------------------------------------------------------
-- 2.13A - CONTESTO DALLA FX CHAIN REALMENTE APERTA
--
-- La catena FX visibile deve vincere sulle selezioni rimaste
-- nell'Arrange. Questo risolve due casi:
-- - Master FX aperta mentre una traccia normale resta selezionata;
-- - Track FX aperta mentre un item resta selezionato.
--
-- Quando riconosce una Track/Master chain, pulisce la selezione
-- item reale: così FX Param resta subito nel contesto traccia e
-- non richiede di cambiare/riselezionare la traccia.
------------------------------------------------------------
function track_chain_has_visible_fx(track, is_master)
    if not track then
        return false
    end

    if is_master and
       type(reaper.TrackFX_GetRecChainVisible) == "function" then

        local ok, visible = pcall(
            reaper.TrackFX_GetRecChainVisible,
            track
        )

        if ok and tonumber(visible) and tonumber(visible) >= 0 then
            return true
        end
    end

    if type(reaper.TrackFX_GetChainVisible) == "function" then
        local ok, visible = pcall(
            reaper.TrackFX_GetChainVisible,
            track
        )

        if ok and tonumber(visible) and tonumber(visible) >= 0 then
            return true
        end
    end

    return false
end

function take_chain_has_visible_fx(take)
    if not take or
       type(reaper.TakeFX_GetChainVisible) ~= "function" then

        return false
    end

    local ok, visible = pcall(
        reaper.TakeFX_GetChainVisible,
        take
    )

    return
        ok and
        tonumber(visible) ~= nil and
        tonumber(visible) >= 0
end

function select_context_from_visible_fx_chain()
    local master = get_master_track()

    --------------------------------------------------------
    -- 1. MASTER / MONITOR FX.
    -- Deve vincere anche se una traccia normale è ancora
    -- selezionata quando si usa "View FX chain for master".
    --------------------------------------------------------
    if master and track_chain_has_visible_fx(master, true) then
        clear_real_item_selection()
        clear_stale_item_memory()
        return set_context_track(master, true)
    end

    --------------------------------------------------------
    -- 2. TRACCE NORMALI SELEZIONATE CON CATENA APERTA.
    --------------------------------------------------------
    local selected_track_count = reaper.CountSelectedTracks(0)

    for i = 0, selected_track_count - 1 do
        local track = reaper.GetSelectedTrack(0, i)

        if track and
           not selected_track_is_master(track) and
           track_chain_has_visible_fx(track, false) then

            clear_real_item_selection()
            clear_stale_item_memory()
            return set_context_track(track, false)
        end
    end

    --------------------------------------------------------
    -- 3. QUALUNQUE TRACCIA NORMALE CON CATENA APERTA.
    -- Utile se REAPER ha aperto la chain senza aggiornare la
    -- selezione della traccia nell'Arrange.
    --------------------------------------------------------
    local track_count = reaper.CountTracks(0)

    for i = 0, track_count - 1 do
        local track = reaper.GetTrack(0, i)

        if track and track_chain_has_visible_fx(track, false) then
            clear_real_item_selection()
            clear_stale_item_memory()
            return set_context_track(track, false)
        end
    end

    --------------------------------------------------------
    -- 4. TAKE FX VISIBILE SU ITEM SELEZIONATO.
    -- Conserva il normale comportamento item quando è
    -- davvero la Take FX chain a essere aperta.
    --------------------------------------------------------
    local selected_item_count = reaper.CountSelectedMediaItems(0)

    for i = 0, selected_item_count - 1 do
        local item = reaper.GetSelectedMediaItem(0, i)
        local take = item and reaper.GetActiveTake(item) or nil

        if take and take_chain_has_visible_fx(take) then
            clear_stale_item_memory()
            return set_context_item(item)
        end
    end

    return false
end

function select_start_context()
    local master = get_master_track()
    local selected_item_count = reaper.CountSelectedMediaItems(0)
    local selected_track = get_first_selected_normal_track()
    local cursor_kind = get_reaper_cursor_context_kind()

    start_context_no_fx_kind = ""

    --------------------------------------------------------
    -- PRIORITÀ ASSOLUTA: FX CHAIN REALMENTE APERTA.
    -- Decide già qui il contesto Master / Track / Take, non
    -- soltanto il plugin selezionato dentro la catena.
    --------------------------------------------------------
    if select_context_from_visible_fx_chain() then
        return true
    end

    --------------------------------------------------------
    -- MASTER INTENZIONALE.
    --
    -- Questa regola deve stare prima dei fallback generici
    -- su last touched track o su qualunque traccia normale.
    -- Se il Master è selezionato davvero, il contesto deve
    -- restare Master, così il browser FX può costruire le
    -- due colonne: Master FX e Monitor FX.
    --------------------------------------------------------
    if master and master_is_selected() then
        if get_track_fx_count(master) > 0 or
           get_monitor_fx_count(master) > 0 then

            return set_context_track(master, true)
        end

        start_context_no_fx_kind = "master"
        return false
    end

    --------------------------------------------------------
    -- REGOLA PRINCIPALE:
    --
    -- Non basta guardare cosa è selezionato, perché in REAPER
    -- item e traccia possono restare selezionati insieme.
    --
    -- Quindi:
    -- - se il contesto REAPER è item, l'item è intenzionale;
    -- - se il contesto REAPER è track, la traccia è intenzionale;
    -- - se non sappiamo il contesto, usiamo il fallback 0.174.
    --------------------------------------------------------

    --------------------------------------------------------
    -- 1. ITEM INTENZIONALE.
    --
    -- Questo risolve il caso:
    -- torno su una traccia, vince la traccia;
    -- poi seleziono/richiamo l'item già selezionato,
    -- e deve vincere l'item già alla prima volta.
    --------------------------------------------------------
    if cursor_kind == "item" and selected_item_count > 0 then
        local item = get_first_selected_item_with_take_fx(selected_track)

        if item then
            return set_context_item(item)
        end

        ----------------------------------------------------
        -- L'utente è nel contesto item, ma l'item non ha FX.
        -- Non cadere sui Track FX, altrimenti sembra che
        -- lo script ignori l'intenzione item.
        ----------------------------------------------------
        start_context_no_fx_kind = "item"
        return false
    end

    --------------------------------------------------------
    -- 2. TRACCIA INTENZIONALE.
    --
    -- Se una traccia normale è selezionata e il contesto non
    -- è item, la traccia vince. Non cancelliamo più la
    -- selezione item: cancellarla era una delle cause per cui
    -- poi servivano due gesti per riaprire l'item.
    --------------------------------------------------------
    if selected_track then
        if get_track_fx_count(selected_track) > 0 then
            return set_context_track(selected_track, false)
        end

        ----------------------------------------------------
        -- Traccia selezionata ma senza FX:
        -- fermati qui. Non aprire la traccia precedente,
        -- non cadere su item vecchi e non cadere sul fallback.
        ----------------------------------------------------
        start_context_no_fx_kind = "track"
        return false
    end

    --------------------------------------------------------
    -- 3. FALLBACK STILE 0.174:
    -- item selezionati con Take FX.
    --------------------------------------------------------
    if selected_item_count > 0 then
        local item = get_first_selected_item_with_take_fx(nil)

        if item then
            return set_context_item(item)
        end
    end

    --------------------------------------------------------
    -- 4. FALLBACK STILE 0.174:
    -- item selezionati senza Take FX:
    -- usa la traccia dell'item, se ha FX normali.
    --------------------------------------------------------
    if selected_item_count > 0 then
        for i = 0, selected_item_count - 1 do
            local item = reaper.GetSelectedMediaItem(0, i)

            if item then
                local item_track = reaper.GetMediaItemTrack(item)

                if item_track and
                   not selected_track_is_master(item_track) and
                   get_track_fx_count(item_track) > 0 then

                    return set_context_track(item_track, false)
                end
            end
        end

        start_context_no_fx_kind = "item"
        return false
    end

    --------------------------------------------------------
    -- 5. LAST TOUCHED TRACK NORMALE.
    -- Solo se non c'è una traccia selezionata.
    --------------------------------------------------------
    if reaper.GetLastTouchedTrack then
        local touched = reaper.GetLastTouchedTrack()

        if touched and
           not selected_track_is_master(touched) and
           get_track_fx_count(touched) > 0 then

            return set_context_track(touched, false)
        end
    end

    --------------------------------------------------------
    -- 6. FALLBACK: qualunque traccia normale con FX.
    -- Questo resta solo come ultima spiaggia.
    --------------------------------------------------------
    local track_count = reaper.CountTracks(0)

    for i = 0, track_count - 1 do
        local tr = reaper.GetTrack(0, i)

        if tr and
           not selected_track_is_master(tr) and
           get_track_fx_count(tr) > 0 then

            return set_context_track(tr, false)
        end
    end

    --------------------------------------------------------
    -- 7. MASTER / MONITOR.
    --
    -- Fallback finale: solo se il Master non era selezionato
    -- ma non abbiamo trovato nessun altro contesto utile.
    -- Se il Master era selezionato, è già stato gestito
    -- all'inizio della funzione.
    --------------------------------------------------------
    if master and
       (
           get_track_fx_count(master) > 0 or
           get_monitor_fx_count(master) > 0
       ) then

        return set_context_track(master, true)
    end

    return false
end

function speak_start_context_no_fx()
    if start_context_no_fx_kind == "item" then
        speak("No FX found for item")
        return true
    end

    if start_context_no_fx_kind == "track" then
        speak("No FX found for track")
        return true
    end

    if start_context_no_fx_kind == "master" then
        speak("No FX found for Master or Monitor FX")
        return true
    end

    speak("No FX found")
    return true
end

------------------------------------------------------------
-- 2.15 - SINCRONIZZA FX VISIVO IN REAPER
--
-- Non apre finestre: prova solo a selezionare visivamente
-- l'FX corrente nella chain, utile per chi guarda lo schermo.
------------------------------------------------------------
function show_current_fx_for_sighted()
    local real_fx = get_current_real_fx_index()

    if real_fx == nil then
        return false
    end

    --------------------------------------------------------
    -- Take FX.
    --------------------------------------------------------
    if ctx.kind == "take" then
        if not ctx.take then
            return false
        end

        if not reaper.TakeFX_SetNamedConfigParm then
            return false
        end

        pcall(
            reaper.TakeFX_SetNamedConfigParm,
            ctx.take,
            real_fx,
            "chain_sel",
            tostring(real_fx)
        )

        return true
    end

    --------------------------------------------------------
    -- Track / Master FX.
    -- Monitor FX non supporta questa selezione visiva.
    --------------------------------------------------------
    if not ctx.track then
        return false
    end

    if not reaper.TrackFX_SetNamedConfigParm then
        return false
    end

    if selected_fx_is_monitor then
        return false
    end

    pcall(
        reaper.TrackFX_SetNamedConfigParm,
        ctx.track,
        real_fx,
        "chain_sel",
        tostring(real_fx)
    )

    return true
end

function show_current_fx_for_sighted_later()
    local wanted_fx_index = fx_index
    local wanted_real_fx = get_current_real_fx_index()

    local function later()
        if fx_index ~= wanted_fx_index then
            return
        end

        if get_current_real_fx_index() ~= wanted_real_fx then
            return
        end

        show_current_fx_for_sighted()
    end

    reaper.defer(later)
end

------------------------------------------------------------
-- 2.16 - NAVIGAZIONE CONTESTO: LEGACY DISATTIVATA
--
-- La vecchia navigazione Ctrl+Alt+frecce è stata sostituita
-- dalla navigazione moderna:
--
-- Ctrl + Page Up / Page Down = traccia precedente / successiva.
-- Ctrl + Left / Right        = item/take FX precedente / successivo.
--
-- Le funzioni operative moderne sono definite più avanti,
-- nella Parte 5 e richiamate dalla Parte 7 / Parte 8.
--
-- Questo blocco resta solo come separatore storico.
------------------------------------------------------------

------------------------------------------------------------
-- FINE PARTE 2 / 8
------------------------------------------------------------

------------------------------------------------------------
-- PARTE 3 / 8
-- PARAMETRI, LABEL, MEMORIE TXT PLUGIN,
-- CUSTOM ORDER, GRUPPI, SLOT
--
-- Stato:
-- - niente salvataggio nel progetto RPP;
-- - tutto lo stato persistente del plugin vive nel TXT;
-- - i vecchi wrapper "dual/project" restano solo per compatibilità;
-- - Custom order, gruppi, memorie parametro, last param,
--   last entry e last area sono tutti per plugin.
--
-- Custom order:
-- - una memoria Custom order per plugin;
-- - salvata nel TXT del plugin;
-- - toggle Plugin order <-> Custom order;
-- - All parameters, Groups e Search results seguono
--   l'ordine custom quando è attivo.
------------------------------------------------------------

------------------------------------------------------------
-- 3.1 - PARAM READ / WRITE
------------------------------------------------------------

------------------------------------------------------------
-- 3.1A - REAEQ PARAMETRI VIRTUALI
--
-- ReaEQ espone alcuni controlli di banda via named config parm,
-- non come normali parametri automatable.
--
-- Usiamo indici negativi per non confonderli con gli indici
-- reali restituiti da TrackFX_GetNumParams / TakeFX_GetNumParams.
------------------------------------------------------------
REAEQ_VIRTUAL_BASE = -100000

REAEQ_BAND_TYPE_NAMES = {
    [0]  = "Low shelf",
    [1]  = "High shelf",
    [2]  = "Band",
    [3]  = "Low pass",
    [4]  = "High pass",
    [5]  = "All pass",
    [6]  = "Notch",
    [7]  = "Band pass",
    [8]  = "Parallel band pass",
    [9]  = "Band alt",
    [10] = "Band alt 2"
}

REAEQ_BAND_TYPE_USER_TO_RAW = {
    [0]  = 0,
    [1]  = 1,
    [2]  = 8,
    [3]  = 3,
    [4]  = 4,
    [5]  = 5,
    [6]  = 6,
    [7]  = 7,
    [8]  = 10,
    [9]  = 9,
    [10] = 2
}

REAEQ_BAND_TYPE_RAW_TO_USER = {
    [0]  = 0,
    [1]  = 1,
    [8]  = 2,
    [3]  = 3,
    [4]  = 4,
    [5]  = 5,
    [6]  = 6,
    [7]  = 7,
    [10] = 8,
    [9]  = 9,
    [2]  = 10
}

REAEQ_BAND_TYPE_USER_MIN = 0
REAEQ_BAND_TYPE_USER_MAX = 10

------------------------------------------------------------
-- ReaEQ band action virtual controls.
--
-- These are virtual script parameters, not real REAPER
-- parameters:
--
--   ReaEQ Target Band:
--     0 = Add band
--     1..N = Band 1..N
--
--   ReaEQ Band Action:
--     momentary button.
--     If target is Add band, it adds a real ReaEQ band.
--     If target is Band N, it removes that real band from
--     the ReaEQ vst_chunk.
--
-- The add/remove is intentionally not a fake enable/disable.
-- It edits the ReaEQ chunk and verifies the real band count.
------------------------------------------------------------
REAEQ_ACTION_TARGET_INDEX = REAEQ_VIRTUAL_BASE + 2
REAEQ_ACTION_BUTTON_INDEX = REAEQ_VIRTUAL_BASE + 1

reaeq_action_target_band = 0
reaeq_action_cc_last_high = false

REAEQ_CHUNK_HEADER_SIZE = 8
REAEQ_CHUNK_BAND_SIZE   = 33
REAEQ_CHUNK_FOOTER_SIZE = 32

REAEQ_B64_CHARS =
    "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"

function reaeq_action_param_is_valid(i)
    i = tonumber(i)

    return
        i == REAEQ_ACTION_TARGET_INDEX or
        i == REAEQ_ACTION_BUTTON_INDEX
end

function reaeq_action_get_band_count()
    local count = 0

    if type(reaeq_get_band_count) == "function" then
        count = tonumber(reaeq_get_band_count()) or 0
    end

    return math.max(0, math.floor(count + 0.5))
end

function reaeq_action_get_target()
    local band_count = reaeq_action_get_band_count()

    reaeq_action_target_band =
        clamp_int(reaeq_action_target_band or 0, 0, band_count)

    return reaeq_action_target_band
end

function reaeq_action_set_target(v)
    local band_count = reaeq_action_get_band_count()

    reaeq_action_target_band =
        clamp_int(v, 0, band_count)

    return true
end

function reaeq_action_target_label()
    local target = reaeq_action_get_target()

    if target <= 0 then
        return "Add band"
    end

    return "Band " .. tostring(target)
end

function reaeq_action_button_label()
    local target = reaeq_action_get_target()

    if target <= 0 then
        return "Add Band"
    end

    return "Remove Band " .. tostring(target)
end

function reaeq_base64_decode(data)
    data = tostring(data or "")
    data = data:gsub("%s", "")

    local out = {}
    local buffer = 0
    local bits_collected = 0

    for i = 1, #data do
        local c = data:sub(i, i)

        if c == "=" then
            break
        end

        local value = REAEQ_B64_CHARS:find(c, 1, true)

        if value then
            value = value - 1
            buffer = buffer * 64 + value
            bits_collected = bits_collected + 6

            while bits_collected >= 8 do
                bits_collected = bits_collected - 8

                local byte =
                    math.floor(buffer / (2 ^ bits_collected)) % 256

                out[#out + 1] = string.char(byte)
                buffer = buffer % (2 ^ bits_collected)
            end
        end
    end

    return table.concat(out)
end

function reaeq_base64_encode(data)
    data = tostring(data or "")

    local out = {}
    local i = 1

    while i <= #data do
        local b1 = data:byte(i) or 0
        local b2 = data:byte(i + 1)
        local b3 = data:byte(i + 2)

        local n = b1 * 65536 + (b2 or 0) * 256 + (b3 or 0)

        local c1 = math.floor(n / 262144) % 64
        local c2 = math.floor(n / 4096) % 64
        local c3 = math.floor(n / 64) % 64
        local c4 = n % 64

        out[#out + 1] = REAEQ_B64_CHARS:sub(c1 + 1, c1 + 1)
        out[#out + 1] = REAEQ_B64_CHARS:sub(c2 + 1, c2 + 1)

        if b2 == nil then
            out[#out + 1] = "="
            out[#out + 1] = "="

        elseif b3 == nil then
            out[#out + 1] = REAEQ_B64_CHARS:sub(c3 + 1, c3 + 1)
            out[#out + 1] = "="

        else
            out[#out + 1] = REAEQ_B64_CHARS:sub(c3 + 1, c3 + 1)
            out[#out + 1] = REAEQ_B64_CHARS:sub(c4 + 1, c4 + 1)
        end

        i = i + 3
    end

    return table.concat(out)
end

function reaeq_chunk_le_u32(s, pos)
    local b1 = s:byte(pos)     or 0
    local b2 = s:byte(pos + 1) or 0
    local b3 = s:byte(pos + 2) or 0
    local b4 = s:byte(pos + 3) or 0

    return b1 + b2 * 256 + b3 * 65536 + b4 * 16777216
end

function reaeq_chunk_put_le_u32(n)
    n = math.floor((tonumber(n) or 0) + 0.5)

    local b1 = n % 256
    local b2 = math.floor(n / 256) % 256
    local b3 = math.floor(n / 65536) % 256
    local b4 = math.floor(n / 16777216) % 256

    return string.char(b1, b2, b3, b4)
end


function reaeq_chunk_put_le_double(v)
    v = tonumber(v)

    if v == nil then
        return nil
    end

    if string.pack then
        local ok, packed = pcall(string.pack, "<d", v)

        if ok and type(packed) == "string" and #packed == 8 then
            return packed
        end
    end

    return nil
end

function reaeq_chunk_get_le_double(s, pos)
    s = tostring(s or "")
    pos = tonumber(pos) or 1

    if string.unpack and #s >= (pos + 7) then
        local ok, value = pcall(string.unpack, "<d", s, pos)

        if ok then
            return tonumber(value)
        end
    end

    return nil
end

function reaeq_chunk_decode_model(chunk_b64)
    local bin = reaeq_base64_decode(chunk_b64)

    if #bin < (REAEQ_CHUNK_HEADER_SIZE + REAEQ_CHUNK_FOOTER_SIZE) then
        return nil, "ReaEQ chunk too short"
    end

    local magic = reaeq_chunk_le_u32(bin, 1)
    local band_count = reaeq_chunk_le_u32(bin, 5)

    local expected_len =
        REAEQ_CHUNK_HEADER_SIZE +
        (band_count * REAEQ_CHUNK_BAND_SIZE) +
        REAEQ_CHUNK_FOOTER_SIZE

    if expected_len ~= #bin then
        return nil,
            "Unexpected ReaEQ chunk length"
    end

    local model = {
        magic = magic,
        band_count = band_count,
        bands = {},
        footer = bin:sub(#bin - REAEQ_CHUNK_FOOTER_SIZE + 1)
    }

    for b = 1, band_count do
        local start_pos =
            REAEQ_CHUNK_HEADER_SIZE +
            ((b - 1) * REAEQ_CHUNK_BAND_SIZE) +
            1

        model.bands[b] =
            bin:sub(
                start_pos,
                start_pos + REAEQ_CHUNK_BAND_SIZE - 1
            )
    end

    return model, ""
end

function reaeq_chunk_encode_model(model)
    model = model or {}

    local band_count = #(model.bands or {})

    local parts = {
        reaeq_chunk_put_le_u32(model.magic or 33),
        reaeq_chunk_put_le_u32(band_count)
    }

    for i = 1, band_count do
        parts[#parts + 1] = model.bands[i]
    end

    parts[#parts + 1] =
        model.footer or string.rep("\0", REAEQ_CHUNK_FOOTER_SIZE)

    return reaeq_base64_encode(table.concat(parts))
end

function reaeq_chunk_default_band_block()
    --------------------------------------------------------
    -- Exact 33-byte block observed when ReaEQ GUI adds a
    -- default band:
    -- Enabled on, raw type 8 = Band, frequency 700 Hz,
    -- gain 0 dB, bandwidth 2.00.
    --------------------------------------------------------
    local bytes = {
        0x01, 0x08, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00,
        0x00, 0x00, 0xE0, 0x85, 0x40, 0x00, 0x00, 0x00,
        0x00, 0x00, 0x00, 0xF0, 0x3F, 0x00, 0x00, 0x00,
        0x00, 0x00, 0x00, 0x00, 0x40, 0x01, 0x00, 0x01,
        0x00
    }

    local out = {}

    for i = 1, #bytes do
        out[#out + 1] = string.char(bytes[i])
    end

    return table.concat(out)
end

function reaeq_chunk_write_and_verify(model, before_count, expected_count)
    local new_chunk = reaeq_chunk_encode_model(model)

    if not fx_set_named_config_parm("vst_chunk", new_chunk) then
        return false, "Cannot write ReaEQ chunk"
    end

    --------------------------------------------------------
    -- Touch a harmless value to encourage REAPER/ReaEQ to
    -- refresh the exposed parameter list immediately.
    --------------------------------------------------------
    if param_count > 0 then
        local v = get_param_value_norm(0)
        set_param_value_norm(0, v)
    end

    param_count = get_current_fx_param_count()

    local after_count = reaeq_get_band_count()

    if after_count == expected_count then
        return true, ""
    end

    return false,
        "ReaEQ band action failed. Before " ..
        tostring(before_count) ..
        ", after " ..
        tostring(after_count)
end

function reaeq_add_band_by_chunk()
    local ok, chunk = fx_get_named_config_parm("vst_chunk")

    if not ok or trim(chunk or "") == "" then
        return false, "Cannot read ReaEQ chunk"
    end

    local before_count = reaeq_get_band_count()
    local model, err = reaeq_chunk_decode_model(chunk)

    if not model then
        return false, err
    end

    model.bands[#model.bands + 1] = reaeq_chunk_default_band_block()

    local expected_count = before_count + 1
    local write_ok, write_msg =
        reaeq_chunk_write_and_verify(model, before_count, expected_count)

    if not write_ok then
        return false, write_msg
    end

    reaeq_action_target_band = expected_count

    return true, "Band added"
end

function reaeq_remove_band_by_chunk(target_band)
    target_band = clamp_int(target_band, 1, reaeq_get_band_count())

    local ok, chunk = fx_get_named_config_parm("vst_chunk")

    if not ok or trim(chunk or "") == "" then
        return false, "Cannot read ReaEQ chunk"
    end

    local before_count = reaeq_get_band_count()

    if before_count <= 1 then
        return false, "Cannot remove last band"
    end

    if target_band < 1 or target_band > before_count then
        return false, "Invalid band"
    end

    local model, err = reaeq_chunk_decode_model(chunk)

    if not model then
        return false, err
    end

    if #model.bands <= 1 then
        return false, "Cannot remove last band"
    end

    table.remove(model.bands, target_band)

    local expected_count = before_count - 1
    local write_ok, write_msg =
        reaeq_chunk_write_and_verify(model, before_count, expected_count)

    if not write_ok then
        return false, write_msg
    end

    reaeq_action_target_band =
        clamp_int(target_band, 0, expected_count)

    return true, "Band " .. tostring(target_band) .. " removed"
end

function reaeq_refresh_grid_after_band_action(preferred_param)
    preferred_param = tonumber(preferred_param)

    clear_filtered_param_context()

    param_count = get_current_fx_param_count()
    build_all_param_indices()

    if custom_order_active and
       type(apply_custom_order_to_all_params) == "function" then

        apply_custom_order_to_all_params()
        build_all_param_indices()
    end

    if preferred_param ~= nil and
       set_param_index_absolute(preferred_param, false) then

        save_current_param_position()
    else
        sync_param_from_active_pos()
        save_current_param_position()
    end

    refresh_window_title()
end

function reaeq_perform_band_action()
    local target = reaeq_action_get_target()
    local ok, msg

    if target <= 0 then
        ok, msg = reaeq_add_band_by_chunk()
    else
        ok, msg = reaeq_remove_band_by_chunk(target)
    end

    reaeq_refresh_grid_after_band_action(REAEQ_ACTION_BUTTON_INDEX)

    return ok == true, clean_one_line(msg or "")
end


function reaeq_band_type_user_to_raw(user_value)
    user_value = clamp_int(
        user_value,
        REAEQ_BAND_TYPE_USER_MIN,
        REAEQ_BAND_TYPE_USER_MAX
    )

    return REAEQ_BAND_TYPE_USER_TO_RAW[user_value] or 8
end

function reaeq_band_type_raw_to_user(raw_value)
    raw_value = math.floor((tonumber(raw_value) or 0) + 0.5)

    return REAEQ_BAND_TYPE_RAW_TO_USER[raw_value] or 2
end


function reaeq_band_type_api_write_is_blocked_user(user_value)
    user_value = math.floor((tonumber(user_value) or 0) + 0.5)

    --------------------------------------------------------
    -- ReaEQ special: questi tre tipi si leggono bene, ma
    -- TrackFX_SetEQParam non è affidabile per scrivere i tre
    -- parametri reali della banda. Non cambiamo mai BANDTYPE.
    --------------------------------------------------------
    return user_value == 5 or
           user_value == 9 or
           user_value == 10
end

function reaeq_band_type_api_write_is_blocked_raw(raw_value)
    return reaeq_band_type_api_write_is_blocked_user(
        reaeq_band_type_raw_to_user(raw_value)
    )
end

function reaeq_band_index_api_write_is_blocked(bandidx)
    bandidx = tonumber(bandidx)

    if bandidx == nil then
        return false
    end

    bandidx = math.floor(bandidx + 0.5)

    local ok, raw_value =
        fx_get_named_config_parm("BANDTYPE" .. tostring(bandidx))

    if not ok then
        return false
    end

    return reaeq_band_type_api_write_is_blocked_raw(raw_value)
end

function reaeq_param_api_write_is_blocked(i)
    if not reaeq_param_is_band_real or
       not reaeq_param_is_band_real(i) then

        return false
    end

    local ok, bandtype, bandidx, paramtype =
        reaeq_get_real_eq_param_info(i)

    if not ok then
        return false
    end

    return reaeq_band_index_api_write_is_blocked(bandidx)
end

function reaeq_param_frequency_api_write_is_blocked(i)
    return reaeq_param_is_frequency and
           reaeq_param_is_frequency(i) and
           reaeq_param_api_write_is_blocked and
           reaeq_param_api_write_is_blocked(i)
end

function fx_get_named_config_parm(name)
    name = tostring(name or "")

    if name == "" then
        return false, ""
    end

    local real_fx = get_current_real_fx_index()

    if real_fx == nil then
        return false, ""
    end

    --------------------------------------------------------
    -- Take FX.
    --------------------------------------------------------
    if ctx.kind == "take" then
        if ctx.take and reaper.TakeFX_GetNamedConfigParm then
            local ok, retval, value =
                pcall(
                    reaper.TakeFX_GetNamedConfigParm,
                    ctx.take,
                    real_fx,
                    name
                )

            if ok and retval then
                return true, tostring(value or "")
            end
        end

        return false, ""
    end

    --------------------------------------------------------
    -- Track / Master / Monitor FX.
    --------------------------------------------------------
    if ctx.track and reaper.TrackFX_GetNamedConfigParm then
        local ok, retval, value =
            pcall(
                reaper.TrackFX_GetNamedConfigParm,
                ctx.track,
                real_fx,
                name
            )

        if ok and retval then
            return true, tostring(value or "")
        end
    end

    return false, ""
end

function fx_set_named_config_parm(name, value)
    name = tostring(name or "")

    if name == "" then
        return false
    end

    local real_fx = get_current_real_fx_index()

    if real_fx == nil then
        return false
    end

    value = tostring(value or "")

    --------------------------------------------------------
    -- Take FX.
    --------------------------------------------------------
    if ctx.kind == "take" then
        if ctx.take and reaper.TakeFX_SetNamedConfigParm then
            local ok, retval =
                pcall(
                    reaper.TakeFX_SetNamedConfigParm,
                    ctx.take,
                    real_fx,
                    name,
                    value
                )

            return ok and retval == true
        end

        return false
    end

    --------------------------------------------------------
    -- Track / Master / Monitor FX.
    --------------------------------------------------------
    if ctx.track and reaper.TrackFX_SetNamedConfigParm then
        local ok, retval =
            pcall(
                reaper.TrackFX_SetNamedConfigParm,
                ctx.track,
                real_fx,
                name,
                value
            )

        return ok and retval == true
    end

    return false
end

function reaeq_make_virtual_index(band_zero, kind)
    band_zero = math.floor((tonumber(band_zero) or 0) + 0.5)
    kind = tostring(kind or "")

    local slot = 0

    if kind == "type" then
        slot = 1
    end

    return REAEQ_VIRTUAL_BASE - (band_zero * 2) - slot
end

function reaeq_decode_virtual_index(i)
    i = tonumber(i)

    if i == nil then
        return nil, ""
    end

    if i > REAEQ_VIRTUAL_BASE then
        return nil, ""
    end

    local n = REAEQ_VIRTUAL_BASE - i

    if n < 0 then
        return nil, ""
    end

    local band_zero = math.floor(n / 2)
    local slot = n % 2
    local kind = slot == 0 and "enabled" or "type"

    return band_zero, kind
end

function reaeq_get_band_count()
    if not is_current_fx_reaeq or not is_current_fx_reaeq() then
        return 0
    end

    local count = 0

    --------------------------------------------------------
    -- Se una banda esiste, almeno BANDENABLEDx o BANDTYPEx
    -- dovrebbe rispondere.
    --------------------------------------------------------
    for b = 0, 63 do
        local ok_enabled =
            fx_get_named_config_parm("BANDENABLED" .. tostring(b))

        local ok_type =
            fx_get_named_config_parm("BANDTYPE" .. tostring(b))

        if ok_enabled or ok_type then
            count = b + 1
        end
    end

    --------------------------------------------------------
    -- Fallback: ReaEQ di solito espone 3 parametri reali
    -- per banda: frequency, gain, bandwidth.
    --------------------------------------------------------
    if count <= 0 and param_count > 0 then
        count = math.floor(param_count / 3)
    end

    return count
end

function reaeq_virtual_param_is_valid(i)
    if reaeq_action_param_is_valid and
       reaeq_action_param_is_valid(i) then

        return is_current_fx_reaeq and is_current_fx_reaeq()
    end

    local band_zero, kind = reaeq_decode_virtual_index(i)

    if band_zero == nil then
        return false
    end

    if kind ~= "enabled" and kind ~= "type" then
        return false
    end

    local band_count = reaeq_get_band_count()

    return band_zero >= 0 and band_zero < band_count
end

function reaeq_get_virtual_param_name(i)
    if reaeq_action_param_is_valid and
       reaeq_action_param_is_valid(i) then

        if tonumber(i) == REAEQ_ACTION_TARGET_INDEX then
            return "ReaEQ Target Band"
        end

        if tonumber(i) == REAEQ_ACTION_BUTTON_INDEX then
            return reaeq_action_button_label()
        end
    end

    local band_zero, kind = reaeq_decode_virtual_index(i)

    if band_zero == nil then
        return ""
    end

    local band_num = band_zero + 1

    if kind == "enabled" then
        return "Band " .. tostring(band_num) .. " Enabled"
    end

    if kind == "type" then
        return "Band " .. tostring(band_num) .. " Type"
    end

    return ""
end

function reaeq_get_virtual_raw(i)
    if reaeq_action_param_is_valid and
       reaeq_action_param_is_valid(i) then

        if tonumber(i) == REAEQ_ACTION_TARGET_INDEX then
            return reaeq_action_get_target(), 0, reaeq_action_get_band_count()
        end

        if tonumber(i) == REAEQ_ACTION_BUTTON_INDEX then
            return 0, 0, 1
        end
    end

    local band_zero, kind = reaeq_decode_virtual_index(i)

    if band_zero == nil then
        return 0, 0, 1
    end

    if kind == "enabled" then
        local ok, value =
            fx_get_named_config_parm("BANDENABLED" .. tostring(band_zero))

        value = tonumber(value) or 0
        value = value >= 0.5 and 1 or 0

        return value, 0, 1
    end

    if kind == "type" then
        local ok, raw_value =
            fx_get_named_config_parm("BANDTYPE" .. tostring(band_zero))

        raw_value = tonumber(raw_value) or 0
        raw_value = math.floor(raw_value + 0.5)

        ----------------------------------------------------
        -- ReaEQ usa raw interni scombinati.
        -- Noi li convertiamo nella lista pubblica utente:
        --
        -- 0  Low shelf
        -- 1  High shelf
        -- 2  Band
        -- 3  Low pass
        -- 4  High pass
        -- 5  All pass
        -- 6  Notch
        -- 7  Band pass
        -- 8  Parallel band pass
        -- 9  Band alt
        -- 10 Band alt 2
        ----------------------------------------------------
        local user_value = reaeq_band_type_raw_to_user(raw_value)

        return
            user_value,
            REAEQ_BAND_TYPE_USER_MIN,
            REAEQ_BAND_TYPE_USER_MAX
    end

    return 0, 0, 1
end

function reaeq_get_virtual_norm(i)
    local value, minval, maxval = reaeq_get_virtual_raw(i)

    if maxval ~= minval then
        return clamp01((value - minval) / (maxval - minval))
    end

    return 0
end

function reaeq_set_virtual_raw(i, value)
    if reaeq_action_param_is_valid and
       reaeq_action_param_is_valid(i) then

        value = tonumber(value) or 0

        if tonumber(i) == REAEQ_ACTION_TARGET_INDEX then
            return reaeq_action_set_target(value)
        end

        if tonumber(i) == REAEQ_ACTION_BUTTON_INDEX then
            if value >= 0.5 then
                local ok, msg = reaeq_perform_band_action()

                if msg ~= "" then
                    speak_later(msg)
                end

                return ok
            end

            return true
        end
    end

    local band_zero, kind = reaeq_decode_virtual_index(i)

    if band_zero == nil then
        return false
    end

    value = tonumber(value) or 0

    if kind == "enabled" then
        value = value >= 0.5 and 1 or 0

        return fx_set_named_config_parm(
            "BANDENABLED" .. tostring(band_zero),
            tostring(value)
        )
    end

    if kind == "type" then
        local user_value = clamp_int(
            value,
            REAEQ_BAND_TYPE_USER_MIN,
            REAEQ_BAND_TYPE_USER_MAX
        )

        ----------------------------------------------------
        -- Lista utente -> raw reale ReaEQ.
        --
        -- Utente 2 = Band normale
        -- ma ReaEQ raw 2 = Band alt 2.
        -- Quindi Band normale deve andare a raw 8.
        ----------------------------------------------------
        local raw_value = reaeq_band_type_user_to_raw(user_value)

        return fx_set_named_config_parm(
            "BANDTYPE" .. tostring(band_zero),
            tostring(raw_value)
        )
    end

    return false
end

function reaeq_set_virtual_norm(i, v)
    if reaeq_action_param_is_valid and
       reaeq_action_param_is_valid(i) then

        v = clamp01(v)

        if tonumber(i) == REAEQ_ACTION_TARGET_INDEX then
            local count = reaeq_action_get_band_count()
            local raw = 0

            if count > 0 then
                raw = math.floor((v * count) + 0.5)
            end

            return reaeq_action_set_target(raw)
        end

        if tonumber(i) == REAEQ_ACTION_BUTTON_INDEX then
            local high = v >= 0.5
            local from_cc =
                (cc_runtime_busy == true) or
                (cc_focus_active == true)

            if from_cc then
                if high and not reaeq_action_cc_last_high then
                    reaeq_action_cc_last_high = true
                    local ok, msg = reaeq_perform_band_action()

                    if msg ~= "" then
                        speak_later(msg)
                    end

                    return ok

                elseif not high then
                    reaeq_action_cc_last_high = false
                end

                return true
            end

            if high then
                local ok, msg = reaeq_perform_band_action()

                if msg ~= "" then
                    speak_later(msg)
                end

                return ok
            end

            return true
        end
    end

    local band_zero, kind = reaeq_decode_virtual_index(i)

    if band_zero == nil then
        return false
    end

    v = clamp01(v)

    if kind == "enabled" then
        return reaeq_set_virtual_raw(i, v >= 0.5 and 1 or 0)
    end

if kind == "type" then
    local user_value =
        math.floor((v * REAEQ_BAND_TYPE_USER_MAX) + 0.5)

    user_value = clamp_int(
        user_value,
        REAEQ_BAND_TYPE_USER_MIN,
        REAEQ_BAND_TYPE_USER_MAX
    )

    return reaeq_set_virtual_raw(i, user_value)
end    

    return false
end

function reaeq_virtual_type_nudge(i, direction, big_step)
    local band_zero, kind = reaeq_decode_virtual_index(i)

    if band_zero == nil or kind ~= "type" then
        return false
    end

    direction = tonumber(direction) or 0

    if direction == 0 then
        return false
    end

    local current = reaeq_get_virtual_raw(i)
    current = clamp_int(
        current,
        REAEQ_BAND_TYPE_USER_MIN,
        REAEQ_BAND_TYPE_USER_MAX
    )

    local amount = 1

    if big_step then
        amount = get_discrete_step_amount(true)
    end

    local new_value =
        current + (direction > 0 and amount or -amount)

    new_value = clamp_int(
        new_value,
        REAEQ_BAND_TYPE_USER_MIN,
        REAEQ_BAND_TYPE_USER_MAX
    )

    if new_value == current then
        return true
    end

    reaeq_set_virtual_raw(i, new_value)

    save_current_param_position()
    speak_later(reaeq_get_virtual_formatted(i))

    return true
end

function reaeq_virtual_enabled_enter_current()
    --------------------------------------------------------
    -- ReaEQ Band Enabled: plain Enter toggle.
    --
    -- Do not write the virtual value manually here.
    -- Use the same absolute-value path used by the script
    -- for Home / End, so the behavior stays identical to
    -- the existing ReaEQ virtual control logic.
    --------------------------------------------------------
    if not reaeq_virtual_param_is_valid or
       not reaeq_virtual_param_is_valid(param_index) then

        return false
    end

    local band_zero, kind = reaeq_decode_virtual_index(param_index)

    if band_zero == nil or kind ~= "enabled" then
        return false
    end

    local current = reaeq_get_virtual_raw(param_index)
    current = tonumber(current) or 0

    --------------------------------------------------------
    -- Toggle by calling the same path used by Home/End:
    -- current On  -> Home/minimum -> Off
    -- current Off -> End/maximum   -> On
    --------------------------------------------------------
    local target = current >= 0.5 and 0 or 1

    if value_set_absolute_from_grid then
        value_set_absolute_from_grid(target)
        return true
    end

    return false
end


function reaeq_get_virtual_formatted(i)
    if reaeq_action_param_is_valid and
       reaeq_action_param_is_valid(i) then

        if tonumber(i) == REAEQ_ACTION_TARGET_INDEX then
            return reaeq_action_target_label()
        end

        if tonumber(i) == REAEQ_ACTION_BUTTON_INDEX then
            return "Ready"
        end
    end

    local band_zero, kind = reaeq_decode_virtual_index(i)

    if band_zero == nil then
        return ""
    end

    local value = reaeq_get_virtual_raw(i)

    if kind == "enabled" then
        return value >= 0.5 and "On" or "Off"
    end

    if kind == "type" then
        value = math.floor((tonumber(value) or 0) + 0.5)

        return REAEQ_BAND_TYPE_NAMES[value] or ("Type " .. tostring(value))
    end

    return ""
end

------------------------------------------------------------
-- ReaEQ real params: Frequency API only.
--
-- Gain / Global Gain / Bandwidth restano generici.
-- Per Frequency riusiamo solo l'API ReaEQ, perché la curva
-- generica 0..1 non risponde bene come cursore musicale.
--
-- Restano attivi anche i virtuali Band Enabled e Band Type.
------------------------------------------------------------

function reaeq_get_real_eq_param_info(i)
    i = tonumber(i)

    if i == nil then
        return false, nil, nil, nil, nil
    end

    if i < 0 or i > param_count - 1 then
        return false, nil, nil, nil, nil
    end

    if not is_current_fx_reaeq or not is_current_fx_reaeq() then
        return false, nil, nil, nil, nil
    end

    if not reaper.TrackFX_GetEQParam then
        return false, nil, nil, nil, nil
    end

    --------------------------------------------------------
    -- Per ora l'API reale di ReaEQ resta disponibile solo
    -- per Track FX. I Take FX continuano a comportarsi come
    -- plugin generici, evitando percorsi non testati.
    --------------------------------------------------------
    if ctx.kind == "take" then
        return false, nil, nil, nil, nil
    end

    if not ctx.track then
        return false, nil, nil, nil, nil
    end

    local real_fx = get_current_real_fx_index()

    if real_fx == nil then
        return false, nil, nil, nil, nil
    end

    local ok, retval, bandtype, bandidx, paramtype, normval =
        pcall(
            reaper.TrackFX_GetEQParam,
            ctx.track,
            real_fx,
            i
        )

    if not ok or not retval then
        return false, nil, nil, nil, nil
    end

    --------------------------------------------------------
    -- ReaEQ can report unstable band information after some
    -- band-type combinations, especially when band 1 is not a
    -- normal Band filter. The script grid, however, is built
    -- deterministically as three real parameters per band:
    -- Frequency, Gain, Bandwidth.
    --
    -- For real band parameters we therefore derive the band
    -- and parameter type from the actual FX parameter index.
    -- This prevents editing band 2 Gain from accidentally
    -- writing band 1 Gain when the API mapping is ambiguous.
    --------------------------------------------------------
    local band_count = 0

    if type(reaeq_get_band_count) == "function" then
        band_count = tonumber(reaeq_get_band_count()) or 0
    end

    if band_count > 0 and i >= 0 and i < (band_count * 3) then
        local stable_band = math.floor(i / 3)
        local stable_param = i - (stable_band * 3)

        local ok_type, raw_type =
            fx_get_named_config_parm("BANDTYPE" .. tostring(stable_band))

        raw_type = tonumber(raw_type)

        if ok_type and raw_type ~= nil then
            bandtype = raw_type
        end

        return true, bandtype, stable_band, stable_param, normval
    end

    return true, bandtype, bandidx, paramtype, normval
end

------------------------------------------------------------
-- ReaEQ real params: Frequency API only.
--
-- Dopo i problemi sul Global Gain, Gain / Global Gain /
-- Bandwidth restano generici come tutti gli altri plugin.
-- Riattiviamo solo la Frequency, perché il movimento generico
-- non segue bene la curva reale di ReaEQ.
------------------------------------------------------------

function reaeq_gain_db_to_raw(db)
    db = tonumber(db) or 0

    if db <= -149.5 then
        return 0
    end

    return 10 ^ (db / 20)
end

function reaeq_gain_raw_to_db(raw)
    raw = tonumber(raw) or 0

    if raw <= 0 then
        return -150
    end

    return 20 * math.log(raw, 10)
end

function reaeq_format_gain_db_from_raw(raw)
    local db = reaeq_gain_raw_to_db(raw)

    if db <= -149.5 then
        return "-inf dB"
    end

    if math.abs(db) < 0.05 then
        db = 0
    end

    local txt = string.format("%.1f", db)
    txt = txt:gsub("%.?0+$", "")

    return txt .. " dB"
end

function reaeq_param_is_global_gain(i)
    --------------------------------------------------------
    -- Solo Global Gain reale di ReaEQ.
    -- Non deve mai catturare i Gain delle bande, che ora
    -- sono gestiti dall'API ReaEQ tramite reaeq_param_is_gain().
    --------------------------------------------------------
    i = tonumber(i)

    if i == nil then
        return false
    end

    if not is_current_fx_reaeq or not is_current_fx_reaeq() then
        return false
    end

    if reaeq_virtual_param_is_valid and
       reaeq_virtual_param_is_valid(i) then

        return false
    end

    if reaeq_param_is_band_real and
       reaeq_param_is_band_real(i) then

        return false
    end

    local name = ""

    if type(get_param_original_name) == "function" then
        name = get_param_original_name(i)
    elseif type(get_param_name) == "function" then
        name = get_param_name(i)
    end

    name = clean_one_line(name or ""):lower()

    if name == "global gain" or
       name == "output gain" or
       name == "out gain" or
       name == "master gain" then

        return true
    end

    --------------------------------------------------------
    -- In alcune versioni ReaEQ il Global Gain può comparire
    -- semplicemente come "Gain" in coda ai parametri.
    -- I Gain delle bande sono già esclusi sopra.
    --------------------------------------------------------
    if name == "gain" then
        return true
    end

    return false
end

function reaeq_global_gain_db_to_raw(db)
    db = tonumber(db) or 0
    db = clamp(db, -150, 12)

    if db <= -149.5 then
        return 0
    end

    return 10 ^ (db / 20)
end

function reaeq_global_gain_raw_to_db(raw)
    raw = tonumber(raw) or 0

    if raw <= 0 then
        return -150
    end

    local db = 20 * math.log(raw, 10)
    db = clamp(db, -150, 12)

    if math.abs(db) < 0.0005 then
        db = 0
    end

    return db
end

function reaeq_get_global_gain_numeric_display_value(i)
    if not reaeq_param_is_global_gain or
       not reaeq_param_is_global_gain(i) then

        return nil
    end

    local raw = get_param_raw(i)
    local db = reaeq_global_gain_raw_to_db(raw)

    local txt = string.format("%.3f", db)
    txt = txt:gsub("%.?0+$", "")

    return txt
end

function reaeq_param_is_band_real(i)
    i = tonumber(i)

    if i == nil then
        return false
    end

    if not is_current_fx_reaeq or not is_current_fx_reaeq() then
        return false
    end

    if not reaeq_get_real_eq_param_info then
        return false
    end

    local ok, bandtype, bandidx, paramtype =
        reaeq_get_real_eq_param_info(i)

    if not ok then
        return false
    end

    bandidx = tonumber(bandidx)
    paramtype = tonumber(paramtype)

    if bandidx == nil or paramtype == nil then
        return false
    end

    local band_count = 0

    if type(reaeq_get_band_count) == "function" then
        band_count = tonumber(reaeq_get_band_count()) or 0
    end

    --------------------------------------------------------
    -- Protezione fondamentale:
    -- i parametri globali di ReaEQ finiscono in coda alla
    -- lista reale. Per non toccare mai il Global Gain,
    -- accettiamo solo i tre parametri reali interni alle
    -- bande: frequency, gain, bandwidth.
    --------------------------------------------------------
    if band_count > 0 then
        if bandidx < 0 or bandidx >= band_count then
            return false
        end

        if i < 0 or i >= (band_count * 3) then
            return false
        end
    else
        if bandidx < 0 then
            return false
        end
    end

    return paramtype >= 0 and paramtype <= 2
end

function reaeq_set_gain_db_by_feedback(i, target_db)
    --------------------------------------------------------
    -- Solo Gain delle bande.
    -- NON tocca il Global Gain.
    -- TrackFX_SetEQParam con isnorm=false vuole il guadagno
    -- lineare: 1 = 0 dB, 2 = +6 dB, 4 = +12 dB.
    --------------------------------------------------------
    if not reaeq_param_is_gain or not reaeq_param_is_gain(i) then
        return false
    end

    target_db = tonumber(target_db)

    if target_db == nil then
        return false
    end

    target_db = reaeq_clamp_gain_db(target_db)

    --------------------------------------------------------
    -- Prima prova sempre la strada chunk.
    -- Questo permette anche ai filtri normali di superare
    -- il limite pratico della manopola (+12 dB) e arrivare
    -- al limite numerico reale di ReaEQ (+36.1 dB).
    --------------------------------------------------------
    if reaeq_set_gain_db_by_chunk(i, target_db) then
        return true
    end

    return reaeq_set_eq_param_real_value(
        i,
        reaeq_gain_db_to_raw(target_db)
    )
end

function reaeq_param_type(i)
    if not is_current_fx_reaeq or not is_current_fx_reaeq() then
        return nil
    end

    if not reaeq_get_real_eq_param_info then
        return nil
    end

    local ok, bandtype, bandidx, paramtype =
        reaeq_get_real_eq_param_info(i)

    if not ok then
        return nil
    end

    return tonumber(paramtype)
end

function reaeq_param_is_frequency(i)
    return reaeq_param_is_band_real(i) and reaeq_param_type(i) == 0
end

function reaeq_param_is_gain(i)
    return reaeq_param_is_band_real(i) and reaeq_param_type(i) == 1
end

function reaeq_param_is_bandwidth(i)
    return reaeq_param_is_band_real(i) and reaeq_param_type(i) == 2
end

function reaeq_parse_first_number(txt)
    txt = tostring(txt or "")
    txt = txt:gsub(",", ".")

    local n = txt:match("[-+]?%d+%.?%d*")

    return tonumber(n)
end

function reaeq_parse_frequency_hz(txt)
    txt = clean_one_line(txt or "")
    local lower = txt:lower():gsub(",", ".")
    local n = reaeq_parse_first_number(lower)

    if n == nil then
        return nil
    end

    --------------------------------------------------------
    -- ReaEQ può formattare come "1000 Hz" oppure "1 kHz".
    -- Ctrl+E invece deve ricevere sempre Hz reali.
    --------------------------------------------------------
    if lower:find("khz", 1, true) then
        n = n * 1000
    end

    return n
end

function reaeq_get_numeric_display_value(i)
    --------------------------------------------------------
    -- Frequency: Ctrl+E parte da Hz reali.
    --------------------------------------------------------
    if reaeq_param_is_frequency and reaeq_param_is_frequency(i) then
        local formatted = get_param_value_formatted(i)
        local n = reaeq_parse_frequency_hz(formatted)

        if n ~= nil then
            local txt = string.format("%.3f", n)
            txt = txt:gsub("%.?0+$", "")
            return txt
        end
    end

    --------------------------------------------------------
    -- Gain delle bande: Ctrl+E parte dai dB parlati dal VST.
    -- Il Global Gain non arriva qui perché reaeq_param_is_gain()
    -- lo esclude esplicitamente.
    --------------------------------------------------------
    if reaeq_param_is_gain and reaeq_param_is_gain(i) then
        local formatted = get_param_value_formatted(i)
        local n = reaeq_parse_first_number(formatted)

        if n ~= nil then
            if math.abs(n) < 0.05 then
                n = 0
            end

            local txt = string.format("%.1f", n)
            txt = txt:gsub("%.?0+$", "")
            return txt
        end
    end

    --------------------------------------------------------
    -- Bandwidth / Q delle bande: valore reale/formattato.
    --------------------------------------------------------
    if reaeq_param_is_bandwidth and reaeq_param_is_bandwidth(i) then
        local formatted = get_param_value_formatted(i)
        local n = reaeq_parse_first_number(formatted)

        if n ~= nil then
            local txt = string.format("%.3f", n)
            txt = txt:gsub("%.?0+$", "")
            return txt
        end
    end

    local value = get_param_raw(i)
    return tostring(value)
end


function reaeq_format_param_value_normalized(i, norm)
    i = tonumber(i) or 0
    norm = clamp01(norm)

    local real_fx = get_current_real_fx_index()

    if real_fx == nil then
        return ""
    end

    local ok, retval, value

    if ctx.kind == "take" then
        if not ctx.take or not reaper.TakeFX_FormatParamValueNormalized then
            return ""
        end

        ok, retval, value =
            pcall(
                reaper.TakeFX_FormatParamValueNormalized,
                ctx.take,
                real_fx,
                i,
                norm,
                ""
            )
    else
        if not ctx.track or not reaper.TrackFX_FormatParamValueNormalized then
            return ""
        end

        ok, retval, value =
            pcall(
                reaper.TrackFX_FormatParamValueNormalized,
                ctx.track,
                real_fx,
                i,
                norm,
                ""
            )
    end

    if ok and retval then
        return clean_one_line(value or "")
    end

    return ""
end

REAEQ_BANDWIDTH_REAL_MIN = 0.01
REAEQ_BANDWIDTH_REAL_MAX = 4.0

REAEQ_GAIN_REAL_MIN_DB = -150
REAEQ_GAIN_REAL_MAX_DB = 36.1

function reaeq_clamp_gain_db(v)
    return clamp(v, REAEQ_GAIN_REAL_MIN_DB, REAEQ_GAIN_REAL_MAX_DB)
end

function reaeq_clamp_bandwidth_real(v)
    return clamp(v, REAEQ_BANDWIDTH_REAL_MIN, REAEQ_BANDWIDTH_REAL_MAX)
end

function reaeq_bandwidth_norm_to_display_number(i, norm)
    local formatted = reaeq_format_param_value_normalized(i, norm)
    local n = reaeq_parse_first_number(formatted)

    if n ~= nil then
        return n
    end

    return nil
end

function reaeq_bandwidth_real_to_norm(i, target_bw)
    --------------------------------------------------------
    -- Bandwidth/Q su ReaEQ non accetta sempre il valore reale
    -- tramite la strada API/chunk nei tre tipi problematici.
    -- Qui troviamo il normalizzato che ReaEQ formatterebbe come
    -- valore reale desiderato, senza cambiare Type e senza toccare
    -- Frequency/Gain.
    --------------------------------------------------------
    target_bw = tonumber(target_bw)

    if target_bw == nil then
        return nil
    end

    target_bw = reaeq_clamp_bandwidth_real(target_bw)

    local lo = 0
    local hi = 1
    local best_norm = nil
    local best_err = nil

    for step = 1, 32 do
        local mid = (lo + hi) * 0.5
        local shown = reaeq_bandwidth_norm_to_display_number(i, mid)

        if shown == nil then
            break
        end

        local err = math.abs(shown - target_bw)

        if best_err == nil or err < best_err then
            best_err = err
            best_norm = mid
        end

        if shown < target_bw then
            lo = mid
        else
            hi = mid
        end
    end

    if best_norm ~= nil then
        return clamp01(best_norm)
    end

    --------------------------------------------------------
    -- Fallback semplice osservato: 0.5 circa = 2, 1 circa = 4.
    -- Serve solo se FormatParamValueNormalized non risponde.
    --------------------------------------------------------
    return clamp01(target_bw / 4)
end

function reaeq_set_bandwidth_real_by_normalized(i, bw)
    if not reaeq_param_is_bandwidth or
       not reaeq_param_is_bandwidth(i) then

        return false
    end

    local norm = reaeq_bandwidth_real_to_norm(i, bw)

    if norm == nil then
        return false
    end

    set_param_value_norm(i, norm)

    return true
end

function reaeq_set_bandwidth_real_by_chunk_alt(i, bw)
    --------------------------------------------------------
    -- Fallback CHUNK solo Bandwidth/campana per i tre tipi
    -- problematici: All pass, Band alt, Band alt 2.
    --
    -- Questa versione non indovina più un offset fisso.
    -- Prima legge il valore attuale della campana dal VST,
    -- poi cerca dentro il blocco binario della banda il double
    -- che contiene proprio quel valore. Solo quel double viene
    -- sostituito. Frequency e Gain non vengono toccati.
    --------------------------------------------------------
    if not reaeq_param_is_bandwidth or
       not reaeq_param_is_bandwidth(i) then

        return false
    end

    bw = tonumber(bw)

    if bw == nil then
        return false
    end

    bw = reaeq_clamp_bandwidth_real(bw)

    local current_bw = nil

    if type(reaeq_get_bandwidth_for_nudge) == "function" then
        current_bw = reaeq_get_bandwidth_for_nudge(i)
    end

    if current_bw == nil then
        local formatted = get_param_value_formatted(i)
        current_bw = reaeq_parse_first_number(formatted)
    end

    current_bw = tonumber(current_bw)

    local ok_info, bandtype, bandidx, paramtype =
        reaeq_get_real_eq_param_info(i)

    if not ok_info then
        return false
    end

    bandidx = tonumber(bandidx)
    paramtype = tonumber(paramtype)

    if bandidx == nil or paramtype ~= 2 then
        return false
    end

    bandidx = math.floor(bandidx + 0.5)

    local ok_chunk, chunk = fx_get_named_config_parm("vst_chunk")

    if not ok_chunk or trim(chunk or "") == "" then
        return false
    end

    local model, err = reaeq_chunk_decode_model(chunk)

    if not model then
        return false
    end

    local band_number = bandidx + 1

    if not model.bands or not model.bands[band_number] then
        return false
    end

    local band = model.bands[band_number]

    if #band ~= REAEQ_CHUNK_BAND_SIZE then
        return false
    end

    local packed = reaeq_chunk_put_le_double(bw)

    if not packed then
        return false
    end

    --------------------------------------------------------
    -- Cerca il campo della campana.
    -- Preferiamo la parte finale del blocco, così evitiamo
    -- di scambiare per campana il Gain quando entrambi valgono
    -- 1.0 o valori simili.
    --------------------------------------------------------
    local best_pos = nil
    local best_err = nil

    if current_bw ~= nil then
        for pos = 22, 26 do
            local v = reaeq_chunk_get_le_double(band, pos)

            if v ~= nil and v > 0 and v <= 4 then
                local e = math.abs(v - current_bw)

                if best_err == nil or e < best_err then
                    best_err = e
                    best_pos = pos
                end
            end
        end

        if best_err == nil or best_err > 0.0005 then
            for pos = 1, 26 do
                local v = reaeq_chunk_get_le_double(band, pos)

                if v ~= nil and v > 0 and v <= 4 then
                    local e = math.abs(v - current_bw)

                    if best_err == nil or e < best_err then
                        best_err = e
                        best_pos = pos
                    end
                end
            end
        end
    end

    --------------------------------------------------------
    -- Fallback: le due posizioni più probabili viste nei test.
    -- 25 è la posizione della struttura usata dalla 0.247/0.248;
    -- 22 è la posizione del blocco ReaEQ classico osservato nei
    -- default chunk. Se il valore attuale non ci ha permesso di
    -- scegliere, proviamo prima la strada già coerente con Frequency
    -- e Gain funzionanti.
    --------------------------------------------------------
    if best_pos == nil then
        best_pos = 25
    end

    if best_pos < 1 or best_pos > 26 then
        return false
    end

    local new_band =
        band:sub(1, best_pos - 1) ..
        packed ..
        band:sub(best_pos + 8)

    if new_band == band then
        return true
    end

    model.bands[band_number] = new_band

    local new_chunk = reaeq_chunk_encode_model(model)

    if not fx_set_named_config_parm("vst_chunk", new_chunk) then
        return false
    end

    if reaper.TrackList_AdjustWindows then
        reaper.TrackList_AdjustWindows(false)
    end

    return true
end

function reaeq_get_bandwidth_for_nudge(i)
    local formatted = get_param_value_formatted(i)
    local bw = reaeq_parse_first_number(formatted)

    if bw ~= nil then
        return reaeq_clamp_bandwidth_real(bw)
    end

    local raw = get_param_raw(i)
    raw = tonumber(raw)

    if raw ~= nil then
        return reaeq_clamp_bandwidth_real(raw)
    end

    return nil
end

function reaeq_bandwidth_nudge_chunk_alt(direction, big_step)
    if not reaeq_param_is_bandwidth or
       not reaeq_param_is_bandwidth(param_index) then

        return false
    end

    direction = tonumber(direction) or 0

    if direction == 0 then
        return false
    end

    local bw = reaeq_get_bandwidth_for_nudge(param_index)

    if bw == nil then
        return false
    end

    local scale = get_step_scale()
    local delta = big_step and 0.25 or 0.05
    delta = delta * (tonumber(scale) or 1)

    if delta <= 0 then
        delta = big_step and 0.25 or 0.05
    end

    local new_bw = reaeq_clamp_bandwidth_real(bw + (delta * direction))

    --------------------------------------------------------
    -- Vicino ai bordi reali di ReaEQ, evita valori formali
    -- intermedi non utili: se il passo scende sotto 0.01,
    -- resta esattamente a 0.01; se sale oltre 4.0, resta
    -- esattamente a 4.0.
    --------------------------------------------------------
    if direction < 0 and new_bw <= REAEQ_BANDWIDTH_REAL_MIN then
        new_bw = REAEQ_BANDWIDTH_REAL_MIN
    elseif direction > 0 and new_bw >= REAEQ_BANDWIDTH_REAL_MAX then
        new_bw = REAEQ_BANDWIDTH_REAL_MAX
    end

    if not reaeq_set_bandwidth_real_by_chunk_alt(param_index, new_bw) then
        return false
    end

    disarm_slot_deletes()
    clear_param_memory_arm()
    save_current_param_position()

    speak_later(get_param_value_formatted(param_index))

    return true
end


function reaeq_bandwidth_nudge_limited(direction, big_step)
    --------------------------------------------------------
    -- Bandwidth/campana ReaEQ: range reale utile uniforme
    -- per tutti i filtri, non solo per All pass/Band alt:
    -- minimo 0.01, massimo 4.0.
    --------------------------------------------------------
    if not reaeq_param_is_bandwidth or
       not reaeq_param_is_bandwidth(param_index) then

        return false
    end

    direction = tonumber(direction) or 0

    if direction == 0 then
        return false
    end

    local bw = reaeq_get_bandwidth_for_nudge(param_index)

    if bw == nil then
        return false
    end

    local scale = get_step_scale()
    local delta = big_step and 0.25 or 0.05
    delta = delta * (tonumber(scale) or 1)

    if delta <= 0 then
        delta = big_step and 0.25 or 0.05
    end

    local new_bw = reaeq_clamp_bandwidth_real(bw + (delta * direction))

    if direction < 0 and new_bw <= REAEQ_BANDWIDTH_REAL_MIN then
        new_bw = REAEQ_BANDWIDTH_REAL_MIN
    elseif direction > 0 and new_bw >= REAEQ_BANDWIDTH_REAL_MAX then
        new_bw = REAEQ_BANDWIDTH_REAL_MAX
    end

    local ok = reaeq_set_bandwidth_real_by_chunk_alt(param_index, new_bw)

    if not ok then
        return false
    end

    disarm_slot_deletes()
    clear_param_memory_arm()
    save_current_param_position()

    speak_later(get_param_value_formatted(param_index))

    return true
end

function reaeq_bandwidth_set_absolute_limited(v)
    --------------------------------------------------------
    -- Home/End per tutte le larghezze di banda ReaEQ:
    -- Home = 0.01, End = 4.0.
    --------------------------------------------------------
    if not reaeq_param_is_bandwidth or
       not reaeq_param_is_bandwidth(param_index) then

        return false
    end

    v = clamp01(v)

    local bw = v <= 0 and REAEQ_BANDWIDTH_REAL_MIN or REAEQ_BANDWIDTH_REAL_MAX
    local ok = reaeq_set_bandwidth_real_by_chunk_alt(param_index, bw)

    if not ok then
        return false
    end

    disarm_slot_deletes()
    clear_param_memory_arm()
    save_current_param_position()
    announce_value_only()

    return true
end

function reaeq_format_band_value_with_units(i, formatted)
    --------------------------------------------------------
    -- Solo per i parametri reali delle bande ReaEQ.
    -- Non tocca Global Gain, perché reaeq_param_is_gain()
    -- e reaeq_param_is_frequency() escludono i parametri globali.
    --------------------------------------------------------
    formatted = clean_one_line(formatted or "")

    if formatted == "" then
        return ""
    end

    if reaeq_param_is_frequency and reaeq_param_is_frequency(i) then
        local hz = reaeq_parse_frequency_hz(formatted)

        if hz ~= nil then
            if math.abs(hz) < 0.0005 then
                hz = 0
            end

            return string.format("%.1f", hz) .. " Hz"
        end
    end

    if reaeq_param_is_gain and reaeq_param_is_gain(i) then
        local db = reaeq_parse_first_number(formatted)

        if db ~= nil then
            if math.abs(db) < 0.05 then
                db = 0
            end

            return string.format("%.1f", db) .. " dB"
        end
    end

    return formatted
end



function reaeq_set_band_real_value_by_chunk(i, real_value)
    --------------------------------------------------------
    -- Scrittura CHUNK per i parametri reali delle bande ReaEQ.
    -- Serve per superare i limiti pratici della manopola/API:
    -- paramtype 0 = Frequency, 1 = Gain lineare, 2 = Bandwidth.
    -- Non scrive mai BANDTYPE e non cambia mai il filtro.
    --------------------------------------------------------
    if not reaeq_param_is_band_real or
       not reaeq_param_is_band_real(i) then

        return false
    end

    real_value = tonumber(real_value)

    if real_value == nil then
        return false
    end

    local ok_info, bandtype, bandidx, paramtype =
        reaeq_get_real_eq_param_info(i)

    if not ok_info then
        return false
    end

    bandidx = tonumber(bandidx)
    paramtype = tonumber(paramtype)

    if bandidx == nil or paramtype == nil then
        return false
    end

    bandidx = math.floor(bandidx + 0.5)
    paramtype = math.floor(paramtype + 0.5)

    if paramtype < 0 or paramtype > 2 then
        return false
    end

    if paramtype == 0 then
        real_value = clamp(real_value, 20, 24000)
    elseif paramtype == 1 then
        real_value = clamp(real_value, 0, 64)
    elseif paramtype == 2 then
        real_value = reaeq_clamp_bandwidth_real(real_value)
    end

    local ok_chunk, chunk = fx_get_named_config_parm("vst_chunk")

    if not ok_chunk or trim(chunk or "") == "" then
        return false
    end

    local model, err = reaeq_chunk_decode_model(chunk)

    if not model then
        return false
    end

    local band_number = bandidx + 1

    if not model.bands or not model.bands[band_number] then
        return false
    end

    local band = model.bands[band_number]

    if #band ~= REAEQ_CHUNK_BAND_SIZE then
        return false
    end

    local packed = reaeq_chunk_put_le_double(real_value)

    if not packed then
        return false
    end

    local start_pos = 9 + (paramtype * 8)
    local end_pos = start_pos + 7

    local new_band =
        band:sub(1, start_pos - 1) ..
        packed ..
        band:sub(end_pos + 1)

    if new_band == band then
        return true
    end

    model.bands[band_number] = new_band

    local new_chunk = reaeq_chunk_encode_model(model)

    if not fx_set_named_config_parm("vst_chunk", new_chunk) then
        return false
    end

    if reaper.TrackList_AdjustWindows then
        reaper.TrackList_AdjustWindows(false)
    end

    return true
end

function reaeq_set_gain_db_by_chunk(i, db)
    if not reaeq_param_is_gain or
       not reaeq_param_is_gain(i) then

        return false
    end

    db = tonumber(db)

    if db == nil then
        return false
    end

    db = reaeq_clamp_gain_db(db)

    return reaeq_set_band_real_value_by_chunk(
        i,
        reaeq_gain_db_to_raw(db)
    )
end

function reaeq_get_gain_db_for_nudge(i)
    local formatted = get_param_value_formatted(i)
    local db = reaeq_parse_first_number(formatted)

    if db ~= nil then
        return reaeq_clamp_gain_db(db)
    end

    local raw = get_param_raw(i)
    raw = tonumber(raw)

    if raw ~= nil then
        return reaeq_clamp_gain_db(reaeq_gain_raw_to_db(raw))
    end

    return nil
end

function reaeq_gain_nudge_chunk_direct(direction, big_step)
    --------------------------------------------------------
    -- Gain delle bande ReaEQ in dB reali.
    -- Non usa più il movimento normalizzato della manopola,
    -- perché la manopola pratica si ferma circa a +12 dB
    -- mentre ReaEQ accetta valori numerici fino a +36.1 dB.
    -- Per i tre tipi problematici usa il chunk; per gli altri
    -- lascia lavorare reaeq_set_gain_db_by_feedback().
    --------------------------------------------------------
    if not reaeq_param_is_gain or
       not reaeq_param_is_gain(param_index) then

        return false
    end

    direction = tonumber(direction) or 0

    if direction == 0 then
        return false
    end

    local db = reaeq_get_gain_db_for_nudge(param_index)

    if db == nil then
        return false
    end

    local scale = get_step_scale()

    --------------------------------------------------------
    -- ReaEQ Gain step in dB reali.
    -- Normal ora vale circa 1 dB con Alt+Up/Down.
    -- Prima Normal valeva circa 0.1 dB e serviva Step 10x
    -- per ottenere il movimento musicale da 1 dB.
    --------------------------------------------------------
    local delta = big_step and 10.0 or 1.0
    delta = delta * (tonumber(scale) or 1)

    if delta <= 0 then
        delta = big_step and 10.0 or 1.0
    end

    local new_db = reaeq_clamp_gain_db(db + (delta * direction))

    --------------------------------------------------------
    -- Quando il gain è a -inf / -150 dB, un passo di 0.1 dB
    -- resta praticamente sul fondo e può sembrare bloccato.
    -- Il primo movimento verso l'alto lo porta a un valore
    -- realmente modificabile, poi i passi normali riprendono.
    --------------------------------------------------------
    if db <= (REAEQ_GAIN_REAL_MIN_DB + 0.1) and direction > 0 then
        new_db = big_step and -36.0 or -60.0
    end

    if not reaeq_set_gain_db_by_feedback(param_index, new_db) then
        return false
    end

    disarm_slot_deletes()
    clear_param_memory_arm()
    save_current_param_position()

    speak_later(get_param_value_formatted(param_index))

    return true
end

function reaeq_set_frequency_hz_by_chunk(i, hz)
    --------------------------------------------------------
    -- Fallback sperimentale SOLO Frequency, SOLO per i tre
    -- tipi in cui l'API ReaEQ blocca lo slider:
    -- All pass, Band alt, Band alt 2.
    -- Non scrive mai BANDTYPE e non tocca Gain/Bandwidth.
    --------------------------------------------------------
    hz = tonumber(hz)

    if hz == nil then
        return false
    end

    hz = clamp(hz, 20, 24000)

    local ok_info, bandtype, bandidx, paramtype =
        reaeq_get_real_eq_param_info(i)

    if not ok_info then
        return false
    end

    bandidx = tonumber(bandidx)
    paramtype = tonumber(paramtype)

    if bandidx == nil or paramtype ~= 0 then
        return false
    end

    bandidx = math.floor(bandidx + 0.5)

    local ok_chunk, chunk = fx_get_named_config_parm("vst_chunk")

    if not ok_chunk or trim(chunk or "") == "" then
        return false
    end

    local model, err = reaeq_chunk_decode_model(chunk)

    if not model then
        return false
    end

    local band_number = bandidx + 1

    if not model.bands or not model.bands[band_number] then
        return false
    end

    local band = model.bands[band_number]

    if #band ~= REAEQ_CHUNK_BAND_SIZE then
        return false
    end

    local packed = reaeq_chunk_put_le_double(hz)

    if not packed then
        return false
    end

    --------------------------------------------------------
    -- Struttura blocco ReaEQ 33 byte:
    -- byte 1      enabled
    -- byte 2      raw band type
    -- byte 9..16  frequency double LE
    -- byte 17..24 gain double LE
    -- byte 25..32 bandwidth double LE
    -- byte 33     reserved/flag
    --------------------------------------------------------
    local new_band =
        band:sub(1, 8) ..
        packed ..
        band:sub(17)

    if new_band == band then
        return true
    end

    model.bands[band_number] = new_band

    local new_chunk = reaeq_chunk_encode_model(model)

    if not fx_set_named_config_parm("vst_chunk", new_chunk) then
        return false
    end

    --------------------------------------------------------
    -- Piccolo refresh non distruttivo: non cambia Type e non
    -- scrive sugli altri due parametri della banda.
    --------------------------------------------------------
    if reaper.TrackList_AdjustWindows then
        reaper.TrackList_AdjustWindows(false)
    end

    return true
end

function reaeq_get_frequency_hz_for_nudge(i)
    local formatted = get_param_value_formatted(i)
    local hz = reaeq_parse_frequency_hz(formatted)

    if hz ~= nil then
        return clamp(hz, 20, 24000)
    end

    local value = get_param_raw(i)
    value = tonumber(value)

    if value ~= nil and value >= 20 and value <= 24000 then
        return value
    end

    return nil
end

function reaeq_frequency_hz_to_log_norm(hz)
    hz = clamp(hz, 20, 24000)
    return clamp01(math.log(hz / 20) / math.log(24000 / 20))
end

function reaeq_frequency_log_norm_to_hz(norm)
    norm = clamp01(norm)
    return 20 * ((24000 / 20) ^ norm)
end

function reaeq_frequency_nudge_chunk_direct(direction, big_step)
    direction = tonumber(direction) or 0

    if direction == 0 then
        return false
    end

    local hz = reaeq_get_frequency_hz_for_nudge(param_index)

    if hz == nil then
        return false
    end

    local arrow_step, page_step = get_param_steps(param_index)
    local scale = get_step_scale()
    local step = big_step and page_step or arrow_step

    step = (tonumber(step) or 0.001) * scale

    if step <= 0 then
        step = big_step and 0.02 or 0.001
    end

    if step > 1 then
        step = 1
    end

    local old_norm = reaeq_frequency_hz_to_log_norm(hz)
    local new_norm = clamp01(old_norm + (step * direction))
    local new_hz = reaeq_frequency_log_norm_to_hz(new_norm)

    if not reaeq_set_frequency_hz_by_chunk(param_index, new_hz) then
        return false
    end

    disarm_slot_deletes()
    clear_param_memory_arm()
    save_current_param_position()

    speak_later(get_param_value_formatted(param_index))

    return true
end

function reaeq_set_eq_param_real_value(i, real_value)
    --------------------------------------------------------
    -- API reale solo sui parametri di banda:
    -- Frequency, Gain di banda, Bandwidth.
    -- Global Gain resta fuori.
    --
    -- Fix ReaEQ 0.283:
    -- Frequency e Bandwidth NON passano più da
    -- TrackFX_SetEQParam. Su molti Type quella API può
    -- indirizzare la banda sbagliata. Per questi due campi
    -- usiamo sempre il chunk della banda assoluta della griglia.
    -- Gain resta nella strada precedente.
    --------------------------------------------------------
    if not reaeq_param_is_band_real or
       not reaeq_param_is_band_real(i) then

        return false
    end

    local ok, bandtype, bandidx, paramtype =
        reaeq_get_real_eq_param_info(i)

    if not ok then
        return false
    end

    real_value = tonumber(real_value)

    if real_value == nil then
        return false
    end

    paramtype = tonumber(paramtype)

    --------------------------------------------------------
    -- Frequency e Bandwidth: sempre chunk, mai SetEQParam.
    --------------------------------------------------------
    if paramtype == 0 or paramtype == 2 then
        return reaeq_set_band_real_value_by_chunk(i, real_value)
    end

    if not reaper.TrackFX_SetEQParam then
        return false
    end

    if ctx.kind == "take" then
        return false
    end

    if not ctx.track then
        return false
    end

    local real_fx = get_current_real_fx_index()

    if real_fx == nil then
        return false
    end

    if reaeq_band_index_api_write_is_blocked and
       reaeq_band_index_api_write_is_blocked(bandidx) then

        return reaeq_set_band_real_value_by_chunk(i, real_value)
    end

    local ok_set, retval =
        pcall(
            reaper.TrackFX_SetEQParam,
            ctx.track,
            real_fx,
            bandtype,
            bandidx,
            paramtype,
            real_value,
            false
        )

    return ok_set and retval == true
end

function reaeq_set_eq_param_normalized_value(i, norm_value)
    --------------------------------------------------------
    -- Movimento normalizzato via API solo per parametri di banda.
    -- Global Gain resta fuori.
    --
    -- Fix ReaEQ 0.283:
    -- Frequency e Bandwidth vengono tradotti in valore reale
    -- e scritti nel chunk della banda assoluta. Questo evita
    -- il bug dei Type in cui SetEQParam muove una banda vicina.
    --------------------------------------------------------
    if not reaeq_param_is_band_real or
       not reaeq_param_is_band_real(i) then

        return false
    end

    local ok, bandtype, bandidx, paramtype =
        reaeq_get_real_eq_param_info(i)

    if not ok then
        return false
    end

    norm_value = clamp01(norm_value)
    paramtype = tonumber(paramtype)

    if paramtype == 0 then
        return reaeq_set_band_real_value_by_chunk(
            i,
            reaeq_frequency_log_norm_to_hz(norm_value)
        )
    end

    if paramtype == 2 then
        local bw = nil

        if type(reaeq_bandwidth_norm_to_display_number) == "function" then
            bw = reaeq_bandwidth_norm_to_display_number(i, norm_value)
        end

        if bw == nil then
            bw = REAEQ_BANDWIDTH_REAL_MIN +
                 ((REAEQ_BANDWIDTH_REAL_MAX - REAEQ_BANDWIDTH_REAL_MIN) * norm_value)
        end

        return reaeq_set_band_real_value_by_chunk(
            i,
            reaeq_clamp_bandwidth_real(bw)
        )
    end

    if not reaper.TrackFX_SetEQParam then
        return false
    end

    if ctx.kind == "take" then
        return false
    end

    if not ctx.track then
        return false
    end

    local real_fx = get_current_real_fx_index()

    if real_fx == nil then
        return false
    end

    if reaeq_band_index_api_write_is_blocked and
       reaeq_band_index_api_write_is_blocked(bandidx) then

        return false
    end

    local ok_set, retval =
        pcall(
            reaper.TrackFX_SetEQParam,
            ctx.track,
            real_fx,
            bandtype,
            bandidx,
            paramtype,
            norm_value,
            true
        )

    return ok_set and retval == true
end

function reaeq_band_param_nudge_direct(direction, big_step)
    if not reaeq_param_is_band_real or
       not reaeq_param_is_band_real(param_index) then

        return false
    end

    direction = tonumber(direction) or 0

    if direction == 0 then
        return false
    end

    local old_v = get_param_value_norm(param_index)
    local old_fmt = get_param_value_formatted(param_index)

    local arrow_step, page_step = get_param_steps(param_index)
    local scale = get_step_scale()
    local step = big_step and page_step or arrow_step

    step = (tonumber(step) or 0.001) * scale

    if step <= 0 then
        step = big_step and 0.02 or 0.001
    end

    if step > 1 then
        step = 1
    end

    --------------------------------------------------------
    -- Gain delle bande ReaEQ:
    -- deve usare SEMPRE il movimento diretto in dB prima
    -- del controllo new_v == old_v.
    -- La manopola normalizzata di ReaEQ può essere già al
    -- massimo pratico intorno a +12 dB, ma il valore numerico
    -- reale accetta fino a +36.1 dB. Se controlliamo prima
    -- new_v == old_v, frecce e Page si fermano a +12.
    --------------------------------------------------------
    if reaeq_param_is_gain and
       reaeq_param_is_gain(param_index) then

        return reaeq_gain_nudge_chunk_direct(direction, big_step == true)
    end

    local new_v = clamp01(old_v + (step * direction))

    if new_v == old_v then
        return true
    end

    if reaeq_param_is_frequency and
       reaeq_param_is_frequency(param_index) then

        return reaeq_frequency_nudge_chunk_direct(direction, big_step == true)
    end

    if reaeq_param_is_bandwidth and
       reaeq_param_is_bandwidth(param_index) then

        return reaeq_bandwidth_nudge_limited(direction, big_step == true)

    elseif reaeq_param_api_write_is_blocked and
       reaeq_param_api_write_is_blocked(param_index) then

        return false

    elseif not reaeq_set_eq_param_normalized_value(param_index, new_v) then
        return false
    end

    disarm_slot_deletes()
    clear_param_memory_arm()
    save_current_param_position()

    local new_fmt = get_param_value_formatted(param_index)

    if new_fmt == "" then
        new_fmt = old_fmt
    end

    speak_later(new_fmt)

    return true
end

function reaeq_frequency_nudge_direct(direction, big_step)
    if not reaeq_param_is_frequency or
       not reaeq_param_is_frequency(param_index) then

        return false
    end

    return reaeq_band_param_nudge_direct(direction, big_step)
end

function reaeq_build_default_param_indices()
    local out = {}
    local seen = {}
    local band_count = reaeq_get_band_count()

    --------------------------------------------------------
    -- Ordine per colonna:
    -- 1 Enabled
    -- 2 Type
    -- 3 Real param A
    -- 4 Real param B
    -- 5 Real param C
    --------------------------------------------------------
    for b = 0, band_count - 1 do
        out[#out + 1] = reaeq_make_virtual_index(b, "enabled")
        out[#out + 1] = reaeq_make_virtual_index(b, "type")

        local base = b * 3

        for k = 0, 2 do
            local real_i = base + k

            if real_i >= 0 and real_i <= param_count - 1 then
                out[#out + 1] = real_i
                seen[real_i] = true
            end
        end
    end

    --------------------------------------------------------
    -- Controlli virtuali di gestione bande.
    -- Li mettiamo dopo le bande e prima dei globali ReaEQ.
    --------------------------------------------------------
    out[#out + 1] = REAEQ_ACTION_TARGET_INDEX
    out[#out + 1] = REAEQ_ACTION_BUTTON_INDEX

    --------------------------------------------------------
    -- Se ReaEQ espone altri parametri reali globali,
    -- non li perdiamo: li mettiamo in coda.
    --------------------------------------------------------
    for i = 0, param_count - 1 do
        if not seen[i] then
            out[#out + 1] = i
            seen[i] = true
        end
    end

    return out
end


------------------------------------------------------------
-- 3.1A2 - REACOMP ACCESSIBILITY LAYER
--
-- ReaComp espone quasi tutto come parametri reali. Qui non
-- usiamo API pesanti: aggiungiamo solo nomi accessibili,
-- toggle parlati On/Off, Detector input con valori discreti
-- sparsi, e una riga virtuale di riepilogo dei filtri del
-- detector.
------------------------------------------------------------
REACOMP_VIRTUAL_BASE = -200000
REACOMP_VIRTUAL_DETECTOR_FILTER_RANGE = REACOMP_VIRTUAL_BASE

REACOMP_DETECTOR_INPUT_VALUES = {
    { value = 0,    label = "Main inputs" },
    { value = 2,    label = "Auxiliary inputs" },
    { value = 1024, label = "Main input left" },
    { value = 1025, label = "Main input right" },
    { value = 1026, label = "Auxiliary input left" },
    { value = 1027, label = "Auxiliary input right" },
    { value = 999,  label = "Feedback pre-fader" },
    { value = 1000, label = "Output feedback deprecated" }
}

REACOMP_NAME_ALIASES = {
    ["hipass"] = "Detector Highpass",
    ["hi pass"] = "Detector Highpass",
    ["highpass"] = "Detector Highpass",
    ["high pass"] = "Detector Highpass",
    ["lowpass"] = "Detector Lowpass",
    ["low pass"] = "Detector Lowpass",
    ["signin"] = "Detector input",
    ["sign in"] = "Detector input",
    ["pre-comp"] = "Lookahead",
    ["precomp"] = "Lookahead",
    ["pre comp"] = "Lookahead",
    ["filter preview"] = "Filter Preview",
    ["auto make up gain"] = "Auto Make Up Gain",
    ["auto makeup gain"] = "Auto Make Up Gain",
    ["auto release"] = "Auto Release",
    ["rms size"] = "RMS size",
    ["dry"] = "Dry mix",
    ["wet"] = "Wet mix",
    ["resvd"] = "Reserved",
    ["audin"] = "Audition input",
    ["aud in"] = "Audition input",
    ["legacy attack/knee options"] = "Legacy attack knee options",
    ["deprecated broken anti-alias"] = "Deprecated anti-alias compatibility",
    ["multichannel mode"] = "Multichannel mode",
    ["metering index"] = "Metering display mode"
}

function reacomp_normalize_param_name(name)
    name = clean_one_line(name or "")
    name = name:lower()
    name = name:gsub("%s+", " ")

    return trim(name)
end

function reacomp_get_real_param_raw_name(i)
    i = tonumber(i)

    if i == nil or i < 0 or i > param_count - 1 then
        return ""
    end

    local real_fx = get_current_real_fx_index()

    if real_fx == nil then
        return ""
    end

    local ok, retval, name

    if ctx.kind == "take" then
        if not ctx.take then
            return ""
        end

        ok, retval, name =
            pcall(reaper.TakeFX_GetParamName, ctx.take, real_fx, i, "")
    else
        if not ctx.track then
            return ""
        end

        ok, retval, name =
            pcall(reaper.TrackFX_GetParamName, ctx.track, real_fx, i, "")
    end

    if ok and retval then
        return clean_one_line(name or "")
    end

    return ""
end

function reacomp_real_param_key(i)
    return reacomp_normalize_param_name(
        reacomp_get_real_param_raw_name(i)
    )
end

function reacomp_param_alias_for_real_index(i)
    if not is_current_fx_reacomp or not is_current_fx_reacomp() then
        return ""
    end

    local key = reacomp_real_param_key(i)

    if key == "" then
        return ""
    end

    return REACOMP_NAME_ALIASES[key] or ""
end

function reacomp_real_param_matches(i, names)
    local key = reacomp_real_param_key(i)

    if key == "" then
        return false
    end

    for _, name in ipairs(names or {}) do
        if key == reacomp_normalize_param_name(name) then
            return true
        end
    end

    return false
end

function reacomp_find_real_param_by_names(names)
    if not is_current_fx_reacomp or not is_current_fx_reacomp() then
        return nil
    end

    for i = 0, param_count - 1 do
        if reacomp_real_param_matches(i, names) then
            return i
        end
    end

    return nil
end

function reacomp_param_is_detector_input(i)
    return is_current_fx_reacomp and
           is_current_fx_reacomp() and
           reacomp_real_param_matches(i, { "SignIn", "Sign In" })
end

function reacomp_param_is_toggle(i)
    if not is_current_fx_reacomp or not is_current_fx_reacomp() then
        return false
    end

    return reacomp_real_param_matches(
        i,
        {
            "Filter Preview",
            "Auto Make Up Gain",
            "Auto Makeup Gain",
            "Auto Release"
        }
    )
end

function reacomp_param_is_rms_size(i)
    return is_current_fx_reacomp and
           is_current_fx_reacomp() and
           reacomp_real_param_matches(i, { "RMS size" })
end

function reacomp_virtual_param_is_valid(i)
    i = tonumber(i)

    return is_current_fx_reacomp and
           is_current_fx_reacomp() and
           i == REACOMP_VIRTUAL_DETECTOR_FILTER_RANGE
end

function reacomp_get_virtual_param_name(i)
    if reacomp_virtual_param_is_valid(i) then
        return "Detector filter range"
    end

    return ""
end

function reacomp_detector_value_to_user_index(raw)
    raw = math.floor((tonumber(raw) or 0) + 0.5)

    local fallback = 1

    for idx, entry in ipairs(REACOMP_DETECTOR_INPUT_VALUES) do
        if entry.value == raw then
            return idx
        end
    end

    return fallback
end

function reacomp_detector_user_index_to_value(index)
    index = clamp_int(index, 1, #REACOMP_DETECTOR_INPUT_VALUES)

    local entry = REACOMP_DETECTOR_INPUT_VALUES[index]

    return entry and entry.value or 0
end

function reacomp_detector_label_from_raw(raw)
    local idx = reacomp_detector_value_to_user_index(raw)
    local entry = REACOMP_DETECTOR_INPUT_VALUES[idx]

    return entry and entry.label or ("Value " .. tostring(raw))
end

function reacomp_get_raw_real_param_value(i)
    local value = get_param_raw(i)

    return tonumber(value) or 0
end

function reacomp_set_real_param_raw(i, value)
    i = tonumber(i)

    if i == nil or i < 0 or i > param_count - 1 then
        return false
    end

    value = tonumber(value) or 0

    local real_fx = get_current_real_fx_index()

    if real_fx == nil then
        return false
    end

    if ctx.kind == "take" then
        if ctx.take then
            reaper.TakeFX_SetParam(ctx.take, real_fx, i, value)
            return true
        end

        return false
    end

    if ctx.track then
        reaper.TrackFX_SetParam(ctx.track, real_fx, i, value)
        return true
    end

    return false
end

function reacomp_get_detector_user_index(i)
    local raw = reacomp_get_raw_real_param_value(i)

    return reacomp_detector_value_to_user_index(raw)
end

function reacomp_get_detector_norm(i)
    local count = #REACOMP_DETECTOR_INPUT_VALUES

    if count <= 1 then
        return 0
    end

    local idx = reacomp_get_detector_user_index(i)

    return clamp01((idx - 1) / (count - 1))
end

function reacomp_set_detector_user_index(i, index)
    local raw = reacomp_detector_user_index_to_value(index)

    return reacomp_set_real_param_raw(i, raw)
end

function reacomp_set_detector_norm(i, norm)
    local count = #REACOMP_DETECTOR_INPUT_VALUES

    if count <= 1 then
        return false
    end

    norm = clamp01(norm)

    local idx = math.floor((norm * (count - 1)) + 0.5) + 1

    idx = clamp_int(idx, 1, count)

    return reacomp_set_detector_user_index(i, idx)
end

function reacomp_detector_nudge(i, direction, big_step)
    if not reacomp_param_is_detector_input(i) then
        return false
    end

    direction = tonumber(direction) or 0

    if direction == 0 then
        return false
    end

    local amount = 1

    if big_step then
        amount = get_discrete_step_amount(true)
    end

    local idx = reacomp_get_detector_user_index(i)
    local new_idx = idx + (direction > 0 and amount or -amount)

    new_idx = clamp_int(new_idx, 1, #REACOMP_DETECTOR_INPUT_VALUES)

    if new_idx == idx then
        return true
    end

    reacomp_set_detector_user_index(i, new_idx)

    disarm_slot_deletes()
    clear_param_memory_arm()
    save_current_param_position()
    speak_later(reacomp_get_detector_formatted(i))

    return true
end

function reacomp_get_detector_formatted(i)
    local raw = reacomp_get_raw_real_param_value(i)

    return reacomp_detector_label_from_raw(raw)
end

function reacomp_format_toggle(i)
    local raw = reacomp_get_raw_real_param_value(i)

    return raw >= 0.5 and "On" or "Off"
end

function reacomp_format_rms_size(i, formatted)
    formatted = clean_one_line(formatted or "")

    local n = nil

    if reaeq_parse_first_number then
        n = reaeq_parse_first_number(formatted)
    else
        n = tonumber(formatted)
    end

    if n == nil then
        return formatted
    end

    if math.abs(n) < 0.0005 then
        return "0 ms, peak detector"
    end

    local txt = string.format("%.3f", n)
    txt = txt:gsub("%.?0+$", "")

    return txt .. " ms"
end

function reacomp_format_hz_text(value)
    value = tonumber(value) or 0

    if value <= 0 then
        return "0 Hz"
    end

    local txt = string.format("%.1f", value)
    txt = txt:gsub("%.?0+$", "")

    return txt .. " Hz"
end

function reacomp_get_detector_filter_range_formatted()
    local hp_i = reacomp_find_real_param_by_names({ "Hipass", "Hi pass", "Highpass", "High pass" })
    local lp_i = reacomp_find_real_param_by_names({ "Lowpass", "Low pass" })

    local hp = nil
    local lp = nil

    if hp_i ~= nil then
        hp = reaeq_parse_first_number(get_param_value_formatted(hp_i))
        if hp == nil then
            hp = reacomp_get_raw_real_param_value(hp_i)
        end
    end

    if lp_i ~= nil then
        lp = reaeq_parse_first_number(get_param_value_formatted(lp_i))
        if lp == nil then
            lp = reacomp_get_raw_real_param_value(lp_i)
        end
    end

    hp = tonumber(hp) or 0
    lp = tonumber(lp) or 20000

    local hp_on = hp > 0.5
    local lp_on = lp < 19999.5

    if not hp_on and not lp_on then
        return "Full range"
    end

    if hp_on and lp_on then
        return reacomp_format_hz_text(hp) .. " to " .. reacomp_format_hz_text(lp)
    end

    if hp_on then
        return "Above " .. reacomp_format_hz_text(hp)
    end

    return "Below " .. reacomp_format_hz_text(lp)
end

function reacomp_get_virtual_formatted(i)
    if i == REACOMP_VIRTUAL_DETECTOR_FILTER_RANGE then
        return reacomp_get_detector_filter_range_formatted()
    end

    return ""
end

function reacomp_get_virtual_raw(i)
    if reacomp_virtual_param_is_valid(i) then
        return 0, 0, 1
    end

    return 0, 0, 1
end

function reacomp_get_virtual_norm(i)
    return 0
end

function reacomp_set_virtual_raw(i, value)
    return false
end

function reacomp_set_virtual_norm(i, value)
    return false
end

function reacomp_get_real_param_formatted(i, formatted)
    if not is_current_fx_reacomp or not is_current_fx_reacomp() then
        return clean_one_line(formatted or "")
    end

    if reacomp_param_is_detector_input(i) then
        return reacomp_get_detector_formatted(i)
    end

    if reacomp_param_is_toggle(i) then
        return reacomp_format_toggle(i)
    end

    if reacomp_param_is_rms_size(i) then
        return reacomp_format_rms_size(i, formatted)
    end

    return clean_one_line(formatted or "")
end

function reacomp_build_default_param_indices()
    local out = {}
    local used = {}

    local order = {
        { "Threshold" },
        { "Ratio" },
        { "Attack" },
        { "Release" },
        { "Pre-comp", "Precomp" },
        { "RMS size" },
        { "Knee" },
        { "SignIn", "Sign In" },
        { "Hipass", "Hi pass", "Highpass", "High pass" },
        { "Lowpass", "Low pass" },
        { "__virtual_detector_filter_range__" },
        { "Filter Preview" },
        { "Dry" },
        { "Wet" },
        { "Auto Make Up Gain", "Auto Makeup Gain" },
        { "Auto Release" }
    }

    for _, names in ipairs(order) do
        if names[1] == "__virtual_detector_filter_range__" then
            out[#out + 1] = REACOMP_VIRTUAL_DETECTOR_FILTER_RANGE
        else
            local i = reacomp_find_real_param_by_names(names)

            if i ~= nil and not used[i] then
                out[#out + 1] = i
                used[i] = true
            end
        end
    end

    --------------------------------------------------------
    -- Non perdiamo nessun parametro reale: quelli non messi
    -- nella vista principale finiscono in coda/Advanced.
    --------------------------------------------------------
    for i = 0, param_count - 1 do
        if not used[i] then
            out[#out + 1] = i
            used[i] = true
        end
    end

    return out
end


------------------------------------------------------------
-- 3.1A3 - REAGATE ACCESSIBILITY LAYER
--
-- ReaGate usa una struttura molto simile a ReaComp per il
-- detector: SignIn ha valori sparsi 0, 2, 1024, ecc.
-- Qui riusiamo la stessa logica di ReaComp per Detector input,
-- nomi parlanti, toggle On/Off e riepilogo filtro detector.
------------------------------------------------------------
REAGATE_VIRTUAL_BASE = -210000
REAGATE_VIRTUAL_DETECTOR_FILTER_RANGE = REAGATE_VIRTUAL_BASE

REAGATE_NAME_ALIASES = {
    ["hipass"] = "Detector Highpass",
    ["hi pass"] = "Detector Highpass",
    ["highpass"] = "Detector Highpass",
    ["high pass"] = "Detector Highpass",
    ["lowpass"] = "Detector Lowpass",
    ["low pass"] = "Detector Lowpass",
    ["signin"] = "Detector input",
    ["sign in"] = "Detector input",
    ["pre-open"] = "Lookahead",
    ["preopen"] = "Lookahead",
    ["pre open"] = "Lookahead",
    ["filter preview"] = "Filter Preview",
    ["preview filter"] = "Filter Preview",
    ["dry"] = "Dry mix",
    ["wet"] = "Wet mix",
    ["hysteresis"] = "Hysteresis",
    ["attack"] = "Attack",
    ["hold"] = "Hold",
    ["release"] = "Release",
    ["threshold"] = "Threshold",
    ["invert gate"] = "Invert gate",
    ["invert"] = "Invert gate",
    ["send midi on open/close"] = "Send MIDI on open close",
    ["send midi on open close"] = "Send MIDI on open close",
    ["send midi"] = "Send MIDI",
    ["midi note"] = "MIDI note",
    ["midi note on open"] = "MIDI note",
    ["midi note on close"] = "MIDI note off",
    ["midi channel"] = "MIDI channel",
    ["midi chan"] = "MIDI channel",
    ["midi velocity"] = "MIDI velocity",
    ["midi vel"] = "MIDI velocity",
    ["audin"] = "Audition input",
    ["aud in"] = "Audition input",
    ["audition input"] = "Audition input"
}

function reagate_param_alias_for_real_index(i)
    if not is_current_fx_reagate or not is_current_fx_reagate() then
        return ""
    end

    local key = reacomp_real_param_key(i)

    if key == "" then
        return ""
    end

    return REAGATE_NAME_ALIASES[key] or ""
end

function reagate_real_param_matches(i, names)
    local key = reacomp_real_param_key(i)

    if key == "" then
        return false
    end

    for _, name in ipairs(names or {}) do
        if key == reacomp_normalize_param_name(name) then
            return true
        end
    end

    return false
end

function reagate_find_real_param_by_names(names)
    if not is_current_fx_reagate or not is_current_fx_reagate() then
        return nil
    end

    for i = 0, param_count - 1 do
        if reagate_real_param_matches(i, names) then
            return i
        end
    end

    return nil
end

function reagate_param_is_detector_input(i)
    return is_current_fx_reagate and
           is_current_fx_reagate() and
           reagate_real_param_matches(i, { "SignIn", "Sign In" })
end

function reagate_param_is_toggle(i)
    if not is_current_fx_reagate or not is_current_fx_reagate() then
        return false
    end

    return reagate_real_param_matches(
        i,
        {
            "Filter Preview",
            "Preview Filter",
            "Invert Gate",
            "Invert",
            "Send MIDI on open/close",
            "Send MIDI on open close",
            "Send MIDI",
            "Audition input",
            "AudIn",
            "Aud In"
        }
    )
end

function reagate_virtual_param_is_valid(i)
    i = tonumber(i)

    return is_current_fx_reagate and
           is_current_fx_reagate() and
           i == REAGATE_VIRTUAL_DETECTOR_FILTER_RANGE
end

function reagate_get_virtual_param_name(i)
    if reagate_virtual_param_is_valid(i) then
        return "Detector filter range"
    end

    return ""
end

function reagate_get_detector_user_index(i)
    local raw = reacomp_get_raw_real_param_value(i)

    return reacomp_detector_value_to_user_index(raw)
end

function reagate_get_detector_norm(i)
    local count = #REACOMP_DETECTOR_INPUT_VALUES

    if count <= 1 then
        return 0
    end

    local idx = reagate_get_detector_user_index(i)

    return clamp01((idx - 1) / (count - 1))
end

function reagate_set_detector_user_index(i, index)
    local raw = reacomp_detector_user_index_to_value(index)

    return reacomp_set_real_param_raw(i, raw)
end

function reagate_set_detector_norm(i, norm)
    local count = #REACOMP_DETECTOR_INPUT_VALUES

    if count <= 1 then
        return false
    end

    norm = clamp01(norm)

    local idx = math.floor((norm * (count - 1)) + 0.5) + 1

    idx = clamp_int(idx, 1, count)

    return reagate_set_detector_user_index(i, idx)
end

function reagate_detector_nudge(i, direction, big_step)
    if not reagate_param_is_detector_input(i) then
        return false
    end

    direction = tonumber(direction) or 0

    if direction == 0 then
        return false
    end

    local amount = 1

    if big_step then
        amount = get_discrete_step_amount(true)
    end

    local idx = reagate_get_detector_user_index(i)
    local new_idx = idx + (direction > 0 and amount or -amount)

    new_idx = clamp_int(new_idx, 1, #REACOMP_DETECTOR_INPUT_VALUES)

    if new_idx == idx then
        return true
    end

    reagate_set_detector_user_index(i, new_idx)

    disarm_slot_deletes()
    clear_param_memory_arm()
    save_current_param_position()
    speak_later(reagate_get_detector_formatted(i))

    return true
end

function reagate_get_detector_formatted(i)
    local raw = reacomp_get_raw_real_param_value(i)

    return reacomp_detector_label_from_raw(raw)
end

function reagate_format_toggle(i)
    local raw = reacomp_get_raw_real_param_value(i)

    return raw >= 0.5 and "On" or "Off"
end

function reagate_format_hz_text(value)
    return reacomp_format_hz_text(value)
end

function reagate_get_detector_filter_range_formatted()
    local hp_i = reagate_find_real_param_by_names({ "Hipass", "Hi pass", "Highpass", "High pass" })
    local lp_i = reagate_find_real_param_by_names({ "Lowpass", "Low pass" })

    local hp = nil
    local lp = nil

    if hp_i ~= nil then
        hp = reaeq_parse_first_number(get_param_value_formatted(hp_i))
        if hp == nil then
            hp = reacomp_get_raw_real_param_value(hp_i)
        end
    end

    if lp_i ~= nil then
        lp = reaeq_parse_first_number(get_param_value_formatted(lp_i))
        if lp == nil then
            lp = reacomp_get_raw_real_param_value(lp_i)
        end
    end

    hp = tonumber(hp) or 0
    lp = tonumber(lp) or 20000

    local hp_on = hp > 0.5
    local lp_on = lp < 19999.5

    if not hp_on and not lp_on then
        return "Full range"
    end

    if hp_on and lp_on then
        return reagate_format_hz_text(hp) .. " to " .. reagate_format_hz_text(lp)
    end

    if hp_on then
        return "Above " .. reagate_format_hz_text(hp)
    end

    return "Below " .. reagate_format_hz_text(lp)
end

function reagate_get_virtual_formatted(i)
    if i == REAGATE_VIRTUAL_DETECTOR_FILTER_RANGE then
        return reagate_get_detector_filter_range_formatted()
    end

    return ""
end

function reagate_get_virtual_raw(i)
    if reagate_virtual_param_is_valid(i) then
        return 0, 0, 1
    end

    return 0, 0, 1
end

function reagate_get_virtual_norm(i)
    return 0
end

function reagate_set_virtual_raw(i, value)
    return false
end

function reagate_set_virtual_norm(i, value)
    return false
end

function reagate_get_real_param_formatted(i, formatted)
    if not is_current_fx_reagate or not is_current_fx_reagate() then
        return clean_one_line(formatted or "")
    end

    if reagate_param_is_detector_input(i) then
        return reagate_get_detector_formatted(i)
    end

    if reagate_param_is_toggle(i) then
        return reagate_format_toggle(i)
    end

    return clean_one_line(formatted or "")
end

function reagate_build_default_param_indices()
    local out = {}
    local used = {}

    local order = {
        { "Threshold" },
        { "Attack" },
        { "Hold" },
        { "Release" },
        { "Hysteresis" },
        { "Pre-open", "Preopen", "Pre open" },
        { "RMS size", "RMS" },
        { "SignIn", "Sign In" },
        { "Hipass", "Hi pass", "Highpass", "High pass" },
        { "Lowpass", "Low pass" },
        { "__virtual_detector_filter_range__" },
        { "Filter Preview", "Preview Filter" },
        { "Dry" },
        { "Wet" },
        { "Invert Gate", "Invert" },

        ----------------------------------------------------
        -- MIDI block kept together.
        ----------------------------------------------------
        { "Send MIDI on open/close", "Send MIDI on open close", "Send MIDI" },
        { "MIDI note", "MIDI note on open", "MIDI note on close" },
        { "MIDI channel", "MIDI chan" },
        { "MIDI velocity", "MIDI vel" },

        { "Audition input", "AudIn", "Aud In" }
    }

    for _, names in ipairs(order) do
        if names[1] == "__virtual_detector_filter_range__" then
            out[#out + 1] = REAGATE_VIRTUAL_DETECTOR_FILTER_RANGE
        else
            local i = reagate_find_real_param_by_names(names)

            if i ~= nil and not used[i] then
                out[#out + 1] = i
                used[i] = true
            end
        end
    end

    for i = 0, param_count - 1 do
        if not used[i] then
            out[#out + 1] = i
            used[i] = true
        end
    end

    return out
end

------------------------------------------------------------
-- 3.1B - PARAMETRI: NOMI / VALORI
------------------------------------------------------------
function get_param_name(i)
    i = tonumber(i) or 0

    if fx_compare_param_is_valid and fx_compare_param_is_valid(i) then
        return "Compare"
    end

    if reaeq_virtual_param_is_valid(i) then
        return reaeq_get_virtual_param_name(i)
    end

    if reacomp_virtual_param_is_valid and
       reacomp_virtual_param_is_valid(i) then

        return reacomp_get_virtual_param_name(i)
    end

    if reagate_virtual_param_is_valid and
       reagate_virtual_param_is_valid(i) then

        return reagate_get_virtual_param_name(i)
    end

    local reacomp_alias = ""

    if reacomp_param_alias_for_real_index then
        reacomp_alias = reacomp_param_alias_for_real_index(i)
    end

    if reacomp_alias ~= "" then
        return reacomp_alias
    end

    local reagate_alias = ""

    if reagate_param_alias_for_real_index then
        reagate_alias = reagate_param_alias_for_real_index(i)
    end

    if reagate_alias ~= "" then
        return reagate_alias
    end

    local real_fx = get_current_real_fx_index()
    local _, name

    if ctx.kind == "take" then
        if not ctx.take then
            return ""
        end

        _, name = reaper.TakeFX_GetParamName(ctx.take, real_fx, i, "")
    else
        if not ctx.track then
            return ""
        end

        _, name = reaper.TrackFX_GetParamName(ctx.track, real_fx, i, "")
    end

    return name or ""
end

function get_param_raw(i)
    i = tonumber(i) or 0

    if fx_compare_param_is_valid and fx_compare_param_is_valid(i) then
        local norm = fx_compare_get_norm()
        return norm, 0, 1
    end

    if reaeq_virtual_param_is_valid(i) then
        return reaeq_get_virtual_raw(i)
    end

    if reacomp_virtual_param_is_valid and
       reacomp_virtual_param_is_valid(i) then

        return reacomp_get_virtual_raw(i)
    end

    if reagate_virtual_param_is_valid and
       reagate_virtual_param_is_valid(i) then

        return reagate_get_virtual_raw(i)
    end

    local real_fx = get_current_real_fx_index()
    local value, minval, maxval

    if ctx.kind == "take" then
        if not ctx.take then
            return 0, 0, 1
        end

        value, minval, maxval =
            reaper.TakeFX_GetParam(ctx.take, real_fx, i)
    else
        if not ctx.track then
            return 0, 0, 1
        end

        value, minval, maxval =
            reaper.TrackFX_GetParam(ctx.track, real_fx, i)
    end

    value  = tonumber(value)  or 0
    minval = tonumber(minval) or 0
    maxval = tonumber(maxval) or 1

    return value, minval, maxval
end

function get_param_value_norm(i)
    i = tonumber(i) or 0

    if fx_compare_param_is_valid and fx_compare_param_is_valid(i) then
        return fx_compare_get_norm()
    end

    if reaeq_virtual_param_is_valid(i) then
        return reaeq_get_virtual_norm(i)
    end

    if reacomp_virtual_param_is_valid and
       reacomp_virtual_param_is_valid(i) then

        return reacomp_get_virtual_norm(i)
    end

    if reagate_virtual_param_is_valid and
       reagate_virtual_param_is_valid(i) then

        return reagate_get_virtual_norm(i)
    end

    if reacomp_param_is_detector_input and
       reacomp_param_is_detector_input(i) then

        return reacomp_get_detector_norm(i)
    end

    if reagate_param_is_detector_input and
       reagate_param_is_detector_input(i) then

        return reagate_get_detector_norm(i)
    end

    local real_fx = get_current_real_fx_index()

    if ctx.kind == "take" then
        if not ctx.take then
            return 0
        end

        if reaper.TakeFX_GetParamNormalized then
            return clamp01(
                reaper.TakeFX_GetParamNormalized(ctx.take, real_fx, i)
            )
        end

        local value, minval, maxval = get_param_raw(i)

        if maxval ~= minval then
            return clamp01((value - minval) / (maxval - minval))
        end

        return 0
    end

    if not ctx.track then
        return 0
    end

    if reaper.TrackFX_GetParamNormalized then
        return clamp01(
            reaper.TrackFX_GetParamNormalized(ctx.track, real_fx, i)
        )
    end

    local value, minval, maxval = get_param_raw(i)

    if maxval ~= minval then
        return clamp01((value - minval) / (maxval - minval))
    end

    return 0
end

function set_param_value_norm(i, v)
    i = tonumber(i) or 0
    v = clamp01(v)

    if fx_compare_param_is_valid and fx_compare_param_is_valid(i) then
        fx_compare_set_norm(v)
        return
    end

    if reaeq_virtual_param_is_valid(i) then
        reaeq_set_virtual_norm(i, v)
        return
    end

    if reacomp_virtual_param_is_valid and
       reacomp_virtual_param_is_valid(i) then

        reacomp_set_virtual_norm(i, v)
        return
    end

    if reagate_virtual_param_is_valid and
       reagate_virtual_param_is_valid(i) then

        reagate_set_virtual_norm(i, v)
        return
    end

    if reacomp_param_is_detector_input and
       reacomp_param_is_detector_input(i) then

        reacomp_set_detector_norm(i, v)
        return
    end

    if reagate_param_is_detector_input and
       reagate_param_is_detector_input(i) then

        reagate_set_detector_norm(i, v)
        return
    end

    --------------------------------------------------------
    -- ReaEQ band real parameters need the ReaEQ API path.
    -- This keeps reset/default in sync with the special ReaEQ
    -- value handling used by the rest of the script.
    --------------------------------------------------------
    if is_current_fx_reaeq and is_current_fx_reaeq() and
       reaeq_param_is_band_real and
       reaeq_param_is_band_real(i) and
       reaeq_set_eq_param_normalized_value and
       reaeq_set_eq_param_normalized_value(i, v) then

        return
    end

    local real_fx = get_current_real_fx_index()

    if ctx.kind == "take" then
        if not ctx.take then
            return
        end

        if reaper.TakeFX_SetParamNormalized then
            reaper.TakeFX_SetParamNormalized(ctx.take, real_fx, i, v)
        else
            reaper.TakeFX_SetParam(ctx.take, real_fx, i, v)
        end

        return
    end

    if not ctx.track then
        return
    end

    if reaper.TrackFX_SetParamNormalized then
        reaper.TrackFX_SetParamNormalized(ctx.track, real_fx, i, v)
    else
        reaper.TrackFX_SetParam(ctx.track, real_fx, i, v)
    end
end

function set_param_value_raw(i, v)
    i = tonumber(i) or 0
    v = tonumber(v) or 0

    if fx_compare_param_is_valid and fx_compare_param_is_valid(i) then
        fx_compare_set_norm(v >= 0.5 and 1 or 0)
        return
    end

    if reaeq_virtual_param_is_valid(i) then
        reaeq_set_virtual_raw(i, v)
        return
    end

    if reacomp_virtual_param_is_valid and
       reacomp_virtual_param_is_valid(i) then

        reacomp_set_virtual_raw(i, v)
        return
    end

    if reagate_virtual_param_is_valid and
       reagate_virtual_param_is_valid(i) then

        reagate_set_virtual_raw(i, v)
        return
    end

    if reacomp_param_is_detector_input and
       reacomp_param_is_detector_input(i) then

        -- Numeric/raw edit on Detector input accepts either the
        -- real sparse values (0, 2, 999, 1024...) or the user
        -- list positions 1..8.
        local raw_v = math.floor((tonumber(v) or 0) + 0.5)
        local matched = false

        for _, entry in ipairs(REACOMP_DETECTOR_INPUT_VALUES or {}) do
            if entry.value == raw_v then
                matched = true
                break
            end
        end

        if matched then
            reacomp_set_real_param_raw(i, raw_v)
        else
            reacomp_set_detector_user_index(i, raw_v)
        end

        return
    end

    if reagate_param_is_detector_input and
       reagate_param_is_detector_input(i) then

        local raw_v = math.floor((tonumber(v) or 0) + 0.5)
        local matched = false

        for _, entry in ipairs(REACOMP_DETECTOR_INPUT_VALUES or {}) do
            if entry.value == raw_v then
                matched = true
                break
            end
        end

        if matched then
            reacomp_set_real_param_raw(i, raw_v)
        else
            reagate_set_detector_user_index(i, raw_v)
        end

        return
    end

    local real_fx = get_current_real_fx_index()

    if ctx.kind == "take" then
        if ctx.take then
            reaper.TakeFX_SetParam(ctx.take, real_fx, i, v)
        end

        return
    end

    if ctx.track then
        reaper.TrackFX_SetParam(ctx.track, real_fx, i, v)
    end
end

function get_param_value_formatted_at_norm(i, norm)
    i = tonumber(i) or 0
    norm = clamp01(norm)

    if i < 0 or i > param_count - 1 then
        return ""
    end

    local real_fx = get_current_real_fx_index()

    if real_fx == nil then
        return ""
    end

    local ok, retval, value

    if ctx.kind == "take" then
        if not ctx.take then
            return ""
        end

        if reaper.TakeFX_FormatParamValueNormalized then
            ok, retval, value =
                pcall(
                    reaper.TakeFX_FormatParamValueNormalized,
                    ctx.take,
                    real_fx,
                    i,
                    norm,
                    ""
                )

            if ok and retval then
                value = clean_one_line(value or "")

                if value ~= "" then
                    return value
                end
            end
        end

        return ""
    end

    if not ctx.track then
        return ""
    end

    if reaper.TrackFX_FormatParamValueNormalized then
        ok, retval, value =
            pcall(
                reaper.TrackFX_FormatParamValueNormalized,
                ctx.track,
                real_fx,
                i,
                norm,
                ""
            )

        if ok and retval then
            value = clean_one_line(value or "")

            if value ~= "" then
                return value
            end
        end
    end

    return ""
end

function get_param_value_formatted_from_normalized(i)
    i = tonumber(i) or 0

    if i < 0 or i > param_count - 1 then
        return ""
    end

    local real_fx = get_current_real_fx_index()

    if real_fx == nil then
        return ""
    end

    local norm = get_param_value_norm(i)
    local ok, retval, value

    --------------------------------------------------------
    -- Take FX.
    --------------------------------------------------------
    if ctx.kind == "take" then
        if not ctx.take then
            return ""
        end

        if reaper.TakeFX_FormatParamValueNormalized then
            ok, retval, value =
                pcall(
                    reaper.TakeFX_FormatParamValueNormalized,
                    ctx.take,
                    real_fx,
                    i,
                    norm,
                    ""
                )

            if ok and retval then
                value = clean_one_line(value or "")

                if value ~= "" then
                    return value
                end
            end
        end

        return ""
    end

    --------------------------------------------------------
    -- Track / Master / Monitor FX.
    --------------------------------------------------------
    if not ctx.track then
        return ""
    end

    if reaper.TrackFX_FormatParamValueNormalized then
        ok, retval, value =
            pcall(
                reaper.TrackFX_FormatParamValueNormalized,
                ctx.track,
                real_fx,
                i,
                norm,
                ""
            )

        if ok and retval then
            value = clean_one_line(value or "")

            if value ~= "" then
                return value
            end
        end
    end

    return ""
end

function get_param_value_formatted(i)
    i = tonumber(i) or 0

    if fx_compare_param_is_valid and fx_compare_param_is_valid(i) then
        return fx_compare_get_formatted()
    end

    --------------------------------------------------------
    -- ReaEQ virtual params:
    -- solo Band Enabled / Band Type restano speciali.
    --------------------------------------------------------
    if reaeq_virtual_param_is_valid(i) then
        return reaeq_get_virtual_formatted(i)
    end

    if reacomp_virtual_param_is_valid and
       reacomp_virtual_param_is_valid(i) then

        return reacomp_get_virtual_formatted(i)
    end

    if reagate_virtual_param_is_valid and
       reagate_virtual_param_is_valid(i) then

        return reagate_get_virtual_formatted(i)
    end

    --------------------------------------------------------
    -- Tutti i parametri reali, incluso ReaEQ, passano dal
    -- percorso generico usato per tutti i plugin.
    --------------------------------------------------------
    local real_fx = get_current_real_fx_index()
    local ok, retval, value

    if real_fx == nil then
        return ""
    end

    if ctx.kind == "take" then
        if not ctx.take then
            return ""
        end

        if reaper.TakeFX_GetFormattedParamValue then
            ok, retval, value =
                pcall(
                    reaper.TakeFX_GetFormattedParamValue,
                    ctx.take,
                    real_fx,
                    i,
                    ""
                )

            if ok and retval then
                local formatted = reaeq_format_band_value_with_units(i, value or "")

                if reacomp_get_real_param_formatted then
                    formatted = reacomp_get_real_param_formatted(i, formatted)
                end

                if reagate_get_real_param_formatted then
                    formatted = reagate_get_real_param_formatted(i, formatted)
                end

                return formatted
            end
        end

        return ""
    end

    if not ctx.track then
        return ""
    end

    if reaper.TrackFX_GetFormattedParamValue then
        ok, retval, value =
            pcall(
                reaper.TrackFX_GetFormattedParamValue,
                ctx.track,
                real_fx,
                i,
                ""
            )

        if ok and retval then
            local formatted = reaeq_format_band_value_with_units(i, value or "")

            if reacomp_get_real_param_formatted then
                formatted = reacomp_get_real_param_formatted(i, formatted)
            end

            if reagate_get_real_param_formatted then
                formatted = reagate_get_real_param_formatted(i, formatted)
            end

            return formatted
        end
    end

    return ""
end

------------------------------------------------------------
-- 3.2 - LABEL FX / PARAMETRI------------------------------------------------------------
-- 3.2 - LABEL FX / PARAMETRI
------------------------------------------------------------
function get_fx_raw_label()
    if selected_fx_label and selected_fx_label ~= "" then
        return clean_one_line(selected_fx_label)
    end

    return clean_one_line(fx_names[fx_index + 1] or fx_names[1] or "FX")
end

function get_fx_label()
    return strip_fx_prefix(get_fx_raw_label())
end

function get_param_original_name(i)
    i = tonumber(i) or 0

    local name = clean_one_line(get_param_name(i))

    if name == "" then
        name = "Parameter " .. tostring(i + 1)
    end

    return name
end

function get_param_alias(i)
    i = tonumber(i)

    if i == nil then
        return ""
    end

    --------------------------------------------------------
    -- L'alias appartiene al parametro, non alla vista.
    -- Quindi il nome personalizzato resta visibile in:
    -- Plugin order, Custom order, Groups e F7 Edit group.
    --------------------------------------------------------
    return clean_one_line(custom_param_aliases[i] or "")
end

function get_param_display_name(i)
    local alias = get_param_alias(i)

    if alias ~= "" then
        return alias
    end

    return get_param_original_name(i)
end

function get_param_cc_learn_spoken_label(i)
    i = tonumber(i)

    if i == nil then
        return ""
    end

    --------------------------------------------------------
    -- Se il Floating CC è attivo o in attesa, i CC normali
    -- vengono messi da parte anche nel parlato dei parametri.
    --------------------------------------------------------
    if cc_focus_active or cc_focus_waiting then
        return ""
    end

--------------------------------------------------------
-- Ora il CC interno può esistere sia sui parametri reali
-- sia sugli pseudo-parametri ReaEQ supportati.
--------------------------------------------------------
if type(cc_learn_param_is_supported) == "function" and
   not cc_learn_param_is_supported(i) then

    return ""
end    

    --------------------------------------------------------
    -- Legge prima il CC interno salvato nel TXT plugin.
    -- È lo stesso link usato dal runtime CC e dal Tab.
    --------------------------------------------------------
    local txt = ""

    if type(get_plugin_state_safe) == "function" then
        txt = get_plugin_state_safe(
            "cc_link_v1::param::" .. tostring(i)
        )
    end

    local channel = nil
    local cc = nil

    if type(cc_link_parse_text) == "function" then
        channel, cc = cc_link_parse_text(txt)
    else
        local channel_s, cc_s =
            tostring(txt or ""):match("^(%d+)%s*\t%s*(%d+)$")

        channel = tonumber(channel_s)
        cc = tonumber(cc_s)

        if channel ~= nil then
            channel = clamp_int(channel, 1, 16)
        end

        if cc ~= nil then
            cc = clamp_int(cc, 0, 127)
        end
    end

    if channel ~= nil and cc ~= nil then
        return
            "CC channel " ..
            tostring(channel) ..
            " CC " ..
            tostring(cc)
    end

    --------------------------------------------------------
    -- Fallback: prova anche il learn nativo REAPER.
    --------------------------------------------------------
    if type(fx_get_named_config_parm) ~= "function" then
        return ""
    end

    local ok, midi1 =
        fx_get_named_config_parm(
            "param." .. tostring(i) .. ".learn.midi1"
        )

    midi1 = tostring(midi1 or "")

    if not ok or midi1 == "" or #midi1 < 2 then
        return ""
    end

    local status = midi1:byte(1) or 0
    local native_cc = midi1:byte(2) or 0

    if math.floor(status / 16) ~= 0x0B then
        return ""
    end

    local native_channel = (status % 16) + 1

    return
        "CC channel " ..
        tostring(native_channel) ..
        " CC " ..
        tostring(native_cc)
end

------------------------------------------------------------
-- 3.2A - SUFFISSO AUTOMAZIONE PARAMETRO REALE
--
-- Il parlato principale resta compatto:
-- Nome parametro, valore, Auto, CC.
--
-- Auto non viene salvato nel TXT e non usa memoria runtime.
-- Viene letto direttamente dall'envelope reale di REAPER,
-- quindi resta attendibile anche dopo chiusura e riapertura.
------------------------------------------------------------
function fx_param_get_envelope(real_fx, param_i, create)
    real_fx = tonumber(real_fx)
    param_i = tonumber(param_i)

    if real_fx == nil or param_i == nil or param_i < 0 then
        return nil
    end

    create = create == true

    if ctx.kind == "take" then
        if ctx.take and reaper.TakeFX_GetEnvelope then
            local ok, env =
                pcall(
                    reaper.TakeFX_GetEnvelope,
                    ctx.take,
                    real_fx,
                    param_i,
                    create
                )

            if ok then
                return env
            end
        end

        return nil
    end

    if ctx.track and reaper.GetFXEnvelope then
        local ok, env =
            pcall(
                reaper.GetFXEnvelope,
                ctx.track,
                real_fx,
                param_i,
                create
            )

        if ok then
            return env
        end
    end

    return nil
end

function fx_param_current_real_fx_index()
    if type(get_current_real_fx_index) ~= "function" then
        return nil
    end

    return get_current_real_fx_index()
end

function fx_param_envelope_get_state(env)
    if not env then
        return nil
    end

    --------------------------------------------------------
    -- REAPER può esporre GetSetEnvelopeState2 oppure la
    -- versione classica. Inoltre, a seconda della firma,
    -- la stringa può arrivare come primo o secondo valore.
    --------------------------------------------------------
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

    return nil
end

function fx_param_envelope_set_state(env, state)
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

    return false
end

function fx_param_envelope_state_get_first_number(state, key)
    state = tostring(state or "")
    key = clean_one_line(key or "")

    if key == "" then
        return nil
    end

    local pattern = "^%s*" .. key .. "%s+([^%s]+)"

    for line in state:gmatch("[^\r\n]+") do
        local v = line:match(pattern)

        if v ~= nil then
            return tonumber(v)
        end
    end

    return nil
end

function fx_param_envelope_state_set_first_number(state, key, value, default_tail)
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

function fx_param_envelope_state_is_visible(state)
    local v = fx_param_envelope_state_get_first_number(state, "VIS")

    if v == nil then
        return nil
    end

    return v ~= 0
end

function fx_param_envelope_state_is_active(state)
    local v = fx_param_envelope_state_get_first_number(state, "ACT")

    if v == nil then
        return nil
    end

    return v ~= 0
end

function fx_param_envelope_state_set_visible(state, visible)
    visible = visible == true

    return fx_param_envelope_state_set_first_number(
        state,
        "VIS",
        visible and "1" or "0",
        "1 1"
    )
end

function fx_param_envelope_state_set_active(state, active)
    active = active == true

    return fx_param_envelope_state_set_first_number(
        state,
        "ACT",
        active and "1" or "0",
        "-1"
    )
end

function fx_param_envelope_is_visible(env)
    if not env then
        return false
    end

    local state = fx_param_envelope_get_state(env)

    if state ~= nil then
        local visible = fx_param_envelope_state_is_visible(state)

        if visible ~= nil then
            return visible == true
        end
    end

    if reaper.GetEnvelopeInfo_Value then
        local ok, value =
            pcall(reaper.GetEnvelopeInfo_Value, env, "B_VISIBLE")

        if ok then
            return tonumber(value) == 1
        end
    end

    return false
end

function fx_param_envelope_is_active(env)
    if not env then
        return false
    end

    local state = fx_param_envelope_get_state(env)

    if state ~= nil then
        local active = fx_param_envelope_state_is_active(state)

        if active ~= nil then
            return active == true
        end
    end

    if reaper.GetEnvelopeInfo_Value then
        local ok, value =
            pcall(reaper.GetEnvelopeInfo_Value, env, "B_ACTIVE")

        if ok then
            return tonumber(value) == 1
        end
    end

    return false
end

function fx_param_envelope_set_active_visible(env, active, visible)
    if not env then
        return false
    end

    active = active == true
    visible = visible == true

    local state = fx_param_envelope_get_state(env)

    if state ~= nil then
        local new_state = state

        ----------------------------------------------------
        -- Spegnimento reale:
        -- prima lo togliamo dalla vista, poi lo disattiviamo.
        -- Così il parametro viene liberato e non resta guidato
        -- da un envelope solo nascosto.
        ----------------------------------------------------
        if active then
            new_state = fx_param_envelope_state_set_active(new_state, true)
            new_state = fx_param_envelope_state_set_visible(new_state, visible)
        else
            new_state = fx_param_envelope_state_set_visible(new_state, false)
            new_state = fx_param_envelope_state_set_active(new_state, false)
        end

        if fx_param_envelope_set_state(env, new_state) then
            return true
        end
    end

    local ok_any = false

    if reaper.SetEnvelopeInfo_Value then
        local ok_visible =
            pcall(
                reaper.SetEnvelopeInfo_Value,
                env,
                "B_VISIBLE",
                visible and 1 or 0
            )

        local ok_active =
            pcall(
                reaper.SetEnvelopeInfo_Value,
                env,
                "B_ACTIVE",
                active and 1 or 0
            )

        ok_any = ok_visible or ok_active
    end

    return ok_any == true
end

function fx_param_envelope_set_visible(env, visible)
    --------------------------------------------------------
    -- Compatibilità con il vecchio nome funzione:
    -- visible=true accende anche ACT;
    -- visible=false spegne anche ACT.
    --------------------------------------------------------
    return fx_param_envelope_set_active_visible(env, visible == true, visible == true)
end

function fx_param_envelope_is_visible_for_param(param_i)
    param_i = tonumber(param_i)

    if param_i == nil or param_i < 0 then
        return false
    end

    local real_fx = fx_param_current_real_fx_index()

    if real_fx == nil then
        return false
    end

    local env = fx_param_get_envelope(real_fx, param_i, false)

    if not env then
        return false
    end

    return fx_param_envelope_is_visible(env)
end

function fx_param_envelope_is_active_for_param(param_i)
    param_i = tonumber(param_i)

    if param_i == nil or param_i < 0 then
        return false
    end

    local real_fx = fx_param_current_real_fx_index()

    if real_fx == nil then
        return false
    end

    local env = fx_param_get_envelope(real_fx, param_i, false)

    if not env then
        return false
    end

    return fx_param_envelope_is_active(env)
end

function fx_param_set_envelope_auto_for_param(param_i, active, create)
    param_i = tonumber(param_i)

    if param_i == nil or param_i < 0 then
        return false
    end

    local real_fx = fx_param_current_real_fx_index()

    if real_fx == nil then
        return false
    end

    local env = fx_param_get_envelope(real_fx, param_i, create == true)

    if not env then
        return false
    end

    return fx_param_envelope_set_active_visible(env, active == true, active == true)
end

function fx_param_set_envelope_visible_for_param(param_i, visible, create)
    return fx_param_set_envelope_auto_for_param(param_i, visible == true, create == true)
end

function get_param_automation_spoken_label(i)
    if fx_param_envelope_is_active_for_param(i) then
        return "Auto"
    end

    return ""
end

function get_param_label_for_param(i)
    i = tonumber(i) or 0

    local name = clean_one_line(get_param_display_name(i))
    local value = clean_one_line(get_param_value_formatted(i))
    local auto_label = ""
    local cc_label = ""

    if type(get_param_automation_spoken_label) == "function" then
        auto_label = clean_one_line(get_param_automation_spoken_label(i))
    end

    if type(get_param_cc_learn_spoken_label) == "function" then
        cc_label = clean_one_line(get_param_cc_learn_spoken_label(i))
    end

    if name == "" then
        name = "Parameter " .. tostring(i + 1)
    end

    local main = name

    if value ~= "" then
        main = main .. " " .. value
    end

    if auto_label ~= "" then
        main = main .. ". " .. auto_label
    end

    if cc_label ~= "" then
        main = main .. ". " .. cc_label
    end

    return main
end

function get_param_label()
    if fx_offline_grid_active then
        return get_fx_offline_grid_label()
    end

    return get_param_label_for_param(param_index)
end

function get_param_label_for_index(i)
    return get_param_label_for_param(i)
end

------------------------------------------------------------
-- 3.3 - STORAGE HELPERS: SOLO TXT PLUGIN
------------------------------------------------------------
function plugin_storage_available()
    if plugin_txt_loaded ~= true then
        return false
    end

    local current = clean_one_line(get_fx_raw_label())
    local loaded  = clean_one_line(plugin_txt_raw_fx_name or "")

    return current ~= "" and loaded ~= "" and current == loaded
end

function get_plugin_state_safe(key)
    if not plugin_storage_available() then
        return ""
    end

    key = tostring(key or "")

    if type(get_plugin_state) == "function" then
        local ok, value = pcall(get_plugin_state, key)

        if ok then
            return value or ""
        end
    end

    return ""
end

function set_plugin_state_safe(key, value)
    if not plugin_storage_available() then
        return
    end

    key = tostring(key or "")
    value = tostring(value or "")

    if type(set_plugin_state) == "function" then
        pcall(set_plugin_state, key, value)
    end
end

------------------------------------------------------------
-- Compatibilità vecchio doppio stato.
-- project_key viene ignorato.
------------------------------------------------------------
function get_dual_state(project_key, plugin_key)
    return get_plugin_state_safe(plugin_key)
end

function set_dual_state(project_key, plugin_key, value)
    set_plugin_state_safe(plugin_key, value)
end

------------------------------------------------------------
-- 3.4 - ID CONTESTO
------------------------------------------------------------
function get_context_storage_id()
    --------------------------------------------------------
    -- Take / item:
    -- - id stabile della traccia;
    -- - GUID dell'item;
    -- - nome take, se presente.
    --------------------------------------------------------
    if ctx.kind == "take" then
        local track_id = ""

        if ctx.track and type(get_track_memory_id) == "function" then
            track_id = get_track_memory_id(ctx.track, false)
        end

        if track_id == "" and ctx.track then
            local track_num =
                reaper.GetMediaTrackInfo_Value(ctx.track, "IP_TRACKNUMBER")

            local _, track_name = reaper.GetTrackName(ctx.track)

            track_id =
                "tracknum_" ..
                tostring(math.floor(tonumber(track_num) or 0)) ..
                "::" ..
                clean_one_line(track_name or "")
        end

        local item_guid = ""

        if ctx.item then
            if type(get_item_guid) == "function" then
                item_guid = get_item_guid(ctx.item)
            else
                local ok, _, guid =
                    pcall(
                        reaper.GetSetMediaItemInfo_String,
                        ctx.item,
                        "GUID",
                        "",
                        false
                    )

                if ok then
                    item_guid = clean_one_line(guid or "")
                end
            end
        end

        local take_name = ""

        if ctx.take then
            local ok, _, name =
                pcall(
                    reaper.GetSetMediaItemTakeInfo_String,
                    ctx.take,
                    "P_NAME",
                    "",
                    false
                )

            if ok then
                take_name = clean_one_line(name or "")
            end
        end

        return
            "take::" ..
            track_id ..
            "::item::" ..
            item_guid ..
            "::take::" ..
            take_name
    end

    --------------------------------------------------------
    -- Master.
    --------------------------------------------------------
    if ctx.is_master then
        return "track::MASTER"
    end

    --------------------------------------------------------
    -- Track normale.
    --------------------------------------------------------
    if ctx.track and type(get_track_memory_id) == "function" then
        return get_track_memory_id(ctx.track, false)
    end

    local guid = ""

    if ctx.track and reaper.GetTrackGUID then
        guid = clean_one_line(reaper.GetTrackGUID(ctx.track) or "")
    end

    if guid == "" and ctx.track then
        local track_num =
            reaper.GetMediaTrackInfo_Value(ctx.track, "IP_TRACKNUMBER")

        local _, track_name = reaper.GetTrackName(ctx.track)

        guid =
            "tracknum_" ..
            tostring(math.floor(tonumber(track_num) or 0)) ..
            "::" ..
            clean_one_line(track_name or "")
    end

    return "track::" .. guid
end

------------------------------------------------------------
-- 3.4A - CHIAVI PROJECT DISATTIVATE / COMPATIBILITÀ
------------------------------------------------------------
function get_project_group_key()
    return "disabled_project_group_key"
end

function get_project_group_slot_key(slot)
    slot = clamp_int(slot, 1, 12)

    return "disabled_project_group_slot_" .. tostring(slot)
end

function get_project_param_slot_key(slot)
    slot = clamp_int(slot, 1, 12)

    return "disabled_project_param_slot_" .. tostring(slot)
end

------------------------------------------------------------
-- 3.5 - CHIAVI DI STORAGE PLUGIN TXT
------------------------------------------------------------
function get_plugin_group_key()
    return "temporary_group_v1"
end

function get_plugin_group_slot_key(slot)
    slot = clamp_int(slot, 1, 12)

    return "group_slot_v1::slot::" .. tostring(slot)
end

function get_plugin_group_slot_name_key(slot)
    slot = clamp_int(slot, 1, 12)

    return "group_slot_name_v1::slot::" .. tostring(slot)
end

------------------------------------------------------------
-- Posizione indipendente per ciascun Group reale.
-- Viene salvata in Extra del TXT del plugin e non ha alcun
-- legame con LastParam, Plugin order o Custom order.
------------------------------------------------------------
function get_plugin_group_last_position_key(slot)
    slot = clamp_int(slot, 1, 12)

    return "group_last_position_v1::slot::" .. tostring(slot)
end

function get_plugin_param_slot_key(slot)
    slot = clamp_int(slot, 1, 12)

    return "param_memory_slot_v1::slot::" .. tostring(slot)
end

function get_plugin_last_param_key()
    return "last_param_v1"
end

function get_plugin_last_entry_key()
    return "last_entry_v1"
end

function get_plugin_last_area_key()
    return "last_area_v1"
end

function get_plugin_custom_order_key()
    return "custom_order_v1"
end

function get_plugin_hidden_params_key()
    return "hidden_params_v1"
end

------------------------------------------------------------
-- 3.5A - NOMI GRUPPI
------------------------------------------------------------
function get_group_slot_name(slot)
    slot = clamp_int(slot, 1, 12)

    return clean_one_line(
        get_plugin_state_safe(get_plugin_group_slot_name_key(slot)) or ""
    )
end

function set_group_slot_name(slot, name, save_now)
    slot = clamp_int(slot, 1, 12)
    name = clean_one_line(name or "")

    set_plugin_state_safe(
        get_plugin_group_slot_name_key(slot),
        name
    )

    --------------------------------------------------------
    -- Normalmente rinominare un gruppo è un gesto esplicito,
    -- quindi salva subito.
    -- Quando invece questa funzione viene usata dentro una
    -- cancellazione più grande, il chiamante può passare false
    -- e fare un solo salvataggio finale.
    --------------------------------------------------------
    if save_now ~= false then
        plugin_txt_save_if_dirty(true)
    end
end

function get_group_slot_status_label(slot)
    slot = clamp_int(slot, 1, 12)

    local txt = get_saved_group_slot_text(slot)
    local count = count_saved_group_text(txt or "")

    if count <= 0 then
        return nil
    end

    local name = get_group_slot_name(slot)

    if name ~= "" then
        return name .. ". " .. tostring(count) .. " parameters"
    end

    return
        "Group " ..
        tostring(slot) ..
        ". " ..
        tostring(count) ..
        " parameters"
end

------------------------------------------------------------
-- 3.6 - CUSTOM ORDER: STATO E TXT PLUGIN
------------------------------------------------------------
custom_order_active = false
custom_order_indices = {}
custom_order_dirty = false
custom_param_aliases = custom_param_aliases or {}

function custom_order_clear_runtime()
    custom_order_active = false
    custom_order_indices = {}
    custom_order_dirty = false
    custom_param_aliases = {}
end

function custom_order_make_plugin_order()
    local out = {}

    if is_current_fx_reaeq and is_current_fx_reaeq() then
        out = reaeq_build_default_param_indices()

    elseif is_current_fx_reacomp and is_current_fx_reacomp() then
        out = reacomp_build_default_param_indices()

    elseif is_current_fx_reagate and is_current_fx_reagate() then
        out = reagate_build_default_param_indices()

    else
        for i = 0, param_count - 1 do
            out[#out + 1] = i
        end
    end

    return fx_compare_insert_into_param_list(out)
end

function custom_order_contains_index(list, wanted)
    if not list then
        return false
    end

    wanted = tonumber(wanted)

    if wanted == nil then
        return false
    end

    for i = 1, #list do
        if tonumber(list[i]) == wanted then
            return true
        end
    end

    return false
end

function custom_order_is_complete(list)
    if not list then
        return false
    end

    local base = custom_order_make_plugin_order()

    --------------------------------------------------------
    -- Ora la Custom order può contenere copie volontarie.
    -- Quindi non richiediamo più #list == #base: richiediamo
    -- solo che tutti i parametri base siano presenti almeno una
    -- volta. Le occorrenze extra sono gestite da F8.
    --------------------------------------------------------
    local seen = {}

    for i = 1, #list do
        local index = tonumber(list[i])

        if index ~= nil then
            seen[math.floor(index + 0.5)] = true
        end
    end

    for i = 1, #base do
        local index = tonumber(base[i])

        if index == nil or not seen[math.floor(index + 0.5)] then
            return false
        end
    end

    return true
end

function custom_order_normalize_list(list)
    local out = {}
    local present = {}

    list = list or {}

    --------------------------------------------------------
    -- Mantiene l'ordine salvato e ora conserva anche le copie
    -- volontarie create con Ctrl+C. Prima questa funzione
    -- eliminava ogni duplicato; ora controlla solo che ogni
    -- parametro reale del plugin resti presente almeno una volta.
    --------------------------------------------------------
    for i = 1, #list do
        local index = tonumber(list[i])

        if index ~= nil then
            index = math.floor(index + 0.5)

            if param_index_is_valid(index) then
                out[#out + 1] = index
                present[index] = true
            end
        end
    end

    --------------------------------------------------------
    -- Poi aggiunge eventuali parametri nuovi mancanti, inclusi
    -- i virtuali ReaEQ/Compare. Le copie già presenti restano.
    --------------------------------------------------------
    local base = custom_order_make_plugin_order()

    for i = 1, #base do
        local index = base[i]

        if not present[index] then
            present[index] = true
            out[#out + 1] = index
        end
    end

    return out
end

------------------------------------------------------------
-- 3.6L - CUSTOM ORDER LAZY / PERSISTENZA SOLO SU MODIFICA
--
-- Ctrl+L può aprire una Custom order virtuale identica alla
-- Plugin order, ma quel semplice accesso NON deve creare memoria.
-- La memoria Custom esiste soltanto quando c'è almeno una
-- differenza strutturale reale:
-- - ordine diverso;
-- - copie/duplicati;
-- - alias parametro;
-- - parametri nascosti.
-- I valori audio/VST dei parametri NON fanno parte di questo stato.
------------------------------------------------------------
function custom_order_list_equals_plugin_order(list)
    list = list or custom_order_indices or {}

    local base = custom_order_make_plugin_order()

    if #list ~= #base then
        return false
    end

    for pos = 1, #base do
        local a = tonumber(list[pos])
        local b = tonumber(base[pos])

        if a == nil or b == nil or
           math.floor(a + 0.5) ~= math.floor(b + 0.5) then
            return false
        end
    end

    return true
end

function custom_order_has_param_aliases()
    for _, alias in pairs(custom_param_aliases or {}) do
        if clean_one_line(alias or "") ~= "" then
            return true
        end
    end

    return false
end

function custom_order_has_hidden_params_runtime()
    for _, hidden in pairs(hidden_param_selected or {}) do
        if hidden == true then
            return true
        end
    end

    return false
end

function custom_order_has_real_modifications()
    if param_count <= 0 then
        return false
    end

    if not custom_order_list_equals_plugin_order(custom_order_indices) then
        return true
    end

    if custom_order_has_param_aliases() then
        return true
    end

    if custom_order_has_hidden_params_runtime() then
        return true
    end

    return false
end

function custom_order_serialize_indices(list)
    local lines = {}

    list = custom_order_normalize_list(list or custom_order_indices)

    for pos = 1, #list do
        local i = list[pos]
        local original_name = get_param_original_name(i)
        local alias = clean_one_line(custom_param_aliases[i] or "")

        if alias ~= "" then
            lines[#lines + 1] =
                tostring(i) ..
                "\t" ..
                original_name ..
                "\t" ..
                alias
        else
            lines[#lines + 1] =
                tostring(i) ..
                "\t" ..
                original_name
        end
    end

    return table.concat(lines, "\n")
end

function get_custom_order_text()
    return get_plugin_state_safe(get_plugin_custom_order_key())
end

function set_custom_order_text(txt, save_now)
    set_plugin_state_safe(get_plugin_custom_order_key(), txt or "")

    if save_now == false then
        plugin_txt_save_if_dirty(false)
    else
        plugin_txt_save_if_dirty(true)
    end
end

function plugin_txt_custom_order_has_content()
    return trim(get_custom_order_text() or "") ~= ""
end

function plugin_txt_clear_custom_order()
    set_custom_order_text("")

    if plugin_txt_loaded and type(plugin_txt_set_custom_order_view) == "function" then
        plugin_txt_set_custom_order_view("plugin")
        plugin_txt_save_if_dirty()
    end
end

function custom_order_resolve_saved_param_fast(index_s, name)
    local saved_index = tonumber(index_s)

    --------------------------------------------------------
    -- Custom order può contenere centinaia o migliaia di righe.
    -- Qui l'indice salvato è il riferimento principale.
    -- Evita di fare, per ogni riga, una scansione completa
    -- dei nomi parametro: su plugin da 900 parametri quello
    -- diventava molto lento all'apertura se il TXT ricordava
    -- Custom order come vista attiva.
    --------------------------------------------------------
    if saved_index ~= nil then
        saved_index = math.floor(saved_index + 0.5)

        if saved_index >= 0 and saved_index <= param_count - 1 then
            return saved_index
        end

        if reaeq_virtual_param_is_valid and
           reaeq_virtual_param_is_valid(saved_index) then
            return saved_index
        end

        if fx_compare_param_is_valid and
           fx_compare_param_is_valid(saved_index) then
            return saved_index
        end
    end

    --------------------------------------------------------
    -- Fallback di compatibilità: se l'indice non è più valido,
    -- prova ancora per nome. Questo è più lento, ma avviene solo
    -- per righe problematiche o vecchi TXT.
    --------------------------------------------------------
    return resolve_saved_param(index_s, name)
end

function custom_order_parse_text(txt)
    local raw = {}

    custom_param_aliases = {}

    txt = txt or ""

    for line in txt:gmatch("[^\r\n]+") do
        line = trim(line)

        if line ~= "" then
            local index_s, original_name, alias =
                parse_custom_order_line(line)

            local found = custom_order_resolve_saved_param_fast(
                index_s,
                original_name
            )

            if found ~= nil then
                raw[#raw + 1] = found

                alias = clean_one_line(alias or "")

                if alias ~= "" then
                    custom_param_aliases[found] = alias
                end
            end
        end
    end

    return custom_order_normalize_list(raw)
end

function load_custom_order_runtime_from_txt()
    custom_order_clear_runtime()

load_hidden_params_from_txt()

    if param_count <= 0 then
        return false
    end

    local txt = trim(get_custom_order_text() or "")

    if txt == "" then
        return false
    end

    custom_order_indices = custom_order_parse_text(txt)

    if not custom_order_is_complete(custom_order_indices) then
        custom_order_indices =
            custom_order_normalize_list(custom_order_indices)
    end

    custom_order_active = true
    custom_order_dirty = false

    --------------------------------------------------------
    -- Compatibilità con versioni precedenti: se nel TXT esiste
    -- una Custom salvata che in realtà è identica alla Plugin
    -- order e non contiene alias/hidden, la eliminiamo.
    --------------------------------------------------------
    if not custom_order_has_real_modifications() then
        set_plugin_state_safe(get_plugin_custom_order_key(), "")

        if plugin_txt_loaded and
           type(plugin_txt_set_custom_order_view) == "function" then
            plugin_txt_set_custom_order_view("plugin")
        end

        plugin_txt_save_if_dirty(false)
        custom_order_active = false
        custom_order_dirty = false
        return false
    end

    return true
end

function save_custom_order_runtime_to_txt(save_now)
    if param_count <= 0 then
        return false
    end

    custom_order_indices =
        custom_order_normalize_list(custom_order_indices)

    --------------------------------------------------------
    -- Se la Custom è tornata perfettamente uguale alla Plugin
    -- order, non deve esistere una memoria Custom persistente.
    -- La vista può restare Custom per la sessione corrente, ma
    -- al prossimo caricamento resterà soltanto il Default.
    --------------------------------------------------------
    if not custom_order_has_real_modifications() then
        set_plugin_state_safe(get_plugin_custom_order_key(), "")

        if plugin_txt_loaded and
           type(plugin_txt_set_custom_order_view) == "function" then
            plugin_txt_set_custom_order_view("plugin")
        end

        if save_now == false then
            plugin_txt_save_if_dirty(false)
        else
            plugin_txt_save_if_dirty(true)
        end

        custom_order_dirty = false
        return true
    end

    --------------------------------------------------------
    -- Prima differenza reale: da questo momento nasce la
    -- memoria Custom. Se siamo davvero nella vista Custom,
    -- ricordiamo anche quella vista; da un Group lasciamo invece
    -- invariata la vista sottostante Plugin/Custom.
    --------------------------------------------------------
    if custom_order_active and plugin_txt_loaded and
       type(plugin_txt_set_custom_order_view) == "function" then
        plugin_txt_set_custom_order_view("custom")
    end

    local txt = custom_order_serialize_indices(custom_order_indices)
    set_custom_order_text(txt, save_now)

    custom_order_dirty = false

    return true
end

function ensure_custom_order_runtime()
    if param_count <= 0 then
        return false
    end

    if custom_order_is_complete(custom_order_indices) then
        return true
    end

    custom_order_indices = custom_order_make_plugin_order()

    return true
end

function activate_custom_order_from_current_grid()
    if param_count <= 0 then
        speak("No parameter")
        return false
    end

    save_active_grid_size_to_txt()

    --------------------------------------------------------
    -- Ctrl+L deve essere leggero.
    -- Se il Custom order è già stato caricato in memoria per
    -- questo FX, non rilegge e non riparsa il TXT a ogni toggle.
    -- Su plugin con centinaia di parametri questo evita il blocco
    -- lungo al secondo/terzo ingresso in Custom order.
    --------------------------------------------------------
    if custom_order_is_complete(custom_order_indices) then
        custom_order_active = true
        load_hidden_params_from_txt()

    elseif plugin_txt_custom_order_has_content() then
        if not load_custom_order_runtime_from_txt() then
            custom_order_indices = custom_order_make_plugin_order()
            custom_order_active = true
        end

    else
        ----------------------------------------------------
        -- Prima apertura Custom: soltanto runtime.
        -- Nessuna memoria viene creata finché F7 non produce
        -- una vera modifica strutturale.
        ----------------------------------------------------
        custom_order_indices = custom_order_make_plugin_order()
        custom_order_active = true
        custom_order_dirty = false
    end

    rebuild_group_results_from_selected()

    if not set_param_index_absolute(param_index, false) then
        active_pos = 1
        sync_param_from_active_pos()
    end

    save_current_param_position()

    --------------------------------------------------------
    -- Anche la vista Custom diventa persistente soltanto dopo
    -- che esiste davvero una memoria Custom. Il semplice Ctrl+L
    -- su una copia identica alla Plugin order resta virtuale.
    --------------------------------------------------------
    if plugin_txt_custom_order_has_content() and
       type(plugin_txt_set_custom_order_view) == "function" then
        plugin_txt_set_custom_order_view("custom")
        plugin_txt_save_if_dirty(false)
    end

    restore_active_grid_size_from_txt()

    return true
end

function deactivate_custom_order()
    save_active_grid_size_to_txt()

    custom_order_active = false
    custom_order_dirty = false

    rebuild_group_results_from_selected()

    if not set_param_index_absolute(param_index, false) then
        active_pos = 1
        sync_param_from_active_pos()
    end

    save_current_param_position()

    if type(plugin_txt_set_custom_order_view) == "function" then
        plugin_txt_set_custom_order_view("plugin")
        plugin_txt_save_if_dirty(false)
    end

    restore_active_grid_size_from_txt()

    return true
end

function toggle_custom_order_mode()
    clear_param_memory_arm()
    disarm_slot_deletes()

    if custom_order_active then
        deactivate_custom_order()
        announce_grid_context("Plugin order")
        return true
    end

    if activate_custom_order_from_current_grid() then
        announce_grid_context("Custom order")
        return true
    end

    return false
end

function get_custom_order_memory_label()
    if not plugin_txt_custom_order_has_content() then
        return nil
    end

    local txt = get_custom_order_text()
    local list = custom_order_parse_text(txt)
    local count = #list

    if count <= 0 then
        return nil
    end

    return tostring(count) .. " parameters"
end

function load_custom_order_from_memory(speak_it)
    if not plugin_txt_custom_order_has_content() then
        if speak_it then
            speak("No custom order")
        end

        return false
    end

    if not load_custom_order_runtime_from_txt() then
        if speak_it then
            speak("No custom order")
        end

        return false
    end

    rebuild_group_results_from_selected()

    if not set_param_index_absolute(param_index, false) then
        active_pos = 1
        sync_param_from_active_pos()
    end

    save_current_param_position()

    if speak_it then
        announce_grid_context("Custom order")
    end

    return true
end

function delete_custom_order_memory(silent)
    plugin_txt_clear_custom_order()
    plugin_txt_save_if_dirty()

    custom_order_clear_runtime()

    build_all_param_indices()
    rebuild_group_results_from_selected()

    if not set_param_index_absolute(param_index, false) then
        active_pos = 1
        sync_param_from_active_pos()
    end

    save_current_param_position()

    if not silent then
        speak("Custom order deleted")
    end

    return true
end

------------------------------------------------------------
-- 3.6B - HIDDEN PARAMETERS IN CUSTOM ORDER
------------------------------------------------------------
function get_hidden_params_text()
    return get_plugin_state_safe(get_plugin_hidden_params_key())
end

function set_hidden_params_text(txt, save_now)
    set_plugin_state_safe(get_plugin_hidden_params_key(), txt or "")

    if save_now == false then
        plugin_txt_save_if_dirty(false)
    else
        plugin_txt_save_if_dirty(true)
    end
end

function hidden_params_clear_runtime()
    hidden_param_selected = {}
end

function hidden_params_count()
    local count = 0

    for _, v in pairs(hidden_param_selected or {}) do
        if v then
            count = count + 1
        end
    end

    return count
end

function hidden_param_is_hidden(i)
    i = tonumber(i)

    if i == nil then
        return false
    end

    return hidden_param_selected[i] == true
end

function hidden_params_serialize()
    local lines = {}
    local base = custom_order_make_plugin_order()

    for pos = 1, #base do
        local i = base[pos]

        if hidden_param_selected[i] then
            lines[#lines + 1] =
                tostring(i) ..
                "\t" ..
                clean_one_line(get_param_name(i))
        end
    end

    return table.concat(lines, "\n")
end

function hidden_params_parse_text(txt)
    hidden_param_selected = {}

    txt = tostring(txt or "")

    for line in txt:gmatch("[^\r\n]+") do
        line = trim(line)

        if line ~= "" then
            local index_s, name = parse_param_line(line)
            local found = resolve_saved_param(index_s, name)

            if found ~= nil then
                hidden_param_selected[found] = true
            end
        end
    end

    return hidden_params_count() > 0
end

function load_hidden_params_from_txt()
    hidden_params_clear_runtime()

    local txt = get_hidden_params_text()

    if trim(txt or "") == "" then
        return false
    end

    return hidden_params_parse_text(txt)
end

function save_hidden_params_to_txt()
    --------------------------------------------------------
    -- Hidden è una modifica strutturale Custom. Scriviamo prima
    -- lo stato hidden nel profilo in memoria e poi lasciamo che
    -- il salvataggio Custom decida se creare la memoria oppure,
    -- quando l'ultimo hidden è stato ripristinato e non restano
    -- altre differenze, eliminarla di nuovo.
    --------------------------------------------------------
    set_hidden_params_text(hidden_params_serialize(), false)
    ensure_custom_order_runtime()
    save_custom_order_runtime_to_txt(true)
    return true
end

function hide_current_param_in_custom_order()
    clear_param_memory_arm()
    disarm_slot_deletes()

    if not param_index_is_valid(param_index) then
        speak("No parameter")
        return false
    end

    local i = param_index
    local hidden_label = get_param_label_for_index(i)

    --------------------------------------------------------
    -- Hide è una modifica strutturale: funziona soltanto quando
    -- l'utente è già entrato intenzionalmente in Custom con Ctrl+L.
    --------------------------------------------------------
    if not custom_order_require_active_for_structural_edit() then
        return false
    end

    --------------------------------------------------------
    -- Carica lo stato hidden corrente dal TXT, così non
    -- sovrascriviamo eventuali parametri già nascosti.
    --------------------------------------------------------
    if type(load_hidden_params_from_txt) == "function" then
        load_hidden_params_from_txt()
    end

    if hidden_param_selected[i] then
        speak("Already hidden. " .. hidden_label)
        return false
    end

    hidden_param_selected[i] = true
    save_hidden_params_to_txt()

    --------------------------------------------------------
    -- Ricostruisce le liste. Da questo momento il parametro
    -- nascosto non appare più nella Custom order.
    --------------------------------------------------------
    build_all_param_indices()
    rebuild_group_results_from_selected()

    if search_active and type(refresh_search_results) == "function" then
        refresh_search_results()
    end

    local visible = get_active_indices()

    if #visible <= 0 then
        active_pos = 1
        param_index = 0

        save_current_entry_state()
        speak("Hidden. No visible parameters")
        return true
    end

    --------------------------------------------------------
    -- Il parametro appena nascosto non può più essere trovato.
    -- Quindi resta nella posizione più vicina possibile.
    --------------------------------------------------------
    active_pos = clamp_int(active_pos, 1, #visible)
    sync_param_from_active_pos()

    save_current_param_position()
    save_current_entry_state()
    save_current_area_state("grid")

    if type(plugin_txt_set_custom_order_view) == "function" then
        plugin_txt_set_custom_order_view("custom")
        plugin_txt_save_if_dirty(false)
    end

    speak("Hidden. " .. get_current_param_spoken_label())

    return true
end


function hide_f7_selected_params_in_custom_order()
    clear_param_memory_arm()
    disarm_slot_deletes()

    --------------------------------------------------------
    -- Solo F7:
    -- Ctrl+Delete deve nascondere tutti i parametri selezionati.
    -- Se non c'è una selezione, resta coerente col comportamento
    -- precedente e nasconde solo il parametro corrente.
    --------------------------------------------------------
    if mode ~= "group_edit" then
        return hide_current_param_in_custom_order()
    end

    local selected_block = {}
    local seen = {}
    local base = get_full_grid_indices()

    for pos = 1, #base do
        local i = tonumber(base[pos])

        if i ~= nil and group_selected[i] and not seen[i] then
            if param_index_is_valid(i) then
                selected_block[#selected_block + 1] = i
                seen[i] = true
            end
        end
    end

    if #selected_block <= 0 then
        return hide_current_param_in_custom_order()
    end

    --------------------------------------------------------
    -- F7 non autorizza da solo modifiche alla Plugin order.
    -- Per nascondere in massa bisogna essere già in Custom.
    --------------------------------------------------------
    if not custom_order_require_active_for_structural_edit() then
        return false
    end

    if type(load_hidden_params_from_txt) == "function" then
        load_hidden_params_from_txt()
    end

    local added = 0

    for n = 1, #selected_block do
        local i = selected_block[n]

        if not hidden_param_selected[i] then
            hidden_param_selected[i] = true
            added = added + 1
        end

        group_selected[i] = nil
    end

    if added <= 0 then
        speak("Already hidden")
        return false
    end

    save_hidden_params_to_txt()

    build_all_param_indices()
    rebuild_group_results_from_selected()

    if search_active and type(refresh_search_results) == "function" then
        refresh_search_results()
    end

    search_active = false
    group_active = false
    search_results = {}
    group_results = {}

    set_f7_group_edit_context()

    if type(group_edit_snapshot_base_selection) == "function" then
        group_edit_snapshot_base_selection()
    end

    local visible = get_active_indices()

    if #visible <= 0 then
        active_pos = 1
        param_index = 0

        group_select_path = {}
        group_select_dir_path = {}
        group_select_path_lookup = {}

        save_f7_runtime_selection_for_current_fx()
        save_current_entry_state()
        save_current_area_state("grid")

        speak("Hidden " .. tostring(added) .. " parameters. No visible parameters")
        return true
    end

    active_pos = clamp_int(active_pos, 1, #visible)
    sync_param_from_active_pos()

    group_edit_reset_path_to_pos(active_pos)
    save_f7_runtime_selection_for_current_fx()

    save_current_param_position()
    save_current_entry_state()
    save_current_area_state("grid")

    if type(plugin_txt_set_custom_order_view) == "function" then
        plugin_txt_set_custom_order_view("custom")
        plugin_txt_save_if_dirty(false)
    end

    if added == 1 then
        speak("Hidden 1 parameter. " .. get_current_param_spoken_label())
    else
        speak(
            "Hidden " ..
            tostring(added) ..
            " parameters. " ..
            get_current_param_spoken_label()
        )
    end

    return true
end

function unhide_param(i, speak_it)
    i = tonumber(i)

    if i == nil then
        return false
    end

    if not hidden_param_selected[i] then
        if speak_it then
            speak("Not hidden")
        end

        return false
    end

    hidden_param_selected[i] = nil
    save_hidden_params_to_txt()

    build_all_param_indices()
    rebuild_group_results_from_selected()

    if custom_order_active then
        set_param_index_absolute(i, false)
        save_current_param_position()
    end

    if speak_it then
        speak("Restored. " .. get_param_label_for_index(i))
    end

    return true
end

function unhide_custom_order_param(i, speak_it)
    return unhide_param(i, speak_it)
end

------------------------------------------------------------
-- 3.6A - CUSTOM ORDER: VISTA ATTIVA PERSISTENTE
------------------------------------------------------------
function save_custom_order_view_to_txt()
    if not plugin_txt_loaded then
        return false
    end

    if custom_order_active and plugin_txt_custom_order_has_content() then
        plugin_txt_set_custom_order_view("custom")
    else
        plugin_txt_set_custom_order_view("plugin")
    end

    plugin_txt_save_if_dirty()

    return true
end

function save_custom_order_to_txt()
    if custom_order_active then
        ensure_custom_order_runtime()
        save_custom_order_runtime_to_txt()
    end

    save_custom_order_view_to_txt()

    return true
end

function load_custom_order_from_txt()
    custom_order_clear_runtime()

    if param_count <= 0 then
        return false
    end

    if not plugin_txt_loaded then
        return false
    end

    local view = "plugin"

    if type(plugin_txt_get_custom_order_view) == "function" then
        view = plugin_txt_get_custom_order_view()
    end

    view = clean_one_line(view or "")

    --------------------------------------------------------
    -- Carica sempre i dati della Custom order se esistono,
    -- anche quando la vista ricordata è Plugin order.
    -- Serve perché gli alias dei parametri sono ora globali
    -- alla vista e devono essere disponibili ovunque.
    --------------------------------------------------------
    if not plugin_txt_custom_order_has_content() then
        custom_order_active = false

        if view == "custom" and
           type(plugin_txt_set_custom_order_view) == "function" then

            plugin_txt_set_custom_order_view("plugin")
            plugin_txt_save_if_dirty()
        end

        return false
    end

    if not load_custom_order_runtime_from_txt() then
        custom_order_active = false
        custom_order_dirty = false
        return false
    end

    custom_order_active = (view == "custom")
    custom_order_dirty = false

    return custom_order_active
end

function apply_custom_order_to_all_params()
    if custom_order_active then
        custom_order_indices =
            custom_order_normalize_list(custom_order_indices)
    end

    return true
end

function set_custom_order_active(active, speak_it)
    clear_param_memory_arm()
    disarm_slot_deletes()

    local old_param = param_index

    if active then
        if plugin_txt_custom_order_has_content() then
            if not load_custom_order_runtime_from_txt() then
                custom_order_indices = custom_order_make_plugin_order()
            end
        else
            custom_order_indices = custom_order_make_plugin_order()
        end

        custom_order_active = true
        custom_order_dirty = false

        if plugin_txt_custom_order_has_content() and
           type(plugin_txt_set_custom_order_view) == "function" then
            plugin_txt_set_custom_order_view("custom")
            plugin_txt_save_if_dirty()
        end

    else
        custom_order_active = false
        custom_order_dirty = false

        if type(plugin_txt_set_custom_order_view) == "function" then
            plugin_txt_set_custom_order_view("plugin")
            plugin_txt_save_if_dirty()
        end
    end

    rebuild_group_results_from_selected()

    if search_active and type(refresh_search_results) == "function" then
        refresh_search_results()
    end

    if not set_param_index_absolute(old_param, false) then
        active_pos = 1
        sync_param_from_active_pos()
    end

    save_current_param_position()

    if speak_it then
        if custom_order_active then
            announce_grid_context("Custom order")
        else
            announce_grid_context("Plugin order")
        end
    end

    return true
end

------------------------------------------------------------
-- 3.7 - LAST PARAM MEMORY
------------------------------------------------------------
function get_last_param_key()
    return get_plugin_last_param_key()
end

function save_current_param_position()
    if not param_index_is_valid(param_index) then
        return
    end

    if type(param_step_scale_sync_for_current_param) == "function" then
        param_step_scale_sync_for_current_param()
    end

    --------------------------------------------------------
    -- Floating CC:
    -- ogni volta che lo script salva una nuova posizione
    -- parametro, controlla se il parametro è cambiato.
    -- Se è cambiato, il pickup viene riarma-to sul valore reale
    -- del parametro corrente.
    --------------------------------------------------------
    if type(cc_focus_arm_pickup_for_current_param) == "function" then
        cc_focus_arm_pickup_for_current_param()
    end

    local name = clean_one_line(get_param_name(param_index))

    if name == "" then
        name = "Parameter " .. tostring(param_index + 1)
    end

    local value =
        tostring(param_index) ..
        "\t" ..
        name

    set_plugin_state_safe(
        get_plugin_last_param_key(),
        value
    )

    --------------------------------------------------------
    -- Se siamo dentro un Group reale, aggiorna anche la sua
    -- posizione privata. Non modifica Custom order o Plugin order.
    --------------------------------------------------------
    if type(save_current_group_position) == "function" then
        save_current_group_position()
    end

    --------------------------------------------------------
    -- Salvataggio TXT più leggero:
    -- LastParam serve a ricordare dove eri, ma non è un gesto
    -- esplicito dell'utente come salvare un gruppo, un CC o un
    -- Default. Quindi aggiorniamo il profilo in memoria e lo
    -- lasciamo dirty, ma NON scriviamo il TXT a ogni cambio
    -- parametro.
    --
    -- Il valore verrà scritto quando serve davvero:
    -- cambio FX/contesto, uscita, oppure un altro salvataggio
    -- esplicito già necessario.
    --------------------------------------------------------
    if plugin_txt_loaded and value ~= plugin_txt_last_saved_param_position then
        plugin_txt_last_saved_param_position = value
        plugin_txt_save_if_dirty(false)
    end
end

------------------------------------------------------------
-- 3.7A - LAST POSITION MEMORY PER GROUP
--
-- Ogni Group conserva la propria posizione indipendentemente
-- da Plugin order, Custom order e dagli altri Group.
-- Salviamo anche l'occorrenza (active_pos), non soltanto il
-- param_index, perche' un Group puo' contenere duplicati.
------------------------------------------------------------
function get_current_group_position_slot()
    if group_active and current_group_slot ~= nil then
        return clamp_int(current_group_slot, 1, 12)
    end

    if mode == "group_edit" and
       group_edit_loaded_slot ~= nil and
       group_edit_show_all_params ~= true then

        return clamp_int(group_edit_loaded_slot, 1, 12)
    end

    return nil
end

function save_current_group_position()
    local slot = get_current_group_position_slot()

    if slot == nil then
        return false
    end

    local list = group_results or {}

    if #list <= 0 then
        return false
    end

    local pos = clamp_int(active_pos, 1, #list)
    local i = tonumber(list[pos])

    if i == nil then
        return false
    end

    i = math.floor(i + 0.5)

    local name = clean_one_line(get_param_name(i))

    if name == "" then
        name = "Parameter " .. tostring(i + 1)
    end

    local value =
        tostring(pos) ..
        "\t" ..
        tostring(i) ..
        "\t" ..
        name

    set_plugin_state_safe(
        get_plugin_group_last_position_key(slot),
        value
    )

    return true
end

function restore_group_last_position(slot)
    slot = clamp_int(slot, 1, 12)

    local list = group_results or {}

    if #list <= 0 then
        return false
    end

    local saved = trim(
        get_plugin_state_safe(
            get_plugin_group_last_position_key(slot)
        ) or ""
    )

    if saved == "" then
        return false
    end

    local pos_s, index_s, name =
        saved:match("^(%d+)%s*\t%s*(%-?%d+)%s*\t%s*(.*)$")

    local saved_pos = tonumber(pos_s)
    local saved_index = tonumber(index_s)

    name = clean_one_line(name or "")

    --------------------------------------------------------
    -- Prima scelta: stessa OCCORRENZA e stesso parametro.
    -- E' il caso normale quando si cambia Group e si ritorna.
    --------------------------------------------------------
    if saved_pos ~= nil then
        saved_pos = math.floor(saved_pos + 0.5)

        if saved_pos >= 1 and saved_pos <= #list then
            local i = tonumber(list[saved_pos])

            if i ~= nil then
                i = math.floor(i + 0.5)

                if saved_index == nil or i == saved_index then
                    active_pos = saved_pos
                    sync_param_from_active_pos()
                    return true
                end
            end
        end
    end

    --------------------------------------------------------
    -- Se il Group e' stato riordinato, prova a ritrovare lo
    -- stesso parametro. Con duplicati usa la prima occorrenza
    -- compatibile, dato che la vecchia posizione non esiste piu'.
    --------------------------------------------------------
    if saved_index ~= nil then
        saved_index = math.floor(saved_index + 0.5)

        for pos = 1, #list do
            local i = tonumber(list[pos])

            if i ~= nil and math.floor(i + 0.5) == saved_index then
                local pname = clean_one_line(get_param_name(i))

                if name == "" or pname == name then
                    active_pos = pos
                    sync_param_from_active_pos()
                    return true
                end
            end
        end
    end

    --------------------------------------------------------
    -- Ultimo fallback per nome, utile se il parametro reale
    -- mantiene il nome ma cambia indice fra versioni del plugin.
    --------------------------------------------------------
    if name ~= "" then
        local wanted = name:lower()

        for pos = 1, #list do
            local i = tonumber(list[pos])

            if i ~= nil then
                local pname = clean_one_line(get_param_name(i)):lower()

                if pname == wanted then
                    active_pos = pos
                    sync_param_from_active_pos()
                    return true
                end
            end
        end
    end

    return false
end

function restore_last_param_position()
    if param_count <= 0 then
        return false
    end

    local saved =
        trim(get_plugin_state_safe(get_plugin_last_param_key()) or "")

    if saved == "" then
        return false
    end

    local index_s, name =
        saved:match("^(%-?%d+)%s*\t%s*(.*)$")

    local saved_index = tonumber(index_s)

    name = clean_one_line(name or "")

    --------------------------------------------------------
    -- Prima prova per nome nella griglia completa.
    --------------------------------------------------------
    if name ~= "" then
        local wanted = name:lower()
        local base = get_full_grid_indices()

        for pos = 1, #base do
            local i = base[pos]
            local pname = clean_one_line(get_param_name(i)):lower()

            if pname == wanted then
                return set_param_index_absolute(i, false)
            end
        end
    end

    --------------------------------------------------------
    -- Fallback per indice reale.
    --------------------------------------------------------
    if saved_index ~= nil and
       saved_index >= 0 and
       saved_index <= param_count - 1 then

        return set_param_index_absolute(
            math.floor(saved_index + 0.5),
            false
        )
    end

    --------------------------------------------------------
    -- Fallback per indice virtuale ReaEQ.
    --------------------------------------------------------
    if saved_index ~= nil and reaeq_virtual_param_is_valid(saved_index) then
        return set_param_index_absolute(
            math.floor(saved_index + 0.5),
            false
        )
    end

    return false
end

------------------------------------------------------------
-- 3.8 - LAST ENTRY MEMORY
------------------------------------------------------------
function get_last_entry_key()
    return get_plugin_last_entry_key()
end

function save_current_entry_state()
    local txt = "all"

    if group_active and current_group_slot ~= nil then
        txt = "group\t" .. tostring(current_group_slot)
    end

    set_plugin_state_safe(
        get_plugin_last_entry_key(),
        txt
    )
end

function restore_last_entry_state()
    local saved =
        trim(get_plugin_state_safe(get_plugin_last_entry_key()) or "")

    if saved == "" or saved == "all" then
        return false
    end

    local kind, slot_s =
        saved:match("^(%S+)%s*\t%s*(%d+)$")

    if kind ~= "group" then
        return false
    end

    local slot = tonumber(slot_s)

    if slot == nil then
        return false
    end

    slot = clamp_int(slot, 1, 12)

    local txt = get_plugin_state_safe(get_plugin_group_slot_key(slot)) or ""

    --------------------------------------------------------
    -- Il Group salvato e' una lista autoritativa autonoma.
    -- Ripristinalo direttamente dal suo TXT, mantenendo ordine
    -- e duplicati esattamente come sono stati salvati.
    --
    -- IMPORTANTE: non passare piu' da group_selected +
    -- rebuild_group_results_from_selected(), perche' quel rebuild
    -- usa get_full_grid_indices() e quindi, se Custom order e'
    -- attiva, riordinava il Group secondo la Custom.
    --------------------------------------------------------
    local loaded = load_group_text_to_results(txt)

    if #loaded <= 0 then
        group_results = {}
        group_selected = {}
        group_active = false
        search_active = false

        clear_group_context()
        save_current_entry_state()

        return false
    end

    group_results = loaded
    rebuild_group_membership_from_results()

    search_active = false
    group_active = true

    mode = "list"
    value_return_mode = "list"
    numeric_return_mode = "list"

    set_loaded_group_context(slot)

    --------------------------------------------------------
    -- Ripristina la posizione privata di questo Group.
    -- Se non ne ha ancora una, parte dal primo parametro.
    --------------------------------------------------------
    if not restore_group_last_position(slot) then
        active_pos = 1
        sync_param_from_active_pos()
    end

    save_current_param_position()

    return true
end

------------------------------------------------------------
-- 3.9 - LAST AREA MEMORY
------------------------------------------------------------
function get_last_area_key()
    return get_plugin_last_area_key()
end

function save_current_area_state(area)
    area = clean_one_line(area or "")

    if area ~= "browser" and area ~= "grid" then
        if mode == "fx_browser" then
            area = "browser"
        else
            area = "grid"
        end
    end

    set_plugin_state_safe(
        get_plugin_last_area_key(),
        area
    )
end

function restore_last_area_state()
    local saved =
        trim(get_plugin_state_safe(get_plugin_last_area_key()) or "")

    if saved == "browser" or saved == "grid" then
        return saved
    end

    return nil
end

function plugin_txt_has_grid_memory()
    if not plugin_txt_loaded then
        return false
    end

    if type(plugin_txt_matches_selected_fx) == "function" and
       not plugin_txt_matches_selected_fx() then

        return false
    end

    local last_param = trim(plugin_txt_get_last_param and plugin_txt_get_last_param() or "")

    if last_param ~= "" then
        return true
    end

    local last_entry = trim(plugin_txt_get_last_entry and plugin_txt_get_last_entry() or "")

    if last_entry ~= "" then
        return true
    end

    local custom_order = trim(plugin_txt_get_custom_order and plugin_txt_get_custom_order() or "")

    if custom_order ~= "" then
        return true
    end

    if type(plugin_txt_default_values_has_content) == "function" and
       plugin_txt_default_values_has_content() then

        return true
    end

    return false
end

------------------------------------------------------------
-- 3.10 - RISOLUZIONE PARAMETRI SALVATI
------------------------------------------------------------
function parse_param_line(line)
    line = line or ""

    local index_s, name = line:match("^(%-?%d+)%s*\t%s*(.*)$")

    if not index_s then
        return nil, ""
    end

    return index_s, clean_one_line(name or "")
end

function parse_custom_order_line(line)
    line = line or ""

    local index_s, original_name, alias =
        line:match("^(%-?%d+)%s*\t%s*([^\t]*)%s*\t%s*(.*)$")

    if index_s then
        return
            index_s,
            clean_one_line(original_name or ""),
            clean_one_line(alias or "")
    end

    index_s, original_name =
        line:match("^(%-?%d+)%s*\t%s*(.*)$")

    if not index_s then
        return nil, "", ""
    end

    return
        index_s,
        clean_one_line(original_name or ""),
        ""
end

function resolve_saved_param(index_s, name)
    local saved_index = tonumber(index_s)
    name = clean_one_line(name or "")

    --------------------------------------------------------
    -- Memory positions must be deterministic.
    --
    -- Old behavior resolved by parameter name first.
    -- On large plug-ins many parameters can share the same name,
    -- so a saved memory could jump to the first matching label
    -- instead of the exact parameter that was saved.
    --
    -- The saved index is now the primary reference.
    -- The name remains only as a human-readable label and as a
    -- fallback for very old or unusual slots where the index is
    -- missing/invalid.
    --------------------------------------------------------
    if saved_index ~= nil then
        saved_index = math.floor(saved_index + 0.5)

        if param_index_is_valid and param_index_is_valid(saved_index) then
            return saved_index
        end
    end

    --------------------------------------------------------
    -- Fallback compatibility: if no valid index exists, try the
    -- older name-based lookup. This is intentionally second now.
    --------------------------------------------------------
    if name ~= "" then
        local wanted = name:lower()
        local base = get_full_grid_indices()

        for pos = 1, #base do
            local i = base[pos]
            local pname = clean_one_line(get_param_name(i)):lower()

            if pname == wanted then
                return i
            end
        end
    end

    return nil
end

function resolve_saved_group_param(index_s, name)
    local saved_index = tonumber(index_s)
    name = clean_one_line(name or "")

    --------------------------------------------------------
    -- Nei gruppi l'indice è il riferimento principale.
    -- Questo evita che due parametri con lo stesso nome
    -- vengano risolti entrambi sul primo parametro trovato.
    --------------------------------------------------------
    if saved_index ~= nil then
        saved_index = math.floor(saved_index + 0.5)

        if param_index_is_valid(saved_index) then
            local current_name =
                clean_one_line(get_param_name(saved_index))

            ------------------------------------------------
            -- Se il nome combacia, usa direttamente l'indice.
            -- È il caso normale e risolve i duplicati.
            ------------------------------------------------
            if name == "" or current_name:lower() == name:lower() then
                return saved_index
            end
        end
    end

    --------------------------------------------------------
    -- Fallback vecchio:
    -- se l'indice non è più valido o il plugin è cambiato,
    -- prova a ritrovare il parametro per nome.
    --------------------------------------------------------
    if name ~= "" then
        local wanted = name:lower()
        ----------------------------------------------------
        -- Anche il fallback resta indipendente da Custom:
        -- cerca nella lista reale del plugin, non nella vista
        -- Custom corrente e non rispetta gli hidden di Custom.
        ----------------------------------------------------
        local base = all_param_indices or {}

        if #base <= 0 and type(custom_order_make_plugin_order) == "function" then
            base = custom_order_make_plugin_order()
        end

        for pos = 1, #base do
            local i = base[pos]
            local pname = clean_one_line(get_param_name(i)):lower()

            if pname == wanted then
                return i
            end
        end
    end

    return nil
end

------------------------------------------------------------
-- 3.11 - LISTA PARAMETRI ATTIVA / GRIGLIA CORRENTE
------------------------------------------------------------
function build_all_param_indices()
    all_param_indices = {}

    if fx_offline_grid_active or current_fx_is_offline() then
        return
    end

    if is_current_fx_reaeq and is_current_fx_reaeq() then
        all_param_indices = reaeq_build_default_param_indices()
    elseif is_current_fx_reacomp and is_current_fx_reacomp() then
        all_param_indices = reacomp_build_default_param_indices()
    elseif is_current_fx_reagate and is_current_fx_reagate() then
        all_param_indices = reagate_build_default_param_indices()
    else
        for i = 0, param_count - 1 do
            all_param_indices[#all_param_indices + 1] = i
        end
    end

    all_param_indices = fx_compare_insert_into_param_list(all_param_indices)

    if custom_order_active then
        custom_order_indices =
            custom_order_normalize_list(custom_order_indices)
    end
end

function get_full_grid_indices()
    if custom_order_active then
        ensure_custom_order_runtime()

        local out = {}

        for pos = 1, #custom_order_indices do
            local i = custom_order_indices[pos]

            if not hidden_param_is_hidden(i) then
                out[#out + 1] = i
            end
        end

        return out
    end

    return all_param_indices
end

function is_group_edit_context()
    return
        mode == "group_edit" or
        value_return_mode == "group_edit" or
        numeric_return_mode == "group_edit"
end

function runtime_limit_param_indices(list)
    if runtime_safe_mode ~= true then
        return list
    end

    list = list or {}

    local out = {}
    local max_count = math.min(20, #list)

    for i = 1, max_count do
        out[#out + 1] = list[i]
    end

    return out
end

function get_active_indices()
    local list = nil

    if mode == "group_edit" then
        ----------------------------------------------------
        -- F7 è il motore di selezione; Search è soltanto la
        -- vista corrente.
        --
        -- Se F7 sta modificando un Group reale, il recinto base
        -- è group_results, NON Plugin/Custom order.
        ----------------------------------------------------
        if search_active then
            list = search_results
        elseif group_edit_uses_group_occurrences() then
            list = group_results
        else
            list = get_full_grid_indices()
        end

    elseif group_active then
        list = group_results

    elseif search_active then
        list = search_results

    else
        list = get_full_grid_indices()
    end

    return runtime_limit_param_indices(list)
end

function get_active_count()
    return #get_active_indices()
end

function sync_param_from_active_pos()
    local old_param_index = param_index

    local list = get_active_indices()
    local count = #list

    if count <= 0 then
        active_pos = 1
        param_index = 0

        return false
    end

    active_pos = clamp_int(active_pos, 1, count)
    param_index = list[active_pos] or 0

    return true
end

function set_active_pos(new_pos, speak_it)
    local count = get_active_count()

    if count <= 0 then
        return false
    end

    new_pos = clamp_int(new_pos, 1, count)

    if new_pos == active_pos then
        return false
    end

    active_pos = new_pos

    sync_param_from_active_pos()
    save_current_param_position()

    if speak_it then
        announce_current_param()
    end

    return true
end

function set_param_index_absolute(new_param_index, speak_it)
    new_param_index = tonumber(new_param_index)

    if new_param_index == nil then
        return false
    end

    new_param_index = math.floor(new_param_index + 0.5)

    local list = get_active_indices()

    for pos = 1, #list do
        if list[pos] == new_param_index then
            active_pos = pos
            param_index = new_param_index

            save_current_param_position()

            if speak_it then
                announce_current_param()
            end

            return true
        end
    end

    return false
end

function clear_filtered_param_context()
    search_active = false
    group_active = false

    search_results = {}
    group_results = {}

    search_query = ""
    search_buffer = ""
    search_cursor = 1
    search_edge = nil

    mode = "list"
    value_return_mode = "list"
    numeric_return_mode = "list"

    clear_group_context()
end

function set_param_index_in_full_grid(new_param_index, speak_it)
    clear_filtered_param_context()

    local list = get_full_grid_indices()

    for pos = 1, #list do
if list[pos] == new_param_index then
    local old_param_index = param_index

    active_pos = pos
    param_index = new_param_index

    save_current_param_position()

    if speak_it then
        announce_current_param()
    end

    return true
end
    end

    return false
end

function return_to_all_parameters(prefix)
    save_active_grid_size_to_txt()

    local old_param_index = param_index

    clear_filtered_param_context()

    restore_active_grid_size_from_txt()

    if not set_param_index_absolute(old_param_index, false) then
        active_pos = 1
        sync_param_from_active_pos()
    end

    save_current_entry_state()

    announce_grid_context(prefix)
end

------------------------------------------------------------
-- 3.12 - SPEECH DELLA GRIGLIA / PARAMETRO CORRENTE
------------------------------------------------------------
function get_grid_label()
    if mode == "group_edit" then
        local edit_label = "Edit group"

        if group_edit_loaded_slot ~= nil then
            local name = get_group_slot_name(group_edit_loaded_slot)
            edit_label = name ~= "" and name or
                ("Edit Group " .. tostring(group_edit_loaded_slot))
        elseif custom_order_active == true then
            edit_label = "Edit Custom order"
        end

        if search_active then
            return edit_label .. ". Search results"
        end

        if group_edit_loaded_slot ~= nil and
           group_edit_show_all_params == true then
            return edit_label .. ". All parameters"
        end

        return edit_label
    end

    if group_active and current_group_slot ~= nil then
        return "Group " .. tostring(current_group_slot)
    end

    if group_active then
        return "Group"
    end

    if search_active then
        if custom_order_active then
            return "Custom order. Search results"
        end

        return "Plugin order. Search results"
    end

    if custom_order_active then
        return "Custom order. All parameters"
    end

    return "Plugin order. All parameters"
end
function get_group_context_label()
    if current_group_slot ~= nil then
        local name = get_group_slot_name(current_group_slot)

        if name ~= "" then
            return name
        end

        return "Group " .. tostring(current_group_slot)
    end

    if group_edit_is_temporary then
        return "Edit group"
    end

    return "Group"
end

function get_current_param_spoken_label()
    if fx_offline_grid_active then
        return get_fx_offline_grid_label()
    end

    local label = get_param_label()

    if is_group_edit_context() then
        local list = get_active_indices()

        if group_edit_position_is_selected and
           group_edit_position_is_selected(active_pos, list) then
            label = "Selected " .. label
        end
    end

    return label
end

function announce_current_param()
    cancel_pending_speech()
    speak(get_current_param_spoken_label())
end

function announce_grid_context(prefix)
    cancel_pending_speech()

    local msg = ""
    local grid_label = get_grid_label()
    prefix = clean_one_line(prefix or "")

    --------------------------------------------------------
    -- Evita messaggi doppi tipo:
    -- "Custom order. Custom order. All parameters..."
    -- o "Plugin order. Plugin order. All parameters..."
    --------------------------------------------------------
    local grid_starts_with_prefix =
        prefix ~= "" and
        grid_label:sub(1, #prefix) == prefix

    if prefix ~= "" and
       prefix ~= grid_label and
       not grid_starts_with_prefix then
        msg = prefix .. ". "
    end

    msg = msg .. grid_label .. ". "

    if mode == "group_edit" then
        msg = msg .. tostring(count_group_selected()) .. " selected. "
    end

    msg = msg .. get_current_param_spoken_label()

    speak(msg)
end
function save_panel_return_snapshot()
    panel_return_mode = "all"
    panel_return_group_slot = nil
    panel_return_param_index = param_index

    if group_active and current_group_slot ~= nil then
        panel_return_mode = "group"
        panel_return_group_slot = current_group_slot
    end
end

function restore_panel_return_snapshot()
    clear_param_memory_arm()
    disarm_slot_deletes()

    local wanted_param = panel_return_param_index

    if panel_return_mode == "group" and
       panel_return_group_slot ~= nil then

        if load_group_slot(panel_return_group_slot) then
            if wanted_param ~= nil then
                set_param_index_absolute(wanted_param, false)
                save_current_param_position()
                announce_grid_context(nil)
            end

            return true
        end
    end

    return_to_all_parameters(nil)

    if wanted_param ~= nil then
        set_param_index_in_full_grid(wanted_param, false)
        announce_grid_context(nil)
    end

    return true
end

function save_f7_return_snapshot()
    --------------------------------------------------------
    -- F7 deve poter tornare anche a Search results, non solo
    -- a Plugin/Custom order o a un Group. Manteniamo quindi
    -- uno snapshot completo della griglia oltre al fallback
    -- legacy usato da altre parti dello script.
    --------------------------------------------------------
    f7_grid_return_snapshot = capture_navigation_return_snapshot()

    --------------------------------------------------------
    -- Se F7 nasce dentro Search, conserva anche il ritorno
    -- originale della sessione Search. Così, uscendo da F7,
    -- i risultati tornano ad avere il loro Esc corretto.
    --------------------------------------------------------
    f7_grid_return_snapshot.search_return_state = {
        valid = search_return_valid == true,
        mode = search_return_mode,
        param_index = search_return_param_index,
        active_pos = search_return_active_pos,
        custom_order_active = search_return_custom_order_active == true,
        group_active = search_return_group_active == true,
        group_slot = search_return_group_slot,
        group_edit_is_temporary = search_return_group_edit_is_temporary == true,
        group_edit_show_all_params = search_return_group_edit_show_all_params == true,
        group_results = search_snapshot_copy_table(search_return_group_results),
        group_selected = search_snapshot_copy_table(search_return_group_selected),
        group_select_anchor_pos = search_return_group_select_anchor_pos,
        group_select_path = search_snapshot_copy_table(search_return_group_select_path),
        group_select_dir_path = search_snapshot_copy_table(search_return_group_select_dir_path),
        group_select_path_action = search_return_group_select_path_action,
        group_select_base_selected = search_snapshot_copy_table(search_return_group_select_base_selected)
    }

    save_panel_return_snapshot()

    f7_return_mode = panel_return_mode
    f7_return_group_slot = panel_return_group_slot
    f7_return_param_index = panel_return_param_index
end

function exit_loaded_group_edit_to_group()
    local slot = group_edit_loaded_slot

    if slot == nil then
        return false
    end

    local wanted_group_pos = nil

    if group_edit_show_all_params == true then
        save_f7_runtime_selection_for_current_fx()

        local old_param = param_index
        if old_param ~= nil then
            for pos = 1, #(group_results or {}) do
                if group_results[pos] == old_param then
                    wanted_group_pos = pos
                    break
                end
            end
        end
    elseif search_active and
           type(group_edit_visible_pos_to_group_pos) == "function" then
        wanted_group_pos = group_edit_visible_pos_to_group_pos(active_pos)
    else
        wanted_group_pos = active_pos
    end

    --------------------------------------------------------
    -- Il Group reale è già stato modificato e salvato in-place.
    -- NON ripristinare lo snapshot F7 precedente, perché quello
    -- contiene la vecchia lista e annullerebbe visivamente Paste,
    -- Delete o altri edit strutturali appena fatti.
    --------------------------------------------------------
    search_active = false
    search_results = {}
    search_query = ""
    search_buffer = ""
    search_cursor = 1
    search_edge = nil
    group_edit_search_positions = {}

    if type(search_clear_return_snapshot) == "function" then
        search_clear_return_snapshot()
    end

    f7_grid_return_snapshot = nil
    f7_return_mode = "all"
    f7_return_group_slot = nil
    f7_return_param_index = nil

    group_edit_occurrence_selected = {}
    group_edit_occurrence_base_selected = {}
    group_select_path = {}
    group_select_dir_path = {}
    group_select_path_lookup = {}

    mode = "list"
    value_return_mode = "list"
    numeric_return_mode = "list"

    group_active = true
    set_loaded_group_context(slot)
    rebuild_group_membership_from_results()

    active_pos = clamp_int(
        wanted_group_pos or 1,
        1,
        math.max(1, #group_results)
    )
    sync_param_from_active_pos()

    save_current_param_position()
    save_current_entry_state()
    announce_grid_context(nil)

    return true
end

function restore_f7_return_snapshot()
    --------------------------------------------------------
    -- Un F7 aperto da un Group reale torna al Group VIVO,
    -- non allo snapshot precedente alla modifica.
    --------------------------------------------------------
    if group_edit_loaded_slot ~= nil then
        return exit_loaded_group_edit_to_group()
    end

    --------------------------------------------------------
    -- Ritorno moderno: ripristina esattamente il recinto da
    -- cui F7 era stato aperto, compresi eventuali risultati
    -- Search. Lo snapshot viene consumato una sola volta.
    --------------------------------------------------------
    if type(f7_grid_return_snapshot) == "table" and
       f7_grid_return_snapshot.valid == true then

        local snapshot = f7_grid_return_snapshot
        local search_state = snapshot.search_return_state
        f7_grid_return_snapshot = nil

        local ok = restore_navigation_return_snapshot(snapshot, true)

        if type(search_state) == "table" then
            search_return_valid = search_state.valid == true
            search_return_mode = search_state.mode or "list"
            search_return_param_index = search_state.param_index
            search_return_active_pos = tonumber(search_state.active_pos) or 1
            search_return_custom_order_active =
                search_state.custom_order_active == true
            search_return_group_active = search_state.group_active == true
            search_return_group_slot = search_state.group_slot
            search_return_group_edit_is_temporary =
                search_state.group_edit_is_temporary == true
            search_return_group_edit_show_all_params =
                search_state.group_edit_show_all_params == true
            search_return_group_results =
                search_snapshot_copy_table(search_state.group_results)
            search_return_group_selected =
                search_snapshot_copy_table(search_state.group_selected)
            search_return_group_select_anchor_pos =
                tonumber(search_state.group_select_anchor_pos) or 1
            search_return_group_select_path =
                search_snapshot_copy_table(search_state.group_select_path)
            search_return_group_select_dir_path =
                search_snapshot_copy_table(search_state.group_select_dir_path)
            search_return_group_select_path_action =
                tostring(search_state.group_select_path_action or "select")
            search_return_group_select_base_selected =
                search_snapshot_copy_table(search_state.group_select_base_selected)
        end

        return ok
    end

    panel_return_mode = f7_return_mode or "all"
    panel_return_group_slot = f7_return_group_slot
    panel_return_param_index = f7_return_param_index

    local ok = restore_panel_return_snapshot()

    --------------------------------------------------------
    -- F7 non modifica più il selettore slot.
    -- Ctrl+G / Ctrl+M restano sticky anche entrando e uscendo.
    --------------------------------------------------------
    return ok
end

function save_memory_manager_return_snapshot()
    --------------------------------------------------------
    -- Snapshot completo prima di F8. È quello usato per il
    -- ritorno moderno, compreso Edit F7.
    --------------------------------------------------------
    memory_manager_grid_return_snapshot =
        capture_navigation_return_snapshot()

    --------------------------------------------------------
    -- Manteniamo anche il piccolo snapshot legacy come fallback.
    --------------------------------------------------------
    save_panel_return_snapshot()

    memory_manager_return_mode = panel_return_mode
    memory_manager_return_group_slot = panel_return_group_slot
    memory_manager_return_param_index = panel_return_param_index
end

------------------------------------------------------------
-- 3.14 - SERIALIZZAZIONE GRUPPI
------------------------------------------------------------
function serialize_group_selected()
    local lines = {}
    local base = get_full_grid_indices()

    for pos = 1, #base do
        local i = base[pos]

        if group_selected[i] then
            local name = clean_one_line(get_param_name(i))
            lines[#lines + 1] = tostring(i) .. "\t" .. name
        end
    end

    return table.concat(lines, "\n")
end

------------------------------------------------------------
-- Group reale: serializzazione per OCCORRENZA.
-- Non usa Plugin order o Custom order e non elimina duplicati.
------------------------------------------------------------
function serialize_group_results(list)
    local lines = {}

    list = list or group_results or {}

    for pos = 1, #list do
        local i = tonumber(list[pos])

        if i ~= nil then
            i = math.floor(i + 0.5)

            if param_index_is_valid(i) then
                local name = clean_one_line(get_param_name(i))
                lines[#lines + 1] = tostring(i) .. "\t" .. name
            end
        end
    end

    return table.concat(lines, "\n")
end

function load_group_text_to_results(txt)
    local out = {}

    txt = tostring(txt or "")

    if trim(txt) == "" then
        return out
    end

    for line in txt:gmatch("[^\r\n]+") do
        line = trim(line)

        if line ~= "" then
            local index_s, name = parse_param_line(line)
            local found = resolve_saved_group_param(index_s, name)

            if found ~= nil then
                out[#out + 1] = found
            end
        end
    end

    return out
end

function serialize_group_edit_occurrence_selection()
    local list = {}

    if group_edit_loaded_slot == nil then
        return ""
    end

    for pos = 1, #(group_results or {}) do
        if group_edit_occurrence_selected[pos] then
            list[#list + 1] = group_results[pos]
        end
    end

    return serialize_group_results(list)
end

function save_loaded_group_results(slot)
    slot = slot or current_group_slot or group_edit_loaded_slot

    if slot == nil then
        return false
    end

    slot = clamp_int(slot, 1, 12)

    set_plugin_state_safe(
        get_plugin_group_slot_key(slot),
        serialize_group_results(group_results)
    )

    plugin_txt_save_if_dirty(true)
    return true
end

function count_group_selected()
    local count = 0

    if group_edit_uses_group_occurrences() then
        for _, v in pairs(group_edit_occurrence_selected or {}) do
            if v then
                count = count + 1
            end
        end

        return count
    end

    for _, v in pairs(group_selected or {}) do
        if v then
            count = count + 1
        end
    end

    return count
end

function load_group_text_to_selected(txt)
    group_selected = {}

    txt = txt or ""

    if trim(txt) == "" then
        return false
    end

    for line in txt:gmatch("[^\r\n]+") do
        line = trim(line)

        if line ~= "" then
            local index_s, name = parse_param_line(line)

            ------------------------------------------------
            -- Gruppi: preferisci l'indice salvato.
            -- Così due parametri con lo stesso nome restano
            -- due parametri distinti nel gruppo.
            ------------------------------------------------
            local found = resolve_saved_group_param(index_s, name)

            if found ~= nil then
                group_selected[found] = true
            end
        end
    end

    return count_group_selected() > 0
end

function rebuild_group_results_from_selected()
    --------------------------------------------------------
    -- Un Group reale caricato è autoritativo: NON deve mai
    -- essere ricostruito da Plugin/Custom order.
    --------------------------------------------------------
    if (group_active and current_group_slot ~= nil) or
       group_edit_loaded_slot ~= nil then
        return #group_results > 0
    end

    group_results = {}

    local base = get_full_grid_indices()

    for pos = 1, #base do
        local i = base[pos]

        if group_selected[i] then
            group_results[#group_results + 1] = i
        end
    end

    return #group_results > 0
end

function rebuild_group_membership_from_results()
    group_selected = {}

    for pos = 1, #(group_results or {}) do
        local i = tonumber(group_results[pos])

        if i ~= nil and param_index_is_valid(i) then
            group_selected[math.floor(i + 0.5)] = true
        end
    end
end

------------------------------------------------------------
-- 3.15 - GRUPPI / TOGGLE ALL <-> ULTIMO GRUPPO
------------------------------------------------------------
function clear_temporary_group_selection()
    group_selected = {}
    group_results = {}
    group_active = false

    set_plugin_state_safe(
        get_plugin_group_key(),
        ""
    )

    plugin_txt_save_if_dirty(true)
end

function save_group_to_plugin_txt()
    local txt = serialize_group_selected()

    set_plugin_state_safe(
        get_plugin_group_key(),
        txt
    )

    plugin_txt_save_if_dirty(true)

    return txt ~= ""
end

function save_group_to_project()
    return save_group_to_plugin_txt()
end

function clear_group_from_plugin_txt()
    group_selected = {}
    group_results = {}
    group_active = false

    set_plugin_state_safe(
        get_plugin_group_key(),
        ""
    )

plugin_txt_save_if_dirty(true)

    clear_param_memory_arm()
    disarm_slot_deletes()

    if mode == "group_edit" then
        value_return_mode = "group_edit"
        numeric_return_mode = "group_edit"

        if not set_param_index_absolute(param_index, false) then
            active_pos = 1
            sync_param_from_active_pos()
        end

        speak("Unselected all")
        return
    end

    mode = "list"
    value_return_mode = "list"
    numeric_return_mode = "list"

    clear_group_context()

    active_pos = 1
    sync_param_from_active_pos()

    save_current_entry_state()

    speak("Group deleted")
end

function clear_group_from_project()
    clear_group_from_plugin_txt()
end

function load_group_from_plugin_txt_to_selected()
    local txt = get_plugin_state_safe(get_plugin_group_key()) or ""

    return load_group_text_to_selected(txt)
end

function load_group_from_project_to_selected()
    return load_group_from_plugin_txt_to_selected()
end

function load_group_as_active_grid(speak_it)
    --------------------------------------------------------
    -- Anche il Quick Group deve essere autonomo da Custom.
    -- La sua lista salvata viene caricata direttamente, senza
    -- ricostruirla attraverso l'ordine Plugin/Custom corrente.
    --------------------------------------------------------
    local txt = get_plugin_state_safe(get_plugin_group_key()) or ""
    local loaded = load_group_text_to_results(txt)

    if #loaded <= 0 then
        group_results = {}
        group_selected = {}
        group_active = false
        search_active = false

        mode = "list"
        value_return_mode = "list"
        numeric_return_mode = "list"

        clear_group_context()
        save_current_entry_state()

        if speak_it then
            speak("No group")
        end

        return false
    end

    group_results = loaded
    rebuild_group_membership_from_results()

    search_active = false
    group_active = true

    mode = "list"
    value_return_mode = "list"
    numeric_return_mode = "list"

    current_group_slot = nil
    group_edit_is_temporary = false

    active_pos = 1
    sync_param_from_active_pos()

    save_current_param_position()
    save_current_entry_state()

    if speak_it then
        speak(
            "Group. " ..
            tostring(#group_results) ..
            " parameters. " ..
            get_param_label()
        )
    end

    return true
end

function toggle_all_or_last_group()
    clear_param_memory_arm()
    disarm_slot_deletes()

    if group_active and current_group_slot ~= nil then
        return_to_all_parameters(nil)
        return true
    end

    if last_toggle_group_slot == nil then
        speak("No group selected")
        return false
    end

    return load_group_slot(last_toggle_group_slot)
end

------------------------------------------------------------
-- 3.16 - LABEL MEMORIE PER Parameter Navigator.
------------------------------------------------------------
function get_saved_param_slot_text(slot)
    slot = clamp_int(slot, 1, 12)

    return get_plugin_state_safe(
        get_plugin_param_slot_key(slot)
    )
end

function get_saved_group_slot_text(slot)
    slot = clamp_int(slot, 1, 12)

    return get_plugin_state_safe(
        get_plugin_group_slot_key(slot)
    )
end

function get_saved_param_slot_label(slot)
    slot = clamp_int(slot, 1, 12)

    local txt = trim(get_saved_param_slot_text(slot) or "")

    if txt == "" then
        return nil
    end

    local index_s, name = parse_param_line(txt)
    local found = resolve_saved_param(index_s, name)

    if found == nil then
        return "Memory position " .. tostring(slot) .. ". Missing parameter"
    end

    return
        "Memory position " ..
        tostring(slot) ..
        ". " ..
        get_param_label_for_index(found)
end

function count_saved_group_text(txt)
    local count = 0

    txt = txt or ""

    if trim(txt) == "" then
        return 0
    end

    for line in txt:gmatch("[^\r\n]+") do
        line = trim(line)

        if line ~= "" then
            local index_s, name = parse_param_line(line)
            local found = resolve_saved_group_param(index_s, name)

            ------------------------------------------------
            -- Ogni riga valida è una OCCORRENZA del Group.
            -- Duplicati intenzionali vengono contati e mantenuti.
            ------------------------------------------------
            if found ~= nil then
                count = count + 1
            end
        end
    end

    return count
end
function get_saved_group_slot_label(slot)
    slot = clamp_int(slot, 1, 12)

    return get_group_slot_status_label(slot)
end

------------------------------------------------------------
-- 3.17 - GROUP SLOT MEMORIES: CTRL+F1 ... CTRL+F12
------------------------------------------------------------
function group_slot_has_content(slot)
    slot = clamp_int(slot, 1, 12)

    local txt = get_saved_group_slot_text(slot)

    return count_saved_group_text(txt or "") > 0
end

function group_slot_has_data(slot)
    return group_slot_has_content(slot)
end

function save_group_slot(slot)
    slot = clamp_int(slot, 1, 12)

    --------------------------------------------------------
    -- Creare/salvare un Group è una modifica strutturale:
    -- richiede F7.
    --------------------------------------------------------
    if mode ~= "group_edit" then
        speak_f7_edit_required()
        return false
    end

    if group_slot_has_content(slot) then
        speak("Slot occupied. Group " .. tostring(slot))
        return false
    end

    local txt = ""

    if group_edit_uses_group_occurrences() then
        txt = serialize_group_edit_occurrence_selection()
    else
        txt = serialize_group_selected()
    end

    if trim(txt) == "" then
        speak("No parameters selected")
        return false
    end

    set_plugin_state_safe(
        get_plugin_group_slot_key(slot),
        txt
    )

    plugin_txt_save_if_dirty(true)

    disarm_slot_deletes()

    speak("Group " .. tostring(slot) .. " saved")

    return true
end
function delete_group_slot(slot, silent)
    slot = clamp_int(slot, 1, 12)

    set_plugin_state_safe(
        get_plugin_group_slot_key(slot),
        ""
    )

    set_group_slot_name(slot, "", false)

    --------------------------------------------------------
    -- Uno slot Group cancellato non deve lasciare in eredita'
    -- la vecchia posizione a un eventuale nuovo Group.
    --------------------------------------------------------
    set_plugin_state_safe(
        get_plugin_group_last_position_key(slot),
        ""
    )

plugin_txt_save_if_dirty(true)

    if last_group_slot_touched == slot then
        group_slot_delete_armed = false
    end

    if last_toggle_group_slot == slot then
        last_toggle_group_slot = nil
    end

    if current_group_slot == slot then
        clear_group_context()
        group_active = false
        group_results = {}

        save_current_entry_state()
    end

    if memory_manager_return_group_slot == slot then
        memory_manager_return_mode = "all"
        memory_manager_return_group_slot = nil
    end

    if f7_return_group_slot == slot then
        f7_return_mode = "all"
        f7_return_group_slot = nil
    end

    if not silent then
        speak("Group " .. tostring(slot) .. " deleted")
    end
end

function load_group_slot(slot)
    slot = clamp_int(slot, 1, 12)

    save_active_grid_size_to_txt()

    local txt = get_saved_group_slot_text(slot) or ""
    local loaded = load_group_text_to_results(txt)

    if #loaded <= 0 then
        group_results = {}
        group_selected = {}
        group_active = false
        search_active = false

        mode = "list"
        value_return_mode = "list"
        numeric_return_mode = "list"

        clear_group_context()
        clear_param_memory_arm()
        disarm_slot_deletes()

        if last_toggle_group_slot == slot then
            last_toggle_group_slot = nil
        end

        save_current_entry_state()

        speak("No group " .. tostring(slot))
        return false
    end

    --------------------------------------------------------
    -- Lista del Group: ordine e duplicati arrivano direttamente
    -- dal suo slot TXT. Custom order non viene consultata.
    --------------------------------------------------------
    group_results = loaded
    rebuild_group_membership_from_results()

    search_active = false
    search_results = {}
    search_query = ""
    group_active = true

    mode = "list"
    value_return_mode = "list"
    numeric_return_mode = "list"

    set_loaded_group_context(slot)

    restore_active_grid_size_from_txt()

    --------------------------------------------------------
    -- Ogni Group torna alla propria ultima posizione.
    -- Nessuna dipendenza da Plugin order o Custom order.
    --------------------------------------------------------
    if not restore_group_last_position(slot) then
        active_pos = 1
        sync_param_from_active_pos()
    end

    save_current_param_position()
    save_current_entry_state()

    clear_param_memory_arm()
    disarm_slot_deletes()

    local group_label = get_group_slot_status_label(slot)

    if group_label == nil then
        group_label =
            "Group " ..
            tostring(slot) ..
            ". " ..
            tostring(#group_results) ..
            " parameters"
    end

    speak(
        group_label ..
        ". " ..
        get_param_label()
    )

    plugin_txt_save_if_dirty(true)

    return true
end
------------------------------------------------------------
-- 3.18 - PARAMETER SLOT MEMORIES: CTRL+F1 ... CTRL+F12
------------------------------------------------------------
function param_slot_has_content(slot)
    slot = clamp_int(slot, 1, 12)

    local txt = get_saved_param_slot_text(slot)

    return trim(txt or "") ~= ""
end

function arm_param_memory()
    if not param_index_is_valid(param_index) then
        speak("No parameter")
        return false
    end

    param_memory_armed_index = param_index
    param_memory_armed_name = clean_one_line(get_param_name(param_index))

    if param_memory_armed_name == "" then
        param_memory_armed_name = "Parameter " .. tostring(param_index + 1)
    end

    disarm_slot_deletes()

    speak("Parameter armed. " .. get_param_label())

    return true
end

function save_param_memory_slot(slot)
    slot = clamp_int(slot, 1, 12)

    --------------------------------------------------------
    -- Versione 0.237:
    -- le Memory positions si comportano come i Groups:
    -- Ctrl+Shift+F1 ... F12 salva solo se lo slot è vuoto.
    -- Se lo slot è già occupato, non sovrascrive.
    -- La cancellazione resta nel gestore F8.
    --------------------------------------------------------
    local i = param_index

    if not param_index_is_valid(i) then
        clear_param_memory_arm()
        disarm_slot_deletes()

        speak("No parameter")
        return true
    end

    if param_slot_has_content(slot) then
        clear_param_memory_arm()
        disarm_slot_deletes()

        speak("Slot occupied. Memory position " .. tostring(slot))
        return false
    end

    local name = clean_one_line(get_param_name(i))

    if name == "" then
        name = "Parameter " .. tostring(i + 1)
    end

    local txt = tostring(i) .. "\t" .. name

    set_plugin_state_safe(
        get_plugin_param_slot_key(slot),
        txt
    )

plugin_txt_save_if_dirty(true)

    clear_param_memory_arm()
    disarm_slot_deletes()

    speak(
        "Memory position " ..
        tostring(slot) ..
        " saved. " ..
        get_param_label_for_index(i)
    )

    return true
end

function delete_param_memory_slot(slot, silent)
    slot = clamp_int(slot, 1, 12)

    set_plugin_state_safe(
        get_plugin_param_slot_key(slot),
        ""
    )

plugin_txt_save_if_dirty(true)

    if last_param_slot_touched == slot then
        param_slot_delete_armed = false
    end

    if not silent then
        speak("Memory position " .. tostring(slot) .. " deleted")
    end
end

function load_param_memory_slot(slot)
    slot = clamp_int(slot, 1, 12)

    local txt = trim(get_saved_param_slot_text(slot) or "")

    if txt == "" then
        clear_param_memory_arm()
        disarm_slot_deletes()

        speak("No memory position " .. tostring(slot))
        return false
    end

    local index_s, name = parse_param_line(txt)
    local found = resolve_saved_param(index_s, name)

    if found == nil then
        clear_param_memory_arm()
        disarm_slot_deletes()

        speak("No memory position " .. tostring(slot))
        return false
    end

    set_param_index_in_full_grid(found, false)

    clear_param_memory_arm()
    disarm_slot_deletes()

    speak(get_param_label())

    return true
end

function handle_param_memory_slot(slot)
    slot = clamp_int(slot, 1, 12)

    return load_param_memory_slot(slot)
end

function jump_to_param_memory_slot_inside_group_edit(slot)
    slot = clamp_int(slot, 1, 12)

    local txt = trim(get_saved_param_slot_text(slot) or "")

    if txt == "" then
        speak("No memory position " .. tostring(slot))
        return false
    end

    local index_s, name = parse_param_line(txt)
    local found = resolve_saved_param(index_s, name)

    if found == nil then
        speak("No memory position " .. tostring(slot))
        return false
    end

    mode = "group_edit"
    value_return_mode = "group_edit"
    numeric_return_mode = "group_edit"

    if not set_param_index_absolute(found, false) then
        speak("No memory position " .. tostring(slot))
        return false
    end

    speak(get_current_param_spoken_label())

    return true
end

------------------------------------------------------------
-- 3.19 - NAVIGAZIONE CONTESTO CTRL+ALT: LEGACY DISATTIVATA
--
-- La vecchia navigazione Ctrl+Alt+frecce è stata rimossa.
--
-- La navigazione moderna è:
-- - Ctrl + Page Up / Page Down = traccia precedente / successiva;
-- - Ctrl + Left / Right        = item/take FX precedente / successivo.
--
-- Le funzioni operative moderne sono definite più avanti
-- nella Parte 5 e richiamate dalla Parte 7 / Parte 8.
------------------------------------------------------------

------------------------------------------------------------
-- FINE PARTE 3 / 8
------------------------------------------------------------

------------------------------------------------------------
-- PARTE 4 prima parte / 8
-- Lo-lo + GPT per funzioni
-- RICERCA, F7 GROUP EDIT, NAVIGAZIONE GRIGLIA,
-- CUSTOM ORDER MOVE, VALUE MODE, EDIT NUMERICO
--
-- Nota:
-- - le ricerche recenti restano globali in reaper.ini;
-- - gruppi, custom order e memorie parametro sono nel TXT plugin;
-- - questa parte non scrive più nel progetto RPP.
--
-- F7 GROUP EDIT:
-- - Space seleziona/deseleziona il parametro corrente.
-- - Enter entra in Value mode sul parametro corrente.
-- - Shift+frecce crea una selezione continua stile editor.
-- - Shift+Page Up / Page Down seleziona verticalmente nella colonna.
-- - Shift+Home / End seleziona fino a fine/inizio colonna.
-- - Ctrl+Shift+Home / End seleziona tutto.
--
-- Fix importante:
-- - group_edit_reset_path_to_pos() viene definita in PARTE 7.
-- - rimossi doppioni della logica serpente.
-- - Page Up / Page Down usano dir_tag "up" / "down":
--   se tornano indietro sottraggono;
--   se dopo un movimento verticale si supera in orizzontale,
--   sommano come le frecce.
------------------------------------------------------------

------------------------------------------------------------
-- 4.1 - STEP SIZES PARAMETRI FX
------------------------------------------------------------
HAS_TRACK_STEP_API = reaper.TrackFX_GetParamStepSizes ~= nil
HAS_TAKE_STEP_API  = reaper.TakeFX_GetParamStepSizes  ~= nil
HAS_STEP_API       = HAS_TRACK_STEP_API or HAS_TAKE_STEP_API

function param_index_is_valid(i)
    i = tonumber(i)

    if i == nil then
        return false
    end

    if fx_compare_param_is_valid and fx_compare_param_is_valid(i) then
        return true
    end

    if param_count > 0 and i >= 0 and i <= param_count - 1 then
        return true
    end

    if reaeq_virtual_param_is_valid and reaeq_virtual_param_is_valid(i) then
        return true
    end

    if reacomp_virtual_param_is_valid and reacomp_virtual_param_is_valid(i) then
        return true
    end

    return false
end

function get_param_steps(i)
    i = tonumber(i) or 0

    if fx_compare_param_is_valid and fx_compare_param_is_valid(i) then
        return 1, 1, true, true, true
    end

    --------------------------------------------------------
    -- ReaEQ virtual params.
    --------------------------------------------------------
    if reaeq_virtual_param_is_valid and reaeq_virtual_param_is_valid(i) then
        if reaeq_action_param_is_valid and
           reaeq_action_param_is_valid(i) then

            if i == REAEQ_ACTION_TARGET_INDEX then
                local count = math.max(1, reaeq_action_get_band_count())
                local step = 1 / count

                return step, step, false, true, true
            end

            if i == REAEQ_ACTION_BUTTON_INDEX then
                return 1, 1, true, true, true
            end
        end

        local band_zero, kind = reaeq_decode_virtual_index(i)

        if kind == "enabled" then
            return 1, 1, true, true, true
        end

if kind == "type" then
    local step = 1 / REAEQ_BAND_TYPE_USER_MAX

    return step, step, false, true, true
end
    end

    if reacomp_virtual_param_is_valid and
       reacomp_virtual_param_is_valid(i) then

        return 0, 0, false, false, false
    end

    if reacomp_param_is_detector_input and
       reacomp_param_is_detector_input(i) then

        local count = #REACOMP_DETECTOR_INPUT_VALUES
        local step = count > 1 and (1 / (count - 1)) or 1

        return step, step, false, true, true
    end

    if reacomp_param_is_toggle and
       reacomp_param_is_toggle(i) then

        return 1, 1, true, true, true
    end

    local arrow = 0.01
    local page  = 0.08

    local is_toggle = false
    local is_stepped = false
    local suspicious_step = false

    if param_index_is_valid(i) and HAS_STEP_API then
        local ok = false
        local retval, step, smallstep, largestep, istoggle
        local real_fx = get_current_real_fx_index()

        if ctx.kind == "take" then
            if ctx.take and HAS_TAKE_STEP_API then
                ok, retval, step, smallstep, largestep, istoggle =
                    pcall(
                        reaper.TakeFX_GetParamStepSizes,
                        ctx.take,
                        real_fx,
                        i
                    )
            end
        else
            if ctx.track and HAS_TRACK_STEP_API then
                ok, retval, step, smallstep, largestep, istoggle =
                    pcall(
                        reaper.TrackFX_GetParamStepSizes,
                        ctx.track,
                        real_fx,
                        i
                    )
            end
        end

        if ok and retval then
            step      = tonumber(step) or 0
            smallstep = tonumber(smallstep) or 0
            largestep = tonumber(largestep) or 0

            is_toggle = istoggle == true or istoggle == 1
            is_stepped = step > 0

            suspicious_step =
                step >= 1 or
                smallstep >= 1 or
                largestep >= 1

            if is_toggle then
                arrow = 1
                page  = 1

            elseif suspicious_step then
                arrow = 0.01
                page  = 0.08

            else
                arrow =
                    (smallstep > 0 and smallstep) or
                    (step > 0 and step) or
                    arrow

                page =
                    (largestep > 0 and largestep) or
                    (arrow * 8)
            end
        end
    end

    arrow = clamp01(arrow)
    page  = clamp01(page)

    if arrow <= 0 then
        arrow = 0.01
    end

    if page <= 0 then
        page = arrow * 8
    end

    return arrow, page, is_toggle, is_stepped, suspicious_step
end

function open_current_context_fx_chain()
    clear_param_memory_arm()
    disarm_slot_deletes()
    cancel_pending_speech()

    local real_fx = get_current_real_fx_index()

    --------------------------------------------------------
    -- ITEM / TAKE FX CHAIN
    --------------------------------------------------------
    if ctx.kind == "take" then
        if ctx.take and reaper.TakeFX_Show then
            local fx_to_show = real_fx or fx_index or 0

            if fx_to_show < 0 then
                fx_to_show = 0
            end

            reaper.TakeFX_Show(ctx.take, fx_to_show, 1)
        end

        close_script_silent_for_external_window()
        return true
    end

    --------------------------------------------------------
    -- TRACK / MASTER / MONITOR FX CHAIN
    --------------------------------------------------------
    if ctx.track and reaper.TrackFX_Show then
        local fx_to_show = real_fx or fx_index or 0

        if fx_to_show < 0 then
            fx_to_show = 0
        end

        reaper.TrackFX_Show(ctx.track, fx_to_show, 1)
    end

    close_script_silent_for_external_window()
    return true
end

------------------------------------------------------------
-- 4.2 - ANNUNCI PARAMETRO / VALORE
------------------------------------------------------------
function announce_param()
    announce_current_param()
end

function announce_param_name_value_only()
    if not param_index_is_valid(param_index) then
        speak("No parameter")
        return false
    end

    local name = clean_one_line(get_param_display_name(param_index))
    local value = clean_one_line(get_param_value_formatted(param_index))

    if name == "" then
        name = "Parameter " .. tostring(param_index + 1)
    end

    if value ~= "" then
        speak(name .. " " .. value)
    else
        speak(name)
    end

    return true
end

function announce_value_only()
    if not param_index_is_valid(param_index) then
        speak("No parameter")
        return
    end

    speak_later(get_param_value_formatted(param_index))
end

function announce_value_only_if_changed(before_fmt)
    if not param_index_is_valid(param_index) then
        speak("No parameter")
        return false
    end

    before_fmt = clean_one_line(before_fmt or "")

    local after_fmt = clean_one_line(
        get_param_value_formatted(param_index)
    )

    --------------------------------------------------------
    -- Bordi silenziosi per slider combo/discreti e plugin
    -- che cambiano valore normalizzato senza cambiare label.
    -- Esempio: Pro-Q 4 può continuare a restituire la stessa
    -- label formattata vicino al limite. In quel caso non
    -- ripetiamo il parlato: si parla solo se la label cambia.
    --------------------------------------------------------
    if after_fmt == "" or after_fmt == before_fmt then
        return false
    end

    speak_later(after_fmt)
    return true
end

function announce_parameter_value_only()
    announce_parameter_mode()
end

------------------------------------------------------------
-- 4.3 - RESET GRIGLIA / RICERCA / GRUPPO
------------------------------------------------------------
function reset_to_full_grid_silent()
    local old_param_index = param_index

    search_active = false
    group_active = false

    search_results = {}
    group_results = {}

    search_query = ""
    search_buffer = ""
    search_cursor = 1
    search_edge = nil

    mode = "list"
    value_return_mode = "list"
    numeric_return_mode = "list"

    clear_group_context()

    if not set_param_index_absolute(old_param_index, false) then
        active_pos = 1
        sync_param_from_active_pos()
    end
end

------------------------------------------------------------
-- 4.4 - CUSTOM ORDER: SPOSTAMENTO PARAMETRI
--
-- Logica:
-- - Shift + frecce = sposta il parametro.
-- - Up / Down = movimento verticale di 1 posizione.
-- - Left / Right = movimento orizzontale nella griglia.
-- - Shift + Page Up / Page Down = sposta secondo Page jump.
-- - Shift + Home / End = sposta al bordo della colonna.
-- - Ctrl + Shift + Home / End = sposta all'inizio/fine lista.
-- - I bordi vengono rispettati sempre.
-- - "First parameter" / "Last parameter" viene detto una sola volta
--   finché si continua a spingere contro lo stesso bordo.
------------------------------------------------------------
custom_order_edge_spoken = nil

------------------------------------------------------------
-- 4.4S - SICUREZZA STRUTTURALE PLUGIN ORDER
--
-- Plugin order è sempre sola lettura dal punto di vista della
-- STRUTTURA della griglia. Nessun comando di Move / Cut / Copy /
-- Paste / Hide può creare o attivare automaticamente la Custom.
-- L'unico ingresso intenzionale alla Custom order resta Ctrl+L.
------------------------------------------------------------
function speak_plugin_order_read_only()
    speak("Plugin order. Read only")
    return false
end

function custom_order_require_active_for_structural_edit()
    --------------------------------------------------------
    -- Custom è una vista del risultato. La scrittura della
    -- struttura è consentita soltanto dentro F7.
    --------------------------------------------------------
    if not f7_structural_edit_is_active() then
        return speak_f7_edit_required()
    end

    if get_structural_edit_container() ~= "custom" or
       not custom_order_active then
        speak("Custom order not active")
        return false
    end

    if not ensure_custom_order_runtime() then
        speak("No custom order")
        return false
    end

    return true
end
function custom_order_clear_edge_speech()
    custom_order_edge_spoken = nil
end

function custom_order_speak_edge_once(edge)
    edge = clean_one_line(edge or "")

    if edge == "" then
        return
    end

    if custom_order_edge_spoken == edge then
        return
    end

    custom_order_edge_spoken = edge

    if edge == "first" then
        speak("First parameter")

    elseif edge == "last" then
        speak("Last parameter")

    elseif edge == "column_start" then
        speak("Column start")

    elseif edge == "column_end" then
        speak("Column end")
    end
end

function custom_order_find_pos_of_param(index)
    index = tonumber(index)

    if index == nil then
        return nil
    end

    if not ensure_custom_order_runtime() then
        return nil
    end

    for pos = 1, #custom_order_indices do
        if custom_order_indices[pos] == index then
            return pos
        end
    end

    return nil
end

function custom_order_swap_positions(pos_a, pos_b)
    if not ensure_custom_order_runtime() then
        return false
    end

    local count = #custom_order_indices

    if count <= 0 then
        return false
    end

    pos_a = clamp_int(pos_a, 1, count)
    pos_b = clamp_int(pos_b, 1, count)

    if pos_a == pos_b then
        return false
    end

    custom_order_indices[pos_a], custom_order_indices[pos_b] =
        custom_order_indices[pos_b], custom_order_indices[pos_a]

    custom_order_dirty = true

    return true
end

function custom_order_prepare_move()
    if not param_index_is_valid(param_index) then
        speak("No parameter")
        return nil, nil, nil
    end

    --------------------------------------------------------
    -- Plugin order è strutturalmente sola lettura.
    -- Shift non deve più creare automaticamente la Custom.
    --------------------------------------------------------
    if not custom_order_require_active_for_structural_edit() then
        return nil, nil, nil
    end

    local old_param = param_index
    local old_pos = custom_order_find_pos_of_param(old_param)
    local count = #custom_order_indices

    if old_pos == nil or count <= 0 then
        speak("No parameter")
        return nil, nil, nil
    end

    return old_param, old_pos, count
end

function custom_order_finish_move(old_param, old_pos, new_pos, move_label)
    local step = new_pos > old_pos and 1 or -1
    local pos = old_pos

    while pos ~= new_pos do
        custom_order_swap_positions(pos, pos + step)
        pos = pos + step
    end

    save_custom_order_runtime_to_txt(false)

    rebuild_group_results_from_selected()

    if search_active then
        refresh_search_results()
    end

    if not set_param_index_absolute(old_param, false) then
        active_pos = 1
        sync_param_from_active_pos()
    end

    save_current_param_position()

    custom_order_clear_edge_speech()

    move_label = clean_one_line(move_label or "")

    if move_label ~= "" then
        speak(move_label .. ". " .. get_current_param_spoken_label())

    elseif new_pos < old_pos then
        speak("Moved up. " .. get_current_param_spoken_label())

    else
        speak("Moved down. " .. get_current_param_spoken_label())
    end

    return true
end

function custom_order_move_current_to_position(new_pos)
    local old_param, old_pos, count = custom_order_prepare_move()

    if old_param == nil then
        return false
    end

    new_pos = tonumber(new_pos) or old_pos
    new_pos = math.floor(new_pos + 0.5)

    if new_pos < 1 then
        custom_order_speak_edge_once("first")
        return false
    end

    if new_pos > count then
        custom_order_speak_edge_once("last")
        return false
    end

    if new_pos == old_pos then
        if old_pos <= 1 then
            custom_order_speak_edge_once("first")
        elseif old_pos >= count then
            custom_order_speak_edge_once("last")
        end

        return false
    end

    return custom_order_finish_move(old_param, old_pos, new_pos)
end

function custom_order_move_current_by_amount(amount, move_label)
    amount = tonumber(amount) or 0

    --------------------------------------------------------
    -- Arrotondamento corretto anche per numeri negativi.
    --
    -- Prima era:
    -- math.floor(amount + (amount >= 0 and 0.5 or -0.5))
    --
    -- Ma con amount = -1 produceva -2.
    -- Quindi Shift+Up spostava di due posizioni.
    --------------------------------------------------------
    if amount > 0 then
        amount = math.floor(amount + 0.5)
    elseif amount < 0 then
        amount = math.ceil(amount - 0.5)
    else
        amount = 0
    end

    if amount == 0 then
        return false
    end

    local old_param, old_pos, count = custom_order_prepare_move()

    if old_param == nil then
        return false
    end

    local new_pos = old_pos + amount

    if new_pos < 1 then
        custom_order_speak_edge_once("first")
        return false
    end

    if new_pos > count then
        custom_order_speak_edge_once("last")
        return false
    end

    return custom_order_finish_move(old_param, old_pos, new_pos, move_label)
end

------------------------------------------------------------
-- 4.4A - MOVIMENTO CUSTOM ORDER DENTRO UN GRUPPO FILTRATO
--
-- Quando un Group è caricato, active_pos e la geometria della
-- griglia appartengono a group_results, mentre custom_order_indices
-- contiene anche tutti i parametri che il gruppo non mostra.
--
-- Il vecchio movimento usava direttamente le posizioni della
-- Custom order completa: uno Shift+freccia poteva quindi scambiare
-- il parametro corrente con un parametro filtrato. Nel Group non
-- cambiava nulla di visibile e sembrava che il parametro fosse
-- bloccato.
--
-- Qui muoviamo invece la sequenza dei soli parametri del Group
-- dentro gli slot che essi già occupano nella Custom order.
-- I parametri esclusi dal Group restano esattamente al loro posto.
------------------------------------------------------------
function custom_order_move_current_inside_group_to_position(new_group_pos, move_label)
    if not group_active or mode ~= "list" then
        return false
    end

    if not param_index_is_valid(param_index) then
        speak("No parameter")
        return false
    end

    --------------------------------------------------------
    -- Routine legacy difensiva: non deve mai attivare la Custom
    -- da sola. I Group reali usano il loro motore autonomo.
    --------------------------------------------------------
    if not custom_order_require_active_for_structural_edit() then
        return false
    end

    rebuild_group_results_from_selected()

    local count = #group_results

    if count <= 0 then
        speak("No parameter")
        return false
    end

    local old_group_pos = clamp_int(active_pos, 1, count)

    new_group_pos = tonumber(new_group_pos) or old_group_pos
    new_group_pos = math.floor(new_group_pos + 0.5)

    if new_group_pos < 1 or new_group_pos > count then
        return false
    end

    if new_group_pos == old_group_pos then
        return false
    end

    --------------------------------------------------------
    -- Raccoglie le posizioni REALI della Custom order occupate
    -- dai parametri visibili del Group.
    --
    -- hidden_param_is_hidden() è importante: un parametro
    -- nascosto non fa parte di group_results e non deve creare
    -- un disallineamento tra lista filtrata e slot reali.
    --------------------------------------------------------
    local group_slots = {}

    for order_pos = 1, #custom_order_indices do
        local i = custom_order_indices[order_pos]

        if group_selected[i] and not hidden_param_is_hidden(i) then
            group_slots[#group_slots + 1] = order_pos
        end
    end

    --------------------------------------------------------
    -- Le due liste devono descrivere esattamente le stesse
    -- occorrenze, comprese eventuali copie volontarie.
    --------------------------------------------------------
    if #group_slots ~= count then
        return false
    end

    local ordered_group = {}

    for n = 1, #group_slots do
        ordered_group[n] = custom_order_indices[group_slots[n]]
    end

    local moved_param = table.remove(ordered_group, old_group_pos)

    if moved_param == nil then
        return false
    end

    table.insert(ordered_group, new_group_pos, moved_param)

    --------------------------------------------------------
    -- Riscrive SOLO gli slot appartenenti al Group.
    -- Tutti i parametri filtrati rimangono nella posizione
    -- originale della Custom order.
    --------------------------------------------------------
    for n = 1, #group_slots do
        custom_order_indices[group_slots[n]] = ordered_group[n]
    end

    custom_order_dirty = true

    save_custom_order_runtime_to_txt(false)
    rebuild_group_results_from_selected()

    --------------------------------------------------------
    -- active_pos è una posizione del Group: mantenerla esplicita
    -- evita anche ambiguità con parametri copiati più volte.
    --------------------------------------------------------
    active_pos = clamp_int(new_group_pos, 1, #group_results)
    sync_param_from_active_pos()
    save_current_param_position()

    custom_order_clear_edge_speech()

    move_label = clean_one_line(move_label or "")

    if move_label ~= "" then
        speak(move_label .. ". " .. get_current_param_spoken_label())
    else
        speak(get_current_param_spoken_label())
    end

    return true
end

function custom_order_move_current_vertical(direction)
    direction = tonumber(direction) or 0

    if direction == 0 then
        return false
    end

    --------------------------------------------------------
    -- Dentro un Group la geometria deve essere quella del Group,
    -- non quella della Custom order completa.
    --------------------------------------------------------
    if group_active and mode == "list" then
        local count = #group_results

        if count <= 0 then
            speak("No parameter")
            return false
        end

        local old_pos = clamp_int(active_pos, 1, count)
        local safe_grid = clamp_int(grid_size, GRID_MIN, GRID_MAX)

        local col_start =
            math.floor((old_pos - 1) / safe_grid) * safe_grid + 1

        local col_end = math.min(count, col_start + safe_grid - 1)
        local new_pos = old_pos + direction

        if new_pos < col_start then
            custom_order_speak_edge_once("column_start")
            return false
        end

        if new_pos > col_end then
            custom_order_speak_edge_once("column_end")
            return false
        end

        local label = direction < 0 and "Moved up" or "Moved down"

        return custom_order_move_current_inside_group_to_position(
            new_pos,
            label
        )
    end

    local old_param, old_pos, count = custom_order_prepare_move()

    if old_param == nil then
        return false
    end

    local safe_grid = clamp_int(grid_size, GRID_MIN, GRID_MAX)

    local col_start =
        math.floor((old_pos - 1) / safe_grid) * safe_grid + 1

    local col_end = col_start + safe_grid - 1

    if col_end > count then
        col_end = count
    end

    local new_pos = old_pos + direction

    --------------------------------------------------------
    -- Shift+Up / Shift+Down devono restare dentro la colonna.
    --------------------------------------------------------
    if new_pos < col_start then
        custom_order_speak_edge_once("column_start")
        return false
    end

    if new_pos > col_end then
        custom_order_speak_edge_once("column_end")
        return false
    end

    if new_pos == old_pos then
        return false
    end

    local label = direction < 0 and "Moved up" or "Moved down"

    return custom_order_finish_move(old_param, old_pos, new_pos, label)
end

function custom_order_move_current_horizontal(direction)
    direction = tonumber(direction) or 0

    if direction == 0 then
        return false
    end

    --------------------------------------------------------
    -- Sinistra/destra si muovono in orizzontale nella griglia:
    -- LEFT  = stessa riga, colonna precedente.
    -- RIGHT = stessa riga, colonna successiva.
    --------------------------------------------------------

    --------------------------------------------------------
    -- Dentro un Group usa le posizioni filtrate del Group.
    -- Così il salto orizzontale ignora i parametri non inclusi.
    --------------------------------------------------------
    if group_active and mode == "list" then
        local count = #group_results

        if count <= 0 then
            speak("No parameter")
            return false
        end

        local old_pos = clamp_int(active_pos, 1, count)
        local safe_grid = clamp_int(grid_size, GRID_MIN, GRID_MAX)
        local row = (old_pos - 1) % safe_grid

        local col_start =
            math.floor((old_pos - 1) / safe_grid) * safe_grid + 1

        local new_col_start = col_start + (safe_grid * direction)

        if new_col_start < 1 then
            custom_order_speak_edge_once("first")
            return false
        end

        if new_col_start > count then
            custom_order_speak_edge_once("last")
            return false
        end

        local new_pos = math.min(count, new_col_start + row)
        local label = direction < 0 and "Moved left" or "Moved right"

        return custom_order_move_current_inside_group_to_position(
            new_pos,
            label
        )
    end

    local old_param, old_pos, count = custom_order_prepare_move()

    if old_param == nil then
        return false
    end

    local safe_grid = clamp_int(grid_size, GRID_MIN, GRID_MAX)
    local row = (old_pos - 1) % safe_grid

    local col_start =
        math.floor((old_pos - 1) / safe_grid) * safe_grid + 1

    local new_col_start = col_start + (safe_grid * direction)

    if new_col_start < 1 then
        custom_order_speak_edge_once("first")
        return false
    end

    if new_col_start > count then
        custom_order_speak_edge_once("last")
        return false
    end

    local new_pos = new_col_start + row

    if new_pos > count then
        new_pos = count
    end

    if new_pos == old_pos then
        return false
    end

    local label = direction < 0 and "Moved left" or "Moved right"

    return custom_order_finish_move(old_param, old_pos, new_pos, label)
end

function custom_order_move_current_page(direction)
    direction = tonumber(direction) or 0

    if direction == 0 then
        return false
    end

    local amount = get_page_nav_amount() * direction
    local label = direction < 0 and "Moved page up" or "Moved page down"

    return custom_order_move_current_by_amount(amount, label)
end

function custom_order_get_current_column_bounds()
    local old_param, old_pos, count = custom_order_prepare_move()

    if old_param == nil then
        return nil, nil, nil, nil
    end

    local safe_grid = clamp_int(grid_size, GRID_MIN, GRID_MAX)

    local col_start =
        math.floor((old_pos - 1) / safe_grid) * safe_grid + 1

    local col_end = col_start + safe_grid - 1

    if col_end > count then
        col_end = count
    end

    return old_param, old_pos, col_start, col_end
end

function custom_order_move_current_to_column_edge(to_end)
    local old_param, old_pos, col_start, col_end =
        custom_order_get_current_column_bounds()

    if old_param == nil then
        return false
    end

    local target = to_end and col_end or col_start

    if target == old_pos then
        local count = #custom_order_indices

        if old_pos <= 1 then
            custom_order_speak_edge_once("first")
        elseif old_pos >= count then
            custom_order_speak_edge_once("last")
        end

        return false
    end

    local label = to_end and "Moved to column end" or "Moved to column start"

    return custom_order_finish_move(old_param, old_pos, target, label)
end

function custom_order_move_current_to_list_edge(to_end)
    local old_param, old_pos, count = custom_order_prepare_move()

    if old_param == nil then
        return false
    end

    local target = to_end and count or 1

    if target == old_pos then
        if target <= 1 then
            custom_order_speak_edge_once("first")
        else
            custom_order_speak_edge_once("last")
        end

        return false
    end

    local label = to_end and "Moved to last parameter" or "Moved to first parameter"

    return custom_order_finish_move(old_param, old_pos, target, label)
end

------------------------------------------------------------
-- 4.4Z - F7: SELEZIONE PER OCCORRENZA NEI GROUP REALI
------------------------------------------------------------
function group_edit_visible_pos_to_group_pos(pos)
    pos = tonumber(pos)

    if pos == nil then
        return nil
    end

    pos = math.floor(pos + 0.5)

    if group_edit_uses_group_occurrences() and search_active then
        return tonumber((group_edit_search_positions or {})[pos])
    end

    return pos
end

function group_edit_position_is_selected(pos, list)
    list = list or get_active_indices()

    if group_edit_uses_group_occurrences() then
        local group_pos = group_edit_visible_pos_to_group_pos(pos)
        return group_pos ~= nil and
            group_edit_occurrence_selected[group_pos] == true
    end

    local i = list[tonumber(pos) or -1]
    return i ~= nil and group_selected[i] == true
end

function group_edit_set_position_selected(pos, selected, list)
    list = list or get_active_indices()
    selected = selected == true

    if group_edit_uses_group_occurrences() then
        local group_pos = group_edit_visible_pos_to_group_pos(pos)

        if group_pos == nil then
            return false
        end

        if selected then
            group_edit_occurrence_selected[group_pos] = true
        else
            group_edit_occurrence_selected[group_pos] = nil
        end

        return true
    end

    local i = list[tonumber(pos) or -1]

    if i == nil then
        return false
    end

    if selected then
        group_selected[i] = true
    else
        group_selected[i] = nil
    end

    return true
end

function group_edit_selected_group_positions()
    local out = {}

    if not group_edit_uses_group_occurrences() then
        return out
    end

    for pos = 1, #(group_results or {}) do
        if group_edit_occurrence_selected[pos] then
            out[#out + 1] = pos
        end
    end

    return out
end

------------------------------------------------------------
-- 4.5 - F7 GROUP EDIT
------------------------------------------------------------
if group_select_anchor_pos == nil then
    group_select_anchor_pos = 1
end

if group_select_path == nil then
    group_select_path = {}
end

if group_select_dir_path == nil then
    group_select_dir_path = {}
end

if group_select_path_lookup == nil then
    group_select_path_lookup = {}
end

function group_edit_get_count()
    return get_active_count()
end

function group_edit_get_column_bounds(pos)
    local count = group_edit_get_count()

    if count <= 0 then
        return 1, 1
    end

    local safe_grid = clamp_int(grid_size, GRID_MIN, GRID_MAX)

    pos = clamp_int(pos, 1, count)

    local col_start =
        math.floor((pos - 1) / safe_grid) * safe_grid + 1

    local col_end = col_start + safe_grid - 1

    if col_end > count then
        col_end = count
    end

    return col_start, col_end
end

function group_edit_rebuild_path_lookup()
    group_select_path_lookup = {}

    for pos = 1, #group_select_path do
        local p = tonumber(group_select_path[pos])

        if p ~= nil then
            group_select_path_lookup[p] = pos
        end
    end
end

function group_edit_opposite_dir(dir)
    dir = tostring(dir or "")

    if dir == "up" then return "down" end
    if dir == "down" then return "up" end
    if dir == "left" then return "right" end
    if dir == "right" then return "left" end

    return ""
end

function group_edit_shift_step_to_pos(new_pos, speak_it, dir_tag)
    local count = group_edit_get_count()

    if count <= 0 then
        return false
    end

    new_pos = clamp_int(new_pos, 1, count)

    if group_select_path == nil then
        group_select_path = {}
    end

    if group_select_dir_path == nil then
        group_select_dir_path = {}
    end

    dir_tag = tostring(dir_tag or "")

    --------------------------------------------------------
    -- SERPENTE: LA POSIZIONE PARLATA È SEMPRE SELEZIONATA
    --
    -- Prima pressione Shift:
    --   - seleziona/deseleziona il parametro CORRENTE;
    --   - NON muove active_pos;
    --   - quindi 0 -> 1 parla ancora il parametro di partenza.
    --
    -- Pressioni successive nella stessa direzione:
    --   - raggiungono la nuova cella;
    --   - la nuova cella entra subito nel tratto;
    --   - quindi 1 -> 2 parla il secondo parametro, già selezionato.
    --
    -- Tornando nella direzione opposta:
    --   - viene tolta l'ultima cella del tratto;
    --   - il cursore torna alla precedente cella ancora selezionata;
    --   - sull'ultima cella 1 -> 0 resta fermo sul parametro corrente.
    --------------------------------------------------------

    local path_len = #group_select_path

    --------------------------------------------------------
    -- Se il cursore non coincide più con la coda del tratto
    -- (per esempio dopo un cambio vista), comincia un nuovo tratto
    -- dalla posizione corrente conservando la selezione già fatta.
    --------------------------------------------------------
    if path_len > 0 and group_select_path[path_len] ~= active_pos then
        group_edit_reset_path_to_pos(active_pos)
        path_len = 0
    end

    --------------------------------------------------------
    -- PRIMO SHIFT: seleziona qui, senza spostarsi.
    --------------------------------------------------------
    if path_len <= 0 then
        group_select_path[1] = active_pos
        group_select_dir_path[1] = dir_tag

        group_edit_rebuild_path_lookup()
        group_edit_rebuild_selection_from_path()
        save_f7_runtime_selection_for_current_fx()

        if speak_it ~= false then
            group_edit_speak_selection()
        end

        return true
    end

    local last_path_pos = group_select_path[path_len]
    local last_dir = group_select_dir_path[path_len]

    --------------------------------------------------------
    -- BACKTRACK:
    -- se dalla cella corrente si torna nella direzione opposta
    -- rispetto al passo che l'ha selezionata, elimina proprio
    -- quella cella. La posizione parlata resta quindi sempre
    -- una cella ancora selezionata, salvo il caso 1 -> 0.
    --------------------------------------------------------
    local is_backtracking =
        last_path_pos == active_pos and
        dir_tag ~= "" and
        group_edit_opposite_dir(last_dir) == dir_tag

    if is_backtracking then
        table.remove(group_select_path)
        table.remove(group_select_dir_path)

        local remaining = #group_select_path

        if remaining > 0 then
            active_pos = clamp_int(group_select_path[remaining], 1, count)
        end

    else
        ----------------------------------------------------
        -- ESTENSIONE:
        -- la posizione corrente è già nel tratto; questa volta
        -- selezioniamo la destinazione e ci spostiamo sopra.
        ----------------------------------------------------
        if new_pos == active_pos then
            return false
        end

        group_select_path[#group_select_path + 1] = new_pos
        group_select_dir_path[#group_select_dir_path + 1] = dir_tag
        active_pos = new_pos
    end

    group_edit_rebuild_path_lookup()

    sync_param_from_active_pos()
    save_current_param_position()

    group_edit_rebuild_selection_from_path()
    save_f7_runtime_selection_for_current_fx()

    if speak_it ~= false then
        group_edit_speak_selection()
    end

    return true
end

function group_edit_set_anchor_here()
    group_edit_reset_path_to_pos(active_pos)
end

function group_edit_copy_selected(src)
    local out = {}

    src = src or {}

    for k, v in pairs(src) do
        if v then
            out[k] = true
        end
    end

    return out
end

function group_edit_snapshot_base_selection()
    if group_edit_uses_group_occurrences() then
        group_edit_occurrence_base_selected =
            group_edit_copy_selected(group_edit_occurrence_selected)
    else
        group_select_base_selected = group_edit_copy_selected(group_selected)
    end
end

function group_edit_clear_base_selection()
    if group_edit_uses_group_occurrences() then
        group_edit_occurrence_base_selected = {}
    else
        group_select_base_selected = {}
    end
end

function group_edit_rebuild_selection_from_path()
    local list = get_active_indices()
    local count = #list

    --------------------------------------------------------
    -- Riparte dalla selezione già esistente.
    -- Nei Group reali la selezione è per OCCORRENZA.
    --------------------------------------------------------
    if group_edit_uses_group_occurrences() then
        group_edit_occurrence_selected =
            group_edit_copy_selected(group_edit_occurrence_base_selected)
    else
        group_selected = group_edit_copy_selected(group_select_base_selected)
    end

    if count <= 0 then
        return false
    end

    local action = group_select_path_action or "select"

    for n = 1, #group_select_path do
        local pos = tonumber(group_select_path[n])

        if pos ~= nil then
            pos = clamp_int(pos, 1, count)
            group_edit_set_position_selected(
                pos,
                action ~= "unselect",
                list
            )
        end
    end

    return true
end

function group_edit_speak_selection()
    speak(
        tostring(count_group_selected()) ..
        " selected. " ..
        get_current_param_spoken_label()
    )
end

function group_edit_move_plain_to_pos(new_pos)
    local count = group_edit_get_count()

    if count <= 0 then
        return false
    end

    new_pos = clamp_int(new_pos, 1, count)

    if new_pos == active_pos then
        return false
    end

    active_pos = new_pos

    sync_param_from_active_pos()
    save_current_param_position()

    group_edit_reset_path_to_pos(active_pos)

    speak(get_current_param_spoken_label())

    return true
end

function group_edit_move_select_to_pos(new_pos, dir_tag)
    return group_edit_shift_step_to_pos(new_pos, true, dir_tag)
end

function group_edit_move_vertical(direction, select_it)
    direction = tonumber(direction) or 0

    if direction == 0 then
        return false
    end

    local count = group_edit_get_count()

    if count <= 0 then
        return false
    end

    local col_start, col_end = group_edit_get_column_bounds(active_pos)
    local new_pos = active_pos + direction

    if new_pos < col_start then
        new_pos = col_start
    end

    if new_pos > col_end then
        new_pos = col_end
    end

    if new_pos == active_pos then
        return false
    end

    if select_it then
        local dir_tag = direction < 0 and "up" or "down"
        return group_edit_shift_step_to_pos(new_pos, true, dir_tag)
    end

    return group_edit_move_plain_to_pos(new_pos)
end

function group_edit_move_horizontal(direction, select_it)
    direction = tonumber(direction) or 0

    if direction == 0 then
        return false
    end

    local count = group_edit_get_count()

    if count <= 0 then
        return false
    end

    local safe_grid = clamp_int(grid_size, GRID_MIN, GRID_MAX)
    local row = (active_pos - 1) % safe_grid

    local col_start =
        math.floor((active_pos - 1) / safe_grid) * safe_grid + 1

    local new_col_start = col_start + (safe_grid * direction)

    if new_col_start < 1 or new_col_start > count then
        return false
    end

    local new_pos = new_col_start + row

    if new_pos > count then
        new_pos = count
    end

    if new_pos == active_pos then
        return false
    end

    if select_it then
        local dir_tag = direction < 0 and "left" or "right"
        return group_edit_shift_step_to_pos(new_pos, true, dir_tag)
    end

    return group_edit_move_plain_to_pos(new_pos)
end

function group_edit_shift_vertical_steps(direction, amount)
    direction = tonumber(direction) or 0
    amount = tonumber(amount) or 0
    amount = math.floor(math.abs(amount))

    if direction == 0 or amount <= 0 then
        return false
    end

    local moved = false
    local dir_tag = direction < 0 and "up" or "down"

    for _ = 1, amount do
        local col_start, col_end = group_edit_get_column_bounds(active_pos)
        local new_pos = active_pos + direction

        if new_pos < col_start then
            new_pos = col_start
        end

        if new_pos > col_end then
            new_pos = col_end
        end

        if new_pos == active_pos then
            break
        end

        if group_edit_shift_step_to_pos(new_pos, false, dir_tag) then
            moved = true
        else
            break
        end
    end

    if moved then
        group_edit_speak_selection()
    end

    return moved
end

function group_edit_shift_horizontal_steps(direction, amount)
    direction = tonumber(direction) or 0
    amount = tonumber(amount) or 0
    amount = math.floor(math.abs(amount))

    if direction == 0 or amount <= 0 then
        return false
    end

    local moved = false
    local dir_tag = direction < 0 and "left" or "right"

    for _ = 1, amount do
        local count = group_edit_get_count()

        if count <= 0 then
            break
        end

        local safe_grid = clamp_int(grid_size, GRID_MIN, GRID_MAX)
        local row = (active_pos - 1) % safe_grid

        local col_start =
            math.floor((active_pos - 1) / safe_grid) * safe_grid + 1

        local new_col_start = col_start + (safe_grid * direction)

        if new_col_start < 1 or new_col_start > count then
            break
        end

        local new_pos = new_col_start + row

        if new_pos > count then
            new_pos = count
        end

        if new_pos == active_pos then
            break
        end

        if group_edit_shift_step_to_pos(new_pos, false, dir_tag) then
            moved = true
        else
            break
        end
    end

    if moved then
        group_edit_speak_selection()
    end

    return moved
end

function group_edit_shift_to_column_edge(to_end)
    local col_start, col_end = group_edit_get_column_bounds(active_pos)
    local target = to_end and col_end or col_start

    if target == active_pos then
        return false
    end

    local direction = target > active_pos and 1 or -1
    local amount = math.abs(target - active_pos)

    return group_edit_shift_vertical_steps(direction, amount)
end

function group_edit_move_page_vertical(direction, select_it)
    direction = tonumber(direction) or 0

    if direction == 0 then
        return false
    end

    local amount = get_page_nav_amount()

    if select_it then
        return group_edit_shift_vertical_steps(direction, amount)
    end

    local count = group_edit_get_count()

    if count <= 0 then
        return false
    end

    local col_start, col_end = group_edit_get_column_bounds(active_pos)
    local new_pos = active_pos + (amount * direction)

    if new_pos < col_start then
        new_pos = col_start
    end

    if new_pos > col_end then
        new_pos = col_end
    end

    return group_edit_move_plain_to_pos(new_pos)
end

function group_edit_column_edge(to_end, select_it)
    local count = group_edit_get_count()

    if count <= 0 then
        return false
    end

    local col_start, col_end = group_edit_get_column_bounds(active_pos)
    local new_pos = to_end and col_end or col_start

    if select_it then
        return group_edit_shift_to_column_edge(to_end)
    end

    return group_edit_move_plain_to_pos(new_pos)
end

function group_edit_select_all_grid()
    local list = get_active_indices()
    local count = #list

    if count <= 0 then
        speak("No parameter")
        return false
    end

    --------------------------------------------------------
    -- "Select all" in F7 è additivo rispetto alla selezione
    -- già costruita. Questo è essenziale quando Search viene
    -- usata più volte: selezionare tutti i risultati correnti
    -- non deve cancellare parametri scelti in ricerche precedenti.
    --------------------------------------------------------
    for pos = 1, count do
        group_edit_set_position_selected(pos, true, list)
    end

    active_pos = count
    sync_param_from_active_pos()
    save_current_param_position()

    save_f7_runtime_selection_for_current_fx()

    --------------------------------------------------------
    -- Dopo il comando la selezione completa diventa la nuova
    -- base stabile e la testa del prossimo serpente parte dal
    -- parametro corrente senza aggiungere una cella fantasma.
    --------------------------------------------------------
    group_edit_reset_path_to_pos(active_pos)

    speak(
        "Selected all. " ..
        tostring(count_group_selected()) ..
        " selected"
    )

    return true
end

------------------------------------------------------------
-- 4.5A - F7 RUNTIME SELECTION PER FX
------------------------------------------------------------
function get_f7_runtime_key()
    local ctx_id =
        get_context_storage_id and get_context_storage_id() or "context"

    local fx_name = clean_one_line(get_fx_raw_label() or "FX")
    local real_fx = tostring(get_current_real_fx_index() or fx_index or 0)

    return ctx_id .. "::fx::" .. real_fx .. "::" .. fx_name
end

function copy_bool_table(src)
    local out = {}

    src = src or {}

    for k, v in pairs(src) do
        if v then
            out[k] = true
        end
    end

    return out
end

function save_f7_runtime_selection_for_current_fx()
    --------------------------------------------------------
    -- La selezione per OCCORRENZA di un Group reale è locale
    -- all'editor del Group e non deve contaminare la selezione
    -- F7 generale del plugin.
    --------------------------------------------------------
    if group_edit_uses_group_occurrences() then
        return true
    end

    if not f7_runtime_selected_by_fx then
        f7_runtime_selected_by_fx = {}
    end

    local key = get_f7_runtime_key()

    f7_runtime_selected_by_fx[key] = copy_bool_table(group_selected)
    return true
end

function load_f7_runtime_selection_for_current_fx()
    if group_edit_uses_group_occurrences() then
        return count_group_selected() > 0
    end

    if not f7_runtime_selected_by_fx then
        f7_runtime_selected_by_fx = {}
    end

    local key = get_f7_runtime_key()
    local saved = f7_runtime_selected_by_fx[key]

    group_selected = copy_bool_table(saved)

    return count_group_selected() > 0
end

function clear_f7_runtime_selection_for_current_fx()
    if not f7_runtime_selected_by_fx then
        f7_runtime_selected_by_fx = {}
    end

    local key = get_f7_runtime_key()

    f7_runtime_selected_by_fx[key] = {}
end

------------------------------------------------------------
-- GROUP REALE: CLIPBOARD LOCALE / CROSS-CONTEXT
------------------------------------------------------------
function group_clipboard_capture(mode_name)
    --------------------------------------------------------
    -- Il Group normale è una vista. Cut/Copy strutturale del
    -- contenuto del Group esiste soltanto nel suo Edit F7.
    --------------------------------------------------------
    if mode ~= "group_edit" or
       group_edit_loaded_slot == nil or
       group_edit_show_all_params == true then
        return speak_f7_edit_required()
    end

    local slot = group_edit_loaded_slot
    local positions = group_edit_selected_group_positions()

    if #positions <= 0 then
        local pos = group_edit_visible_pos_to_group_pos(active_pos)
        if pos ~= nil then positions[1] = pos end
    end

    if #positions <= 0 then
        speak("No parameter")
        return false
    end

    table.sort(positions)

    custom_cut_clipboard_indices = {}
    custom_cut_clipboard_order_positions = {}
    custom_cut_clipboard_group_positions = {}
    custom_clipboard_group_origin = false
    custom_clipboard_group_signature = ""
    custom_clipboard_mode = mode_name == "copy" and "copy" or "cut"

    group_clipboard_source_slot = clamp_int(slot, 1, 12)
    group_clipboard_source_positions = {}

    for n = 1, #positions do
        local pos = positions[n]
        local i = tonumber(group_results[pos])

        if i ~= nil and param_index_is_valid(i) then
            custom_cut_clipboard_indices[#custom_cut_clipboard_indices + 1] =
                math.floor(i + 0.5)
            group_clipboard_source_positions[#group_clipboard_source_positions + 1] = pos
        end
    end

    if #custom_cut_clipboard_indices <= 0 then
        speak("No parameter")
        return false
    end

    local word = custom_clipboard_mode == "copy" and "Copied" or "Cut"

    if #custom_cut_clipboard_indices == 1 then
        speak(word .. ". " ..
            get_param_label_for_index(custom_cut_clipboard_indices[1]))
    else
        speak(word .. " " ..
            tostring(#custom_cut_clipboard_indices) .. " parameters")
    end

    return true
end
function group_clipboard_valid_block()
    local out = {}

    for n = 1, #(custom_cut_clipboard_indices or {}) do
        local i = tonumber(custom_cut_clipboard_indices[n])

        if i ~= nil then
            i = math.floor(i + 0.5)

            if param_index_is_valid(i) then
                out[#out + 1] = i
            end
        end
    end

    return out
end

function group_paste_clipboard_into_current_group()
    --------------------------------------------------------
    -- Paste può cambiare il Group soltanto dentro il suo F7.
    --------------------------------------------------------
    if mode ~= "group_edit" or
       group_edit_loaded_slot == nil or
       group_edit_show_all_params == true then
        return speak_f7_edit_required()
    end

    local slot = group_edit_loaded_slot

    --------------------------------------------------------
    -- CUT È LOCALE AL CONTENITORE.
    -- Un Cut Custom non può essere incollato in un Group e un
    -- Cut di un altro Group non può essere reinterpretato qui.
    -- Copy invece resta volutamente cross-context.
    --------------------------------------------------------
    if custom_clipboard_mode == "cut" then
        if group_clipboard_source_slot == nil then
            speak("Cut belongs to Custom order")
            return false
        end

        local source_slot = clamp_int(group_clipboard_source_slot, 1, 12)
        local target_slot = clamp_int(slot, 1, 12)

        if source_slot ~= target_slot then
            speak("Cut belongs to Group " .. tostring(source_slot))
            return false
        end
    end

    local block = group_clipboard_valid_block()

    if #block <= 0 then
        speak("Clipboard empty")
        return false
    end

    local target_pos = nil

    if mode == "group_edit" and group_edit_loaded_slot ~= nil then
        target_pos = group_edit_visible_pos_to_group_pos(active_pos)
    else
        target_pos = active_pos
    end

    target_pos = clamp_int(
        target_pos or 1,
        1,
        math.max(1, #group_results)
    )

    local same_group_cut =
        custom_clipboard_mode == "cut" and
        group_clipboard_source_slot ~= nil and
        clamp_int(group_clipboard_source_slot, 1, 12) == clamp_int(slot, 1, 12) and
        #(group_clipboard_source_positions or {}) > 0

    local out = {}
    local insert_pos = target_pos

    if same_group_cut then
        local source_lookup = {}
        local source_positions = {}

        for n = 1, #group_clipboard_source_positions do
            local pos = tonumber(group_clipboard_source_positions[n])

            if pos ~= nil then
                pos = math.floor(pos + 0.5)

                if pos >= 1 and pos <= #group_results and not source_lookup[pos] then
                    source_lookup[pos] = true
                    source_positions[#source_positions + 1] = pos
                end
            end
        end

        if source_lookup[target_pos] then
            speak("Move to another position before paste")
            return false
        end

        insert_pos = 1

        for pos = 1, target_pos - 1 do
            if not source_lookup[pos] then
                insert_pos = insert_pos + 1
            end
        end

        local reduced = {}

        for pos = 1, #group_results do
            if not source_lookup[pos] then
                reduced[#reduced + 1] = group_results[pos]
            end
        end

        for pos = 1, insert_pos - 1 do
            out[#out + 1] = reduced[pos]
        end

        for n = 1, #block do
            out[#out + 1] = block[n]
        end

        for pos = insert_pos, #reduced do
            out[#out + 1] = reduced[pos]
        end

    else
        ----------------------------------------------------
        -- Clipboard proveniente da Plugin/Custom/Search o da
        -- un altro Group: inserisce qui senza modificare la fonte.
        ----------------------------------------------------
        for pos = 1, target_pos - 1 do
            out[#out + 1] = group_results[pos]
        end

        for n = 1, #block do
            out[#out + 1] = block[n]
        end

        for pos = target_pos, #group_results do
            out[#out + 1] = group_results[pos]
        end

        insert_pos = target_pos
    end

    group_results = out
    save_loaded_group_results(slot)
    rebuild_group_membership_from_results()

    search_active = false
    search_results = {}
    search_query = ""
    group_edit_search_positions = {}
    search_clear_return_snapshot()

    active_pos = clamp_int(insert_pos, 1, #group_results)

    if mode == "group_edit" and group_edit_loaded_slot ~= nil then
        group_edit_occurrence_selected = {}

        for n = 1, #block do
            group_edit_occurrence_selected[insert_pos + n - 1] = true
        end

        group_edit_occurrence_base_selected =
            group_edit_copy_selected(group_edit_occurrence_selected)
        group_active = false
        set_f7_group_edit_context(slot)
    else
        group_active = true
        set_loaded_group_context(slot)
    end

    sync_param_from_active_pos()
    save_current_param_position()
    save_current_entry_state()

    if mode == "group_edit" then
        group_edit_reset_path_to_pos(active_pos)
    end

    if same_group_cut then
        group_clipboard_source_positions = {}
        for n = 1, #block do
            group_clipboard_source_positions[n] = insert_pos + n - 1
        end
    end

    local word = custom_clipboard_mode == "copy" and "Copied" or
        (same_group_cut and "Moved" or "Inserted")

    if #block == 1 then
        speak(word .. ". Group. " .. get_current_param_spoken_label())
    else
        speak(
            word .. " " .. tostring(#block) ..
            " parameters. Group. " .. get_current_param_spoken_label()
        )
    end

    return true
end

------------------------------------------------------------
-- 4.5AA - CUSTOM ORDER CUT / PASTE
--
-- Ctrl+X:
--   - in F7: taglia i parametri selezionati;
--   - fuori da F7: taglia il parametro corrente.
--
-- Ctrl+V:
--   - incolla/sposta il blocco tagliato prima del parametro
--     corrente nella Custom order.
--
-- Nota:
-- il taglio non è distruttivo finché non viene fatto Paste.
------------------------------------------------------------

function custom_cut_clipboard_clear()
    group_clipboard_source_slot = nil
    group_clipboard_source_positions = {}
    custom_cut_clipboard_indices = {}
    custom_cut_clipboard_order_positions = {}
    custom_cut_clipboard_group_positions = {}
    custom_clipboard_group_origin = false
    custom_clipboard_group_signature = ""
    custom_clipboard_mode = ""
end

function custom_group_selection_signature()
    local indices = {}

    for i, selected in pairs(group_selected or {}) do
        if selected and param_index_is_valid(i) then
            indices[#indices + 1] = math.floor((tonumber(i) or 0) + 0.5)
        end
    end

    table.sort(indices)

    local parts = {}

    for n = 1, #indices do
        parts[n] = tostring(indices[n])
    end

    return table.concat(parts, ",")
end

function custom_group_order_slots()
    local slots = {}

    if not ensure_custom_order_runtime() then
        return slots
    end

    for order_pos = 1, #custom_order_indices do
        local i = custom_order_indices[order_pos]

        if group_selected[i] and not hidden_param_is_hidden(i) then
            slots[#slots + 1] = order_pos
        end
    end

    return slots
end

function custom_clipboard_mark_group_origin()
    custom_clipboard_group_origin =
        group_active == true and mode == "list"

    custom_clipboard_group_signature =
        custom_clipboard_group_origin and
        custom_group_selection_signature() or ""

    custom_cut_clipboard_group_positions = {}
end

function custom_clipboard_matches_current_group()
    if not custom_clipboard_group_origin then
        return false
    end

    if not group_active or mode ~= "list" then
        return false
    end

    local now = custom_group_selection_signature()

    return now ~= "" and now == custom_clipboard_group_signature
end

function custom_cut_clipboard_count()
    return #(custom_cut_clipboard_indices or {})
end

function custom_cut_make_block_from_f7_selection()
    local out = {}
    local seen = {}
    local base = get_full_grid_indices()

    for pos = 1, #base do
        local i = base[pos]

        if group_selected[i] and not seen[i] then
            out[#out + 1] = i
            seen[i] = true
        end
    end

    return out
end

function custom_cut_current_or_selected()
    clear_param_memory_arm()
    disarm_slot_deletes()

    --------------------------------------------------------
    -- Cut strutturale esiste soltanto dentro F7.
    --------------------------------------------------------
    if mode ~= "group_edit" then
        return speak_f7_edit_required()
    end

    if group_edit_uses_group_occurrences() then
        return group_clipboard_capture("cut")
    end

    --------------------------------------------------------
    -- All parameters dentro F7 di un Group è una sorgente:
    -- Copy sì, Cut no.
    --------------------------------------------------------
    if group_edit_loaded_slot ~= nil and
       group_edit_show_all_params == true then
        speak("Cut not available in All parameters")
        return false
    end

    --------------------------------------------------------
    -- Il ramo rimanente è Custom F7.
    --------------------------------------------------------
    if get_structural_edit_container() ~= "custom" or
       not custom_order_active then
        return speak_f7_edit_required()
    end

    if not ensure_custom_order_runtime() then
        speak("No custom order")
        return false
    end

    group_clipboard_source_slot = nil
    group_clipboard_source_positions = {}

    custom_cut_clipboard_indices = {}
    custom_cut_clipboard_order_positions = {}
    custom_cut_clipboard_group_positions = {}
    custom_clipboard_mode = "cut"
    custom_clipboard_group_origin = false
    custom_clipboard_group_signature = ""

    custom_cut_clipboard_indices =
        custom_cut_make_block_from_f7_selection()

    --------------------------------------------------------
    -- Nessuna selezione: F7 lavora sul parametro corrente.
    --------------------------------------------------------
    if #custom_cut_clipboard_indices <= 0 then
        if not param_index_is_valid(param_index) then
            speak("No parameter")
            return false
        end

        local pos = clamp_int(active_pos, 1, #custom_order_indices)
        local i = tonumber(custom_order_indices[pos])

        if i ~= nil and param_index_is_valid(i) then
            custom_cut_clipboard_indices[1] = math.floor(i + 0.5)
            custom_cut_clipboard_order_positions[1] = pos
        else
            custom_cut_clipboard_indices[1] = param_index
        end
    end

    if #custom_cut_clipboard_indices == 1 then
        speak(
            "Cut. " ..
            get_param_label_for_index(custom_cut_clipboard_indices[1])
        )
    else
        speak(
            "Cut " ..
            tostring(#custom_cut_clipboard_indices) ..
            " parameters"
        )
    end

    return true
end
function custom_cut_make_valid_block()
    local block = {}
    local seen = {}

    if not custom_cut_clipboard_indices then
        custom_cut_clipboard_indices = {}
    end

    if not ensure_custom_order_runtime() then
        return block
    end

    local present = {}

    for pos = 1, #custom_order_indices do
        local i = custom_order_indices[pos]
        present[i] = true
    end

    for n = 1, #custom_cut_clipboard_indices do
        local i = tonumber(custom_cut_clipboard_indices[n])

        if i ~= nil then
            i = math.floor(i + 0.5)

            if present[i] and not seen[i] then
                block[#block + 1] = i
                seen[i] = true
            end
        end
    end

    return block
end

function custom_cut_make_position_block()
    local block = {}
    local remove_pos = {}

    if not custom_cut_clipboard_order_positions then
        custom_cut_clipboard_order_positions = {}
    end

    if custom_clipboard_mode ~= "cut" then
        return block, remove_pos
    end

    if not ensure_custom_order_runtime() then
        return block, remove_pos
    end

    local used = {}

    for n = 1, #custom_cut_clipboard_order_positions do
        local pos = tonumber(custom_cut_clipboard_order_positions[n])

        if pos ~= nil then
            pos = clamp_int(pos, 1, #custom_order_indices)

            if not used[pos] then
                local i = tonumber(custom_order_indices[pos])

                if i ~= nil then
                    i = math.floor(i + 0.5)

                    if param_index_is_valid(i) then
                        block[#block + 1] = i
                        remove_pos[pos] = true
                        used[pos] = true
                    end
                end
            end
        end
    end

    return block, remove_pos
end

function custom_paste_cut_clipboard_inside_group()
    if not custom_clipboard_matches_current_group() then
        return nil
    end

    if not param_index_is_valid(param_index) then
        speak("No parameter")
        return false
    end

    --------------------------------------------------------
    -- Routine legacy mantenuta solo per compatibilità interna.
    -- Non può più attivare la Custom automaticamente: i Group
    -- reali usano il clipboard autonomo e non dipendono da Custom.
    --------------------------------------------------------
    if not custom_order_require_active_for_structural_edit() then
        return false
    end

    rebuild_group_results_from_selected()

    local count = #group_results

    if count <= 0 then
        speak("No parameter")
        return false
    end

    local target_group_pos = clamp_int(active_pos, 1, count)
    local group_slots = custom_group_order_slots()

    if #group_slots ~= count then
        return nil
    end

    local base_group = {}

    for n = 1, #group_slots do
        base_group[n] = custom_order_indices[group_slots[n]]
    end

    local is_copy = custom_clipboard_mode == "copy"
    local block = {}

    for n = 1, #(custom_cut_clipboard_indices or {}) do
        local i = tonumber(custom_cut_clipboard_indices[n])

        if i ~= nil then
            i = math.floor(i + 0.5)

            if param_index_is_valid(i) and
               group_selected[i] and
               not hidden_param_is_hidden(i) then

                block[#block + 1] = i
            end
        end
    end

    if #block <= 0 then
        return nil
    end

    local new_group = {}
    local insert_pos = target_group_pos

    if is_copy then
        ----------------------------------------------------
        -- Copy nel Group:
        -- aggiunge gli slot nuovi in fondo alla Custom order,
        -- poi riordina soltanto gli slot appartenenti al Group.
        -- In questo modo tutti gli slot preesistenti dei parametri
        -- filtrati restano esattamente dove si trovavano.
        ----------------------------------------------------
        local old_custom_count = #custom_order_indices

        for n = 1, #block do
            custom_order_indices[#custom_order_indices + 1] = block[n]
        end

        group_slots = custom_group_order_slots()

        if #group_slots ~= count + #block then
            while #custom_order_indices > old_custom_count do
                table.remove(custom_order_indices)
            end

            return nil
        end

        for pos = 1, target_group_pos - 1 do
            new_group[#new_group + 1] = base_group[pos]
        end

        for n = 1, #block do
            new_group[#new_group + 1] = block[n]
        end

        for pos = target_group_pos, #base_group do
            new_group[#new_group + 1] = base_group[pos]
        end

    else
        ----------------------------------------------------
        -- Cut nel Group:
        -- individua le occorrenze del blocco nella lista filtrata
        -- e le reinserisce prima del parametro corrente.
        ----------------------------------------------------
        local source_positions = {}
        local source_lookup = {}

        for n = 1, #(custom_cut_clipboard_group_positions or {}) do
            local pos = tonumber(custom_cut_clipboard_group_positions[n])

            if pos ~= nil then
                pos = clamp_int(pos, 1, count)

                if not source_lookup[pos] then
                    local wanted = tonumber(block[#source_positions + 1] or block[1])
                    local actual = tonumber(base_group[pos])

                    if actual ~= nil and
                       (wanted == nil or actual == wanted) then

                        source_positions[#source_positions + 1] = pos
                        source_lookup[pos] = true
                    end
                end
            end
        end

        ----------------------------------------------------
        -- Se la posizione relativa non è più valida, prova la
        -- vera posizione assoluta salvata al momento del Cut.
        ----------------------------------------------------
        if #source_positions <= 0 then
            for n = 1, #(custom_cut_clipboard_order_positions or {}) do
                local wanted_order_pos =
                    tonumber(custom_cut_clipboard_order_positions[n])

                if wanted_order_pos ~= nil then
                    for group_pos = 1, #group_slots do
                        if group_slots[group_pos] == wanted_order_pos and
                           not source_lookup[group_pos] then

                            source_positions[#source_positions + 1] = group_pos
                            source_lookup[group_pos] = true
                            break
                        end
                    end
                end
            end
        end

        ----------------------------------------------------
        -- Plugin order non ha duplicati: se il Cut è avvenuto
        -- prima dell'attivazione della Custom order basta trovare
        -- l'unica occorrenza del parametro nel Group.
        ----------------------------------------------------
        if #source_positions <= 0 and #block == 1 then
            for pos = 1, #base_group do
                if base_group[pos] == block[1] then
                    source_positions[1] = pos
                    source_lookup[pos] = true
                    break
                end
            end
        end

        if #source_positions <= 0 then
            return nil
        end

        if source_lookup[target_group_pos] then
            speak("Move to another position before paste")
            return false
        end

        table.sort(source_positions)

        local actual_block = {}

        for n = 1, #source_positions do
            actual_block[n] = base_group[source_positions[n]]
        end

        block = actual_block

        ----------------------------------------------------
        -- Posizione di inserimento nella lista ridotta:
        -- quante occorrenze NON tagliate esistono prima del
        -- target, più uno. Il risultato equivale a Paste prima
        -- del parametro corrente anche se la sorgente era sopra.
        ----------------------------------------------------
        insert_pos = 1

        for pos = 1, target_group_pos - 1 do
            if not source_lookup[pos] then
                insert_pos = insert_pos + 1
            end
        end

        local reduced = {}

        for pos = 1, #base_group do
            if not source_lookup[pos] then
                reduced[#reduced + 1] = base_group[pos]
            end
        end

        for pos = 1, insert_pos - 1 do
            new_group[#new_group + 1] = reduced[pos]
        end

        for n = 1, #block do
            new_group[#new_group + 1] = block[n]
        end

        for pos = insert_pos, #reduced do
            new_group[#new_group + 1] = reduced[pos]
        end
    end

    if #new_group ~= #group_slots then
        return nil
    end

    --------------------------------------------------------
    -- Scrive esclusivamente gli slot visibili del Group.
    --------------------------------------------------------
    for n = 1, #group_slots do
        custom_order_indices[group_slots[n]] = new_group[n]
    end

    custom_order_dirty = true
    save_custom_order_runtime_to_txt(false)
    rebuild_group_results_from_selected()

    active_pos = clamp_int(insert_pos, 1, #group_results)
    sync_param_from_active_pos()

    --------------------------------------------------------
    -- Un Cut può essere incollato di nuovo: aggiorna le sue
    -- coordinate all'occorrenza appena spostata.
    --------------------------------------------------------
    if not is_copy then
        local refreshed_slots = custom_group_order_slots()

        custom_cut_clipboard_group_positions = {}
        custom_cut_clipboard_order_positions = {}

        for n = 1, #block do
            local group_pos = insert_pos + n - 1
            custom_cut_clipboard_group_positions[n] = group_pos
            custom_cut_clipboard_order_positions[n] =
                refreshed_slots[group_pos]
        end
    end

    save_current_param_position()
    save_current_entry_state()
    save_current_area_state("grid")

    local action_word = is_copy and "Copied" or "Moved"

    if #block == 1 then
        speak(
            action_word ..
            ". Group. " ..
            get_current_param_spoken_label()
        )
    else
        speak(
            action_word ..
            " " ..
            tostring(#block) ..
            " parameters. Group. " ..
            get_current_param_spoken_label()
        )
    end

    return true
end

function custom_paste_cut_clipboard()
    clear_param_memory_arm()
    disarm_slot_deletes()

    --------------------------------------------------------
    -- Paste strutturale esiste soltanto dentro F7.
    --------------------------------------------------------
    if mode ~= "group_edit" then
        return speak_f7_edit_required()
    end

    if group_edit_loaded_slot ~= nil and
       group_edit_show_all_params == true then
        speak("Return to group before paste")
        return false
    end

    if group_edit_uses_group_occurrences() then
        return group_paste_clipboard_into_current_group()
    end

    --------------------------------------------------------
    -- Il vecchio Paste Group-via-Custom non viene più chiamato:
    -- Group e Custom sono contenitori autonomi.
    --------------------------------------------------------

    --------------------------------------------------------
    -- Un Cut nato in un Group resta proprietà di quel Group.
    -- Non viene convertito implicitamente in Copy sulla Custom.
    --------------------------------------------------------
    if custom_clipboard_mode == "cut" and
       group_clipboard_source_slot ~= nil then
        speak("Cut belongs to Group " ..
            tostring(clamp_int(group_clipboard_source_slot, 1, 12)))
        return false
    end

    --------------------------------------------------------
    -- Plugin order è read only: Paste strutturale soltanto in
    -- Custom già attiva tramite Ctrl+L.
    --------------------------------------------------------
    if get_structural_edit_container() ~= "custom" or
       not custom_order_active then
        return speak_f7_edit_required()
    end

    if not ensure_custom_order_runtime() then
        speak("No custom order")
        return false
    end

    if not custom_cut_clipboard_indices or
       #custom_cut_clipboard_indices <= 0 then

        speak("Clipboard empty")
        return false
    end

    if not param_index_is_valid(param_index) then
        speak("No parameter")
        return false
    end

    local target_param = param_index

    --------------------------------------------------------
    -- A questo punto la Custom è già stata verificata come
    -- contesto strutturale attivo e il Cut (se presente) è Custom.
    --------------------------------------------------------
    local is_copy = custom_clipboard_mode == "copy"

    local target_active_pos = clamp_int(active_pos, 1, #custom_order_indices)
    local block = {}
    local remove_pos_lookup = {}

    --------------------------------------------------------
    -- Cut corrente in Custom order:
    -- usa la posizione reale dell'occorrenza, non solo il
    -- param_index. Così originale e copie restano indipendenti.
    --------------------------------------------------------
    if not is_copy then
        block, remove_pos_lookup = custom_cut_make_position_block()
    end

    if #block <= 0 then
        block = custom_cut_make_valid_block()
        remove_pos_lookup = {}
    end

    if #block <= 0 then
        speak("Clipboard empty")
        return false
    end

    --------------------------------------------------------
    -- Se stai cercando di incollare esattamente sopra la stessa
    -- occorrenza tagliata, non fare nulla. Se invece tagli una
    -- copia e vai altrove, viene spostata solo quella copia.
    --------------------------------------------------------
    if (not is_copy) and remove_pos_lookup[target_active_pos] then
        speak("Move to another position before paste")
        return false
    end

    --------------------------------------------------------
    -- Cut: rimuove solo le posizioni tagliate quando sono note.
    -- Fallback vecchio: rimuove per indice solo per blocchi F7,
    -- dove non esiste una posizione singola dell'occorrenza.
    -- Copy: lascia tutto com'è e inserisce una nuova occorrenza.
    --------------------------------------------------------
    local block_lookup = {}

    for n = 1, #block do
        block_lookup[block[n]] = true
    end

    local reduced = {}
    local target_pos = nil
    local old_to_new_pos = {}

    for pos = 1, #custom_order_indices do
        local i = custom_order_indices[pos]
        local keep = true

        if not is_copy then
            if next(remove_pos_lookup) ~= nil then
                keep = remove_pos_lookup[pos] ~= true
            else
                keep = not block_lookup[i]
            end
        end

        if keep then
            reduced[#reduced + 1] = i
            old_to_new_pos[pos] = #reduced
        end
    end

    target_pos = old_to_new_pos[target_active_pos]

    if target_pos == nil then
        local before_count = 0

        for pos, _ in pairs(remove_pos_lookup or {}) do
            if tonumber(pos) and tonumber(pos) < target_active_pos then
                before_count = before_count + 1
            end
        end

        target_pos = clamp_int(target_active_pos - before_count, 1, #reduced + 1)
    end

    --------------------------------------------------------
    -- Inserisce il blocco prima del parametro corrente.
    --------------------------------------------------------
    local out = {}

    for pos = 1, target_pos - 1 do
        out[#out + 1] = reduced[pos]
    end

    for n = 1, #block do
        out[#out + 1] = block[n]
    end

    for pos = target_pos, #reduced do
        out[#out + 1] = reduced[pos]
    end

    custom_order_indices = custom_order_normalize_list(out)
    custom_order_active = true
    custom_order_dirty = true

    save_custom_order_runtime_to_txt(false)

    if type(plugin_txt_set_custom_order_view) == "function" then
        plugin_txt_set_custom_order_view("custom")
        plugin_txt_save_if_dirty(false)
    end

    build_all_param_indices()

    if search_active and type(refresh_search_results) == "function" then
        refresh_search_results()
    end

    --------------------------------------------------------
    -- Dopo Paste:
    -- - dentro F7 resta in F7;
    -- - fuori da F7 torna alla lista normale Custom order.
    --------------------------------------------------------
    if mode == "group_edit" then
        group_selected = {}

        for n = 1, #block do
            group_selected[block[n]] = true
        end

        search_active = false
        group_active = false
        search_results = {}
        group_results = {}

        set_f7_group_edit_context()

        set_param_index_absolute(block[1], false)

        group_edit_reset_path_to_pos(active_pos)
        save_f7_runtime_selection_for_current_fx()

    else
        search_active = false
        group_active = false
        search_results = {}
        group_results = {}

        clear_group_context()

        mode = "list"
        value_return_mode = "list"
        numeric_return_mode = "list"

        active_pos = clamp_int(target_pos, 1, #get_active_indices())
        sync_param_from_active_pos()
    end

    save_current_param_position()
    save_current_entry_state()
    save_current_area_state("grid")

    local action_word = is_copy and "Copied" or "Moved"

    if #block == 1 then
        speak(action_word .. ". Custom order. " .. get_current_param_spoken_label())
    else
        speak(
            action_word ..
            " " ..
            tostring(#block) ..
            " parameters. Custom order. " ..
            get_current_param_spoken_label()
        )
    end

    return true
end

------------------------------------------------------------
-- 4.5A1 - CUSTOM ORDER: COPIA / DUPLICATI
------------------------------------------------------------
function custom_copy_current_or_selected()
    clear_param_memory_arm()
    disarm_slot_deletes()

    --------------------------------------------------------
    -- Fuori da F7 non esiste più Copy strutturale.
    --------------------------------------------------------
    if mode ~= "group_edit" then
        return speak_f7_edit_required()
    end

    if group_edit_uses_group_occurrences() then
        return group_clipboard_capture("copy")
    end

    --------------------------------------------------------
    -- All parameters dentro F7 di un Group è una sorgente
    -- neutra: Copy è consentito per aggiungere poi al Group.
    --------------------------------------------------------
    local group_all_source =
        group_edit_loaded_slot ~= nil and
        group_edit_show_all_params == true

    if not group_all_source and
       (get_structural_edit_container() ~= "custom" or
        not custom_order_active) then
        return speak_f7_edit_required()
    end

    group_clipboard_source_slot = nil
    group_clipboard_source_positions = {}

    custom_cut_clipboard_indices = {}
    custom_cut_clipboard_order_positions = {}
    custom_cut_clipboard_group_positions = {}
    custom_clipboard_mode = "copy"
    custom_clipboard_group_origin = false
    custom_clipboard_group_signature = ""

    custom_cut_clipboard_indices =
        custom_cut_make_block_from_f7_selection()

    if #custom_cut_clipboard_indices <= 0 then
        if not param_index_is_valid(param_index) then
            speak("No parameter")
            return false
        end

        custom_cut_clipboard_indices[1] = param_index
    end

    if #custom_cut_clipboard_indices == 1 then
        speak(
            "Copied. " ..
            get_param_label_for_index(custom_cut_clipboard_indices[1])
        )
    else
        speak(
            "Copied " ..
            tostring(#custom_cut_clipboard_indices) ..
            " parameters"
        )
    end

    return true
end
function custom_order_prepare_for_duplicate_edit()
    --------------------------------------------------------
    -- Anche la gestione delle copie è strutturale e richiede F7.
    --------------------------------------------------------
    if not f7_structural_edit_is_active() then
        return speak_f7_edit_required()
    end

    if get_structural_edit_container() ~= "custom" or
       not custom_order_active then
        return speak_f7_edit_required()
    end

    return ensure_custom_order_runtime()
end

function custom_order_count_occurrences(list)
    local counts = {}

    list = list or custom_order_indices or {}

    for pos = 1, #list do
        local i = tonumber(list[pos])

        if i ~= nil then
            i = math.floor(i + 0.5)
            counts[i] = (counts[i] or 0) + 1
        end
    end

    return counts
end

function custom_order_build_copied_slots()
    local list = nil

    if custom_order_is_complete(custom_order_indices or {}) then
        list = custom_order_indices
    elseif plugin_txt_custom_order_has_content() then
        list = custom_order_parse_text(get_custom_order_text())
    else
        list = {}
    end

    local seen = {}
    local out = {}

    for pos = 1, #list do
        local i = tonumber(list[pos])

        if i ~= nil then
            i = math.floor(i + 0.5)
            seen[i] = (seen[i] or 0) + 1

            if seen[i] > 1 then
                out[#out + 1] = {
                    kind = "copy",
                    param_index = i,
                    order_pos = pos,
                    occurrence = seen[i],
                    label = get_param_label_for_index(i) ..
                        ". Copy " .. tostring(seen[i])
                }
            end
        end
    end

    return out
end

function custom_order_delete_copied_occurrence(order_pos, speak_it)
    order_pos = tonumber(order_pos)

    if order_pos == nil then
        if speak_it then speak("No copied parameter") end
        return false
    end

    if not custom_order_prepare_for_duplicate_edit() then
        if speak_it then speak("No custom order") end
        return false
    end

    order_pos = clamp_int(order_pos, 1, #custom_order_indices)
    local param_i = tonumber(custom_order_indices[order_pos])

    if param_i == nil then
        if speak_it then speak("No copied parameter") end
        return false
    end

    local counts = custom_order_count_occurrences(custom_order_indices)

    if (counts[param_i] or 0) <= 1 then
        if speak_it then speak("Not copied. " .. get_param_label_for_index(param_i)) end
        return false
    end

    local label = get_param_label_for_index(param_i)
    table.remove(custom_order_indices, order_pos)

    custom_order_indices = custom_order_normalize_list(custom_order_indices)
    custom_order_active = true
    custom_order_dirty = true

    save_custom_order_runtime_to_txt(false)

    if type(plugin_txt_set_custom_order_view) == "function" then
        plugin_txt_set_custom_order_view("custom")
        plugin_txt_save_if_dirty(false)
    end

    build_all_param_indices()
    rebuild_group_results_from_selected()

    if speak_it then
        speak("Deleted copy. " .. label)
    end

    return true
end

function custom_order_go_to_copied_occurrence(order_pos)
    order_pos = tonumber(order_pos)

    if order_pos == nil then
        speak("No copied parameter")
        return false
    end

    if not custom_order_prepare_for_duplicate_edit() then
        speak("No custom order")
        return false
    end

    order_pos = clamp_int(order_pos, 1, #custom_order_indices)

    custom_order_active = true
    build_all_param_indices()

    mode = "list"
    value_return_mode = "list"
    numeric_return_mode = "list"
    search_active = false
    group_active = false
    search_results = {}
    group_results = {}
    clear_group_context()

    active_pos = order_pos
    sync_param_from_active_pos()
    save_current_param_position()
    save_current_entry_state()
    save_current_area_state("grid")

    speak(get_param_label())

    return true
end

------------------------------------------------------------
-- 4.5B - ENTRATA / USCITA F7 GROUP EDIT
------------------------------------------------------------
function enter_group_edit_mode()
    if mode == "group_edit" then
        restore_f7_return_snapshot()
        return true
    end

    --------------------------------------------------------
    -- F7 e' la modifica strutturale avanzata. Plugin order
    -- non puo' entrarci: prima serve Ctrl+L -> Custom order.
    -- Search aperte dalla Plugin order restano ugualmente locked.
    --------------------------------------------------------
    if plugin_order_structure_is_read_only() then
        speak("F7 not available in Plugin order")
        return false
    end

    local source_group_slot =
        group_active and current_group_slot or nil

    local keep_search =
        source_group_slot == nil and
        search_active == true and
        #(search_results or {}) > 0

    local kept_search_results =
        keep_search and navigation_snapshot_copy_table(search_results) or {}

    local kept_search_query =
        keep_search and tostring(search_query or "") or ""

    local kept_param_index = param_index
    local kept_active_pos = active_pos

    save_f7_return_snapshot()

    --------------------------------------------------------
    -- F7 aperto da un Group reale: il recinto Edit è proprio
    -- quel Group, con ordine e duplicati indipendenti da Custom.
    --------------------------------------------------------
    if source_group_slot ~= nil then
        group_edit_loaded_slot = source_group_slot
        group_edit_show_all_params = false
        group_edit_occurrence_selected = {}
        group_edit_occurrence_base_selected = {}
        group_edit_search_positions = {}

        search_active = false
        search_results = {}
        search_query = ""
        search_buffer = ""
        search_cursor = 1
        search_edge = nil

        group_active = false
        set_f7_group_edit_context(source_group_slot)

        mode = "group_edit"
        value_return_mode = "group_edit"
        numeric_return_mode = "group_edit"

        active_pos = clamp_int(
            kept_active_pos,
            1,
            math.max(1, #group_results)
        )
        sync_param_from_active_pos()

    else
        load_f7_runtime_selection_for_current_fx()

        group_results = {}
        group_active = false

        if keep_search then
            search_active = true
            search_results = kept_search_results
            search_query = kept_search_query
            search_buffer = ""
            search_cursor = 1
            search_edge = nil
        else
            search_active = false
            search_results = {}
            search_query = ""
            search_buffer = ""
            search_cursor = 1
            search_edge = nil
        end

        clear_group_context()
        set_f7_group_edit_context()

        mode = "group_edit"
        value_return_mode = "group_edit"
        numeric_return_mode = "group_edit"

        if keep_search then
            active_pos = clamp_int(
                kept_active_pos,
                1,
                math.max(1, get_active_count())
            )

            if not set_param_index_absolute(kept_param_index, false) then
                active_pos = 1
                sync_param_from_active_pos()
            end
        else
            if not set_param_index_absolute(kept_param_index, false) then
                active_pos = 1
                sync_param_from_active_pos()
            end
        end
    end

    clear_param_memory_arm()
    disarm_slot_deletes()

    group_edit_reset_path_to_pos(active_pos)

    local context_label = get_grid_label()

    speak(
        context_label ..
        ". " ..
        tostring(count_group_selected()) ..
        " selected. " ..
        get_current_param_spoken_label()
    )

    return true
end
function toggle_group_selected_current()
    if not param_index_is_valid(param_index) then
        speak("No parameter")
        return false
    end

    disarm_slot_deletes()
    clear_param_memory_arm()

    local list = get_active_indices()
    local selected = group_edit_position_is_selected(active_pos, list)
    local label = get_param_label()

    group_edit_set_position_selected(active_pos, not selected, list)

    if selected then
        speak(label)
    else
        speak("Selected " .. label)
    end

    if type(group_edit_snapshot_base_selection) == "function" then
        group_edit_snapshot_base_selection()
    end

    group_select_anchor_pos = active_pos
    group_select_path = {}
    group_select_dir_path = {}

    if group_edit_position_is_selected(active_pos, list) then
        group_select_path_action = "unselect"
    else
        group_select_path_action = "select"
    end

    if type(group_edit_rebuild_path_lookup) == "function" then
        group_edit_rebuild_path_lookup()
    end

    save_f7_runtime_selection_for_current_fx()

    return true
end
function unselect_all_group_edit()
    if group_edit_uses_group_occurrences() then
        group_edit_occurrence_selected = {}
        group_edit_occurrence_base_selected = {}
    else
        group_selected = {}
        group_results = {}
        group_active = false
        group_select_base_selected = {}
    end

    clear_param_memory_arm()
    disarm_slot_deletes()

    mode = "group_edit"
    value_return_mode = "group_edit"
    numeric_return_mode = "group_edit"

    if not set_param_index_absolute(param_index, false) then
        active_pos = 1
        sync_param_from_active_pos()
    end

    group_edit_reset_path_to_pos(active_pos)

    speak("Unselected all. 0 selected")
end
function select_all_group_edit()
    group_edit_select_all_grid()
end

function finish_group_edit_and_load()
    disarm_slot_deletes()
    clear_param_memory_arm()

    if not rebuild_group_results_from_selected() then
        group_active = false
        group_results = {}

        mode = "list"
        value_return_mode = "list"
        numeric_return_mode = "list"

        clear_group_context()

        active_pos = 1
        sync_param_from_active_pos()

        save_current_entry_state()

        group_select_path = {}
        group_select_path_lookup = {}
        group_select_dir_path = {}

        group_select_base_selected = {}

        speak("No group")
        return
    end

    search_active = false
    group_active = true

    mode = "list"
    value_return_mode = "list"
    numeric_return_mode = "list"

    current_group_slot = nil
    group_edit_is_temporary = true

    active_pos = 1
    sync_param_from_active_pos()

    save_current_param_position()
    save_current_entry_state()

    if type(save_group_to_plugin_txt) == "function" then
        save_group_to_plugin_txt()
    elseif type(save_group_to_project) == "function" then
        save_group_to_project()
    end

    group_select_path = {}
    group_select_path_lookup = {}
    group_select_dir_path = {}

    group_select_base_selected = {}

    speak(
        "Group. " ..
        tostring(#group_results) ..
        " parameters. " ..
        get_param_label()
    )
end

------------------------------------------------------------
-- 4.5B1 - F7: NAVIGAZIONE GEOMETRICA TRA I SOLI SELEZIONATI
--
-- Ctrl+Alt+Up / Down:
--   cerca il selezionato precedente / successivo nella stessa colonna.
--
-- Ctrl+Alt+Left / Right:
--   cerca la prima colonna precedente / successiva che contiene
--   almeno un parametro selezionato e mantiene il rigo il piu'
--   possibile, scegliendo il selezionato piu' vicino verticalmente.
--
-- La navigazione:
-- - non modifica group_selected;
-- - non cicla ai bordi;
-- - usa la vista F7 corrente, quindi rispetta anche Search;
-- - se nessun selezionato e' visibile, lo segnala una sola volta.
------------------------------------------------------------
function group_edit_selected_nav_visible_count(list)
    list = list or get_active_indices()

    local count = 0

    for pos = 1, #list do
        if group_edit_position_is_selected(pos, list) then
            count = count + 1
        end
    end

    return count
end

function group_edit_selected_nav_move_to_pos(target_pos, list)
    list = list or get_active_indices()

    local count = #list

    if count <= 0 or target_pos == nil then
        return false
    end

    target_pos = clamp_int(target_pos, 1, count)

    if not group_edit_position_is_selected(target_pos, list) then
        return false
    end

    active_pos = target_pos
    sync_param_from_active_pos()
    save_current_param_position()

    --------------------------------------------------------
    -- La navigazione non cambia la selezione, ma il prossimo
    -- tratto Shift deve partire dalla nuova posizione corrente.
    --------------------------------------------------------
    group_edit_reset_path_to_pos(active_pos)

    speak(get_current_param_spoken_label())

    return true
end

function group_edit_selected_nav_vertical(direction)
    direction = tonumber(direction) or 0

    if direction == 0 then
        return false
    end

    local list = get_active_indices()
    local count = #list

    if count <= 0 then
        return false
    end

    if group_edit_selected_nav_visible_count(list) <= 0 then
        speak("No selected parameters")
        return true
    end

    local safe_grid = clamp_int(grid_size, GRID_MIN, GRID_MAX)
    local pos = clamp_int(active_pos, 1, count)

    local col_start =
        math.floor((pos - 1) / safe_grid) * safe_grid + 1

    local col_end = math.min(col_start + safe_grid - 1, count)

    if direction < 0 then
        for target = pos - 1, col_start, -1 do
            local i = list[target]

            if group_edit_position_is_selected(target, list) then
                return group_edit_selected_nav_move_to_pos(target, list)
            end
        end
    else
        for target = pos + 1, col_end do
            local i = list[target]

            if group_edit_position_is_selected(target, list) then
                return group_edit_selected_nav_move_to_pos(target, list)
            end
        end
    end

    --------------------------------------------------------
    -- Bordo / nessun altro selezionato nella direzione:
    -- resta fermo e non parla.
    --------------------------------------------------------
    return true
end

function group_edit_selected_nav_horizontal(direction)
    direction = tonumber(direction) or 0

    if direction == 0 then
        return false
    end

    local list = get_active_indices()
    local count = #list

    if count <= 0 then
        return false
    end

    if group_edit_selected_nav_visible_count(list) <= 0 then
        speak("No selected parameters")
        return true
    end

    local safe_grid = clamp_int(grid_size, GRID_MIN, GRID_MAX)
    local pos = clamp_int(active_pos, 1, count)

    local current_col = math.floor((pos - 1) / safe_grid) + 1
    local current_row = (pos - 1) % safe_grid
    local total_cols = math.ceil(count / safe_grid)

    local col = current_col + direction

    while col >= 1 and col <= total_cols do
        local col_start = ((col - 1) * safe_grid) + 1
        local col_end = math.min(col_start + safe_grid - 1, count)

        local best_pos = nil
        local best_distance = nil

        for target = col_start, col_end do
            local i = list[target]

            if group_edit_position_is_selected(target, list) then
                local target_row = (target - 1) % safe_grid
                local distance = math.abs(target_row - current_row)

                if best_pos == nil or distance < best_distance then
                    best_pos = target
                    best_distance = distance
                end
            end
        end

        ----------------------------------------------------
        -- Prima colonna nella direzione che contiene almeno
        -- un selezionato: entra li' e non salta oltre.
        ----------------------------------------------------
        if best_pos ~= nil then
            return group_edit_selected_nav_move_to_pos(best_pos, list)
        end

        col = col + direction
    end

    --------------------------------------------------------
    -- Nessuna colonna selezionata nella direzione: fermo.
    --------------------------------------------------------
    return true
end

------------------------------------------------------------
-- 4.5C - TASTI F7 GROUP EDIT
------------------------------------------------------------
function handle_group_edit_grid_key(char)
    local is_ctrl = ctrl_down()
    local is_shift = shift_down()
    local is_alt = alt_down()

    if char == KEY_F7 then
        restore_f7_return_snapshot()
        return true
    end

    if char == KEY_F8 then
        enter_memory_manager_mode()
        return true
    end

    --------------------------------------------------------
    -- Ctrl+Alt+frecce dentro F7:
    -- naviga soltanto tra i parametri gia' selezionati.
    -- Le vecchie Ctrl+Alt di cambio contesto sono disattivate.
    --------------------------------------------------------
    if is_ctrl and is_alt and not is_shift then
        if char == KEY_UP then
            group_edit_selected_nav_vertical(-1)
            return true

        elseif char == KEY_DOWN then
            group_edit_selected_nav_vertical(1)
            return true

        elseif char == KEY_LEFT then
            group_edit_selected_nav_horizontal(-1)
            return true

        elseif char == KEY_RIGHT then
            group_edit_selected_nav_horizontal(1)
            return true
        end
    end

    --------------------------------------------------------
    -- Ctrl+G / Ctrl+M restano disponibili anche dentro F7.
    -- Ctrl+M arriva come char 13 e va disambiguato PRIMA di
    -- Ctrl+Enter usando il JS physical-key state.
    --------------------------------------------------------
    if is_ctrl and not is_shift and not is_alt and char == KEY_CTRL_G then
        select_group_slot_access_mode()
        return true
    end

    if char13_is_ctrl_m(char) then
        select_param_slot_access_mode()
        return true
    end

    --------------------------------------------------------
    -- Ctrl+Enter dentro F7 segue sempre il recinto sticky:
    -- Groups = rename gruppo; Memory positions = rename parametro.
    --------------------------------------------------------
    if is_ctrl and not is_shift and not is_alt and char == KEY_ENTER then
        handle_ctrl_enter_contextual_name_edit()
        return true
    end

    --------------------------------------------------------
    -- Ctrl+F dentro F7:
    -- - se un filtro Search è visibile, lo toglie e mostra
    --   tutto il recinto Edit SENZA perdere la selezione;
    -- - se il filtro non è visibile, apre una nuova Search.
    --
    -- In questo modo più ricerche successive continuano sempre
    -- la stessa selezione F7. Delete resta l'unico reset totale.
    --------------------------------------------------------
    if is_ctrl and not is_shift and not is_alt and char == KEY_CTRL_F then
        if search_active then
            close_search_filter_inside_group_edit()
        else
            start_search_edit()
        end

        return true
    end

    --------------------------------------------------------
    -- Reset Backspace anche dentro F7:
    -- parametro, Step/Grid o reset globale secondo modificatori.
    --------------------------------------------------------
    if handle_backspace_reset_shortcut(char) then
        return true
    end

    --------------------------------------------------------
    -- Step/Grid anche dentro F7.
    -- Alt+Freccia sinistra/destra cambia Step; F1/F2 cambia Grid.
    -- F7 resta una modalità musicale viva: puoi cambiare
    -- Step/Grid o richiamare le azioni utili mentre selezioni.
    --------------------------------------------------------
    if not is_ctrl and not is_shift then
        if handle_step_grid_keys(char) then
            return true
        end
    end

    if not is_ctrl and not is_shift and not is_alt then
        if char == KEY_F5 then
            disarm_slot_deletes()
            clear_param_memory_arm()

            reaper.Main_OnCommand(CMD_F5_ACTION, 0)
            return true

        elseif char == KEY_F6 then
            disarm_slot_deletes()
            clear_param_memory_arm()

            reaper.Main_OnCommand(CMD_F6_ACTION, 0)
            return true

        elseif char == KEY_F9 then
            disarm_slot_deletes()
            clear_param_memory_arm()

            reaper.Main_OnCommand(CMD_F9_ACTION, 0)
            return true
        end
    end

    if is_ctrl and not is_shift and not is_alt and char == KEY_DELETE then
        if group_edit_uses_group_occurrences() then
            group_remove_selected_occurrences()
        elseif group_edit_loaded_slot ~= nil and
               group_edit_show_all_params == true then
            speak("Return to group before remove")
        else
            hide_f7_selected_params_in_custom_order()
        end
        return true
    end

    if char == KEY_DELETE then
        clear_group_edit_selection_only()
        return true
    end    

    if char == KEY_SPACE and is_shift and not is_ctrl and not is_alt then
        toggle_group_selected_current()
        return true
    end

    if char == KEY_ENTER and
       not is_ctrl and
       not is_shift and
       not is_alt then

        enter_value_mode()
        return true
    end

    if char == KEY_TAB then
        speak(tostring(count_group_selected()) .. " selected")
        return true
    end

    if char == KEY_BACKSLASH then
        read_current_line()
        return true
    end

    if is_ctrl and is_shift and not is_alt and
       (char == KEY_HOME or char == KEY_END) then

        group_edit_select_all_grid()
        return true
    end

    if is_shift and not is_ctrl and not is_alt and char == KEY_HOME then
        group_edit_column_edge(true, true)
        return true
    end

    if is_shift and not is_ctrl and not is_alt and char == KEY_END then
        group_edit_column_edge(false, true)
        return true
    end

    if not is_shift and not is_ctrl and not is_alt and char == KEY_HOME then
        group_edit_column_edge(true, false)
        return true
    end

    if not is_shift and not is_ctrl and not is_alt and char == KEY_END then
        group_edit_column_edge(false, false)
        return true
    end

    if is_ctrl and not is_shift and not is_alt and char == KEY_HOME then
        group_edit_move_plain_to_pos(group_edit_get_count())
        return true
    end

    if is_ctrl and not is_shift and not is_alt and char == KEY_END then
        group_edit_move_plain_to_pos(1)
        return true
    end

    if is_shift and not is_ctrl and not is_alt and char == KEY_UP then
        group_edit_move_vertical(-1, true)
        return true
    end

    if is_shift and not is_ctrl and not is_alt and char == KEY_DOWN then
        group_edit_move_vertical(1, true)
        return true
    end

    if is_shift and not is_ctrl and not is_alt and char == KEY_LEFT then
        group_edit_move_horizontal(-1, true)
        return true
    end

    if is_shift and not is_ctrl and not is_alt and char == KEY_RIGHT then
        group_edit_move_horizontal(1, true)
        return true
    end

    if is_shift and not is_ctrl and not is_alt and char == KEY_PAGE_UP then
        group_edit_move_page_vertical(-1, true)
        return true
    end

    if is_shift and not is_ctrl and not is_alt and char == KEY_PAGE_DOWN then
        group_edit_move_page_vertical(1, true)
        return true
    end

    if not is_shift and not is_ctrl and not is_alt and char == KEY_UP then
        group_edit_move_vertical(-1, false)
        return true
    end

    if not is_shift and not is_ctrl and not is_alt and char == KEY_DOWN then
        group_edit_move_vertical(1, false)
        return true
    end

    if not is_shift and not is_ctrl and not is_alt and char == KEY_LEFT then
        group_edit_move_horizontal(-1, false)
        return true
    end

    if not is_shift and not is_ctrl and not is_alt and char == KEY_RIGHT then
        group_edit_move_horizontal(1, false)
        return true
    end

    if not is_shift and not is_ctrl and not is_alt and char == KEY_PAGE_UP then
        group_edit_move_page_vertical(-1, false)
        return true
    end

    if not is_shift and not is_ctrl and not is_alt and char == KEY_PAGE_DOWN then
        group_edit_move_page_vertical(1, false)
        return true
    end

    if handle_letter_jump(char) then
        group_edit_set_anchor_here()
        return true
    end

    return true
end

------------------------------------------------------------
-- 4.6 - NAVIGAZIONE PER INIZIALE
------------------------------------------------------------
function list_cycle_by_initial(letter)
    letter = clean_one_line(letter or ""):lower()

    if letter == "" then
        return false
    end

    local list = get_active_indices()
    local count = #list

    if count <= 0 then
        return false
    end

    disarm_slot_deletes()
    clear_param_memory_arm()

    local start_pos = active_pos + 1

    for n = 1, count do
        local pos = ((start_pos + n - 2) % count) + 1
        local param_i = list[pos]
        local name = get_param_display_name(param_i):lower()

        if name ~= "" and name:sub(1, 1) == letter then
local old_param_index = param_index

active_pos = pos
param_index = param_i
last_letter_key = letter

save_current_param_position()
announce_current_param()            

            return true
        end
    end

    return true
end

------------------------------------------------------------

------------------------------------------------------------
-- PARTE 4 seconda parte / 8
-- 4.7 - RECENT SEARCHES
------------------------------------------------------------
function load_recent_searches()
    recent_searches = {}

    local txt = reaper.GetExtState(EXT_SECTION, EXT_RECENT_SEARCHES) or ""

    for line in txt:gmatch("[^\r\n]+") do
        local q = clean_one_line(line)

        if q ~= "" then
            recent_searches[#recent_searches + 1] = q
        end

        if #recent_searches >= RECENT_MAX then
            break
        end
    end
end

function save_recent_searches()
    local lines = {}

    for i = 1, math.min(#recent_searches, RECENT_MAX) do
        local q = clean_one_line(recent_searches[i])

        if q ~= "" then
            lines[#lines + 1] = q
        end
    end

    reaper.SetExtState(
        EXT_SECTION,
        EXT_RECENT_SEARCHES,
        table.concat(lines, "\n"),
        true
    )
end

function add_recent_search(q)
    q = clean_one_line(q)

    if q == "" then
        return
    end

    local out = { q }
    local q_lower = q:lower()

    for i = 1, #recent_searches do
        local old = clean_one_line(recent_searches[i])

        if old ~= "" and old:lower() ~= q_lower then
            out[#out + 1] = old
        end

        if #out >= RECENT_MAX then
            break
        end
    end

    recent_searches = out

    save_recent_searches()
end

function remove_recent_search_at(pos)
    disarm_slot_deletes()
    clear_param_memory_arm()

    pos = tonumber(pos)

    if pos == nil or pos < 1 or pos > #recent_searches then
        speak("No recent search")
        return
    end

    local removed = table.remove(recent_searches, pos)
    removed = clean_one_line(removed or "")

    save_recent_searches()

    if #recent_searches == 0 then
        recent_pos = 1
        recent_restore_return_snapshot(false)

        speak("Deleted " .. removed .. ". No recent searches")
        return
    end

    recent_pos = clamp_int(recent_pos, 1, #recent_searches)

    speak("Deleted " .. removed .. ". " .. recent_searches[recent_pos])
end

function speak_recent_current()
    if #recent_searches == 0 then
        speak("No recent searches")
        return
    end

    recent_pos = clamp_int(recent_pos, 1, #recent_searches)

    speak(
        "Recent searches. " ..
        tostring(recent_pos) ..
        " of " ..
        tostring(#recent_searches) ..
        ". " ..
        recent_searches[recent_pos]
    )
end

function recent_restore_return_snapshot(announce_it)
    local snapshot = recent_return_snapshot
    recent_return_snapshot = nil

    return restore_navigation_return_snapshot(snapshot, announce_it)
end

function start_recent_searches()
    --------------------------------------------------------
    -- Secondo Ctrl+R = stesso comportamento di Esc.
    --------------------------------------------------------
    if mode == "recent" then
        recent_restore_return_snapshot(true)
        return
    end

    load_recent_searches()

    clear_param_memory_arm()
    disarm_slot_deletes()

    if #recent_searches == 0 then
        speak("No recent searches")
        return
    end

    --------------------------------------------------------
    -- Salva il recinto reale PRIMA di passare alla lista completa.
    --------------------------------------------------------
    recent_return_snapshot = capture_navigation_return_snapshot()

    reset_to_full_grid_silent()

    recent_pos = 1
    mode = "recent"

    speak_recent_current()
end

function recent_move_vertical(direction)
    local count = #recent_searches

    if count <= 0 then
        return
    end

    disarm_slot_deletes()
    clear_param_memory_arm()

    local safe_grid = clamp_int(grid_size, GRID_MIN, GRID_MAX)

    local col_start =
        math.floor((recent_pos - 1) / safe_grid) * safe_grid + 1

    local col_end = col_start + safe_grid - 1

    if col_end > count then
        col_end = count
    end

    local new_pos = recent_pos + direction

    if new_pos < col_start or new_pos > col_end then
        return
    end

    recent_pos = new_pos

    speak_recent_current()
end

function recent_move_page(direction)
    local count = #recent_searches

    if count <= 0 then
        return
    end

    disarm_slot_deletes()
    clear_param_memory_arm()

    local amount = get_page_nav_amount()
    local new_pos = recent_pos + (amount * direction)

    new_pos = clamp_int(new_pos, 1, count)

    if new_pos ~= recent_pos then
        recent_pos = new_pos
        speak_recent_current()
    end
end

function recent_move_horizontal(direction)
    local count = #recent_searches

    if count <= 0 then
        return
    end

    disarm_slot_deletes()
    clear_param_memory_arm()

    local safe_grid = clamp_int(grid_size, GRID_MIN, GRID_MAX)
    local row = (recent_pos - 1) % safe_grid

    local col_start =
        math.floor((recent_pos - 1) / safe_grid) * safe_grid + 1

    local new_col_start = col_start + (safe_grid * direction)
    local new_pos = new_col_start + row

    if new_col_start < 1 or new_col_start > count then
        return
    end

    if new_pos > count then
        new_pos = count
    end

    if new_pos ~= recent_pos then
        recent_pos = new_pos
        speak_recent_current()
    end
end

function recent_column_home()
    local count = #recent_searches

    if count <= 0 then
        return
    end

    disarm_slot_deletes()
    clear_param_memory_arm()

    local safe_grid = clamp_int(grid_size, GRID_MIN, GRID_MAX)

    local col_start =
        math.floor((recent_pos - 1) / safe_grid) * safe_grid + 1

    if recent_pos ~= col_start then
        recent_pos = col_start
        speak_recent_current()
    end
end

function recent_column_end()
    local count = #recent_searches

    if count <= 0 then
        return
    end

    disarm_slot_deletes()
    clear_param_memory_arm()

    local safe_grid = clamp_int(grid_size, GRID_MIN, GRID_MAX)

    local col_start =
        math.floor((recent_pos - 1) / safe_grid) * safe_grid + 1

    local col_end = col_start + safe_grid - 1

    if col_end > count then
        col_end = count
    end

    if recent_pos ~= col_end then
        recent_pos = col_end
        speak_recent_current()
    end
end

function recent_first()
    if #recent_searches <= 0 then
        return
    end

    disarm_slot_deletes()
    clear_param_memory_arm()

    recent_pos = 1

    speak_recent_current()
end

function recent_last()
    if #recent_searches <= 0 then
        return
    end

    disarm_slot_deletes()
    clear_param_memory_arm()

    recent_pos = #recent_searches

    speak_recent_current()
end

------------------------------------------------------------
-- 4.8 - RICERCA PARAMETRI
------------------------------------------------------------
function search_snapshot_copy_table(src)
    local out = {}

    src = src or {}

    for k, v in pairs(src) do
        out[k] = v
    end

    return out
end

function search_clear_return_snapshot()
    search_return_valid = false
    search_return_mode = "list"
    search_return_param_index = nil
    search_return_active_pos = 1
    search_return_custom_order_active = false
    search_return_group_active = false
    search_return_group_slot = nil
    search_return_group_edit_is_temporary = false
    search_return_group_results = {}
    search_return_group_selected = {}
    search_return_group_select_anchor_pos = 1
    search_return_group_select_path = {}
    search_return_group_select_dir_path = {}
    search_return_group_select_path_action = "select"
    search_return_group_select_base_selected = {}
    search_return_group_edit_loaded_slot = nil
    search_return_group_edit_show_all_params = false
    search_return_group_edit_occurrence_selected = {}
    search_return_group_edit_occurrence_base_selected = {}
    search_return_group_edit_search_positions = {}
end

function search_capture_return_snapshot()
    if search_return_valid then
        return true
    end

    search_return_valid = true
    search_return_mode = mode or "list"
    search_return_param_index = param_index
    search_return_active_pos = active_pos
    search_return_custom_order_active = custom_order_active == true
    search_return_group_active = group_active == true
    search_return_group_slot = current_group_slot
    search_return_group_edit_is_temporary = group_edit_is_temporary == true

    search_return_group_results =
        search_snapshot_copy_table(group_results)

    search_return_group_selected =
        search_snapshot_copy_table(group_selected)

    search_return_group_select_anchor_pos =
        tonumber(group_select_anchor_pos) or 1

    search_return_group_select_path =
        search_snapshot_copy_table(group_select_path)

    search_return_group_select_dir_path =
        search_snapshot_copy_table(group_select_dir_path)

    search_return_group_select_path_action =
        tostring(group_select_path_action or "select")

    search_return_group_select_base_selected =
        search_snapshot_copy_table(group_select_base_selected)

    search_return_group_edit_loaded_slot = group_edit_loaded_slot
    search_return_group_edit_show_all_params = group_edit_show_all_params == true
    search_return_group_edit_occurrence_selected =
        search_snapshot_copy_table(group_edit_occurrence_selected)
    search_return_group_edit_occurrence_base_selected =
        search_snapshot_copy_table(group_edit_occurrence_base_selected)
    search_return_group_edit_search_positions =
        search_snapshot_copy_table(group_edit_search_positions)

    return true
end

function search_restore_return_snapshot()
    clear_param_memory_arm()
    disarm_slot_deletes()

    if not search_return_valid then
        return_to_all_parameters(nil)
        return true
    end

    local wanted_mode = search_return_mode or "list"
    local wanted_param = search_return_param_index
    local wanted_pos = tonumber(search_return_active_pos) or 1
    local loaded_slot = search_return_group_edit_loaded_slot
    local wanted_show_all = search_return_group_edit_show_all_params == true

    local current_occurrence_selection =
        search_snapshot_copy_table(group_edit_occurrence_selected)
    local current_group_pos = nil

    if loaded_slot ~= nil and group_edit_uses_group_occurrences() then
        current_group_pos = group_edit_visible_pos_to_group_pos(active_pos)
    end

    search_active = false
    search_results = {}
    search_query = ""
    search_buffer = ""
    search_cursor = 1
    search_edge = nil
    search_edit_fresh = false
    group_edit_search_positions = {}

    custom_order_active =
        search_return_custom_order_active == true

    build_all_param_indices()

    if wanted_mode == "group_edit" then
        group_active = false

        if loaded_slot ~= nil then
            group_results =
                search_snapshot_copy_table(search_return_group_results)
            group_edit_occurrence_selected = current_occurrence_selection
            set_f7_group_edit_context(loaded_slot)
            group_edit_show_all_params = wanted_show_all
        else
            group_results = {}
            group_selected =
                search_snapshot_copy_table(group_selected)
            set_f7_group_edit_context()
        end

        mode = "group_edit"
        value_return_mode = "group_edit"
        numeric_return_mode = "group_edit"

        if loaded_slot ~= nil and not wanted_show_all and current_group_pos ~= nil then
            active_pos = clamp_int(
                current_group_pos,
                1,
                math.max(1, #group_results)
            )
            sync_param_from_active_pos()
        else
            active_pos = wanted_pos

            if wanted_param ~= nil and
               not set_param_index_absolute(wanted_param, false) then

                active_pos = clamp_int(
                    wanted_pos,
                    1,
                    math.max(1, get_active_count())
                )
                sync_param_from_active_pos()
            end
        end

        group_edit_reset_path_to_pos(active_pos)
        save_f7_runtime_selection_for_current_fx()

        save_current_param_position()
        save_current_entry_state()

        search_clear_return_snapshot()
        announce_grid_context(nil)
        return true
    end

    if search_return_group_active then
        group_selected =
            search_snapshot_copy_table(search_return_group_selected)

        group_results =
            search_snapshot_copy_table(search_return_group_results)

        group_active = true

        if search_return_group_slot ~= nil then
            set_loaded_group_context(search_return_group_slot)
        elseif search_return_group_edit_is_temporary then
            set_f7_group_edit_context()
        else
            clear_group_context()
        end

        mode = "list"
        value_return_mode = "list"
        numeric_return_mode = "list"

        active_pos = clamp_int(
            wanted_pos,
            1,
            math.max(1, get_active_count())
        )
        sync_param_from_active_pos()

        save_current_param_position()
        save_current_entry_state()

        search_clear_return_snapshot()
        announce_grid_context(nil)
        return true
    end

    group_active = false
    group_results = {}
    clear_group_context()

    mode = "list"
    value_return_mode = "list"
    numeric_return_mode = "list"

    active_pos = wanted_pos

    if wanted_param ~= nil and
       not set_param_index_absolute(wanted_param, false) then

        active_pos = clamp_int(
            wanted_pos,
            1,
            math.max(1, get_active_count())
        )
        sync_param_from_active_pos()
    end

    save_current_param_position()
    save_current_entry_state()

    search_clear_return_snapshot()
    announce_grid_context(nil)
    return true
end

function refresh_search_results()
    search_results = {}
    group_edit_search_positions = {}

    local q = trim(search_query or ""):lower()

    if q == "" then
        return
    end

    local base = nil
    local loaded_group_search = group_edit_uses_group_occurrences()

    if loaded_group_search then
        base = group_results
    else
        base = get_full_grid_indices()
    end

    for pos = 1, #base do
        local i = base[pos]
        local name = get_param_display_name(i):lower()

        if name ~= "" and name:find(q, 1, true) then
            search_results[#search_results + 1] = i

            if loaded_group_search then
                group_edit_search_positions[#group_edit_search_positions + 1] = pos
            end
        end
    end
end

function clear_search_results(speak_it)
    reset_to_full_grid_silent()

    clear_param_memory_arm()
    disarm_slot_deletes()

    save_current_entry_state()

    if speak_it then
        announce_grid_context(nil)
    end
end

function close_search_filter_inside_group_edit()
    if mode ~= "group_edit" then
        return false
    end

    local loaded_slot = group_edit_loaded_slot
    local wanted_show_all = group_edit_show_all_params == true
    local wanted_param = param_index
    local wanted_pos = active_pos
    local wanted_group_pos = nil

    if loaded_slot ~= nil and not wanted_show_all then
        wanted_group_pos = group_edit_visible_pos_to_group_pos(active_pos)
    end

    search_active = false
    search_results = {}
    search_query = ""
    search_buffer = ""
    search_cursor = 1
    search_edge = nil
    search_edit_fresh = false
    group_edit_search_positions = {}

    group_active = false

    if loaded_slot ~= nil then
        set_f7_group_edit_context(loaded_slot)
        group_edit_show_all_params = wanted_show_all
    else
        group_results = {}
        set_f7_group_edit_context()
        build_all_param_indices()
    end

    mode = "group_edit"
    value_return_mode = "group_edit"
    numeric_return_mode = "group_edit"

    if loaded_slot ~= nil and not wanted_show_all and wanted_group_pos ~= nil then
        active_pos = clamp_int(
            wanted_group_pos,
            1,
            math.max(1, #group_results)
        )
        sync_param_from_active_pos()
    elseif wanted_param ~= nil and
           not set_param_index_absolute(wanted_param, false) then

        active_pos = clamp_int(
            wanted_pos,
            1,
            math.max(1, get_active_count())
        )
        sync_param_from_active_pos()
    end

    group_edit_reset_path_to_pos(active_pos)
    save_f7_runtime_selection_for_current_fx()

    save_current_param_position()
    save_current_entry_state()

    search_clear_return_snapshot()
    announce_grid_context(nil)

    return true
end

function apply_search_query(q, save_recent)
    q = clean_one_line(q)

    clear_param_memory_arm()
    disarm_slot_deletes()

    local return_to_f7 =
        search_return_valid == true and
        search_return_mode == "group_edit"

    if q == "" then
        if return_to_f7 then
            search_restore_return_snapshot()
        else
            clear_search_results(true)
        end

        return
    end

    if return_to_f7 then
        local loaded_slot = search_return_group_edit_loaded_slot
        local wanted_show_all = search_return_group_edit_show_all_params == true

        search_active = false
        search_results = {}
        search_query = q
        search_buffer = ""
        search_cursor = 1
        search_edge = nil

        group_active = false

        if loaded_slot ~= nil then
            group_results =
                search_snapshot_copy_table(search_return_group_results)
            set_f7_group_edit_context(loaded_slot)
            group_edit_show_all_params = wanted_show_all
        else
            group_results = {}
            set_f7_group_edit_context()
        end

        refresh_search_results()

        mode = "group_edit"
        value_return_mode = "group_edit"
        numeric_return_mode = "group_edit"

        if #search_results == 0 then
            search_active = false
            group_edit_search_positions = {}
            group_edit_reset_path_to_pos(active_pos)
            save_f7_runtime_selection_for_current_fx()
            search_clear_return_snapshot()
            speak("No results")
            return
        end

        search_active = true
        active_pos = 1

        sync_param_from_active_pos()
        save_current_param_position()
        save_current_entry_state()

        group_edit_reset_path_to_pos(active_pos)

        if save_recent then
            add_recent_search(q)
        end

        speak(
            "Search results. " ..
            tostring(#search_results) ..
            " results. " ..
            tostring(count_group_selected()) ..
            " selected. " ..
            get_current_param_spoken_label()
        )

        return
    end

    reset_to_full_grid_silent()

    search_query = q

    refresh_search_results()

    mode = "list"
    search_buffer = ""
    search_cursor = 1
    search_edge = nil

    if #search_results == 0 then
        search_active = false
        speak("No results")
        return
    end

    search_active = true
    group_active = false

    active_pos = 1

    sync_param_from_active_pos()
    save_current_param_position()
    save_current_entry_state()

    if save_recent then
        add_recent_search(q)
    end

    speak(
        "Search results. " ..
        tostring(#search_results) ..
        " results. " ..
        get_param_label()
    )
end

function start_search_edit()
    local from_f7 =
        mode == "group_edit" or
        (search_return_valid == true and
         search_return_mode == "group_edit")

    local loaded_slot = group_edit_loaded_slot

    search_capture_return_snapshot()

    if from_f7 then
        search_active = false
        search_results = {}
        search_query = ""
        group_edit_search_positions = {}

        group_active = false

        if loaded_slot ~= nil then
            set_f7_group_edit_context(loaded_slot)
        else
            group_results = {}
            set_f7_group_edit_context()
            build_all_param_indices()
        end

        value_return_mode = "group_edit"
        numeric_return_mode = "group_edit"
    else
        reset_to_full_grid_silent()
    end

    clear_param_memory_arm()
    disarm_slot_deletes()

    mode = "search_edit"
    search_buffer = ""
    search_cursor = 1
    search_edge = nil
    search_edit_fresh = true

    speak("Search")
end

function toggle_search_edit_or_clear_results()
    --------------------------------------------------------
    -- Fuori da F7 mantiene il comportamento storico: Ctrl+F
    -- apre una Search nuova. Il toggle filtro <-> tutto è invece
    -- gestito esplicitamente dal handler F7.
    --------------------------------------------------------
    start_search_edit()
    return true
end

function cancel_search_edit()
    return search_restore_return_snapshot()
end

function finish_search_edit()
    apply_search_query(search_buffer, true)
end

function speak_search_buffer()
    local content = search_buffer ~= "" and search_buffer or "Empty"

    speak("Search. " .. content)
end

function insert_search_char(ch)
    search_edge = nil

    local left = search_buffer:sub(1, search_cursor - 1)
    local right = search_buffer:sub(search_cursor)

    search_buffer = left .. ch .. right
    search_cursor = search_cursor + 1
end

function delete_search_char_before_cursor()
    if search_cursor <= 1 or #search_buffer == 0 then
        speak("Empty")
        return
    end

    local removed = search_buffer:sub(search_cursor - 1, search_cursor - 1)
    local left = search_buffer:sub(1, search_cursor - 2)
    local right = search_buffer:sub(search_cursor)

    search_buffer = left .. right
    search_cursor = search_cursor - 1
    search_edge = nil

    speak(removed)
end

function delete_search_char_at_cursor()
    if search_cursor > #search_buffer or #search_buffer == 0 then
        speak("Empty")
        return
    end

    local removed = search_buffer:sub(search_cursor, search_cursor)
    local left = search_buffer:sub(1, search_cursor - 1)
    local right = search_buffer:sub(search_cursor + 1)

    search_buffer = left .. right
    search_edge = nil

    speak(removed)
end

function speak_search_edge_char(edge_name)
    local len = #search_buffer

    if len == 0 then
        speak("Empty")
        return
    end

    if search_edge == edge_name then
        return
    end

    local pos = edge_name == "end" and len or 1
    local ch = search_buffer:sub(pos, pos)

    search_edge = edge_name

    speak(ch ~= "" and ch or "Empty")
end

------------------------------------------------------------
-- TEXT EDIT WORD SPEECH HELPERS
------------------------------------------------------------
function text_is_word_char(ch)
    ch = tostring(ch or "")

    return ch:match("[%w_]") ~= nil
end

function text_find_word_bounds(buffer, pos)
    buffer = tostring(buffer or "")
    pos = tonumber(pos) or 1

    local len = #buffer

    if len <= 0 then
        return nil, nil
    end

    pos = clamp_int(pos, 1, len)

    if not text_is_word_char(buffer:sub(pos, pos)) then
        return nil, nil
    end

    local first = pos
    local last = pos

    while first > 1 and text_is_word_char(buffer:sub(first - 1, first - 1)) do
        first = first - 1
    end

    while last < len and text_is_word_char(buffer:sub(last + 1, last + 1)) do
        last = last + 1
    end

    return first, last
end

function text_word_at_cursor(buffer, cursor, direction)
    buffer = tostring(buffer or "")
    cursor = tonumber(cursor) or 1
    direction = tonumber(direction) or 1

    local len = #buffer

    if len <= 0 then
        return "Empty"
    end

    cursor = clamp_int(cursor, 1, len + 1)

    local pos = cursor

    pos = clamp_int(pos, 1, len)

    while pos >= 1 and pos <= len do
        local ch = buffer:sub(pos, pos)

        if text_is_word_char(ch) then
            local first, last = text_find_word_bounds(buffer, pos)

            if first and last then
                return buffer:sub(first, last)
            end
        end

        pos = pos + (direction < 0 and -1 or 1)
    end

    return "Blank"
end

function text_get_word_at_or_near_cursor(buffer, cursor, direction)
    buffer = tostring(buffer or "")
    cursor = tonumber(cursor) or 1
    direction = tonumber(direction) or 1

    local len = #buffer

    if len <= 0 then
        return "Empty"
    end

    cursor = clamp_int(cursor, 1, len + 1)

    --------------------------------------------------------
    -- Prima prova il carattere sotto il cursore.
    --------------------------------------------------------
    local pos = cursor

    if pos > len then
        pos = len
    end

    if pos < 1 then
        pos = 1
    end

    if text_is_word_char(buffer:sub(pos, pos)) then
        local first, last = text_find_word_bounds(buffer, pos)

        if first and last then
            return buffer:sub(first, last)
        end
    end

    --------------------------------------------------------
    -- Se il cursore è tra due parole o su uno spazio,
    -- cerca nella direzione richiesta.
    --------------------------------------------------------
    pos = cursor

    if direction < 0 then
        pos = pos - 1
    end

    pos = clamp_int(pos, 1, len)

    while pos >= 1 and pos <= len do
        local ch = buffer:sub(pos, pos)

        if text_is_word_char(ch) then
            local first, last = text_find_word_bounds(buffer, pos)

            if first and last then
                return buffer:sub(first, last)
            end
        end

        pos = pos + (direction < 0 and -1 or 1)
    end

    return "Blank"
end

function text_move_cursor_word_left(buffer, cursor)
    buffer = tostring(buffer or "")
    cursor = tonumber(cursor) or 1

    local len = #buffer

    if len <= 0 then
        return 1
    end

    cursor = clamp_int(cursor, 1, len + 1)

    local pos = cursor - 1

    while pos > 1 and not text_is_word_char(buffer:sub(pos, pos)) do
        pos = pos - 1
    end

    while pos > 1 and text_is_word_char(buffer:sub(pos - 1, pos - 1)) do
        pos = pos - 1
    end

    return clamp_int(pos, 1, len + 1)
end

function text_move_cursor_word_right(buffer, cursor)
    buffer = tostring(buffer or "")
    cursor = tonumber(cursor) or 1

    local len = #buffer

    if len <= 0 then
        return 1
    end

    cursor = clamp_int(cursor, 1, len + 1)

    --------------------------------------------------------
    -- Trova la parola corrente o vicina.
    -- Se siamo già dentro una parola, prima salta alla fine
    -- di quella parola.
    --------------------------------------------------------
    local pos = cursor

    if pos > len then
        pos = len
    end

    if text_is_word_char(buffer:sub(pos, pos)) then
        while pos <= len and text_is_word_char(buffer:sub(pos, pos)) do
            pos = pos + 1
        end
    end

    --------------------------------------------------------
    -- Salta gli spazi / separatori fino alla prossima parola.
    --------------------------------------------------------
    while pos <= len and not text_is_word_char(buffer:sub(pos, pos)) do
        pos = pos + 1
    end

    --------------------------------------------------------
    -- Se abbiamo trovato una prossima parola, torna sulla
    -- sua prima lettera.
    --------------------------------------------------------
    if pos <= len and text_is_word_char(buffer:sub(pos, pos)) then
        return pos
    end

    --------------------------------------------------------
    -- Bordo finale:
    -- NON andare a len + 1.
    -- Resta sulla prima lettera dell'ultima parola.
    --------------------------------------------------------
    pos = len

    while pos > 1 and not text_is_word_char(buffer:sub(pos, pos)) do
        pos = pos - 1
    end

    if not text_is_word_char(buffer:sub(pos, pos)) then
        return cursor
    end

    while pos > 1 and text_is_word_char(buffer:sub(pos - 1, pos - 1)) do
        pos = pos - 1
    end

    return pos
end

------------------------------------------------------------
-- TEXT EDIT CHAR MOVEMENT
--
-- Regole:
-- - freccia sinistra/destra non ripete la prima o ultima lettera;
-- - quando si è già al bordo, resta in silenzio;
-- - non dice più "End";
-- - Home/End possono comunque usare gli helper edge dei singoli campi.
------------------------------------------------------------
text_char_move_changed = true

function text_speak_char_at_cursor(buffer, cursor)
    buffer = tostring(buffer or "")
    cursor = tonumber(cursor) or 1

    local len = #buffer

    if len <= 0 then
        speak("Empty")
        return
    end

    if text_char_move_changed == false then
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
        text_char_move_changed = false
        return 1
    end

    --------------------------------------------------------
    -- Se per qualche motivo il cursore è oltre l'ultima
    -- lettera, rientra sull'ultima lettera e la legge.
    --------------------------------------------------------
    if cursor > len then
        text_char_move_changed = true
        return len
    end

    cursor = clamp_int(cursor, 1, len)

    if cursor <= 1 then
        text_char_move_changed = false
        return 1
    end

    text_char_move_changed = true
    return cursor - 1
end

function text_move_cursor_right_char(buffer, cursor)
    buffer = tostring(buffer or "")
    cursor = tonumber(cursor) or 1

    local len = #buffer

    if len <= 0 then
        text_char_move_changed = false
        return 1
    end

    cursor = clamp_int(cursor, 1, len)

    if cursor >= len then
        text_char_move_changed = false
        return len
    end

    text_char_move_changed = true
    return cursor + 1
end

function handle_search_edit(char)
    local is_ctrl = ctrl_down()
    local is_shift = shift_down()
    local is_alt = alt_down()

    --------------------------------------------------------
    -- Ctrl+F dentro Search = nuova ricerca.
    -- Cancella anche l'eventuale testo già scritto e riparte
    -- dalla lista completa. Non chiude la sessione Search.
    --------------------------------------------------------
    if is_ctrl and not is_shift and not is_alt and char == KEY_CTRL_F then
        start_search_edit()
        return true
    end

    if char == KEY_ESC then
        cancel_search_edit()
        return true
    end

    if char == KEY_ENTER then
        finish_search_edit()
        return true
    end

    if char == KEY_TAB or char == KEY_BACKSLASH then
        speak_search_buffer()
        return true
    end

    if char == KEY_BACKSPACE or
       char == KEY_BACKSPACE_2 then

        search_edit_fresh = false

        delete_search_char_before_cursor()
        return true
    end

    if char == KEY_DELETE then
        if search_edit_fresh then
            search_edit_fresh = false

            if search_buffer ~= "" then
                search_buffer = ""
                search_cursor = 1
                search_edge = nil

                speak("Cleared")
            else
                speak("Empty")
            end

            return true
        end

        delete_search_char_at_cursor()
        return true
    end

    if not is_ctrl and not is_shift and not is_alt and char == KEY_LEFT then
        search_edit_fresh = false

        if #search_buffer == 0 then
            speak("Empty")
            return true
        end

        search_cursor =
            text_move_cursor_left_char(search_buffer, search_cursor)

        search_edge = nil

        text_speak_char_at_cursor(search_buffer, search_cursor)

        return true
    end

    if not is_ctrl and not is_shift and not is_alt and char == KEY_RIGHT then
        search_edit_fresh = false

        if #search_buffer == 0 then
            speak("Empty")
            return true
        end

        search_cursor =
            text_move_cursor_right_char(search_buffer, search_cursor)

        search_edge = nil

        text_speak_char_at_cursor(search_buffer, search_cursor)

        return true
    end

    if is_ctrl and not is_shift and not is_alt and char == KEY_LEFT then
        search_edit_fresh = false

        if #search_buffer == 0 then
            speak("Empty")
            return true
        end

        local old_cursor = search_cursor
        local new_cursor =
            text_move_cursor_word_left(search_buffer, search_cursor)

        if new_cursor == old_cursor then
            return true
        end

        search_cursor = new_cursor
        search_edge = nil

        speak(
            text_get_word_at_or_near_cursor(
                search_buffer,
                search_cursor,
                -1
            )
        )

        return true
    end

    if is_ctrl and not is_shift and not is_alt and char == KEY_RIGHT then
        search_edit_fresh = false

        if #search_buffer == 0 then
            speak("Empty")
            return true
        end

        local old_cursor = search_cursor

        search_cursor =
            text_move_cursor_word_right(search_buffer, search_cursor)

        search_edge = nil

        if search_cursor == old_cursor then
            return true
        end

        speak(
            text_get_word_at_or_near_cursor(
                search_buffer,
                search_cursor,
                1
            )
        )

        return true
    end

    if char == KEY_HOME then
        search_edit_fresh = false

        if #search_buffer == 0 then
            search_cursor = 1
            search_edge = nil

            speak("Empty")
        else
            search_cursor = #search_buffer + 1
            speak_search_edge_char("end")
        end

        return true
    end

    if char == KEY_END then
        search_edit_fresh = false

        if #search_buffer == 0 then
            search_cursor = 1
            search_edge = nil

            speak("Empty")
        else
            search_cursor = 1
            speak_search_edge_char("home")
        end

        return true
    end

    local c = safe_char(char)

    if not is_ctrl and not is_alt and
       c and c:match("[%w%s%-%._%#%+%[%]%(%)]") then

        search_edit_fresh = false

        insert_search_char(c)
        speak(c)

        return true
    end

    return true
end

------------------------------------------------------------
-- 4.8 - CONTESTO STRUTTURALE MODIFICABILE
--
-- Plugin order e le sue Search sono sola lettura strutturale.
-- Solo Ctrl+L entra intenzionalmente in Custom order.
-- I Group reali restano contenitori autonomi modificabili.
------------------------------------------------------------
function get_structural_edit_container()
    --------------------------------------------------------
    -- Group reale / Group Edit, compresa una Search aperta
    -- sopra un Group: resta sempre contesto Group.
    --------------------------------------------------------
    if (group_active and current_group_slot ~= nil) or
       group_edit_loaded_slot ~= nil then
        return "group"
    end

    if search_return_valid and
       search_return_group_active and
       search_return_group_slot ~= nil then
        return "group"
    end

    --------------------------------------------------------
    -- Custom order, compresa una Search aperta dalla Custom.
    --------------------------------------------------------
    if custom_order_active == true then
        return "custom"
    end

    if search_return_valid and
       search_return_custom_order_active == true then
        return "custom"
    end

    --------------------------------------------------------
    -- Tutto il resto e' Plugin order: sola lettura strutturale.
    --------------------------------------------------------
    return "plugin"
end

function plugin_order_structure_is_read_only()
    return get_structural_edit_container() == "plugin"
end

------------------------------------------------------------
-- 4.8S - F7 È L'UNICA PORTA DI MODIFICA STRUTTURALE
--
-- Plugin order, Custom order e Group fuori da F7 sono viste.
-- Soltanto Edit F7 può cambiare ordine, nomi, visibilità,
-- clipboard strutturale o contenuto dei Group.
------------------------------------------------------------
function f7_structural_edit_is_active()
    return mode == "group_edit"
end

function speak_f7_edit_required()
    local container = get_structural_edit_container()

    if container == "plugin" then
        speak("Plugin order. Read only")
    elseif container == "group" then
        speak("Group. Read only. Press F7 to edit")
    else
        speak("Custom order. Read only. Press F7 to edit")
    end

    return false
end
function start_param_name_edit()
    clear_param_memory_arm()
    disarm_slot_deletes()

    --------------------------------------------------------
    -- Il nome del parametro è modificabile soltanto dentro F7.
    -- Plugin/Custom/Group normali sono viste in sola lettura
    -- dal punto di vista strutturale.
    --------------------------------------------------------
    if not f7_structural_edit_is_active() then
        speak_f7_edit_required()
        return false
    end

    if not param_index_is_valid(param_index) then
        speak("No parameter")
        return false
    end

    --------------------------------------------------------
    -- Gli alias parametri restano metadati Custom del plugin.
    -- F7 rende intenzionale la modifica anche se il parametro
    -- è raggiunto da un Group.
    --------------------------------------------------------
    ensure_custom_order_runtime()

    name_edit_return_mode = mode
    name_edit_param_index = param_index

    name_edit_buffer = get_param_alias(param_index)

    if name_edit_buffer == "" then
        name_edit_buffer = get_param_original_name(param_index)
    end

    name_edit_cursor = #name_edit_buffer + 1
    name_edit_edge = nil
    name_edit_fresh = true

    mode = "name_edit"

    speak("Edit param name. " .. name_edit_buffer)

    return true
end
function finish_param_name_edit()
    if name_edit_param_index == nil then
        mode = name_edit_return_mode or "list"
        announce_grid_context(nil)
        return
    end

    local i = name_edit_param_index
    local typed = clean_one_line(name_edit_buffer or "")
    local original = get_param_original_name(i)

    ensure_custom_order_runtime()

    if typed == "" or typed == original then
        custom_param_aliases[i] = nil

        save_custom_order_runtime_to_txt()

        mode = name_edit_return_mode or "list"
        name_edit_param_index = nil
        name_edit_buffer = ""
        name_edit_cursor = 1
        name_edit_edge = nil

        if search_active then
            refresh_search_results()
        end

        set_param_index_absolute(i, false)

        speak("Name reset. " .. original)
        return
    end

    custom_param_aliases[i] = typed

    save_custom_order_runtime_to_txt()

    mode = name_edit_return_mode or "list"
    name_edit_param_index = nil
    name_edit_buffer = ""
    name_edit_cursor = 1
    name_edit_edge = nil

    if search_active then
        refresh_search_results()
    end

    set_param_index_absolute(i, false)

    speak("Name saved. " .. get_param_display_name(i))
end

function cancel_param_name_edit()
    local i = name_edit_param_index

    mode = name_edit_return_mode or "list"

    name_edit_param_index = nil
    name_edit_buffer = ""
    name_edit_cursor = 1
    name_edit_edge = nil

    if i ~= nil then
        set_param_index_absolute(i, false)
    end

    speak("Cancelled. " .. get_current_param_spoken_label())
end

function speak_name_edit_buffer()
    local content = name_edit_buffer ~= "" and name_edit_buffer or "Empty"

    speak("Edit param name. " .. content)
end

function insert_name_edit_char(ch)
    name_edit_edge = nil

    local left = name_edit_buffer:sub(1, name_edit_cursor - 1)
    local right = name_edit_buffer:sub(name_edit_cursor)

    name_edit_buffer = left .. ch .. right
    name_edit_cursor = name_edit_cursor + 1
end

function delete_name_edit_char_before_cursor()
    if name_edit_cursor <= 1 or #name_edit_buffer == 0 then
        speak("Empty")
        return
    end

    local removed =
        name_edit_buffer:sub(name_edit_cursor - 1, name_edit_cursor - 1)

    local left = name_edit_buffer:sub(1, name_edit_cursor - 2)
    local right = name_edit_buffer:sub(name_edit_cursor)

    name_edit_buffer = left .. right
    name_edit_cursor = name_edit_cursor - 1
    name_edit_edge = nil

    speak(removed)
end

function delete_name_edit_char_at_cursor()
    if name_edit_cursor > #name_edit_buffer or #name_edit_buffer == 0 then
        speak("Empty")
        return
    end

    local removed =
        name_edit_buffer:sub(name_edit_cursor, name_edit_cursor)

    local left = name_edit_buffer:sub(1, name_edit_cursor - 1)
    local right = name_edit_buffer:sub(name_edit_cursor + 1)

    name_edit_buffer = left .. right
    name_edit_edge = nil

    speak(removed)
end

function speak_name_edit_edge_char(edge_name)
    local len = #name_edit_buffer

    if len == 0 then
        speak("Empty")
        return
    end

    if name_edit_edge == edge_name then
        return
    end

    local pos = edge_name == "end" and len or 1
    local ch = name_edit_buffer:sub(pos, pos)

    name_edit_edge = edge_name

    speak(ch ~= "" and ch or "Empty")
end

function handle_param_name_edit(char)
    local is_ctrl = ctrl_down()
    local is_alt = alt_down()

    if char == KEY_ESC then
        cancel_param_name_edit()
        return true
    end

    if char == KEY_ENTER then
        finish_param_name_edit()
        return true
    end

    if char == KEY_TAB or char == KEY_BACKSLASH then
        speak_name_edit_buffer()
        return true
    end

    if char == KEY_BACKSPACE or
       char == KEY_BACKSPACE_2 then

        name_edit_fresh = false

        delete_name_edit_char_before_cursor()
        return true
    end

    if char == KEY_DELETE then
        if name_edit_fresh then
            name_edit_fresh = false

            if name_edit_buffer ~= "" then
                name_edit_buffer = ""
                name_edit_cursor = 1
                name_edit_edge = nil

                speak("Cleared")
            else
                speak("Empty")
            end

            return true
        end

        delete_name_edit_char_at_cursor()
        return true
    end

    if not is_ctrl and not shift_down() and not is_alt and char == KEY_LEFT then
        name_edit_fresh = false

        if #name_edit_buffer == 0 then
            speak("Empty")
            return true
        end

        name_edit_cursor =
            text_move_cursor_left_char(name_edit_buffer, name_edit_cursor)

        name_edit_edge = nil

        text_speak_char_at_cursor(name_edit_buffer, name_edit_cursor)

        return true
    end

    if not is_ctrl and not shift_down() and not is_alt and char == KEY_RIGHT then
        name_edit_fresh = false

        if #name_edit_buffer == 0 then
            speak("Empty")
            return true
        end

        name_edit_cursor =
            text_move_cursor_right_char(name_edit_buffer, name_edit_cursor)

        name_edit_edge = nil

        text_speak_char_at_cursor(name_edit_buffer, name_edit_cursor)

        return true
    end

    if is_ctrl and not shift_down() and not is_alt and char == KEY_LEFT then
        name_edit_fresh = false

        if #name_edit_buffer == 0 then
            speak("Empty")
            return true
        end

        local old_cursor = name_edit_cursor
        local new_cursor =
            text_move_cursor_word_left(name_edit_buffer, name_edit_cursor)

        if new_cursor == old_cursor then
            return true
        end

        name_edit_cursor = new_cursor
        name_edit_edge = nil

        speak(
            text_get_word_at_or_near_cursor(
                name_edit_buffer,
                name_edit_cursor,
                -1
            )
        )

        return true
    end

    if is_ctrl and not shift_down() and not is_alt and char == KEY_RIGHT then
        name_edit_fresh = false

        if #name_edit_buffer == 0 then
            speak("Empty")
            return true
        end

        local old_cursor = name_edit_cursor

        name_edit_cursor =
            text_move_cursor_word_right(name_edit_buffer, name_edit_cursor)

        name_edit_edge = nil

        if name_edit_cursor == old_cursor then
            return true
        end

        speak(
            text_get_word_at_or_near_cursor(
                name_edit_buffer,
                name_edit_cursor,
                1
            )
        )

        return true
    end

    if char == KEY_HOME then
        name_edit_fresh = false

        if #name_edit_buffer == 0 then
            name_edit_cursor = 1
            name_edit_edge = nil

            speak("Empty")
        else
            name_edit_cursor = #name_edit_buffer + 1
            speak_name_edit_edge_char("end")
        end

        return true
    end

    if char == KEY_END then
        name_edit_fresh = false

        if #name_edit_buffer == 0 then
            name_edit_cursor = 1
            name_edit_edge = nil

            speak("Empty")
        else
            name_edit_cursor = 1
            speak_name_edit_edge_char("home")
        end

        return true
    end

    local c = safe_char(char)

    if not is_ctrl and not is_alt and
       c and c:match("[%w%s%-%._%#%+%[%]%(%)]") then

        name_edit_fresh = false

        insert_name_edit_char(c)
        speak(c)

        return true
    end

    return true
end

------------------------------------------------------------
-- 4.8B - EDIT NOME GRUPPO
------------------------------------------------------------
function start_group_name_edit(slot_override)
    clear_param_memory_arm()
    disarm_slot_deletes()

    --------------------------------------------------------
    -- Anche il nome del Group è protetto: si modifica soltanto
    -- da Edit F7. Aprire o visitare un Group non abilita rename.
    --------------------------------------------------------
    if not f7_structural_edit_is_active() then
        speak_f7_edit_required()
        return false
    end

    local wanted_slot = tonumber(slot_override)

    if wanted_slot == nil then
        wanted_slot = current_group_slot
    end

    if wanted_slot == nil and group_edit_loaded_slot ~= nil then
        wanted_slot = group_edit_loaded_slot
    end

    if wanted_slot == nil then
        speak("No current group")
        return false
    end

    wanted_slot = clamp_int(wanted_slot, 1, 12)

    if not group_slot_has_content(wanted_slot) then
        speak("No current group")
        return false
    end

    group_name_edit_slot = wanted_slot
    group_name_edit_return_mode = mode

    group_name_edit_buffer = get_group_slot_name(group_name_edit_slot)
    group_name_edit_cursor = #group_name_edit_buffer + 1
    group_name_edit_edge = nil
    group_name_edit_fresh = true

    mode = "group_name_edit"

    if group_name_edit_buffer ~= "" then
        speak(
            "Edit group " ..
            tostring(group_name_edit_slot) ..
            " name. " ..
            group_name_edit_buffer
        )
    else
        speak(
            "Edit group " ..
            tostring(group_name_edit_slot) ..
            " name. Empty"
        )
    end

    return true
end
function finish_group_name_edit()
    local slot = group_name_edit_slot

    if slot == nil then
        mode = group_name_edit_return_mode or "list"
        announce_grid_context(nil)
        return
    end

    local typed = clean_one_line(group_name_edit_buffer or "")

    set_group_slot_name(slot, typed)

    mode = group_name_edit_return_mode or "list"

    group_name_edit_slot = nil
    group_name_edit_buffer = ""
    group_name_edit_cursor = 1
    group_name_edit_edge = nil

    local label = get_group_slot_status_label(slot)

    if label == nil then
        label = "Group " .. tostring(slot)
    end

    if typed == "" then
        speak("Group name reset. " .. label)
    else
        speak("Group name saved. " .. label)
    end
end

function cancel_group_name_edit()
    local slot = group_name_edit_slot

    mode = group_name_edit_return_mode or "list"

    group_name_edit_slot = nil
    group_name_edit_buffer = ""
    group_name_edit_cursor = 1
    group_name_edit_edge = nil

    if slot ~= nil then
        local label = get_group_slot_status_label(slot)

        if label ~= nil then
            speak("Cancelled. " .. label)
            return
        end
    end

    speak("Cancelled")
end

function speak_group_name_edit_buffer()
    local content =
        group_name_edit_buffer ~= "" and
        group_name_edit_buffer or
        "Empty"

    speak(
        "Edit group " ..
        tostring(group_name_edit_slot or current_group_slot or "") ..
        " name. " ..
        content
    )
end

function insert_group_name_edit_char(ch)
    group_name_edit_edge = nil

    local left =
        group_name_edit_buffer:sub(1, group_name_edit_cursor - 1)

    local right =
        group_name_edit_buffer:sub(group_name_edit_cursor)

    group_name_edit_buffer = left .. ch .. right
    group_name_edit_cursor = group_name_edit_cursor + 1
end

function delete_group_name_edit_char_before_cursor()
    if group_name_edit_cursor <= 1 or #group_name_edit_buffer == 0 then
        speak("Empty")
        return
    end

    local removed =
        group_name_edit_buffer:sub(
            group_name_edit_cursor - 1,
            group_name_edit_cursor - 1
        )

    local left =
        group_name_edit_buffer:sub(1, group_name_edit_cursor - 2)

    local right =
        group_name_edit_buffer:sub(group_name_edit_cursor)

    group_name_edit_buffer = left .. right
    group_name_edit_cursor = group_name_edit_cursor - 1
    group_name_edit_edge = nil

    speak(removed)
end

function delete_group_name_edit_char_at_cursor()
    if group_name_edit_cursor > #group_name_edit_buffer or
       #group_name_edit_buffer == 0 then

        speak("Empty")
        return
    end

    local removed =
        group_name_edit_buffer:sub(
            group_name_edit_cursor,
            group_name_edit_cursor
        )

    local left =
        group_name_edit_buffer:sub(1, group_name_edit_cursor - 1)

    local right =
        group_name_edit_buffer:sub(group_name_edit_cursor + 1)

    group_name_edit_buffer = left .. right
    group_name_edit_edge = nil

    speak(removed)
end

function speak_group_name_edit_edge_char(edge_name)
    local len = #group_name_edit_buffer

    if len == 0 then
        speak("Empty")
        return
    end

    if group_name_edit_edge == edge_name then
        return
    end

    local pos = edge_name == "end" and len or 1
    local ch = group_name_edit_buffer:sub(pos, pos)

    group_name_edit_edge = edge_name

    speak(ch ~= "" and ch or "Empty")
end

function handle_group_name_edit(char)
    local is_ctrl = ctrl_down()
    local is_alt = alt_down()

    if char == KEY_ESC then
        cancel_group_name_edit()
        return true
    end

    if char == KEY_ENTER then
        finish_group_name_edit()
        return true
    end

    if char == KEY_TAB or char == KEY_BACKSLASH then
        speak_group_name_edit_buffer()
        return true
    end

    if char == KEY_BACKSPACE or
       char == KEY_BACKSPACE_2 then

        group_name_edit_fresh = false

        delete_group_name_edit_char_before_cursor()
        return true
    end

    if char == KEY_DELETE then
        if group_name_edit_fresh then
            group_name_edit_fresh = false

            if group_name_edit_buffer ~= "" then
                group_name_edit_buffer = ""
                group_name_edit_cursor = 1
                group_name_edit_edge = nil

                speak("Cleared")
            else
                speak("Empty")
            end

            return true
        end

        delete_group_name_edit_char_at_cursor()
        return true
    end

    if not is_ctrl and not shift_down() and not is_alt and char == KEY_LEFT then
        group_name_edit_fresh = false

        if #group_name_edit_buffer == 0 then
            speak("Empty")
            return true
        end

        group_name_edit_cursor =
            text_move_cursor_left_char(
                group_name_edit_buffer,
                group_name_edit_cursor
            )

        group_name_edit_edge = nil

        text_speak_char_at_cursor(
            group_name_edit_buffer,
            group_name_edit_cursor
        )

        return true
    end

    if not is_ctrl and not shift_down() and not is_alt and char == KEY_RIGHT then
        group_name_edit_fresh = false

        if #group_name_edit_buffer == 0 then
            speak("Empty")
            return true
        end

        group_name_edit_cursor =
            text_move_cursor_right_char(
                group_name_edit_buffer,
                group_name_edit_cursor
            )

        group_name_edit_edge = nil

        text_speak_char_at_cursor(
            group_name_edit_buffer,
            group_name_edit_cursor
        )

        return true
    end

    if is_ctrl and not shift_down() and not is_alt and char == KEY_LEFT then
        group_name_edit_fresh = false

        if #group_name_edit_buffer == 0 then
            speak("Empty")
            return true
        end

        local old_cursor = group_name_edit_cursor

        local new_cursor =
            text_move_cursor_word_left(
                group_name_edit_buffer,
                group_name_edit_cursor
            )

        if new_cursor == old_cursor then
            return true
        end

        group_name_edit_cursor = new_cursor
        group_name_edit_edge = nil

        speak(
            text_get_word_at_or_near_cursor(
                group_name_edit_buffer,
                group_name_edit_cursor,
                -1
            )
        )

        return true
    end

    if is_ctrl and not shift_down() and not is_alt and char == KEY_RIGHT then
        group_name_edit_fresh = false

        if #group_name_edit_buffer == 0 then
            speak("Empty")
            return true
        end

        local old_cursor = group_name_edit_cursor

        group_name_edit_cursor =
            text_move_cursor_word_right(
                group_name_edit_buffer,
                group_name_edit_cursor
            )

        group_name_edit_edge = nil

        if group_name_edit_cursor == old_cursor then
            return true
        end

        speak(
            text_get_word_at_or_near_cursor(
                group_name_edit_buffer,
                group_name_edit_cursor,
                1
            )
        )

        return true
    end

    if char == KEY_HOME then
        group_name_edit_fresh = false

        if #group_name_edit_buffer == 0 then
            group_name_edit_cursor = 1
            group_name_edit_edge = nil

            speak("Empty")
        else
            group_name_edit_cursor = #group_name_edit_buffer + 1
            speak_group_name_edit_edge_char("end")
        end

        return true
    end

    if char == KEY_END then
        group_name_edit_fresh = false

        if #group_name_edit_buffer == 0 then
            group_name_edit_cursor = 1
            group_name_edit_edge = nil

            speak("Empty")
        else
            group_name_edit_cursor = 1
            speak_group_name_edit_edge_char("home")
        end

        return true
    end

    local c = safe_char(char)

    if not is_ctrl and not is_alt and
       c and c:match("[%w%s%-%._%#%+%[%]%(%)]") then

        group_name_edit_fresh = false

        insert_group_name_edit_char(c)
        speak(c)

        return true
    end

    return true
end

------------------------------------------------------------
-- 4.9 - TASTI RECENT SEARCHES
------------------------------------------------------------
function handle_recent_key(char)
    local is_ctrl = ctrl_down()
    local is_shift = shift_down()
    local is_alt = alt_down()

    if char == KEY_ESC or
       (is_ctrl and not is_shift and not is_alt and char == KEY_CTRL_R) then

        recent_restore_return_snapshot(true)
        return true
    end

    if char == KEY_TAB or char == KEY_BACKSLASH then
        speak_recent_current()
        return true
    end

    if char == KEY_UP then
        recent_move_vertical(-1)
        return true
    end

    if char == KEY_DOWN then
        recent_move_vertical(1)
        return true
    end

    if char == KEY_LEFT then
        recent_move_horizontal(-1)
        return true
    end

    if char == KEY_RIGHT then
        recent_move_horizontal(1)
        return true
    end

    if char == KEY_PAGE_UP then
        recent_move_page(-1)
        return true
    end

    if char == KEY_PAGE_DOWN then
        recent_move_page(1)
        return true
    end

    if char == KEY_HOME then
        if is_ctrl then
            recent_last()
        else
            recent_column_end()
        end

        return true
    end

    if char == KEY_END then
        if is_ctrl then
            recent_first()
        else
            recent_column_home()
        end

        return true
    end

    if char == KEY_DELETE then
        remove_recent_search_at(recent_pos)
        return true
    end

    if char == KEY_ENTER then
        clear_param_memory_arm()
        disarm_slot_deletes()

        if #recent_searches == 0 then
            speak("No recent searches")
            return true
        end

        recent_pos = clamp_int(recent_pos, 1, #recent_searches)

        apply_search_query(recent_searches[recent_pos], true)
        return true
    end

    return true
end

------------------------------------------------------------
-- 4.10 - LIST GRID NAV HELPERS
------------------------------------------------------------
function list_move_to_pos(new_pos)
    set_active_pos(new_pos, true)
end

function list_move_vertical(direction)
    local count = get_active_count()

    if count <= 0 then
        return
    end

    disarm_slot_deletes()
    clear_param_memory_arm()

    local safe_grid = clamp_int(grid_size, GRID_MIN, GRID_MAX)

    local col_start =
        math.floor((active_pos - 1) / safe_grid) * safe_grid + 1

    local col_end = col_start + safe_grid - 1

    if col_end > count then
        col_end = count
    end

    local new_pos = active_pos + direction

    if new_pos < col_start or new_pos > col_end then
        return
    end

    list_move_to_pos(new_pos)
end

function list_move_by_step(direction)
    local count = get_active_count()

    if count <= 0 then
        return
    end

    disarm_slot_deletes()
    clear_param_memory_arm()

    --------------------------------------------------------
    -- Page Up / Page Down devono rispettare lo stesso recinto
    -- verticale di Up / Down e Home / End: non oltrepassano
    -- mai il bordo della colonna definita da Grid.
    --------------------------------------------------------
    local safe_grid = clamp_int(grid_size, GRID_MIN, GRID_MAX)

    local col_start =
        math.floor((active_pos - 1) / safe_grid) * safe_grid + 1

    local col_end = math.min(count, col_start + safe_grid - 1)

    local amount = get_page_nav_amount()
    local new_pos = active_pos + (amount * direction)

    if new_pos < col_start then
        new_pos = col_start
    end

    if new_pos > col_end then
        new_pos = col_end
    end

    if new_pos == active_pos then
        return
    end

    list_move_to_pos(new_pos)
end

function list_move_horizontal(direction)
    local count = get_active_count()

    if count <= 0 then
        return
    end

    disarm_slot_deletes()
    clear_param_memory_arm()

    local safe_grid = clamp_int(grid_size, GRID_MIN, GRID_MAX)
    local row = (active_pos - 1) % safe_grid

    local col_start =
        math.floor((active_pos - 1) / safe_grid) * safe_grid + 1

    local new_col_start = col_start + (safe_grid * direction)
    local new_pos = new_col_start + row

    if new_col_start < 1 or new_col_start > count then
        return
    end

    if new_pos > count then
        new_pos = count
    end

    list_move_to_pos(new_pos)
end

function list_column_home()
    local count = get_active_count()

    if count <= 0 then
        return
    end

    disarm_slot_deletes()
    clear_param_memory_arm()

    local safe_grid = clamp_int(grid_size, GRID_MIN, GRID_MAX)

    local col_start =
        math.floor((active_pos - 1) / safe_grid) * safe_grid + 1

    list_move_to_pos(col_start)
end

function list_column_end()
    local count = get_active_count()

    if count <= 0 then
        return
    end

    disarm_slot_deletes()
    clear_param_memory_arm()

    local safe_grid = clamp_int(grid_size, GRID_MIN, GRID_MAX)

    local col_start =
        math.floor((active_pos - 1) / safe_grid) * safe_grid + 1

    local col_end = col_start + safe_grid - 1

    if col_end > count then
        col_end = count
    end

    list_move_to_pos(col_end)
end

function list_first()
    local count = get_active_count()

    if count <= 0 then
        return
    end

    disarm_slot_deletes()
    clear_param_memory_arm()

    list_move_to_pos(1)
end

function list_last()
    local count = get_active_count()

    if count <= 0 then
        return
    end

    disarm_slot_deletes()
    clear_param_memory_arm()

    list_move_to_pos(count)
end

------------------------------------------------------------
-- 4.11 - VALUE NAV HELPERS
------------------------------------------------------------
function refocus_fx_params_after_user_value_change()
    --------------------------------------------------------
    -- Alcuni plugin, quando un parametro cambia valore,
    -- riportano il focus sulla loro GUI o sulla chain FX.
    -- In quel caso la finestra gfx perde tastiera: lo script
    -- sembra uscito, ma resta vivo in background.
    --
    -- Questa funzione viene chiamata solo dopo un cambio valore
    -- comandato dall'utente, non durante le scansioni interne
    -- dei combo e non nel background CC.
    --------------------------------------------------------
    if background_focus_mode == true then
        return false
    end

    if type(gfx) ~= "table" or type(gfx.init) ~= "function" then
        return false
    end

    local function grab()
        local t = title or ""

        if t == "" and type(build_window_title) == "function" then
            build_window_title()
            t = title or ""
        end

        if t == "" then
            t = "FX Parameters"
        end

        pcall(gfx.init, t, 1, 1, 0, -32000, -32000)
    end

    grab()

    if type(reaper) == "table" and type(reaper.defer) == "function" then
        reaper.defer(function()
            if background_focus_mode ~= true then
                grab()
            end
        end)
    end

    return true
end

function value_apply(new_v, old_v)
    if not param_index_is_valid(param_index) then
        speak("No parameter")
        return
    end

    old_v = clamp01(old_v)
    new_v = clamp01(new_v)

    if math.abs(new_v - old_v) <= 0.0000001 then
        return
    end

    local old_fmt = clean_one_line(
        get_param_value_formatted(param_index)
    )

    disarm_slot_deletes()
    clear_param_memory_arm()

    set_param_value_norm(param_index, new_v)
    save_current_param_position()

    if type(refocus_fx_params_after_user_value_change) == "function" then
        refocus_fx_params_after_user_value_change()
    end

    if current_fx_is_lexicon_like and
       current_fx_is_lexicon_like() and
       type(speak_param_value_after_plugin_set) == "function" then

        speak_param_value_after_plugin_set("", old_fmt)
        return
    end

    if type(announce_value_only_if_changed) == "function" then
        announce_value_only_if_changed(old_fmt)
    else
        announce_value_only()
    end
end

------------------------------------------------------------
-- 4.12 - COMBO / PARAMETRI DISCRETI
------------------------------------------------------------
function param_binary_raw_range_is_01(i)
    i = tonumber(i)

    if i == nil then
        return false
    end

    local _, minval, maxval = get_param_raw(i)
    minval = tonumber(minval) or 0
    maxval = tonumber(maxval) or 1

    return
        math.abs(minval - 0) <= 0.0000001 and
        math.abs(maxval - 1) <= 0.0000001
end

function binary_label_looks_numeric(txt)
    txt = clean_one_line(txt or "")

    if txt == "" then
        return true
    end

    --------------------------------------------------------
    -- Numeri puri, percentuali e valori con unità comuni:
    -- questi sono slider continui, non combo testuali.
    --------------------------------------------------------
    local lower = txt:lower()

    lower = lower:gsub("%%", "")
    lower = lower:gsub("db", "")
    lower = lower:gsub("hz", "")
    lower = lower:gsub("khz", "")
    lower = lower:gsub("ms", "")
    lower = lower:gsub("sec", "")
    lower = lower:gsub("s", "")
    lower = lower:gsub("x", "")
    lower = trim(lower)

    return lower:match("^[%+%-]?%d+[%.%,]?%d*$") ~= nil
end

function fx_label_lower_for_current_fx()
    local label = ""

    if type(get_fx_raw_label) == "function" then
        label = get_fx_raw_label() or ""
    elseif selected_fx_label and selected_fx_label ~= "" then
        label = selected_fx_label
    end

    return clean_one_line(label):lower()
end

function current_fx_is_lexicon_like()
    local label = ""

    if type(fx_label_lower_for_current_fx) == "function" then
        label = fx_label_lower_for_current_fx()
    end

    --------------------------------------------------------
    -- Alcuni installer Lexicon mostrano il nome in forme
    -- diverse: "(Lexicon)", "PCM Native...", "LXP...".
    -- Teniamo il riconoscimento volutamente stretto: PCM e LXP
    -- valgono solo insieme a parole tipiche della suite Lexicon.
    --------------------------------------------------------
    if label:find("lexicon", 1, true) ~= nil then
        return true
    end

    if label:find("pcm native", 1, true) ~= nil then
        return true
    end

    if label:find("lxp", 1, true) ~= nil and
       (label:find("reverb", 1, true) ~= nil or
        label:find("delay", 1, true) ~= nil or
        label:find("chorus", 1, true) ~= nil) then

        return true
    end

    return false
end

function fx_text_combo_allow_numeric_labels(i)
    --------------------------------------------------------
    -- Alcuni Lexicon espongono parametri a scatti con label
    -- numeriche formattate, per esempio "Predelay 375.00 ms".
    -- Non sono veri slider continui per la navigazione da
    -- tastiera: vanno trattati come combo/step mascherati.
    --------------------------------------------------------
    if current_fx_is_lexicon_like and current_fx_is_lexicon_like() then
        return true
    end

    return false
end

function speak_param_value_after_plugin_set(expected_label, before_fmt)
    expected_label = clean_one_line(expected_label or "")
    before_fmt = clean_one_line(before_fmt or "")

    local serial = speak_serial + 1
    speak_serial = serial

    local tries = 0
    local max_tries = 8

    local function later()
        if serial ~= speak_serial then
            return
        end

        tries = tries + 1

        local now_fmt = clean_one_line(
            get_param_value_formatted(param_index)
        )

        ----------------------------------------------------
        -- Alcuni Lexicon aggiornano la stringa formattata
        -- con uno o più defer di ritardo. Prima aspettiamo
        -- davvero una label nuova; se non arriva, parliamo
        -- l'etichetta prevista o l'ultimo valore leggibile.
        ----------------------------------------------------
        if now_fmt ~= "" and now_fmt ~= before_fmt then
            speak(now_fmt)
            return
        end

        if tries < max_tries then
            reaper.defer(later)
            return
        end

        if expected_label ~= "" then
            speak(expected_label)
            return
        end

        if now_fmt ~= "" then
            speak(now_fmt)
            return
        end
    end

    reaper.defer(later)
end


function lexicon_label_at_norm_for_scan(i, norm)
    i = tonumber(i)

    if i == nil then
        return ""
    end

    norm = clamp01(norm)

    if type(get_param_value_formatted_at_norm) == "function" then
        local label = clean_one_line(
            get_param_value_formatted_at_norm(i, norm)
        )

        if label ~= "" then
            return label
        end
    end

    return ""
end

function lexicon_find_next_label_segment(direction, from_v, from_fmt, scan_steps)
    if not param_index_is_valid(param_index) then
        return nil
    end

    direction = tonumber(direction) or 0

    if direction == 0 then
        return nil
    end

    scan_steps = tonumber(scan_steps) or 4096

    if scan_steps < 512 then
        scan_steps = 512
    end

    from_v = clamp01(from_v)
    from_fmt = clean_one_line(from_fmt or "")

    if from_fmt == "" then
        from_fmt = clean_one_line(get_param_value_formatted(param_index))
    end

    local base_i = clamp_int(from_v * scan_steps, 0, scan_steps)
    local start_i, end_i, step_i

    if direction > 0 then
        start_i = base_i + 1
        end_i = scan_steps
        step_i = 1
    else
        start_i = base_i - 1
        end_i = 0
        step_i = -1
    end

    local found_start = nil
    local found_end = nil
    local found_label = ""
    local i = start_i

    while (direction > 0 and i <= end_i) or
          (direction < 0 and i >= end_i) do

        local norm = clamp01(i / scan_steps)
        local label = lexicon_label_at_norm_for_scan(param_index, norm)

        if label == "" then
            local old_speech = speech_suspended
            speech_suspended = true
            set_param_value_norm(param_index, norm)
            label = clean_one_line(get_param_value_formatted(param_index))
            speech_suspended = old_speech
        end

        if label ~= "" and label ~= from_fmt then
            found_start = i
            found_label = label
            found_end = i
            break
        end

        i = i + step_i
    end

    if found_start == nil then
        return nil
    end

    i = found_start + step_i

    while (direction > 0 and i <= end_i) or
          (direction < 0 and i >= end_i) do

        local norm = clamp01(i / scan_steps)
        local label = lexicon_label_at_norm_for_scan(param_index, norm)

        if label == "" then
            local old_speech = speech_suspended
            speech_suspended = true
            set_param_value_norm(param_index, norm)
            label = clean_one_line(get_param_value_formatted(param_index))
            speech_suspended = old_speech
        end

        if label ~= found_label then
            break
        end

        found_end = i
        i = i + step_i
    end

    local target_i = math.floor(((found_start + found_end) / 2) + 0.5)

    return {
        norm = clamp01(target_i / scan_steps),
        label = found_label,
        start_i = found_start,
        end_i = found_end,
        target_i = target_i
    }
end

function lexicon_nudge_until_label_changes(direction, big_step, base_v, base_fmt, expected_label)
    if not param_index_is_valid(param_index) then
        return false
    end

    if not current_fx_is_lexicon_like or
       not current_fx_is_lexicon_like() then

        return false
    end

    direction = tonumber(direction) or 0

    if direction == 0 then
        return false
    end

    base_v = clamp01(base_v or get_param_value_norm(param_index))
    base_fmt = clean_one_line(base_fmt or get_param_value_formatted(param_index))
    expected_label = clean_one_line(expected_label or "")

    local steps_to_move = big_step and get_discrete_step_amount(true) or 1
    steps_to_move = clamp_int(steps_to_move, 1, 64)

    local scan_steps = 4096
    local current_v = base_v
    local current_fmt = base_fmt
    local moved = false
    local target_label = expected_label

    for _ = 1, steps_to_move do
        local seg = lexicon_find_next_label_segment(
            direction,
            current_v,
            current_fmt,
            scan_steps
        )

        if not seg then
            break
        end

        current_v = clamp01(seg.norm)
        current_fmt = clean_one_line(seg.label or current_fmt)
        target_label = current_fmt
        moved = true
    end

    if not moved then
        ----------------------------------------------------
        -- Non bloccare Alt+Freccia se la scansione Lexicon
        -- non trova una label diversa. Nella 0.315 qui
        -- tornavamo true: il chiamante pensava che il valore
        -- fosse stato gestito e non arrivava più al fallback
        -- normale/direct. Risultato: frecce bloccate, mentre
        -- Home/End continuavano a funzionare.
        ----------------------------------------------------
        set_param_value_norm(param_index, base_v)
        return false
    end

    disarm_slot_deletes()
    clear_param_memory_arm()

    set_param_value_norm(param_index, current_v)
    save_current_param_position()

    if type(clear_silent_edge) == "function" then
        clear_silent_edge()
    end

    if type(refocus_fx_params_after_user_value_change) == "function" then
        refocus_fx_params_after_user_value_change()
    end

    cancel_pending_speech()

    if target_label ~= "" then
        speak(target_label)
    elseif type(speak_param_value_after_plugin_set) == "function" then
        speak_param_value_after_plugin_set("", base_fmt)
    else
        announce_value_only()
    end

    return true
end

binary_text_label_cache = binary_text_label_cache or {}

function param_binary_text_label_cache_key(i)
    local ctx = ""

    if type(current_context_key) == "function" then
        ctx = current_context_key() or ""
    end

    return tostring(ctx or "") .. ":" .. tostring(fx_index or "") .. ":" .. tostring(i or "")
end

function param_binary_has_distinct_text_labels(i)
    if not param_binary_raw_range_is_01(i) then
        return false
    end

    local cache_key = param_binary_text_label_cache_key(i)
    local cached = binary_text_label_cache[cache_key]

    if cached ~= nil then
        return cached == true
    end

    if type(get_param_value_formatted_at_norm) ~= "function" then
        binary_text_label_cache[cache_key] = false
        return false
    end

    local label0 = clean_one_line(get_param_value_formatted_at_norm(i, 0))
    local label1 = clean_one_line(get_param_value_formatted_at_norm(i, 1))

    if label0 == "" or label1 == "" or label0 == label1 then
        binary_text_label_cache[cache_key] = false
        return false
    end

    --------------------------------------------------------
    -- Importante:
    -- il vecchio fix binario guardava solo le due estremità
    -- 0 e 1. Però molti combo con più di due posizioni hanno
    -- comunque una label diversa a 0 e a 1; in quel caso non
    -- sono pulsanti binari, sono combo multipli. Se li trattiamo
    -- come binari, Alt+Up/Down saltano direttamente a primo/ultimo
    -- valore, cioè il comportamento di Alt+Home/Alt+End.
    --
    -- Qui quindi campioniamo il parametro e accettiamo il percorso
    -- diretto solo se le label testuali distinte sono esattamente 2.
    --------------------------------------------------------
    local labels = {}
    local count = 0

    for n = 0, 16 do
        local norm = n / 16
        local label = clean_one_line(
            get_param_value_formatted_at_norm(i, norm)
        )

        if label ~= "" then
            if labels[label] ~= true then
                labels[label] = true
                count = count + 1

                if count > 2 then
                    binary_text_label_cache[cache_key] = false
                    return false
                end
            end
        end
    end

    if count ~= 2 then
        binary_text_label_cache[cache_key] = false
        return false
    end

    --------------------------------------------------------
    -- La protezione importante: entra solo quando le due
    -- estremità sono vere parole/etichette, non numeri.
    -- Così non trasformiamo slider continui 0..1 in toggle.
    --------------------------------------------------------
    if binary_label_looks_numeric(label0) and
       binary_label_looks_numeric(label1) then

        binary_text_label_cache[cache_key] = false
        return false
    end

    binary_text_label_cache[cache_key] = true
    return true
end

function param_is_binary_discrete_candidate(i, is_stepped, suspicious_step)
    if not param_binary_raw_range_is_01(i) then
        return false
    end

    --------------------------------------------------------
    -- Non basta che REAPER dica stepped/suspicious.
    -- Molti combo multipli sono stepped 0..1, ma non sono
    -- binari. Il percorso diretto primo/ultimo va usato solo
    -- quando la scansione conferma davvero due sole label.
    --------------------------------------------------------
    return param_binary_has_distinct_text_labels(i)
end

function binary_discrete_target_label(i, target_v)
    i = tonumber(i)
    target_v = clamp01(target_v)

    if i == nil then
        return ""
    end

    local msg = ""

    if type(get_param_value_formatted_at_norm) == "function" then
        msg = clean_one_line(
            get_param_value_formatted_at_norm(i, target_v)
        )
    end

    if msg ~= "" then
        return msg
    end

    msg = clean_one_line(get_param_value_formatted(i))

    if msg ~= "" then
        return msg
    end

    return target_v >= 0.5 and "On" or "Off"
end

function value_set_binary_discrete_direct(target_v, force_speak)
    if not param_index_is_valid(param_index) then
        return false
    end

    target_v = clamp01(target_v)
    target_v = target_v >= 0.5 and 1 or 0
    force_speak = force_speak == true

    local old_v = get_param_value_norm(param_index)

    if not force_speak and
       math.abs(old_v - target_v) <= 0.0000001 then

        if type(value_edge_silent) == "function" then
            return value_edge_silent(
                target_v >= 0.5 and "fx-binary-on" or "fx-binary-off"
            )
        end

        return true
    end

    --------------------------------------------------------
    -- Fondamentale per i pulsanti momentanei JSFX:
    -- prendiamo la label di destinazione PRIMA del set,
    -- perché dopo il set il plugin può rimettersi subito a 0.
    --------------------------------------------------------
    local msg = binary_discrete_target_label(param_index, target_v)

    disarm_slot_deletes()
    clear_param_memory_arm()

    set_param_value_norm(param_index, target_v)
    save_current_param_position()

    if type(clear_silent_edge) == "function" then
        clear_silent_edge()
    end

    if type(refocus_fx_params_after_user_value_change) == "function" then
        refocus_fx_params_after_user_value_change()
    end

    if msg == "" then
        msg = target_v == 1 and "On" or "Off"
    end

    cancel_pending_speech()
    speak(msg)

    return true
end

function value_nudge_binary_discrete_direct(direction)
    direction = tonumber(direction) or 0

    if direction == 0 then
        return false
    end

    return value_set_binary_discrete_direct(
        direction > 0 and 1 or 0,
        false
    )
end


------------------------------------------------------------
-- JSFX integer/raw combo nudge
--
-- I JSFX espongono spesso slider combo come valori raw interi
-- reali, per esempio 2, 3, 4, 5, 6. Su questi parametri il
-- percorso normalizzato può restare sullo stesso stato quando
-- si prova a tornare indietro. Qui quindi, solo per JSFX con
-- range intero ragionevole, muoviamo direttamente il valore raw.
------------------------------------------------------------
function current_fx_is_jsfx()
    local name = ""

    if type(get_fx_raw_label) == "function" then
        name = get_fx_raw_label() or ""
    end

    name = clean_one_line(name or ""):lower()

    return name:match("^js:%s*") ~= nil or
           name:match("^jsfx%s*:%s*") ~= nil
end

function value_nudge_jsfx_raw_integer_combo_direct(direction, big_step)
    if not param_index_is_valid(param_index) then
        return false
    end

    if not current_fx_is_jsfx or not current_fx_is_jsfx() then
        return false
    end

    direction = tonumber(direction) or 0

    if direction == 0 then
        return false
    end

    local value, minval, maxval = get_param_raw(param_index)

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

    --------------------------------------------------------
    -- Protezioni anti-slider continuo:
    -- - range non enorme;
    -- - estremi e valore corrente molto vicini a interi.
    --------------------------------------------------------
    if (max_i - min_i) > 8192 then
        return false
    end

    if math.abs(minval - min_i) > 0.000001 or
       math.abs(maxval - max_i) > 0.000001 or
       math.abs(value - current_i) > 0.000001 then

        return false
    end

    current_i = clamp_int(current_i, min_i, max_i)

    local amount = big_step and get_discrete_step_amount(true) or 1

    amount = clamp_int(amount, 1, 8192)

    local target_i = clamp_int(
        current_i + (amount * direction),
        min_i,
        max_i
    )

    if target_i == current_i then
        if type(value_edge_silent) == "function" then
            value_edge_silent(
                direction > 0 and
                ("fx-jsfx-raw-max:" .. tostring(param_index or "")) or
                ("fx-jsfx-raw-min:" .. tostring(param_index or ""))
            )
        end

        return true
    end

    local target_norm = 0

    if max_i ~= min_i then
        target_norm = clamp01((target_i - min_i) / (max_i - min_i))
    end

    local target_label = ""

    if type(get_param_value_formatted_at_norm) == "function" then
        target_label = clean_one_line(
            get_param_value_formatted_at_norm(param_index, target_norm)
        )
    end

    disarm_slot_deletes()
    clear_param_memory_arm()

    set_param_value_raw(param_index, target_i)
    save_current_param_position()

    if type(clear_silent_edge) == "function" then
        clear_silent_edge()
    end

    if type(refocus_fx_params_after_user_value_change) == "function" then
        refocus_fx_params_after_user_value_change()
    end

    local spoken = clean_one_line(get_param_value_formatted(param_index))

    if spoken == "" then
        spoken = target_label
    end

    if spoken == "" then
        spoken = tostring(target_i)
    end

    cancel_pending_speech()
    speak(spoken)

    return true
end


------------------------------------------------------------
-- FX text combo fast map cache
--
-- Come in Track Param F4: per i combo testuali multipli
-- costruiamo una mappa usando FormatParamValueNormalized.
-- Questo evita di muovere il parametro reale durante ogni
-- scansione e rende le frecce molto più veloci dopo la prima
-- lettura. I binari veri restano gestiti dalla logica speciale
-- sopra, per non rompere i pulsanti momentanei.
------------------------------------------------------------
fx_text_combo_map_cache = fx_text_combo_map_cache or {}

function fx_text_combo_map_cache_key(i)
    local ctx_key = ""

    if type(current_context_key) == "function" then
        ctx_key = current_context_key() or ""
    end

    return tostring(ctx_key or "") .. ":" ..
           tostring(fx_index or "") .. ":" ..
           tostring(i or "")
end

function fx_text_combo_map_build(i)
    i = tonumber(i)

    if i == nil or not param_index_is_valid(i) then
        return nil
    end

    --------------------------------------------------------
    -- Non usare la mappa sui binari speciali. Quelli hanno
    -- bisogno del percorso diretto, perché alcuni JSFX/plugin
    -- possono tornare subito a 0 dopo il set.
    --------------------------------------------------------
    if type(param_binary_has_distinct_text_labels) == "function" and
       param_binary_has_distinct_text_labels(i) then
        return nil
    end

    if type(get_param_value_formatted_at_norm) ~= "function" then
        return nil
    end

    local cache_key = fx_text_combo_map_cache_key(i)
    local cached = fx_text_combo_map_cache[cache_key]

    if cached ~= nil then
        if cached == false then
            return nil
        end

        return cached
    end

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

    for step_i = 0, scan_steps do
        local label = clean_one_line(
            get_param_value_formatted_at_norm(i, step_i / scan_steps)
        )

        if label == "" then
            label = last_label or ""
        end

        if step_i == 0 then
            last_label = label
            last_start_i = 0

            if label ~= "" and not binary_label_looks_numeric(label) then
                text_label_count = text_label_count + 1
            end

        elseif label ~= last_label then
            add_segment(last_label, last_start_i, step_i - 1)

            if label ~= "" and not binary_label_looks_numeric(label) then
                text_label_count = text_label_count + 1
            end

            if #items > 256 then
                too_many = true
                break
            end

            last_label = label
            last_start_i = step_i
        end
    end

    if not too_many then
        add_segment(last_label, last_start_i, scan_steps)
    end

    --------------------------------------------------------
    -- Non usarla per slider numerici o per due sole label.
    -- Due label restano al percorso binario o al fallback.
    --------------------------------------------------------
    local allow_numeric_labels = false

    if type(fx_text_combo_allow_numeric_labels) == "function" then
        allow_numeric_labels = fx_text_combo_allow_numeric_labels(i) == true
    end

    local min_items_for_map = 3

    if current_fx_is_lexicon_like and current_fx_is_lexicon_like() then
        ----------------------------------------------------
        -- Lexicon: anche molti parametri con due sole scelte
        -- non si comportano bene nel percorso binario/direct.
        -- Li trattiamo come mini-combo mappati, così
        -- Alt+Up/Down fa sempre uno scatto intero e non resta
        -- dentro la stessa regione normalizzata.
        ----------------------------------------------------
        min_items_for_map = 2
    end

    if too_many or #items < min_items_for_map or
       (text_label_count <= 0 and not allow_numeric_labels) then

        fx_text_combo_map_cache[cache_key] = false
        return nil
    end

    local map = {
        scan_steps = scan_steps,
        items = items
    }

    fx_text_combo_map_cache[cache_key] = map

    return map
end

function fx_text_combo_map_find_index(map, base_v, base_fmt)
    if not map or not map.items then
        return 0
    end

    base_v = clamp01(base_v)
    base_fmt = clean_one_line(base_fmt or "")

    local items = map.items
    local scan_steps = tonumber(map.scan_steps) or 512
    local base_i = clamp_int(base_v * scan_steps, 0, scan_steps)
    local best_i = 0
    local best_distance = 1000000000

    for idx = 1, #items do
        local it = items[idx]

        if it and base_fmt ~= "" and
           clean_one_line(it.label or "") == base_fmt then

            local center_i = tonumber(it.center_i) or 0
            local d = math.abs(center_i - base_i)

            if d < best_distance then
                best_i = idx
                best_distance = d
            end
        end
    end

    if best_i > 0 then
        return best_i
    end

    for idx = 1, #items do
        local it = items[idx]

        if it and
           base_i >= (tonumber(it.start_i) or 0) and
           base_i <= (tonumber(it.end_i) or 0) then

            return idx
        end
    end

    return 0
end

function value_nudge_text_combo_cached(direction, big_step)
    if not param_index_is_valid(param_index) then
        return false
    end

    direction = tonumber(direction) or 0

    if direction == 0 then
        return false
    end

    local base_v = get_param_value_norm(param_index)

    if base_v == nil then
        return false
    end

    local base_fmt = clean_one_line(get_param_value_formatted(param_index))

    if base_fmt == "" then
        return false
    end

    local map = fx_text_combo_map_build(param_index)

    local min_items_for_nudge = 3

    --------------------------------------------------------
    -- Lexicon / PCM / LXP:
    -- alcuni controlli sono combo mascherati da slider e possono
    -- avere solo due aree testuali, ma non essere esposti come
    -- raw 0/1. In quel caso usiamo comunque la mappa a segmenti,
    -- come fa F4 in Track Params quando trova il prossimo cambio.
    --------------------------------------------------------
    if current_fx_is_lexicon_like and current_fx_is_lexicon_like() then
        min_items_for_nudge = 2
    end

    if not map or not map.items or #map.items < min_items_for_nudge then
        return false
    end

    local current_i = fx_text_combo_map_find_index(map, base_v, base_fmt)

    if current_i <= 0 then
        return false
    end

    local amount = big_step and get_discrete_step_amount(true) or 1

    if amount < 1 then
        amount = 1
    end

    local target_i = clamp_int(
        current_i + (amount * direction),
        1,
        #map.items
    )

    if target_i == current_i then
        if type(value_edge_silent) == "function" then
            value_edge_silent(
                direction > 0 and
                ("fx-combo-cache-max:" .. fx_text_combo_map_cache_key(param_index)) or
                ("fx-combo-cache-min:" .. fx_text_combo_map_cache_key(param_index))
            )
        end

        return true
    end

    local target = map.items[target_i]

    if not target then
        return false
    end

    local norm = clamp01(
        (tonumber(target.center_i) or 0) /
        (tonumber(map.scan_steps) or 512)
    )

    local target_label = clean_one_line(target.label or "")

    disarm_slot_deletes()
    clear_param_memory_arm()

    set_param_value_norm(param_index, norm)
    save_current_param_position()

    if type(clear_silent_edge) == "function" then
        clear_silent_edge()
    end

    if type(refocus_fx_params_after_user_value_change) == "function" then
        refocus_fx_params_after_user_value_change()
    end

    cancel_pending_speech()
    speak(target_label)

    return true
end

function find_next_distinct_value_linear(direction, base_v, base_fmt, fine_scan)
    if not param_index_is_valid(param_index) then
        return false
    end

    direction = tonumber(direction) or 0

    if direction == 0 then
        return false
    end

    local scan_steps = tonumber(fine_scan) or 4096

    if scan_steps < 128 then
        scan_steps = 128
    end

    base_v = clamp01(base_v)
    base_fmt = tostring(base_fmt or "")

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
            set_param_value_norm(param_index, try_v)

            local try_fmt = get_param_value_formatted(param_index)

            if try_fmt ~= base_fmt then
                return true
            end
        end

        i = i + step_i
    end

    set_param_value_norm(param_index, base_v)

    return false
end

function find_next_distinct_value(direction, base_v, base_fmt, fine_scan)
    if not param_index_is_valid(param_index) then
        return false
    end

    direction = tonumber(direction) or 0

    if direction == 0 then
        return false
    end

    local scan_steps = tonumber(fine_scan) or 4096

    if scan_steps < 128 then
        scan_steps = 128
    end

    base_v = clamp01(base_v)
    base_fmt = tostring(base_fmt or "")

    --------------------------------------------------------
    -- Combo sparsi / label lontane:
    -- prima il vecchio metodo avanzava di 1/4096 per volta.
    -- Su plugin con pochi stati distribuiti lontani questo poteva
    -- produrre latenza. Ora saltiamo con ricerca esponenziale fino
    -- alla prossima label diversa, poi rifiniamo il bordo con una
    -- piccola ricerca binaria. Se qualcosa non torna, c'è il vecchio
    -- scan lineare come fallback sicuro.
    --------------------------------------------------------

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

        local try_v = clamp01(probe_i / scan_steps)
        set_param_value_norm(param_index, try_v)

        local try_fmt = get_param_value_formatted(param_index)

        if try_fmt ~= base_fmt then
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
        set_param_value_norm(param_index, base_v)
        return false
    end

    local low_i
    local high_i

    if direction > 0 then
        low_i = last_same_i
        high_i = found_i

        while (high_i - low_i) > 1 do
            local mid_i = math.floor((low_i + high_i) / 2)
            local try_v = clamp01(mid_i / scan_steps)

            set_param_value_norm(param_index, try_v)

            local try_fmt = get_param_value_formatted(param_index)

            if try_fmt ~= base_fmt then
                high_i = mid_i
            else
                low_i = mid_i
            end
        end

        set_param_value_norm(param_index, clamp01(high_i / scan_steps))

    else
        low_i = found_i
        high_i = last_same_i

        while (high_i - low_i) > 1 do
            local mid_i = math.floor((low_i + high_i) / 2)
            local try_v = clamp01(mid_i / scan_steps)

            set_param_value_norm(param_index, try_v)

            local try_fmt = get_param_value_formatted(param_index)

            if try_fmt ~= base_fmt then
                low_i = mid_i
            else
                high_i = mid_i
            end
        end

        set_param_value_norm(param_index, clamp01(low_i / scan_steps))
    end

    local final_fmt = get_param_value_formatted(param_index)

    if final_fmt ~= base_fmt then
        return true
    end

    --------------------------------------------------------
    -- Fallback: se un plugin ha label non monotone o strane,
    -- ripristina la ricerca vecchia invece di rischiare salti.
    --------------------------------------------------------
    set_param_value_norm(param_index, base_v)

    return find_next_distinct_value_linear(
        direction,
        base_v,
        base_fmt,
        fine_scan
    )
end

function lexicon_force_value_nudge_direct(direction, big_step)
    if not param_index_is_valid(param_index) then
        return false
    end

    if not current_fx_is_lexicon_like or
       not current_fx_is_lexicon_like() then

        return false
    end

    direction = tonumber(direction) or 0

    if direction == 0 then
        return false
    end

    local old_v = get_param_value_norm(param_index)
    local before_fmt = clean_one_line(get_param_value_formatted(param_index))

    local arrow_step, page_step, is_toggle, is_stepped, suspicious_step =
        get_param_steps(param_index)

    if is_toggle then
        return false
    end

    --------------------------------------------------------
    -- Prima strada Lexicon: raw intero reale.
    -- Molti combo mascherati da slider hanno un valore raw
    -- intero anche quando la label sembra testo o numero con
    -- unità. In quel caso muoviamo l'indice, non un pezzetto
    -- normalizzato: Alt+freccia va sempre all'elemento dopo.
    --------------------------------------------------------
    local raw, minval, maxval = get_param_raw(param_index)

    raw = tonumber(raw)
    minval = tonumber(minval)
    maxval = tonumber(maxval)

    if raw ~= nil and minval ~= nil and maxval ~= nil then
        if maxval < minval then
            minval, maxval = maxval, minval
        end

        local min_i = math.floor(minval + 0.5)
        local max_i = math.floor(maxval + 0.5)
        local raw_i = math.floor(raw + 0.5)

        local raw_is_integer =
            math.abs(minval - min_i) <= 0.000001 and
            math.abs(maxval - max_i) <= 0.000001 and
            math.abs(raw - raw_i) <= 0.000001

        local raw_range = max_i - min_i

        if raw_is_integer and raw_range > 0 and raw_range <= 4096 and
           (is_stepped or suspicious_step or raw_range > 1) then

            local raw_step = big_step and get_discrete_step_amount(true) or 1
            raw_step = clamp_int(raw_step, 1, 4096)

            local target_raw = clamp_int(
                raw_i + (raw_step * direction),
                min_i,
                max_i
            )

            if target_raw == raw_i then
                if type(value_edge_silent) == "function" then
                    value_edge_silent(
                        direction > 0 and
                        ("fx-lexicon-raw-max:" .. tostring(param_index or "")) or
                        ("fx-lexicon-raw-min:" .. tostring(param_index or ""))
                    )
                end

                return true
            end

            local target_label = ""

            if type(get_param_value_formatted_at_norm) == "function" then
                local target_norm = clamp01((target_raw - min_i) / raw_range)
                target_label = clean_one_line(
                    get_param_value_formatted_at_norm(param_index, target_norm)
                )
            end

            disarm_slot_deletes()
            clear_param_memory_arm()

            set_param_value_raw(param_index, target_raw)
            save_current_param_position()

            if type(clear_silent_edge) == "function" then
                clear_silent_edge()
            end

            if type(refocus_fx_params_after_user_value_change) == "function" then
                refocus_fx_params_after_user_value_change()
            end

            cancel_pending_speech()

            if target_label ~= "" then
                speak(target_label)
            elseif type(speak_param_value_after_plugin_set) == "function" then
                speak_param_value_after_plugin_set("", before_fmt)
            else
                announce_value_only()
            end

            return true
        end
    end

    local step = big_step and page_step or arrow_step
    step = tonumber(step) or 0

    --------------------------------------------------------
    -- Se l'API non fornisce step credibili, non passiamo
    -- dalla scansione delle label: su Lexicon può leggere
    -- etichette stantie. Usiamo un movimento normalizzato
    -- controllato e parliamo dopo il ritardo.
    --------------------------------------------------------
    if step <= 0 or step >= 1 then
        step = big_step and 0.08 or 0.01
    end

    if type(lexicon_nudge_until_label_changes) == "function" and
       lexicon_nudge_until_label_changes(
            direction,
            big_step == true,
            old_v,
            before_fmt,
            ""
       ) then

        return true
    end

    local new_v = clamp01(old_v + (step * direction))

    if math.abs(new_v - old_v) <= 0.0000001 then
        if type(value_edge_silent) == "function" then
            value_edge_silent(
                direction > 0 and
                ("fx-lexicon-max:" .. tostring(param_index or "")) or
                ("fx-lexicon-min:" .. tostring(param_index or ""))
            )
        end

        return true
    end

    disarm_slot_deletes()
    clear_param_memory_arm()

    set_param_value_norm(param_index, new_v)

    --------------------------------------------------------
    -- Alcuni parametri Lexicon sono raw interi mascherati.
    -- Se il set normalizzato non ha spostato davvero il valore,
    -- proviamo un passo raw intero sicuro.
    --------------------------------------------------------
    local after_v = get_param_value_norm(param_index)

    if math.abs(after_v - old_v) <= 0.0000001 then
        local raw, minval, maxval = get_param_raw(param_index)

        raw = tonumber(raw)
        minval = tonumber(minval)
        maxval = tonumber(maxval)

        if raw ~= nil and minval ~= nil and maxval ~= nil then
            if maxval < minval then
                minval, maxval = maxval, minval
            end

            local min_i = math.floor(minval + 0.5)
            local max_i = math.floor(maxval + 0.5)
            local raw_i = math.floor(raw + 0.5)

            if (max_i > min_i) and
               ((max_i - min_i) <= 4096) and
               math.abs(minval - min_i) <= 0.000001 and
               math.abs(maxval - max_i) <= 0.000001 and
               math.abs(raw - raw_i) <= 0.000001 then

                local raw_step = big_step and get_discrete_step_amount(true) or 1
                raw_step = clamp_int(raw_step, 1, 4096)

                set_param_value_raw(
                    param_index,
                    clamp_int(raw_i + (raw_step * direction), min_i, max_i)
                )
            end
        end
    end

    save_current_param_position()

    if type(clear_silent_edge) == "function" then
        clear_silent_edge()
    end

    if type(refocus_fx_params_after_user_value_change) == "function" then
        refocus_fx_params_after_user_value_change()
    end

    if type(speak_param_value_after_plugin_set) == "function" then
        speak_param_value_after_plugin_set("", before_fmt)
    else
        announce_value_only()
    end

    return true
end

function lexicon_force_value_set_absolute_direct(v)
    if not param_index_is_valid(param_index) then
        return false
    end

    if not current_fx_is_lexicon_like or
       not current_fx_is_lexicon_like() then

        return false
    end

    local target_v = clamp01(v)
    local before_fmt = clean_one_line(get_param_value_formatted(param_index))
    local old_v = get_param_value_norm(param_index)

    if math.abs(target_v - old_v) <= 0.0000001 then
        if type(value_edge_silent) == "function" then
            value_edge_silent(
                target_v <= 0.0000001 and
                ("fx-lexicon-absolute-min:" .. tostring(param_index or "")) or
                ("fx-lexicon-absolute-max:" .. tostring(param_index or ""))
            )
        end

        return true
    end

    disarm_slot_deletes()
    clear_param_memory_arm()

    set_param_value_norm(param_index, target_v)
    save_current_param_position()

    if type(clear_silent_edge) == "function" then
        clear_silent_edge()
    end

    if type(refocus_fx_params_after_user_value_change) == "function" then
        refocus_fx_params_after_user_value_change()
    end

    if type(speak_param_value_after_plugin_set) == "function" then
        speak_param_value_after_plugin_set("", before_fmt)
    else
        announce_value_only()
    end

    return true
end

function value_nudge_discrete(direction, big_step)
    if not param_index_is_valid(param_index) then
        speak("No parameter")
        return false
    end

    if type(value_nudge_jsfx_raw_integer_combo_direct) == "function" and
       value_nudge_jsfx_raw_integer_combo_direct(direction, big_step == true) then

        return true
    end

    --------------------------------------------------------
    -- Percorso veloce per combo testuali multipli.
    -- Se non è disponibile o non è affidabile, torna sotto
    -- alla scansione classica.
    --------------------------------------------------------
    if type(value_nudge_text_combo_cached) == "function" and
       value_nudge_text_combo_cached(direction, big_step == true) then

        return true
    end

    local steps_to_move = get_discrete_step_amount(big_step)
    local moved = false

    local original_v = get_param_value_norm(param_index)
    local current_fmt = get_param_value_formatted(param_index)

    for _ = 1, steps_to_move do
        local before_v = get_param_value_norm(param_index)
        local before_fmt = get_param_value_formatted(param_index)

        local changed =
            find_next_distinct_value(direction, before_v, before_fmt, 4096)

        if changed then
            moved = true
            current_fmt = get_param_value_formatted(param_index)
        else
            set_param_value_norm(param_index, before_v)
            break
        end
    end

    if moved then
        disarm_slot_deletes()
        clear_param_memory_arm()

        save_current_param_position()

        if type(refocus_fx_params_after_user_value_change) == "function" then
            refocus_fx_params_after_user_value_change()
        end

        speak_later(current_fmt)
    else
        set_param_value_norm(param_index, original_v)
    end

    return moved
end



function reaeq_gain_nudge_db_direct(direction, big_step)
    if not reaeq_param_is_gain or
       not reaeq_param_is_gain(param_index) then

        return false
    end

    return reaeq_band_param_nudge_direct(direction, big_step)
end

function reaeq_gain_set_absolute_db_from_value(v)
    --------------------------------------------------------
    -- Solo Gain delle bande.
    -- Alt+Home/Home = -inf / minimo pratico.
    -- Alt+End/End = +36.1 dB, cioè il massimo numerico
    -- accettato da ReaEQ anche se la manopola grafica si
    -- ferma circa a +12 dB.
    -- Il Global Gain resta intatto.
    --------------------------------------------------------
    if not reaeq_param_is_gain or
       not reaeq_param_is_gain(param_index) then

        return false
    end

    v = clamp01(v)

    local target_db = 0

    if v <= 0 then
        target_db = REAEQ_GAIN_REAL_MIN_DB
    else
        target_db = REAEQ_GAIN_REAL_MAX_DB
    end

    if not reaeq_set_gain_db_by_feedback(param_index, target_db) then
        return false
    end

    disarm_slot_deletes()
    clear_param_memory_arm()
    save_current_param_position()
    announce_value_only()

    return true
end

function value_nudge(direction, big_step)
    if not param_index_is_valid(param_index) then
        speak("No parameter")
        return false
    end

    if fx_compare_param_is_valid and fx_compare_param_is_valid(param_index) then
        return fx_compare_nudge(direction)
    end

------------------------------------------------------------
-- ReaEQ Band Type:
-- gestione diretta 0..10.
-- Evita la scansione discreta generica, che può saltare
-- o confondere i raw interni scombinati di ReaEQ.
------------------------------------------------------------
if reaeq_virtual_param_is_valid and
   reaeq_virtual_param_is_valid(param_index) then

    local band_zero, kind = reaeq_decode_virtual_index(param_index)

    if kind == "type" then
        return reaeq_virtual_type_nudge(
            param_index,
            direction,
            big_step == true
        )
    end
end

    if reacomp_virtual_param_is_valid and
       reacomp_virtual_param_is_valid(param_index) then

        speak_later(get_param_value_formatted(param_index))
        return true
    end

    if reagate_virtual_param_is_valid and
       reagate_virtual_param_is_valid(param_index) then

        speak_later(get_param_value_formatted(param_index))
        return true
    end

    if reacomp_param_is_detector_input and
       reacomp_param_is_detector_input(param_index) then

        return reacomp_detector_nudge(
            param_index,
            direction,
            big_step == true
        )
    end

    if reagate_param_is_detector_input and
       reagate_param_is_detector_input(param_index) then

        return reagate_detector_nudge(
            param_index,
            direction,
            big_step == true
        )
    end

    direction = tonumber(direction) or 0

    if direction == 0 then
        return false
    end

    --------------------------------------------------------
    -- ReaEQ band real params:
    -- Frequency, Gain di banda e Bandwidth usano l'API ReaEQ.
    -- Il Global Gain resta escluso da reaeq_param_is_band_real().
    --------------------------------------------------------
    if reaeq_band_param_nudge_direct and
       reaeq_band_param_nudge_direct(direction, big_step == true) then

        return true
    end

    local old_v = get_param_value_norm(param_index)
    local old_fmt = get_param_value_formatted(param_index)

    local arrow_step, page_step, is_toggle, is_stepped, suspicious_step =
        get_param_steps(param_index)

    if not is_toggle and
       param_is_binary_discrete_candidate and
       param_is_binary_discrete_candidate(
            param_index,
            is_stepped,
            suspicious_step
       ) and
       value_nudge_binary_discrete_direct and
       value_nudge_binary_discrete_direct(direction) then

        return true
    end

    if is_toggle then
        local new_v = direction > 0 and 1 or 0

        value_apply(new_v, old_v)
        return true
    end

    if is_stepped or suspicious_step then
        value_nudge_discrete(direction, big_step)
        return true
    end

    local scale = get_step_scale()
    local step = big_step and page_step or arrow_step

    step = step * scale

    if step > 1 then
        step = 1
    end

    local new_v = clamp01(old_v + (step * direction))

    value_apply(new_v, old_v)

    local new_fmt = get_param_value_formatted(param_index)

    if new_fmt == old_fmt then
        value_nudge_discrete(direction, big_step)
    end

    return true
end


function reaeq_blocked_band_real_set_absolute_from_value(v)
    --------------------------------------------------------
    -- Home / End / Alt+Home / Alt+End fallback per i tre
    -- tipi ReaEQ problematici: All pass, Band alt, Band alt 2.
    -- Non passa dal valore normalizzato generico, perché dopo
    -- alcuni cambi di Type REAPER può leggere bene il parametro
    -- ma non applicare il salto minimo/massimo via API standard.
    --
    -- Frequency e Bandwidth vengono scritti nella stessa strada
    -- speciale che ha sbloccato frecce e Ctrl+E.
    -- Gain resta nella sua strada dB già esistente.
    --------------------------------------------------------
    if not param_index_is_valid(param_index) then
        return false
    end

    if not reaeq_param_api_write_is_blocked or
       not reaeq_param_api_write_is_blocked(param_index) then

        return false
    end

    v = clamp01(v)

    if reaeq_param_is_frequency and
       reaeq_param_is_frequency(param_index) then

        local hz = v <= 0 and 20 or 24000

        if not reaeq_set_frequency_hz_by_chunk(param_index, hz) then
            return false
        end

        disarm_slot_deletes()
        clear_param_memory_arm()
        save_current_param_position()
        announce_value_only()

        return true
    end

    if reaeq_param_is_bandwidth and
       reaeq_param_is_bandwidth(param_index) then

        local bw = v <= 0 and REAEQ_BANDWIDTH_REAL_MIN or REAEQ_BANDWIDTH_REAL_MAX

        if not reaeq_set_bandwidth_real_by_chunk_alt(param_index, bw) then
            return false
        end

        disarm_slot_deletes()
        clear_param_memory_arm()
        save_current_param_position()
        announce_value_only()

        return true
    end

    return false
end

function value_set_absolute_lexicon_label_map(v)
    if not param_index_is_valid(param_index) then
        return false
    end

    if not current_fx_is_lexicon_like or
       not current_fx_is_lexicon_like() then

        return false
    end

    if not fx_text_combo_map_build then
        return false
    end

    local map = fx_text_combo_map_build(param_index)

    if not map or not map.items or #map.items <= 0 then
        return false
    end

    local target_i = clamp01(v) <= 0.0000001 and 1 or #map.items
    local target = map.items[target_i]

    if not target then
        return false
    end

    local before_fmt = clean_one_line(get_param_value_formatted(param_index))
    local norm = clamp01(
        (tonumber(target.center_i) or 0) /
        (tonumber(map.scan_steps) or 512)
    )

    disarm_slot_deletes()
    clear_param_memory_arm()

    set_param_value_norm(param_index, norm)
    save_current_param_position()

    if type(refocus_fx_params_after_user_value_change) == "function" then
        refocus_fx_params_after_user_value_change()
    end

    if type(speak_param_value_after_plugin_set) == "function" then
        speak_param_value_after_plugin_set(
            clean_one_line(target.label or ""),
            before_fmt
        )
    else
        speak_later(clean_one_line(target.label or ""))
    end

    return true
end

function value_set_absolute(v)
    if not param_index_is_valid(param_index) then
        speak("No parameter")
        return false
    end

    if fx_compare_param_is_valid and fx_compare_param_is_valid(param_index) then
        fx_compare_set_norm(v)
        save_current_param_position()
        announce_value_only()
        return true
    end

    if current_fx_is_lexicon_like and
       current_fx_is_lexicon_like() then

        if value_set_absolute_lexicon_label_map and
           value_set_absolute_lexicon_label_map(v) then

            return true
        end

        if lexicon_force_value_set_absolute_direct and
           lexicon_force_value_set_absolute_direct(v) then

            return true
        end
    end

    --------------------------------------------------------
    -- ReaEQ Bandwidth su tutti i filtri:
    -- Home = 0.01, End = 4.0.
    -- Lo facciamo prima della gestione generica, così non
    -- passa mai dallo 0 normalizzato.
    --------------------------------------------------------
    if reaeq_bandwidth_set_absolute_limited and
       reaeq_bandwidth_set_absolute_limited(v) then

        return true
    end

    --------------------------------------------------------
    -- ReaEQ blocked band params:
    -- per i tre tipi All pass / Band alt / Band alt 2,
    -- Home/End devono usare la stessa strada speciale usata
    -- da frecce e Ctrl+E, altrimenti dopo un cambio Type il
    -- salto minimo/massimo può non muovere Frequency/Bandwidth.
    --------------------------------------------------------
    if reaeq_blocked_band_real_set_absolute_from_value and
       reaeq_blocked_band_real_set_absolute_from_value(v) then

        return true
    end

    --------------------------------------------------------
    -- ReaEQ Gain only:
    -- Alt+Home / Alt+End devono continuare a funzionare
    -- come prima per tutti i plugin. Qui correggiamo solo
    -- il caso ReaEQ Gain, perché dopo Ctrl+E il valore può
    -- vivere fuori dalla scala normale dello slider.
    --------------------------------------------------------
    if reaeq_gain_set_absolute_db_from_value and
       reaeq_gain_set_absolute_db_from_value(v) then

        return true
    end

    if reacomp_virtual_param_is_valid and
       reacomp_virtual_param_is_valid(param_index) then

        speak_later(get_param_value_formatted(param_index))
        return true
    end

    if reagate_virtual_param_is_valid and
       reagate_virtual_param_is_valid(param_index) then

        speak_later(get_param_value_formatted(param_index))
        return true
    end

    if reacomp_param_is_detector_input and
       reacomp_param_is_detector_input(param_index) then

        if clamp01(v) <= 0 then
            reacomp_set_detector_user_index(param_index, 1)
        else
            reacomp_set_detector_user_index(
                param_index,
                #REACOMP_DETECTOR_INPUT_VALUES
            )
        end

        disarm_slot_deletes()
        clear_param_memory_arm()
        save_current_param_position()
        announce_value_only()

        return true
    end

    if reagate_param_is_detector_input and
       reagate_param_is_detector_input(param_index) then

        if clamp01(v) <= 0 then
            reagate_set_detector_user_index(param_index, 1)
        else
            reagate_set_detector_user_index(
                param_index,
                #REACOMP_DETECTOR_INPUT_VALUES
            )
        end

        disarm_slot_deletes()
        clear_param_memory_arm()
        save_current_param_position()
        announce_value_only()

        return true
    end

    local arrow_step, page_step, is_toggle, is_stepped, suspicious_step =
        get_param_steps(param_index)

    if not is_toggle and
       param_is_binary_discrete_candidate and
       param_is_binary_discrete_candidate(
            param_index,
            is_stepped,
            suspicious_step
       ) and
       value_set_binary_discrete_direct and
       (clamp01(v) <= 0.0000001 or clamp01(v) >= 0.9999999) then

        return value_set_binary_discrete_direct(v, true)
    end

    local old_v = get_param_value_norm(param_index)

    value_apply(v, old_v)

    return true
end

function value_nudge_from_grid(direction, big_step)
    if not param_index_is_valid(param_index) then
        speak("No parameter")
        return false
    end

    disarm_slot_deletes()
    clear_param_memory_arm()

    value_nudge(direction, big_step == true)

    return true
end

function value_set_absolute_from_grid(v)
    if not param_index_is_valid(param_index) then
        speak("No parameter")
        return false
    end

    disarm_slot_deletes()
    clear_param_memory_arm()

    value_set_absolute(v)

    return true
end

------------------------------------------------------------
-- 4.12A - VALUE MODE
--
-- Ctrl+V:
--   entra/esce dalla modalità Value.
--
-- In Value mode:
--   Up / Down        = aumenta / diminuisce valore
--   Page Up / Down   = aumenta / diminuisce con step grande
--   Home             = valore minimo
--   End              = valore massimo
--   Tab / \          = legge parametro e valore
--   Enter            = torna alla griglia
--
-- Nota:
-- Ctrl+Shift+V resta dedicato al paste della Custom order.
------------------------------------------------------------

function announce_parameter_mode()
    if not param_index_is_valid(param_index) then
        speak("No parameter")
        return
    end

    local name = clean_one_line(get_param_display_name(param_index))
    local value = clean_one_line(get_param_value_formatted(param_index))

    if name == "" then
        name = "Parameter " .. tostring(param_index + 1)
    end

    if value ~= "" then
        speak("Value. " .. name .. " " .. value)
    else
        speak("Value. " .. name)
    end
end

function enter_value_mode()
    clear_param_memory_arm()
    disarm_slot_deletes()
    cancel_pending_speech()

    if mode == "fx_browser" then
        speak("No parameter")
        return false
    end

    if edit_mode or
       mode == "search_edit" or
       mode == "name_edit" or
       mode == "group_name_edit" or
       mode == "recent" or
       mode == "memory_manager" or
       mode == "cc_learn" then

        speak("Return to parameter grid first")
        return false
    end

    if not param_index_is_valid(param_index) then
        speak("No parameter")
        return false
    end

    value_return_mode = mode or "list"
    mode = "value"

    announce_parameter_mode()

    return true
end

function exit_value_mode()
    mode = value_return_mode or "list"
    value_return_mode = "list"

    announce_grid_context(nil)

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

    --------------------------------------------------------
    -- Alt+Freccia sinistra/destra:
    -- Step scale anche dentro Value mode.
    -- Così puoi cambiare la sensibilità mentre stai
    -- modificando il valore.
    --------------------------------------------------------
    if is_alt and not is_ctrl and not is_shift and char == KEY_LEFT then
        disarm_slot_deletes()
        clear_param_memory_arm()

        last_function_touched = "step"
        change_step_scale(-1)

        return true

    elseif is_alt and not is_ctrl and not is_shift and char == KEY_RIGHT then
        disarm_slot_deletes()
        clear_param_memory_arm()

        last_function_touched = "step"
        change_step_scale(1)

        return true
    end

    --------------------------------------------------------
    -- F1 / F2 restano liberi qui per la nuova mappa globale:
    -- fuori dal Value mode gestiscono la Grid size.
    --------------------------------------------------------

    --------------------------------------------------------
    -- Backspace funziona anche dentro Value mode.
    -- L'edit numerico resta escluso perché viene intercettato
    -- prima e usa Backspace per cancellare il carattere.
    --------------------------------------------------------
    if handle_backspace_reset_shortcut(char) then
        return true
    end

    --------------------------------------------------------
    -- Ctrl+E: apre l'edit numerico anche dal Value mode.
    -- Deve stare qui perché il Value mode intercetta i tasti
    -- prima del gestore globale della griglia.
    --------------------------------------------------------
    if is_ctrl and not is_shift and not is_alt and char == KEY_CTRL_E then
        enter_edit_from_anywhere()
        return true
    end

    --------------------------------------------------------
    -- Ctrl+V richiude la modalità Value.
    --------------------------------------------------------
    if is_ctrl and not is_shift and not is_alt and char == KEY_CTRL_V then
        exit_value_mode()
        return true
    end

    --------------------------------------------------------
    -- Enter torna alla griglia.
    --------------------------------------------------------
    if char == KEY_ENTER then
        exit_value_mode()
        return true
    end

    --------------------------------------------------------
    -- Tab / backslash: legge parametro e valore.
    --------------------------------------------------------
    if char == KEY_TAB or char == KEY_BACKSLASH then
        announce_parameter_mode()
        return true
    end

    --------------------------------------------------------
    -- Navigazione valore senza Alt.
    -- In Value mode, freccia sinistra/destra cambiano lo
    -- step scale come Alt+freccia sinistra/destra.
    --------------------------------------------------------
    if char == KEY_LEFT then
        disarm_slot_deletes()
        clear_param_memory_arm()

        last_function_touched = "step"
        change_step_scale(-1)

        return true

    elseif char == KEY_RIGHT then
        disarm_slot_deletes()
        clear_param_memory_arm()

        last_function_touched = "step"
        change_step_scale(1)

        return true

    elseif char == KEY_UP then
        value_nudge_from_grid(1, false)
        return true

    elseif char == KEY_DOWN then
        value_nudge_from_grid(-1, false)
        return true

    elseif char == KEY_PAGE_UP then
        value_nudge_from_grid(1, true)
        return true

    elseif char == KEY_PAGE_DOWN then
        value_nudge_from_grid(-1, true)
        return true

    elseif char == KEY_HOME then
        value_set_absolute_from_grid(0)
        return true

    elseif char == KEY_END then
        value_set_absolute_from_grid(1)
        return true
    end

    return true
end

------------------------------------------------------------
-- 4.13 - EDIT NUMERICO
------------------------------------------------------------
function start_numeric_edit()
    if not param_index_is_valid(param_index) then
        speak("No parameter")
        return false
    end

    if reacomp_virtual_param_is_valid and
       reacomp_virtual_param_is_valid(param_index) then

        speak("Read only. " .. get_param_display_name(param_index) .. " " .. get_param_value_formatted(param_index))
        return false
    end

    disarm_slot_deletes()
    clear_param_memory_arm()

    local value = nil
    local name = clean_one_line(get_param_display_name(param_index))

    if name == "" then
        name = "Parameter " .. tostring(param_index + 1)
    end

    --------------------------------------------------------
    -- ReaEQ Frequency / Bandwidth:
    -- il numeric deve mostrare il valore reale/formattato,
    -- non il raw interno.
    --
    -- Gain resta invariato.
    --------------------------------------------------------
if is_current_fx_reaeq and
   is_current_fx_reaeq() and
   reaeq_param_is_global_gain and
   reaeq_param_is_global_gain(param_index) then

    value = reaeq_get_global_gain_numeric_display_value(param_index)

elseif is_current_fx_reaeq and
   is_current_fx_reaeq() and
   (
       reaeq_param_is_frequency(param_index) or
       reaeq_param_is_gain(param_index) or
       reaeq_param_is_bandwidth(param_index)
   ) then

    value = reaeq_get_numeric_display_value(param_index)
else
    value = get_param_raw(param_index)
    value = tostring(value)
end    

    edit_buffer = tostring(value)
    edit_cursor = #edit_buffer + 1
    edit_started = false
    numeric_edit_fresh = true
    edit_mode = true
    numeric_return_mode = mode or "list"

    speak("Edit " .. name .. " " .. edit_buffer)

    return true
end

function finish_numeric_edit()
    local typed = tonumber(edit_buffer)

    if typed == nil then
        speak("Invalid value")
        return
    end

    local is_reaeq_gain = false
    local is_reaeq_freq = false
    local is_reaeq_bw = false
    local is_reaeq_global_gain = false

    --------------------------------------------------------
    -- ReaEQ special cases.
    --
    -- Gain:
    --   resta come ora. L'utente scrive in dB.
    --
    -- Frequency:
    --   l'utente scrive direttamente in Hz.
    --
    -- Bandwidth / Q:
    --   l'utente scrive direttamente il valore mostrato.
    --------------------------------------------------------
    if reaeq_param_is_global_gain and
       reaeq_param_is_global_gain(param_index) then

        is_reaeq_global_gain = true

    elseif reaeq_param_is_gain and reaeq_param_is_gain(param_index) then
        is_reaeq_gain = true

    elseif reaeq_param_is_frequency and
           reaeq_param_is_frequency(param_index) then

        is_reaeq_freq = true

    elseif reaeq_param_is_bandwidth and
           reaeq_param_is_bandwidth(param_index) then

        is_reaeq_bw = true
    end

    if is_reaeq_global_gain then
        ----------------------------------------------------
        -- ReaEQ Global Gain:
        -- Ctrl+E lavora in dB, ma il parametro grezzo è
        -- lineare: -150 dB = 0, -6 dB = 0.5,
        -- 0 dB = 1, +12 dB = 4.
        -- Non tocca i Gain delle bande.
        ----------------------------------------------------
        typed = clamp(typed, -150, 12)
        set_param_value_raw(
            param_index,
            reaeq_global_gain_db_to_raw(typed)
        )

    elseif is_reaeq_gain then
        ----------------------------------------------------
        -- ReaEQ Gain:
        -- l'utente scrive in dB, ma ReaEQ deve ricevere
        -- il valore grezzo corrispondente.
        --
        -- Non passare 0 direttamente a TrackFX_SetEQParam:
        -- per Gain verrebbe interpretato come raw 0 e quindi
        -- diventerebbe -inf.
        ----------------------------------------------------
        typed = reaeq_clamp_gain_db(typed)

        if not reaeq_set_gain_db_by_feedback(param_index, typed) then
            set_param_value_raw(
                param_index,
                reaeq_gain_db_to_raw(typed)
            )
        end

    elseif is_reaeq_freq then
        ----------------------------------------------------
        -- ReaEQ Frequency:
        -- numeric in Hz reali.
        ----------------------------------------------------
        typed = clamp(typed, 20, 24000)

        if not reaeq_set_frequency_hz_by_chunk(param_index, typed) then
            speak("Frequency not changed")
        end

    elseif is_reaeq_bw then
        ----------------------------------------------------
        -- ReaEQ Bandwidth / Q:
        -- numeric nel valore reale mostrato da ReaEQ.
        -- Nei tre filtri problematici convertiamo quel valore
        -- nel normalizzato corrispondente, perché il raw 0..1
        -- non coincide con il numero parlato.
        ----------------------------------------------------
        typed = reaeq_clamp_bandwidth_real(typed)

        if not reaeq_set_bandwidth_real_by_chunk_alt(param_index, typed) then
            speak("Bandwidth not changed")
        end

    else
        ----------------------------------------------------
        -- Tutti gli altri plugin / parametri:
        -- comportamento normale.
        ----------------------------------------------------
        local _, minval, maxval = get_param_raw(param_index)
        typed = clamp(typed, minval, maxval)

        set_param_value_raw(param_index, typed)
    end

    edit_mode = false
    edit_buffer = ""
    edit_cursor = 1
    edit_started = false
    numeric_edit_fresh = false

    disarm_slot_deletes()
    clear_param_memory_arm()

    save_current_param_position()

    mode = numeric_return_mode or "list"
    numeric_return_mode = "list"

    announce_grid_context(nil)
end

function cancel_numeric_edit()
    edit_mode = false
    edit_buffer = ""
    edit_cursor = 1
    edit_started = false
    numeric_edit_fresh = false

    mode = numeric_return_mode or "list"
    numeric_return_mode = "list"

    announce_grid_context(nil)
end

function close_numeric_edit()
    finish_numeric_edit()
end

function speak_numeric_buffer()
    local name = clean_one_line(get_param_display_name(param_index))
    local content = edit_buffer ~= "" and edit_buffer or "Empty"

    if name == "" then
        name = "Parameter " .. tostring(param_index + 1)
    end

    speak("Edit " .. name .. " " .. content)
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

function handle_numeric_edit(char)
    local is_ctrl = ctrl_down()
    local is_shift = shift_down()
    local is_alt = alt_down()

    if char == KEY_ESC then
        cancel_numeric_edit()
        return true
    end

    --------------------------------------------------------
    -- Ctrl+E dentro l'edit numerico = Esc:
    -- annulla il buffer e torna esattamente al contesto di origine.
    --------------------------------------------------------
    if char == KEY_CTRL_E then
        cancel_numeric_edit()
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

    if not is_ctrl and not is_shift and not is_alt and char == KEY_LEFT then
        numeric_edit_fresh = false

        if #edit_buffer == 0 then
            speak("Empty")
            return true
        end

        edit_cursor = text_move_cursor_left_char(edit_buffer, edit_cursor)

        text_speak_char_at_cursor(edit_buffer, edit_cursor)

        return true
    end

    if not is_ctrl and not is_shift and not is_alt and char == KEY_RIGHT then
        numeric_edit_fresh = false

        if #edit_buffer == 0 then
            speak("Empty")
            return true
        end

        edit_cursor = text_move_cursor_right_char(edit_buffer, edit_cursor)

        text_speak_char_at_cursor(edit_buffer, edit_cursor)

        return true
    end

    --------------------------------------------------------
    -- Home / End nel numeric edit.
    --
    -- Mantiene la stessa logica degli altri campi:
    -- KEY_HOME va alla fine del testo,
    -- KEY_END va all'inizio del testo.
    --
    -- Non dice più "End".
    -- Se sei già al bordo, resta in silenzio.
    --------------------------------------------------------
    if char == KEY_HOME then
        numeric_edit_fresh = false

        if #edit_buffer == 0 then
            edit_cursor = 1
            speak("Empty")
            return true
        end

        if edit_cursor >= #edit_buffer then
            return true
        end

        edit_cursor = #edit_buffer
        text_char_move_changed = true
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

        if edit_cursor <= 1 then
            return true
        end

        edit_cursor = 1
        text_char_move_changed = true
        text_speak_char_at_cursor(edit_buffer, edit_cursor)

        return true
    end    

    if char == KEY_BACKSPACE or
       char == KEY_BACKSPACE_2 then

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

    local c = safe_char(char)

    local test_buffer = edit_started and edit_buffer or ""
    local test_cursor = edit_started and edit_cursor or 1

    if not is_ctrl and not is_alt and
       numeric_buffer_can_accept_char_at(c, test_buffer, test_cursor) then

        numeric_edit_fresh = false

        insert_numeric_char_at_cursor(c)

        speak(c)
        return true
    end

    return true
end

function enter_edit_from_anywhere()
    --------------------------------------------------------
    -- Secondo Ctrl+E dentro l'edit numerico = Esc:
    -- annulla e torna al recinto da cui l'edit era partito.
    --------------------------------------------------------
    if edit_mode then
        cancel_numeric_edit()
        return
    end

    --------------------------------------------------------
    -- Se siamo in Value mode, Ctrl+E apre l'edit numerico
    -- partendo dal parametro corrente e al secondo Ctrl+E
    -- annulla e torna al contesto di origine.
    --------------------------------------------------------
    if mode == "value" then
        ----------------------------------------------------
        -- Uscita silenziosa dal Value mode:
        -- Ctrl+E deve aprire subito l'edit numerico, non
        -- parlare prima il contesto della griglia.
        ----------------------------------------------------
        mode = value_return_mode or "list"
        value_return_mode = "list"
    end

    if mode == "search_edit" or
       mode == "recent" or
       mode == "memory_manager" then

        return_to_all_parameters(nil)
    end

    start_numeric_edit()
end

function jump_to_current_grid()
    disarm_slot_deletes()
    clear_param_memory_arm()

    --------------------------------------------------------
    -- Se siamo dentro l'edit numerico, chiude l'edit e torna
    -- alla griglia da cui era partito Ctrl+E.
    --------------------------------------------------------
    if edit_mode then
        edit_mode = false
        edit_buffer = ""
        edit_cursor = 1
        edit_started = false
        numeric_edit_fresh = false

        mode = numeric_return_mode or "list"
        numeric_return_mode = "list"

        announce_grid_context(nil)
        return
    end

    --------------------------------------------------------
    -- Se siamo in Value mode, torna alla griglia da cui era
    -- partito Ctrl+V.
    --------------------------------------------------------
    if mode == "value" then
        exit_value_mode()
        return
    end

    --------------------------------------------------------
    -- Recinti temporanei:
    -- torna alla griglia stabile All parameters.
    --------------------------------------------------------
    if mode == "search_edit" or
       mode == "recent" or
       mode == "memory_manager" then

        return_to_all_parameters(nil)
        return
    end

    --------------------------------------------------------
    -- Fallback:
    -- legge il contesto corrente della griglia.
    --------------------------------------------------------
    announce_grid_context(nil)
end

------------------------------------------------------------
-- 4.16 - LETTURA RIGA CORRENTE
------------------------------------------------------------
function read_current_line()
    if edit_mode then
        speak_numeric_buffer()
        return
    end

    if mode == "search_edit" then
        speak_search_buffer()
        return
    end

    if mode == "recent" then
        speak_recent_current()
        return
    end

    if mode == "memory_manager" then
        return
    end    

    cancel_pending_speech()

    if fx_offline_grid_active then
        speak(get_fx_offline_grid_label())
        return
    end

    if mode == "group_edit" then
        ----------------------------------------------------
        -- Backslash legge il contesto dell'Edit, mentre Tab
        -- resta dedicato esclusivamente al numero selezionati.
        --
        -- Se F7 appartiene a un Group reale, il conteggio e'
        -- sempre quello completo del Group, anche con Search o
        -- All parameters temporaneamente visibili. I duplicati
        -- contano come occorrenze distinte del Group.
        ----------------------------------------------------
        local total = 0

        if group_edit_loaded_slot ~= nil then
            total = #(group_results or {})
        else
            total = get_active_count()
        end

        local unit = total == 1 and "parameter" or "parameters"

        local edit_label =
            group_edit_loaded_slot ~= nil and "Edit group" or
            (custom_order_active and "Edit Custom order" or "Edit")

        speak(
            edit_label .. ". " ..
            tostring(total) .. " " .. unit .. ". " ..
            get_current_param_spoken_label()
        )

        return
    end

    if group_active then
        speak(
            get_group_context_label() ..
            ". " ..
            tostring(active_pos) ..
            " of " ..
            tostring(get_active_count()) ..
            ". " ..
            get_current_param_spoken_label()
        )

        return
    end

    if search_active then
        speak(
            get_grid_label() ..
            ". " ..
            tostring(active_pos) ..
            " of " ..
            tostring(get_active_count()) ..
            ". " ..
            get_current_param_spoken_label()
        )

        return
    end

    speak(
        get_grid_label() ..
        ". " ..
        tostring(active_pos) ..
        " of " ..
        tostring(get_active_count()) ..
        ". " ..
        get_current_param_spoken_label()
    )
end

------------------------------------------------------------
-- 4.17 - PREPARAZIONE CAMBIO CONTESTO CTRL+ALT
--
-- Usata quando lo script cambia traccia o item senza uscire.
--
-- Non salva il plugin: quello verrà fatto dalla funzione di
-- cambio contesto.
--
-- Qui chiude solo i recinti temporanei:
-- - edit numerico;
-- - value mode;
-- - search edit;
-- - recent searches;
-- - name edit;
-- - Parameter Navigator.;
-- - F7 group edit.
--
-- Così il nuovo contesto riparte pulito in browser FX o griglia.
------------------------------------------------------------
function prepare_ui_state_for_context_switch()
    cancel_pending_speech()
    clear_param_memory_arm()
    disarm_slot_deletes()

    --------------------------------------------------------
    -- Edit numerico.
    --------------------------------------------------------
    edit_mode = false
    edit_buffer = ""
    edit_started = false

    --------------------------------------------------------
    -- Search edit / recent searches.
    --------------------------------------------------------
    search_buffer = ""
    search_cursor = 1
    search_edge = nil

    --------------------------------------------------------
    -- Name edit.
    --------------------------------------------------------
    name_edit_buffer = ""
    name_edit_cursor = 1
    name_edit_edge = nil
    name_edit_return_mode = "list"
    name_edit_param_index = nil

    --------------------------------------------------------
    -- Group name edit.
    --------------------------------------------------------
    group_name_edit_buffer = ""
    group_name_edit_cursor = 1
    group_name_edit_edge = nil
    group_name_edit_return_mode = "list"
    group_name_edit_slot = nil

    --------------------------------------------------------
    -- F7 group edit runtime path.
    -- La selezione F7 runtime per FX resta salvata nella
    -- tabella f7_runtime_selected_by_fx, perché è per FX.
    --------------------------------------------------------
    group_select_path = {}
    group_select_dir_path = {}
    group_select_path_lookup = {}
    group_select_base_selected = {}
    group_select_path_action = "select"

    --------------------------------------------------------
    -- Torna a uno stato base.
    -- Il nuovo contesto ricostruirà poi:
    -- - fx list;
    -- - plugin txt;
    -- - parametri;
    -- - ultimo FX;
    -- - ultimo parametro;
    -- - ultima area.
    --------------------------------------------------------
    mode = "list"
    value_return_mode = "list"
    numeric_return_mode = "list"

    search_active = false
    group_active = false

    search_results = {}
    group_results = {}

    clear_group_context()

    return true
end

------------------------------------------------------------
-- FINE PARTE 4 / 8
------------------------------------------------------------

------------------------------------------------------------
-- PARTE 5 / 8
-- PROFILO TXT PLUGIN, FX BROWSER, RIPRISTINO PLUGIN,
-- PREPARAZIONE GRIGLIA PARAMETRI
--
-- Nota:
-- - nessun salvataggio nel progetto RPP;
-- - il profilo del plugin resta nel TXT;
-- - l'ultimo FX del contesto viene ricordato in ExtState
--   globale, quindi non sporca il progetto;
-- - step scale, grid size, last param, last entry, last area,
--   custom order, gruppi e memorie parametro vivono nel TXT.
------------------------------------------------------------

------------------------------------------------------------
-- 5.0 - COMPATIBILITÀ TASTI AGGIUNTI
------------------------------------------------------------
if KEY_CTRL_D == nil then
    KEY_CTRL_D = 4
end

------------------------------------------------------------
-- 5.1 - PROFILO TXT PER PLUGIN
------------------------------------------------------------
function plugin_txt_matches_selected_fx()
    if not plugin_txt_loaded then
        return false
    end

    local current = clean_one_line(get_fx_raw_label())
    local loaded = clean_one_line(plugin_txt_raw_fx_name or "")

    return current ~= "" and loaded ~= "" and current == loaded
end

function load_plugin_txt_for_selected_fx()
    if not selected_fx_label or selected_fx_label == "" then
        return false
    end

    local ok = plugin_txt_load_for_current_fx()

if type(cc_runtime_clear_link_cache) == "function" then
    cc_runtime_clear_link_cache()
end

    if ok then
        restore_slot_access_mode_from_plugin_txt()

        grid_size_user_changed = false
        grid_size_auto_default = false

        ----------------------------------------------------
        -- Ripristina Step e Grid specifici del plugin,
        -- se presenti nella sezione [Extra] del TXT.
        ----------------------------------------------------
        if type(restore_plugin_step_grid_from_txt) == "function" then
            restore_plugin_step_grid_from_txt()
        else
            if type(restore_plugin_step_scale_from_txt) == "function" then
                restore_plugin_step_scale_from_txt()
            end

            if type(restore_plugin_grid_size_from_txt) == "function" then
                restore_plugin_grid_size_from_txt()
            end
        end

        ----------------------------------------------------
        -- Carica lo stato Custom order richiesto dal TXT.
        -- Se param_count non è ancora pronto, la funzione
        -- uscirà senza danni e verrà richiamata dopo.
        ----------------------------------------------------
        if type(load_custom_order_from_txt) == "function" then
            load_custom_order_from_txt()
        end
if type(restore_cc_combo_speech_from_txt) == "function" then
    restore_cc_combo_speech_from_txt()
end

if type(cc_runtime_restore_fixed_map_state_from_txt) == "function" then
    cc_runtime_restore_fixed_map_state_from_txt()
end
    end

    return ok
end

function ensure_plugin_txt_for_selected_fx()
    if plugin_txt_matches_selected_fx() then
        return true
    end

    if plugin_txt_loaded then
        plugin_txt_unload()
    end

    return load_plugin_txt_for_selected_fx()
end

function save_plugin_txt_now()
    if plugin_txt_loaded then
        plugin_txt_save_if_dirty(true)
    end
end

function reload_plugin_txt_context()
    if plugin_txt_loaded then
        plugin_txt_unload()
    end

    if type(cc_runtime_clear_link_cache) == "function" then
        cc_runtime_clear_link_cache()
    end

    return load_plugin_txt_for_selected_fx()
end

------------------------------------------------------------
-- 5.1A - REAEQ DEFAULT GRID
--
-- ReaEQ è speciale solo come default iniziale:
-- se il TXT non contiene grid_size_v1, usa Grid 5 in memoria.
--
-- Importante:
-- Grid 5 NON viene salvata automaticamente.
-- Verrà salvata solo se l'utente cambia la griglia con F3/F4
-- oppure esegue un reset della griglia/default.
------------------------------------------------------------
function is_current_fx_reaeq()
    local label = clean_one_line(get_fx_raw_label() or "")

    label = strip_fx_prefix(label)
    label = clean_one_line(label):lower()

    if label == "" then
        return false
    end

    --------------------------------------------------------
    -- Copre:
    -- ReaEQ
    -- VST: ReaEQ (Cockos)
    -- VST3: ReaEQ (Cockos)
    -- eventuali varianti con prefisso/suffisso.
    --------------------------------------------------------
    return label:find("reaeq", 1, true) ~= nil
end

function current_fx_has_reacomp_param_signature()
    --------------------------------------------------------
    -- Fallback importante:
    -- su alcuni sistemi o profili il nome FX può non essere
    -- quello atteso, oppure può essere stato rinominato.
    -- In quel caso riconosciamo ReaComp dalla firma dei suoi
    -- parametri reali.
    --
    -- Questa funzione NON usa get_param_name(), così evita
    -- ricorsioni con alias/special layout.
    --------------------------------------------------------
    local real_fx = get_current_real_fx_index()

    if real_fx == nil then
        return false
    end

    local found = {}

    for i = 0, (tonumber(param_count) or 0) - 1 do
        local ok, retval, name

        if ctx.kind == "take" then
            if ctx.take then
                ok, retval, name =
                    pcall(reaper.TakeFX_GetParamName, ctx.take, real_fx, i, "")
            end
        else
            if ctx.track then
                ok, retval, name =
                    pcall(reaper.TrackFX_GetParamName, ctx.track, real_fx, i, "")
            end
        end

        if ok and retval then
            local key = clean_one_line(name or "")
            key = key:lower()
            key = key:gsub("%s+", " ")
            key = trim(key)

            if key ~= "" then
                found[key] = true
            end
        end
    end

    --------------------------------------------------------
    -- ReaComp ha questa combinazione molto specifica.
    -- Così non dipendiamo solo dal nome del plug-in.
    --------------------------------------------------------
    return
        found["threshold"] == true and
        found["ratio"] == true and
        found["signin"] == true and
        found["filter preview"] == true and
        found["rms size"] == true and
        found["auto make up gain"] == true
end

------------------------------------------------------------
-- ReaComp detection cache / safety
--
-- Nota importante:
-- la 0.198 usava anche una scansione per firma dei parametri
-- dentro is_current_fx_reacomp(). Quella funzione viene chiamata
-- da molte routine generiche, anche da get_param_name() e
-- get_param_value_formatted(). In F8, quando esistono parametri
-- nascosti, la lista Hidden parameters può moltiplicare queste
-- chiamate e interrogare ripetutamente tutti i nomi dei parametri
-- del plugin corrente. Su alcuni plugin questo può rendere REAPER
-- instabile.
--
-- Per stabilità, ReaComp viene riconosciuto dal nome FX, che è il
-- caso normale: JS/VST/VST3 ReaComp (Cockos). La funzione di firma
-- resta nel file come diagnostica/fallback manuale, ma non viene
-- più chiamata automaticamente da ogni richiesta generica.
------------------------------------------------------------
reacomp_detect_cache_key = nil
reacomp_detect_cache_value = nil

function reacomp_detection_make_cache_key()
    local real_fx = nil

    if type(get_current_real_fx_index) == "function" then
        real_fx = get_current_real_fx_index()
    end

    return
        tostring(ctx and ctx.kind or "") ..
        "::" ..
        tostring(ctx and ctx.track or "") ..
        "::" ..
        tostring(ctx and ctx.take or "") ..
        "::" ..
        tostring(real_fx or fx_index or 0) ..
        "::" ..
        tostring(param_count or 0) ..
        "::" ..
        tostring(get_fx_raw_label() or "")
end

function reacomp_clear_detection_cache()
    reacomp_detect_cache_key = nil
    reacomp_detect_cache_value = nil
end

function is_current_fx_reacomp()
    local key = reacomp_detection_make_cache_key()

    if reacomp_detect_cache_key == key and
       reacomp_detect_cache_value ~= nil then

        return reacomp_detect_cache_value == true
    end

    local label = clean_one_line(get_fx_raw_label() or "")

    label = strip_fx_prefix(label)
    label = clean_one_line(label):lower()

    --------------------------------------------------------
    -- Copre:
    -- ReaComp
    -- VST: ReaComp (Cockos)
    -- VST3: ReaComp (Cockos)
    -- ed eventuali nomi standard Cockos.
    --
    -- Non usiamo più automaticamente la scansione per firma,
    -- perché in F8/Hidden parameters veniva chiamata troppe volte
    -- anche per plugin non ReaComp.
    --------------------------------------------------------
    local result =
        label ~= "" and
        label:find("reacomp", 1, true) ~= nil

    reacomp_detect_cache_key = key
    reacomp_detect_cache_value = result and true or false

    return reacomp_detect_cache_value
end


reagate_detect_cache_key = nil
reagate_detect_cache_value = nil

function reagate_clear_detection_cache()
    reagate_detect_cache_key = nil
    reagate_detect_cache_value = nil
end

function is_current_fx_reagate()
    local key = reacomp_detection_make_cache_key()

    if reagate_detect_cache_key == key and
       reagate_detect_cache_value ~= nil then

        return reagate_detect_cache_value == true
    end

    local label = clean_one_line(get_fx_raw_label() or "")

    label = strip_fx_prefix(label)
    label = clean_one_line(label):lower()

    local result =
        label ~= "" and
        label:find("reagate", 1, true) ~= nil

    reagate_detect_cache_key = key
    reagate_detect_cache_value = result and true or false

    return reagate_detect_cache_value
end

function plugin_grid_size_has_saved_value()
    if not plugin_storage_available() then
        return false
    end

    local saved = trim(get_plugin_state_safe(get_plugin_grid_size_key()) or "")

    return saved ~= ""
end

function apply_reaeq_default_grid_if_needed()
    grid_size_auto_default = false

    if not is_current_fx_reaeq() then
        return false
    end

    if not plugin_storage_available() then
        return false
    end

    --------------------------------------------------------
    -- Se il TXT ha già una griglia salvata, non tocca nulla.
    --------------------------------------------------------
    if plugin_grid_size_has_saved_value() then
        return false
    end

    --------------------------------------------------------
    -- ReaEQ vergine:
    -- 5 elementi per colonna.
    --
    -- Colonna ideale:
    -- Band enabled / filter type / frequency / gain / bandwidth.
    --
    -- Non salva nel TXT.
    --------------------------------------------------------
    grid_size = 5
    grid_size_auto_default = true

    return true
end

------------------------------------------------------------
-- 5.1B - STEP / GRID PER PLUGIN TXT
--
-- Queste funzioni sovrascrivono in modo più sicuro quelle
-- della parte 2, usando plugin_storage_available().
------------------------------------------------------------
function save_plugin_grid_size_to_txt()
    if not plugin_storage_available() then
        return false
    end

    grid_size = clamp_int(grid_size, GRID_MIN, GRID_MAX)

    --------------------------------------------------------
    -- ReaEQ vergine:
    -- se Grid 5 è solo default automatico e l'utente non ha
    -- cambiato la griglia, NON salvare grid_size_v1.
    --------------------------------------------------------
    if is_current_fx_reaeq() and
       not grid_size_user_changed and
       not plugin_grid_size_has_saved_value() then

        return false
    end

    set_plugin_state_safe(
        get_plugin_grid_size_key(),
        tostring(grid_size)
    )

    grid_size_auto_default = false

    plugin_txt_save_if_dirty(true)

    return true
end

function restore_plugin_grid_size_from_txt()
    if not plugin_storage_available() then
        return false
    end

    local saved = get_plugin_state_safe(get_plugin_grid_size_key())
    local n = tonumber(saved)

    if n == nil then
        return false
    end

    grid_size = clamp_int(n, GRID_MIN, GRID_MAX)

    return true
end

function save_plugin_step_scale_to_txt()
    --------------------------------------------------------
    -- Compatibilità: il vecchio step globale del plugin non
    -- viene più scritto. Ora lo step vive per parametro.
    --------------------------------------------------------
    if type(param_step_scale_flush_current) == "function" then
        return param_step_scale_flush_current()
    end

    return false
end

function restore_plugin_step_scale_from_txt()
    --------------------------------------------------------
    -- Default sempre Step normal. Se il parametro corrente ha
    -- una taratura nel TXT, viene applicata quella.
    --------------------------------------------------------
    if type(param_step_scale_sync_for_current_param) == "function" then
        return param_step_scale_sync_for_current_param()
    end

    step_scale_index = STEP_NORMAL_INDEX

    return true
end

function save_plugin_step_grid_to_txt()
    save_plugin_step_scale_to_txt()
    save_plugin_grid_size_to_txt()
end

function restore_plugin_step_grid_from_txt()
    restore_plugin_step_scale_from_txt()
    restore_plugin_grid_size_from_txt()
end

------------------------------------------------------------
-- 5.2 - BROWSER FX INTERNO
------------------------------------------------------------
function clear_fx_browser_lists()
    fx_browser_all = {}
    fx_browser_master = {}
    fx_browser_monitor = {}
end

function make_fx_browser_entry(list_index, number_in_group)
    list_index = tonumber(list_index) or 1
    number_in_group = tonumber(number_in_group) or list_index

    return {
        list_index = list_index,
        number = number_in_group,
        name = clean_one_line(fx_names[list_index] or ""),
        is_monitor = fx_is_monitor[list_index] == true
    }
end

function build_fx_browser_lists()
    clear_fx_browser_lists()

    if fx_count <= 0 or #fx_names <= 0 then
        fx_browser_col = "fx"
        fx_browser_pos = 1
        return
    end

    local master_num = 0
    local monitor_num = 0

    --------------------------------------------------------
    -- Master: due colonne separate.
    -- Sinistra/destra nel browser cambia Master <-> Monitor FX.
    --
    -- Quando si entra nel browser dal contesto Master,
    -- la posizione iniziale preferisce sempre la colonna Master
    -- se contiene almeno un FX.
    --
    -- Se Master FX è vuota ma Monitor FX contiene qualcosa,
    -- allora parte dalla colonna Monitor FX.
    --
    -- Questo evita che l'ultimo Monitor FX salvato porti
    -- il cursore invisibile direttamente nella colonna destra.
    --------------------------------------------------------
    if ctx.is_master then
        for i = 1, #fx_names do
            if fx_is_monitor[i] then
                monitor_num = monitor_num + 1

                fx_browser_monitor[#fx_browser_monitor + 1] =
                    make_fx_browser_entry(i, monitor_num)
            else
                master_num = master_num + 1

                fx_browser_master[#fx_browser_master + 1] =
                    make_fx_browser_entry(i, master_num)
            end
        end

        if #fx_browser_master > 0 then
            fx_browser_col = "master"
            fx_browser_pos = 1

        elseif #fx_browser_monitor > 0 then
            fx_browser_col = "monitor"
            fx_browser_pos = 1

        else
            fx_browser_col = "master"
            fx_browser_pos = 1
        end

        ----------------------------------------------------
        -- Non cambiare mai l'FX corrente qui.
        -- build_fx_browser_lists() deve solo costruire il browser.
        -- La sincronizzazione del cursore browser verrà fatta dopo
        -- con sync_fx_browser_to_current_fx().
        ----------------------------------------------------
        return
    end

    --------------------------------------------------------
    -- Track / Take: una sola colonna FX.
    --------------------------------------------------------
    for i = 1, #fx_names do
        fx_browser_all[#fx_browser_all + 1] =
            make_fx_browser_entry(i, i)
    end

    fx_browser_col = "fx"
    fx_browser_pos = 1

    sync_fx_browser_to_current_fx()
end

------------------------------------------------------------
-- 5.3 - MEMORIA ULTIMO FX DEL CONTESTO
--
-- Non usa il progetto RPP.
-- Usa ExtState persistente globale, quindi:
-- - non sporca il progetto;
-- - funziona anche tra sessioni;
-- - resta legata al contesto tramite GUID/nome.
------------------------------------------------------------
function get_last_fx_context_key()
    return
        EXT_LAST_FX_PREFIX ..
        "::" ..
        get_context_storage_id()
end

function get_context_fallback_storage_id()
    if ctx.kind == "take" then
        local track_num = 0
        local take_name = ""

        if ctx.track then
            track_num =
                reaper.GetMediaTrackInfo_Value(
                    ctx.track,
                    "IP_TRACKNUMBER"
                )

            track_num = math.floor(tonumber(track_num) or 0)
        end

        if ctx.take then
            local _, name =
                reaper.GetSetMediaItemTakeInfo_String(
                    ctx.take,
                    "P_NAME",
                    "",
                    false
                )

            take_name = clean_one_line(name or "")
        end

        return
            "take_fallback::track::" ..
            tostring(track_num) ..
            "::" ..
            take_name
    end

    if ctx.is_master then
        return "track_fallback::MASTER"
    end

    local track_num = 0
    local track_name = ""

    if ctx.track then
        track_num =
            reaper.GetMediaTrackInfo_Value(
                ctx.track,
                "IP_TRACKNUMBER"
            )

        local _, name = reaper.GetTrackName(ctx.track)

        track_num = math.floor(tonumber(track_num) or 0)
        track_name = clean_one_line(name or "")
    end

    return
        "track_fallback::" ..
        tostring(track_num) ..
        "::" ..
        track_name
end

function get_last_fx_fallback_key()
    return
        EXT_LAST_FX_PREFIX ..
        "::fallback::" ..
        get_context_fallback_storage_id()
end

function save_global_state(key, value)
    key = tostring(key or "")

    if key == "" then
        return false
    end

    reaper.SetExtState(
        EXT_SECTION,
        key,
        tostring(value or ""),
        true
    )

    return true
end

function get_global_state(key)
    key = tostring(key or "")

    if key == "" then
        return ""
    end

    return reaper.GetExtState(EXT_SECTION, key) or ""
end

function save_last_fx_fallback_state(txt)
    save_global_state(get_last_fx_fallback_key(), txt)
end

function get_last_fx_fallback_state()
    return get_global_state(get_last_fx_fallback_key())
end

function fx_memory_normalized_name_at(list_index)
    return clean_one_line(fx_names[list_index] or ""):lower()
end

function fx_memory_monitor_at(list_index)
    return fx_is_monitor[list_index] == true
end

function fx_memory_select_list_index(list_index)
    list_index = tonumber(list_index)

    if list_index == nil then
        return false
    end

    list_index = math.floor(list_index + 0.5)

    if list_index < 1 or list_index > #fx_names then
        return false
    end

    fx_index = list_index - 1
    selected_fx_label = fx_names[list_index] or ""
    selected_fx_is_monitor = fx_is_monitor[list_index] == true

    return true
end

function fx_memory_get_occurrence_for_list_index(list_index)
    list_index = tonumber(list_index)

    if list_index == nil then
        return 1
    end

    list_index = math.floor(list_index + 0.5)

    if list_index < 1 or list_index > #fx_names then
        return 1
    end

    local wanted = fx_memory_normalized_name_at(list_index)
    local wanted_monitor = fx_memory_monitor_at(list_index)

    if wanted == "" then
        return 1
    end

    local occurrence = 0

    for i = 1, list_index do
        if fx_memory_normalized_name_at(i) == wanted and
           fx_memory_monitor_at(i) == wanted_monitor then

            occurrence = occurrence + 1
        end
    end

    if occurrence < 1 then
        occurrence = 1
    end

    return occurrence
end

function fx_memory_find_name_occurrence(raw_name, wanted_monitor, occurrence)
    raw_name = clean_one_line(raw_name or "")
    occurrence = clamp_int(occurrence, 1, 9999)

    if raw_name == "" then
        return nil
    end

    local wanted = raw_name:lower()
    local seen = 0

    for i = 1, #fx_names do
        local name = fx_memory_normalized_name_at(i)
        local is_monitor = fx_memory_monitor_at(i)

        if name == wanted and is_monitor == wanted_monitor then
            seen = seen + 1

            if seen == occurrence then
                return i
            end
        end
    end

    return nil
end

function fx_memory_parse_saved_position(saved)
    saved = trim(saved or "")

    if saved == "" then
        return nil
    end

    local parts = {}

    for part in (saved .. "	"):gmatch("([^	]*)	") do
        parts[#parts + 1] = part
    end

    if #parts < 4 then
        return nil
    end

    local data = {
        fx_index = tonumber(parts[1]),
        real_index = tonumber(parts[2]),
        monitor = clean_one_line(parts[3] or "") == "1",
        occurrence = 1,
        has_occurrence = false,
        name = ""
    }

    --------------------------------------------------------
    -- Formato vecchio:
    -- fx_index TAB real_index TAB monitor TAB name
    --
    -- Formato nuovo:
    -- fx_index TAB real_index TAB monitor TAB occurrence TAB name
    --------------------------------------------------------
    if #parts >= 5 and tonumber(parts[4]) ~= nil then
        data.occurrence = clamp_int(tonumber(parts[4]), 1, 9999)
        data.has_occurrence = true

        local name_parts = {}

        for i = 5, #parts do
            name_parts[#name_parts + 1] = parts[i]
        end

        data.name = clean_one_line(table.concat(name_parts, "	"))
    else
        local name_parts = {}

        for i = 4, #parts do
            name_parts[#name_parts + 1] = parts[i]
        end

        data.name = clean_one_line(table.concat(name_parts, "	"))
    end

    return data
end

function save_current_fx_position()
    if fx_count <= 0 then
        return false
    end

    if fx_index < 0 or fx_index > fx_count - 1 then
        return false
    end

    local list_index = fx_index + 1
    local raw_name = clean_one_line(fx_names[list_index] or "")
    local real_index = fx_real_indices[list_index] or fx_index
    local occurrence = fx_memory_get_occurrence_for_list_index(list_index)

    local is_monitor =
        fx_is_monitor[list_index] == true and "1" or "0"

    local txt =
        tostring(fx_index) ..
        "	" ..
        tostring(real_index) ..
        "	" ..
        is_monitor ..
        "	" ..
        tostring(occurrence) ..
        "	" ..
        raw_name

    save_global_state(get_last_fx_context_key(), txt)
    save_last_fx_fallback_state(txt)

    return true
end

function apply_saved_fx_position_text(saved)
    local data = fx_memory_parse_saved_position(saved)

    if data == nil or fx_count <= 0 then
        return false
    end

    local saved_fx_index = data.fx_index
    local saved_real = data.real_index
    local saved_monitor = data.monitor == true
    local saved_occurrence = clamp_int(data.occurrence, 1, 9999)
    local saved_has_occurrence = data.has_occurrence == true
    local saved_name = clean_one_line(data.name or "")

    --------------------------------------------------------
    -- 1. Nome + area + numero istanza.
    -- Questo distingue tre Pro-Q 4 uguali nella stessa chain.
    --------------------------------------------------------
    if saved_name ~= "" and saved_has_occurrence then
        local list_index = fx_memory_find_name_occurrence(
            saved_name,
            saved_monitor,
            saved_occurrence
        )

        if list_index ~= nil and fx_memory_select_list_index(list_index) then
            return true
        end
    end

    --------------------------------------------------------
    -- 2. Indice reale REAPER.
    --------------------------------------------------------
    if saved_real ~= nil then
        for i = 1, #fx_real_indices do
            if fx_real_indices[i] == saved_real and
               fx_memory_monitor_at(i) == saved_monitor then

                if fx_memory_select_list_index(i) then
                    return true
                end
            end
        end
    end

    --------------------------------------------------------
    -- 3. Posizione nella lista corrente.
    --------------------------------------------------------
    if saved_fx_index ~= nil and
       saved_fx_index >= 0 and
       saved_fx_index <= fx_count - 1 then

        local list_index = math.floor(saved_fx_index + 0.5) + 1

        if fx_memory_select_list_index(list_index) then
            return true
        end
    end

    --------------------------------------------------------
    -- 4. Compatibilità finale vecchia: primo nome uguale.
    -- Si usa solo se occurrence / indice reale / posizione falliscono.
    --------------------------------------------------------
    if saved_name ~= "" then
        local list_index = fx_memory_find_name_occurrence(
            saved_name,
            saved_monitor,
            1
        )

        if list_index ~= nil and fx_memory_select_list_index(list_index) then
            return true
        end
    end

    return false
end

function restore_last_fx_position()
    local saved = get_global_state(get_last_fx_context_key())

    if apply_saved_fx_position_text(saved) then
        return true
    end

    saved = get_last_fx_fallback_state()

    if apply_saved_fx_position_text(saved) then
        return true
    end

    return false
end

------------------------------------------------------------
-- 5.4 - FX BROWSER: LISTA / POSIZIONE / SPEECH
------------------------------------------------------------
function get_fx_browser_list()
    if ctx.is_master then
        if fx_browser_col == "monitor" then
            return fx_browser_monitor
        end

        return fx_browser_master
    end

    return fx_browser_all
end

function get_fx_browser_col_name()
    if ctx.is_master then
        if fx_browser_col == "monitor" then
            return "Monitor FX"
        end

        return "Master"
    end

    return "FX"
end

function clamp_fx_browser_pos()
    local list = get_fx_browser_list()
    local count = #list

    if count <= 0 then
        fx_browser_pos = 1
        return
    end

    fx_browser_pos = clamp_int(fx_browser_pos, 1, count)
end

function sync_fx_browser_to_current_fx()
    local wanted_list_index = fx_index + 1

    --------------------------------------------------------
    -- Master / Monitor:
    -- prima sceglie la colonna corretta in base all'FX
    -- realmente selezionato.
    --------------------------------------------------------
    if ctx.is_master then
        if fx_is_monitor[wanted_list_index] == true then
            fx_browser_col = "monitor"
        else
            fx_browser_col = "master"
        end
    end

    local list = get_fx_browser_list()

    for pos = 1, #list do
        if list[pos].list_index == wanted_list_index then
            fx_browser_pos = pos
            return true
        end
    end

    --------------------------------------------------------
    -- Fallback: se la colonna scelta è vuota o non contiene
    -- l'FX, passa a una colonna disponibile senza cambiare FX.
    --------------------------------------------------------
    if ctx.is_master then
        if fx_browser_col == "master" and #fx_browser_monitor > 0 then
            fx_browser_col = "monitor"
            list = get_fx_browser_list()

        elseif fx_browser_col == "monitor" and #fx_browser_master > 0 then
            fx_browser_col = "master"
            list = get_fx_browser_list()
        end

        for pos = 1, #list do
            if list[pos].list_index == wanted_list_index then
                fx_browser_pos = pos
                return true
            end
        end
    end

    fx_browser_pos = 1

    return false
end

function get_fx_browser_current_entry()
    local list = get_fx_browser_list()

    if #list <= 0 then
        return nil
    end

    clamp_fx_browser_pos()

    return list[fx_browser_pos]
end

function sync_current_fx_to_browser_cursor_silent()
    local entry = get_fx_browser_current_entry()

    if not entry then
        return false
    end

    if not entry.list_index or not fx_names[entry.list_index] then
        return false
    end

    fx_index = entry.list_index - 1
    selected_fx_label = fx_names[entry.list_index] or ""
    selected_fx_is_monitor = fx_is_monitor[entry.list_index] == true

    return selected_fx_label ~= ""
end

function get_fx_browser_entry_is_bypassed(entry)
    if not entry or not entry.list_index then
        return false
    end

    local real_fx = fx_real_indices[entry.list_index]

    if real_fx == nil then
        return false
    end

    return fx_real_fx_is_bypassed(real_fx)
end

function get_fx_browser_entry_spoken_label(entry)
    if not entry then
        return "No FX"
    end

    local name = strip_fx_prefix(entry.name)

    name = clean_one_line(name)

    if name == "" then
        name = "FX"
    end

    local msg = ""
    local delta_solo = get_fx_browser_entry_delta_solo_spoken_part(entry)

    if delta_solo ~= "" then
        msg = msg .. delta_solo .. " "
    end

    local real_fx = fx_real_indices[entry.list_index]

    if real_fx ~= nil and fx_get_offline_for_real_fx(real_fx) == true then
        msg = msg .. "Offline "
    elseif get_fx_browser_entry_is_bypassed(entry) then
        msg = msg .. "Bypassed. "
    end

    return msg .. name
end

function speak_fx_browser_current(prefix)
    local list = get_fx_browser_list()

    if #list <= 0 then
        local msg = "No FX"

        if prefix and prefix ~= "" then
            msg = prefix .. ". " .. msg
        end

        speak(msg)
        return
    end

    clamp_fx_browser_pos()

    local entry = list[fx_browser_pos]
    local entry_label = get_fx_browser_entry_spoken_label(entry)

    if prefix and prefix ~= "" then
        speak(prefix .. ". " .. entry_label)
    else
        speak(entry_label)
    end
end

------------------------------------------------------------
-- 5.5 - ENTRATA NEL BROWSER FX
------------------------------------------------------------
function enter_fx_browser_mode(prefix, remember_area)
    cancel_pending_speech()
    clear_param_memory_arm()
    disarm_slot_deletes()

    --------------------------------------------------------
    -- Rebuild the FX list before opening the internal browser.
    -- This restores the older stable Master / Monitor FX behavior:
    -- the browser is built from the current REAPER context, not from
    -- a possibly stale parameter-grid list.
    --------------------------------------------------------
    --------------------------------------------------------
    -- Se siamo sul Master, non lasciare che un fallback
    -- precedente abbia trasformato il contesto in una traccia
    -- normale. Prima di costruire il browser, riallinea il
    -- contesto al Master selezionato.
    --------------------------------------------------------
    if master_is_selected and master_is_selected() then
        local master = get_master_track()

        if master and
           (
               get_track_fx_count(master) > 0 or
               get_monitor_fx_count(master) > 0
           ) then

            set_context_track(master, true)
        end
    end

    build_fx_list_for_current_context()

    build_fx_browser_lists()
    sync_fx_browser_to_current_fx()

    if fx_count <= 0 then
        speak("No FX in selected context")
        return false
    end

    ensure_plugin_txt_for_selected_fx()

    mode = "fx_browser"
    value_return_mode = "list"
    numeric_return_mode = "list"

    edit_mode = false
    edit_buffer = ""
    edit_started = false

    if remember_area ~= false then
        save_current_area_state("browser")
        save_plugin_txt_now()
    end

    gfx.init("FX Browser", 1, 1, 0, -32000, -32000)

    speak_fx_browser_current(prefix)

    return true
end

function fx_browser_switch_col(direction)
    if not ctx.is_master then
        return
    end

    direction = tonumber(direction) or 0

    if direction == 0 then
        return
    end

    local old_col = fx_browser_col
    local old_pos = fx_browser_pos

    if direction > 0 then
        if fx_browser_col == "monitor" then
            return
        end

        fx_browser_col = "monitor"
    else
        if fx_browser_col == "master" then
            return
        end

        fx_browser_col = "master"
    end

    local list = get_fx_browser_list()

    if #list <= 0 then
        fx_browser_col = old_col
        fx_browser_pos = old_pos
        return
    end

    fx_browser_pos = clamp_int(old_pos, 1, #list)

    speak_fx_browser_current()
end

function fx_browser_move_vertical(direction)
    local list = get_fx_browser_list()

    if #list <= 0 then
        speak_fx_browser_current()
        return
    end

    local new_pos = fx_browser_pos + direction

    new_pos = clamp_int(new_pos, 1, #list)

    if new_pos ~= fx_browser_pos then
        fx_browser_pos = new_pos
        speak_fx_browser_current()
    end
end

function fx_browser_page(direction)
    local list = get_fx_browser_list()

    if #list <= 0 then
        return
    end

    local amount = get_page_nav_amount()
    local new_pos = fx_browser_pos + (amount * direction)

    new_pos = clamp_int(new_pos, 1, #list)

    if new_pos ~= fx_browser_pos then
        fx_browser_pos = new_pos
        speak_fx_browser_current()
    end
end

function fx_browser_first()
    local list = get_fx_browser_list()

    if #list <= 0 then
        return
    end

    fx_browser_pos = 1

    speak_fx_browser_current()
end

function fx_browser_last()
    local list = get_fx_browser_list()

    if #list <= 0 then
        return
    end

    fx_browser_pos = #list

    speak_fx_browser_current()
end

------------------------------------------------------------
-- 5.6 - SELEZIONE FX DAL BROWSER
------------------------------------------------------------
function select_fx_browser_entry(entry)
    if not entry then
        speak("No FX")
        return false
    end

    if not entry.list_index or not fx_names[entry.list_index] then
        speak("No FX")
        return false
    end

    --------------------------------------------------------
    -- Prima di cambiare plugin, salva il profilo corrente.
    --------------------------------------------------------
    save_current_plugin_profile_before_switch()

    fx_index = entry.list_index - 1
    selected_fx_label = fx_names[entry.list_index] or ""
    selected_fx_is_monitor = fx_is_monitor[entry.list_index] == true

    save_current_fx_position()

    --------------------------------------------------------
    -- Sincronizza anche la FX chain visiva.
    -- Non apre la chain e non ruba focus.
    --------------------------------------------------------
    show_current_fx_for_sighted()
    show_current_fx_for_sighted_later()

    reload_plugin_txt_context()

    return true
end

------------------------------------------------------------
-- 5.7 - PREPARAZIONE GRIGLIA PARAMETRI
--
-- Ricostruisce il campo di gioco:
-- Plugin order oppure Custom order.
------------------------------------------------------------
function reset_param_browser_runtime_state()
    search_active = false
    group_active = false

    search_results = {}
    group_results = {}
    group_selected = {}

    search_query = ""
    search_buffer = ""
    search_cursor = 1
    search_edge = nil

    edit_mode = false
    edit_buffer = ""
    edit_started = false

    mode = "list"
    value_return_mode = "list"
    numeric_return_mode = "list"

    clear_group_context()
    clear_param_memory_arm()
    disarm_slot_deletes()

    if type(custom_order_clear_runtime) == "function" then
        custom_order_clear_runtime()
    end
end

function prepare_selected_fx_for_param_browser()
    if current_fx_is_offline() then
        return enter_offline_fx_grid(false)
    end

    clear_fx_offline_grid_state()

    param_count = get_current_fx_param_count()

    if param_count <= 0 then
        speak("Plugin has no parameters")
        return false
    end

    reset_param_browser_runtime_state()

    --------------------------------------------------------
    -- Prima costruisce sempre l'ordine reale del plugin.
    --------------------------------------------------------
    build_all_param_indices()

    --------------------------------------------------------
    -- Poi carica profilo TXT e possibile Custom order.
    --------------------------------------------------------
    ensure_plugin_txt_for_selected_fx()

    --------------------------------------------------------
    -- ReaEQ vergine:
    -- default Grid 5 solo in memoria.
    -- Se esiste grid_size_v1 nel TXT, non tocca nulla.
    --------------------------------------------------------
    apply_reaeq_default_grid_if_needed()

    --------------------------------------------------------
    -- Ora param_count è valido: Custom order può davvero
    -- normalizzarsi sul plugin corrente.
    --------------------------------------------------------
    if type(load_custom_order_from_txt) == "function" then
        load_custom_order_from_txt()
    end

    restore_active_grid_size_from_txt()

    if type(apply_custom_order_to_all_params) == "function" then
        apply_custom_order_to_all_params()
    end    

    --------------------------------------------------------
    -- Ricostruisce l'ordine reale dopo eventuale stato custom.
    --------------------------------------------------------
    build_all_param_indices()

    --------------------------------------------------------
    -- Shift+C salvato nel TXT:
    -- qui param_count e griglia sono finalmente pronti.
    -- Se lo stato era On, fai la vera accensione runtime
    -- come quando premi Shift+C manualmente.
    --------------------------------------------------------
    if type(cc_runtime_apply_restored_fixed_map_after_grid_ready) == "function" then
        cc_runtime_apply_restored_fixed_map_after_grid_ready(false)
    end

    active_pos = 1
    param_index = 0

    --------------------------------------------------------
    -- Ripristina ultimo parametro.
    -- La posizione viene cercata nella lista corrente,
    -- quindi funziona sia in Plugin order sia in Custom order.
    --------------------------------------------------------
if not restore_last_param_position() then
    sync_param_from_active_pos()
end

    --------------------------------------------------------
    -- Ripristina l'ultima entrata stabile:
    -- All parameters oppure Group reale.
    -- Search results non è una entrata stabile.
    --------------------------------------------------------
    restore_last_entry_state()

    refresh_window_title()

plugin_default_snapshot_save_current_if_empty()
    save_current_param_position()
    save_current_entry_state()
    save_current_area_state("grid")
    save_plugin_txt_now()

    return true
end

function fx_browser_accept_current()
    local entry = get_fx_browser_current_entry()

    if not select_fx_browser_entry(entry) then
        return false
    end

    if not prepare_selected_fx_for_param_browser() then
        mode = "fx_browser"
        return false
    end

    announce_startup()

    return true
end

function fx_browser_digit(digit)
    digit = tostring(digit or "")

    if digit == "" then
        return false
    end

    local list = get_fx_browser_list()

    if #list <= 0 then
        speak_fx_browser_current()
        return true
    end

    local matches = {}

    for i = 1, #list do
        local number_text = tostring(list[i].number)

        if number_text:sub(1, #digit) == digit then
            matches[#matches + 1] = i
        end
    end

    if #matches <= 0 then
        return true
    end

    if #matches == 1 then
        fx_browser_pos = matches[1]
        fx_browser_accept_current()

        return true
    end

    --------------------------------------------------------
    -- Più corrispondenze: cicla dalla posizione corrente.
    --------------------------------------------------------
    local next_match = matches[1]

    for i = 1, #matches do
        if matches[i] > fx_browser_pos then
            next_match = matches[i]
            break
        end
    end

    fx_browser_pos = next_match

    speak_fx_browser_current()

    return true
end

function fx_browser_cycle_by_initial(letter)
    letter = clean_one_line(letter or ""):lower()

    if letter == "" then
        return false
    end

    local list = get_fx_browser_list()

    if #list <= 0 then
        speak_fx_browser_current()
        return true
    end

    local matches = {}

    for i = 1, #list do
        local entry = list[i]
        local name = strip_fx_prefix(entry.name)

        name = clean_one_line(name):lower()

        if name ~= "" and name:sub(1, 1) == letter then
            matches[#matches + 1] = i
        end
    end

    if #matches <= 0 then
        return true
    end

    --------------------------------------------------------
    -- Cicla dalla posizione corrente.
    -- Se ci sono più FX con la stessa iniziale:
    -- r -> ReaEQ -> ReaGate -> ReaComp...
    --------------------------------------------------------
    local next_match = matches[1]

    for i = 1, #matches do
        if matches[i] > fx_browser_pos then
            next_match = matches[i]
            break
        end
    end

    fx_browser_pos = next_match

    speak_fx_browser_current()

    return true
end

------------------------------------------------------------
-- 5.8 - CAMBIO CONTESTO SENZA USCIRE DALLO SCRIPT
--
-- Usato da CTRL+ALT+frecce.
--
-- Idea:
-- - salva lo stato del plugin corrente;
-- - cambia traccia oppure item;
-- - ricostruisce FX list;
-- - ripristina ultimo FX del nuovo contesto se esiste;
-- - se il nuovo contesto ha più FX e non ha memoria stabile,
--   apre il browser FX;
-- - se ha un solo FX, entra direttamente nella griglia;
-- - se non trova nulla, resta dov'era.
--
-- Master:
-- - non si muove.
--
-- Track mode:
-- - CTRL+ALT+UP/DOWN cambia traccia.
-- - salta le tracce senza FX.
--
-- Take/item mode:
-- - CTRL+ALT+LEFT/RIGHT cambia item sulla stessa traccia.
-- - salta gli item senza Take FX.
------------------------------------------------------------
function context_switch_save_current_state()
    --------------------------------------------------------
    -- Non chiama save_exit_context_memory():
    -- quella memoria anti-stale serve quando lo script esce.
    -- Qui lo script resta aperto e cambia solo contesto.
    --------------------------------------------------------
    if fx_count > 0 then
        save_current_fx_position()
    end

    if param_count > 0 then
        save_current_param_position()
        save_current_entry_state()
    end

    if mode == "fx_browser" then
        save_current_area_state("browser")
    else
        save_current_area_state("grid")
    end

    if type(save_current_plugin_profile_before_switch) == "function" then
        save_current_plugin_profile_before_switch()
    else
        if type(save_plugin_step_grid_to_txt) == "function" then
            save_plugin_step_grid_to_txt()
        end

        if type(save_custom_order_to_txt) == "function" then
            save_custom_order_to_txt()
        end

        save_plugin_txt_now()
    end
end

function context_switch_reset_plugin_runtime_defaults()
    reset_step_scale()
    reset_grid_size()

    grid_size_user_changed = false
    grid_size_auto_default = false

    if type(custom_order_clear_runtime) == "function" then
        custom_order_clear_runtime()
    end

    fx_index = 0
    selected_fx_label = ""
    selected_fx_is_monitor = false
    initial_fx_restored_by_memory = false

    param_count = 0
    param_index = 0
    active_pos = 1

    all_param_indices = {}
    active_param_indices = {}

    search_results = {}
    group_results = {}
    group_selected = {}

    search_active = false
    group_active = false

    clear_group_context()
    clear_param_memory_arm()
    disarm_slot_deletes()
end

function context_switch_load_current_context(prefix)
    prefix = clean_one_line(prefix or "")

    --------------------------------------------------------
    -- Chiude eventuali recinti temporanei:
    -- F7, search, value, numeric edit, Parameter Navigator., ecc.
    -- Questa funzione è stata aggiunta in parte 4.
    --------------------------------------------------------
    if type(prepare_ui_state_for_context_switch) == "function" then
        prepare_ui_state_for_context_switch()
    end

    context_switch_reset_plugin_runtime_defaults()

    build_fx_list_for_current_context()

    if fx_count <= 0 then
        if prefix ~= "" then
            speak(prefix .. ". No FX")
        else
            speak("No FX")
        end

        return false
    end

    --------------------------------------------------------
    -- Fallback pulito: primo FX del nuovo contesto.
    -- restore_initial_fx_selection() potrà poi sovrascriverlo
    -- se trova una memoria valida.
    --------------------------------------------------------
    fx_index = 0
    selected_fx_label = fx_names[1] or ""
    selected_fx_is_monitor = fx_is_monitor[1] == true
    initial_fx_restored_by_memory = false

    --------------------------------------------------------
    -- Ripristina l'ultimo FX del nuovo contesto.
    -- Se non esiste memoria, resta sul primo FX.
    --------------------------------------------------------
    restore_initial_fx_selection()

    build_fx_browser_lists()
    sync_fx_browser_to_current_fx()

    load_plugin_txt_for_selected_fx()

    --------------------------------------------------------
    -- Priorità nuova:
    -- se il TXT del plugin contiene una memoria utile, oppure
    -- l'FX è stato ripristinato con certezza, proviamo la
    -- griglia prima del browser.
    --
    -- In pratica: memoria plugin valida batte LastArea=browser.
    --------------------------------------------------------
    local last_area = restore_last_area_state()
    local has_grid_memory = plugin_txt_has_grid_memory()

    if last_area == "grid" or
       has_grid_memory or
       initial_fx_restored_by_memory then

        if prepare_selected_fx_for_param_browser() then
            announce_startup()
            return true
        end
    end

    --------------------------------------------------------
    -- Solo quando non c'è memoria utile e ci sono più FX,
    -- il browser resta il fallback sicuro.
    --------------------------------------------------------
    if fx_count > 1 then
        enter_fx_browser_mode(prefix, false)
        return true
    end

    if prepare_selected_fx_for_param_browser() then
        announce_startup()
        return true
    end

    return false
end

------------------------------------------------------------
-- 5.8A - HELPERS TRACCE
------------------------------------------------------------
function get_track_zero_index(track)
    if not track then
        return nil
    end

    local n = reaper.GetMediaTrackInfo_Value(track, "IP_TRACKNUMBER")

    n = math.floor(tonumber(n) or 0)

    if n <= 0 then
        return nil
    end

    return n - 1
end

function track_has_normal_fx(track)
    if not track then
        return false
    end

    return get_track_fx_count(track) > 0
end

function select_only_track_for_context_switch(track)
    if not track then
        return false
    end

    if reaper.SetOnlyTrackSelected then
        reaper.SetOnlyTrackSelected(track)
    else
        local count = reaper.CountTracks(0)

        for i = 0, count - 1 do
            local tr = reaper.GetTrack(0, i)

            if tr then
                reaper.SetTrackSelected(tr, tr == track)
            end
        end
    end

    clear_real_item_selection()
    reaper.UpdateArrange()

    return true
end

function find_track_with_fx_by_direction(direction)
    direction = tonumber(direction) or 0

    if direction == 0 then
        return nil
    end

    if not ctx.track or ctx.is_master then
        return nil
    end

    local track_count = reaper.CountTracks(0)

    if track_count <= 0 then
        return nil
    end

    local current_index = get_track_zero_index(ctx.track)

    if current_index == nil then
        return nil
    end

    local i = current_index + direction

    while i >= 0 and i <= track_count - 1 do
        local tr = reaper.GetTrack(0, i)

        if tr and track_has_normal_fx(tr) then
            return tr
        end

        i = i + direction
    end

    return nil
end

function switch_track_context_by_direction(direction)
    direction = tonumber(direction) or 0

    if direction == 0 then
        return false
    end

    --------------------------------------------------------
    -- Master: non fa nulla.
    --------------------------------------------------------
    if ctx.is_master then
        speak("Master")
        return false
    end

    --------------------------------------------------------
    -- Anche se eravamo in item mode, Ctrl+Page Up/Down
    -- deve poter uscire dal contesto item e passare ai Track FX.
    --
    -- Se ctx.track esiste, find_track_with_fx_by_direction()
    -- può partire dalla traccia dell'item corrente.
    --------------------------------------------------------    

    local old_ctx = {
        kind = ctx.kind,
        track = ctx.track,
        take = ctx.take,
        item = ctx.item,
        is_master = ctx.is_master
    }

    local target_track = find_track_with_fx_by_direction(direction)

    if not target_track then
        if direction < 0 then
            speak("No previous track with FX")
        else
            speak("No next track with FX")
        end

        return false
    end

    context_switch_save_current_state()

    if plugin_txt_loaded then
        plugin_txt_unload()
    end

    if not set_context_track(target_track, false) then
        ctx = old_ctx
        speak("Track switch failed")
        return false
    end

    select_only_track_for_context_switch(target_track)

    local prefix = "Track " .. get_track_spoken_label(target_track)

    if not context_switch_load_current_context(prefix) then
        ctx = old_ctx
        return false
    end

    return true
end

function switch_take_context_to_current_track_fx()
    --------------------------------------------------------
    -- Ctrl+W:
    -- se siamo dentro item/take FX, torna ai Track FX della
    -- traccia corrente. Se siamo già nei Track FX, non fa nulla.
    --------------------------------------------------------
    if ctx.kind ~= "take" then
        return false
    end

    local target_track = ctx.track

    if not target_track then
        speak("No track")
        return true
    end

    if not track_has_normal_fx(target_track) then
        speak("Track has no FX")
        return true
    end

    local old_ctx = {
        kind = ctx.kind,
        track = ctx.track,
        take = ctx.take,
        item = ctx.item,
        is_master = ctx.is_master
    }

    context_switch_save_current_state()

    if plugin_txt_loaded then
        plugin_txt_unload()
    end

    if not set_context_track(target_track, false) then
        ctx = old_ctx
        speak("Track switch failed")
        return true
    end

    select_only_track_for_context_switch(target_track)

    local prefix = "Track " .. get_track_spoken_label(target_track)

    if not context_switch_load_current_context(prefix) then
        ctx = old_ctx
        return true
    end

    return true
end

------------------------------------------------------------
-- 5.8B - HELPERS ITEM / TAKE FX
------------------------------------------------------------
function item_has_take_fx(item)
    if not item then
        return false
    end

    local take = reaper.GetActiveTake(item)

    if not take then
        return false
    end

    return get_take_fx_count(take) > 0
end

function get_item_index_on_track(track, item)
    if not track or not item then
        return nil
    end

    local count = reaper.CountTrackMediaItems(track)

    for i = 0, count - 1 do
        local it = reaper.GetTrackMediaItem(track, i)

        if it == item then
            return i
        end
    end

    return nil
end

function find_item_with_take_fx_by_direction(direction)
    direction = tonumber(direction) or 0

    if direction == 0 then
        return nil
    end

    if ctx.kind ~= "take" or not ctx.track or not ctx.item then
        return nil
    end

    local item_count = reaper.CountTrackMediaItems(ctx.track)

    if item_count <= 0 then
        return nil
    end

    local current_index = get_item_index_on_track(ctx.track, ctx.item)

    if current_index == nil then
        return nil
    end

    local i = current_index + direction

    while i >= 0 and i <= item_count - 1 do
        local item = reaper.GetTrackMediaItem(ctx.track, i)

        if item and item_has_take_fx(item) then
            return item
        end

        i = i + direction
    end

    return nil
end

function select_only_item_for_context_switch(item)
    if not item then
        return false
    end

    local track = reaper.GetMediaItemTrack(item)

    if track then
        select_only_track_for_context_switch(track)
    else
        clear_real_item_selection()
    end

    reaper.SetMediaItemSelected(item, true)

    local item_pos = reaper.GetMediaItemInfo_Value(item, "D_POSITION")
    item_pos = tonumber(item_pos) or 0

    reaper.SetEditCurPos(item_pos, true, true)
    reaper.UpdateArrange()

    return true
end

function find_item_with_take_fx_from_track_context(direction)
    direction = tonumber(direction) or 0

    if not ctx.track then
        return nil
    end

    local item_count = reaper.CountTrackMediaItems(ctx.track)

    if item_count <= 0 then
        return nil
    end

    --------------------------------------------------------
    -- Se c'è un item selezionato sulla traccia corrente e ha FX,
    -- entra direttamente in quello. Questo permette di aprire i
    -- take FX dall'interno dello script anche quando il contesto
    -- corrente è Track FX.
    --------------------------------------------------------
    local selected_item = get_first_selected_item_on_track(ctx.track)

    if selected_item and item_has_take_fx(selected_item) then
        return selected_item
    end

    --------------------------------------------------------
    -- Se l'item selezionato non ha FX, cerca il prossimo/precedente
    -- item con FX partendo dalla sua posizione. Se non c'è item
    -- selezionato, parte dall'inizio o dalla fine secondo la freccia.
    --------------------------------------------------------
    local start_index = nil

    if selected_item then
        start_index = get_item_index_on_track(ctx.track, selected_item)
    end

    local i = 0

    if start_index ~= nil then
        i = start_index + direction
    elseif direction < 0 then
        i = item_count - 1
    else
        i = 0
    end

    while i >= 0 and i <= item_count - 1 do
        local item = reaper.GetTrackMediaItem(ctx.track, i)

        if item and item_has_take_fx(item) then
            return item
        end

        i = i + direction
    end

    return nil
end

function switch_item_context_by_direction(direction)
    direction = tonumber(direction) or 0

    if direction == 0 then
        return false
    end

    local old_ctx = {
        kind = ctx.kind,
        track = ctx.track,
        take = ctx.take,
        item = ctx.item,
        is_master = ctx.is_master
    }

    local target_item = nil

    if ctx.kind == "take" then
        target_item = find_item_with_take_fx_by_direction(direction)
    else
        target_item = find_item_with_take_fx_from_track_context(direction)
    end

    if not target_item then
        if ctx.kind ~= "take" then
            speak("No item with FX")
        elseif direction < 0 then
            speak("No previous item with FX")
        else
            speak("No next item with FX")
        end

        return false
    end

    context_switch_save_current_state()

    if plugin_txt_loaded then
        plugin_txt_unload()
    end

    if not set_context_item(target_item) then
        ctx = old_ctx
        speak("Item switch failed")
        return false
    end

    select_only_item_for_context_switch(target_item)

    local prefix = "Item " .. get_take_spoken_label()

    if not context_switch_load_current_context(prefix) then
        ctx = old_ctx
        return false
    end

    return true
end

------------------------------------------------------------
-- FINE PARTE 5 / 8
------------------------------------------------------------

------------------------------------------------------------
-- PARTE 6 / 8
-- USCITA, TASTI FX BROWSER, CONTEGGIO PARAMETRI,
-- RIORDINO FX CATENA, CAMBIO PLUGIN
--
-- Nota:
-- - non salva nulla nel progetto RPP;
-- - prima di uscire/cambiare/spostare FX salva il TXT plugin;
-- - salva sempre Step + Grid + Custom order;
-- - il riordino FX non supporta Monitor FX;
-- - dopo ogni cambio FX ricostruisce lista, profilo TXT,
--   griglia parametri e selezione visiva.
------------------------------------------------------------

------------------------------------------------------------
-- 6.1 - USCITA SCRIPT
------------------------------------------------------------
function exit_script()
    if type(transport_space_release_intercept) == "function" then
        transport_space_release_intercept()
    end

    local exit_already_spoken = false

    if type(plugin_default_snapshot_regenerate_and_exit) == "function" then
        exit_already_spoken = plugin_default_snapshot_regenerate_and_exit()
    end

    save_exit_context_memory()

    if fx_count and fx_count > 0 then
        save_current_fx_position()
    end

    if param_count and param_count > 0 and
       type(param_index_is_valid) == "function" and
       param_index_is_valid(param_index) then

        save_current_param_position()
        save_current_entry_state()
    end

    if mode == "fx_browser" then
        save_current_area_state("browser")
    else
        save_current_area_state("grid")
    end

    if type(save_current_plugin_profile_before_switch) == "function" then
        save_current_plugin_profile_before_switch()
    else
        if type(save_plugin_step_grid_to_txt) == "function" then
            save_plugin_step_grid_to_txt()
        else
            if type(save_plugin_step_scale_to_txt) == "function" then
                save_plugin_step_scale_to_txt()
            end

            if type(save_plugin_grid_size_to_txt) == "function" then
                save_plugin_grid_size_to_txt()
            end
        end

        if type(save_custom_order_to_txt) == "function" then
            save_custom_order_to_txt()
        end

        save_plugin_txt_now()
    end

    if not exit_already_spoken then
        speak("Exit")
    end

    gfx.quit()
end

------------------------------------------------------------
-- 6.2 - TASTI FX BROWSER
------------------------------------------------------------
function handle_fx_browser_key(char)
    local is_ctrl = ctrl_down()
    local is_shift = shift_down()
    local is_alt = alt_down()

    --------------------------------------------------------
    -- CTRL+PAGE UP / CTRL+PAGE DOWN:
    -- cambio traccia anche dal browser FX.
    --
    -- CTRL+PAGE UP   = traccia precedente
    -- CTRL+PAGE DOWN = traccia successiva
    --
    -- Non usa ALT, così ALT+frecce resta libero per il valore
    -- e non dipendiamo da CTRL+ALT+frecce.
    --------------------------------------------------------
    if is_ctrl and not is_shift and not is_alt and char == KEY_PAGE_UP then
        switch_track_context_by_direction(-1)
        return true
    end

    if is_ctrl and not is_shift and not is_alt and char == KEY_PAGE_DOWN then
        switch_track_context_by_direction(1)
        return true
    end

    --------------------------------------------------------
    -- CTRL+LEFT / CTRL+RIGHT:
    -- cambio item/take senza uscire dallo script.
    --------------------------------------------------------
    if is_ctrl and not is_shift and not is_alt and char == KEY_LEFT then
        handle_ctrl_left_right_item_nav(-1)
        return true
    end

    if is_ctrl and not is_shift and not is_alt and char == KEY_RIGHT then
        handle_ctrl_left_right_item_nav(1)
        return true
    end

    --------------------------------------------------------
    -- CTRL+B:
    -- bypass dell'FX selezionato nel browser.
    --------------------------------------------------------
    if is_ctrl and not is_shift and not is_alt and char == KEY_CTRL_B then
        sync_current_fx_to_browser_cursor_silent()

        if type(toggle_current_fx_bypass) == "function" then
            toggle_current_fx_bypass()
        else
            speak("Bypass not available")
        end

        build_fx_browser_lists()
        sync_fx_browser_to_current_fx()

        return true
    end

    --------------------------------------------------------
    -- CTRL+SHIFT+D:
    -- Delta Solo dell'FX evidenziato nel browser.
    --------------------------------------------------------
    if is_ctrl and is_shift and not is_alt and char == KEY_CTRL_D then
        sync_current_fx_to_browser_cursor_silent()

        if type(toggle_delta_solo_last_focused_fx) == "function" then
            toggle_delta_solo_last_focused_fx()
        else
            speak("Delta Solo not available")
        end

        build_fx_browser_lists()
        sync_fx_browser_to_current_fx()

        return true
    end

    --------------------------------------------------------
    -- CTRL+SHIFT+UP / CTRL+SHIFT+DOWN:
    -- sposta fisicamente l'FX nella catena.
    --------------------------------------------------------
    if is_ctrl and is_shift and not is_alt and char == KEY_UP then
        move_current_fx_in_chain(-1)
        return true
    end

    if is_ctrl and is_shift and not is_alt and char == KEY_DOWN then
        move_current_fx_in_chain(1)
        return true
    end

    --------------------------------------------------------
    -- ESC esce sempre.
    --------------------------------------------------------
    if char == KEY_ESC then
        exit_script()
        return true
    end

    --------------------------------------------------------
    -- Lettura posizione corrente nel browser.
    --------------------------------------------------------
    if char == KEY_BACKSLASH then
        speak_fx_browser_current()
        return true
    end

    --------------------------------------------------------
    -- TAB:
    -- legge il plugin corrente nel browser FX.
    --------------------------------------------------------
    if char == KEY_TAB then
        speak_fx_browser_current()
        return true
    end

    --------------------------------------------------------
    -- CTRL+P / ENTER:
    -- entra nel plugin selezionato e torna alla griglia.
    --------------------------------------------------------
    if char == KEY_CTRL_P or char == KEY_ENTER then
        fx_browser_accept_current()
        return true
    end

    --------------------------------------------------------
    -- Navigazione verticale.
    --------------------------------------------------------
    if char == KEY_UP then
        fx_browser_move_vertical(-1)
        return true
    end

    if char == KEY_DOWN then
        fx_browser_move_vertical(1)
        return true
    end

    --------------------------------------------------------
    -- Master: sinistra/destra cambia colonna
    -- Master FX <-> Monitor FX.
    --------------------------------------------------------
    if char == KEY_LEFT then
        fx_browser_switch_col(-1)
        return true
    end

    if char == KEY_RIGHT then
        fx_browser_switch_col(1)
        return true
    end

    --------------------------------------------------------
    -- Page navigation.
    --------------------------------------------------------
    if char == KEY_PAGE_UP then
        fx_browser_page(-1)
        return true
    end

    if char == KEY_PAGE_DOWN then
        fx_browser_page(1)
        return true
    end

    --------------------------------------------------------
    -- Home / End.
    -- Mantiene la tua logica invertita con CTRL.
    --------------------------------------------------------
    if char == KEY_HOME then
        if is_ctrl then
            fx_browser_last()
        else
            fx_browser_first()
        end

        return true
    end

    if char == KEY_END then
        if is_ctrl then
            fx_browser_first()
        else
            fx_browser_last()
        end

        return true
    end

    --------------------------------------------------------
    -- Carattere diretto:
    -- lettere e numeri cercano l'iniziale reale del nome FX.
    --
    -- r = ReaEQ / ReaGate
    -- s = Saturn 2
    -- l = LJuno-116
    -- 8 = 808 Studio / altri FX che iniziano per 8
    --
    -- Se più FX hanno la stessa iniziale, il carattere cicla.
    --------------------------------------------------------
    local c = safe_char(char)

    if c then
        c = c:lower()

        if c:match("[%w]") then
            fx_browser_cycle_by_initial(c)
            return true
        end
    end

    return true
end

------------------------------------------------------------
-- 6.3 - FX PARAM COUNT
------------------------------------------------------------
function get_current_fx_param_count()
    local real_fx = get_current_real_fx_index()

    if real_fx == nil then
        return 0
    end

    if fx_get_offline_for_real_fx(real_fx) == true then
        return 0
    end

    if ctx.kind == "take" then
        if not ctx.take then
            return 0
        end

        return reaper.TakeFX_GetNumParams(ctx.take, real_fx) or 0
    end

    if not ctx.track then
        return 0
    end

    return reaper.TrackFX_GetNumParams(ctx.track, real_fx) or 0
end


------------------------------------------------------------
-- 6.3A - FX PARAM SNAPSHOT SU CLIPBOARD DI SISTEMA
--
-- Ctrl+Alt+Shift+C:
--   copia tutti i parametri NATIVI del plugin corrente.
--
-- Ctrl+V:
--   se gli appunti contengono uno snapshot FX Param valido,
--   lo ripristina. Se non contengono uno snapshot, Ctrl+V
--   continua a fare esattamente quello che faceva prima.
--
-- Sicurezza:
--   prima di scrivere controlla nome plugin, numero parametri
--   e nome di ogni parametro. Nessun paste parziale.
------------------------------------------------------------
FX_PARAM_SNAPSHOT_MAGIC = "FXPARAM_SNAPSHOT_V1"

function fx_snapshot_escape(s)
    s = tostring(s or "")
    s = s:gsub("\\", "\\\\")
    s = s:gsub("\t", "\\t")
    s = s:gsub("\r", "\\r")
    s = s:gsub("\n", "\\n")
    return s
end

function fx_snapshot_unescape(s)
    s = tostring(s or "")

    local out = {}
    local i = 1

    while i <= #s do
        local c = s:sub(i, i)

        if c == "\\" and i < #s then
            local n = s:sub(i + 1, i + 1)

            if n == "t" then
                out[#out + 1] = "\t"
                i = i + 2
            elseif n == "r" then
                out[#out + 1] = "\r"
                i = i + 2
            elseif n == "n" then
                out[#out + 1] = "\n"
                i = i + 2
            elseif n == "\\" then
                out[#out + 1] = "\\"
                i = i + 2
            else
                out[#out + 1] = c
                i = i + 1
            end
        else
            out[#out + 1] = c
            i = i + 1
        end
    end

    return table.concat(out)
end

function fx_snapshot_system_clipboard_set(txt)
    txt = tostring(txt or "")

    if type(reaper.CF_SetClipboard) == "function" then
        local ok = pcall(reaper.CF_SetClipboard, txt)

        if ok then
            return true
        end
    end

    if type(reaper.JS_Window_SetClipboard) == "function" then
        local ok = pcall(reaper.JS_Window_SetClipboard, txt)

        if ok then
            return true
        end
    end

    return false
end

function fx_snapshot_system_clipboard_get()
    if type(reaper.CF_GetClipboard) == "function" then
        local ok, a, b = pcall(reaper.CF_GetClipboard)

        if ok then
            if type(a) == "string" then
                return a
            end

            if type(b) == "string" then
                return b
            end
        end
    end

    if type(reaper.JS_Window_GetClipboard) == "function" then
        local ok, a, b = pcall(reaper.JS_Window_GetClipboard)

        if ok then
            if type(a) == "string" then
                return a
            end

            if type(b) == "string" then
                return b
            end
        end
    end

    return nil
end

function fx_snapshot_native_param_name(i)
    i = math.floor((tonumber(i) or 0) + 0.5)

    local real_fx = get_current_real_fx_index()

    if real_fx == nil then
        return ""
    end

    local ok, retval, name

    if ctx.kind == "take" then
        if not ctx.take or type(reaper.TakeFX_GetParamName) ~= "function" then
            return ""
        end

        ok, retval, name = pcall(
            reaper.TakeFX_GetParamName,
            ctx.take,
            real_fx,
            i,
            ""
        )
    else
        if not ctx.track or type(reaper.TrackFX_GetParamName) ~= "function" then
            return ""
        end

        ok, retval, name = pcall(
            reaper.TrackFX_GetParamName,
            ctx.track,
            real_fx,
            i,
            ""
        )
    end

    if not ok or not retval then
        return ""
    end

    return tostring(name or "")
end

function fx_snapshot_native_param_norm(i)
    i = math.floor((tonumber(i) or 0) + 0.5)

    local real_fx = get_current_real_fx_index()

    if real_fx == nil then
        return nil
    end

    local ok, value

    if ctx.kind == "take" then
        if not ctx.take then
            return nil
        end

        if type(reaper.TakeFX_GetParamNormalized) == "function" then
            ok, value = pcall(
                reaper.TakeFX_GetParamNormalized,
                ctx.take,
                real_fx,
                i
            )

            if ok then
                return clamp01(tonumber(value) or 0)
            end
        end

        if type(reaper.TakeFX_GetParam) == "function" then
            local ok_raw, raw, minval, maxval = pcall(
                reaper.TakeFX_GetParam,
                ctx.take,
                real_fx,
                i
            )

            if ok_raw then
                raw = tonumber(raw) or 0
                minval = tonumber(minval) or 0
                maxval = tonumber(maxval) or 1

                if maxval ~= minval then
                    return clamp01((raw - minval) / (maxval - minval))
                end

                return 0
            end
        end

        return nil
    end

    if not ctx.track then
        return nil
    end

    if type(reaper.TrackFX_GetParamNormalized) == "function" then
        ok, value = pcall(
            reaper.TrackFX_GetParamNormalized,
            ctx.track,
            real_fx,
            i
        )

        if ok then
            return clamp01(tonumber(value) or 0)
        end
    end

    if type(reaper.TrackFX_GetParam) == "function" then
        local ok_raw, raw, minval, maxval = pcall(
            reaper.TrackFX_GetParam,
            ctx.track,
            real_fx,
            i
        )

        if ok_raw then
            raw = tonumber(raw) or 0
            minval = tonumber(minval) or 0
            maxval = tonumber(maxval) or 1

            if maxval ~= minval then
                return clamp01((raw - minval) / (maxval - minval))
            end

            return 0
        end
    end

    return nil
end

function fx_snapshot_native_param_set_norm(i, v)
    i = math.floor((tonumber(i) or 0) + 0.5)
    v = clamp01(v)

    local real_fx = get_current_real_fx_index()

    if real_fx == nil then
        return false
    end

    if ctx.kind == "take" then
        if not ctx.take then
            return false
        end

        if type(reaper.TakeFX_SetParamNormalized) == "function" then
            local ok = pcall(
                reaper.TakeFX_SetParamNormalized,
                ctx.take,
                real_fx,
                i,
                v
            )

            return ok
        end

        if type(reaper.TakeFX_SetParam) == "function" then
            local ok_get, _, minval, maxval = pcall(
                reaper.TakeFX_GetParam,
                ctx.take,
                real_fx,
                i
            )

            if not ok_get then
                return false
            end

            minval = tonumber(minval) or 0
            maxval = tonumber(maxval) or 1

            local raw = minval + (maxval - minval) * v
            return pcall(reaper.TakeFX_SetParam, ctx.take, real_fx, i, raw)
        end

        return false
    end

    if not ctx.track then
        return false
    end

    if type(reaper.TrackFX_SetParamNormalized) == "function" then
        local ok = pcall(
            reaper.TrackFX_SetParamNormalized,
            ctx.track,
            real_fx,
            i,
            v
        )

        return ok
    end

    if type(reaper.TrackFX_SetParam) == "function" then
        local ok_get, _, minval, maxval = pcall(
            reaper.TrackFX_GetParam,
            ctx.track,
            real_fx,
            i
        )

        if not ok_get then
            return false
        end

        minval = tonumber(minval) or 0
        maxval = tonumber(maxval) or 1

        local raw = minval + (maxval - minval) * v
        return pcall(reaper.TrackFX_SetParam, ctx.track, real_fx, i, raw)
    end

    return false
end

function fx_snapshot_build_text()
    local count = get_current_fx_param_count()

    if count <= 0 then
        return nil, 0
    end

    local plugin_raw = clean_one_line(get_fx_raw_label() or "")

    if plugin_raw == "" then
        return nil, 0
    end

    local lines = {
        FX_PARAM_SNAPSHOT_MAGIC,
        "PluginRaw\t" .. fx_snapshot_escape(plugin_raw),
        "ParamCount\t" .. tostring(count)
    }

    for i = 0, count - 1 do
        local value = fx_snapshot_native_param_norm(i)

        if value == nil then
            return nil, 0
        end

        local name = fx_snapshot_native_param_name(i)

        lines[#lines + 1] =
            "P\t" ..
            tostring(i) .. "\t" ..
            string.format("%.17g", value) .. "\t" ..
            fx_snapshot_escape(name)
    end

    return table.concat(lines, "\n"), count
end

function fx_snapshot_copy_all_to_system_clipboard()
    cancel_pending_speech()
    clear_param_memory_arm()
    disarm_slot_deletes()

    local txt, count = fx_snapshot_build_text()

    if not txt then
        speak("No plugin parameters to snapshot")
        return true
    end

    if not fx_snapshot_system_clipboard_set(txt) then
        speak("System clipboard not available")
        return true
    end

    speak(
        "FX snapshot copied. " ..
        clean_one_line(get_fx_label() or get_fx_raw_label() or "FX") ..
        ". " .. tostring(count) .. " parameters"
    )

    return true
end

function fx_snapshot_parse_text(txt)
    txt = tostring(txt or "")

    local first_line = txt:match("^([^\r\n]*)") or ""

    if trim(first_line) ~= FX_PARAM_SNAPSHOT_MAGIC then
        return nil, false, ""
    end

    local snap = {
        plugin_raw = "",
        param_count = nil,
        params = {}
    }

    local line_number = 0

    for line in txt:gmatch("[^\r\n]+") do
        line_number = line_number + 1

        if line_number > 1 then
            local kind, rest = line:match("^([^\t]+)\t(.*)$")

            if kind == "PluginRaw" then
                snap.plugin_raw = fx_snapshot_unescape(rest or "")

            elseif kind == "ParamCount" then
                snap.param_count = tonumber(rest)

            elseif kind == "P" then
                local index_s, value_s, name_s =
                    (rest or ""):match("^([^\t]+)\t([^\t]+)\t(.*)$")

                local index = tonumber(index_s)
                local value = tonumber(value_s)

                if index == nil or value == nil then
                    return nil, true, "Invalid FX snapshot"
                end

                index = math.floor(index + 0.5)

                if snap.params[index] ~= nil then
                    return nil, true, "Invalid FX snapshot"
                end

                snap.params[index] = {
                    value = clamp01(value),
                    name = fx_snapshot_unescape(name_s or "")
                }
            end
        end
    end

    if snap.param_count == nil then
        return nil, true, "Invalid FX snapshot"
    end

    snap.param_count = math.floor((snap.param_count or 0) + 0.5)

    if snap.param_count < 0 or snap.plugin_raw == "" then
        return nil, true, "Invalid FX snapshot"
    end

    for i = 0, snap.param_count - 1 do
        if snap.params[i] == nil then
            return nil, true, "Invalid FX snapshot"
        end
    end

    return snap, true, ""
end

function fx_snapshot_validate_for_current_fx(snap)
    if type(snap) ~= "table" then
        return false, "Invalid FX snapshot"
    end

    local current_plugin = clean_one_line(get_fx_raw_label() or "")
    local saved_plugin = clean_one_line(snap.plugin_raw or "")

    if current_plugin == "" or saved_plugin ~= current_plugin then
        return false, "Snapshot plugin does not match"
    end

    local current_count = get_current_fx_param_count()

    if current_count ~= snap.param_count then
        return false, "Snapshot parameter count does not match"
    end

    for i = 0, current_count - 1 do
        local current_name = fx_snapshot_native_param_name(i)
        local saved_name = tostring(snap.params[i].name or "")

        if current_name ~= saved_name then
            return false,
                "Snapshot parameters do not match at parameter " ..
                tostring(i + 1)
        end
    end

    return true, ""
end

function fx_snapshot_apply(snap)
    local ok_valid, message = fx_snapshot_validate_for_current_fx(snap)

    if not ok_valid then
        speak(message)
        return false
    end

    local count = snap.param_count
    local undo_started = false

    if type(reaper.Undo_BeginBlock2) == "function" then
        reaper.Undo_BeginBlock2(0)
        undo_started = true
    elseif type(reaper.Undo_BeginBlock) == "function" then
        reaper.Undo_BeginBlock()
        undo_started = true
    end

    --------------------------------------------------------
    -- Legge prima lo stato corrente. Se una scrittura dovesse
    -- fallire a metà, prova a rimettere i parametri già toccati
    -- ai valori precedenti, evitando un preset mezzo incollato.
    --------------------------------------------------------
    local previous_values = {}

    for i = 0, count - 1 do
        previous_values[i] = fx_snapshot_native_param_norm(i)

        if previous_values[i] == nil then
            if undo_started then
                if type(reaper.Undo_EndBlock2) == "function" then
                    reaper.Undo_EndBlock2(0, "FX Param: paste full parameter snapshot", -1)
                elseif type(reaper.Undo_EndBlock) == "function" then
                    reaper.Undo_EndBlock("FX Param: paste full parameter snapshot", -1)
                end
            end

            speak("FX snapshot paste cancelled")
            return false
        end
    end

    local written = 0

    for i = 0, count - 1 do
        if fx_snapshot_native_param_set_norm(i, snap.params[i].value) then
            written = written + 1
        else
            for rollback_i = written - 1, 0, -1 do
                fx_snapshot_native_param_set_norm(
                    rollback_i,
                    previous_values[rollback_i]
                )
            end

            break
        end
    end

    if undo_started then
        if type(reaper.Undo_EndBlock2) == "function" then
            reaper.Undo_EndBlock2(0, "FX Param: paste full parameter snapshot", -1)
        elseif type(reaper.Undo_EndBlock) == "function" then
            reaper.Undo_EndBlock("FX Param: paste full parameter snapshot", -1)
        end
    end

    if written ~= count then
        speak(
            "FX snapshot paste stopped after " ..
            tostring(written) .. " of " .. tostring(count) .. " parameters"
        )
        return false
    end

    if type(reaper.TrackList_AdjustWindows) == "function" then
        reaper.TrackList_AdjustWindows(false)
    end

    if type(reaper.UpdateArrange) == "function" then
        reaper.UpdateArrange()
    end

    cancel_pending_speech()

    speak(
        "FX snapshot pasted. " ..
        clean_one_line(get_fx_label() or get_fx_raw_label() or "FX") ..
        ". " .. tostring(count) .. " parameters"
    )

    return true
end

function fx_snapshot_try_paste_from_system_clipboard()
    local txt = fx_snapshot_system_clipboard_get()

    if type(txt) ~= "string" or txt == "" then
        return false
    end

    local snap, recognized, parse_message = fx_snapshot_parse_text(txt)

    if not recognized then
        return false
    end

    cancel_pending_speech()
    clear_param_memory_arm()
    disarm_slot_deletes()

    if not snap then
        speak(parse_message ~= "" and parse_message or "Invalid FX snapshot")
        return true
    end

    fx_snapshot_apply(snap)
    return true
end

------------------------------------------------------------
-- 6.4 - SPOSTAMENTO FX NELLA CATENA
-- CTRL+SHIFT+UP   = sposta FX sopra
-- CTRL+SHIFT+DOWN = sposta FX sotto
--
-- Supportato:
-- - Track FX
-- - Take FX
-- - Master FX normale
--
-- Non supportato:
-- - Monitor FX
------------------------------------------------------------
function get_current_fx_guid()
    local real_fx = get_current_real_fx_index()

    if real_fx == nil then
        return ""
    end

    if ctx.kind == "take" then
        if ctx.take and reaper.TakeFX_GetFXGUID then
            return clean_one_line(
                reaper.TakeFX_GetFXGUID(ctx.take, real_fx) or ""
            )
        end

        return ""
    end

    if ctx.track and reaper.TrackFX_GetFXGUID then
        return clean_one_line(
            reaper.TrackFX_GetFXGUID(ctx.track, real_fx) or ""
        )
    end

    return ""
end

function find_fx_index_by_guid(guid)
    guid = clean_one_line(guid or "")

    if guid == "" then
        return nil
    end

    for i = 1, #fx_real_indices do
        local real_fx = fx_real_indices[i]
        local test_guid = ""

        if ctx.kind == "take" then
            if ctx.take and reaper.TakeFX_GetFXGUID then
                test_guid =
                    clean_one_line(
                        reaper.TakeFX_GetFXGUID(ctx.take, real_fx) or ""
                    )
            end
        else
            if ctx.track and reaper.TrackFX_GetFXGUID then
                test_guid =
                    clean_one_line(
                        reaper.TrackFX_GetFXGUID(ctx.track, real_fx) or ""
                    )
            end
        end

        if test_guid ~= "" and test_guid == guid then
            return i - 1
        end
    end

    return nil
end

function save_current_plugin_before_fx_change()
    if type(save_current_plugin_profile_before_switch) == "function" then
        save_current_plugin_profile_before_switch()
        return
    end

    if type(save_plugin_step_grid_to_txt) == "function" then
        save_plugin_step_grid_to_txt()
    else
        if type(save_plugin_step_scale_to_txt) == "function" then
            save_plugin_step_scale_to_txt()
        end

        if type(save_plugin_grid_size_to_txt) == "function" then
            save_plugin_grid_size_to_txt()
        end
    end

    if type(save_custom_order_to_txt) == "function" then
        save_custom_order_to_txt()
    end

    if type(cc_runtime_save_fixed_map_state_to_txt) == "function" then
        cc_runtime_save_fixed_map_state_to_txt()
    end

    save_plugin_txt_now()
end

function set_selected_fx_by_index(new_fx_index)
    if fx_count <= 0 then
        return false
    end

    new_fx_index = clamp_int(new_fx_index, 0, fx_count - 1)

    fx_index = new_fx_index
    selected_fx_label = fx_names[fx_index + 1] or ""
    selected_fx_is_monitor = fx_is_monitor[fx_index + 1] == true

    return selected_fx_label ~= ""
end

function move_current_fx_in_chain(direction)
    direction = tonumber(direction) or 0

    if direction == 0 then
        return false
    end

    if fx_count <= 1 then
        speak("Only one plugin")
        return false
    end

    if selected_fx_is_monitor then
        speak("Monitor FX not supported")
        return false
    end

    local real_fx = get_current_real_fx_index()

    if real_fx == nil then
        speak("No FX")
        return false
    end

    local chain_count = 0

    if ctx.kind == "take" then
        if not ctx.take then
            speak("No take")
            return false
        end

        chain_count = reaper.TakeFX_GetCount(ctx.take) or 0
    else
        if not ctx.track then
            speak("No track")
            return false
        end

        chain_count = reaper.TrackFX_GetCount(ctx.track) or 0
    end

    if chain_count <= 1 then
        speak("Only one plugin")
        return false
    end

    if direction < 0 and real_fx <= 0 then
        speak("First plugin")
        return false
    end

    if direction > 0 and real_fx >= chain_count - 1 then
        speak("Last plugin")
        return false
    end

    save_current_plugin_before_fx_change()

    clear_param_memory_arm()
    disarm_slot_deletes()
    cancel_pending_speech()

    local old_param_index = param_index
    local was_fx_browser = mode == "fx_browser"
    local old_guid = get_current_fx_guid()

    --------------------------------------------------------
    -- CopyToTrack / CopyToTake in move mode:
    -- per scendere di uno step, la destinazione è +2.
    --------------------------------------------------------
    local dest_fx

    if direction < 0 then
        dest_fx = real_fx - 1
    else
        dest_fx = real_fx + 2
    end

    --------------------------------------------------------
    -- Le API CopyTo* in modalità move non vanno affidate
    -- come booleano: usiamo pcall per evitare stop brutali.
    --------------------------------------------------------
    local ok = false

    if ctx.kind == "take" then
        if not reaper.TakeFX_CopyToTake then
            speak("Move FX not supported")
            return false
        end

        ok = pcall(
            reaper.TakeFX_CopyToTake,
            ctx.take,
            real_fx,
            ctx.take,
            dest_fx,
            true
        )
    else
        if not reaper.TrackFX_CopyToTrack then
            speak("Move FX not supported")
            return false
        end

        ok = pcall(
            reaper.TrackFX_CopyToTrack,
            ctx.track,
            real_fx,
            ctx.track,
            dest_fx,
            true
        )
    end

    if not ok then
        speak("Move FX failed")
        return false
    end

    --------------------------------------------------------
    -- Ricostruisce la lista FX dopo lo spostamento.
    --------------------------------------------------------
    build_fx_list_for_current_context()

    if fx_count <= 0 then
        speak("No FX")
        return false
    end

    --------------------------------------------------------
    -- Primo metodo robusto: ritrova lo stesso FX tramite GUID.
    --------------------------------------------------------
    local new_fx_index = find_fx_index_by_guid(old_guid)

    --------------------------------------------------------
    -- Fallback: posizione prevista.
    --------------------------------------------------------
    if new_fx_index == nil then
        new_fx_index = real_fx + direction
    end

    set_selected_fx_by_index(new_fx_index)
    save_current_fx_position()

    --------------------------------------------------------
    -- Dopo lo spostamento, seleziona visivamente lo stesso FX.
    --------------------------------------------------------
    show_current_fx_for_sighted()
    show_current_fx_for_sighted_later()

    reload_plugin_txt_context()

    build_fx_browser_lists()
    sync_fx_browser_to_current_fx()

    --------------------------------------------------------
    -- Se eri nel browser FX, resta nel browser.
    --------------------------------------------------------
    if was_fx_browser then
        mode = "fx_browser"

        local label =
            get_fx_browser_entry_spoken_label(
                get_fx_browser_current_entry()
            )

        if direction < 0 then
            speak("Moved up. " .. label)
        else
            speak("Moved down. " .. label)
        end

        return true
    end

    --------------------------------------------------------
    -- Se eri nella griglia parametri, resta sullo stesso FX
    -- e prova a tornare allo stesso parametro.
    --------------------------------------------------------
    if current_fx_is_offline() then
        enter_offline_fx_grid(false)

        if direction < 0 then
            speak("Moved up. " .. get_fx_offline_grid_label())
        else
            speak("Moved down. " .. get_fx_offline_grid_label())
        end

        return true
    end

    param_count = get_current_fx_param_count()

    if param_count <= 0 then
        speak("Plugin has no parameters")
        return false
    end

    reset_param_browser_runtime_state()
    build_all_param_indices()

    --------------------------------------------------------
    -- Anche dopo uno spostamento fisico dell'FX,
    -- ReaEQ vergine deve rientrare con Grid 5 in memoria.
    --------------------------------------------------------
    apply_reaeq_default_grid_if_needed()

    if type(load_custom_order_from_txt) == "function" then
        load_custom_order_from_txt()
    end

    if type(apply_custom_order_to_all_params) == "function" then
        apply_custom_order_to_all_params()
    end

    build_all_param_indices()

    --------------------------------------------------------
    -- Ripristina il parametro precedente.
    --
    -- Non clampare brutalmente a 0..param_count-1:
    -- ReaEQ usa anche parametri virtuali negativi
    -- come Band Enabled / Band Type.
    --------------------------------------------------------
    old_param_index = tonumber(old_param_index)

    if old_param_index ~= nil then
        old_param_index = math.floor(old_param_index + 0.5)
    end

    if old_param_index == nil or
       not param_index_is_valid(old_param_index) then

        active_pos = 1
        sync_param_from_active_pos()

    elseif not set_param_index_absolute(old_param_index, false) then

        active_pos = 1
        sync_param_from_active_pos()
    end

    save_current_param_position()
    save_current_entry_state()
    save_current_area_state("grid")
    save_plugin_txt_now()

    refresh_window_title()

    if direction < 0 then
        speak("Moved up. " .. get_fx_label() .. ". " .. get_param_label())
    else
        speak("Moved down. " .. get_fx_label() .. ". " .. get_param_label())
    end

    return true
end

------------------------------------------------------------
------------------------------------------------------------
-- 6.5 - CAMBIO PLUGIN DIRETTO
-- CTRL+UP   = plugin precedente
-- CTRL+DOWN = plugin successivo
------------------------------------------------------------
function restore_fx_after_failed_switch(
    old_fx_index,
    old_label,
    old_is_monitor,
    old_param_count
)
    fx_index = old_fx_index
    selected_fx_label = old_label or ""
    selected_fx_is_monitor = old_is_monitor == true
    param_count = old_param_count or param_count

    reload_plugin_txt_context()
    refresh_window_title()
end

function switch_fx_by_direction(direction)
    direction = tonumber(direction) or 0

    if direction == 0 then
        return false
    end

    if fx_count <= 1 then
        speak("Only one plugin")
        return false
    end

    local new_fx_index = fx_index + direction

    if new_fx_index < 0 then
        speak("First plugin")
        return false
    end

    if new_fx_index > fx_count - 1 then
        speak("Last plugin")
        return false
    end

    save_current_plugin_before_fx_change()

    clear_param_memory_arm()
    disarm_slot_deletes()
    cancel_pending_speech()

    if type(custom_order_clear_runtime) == "function" then
        custom_order_clear_runtime()
    end

    local old_fx_index = fx_index
    local old_selected_fx_label = selected_fx_label
    local old_selected_fx_is_monitor = selected_fx_is_monitor
    local old_param_count = param_count

    set_selected_fx_by_index(new_fx_index)
    save_current_fx_position()
    reload_plugin_txt_context()

    if current_fx_is_offline() then
        enter_offline_fx_grid(false)
        announce_fx_param_short()
        return true
    end

    param_count = get_current_fx_param_count()

    if param_count <= 0 then
        restore_fx_after_failed_switch(
            old_fx_index,
            old_selected_fx_label,
            old_selected_fx_is_monitor,
            old_param_count
        )

        speak("Plugin has no parameters")
        return false
    end

    if not prepare_selected_fx_for_param_browser() then
        restore_fx_after_failed_switch(
            old_fx_index,
            old_selected_fx_label,
            old_selected_fx_is_monitor,
            old_param_count
        )

        return false
    end

    --------------------------------------------------------
    -- Dopo la preparazione della griglia, sincronizza anche
    -- la selezione visiva nella FX chain.
    --------------------------------------------------------
    show_current_fx_for_sighted()
    show_current_fx_for_sighted_later()

    announce_fx_param_short()

    return true
end

------------------------------------------------------------
-- FINE PARTE 6 / 8
------------------------------------------------------------

------------------------------------------------------------
-- PARTE 7 / 8
-- TITOLO FINESTRA, ANNUNCI, AUTOMAZIONE,
-- TOGGLE PRINCIPALI, CAMBIO CONTESTO, INIT SCRIPT
--
-- Nota:
-- - titolo e annunci sono costruiti dallo stato corrente;
-- - lo script usa una finestra gfx piccola/nascosta solo per
--   catturare i tasti;
-- - lo stato persistente principale vive nel TXT del plugin;
-- - non viene più caricato stato dal progetto RPP.
------------------------------------------------------------

------------------------------------------------------------
-- 7.1 - WINDOW TITLE / ANNUNCIO START
------------------------------------------------------------
function get_safe_fx_label()
    local label = get_fx_label()
    label = clean_one_line(label or "")

    if label == "" then
        label = "FX"
    end

    return label
end

function get_track_spoken_label(track)
    if not track then
        return "Track"
    end

    local track_num =
        reaper.GetMediaTrackInfo_Value(
            track,
            "IP_TRACKNUMBER"
        )

    local _, track_name = reaper.GetTrackName(track)

    track_num = math.floor(tonumber(track_num) or 0)
    track_name = clean_one_line(track_name or "")

    if track_name ~= "" then
        return tostring(track_num) .. " " .. track_name
    end

    return tostring(track_num)
end

function get_take_spoken_label()
    if not ctx.take then
        return "Item"
    end

    local _, item_name =
        reaper.GetSetMediaItemTakeInfo_String(
            ctx.take,
            "P_NAME",
            "",
            false
        )

    item_name = clean_one_line(item_name or "")

    if item_name ~= "" then
        return item_name
    end

    return "Item"
end

function get_context_short_label()
    local fx_label = get_safe_fx_label()

    if ctx.is_master then
        if selected_fx_is_monitor then
            return fx_label .. ", Monitor FX"
        end

        return fx_label .. ", Master"
    end

    if ctx.kind == "take" then
        return fx_label .. ", " .. get_take_spoken_label()
    end

    return fx_label .. ", " .. get_track_spoken_label(ctx.track)
end

function build_window_title()
    title = "FX Parameters: " .. get_context_short_label()
end

function refresh_window_title()
    build_window_title()
    gfx.init(title, 1, 1, 0, -32000, -32000)
end


function announce_fx_param_short()
    if fx_offline_grid_active then
        speak(get_fx_offline_grid_label())
        return
    end

    local status_prefix = get_current_fx_status_spoken_prefix()

    local msg =
        status_prefix ..
        get_safe_fx_label() ..
        ". " ..
        get_param_label()

    speak(msg)
end

function announce_startup()
    if parameter_library_startup_message and
       parameter_library_startup_message ~= "" then

        local msg = parameter_library_startup_message
        parameter_library_startup_message = ""
        speak(msg)
        return
    end

    if fx_offline_grid_active then
        speak(get_fx_offline_grid_label())
        return
    end

    --------------------------------------------------------
    -- Se Shift+C è salvato On per questo plugin, all'ingresso
    -- deve parlare un solo messaggio completo della mappa CC.
    -- Evita la sovrapposizione tra annuncio normale e annuncio
    -- di riattivazione dei CC fissi.
    --------------------------------------------------------
    if cc_runtime_fixed_map_enabled == true and
       type(cc_runtime_build_fixed_map_status_message) == "function" then

        speak(cc_runtime_build_fixed_map_status_message(param_index))
        return
    end

    local status_prefix = get_current_fx_status_spoken_prefix()

    local msg =
        status_prefix ..
        get_context_short_label()

    if custom_order_active then
        msg = msg .. ". Custom order"
    end

    msg =
        msg ..
        ". " ..
        get_param_label()

    speak(msg)
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
    -- a leggere i CC MIDI e a salvare il TXT quando è idle.
    --------------------------------------------------------

    if type(plugin_txt_save_deferred_if_idle) == "function" then
        plugin_txt_save_deferred_if_idle()
    end

    if type(transport_space_release_intercept) == "function" then
        transport_space_release_intercept()
    end

    if mode == "cc_learn" and
       type(cc_learn_poll_recent_input) == "function" then

        cc_learn_poll_recent_input()

    elseif cc_runtime_fixed_map_enabled == true and
           type(cc_runtime_poll_recent_input) == "function" then

        ----------------------------------------------------
        -- Anche quando la finestra non ha focus, Shift+C On
        -- deve usare prima i CC fissi del TXT plugin.
        ----------------------------------------------------
        cc_runtime_poll_recent_input()

    elseif (cc_focus_active or cc_focus_waiting) and
           type(cc_focus_poll_recent_input) == "function" then

        cc_focus_poll_recent_input()

    elseif type(cc_runtime_poll_recent_input) == "function" then
        cc_runtime_poll_recent_input()
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

    save_exit_context_memory()

    if fx_count and fx_count > 0 then
        save_current_fx_position()
    end

    if param_count and param_count > 0 and
       type(param_index_is_valid) == "function" and
       param_index_is_valid(param_index) then

        save_current_param_position()
        save_current_entry_state()
    end

    if mode == "fx_browser" then
        save_current_area_state("browser")
    else
        save_current_area_state("grid")
    end

    if type(save_current_plugin_profile_before_switch) == "function" then
        save_current_plugin_profile_before_switch()
    else
        if type(save_plugin_step_grid_to_txt) == "function" then
            save_plugin_step_grid_to_txt()
        end

        if type(save_custom_order_to_txt) == "function" then
            save_custom_order_to_txt()
        end

        save_plugin_txt_now()
    end

    gfx.quit()
end

function open_reaper_fx_browser_window()
    clear_param_memory_arm()
    disarm_slot_deletes()
    cancel_pending_speech()

    reaper.Main_OnCommand(CMD_SHOW_FX_BROWSER, 0)

    close_script_silent_for_external_window()

    return true
end

------------------------------------------------------------
-- 7.1A - PASSAGGIO AL FRATELLO TRACK PARAMS
--
-- Ctrl+Tab:
--   salva lo stato, chiude silenziosamente questo script
--   e richiama Speak Track Params - TrackTake Navigator.lua.
--
-- Si usa AddRemoveReaScript sul file fratello nella stessa
-- cartella, così non serve conoscere l'ID _RS dinamico.
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

function get_sibling_script_path(filename)
    local folder = get_current_script_folder()

    if folder == "" then
        return ""
    end

    local sep = package.config:sub(1, 1)

    return folder .. sep .. filename
end

function get_utility_script_path(filename)
    filename = clean_one_line(filename or "")

    if filename == "" then
        return ""
    end

    local resource = ""

    if reaper.GetResourcePath then
        resource = reaper.GetResourcePath() or ""
    end

    if resource == "" then
        return ""
    end

    local sep = package.config:sub(1, 1)

    return
        resource .. sep ..
        "Scripts" .. sep ..
        "Lo-lo - Scripts" .. sep ..
        "Utility" .. sep ..
        filename
end

function get_utility_scripts_script_path(filename)
    filename = clean_one_line(filename or "")

    if filename == "" then
        return ""
    end

    local resource = ""

    if reaper.GetResourcePath then
        resource = reaper.GetResourcePath() or ""
    end

    if resource == "" then
        return ""
    end

    local sep = package.config:sub(1, 1)

    return
        resource .. sep ..
        "Scripts" .. sep ..
        "Lo-lo - Scripts" .. sep ..
        "Utility" .. sep ..
        "Scripts" .. sep ..
        filename
end

function get_track_params_script_path()
    local filename = "Speak Track Params - TrackTake Navigator.lua"

    --------------------------------------------------------
    -- Prima scelta: file fratello nella stessa cartella dello
    -- script FX. Questa è la logica corretta della suite nuova:
    -- Scripts/Lo-lo - Scripts/Utility/Scripts/
    --------------------------------------------------------
    local sibling_path = get_sibling_script_path(filename)

    if file_exists(sibling_path) then
        return sibling_path
    end

    --------------------------------------------------------
    -- Seconda scelta: cartella nuova esplicita.
    --------------------------------------------------------
    local utility_scripts_path = get_utility_scripts_script_path(filename)

    if file_exists(utility_scripts_path) then
        return utility_scripts_path
    end

    --------------------------------------------------------
    -- Fallback legacy piatto dentro Utility.
    -- La vecchia sottocartella FX non viene più considerata.
    --------------------------------------------------------
    local utility_path = get_utility_script_path(filename)

    if file_exists(utility_path) then
        return utility_path
    end

    return sibling_path ~= "" and sibling_path or utility_scripts_path
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

function switch_to_track_params_script()
    local path = get_track_params_script_path()

    return run_reascript_by_path_silent(path)
end

------------------------------------------------------------
-- 7.1B - PARAMETER LIBRARY BRIDGE
--
-- Dentro F7 Ctrl+Tab apre Parameter Library.lua.
-- Il passaggio usa piccoli TXT temporanei nella nuova cartella
-- Scripts/Params/ e non modifica i profili esistenti Plugins/.
--
-- La Library non modifica direttamente i parametri: quando una
-- cellula viene richiamata, riapre FX Params e questo script
-- applica i valori tramite il proprio motore, inclusi i parametri
-- virtuali/speciali già gestiti da FX Params.
------------------------------------------------------------
PARAMLIB_PACKET_MAGIC = "PARAMLIB_V1"
PARAMLIB_FOLDER_NAME = "Params"
PARAMLIB_HANDOFF_FILE = "_Parameter Library Handoff.txt"
PARAMLIB_RETURN_FILE = "_Parameter Library Return.txt"
parameter_library_startup_message = ""

function paramlib_escape_field(s)
    s = tostring(s or "")
    s = s:gsub("\\", "\\\\")
    s = s:gsub("\t", "\\t")
    s = s:gsub("\r", "\\r")
    s = s:gsub("\n", "\\n")
    return s
end

function paramlib_unescape_field(s)
    s = tostring(s or "")
    local out = ""
    local i = 1

    while i <= #s do
        local c = s:sub(i, i)

        if c == "\\" and i < #s then
            local n = s:sub(i + 1, i + 1)

            if n == "t" then
                out = out .. "\t"
                i = i + 2
            elseif n == "r" then
                out = out .. "\r"
                i = i + 2
            elseif n == "n" then
                out = out .. "\n"
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

function get_parameter_library_folder()
    local folder = get_current_script_folder()

    if folder == "" then
        return ""
    end

    local sep = package.config:sub(1, 1)
    return folder .. sep .. PARAMLIB_FOLDER_NAME
end

function ensure_parameter_library_folder()
    local folder = get_parameter_library_folder()

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

function get_parameter_library_bridge_path(filename)
    local folder = get_parameter_library_folder()

    if folder == "" then
        return ""
    end

    local sep = package.config:sub(1, 1)
    return folder .. sep .. tostring(filename or "")
end

function get_parameter_library_script_path()
    local filename = "Parameter Library.lua"
    local sibling_path = get_sibling_script_path(filename)

    if file_exists(sibling_path) then
        return sibling_path
    end

    local utility_scripts_path = get_utility_scripts_script_path(filename)

    if file_exists(utility_scripts_path) then
        return utility_scripts_path
    end

    return sibling_path ~= "" and sibling_path or utility_scripts_path
end

function paramlib_collect_f7_records()
    local records = {}
    local seen = {}
    local list = get_active_indices() or {}

    for pos = 1, #list do
        local i = tonumber(list[pos])

        if i ~= nil and group_selected[i] and not seen[i] then
            ------------------------------------------------
            -- Compare è un controllo interno di FX Params,
            -- non un parametro reale/virtuale del plugin.
            ------------------------------------------------
            local is_compare =
                fx_compare_param_is_valid and
                fx_compare_param_is_valid(i)

            if not is_compare then
                seen[i] = true

                records[#records + 1] = {
                    index = i,
                    original_name = clean_one_line(get_param_original_name(i) or ""),
                    display_name = clean_one_line(get_param_display_name(i) or ""),
                    norm = tonumber(get_param_value_norm(i)) or 0,
                    formatted = clean_one_line(get_param_value_formatted(i) or "")
                }
            end
        end
    end

    return records
end

function paramlib_write_packet(path, packet)
    path = tostring(path or "")
    packet = packet or {}

    if path == "" then
        return false
    end

    local f = io.open(path, "wb")

    if not f then
        return false
    end

    local records = packet.records or {}

    f:write(PARAMLIB_PACKET_MAGIC, "\r\n")
    f:write("Mode=", paramlib_escape_field(packet.mode or ""), "\r\n")
    f:write("Source=", paramlib_escape_field(packet.source or ""), "\r\n")
    f:write("Plugin=", paramlib_escape_field(packet.plugin or ""), "\r\n")
    f:write("Cell=", paramlib_escape_field(packet.cell or ""), "\r\n")
    f:write("Grid=", tostring(tonumber(packet.grid) or 1), "\r\n")
    f:write("Active=", tostring(tonumber(packet.active) or 0), "\r\n")
    f:write("Count=", tostring(#records), "\r\n")

    for n = 1, #records do
        local r = records[n] or {}
        f:write(
            "P\t",
            tostring(tonumber(r.index) or 0), "\t",
            paramlib_escape_field(r.original_name or ""), "\t",
            paramlib_escape_field(r.display_name or ""), "\t",
            string.format("%.17g", tonumber(r.norm) or 0), "\t",
            paramlib_escape_field(r.formatted or ""),
            "\r\n"
        )
    end

    f:close()
    return true
end

function paramlib_read_packet(path)
    path = tostring(path or "")

    if path == "" then
        return nil
    end

    local f = io.open(path, "rb")

    if not f then
        return nil
    end

    local first = f:read("*l") or ""
    first = first:gsub("\r$", "")

    if first ~= PARAMLIB_PACKET_MAGIC then
        f:close()
        return nil
    end

    local packet = {
        mode = "",
        source = "",
        plugin = "",
        cell = "",
        grid = 1,
        active = 0,
        records = {}
    }

    for line in f:lines() do
        line = tostring(line or ""):gsub("\r$", "")

        if line:sub(1, 2) == "P\t" then
            local index_s, original_name, display_name, norm_s, formatted =
                line:match("^P\t([^\t]*)\t([^\t]*)\t([^\t]*)\t([^\t]*)\t(.*)$")

            local i = tonumber(index_s)
            local norm = tonumber(norm_s)

            if i ~= nil and norm ~= nil then
                packet.records[#packet.records + 1] = {
                    index = i,
                    original_name = paramlib_unescape_field(original_name or ""),
                    display_name = paramlib_unescape_field(display_name or ""),
                    norm = norm,
                    formatted = paramlib_unescape_field(formatted or "")
                }
            end
        else
            local key, value = line:match("^([^=]+)=(.*)$")

            if key then
                value = paramlib_unescape_field(value or "")

                if key == "Mode" then
                    packet.mode = value
                elseif key == "Source" then
                    packet.source = value
                elseif key == "Plugin" then
                    packet.plugin = value
                elseif key == "Cell" then
                    packet.cell = value
                elseif key == "Grid" then
                    packet.grid = tonumber(value) or 1
                elseif key == "Active" then
                    packet.active = tonumber(value) or 0
                end
            end
        end
    end

    f:close()
    return packet
end

function paramlib_can_open_from_current_context()
    --------------------------------------------------------
    -- F8 / Memory Manager non appartiene alla Parameter Library.
    -- Anche i campi di testo, Value e altri recinti temporanei
    -- restano esclusi: F10 è un passaggio fra griglie stabili.
    --------------------------------------------------------
    return mode == "list" or mode == "group_edit"
end

function switch_to_parameter_library_script()
    if not paramlib_can_open_from_current_context() then
        return false
    end

    if not ensure_parameter_library_folder() then
        speak("Parameter Library folder not available")
        return false
    end

    local from_f7 = mode == "group_edit"
    local packet = {
        mode = "open",
        source = from_f7 and "f7" or "grid",
        plugin = get_fx_raw_label(),
        cell = "",
        grid = grid_size,
        active = param_index,
        records = from_f7 and paramlib_collect_f7_records() or {}
    }

    local handoff_path =
        get_parameter_library_bridge_path(PARAMLIB_HANDOFF_FILE)

    if not paramlib_write_packet(handoff_path, packet) then
        speak("Parameter Library handoff failed")
        return false
    end

    --------------------------------------------------------
    -- Il TXT del plugin conserva Plugin/Custom order,
    -- eventuale gruppo e parametro corrente.
    -- F7 aggiunge sopra questa memoria la selezione a isole.
    --------------------------------------------------------
    save_current_param_position()
    save_current_entry_state()
    save_current_area_state("grid")

    if type(save_plugin_txt_now) == "function" then
        save_plugin_txt_now()
    end

    return run_reascript_by_path_silent(get_parameter_library_script_path())
end

function paramlib_apply_return_packet(packet)
    packet = packet or {}

    local wanted_plugin = clean_one_line(packet.plugin or "")
    local current_plugin = clean_one_line(get_fx_raw_label() or "")
    local source = clean_one_line(packet.source or "")
    local from_f7 = source == "f7"

    --------------------------------------------------------
    -- Compatibilità con i pacchetti della prima versione.
    --------------------------------------------------------
    if source == "" and packet.mode == "return" and
       #(packet.records or {}) > 0 then
        from_f7 = true
    end

    if wanted_plugin == "" or wanted_plugin ~= current_plugin then
        parameter_library_startup_message =
            "Parameter Library. Plugin mismatch. Nothing loaded"
        return false
    end

    local selected = {}
    local valid_count = 0
    local skipped_count = 0
    local do_apply = packet.mode == "apply"

    if do_apply and reaper.Undo_BeginBlock then
        reaper.Undo_BeginBlock()
    end

    for n = 1, #(packet.records or {}) do
        local r = packet.records[n] or {}
        local i = tonumber(r.index)
        local stored_name = clean_one_line(r.original_name or "")
        local current_name = ""

        if i ~= nil then
            current_name = clean_one_line(get_param_original_name(i) or "")
        end

        if i ~= nil and stored_name ~= "" and current_name == stored_name then
            if from_f7 then
                selected[i] = true
            end

            valid_count = valid_count + 1

            if do_apply then
                set_param_value_norm(i, tonumber(r.norm) or 0)
            end
        else
            skipped_count = skipped_count + 1
        end
    end

    if do_apply and reaper.Undo_EndBlock then
        local label = clean_one_line(packet.cell or "")

        if label == "" then
            label = "Parameter Library"
        else
            label = "Parameter Library: " .. label
        end

        reaper.Undo_EndBlock(label, -1)
    end

    if from_f7 then
        ----------------------------------------------------
        -- Ritorno speciale F7: ricostruisce le isole.
        ----------------------------------------------------
        group_selected = selected

        if type(save_f7_runtime_selection_for_current_fx) == "function" then
            save_f7_runtime_selection_for_current_fx()
        end

        if mode ~= "group_edit" then
            enter_group_edit_mode()
        end

        if tonumber(packet.active) ~= nil then
            set_param_index_absolute(tonumber(packet.active), false)

            if type(group_edit_reset_path_to_pos) == "function" then
                group_edit_reset_path_to_pos(active_pos)
            end
        end

        if do_apply then
            parameter_library_startup_message =
                "Parameter Library. " ..
                tostring(valid_count) ..
                " parameters loaded" ..
                (skipped_count > 0 and
                    (". " .. tostring(skipped_count) .. " skipped") or "") ..
                ". " ..
                get_current_param_spoken_label()
        else
            parameter_library_startup_message =
                "FX Parameters. F7. " ..
                tostring(valid_count) ..
                " selected. " ..
                get_current_param_spoken_label()
        end

        return true
    end

    --------------------------------------------------------
    -- Ritorno normale:
    -- init_script ha già ricostruito dal TXT Plugin/Custom order,
    -- eventuale gruppo e ultimo parametro. Non entra in F7.
    --------------------------------------------------------
    if tonumber(packet.active) ~= nil then
        set_param_index_absolute(tonumber(packet.active), false)
        save_current_param_position()
    end

    local grid_label = get_grid_label()

    if do_apply then
        parameter_library_startup_message =
            "Parameter Library. " ..
            tostring(valid_count) ..
            " parameters loaded" ..
            (skipped_count > 0 and
                (". " .. tostring(skipped_count) .. " skipped") or "") ..
            ". " ..
            grid_label .. ". " ..
            get_current_param_spoken_label()
    else
        parameter_library_startup_message =
            "FX Parameters. " ..
            grid_label .. ". " ..
            get_current_param_spoken_label()
    end

    return true
end

function paramlib_consume_return_packet()
    local path = get_parameter_library_bridge_path(PARAMLIB_RETURN_FILE)

    if path == "" or not file_exists(path) then
        return false
    end

    local packet = paramlib_read_packet(path)
    os.remove(path)

    if not packet then
        parameter_library_startup_message =
            "Parameter Library return file invalid"
        return false
    end

    return paramlib_apply_return_packet(packet)
end

function ctrl_tab_to_track_params_key(char)
    local is_ctrl = ctrl_down() or js_ctrl_down_now()
    local is_shift = shift_down() or js_shift_down_now()
    local is_alt = alt_down() or js_alt_down_now()

    if not is_ctrl or is_shift or is_alt or char ~= KEY_TAB then
        return false
    end

    --------------------------------------------------------
    -- Con JS_ReaScriptAPI distinguiamo Ctrl+Tab da Ctrl+I,
    -- che in gfx.getchar() può avere lo stesso codice numerico.
    --------------------------------------------------------
    if type(reaper.JS_VKeys_GetState) == "function" then
        return js_vkey_down_now(VK_TAB) and not js_vkey_down_now(VK_I)
    end

    return true
end

------------------------------------------------------------
-- 7.2 - STATO BYPASS FX
--
-- enabled = true  -> plugin attivo
-- enabled = false -> plugin bypassato
--
-- Per il parlato:
-- - se il plugin è attivo, non aggiunge nulla;
-- - se è bypassato, aggiunge "Bypassed".
------------------------------------------------------------
function fx_bool_enabled(v)
    return v == true or tonumber(v) == 1
end

function fx_get_enabled_for_real_fx(real_fx)
    real_fx = tonumber(real_fx)

    if real_fx == nil then
        return nil
    end

    --------------------------------------------------------
    -- TAKE FX
    --------------------------------------------------------
    if ctx.kind == "take" then
        if not ctx.take then
            return nil
        end

        if not reaper.TakeFX_GetEnabled then
            return nil
        end

        return fx_bool_enabled(
            reaper.TakeFX_GetEnabled(ctx.take, real_fx)
        )
    end

    --------------------------------------------------------
    -- TRACK / MASTER / MONITOR FX
    --------------------------------------------------------
    if not ctx.track then
        return nil
    end

    if not reaper.TrackFX_GetEnabled then
        return nil
    end

    return fx_bool_enabled(
        reaper.TrackFX_GetEnabled(ctx.track, real_fx)
    )
end

function fx_set_enabled_for_real_fx(real_fx, enabled)
    real_fx = tonumber(real_fx)

    if real_fx == nil then
        return false
    end

    enabled = enabled == true

    --------------------------------------------------------
    -- TAKE FX
    --------------------------------------------------------
    if ctx.kind == "take" then
        if not ctx.take then
            return false
        end

        if not reaper.TakeFX_SetEnabled then
            return false
        end

        reaper.TakeFX_SetEnabled(ctx.take, real_fx, enabled)
        return true
    end

    --------------------------------------------------------
    -- TRACK / MASTER / MONITOR FX
    --------------------------------------------------------
    if not ctx.track then
        return false
    end

    if not reaper.TrackFX_SetEnabled then
        return false
    end

    reaper.TrackFX_SetEnabled(ctx.track, real_fx, enabled)

    return true
end

function fx_real_fx_is_bypassed(real_fx)
    local enabled = fx_get_enabled_for_real_fx(real_fx)

    if enabled == nil then
        return false
    end

    return not enabled
end

function get_current_fx_bypass_suffix()
    local real_fx = get_current_real_fx_index()

    if real_fx == nil then
        return ""
    end

    if fx_real_fx_is_bypassed(real_fx) then
        return " Bypassed"
    end

    return ""
end

function get_current_fx_bypass_spoken_part()
    local real_fx = get_current_real_fx_index()

    if real_fx == nil then
        return ""
    end

    if fx_real_fx_is_bypassed(real_fx) then
        return "Bypassed."
    end

    return ""
end

------------------------------------------------------------
-- DELTA SOLO STATUS SPEECH
--
-- Il Delta Solo è una funzione globale REAPER legata
-- all'ultimo FX focused. Qui manteniamo anche una piccola
-- memoria runtime, così nel browser FX possiamo parlare
-- "Enabled Delta Solo" solo sull'FX corretto quando lo script
-- lo ha attivato.
------------------------------------------------------------

delta_solo_current_fx_key = delta_solo_current_fx_key or ""

function delta_solo_command_is_enabled()
    if reaper.GetToggleCommandStateEx then
        local state =
            reaper.GetToggleCommandStateEx(
                0,
                CMD_DELTA_SOLO_LAST_FOCUSED_FX
            )

        return tonumber(state) == 1
    end

    if reaper.GetToggleCommandState then
        local state =
            reaper.GetToggleCommandState(
                CMD_DELTA_SOLO_LAST_FOCUSED_FX
            )

        return tonumber(state) == 1
    end

    return false
end

function get_delta_solo_fx_key_for_real_fx(real_fx)
    real_fx = tonumber(real_fx)

    if real_fx == nil then
        return ""
    end

    local ctx_id = "context"

    if type(get_context_storage_id) == "function" then
        ctx_id = get_context_storage_id()
    end

    return
        tostring(ctx_id) ..
        "::delta_solo_fx::" ..
        tostring(real_fx)
end

function get_current_fx_delta_solo_key()
    local real_fx = get_current_real_fx_index()

    if real_fx == nil then
        return ""
    end

    return get_delta_solo_fx_key_for_real_fx(real_fx)
end

function get_fx_browser_entry_delta_solo_key(entry)
    if not entry or not entry.list_index then
        return ""
    end

    local real_fx = fx_real_indices[entry.list_index]

    if real_fx == nil then
        return ""
    end

    return get_delta_solo_fx_key_for_real_fx(real_fx)
end

function delta_solo_key_is_active(key, list_index)
    key = clean_one_line(key or "")

    if key == "" then
        return false
    end

    if not delta_solo_command_is_enabled() then
        return false
    end

    --------------------------------------------------------
    -- Caso normale: lo script sa quale FX ha attivato.
    --------------------------------------------------------
    if delta_solo_current_fx_key ~= "" then
        return delta_solo_current_fx_key == key
    end

    --------------------------------------------------------
    -- Fallback: se REAPER dice che Delta Solo è attivo ma
    -- lo script non ha ancora una memoria runtime, consideriamo
    -- attivo l'FX corrente.
    --------------------------------------------------------
    if list_index ~= nil then
        return list_index == fx_index + 1
    end

    return key == get_current_fx_delta_solo_key()
end

function get_current_fx_delta_solo_spoken_part()
    local key = get_current_fx_delta_solo_key()

    if delta_solo_key_is_active(key, nil) then
        return "Enabled Delta Solo."
    end

    return ""
end

function get_fx_browser_entry_delta_solo_spoken_part(entry)
    local key = get_fx_browser_entry_delta_solo_key(entry)

    if delta_solo_key_is_active(key, entry and entry.list_index or nil) then
        return "Enabled Delta Solo."
    end

    return ""
end

function get_current_fx_status_spoken_prefix()
    local delta_solo = get_current_fx_delta_solo_spoken_part()
    local bypass = get_current_fx_bypass_spoken_part()
    local msg = ""

    if delta_solo ~= "" then
        msg = msg .. delta_solo .. " "
    end

    if bypass ~= "" then
        msg = msg .. bypass .. " "
    end

    return msg
end

function get_fx_browser_entry_bypass_suffix(entry)
    if not entry or not entry.list_index then
        return ""
    end

    local real_fx = fx_real_indices[entry.list_index]

    if real_fx == nil then
        return ""
    end

    if fx_real_fx_is_bypassed(real_fx) then
        return " Bypassed"
    end

    return ""
end

function toggle_real_fx_bypass(real_fx)
    local enabled = fx_get_enabled_for_real_fx(real_fx)

    if enabled == nil then
        return nil
    end

    local new_enabled = not enabled

    if not fx_set_enabled_for_real_fx(real_fx, new_enabled) then
        return nil
    end

    return new_enabled
end

function toggle_delta_solo_last_focused_fx()
    clear_param_memory_arm()
    disarm_slot_deletes()
    cancel_pending_speech()

    --------------------------------------------------------
    -- Se siamo nel browser FX, prima sincronizza l'FX
    -- evidenziato, così Delta Solo riguarda quello.
    --------------------------------------------------------
    if mode == "fx_browser" then
        sync_current_fx_to_browser_cursor_silent()
    end

    local key = get_current_fx_delta_solo_key()

    reaper.Main_OnCommand(CMD_DELTA_SOLO_LAST_FOCUSED_FX, 0)

    if delta_solo_command_is_enabled() then
        delta_solo_current_fx_key = key

        if mode == "fx_browser" then
            speak_fx_browser_current()
        else
            speak("Enabled Delta Solo. " .. get_safe_fx_label())
        end
    else
        delta_solo_current_fx_key = ""

        if mode == "fx_browser" then
            speak_fx_browser_current()
        else
            speak("Disabled Delta Solo. " .. get_safe_fx_label())
        end
    end

    return true
end

------------------------------------------------------------
-- 7.3 - CTRL+B
-- Toggle bypass del plugin corrente.
--
-- Funziona su:
-- - Track FX
-- - Master FX
-- - Monitor FX
-- - Take FX
--
-- Nota:
-- REAPER usa "enabled".
-- enabled = true  -> plugin attivo
-- enabled = false -> plugin bypassato
------------------------------------------------------------
function toggle_current_fx_bypass()
    clear_param_memory_arm()
    disarm_slot_deletes()
    cancel_pending_speech()

    local real_fx = get_current_real_fx_index()

    if real_fx == nil then
        speak("No FX")
        return false
    end

    local old_enabled = fx_get_enabled_for_real_fx(real_fx)

    if old_enabled == nil then
        speak("Bypass not supported")
        return false
    end

    local new_enabled = toggle_real_fx_bypass(real_fx)

    if new_enabled == nil then
        speak("Bypass not supported")
        return false
    end

    --------------------------------------------------------
    -- Nel browser FX:
    -- parla come la lista, con eventuale prefisso Bypassed.
    --------------------------------------------------------
    if mode == "fx_browser" then
        speak_fx_browser_current()
        return true
    end

    --------------------------------------------------------
    -- Nella griglia parametri:
    -- messaggio diretto di toggle.
    --------------------------------------------------------
    if old_enabled then
        speak("Bypass on. " .. get_safe_fx_label())
    else
        speak("Bypass off. " .. get_safe_fx_label())
    end

    return true
end

function toggle_fx_browser_entry_bypass()
    clear_param_memory_arm()
    disarm_slot_deletes()
    cancel_pending_speech()

    local entry = get_fx_browser_current_entry()

    if not entry then
        speak("No FX")
        return false
    end

    local real_fx = fx_real_indices[entry.list_index]

    if real_fx == nil then
        speak("No FX")
        return false
    end

    local new_enabled = toggle_real_fx_bypass(real_fx)

    if new_enabled == nil then
        speak("Bypass not supported")
        return false
    end

    speak_fx_browser_current()

    return true
end

------------------------------------------------------------
-- 7.3B - CC LEARN RAPIDO PARAMETRO
--
-- Ctrl+Alt+C:
--   apre una modalità interna di learn.
--
-- La modalità usa MIDI_GetRecentInputEvent per intercettare
-- l'ultimo CC ricevuto globalmente da REAPER.
--
-- Il primo CC nuovo:
--   viene catturato e scritto automaticamente sul parametro corrente
--   usando anche param.X.learn.midi1 quando disponibile.
--
-- Enter:
--   non fa nulla.
------------------------------------------------------------
function cc_param_is_real_fx_param(i)
    i = tonumber(i)

    if i == nil then
        return false
    end

    return i >= 0 and i <= param_count - 1
end

function cc_learn_param_is_supported(i)
    i = tonumber(i)

    if i == nil then
        return false
    end

    --------------------------------------------------------
    -- Compare:
    -- parametro virtuale dello script. Non è learnable dal
    -- sistema nativo di REAPER, ma può essere controllato dal
    -- runtime CC interno, come i parametri reali.
    --------------------------------------------------------
    if type(fx_compare_param_is_valid) == "function" and
       fx_compare_param_is_valid(i) then

        return true
    end

    --------------------------------------------------------
    -- Pseudo-parametri ReaEQ:
    -- Band Enabled / Band Type.
    -- Non sono learnable da REAPER, ma sono controllabili
    -- dal runtime CC interno dello script.
    --------------------------------------------------------
    if type(reaeq_virtual_param_is_valid) == "function" and
       reaeq_virtual_param_is_valid(i) then

        return true
    end

    --------------------------------------------------------
    -- Parametri reali normali.
    --------------------------------------------------------
    return cc_param_is_real_fx_param(i)
end

function cc_learn_get_param_key(i, suffix)
    i = tonumber(i) or 0
    suffix = tostring(suffix or "")

    return "param." .. tostring(i) .. ".learn." .. suffix
end

function cc_link_get_param_key(i)
    i = tonumber(i) or 0

    return CC_LINK_PREFIX .. tostring(i)
end

function cc_link_make_text(channel, cc)
    channel = clamp_int(channel, 1, 16)
    cc = clamp_int(cc, 0, 127)

    return tostring(channel) .. "\t" .. tostring(cc)
end

function cc_link_parse_text(txt)
    txt = tostring(txt or "")

    local ch_s, cc_s = txt:match("^(%d+)%s*\t%s*(%d+)$")

    local channel = tonumber(ch_s)
    local cc = tonumber(cc_s)

    if channel == nil or cc == nil then
        return nil, nil
    end

    channel = clamp_int(channel, 1, 16)
    cc = clamp_int(cc, 0, 127)

    return channel, cc
end

------------------------------------------------------------
-- CC RUNTIME LINK CACHE
--
-- Evita di scandire tutto plugin_txt_data.extra a ogni evento CC.
-- La cache è solo runtime:
-- - viene ricostruita dal TXT quando serve;
-- - viene invalidata quando un CC viene salvato/rimosso;
-- - non viene salvata su disco.
------------------------------------------------------------

cc_runtime_link_cache_dirty = true
cc_runtime_links_by_cc = {}

function cc_runtime_make_cc_cache_key(channel, cc)
    channel = clamp_int(channel, 1, 16)
    cc = clamp_int(cc, 0, 127)

    return tostring(channel) .. "::" .. tostring(cc)
end

function cc_runtime_mark_link_cache_dirty()
    cc_runtime_link_cache_dirty = true
end

function cc_runtime_clear_link_cache()
    cc_runtime_links_by_cc = {}
    cc_runtime_link_cache_dirty = true
end

function cc_runtime_rebuild_link_cache()
    cc_runtime_links_by_cc = {}

    if not plugin_storage_available() then
        cc_runtime_link_cache_dirty = false
        return false
    end

    if not plugin_txt_data or not plugin_txt_data.extra then
        cc_runtime_link_cache_dirty = false
        return false
    end

    local prefix_pattern =
        "^" ..
        CC_LINK_PREFIX:gsub("([%.%-%+%*%?%[%]%^%$%(%)%%])", "%%%1") ..
        "(%-?%d+)$"

    for key, txt in pairs(plugin_txt_data.extra or {}) do
        key = tostring(key or "")

        local index_s = key:match(prefix_pattern)
        local param_i = tonumber(index_s)

        if param_i ~= nil and cc_learn_param_is_supported(param_i) then
            local saved_channel, saved_cc = cc_link_parse_text(txt)

            if saved_channel ~= nil and saved_cc ~= nil then
                local cache_key =
                    cc_runtime_make_cc_cache_key(saved_channel, saved_cc)

                if cc_runtime_links_by_cc[cache_key] == nil then
                    cc_runtime_links_by_cc[cache_key] = {}
                end

                cc_runtime_links_by_cc[cache_key][#cc_runtime_links_by_cc[cache_key] + 1] =
                    param_i
            end
        end
    end

    cc_runtime_link_cache_dirty = false

    return true
end

function cc_runtime_get_linked_params_for_cc(channel, cc)
    if cc_runtime_link_cache_dirty then
        cc_runtime_rebuild_link_cache()
    end

    local cache_key = cc_runtime_make_cc_cache_key(channel, cc)

    return cc_runtime_links_by_cc[cache_key] or {}
end


function cc_runtime_count_linked_params()
    if cc_runtime_link_cache_dirty then
        cc_runtime_rebuild_link_cache()
    end

    local count = 0

    for _, list in pairs(cc_runtime_links_by_cc or {}) do
        if type(list) == "table" then
            count = count + #list
        end
    end

    return count
end

function cc_runtime_get_link_for_param(i)
    i = tonumber(i)

    if i == nil then
        return nil, nil
    end

    if not plugin_storage_available() then
        return nil, nil
    end

    local txt = get_plugin_state_safe(
        cc_link_get_param_key(i)
    )

    return cc_link_parse_text(txt)
end

function cc_runtime_get_first_linked_param()
    if cc_runtime_link_cache_dirty then
        cc_runtime_rebuild_link_cache()
    end

    local best_param = nil
    local best_channel = nil
    local best_cc = nil

    for cache_key, list in pairs(cc_runtime_links_by_cc or {}) do
        if type(list) == "table" and #list > 0 then
            local ch_s, cc_s = tostring(cache_key or ""):match("^(%d+)::(%d+)$")
            local channel = tonumber(ch_s)
            local cc = tonumber(cc_s)

            for n = 1, #list do
                local p = tonumber(list[n])

                if p ~= nil and
                   (best_param == nil or p < best_param) then

                    best_param = p
                    best_channel = channel
                    best_cc = cc
                end
            end
        end
    end

    return best_param, best_channel, best_cc
end

function cc_runtime_build_fixed_map_status_message(prefer_param_index)
    if cc_runtime_link_cache_dirty then
        cc_runtime_rebuild_link_cache()
    end

    local count = cc_runtime_count_linked_params()
    local msg = "Fixed CC map on"

    if count <= 0 then
        return msg .. ". No linked parameters"
    end

    if count == 1 then
        msg = msg .. ". 1 parameter"
    else
        msg = msg .. ". " .. tostring(count) .. " parameters"
    end

    local param_i = tonumber(prefer_param_index)
    local channel = nil
    local cc = nil

    if param_i ~= nil then
        channel, cc = cc_runtime_get_link_for_param(param_i)
    end

    if channel == nil or cc == nil then
        param_i, channel, cc = cc_runtime_get_first_linked_param()
    end

    if param_i ~= nil then
        local name = ""
        local value = ""

        if type(get_param_display_name) == "function" then
            name = clean_one_line(get_param_display_name(param_i))
        elseif type(get_param_name) == "function" then
            name = clean_one_line(get_param_name(param_i))
        end

        if name == "" then
            name = "Parameter " .. tostring(param_i + 1)
        end

        if type(get_param_value_formatted) == "function" then
            value = clean_one_line(get_param_value_formatted(param_i))
        end

        if value ~= "" then
            msg = msg .. ". " .. name .. " " .. value
        else
            msg = msg .. ". " .. name
        end
    end

    if channel ~= nil and cc ~= nil then
        msg = msg ..
            ". CC channel " .. tostring(channel) ..
            " CC " .. tostring(cc)
    end

    return msg
end

function cc_runtime_get_recent_seq()
    if not reaper.MIDI_GetRecentInputEvent then
        return 0
    end

    local ok, seq =
        pcall(reaper.MIDI_GetRecentInputEvent, 0)

    if ok then
        return tonumber(seq) or 0
    end

    return 0
end

function cc_runtime_save_fixed_map_state_to_txt()
    if not plugin_storage_available() then
        return false
    end

    set_plugin_state_safe(
        CC_RUNTIME_FIXED_MAP_ENABLED_KEY,
        cc_runtime_fixed_map_enabled and "1" or ""
    )

    plugin_txt_save_if_dirty(true)

    return true
end

function cc_runtime_restore_fixed_map_state_from_txt()
    cc_runtime_fixed_map_enabled = false
    cc_runtime_clear_all_pickup()
    cc_runtime_last_seq = cc_runtime_get_recent_seq()

    if not plugin_storage_available() then
        return false
    end

    local saved =
        get_plugin_state_safe(
            CC_RUNTIME_FIXED_MAP_ENABLED_KEY
        )

    if tostring(saved or "") ~= "1" then
        return false
    end

    --------------------------------------------------------
    -- Ripristino silenzioso: non parla e non riscrive il TXT.
    -- Se il plugin non ha più una mappa CC valida, resta off
    -- senza sporcare il profilo.
    --------------------------------------------------------
    return cc_runtime_set_fixed_map_enabled(true, false, false)
end

function cc_runtime_set_fixed_map_enabled(enabled, speak_it, save_to_txt)
    enabled = enabled == true

    if enabled then
        if not plugin_storage_available() then
            cc_runtime_fixed_map_enabled = false

            if save_to_txt ~= false then
                cc_runtime_save_fixed_map_state_to_txt()
            end

            if speak_it then
                speak("No plugin profile")
            end

            return false
        end

        cc_runtime_mark_link_cache_dirty()
        cc_runtime_rebuild_link_cache()

        local count = cc_runtime_count_linked_params()

        ----------------------------------------------------
        -- Non forzare più Shift+C a Off quando in questo
        -- momento la cache dei CC risulta vuota.
        --
        -- Prima qui lo script rimetteva subito
        -- cc_runtime_fixed_map_enabled = false se count <= 0.
        -- Questo impediva proprio di memorizzare lo stato On
        -- nel TXT del plugin, specialmente durante caricamenti,
        -- cambio FX o cache non ancora ricostruita.
        --
        -- Ora Shift+C è uno stato del plugin: può restare On
        -- e viene salvato nel TXT. Se non ci sono CC fissi
        -- mappati, semplicemente non muove nulla finché non
        -- esistono link validi.
        ----------------------------------------------------

        ----------------------------------------------------
        -- La mappa fissa e il Floating CC sono due modalità
        -- alternative. Shift+C riporta il controllo ai CC
        -- fissi salvati nel TXT senza usare Ctrl+C.
        ----------------------------------------------------
        if type(cc_focus_clear) == "function" then
            cc_focus_clear()
        else
            cc_focus_active = false
            cc_focus_waiting = false
        end

        ----------------------------------------------------
        -- Importante:
        -- quando Shift+C riattiva i CC fissi del plugin,
        -- deve spegnere anche la memoria volatile del
        -- Floating CC. Altrimenti, alla riapertura dello
        -- script, il polling può restare agganciato al
        -- Floating CC e i CC fissi risultano On ma non
        -- muovono nulla finché non fai Off/On a mano.
        ----------------------------------------------------
        if type(cc_focus_clear_session_memory) == "function" then
            cc_focus_clear_session_memory()
        end

        cc_runtime_fixed_map_enabled = true
        cc_runtime_clear_all_pickup()
        cc_runtime_last_seq = cc_runtime_get_recent_seq()

        if save_to_txt ~= false then
            cc_runtime_save_fixed_map_state_to_txt()
        end

        if speak_it then
            if type(cc_runtime_build_fixed_map_status_message) == "function" then
                speak(cc_runtime_build_fixed_map_status_message(param_index))
            elseif count <= 0 then
                speak("Fixed CC map on. No linked parameters")
            elseif count == 1 then
                speak("Fixed CC map on. 1 parameter")
            else
                speak("Fixed CC map on. " .. tostring(count) .. " parameters")
            end
        end

        return true
    end

    cc_runtime_fixed_map_enabled = false
    cc_runtime_clear_all_pickup()
    cc_runtime_last_seq = cc_runtime_get_recent_seq()

    if save_to_txt ~= false then
        cc_runtime_save_fixed_map_state_to_txt()
    end

    if speak_it then
        speak("Fixed CC map off")
    end

    return true
end

function cc_runtime_toggle_fixed_map()
    return cc_runtime_set_fixed_map_enabled(
        not cc_runtime_fixed_map_enabled,
        true
    )
end

function cc_runtime_apply_restored_fixed_map_after_grid_ready(speak_it)
    --------------------------------------------------------
    -- Ripristino forte dopo la preparazione della griglia.
    --
    -- All'apertura il TXT del plugin può essere letto prima
    -- che param_count e la lista parametri siano davvero pronti.
    -- In quel caso Shift+C risultava On, ma la cache runtime
    -- dei CC fissi veniva costruita vuota e poi non veniva più
    -- ricostruita.
    --
    -- Questa funzione va chiamata quando la griglia è pronta:
    -- rilegge lo stato salvato nel TXT e, se è On, esegue la
    -- stessa accensione completa del tasto Shift+C manuale.
    --------------------------------------------------------
    if not plugin_storage_available() then
        return false
    end

    local saved = get_plugin_state_safe(
        CC_RUNTIME_FIXED_MAP_ENABLED_KEY
    )

    if tostring(saved or "") ~= "1" then
        cc_runtime_fixed_map_enabled = false
        cc_runtime_clear_all_pickup()
        cc_runtime_mark_link_cache_dirty()
        return false
    end

    cc_runtime_mark_link_cache_dirty()

    return cc_runtime_set_fixed_map_enabled(
        true,
        speak_it == true,
        false
    )
end


function cc_link_save_for_param(i, channel, cc)
    i = tonumber(i)

    if i == nil then
        return false
    end

    if not cc_learn_param_is_supported(i) then
        return false
    end

    set_plugin_state_safe(
        cc_link_get_param_key(i),
        cc_link_make_text(channel, cc)
    )

plugin_txt_save_if_dirty(true)

if type(cc_runtime_clear_pickup_for_param) == "function" then
    cc_runtime_clear_pickup_for_param(i)
end

if type(cc_runtime_mark_link_cache_dirty) == "function" then
    cc_runtime_mark_link_cache_dirty()
end

return true
end

function cc_link_remove_for_param(i)
    i = tonumber(i)

    if i == nil then
        return false
    end

    set_plugin_state_safe(
        cc_link_get_param_key(i),
        ""
    )

plugin_txt_save_if_dirty(true)

if type(cc_runtime_clear_pickup_for_param) == "function" then
    cc_runtime_clear_pickup_for_param(i)
end

if type(cc_runtime_mark_link_cache_dirty) == "function" then
    cc_runtime_mark_link_cache_dirty()
end

return true
end

function cc_link_find_same_cc_on_other_params(target_i, channel, cc)
    target_i = tonumber(target_i)

    local found = {}

    if target_i == nil then
        return found
    end

    if not plugin_storage_available() then
        return found
    end

    if not plugin_txt_data or not plugin_txt_data.extra then
        return found
    end

    channel = clamp_int(channel, 1, 16)
    cc = clamp_int(cc, 0, 127)

    local prefix_pattern =
        "^" ..
        CC_LINK_PREFIX:gsub("([%.%-%+%*%?%[%]%^%$%(%)%%])", "%%%1") ..
        "(%-?%d+)$"

    for key, txt in pairs(plugin_txt_data.extra or {}) do
        key = tostring(key or "")

        local index_s = key:match(prefix_pattern)
        local param_i = tonumber(index_s)

        if param_i ~= nil and param_i ~= target_i then
            local saved_channel, saved_cc = cc_link_parse_text(txt)

            if saved_channel == channel and saved_cc == cc then
                found[#found + 1] = param_i
            end
        end
    end

    return found
end

function cc_link_remove_same_cc_from_other_params(target_i, channel, cc)
    target_i = tonumber(target_i)

    if target_i == nil then
        return 0
    end

    if not plugin_storage_available() then
        return 0
    end

    if not plugin_txt_data or not plugin_txt_data.extra then
        return 0
    end

    channel = clamp_int(channel, 1, 16)
    cc = clamp_int(cc, 0, 127)

    local removed = 0
    local prefix_pattern =
        "^" ..
        CC_LINK_PREFIX:gsub("([%.%-%+%*%?%[%]%^%$%(%)%%])", "%%%1") ..
        "(%-?%d+)$"

    for key, txt in pairs(plugin_txt_data.extra or {}) do
        key = tostring(key or "")

        local index_s = key:match(prefix_pattern)
        local param_i = tonumber(index_s)

        if param_i ~= nil and param_i ~= target_i then
            local saved_channel, saved_cc = cc_link_parse_text(txt)

            if saved_channel == channel and saved_cc == cc then
                ------------------------------------------------
                -- Rimuove il link interno dello script.
                ------------------------------------------------
                plugin_txt_data.extra[key] = ""
                plugin_txt_mark_dirty()

if type(cc_runtime_mark_link_cache_dirty) == "function" then
    cc_runtime_mark_link_cache_dirty()
end

if type(cc_runtime_clear_pickup_for_param) == "function" then
    cc_runtime_clear_pickup_for_param(param_i)
end

                ------------------------------------------------
                -- Rimuove anche il learn nativo REAPER dal
                -- vecchio parametro, altrimenti REAPER potrebbe
                -- continuare a controllarlo comunque.
                ------------------------------------------------
                if cc_param_is_real_fx_param(param_i) and
                   type(fx_set_named_config_parm) == "function" and
                   type(cc_learn_get_param_key) == "function" then

                    fx_set_named_config_parm(
                        cc_learn_get_param_key(param_i, "midi1"),
                        ""
                    )

                    fx_set_named_config_parm(
                        cc_learn_get_param_key(param_i, "midi2"),
                        ""
                    )

                    fx_set_named_config_parm(
                        cc_learn_get_param_key(param_i, "osc"),
                        ""
                    )
                end

                removed = removed + 1
            end
        end
    end

    return removed
end

function cc_runtime_decode_cc_buffer(buf)
    buf = tostring(buf or "")

    if #buf < 3 then
        return nil, nil, nil, nil
    end

    local status = buf:byte(1) or 0
    local data1  = buf:byte(2) or 0
    local data2  = buf:byte(3) or 0

    --------------------------------------------------------
    -- MIDI CC:
    -- status 0xB0 ... 0xBF
    -- data1 = CC number
    -- data2 = value 0..127
    --------------------------------------------------------
    if math.floor(status / 16) ~= 0x0B then
        return nil, nil, nil, nil
    end

    local channel = (status % 16) + 1
    local cc = clamp_int(data1, 0, 127)
    local value = clamp_int(data2, 0, 127)

    return channel, cc, value, status
end

------------------------------------------------------------
-- CC SPEECH PER PARAMETRO
--
-- Ctrl+T non è più un toggle globale.
--
-- Ora Ctrl+T abilita/disabilita il parlato CC solo per
-- il parametro corrente e salva lo stato nel TXT del plugin.
--
-- Default:
-- - nessun parametro parla quando viene mosso da CC.
--
-- Nel TXT plugin:
-- - ogni parametro abilitato viene salvato in [Extra]
--   con chiave cc_param_speech_v1::<param_index> = 1
------------------------------------------------------------

CC_PARAM_SPEECH_PREFIX =
    CC_PARAM_SPEECH_PREFIX or "cc_param_speech_v1::"

function cc_param_speech_get_key(i)
    i = tonumber(i)

    if i == nil then
        i = 0
    end

    i = math.floor(i + 0.5)

    return CC_PARAM_SPEECH_PREFIX .. tostring(i)
end

function cc_param_speech_is_supported(i)
    i = tonumber(i)

    if i == nil then
        return false
    end

    --------------------------------------------------------
    -- Compare virtuale:
    -- Compare non è un parametro REAPER reale, ma è un
    -- metaparametro valido dello script.
    -- Quindi deve poter usare anche Ctrl+T per il parlato CC.
    --------------------------------------------------------
    if type(fx_compare_param_is_valid) == "function" and
       fx_compare_param_is_valid(i) then

        return true
    end

    --------------------------------------------------------
    -- ReaEQ virtual params:
    -- Band Enabled e Band Type non sono parametri classici,
    -- ma sono parametri validi dello script.
    -- Quindi possono avere Ctrl+T memorizzato nel TXT.
    --------------------------------------------------------
    if type(reaeq_virtual_param_is_valid) == "function" and
       reaeq_virtual_param_is_valid(i) then

        return true
    end

    --------------------------------------------------------
    -- Parametri reali normali.
    --------------------------------------------------------
    if i < 0 or i > param_count - 1 then
        return false
    end

    if type(param_index_is_valid) == "function" then
        return param_index_is_valid(i)
    end

    return true
end

function cc_param_speech_is_enabled(i)
    if not plugin_storage_available() then
        return false
    end

    if not cc_param_speech_is_supported(i) then
        return false
    end

    local value =
        get_plugin_state_safe(
            cc_param_speech_get_key(i)
        )

    return tostring(value or "") == "1"
end

function cc_param_speech_set_enabled(i, enabled)
    if not plugin_storage_available() then
        return false
    end

    if not cc_param_speech_is_supported(i) then
        return false
    end

    if enabled then
        set_plugin_state_safe(
            cc_param_speech_get_key(i),
            "1"
        )
    else
        ----------------------------------------------------
        -- Valore vuoto:
        -- non parla e rimane compatibile con il tuo sistema
        -- Extra/TXT già esistente.
        ----------------------------------------------------
        set_plugin_state_safe(
            cc_param_speech_get_key(i),
            ""
        )
    end

    plugin_txt_save_if_dirty(true)

    return true
end

function save_cc_combo_speech_to_txt()
    --------------------------------------------------------
    -- Compatibilità:
    -- la vecchia funzione resta presente, ma non salva più
    -- un toggle globale.
    --------------------------------------------------------
    if plugin_txt_loaded then
        plugin_txt_save_if_dirty(true)
        return true
    end

    return false
end

function restore_cc_combo_speech_from_txt()
    --------------------------------------------------------
    -- Non c'è più uno stato globale da ripristinare.
    -- Le preferenze vengono lette direttamente dal TXT
    -- parametro per parametro.
    --------------------------------------------------------
    cc_combo_speak_enabled = false
    cc_combo_speak_last_value_by_param = {}

    return plugin_txt_loaded == true
end

function toggle_cc_combo_speech()
    clear_param_memory_arm()
    disarm_slot_deletes()
    cancel_pending_speech()

    if not cc_param_speech_is_supported(param_index) then
        speak("CC speech not available")
        return false
    end

    if not plugin_storage_available() then
        speak("Plugin TXT not available")
        return false
    end

    local old_enabled = cc_param_speech_is_enabled(param_index)
    local new_enabled = not old_enabled

    cc_param_speech_set_enabled(param_index, new_enabled)

    --------------------------------------------------------
    -- Azzera la cache delle ultime label parlate.
    -- Così quando riattivi il parametro, la prima variazione
    -- utile viene letta.
    --------------------------------------------------------
    cc_combo_speak_last_value_by_param = {}

    local name = clean_one_line(get_param_display_name(param_index))

    if name == "" then
        name = "Parameter"
    end

    if new_enabled then
        speak("CC speech on. " .. name)
    else
        speak("CC speech off. " .. name)
    end

    return true
end

function cc_combo_speak_strip_positive_plus(msg)
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

function cc_combo_speak_send(msg)
    msg = cc_combo_speak_strip_positive_plus(msg or "")

    if msg == "" then
        return
    end

    if type(speak_later) == "function" then
        speak_later(msg)
    else
        speak(msg)
    end
end

function cc_combo_speak_make_key(i)
    local real_fx = get_current_real_fx_index()

    return
        tostring(real_fx or fx_index or 0) ..
        "::" ..
        tostring(i)
end

function cc_param_should_speak_combo(i, formatted_value)
    --------------------------------------------------------
    -- Nuova logica:
    -- non tenta più di indovinare se il parametro è combo,
    -- continuo, finto slider, frequenza, gain, ecc.
    --
    -- Parla solo se l'utente ha abilitato quel parametro
    -- con Ctrl+T.
    --------------------------------------------------------
    if not cc_param_speech_is_enabled(i) then
        return false
    end

    formatted_value = clean_one_line(formatted_value or "")

    if formatted_value == "" then
        return false
    end

    return true
end

function cc_combo_speak_after_value_change(i, before_fmt, after_fmt)
    before_fmt = clean_one_line(before_fmt or "")
    after_fmt = clean_one_line(after_fmt or "")

    if after_fmt == "" then
        return false
    end

    if before_fmt == after_fmt then
        return false
    end

    if not cc_param_should_speak_combo(i, after_fmt) then
        return false
    end

    local key = cc_combo_speak_make_key(i)

    --------------------------------------------------------
    -- Parla solo quando il valore formattato cambia davvero.
    --------------------------------------------------------
    if cc_combo_speak_last_value_by_param[key] == after_fmt then
        return false
    end

    cc_combo_speak_last_value_by_param[key] = after_fmt

    if i == param_index then
        cc_combo_speak_send(after_fmt)
    else
        cc_combo_speak_send(
            get_param_display_name(i) ..
            " " ..
            after_fmt
        )
    end

    return true
end

function cc_runtime_apply_to_learned_params(channel, cc, value)
    if cc_runtime_busy then
        return false
    end

    if not plugin_storage_available() then
        return false
    end

    channel = clamp_int(channel, 1, 16)
    cc = clamp_int(cc, 0, 127)
    value = clamp_int(value, 0, 127)

    local linked_params =
        cc_runtime_get_linked_params_for_cc(channel, cc)

    if #linked_params <= 0 then
        return false
    end

    local norm = clamp01(value / 127)
    local changed = false

    cc_runtime_busy = true

    for n = 1, #linked_params do
        local param_i = tonumber(linked_params[n])

        if param_i ~= nil and cc_learn_param_is_supported(param_i) then
            ------------------------------------------------
            -- Soft takeover / pickup:
            -- il CC fisso non muove il parametro finché
            -- non raggiunge o attraversa il valore reale
            -- corrente dello slider.
            ------------------------------------------------
            if cc_runtime_pickup_allows_value(param_i, norm) then
                if type(cc_runtime_should_ignore_jitter_for_param) == "function" and
                   cc_runtime_should_ignore_jitter_for_param(param_i, value) then

                    -- piccolo rimbalzo MIDI: ignora senza parlare
                else
                    local before_fmt = get_param_value_formatted(param_i)

                    if cc_control_set_param_norm(param_i, norm) then
                    cc_runtime_pickup_mark_param_applied(param_i, norm)

                    local after_fmt = get_param_value_formatted(param_i)

                    if type(cc_combo_speak_after_value_change) == "function" then
                        cc_combo_speak_after_value_change(
                            param_i,
                            before_fmt,
                            after_fmt
                        )
                    end

                        changed = true
                    end
                end
            end
        end
    end

    cc_runtime_busy = false

    if changed then
        save_current_param_position()
    end

    return changed
end

function cc_runtime_poll_recent_input()
    if mode == "cc_learn" then
        return false
    end

    if cc_runtime_fixed_map_enabled ~= true then
        return false
    end

    if not reaper.MIDI_GetRecentInputEvent then
        return false
    end

    local ok, seq, buf =
        pcall(reaper.MIDI_GetRecentInputEvent, 0)

    if not ok then
        return false
    end

    seq = tonumber(seq) or 0

    if seq == 0 then
        return false
    end

    if seq == cc_runtime_last_seq then
        return false
    end

    cc_runtime_last_seq = seq

    local channel, cc, value =
        cc_runtime_decode_cc_buffer(buf)

    if channel == nil then
        return false
    end

    return cc_runtime_apply_to_learned_params(channel, cc, value)
end

------------------------------------------------------------
-- FLOATING CC MODE
------------------------------------------------------------

function cc_focus_get_current_recent_seq()
    if not reaper.MIDI_GetRecentInputEvent then
        return 0
    end

    local ok, seq =
        pcall(reaper.MIDI_GetRecentInputEvent, 0)

    if ok then
        return tonumber(seq) or 0
    end

    return 0
end

function cc_focus_clear()
    cc_focus_active = false
    cc_focus_waiting = false

    cc_focus_channel = nil
    cc_focus_cc = nil
    cc_focus_value = nil
    cc_focus_status_byte = nil

cc_focus_clear_pickup()
end

function cc_focus_target_is_allowed()
    if edit_mode then
        return false
    end

    if mode == "fx_browser" or
       mode == "search_edit" or
       mode == "name_edit" or
       mode == "group_name_edit" or
       mode == "recent" or
       mode == "memory_manager" or
       mode == "cc_learn" then

        return false
    end

    return true
end

function cc_focus_pickup_crossed_target(old_norm, new_norm, target_norm)
    old_norm = tonumber(old_norm)
    new_norm = tonumber(new_norm)
    target_norm = tonumber(target_norm)

    if new_norm == nil or target_norm == nil then
        return false
    end

    local eps = 1 / 127

    --------------------------------------------------------
    -- Se il controller è praticamente sul valore del parametro,
    -- aggancia subito.
    --------------------------------------------------------
    if math.abs(new_norm - target_norm) <= eps then
        return true
    end

    --------------------------------------------------------
    -- Se non abbiamo un valore precedente, non possiamo ancora
    -- sapere se abbiamo attraversato il target.
    --------------------------------------------------------
    if old_norm == nil then
        return false
    end

    --------------------------------------------------------
    -- Attraversamento dal basso verso l'alto.
    --------------------------------------------------------
    if old_norm < target_norm and new_norm >= target_norm then
        return true
    end

    --------------------------------------------------------
    -- Attraversamento dall'alto verso il basso.
    --------------------------------------------------------
    if old_norm > target_norm and new_norm <= target_norm then
        return true
    end

    return false
end

------------------------------------------------------------
-- FLOATING CC: ARMA PICKUP SUL PARAMETRO CORRENTE
--
-- Quando cambia parametro, il target deve diventare il valore
-- reale del nuovo parametro, e la memoria del movimento
-- precedente deve essere azzerata.
------------------------------------------------------------
function cc_focus_arm_pickup_for_current_param(force)
    if not cc_focus_active then
        return false
    end

    if cc_focus_waiting then
        return false
    end

    if not param_index_is_valid or
       not param_index_is_valid(param_index) then

        cc_focus_pickup_active = false
        cc_focus_pickup_target_norm = nil
        cc_focus_pickup_last_norm = nil
        cc_focus_pickup_param_index = nil

        return false
    end

    --------------------------------------------------------
    -- IMPORTANTISSIMO:
    -- Se siamo già sullo stesso parametro, non riarmare.
    --
    -- Altrimenti, quando il CC modifica il valore,
    -- save_current_param_position() richiama questa funzione
    -- e il pickup viene rimesso in attesa continuamente.
    --------------------------------------------------------
    if force ~= true and
       cc_focus_pickup_param_index == param_index and
       cc_focus_pickup_target_norm ~= nil then

        return false
    end

    cc_focus_pickup_param_index = param_index
    cc_focus_pickup_target_norm = cc_control_get_param_norm_for_pickup(param_index)
    cc_focus_pickup_last_norm = nil
    cc_focus_pickup_active = true

    return true
end

function cc_focus_apply_to_current_param(value)
    if not cc_focus_target_is_allowed() then
        return false
    end

    if not param_index_is_valid(param_index) then
        return false
    end

    value = clamp_int(value, 0, 127)

    if type(cc_runtime_should_ignore_jitter_for_param) == "function" and
       cc_runtime_should_ignore_jitter_for_param(param_index, value) then

        return false
    end

    local norm = clamp01(value / 127)

    --------------------------------------------------------
    -- Se cambio parametro mentre il Floating CC è attivo,
    -- il pickup si riarma sul valore reale del nuovo parametro.
    --
    -- Fix importante:
    -- quando cambia parametro, il vecchio valore fisico del CC
    -- NON deve essere usato per calcolare l'attraversamento.
    -- Altrimenti il pickup resta legato al parametro precedente.
    --------------------------------------------------------
    if cc_focus_pickup_param_index ~= param_index or
       cc_focus_pickup_target_norm == nil then

        cc_focus_pickup_param_index = param_index
        cc_focus_pickup_target_norm = cc_control_get_param_norm_for_pickup(param_index)
        cc_focus_pickup_last_norm = nil
        cc_focus_pickup_active = true
    end

    local old_norm = cc_focus_pickup_last_norm
    local target_norm = cc_focus_pickup_target_norm

    cc_focus_pickup_last_norm = norm

    --------------------------------------------------------
    -- Soft takeover:
    -- finché il CC fisico non tocca o attraversa il valore
    -- reale del parametro corrente, non muove niente.
    --------------------------------------------------------
    if cc_focus_pickup_active then
        if not cc_focus_pickup_crossed_target(
            old_norm,
            norm,
            target_norm
        ) then
            return false
        end

        cc_focus_pickup_active = false
    end

local before_fmt = get_param_value_formatted(param_index)

cc_control_set_param_norm(param_index, norm)

if type(cc_combo_speak_after_value_change) == "function" then
    cc_combo_speak_after_value_change(
        param_index,
        before_fmt,
        get_param_value_formatted(param_index)
    )
end

    save_current_param_position()

    return true
end

function cc_focus_capture_from_midi_buffer(buf)
    local channel, cc, value, status =
        cc_runtime_decode_cc_buffer(buf)

    if channel == nil then
        return false
    end

    cc_focus_channel = channel
    cc_focus_cc = cc
    cc_focus_value = value
    cc_focus_status_byte = status

    cc_focus_waiting = false
    cc_focus_active = true

    --------------------------------------------------------
    -- Pickup iniziale:
    -- il primo CC catturato definisce il controller fisico,
    -- ma non deve fare saltare subito il parametro.
    --------------------------------------------------------
    cc_focus_pickup_param_index = param_index
    cc_focus_pickup_target_norm = nil

    if param_index_is_valid(param_index) then
        cc_focus_pickup_target_norm = get_param_value_norm(param_index)
    end

    cc_focus_pickup_last_norm = clamp01(value / 127)
    cc_focus_pickup_active = true

    --------------------------------------------------------
    -- Se per caso il controller è già sul valore reale,
    -- aggancia subito senza salto.
    --------------------------------------------------------
    if cc_focus_pickup_target_norm ~= nil and
       cc_focus_pickup_crossed_target(
           nil,
           cc_focus_pickup_last_norm,
           cc_focus_pickup_target_norm
       ) then

        cc_focus_pickup_active = false
        cc_focus_apply_to_current_param(value)
    end

    cc_focus_save_session_memory()    

    local param_name = ""

    if param_index_is_valid(param_index) then
        param_name = clean_one_line(get_param_display_name(param_index))
    end

    if param_name ~= "" then
        speak(
            "Floating CC. Channel " ..
            tostring(channel) ..
            " CC " ..
            tostring(cc) ..
            ". " ..
            param_name
        )
    else
        speak(
            "Floating CC. Channel " ..
            tostring(channel) ..
            " CC " ..
            tostring(cc)
        )
    end

    return true
end

function cc_focus_poll_recent_input()
    if not cc_focus_active and not cc_focus_waiting then
        return false
    end

    if not reaper.MIDI_GetRecentInputEvent then
        return false
    end

    local ok, seq, buf =
        pcall(reaper.MIDI_GetRecentInputEvent, 0)

    if not ok then
        return false
    end

    seq = tonumber(seq) or 0

    if seq == 0 then
        return false
    end

    if seq == cc_focus_last_seq then
        return false
    end

    cc_focus_last_seq = seq
    cc_runtime_last_seq = seq

    local channel, cc, value =
        cc_runtime_decode_cc_buffer(buf)

    if channel == nil then
        return false
    end

    --------------------------------------------------------
    -- Primo CC nuovo dopo Ctrl+Shift+C:
    -- viene catturato come Floating CC.
    --------------------------------------------------------
    if cc_focus_waiting then
        return cc_focus_capture_from_midi_buffer(buf)
    end

    --------------------------------------------------------
    -- Floating CC già attivo:
    -- risponde solo al CC catturato.
    --------------------------------------------------------
    if cc_focus_active and
       channel == cc_focus_channel and
       cc == cc_focus_cc then

        cc_focus_value = value
        cc_focus_apply_to_current_param(value)

        return true
    end

    return false
end

function toggle_cc_focus_mode()
    clear_param_memory_arm()
    disarm_slot_deletes()
    cancel_pending_speech()

    --------------------------------------------------------
    -- Se è già attivo o in attesa, lo spegne.
    -- I CC normali salvati nel TXT tornano subito operativi.
    --------------------------------------------------------
    if cc_focus_active or cc_focus_waiting then
        cc_focus_clear()
        cc_focus_clear_session_memory()

        speak("Floating CC off. Normal CC mappings")
        return true
    end

    if not reaper.MIDI_GetRecentInputEvent then
        speak("MIDI input history not available")
        return false
    end

    --------------------------------------------------------
    -- Avvia il Floating CC pulito.
    --------------------------------------------------------
    cc_focus_clear()
    cc_focus_clear_session_memory()

    cc_focus_waiting = true

    cc_focus_last_seq = cc_focus_get_current_recent_seq()
    cc_runtime_last_seq = cc_focus_last_seq

    speak("Floating CC. Move a MIDI control")

    return true
end

function cc_learn_get_current_recent_seq()
    if not reaper.MIDI_GetRecentInputEvent then
        return 0
    end

    local ok, retval =
        pcall(reaper.MIDI_GetRecentInputEvent, 0)

    if ok then
        return tonumber(retval) or 0
    end

    return 0
end

function cc_learn_clear_capture()
    cc_learn_captured = false
    cc_learn_channel = nil
    cc_learn_cc = nil
    cc_learn_value = nil
    cc_learn_status_byte = nil
end

function disarm_cc_learn_mode()
    local i = cc_learn_target_param_index
    local label = ""

    if i ~= nil and param_index_is_valid(i) then
        label = get_param_label_for_index(i)
    end

    if label == "" then
        local name = clean_one_line(cc_learn_target_param_name)

        if name ~= "" then
            label = name
        end
    end

    mode = cc_learn_return_mode or "list"

    cc_learn_target_param_index = nil
    cc_learn_target_param_name = ""
    cc_learn_clear_capture()

    if label ~= "" then
        speak("CC learn disarmed. " .. label)
    else
        speak("CC learn disarmed")
    end

    return true
end

function cc_learn_capture_from_midi_buffer(buf)
    local channel, cc, value, status =
        cc_runtime_decode_cc_buffer(buf)

    if channel == nil then
        return false
    end

    cc_learn_status_byte = status
    cc_learn_channel = channel
    cc_learn_cc = cc
    cc_learn_value = value
    cc_learn_captured = true

    return true
end

function cc_learn_poll_recent_input()
    if mode ~= "cc_learn" then
        return false
    end

    if not reaper.MIDI_GetRecentInputEvent then
        return false
    end

    local ok, seq, buf =
        pcall(reaper.MIDI_GetRecentInputEvent, 0)

    if not ok then
        return false
    end

    seq = tonumber(seq) or 0

    if seq == 0 then
        return false
    end

    --------------------------------------------------------
    -- Protezione importante:
    -- ignora tutto ciò che era già presente quando Ctrl+Alt+C
    -- ha armato il learn.
    --------------------------------------------------------
    if seq == cc_learn_last_seq then
        return false
    end

    cc_learn_last_seq = seq
    cc_runtime_last_seq = seq

    --------------------------------------------------------
    -- One-shot learn:
    -- il primo CC nuovo viene catturato, assegnato subito,
    -- e la modalità CC Learn si chiude automaticamente.
    --------------------------------------------------------
    if cc_learn_capture_from_midi_buffer(buf) then
        cc_learn_apply_to_param()
        return true
    end

    return false
end

function cc_learn_read_current()
    if cc_learn_captured then
        speak(
            "CC learn. Channel " ..
            tostring(cc_learn_channel) ..
            " CC " ..
            tostring(cc_learn_cc) ..
            " value " ..
            tostring(cc_learn_value)
        )

        return true
    end

    speak("CC learn. Move a MIDI control")
    return true
end


function cc_learn_apply_to_param()
    if cc_learn_target_param_index == nil then
        speak("No parameter")
        return false
    end

    if not cc_learn_param_is_supported(cc_learn_target_param_index) then
        speak("CC learn not available")
        return false
    end

    if not cc_learn_captured or
       cc_learn_status_byte == nil or
       cc_learn_cc == nil then

        speak("No CC captured")
        return false
    end

    local i = cc_learn_target_param_index

    local duplicate_params =
        cc_link_find_same_cc_on_other_params(
            i,
            cc_learn_channel,
            cc_learn_cc
        )

    local removed_duplicates =
        cc_link_remove_same_cc_from_other_params(
            i,
            cc_learn_channel,
            cc_learn_cc
        )

    cc_link_save_for_param(
        i,
        cc_learn_channel,
        cc_learn_cc
    )

    --------------------------------------------------------
    
    --------------------------------------------------------
    -- Soft takeover reale:
    -- non scriviamo più il MIDI learn nativo di REAPER,
    -- perché REAPER potrebbe muovere il parametro subito,
    -- prima che il pickup interno dello script abbia agganciato
    -- il valore nominale dello slider.
    --
    -- Il CC fisso viene gestito solo dal runtime interno
    -- tramite il link salvato nel TXT plugin.
    --------------------------------------------------------
    --------------------------------------------------------
    -- Soft takeover reale:
    -- per i parametri reali puliamo anche l'eventuale learn
    -- nativo REAPER.
    --
    -- Per i pseudo-parametri ReaEQ non usiamo learn nativo:
    -- restano gestiti solo dal runtime interno dello script.
    --------------------------------------------------------
    if cc_param_is_real_fx_param(i) then
        fx_set_named_config_parm(
            cc_learn_get_param_key(i, "midi1"),
            ""
        )

        fx_set_named_config_parm(
            cc_learn_get_param_key(i, "midi2"),
            ""
        )

        fx_set_named_config_parm(
            cc_learn_get_param_key(i, "osc"),
            ""
        )

        fx_set_named_config_parm(
            "param." .. tostring(i) .. ".learn.mode",
            "0"
        )

        fx_set_named_config_parm(
            "param." .. tostring(i) .. ".learn.flags",
            "0"
        )
    end    

    --------------------------------------------------------
    -- Importantissimo:
    -- dopo il learn non muovere il parametro al valore attuale
    -- del CC. Il primo movimento utile dovrà passare dal pickup.
    --------------------------------------------------------
    if type(cc_runtime_clear_pickup_for_param) == "function" then
        cc_runtime_clear_pickup_for_param(i)
    end

    mode = cc_learn_return_mode or "list"

    local name = clean_one_line(cc_learn_target_param_name)

    if name == "" then
        name = get_param_display_name(i)
    end

    local msg =
        "Learned. Channel " ..
        tostring(cc_learn_channel) ..
        " CC " ..
        tostring(cc_learn_cc) ..
        ". "

    if removed_duplicates > 0 then
        if removed_duplicates == 1 then
            local old_i = duplicate_params[1]
            local old_name = ""

            if old_i ~= nil then
                old_name = clean_one_line(get_param_display_name(old_i))
            end

            if old_name ~= "" then
                msg =
                    msg ..
                    "Moved from " ..
                    old_name ..
                    ". "
            else
                msg =
                    msg ..
                    "Removed from one other parameter. "
            end
        else
            msg =
                msg ..
                "Removed from " ..
                tostring(removed_duplicates) ..
                " other parameters. "
        end
    end

    msg = msg .. name

    speak(msg)

    cc_learn_target_param_index = nil
    cc_learn_target_param_name = ""
    cc_learn_clear_capture()

    return true
end

function cc_learn_param_has_assignment(i)
    i = tonumber(i)

    if i == nil then
        return false
    end

    --------------------------------------------------------
    -- Il CC Learn dello script è salvato solo nel TXT plugin.
    --
    -- Importante:
    -- non controlliamo più i param.X.learn.midi1/midi2/osc
    -- nativi di REAPER per decidere il messaggio, perché molti
    -- plugin/REAPER possono restituire valori non vuoti anche
    -- quando non esiste un learn CC gestito dallo script.
    --
    -- Così Delete dice "CC learn removed" solo se esiste davvero
    -- un link interno salvato dal nostro sistema CC.
    --------------------------------------------------------
    local txt = ""

    if type(get_plugin_state_safe) == "function" and
       type(cc_link_get_param_key) == "function" then

        txt = get_plugin_state_safe(cc_link_get_param_key(i))
    end

    if type(cc_link_parse_text) == "function" then
        local channel, cc = cc_link_parse_text(txt)

        return channel ~= nil and cc ~= nil
    end

    return trim(txt or "") ~= ""
end

function cc_learn_remove_from_param()
    local i = cc_learn_target_param_index

    if i == nil then
        i = param_index
    end

    if not cc_learn_param_is_supported(i) then
        speak("CC learn not available")
        return false
    end

    local name = clean_one_line(cc_learn_target_param_name)

    if name == "" then
        name = get_param_display_name(i)
    end

    local had_assignment = cc_learn_param_has_assignment(i)

    mode = cc_learn_return_mode or "list"

    cc_learn_target_param_index = nil
    cc_learn_target_param_name = ""
    cc_learn_clear_capture()

    if not had_assignment then
        speak("No CC learn. " .. name)
        return false
    end

    --------------------------------------------------------
    -- Rimuove il link interno dello script.
    --------------------------------------------------------
    cc_link_remove_for_param(i)

    --------------------------------------------------------
    -- Per i parametri reali rimuove anche il learn nativo
    -- REAPER. Per i pseudo-parametri basta rimuovere il link
    -- interno dello script.
    --------------------------------------------------------
    if cc_param_is_real_fx_param(i) then
        fx_set_named_config_parm(
            cc_learn_get_param_key(i, "midi1"),
            ""
        )

        fx_set_named_config_parm(
            cc_learn_get_param_key(i, "midi2"),
            ""
        )

        fx_set_named_config_parm(
            cc_learn_get_param_key(i, "osc"),
            ""
        )
    end

    speak("CC learn removed. " .. name)

    return true
end

function start_cc_learn_mode()
    if mode == "cc_learn" then
        return disarm_cc_learn_mode()
    end

    clear_param_memory_arm()
    disarm_slot_deletes()
    cancel_pending_speech()

    --------------------------------------------------------
    -- Ctrl+Alt+C deve riportare il lavoro sui CC fissi.
    -- Se il Floating CC è attivo o in attesa, lo spegne solo
    -- nello stato runtime corrente, senza toccare la memoria
    -- di sessione e senza cambiare il comportamento normale
    -- di Ctrl+Shift+C.
    --------------------------------------------------------
    if cc_focus_active or cc_focus_waiting then
        cc_focus_clear()
    end

    if mode == "fx_browser" then
        speak("No parameter")
        return false
    end

    if edit_mode or
       mode == "search_edit" or
       mode == "name_edit" or
       mode == "group_name_edit" or
       mode == "recent" or
       mode == "memory_manager" then

        speak("Return to parameter grid first")
        return false
    end

    if not param_index_is_valid(param_index) then
        speak("No parameter")
        return false
    end

    if not cc_learn_param_is_supported(param_index) then
        speak("CC learn not available")
        return false
    end

    if not reaper.MIDI_GetRecentInputEvent then
        speak("MIDI input history not available")
        return false
    end

    cc_learn_return_mode = mode or "list"
    cc_learn_target_param_index = param_index
    cc_learn_target_param_name = get_param_display_name(param_index)

    cc_learn_clear_capture()

    --------------------------------------------------------
    -- Aggancia lo stato MIDI attuale, così non prende un CC
    -- vecchio appena entrati nel campo.
    --------------------------------------------------------
    cc_learn_last_seq = cc_learn_get_current_recent_seq()
    cc_runtime_last_seq = cc_learn_last_seq

    mode = "cc_learn"

    speak("CC learn. Move a MIDI control")

    return true
end

function handle_cc_learn_key(char)
    if mode ~= "cc_learn" then
        return false
    end

    local is_ctrl = ctrl_down()
    local is_shift = shift_down()
    local is_alt = alt_down()

    --------------------------------------------------------
    -- Esc oppure Ctrl+Alt+C mentre il learn è armato:
    -- disarma e torna al punto di partenza, senza uscire
    -- dallo script.
    --------------------------------------------------------
    if char == KEY_ESC then
        disarm_cc_learn_mode()
        return true
    end

    if is_ctrl and not is_shift and is_alt and
       (char == KEY_CTRL_C or char == KEY_CTRL_ALT_C) then

        disarm_cc_learn_mode()
        return true
    end

    --------------------------------------------------------
    -- Tab / backslash:
    -- legge lo stato del learn.
    --------------------------------------------------------
    if char == KEY_TAB or char == KEY_BACKSLASH then
        cc_learn_read_current()
        return true
    end

    --------------------------------------------------------
    -- Enter non fa nulla.
    -- Il learn viene applicato automaticamente al primo CC nuovo.
    --------------------------------------------------------
    if char == KEY_ENTER then
        return true
    end

    --------------------------------------------------------
    -- Delete:
    -- rimuove il learn dal parametro corrente.
    --------------------------------------------------------
    if char == KEY_DELETE then
        cc_learn_remove_from_param()
        return true
    end

    return true
end

------------------------------------------------------------
-- CC LINK STATUS SPEECH
-- Legge dal TXT plugin il CC associato al parametro corrente.
------------------------------------------------------------
function get_current_param_cc_spoken_part()
    --------------------------------------------------------
    -- Floating CC:
    -- quando è attivo, i CC normali vengono messi da parte.
    --------------------------------------------------------
    if cc_focus_waiting then
        return ". Floating CC waiting"
    end

    if cc_focus_active then
        return
            ". Floating CC channel " ..
            tostring(cc_focus_channel) ..
            " CC " ..
            tostring(cc_focus_cc)
    end

    if not param_index_is_valid(param_index) then
        return ""
    end

    --------------------------------------------------------
    -- Ora il parlato CC vale sia per i parametri reali sia
    -- per gli pseudo-parametri supportati dallo script.
    --------------------------------------------------------
    if not cc_learn_param_is_supported(param_index) then
        return ""
    end

    local txt = get_plugin_state_safe(
        cc_link_get_param_key(param_index)
    )

    local channel, cc = cc_link_parse_text(txt)

    if channel == nil or cc == nil then
        return ""
    end

    return
        ". CC channel " ..
        tostring(channel) ..
        " CC " ..
        tostring(cc)
end

function get_current_fx_preset_name_and_index()
    local real_fx = get_current_real_fx_index()

    if real_fx == nil then
        return nil, nil, nil
    end

    local retval = false
    local preset_name = ""

    --------------------------------------------------------
    -- TAKE FX
    --------------------------------------------------------
    if ctx.kind == "take" then
        if not ctx.take then
            return nil, nil, nil
        end

        if not reaper.TakeFX_GetPreset then
            return nil, nil, nil
        end

        local ok
        ok, retval, preset_name =
            pcall(
                reaper.TakeFX_GetPreset,
                ctx.take,
                real_fx,
                ""
            )

        if not ok or not retval then
            return nil, nil, nil
        end

        local preset_index = nil
        local preset_count = nil

        if reaper.TakeFX_GetPresetIndex then
            local ok2, idx, count =
                pcall(
                    reaper.TakeFX_GetPresetIndex,
                    ctx.take,
                    real_fx
                )

            if ok2 then
                preset_index = tonumber(idx)
                preset_count = tonumber(count)
            end
        end

        return clean_one_line(preset_name or ""), preset_index, preset_count
    end

    --------------------------------------------------------
    -- TRACK / MASTER / MONITOR FX
    --------------------------------------------------------
    if not ctx.track then
        return nil, nil, nil
    end

    if not reaper.TrackFX_GetPreset then
        return nil, nil, nil
    end

    local ok
    ok, retval, preset_name =
        pcall(
            reaper.TrackFX_GetPreset,
            ctx.track,
            real_fx,
            ""
        )

    if not ok or not retval then
        return nil, nil, nil
    end

    local preset_index = nil
    local preset_count = nil

    if reaper.TrackFX_GetPresetIndex then
        local ok2, idx, count =
            pcall(
                reaper.TrackFX_GetPresetIndex,
                ctx.track,
                real_fx
            )

        if ok2 then
            preset_index = tonumber(idx)
            preset_count = tonumber(count)
        end
    end

    return clean_one_line(preset_name or ""), preset_index, preset_count
end

function speak_current_fx_preset()
    local preset_name, preset_index, preset_count =
        get_current_fx_preset_name_and_index()

    if preset_name == nil or preset_name == "" then
        speak("No preset")
        return false
    end

    if preset_index ~= nil and preset_index >= 0 then
        speak(tostring(preset_index + 1) .. ". " .. preset_name)
    else
        speak(preset_name)
    end

    return true
end

function navigate_current_fx_preset(direction)
    direction = tonumber(direction) or 0

    if direction == 0 then
        return false
    end

    clear_param_memory_arm()
    disarm_slot_deletes()
    cancel_pending_speech()

    --------------------------------------------------------
    -- Se siamo nel browser FX, usa l'FX evidenziato.
    --------------------------------------------------------
    if mode == "fx_browser" then
        sync_current_fx_to_browser_cursor_silent()
    end

    local real_fx = get_current_real_fx_index()

    if real_fx == nil then
        speak("No FX")
        return false
    end

    local ok = false

    --------------------------------------------------------
    -- TAKE FX
    --------------------------------------------------------
    if ctx.kind == "take" then
        if not ctx.take then
            speak("No take")
            return false
        end

        if not reaper.TakeFX_NavigatePresets then
            speak("Preset navigation not supported")
            return false
        end

        ok =
            pcall(
                reaper.TakeFX_NavigatePresets,
                ctx.take,
                real_fx,
                direction
            )

    --------------------------------------------------------
    -- TRACK / MASTER / MONITOR FX
    --------------------------------------------------------
    else
        if not ctx.track then
            speak("No track")
            return false
        end

        if not reaper.TrackFX_NavigatePresets then
            speak("Preset navigation not supported")
            return false
        end

        ok =
            pcall(
                reaper.TrackFX_NavigatePresets,
                ctx.track,
                real_fx,
                direction
            )
    end

    if not ok then
        speak("Preset navigation failed")
        return false
    end

    --------------------------------------------------------
    -- Dopo il cambio preset, resta nello stesso punto dello
    -- script e legge il preset corrente.
    --------------------------------------------------------
    speak_current_fx_preset()

    return true
end

------------------------------------------------------------
-- 7.3A - PRESET BROWSING FX CORRENTE
--
-- Alt+F1 = preset precedente
-- Alt+F2 = preset successivo
--
-- Alt+F11 / Alt+F12 restano liberi per OSARA Peak Watcher.
--
-- Usa i preset che REAPER espone per l'FX corrente.
-- Non riordina preset, non gestisce preset custom dello script:
-- naviga semplicemente avanti / indietro.
------------------------------------------------------------
function handle_preset_navigation_keys(char)
    local is_ctrl = ctrl_down()
    local is_shift = shift_down()
    local is_alt = alt_down()

    --------------------------------------------------------
    -- Alt+F1 / Alt+F2:
    -- preset precedente / successivo.
    --
    -- Ctrl+F1 / Ctrl+F2 restano liberi per gli slot.
    --------------------------------------------------------
    if is_ctrl or is_shift or not is_alt then
        return false
    end

    if char == KEY_F1 then
        navigate_current_fx_preset(-1)
        return true
    end

    if char == KEY_F2 then
        navigate_current_fx_preset(1)
        return true
    end

    return false
end

------------------------------------------------------------
-- 7.4 - SUPPORTO GROUP EDIT
--
-- Qui viene definita anche group_edit_reset_path_to_pos().
-- Era la funzione mancante che causava:
-- attempt to call a nil value global 'group_edit_reset_path_to_pos'
------------------------------------------------------------
function group_edit_reset_path_to_pos(pos)
    local count = 0

    if type(group_edit_get_count) == "function" then
        count = group_edit_get_count()
    elseif type(get_active_count) == "function" then
        count = get_active_count()
    end

    --------------------------------------------------------
    -- Ogni nuovo tratto del serpente conserva la selezione
    -- già fatta come base.
    --------------------------------------------------------
    if type(group_edit_snapshot_base_selection) == "function" then
        group_edit_snapshot_base_selection()
    else
        group_select_base_selected = {}
    end

    if count <= 0 then
        group_select_anchor_pos = 1
        group_select_path = {}
        group_select_dir_path = {}
        group_select_path_lookup = {}
        group_select_path_action = "select"

        return false
    end

    pos = clamp_int(pos or active_pos or 1, 1, count)

    --------------------------------------------------------
    -- Pennello intelligente:
    -- se il parametro di partenza è già selezionato,
    -- il tratto Shift deseleziona.
    --
    -- se il parametro di partenza non è selezionato,
    -- il tratto Shift seleziona.
    --------------------------------------------------------
    local list = get_active_indices()

    if group_edit_position_is_selected(pos, list) then
        group_select_path_action = "unselect"
    else
        group_select_path_action = "select"
    end

    group_select_anchor_pos = pos

    --------------------------------------------------------
    -- La posizione corrente è la TESTA del serpente, non una
    -- cella già percorsa. Il primo Shift selezionerà quindi
    -- proprio questa cella e il conteggio partirà da 1.
    --------------------------------------------------------
    group_select_path = {}
    group_select_dir_path = {}
    group_select_path_lookup = {}

    return true
end

function clear_group_edit_selection_only()
    if group_edit_uses_group_occurrences() then
        group_edit_occurrence_selected = {}
        group_edit_occurrence_base_selected = {}
    else
        group_selected = {}
        group_select_base_selected = {}

        -- Nella vista All parameters di un Group, group_results
        -- è ancora il Group autonomo parcheggiato: non va cancellato.
        if group_edit_loaded_slot == nil then
            group_results = {}
            group_active = false
        end
    end

    group_select_path = {}
    group_select_path_lookup = {}
    group_select_dir_path = {}

    if not group_edit_uses_group_occurrences() and
       type(clear_f7_runtime_selection_for_current_fx) == "function" then
        clear_f7_runtime_selection_for_current_fx()
    end

    clear_param_memory_arm()
    disarm_slot_deletes()

    mode = "group_edit"
    value_return_mode = "group_edit"
    numeric_return_mode = "group_edit"

    if not set_param_index_absolute(param_index, false) then
        active_pos = 1
        sync_param_from_active_pos()
    end

    group_edit_reset_path_to_pos(active_pos)

    speak("Unselected all. 0 selected")
end
------------------------------------------------------------
-- 7.5 - TOUCH PARAMETRO PER AUTOMAZIONE REAPER
--
-- Serve per rendere il parametro corrente "last touched"
-- agli occhi di REAPER. Dopo il micro-movimento viene richiamata
-- l'azione nativa per mostrare/nascondere l'envelope.
------------------------------------------------------------
function touch_current_param_for_reaper()
    --------------------------------------------------------
    -- I parametri virtuali ReaEQ non sono automatable reali.
    -- Quindi non possono diventare "last touched" per REAPER.
    --------------------------------------------------------
    if param_index < 0 or param_index > param_count - 1 then
        return false
    end

    local old_v = get_param_value_norm(param_index)
    local touch_v

    if old_v < 0.999999 then
        touch_v = old_v + 0.000001
    else
        touch_v = old_v - 0.000001
    end

    touch_v = clamp01(touch_v)

    set_param_value_norm(param_index, touch_v)
    set_param_value_norm(param_index, old_v)

    save_current_param_position()

    return true
end

function show_hide_current_param_envelope()
    clear_param_memory_arm()
    disarm_slot_deletes()
    cancel_pending_speech()

    --------------------------------------------------------
    -- I parametri virtuali ReaEQ e gli indici non reali non
    -- hanno un envelope REAPER da mostrare o nascondere.
    --------------------------------------------------------
    if param_index < 0 or param_index > param_count - 1 then
        speak("No parameter")
        return false
    end

    local before_active = false

    if type(fx_param_envelope_is_active_for_param) == "function" then
        before_active = fx_param_envelope_is_active_for_param(param_index) == true
    end

    local target_active = not before_active
    local create_env = target_active == true

    if not fx_param_set_envelope_auto_for_param(param_index, target_active, create_env) then
        speak("Automation not available")
        return false
    end

    if reaper.MarkProjectDirty then
        reaper.MarkProjectDirty(0)
    end

    if reaper.TrackList_AdjustWindows then
        reaper.TrackList_AdjustWindows(false)
    end

    if reaper.UpdateArrange then
        reaper.UpdateArrange()
    end

    if target_active then
        speak("Auto. " .. get_param_label())
    else
        speak("Auto off. " .. get_param_label())
    end

    return true
end

------------------------------------------------------------
-- 7.5A - AUTOMAZIONE FX CORRENTE / NAVIGAZIONE AUTO
--
-- Ctrl+Shift+Alt+A:
--   disattiva e nasconde tutti gli envelope del solo FX corrente.
--
-- Alt+F3 / Alt+F4:
--   salta ciclicamente al parametro Auto precedente / successivo
--   del solo FX corrente. La lista è reale: legge ACT dall'envelope
--   REAPER e non usa memoria dello script.
------------------------------------------------------------
function fx_param_is_real_automatable_index(i)
    i = tonumber(i)

    return i ~= nil and param_count > 0 and i >= 0 and i <= param_count - 1
end

function fx_param_collect_auto_indices_for_current_fx()
    local out = {}
    local seen = {}
    local base = {}

    if type(get_full_grid_indices) == "function" then
        base = get_full_grid_indices()
    else
        for i = 0, (tonumber(param_count) or 0) - 1 do
            base[#base + 1] = i
        end
    end

    for pos = 1, #base do
        local i = tonumber(base[pos])

        if fx_param_is_real_automatable_index(i) and not seen[i] then
            if fx_param_envelope_is_active_for_param(i) then
                out[#out + 1] = i
                seen[i] = true
            end
        end
    end

    return out
end

function fx_param_find_current_auto_position(list)
    list = list or {}

    for pos = 1, #list do
        if tonumber(list[pos]) == tonumber(param_index) then
            return pos
        end
    end

    return 0
end

function fx_param_jump_to_auto_param(direction)
    clear_param_memory_arm()
    disarm_slot_deletes()
    cancel_pending_speech()

    direction = tonumber(direction) or 0

    if direction == 0 then
        return false
    end

    local list = fx_param_collect_auto_indices_for_current_fx()
    local count = #list

    if count <= 0 then
        speak("No automated parameters")
        return false
    end

    local pos = fx_param_find_current_auto_position(list)
    local target_pos = 1

    if pos <= 0 then
        if direction < 0 then
            target_pos = count
        else
            target_pos = 1
        end
    else
        target_pos = pos + direction

        if target_pos < 1 then
            target_pos = count
        elseif target_pos > count then
            target_pos = 1
        end
    end

    local target_param = list[target_pos]

    if type(set_param_index_in_full_grid) == "function" then
        if set_param_index_in_full_grid(target_param, true) then
            return true
        end
    end

    if type(set_param_index_absolute) == "function" then
        if set_param_index_absolute(target_param, true) then
            return true
        end
    end

    param_index = target_param
    save_current_param_position()
    announce_current_param()

    return true
end

function handle_auto_param_navigation_keys(char)
    local is_ctrl = ctrl_down()
    local is_shift = shift_down()
    local is_alt = alt_down()

    if is_ctrl or is_shift or not is_alt then
        return false
    end

    if char == KEY_F3 then
        return fx_param_jump_to_auto_param(-1)
    end

    if char == KEY_F4 then
        return fx_param_jump_to_auto_param(1)
    end

    return false
end

function clear_all_current_fx_param_envelopes()
    clear_param_memory_arm()
    disarm_slot_deletes()
    cancel_pending_speech()

    local real_fx = fx_param_current_real_fx_index()

    if real_fx == nil then
        speak("No FX")
        return false
    end

    local count = tonumber(param_count) or 0

    if count <= 0 then
        speak("No parameters")
        return false
    end

    local changed = 0
    local touched = 0

    for i = 0, count - 1 do
        local env = fx_param_get_envelope(real_fx, i, false)

        if env then
            local was_active = fx_param_envelope_is_active(env)
            local was_visible = fx_param_envelope_is_visible(env)

            if was_active or was_visible then
                touched = touched + 1

                if fx_param_envelope_set_active_visible(env, false, false) then
                    changed = changed + 1
                end
            end
        end
    end

    if changed > 0 then
        if reaper.MarkProjectDirty then
            reaper.MarkProjectDirty(0)
        end

        if reaper.TrackList_AdjustWindows then
            reaper.TrackList_AdjustWindows(false)
        end

        if reaper.UpdateArrange then
            reaper.UpdateArrange()
        end

        save_current_param_position()
        speak("Cleared " .. tostring(changed) .. " automated parameters")
        return true
    end

    if touched > 0 then
        speak("Automation clear failed")
        return false
    end

    speak("No automated parameters")
    return false
end

------------------------------------------------------------
-- 7.6 - TOGGLE FX BROWSER / PARAMETRI
------------------------------------------------------------
function toggle_fx_browser_or_parameter()
    if mode == "fx_browser" then
        fx_browser_accept_current()
        return true
    end

    enter_fx_browser_mode(nil)

    return true
end

------------------------------------------------------------
-- 7.7 - TOGGLE Parameter Navigator. / GRIGLIA
------------------------------------------------------------
function toggle_memory_manager_or_grid()
    if mode == "memory_manager" then
        jump_to_current_grid()
        return true
    end

    enter_memory_manager_mode()

    return true
end

------------------------------------------------------------
-- 7.8 - TOGGLE F7 GROUP EDIT
------------------------------------------------------------
function toggle_f7_or_previous_grid()
    if mode == "group_edit" then
        restore_f7_return_snapshot()
        return true
    end

    enter_group_edit_mode()

    return true
end

------------------------------------------------------------
-- 7.9 - CTRL+D
-- All parameters <-> ultimo gruppo reale.
------------------------------------------------------------
function handle_ctrl_d()
    if mode == "group_edit" then
        restore_f7_return_snapshot()
        return true
    end

    toggle_all_or_last_group()

    return true
end

------------------------------------------------------------
-- 7.10 - CTRL+L
-- Toggle ordine parametri:
-- Plugin order <-> Custom order salvato nel TXT plugin.
------------------------------------------------------------
function exit_loaded_group_to_underlying_order()
    local old_param = param_index

    --------------------------------------------------------
    -- Ctrl+L è un'uscita definitiva dal recinto Group.
    -- Consuma anche eventuali snapshot temporanei di Search/F7,
    -- così un Esc successivo non può resuscitare il vecchio Group.
    --------------------------------------------------------
    if type(search_clear_return_snapshot) == "function" then
        search_clear_return_snapshot()
    end

    f7_grid_return_snapshot = nil
    f7_return_mode = "all"
    f7_return_group_slot = nil
    f7_return_param_index = nil

    search_active = false
    search_results = {}
    search_query = ""
    search_buffer = ""
    search_cursor = 1
    search_edge = nil
    group_edit_search_positions = {}

    group_active = false
    group_results = {}

    mode = "list"
    value_return_mode = "list"
    numeric_return_mode = "list"

    clear_group_context()

    if type(load_f7_runtime_selection_for_current_fx) == "function" then
        load_f7_runtime_selection_for_current_fx()
    end

    build_all_param_indices()

    if old_param ~= nil and
       not set_param_index_absolute(old_param, false) then
        active_pos = 1
        sync_param_from_active_pos()
    end

    save_current_param_position()
    save_current_entry_state()
    announce_grid_context(nil)

    return true
end

function toggle_custom_order_or_plugin_order()
    clear_param_memory_arm()
    disarm_slot_deletes()
    cancel_pending_speech()

    --------------------------------------------------------
    -- Ctrl+L dentro un Group NON cambia Plugin/Custom order:
    -- esce semplicemente dal Group e rivela il recinto stabile
    -- che era già sotto (Custom se attiva, altrimenti Plugin).
    --
    -- Vale anche se sopra il Group c'è una Search temporanea:
    -- il ritorno Search conserva quale recinto Group era sotto.
    --------------------------------------------------------
    if search_return_valid and
       search_return_group_active and
       search_return_group_slot ~= nil then

        custom_order_active =
            search_return_custom_order_active == true

        return exit_loaded_group_to_underlying_order()
    end

    if (group_active and current_group_slot ~= nil) or
       group_edit_loaded_slot ~= nil then
        return exit_loaded_group_to_underlying_order()
    end

    --------------------------------------------------------
    -- Se sei dentro un recinto temporaneo, prima rientra
    -- nella griglia stabile. Evita cambi d'ordine mentre
    -- un editor testuale o un pannello è aperto.
    --------------------------------------------------------
    if mode == "search_edit" then
        cancel_search_edit()
        return true
    end

    if mode == "recent" then
        return_to_all_parameters(nil)
        return true
    end

    if mode == "memory_manager" then
        jump_to_current_grid()
        return true
    end

    if edit_mode then
        close_numeric_edit()
        return true
    end

    if mode == "fx_browser" then
        fx_browser_accept_current()
        return true
    end

    toggle_custom_order_mode()

    return true
end

------------------------------------------------------------
-- 7.11 - RIPRISTINO FX INIZIALE
------------------------------------------------------------
function select_default_fx()
    fx_index = 0
    selected_fx_label = fx_names[1] or ""
    selected_fx_is_monitor = fx_is_monitor[1] == true
end

function restore_initial_fx_selection()
    initial_fx_restored_by_memory = false

    --------------------------------------------------------
    -- Priorità assoluta solo quando l'FX chain è aperta:
    -- se l'utente è già su un plugin nella catena, lo script
    -- deve aprire direttamente quel plugin e non l'ultimo
    -- salvato nel TXT/ExtState.
    --------------------------------------------------------
    if type(fx_chain_visible_select_current_fx) == "function" and
       fx_chain_visible_select_current_fx() then

        initial_fx_restored_by_memory = true
        return true
    end

    if restore_last_fx_position and restore_last_fx_position() then
        initial_fx_restored_by_memory = true
        return true
    end

    select_default_fx()

    return selected_fx_label ~= ""
end

------------------------------------------------------------
-- 7.12 - SALVATAGGIO PROFILO PLUGIN CORRENTE
--
-- Usato da parte 5 e parte 6 prima di cambiare FX,
-- spostare FX o uscire.
------------------------------------------------------------
function save_current_plugin_profile_before_switch()
    if type(save_plugin_step_grid_to_txt) == "function" then
        save_plugin_step_grid_to_txt()
    else
        if type(save_plugin_step_scale_to_txt) == "function" then
            save_plugin_step_scale_to_txt()
        end

        if type(save_plugin_grid_size_to_txt) == "function" then
            save_plugin_grid_size_to_txt()
        end
    end

    if type(save_custom_order_to_txt) == "function" then
        save_custom_order_to_txt()
    end

    if type(cc_runtime_save_fixed_map_state_to_txt) == "function" then
        cc_runtime_save_fixed_map_state_to_txt()
    end

    save_plugin_txt_now()
end

------------------------------------------------------------
-- 7.13 - MARKER NORMALI: CTRL+I / CTRL+O
--
-- CTRL+I = marker normale precedente
-- CTRL+O = marker normale successivo
--
-- Non usa stretch marker.
-- Non usa time marker speciali.
-- Ignora le regioni.
------------------------------------------------------------
marker_edge_spoken = nil -- "first", "last", "none", nil

function format_marker_time_for_speech(pos)
    pos = tonumber(pos) or 0

    local minutes = math.floor(pos / 60)
    local seconds = pos - (minutes * 60)

    return string.format("%d:%05.2f", minutes, seconds)
end

function speak_normal_marker(marker_number, marker_name, marker_pos)
    marker_number = tonumber(marker_number) or 0
    marker_name = clean_one_line(marker_name or "")

    local msg = ""

    if marker_name ~= "" then
        msg = marker_name
    else
        msg = "Marker " .. tostring(marker_number)
    end

    msg = msg .. ". " .. format_marker_time_for_speech(marker_pos)

    speak(msg)
end

function speak_marker_edge_once(edge_name)
    edge_name = clean_one_line(edge_name or "")

    if edge_name == "" then
        return
    end

    if marker_edge_spoken == edge_name then
        return
    end

    marker_edge_spoken = edge_name

    if edge_name == "first" then
        speak("First marker")
    elseif edge_name == "last" then
        speak("Last marker")
    elseif edge_name == "none" then
        speak("No marker")
    end
end

function goto_normal_marker(direction)
    direction = tonumber(direction) or 0

    if direction == 0 then
        return false
    end

    clear_param_memory_arm()
    disarm_slot_deletes()
    cancel_pending_speech()

    local retval, marker_count, region_count =
        reaper.CountProjectMarkers(0)

    marker_count = tonumber(marker_count) or 0
    region_count = tonumber(region_count) or 0

    if marker_count <= 0 then
        speak_marker_edge_once("none")
        return false
    end

    local total = marker_count + region_count
    local cur_pos = reaper.GetCursorPosition()
    local eps = 0.000001

    local wanted_pos = nil
    local wanted_number = nil
    local wanted_name = ""

    for i = 0, total - 1 do
        local ok, is_region, pos, rgnend, name, markrgnindexnumber =
            reaper.EnumProjectMarkers(i)

        if ok and not is_region then
            pos = tonumber(pos) or 0

            if direction > 0 then
                if pos > cur_pos + eps then
                    if wanted_pos == nil or pos < wanted_pos then
                        wanted_pos = pos
                        wanted_number = markrgnindexnumber
                        wanted_name = name or ""
                    end
                end
            else
                if pos < cur_pos - eps then
                    if wanted_pos == nil or pos > wanted_pos then
                        wanted_pos = pos
                        wanted_number = markrgnindexnumber
                        wanted_name = name or ""
                    end
                end
            end
        end
    end

    if wanted_pos == nil then
        if direction > 0 then
            speak_marker_edge_once("last")
        else
            speak_marker_edge_once("first")
        end

        return false
    end

    --------------------------------------------------------
    -- Se ci muoviamo davvero, il bordo può essere annunciato
    -- di nuovo la prossima volta che verrà raggiunto.
    --------------------------------------------------------
    marker_edge_spoken = nil

    --------------------------------------------------------
    -- moveview = true
    -- seekplay = true: se REAPER sta suonando, segue il marker.
    --------------------------------------------------------
    reaper.SetEditCurPos(wanted_pos, true, true)

    speak_normal_marker(wanted_number, wanted_name, wanted_pos)

    return true
end

function goto_normal_marker_number(marker_number)
    marker_number = tonumber(marker_number)

    if marker_number == nil then
        return false
    end

    marker_number = clamp_int(marker_number, 1, 10)

    clear_param_memory_arm()
    disarm_slot_deletes()
    cancel_pending_speech()

    local retval, marker_count, region_count =
        reaper.CountProjectMarkers(0)

    marker_count = tonumber(marker_count) or 0
    region_count = tonumber(region_count) or 0

    if marker_count <= 0 then
        speak_marker_edge_once("none")
        return true
    end

    local total = marker_count + region_count

    for i = 0, total - 1 do
        local ok, is_region, pos, rgnend, name, markrgnindexnumber =
            reaper.EnumProjectMarkers(i)

        if ok and
           not is_region and
           tonumber(markrgnindexnumber) == marker_number then

            marker_edge_spoken = nil
            reaper.SetEditCurPos(tonumber(pos) or 0, true, true)
            speak_normal_marker(marker_number, name or "", pos)
            return true
        end
    end

    speak("Marker " .. tostring(marker_number) .. " not found")
    return true
end

function handle_ctrl_marker_keys(char)
    local is_ctrl = ctrl_down()
    local is_shift = shift_down()
    local is_alt = alt_down()

    if not is_ctrl or is_shift or is_alt then
        return false
    end

    if char == KEY_CTRL_I then
        goto_normal_marker(-1)
        return true
    end

    if char == KEY_CTRL_O then
        goto_normal_marker(1)
        return true
    end

    return false
end

------------------------------------------------------------
-- 7.14 - CAMBIO CONTESTO: WRAPPER SICURI
--
-- Le funzioni pesanti di cambio contesto sono nella PARTE 5:
--
-- switch_track_context_by_direction(direction)
-- switch_item_context_by_direction(direction)
--
-- Qui NON le ridefiniamo, per evitare di sovrascriverle.
------------------------------------------------------------
function handle_ctrl_left_right_item_nav(direction)
    direction = tonumber(direction) or 0

    if direction == 0 then
        return false
    end

    if type(switch_item_context_by_direction) ~= "function" then
        speak("Item navigation not available")
        return false
    end

    return switch_item_context_by_direction(direction)
end

function handle_ctrl_page_track_nav(direction)
    direction = tonumber(direction) or 0

    if direction == 0 then
        return false
    end

    if type(switch_track_context_by_direction) ~= "function" then
        speak("Track navigation not available")
        return false
    end

    return switch_track_context_by_direction(direction)
end

------------------------------------------------------------
-- 7.15 - INIT SCRIPT
------------------------------------------------------------
function init_script()
if not select_start_context() then
    speak_start_context_no_fx()
    return false
end    

    build_fx_list_for_current_context()

    if fx_count <= 0 then
        speak("No FX in selected context")
        return false
    end

    load_recent_searches()

    cc_focus_restore_session_memory()

    --------------------------------------------------------
    -- Stato globale non legato al progetto:
    -- step/grid partono da default; poi il TXT del plugin
    -- corrente può sovrascriverli.
    --------------------------------------------------------
    reset_step_scale()
    reset_grid_size()

    if not restore_initial_fx_selection() then
        speak("No FX in selected context")
        return false
    end

    build_fx_browser_lists()
    sync_fx_browser_to_current_fx()

    load_plugin_txt_for_selected_fx()

    --------------------------------------------------------
    -- Ora che il TXT è caricato, ripristina Step/Grid.
    --------------------------------------------------------
    if type(restore_plugin_step_grid_from_txt) == "function" then
        restore_plugin_step_grid_from_txt()
    else
        if type(restore_plugin_step_scale_from_txt) == "function" then
            restore_plugin_step_scale_from_txt()
        end

        if type(restore_plugin_grid_size_from_txt) == "function" then
            restore_plugin_grid_size_from_txt()
        end
    end

    --------------------------------------------------------
    -- Carica lo stato ordine custom del plugin.
    -- Se param_count è ancora 0, load_custom_order_from_txt
    -- non farà nulla. Verrà richiamata anche in prepare.
    --------------------------------------------------------
    if type(load_custom_order_from_txt) == "function" then
        load_custom_order_from_txt()
    end

    local last_area = restore_last_area_state()
    local has_grid_memory = plugin_txt_has_grid_memory()

    --------------------------------------------------------
    -- Priorità nuova:
    -- se il plugin ha una memoria TXT utile, o se l'FX è stato
    -- ripristinato con certezza, entra nella griglia anche se
    -- l'ultima area salvata era browser.
    --------------------------------------------------------
    if last_area == "grid" or
       has_grid_memory or
       initial_fx_restored_by_memory then

        if prepare_selected_fx_for_param_browser() then
            return true
        end
    end

    --------------------------------------------------------
    -- Il browser si apre solo come fallback: più FX e nessuna
    -- memoria plugin utile da usare per entrare direttamente.
    --------------------------------------------------------
    if fx_count > 1 then
        enter_fx_browser_mode(nil, false)
        return true
    end

    if not prepare_selected_fx_for_param_browser() then
        gfx.quit()
        return false
    end

    return true
end

------------------------------------------------------------
-- FINE PARTE 7 / 8
------------------------------------------------------------

------------------------------------------------------------
-- OSARA PEAK WATCHER ACTIONS
--
-- Alt+F10:
--   watcher 1 reset
--
-- Alt+Shift+F10/F11/F12:
--   watcher 2 reset / channel 1 / channel 2
--
-- Nessun messaggio parlato qui:
-- OSARA parla già da solo.
------------------------------------------------------------
function run_osara_named_action(command_id)
    command_id = tostring(command_id or "")

    if command_id == "" then
        return true
    end

    local cmd = reaper.NamedCommandLookup(command_id)

    if cmd and cmd ~= 0 then
        reaper.Main_OnCommand(cmd, 0)
    end

    return true
end

function handle_osara_peak_watcher_keys(char)
    local is_ctrl = ctrl_down()
    local is_shift = shift_down()
    local is_alt = alt_down()

    if is_ctrl or not is_alt then
        return false
    end

    --------------------------------------------------------
    -- Alt+F10/F11/F12: watcher 1 reset / channel 1 / channel 2.
    -- Alt+F11/F12 sono di nuovo liberi per OSARA: i preset
    -- dello script sono su Alt+F1/F2.
    --------------------------------------------------------
    if not is_shift then
        if char == KEY_F10 then
            return run_osara_named_action("_OSARA_RESETPEAKWATCHERT1")
        end

        if char == KEY_F11 then
            return run_osara_named_action("_OSARA_REPORTPEAKWATCHERT1C1")
        end

        if char == KEY_F12 then
            return run_osara_named_action("_OSARA_REPORTPEAKWATCHERT1C2")
        end

        return false
    end

    --------------------------------------------------------
    -- Alt+Shift+F10/F11/F12: watcher 2.
    --------------------------------------------------------
    if char == KEY_F10 then
        return run_osara_named_action("_OSARA_RESETPEAKWATCHERT2")
    end

    if char == KEY_F11 then
        return run_osara_named_action("_OSARA_REPORTPEAKWATCHERT2C1")
    end

    if char == KEY_F12 then
        return run_osara_named_action("_OSARA_REPORTPEAKWATCHERT2C2")
    end

    return false
end

------------------------------------------------------------
-- DEFAULT SNAPSHOT PER PLUGIN
--
-- Salva e usa i valori di default del plugin nel TXT.
-- Backspace:
--   reset parametro corrente.
--
-- Ctrl+Backspace:
--   reset ultimo controllo Step / Grid.
--
-- Ctrl+Shift+Backspace:
--   reset tutti i parametri del plugin.
------------------------------------------------------------

function plugin_default_snapshot_has_content()
    if type(plugin_txt_default_values_has_content) == "function" then
        return plugin_txt_default_values_has_content()
    end

    return trim(plugin_txt_get_default_values() or "") ~= ""
end

function plugin_default_snapshot_count()
    local txt = plugin_txt_get_default_values()
    local count = 0
    local reaeq_band_count = nil
    local reaeq_param_count = nil

    for line in tostring(txt or ""):gmatch("[^\r\n]+") do
        line = trim(line)

        if line ~= "" then
            local index_s = line:match("^(%-?%d+)%s*\t")

            if tonumber(index_s) ~= nil then
                count = count + 1
            else
                local tag, key, value =
                    line:match("^([^%s\t]+)%s*\t%s*([^%s\t]+)%s*\t%s*(.*)$")

                if tag == "META" and key == "REA_EQ_BAND_COUNT" then
                    reaeq_band_count = tonumber(value)
                elseif tag == "META" and key == "REA_EQ_PARAM_COUNT" then
                    reaeq_param_count = tonumber(value)
                end
            end
        end
    end

    --------------------------------------------------------
    -- ReaEQ viene salvato come chunk strutturale unico.
    -- In quel caso non ci sono righe numeriche per parametro:
    -- il numero qui serve solo per messaggi/F8.
    --------------------------------------------------------
    if count <= 0 and reaeq_band_count ~= nil then
        reaeq_band_count = math.max(0, math.floor(reaeq_band_count + 0.5))
        reaeq_param_count = math.max(0, math.floor((reaeq_param_count or 0) + 0.5))

        return math.max(
            1,
            (reaeq_band_count * 5) +
            math.max(0, reaeq_param_count - (reaeq_band_count * 3))
        )
    end

    return count
end

function plugin_default_snapshot_meta_line(key, value)
    key = clean_one_line(key or "")

    if key == "" then
        return ""
    end

    return "META\t" .. key .. "\t" .. tostring(value or "")
end

function plugin_default_snapshot_serialize_current()
    local lines = {}

    --------------------------------------------------------
    -- ReaEQ: il default deve essere strutturale, non una lista
    -- di indici. ReaEQ può aggiungere/rimuovere bande e la griglia
    -- contiene anche controlli virtuali come Add band/Remove band.
    -- Se salviamo e ripristiniamo per indice, dopo una variazione
    -- della struttura si possono muovere bande sbagliate o rimuovere
    -- parametri. Per ReaEQ la sorgente di verità è il vst_chunk.
    --------------------------------------------------------
    if is_current_fx_reaeq and is_current_fx_reaeq() and
       fx_get_named_config_parm then

        local ok, chunk = fx_get_named_config_parm("vst_chunk")

        if ok and trim(chunk or "") ~= "" then
            lines[#lines + 1] =
                plugin_default_snapshot_meta_line(
                    "REA_EQ_DEFAULT_MODE",
                    "CHUNK_ONLY"
                )

            lines[#lines + 1] =
                plugin_default_snapshot_meta_line(
                    "REA_EQ_BAND_COUNT",
                    tostring(reaeq_get_band_count and reaeq_get_band_count() or 0)
                )

            lines[#lines + 1] =
                plugin_default_snapshot_meta_line(
                    "REA_EQ_PARAM_COUNT",
                    tostring(param_count or 0)
                )

            lines[#lines + 1] =
                plugin_default_snapshot_meta_line(
                    "REA_EQ_VST_CHUNK",
                    chunk
                )

            ------------------------------------------------
            -- ReaEQ salva il corpo del plugin nel chunk, ma
            -- Bypass, Wet e Delta sono controlli wrapper di
            -- REAPER: non vivono nel vst_chunk. Li salviamo
            -- separatamente come ultimi tre parametri reali
            -- esposti dall'FX, nello stesso ordine REAPER.
            ------------------------------------------------
            if plugin_default_snapshot_capture_reaeq_wrapper_tail then
                plugin_default_snapshot_capture_reaeq_wrapper_tail(lines)
            end

            return table.concat(lines, "\n")
        end
    end

    local base = get_full_grid_indices()

    for pos = 1, #base do
        local i = base[pos]

        ----------------------------------------------------
        -- Compare resta fuori dal default snapshot.
        -- Reset singolo e globale lo disarmano sempre.
        ----------------------------------------------------
        if param_index_is_valid(i) and
           not (fx_compare_param_is_valid and fx_compare_param_is_valid(i)) then

            local name = clean_one_line(get_param_name(i))
            local norm = get_param_value_norm(i)

            lines[#lines + 1] =
                tostring(i) ..
                "\t" ..
                name ..
                "\t" ..
                tostring(norm)
        end
    end

    return table.concat(lines, "\n")
end

function plugin_default_snapshot_save_current_if_empty()
    if not plugin_storage_available() then
        return false
    end

    if plugin_default_snapshot_has_content() then
        return false
    end

    local txt = plugin_default_snapshot_serialize_current()

    if trim(txt) == "" then
        return false
    end

    plugin_txt_set_default_values(txt)
    plugin_txt_save_if_dirty(true)

    return true
end

function plugin_default_snapshot_find_param(i)
    i = tonumber(i)

    if i == nil then
        return nil
    end

    local txt = plugin_txt_get_default_values()

    for line in tostring(txt or ""):gmatch("[^\r\n]+") do
        line = trim(line)

        if line ~= "" then
            local index_s, name, norm_s =
                line:match("^(%-?%d+)%s*\t%s*([^\t]*)%s*\t%s*(.*)$")

            local saved_index = tonumber(index_s)
            local saved_norm = tonumber(norm_s)

            if saved_index ~= nil and saved_norm ~= nil then
                saved_index = math.floor(saved_index + 0.5)

                if saved_index == i then
                    return clamp01(saved_norm)
                end
            end
        end
    end

    return nil
end

function plugin_default_snapshot_find_meta(key)
    key = clean_one_line(key or "")

    if key == "" then
        return nil
    end

    local txt = plugin_txt_get_default_values()

    for line in tostring(txt or ""):gmatch("[^\r\n]+") do
        line = trim(line)

        if line ~= "" then
            local tag, saved_key, value =
                line:match("^([^%s\t]+)%s*\t%s*([^%s\t]+)%s*\t%s*(.*)$")

            if tag == "META" and saved_key == key then
                return tostring(value or "")
            end
        end
    end

    return nil
end

function plugin_default_snapshot_has_reaeq_chunk()
    local chunk = plugin_default_snapshot_find_meta("REA_EQ_VST_CHUNK")

    return trim(chunk or "") ~= ""
end

function plugin_default_snapshot_capture_reaeq_wrapper_tail(lines)
    if type(lines) ~= "table" then
        return false
    end

    if not (is_current_fx_reaeq and is_current_fx_reaeq()) then
        return false
    end

    local count = tonumber(param_count) or 0

    --------------------------------------------------------
    -- REAPER espone i tre controlli generici dell'FX in fondo
    -- alla lista parametri: Bypass, Wet, Delta. ReaEQ, quando
    -- viene salvato come chunk strutturale, non include questi
    -- tre valori nel chunk del plugin. Per questo li salviamo
    -- come coda indipendente dal numero di bande.
    --------------------------------------------------------
    if count < 3 then
        return false
    end

    for tail = 1, 3 do
        local i = count - 3 + (tail - 1)

        if param_index_is_valid(i) then
            lines[#lines + 1] =
                plugin_default_snapshot_meta_line(
                    "REA_EQ_WRAPPER_TAIL_" .. tostring(tail) .. "_NAME",
                    clean_one_line(get_param_name(i) or "")
                )

            lines[#lines + 1] =
                plugin_default_snapshot_meta_line(
                    "REA_EQ_WRAPPER_TAIL_" .. tostring(tail) .. "_NORM",
                    tostring(get_param_value_norm(i))
                )
        end
    end

    return true
end

function plugin_default_snapshot_restore_reaeq_wrapper_tail()
    if not (is_current_fx_reaeq and is_current_fx_reaeq()) then
        return false
    end

    local count = tonumber(param_count) or 0

    if count < 3 then
        return false
    end

    local restored = 0

    for tail = 1, 3 do
        local norm_s =
            plugin_default_snapshot_find_meta(
                "REA_EQ_WRAPPER_TAIL_" .. tostring(tail) .. "_NORM"
            )

        local norm = tonumber(norm_s)

        if norm ~= nil then
            local i = count - 3 + (tail - 1)

            if param_index_is_valid(i) then
                set_param_value_norm(i, clamp01(norm))
                restored = restored + 1
            end
        end
    end

    return restored > 0
end

function plugin_default_snapshot_is_reaeq_chunk_only()
    if not plugin_default_snapshot_has_reaeq_chunk() then
        return false
    end

    local mode = clean_one_line(
        plugin_default_snapshot_find_meta("REA_EQ_DEFAULT_MODE") or ""
    )

    --------------------------------------------------------
    -- Anche i vecchi default ReaEQ che hanno il chunk vanno
    -- trattati come strutturali durante il reset globale: il chunk
    -- è più affidabile delle vecchie righe per indice.
    --------------------------------------------------------
    return mode == "CHUNK_ONLY" or (is_current_fx_reaeq and is_current_fx_reaeq())
end

function plugin_default_snapshot_rebuild_grid_after_structural_reset(
    preferred_param_index,
    preferred_active_pos
)
    preferred_param_index = tonumber(preferred_param_index)
    preferred_active_pos = tonumber(preferred_active_pos)

    clear_filtered_param_context()

    param_count = get_current_fx_param_count()
    build_all_param_indices()

    if custom_order_active and
       type(apply_custom_order_to_all_params) == "function" then

        apply_custom_order_to_all_params()
        build_all_param_indices()
    end

    --------------------------------------------------------
    -- Dopo un reset strutturale ReaEQ la griglia va ricostruita,
    -- ma non bisogna disorientare l'utente portandolo sempre
    -- all'inizio.
    --
    -- Prima proviamo a tornare allo stesso parametro.
    -- Se non esiste più, per esempio perché la banda è stata rimossa
    -- dal default chunk, torniamo alla posizione più vicina.
    --------------------------------------------------------
    local restored = false

    if preferred_param_index ~= nil and
       type(set_param_index_absolute) == "function" then

        restored = set_param_index_absolute(
            math.floor(preferred_param_index + 0.5),
            false
        ) == true
    end

    if not restored then
        local count = get_active_count()

        if count > 0 then
            active_pos = clamp_int(preferred_active_pos or active_pos, 1, count)
            sync_param_from_active_pos()
        else
            active_pos = 1
            param_index = 0
        end

        save_current_param_position()
    end

    refresh_window_title()
end

function plugin_default_snapshot_restore_reaeq_chunk(preferred_param_index, preferred_active_pos)
    if not (is_current_fx_reaeq and is_current_fx_reaeq()) then
        return false
    end

    if not fx_set_named_config_parm then
        return false
    end

    local chunk = plugin_default_snapshot_find_meta("REA_EQ_VST_CHUNK")

    if trim(chunk or "") == "" then
        return false
    end

    local ok = fx_set_named_config_parm("vst_chunk", chunk)

    if not ok then
        return false
    end

    --------------------------------------------------------
    -- Forza REAPER/ReaEQ a rinfrescare lo stato, poi ricostruisce
    -- la griglia da zero. Questo evita liste vuote o vecchi indici.
    --------------------------------------------------------
    local real_fx = get_current_real_fx_index()

    if real_fx ~= nil and ctx.track and reaper.TrackFX_GetParamNormalized and
       reaper.TrackFX_SetParamNormalized and param_count > 0 then

        local v = reaper.TrackFX_GetParamNormalized(ctx.track, real_fx, 0)
        reaper.TrackFX_SetParamNormalized(ctx.track, real_fx, 0, v)
    end

    plugin_default_snapshot_rebuild_grid_after_structural_reset(
        preferred_param_index,
        preferred_active_pos
    )

    --------------------------------------------------------
    -- Il chunk ha rimesso a posto bande e parametri interni;
    -- ora rimettiamo anche i tre wrapper REAPER che non sono
    -- dentro il chunk: Bypass, Wet e Delta.
    --------------------------------------------------------
    if plugin_default_snapshot_restore_reaeq_wrapper_tail then
        plugin_default_snapshot_restore_reaeq_wrapper_tail()
    end

    return true
end

default_snapshot_pending_regenerate = false

function plugin_default_snapshot_delete_and_arm_regenerate()
    if not plugin_storage_available() then
        speak("No default snapshot")
        return false
    end

    plugin_txt_clear_default_values()
    plugin_txt_save_if_dirty(true)

    default_snapshot_pending_regenerate = true

    speak("Default deleted. Press Enter or F8 to save a new default")

    return true
end

function plugin_default_snapshot_regenerate_pending_core()
    if not default_snapshot_pending_regenerate then
        return "", 0
    end

    if not plugin_storage_available() then
        return "", 0
    end

    local txt = plugin_default_snapshot_serialize_current()

    if trim(txt or "") == "" then
        return "", 0
    end

    plugin_txt_set_default_values(txt)
    plugin_txt_save_if_dirty(true)

    default_snapshot_pending_regenerate = false

    local count = plugin_default_snapshot_count()

    local msg =
        "Default saved. " ..
        tostring(count) ..
        " parameters"

    return msg, count
end

function plugin_default_snapshot_regenerate_and_return_from_f8()
    cancel_pending_speech()

    if default_snapshot_pending_regenerate then
        plugin_default_snapshot_regenerate_pending_core()
    end

    run_without_speech(function()
        restore_memory_manager_return_context()
    end)

    cancel_pending_speech()
    announce_grid_context(nil)

    return true
end

function plugin_default_snapshot_regenerate_and_exit()
    local msg = ""

    if default_snapshot_pending_regenerate then
        msg = plugin_default_snapshot_regenerate_pending_core()
    end

    if msg ~= "" then
        speak(msg .. ". Exit")
        return true
    end

    return false
end

function reset_current_param_to_plugin_default_snapshot()
    clear_param_memory_arm()
    disarm_slot_deletes()
    cancel_pending_speech()

    if not param_index_is_valid(param_index) then
        speak("No parameter")
        return false
    end

    --------------------------------------------------------
    -- Compare: reset singolo = disarmo, volutamente fuori dal
    -- default snapshot.
    --------------------------------------------------------
    if fx_compare_param_is_valid and fx_compare_param_is_valid(param_index) then
        fx_compare_clear_state()
        save_current_param_position()
        speak(get_param_label())
        return true
    end

    --------------------------------------------------------
    -- ReaEQ structural controls: il singolo reset non cambia la
    -- struttura. Riporta solo il controllo in stato neutro.
    --------------------------------------------------------
    if reaeq_action_param_is_valid and
       reaeq_action_param_is_valid(param_index) then

        set_param_value_norm(param_index, 0)
        save_current_param_position()
        speak("Reset. " .. get_param_label())
        return true
    end

    if not plugin_default_snapshot_has_content() then
        speak("No default snapshot")
        return false
    end

    local norm = plugin_default_snapshot_find_param(param_index)

    if norm == nil then
        speak("No default for this parameter")
        return false
    end

    set_param_value_norm(param_index, norm)
    save_current_param_position()

    speak("Reset. " .. get_param_label())

    return true
end

function reset_all_params_to_plugin_default_snapshot()
    clear_param_memory_arm()
    disarm_slot_deletes()
    cancel_pending_speech()

    if not plugin_default_snapshot_has_content() then
        speak("No default snapshot")
        return false
    end

    local txt = plugin_txt_get_default_values()
    local reset_count = 0
    local reaeq_structural_reset = false

    --------------------------------------------------------
    -- Salva orientamento prima di un eventuale reset strutturale.
    -- ReaEQ può cambiare numero di bande, quindi dopo il chunk
    -- si prova a tornare allo stesso parametro o alla posizione
    -- più vicina, non all'inizio.
    --------------------------------------------------------
    local restore_param_index = param_index
    local restore_active_pos = active_pos

    --------------------------------------------------------
    -- ReaEQ: prima ripristina il chunk del default. Questo è il
    -- punto che ripristina anche numero bande, tipi, enabled,
    -- frequenze, gain, BW e globali. Se il chunk esiste, NON
    -- applichiamo dopo anche la vecchia lista per indice: quella
    -- è proprio la parte instabile con Add band / Remove band.
    --------------------------------------------------------
    if is_current_fx_reaeq and is_current_fx_reaeq() then
        reaeq_structural_reset =
            plugin_default_snapshot_restore_reaeq_chunk(
                restore_param_index,
                restore_active_pos
            )

        if reaeq_structural_reset then
            reset_count = plugin_default_snapshot_count()

            if fx_compare_clear_state then
                fx_compare_clear_state()
            end

            local current_label = ""

            if param_index_is_valid(param_index) then
                current_label = get_param_label() or ""
            end

            current_label = clean_one_line(current_label or "")

            if current_label ~= "" then
                speak("Reset ReaEQ default. " .. current_label)
            else
                speak("Reset ReaEQ default")
            end

            return true
        end
    end

    for line in tostring(txt or ""):gmatch("[^\r\n]+") do
        line = trim(line)

        if line ~= "" then
            local index_s, name, norm_s =
                line:match("^(%-?%d+)%s*\t%s*([^\t]*)%s*\t%s*(.*)$")

            local i = tonumber(index_s)
            local norm = tonumber(norm_s)

            if i ~= nil and norm ~= nil then
                i = math.floor(i + 0.5)

                if param_index_is_valid(i) and
                   not (fx_compare_param_is_valid and fx_compare_param_is_valid(i)) then

                    ------------------------------------------------
                    -- Se il chunk ReaEQ è stato già ripristinato,
                    -- i parametri di banda sono già tornati al loro
                    -- stato default. Applichiamo comunque i parametri
                    -- validi, ma la funzione set_param_value_norm ora
                    -- usa la via ReaEQ corretta per i real band params.
                    ------------------------------------------------
                    set_param_value_norm(i, clamp01(norm))
                    reset_count = reset_count + 1
                end
            end
        end
    end

    --------------------------------------------------------
    -- Compare: reset globale = disarmo.
    --------------------------------------------------------
    if fx_compare_clear_state then
        fx_compare_clear_state()
    end

    --------------------------------------------------------
    -- Se non c'è stato reset strutturale, la posizione è ancora
    -- valida e basta salvarla. Se invece c'è stato, la funzione
    -- del chunk ha già ricostruito la griglia e ripristinato
    -- l'orientamento.
    --------------------------------------------------------
    if not reaeq_structural_reset then
        save_current_param_position()
    end

    local current_label = ""

    if param_index_is_valid(param_index) then
        current_label = get_param_label() or ""
    end

    current_label = clean_one_line(current_label or "")

    if current_label ~= "" then
        speak("Reset " .. tostring(reset_count) .. " parameters. " .. current_label)
    else
        speak("Reset " .. tostring(reset_count) .. " parameters")
    end

    return true
end

------------------------------------------------------------
-- PARTE 8 / 8
-- MAIN LOOP E START
--
-- Nota:
-- - ordine dei controlli importante: prima i comandi globali,
--   poi i recinti speciali, poi la griglia normale;
-- - ogni ramo che intercetta un tasto richiama reaper.defer(main_loop);
-- - lo stato persistente viene salvato nel TXT del plugin.
------------------------------------------------------------

------------------------------------------------------------
-- 8.1 - LOOP HELPER
------------------------------------------------------------
function continue_main_loop()
    reaper.defer(main_loop)
end

function handle_step_grid_keys(char)
    local is_ctrl = ctrl_down()
    local is_shift = shift_down()
    local is_alt = alt_down()

    --------------------------------------------------------
    -- Nuova mappa:
    -- Alt+Freccia sinistra/destra = Step scale -/+
    -- F1/F2 = Grid size -/+
    -- Le vecchie F3/F4 non gestiscono più la Grid.
    --------------------------------------------------------
    if is_alt and not is_ctrl and not is_shift then
        if char == KEY_LEFT then
            disarm_slot_deletes()
            clear_param_memory_arm()

            last_function_touched = "step"
            change_step_scale(-1)

            return true

        elseif char == KEY_RIGHT then
            disarm_slot_deletes()
            clear_param_memory_arm()

            last_function_touched = "step"
            change_step_scale(1)

            return true
        end

        return false
    end

    if is_ctrl or is_shift or is_alt then
        return false
    end

    if char == KEY_F1 then
        disarm_slot_deletes()
        clear_param_memory_arm()

        last_function_touched = "grid"
        change_grid_size(-1)

        return true

    elseif char == KEY_F2 then
        disarm_slot_deletes()
        clear_param_memory_arm()

        last_function_touched = "grid"
        change_grid_size(1)

        return true
    end

    return false
end

function handle_alt_value_keys(char)
    local is_ctrl = ctrl_down()

    if is_ctrl then
        return false
    end

    if char == KEY_UP then
        value_nudge_from_grid(1, false)
        return true

    elseif char == KEY_DOWN then
        value_nudge_from_grid(-1, false)
        return true

    elseif char == KEY_PAGE_UP then
        value_nudge_from_grid(1, true)
        return true

    elseif char == KEY_PAGE_DOWN then
        value_nudge_from_grid(-1, true)
        return true

    elseif char == KEY_HOME then
        value_set_absolute_from_grid(0)
        return true

    elseif char == KEY_END then
        value_set_absolute_from_grid(1)
        return true
    end

    return false
end

------------------------------------------------------------
-- GROUP REALE: DELETE LOCALE / OCCORRENZE
------------------------------------------------------------
function group_remove_positions(slot, positions, speak_it)
    slot = slot or current_group_slot or group_edit_loaded_slot

    if slot == nil then
        return false
    end

    positions = positions or {}

    local unique = {}
    local ordered = {}

    for n = 1, #positions do
        local pos = tonumber(positions[n])

        if pos ~= nil then
            pos = math.floor(pos + 0.5)

            if pos >= 1 and pos <= #group_results and not unique[pos] then
                unique[pos] = true
                ordered[#ordered + 1] = pos
            end
        end
    end

    if #ordered <= 0 then
        return false
    end

    table.sort(ordered)
    local first_removed = ordered[1]

    for n = #ordered, 1, -1 do
        table.remove(group_results, ordered[n])
    end

    save_loaded_group_results(slot)
    rebuild_group_membership_from_results()

    --------------------------------------------------------
    -- Una modifica strutturale chiude l'eventuale lente Search:
    -- il Group appena salvato resta la sola fonte autoritativa.
    --------------------------------------------------------
    if mode == "group_edit" and group_edit_loaded_slot ~= nil then
        search_active = false
        search_results = {}
        search_query = ""
        search_buffer = ""
        search_cursor = 1
        search_edge = nil
        group_edit_search_positions = {}
        search_clear_return_snapshot()
    end

    group_edit_occurrence_selected = {}
    group_edit_occurrence_base_selected = {}
    group_select_path = {}
    group_select_dir_path = {}
    group_select_path_lookup = {}

    if #group_results <= 0 then
        local msg = "Group " .. tostring(slot) .. " empty"

        ----------------------------------------------------
        -- Il Group non esiste più come recinto navigabile.
        -- Elimina anche il ritorno F7 salvato verso quel Group.
        ----------------------------------------------------
        f7_grid_return_snapshot = nil
        f7_return_mode = "all"
        f7_return_group_slot = nil
        f7_return_param_index = nil

        if type(search_clear_return_snapshot) == "function" then
            search_clear_return_snapshot()
        end

        group_active = false
        clear_group_context()

        if type(load_f7_runtime_selection_for_current_fx) == "function" then
            load_f7_runtime_selection_for_current_fx()
        end

        mode = "list"
        value_return_mode = "list"
        numeric_return_mode = "list"
        active_pos = 1
        sync_param_from_active_pos()
        save_current_entry_state()

        if speak_it ~= false then
            speak(msg)
        end

        return true
    end

    active_pos = clamp_int(first_removed, 1, #group_results)
    sync_param_from_active_pos()
    save_current_param_position()
    save_current_entry_state()

    if mode == "group_edit" then
        set_f7_group_edit_context(slot)
        group_edit_reset_path_to_pos(active_pos)
    else
        group_active = true
        set_loaded_group_context(slot)
    end

    if speak_it ~= false then
        local prefix = #ordered == 1 and "Removed from group" or
            ("Removed " .. tostring(#ordered) .. " parameters from group")
        speak(prefix .. ". " .. get_param_label())
    end

    return true
end

function group_remove_current_occurrence()
    --------------------------------------------------------
    -- Il Group normale è read only; la rimozione vive in F7.
    --------------------------------------------------------
    if mode ~= "group_edit" or
       not group_edit_uses_group_occurrences() then
        return speak_f7_edit_required()
    end

    return group_remove_selected_occurrences()
end
function group_remove_selected_occurrences()
    if not group_edit_uses_group_occurrences() then
        return false
    end

    local positions = group_edit_selected_group_positions()

    if #positions <= 0 then
        local pos = group_edit_visible_pos_to_group_pos(active_pos)
        if pos ~= nil then positions[1] = pos end
    end

    return group_remove_positions(
        group_edit_loaded_slot,
        positions,
        true
    )
end

------------------------------------------------------------
-- GROUP REALE: MOVE LOCALE, SENZA TOCCARE CUSTOM ORDER
------------------------------------------------------------
function group_move_current_to_pos(new_pos, label)
    --------------------------------------------------------
    -- Lo spostamento singolo fuori da F7 è stato rimosso.
    -- In F7 si usa selezione + Cut/Paste.
    --------------------------------------------------------
    return speak_f7_edit_required()
end
function group_move_current_vertical(direction)
    local count = #(group_results or {})
    if count <= 0 then return false end

    local col_start, col_end = group_edit_get_column_bounds(active_pos)
    local new_pos = clamp_int(active_pos + direction, col_start, col_end)

    return group_move_current_to_pos(
        new_pos,
        direction < 0 and "Moved up" or "Moved down"
    )
end

function group_move_current_horizontal(direction)
    local count = #(group_results or {})
    if count <= 0 then return false end

    local safe_grid = clamp_int(grid_size, GRID_MIN, GRID_MAX)
    local row = (active_pos - 1) % safe_grid
    local col_start =
        math.floor((active_pos - 1) / safe_grid) * safe_grid + 1
    local new_col_start = col_start + (safe_grid * direction)

    if new_col_start < 1 or new_col_start > count then
        return false
    end

    local new_pos = new_col_start + row
    if new_pos > count then new_pos = count end

    return group_move_current_to_pos(
        new_pos,
        direction < 0 and "Moved left" or "Moved right"
    )
end

function group_move_current_page(direction)
    local count = #(group_results or {})
    if count <= 0 then return false end

    local col_start, col_end = group_edit_get_column_bounds(active_pos)
    local amount = get_page_nav_amount() * direction
    local new_pos = clamp_int(active_pos + amount, col_start, col_end)

    return group_move_current_to_pos(
        new_pos,
        direction < 0 and "Moved page up" or "Moved page down"
    )
end

function group_move_current_to_column_edge(to_end)
    local count = #(group_results or {})
    if count <= 0 then return false end

    local col_start, col_end = group_edit_get_column_bounds(active_pos)
    local target = to_end and col_end or col_start

    return group_move_current_to_pos(
        target,
        to_end and "Moved to column end" or "Moved to column start"
    )
end

function group_move_current_to_list_edge(to_end)
    local count = #(group_results or {})
    if count <= 0 then return false end

    local target = to_end and count or 1

    return group_move_current_to_pos(
        target,
        to_end and "Moved to last parameter" or "Moved to first parameter"
    )
end

function handle_shift_custom_order_keys(char)
    --------------------------------------------------------
    -- Rimosso: fuori da F7 Shift non modifica più né Custom
    -- né Group. Dentro F7 lo Shift è gestito dal motore di
    -- selezione/serpentone.
    --------------------------------------------------------
    return false
end
function toggle_loaded_group_edit_all_parameters(function_slot)
    if mode ~= "group_edit" or
       group_edit_loaded_slot == nil or
       group_edit_loaded_slot ~= function_slot then
        return false
    end

    clear_param_memory_arm()
    disarm_slot_deletes()

    local old_param = param_index

    --------------------------------------------------------
    -- Ctrl+Fn dentro F7 su un Group reale alterna soltanto
    -- il recinto visibile: Group <-> tutti i parametri.
    -- F7 resta attivo e le due selezioni restano separate.
    --------------------------------------------------------
    search_active = false
    search_results = {}
    search_query = ""
    search_buffer = ""
    search_cursor = 1
    search_edge = nil
    group_edit_search_positions = {}

    if type(search_clear_return_snapshot) == "function" then
        search_clear_return_snapshot()
    end

    group_select_path = {}
    group_select_dir_path = {}
    group_select_path_lookup = {}

    if group_edit_show_all_params ~= true then
        group_edit_show_all_params = true

        -- La vista completa usa la selezione F7 generale del FX.
        load_f7_runtime_selection_for_current_fx()
        build_all_param_indices()

        if old_param ~= nil and
           not set_param_index_absolute(old_param, false) then
            active_pos = 1
            sync_param_from_active_pos()
        end
    else
        -- Conserva la selezione completa, poi torna alle occorrenze Group.
        save_f7_runtime_selection_for_current_fx()
        group_edit_show_all_params = false
        rebuild_group_membership_from_results()

        local found_pos = nil

        if old_param ~= nil then
            for pos = 1, #(group_results or {}) do
                if group_results[pos] == old_param then
                    found_pos = pos
                    break
                end
            end
        end

        active_pos = clamp_int(
            found_pos or active_pos or 1,
            1,
            math.max(1, #group_results)
        )
        sync_param_from_active_pos()
    end

    mode = "group_edit"
    value_return_mode = "group_edit"
    numeric_return_mode = "group_edit"
    group_active = false

    group_edit_reset_path_to_pos(active_pos)
    save_current_param_position()
    save_current_entry_state()
    announce_grid_context(nil)

    return true
end

function handle_ctrl_function_slot(function_slot, save_slot)
    if function_slot == nil then
        return false
    end

    save_slot = save_slot == true

    --------------------------------------------------------
    -- Selettori indipendenti:
    --   Ctrl+G = Groups
    --   Ctrl+M = Memory positions
    --
    -- La scelta è autoritativa per F1 ... F12 anche in F7.
    -- F7 non forza più Groups e la griglia normale non forza
    -- più Memory positions.
    --
    -- Ctrl+F1 ... F12       = richiama dal recinto scelto.
    -- Ctrl+Shift+F1 ... F12 = salva nel recinto scelto.
    --------------------------------------------------------
    if save_slot then
        if slot_access_mode == "group" then
            return save_group_slot(function_slot)
        end

        return save_param_memory_slot(function_slot)
    end

    if slot_access_mode == "group" then
        ----------------------------------------------------
        -- Ctrl+F1 ... F12 nei Groups apre il Group richiesto.
        -- Ripremere lo STESSO slot non chiude il Group: ripete
        -- nome/contesto e parametro corrente.
        --
        -- Per uscire dal Group si usa Ctrl+L. Ctrl+L non cambia
        -- lo stato della Custom order: rivela semplicemente il
        -- recinto stabile sottostante, Custom oppure Plugin order.
        --
        -- Un Ctrl+F diverso mentre un Group è aperto carica
        -- direttamente l'altro Group.
        ----------------------------------------------------
        if mode ~= "group_edit" and
           group_active and
           current_group_slot == function_slot then

            ------------------------------------------------
            -- Lo stesso Ctrl+Fn NON chiude più il Group.
            -- Ripete semplicemente contesto e parametro corrente.
            ------------------------------------------------
            announce_grid_context(nil)
            return true
        end

        if mode == "group_edit" then
            if group_edit_loaded_slot == function_slot then
                return toggle_loaded_group_edit_all_parameters(function_slot)
            end

            ------------------------------------------------
            -- Richiamare un Group diverso mentre F7 è aperto apre
            -- quel Group e poi entra nel suo editor autonomo.
            ------------------------------------------------
            local ok = load_group_slot(function_slot)

            if ok then
                enter_group_edit_mode()
            end

            return true
        end

        clear_param_memory_arm()
        disarm_slot_deletes()

        load_group_slot(function_slot)
        return true
    end

    if mode == "group_edit" then
        return jump_to_param_memory_slot_inside_group_edit(function_slot)
    end

    handle_param_memory_slot(function_slot)

    return true
end

function handle_list_navigation_keys(char)
    local is_ctrl = ctrl_down()

    --------------------------------------------------------
    -- FX offline: la griglia è vuota apposta.
    -- Le frecce e i tasti di navigazione devono comunque
    -- ripetere sempre il messaggio fisso dell'FX offline,
    -- invece di restare muti perché non ci sono parametri.
    --------------------------------------------------------
    if fx_offline_grid_active then
        if char == KEY_UP or
           char == KEY_DOWN or
           char == KEY_LEFT or
           char == KEY_RIGHT or
           char == KEY_HOME or
           char == KEY_END or
           char == KEY_PAGE_UP or
           char == KEY_PAGE_DOWN then

            cancel_pending_speech()
            speak(get_fx_offline_grid_label())
            return true
        end
    end

    if char == KEY_UP then
        list_move_vertical(-1)
        return true

    elseif char == KEY_DOWN then
        list_move_vertical(1)
        return true

    elseif char == KEY_LEFT then
        list_move_horizontal(-1)
        return true

    elseif char == KEY_RIGHT then
        list_move_horizontal(1)
        return true

    elseif char == KEY_HOME then
        if is_ctrl then
            list_last()
        else
            list_column_end()
        end

        return true

    elseif char == KEY_END then
        if is_ctrl then
            list_first()
        else
            list_column_home()
        end

        return true

    elseif char == KEY_PAGE_UP then
        list_move_by_step(-1)
        return true

    elseif char == KEY_PAGE_DOWN then
        list_move_by_step(1)
        return true

    elseif char == KEY_ENTER then
        enter_value_mode()
        return true
    end

    return false
end

function handle_letter_jump(char)
    if ctrl_down() or alt_down() then
        return false
    end

    char = tonumber(char) or 0

    if char < 32 or char > 255 then
        return false
    end

    local ok, key = pcall(string.char, char)

    if not ok or not key then
        return false
    end

    key = key:lower()

    if key == " " then
        return false
    end

    list_cycle_by_initial(key)

    return true
end

------------------------------------------------------------
-- 8.1A - CTRL+ENTER LEGATO A CTRL+G / CTRL+M
--
-- Ctrl+G selezionato:
--   CTRL+ENTER = rinomina il gruppo corrente.
--
-- Ctrl+M selezionato:
--   CTRL+ENTER = rinomina il parametro corrente.
--
-- F7 non cambia il significato del comando. Se F7 è stato
-- aperto da un gruppo salvato, Ctrl+G + Ctrl+Enter rinomina
-- quel gruppo sottostante senza uscire da Edit group.
------------------------------------------------------------
function handle_ctrl_enter_contextual_name_edit()
    --------------------------------------------------------
    -- Ctrl+Enter non apre più nessun rename fuori da F7.
    --------------------------------------------------------
    if not f7_structural_edit_is_active() then
        speak_f7_edit_required()
        return true
    end

    if slot_access_mode == "group" then
        local wanted_slot = current_group_slot

        if wanted_slot == nil and mode == "group_edit" then
            wanted_slot = group_edit_loaded_slot or f7_return_group_slot
        end

        if wanted_slot == nil and search_return_valid then
            wanted_slot = search_return_group_slot
        end

        start_group_name_edit(wanted_slot)
        return true
    end

    start_param_name_edit()
    return true
end
function handle_js_global_key_shortcuts()
    local js_available = type(reaper.JS_VKeys_GetState) == "function"

    if not js_available then
        transport_space_release_intercept()
        space_transport_was_down = false
        return false
    end

    local is_ctrl = js_ctrl_down_now()
    local is_shift = js_shift_down_now()
    local is_alt = js_alt_down_now()

    --------------------------------------------------------
    -- Ctrl+Alt+Shift+C: snapshot completo plugin.
    -- Letto dal current-state scanner JS, così resta affidabile
    -- anche se gfx.getchar() restituisce 0 o un codice ambiguo.
    --------------------------------------------------------
    local snapshot_c_down = js_vkey_down_now(VK_C)

    if js_key_edge(
        "ctrl_alt_shift_c_fx_snapshot",
        snapshot_c_down and is_ctrl and is_shift and is_alt
    ) then
        return fx_snapshot_copy_all_to_system_clipboard()
    end

    local space_down = js_vkey_down_now(VK_SPACE)
    local ctrl_clean_down =
        is_ctrl and
        not is_shift and
        not is_alt

    --------------------------------------------------------
    -- Ctrl+Space: Play / Pause globale.
    -- Mentre Ctrl è premuto intercettiamo Space, così la
    -- combinazione non passa anche alle shortcut native di
    -- REAPER e non retriggera dall'inizio.
    --------------------------------------------------------
    transport_space_set_intercept(ctrl_clean_down)

    if js_key_edge(
        "ctrl_space_transport",
        space_down and ctrl_clean_down
    ) then
        space_transport_was_down = true
        space_transport_swallow_queue = true
        return transport_play_pause_manual()
    end

    if not (space_down and ctrl_clean_down) then
        space_transport_was_down = false

        if not space_down then
            space_transport_swallow_queue = false
        end
    end

    --------------------------------------------------------
    -- Shift+Space: selezione/deselezione solo dentro F7.
    -- Space puro resta libero per Play / Stop.
    --------------------------------------------------------
    if js_key_edge(
        "shift_space_group_edit",
        space_down and is_shift and not is_ctrl and not is_alt and mode == "group_edit"
    ) then
        cancel_pending_speech()
        toggle_group_selected_current()
        return true
    end

    --------------------------------------------------------
    -- Space: Play / Stop globale, ma non nei campi di testo.
    -- Se il transport è in pausa, riparte subito.
    --------------------------------------------------------
    if js_key_edge(
        "plain_space_transport",
        space_down and not is_ctrl and not is_shift and not is_alt and not mode_is_text_edit()
    ) then
        return transport_play_stop_manual()
    end

    --------------------------------------------------------
    -- Ctrl+1 ... Ctrl+0: marker 1 ... 10.
    -- Anche questi possono arrivare con gfx.getchar() == 0,
    -- quindi li leggiamo dal JS current-state scanner.
    --------------------------------------------------------
    if is_ctrl and not is_shift and not is_alt then
        local digit_vks = {
            VK_1, VK_2, VK_3, VK_4, VK_5,
            VK_6, VK_7, VK_8, VK_9, VK_0
        }

        for i = 1, #digit_vks do
            local vk = digit_vks[i]
            local down = js_vkey_down_now(vk)
            local marker_number = js_digit_vk_to_marker_number(vk)

            if js_key_edge("ctrl_digit_" .. tostring(vk), down) then
                return goto_normal_marker_number(marker_number)
            end
        end
    else
        js_clear_key_edge("ctrl_digit_" .. tostring(VK_0))
        js_clear_key_edge("ctrl_digit_" .. tostring(VK_1))
        js_clear_key_edge("ctrl_digit_" .. tostring(VK_2))
        js_clear_key_edge("ctrl_digit_" .. tostring(VK_3))
        js_clear_key_edge("ctrl_digit_" .. tostring(VK_4))
        js_clear_key_edge("ctrl_digit_" .. tostring(VK_5))
        js_clear_key_edge("ctrl_digit_" .. tostring(VK_6))
        js_clear_key_edge("ctrl_digit_" .. tostring(VK_7))
        js_clear_key_edge("ctrl_digit_" .. tostring(VK_8))
        js_clear_key_edge("ctrl_digit_" .. tostring(VK_9))
    end

    return false
end

------------------------------------------------------------
-- 8.2 - MAIN LOOP
------------------------------------------------------------
function main_loop()
    if background_focus_mode == true then
        background_defer_loop_tick()
        return
    end

    local char = gfx.getchar()

    if char and char > 0 then
        plugin_txt_note_user_activity()
    elseif char == 0 then
        plugin_txt_save_deferred_if_idle()
    end

    --------------------------------------------------------
    -- Finestra chiusa: salva il TXT e termina senza parlare.
    --------------------------------------------------------
if char < 0 then
    if type(transport_space_release_intercept) == "function" then
        transport_space_release_intercept()
    end

    --------------------------------------------------------
    -- Finestra chiusa:
    -- salva tutto senza parlare.
    --
    -- Se il default era stato cancellato in F8 ed era pending,
    -- prima rigenera il nuovo default snapshot.
    --------------------------------------------------------
    if default_snapshot_pending_regenerate then
        if type(plugin_default_snapshot_regenerate_pending_core) == "function" then
            plugin_default_snapshot_regenerate_pending_core()
        end
    end

    if fx_count and fx_count > 0 then
        save_current_fx_position()
    end

    if param_count and param_count > 0 and
       type(param_index_is_valid) == "function" and
       param_index_is_valid(param_index) then

        save_current_param_position()
        save_current_entry_state()
    end

    if mode == "fx_browser" then
        save_current_area_state("browser")
    else
        save_current_area_state("grid")
    end

    if type(save_current_plugin_profile_before_switch) == "function" then
        save_current_plugin_profile_before_switch()
    else
        if type(save_plugin_step_grid_to_txt) == "function" then
            save_plugin_step_grid_to_txt()
        end

        if type(save_custom_order_to_txt) == "function" then
            save_custom_order_to_txt()
        end

        save_plugin_txt_now()
    end

    return
end

    local is_ctrl = ctrl_down()
    local is_shift = shift_down()
    local is_alt = alt_down()
    local function_slot = function_key_to_slot(char)

    if runtime_safe_mode == true and function_slot ~= nil then
        continue_main_loop()
        return
    end

--------------------------------------------------------
-- CTRL+SHIFT+ALT+F1:
-- legge description, version e author dall'header del file.
-- Globale: funziona da qualunque punto dello script.
--------------------------------------------------------
if is_ctrl and is_shift and is_alt and char == KEY_F1 then
    speak_script_version()

    continue_main_loop()
    return
end


--------------------------------------------------------
-- SHIFT+C:
-- attiva/disattiva la mappa dei CC fissi salvati nel TXT.
-- Ctrl+Alt+C resta CC Learn; Ctrl+Shift+C resta Floating CC.
--------------------------------------------------------
if not mode_is_text_edit() and
   not is_ctrl and is_shift and not is_alt and char == KEY_C then

    cc_runtime_toggle_fixed_map()

    continue_main_loop()
    return
end

--------------------------------------------------------
-- JS KEY GLOBALS:
-- Ctrl+Space, Space, Shift+Space in F7,
-- Ctrl+1 ... Ctrl+0 marker direct.
--------------------------------------------------------
if handle_js_global_key_shortcuts() then
    continue_main_loop()
    return
end

--------------------------------------------------------
-- CTRL+ALT+SHIFT+C fallback da gfx.getchar().
-- Normalmente viene già preso dal JS current-state scanner.
--------------------------------------------------------
if type(reaper.JS_VKeys_GetState) ~= "function" and
   is_ctrl and is_shift and is_alt and
   (char == KEY_CTRL_C or char == KEY_CTRL_ALT_C or char == KEY_C) then

    fx_snapshot_copy_all_to_system_clipboard()

    continue_main_loop()
    return
end

--------------------------------------------------------
-- CTRL+V globale per snapshot FX Param.
-- Se il clipboard NON è uno snapshot, non intercetta nulla:
-- i vecchi Ctrl+V (Value mode / Custom order / campi)
-- continuano più sotto senza cambiamenti.
--------------------------------------------------------
if is_ctrl and not is_shift and not is_alt and char == KEY_CTRL_V then
    if fx_snapshot_try_paste_from_system_clipboard() then
        continue_main_loop()
        return
    end
end

--------------------------------------------------------
-- CC POLL:
-- - in CC Learn cattura il CC da imparare;
-- - in Floating CC usa un solo CC volante sul parametro corrente;
-- - altrimenti applica i CC salvati nel TXT.
--------------------------------------------------------
if mode == "cc_learn" then
    cc_learn_poll_recent_input()

elseif cc_runtime_fixed_map_enabled == true then
    ----------------------------------------------------
    -- Shift+C On ha priorità sul Floating CC.
    -- Così, quando lo stato viene ripristinato dal TXT del
    -- plugin, i CC fissi ricominciano subito a muovere i
    -- parametri senza dover fare Off/On manuale.
    ----------------------------------------------------
    cc_runtime_poll_recent_input()

elseif cc_focus_active or cc_focus_waiting then
    cc_focus_poll_recent_input()

else
    cc_runtime_poll_recent_input()
end    

    --------------------------------------------------------
    -- F8 MEMORY MANAGER:
    -- finestra gestionale protetta.
    -- Lascia navigazione/gestione F8, Alt+freccia sinistra/destra per Step e
    -- versione globale. Blocca preset, Value mode,
    -- numeric edit e modifiche del parametro sottostante.
    --------------------------------------------------------
    if mode == "memory_manager" then
        handle_memory_manager_key(char)

        continue_main_loop()
        return
    end

    --------------------------------------------------------
    -- ALT+F1 / ALT+F2:
    -- preset precedente / successivo dell'FX corrente.
    -- Alt+F11/F12 restano liberi per OSARA Peak Watcher.
    --------------------------------------------------------
    if handle_preset_navigation_keys(char) then
        continue_main_loop()
        return
    end

    --------------------------------------------------------
    -- OSARA Peak Watcher:
    -- Alt+F10/F11/F12 e Alt+Shift+F10/F11/F12.
        --------------------------------------------------------
    if handle_osara_peak_watcher_keys(char) then
        continue_main_loop()
        return
    end

    --------------------------------------------------------
    -- F10:
    -- apre Parameter Library da qualunque griglia stabile.
    -- In F7 porta anche la selezione corrente; fuori da F7
    -- la Library apre solo F1. F8 è già intercettato sopra.
    --------------------------------------------------------
    if char == KEY_F10 and
       not is_ctrl and not is_shift and not is_alt then

        if paramlib_can_open_from_current_context() then
            switch_to_parameter_library_script()
            return
        end
    end

    --------------------------------------------------------
    -- CTRL+SHIFT+F:
    -- apre la FX chain del contesto corrente.
    --------------------------------------------------------
    if is_ctrl and is_shift and not is_alt and char == KEY_CTRL_F then
        open_current_context_fx_chain()
        return
    end

    --------------------------------------------------------
    -- ALT+SHIFT+F:
    -- apre il browser FX nativo di REAPER e chiude questo
    -- loop gfx, così il campo ricerca del browser può ricevere
    -- tastiera e focus.
    --
    -- In gfx.getchar(), Alt+Shift+F può arrivare come char 326,
    -- non come normale lettera "f".
    --------------------------------------------------------
    if is_alt and is_shift and not is_ctrl then
        local c = safe_char(char)

        if (c and c:lower() == "f") or
           char == 70 or
           char == 102 or
           char == 326 then

            open_reaper_fx_browser_window()
            return
        end
    end    

    --------------------------------------------------------
    -- CTRL+W:
    -- da item/take FX torna ai Track FX della traccia corrente.
    -- Se siamo già nei Track FX, non fa nulla.
    --------------------------------------------------------
    if is_ctrl and not is_shift and not is_alt and char == KEY_CTRL_W then
        if type(switch_take_context_to_current_track_fx) == "function" then
            if switch_take_context_to_current_track_fx() then
                continue_main_loop()
                return
            end
        end
    end

    --------------------------------------------------------
    -- CTRL+PAGE UP / CTRL+PAGE DOWN:
    -- cambio traccia senza uscire dallo script.
    --------------------------------------------------------
    if is_ctrl and not is_shift and not is_alt and char == KEY_PAGE_UP then
        handle_ctrl_page_track_nav(-1)

        continue_main_loop()
        return
    end

    if is_ctrl and not is_shift and not is_alt and char == KEY_PAGE_DOWN then
        handle_ctrl_page_track_nav(1)

        continue_main_loop()
        return
    end

    --------------------------------------------------------
    -- CTRL+LEFT / CTRL+RIGHT:
    -- cambio item/take senza uscire dallo script.
    --
    -- Nei campi testo NON deve cambiare item:
    -- lì Ctrl+Left / Ctrl+Right serve per muoversi parola per parola.
    --------------------------------------------------------
    if mode ~= "search_edit" and
       mode ~= "name_edit" and
       mode ~= "group_name_edit" and
       is_ctrl and not is_shift and not is_alt and char == KEY_LEFT then

        handle_ctrl_left_right_item_nav(-1)

        continue_main_loop()
        return
    end

    if mode ~= "search_edit" and
       mode ~= "name_edit" and
       mode ~= "group_name_edit" and
       is_ctrl and not is_shift and not is_alt and char == KEY_RIGHT then

        handle_ctrl_left_right_item_nav(1)

        continue_main_loop()
        return
    end

    --------------------------------------------------------
    -- CTRL+Q:
    -- lascia FX Params vivo in background, con CC attivi,
    -- e torna a REAPER/TCP.
    --------------------------------------------------------
    if char == KEY_CTRL_Q then
        leave_script_focus_to_tcp_background()
        continue_main_loop()
        return
    end

    --------------------------------------------------------
    -- CTRL+TAB:
    -- - dentro F7 passa a Parameter Library;
    -- - fuori da F7 mantiene il passaggio storico a Track Params.
    --------------------------------------------------------
    if ctrl_tab_to_track_params_key(char) then
        if mode == "group_edit" then
            switch_to_parameter_library_script()
        else
            switch_to_track_params_script()
        end
        return
    end

    --------------------------------------------------------
    -- CTRL+I / CTRL+O:
    -- marker normale precedente / successivo.
    -- Deve stare presto, perché CTRL+I usa lo stesso codice
    -- numerico di TAB dentro gfx.getchar().
    --------------------------------------------------------
    if handle_ctrl_marker_keys(char) then
        continue_main_loop()
        return
    end

    --------------------------------------------------------
    -- CC LEARN MODE:
    -- Esc oppure Ctrl+Alt+C disarmano il learn e ritornano
    -- allo script. Esc non chiude lo script mentre il learn
    -- è armato.
    --------------------------------------------------------
    if mode == "cc_learn" then
        handle_cc_learn_key(char)

        continue_main_loop()
        return
    end

    --------------------------------------------------------
    -- ESC:
    -- nei recinti temporanei NON chiude lo script.
    -- Torna esattamente al contesto di origine.
    -- Solo dalla griglia stabile mantiene l'uscita globale.
    --------------------------------------------------------
if char == KEY_ESC then
    ----------------------------------------------------
    -- Numeric edit: annulla il buffer, senza applicarlo.
    ----------------------------------------------------
    if edit_mode then
        cancel_numeric_edit()
        continue_main_loop()
        return
    end

    ----------------------------------------------------
    -- Value: chiude Value e torna alla griglia da cui era entrato.
    ----------------------------------------------------
    if mode == "value" then
        exit_value_mode()
        continue_main_loop()
        return
    end

    ----------------------------------------------------
    -- Recent: stesso ritorno del secondo Ctrl+R.
    ----------------------------------------------------
    if mode == "recent" then
        recent_restore_return_snapshot(true)
        continue_main_loop()
        return
    end

    ----------------------------------------------------
    -- Search ha priorità su F7.
    --
    -- Se siamo dentro Edit F7 con una lente Search attiva,
    -- Esc deve chiudere SOLO Search e restare in Edit F7.
    -- Lo stesso vale mentre si sta ancora scrivendo nel campo
    -- Search. Solo un Esc successivo, senza più Search, può
    -- uscire da F7 verso Plugin order / Custom order / Group.
    ----------------------------------------------------
    if mode == "search_edit" or
       search_active or
       search_return_valid then

        search_restore_return_snapshot()
        continue_main_loop()
        return
    end

    ----------------------------------------------------
    -- F7: Esc equivale a ripremere F7 SOLO quando non c'è
    -- una Search attiva sopra Edit.
    ----------------------------------------------------
    if mode == "group_edit" then
        restore_f7_return_snapshot()
        continue_main_loop()
        return
    end

    exit_script()
    return
end

    --------------------------------------------------------
    -- TRANSPORT GLOBALE / SPAZIO NEI CAMPI TESTO
    --
    -- La gestione affidabile di Ctrl+Space, Space e
    -- Shift+Space in F7 avviene sopra tramite JS_VKeys.
    -- Questo blocco resta come fallback quando Space arriva
    -- da gfx.getchar() e per inserire spazio nei campi testo.
    --------------------------------------------------------
    if char == KEY_SPACE then
        cancel_pending_speech()

        if transport_should_swallow_space_char(char) then
            -- già gestito dal polling JS di Ctrl+Spazio

        elseif mode == "search_edit" and not is_ctrl and not is_alt then
            handle_search_edit(char)

        elseif mode == "name_edit" and not is_ctrl and not is_alt then
            handle_param_name_edit(char)

        elseif mode == "group_name_edit" and not is_ctrl and not is_alt then
            handle_group_name_edit(char)

        elseif mode == "group_edit" and is_shift and not is_ctrl and not is_alt then
            toggle_group_selected_current()

        elseif is_ctrl and not is_shift and not is_alt then
            transport_play_pause_manual()

        elseif not is_ctrl and not is_shift and not is_alt then
            transport_play_stop_manual()
        end

        continue_main_loop()
        return
    end

    --------------------------------------------------------
    -- CTRL+Z: undo REAPER.
    --------------------------------------------------------
    if char == KEY_CTRL_Z then
        cancel_pending_speech()
        reaper.Main_OnCommand(CMD_UNDO, 0)

        continue_main_loop()
        return
    end

    --------------------------------------------------------
    -- CTRL+ALT+B:
    -- passa l'FX selezionato da online a offline e viceversa.
    -- Se torna online, la griglia viene ricostruita con i
    -- parametri reali del plugin.
    --------------------------------------------------------
    if (is_ctrl and is_alt and not is_shift and char == KEY_CTRL_B) or
       char == KEY_CTRL_ALT_B then
        toggle_current_fx_offline()

        continue_main_loop()
        return
    end

    --------------------------------------------------------
    -- CTRL+B:
    -- Griglia parametri:
    --   toggle bypass del plugin corrente.
    --
    -- Browser FX:
    --   toggle bypass del plugin evidenziato nel browser.
    --------------------------------------------------------
    if char == KEY_CTRL_B then
        if mode == "fx_browser" then
            toggle_fx_browser_entry_bypass()
        else
            toggle_current_fx_bypass()
        end

        continue_main_loop()
        return
    end

--------------------------------------------------------
-- SHIFT+\:
-- legge solo nome parametro e valore.
-- Non legge griglia, gruppo, posizione, CC o contesto.
--
-- In gfx.getchar() Shift+\ arriva come 124.
--------------------------------------------------------
if not is_ctrl and is_shift and not is_alt and
   char == KEY_SHIFT_BACKSLASH then

    announce_param_name_value_only()

    continue_main_loop()
    return
end

--------------------------------------------------------
-- CTRL+SHIFT+C:
-- Floating CC volatile.
--
-- Primo Ctrl+Shift+C:
--   cattura il prossimo CC MIDI e lo usa sempre
--   sul parametro corrente.
--
-- Secondo Ctrl+Shift+C:
--   spegne il Floating CC e riattiva i CC normali salvati.
--------------------------------------------------------
if is_ctrl and is_shift and not is_alt and char == KEY_CTRL_C then
    toggle_cc_focus_mode()

    continue_main_loop()
    return
end

--------------------------------------------------------
-- CTRL+T:
-- attiva/disattiva il parlato dei valori combo/discreti
-- mossi tramite CC normale o Floating CC.
--
-- In gfx.getchar(), Ctrl+T arriva come 20.
--------------------------------------------------------
if is_ctrl and not is_shift and not is_alt and char == 20 then
    toggle_cc_combo_speech()

    continue_main_loop()
    return
end

    --------------------------------------------------------
    -- CTRL+ALT+C:
    -- CC Learn veloce sul parametro corrente.
    -- Ctrl+C resta libero e non arma più il learn.
    --------------------------------------------------------
    if is_ctrl and not is_shift and is_alt and
       (char == KEY_CTRL_C or char == KEY_CTRL_ALT_C) then

        start_cc_learn_mode()

        continue_main_loop()
        return
    end

    --------------------------------------------------------
    -- CTRL+DELETE:
    -- modifica la struttura soltanto in Custom o nel Group.
    -- Plugin order resta read only anche dentro F7/Search.
    --------------------------------------------------------
    if is_ctrl and not is_shift and not is_alt and char == KEY_DELETE then
        if mode ~= "group_edit" then
            speak_f7_edit_required()

        elseif group_edit_loaded_slot ~= nil and
               group_edit_show_all_params == true then
            speak("Return to group before remove")

        elseif group_edit_uses_group_occurrences() then
            group_remove_selected_occurrences()

        elseif get_structural_edit_container() == "custom" and
               type(hide_f7_selected_params_in_custom_order) == "function" then
            hide_f7_selected_params_in_custom_order()

        else
            speak_f7_edit_required()
        end

        continue_main_loop()
        return
    end

--------------------------------------------------------
-- ALT+F1 / ALT+F2:
-- preset precedente / successivo dell'FX corrente.
--------------------------------------------------------
if handle_preset_navigation_keys(char) then
    continue_main_loop()
    return
end

--------------------------------------------------------
-- ALT+F3 / ALT+F4:
-- parametro Auto precedente / successivo nel solo FX corrente.
--------------------------------------------------------
if handle_auto_param_navigation_keys(char) then
    continue_main_loop()
    return
end

    --------------------------------------------------------
    -- CTRL+L:
    -- Plugin order <-> Custom order.
    --------------------------------------------------------
    if is_ctrl and not is_shift and not is_alt and char == KEY_CTRL_L then
        toggle_custom_order_or_plugin_order()

        continue_main_loop()
        return
    end
    
    --------------------------------------------------------
    -- CTRL+SHIFT+UP / DOWN:
    -- sposta fisicamente l'FX nella catena.
    -- Deve stare prima di CTRL+UP/DOWN.
    -- In F7 non deve intervenire.
    --------------------------------------------------------
    if mode ~= "group_edit" and
       is_ctrl and is_shift and not is_alt and char == KEY_UP then

        move_current_fx_in_chain(-1)

        continue_main_loop()
        return
    end

    if mode ~= "group_edit" and
       is_ctrl and is_shift and not is_alt and char == KEY_DOWN then

        move_current_fx_in_chain(1)

        continue_main_loop()
        return
    end

    --------------------------------------------------------
    -- EDIT NUMERICO
    -- Deve stare prima di FX browser, Value mode, Ctrl+V,
    -- Ctrl+G, Ctrl+M e altri comandi globali: quando Ctrl+E apre
    -- l'edit, tutti i tasti successivi devono andare al campo
    -- numerico finché non viene confermato o annullato.
    --------------------------------------------------------
    if edit_mode then
        handle_numeric_edit(char)

        continue_main_loop()
        return
    end

    --------------------------------------------------------
    -- FX BROWSER
    --------------------------------------------------------
    if mode == "fx_browser" then
        handle_fx_browser_key(char)

        continue_main_loop()
        return
    end

    --------------------------------------------------------
    -- VALUE MODE
    -- In questa modalità le frecce modificano direttamente
    -- il valore del parametro corrente.
    --------------------------------------------------------
    if mode == "value" then
        handle_value_mode_key(char)

        continue_main_loop()
        return
    end

    --------------------------------------------------------
    -- ALT + NAVIGAZIONE VALORE DALLA GRIGLIA
    --------------------------------------------------------
    if is_alt and handle_alt_value_keys(char) then
        continue_main_loop()
        return
    end

    --------------------------------------------------------
    -- SHIFT + NAVIGAZIONE FUORI DA F7:
    -- nessuna modifica strutturale. Custom e Group normali sono
    -- viste; il serpentone esiste soltanto dentro F7.
    --------------------------------------------------------
    if mode ~= "group_edit" and
       is_shift and not is_alt and
       (
           (not is_ctrl and
            (char == KEY_UP or char == KEY_DOWN or
             char == KEY_LEFT or char == KEY_RIGHT or
             char == KEY_PAGE_UP or char == KEY_PAGE_DOWN or
             char == KEY_HOME or char == KEY_END))
           or
           (is_ctrl and (char == KEY_HOME or char == KEY_END))
       ) then

        continue_main_loop()
        return
    end

    --------------------------------------------------------
    -- CTRL+F1 ... CTRL+F12
    --------------------------------------------------------
    if is_ctrl and not is_alt and function_slot ~= nil then
        handle_ctrl_function_slot(function_slot, is_shift)

        continue_main_loop()
        return
    end

    --------------------------------------------------------
    -- CTRL+SHIFT+ALT+A:
    -- disattiva e nasconde tutti gli envelope del solo FX corrente.
    --------------------------------------------------------
    if is_ctrl and is_shift and is_alt and
       (char == KEY_CTRL_A or char == KEY_A or char == KEY_CTRL_ALT_A) then

        clear_all_current_fx_param_envelopes()

        continue_main_loop()
        return
    end

    --------------------------------------------------------
    -- CTRL+SHIFT+A:
    -- mostra/nasconde l'envelope del parametro corrente.
    --
    -- CTRL+A resta libero/coerente per selezione; in F7 mantiene
    -- il vecchio comportamento di selezionare tutto il gruppo.
    --------------------------------------------------------
    if is_ctrl and is_shift and not is_alt and char == KEY_CTRL_A then
        show_hide_current_param_envelope()

        continue_main_loop()
        return
    end

    if is_ctrl and not is_shift and not is_alt and
       char == KEY_CTRL_A and mode == "group_edit" then

        select_all_group_edit()

        continue_main_loop()
        return
    end

    --------------------------------------------------------
    -- CTRL+SHIFT+D:
    -- Delta solo dell'ultimo FX focused secondo REAPER.
    --------------------------------------------------------
    if is_ctrl and is_shift and not is_alt and char == KEY_CTRL_D then
        toggle_delta_solo_last_focused_fx()

        continue_main_loop()
        return
    end

    --------------------------------------------------------
    -- CTRL+D rimosso.
    --
    -- Il ritorno dal Group è ora Ctrl+L. Ripremere Ctrl+F1 ... F12
    -- sullo stesso slot resta nel Group e ne ripete il contesto.
    --------------------------------------------------------

    --------------------------------------------------------
    -- CTRL+UP / CTRL+DOWN:
    -- cambio plugin diretto.
    --------------------------------------------------------
    if is_ctrl and not is_shift and not is_alt and char == KEY_UP then
        switch_fx_by_direction(-1)

        continue_main_loop()
        return
    end

    if is_ctrl and not is_shift and not is_alt and char == KEY_DOWN then
        switch_fx_by_direction(1)

        continue_main_loop()
        return
    end

    --------------------------------------------------------
    -- CTRL+P:
    -- toggle Browser FX <-> Griglia parametri.
    --------------------------------------------------------
    if char == KEY_CTRL_P then
        toggle_fx_browser_or_parameter()

        continue_main_loop()
        return
    end

--------------------------------------------------------
-- CTRL+G:
-- seleziona sempre Groups. Non è più un toggle.
--------------------------------------------------------
if is_ctrl and not is_shift and not is_alt and char == KEY_CTRL_G then
    select_group_slot_access_mode()

    continue_main_loop()
    return
end

--------------------------------------------------------
-- CTRL+M:
-- seleziona sempre Memory positions.
--
-- gfx.getchar() restituisce 13, quindi deve stare PRIMA del
-- ramo Ctrl+Enter ed essere disambiguato con JS physical M.
--------------------------------------------------------
if char13_is_ctrl_m(char) then
    select_param_slot_access_mode()

    continue_main_loop()
    return
end

--------------------------------------------------------
-- CTRL+X:
-- Cut strutturale è disponibile soltanto dentro F7.
-- Rimane locale a Custom o al Group in Edit.
--------------------------------------------------------
if is_ctrl and not is_shift and not is_alt and char == KEY_CTRL_X then
    custom_cut_current_or_selected()

    continue_main_loop()
    return
end

--------------------------------------------------------
-- CTRL+C:
-- Copy strutturale è disponibile soltanto dentro F7.
-- All parameters del Group resta una sorgente neutra.
--------------------------------------------------------
if is_ctrl and not is_shift and not is_alt and char == KEY_CTRL_C then
    custom_copy_current_or_selected()

    continue_main_loop()
    return
end

--------------------------------------------------------
-- CTRL+V:
-- Paste modifica soltanto il contenitore F7 corrente.
-- Cut non può attraversare Custom <-> Group.
--------------------------------------------------------
if is_ctrl and not is_shift and not is_alt and char == KEY_CTRL_V then
    custom_paste_cut_clipboard()

    continue_main_loop()
    return
end

--------------------------------------------------------
-- CTRL+E: edit numerico diretto.
--------------------------------------------------------
if char == KEY_CTRL_E then
    enter_edit_from_anywhere()

    continue_main_loop()
    return
end

    --------------------------------------------------------
    -- CTRL+ENTER:
    -- segue il recinto sticky scelto con Ctrl+G / Ctrl+M:
    -- - Groups = rinomina il gruppo corrente;
    -- - Memory positions = rinomina il parametro corrente.
    --------------------------------------------------------
    if is_ctrl and not is_shift and not is_alt and char == KEY_ENTER then
        handle_ctrl_enter_contextual_name_edit()

        continue_main_loop()
        return
    end

    --------------------------------------------------------
    -- ENTER su ReaEQ Band Enabled:
    -- usa la stessa strada di Home/End, ma in forma toggle.
    -- Tutti gli altri parametri mantengono Enter = Value mode.
    --------------------------------------------------------
    if not is_ctrl and not is_shift and not is_alt and
       char == KEY_ENTER and
       mode == "list" and
       reaeq_virtual_enabled_enter_current and
       reaeq_virtual_enabled_enter_current() then

        continue_main_loop()
        return
    end

    --------------------------------------------------------
    -- ENTER:
    -- entra in Value mode sul parametro corrente.
    -- In F8 Enter resta gestito dalla finestra Memory manager.
    -- In F7 Enter è gestito da handle_group_edit_grid_key().
    --------------------------------------------------------
    if not is_ctrl and not is_shift and not is_alt and
       char == KEY_ENTER and
       mode == "list" then

        enter_value_mode()

        continue_main_loop()
        return
    end

    --------------------------------------------------------
    -- EDIT NOME GRUPPO
    --------------------------------------------------------
    if mode == "group_name_edit" then
        handle_group_name_edit(char)

        continue_main_loop()
        return
    end

    --------------------------------------------------------
    -- EDIT NOME PARAMETRO CUSTOM
    --------------------------------------------------------
    if mode == "name_edit" then
        handle_param_name_edit(char)

        continue_main_loop()
        return
    end

    --------------------------------------------------------
    -- EDIT NUMERICO
    --------------------------------------------------------
    if edit_mode then
        handle_numeric_edit(char)

        continue_main_loop()
        return
    end

    --------------------------------------------------------
    -- SEARCH EDIT
    --------------------------------------------------------
    if mode == "search_edit" then
        handle_search_edit(char)

        continue_main_loop()
        return
    end

    --------------------------------------------------------
    -- RECENT SEARCHES
    --------------------------------------------------------
    if mode == "recent" then
        handle_recent_key(char)

        continue_main_loop()
        return
    end

    --------------------------------------------------------
    -- Parameter Navigator.
    --------------------------------------------------------
------------------------------------------------------------
-- Parameter Navigator.
--
-- Tutti i tasti di F8 passano da handle_memory_manager_key().
-- Questo evita doppi messaggi quando il Default snapshot è pending:
-- - Enter salva e torna alla griglia;
-- - F8 salva e torna alla griglia;
-- - Esc salva ed esce.
------------------------------------------------------------
if mode == "memory_manager" then
    handle_memory_manager_key(char)

    continue_main_loop()
    return
end

    --------------------------------------------------------
    -- F7 GROUP EDIT GRID
    -- In questa modalità lo Shift è selezione, non Custom order.
    --------------------------------------------------------
    if mode == "group_edit" then
        handle_group_edit_grid_key(char)

        continue_main_loop()
        return
    end

    --------------------------------------------------------
    -- BACKSLASH:
    -- lettura corrente solo nella griglia normale.
    --------------------------------------------------------
    if char == KEY_BACKSLASH and mode == "list" then
        clear_param_memory_arm()
        disarm_slot_deletes()

        read_current_line()

        continue_main_loop()
        return
    end

--------------------------------------------------------
-- BACKSPACE:
-- - Backspace normale:
--     reset parametro corrente al default snapshot.
--
-- - Ctrl+Backspace:
--     reset dell'ultimo controllo Step / Grid.
--
-- - Ctrl+Shift+Backspace:
--     reset globale di tutti i parametri al default snapshot.
--
-- Nota:
-- KEY_BACKSPACE_3 ha lo stesso codice di KEY_DELETE.
-- Quindi NON va usato qui, altrimenti Delete verrebbe preso
-- come Backspace.
--------------------------------------------------------
if handle_backspace_reset_shortcut(char) then
    continue_main_loop()
    return
end

--------------------------------------------------------
-- CTRL+F:
-- apre sempre una nuova Search vuota sull'elenco completo.
-- Se eri nei risultati li cancella; se eri già nel campo
-- cancella il testo. Solo Esc torna al contesto di origine.
--------------------------------------------------------
if char == KEY_CTRL_F then
    toggle_search_edit_or_clear_results()

    continue_main_loop()
    return
end    

    --------------------------------------------------------
    -- CTRL+R: ricerche recenti.
    --------------------------------------------------------
    if char == KEY_CTRL_R then
        start_recent_searches()

        continue_main_loop()
        return
    end

--------------------------------------------------------
-- DELETE:
-- fuori da F7/F8 e fuori dai campi edit rimuove il CC
-- assegnato al parametro corrente.
--
-- Nei campi edit, in F7, in F8 e in CC Learn viene
-- intercettato prima dai rispettivi handler.
--------------------------------------------------------
if char == KEY_DELETE then
    clear_param_memory_arm()
    disarm_slot_deletes()

    if type(cc_learn_remove_from_param) == "function" then
        cc_learn_remove_from_param()
    else
        speak("CC remove not available")
    end

    continue_main_loop()
    return
end    

    --------------------------------------------------------
    -- TAB:
    -- solo nella griglia normale legge Step/Grid.
    --------------------------------------------------------
    if char == KEY_TAB then
        clear_param_memory_arm()
        disarm_slot_deletes()

        announce_step_grid_status()

        continue_main_loop()
        return
    end

    --------------------------------------------------------
    -- FUNCTION KEYS GLOBALI
    --------------------------------------------------------
    if handle_step_grid_keys(char) then
        continue_main_loop()
        return

    elseif char == KEY_F5 then
        disarm_slot_deletes()
        clear_param_memory_arm()

        reaper.Main_OnCommand(CMD_F5_ACTION, 0)

        continue_main_loop()
        return

    elseif char == KEY_F6 then
        disarm_slot_deletes()
        clear_param_memory_arm()

        reaper.Main_OnCommand(CMD_F6_ACTION, 0)

        continue_main_loop()
        return

    elseif char == KEY_F7 then
        toggle_f7_or_previous_grid()

        continue_main_loop()
        return

    elseif char == KEY_F8 then
        toggle_memory_manager_or_grid()

        continue_main_loop()
        return

    elseif char == KEY_F9 then
        disarm_slot_deletes()
        clear_param_memory_arm()

        reaper.Main_OnCommand(CMD_F9_ACTION, 0)

        continue_main_loop()
        return
    end

    --------------------------------------------------------
    -- LIST GRID MODE
    --------------------------------------------------------
    if mode == "list" then
        if not handle_list_navigation_keys(char) then
            handle_letter_jump(char)
        end
    end

    continue_main_loop()
end

------------------------------------------------------------
-- 8.3 - START
------------------------------------------------------------
if init_script() then
    if type(paramlib_consume_return_packet) == "function" then
        paramlib_consume_return_packet()
    end

    start_time = reaper.time_precise()

    if mode ~= "fx_browser" then
        function delayed_announce()
            if (reaper.time_precise() - start_time) > 0.35 then
                announce_startup()
            else
                reaper.defer(delayed_announce)
            end
        end

        reaper.defer(delayed_announce)
    end

    main_loop()
end

------------------------------------------------------------
-- FINE PARTE 8 / 8
------------------------------------------------------------