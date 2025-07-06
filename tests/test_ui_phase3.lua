--[[
    MIDI Drum Sequencer - test_ui_phase3.lua
    
    Unit tests for Phase 3 UI functionality.
    Tests volume sliders and audio visual feedback.
    
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

-- Tests volume controls and audio integration
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

-- Mock audio system for testing
local mockAudio = {
    volumes = {0.7, 0.7, 0.7, 0.7, 0.7, 0.7, 0.7, 0.7},
    triggerFeedback = {0, 0, 0, 0, 0, 0, 0, 0},
    playedTracks = {},
    
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
    
    playSample = function(self, track)
        if track >= 1 and track <= 8 then
            table.insert(self.playedTracks, track)
            self.triggerFeedback[track] = 0.1
        end
    end
}

local ui = require("ui")
local sequencer = require("sequencer")

local TestUIPhase3 = {}

function TestUIPhase3:setUp()
    -- Initialize modules
    sequencer:init()
    ui.sequencer = sequencer
    ui.audio = mockAudio
    ui.utils = require("utils")
    ui.volumeDragging = nil
    ui.clickedButton = nil
    
    -- Reset mock audio
    mockAudio.playedTracks = {}
    for i = 1, 8 do
        mockAudio.volumes[i] = 0.7
        mockAudio.triggerFeedback[i] = 0
    end
end

function TestUIPhase3:testVolumeSliderCalculation()
    -- Test volume calculation for different positions
    local track = 1
    local baseX = ui.gridX + 16 * (ui.cellSize + ui.cellPadding) + 20
    
    -- Volume at start (0%)
    ui:updateVolumeFromMouse(track, baseX)
    luaunit.assertEquals(mockAudio:getVolume(track), 0.0)
    
    -- Volume at end (100%)
    ui:updateVolumeFromMouse(track, baseX + ui.volumeSliderWidth)
    luaunit.assertEquals(mockAudio:getVolume(track), 1.0)
    
    -- Volume at middle (50%)
    ui:updateVolumeFromMouse(track, baseX + ui.volumeSliderWidth / 2)
    luaunit.assertAlmostEquals(mockAudio:getVolume(track), 0.5, 0.01)
    
    -- Mouse before slider (should clamp to 0%)
    ui:updateVolumeFromMouse(track, baseX - 50)
    luaunit.assertEquals(mockAudio:getVolume(track), 0.0)
    
    -- Mouse after slider (should clamp to 100%)
    ui:updateVolumeFromMouse(track, baseX + ui.volumeSliderWidth + 50)
    luaunit.assertEquals(mockAudio:getVolume(track), 1.0)
end

function TestUIPhase3:testVolumeDragging()
    -- Test starting volume drag
    luaunit.assertNil(ui.volumeDragging)
    
    local track = 3
    local y = ui.gridY + (track - 1) * (ui.cellSize + ui.cellPadding)
    local sliderX = ui.gridX + 16 * (ui.cellSize + ui.cellPadding) + 20
    local sliderY = y + (ui.cellSize - ui.volumeSliderHeight) / 2
    
    -- Click on volume slider
    ui:mousepressed(sliderX + 20, sliderY)
    luaunit.assertEquals(ui.volumeDragging, track)
    
    -- Mouse movement should update volume
    ui:mousemoved(sliderX + 40, sliderY)
    local expectedVolume = 40 / ui.volumeSliderWidth
    luaunit.assertAlmostEquals(mockAudio:getVolume(track), expectedVolume, 0.01)
    
    -- Release should stop dragging
    ui:mousereleased(0, 0)
    luaunit.assertNil(ui.volumeDragging)
end

function TestUIPhase3:testTrackLabelClick()
    -- Test clicking on track labels plays samples
    luaunit.assertEquals(#mockAudio.playedTracks, 0)
    
    -- Click on track 1 label
    local labelY = ui.gridY + 8
    ui:mousepressed(ui.gridX - 30, labelY)
    
    luaunit.assertEquals(#mockAudio.playedTracks, 1)
    luaunit.assertEquals(mockAudio.playedTracks[1], 1)
    
    -- Click on track 5 label
    labelY = ui.gridY + (5 - 1) * (ui.cellSize + ui.cellPadding) + 8
    ui:mousepressed(ui.gridX - 30, labelY)
    
    luaunit.assertEquals(#mockAudio.playedTracks, 2)
    luaunit.assertEquals(mockAudio.playedTracks[2], 5)
end

function TestUIPhase3:testVisualFeedback()
    -- Test that trigger feedback affects grid colors
    -- This is tested by calling drawGrid() which uses hasTriggerFeedback()
    
    -- Set trigger feedback for track 1
    mockAudio.triggerFeedback[1] = 0.05
    
    -- Draw grid should not crash and should call hasTriggerFeedback
    local success = pcall(function() ui:drawGrid() end)
    luaunit.assertTrue(success)
    
    -- Test that hasTriggerFeedback is working
    luaunit.assertTrue(mockAudio:hasTriggerFeedback(1))
    luaunit.assertFalse(mockAudio:hasTriggerFeedback(2))
end

function TestUIPhase3:testVolumeControlsDrawing()
    -- Test that volume controls drawing doesn't crash
    local success = pcall(function() ui:drawVolumeControls() end)
    luaunit.assertTrue(success)
    
    -- Test without audio (should return early)
    ui.audio = nil
    success = pcall(function() ui:drawVolumeControls() end)
    luaunit.assertTrue(success)
    
    -- Restore audio
    ui.audio = mockAudio
end

function TestUIPhase3:testVolumeSliderHitDetection()
    -- Test that volume slider hit detection works correctly
    for track = 1, 8 do
        local y = ui.gridY + (track - 1) * (ui.cellSize + ui.cellPadding)
        local sliderX = ui.gridX + 16 * (ui.cellSize + ui.cellPadding) + 20
        local sliderY = y + (ui.cellSize - ui.volumeSliderHeight) / 2
        
        -- Click inside slider area
        ui.volumeDragging = nil
        ui:mousepressed(sliderX + 10, sliderY + 2)
        luaunit.assertEquals(ui.volumeDragging, track)
        
        -- Reset for next test
        ui:mousereleased(0, 0)
    end
end

function TestUIPhase3:testAudioIntegrationWithoutCrash()
    -- Test that UI works when audio is nil
    ui.audio = nil
    
    local success = pcall(function()
        ui:mousepressed(ui.gridX - 30, ui.gridY + 8)  -- Track label click
        ui:drawVolumeControls()
        ui:updateVolumeFromMouse(1, 100)
    end)
    
    luaunit.assertTrue(success)
    
    -- Restore audio
    ui.audio = mockAudio
end

return TestUIPhase3