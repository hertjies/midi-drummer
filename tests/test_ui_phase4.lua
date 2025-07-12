--[[
    MIDI Drum Sequencer - test_ui_phase4.lua
    
    Unit tests for Phase 4 UI functionality.
    Tests MIDI export button and integration.
    
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

-- Tests MIDI export button and integration
-- Path is already set by test_runner.lua when running the full suite
-- For standalone execution, add paths:
if not package.path:match("./src/%?%.lua") then
    package.path = package.path .. ";./src/?.lua;./lib/?.lua"
end

local luaunit = require("luaunit")

-- Mock Love2D graphics functions for testing
love = love or {}
love.graphics = love.graphics or {
    setColor = function() end,
    setFont = function() end,
    newFont = function() return {
        getWidth = function() return 10 end,
        getHeight = function() return 10 end
    } end,
    print = function() end,
    rectangle = function() end,
    circle = function() end,
    setLineWidth = function() end,
    getFont = function() return {
        getWidth = function() return 10 end,
        getHeight = function() return 10 end
    } end
}

-- Mock MIDI system for testing
local mockMidi = {
    exports = {},
    
    getPatternStats = function(self, pattern)
        if not pattern then return nil end
        return {
            totalNotes = 5,
            notesPerTrack = {2, 2, 1, 0, 0, 0, 0, 0},
            activeSteps = 3
        }
    end,
    
    exportPattern = function(self, pattern, bpm, filename)
        if not pattern or not bpm then return false end
        table.insert(self.exports, {
            pattern = pattern,
            bpm = bpm,
            filename = filename
        })
        return true
    end
}

-- Mock audio system
local mockAudio = {
    volumes = {0.7, 0.7, 0.7, 0.7, 0.7, 0.7, 0.7, 0.7},
    triggerFeedback = {0, 0, 0, 0, 0, 0, 0, 0},
    
    getVolume = function(self, track)
        if track >= 1 and track <= 8 then
            return self.volumes[track]
        end
        return 0
    end,
    
    setVolume = function(self, track, volume)
        if track >= 1 and track <= 8 then
            self.volumes[track] = math.max(0, math.min(1, volume))
        end
    end,
    
    hasTriggerFeedback = function(self, track)
        if track >= 1 and track <= 8 then
            return self.triggerFeedback[track] > 0
        end
        return false
    end,
    
    playSample = function(self, track) end
}

-- Mock os.date for consistent testing
local originalDate = os.date
local function mockDate(format)
    if format == "%Y%m%d_%H%M%S" then
        return "20231201_120000"
    end
    return originalDate(format)
end

local ui = require("ui")
local sequencer = require("sequencer")

local TestUIPhase4 = {}

function TestUIPhase4:setUp()
    -- Mock os.date
    os.date = mockDate
    
    -- Initialize modules
    sequencer:init()
    ui.sequencer = sequencer
    ui.audio = mockAudio
    ui.midi = mockMidi
    ui.utils = require("utils")
    ui.clickedButton = nil
    
    -- Reset mock MIDI exports
    mockMidi.exports = {}
    
    -- Create a test pattern
    sequencer.pattern[1][1] = true
    sequencer.pattern[1][9] = true
    sequencer.pattern[2][5] = true
    sequencer.bpm = 140
end

function TestUIPhase4:tearDown()
    -- Restore original functions
    os.date = originalDate
end

function TestUIPhase4:testExportButtonClick()
    -- Test that export button is clickable
    local playX = 200
    local stopX = playX + ui.buttonWidth + 10
    local resetX = stopX + ui.buttonWidth + 10
    local clearX = resetX + ui.buttonWidth + 10
    local exportX = clearX + ui.buttonWidth + 10
    
    -- Click on export button
    ui:mousepressed(exportX + 20, ui.transportY + 10)
    
    luaunit.assertEquals(ui.clickedButton, "EXPORT")
    luaunit.assertEquals(#mockMidi.exports, 1)
    
    -- Check export data
    local export = mockMidi.exports[1]
    luaunit.assertEquals(export.bpm, 140)
    luaunit.assertEquals(export.filename, "drum_pattern_20231201_120000.mid")
    luaunit.assertNotNil(export.pattern)
end

function TestUIPhase4:testExportMIDI()
    -- Test direct export function call
    luaunit.assertEquals(#mockMidi.exports, 0)
    
    ui:exportMIDI()
    
    luaunit.assertEquals(#mockMidi.exports, 1)
    
    local export = mockMidi.exports[1]
    luaunit.assertEquals(export.bpm, sequencer.bpm)
    luaunit.assertTrue(export.filename:match("drum_pattern_"))
    luaunit.assertTrue(export.filename:match("%.mid$"))
end

function TestUIPhase4:testExportWithoutMIDI()
    -- Test export when MIDI module is not available
    ui.midi = nil
    
    local success = pcall(function()
        ui:exportMIDI()
    end)
    
    luaunit.assertTrue(success)  -- Should not crash
    
    -- Restore MIDI
    ui.midi = mockMidi
end

function TestUIPhase4:testExportWithoutSequencer()
    -- Test export when sequencer is not available
    ui.sequencer = nil
    
    local success = pcall(function()
        ui:exportMIDI()
    end)
    
    luaunit.assertTrue(success)  -- Should not crash
    
    -- Restore sequencer
    ui.sequencer = sequencer
end

function TestUIPhase4:testExportButtonDrawing()
    -- Test that drawing transport controls includes export button
    local success = pcall(function()
        ui:drawTransportControls()
    end)
    
    luaunit.assertTrue(success)
end

function TestUIPhase4:testExportButtonHitDetection()
    -- Test export button hit detection boundary cases
    local playX = 200
    local stopX = playX + ui.buttonWidth + 10
    local resetX = stopX + ui.buttonWidth + 10
    local clearX = resetX + ui.buttonWidth + 10
    local exportX = clearX + ui.buttonWidth + 10
    
    -- Click just inside export button
    ui.clickedButton = nil
    ui:mousepressed(exportX + 1, ui.transportY + 1)
    luaunit.assertEquals(ui.clickedButton, "EXPORT")
    
    -- Click just outside export button
    ui.clickedButton = nil
    ui:mousepressed(exportX - 1, ui.transportY + 1)
    luaunit.assertTrue(ui.clickedButton ~= "EXPORT")  -- Should be RESET or nil
    
    -- Click on right edge of export button
    ui.clickedButton = nil
    ui:mousepressed(exportX + ui.buttonWidth - 1, ui.transportY + ui.buttonHeight - 1)
    luaunit.assertEquals(ui.clickedButton, "EXPORT")
end

function TestUIPhase4:testExportWithEmptyPattern()
    -- Clear the pattern
    for track = 1, 8 do
        for step = 1, 16 do
            sequencer.pattern[track][step] = false
        end
    end
    
    -- Export empty pattern
    ui:exportMIDI()
    
    luaunit.assertEquals(#mockMidi.exports, 1)
    
    -- Should still export successfully (empty MIDI file)
    local export = mockMidi.exports[1]
    luaunit.assertNotNil(export.pattern)
end

function TestUIPhase4:testExportFilenameGeneration()
    -- Test that filename includes timestamp
    ui:exportMIDI()
    
    local export = mockMidi.exports[1]
    luaunit.assertTrue(export.filename:match("drum_pattern_20231201_120000%.mid"))
end

function TestUIPhase4:testMultipleExports()
    -- Test multiple exports generate different files (if timestamps differ)
    ui:exportMIDI()
    ui:exportMIDI()
    ui:exportMIDI()
    
    luaunit.assertEquals(#mockMidi.exports, 3)
    
    -- All should have same pattern but potentially different timestamps
    for i = 1, 3 do
        luaunit.assertEquals(mockMidi.exports[i].bpm, sequencer.bpm)
        luaunit.assertNotNil(mockMidi.exports[i].pattern)
    end
end

function TestUIPhase4:testExportButtonStateReset()
    -- Test that button state is reset after click
    local exportX = 200 + 4 * (ui.buttonWidth + 10)
    
    ui:mousepressed(exportX + 20, ui.transportY + 10)
    luaunit.assertEquals(ui.clickedButton, "EXPORT")
    
    ui:mousereleased(exportX + 20, ui.transportY + 10)
    luaunit.assertNil(ui.clickedButton)
end

return TestUIPhase4