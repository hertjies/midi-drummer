--[[
    MIDI Drum Sequencer - midi.lua
    
    Handles MIDI file generation and export.
    Implements Standard MIDI File (SMF) Type 0 format.
    
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

local midi = {
    -- General MIDI drum map (Channel 10)
    -- Maps track numbers to MIDI note numbers
    drumMap = {
        36,  -- Track 1: Kick (C1)
        38,  -- Track 2: Snare (D1)
        42,  -- Track 3: Closed Hi-Hat (F#1)
        46,  -- Track 4: Open Hi-Hat (A#1)
        49,  -- Track 5: Crash Cymbal (C#2)
        51,  -- Track 6: Ride Cymbal (D#2)
        45,  -- Track 7: Low Tom (A0)
        50   -- Track 8: High Tom (D2)
    },
    
    -- MIDI file settings
    format = 0,              -- SMF Type 0 (single track)
    resolution = 96,         -- PPQ (Pulses Per Quarter Note)
    drumChannel = 9,         -- Channel 10 (0-indexed = 9)
    defaultVelocity = 100,   -- Default note velocity (0-127)
    
    -- Track name for metadata
    trackName = "Drum Pattern"
}

-- Initialize MIDI module
function midi:init()
    -- Nothing special needed for initialization
end

-- Export pattern as a MIDI file
-- @param pattern: The 8x16 pattern matrix
-- @param bpm: Beats per minute
-- @param filename: Output filename (optional, defaults to "pattern.mid")
-- @return: true if successful, false otherwise
function midi:exportPattern(pattern, bpm, filename)
    if not pattern or not bpm then
        print("Error: Invalid pattern or BPM for MIDI export")
        return false
    end
    
    filename = filename or "pattern.mid"
    
    -- Build MIDI events from pattern
    local midiEvents = self:buildMidiEvents(pattern, bpm)
    
    -- Generate MIDI file data
    local midiData = self:generateMidiFile(midiEvents, bpm)
    
    -- Write to file
    return self:writeMidiFile(filename, midiData)
end

-- Build MIDI events from the pattern matrix
-- @param pattern: The 8x16 pattern matrix
-- @param bpm: Beats per minute
-- @return: Table of MIDI events
function midi:buildMidiEvents(pattern, bpm)
    local events = {}
    
    -- Calculate timing
    local ticksPerStep = self.resolution / 4  -- 16th notes
    
    -- Add track name event
    table.insert(events, {
        deltaTime = 0,
        type = "meta",
        metaType = 0x03,  -- Track Name
        data = self.trackName
    })
    
    -- Add tempo event
    local microsecondsPerQuarter = math.floor(60000000 / bpm)
    table.insert(events, {
        deltaTime = 0,
        type = "meta", 
        metaType = 0x51,  -- Set Tempo
        data = self:packInt24(microsecondsPerQuarter)
    })
    
    -- Convert pattern to MIDI events
    for step = 1, 16 do
        local stepTime = (step - 1) * ticksPerStep
        
        for track = 1, 8 do
            if pattern[track] and pattern[track][step] then
                -- Note On event
                table.insert(events, {
                    deltaTime = stepTime,
                    type = "midi",
                    status = 0x90 + self.drumChannel,  -- Note On, Channel 10
                    data1 = self.drumMap[track],       -- Note number
                    data2 = self.defaultVelocity       -- Velocity
                })
                
                -- Note Off event (short duration)
                table.insert(events, {
                    deltaTime = stepTime + ticksPerStep / 4,  -- 1/64th note duration
                    type = "midi",
                    status = 0x80 + self.drumChannel,  -- Note Off, Channel 10
                    data1 = self.drumMap[track],       -- Note number
                    data2 = 0                          -- Velocity (0 for note off)
                })
            end
        end
    end
    
    -- Add End of Track event
    table.insert(events, {
        deltaTime = 16 * ticksPerStep,  -- End after full pattern
        type = "meta",
        metaType = 0x2F,  -- End of Track
        data = ""
    })
    
    -- Sort events by time and calculate delta times
    return self:calculateDeltaTimes(events)
end

-- Calculate delta times between events
-- @param events: Table of events with absolute times
-- @return: Table of events with proper delta times
function midi:calculateDeltaTimes(events)
    -- Sort events by absolute time
    table.sort(events, function(a, b) return a.deltaTime < b.deltaTime end)
    
    -- Convert to delta times
    local lastTime = 0
    for i, event in ipairs(events) do
        local absoluteTime = event.deltaTime
        event.deltaTime = absoluteTime - lastTime
        lastTime = absoluteTime
    end
    
    return events
end

-- Generate complete MIDI file data
-- @param events: Table of MIDI events
-- @param bpm: Beats per minute
-- @return: Binary MIDI file data as string
function midi:generateMidiFile(events, bpm)
    -- Generate track chunk
    local trackData = self:generateTrackChunk(events)
    
    -- Generate header chunk
    local headerData = self:generateHeaderChunk(#trackData)
    
    -- Combine header and track
    return headerData .. trackData
end

-- Generate MIDI header chunk
-- @param trackDataLength: Length of track data in bytes
-- @return: Header chunk data
function midi:generateHeaderChunk(trackDataLength)
    local header = {}
    
    -- Header chunk identifier
    table.insert(header, "MThd")
    
    -- Header chunk length (always 6 for Type 0)
    table.insert(header, self:packInt32(6))
    
    -- Format type (0 = Type 0)
    table.insert(header, self:packInt16(self.format))
    
    -- Number of tracks (1 for Type 0)
    table.insert(header, self:packInt16(1))
    
    -- Time division (ticks per quarter note)
    table.insert(header, self:packInt16(self.resolution))
    
    return table.concat(header)
end

-- Generate MIDI track chunk
-- @param events: Table of MIDI events
-- @return: Track chunk data
function midi:generateTrackChunk(events)
    local track = {}
    
    -- Track chunk identifier
    table.insert(track, "MTrk")
    
    -- Generate track events
    local trackEvents = self:generateTrackEvents(events)
    
    -- Track chunk length
    table.insert(track, self:packInt32(#trackEvents))
    
    -- Track events
    table.insert(track, trackEvents)
    
    return table.concat(track)
end

-- Generate track events data
-- @param events: Table of MIDI events
-- @return: Binary track events data
function midi:generateTrackEvents(events)
    local data = {}
    
    for _, event in ipairs(events) do
        -- Add delta time (variable length quantity)
        table.insert(data, self:encodeVLQ(event.deltaTime))
        
        if event.type == "midi" then
            -- MIDI event
            table.insert(data, string.char(event.status))
            table.insert(data, string.char(event.data1))
            if event.status >= 0x80 and event.status <= 0xEF then
                table.insert(data, string.char(event.data2))
            end
        elseif event.type == "meta" then
            -- Meta event
            table.insert(data, string.char(0xFF))  -- Meta event marker
            table.insert(data, string.char(event.metaType))
            table.insert(data, self:encodeVLQ(#event.data))
            table.insert(data, event.data)
        end
    end
    
    return table.concat(data)
end

-- Encode Variable Length Quantity (VLQ)
-- @param value: Integer value to encode
-- @return: VLQ encoded string
function midi:encodeVLQ(value)
    if value == 0 then
        return string.char(0)
    end
    
    local bytes = {}
    local remaining = value
    
    -- Extract 7-bit chunks
    while remaining > 0 do
        table.insert(bytes, 1, remaining % 128)
        remaining = math.floor(remaining / 128)
    end
    
    -- Set continuation bits (all except last byte)
    for i = 1, #bytes - 1 do
        bytes[i] = bytes[i] + 128
    end
    
    -- Convert to string
    local result = {}
    for _, byte in ipairs(bytes) do
        table.insert(result, string.char(byte))
    end
    
    return table.concat(result)
end

-- Pack 32-bit integer as big-endian
-- @param value: Integer value
-- @return: 4-byte string
function midi:packInt32(value)
    return string.char(
        math.floor(value / 16777216) % 256,
        math.floor(value / 65536) % 256,
        math.floor(value / 256) % 256,
        value % 256
    )
end

-- Pack 24-bit integer as big-endian
-- @param value: Integer value
-- @return: 3-byte string
function midi:packInt24(value)
    return string.char(
        math.floor(value / 65536) % 256,
        math.floor(value / 256) % 256,
        value % 256
    )
end

-- Pack 16-bit integer as big-endian
-- @param value: Integer value
-- @return: 2-byte string
function midi:packInt16(value)
    return string.char(
        math.floor(value / 256) % 256,
        value % 256
    )
end

-- Write MIDI file to disk
-- @param filename: Output filename
-- @param data: Binary MIDI data
-- @return: true if successful, false otherwise
function midi:writeMidiFile(filename, data)
    local file, err = io.open(filename, "wb")
    if not file then
        print("Error opening file for writing: " .. (err or "unknown error"))
        return false
    end
    
    local success, writeErr = pcall(function()
        file:write(data)
    end)
    
    file:close()
    
    if success then
        print("MIDI file exported: " .. filename)
        return true
    else
        print("Error writing MIDI file: " .. (writeErr or "unknown error"))
        return false
    end
end

-- Validate pattern before export
-- @param pattern: Pattern matrix to validate
-- @return: true if valid, false otherwise
function midi:validatePattern(pattern)
    if not pattern or type(pattern) ~= "table" then
        return false
    end
    
    -- Check that we have 8 tracks
    if #pattern ~= 8 then
        return false
    end
    
    -- Check that each track has 16 steps
    for track = 1, 8 do
        if not pattern[track] or #pattern[track] ~= 16 then
            return false
        end
        
        -- Check that each step is boolean
        for step = 1, 16 do
            if type(pattern[track][step]) ~= "boolean" then
                return false
            end
        end
    end
    
    return true
end

-- Get MIDI file statistics for a pattern
-- @param pattern: Pattern matrix
-- @return: Table with statistics
function midi:getPatternStats(pattern)
    if not self:validatePattern(pattern) then
        return nil
    end
    
    local stats = {
        totalNotes = 0,
        notesPerTrack = {},
        activeSteps = 0,
        trackNames = {
            "Kick", "Snare", "Hi-Hat C", "Hi-Hat O", 
            "Crash", "Ride", "Tom Low", "Tom High"
        }
    }
    
    -- Initialize track counters
    for track = 1, 8 do
        stats.notesPerTrack[track] = 0
    end
    
    -- Count notes
    for step = 1, 16 do
        local stepHasNotes = false
        for track = 1, 8 do
            if pattern[track][step] then
                stats.totalNotes = stats.totalNotes + 1
                stats.notesPerTrack[track] = stats.notesPerTrack[track] + 1
                stepHasNotes = true
            end
        end
        if stepHasNotes then
            stats.activeSteps = stats.activeSteps + 1
        end
    end
    
    return stats
end

-- Export pattern with custom settings
-- @param pattern: Pattern matrix
-- @param options: Table with export options
-- @return: true if successful, false otherwise
function midi:exportWithOptions(pattern, options)
    options = options or {}
    
    -- Validate inputs
    if not self:validatePattern(pattern) then
        print("Error: Invalid pattern for MIDI export")
        return false
    end
    
    -- Apply options
    local oldVelocity = self.defaultVelocity
    local oldResolution = self.resolution
    
    self.defaultVelocity = options.velocity or self.defaultVelocity
    self.resolution = options.resolution or self.resolution
    
    -- Export
    local success = self:exportPattern(pattern, options.bpm or 120, options.filename)
    
    -- Restore settings
    self.defaultVelocity = oldVelocity
    self.resolution = oldResolution
    
    return success
end

return midi