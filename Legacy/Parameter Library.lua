-- @description Parameter Library
-- @version 0.102
-- @author Lo-lo + GPT

------------------------------------------------------------
-- UNIVERSAL PARAMETER CELL LIBRARY
--
-- Companion to Speak FX Params - TrackTake Navigator.lua.
-- Open it with F10 from the FX parameter grid, or Ctrl+Tab from F7.
--
-- F1  Library cells for the current plugin
-- F2  Current F7 parameter selection, only when opened from F7
--
-- Ctrl+S  In F2 only: save current selection as a named TXT cell
-- Enter   F1: load current cell and return to the source position
-- Delete  F1: delete cell (two presses); F2: remove parameter
-- F10     return to the source position without loading a cell
-- Ctrl+Tab keeps the same return behavior for compatibility
-- Tab / \ read current area / current entry
------------------------------------------------------------

speech_suspended = false

function speak(msg)
    if speech_suspended then return end
    msg = tostring(msg or "")
    if msg == "" then return end

    if reaper.osara_outputMessage then
        reaper.osara_outputMessage(msg)
    else
        reaper.ShowConsoleMsg(msg .. "\n")
    end
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

function clamp_int(v, a, b)
    v = math.floor((tonumber(v) or a) + 0.5)
    a = math.floor(tonumber(a) or 1)
    b = math.floor(tonumber(b) or a)
    if a > b then a, b = b, a end
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
-- Keys / modifiers
------------------------------------------------------------
KEY_ESC = 27
KEY_BACKSPACE = 8
KEY_BACKSPACE_2 = 127
KEY_UP = 30064
KEY_DOWN = 1685026670
KEY_LEFT = 1818584692
KEY_RIGHT = 1919379572
KEY_HOME = 6647396
KEY_END = 1752132965
KEY_PAGE_UP = 1885828464
KEY_PAGE_DOWN = 1885824110
KEY_ENTER = 13
KEY_TAB = 9
KEY_DELETE = 6579564
KEY_BACKSLASH = 92
KEY_F1 = 26161
KEY_F2 = 26162
KEY_F10 = 6697264
KEY_CTRL_S = 19

MOD_CTRL = 4
MOD_SHIFT = 8
MOD_ALT = 16

VK_TAB = 0x09
VK_I = 0x49
VK_CTRL = 0x11
VK_SHIFT = 0x10
VK_ALT = 0x12

function ctrl_down()
    return (gfx.mouse_cap & MOD_CTRL) == MOD_CTRL
end

function shift_down()
    return (gfx.mouse_cap & MOD_SHIFT) == MOD_SHIFT
end

function alt_down()
    return (gfx.mouse_cap & MOD_ALT) == MOD_ALT
end

function js_vkeys_state_now()
    if type(reaper.JS_VKeys_GetState) ~= "function" then
        return ""
    end
    return reaper.JS_VKeys_GetState(-2) or ""
end

function js_vkey_down_now(vk)
    local state = js_vkeys_state_now()
    if state == "" then return false end
    return (state:byte(tonumber(vk) or 0) or 0) ~= 0
end

function ctrl_tab_key(char)
    local is_ctrl = ctrl_down() or js_vkey_down_now(VK_CTRL)
    local is_shift = shift_down() or js_vkey_down_now(VK_SHIFT)
    local is_alt = alt_down() or js_vkey_down_now(VK_ALT)

    if not is_ctrl or is_shift or is_alt or char ~= KEY_TAB then
        return false
    end

    if type(reaper.JS_VKeys_GetState) == "function" then
        return js_vkey_down_now(VK_TAB) and not js_vkey_down_now(VK_I)
    end

    return true
end

------------------------------------------------------------
-- Paths
------------------------------------------------------------
PARAMLIB_PACKET_MAGIC = "PARAMLIB_V1"
PARAMLIB_FOLDER_NAME = "Params"
PARAMLIB_HANDOFF_FILE = "_Parameter Library Handoff.txt"
PARAMLIB_RETURN_FILE = "_Parameter Library Return.txt"
FX_PARAMS_SCRIPT_NAME = "Speak FX Params - TrackTake Navigator.lua"

function get_current_script_path()
    local source = debug.getinfo(1, "S").source or ""
    if source:sub(1, 1) == "@" then source = source:sub(2) end
    return source
end

