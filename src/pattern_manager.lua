--[[
    MIDI Drum Sequencer - pattern_manager.lua
    
    Handles pattern save/load functionality for the MIDI drum sequencer.
    Provides JSON-based pattern storage with full sequencer state preservation.
    
    Copyright (C) 2024 MIDI Drum Sequencer Contributors
    
    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.
    
    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.
    
    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <https://www.gnu.org/licenses/>.
--]]

local pattern_manager = {
    -- Pattern file format version for compatibility tracking
    PATTERN_FORMAT_VERSION = "1.0",
    
    -- Default pattern storage directory
    PATTERNS_DIR = "patterns",
    
    -- Pattern file extension
    PATTERN_EXT = ".json"
}

-- Initialize pattern manager
-- Creates the patterns directory if it doesn't exist
function pattern_manager:init()
    -- Check if patterns directory exists, create if not
    if love and love.filesystem then
        local info = love.filesystem.getInfo(self.PATTERNS_DIR)
        if not info then
            love.filesystem.createDirectory(self.PATTERNS_DIR)
        end
    end
end

-- Simple JSON encoder for pattern data
-- Converts Lua tables to JSON string format
-- @param data: Lua table to encode
-- @return: JSON string representation
function pattern_manager:encodeJSON(data)
    local function encode_value(value)
        if type(value) == "table" then
            -- Check if it's an array (all numeric indices)
            local is_array = true
            local max_index = 0
            for k, v in pairs(value) do
                if type(k) ~= "number" then
                    is_array = false
                    break
                end
                max_index = math.max(max_index, k)
            end
            
            if is_array then
                -- Encode as JSON array
                local result = {}
                for i = 1, max_index do
                    result[i] = encode_value(value[i])
                end
                return "[" .. table.concat(result, ",") .. "]"
            else
                -- Encode as JSON object
                local result = {}
                for k, v in pairs(value) do
                    table.insert(result, "\"" .. tostring(k) .. "\":" .. encode_value(v))
                end
                return "{" .. table.concat(result, ",") .. "}"
            end
        elseif type(value) == "string" then
            return "\"" .. value .. "\""
        elseif type(value) == "number" then
            return tostring(value)
        elseif type(value) == "boolean" then
            return value and "true" or "false"
        else
            return "null"
        end
    end
    
    return encode_value(data)
end

-- Simple JSON decoder for pattern data
-- Converts JSON string to Lua table
-- @param json_string: JSON string to decode
-- @return: Lua table representation
function pattern_manager:decodeJSON(json_string)
    -- Remove whitespace
    json_string = json_string:gsub("^%s*(.-)%s*$", "%1")
    
    local function decode_value(str, pos)
        pos = pos or 1
        
        -- Skip whitespace
        while pos <= #str and str:sub(pos, pos):match("%s") do
            pos = pos + 1
        end
        
        if pos > #str then
            return nil, pos
        end
        
        local char = str:sub(pos, pos)
        
        if char == "{" then
            -- Parse object
            local result = {}
            pos = pos + 1
            
            -- Skip whitespace
            while pos <= #str and str:sub(pos, pos):match("%s") do
                pos = pos + 1
            end
            
            if pos <= #str and str:sub(pos, pos) == "}" then
                return result, pos + 1
            end
            
            while pos <= #str do
                -- Parse key
                local key, new_pos = decode_value(str, pos)
                pos = new_pos
                
                -- Skip whitespace and colon
                while pos <= #str and (str:sub(pos, pos):match("%s") or str:sub(pos, pos) == ":") do
                    pos = pos + 1
                end
                
                -- Parse value
                local value, new_pos = decode_value(str, pos)
                pos = new_pos
                
                result[key] = value
                
                -- Skip whitespace
                while pos <= #str and str:sub(pos, pos):match("%s") do
                    pos = pos + 1
                end
                
                if pos <= #str and str:sub(pos, pos) == "," then
                    pos = pos + 1
                elseif pos <= #str and str:sub(pos, pos) == "}" then
                    return result, pos + 1
                else
                    break
                end
            end
            
            return result, pos
        elseif char == "[" then
            -- Parse array
            local result = {}
            pos = pos + 1
            local index = 1
            
            -- Skip whitespace
            while pos <= #str and str:sub(pos, pos):match("%s") do
                pos = pos + 1
            end
            
            if pos <= #str and str:sub(pos, pos) == "]" then
                return result, pos + 1
            end
            
            while pos <= #str do
                local value, new_pos = decode_value(str, pos)
                pos = new_pos
                result[index] = value
                index = index + 1
                
                -- Skip whitespace
                while pos <= #str and str:sub(pos, pos):match("%s") do
                    pos = pos + 1
                end
                
                if pos <= #str and str:sub(pos, pos) == "," then
                    pos = pos + 1
                elseif pos <= #str and str:sub(pos, pos) == "]" then
                    return result, pos + 1
                else
                    break
                end
            end
            
            return result, pos
        elseif char == "\"" then
            -- Parse string
            local start_pos = pos + 1
            local end_pos = start_pos
            while end_pos <= #str and str:sub(end_pos, end_pos) ~= "\"" do
                end_pos = end_pos + 1
            end
            return str:sub(start_pos, end_pos - 1), end_pos + 1
        elseif char:match("[%d%-]") then
            -- Parse number
            local start_pos = pos
            while pos <= #str and str:sub(pos, pos):match("[%d%.%-]") do
                pos = pos + 1
            end
            return tonumber(str:sub(start_pos, pos - 1)), pos
        elseif str:sub(pos, pos + 3) == "true" then
            return true, pos + 4
        elseif str:sub(pos, pos + 4) == "false" then
            return false, pos + 5
        elseif str:sub(pos, pos + 3) == "null" then
            return nil, pos + 4
        end
        
        return nil, pos
    end
    
    local result, _ = decode_value(json_string)
    return result
