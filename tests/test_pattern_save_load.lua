--[[
    MIDI Drum Sequencer - test_pattern_save_load.lua
    
    Unit tests for pattern save/load functionality including JSON serialization,
    file operations, and complete sequencer state preservation.
    
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

-- Path is already set by test_runner.lua when running the full suite
-- For standalone execution, add paths:
if not package.path:match("./src/%?%.lua") then
    package.path = package.path .. ";./src/?.lua;./lib/?.lua"
end

local luaunit = require("luaunit")

-- Mock Love2D modules for testing
local mockLove = {
    graphics = {
        setColor = function(...) end,
        setFont = function(...) end,
        newFont = function(...) return {getWidth = function() return 50 end, getHeight = function() return 12 end} end,
        print = function(...) end,
        rectangle = function(...) end,
        circle = function(...) end,
        line = function(...) end,
        setLineWidth = function(...) end,
        getFont = function() return {getWidth = function() return 50 end, getHeight = function() return 12 end} end,
        getWidth = function() return 900 end,
        getHeight = function() return 650 end
    },
    timer = {
        getTime = function() return os.clock() end,
        getDelta = function() return 0.016 end  -- 60 FPS
    },
    audio = {
        newSource = function(data) 
            local source = {
                setVolume = function() end,
                isPlaying = function() return false end,
                play = function() end,
                stop = function() end
            }
            source.clone = function() 
                return {
                    setVolume = function() end,
                    isPlaying = function() return false end,
                    play = function() end,
                    stop = function() end,
                    clone = function() return source.clone() end
                }
            end
            return source
        end,
        play = function(source) end
    },
    sound = {
        newSoundData = function(samples, sampleRate, bitDepth, channels)
            return {
                setSample = function() end
            }
        end
    },
    filesystem = {
        getInfo = function(path) return nil end,  -- Simulate no existing directories
        createDirectory = function(path) return true end,
        write = function(filename, data) 
            -- Mock file writing for testing
            _G.mockFileSystem = _G.mockFileSystem or {}
            _G.mockFileSystem[filename] = data
            return true 
        end,
        read = function(filename)
            -- Mock file reading for testing
            _G.mockFileSystem = _G.mockFileSystem or {}
            return _G.mockFileSystem[filename]
        end,
        getDirectoryItems = function(dir)
            -- Mock directory listing for testing
            _G.mockFileSystem = _G.mockFileSystem or {}
            local files = {}
            for filename, _ in pairs(_G.mockFileSystem) do
                if filename:match("^" .. dir .. "/.*%.json$") then
                    local basename = filename:gsub("^" .. dir .. "/", "")
                    table.insert(files, basename)
                end
            end
            return files
        end,
        remove = function(filename)
            -- Mock file deletion for testing
            _G.mockFileSystem = _G.mockFileSystem or {}
            if _G.mockFileSystem[filename] then
                _G.mockFileSystem[filename] = nil
                return true
            end
            return false
        end
    }
}

-- Replace love global with our mock
_G.love = mockLove

-- Load required modules
local pattern_manager = require("src.pattern_manager")
local sequencer = require("src.sequencer")
local audio = require("src.audio")
local utils = require("src.utils")

local TestPatternSaveLoad = {}

-- Global test pattern data since we can't use self in setUp
local testPattern = {}

function TestPatternSaveLoad:setUp()
    -- Clear mock file system before each test
    _G.mockFileSystem = {}
    
    -- Initialize modules
    audio:init()
    sequencer:init()
    
    -- Connect modules
    sequencer.audio = audio
    
    -- Create test pattern data
    testPattern = {
        format_version = "1.0",
        created_at = "2024-07-06 12:00:00",
        name = "test_pattern",
        bpm = 140,
        pattern = {},
        track_volumes = {},
        metronome_volumes = {
            normal = 0.6,
            accent = 0.8
        },
        metronome_enabled = true
    }
    
    -- Create test pattern matrix
    for track = 1, 8 do
        testPattern.pattern[track] = {}
        for step = 1, 16 do
            -- Create a simple test pattern
            testPattern.pattern[track][step] = (track + step) % 3 == 0
        end
    end
    
    -- Create test track volumes
    for track = 1, 8 do
        testPattern.track_volumes[track] = 0.5 + (track * 0.05)
    end
end

function TestPatternSaveLoad:tearDown()
    -- Clean up modules
    sequencer.audio = nil
    
    -- Clear mock file system
    _G.mockFileSystem = {}
end

function TestPatternSaveLoad:testPatternManagerInitialization()
    -- Test pattern manager initialization
    local pm = pattern_manager
    luaunit.assertNotNil(pm, "Pattern manager should be available")
    
    pm:init()
    luaunit.assertTrue(true, "Pattern manager initialization should complete without errors")
end

function TestPatternSaveLoad:testJSONEncoding()
    -- Test JSON encoding functionality
    local pm = pattern_manager
    
    -- Test simple object
    local simple_data = {name = "test", value = 42, active = true}
    local json_string = pm:encodeJSON(simple_data)
    
    luaunit.assertNotNil(json_string, "JSON encoding should return a string")
    luaunit.assertTrue(json_string:find('"name":"test"'), "JSON should contain encoded name")
    luaunit.assertTrue(json_string:find('"value":42'), "JSON should contain encoded number")
    luaunit.assertTrue(json_string:find('"active":true'), "JSON should contain encoded boolean")
end

function TestPatternSaveLoad:testJSONDecoding()
    -- Test JSON decoding functionality
    local pm = pattern_manager
    
    -- Test simple JSON
    local json_string = '{"name":"test","value":42,"active":true}'
    local decoded_data = pm:decodeJSON(json_string)
    
    luaunit.assertNotNil(decoded_data, "JSON decoding should return a table")
    luaunit.assertEquals(decoded_data.name, "test", "Decoded name should match")
    luaunit.assertEquals(decoded_data.value, 42, "Decoded number should match")
    luaunit.assertEquals(decoded_data.active, true, "Decoded boolean should match")
end

function TestPatternSaveLoad:testJSONRoundTrip()
    -- Test JSON encode/decode round trip
    local pm = pattern_manager
    
    local original_data = {
        pattern = {{true, false, true}, {false, true, false}},
        volumes = {0.5, 0.7, 0.9},
        bpm = 120
    }
    
    local json_string = pm:encodeJSON(original_data)
    local decoded_data = pm:decodeJSON(json_string)
    
    luaunit.assertEquals(decoded_data.bpm, original_data.bpm, "BPM should survive round trip")
    luaunit.assertEquals(#decoded_data.pattern, #original_data.pattern, "Pattern array length should match")
    luaunit.assertEquals(decoded_data.pattern[1][1], original_data.pattern[1][1], "Pattern boolean values should match")
    luaunit.assertEquals(decoded_data.volumes[2], original_data.volumes[2], "Volume values should match")
end

function TestPatternSaveLoad:testCreatePatternData()
    -- Test pattern data creation from sequencer state
    local pm = pattern_manager
    
    -- Set up test sequencer state
    sequencer:setBPM(150)
    sequencer.pattern[1][1] = true
    sequencer.pattern[1][5] = true
    sequencer.pattern[3][8] = true
    
    audio:setVolume(1, 0.8)
    audio:setVolume(2, 0.6)
    
    -- Create pattern data
    local pattern_data = pm:createPatternData(sequencer, audio)
    
    luaunit.assertNotNil(pattern_data, "Pattern data should be created")
    luaunit.assertEquals(pattern_data.bpm, 150, "BPM should be preserved")
    luaunit.assertEquals(pattern_data.pattern[1][1], true, "Pattern step should be preserved")
    luaunit.assertEquals(pattern_data.pattern[1][5], true, "Pattern step should be preserved")
    luaunit.assertEquals(pattern_data.pattern[3][8], true, "Pattern step should be preserved")
    luaunit.assertEquals(pattern_data.track_volumes[1], 0.8, "Track volume should be preserved")
    luaunit.assertEquals(pattern_data.track_volumes[2], 0.6, "Track volume should be preserved")
end

function TestPatternSaveLoad:testApplyPatternData()
    -- Test applying pattern data to sequencer
    local pm = pattern_manager
    
    -- Apply test pattern data
    local success, error_msg = pm:applyPatternData(testPattern, sequencer, audio)
    
    luaunit.assertTrue(success, "Pattern data application should succeed")
    luaunit.assertNil(error_msg, "No error message should be returned")
    luaunit.assertEquals(sequencer.bpm, testPattern.bpm, "BPM should be applied")
    
    -- Check pattern data was applied
    for track = 1, 8 do
        for step = 1, 16 do
            local expected = testPattern.pattern[track][step]
            local actual = sequencer.pattern[track][step]
            luaunit.assertEquals(actual, expected, 
                string.format("Pattern[%d][%d] should match", track, step))
        end
    end
    
    -- Check volumes were applied
    for track = 1, 8 do
        local expected = testPattern.track_volumes[track]
        local actual = audio:getVolume(track)
        luaunit.assertAlmostEquals(actual, expected, 0.01, 
            string.format("Volume[%d] should match", track))
    end
end

function TestPatternSaveLoad:testPatternSave()
    -- Test pattern save functionality
    local pm = pattern_manager
    
    -- Save test pattern
    local success, error_msg = pm:savePattern(testPattern, "test_save")
    
    luaunit.assertTrue(success, "Pattern save should succeed")
    luaunit.assertNil(error_msg, "No error message should be returned")
    
    -- Check that file was created in mock filesystem
    local expected_path = "patterns/test_save.json"
    luaunit.assertNotNil(_G.mockFileSystem[expected_path], "Pattern file should be created")
    
    -- Verify file content is valid JSON
    local file_content = _G.mockFileSystem[expected_path]
    local decoded = pm:decodeJSON(file_content)
    luaunit.assertNotNil(decoded, "Saved file should contain valid JSON")
    luaunit.assertEquals(decoded.name, "", "Saved pattern should preserve data")
end

function TestPatternSaveLoad:testPatternLoad()
    -- Test pattern load functionality
    local pm = pattern_manager
    
    -- First save a pattern
    pm:savePattern(testPattern, "test_load")
    
    -- Load the pattern
    local pattern_data, error_msg = pm:loadPattern("test_load")
    
    luaunit.assertNotNil(pattern_data, "Pattern load should return data")
    luaunit.assertNil(error_msg, "No error message should be returned")
    luaunit.assertEquals(pattern_data.bpm, testPattern.bpm, "Loaded BPM should match")
    
    -- Check pattern data integrity
    for track = 1, 8 do
        for step = 1, 16 do
            local expected = testPattern.pattern[track][step]
            local actual = pattern_data.pattern[track][step]
            luaunit.assertEquals(actual, expected, 
                string.format("Loaded pattern[%d][%d] should match", track, step))
        end
    end
end

function TestPatternSaveLoad:testPatternLoadNonexistent()
    -- Test loading nonexistent pattern
    local pm = pattern_manager
    
    local pattern_data, error_msg = pm:loadPattern("nonexistent")
    
    luaunit.assertNil(pattern_data, "Loading nonexistent pattern should return nil")
    luaunit.assertNotNil(error_msg, "Error message should be provided")
    luaunit.assertTrue(error_msg:find("not found"), "Error should indicate file not found")
end

function TestPatternSaveLoad:testGetPatternList()
    -- Test pattern list functionality
    local pm = pattern_manager
    
    -- Initially empty
    local list = pm:getPatternList()
    luaunit.assertEquals(#list, 0, "Pattern list should initially be empty")
    
    -- Save some patterns
    pm:savePattern(testPattern, "pattern_a")
    pm:savePattern(testPattern, "pattern_b")
    pm:savePattern(testPattern, "pattern_c")
    
    -- Check list
    list = pm:getPatternList()
    luaunit.assertEquals(#list, 3, "Pattern list should contain 3 patterns")
    
    -- Check that patterns are sorted
    luaunit.assertTrue(list[1] <= list[2], "Patterns should be sorted")
    luaunit.assertTrue(list[2] <= list[3], "Patterns should be sorted")
end

function TestPatternSaveLoad:testDeletePattern()
    -- Test pattern deletion
    local pm = pattern_manager
    
    -- Save a pattern first
    pm:savePattern(testPattern, "test_delete")
    
    -- Verify it exists
    local list = pm:getPatternList()
    luaunit.assertEquals(#list, 1, "Pattern should exist before deletion")
    
    -- Delete it
    local success, error_msg = pm:deletePattern("test_delete")
    luaunit.assertTrue(success, "Pattern deletion should succeed")
    luaunit.assertNil(error_msg, "No error message should be returned")
    
    -- Verify it's gone
    list = pm:getPatternList()
    luaunit.assertEquals(#list, 0, "Pattern should be deleted")
end

function TestPatternSaveLoad:testFilenameValidation()
    -- Test filename validation
    local pm = pattern_manager
    
    -- Valid filenames
    luaunit.assertTrue(pm:validateFilename("test"), "Simple name should be valid")
    luaunit.assertTrue(pm:validateFilename("test_pattern"), "Underscore should be valid")
    luaunit.assertTrue(pm:validateFilename("test-pattern"), "Hyphen should be valid")
    luaunit.assertTrue(pm:validateFilename("test123"), "Numbers should be valid")
    
    -- Invalid filenames
    luaunit.assertFalse(pm:validateFilename(""), "Empty name should be invalid")
    luaunit.assertFalse(pm:validateFilename("test pattern"), "Space should be invalid")
    luaunit.assertFalse(pm:validateFilename("test.pattern"), "Dot should be invalid")
    luaunit.assertFalse(pm:validateFilename("test/pattern"), "Slash should be invalid")
    
    -- Too long filename
    local long_name = string.rep("a", 51)
    luaunit.assertFalse(pm:validateFilename(long_name), "Too long name should be invalid")
end

function TestPatternSaveLoad:testSequencerIntegration()
    -- Test sequencer pattern save/load integration
    
    -- Set up test pattern in sequencer
    sequencer:setBPM(160)
    sequencer.pattern[2][3] = true
    sequencer.pattern[4][7] = true
    sequencer.pattern[6][11] = true
    audio:setVolume(3, 0.9)
    
    -- Save pattern through sequencer
    local success, error_msg = sequencer:savePattern("integration_test")
    luaunit.assertTrue(success, "Sequencer save should succeed")
    luaunit.assertNil(error_msg, "No error should occur")
    
    -- Clear sequencer state
    sequencer:clearPattern()
    sequencer:setBPM(120)
    audio:setVolume(3, 0.7)
    
    -- Load pattern through sequencer
    success, error_msg = sequencer:loadPattern("integration_test")
    luaunit.assertTrue(success, "Sequencer load should succeed")
    luaunit.assertNil(error_msg, "No error should occur")
    
    -- Verify state was restored
    luaunit.assertEquals(sequencer.bpm, 160, "BPM should be restored")
    luaunit.assertEquals(sequencer.pattern[2][3], true, "Pattern should be restored")
    luaunit.assertEquals(sequencer.pattern[4][7], true, "Pattern should be restored")
    luaunit.assertEquals(sequencer.pattern[6][11], true, "Pattern should be restored")
    luaunit.assertAlmostEquals(audio:getVolume(3), 0.9, 0.01, "Volume should be restored")
end

function TestPatternSaveLoad:testPlaybackStatePersistence()
    -- Test that playback state is handled correctly during load
    
    -- Start playback
    sequencer:play()
    luaunit.assertTrue(sequencer.isPlaying, "Sequencer should be playing")
    
    -- Save and load a pattern
    sequencer:savePattern("playback_test")
    sequencer:loadPattern("playback_test")
    
    -- Should still be playing after load
    luaunit.assertTrue(sequencer.isPlaying, "Sequencer should resume playing after load")
    
    -- Stop and test again
    sequencer:stop()
    luaunit.assertFalse(sequencer.isPlaying, "Sequencer should be stopped")
    
    sequencer:loadPattern("playback_test")
    luaunit.assertFalse(sequencer.isPlaying, "Sequencer should remain stopped after load")
end

function TestPatternSaveLoad:testPatternListSorting()
    -- Test that pattern list is properly sorted
    local pm = pattern_manager
    
    -- Save patterns in non-alphabetical order
    pm:savePattern(testPattern, "zebra")
    pm:savePattern(testPattern, "alpha")
    pm:savePattern(testPattern, "beta")
    pm:savePattern(testPattern, "gamma")
    
    local list = pm:getPatternList()
    luaunit.assertEquals(#list, 4, "All patterns should be listed")
    luaunit.assertEquals(list[1], "alpha", "First should be alpha")
    luaunit.assertEquals(list[2], "beta", "Second should be beta")
    luaunit.assertEquals(list[3], "gamma", "Third should be gamma")
    luaunit.assertEquals(list[4], "zebra", "Fourth should be zebra")
end

function TestPatternSaveLoad:testInvalidPatternFormat()
    -- Test handling of invalid pattern format
    local pm = pattern_manager
    
    -- Try to apply invalid pattern data
    local invalid_pattern = {invalid = "data"}
    local success, error_msg = pm:applyPatternData(invalid_pattern, sequencer, audio)
    
    luaunit.assertFalse(success, "Invalid pattern should fail to apply")
    luaunit.assertNotNil(error_msg, "Error message should be provided")
    luaunit.assertTrue(error_msg:find("format"), "Error should mention format issue")
end

function TestPatternSaveLoad:testMetronomeVolumePreservation()
    -- Test that metronome volumes are preserved
    local pm = pattern_manager
    
    -- Set specific metronome volumes
    sequencer:setMetronomeVolume("normal", 0.4)
    sequencer:setMetronomeVolume("accent", 0.9)
    
    -- Create and apply pattern data
    local pattern_data = pm:createPatternData(sequencer, audio)
    luaunit.assertEquals(pattern_data.metronome_volumes.normal, 0.4, "Normal metronome volume should be preserved")
    luaunit.assertEquals(pattern_data.metronome_volumes.accent, 0.9, "Accent metronome volume should be preserved")
    
    -- Clear and restore
    sequencer:setMetronomeVolume("normal", 0.6)
    sequencer:setMetronomeVolume("accent", 0.8)
    
    pm:applyPatternData(pattern_data, sequencer, audio)
    luaunit.assertEquals(sequencer:getMetronomeVolume("normal"), 0.4, "Normal metronome volume should be restored")
    luaunit.assertEquals(sequencer:getMetronomeVolume("accent"), 0.9, "Accent metronome volume should be restored")
end

return TestPatternSaveLoad