function get_current_script_folder()
    local path = get_current_script_path()
    if path == "" then return "" end
    return path:match("^(.*)[/\\][^/\\]+$") or ""
end

function join_path(a, b)
    a = tostring(a or "")
    b = tostring(b or "")
    if a == "" then return b end
    if b == "" then return a end
    local last = a:sub(-1)
    if last == "/" or last == "\\" then return a .. b end
    return a .. package.config:sub(1, 1) .. b
end

function file_exists(path)
    local f = io.open(tostring(path or ""), "rb")
    if f then f:close(); return true end
    return false
end

function ensure_folder(path)
    path = tostring(path or "")
    if path == "" then return false end

    if reaper.RecursiveCreateDirectory then
        reaper.RecursiveCreateDirectory(path, 0)
        return true
    end

    os.execute('mkdir "' .. path .. '"')
    return true
end

function get_params_root()
    return join_path(get_current_script_folder(), PARAMLIB_FOLDER_NAME)
end

function get_handoff_path()
    return join_path(get_params_root(), PARAMLIB_HANDOFF_FILE)
end

function get_return_path()
    return join_path(get_params_root(), PARAMLIB_RETURN_FILE)
end

function get_fx_params_script_path()
    return join_path(get_current_script_folder(), FX_PARAMS_SCRIPT_NAME)
end

function sanitize_plugin_folder_name(name)
    name = clean_one_line(name or "")
    if name == "" then name = "Unknown FX" end

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

    if name == "" then name = "Unknown FX" end
    if #name > 160 then name = trim(name:sub(1, 160)) end
    return name
end

function sanitize_cell_filename(name)
    name = clean_one_line(name or "")
    name = name:gsub("[/\\%*%?\"<>|:]", " - ")
    name = name:gsub("[%c]", " ")
    name = name:gsub("%s+", " ")
    name = name:gsub("^%s+", "")
    name = name:gsub("%s+$", "")
    name = name:gsub("^%.*", "")
    name = name:gsub("%.*$", "")
    if #name > 160 then name = trim(name:sub(1, 160)) end
    return name
end

------------------------------------------------------------
-- Packet / cell format
------------------------------------------------------------
function escape_field(s)
    s = tostring(s or "")
    s = s:gsub("\\", "\\\\")
    s = s:gsub("\t", "\\t")
    s = s:gsub("\r", "\\r")
    s = s:gsub("\n", "\\n")
    return s
end

function unescape_field(s)
    s = tostring(s or "")
    local out = ""
    local i = 1

    while i <= #s do
        local c = s:sub(i, i)

        if c == "\\" and i < #s then
            local n = s:sub(i + 1, i + 1)
            if n == "t" then
                out = out .. "\t"; i = i + 2
            elseif n == "r" then
                out = out .. "\r"; i = i + 2
            elseif n == "n" then
                out = out .. "\n"; i = i + 2
            elseif n == "\\" then
                out = out .. "\\"; i = i + 2
            else
                out = out .. c; i = i + 1
            end
        else
            out = out .. c
            i = i + 1
        end
    end

    return out
end