end

-- Create pattern data structure from current sequencer state
-- @param sequencer: Sequencer instance with current pattern
-- @param audio: Audio instance with current volumes
-- @return: Pattern data table ready for JSON serialization
function pattern_manager:createPatternData(sequencer, audio)
    local pattern_data = {
        -- Pattern metadata
        format_version = self.PATTERN_FORMAT_VERSION,
        created_at = os.date("%Y-%m-%d %H:%M:%S"),
        name = "",  -- Will be set by UI
        
        -- Sequencer state
        bpm = sequencer.bpm or 120,
        pattern = {},
        
        -- Audio settings
        track_volumes = {},
        metronome_volumes = {},
        metronome_enabled = sequencer.metronomeEnabled or false
    }
    
    -- Copy pattern data (8x16 boolean matrix)
    for track = 1, 8 do
        pattern_data.pattern[track] = {}
        for step = 1, 16 do
            pattern_data.pattern[track][step] = sequencer.pattern[track][step] or false
        end
    end
    
    -- Copy track volumes
    for track = 1, 8 do
        if audio and audio.getVolume then
            pattern_data.track_volumes[track] = audio:getVolume(track) or 0.7
        else
            pattern_data.track_volumes[track] = 0.7  -- Default volume
        end
    end
    
    -- Copy metronome volumes
    if sequencer and sequencer.getMetronomeVolume then
        pattern_data.metronome_volumes.normal = sequencer:getMetronomeVolume("normal") or 0.6
        pattern_data.metronome_volumes.accent = sequencer:getMetronomeVolume("accent") or 0.8
    else
        pattern_data.metronome_volumes.normal = 0.6
        pattern_data.metronome_volumes.accent = 0.8
    end
    
    return pattern_data
end

-- Apply pattern data to sequencer and audio instances
-- @param pattern_data: Pattern data table from JSON
-- @param sequencer: Sequencer instance to update
-- @param audio: Audio instance to update
-- @return: Success flag and error message if any
function pattern_manager:applyPatternData(pattern_data, sequencer, audio)
    -- Validate pattern data format
    if not pattern_data or not pattern_data.format_version then
        return false, "Invalid pattern format: missing format version"
    end
    
    if not pattern_data.pattern then
        return false, "Invalid pattern format: missing pattern data"
    end
    
    -- Apply BPM setting
    if pattern_data.bpm then
        sequencer:setBPM(pattern_data.bpm)
    end
    
    -- Apply pattern data
    for track = 1, 8 do
        if pattern_data.pattern[track] then
            for step = 1, 16 do
                local step_value = pattern_data.pattern[track][step]
                if step_value ~= nil then
                    sequencer.pattern[track][step] = step_value
                end
            end
        end
    end
    
    -- Apply track volumes
    if pattern_data.track_volumes then
        for track = 1, 8 do
            if pattern_data.track_volumes[track] then
                audio:setVolume(track, pattern_data.track_volumes[track])
            end
        end
    end
    
    -- Apply metronome volumes
    if pattern_data.metronome_volumes then
        if pattern_data.metronome_volumes.normal then
            sequencer:setMetronomeVolume("normal", pattern_data.metronome_volumes.normal)
        end
        if pattern_data.metronome_volumes.accent then
            sequencer:setMetronomeVolume("accent", pattern_data.metronome_volumes.accent)
        end
    end
    
    -- Apply metronome enabled state
    if pattern_data.metronome_enabled ~= nil then
        sequencer.metronomeEnabled = pattern_data.metronome_enabled
    end
    
    return true, nil
end

