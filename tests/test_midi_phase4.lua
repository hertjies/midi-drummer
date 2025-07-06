--[[
    MIDI Drum Sequencer - test_midi_phase4.lua
    
    Unit tests for Phase 4 MIDI functionality.
    Tests MIDI file generation, export, and validation.
    
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

-- Tests MIDI file generation, export, and validation
-- Path is already set by test_runner.lua when running the full suite
-- For standalone execution, add paths:
if not package.path:match("./src/%?%.lua") then
    package.path = package.path .. ";./src/?.lua;./lib/?.lua"
end

local luaunit = require("luaunit")

-- Mock io.open for testing file operations
local mockFiles = {}
local originalOpen = io.open

local function mockOpen(filename, mode)
    if mode == "wb" then
        local mockFile = {
            data = "",
            write = function(self, data)
                self.data = self.data .. data
            end,
            close = function(self)
                mockFiles[filename] = self.data
            end
        }
        return mockFile
    end
    return originalOpen(filename, mode)
end

-- Mock os.date for consistent testing
local originalDate = os.date
local function mockDate(format)
    if format == "%Y%m%d_%H%M%S" then
        return "20231201_120000"
    end
    return originalDate(format)
end

local midi = require("midi")

local TestMidiPhase4 = {}

function TestMidiPhase4:setUp()
    -- Reset MIDI settings
    midi.defaultVelocity = 100
    midi.resolution = 96
    midi.format = 0
    midi.drumChannel = 9
    
    -- Clear mock files
    mockFiles = {}
    
    -- Mock file operations
    io.open = mockOpen
    os.date = mockDate
end

function TestMidiPhase4:tearDown()
    -- Restore original functions
    io.open = originalOpen
    os.date = originalDate
end

function TestMidiPhase4:testDrumMapping()
    -- Test that drum map has correct MIDI note numbers
    luaunit.assertEquals(#midi.drumMap, 8)
    luaunit.assertEquals(midi.drumMap[1], 36)  -- Kick
    luaunit.assertEquals(midi.drumMap[2], 38)  -- Snare
    luaunit.assertEquals(midi.drumMap[3], 42)  -- Closed Hi-Hat
    luaunit.assertEquals(midi.drumMap[4], 46)  -- Open Hi-Hat
    luaunit.assertEquals(midi.drumMap[5], 49)  -- Crash
    luaunit.assertEquals(midi.drumMap[6], 51)  -- Ride
    luaunit.assertEquals(midi.drumMap[7], 45)  -- Low Tom
    luaunit.assertEquals(midi.drumMap[8], 50)  -- High Tom
end

function TestMidiPhase4:testValidatePattern()
    -- Test valid pattern
    local validPattern = {}
    for track = 1, 8 do
        validPattern[track] = {}
        for step = 1, 16 do
            validPattern[track][step] = false
        end
    end
    luaunit.assertTrue(midi:validatePattern(validPattern))
    
    -- Test invalid patterns
    luaunit.assertFalse(midi:validatePattern(nil))
    luaunit.assertFalse(midi:validatePattern("not a table"))
    luaunit.assertFalse(midi:validatePattern({}))  -- Empty table
    
    -- Test wrong number of tracks
    local wrongTracks = {}
    for track = 1, 7 do  -- Only 7 tracks
        wrongTracks[track] = {}
        for step = 1, 16 do
            wrongTracks[track][step] = false
        end
    end
    luaunit.assertFalse(midi:validatePattern(wrongTracks))
    
    -- Test wrong number of steps
    local wrongSteps = {}
    for track = 1, 8 do
        wrongSteps[track] = {}
        for step = 1, 15 do  -- Only 15 steps
            wrongSteps[track][step] = false
        end
    end
    luaunit.assertFalse(midi:validatePattern(wrongSteps))
    
    -- Test non-boolean values
    local nonBoolean = {}
    for track = 1, 8 do
        nonBoolean[track] = {}
        for step = 1, 16 do
            nonBoolean[track][step] = step  -- Number instead of boolean
        end
    end
    luaunit.assertFalse(midi:validatePattern(nonBoolean))
end

function TestMidiPhase4:testGetPatternStats()
    -- Create test pattern
    local pattern = {}
    for track = 1, 8 do
        pattern[track] = {}
        for step = 1, 16 do
            pattern[track][step] = false
        end
    end
    
    -- Add some notes
    pattern[1][1] = true   -- Kick on step 1
    pattern[1][9] = true   -- Kick on step 9
    pattern[2][5] = true   -- Snare on step 5
    pattern[2][13] = true  -- Snare on step 13
    pattern[3][1] = true   -- Hi-hat on step 1
    pattern[3][3] = true   -- Hi-hat on step 3
    
    local stats = midi:getPatternStats(pattern)
    
    luaunit.assertNotNil(stats)
    luaunit.assertEquals(stats.totalNotes, 6)
    luaunit.assertEquals(stats.notesPerTrack[1], 2)  -- Kick: 2 notes
    luaunit.assertEquals(stats.notesPerTrack[2], 2)  -- Snare: 2 notes
    luaunit.assertEquals(stats.notesPerTrack[3], 2)  -- Hi-hat: 2 notes
    luaunit.assertEquals(stats.notesPerTrack[4], 0)  -- Others: 0 notes
    luaunit.assertEquals(stats.activeSteps, 5)       -- Steps 1, 3, 5, 9, 13
    
    -- Test invalid pattern
    luaunit.assertNil(midi:getPatternStats(nil))
end

function TestMidiPhase4:testEncodeVLQ()
    -- Test Variable Length Quantity encoding
    luaunit.assertEquals(midi:encodeVLQ(0), string.char(0))
    luaunit.assertEquals(midi:encodeVLQ(127), string.char(127))
    luaunit.assertEquals(midi:encodeVLQ(128), string.char(129, 0))
    luaunit.assertEquals(midi:encodeVLQ(255), string.char(129, 127))
    luaunit.assertEquals(midi:encodeVLQ(16383), string.char(255, 127))
    luaunit.assertEquals(midi:encodeVLQ(16384), string.char(129, 128, 0))
end

function TestMidiPhase4:testPackIntegers()
    -- Test 16-bit packing
    luaunit.assertEquals(midi:packInt16(0), string.char(0, 0))
    luaunit.assertEquals(midi:packInt16(255), string.char(0, 255))
    luaunit.assertEquals(midi:packInt16(256), string.char(1, 0))
    luaunit.assertEquals(midi:packInt16(65535), string.char(255, 255))
    
    -- Test 24-bit packing
    luaunit.assertEquals(midi:packInt24(0), string.char(0, 0, 0))
    luaunit.assertEquals(midi:packInt24(255), string.char(0, 0, 255))
    luaunit.assertEquals(midi:packInt24(65536), string.char(1, 0, 0))
    
    -- Test 32-bit packing
    luaunit.assertEquals(midi:packInt32(0), string.char(0, 0, 0, 0))
    luaunit.assertEquals(midi:packInt32(255), string.char(0, 0, 0, 255))
    luaunit.assertEquals(midi:packInt32(16777216), string.char(1, 0, 0, 0))
end

function TestMidiPhase4:testBuildMidiEvents()
    -- Create simple test pattern
    local pattern = {}
    for track = 1, 8 do
        pattern[track] = {}
        for step = 1, 16 do
            pattern[track][step] = false
        end
    end
    
    -- Add a kick on step 1 and snare on step 5
    pattern[1][1] = true
    pattern[2][5] = true
    
    local events = midi:buildMidiEvents(pattern, 120)
    
    luaunit.assertNotNil(events)
    luaunit.assertTrue(#events > 0)
    
    -- Should have at least: track name, tempo, note events, end of track
    local hasTrackName = false
    local hasTempo = false
    local hasNoteOn = false
    local hasEndOfTrack = false
    
    for _, event in ipairs(events) do
        if event.type == "meta" and event.metaType == 0x03 then
            hasTrackName = true
        elseif event.type == "meta" and event.metaType == 0x51 then
            hasTempo = true
        elseif event.type == "midi" and event.status == 0x99 then  -- Note On Channel 10
            hasNoteOn = true
        elseif event.type == "meta" and event.metaType == 0x2F then
            hasEndOfTrack = true
        end
    end
    
    luaunit.assertTrue(hasTrackName)
    luaunit.assertTrue(hasTempo)
    luaunit.assertTrue(hasNoteOn)
    luaunit.assertTrue(hasEndOfTrack)
end

function TestMidiPhase4:testCalculateDeltaTimes()
    -- Create test events with absolute times
    local events = {
        {deltaTime = 0, type = "meta", metaType = 0x03, data = "Test"},
        {deltaTime = 96, type = "midi", status = 0x99, data1 = 36, data2 = 100},
        {deltaTime = 192, type = "midi", status = 0x99, data1 = 38, data2 = 100},
        {deltaTime = 384, type = "meta", metaType = 0x2F, data = ""}
    }
    
    local result = midi:calculateDeltaTimes(events)
    
    -- Check that delta times are calculated correctly
    luaunit.assertEquals(result[1].deltaTime, 0)    -- First event: 0
    luaunit.assertEquals(result[2].deltaTime, 96)   -- Second event: 96 - 0 = 96
    luaunit.assertEquals(result[3].deltaTime, 96)   -- Third event: 192 - 96 = 96
    luaunit.assertEquals(result[4].deltaTime, 192)  -- Fourth event: 384 - 192 = 192
end

function TestMidiPhase4:testExportPattern()
    -- Create test pattern
    local pattern = {}
    for track = 1, 8 do
        pattern[track] = {}
        for step = 1, 16 do
            pattern[track][step] = false
        end
    end
    
    -- Add some notes
    pattern[1][1] = true
    pattern[2][5] = true
    
    -- Test export
    local success = midi:exportPattern(pattern, 120, "test_pattern.mid")
    luaunit.assertTrue(success)
    
    -- Check that file was "written"
    luaunit.assertNotNil(mockFiles["test_pattern.mid"])
    luaunit.assertTrue(#mockFiles["test_pattern.mid"] > 0)
    
    -- Test invalid inputs
    luaunit.assertFalse(midi:exportPattern(nil, 120, "test.mid"))
    luaunit.assertFalse(midi:exportPattern(pattern, nil, "test.mid"))
end

function TestMidiPhase4:testExportWithOptions()
    -- Create test pattern
    local pattern = {}
    for track = 1, 8 do
        pattern[track] = {}
        for step = 1, 16 do
            pattern[track][step] = false
        end
    end
    pattern[1][1] = true
    
    -- Test export with custom options
    local options = {
        bpm = 140,
        velocity = 127,
        resolution = 480,
        filename = "custom_pattern.mid"
    }
    
    local success = midi:exportWithOptions(pattern, options)
    luaunit.assertTrue(success)
    
    -- Check that settings were restored
    luaunit.assertEquals(midi.defaultVelocity, 100)  -- Should be restored
    luaunit.assertEquals(midi.resolution, 96)        -- Should be restored
    
    -- Test with invalid pattern
    luaunit.assertFalse(midi:exportWithOptions(nil, options))
end

function TestMidiPhase4:testGenerateHeaderChunk()
    local header = midi:generateHeaderChunk(100)  -- 100 bytes of track data
    
    -- Should start with "MThd"
    luaunit.assertEquals(header:sub(1, 4), "MThd")
    
    -- Should be 14 bytes total (4 + 4 + 6)
    luaunit.assertEquals(#header, 14)
end

function TestMidiPhase4:testWriteMidiFile()
    -- Test successful write
    local success = midi:writeMidiFile("test_write.mid", "test data")
    luaunit.assertTrue(success)
    luaunit.assertEquals(mockFiles["test_write.mid"], "test data")
    
    -- Test with empty data
    success = midi:writeMidiFile("empty.mid", "")
    luaunit.assertTrue(success)
    luaunit.assertEquals(mockFiles["empty.mid"], "")
end

return TestMidiPhase4