function write_packet(path, packet)
    packet = packet or {}
    local f = io.open(tostring(path or ""), "wb")
    if not f then return false end

    local records = packet.records or {}

    f:write(PARAMLIB_PACKET_MAGIC, "\r\n")
    f:write("Mode=", escape_field(packet.mode or ""), "\r\n")
    f:write("Source=", escape_field(packet.source or ""), "\r\n")
    f:write("Plugin=", escape_field(packet.plugin or ""), "\r\n")
    f:write("Cell=", escape_field(packet.cell or ""), "\r\n")
    f:write("Grid=", tostring(tonumber(packet.grid) or 1), "\r\n")
    f:write("Active=", tostring(tonumber(packet.active) or 0), "\r\n")
    f:write("Count=", tostring(#records), "\r\n")

    for n = 1, #records do
        local r = records[n] or {}
        f:write(
            "P\t",
            tostring(tonumber(r.index) or 0), "\t",
            escape_field(r.original_name or ""), "\t",
            escape_field(r.display_name or ""), "\t",
            string.format("%.17g", tonumber(r.norm) or 0), "\t",
            escape_field(r.formatted or ""),
            "\r\n"
        )
    end

    f:close()
    return true
end

function read_packet(path)
    local f = io.open(tostring(path or ""), "rb")
    if not f then return nil end

    local first = (f:read("*l") or ""):gsub("\r$", "")
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
                    original_name = unescape_field(original_name or ""),
                    display_name = unescape_field(display_name or ""),
                    norm = norm,
                    formatted = unescape_field(formatted or "")
                }
            end
        else
            local key, value = line:match("^([^=]+)=(.*)$")
            if key then
                value = unescape_field(value or "")
                if key == "Mode" then packet.mode = value
                elseif key == "Source" then packet.source = value
                elseif key == "Plugin" then packet.plugin = value
                elseif key == "Cell" then packet.cell = value
                elseif key == "Grid" then packet.grid = tonumber(value) or 1
                elseif key == "Active" then packet.active = tonumber(value) or 0
                end
            end
        end
    end

    f:close()
    return packet
end

function copy_records(records)
    local out = {}
    for n = 1, #(records or {}) do
        local r = records[n] or {}
        out[#out + 1] = {
            index = tonumber(r.index) or 0,
            original_name = tostring(r.original_name or ""),
            display_name = tostring(r.display_name or ""),
            norm = tonumber(r.norm) or 0,
            formatted = tostring(r.formatted or "")
        }
    end
    return out
end

------------------------------------------------------------
-- State
------------------------------------------------------------
handoff = nil
plugin_raw = ""
plugin_label = ""
plugin_folder = ""
grid_size = 10
return_active_param = 0
return_source = "grid"
f2_available = false
work_records = {}
cells = {}
page = 1
pos_f1 = 1
pos_f2 = 1
mode = "browse"
name_buffer = ""
name_cursor = 1
name_edit_edge = nil
name_edit_fresh = true
text_char_move_changed = true
delete_armed_path = ""

function get_current_list()
    if page == 2 then return work_records end
    return cells
end

function get_current_pos()
    if page == 2 then return pos_f2 end
    return pos_f1
end

function set_current_pos(v)
    local list = get_current_list()
    local count = #list
    local p = count > 0 and clamp_int(v, 1, count) or 1
    if page == 2 then pos_f2 = p else pos_f1 = p end
end

function disarm_delete()
    delete_armed_path = ""
end

function cell_display_name(entry)
    return clean_one_line((entry and entry.name) or "Cell")
end

function param_display_line(entry)
    entry = entry or {}
    local name = clean_one_line(entry.display_name or entry.original_name or "Parameter")
    local value = clean_one_line(entry.formatted or "")
    if value ~= "" then return name .. " " .. value end
    return name
end

function speak_current_entry(prefix)
    local list = get_current_list()
    local count = #list
    local p = get_current_pos()
    local msg = prefix and (prefix .. ". ") or ""

    if count <= 0 then
        if page == 1 then
            speak(msg .. "F1 Library. Empty")
        else
            speak(msg .. "F2 Current parameters. Empty")
        end
        return
    end

    local entry = list[p]

    if page == 1 then
        msg = msg .. cell_display_name(entry) ..
            ". " .. tostring(tonumber(entry.count) or 0) .. " parameters"
    else
        msg = msg .. param_display_line(entry)
    end

    speak(msg)
end

function speak_page_status()
    if page == 1 then
        local count = #cells
        if count <= 0 then
            speak("F1 Library. Empty")
        else
            speak(
                "F1 Library. " .. tostring(count) .. " cells. " ..
                cell_display_name(cells[pos_f1])
            )
        end
    else
        if not f2_available then
            page = 1
            speak_page_status()
            return
        end

        local count = #work_records
        if count <= 0 then
            speak("F2 Current parameters. Empty")
        else
            speak(
                "F2 Current parameters. " .. tostring(count) ..
                " parameters. " .. param_display_line(work_records[pos_f2])
            )
        end
    end
end

------------------------------------------------------------
-- Library scan / save / delete
------------------------------------------------------------
function scan_cells()
    cells = {}
    ensure_folder(plugin_folder)

    local i = 0
    while true do
        local filename = reaper.EnumerateFiles(plugin_folder, i)
        if not filename then break end
        i = i + 1

        if filename:lower():match("%.txt$") then
            local path = join_path(plugin_folder, filename)
            local packet = read_packet(path)

            if packet and clean_one_line(packet.plugin) == clean_one_line(plugin_raw) then
                local name = filename:gsub("%.[Tt][Xx][Tt]$", "")
                cells[#cells + 1] = {
                    name = name,
                    path = path,
                    count = #(packet.records or {})
                }
            end
        end
    end

    table.sort(cells, function(a, b)
        return tostring(a.name or ""):lower() < tostring(b.name or ""):lower()
    end)

    if #cells <= 0 then
        pos_f1 = 1
    else
        pos_f1 = clamp_int(pos_f1, 1, #cells)
    end
end

function save_work_cell(name)
    name = clean_one_line(name or "")

    if #work_records <= 0 then
        speak("No parameters selected")
        return false
    end

    local safe = sanitize_cell_filename(name)
    if safe == "" then
        speak("Invalid name")
        return false
    end

    ensure_folder(plugin_folder)

    local path = join_path(plugin_folder, safe .. ".txt")
    local packet = {
        mode = "cell",
        plugin = plugin_raw,
        cell = safe,
        grid = grid_size,
        active = return_active_param,
        records = work_records
    }

    if not write_packet(path, packet) then
        speak("Save failed")
        return false
    end

    scan_cells()

    for n = 1, #cells do
        if tostring(cells[n].path or "") == path then
            pos_f1 = n
            break
        end
    end

    speak("Saved " .. safe .. ". " .. tostring(#work_records) .. " parameters")
    return true
end

function delete_current_f1_cell()
    if #cells <= 0 then
        speak("Library empty")
        return false
    end

    local entry = cells[pos_f1]
    local path = tostring(entry.path or "")

    if path == "" then
        speak("No cell")
        return false
    end

    if delete_armed_path ~= path then
        delete_armed_path = path
        speak("Delete armed. " .. cell_display_name(entry) .. ". Press Delete again")
        return true
    end

    delete_armed_path = ""
    local ok = os.remove(path)

    if not ok then
        speak("Delete failed")
        return false
    end

    local old_name = cell_display_name(entry)
    scan_cells()
    speak("Deleted " .. old_name)
    return true
end

function delete_current_f2_param()
    if #work_records <= 0 then
        speak("No parameters selected")
        return false
    end

    local entry = work_records[pos_f2]
    local label = param_display_line(entry)
    table.remove(work_records, pos_f2)

    if #work_records <= 0 then
        pos_f2 = 1
        speak("Removed " .. label .. ". 0 parameters")
    else
        pos_f2 = clamp_int(pos_f2, 1, #work_records)
        speak(
            "Removed " .. label .. ". " ..
            tostring(#work_records) .. " parameters. " ..
            param_display_line(work_records[pos_f2])
        )
    end

    return true
end

------------------------------------------------------------
-- Navigation
------------------------------------------------------------
function move_grid_vertical(direction)
    local list = get_current_list()
    local count = #list
    if count <= 0 then speak_page_status(); return false end

    local pos = get_current_pos()
    local safe_grid = math.max(1, math.floor(tonumber(grid_size) or 1))
    local col_start = math.floor((pos - 1) / safe_grid) * safe_grid + 1
    local col_end = math.min(count, col_start + safe_grid - 1)
    local new_pos = pos + (direction < 0 and -1 or 1)
    if new_pos < col_start then new_pos = col_start end
    if new_pos > col_end then new_pos = col_end end

    -- Bordi silenziosi, come in FX Params:
    -- se la freccia non può muoversi non ripete la voce corrente.
    if new_pos == pos then
        return false
    end

    set_current_pos(new_pos)
    disarm_delete()
    speak_current_entry()
    return true
end

function move_grid_horizontal(direction)
    local list = get_current_list()
    local count = #list
    if count <= 0 then speak_page_status(); return false end

    local pos = get_current_pos()
    local safe_grid = math.max(1, math.floor(tonumber(grid_size) or 1))
    local row = (pos - 1) % safe_grid
    local col_start = math.floor((pos - 1) / safe_grid) * safe_grid + 1
    local new_col_start = col_start + safe_grid * (direction < 0 and -1 or 1)

    -- Bordi silenziosi.
    if new_col_start < 1 or new_col_start > count then
        return false
    end

    local new_pos = new_col_start + row
    if new_pos > count then new_pos = count end

    if new_pos == pos then
        return false
    end

    set_current_pos(new_pos)
    disarm_delete()
    speak_current_entry()
    return true
end

function move_list_page(direction)
    local list = get_current_list()
    local count = #list
    if count <= 0 then speak_page_status(); return false end

    local old_pos = get_current_pos()
    local amount = math.max(1, math.floor(tonumber(grid_size) or 1))
    local new_pos = clamp_int(
        old_pos + (direction < 0 and -amount or amount),
        1,
        count
    )

    -- Anche PageUp/PageDown non ripetono il bordo.
    if new_pos == old_pos then
        return false
    end

    set_current_pos(new_pos)
    disarm_delete()
    speak_current_entry()
    return true
end

function move_list_edge(to_end)
    local list = get_current_list()
    if #list <= 0 then speak_page_status(); return false end
    set_current_pos(to_end and #list or 1)
    disarm_delete()
    speak_current_entry()
    return true
end

function cycle_by_initial(letter)
    letter = clean_one_line(letter or ""):lower()
    if letter == "" then return false end

    local list = get_current_list()
    local count = #list
    if count <= 0 then return false end

    local start = get_current_pos() + 1

    for n = 1, count do
        local p = ((start + n - 2) % count) + 1
        local label = ""

        if page == 1 then
            label = cell_display_name(list[p])
        else
            label = clean_one_line(list[p].display_name or list[p].original_name or "")
        end

        if label:lower():sub(1, 1) == letter then
            set_current_pos(p)
            disarm_delete()
            speak_current_entry()
            return true
        end
    end

    return false
end

------------------------------------------------------------
-- Name edit
--
-- Stessa grammatica di editazione testo di FX Params:
-- - Tab / \ legge tutto il campo;
-- - Left / Right legge il carattere e resta muto ai bordi;
-- - Ctrl+Left / Ctrl+Right si muove per parole;
-- - Backspace / Delete legge il carattere rimosso;
-- - Home / End usa la stessa convenzione di FX Params;
-- - i caratteri digitati vengono pronunciati singolarmente.
------------------------------------------------------------
function text_is_word_char(ch)
    ch = tostring(ch or "")
    return ch:match("[%w_]") ~= nil
end

function text_find_word_bounds(buffer, pos)
    buffer = tostring(buffer or "")
    pos = tonumber(pos) or 1

    local len = #buffer
    if len <= 0 then return nil, nil end

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

function text_get_word_at_or_near_cursor(buffer, cursor, direction)
    buffer = tostring(buffer or "")
    cursor = tonumber(cursor) or 1
    direction = tonumber(direction) or 1

    local len = #buffer
    if len <= 0 then return "Empty" end

    cursor = clamp_int(cursor, 1, len + 1)

    local pos = cursor
    if pos > len then pos = len end
    if pos < 1 then pos = 1 end

    if text_is_word_char(buffer:sub(pos, pos)) then
        local first, last = text_find_word_bounds(buffer, pos)
        if first and last then
            return buffer:sub(first, last)
        end
    end

    pos = cursor
    if direction < 0 then pos = pos - 1 end
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
    if len <= 0 then return 1 end

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
    if len <= 0 then return 1 end

    cursor = clamp_int(cursor, 1, len + 1)
    local pos = cursor

    if pos > len then pos = len end

    if text_is_word_char(buffer:sub(pos, pos)) then
        while pos <= len and text_is_word_char(buffer:sub(pos, pos)) do
            pos = pos + 1
        end
    end

    while pos <= len and not text_is_word_char(buffer:sub(pos, pos)) do
        pos = pos + 1
    end

    if pos <= len and text_is_word_char(buffer:sub(pos, pos)) then
        return pos
    end

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

function start_name_edit()
    if not f2_available then
        return false
    end

    if #work_records <= 0 then
        speak("No parameters selected")
        return false
    end

    mode = "name_edit"
    name_buffer = ""
    name_cursor = 1
    name_edit_edge = nil
    name_edit_fresh = true
    disarm_delete()

    speak("Save edit cell name.")
    return true
end

function speak_name_edit_buffer()
    local content = name_buffer ~= "" and name_buffer or "Empty"
    speak("Edit cell name. " .. content)
end

function name_insert_char(ch)
    name_edit_edge = nil

    local left = name_buffer:sub(1, name_cursor - 1)
    local right = name_buffer:sub(name_cursor)

    name_buffer = left .. ch .. right
    name_cursor = name_cursor + 1
end

function delete_name_edit_char_before_cursor()
    if name_cursor <= 1 or #name_buffer == 0 then
        speak("Empty")
        return
    end

    local removed = name_buffer:sub(name_cursor - 1, name_cursor - 1)
    local left = name_buffer:sub(1, name_cursor - 2)
    local right = name_buffer:sub(name_cursor)

    name_buffer = left .. right
    name_cursor = name_cursor - 1
    name_edit_edge = nil

    speak(removed)
end

function delete_name_edit_char_at_cursor()
    if name_cursor > #name_buffer or #name_buffer == 0 then
        speak("Empty")
        return
    end

    local removed = name_buffer:sub(name_cursor, name_cursor)
    local left = name_buffer:sub(1, name_cursor - 1)
    local right = name_buffer:sub(name_cursor + 1)

    name_buffer = left .. right
    name_edit_edge = nil

    speak(removed)
end

function speak_name_edit_edge_char(edge_name)
    local len = #name_buffer

    if len == 0 then
        speak("Empty")
        return
    end

    if name_edit_edge == edge_name then
        return
    end

    local pos = edge_name == "end" and len or 1
    local ch = name_buffer:sub(pos, pos)

    name_edit_edge = edge_name
    speak(ch ~= "" and ch or "Empty")
end

function cancel_name_edit()
    mode = "browse"
    name_buffer = ""
    name_cursor = 1
    name_edit_edge = nil
    name_edit_fresh = true

    speak("Cancelled")
end

function handle_name_edit(char)
    local is_ctrl = ctrl_down() or js_vkey_down_now(VK_CTRL)
    local is_shift = shift_down() or js_vkey_down_now(VK_SHIFT)
    local is_alt = alt_down() or js_vkey_down_now(VK_ALT)

    if char == KEY_ESC then
        cancel_name_edit()
        return true
    end

    if char == KEY_ENTER then
        local name = clean_one_line(name_buffer)

        if name == "" then
            speak("Empty name")
            return true
        end

        if save_work_cell(name) then
            local saved_name = name
            local saved_count = #work_records

            mode = "browse"
            page = 1
            name_buffer = ""
            name_cursor = 1
            name_edit_edge = nil
            name_edit_fresh = true

            speak(
                "Saved. " ..
                tostring(saved_name) ..
                ". " ..
                tostring(saved_count) ..
                (saved_count == 1 and " parameter" or " parameters")
            )
        end

        return true
    end

    if char == KEY_TAB or char == KEY_BACKSLASH then
        speak_name_edit_buffer()
        return true
    end

    if char == KEY_BACKSPACE or char == KEY_BACKSPACE_2 then
        name_edit_fresh = false
        delete_name_edit_char_before_cursor()
        return true
    end

    if char == KEY_DELETE then
        if name_edit_fresh then
            name_edit_fresh = false

            if name_buffer ~= "" then
                name_buffer = ""
                name_cursor = 1
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

    if not is_ctrl and not is_shift and not is_alt and char == KEY_LEFT then
        name_edit_fresh = false

        if #name_buffer == 0 then
            speak("Empty")
            return true
        end

        name_cursor = text_move_cursor_left_char(name_buffer, name_cursor)
        name_edit_edge = nil
        text_speak_char_at_cursor(name_buffer, name_cursor)
        return true
    end

    if not is_ctrl and not is_shift and not is_alt and char == KEY_RIGHT then
        name_edit_fresh = false

        if #name_buffer == 0 then
            speak("Empty")
            return true
        end

        name_cursor = text_move_cursor_right_char(name_buffer, name_cursor)
        name_edit_edge = nil
        text_speak_char_at_cursor(name_buffer, name_cursor)
        return true
    end

    if is_ctrl and not is_shift and not is_alt and char == KEY_LEFT then
        name_edit_fresh = false

        if #name_buffer == 0 then
            speak("Empty")
            return true
        end

        local old_cursor = name_cursor
        local new_cursor = text_move_cursor_word_left(name_buffer, name_cursor)

        if new_cursor == old_cursor then
            return true
        end

        name_cursor = new_cursor
        name_edit_edge = nil
        speak(text_get_word_at_or_near_cursor(name_buffer, name_cursor, -1))
        return true
    end

    if is_ctrl and not is_shift and not is_alt and char == KEY_RIGHT then
        name_edit_fresh = false

        if #name_buffer == 0 then
            speak("Empty")
            return true
        end

        local old_cursor = name_cursor
        name_cursor = text_move_cursor_word_right(name_buffer, name_cursor)
        name_edit_edge = nil

        if name_cursor == old_cursor then
            return true
        end

        speak(text_get_word_at_or_near_cursor(name_buffer, name_cursor, 1))
        return true
    end

    if char == KEY_HOME then
        name_edit_fresh = false

        if #name_buffer == 0 then
            name_cursor = 1
            name_edit_edge = nil
            speak("Empty")
        else
            name_cursor = #name_buffer + 1
            speak_name_edit_edge_char("end")
        end

        return true
    end

    if char == KEY_END then
        name_edit_fresh = false

        if #name_buffer == 0 then
            name_cursor = 1
            name_edit_edge = nil
            speak("Empty")
        else
            name_cursor = 1
            speak_name_edit_edge_char("home")
        end

        return true
    end

    local c = safe_char(char)

    if not is_ctrl and not is_alt and
       c and c:match("[%w%s%-%._%#%+%[%]%(%)]") then

        name_edit_fresh = false
        name_insert_char(c)
        speak(c)
        return true
    end

    return true
end

------------------------------------------------------------
-- Return / apply through FX Params
------------------------------------------------------------
function run_fx_params()
    local path = get_fx_params_script_path()

    if not file_exists(path) then
        speak("FX Params script not found")
        return false
    end

    if type(reaper.AddRemoveReaScript) ~= "function" then
        speak("Script switch not available")
        return false
    end

    local cmd = reaper.AddRemoveReaScript(true, 0, path, true)
    if not cmd or tonumber(cmd) == 0 then
        speak("FX Params action not found")
        return false
    end

    gfx.quit()
    reaper.Main_OnCommand(cmd, 0)
    return true
end

function return_to_fx(mode_name, records, cell_name)
    ensure_folder(get_params_root())

    local packet = {
        mode = mode_name or "return",
        source = return_source,
        plugin = plugin_raw,
        cell = cell_name or "",
        grid = grid_size,
        active = return_active_param,
        records = records or {}
    }

    if not write_packet(get_return_path(), packet) then
        speak("Return handoff failed")
        return false
    end

    return run_fx_params()
end

function load_current_cell()
    if #cells <= 0 then
        speak("Library empty")
        return false
    end

    local entry = cells[pos_f1]
    local packet = read_packet(entry.path)

    if not packet then
        speak("Invalid cell")
        return false
    end

    if clean_one_line(packet.plugin) ~= clean_one_line(plugin_raw) then
        speak("Wrong plugin. Cell skipped")
        return false
    end

    return return_to_fx("apply", copy_records(packet.records), cell_display_name(entry))
end

------------------------------------------------------------
-- Startup
------------------------------------------------------------
function init_library()
    ensure_folder(get_params_root())

    handoff = read_packet(get_handoff_path())
    os.remove(get_handoff_path())

    if not handoff or clean_one_line(handoff.plugin or "") == "" then
        speak("Parameter Library. Open from FX Params F7")
        return false
    end

    plugin_raw = clean_one_line(handoff.plugin)
    plugin_label = strip_fx_prefix(plugin_raw)
    grid_size = math.max(1, math.floor(tonumber(handoff.grid) or 10))
    return_active_param = tonumber(handoff.active) or 0
    return_source = clean_one_line(handoff.source or "")
    if return_source == "" then
        return_source = (#(handoff.records or {}) > 0) and "f7" or "grid"
    end
    f2_available = return_source == "f7"
    work_records = f2_available and copy_records(handoff.records) or {}

    plugin_folder = join_path(
        get_params_root(),
        sanitize_plugin_folder_name(plugin_raw)
    )

    ensure_folder(plugin_folder)
    scan_cells()

    page = 1
    pos_f1 = #cells > 0 and 1 or 1
    pos_f2 = #work_records > 0 and 1 or 1

    local title = "Parameter Library: " .. plugin_label
    gfx.init(title, 1, 1, 0, -32000, -32000)

    local msg = "Parameter Library. " .. plugin_label ..
        ". F1 Library. " .. tostring(#cells) .. " cells"

    if f2_available then
        if #work_records > 0 then
            msg = msg .. ". F2 " .. tostring(#work_records) .. " current parameters"
        else
            msg = msg .. ". F2 empty"
        end
    end

    speak(msg)
    return true
end

------------------------------------------------------------
-- Main loop
------------------------------------------------------------
function main_loop()
    local char = gfx.getchar()

    if char < 0 then
        return
    end

    if char == 0 then
        reaper.defer(main_loop)
        return
    end

    if mode == "name_edit" then
        handle_name_edit(char)
        reaper.defer(main_loop)
        return
    end

    local is_ctrl = ctrl_down() or js_vkey_down_now(VK_CTRL)
    local is_shift = shift_down() or js_vkey_down_now(VK_SHIFT)
    local is_alt = alt_down() or js_vkey_down_now(VK_ALT)

    if char == KEY_F10 and not is_ctrl and not is_shift and not is_alt then
        return_to_fx(
            "return",
            f2_available and copy_records(work_records) or {},
            ""
        )
        return
    end

    if ctrl_tab_key(char) then
        return_to_fx(
            "return",
            f2_available and copy_records(work_records) or {},
            ""
        )
        return
    end

    if char == KEY_ESC then
        gfx.quit()
        return
    end

    if char == KEY_F1 and not is_ctrl and not is_shift and not is_alt then
        page = 1
        disarm_delete()
        speak_page_status()
        reaper.defer(main_loop)
        return
    end

    if char == KEY_F2 and not is_ctrl and not is_shift and not is_alt then
        if f2_available then
            page = 2
            disarm_delete()
            speak_page_status()
        end
        reaper.defer(main_loop)
        return
    end

    if char == KEY_CTRL_S or
       (is_ctrl and not is_shift and not is_alt and char == string.byte("S")) then
        if page == 2 and f2_available then
            start_name_edit()
        end
        reaper.defer(main_loop)
        return
    end

    if char == KEY_TAB and not is_ctrl then
        speak_page_status()
        reaper.defer(main_loop)
        return
    end

    if char == KEY_BACKSLASH and not is_ctrl and not is_alt then
        speak_current_entry()
        reaper.defer(main_loop)
        return
    end

    if char == KEY_ENTER and not is_ctrl and not is_shift and not is_alt then
        if page == 1 then
            load_current_cell()
            return
        end

        speak_current_entry("Current selection")
        reaper.defer(main_loop)
        return
    end

    if char == KEY_DELETE and not is_ctrl and not is_shift and not is_alt then
        if page == 1 then
            delete_current_f1_cell()
        else
            delete_current_f2_param()
        end
        reaper.defer(main_loop)
        return
    end

    if char == KEY_UP and not is_ctrl and not is_shift and not is_alt then
        move_grid_vertical(-1)
        reaper.defer(main_loop)
        return
    end

    if char == KEY_DOWN and not is_ctrl and not is_shift and not is_alt then
        move_grid_vertical(1)
        reaper.defer(main_loop)
        return
    end

    if char == KEY_LEFT and not is_ctrl and not is_shift and not is_alt then
        move_grid_horizontal(-1)
        reaper.defer(main_loop)
        return
    end

    if char == KEY_RIGHT and not is_ctrl and not is_shift and not is_alt then
        move_grid_horizontal(1)
        reaper.defer(main_loop)
        return
    end

    if char == KEY_PAGE_UP and not is_ctrl and not is_shift and not is_alt then
        move_list_page(-1)
        reaper.defer(main_loop)
        return
    end

    if char == KEY_PAGE_DOWN and not is_ctrl and not is_shift and not is_alt then
        move_list_page(1)
        reaper.defer(main_loop)
        return
    end

    if char == KEY_HOME and not is_ctrl and not is_shift and not is_alt then
        move_list_edge(false)
        reaper.defer(main_loop)
        return
    end

    if char == KEY_END and not is_ctrl and not is_shift and not is_alt then
        move_list_edge(true)
        reaper.defer(main_loop)
        return
    end

    local c = safe_char(char)
    if c and not is_ctrl and not is_alt and c:match("[%w]") then
        cycle_by_initial(c)
        reaper.defer(main_loop)
        return
    end

    reaper.defer(main_loop)
end

if init_library() then
    main_loop()
end