-- Save pattern to file
-- @param pattern_data: Pattern data table
-- @param filename: Filename (without extension)
-- @return: Success flag and error message if any
function pattern_manager:savePattern(pattern_data, filename)
    if not filename or filename == "" then
        return false, "Filename cannot be empty"
    end
    
    -- Sanitize filename
    filename = filename:gsub("[^%w%-_]", "_")
    
    -- Create full path
    local full_path = self.PATTERNS_DIR .. "/" .. filename .. self.PATTERN_EXT
    
    -- Convert pattern data to JSON
    local json_data = self:encodeJSON(pattern_data)
    
    -- Save file
    if love and love.filesystem then
        local success = love.filesystem.write(full_path, json_data)
        if success then
            return true, nil
        else
            return false, "Failed to write pattern file"
        end
    elseif _G.mockFileSystem then
        -- For testing with mock filesystem
        _G.mockFileSystem[full_path] = json_data
        return true, nil
    else
        -- For testing without Love2D
        local file = io.open(full_path, "w")
        if file then
            file:write(json_data)
            file:close()
            return true, nil
        else
            return false, "Failed to write pattern file"
        end
    end
end

-- Load pattern from file
-- @param filename: Filename (without extension)
-- @return: Pattern data table or nil, error message if any
function pattern_manager:loadPattern(filename)
    if not filename or filename == "" then
        return nil, "Filename cannot be empty"
    end
    
    -- Sanitize filename
    filename = filename:gsub("[^%w%-_]", "_")
    
    -- Create full path
    local full_path = self.PATTERNS_DIR .. "/" .. filename .. self.PATTERN_EXT
    
    -- Read file
    local file_content
    if love and love.filesystem then
        file_content = love.filesystem.read(full_path)
        if not file_content then
            return nil, "Pattern file not found"
        end
    elseif _G.mockFileSystem then
        -- For testing with mock filesystem
        file_content = _G.mockFileSystem[full_path]
        if not file_content then
            return nil, "Pattern file not found"
        end
    else
        -- For testing without Love2D
        local file = io.open(full_path, "r")
        if not file then
            return nil, "Pattern file not found"
        end
        file_content = file:read("*all")
        file:close()
    end
    
    -- Parse JSON
    local pattern_data = self:decodeJSON(file_content)
    if not pattern_data then
        return nil, "Invalid pattern file format"
    end
    
    return pattern_data, nil
end

-- Get list of available pattern files
-- @return: Array of pattern filenames (without extension)
function pattern_manager:getPatternList()
    local pattern_files = {}
    
    if love and love.filesystem then
        local files = love.filesystem.getDirectoryItems(self.PATTERNS_DIR)
        for _, file in ipairs(files) do
            if file:match("%.json$") then
                local name = file:gsub("%.json$", "")
                table.insert(pattern_files, name)
            end
        end
    elseif _G.mockFileSystem then
        -- For testing with mock filesystem
        local dir_prefix = self.PATTERNS_DIR .. "/"
        for filename, _ in pairs(_G.mockFileSystem) do
            if filename:match("^" .. dir_prefix .. ".*%.json$") then
                local basename = filename:gsub("^" .. dir_prefix, ""):gsub("%.json$", "")
                table.insert(pattern_files, basename)
            end
        end
    else
        -- For testing without Love2D - return empty list
        return {}
    end
    
    -- Sort alphabetically
    table.sort(pattern_files)
    
    return pattern_files
end

-- Delete pattern file
-- @param filename: Filename (without extension)
-- @return: Success flag and error message if any
function pattern_manager:deletePattern(filename)
    if not filename or filename == "" then
        return false, "Filename cannot be empty"
    end
    
    -- Sanitize filename
    filename = filename:gsub("[^%w%-_]", "_")
    
    -- Create full path
    local full_path = self.PATTERNS_DIR .. "/" .. filename .. self.PATTERN_EXT
    
    -- Delete file
    if love and love.filesystem then
        local success = love.filesystem.remove(full_path)
        if success then
            return true, nil
        else
            return false, "Failed to delete pattern file"
        end
    elseif _G.mockFileSystem then
        -- For testing with mock filesystem
        if _G.mockFileSystem[full_path] then
            _G.mockFileSystem[full_path] = nil
            return true, nil
        else
            return false, "Pattern file not found"
        end
    else
        -- For testing without Love2D
        local success = os.remove(full_path)
        if success then
            return true, nil
        else
            return false, "Failed to delete pattern file"
        end
    end
end

-- Validate pattern filename
-- @param filename: Filename to validate
-- @return: True if valid, false otherwise
function pattern_manager:validateFilename(filename)
    if not filename or filename == "" then
        return false
    end
    
    -- Check length
    if #filename > 50 then
        return false
    end
    
    -- Check for valid characters (alphanumeric, hyphen, underscore)
    if not filename:match("^[%w%-_]+$") then
        return false
    end
    
    return true
end

return pattern_manager